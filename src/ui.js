export class GameUI {
  constructor(game, catalog, assets, save, notice) {
    this.game = game; this.catalog = catalog; this.assets = assets; this.save = save; this.notice = notice;
    this.page = 0; this.category = 'cash'; this.panel = null; this.selection = null;
    this.$ = id => document.getElementById(id);
    this.$('closePanel').onclick = () => this.close();
    this.$('modal').addEventListener('click', e => { if (e.target === this.$('modal')) this.close(); });
    document.querySelectorAll('[data-panel]').forEach(button => button.onclick = () => this.open(button.dataset.panel));
    this.$('settingsBtn').onclick = () => { if (game.player) this.open('settings'); };
  }
  element(tag, text, parent, className = '') {
    const e = document.createElement(tag); if (text !== null) e.textContent = text; if (className) e.className = className; if (parent) parent.append(e); return e;
  }
  image(item, parent) {
    const image = this.element('img', null, parent); image.src = this.assets[item.icon].path; image.alt = item.name; return image;
  }
  button(label, parent, fn, className = '') { const b = this.element('button', label, parent, className); b.onclick = fn; return b; }
  perform(fn, rebuild = true) { const ok = fn(); this.save(); if (rebuild) this.open(this.panel, true); return ok; }
  close() { this.$('modal').hidden = true; this.panel = null; }
  open(panel, preserve = false) {
    if (!this.game.player) return;
    if (!preserve && this.panel !== panel) this.selection = null;
    this.panel = panel; this.game.cancelAttack();
    this.$('panelTitle').textContent = { inventory: 'Inventory / กระเป๋า', shop: 'The Wayfarer Shop', pet: 'Trail Companion', quests: 'Quest Journal', settings: 'Settings / ตั้งค่า' }[panel];
    const body = this.$('panelBody'); body.replaceChildren();
    if (panel === 'inventory') this.inventory(body);
    if (panel === 'shop') this.shop(body);
    if (panel === 'pet') this.pet(body);
    if (panel === 'quests') this.quests(body);
    if (panel === 'settings') this.settings(body);
    this.$('modal').hidden = false;
  }
  details(item, entry, parent, shop = false) {
    const d = this.element('div', null, parent, 'item-detail'); d.dataset.detailItem = item.id;
    this.image(item, d); this.element('span', item.type.toUpperCase() + (entry ? ` · ${entry.uid === this.game.player.equipment[item.slot] ? 'EQUIPPED' : 'OWNED'}` : ''), d, 'item-tag');
    this.element('h3', item.name + (entry && item.type === 'equipment' ? ` +${entry.plus}` : ''), d);
    this.element('p', item.description, d);
    if (item.durationHours) this.element('p', `ระยะเวลา ${item.durationHours} ชั่วโมง · นับเวลาจริงแม้ปิดเกม`, d);
    if (shop) {
      this.element('p', `${item.price.toLocaleString()} ${item.currency.toUpperCase()} / ชิ้น`, d);
      const label = this.element('label', 'จำนวน 1–99', d); label.htmlFor = 'buyQuantity';
      const qty = this.element('input', null, d); qty.id = 'buyQuantity'; qty.type = 'number'; qty.min = '1'; qty.max = '99'; qty.value = '1';
      const buy = this.button('ซื้อไอเทม', d, () => this.perform(() => this.game.buy(item.id, Number(qty.value)))); buy.dataset.buy = item.id;
    } else if (entry) {
      if (['equipment', 'consumable', 'pet'].includes(item.type)) {
        const use = this.button(item.type === 'equipment' ? 'สวมใส่' : item.type === 'pet' ? (this.game.player.pet.active ? 'เก็บสัตว์เลี้ยง' : 'เรียกสัตว์เลี้ยง') : 'ใช้ไอเทม', d, () => this.perform(() => this.game.use(entry.uid)));
        use.dataset.use = item.id;
      }
      if (item.type === 'equipment') {
        this.element('p', `เสริมขั้นถัดไป: หิน 1 ชิ้น + ${(entry.plus + 1) * 50} Gold · +1–3 สำเร็จ 100%, +4–6 70%, +7–10 50%`, d);
        const enhance = this.button(entry.plus === 10 ? 'MAX +10' : `เสริมอุปกรณ์ +${entry.plus + 1}`, d, () => this.perform(() => this.game.enhance(entry.uid)));
        enhance.disabled = entry.plus === 10; enhance.dataset.enhance = item.id;
      }
    }
    return d;
  }
  inventory(body) {
    const p = this.game.player;
    this.element('p', `${p.inventory.length}/200 ช่อง · หน้าละ 100 · Gold ${p.gold} · Cash ทดลอง ${p.cash} · CP ${p.cp}`, body);
    const equipped = Object.entries(p.equipment).map(([slot, uid]) => { const entry = p.inventory.find(i => i.uid === uid); return entry ? `${slot}: ${this.game.items[entry.id].name} +${entry.plus}` : ''; }).filter(Boolean).join(' / ');
    this.element('p', equipped || 'เลือกอุปกรณ์เพื่อสวมใส่', body, 'equipment-line');
    const tabs = this.element('div', null, body, 'tabs');
    for (let page = 0; page < 2; page++) this.button(`หน้า ${page + 1}`, tabs, () => { this.page = page; this.open('inventory', true); }, this.page === page ? 'selected' : '');
    const layout = this.element('div', null, body, 'inventory-layout'), grid = this.element('div', null, layout, 'inventory-grid');
    for (let n = 0; n < 100; n++) {
      const entry = p.inventory[this.page * 100 + n];
      if (!entry) { const empty = this.element('div', null, grid, 'item-slot empty'); empty.setAttribute('aria-hidden', 'true'); continue; }
      const item = this.game.items[entry.id];
      const b = this.button('', grid, () => { this.selection = entry.uid; this.open('inventory', true); }, 'item-slot' + (Object.values(p.equipment).includes(entry.uid) ? ' equipped' : ''));
      b.dataset.item = item.id; b.setAttribute('aria-label', `${item.name} +${entry.plus} ×${entry.count}`); this.image(item, b);
      this.element('span', entry.count > 1 ? String(entry.count) : '', b, 'count');
      if (item.type === 'equipment') this.element('span', `+${entry.plus}`, b, 'plus');
    }
    const entry = p.inventory.find(i => i.uid === this.selection) || p.inventory[this.page * 100];
    if (entry) this.details(this.game.items[entry.id], entry, layout); else this.element('p', 'หน้านี้ยังว่าง', layout);
  }
  shop(body) {
    this.element('p', `Cash ทดลอง ${this.game.player.cash} · Gold ${this.game.player.gold} · ไม่มีการชำระเงินจริง`, body);
    const tabs = this.element('div', null, body, 'tabs');
    const categories = { cash: 'Cash & EXP', equipment: 'อาวุธ / ชุด', pet: 'สัตว์เลี้ยง', materials: 'วัตถุดิบ' };
    for (const [key, label] of Object.entries(categories)) this.button(label, tabs, () => { this.category = key; this.selection = null; this.open('shop', true); }, key === this.category ? 'selected' : '');
    const allowed = item => this.category === 'cash' ? item.currency === 'cash' || item.id === 'revive' : this.category === 'equipment' ? item.type === 'equipment' || item.id === 'weapon_reserved' : this.category === 'pet' ? item.type === 'pet' || ['food', 'bond', 'autoLoot'].includes(item.effect) : item.type === 'material' && item.id !== 'weapon_reserved';
    const items = this.catalog.filter(allowed), grid = this.element('div', null, body, 'shop-grid');
    for (const item of items) {
      const b = this.button('', grid, () => { this.selection = item.id; this.open('shop', true); }, 'shop-card'); b.dataset.shopItem = item.id;
      this.image(item, b); const text = this.element('div', null, b); this.element('b', item.name, text);
      if (item.durationHours) this.element('small', `${item.durationHours} HOURS`, text, 'duration');
      this.element('small', `${item.price} ${item.currency.toUpperCase()}`, text);
    }
    const item = items.find(i => i.id === this.selection) || items[0];
    if (item) this.details(item, null, this.element('div', null, body, 'shop-detail'), true);
  }
  pet(body) {
    const p = this.game.player, pet = p.pet, card = this.element('div', null, body, 'pet-card');
    this.image(this.game.items.pet_fox, card); const info = this.element('div', null, card);
    this.element('h3', `Trail Fox · Lv.${pet.level}`, info);
    this.element('p', `EXP ${pet.xp}/${pet.level * 20} · อิ่ม ${Math.ceil(pet.hunger)}% · สนิท ${pet.bond}/100`, info);
    this.element('p', `${pet.active ? 'กำลังเดินตาม' : 'ยังไม่เรียก'} · Auto Loot ${pet.autoLoot ? 'ON' : 'OFF'} · PvE HP +5 / Defense +2 ขณะเรียก`, info);
    const entry = p.inventory.find(i => i.id === 'pet_fox');
    if (entry) { const b = this.button(pet.active ? 'เก็บสัตว์เลี้ยง' : 'เรียกสัตว์เลี้ยง', info, () => this.perform(() => this.game.use(entry.uid))); b.dataset.petAction = 'summon'; }
    for (const [id, label] of [['loot_stone', 'ใช้ Auto Loot Stone'], ['pet_food', 'ให้อาหาร +30'], ['bond_treat', 'เพิ่มความสนิท +10']]) {
      const e = p.inventory.find(i => i.id === id); const b = this.button(`${label} (${e?.count || 0})`, info, () => this.perform(() => this.game.use(e.uid))); b.disabled = !e; b.dataset.petAction = id;
    }
    this.element('p', 'จิ้งจอกวิ่งไปเก็บกล่องดรอปจริงในระยะ 10 เมตร ต้องมีความอิ่มและช่องกระเป๋าว่าง โบนัสใช้เฉพาะ PvE ในต้นแบบนี้', body);
  }
  quests(body) {
    const p = this.game.player;
    this.element('h3', 'Starter Hunt', body); this.element('p', `กำจัดมอนสเตอร์ ${Math.min(5, p.kills)}/5 · รางวัล 10 CP +100 Gold`, body);
    const b = this.button(p.starterClaimed ? 'รับรางวัลแล้ว' : 'รับรางวัล', body, () => this.perform(() => this.game.claimStarterQuest())); b.disabled = p.kills < 5 || p.starterClaimed;
    this.element('p', 'เควสต์เริ่มต้นรับอัตโนมัติเมื่อสร้างตัวละคร · Daily Quest 60 CP/วัน, เควสต์เลื่อน Class, 10 โซน และดันเจี้ยน ยังเป็นแผนพัฒนา', body);
  }
  settings(body) {
    this.element('p', 'PC: WASD เดิน, ลากเมาส์หมุนกล้อง, Wheel ซูม, Space กระโดด, Shift Dash, F โจมตี, 1–3 สกิล, Tab เลือกเป้า, X ยกเลิก, R Speed Run (Lv.20/60)', body);
    this.element('p', 'มือถือ: จอยซ้าย, ปุ่มขวา, ลากพื้นที่ว่างหมุนกล้อง, สองนิ้ว Pinch เพื่อซูม จอยกับปุ่มโจมตีจับคนละนิ้วได้', body);
    this.element('p', 'ข้อมูลบันทึกเฉพาะเครื่อง เป็น Local Playtest ยังไม่มีบัญชี อีเมล Multiplayer เซิร์ฟเวอร์ หรือ GM ไม่มีการชำระเงินจริง', body);
    if (!this.game.player.trialClaimed) this.button('รับ 1,500 Cash ทดลองสำหรับเซฟเดิม', body, () => this.perform(() => { this.game.player.cash += 1500; this.game.player.trialClaimed = true; }));
    this.button('บันทึกและกลับหน้าเลือกตัวละคร', body, () => { this.save(); location.reload(); });
    const credits = this.element('a', 'Asset credits / licenses ↗', body, 'credits'); credits.href = 'CREDITS.md'; credits.target = '_blank';
    this.element('p', 'โมเดลตัวละคร/อาวุธ/จิ้งจอกเป็น Asset ชั่วคราว ชุดและทรงผมมีช่องสวมใส่กับไอคอน แต่ยังไม่มี Mesh Modular ที่ตรง Base จริง', body);
  }
}
