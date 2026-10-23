// Engine-independent playtest rules. This local simulation is NOT a trusted server.
export const SAVE_KEY = 'nextgenleo_playtest_v2';
export const LEGACY_KEY = 'nextgenleo_playtest_v1';
export const clamp = (value, min, max, fallback = min) => Number.isFinite(value) ? Math.max(min, Math.min(max, value)) : fallback;
export const levelHeightScale = level => 0.7 + 0.3 * (clamp(level, 1, 100) - 1) / 99;
export const visibleScale = (level, gmScale = 1) => levelHeightScale(level) * clamp(gmScale, 0.3, 3, 1);
let sequence = 0;
const uid = () => `item-${Date.now().toString(36)}-${++sequence}`;
const clone = value => JSON.parse(JSON.stringify(value));

export class Game {
  constructor(rules, catalog, notify = () => {}) {
    this.rules = rules;
    this.items = Object.fromEntries(catalog.map(item => [item.id, item]));
    this.notify = notify;
    this.time = 0;
    this.now = Date.now();
    this.selected = null;
    this.autoAttack = false;
    this.pendingSkill = null;
    this.attack = null;
    this.cooldowns = {};
    this.jumpQueued = false;
    this.jumpY = 0;
    this.jumpVelocity = 0;
    this.dashUntil = 0;
    this.dashCooldown = 0;
    this.drops = [];
    this.events = [];
    this.monsters = Array.from({ length: rules.world.monsterCount }, (_, i) => {
      const x = i === 0 ? 0 : Math.sin(i * 2.4) * (8 + i * 1.2);
      const z = i === 0 ? -5 : Math.cos(i * 3.7) * (8 + i * 1.2) - 9;
      const elite = i > 0 && i % 7 === 0;
      return { id: `mob-${i}`, x, z, homeX: x, homeZ: z, hp: elite ? 120 : 48, maxHp: elite ? 120 : 48, elite, level: elite ? 3 : 1, respawnAt: 0, nextHit: 0, pose: 'idle' };
    });
  }

  create(name, gender) {
    this.player = { version: 2, name, gender, level: 1, class: 1, xp: 0, hp: 100, sp: 100, gold: 1000, cash: 1500, cp: 0, kills: 0, x: 0, z: 0, yaw: Math.PI, buffs: {}, equipment: {}, inventory: [], starterClaimed: false, trialClaimed: true,
      pet: { active: false, autoLoot: false, evolution: null, level: 1, xp: 0, hunger: 100, bond: 0, x: 1, z: 1 } };
    for (const id of ['sword', 'gun', 'kunai', 'hat', 'hair', 'shirt', 'gloves', 'pants', 'boots', 'accessory', 'pet_fox', 'pet_food', 'loot_stone', 'bond_treat', 'enhance_stone', 'material', 'revive']) this.addItem(id, ['pet_food', 'enhance_stone'].includes(id) ? 10 : 1);
    this.player.equipment.weapon = this.player.inventory.find(i => i.id === 'sword').uid;
    return this.player;
  }

  restore(data, name, gender) {
    this.create(name, gender);
    if (!data || data.name !== name || typeof data !== 'object') return false;
    const p = this.player;
    p.gender = data.gender === 'female' ? 'female' : 'male';
    p.level = Math.floor(clamp(data.level, 1, 100));
    p.class = Math.floor(clamp(data.class, 1, Math.min(10, Math.ceil(p.level / 10))));
    for (const key of ['gold', 'cash', 'cp', 'kills']) p[key] = Math.floor(clamp(data[key], 0, 1e8, key === 'gold' ? 100 : 0));
    p.xp = clamp(data.xp, 0, p.level < 100 ? p.level * 100 - 1 : 0);
    for (const key of ['x', 'z']) p[key] = clamp(data[key], -this.rules.world.bounds, this.rules.world.bounds, 0);
    p.yaw = clamp(data.yaw, -Math.PI * 2, Math.PI * 2, Math.PI);
    p.inventory = [];
    const legacyNames = { 'Novice Sword': 'sword', 'City Warp Scroll': 'warp', 'EXP ×2 (1 ชั่วโมง)': 'exp_1h', 'EXP ×2 (24 ชั่วโมง)': 'exp_24h', 'PvE Attack +20% (1 ชั่วโมง)': 'buff_attack', 'PvE Defense +20% (1 ชั่วโมง)': 'buff_defense', 'Max HP +20% (1 ชั่วโมง)': 'buff_hp' };
    for (const entry of Array.isArray(data.inventory) ? data.inventory.slice(0, 200) : []) {
      if (!entry || typeof entry !== 'object') continue;
      const id = entry.id || legacyNames[entry.name];
      if (this.items[id]) this.addItem(id, Math.floor(clamp(entry.count, 1, 99)), Math.floor(clamp(entry.plus, 0, 10)));
    }
    // Keep equipment references stable after validation, without accepting arbitrary data.
    const used = new Set();
    for (const entry of Array.isArray(data.inventory) ? data.inventory.slice(0, 200) : []) {
      const next = p.inventory.find(i => i.id === entry?.id && !used.has(i.uid));
      if (next && typeof entry.uid === 'string' && entry.uid.length < 100 && !p.inventory.some(i => i !== next && i.uid === entry.uid)) { used.add(entry.uid); next.uid = entry.uid; }
    }
    p.equipment = {};
    for (const [slot, entryId] of Object.entries(data.equipment || {})) {
      const entry = p.inventory.find(i => i.uid === entryId);
      if (entry && this.items[entry.id].slot === slot) p.equipment[slot] = entry.uid;
    }
    if (!p.equipment.weapon) p.equipment.weapon = p.inventory.find(i => this.items[i.id].slot === 'weapon')?.uid;
    p.buffs = {};
    for (const key of ['exp', 'attack', 'defense', 'hp']) {
      const endsAt = clamp(data.buffs?.[key]?.endsAt, 0, this.now + 365 * 864e5);
      if (endsAt > this.now) p.buffs[key] = { endsAt };
    }
    p.hp = clamp(data.hp, 0, this.maxHP(), this.maxHP());
    p.sp = clamp(data.sp, 0, 100, 100);
    if (p.hp === 0) this.deadAt = this.time;
    p.starterClaimed = data.starterClaimed === true || (data.version !== 2 && p.kills >= 5);
    p.trialClaimed = data.trialClaimed === true;
    if (data.pet && p.inventory.some(i => i.id === 'pet_fox')) {
      Object.assign(p.pet, { active: data.pet.active === true, autoLoot: data.pet.autoLoot === true });
      for (const key of ['level', 'hunger', 'bond']) p.pet[key] = clamp(data.pet[key], key === 'level' ? 1 : 0, 100);
      p.pet.level = Math.floor(p.pet.level); p.pet.xp = clamp(data.pet.xp, 0, p.pet.level * 20 - 1);
      p.pet.evolution = ['hp', 'def', 'atk'].includes(data.pet.evolution) ? data.pet.evolution : null;
    }
    p.pet.x = p.x + 1; p.pet.z = p.z + 1;
    return true;
  }

  snapshot() { return clone(this.player); }
  buff(id) { return (this.player.buffs[id]?.endsAt || 0) > this.now; }
  petBonus(kind) { return this.player.pet.active && this.player.pet.evolution === kind ? (kind === 'hp' ? 5 : kind === 'def' ? 2 : 0.05) : 0; }
  evolvePet(kind) {
    const pet = this.player.pet;
    if (!['hp', 'def', 'atk'].includes(kind) || pet.evolution) return this.fail('สัตว์เลี้ยงเลือกสายได้เพียงครั้งเดียว');
    if (!pet.active) return this.fail('เรียกสัตว์เลี้ยงก่อนอัปเกรด');
    pet.evolution = kind; this.notify(`วิวัฒนาการจิ้งจอกสาย ${kind.toUpperCase()} สำเร็จ`); return true;
  }
  maxHP() { return Math.round((100 + this.petBonus('hp')) * (this.buff('hp') ? 1.2 : 1)); }
  weapon() { return this.player.inventory.find(i => i.uid === this.player.equipment.weapon); }
  job() { return this.rules.jobs[this.items[this.weapon()?.id]?.job || 'Sword']; }
  hasCapacity(id, count = 1) {
    const item = this.items[id];
    if (!item || !Number.isInteger(count) || count < 1) return false;
    const equipment = item.type === 'equipment' || item.type === 'pet';
    const free = this.rules.inventory.capacity - this.player.inventory.length;
    const available = equipment ? free : free * 99 + this.player.inventory.filter(i => i.id === id).reduce((n, i) => n + 99 - i.count, 0);
    return available >= count;
  }
  addItem(id, count = 1, plus = 0) {
    if (!this.hasCapacity(id, count)) return false;
    const item = this.items[id];
    if (!['equipment', 'pet'].includes(item.type)) {
      for (const entry of this.player.inventory.filter(i => i.id === id)) {
        const amount = Math.min(count, 99 - entry.count); entry.count += amount; count -= amount;
      }
    }
    while (count > 0) {
      const amount = ['equipment', 'pet'].includes(item.type) ? 1 : Math.min(99, count);
      this.player.inventory.push({ uid: uid(), id, count: amount, plus: item.type === 'equipment' ? plus : 0 }); count -= amount;
    }
    return true;
  }
  removeItem(entry) { entry.count--; if (entry.count <= 0) this.player.inventory.splice(this.player.inventory.indexOf(entry), 1); }
  buy(id, count = 1) {
    const item = this.items[id]; count = Math.floor(clamp(count, 1, 99));
    if (!item || !this.hasCapacity(id, count)) return this.fail('กระเป๋าเต็ม');
    const cost = item.price * count;
    if (this.player[item.currency] < cost) return this.fail('เงินไม่พอ');
    this.player[item.currency] -= cost; this.addItem(id, count); this.notify(`ได้รับ ${item.name} ×${count}`); return true;
  }
  fail(message) { this.notify(message); return false; }
  use(entryId) {
    const entry = this.player.inventory.find(i => i.uid === entryId); if (!entry) return false;
    const item = this.items[entry.id], p = this.player;
    if (item.type === 'equipment') { p.equipment[item.slot] = entry.uid; this.autoAttack = false; this.attack = null; this.notify(`สวม ${item.name}`); return true; }
    if (item.type === 'pet') { p.pet.active = !p.pet.active; p.pet.x = p.x + 1; p.pet.z = p.z + 1; this.notify(p.pet.active ? 'เรียก Trail Fox แล้ว' : 'เก็บสัตว์เลี้ยงแล้ว'); return true; }
    if (item.type !== 'consumable') return false;
    if (item.effect === 'revive') return this.revive('spot');
    if (p.hp <= 0) return this.fail('ชุบชีวิตก่อนใช้ไอเทม');
    if (item.durationHours) p.buffs[item.effect] = { endsAt: Math.max(this.now, p.buffs[item.effect]?.endsAt || 0) + item.durationHours * 36e5 };
    else if (item.effect === 'warp') { p.x = this.rules.world.safeX; p.z = this.rules.world.safeZ; this.cancelAttack(); }
    else {
      if (!p.pet.active) return this.fail('เรียกสัตว์เลี้ยงก่อน');
      if (item.effect === 'food') { p.pet.hunger = Math.min(100, p.pet.hunger + 30); p.pet.bond = Math.min(100, p.pet.bond + 1); }
      if (item.effect === 'bond') p.pet.bond = Math.min(100, p.pet.bond + 10);
      if (item.effect === 'autoLoot') { if (p.pet.autoLoot) return this.fail('เปิด Auto Loot อยู่แล้ว'); p.pet.autoLoot = true; }
    }
    this.removeItem(entry); this.notify(`ใช้ ${item.name}`); return true;
  }
  enhance(entryId, random = Math.random) {
    const entry = this.player.inventory.find(i => i.uid === entryId), stone = this.player.inventory.find(i => i.id === 'enhance_stone');
    if (!entry || this.items[entry.id].type !== 'equipment') return false;
    if (entry.plus >= 10) return this.fail('ถึง +10 แล้ว');
    const cost = (entry.plus + 1) * 50;
    if (!stone || this.player.gold < cost) return this.fail('ต้องมีหินตีบวก 1 ชิ้น และ Gold ' + cost);
    this.removeItem(stone); this.player.gold -= cost;
    const success = random() < (entry.plus < 3 ? 1 : entry.plus < 6 ? 0.7 : 0.5);
    entry.plus = clamp(entry.plus + (success ? 1 : -1), 0, 10);
    this.notify(success ? `เสริมสำเร็จ +${entry.plus}` : `เสริมพลาด ลดเหลือ +${entry.plus} (ไอเทมยังอยู่)`); return true;
  }
  select(id) { this.selected = this.monsters.find(m => m.id === id && m.hp > 0)?.id || null; this.cancelAttack(); }
  target() { return this.monsters.find(m => m.id === this.selected && m.hp > 0); }
  lockNearest() {
    const p = this.player;
    const nearest = this.monsters.filter(m => m.hp > 0).sort((a, b) => Math.hypot(a.x - p.x, a.z - p.z) - Math.hypot(b.x - p.x, b.z - p.z))[0];
    this.select(nearest?.id); return nearest;
  }
  requestAttack(skill = null) {
    if (this.player.hp <= 0 || !this.target()) return this.fail('เลือกมอนสเตอร์ก่อน');
    if (skill && ((this.cooldowns[skill] || 0) > this.time)) return this.fail('สกิลยังคูลดาวน์');
    this.autoAttack = true; this.pendingSkill = skill; this.attackInput = this.lastInput ? { ...this.lastInput } : null; return true;
  }
  cancelAttack() { this.autoAttack = false; this.pendingSkill = null; this.attackInput = null; }
  jump() { if (this.player.hp <= 0) return; if (this.attack) this.jumpQueued = true; else if (this.jumpY === 0) this.jumpVelocity = 6; }
  dash() {
    const p = this.player;
    if (p.hp <= 0 || p.sp < 15 || this.time < this.dashCooldown) return false;
    this.cancelAttack(); this.attack = null; this.jumpQueued = false;
    p.sp -= 15; this.dashUntil = this.time + 0.22; this.dashCooldown = this.time + 1.2; return true;
  }
  gainXP(amount) {
    const p = this.player; p.xp += amount;
    while (p.level < 100 && p.xp >= p.level * 100) { p.xp -= p.level * 100; p.level++; p.hp = this.maxHP(); this.notify(`LEVEL UP · ${p.level}`); }
    if (p.level === 100) p.xp = 0;
  }
  hit(target, skill) {
    const p = this.player, job = this.job();
    if (Math.hypot(target.x - p.x, target.z - p.z) > job.range + 0.5) return;
    const victims = skill?.radius ? this.monsters.filter(m => m.hp > 0 && Math.hypot(m.x - target.x, m.z - target.z) < skill.radius) : [target];
    const damage = Math.round((job.baseDamage + (this.weapon()?.plus || 0) * 2) * (this.buff('attack') ? 1.2 : 1) * (1 + this.petBonus('atk')) * (skill?.multiplier || 1));
    for (const m of victims) {
      m.hp = Math.max(0, m.hp - damage); this.events.push({ kind: 'hit', x: m.x, z: m.z, value: damage, at: this.time });
      if (m.hp === 0) {
        m.respawnAt = this.time + this.rules.world.respawnSeconds; p.kills++; this.gainXP((m.elite ? 45 : 20) * (this.buff('exp') ? 2 : 1));
        this.drops.push({ id: uid(), x: m.x, z: m.z, gold: m.elite ? 20 : 5, itemId: p.kills % 3 === 0 ? 'enhance_stone' : 'material' });
        if (m.id === this.selected) { this.selected = null; this.cancelAttack(); }
      }
    }
  }
  collectDrop(drop) {
    if (!this.hasCapacity(drop.itemId)) return false;
    this.addItem(drop.itemId); this.player.gold += drop.gold;
    this.drops.splice(this.drops.indexOf(drop), 1); this.notify(`เก็บ ${this.items[drop.itemId].name} +${drop.gold} Gold`); return true;
  }
  pickup() {
    if (this.player.hp <= 0) return false;
    const d = this.drops.find(d => Math.hypot(d.x - this.player.x, d.z - this.player.z) < 3.5);
    if (!d) return this.fail('ไม่มีดรอปใกล้ตัว');
    return this.collectDrop(d) || this.fail('กระเป๋าเต็ม');
  }
  revive(where) {
    const p = this.player; if (p.hp > 0) return false;
    if (where === 'spot' && !this.buff('exp')) {
      const entry = p.inventory.find(i => i.id === 'revive'); if (!entry) return this.fail('ต้องมี Revive Leaf หรือบัฟ EXP ×2'); this.removeItem(entry);
    }
    if (where === 'safe') { p.xp = Math.max(0, p.xp - Math.ceil(p.level * 100 * 0.02)); p.x = this.rules.world.safeX; p.z = this.rules.world.safeZ; }
    p.hp = this.maxHP() * 0.5; p.sp = 50; this.notify('ชุบชีวิตแล้ว'); return true;
  }
  claimStarterQuest() {
    const p = this.player;
    if (p.kills < 5 || p.starterClaimed) return false;
    p.cp += 10; p.gold += 100; p.starterClaimed = true; this.notify('Starter Hunt สำเร็จ +10 CP +100 Gold'); return true;
  }

  update(dt, input = {}, now = Date.now()) {
    dt = clamp(dt, 0, 0.1, 0);
    this.time += dt; this.now = now;
    const p = this.player; if (!p) return;
    p.hp = Math.min(p.hp, this.maxHP());
    let vx = input.x || 0, vz = input.z || 0, len = Math.hypot(vx, vz);
    this.lastInput = { x: vx, z: vz };
    // A held stick must not cancel the attack pressed by a second finger.
    // Release/reapply or change direction to give a new movement intent.
    if (this.autoAttack && this.attackInput && len > 0 && Math.hypot(vx - this.attackInput.x, vz - this.attackInput.z) < 0.05) { vx = vz = len = 0; }
    else if (len === 0) this.attackInput = null;
    this.moving = false;
    if (p.hp > 0) {
      if (this.time < this.dashUntil) { vx = Math.sin(p.yaw); vz = Math.cos(p.yaw); len = 1; }
      if (this.attack) {
        if (!this.attack.hit && this.time >= this.attack.hitAt) { this.attack.hit = true; const m = this.monsters.find(m => m.id === this.attack.target && m.hp > 0); if (m) this.hit(m, this.attack.skill); }
        if (this.time >= this.attack.endAt) { this.attack = null; if (this.jumpQueued) { this.jumpQueued = false; this.jump(); } }
      }
      if (!this.attack) {
        if (len > 0 && this.time >= this.dashUntil) this.cancelAttack();
        const m = this.target();
        if (this.autoAttack && m && this.jumpY === 0 && this.jumpVelocity === 0) {
          const dx = m.x - p.x, dz = m.z - p.z, distance = Math.hypot(dx, dz); p.yaw = Math.atan2(dx, dz);
          if (distance > this.job().range) { vx = dx / distance; vz = dz / distance; len = 1; }
          else {
            len = 0;
            if (this.time >= (this.nextAttack || 0)) {
              const skill = this.rules.skillSlots.find(s => s.id === this.pendingSkill);
              if (skill && p.sp < skill.sp) { this.notify('SP ไม่พอ ใช้โจมตีปกติต่อ'); }
              const activeSkill = skill && p.sp >= skill.sp && (this.cooldowns[skill.id] || 0) <= this.time ? skill : null;
              if (activeSkill) { p.sp -= activeSkill.sp; this.cooldowns[activeSkill.id] = this.time + activeSkill.cooldown; }
              this.pendingSkill = null; this.nextAttack = this.time + this.job().interval;
              this.attack = { target: m.id, skill: activeSkill, hit: false, hitAt: this.time + 0.22, endAt: this.time + 0.5 };
            }
          }
        }
        if (len > 0 && !this.attack) {
          vx /= len; vz /= len;
          if (!input.run) this.runExhausted = false;
          const tier = [...this.rules.speedRun].reverse().find(r => p.level >= r.level);
          if (input.run && tier && p.sp < tier.spPerSecond * dt) this.runExhausted = true;
          const run = input.run && !this.runExhausted ? tier : null;
          const speed = this.time < this.dashUntil ? 13 : 4 * (run?.multiplier || 1);
          if (run) p.sp -= run.spPerSecond * dt; else p.sp = Math.min(100, p.sp + 3 * dt);
          p.x = clamp(p.x + vx * speed * dt, -this.rules.world.bounds, this.rules.world.bounds); p.z = clamp(p.z + vz * speed * dt, -this.rules.world.bounds, this.rules.world.bounds);
          p.yaw = Math.atan2(vx, vz); this.moving = true;
        } else p.sp = Math.min(100, p.sp + 3 * dt);
      }
      this.jumpY = Math.max(0, this.jumpY + this.jumpVelocity * dt);
      if (this.jumpY > 0 || this.jumpVelocity > 0) this.jumpVelocity -= 16 * dt;
      if (this.jumpY === 0 && this.jumpVelocity < 0) this.jumpVelocity = 0;
    } else if (this.time - this.deadAt > 30) this.revive('safe');

    for (const m of this.monsters) {
      m.pose = 'idle';
      if (m.hp === 0) { if (this.time >= m.respawnAt) { m.hp = m.maxHp; m.x = m.homeX; m.z = m.homeZ; } continue; }
      const distance = Math.hypot(p.x - m.x, p.z - m.z), inSafe = Math.hypot(p.x - this.rules.world.safeX, p.z - this.rules.world.safeZ) < 3;
      const chasing = p.hp > 0 && !inSafe && (m.hp < m.maxHp || (m.elite && distance < 9) || (p.level < m.level && distance < 6));
      if (chasing && distance > 1.5 && distance < 16) { m.x += (p.x - m.x) / distance * 1.8 * dt; m.z += (p.z - m.z) / distance * 1.8 * dt; m.pose = 'walk'; }
      if (chasing && distance <= 1.7 && this.time > m.nextHit) {
        m.nextHit = this.time + 1.5; m.pose = 'attack-melee-right';
        const defense = 10 * (this.buff('defense') ? 1.2 : 1) + this.petBonus('def');
        p.hp = Math.max(0, p.hp - Math.max(1, Math.round((m.elite ? 16 : 9) * 100 / (100 + defense))));
        if (p.hp === 0) { this.deadAt = this.time; this.cancelAttack(); this.attack = null; this.jumpY = this.jumpVelocity = 0; }
      }
    }
    const pet = p.pet;
    if (pet.active && p.hp > 0) {
      pet.hunger = Math.max(0, pet.hunger - dt / 12);
      const loot = pet.autoLoot && pet.hunger > 0 ? this.drops.find(d => Math.hypot(d.x - p.x, d.z - p.z) < 10 && this.hasCapacity(d.itemId)) : null;
      const tx = loot?.x ?? p.x + 1.2, tz = loot?.z ?? p.z + 1.2;
      const dx = tx - pet.x, dz = tz - pet.z, distance = Math.hypot(dx, dz);
      this.petMoving = distance > 0.4;
      if (distance > 0.4) { const step = Math.min(distance, dt * 6); pet.x += dx / distance * step; pet.z += dz / distance * step; this.petYaw = Math.atan2(dx, dz); }
      if (distance > 30) { pet.x = p.x + 1; pet.z = p.z + 1; }
      if (loot && Math.hypot(loot.x - pet.x, loot.z - pet.z) < 0.65 && this.collectDrop(loot)) {
        pet.xp += 10; if (pet.xp >= pet.level * 20 && pet.level < 100) { pet.xp -= pet.level * 20; pet.level++; }
      }
    }
    this.events = this.events.filter(e => this.time - e.at < 0.9);
  }
}

export function readSave(storage) {
  try {
    const raw = storage.getItem(SAVE_KEY) ?? storage.getItem(LEGACY_KEY);
    if (!raw) return { data: null };
    try { return { data: JSON.parse(raw) }; }
    catch { return { data: null, warning: 'เซฟเดิมอ่านไม่ได้ เริ่มเซฟใหม่ได้ (ไฟล์เดิมยังไม่ถูกลบ)' }; }
  } catch { return { data: null, warning: 'เบราว์เซอร์ไม่อนุญาตการบันทึก เล่นได้เฉพาะรอบนี้' }; }
}

export function writeSave(storage, data) {
  try { storage.setItem(SAVE_KEY, JSON.stringify(data)); return true; } catch { return false; }
}
