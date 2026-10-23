import { Game, readSave, writeSave, levelHeightScale } from './src/gameplay.js';
import { ForestScene } from './src/scene.js';
import { GameUI } from './src/ui.js';

const $ = id => document.getElementById(id);
async function json(path) {
  const response = await fetch(path, { signal: AbortSignal.timeout(15000) });
  if (!response.ok) throw new Error(`โหลด ${path} ไม่สำเร็จ (${response.status})`);
  return response.json();
}
const [rules, items, assets] = await Promise.all(['data/rules.json', 'data/items.json', 'data/assets.json'].map(json));
let toastTimer, forest, started = false, starting = false, gender = 'male', last = 0, hudAt = 0, buffAt = -1, saveWarning = false;
const keys = new Set(), cameraPointers = new Map();
const joy = { x: 0, z: 0, owner: null };
const storage = { getItem: key => window.localStorage.getItem(key), setItem: (key, value) => window.localStorage.setItem(key, value) };
const loaded = readSave(storage);
if (loaded.warning) $('gateError').textContent = loaded.warning;
if (typeof loaded.data?.name === 'string') $('nameInput').value = loaded.data.name.slice(0, 18);
if (loaded.data?.gender === 'female') gender = 'female';

function notice(text) { $('toast').textContent = text; $('toast').style.opacity = '1'; clearTimeout(toastTimer); toastTimer = setTimeout(() => $('toast').style.opacity = '0', 2600); }
const game = new Game(rules, items, notice);
function save() {
  if (!game.player) return;
  if (!writeSave(storage, game.snapshot()) && !saveWarning) { saveWarning = true; notice('บันทึกไม่ได้ เล่นต่อได้เฉพาะรอบนี้ ตรวจสอบพื้นที่จัดเก็บของเบราว์เซอร์'); }
}
const ui = new GameUI(game, items, assets, save, notice);
for (const button of document.querySelectorAll('[data-gender]')) {
  button.classList.toggle('selected', button.dataset.gender === gender);
  button.onclick = () => { gender = button.dataset.gender; document.querySelectorAll('[data-gender]').forEach(b => b.classList.toggle('selected', b === button)); };
}
async function start() {
  if (started || starting) return;
  const name = $('nameInput').value.trim();
  if (name.length < 3 || name.length > 18) { $('gateError').textContent = 'ตั้งชื่อ 3–18 ตัวอักษร'; return; }
  starting = true; $('startBtn').disabled = true; $('startBtn').textContent = 'กำลังโหลด Starter Forest…';
  game.restore(loaded.data, name, gender);
  $('game').hidden = false;
  try {
    forest = new ForestScene($('world'), assets, game, window.showGameError);
    const timeout = setTimeout(() => { $('gateError').textContent = 'กำลังโหลดโมเดล กรุณารอสักครู่…'; }, 7000);
    try { await forest.load(); } finally { clearTimeout(timeout); }
    $('gate').hidden = true; forest.resize(); started = true; last = performance.now();
    save(); refresh(); requestAnimationFrame(loop);
    notice(loaded.warning || 'ยินดีต้อนรับ · Cash และไอเทมทั้งหมดเป็นของทดลอง');
  } catch (error) { window.showGameError(new Error(`เข้า Starter Forest ไม่สำเร็จ: ${error.message}`)); }
  finally { starting = false; }
}
$('startBtn').textContent = 'เข้าสู่ Starter Forest →'; $('startBtn').disabled = false;
$('startBtn').onclick = start;
$('nameInput').onkeydown = e => { if (e.key === 'Enter') start(); };

function resetInput() { keys.clear(); joy.x = joy.z = 0; joy.owner = null; cameraPointers.clear(); $('knob').style.transform = ''; }
addEventListener('blur', () => { resetInput(); save(); });
document.addEventListener('visibilitychange', () => { if (document.hidden) { resetInput(); save(); } });
addEventListener('pagehide', save); setInterval(save, 5000);
document.querySelectorAll('[data-panel],#settingsBtn').forEach(b => b.addEventListener('click', resetInput));
addEventListener('keydown', e => {
  if (!started || /INPUT|SELECT|TEXTAREA/.test(e.target.tagName)) return;
  if (e.key === 'Escape') { ui.close(); resetInput(); return; }
  if (!ui.$('modal').hidden) return;
  const k = e.key.toLowerCase(); if ([' ', 'tab'].includes(k)) e.preventDefault(); keys.add(k);
  if (e.repeat) return;
  if (k === ' ') game.jump(); if (k === 'shift') game.dash(); if (k === 'f') game.requestAttack();
  if (k === 'tab') game.lockNearest(); if (k === 'x') game.cancelAttack(); if (k === 'g') game.pickup();
  if (['1', '2', '3'].includes(k)) game.requestAttack(rules.skillSlots[Number(k) - 1].id);
});
addEventListener('keyup', e => { keys.delete(e.key.toLowerCase()); save(); });
// Secondary fingers do not reliably produce a synthetic click on mobile.
// Handle each pointer on press; retain keyboard/accessibility-generated click.
function bindAction(button, action) {
  button.addEventListener('pointerdown', event => { if (event.button > 0) return; event.preventDefault(); action(); });
  button.onclick = event => { if (event.detail === 0) action(); };
}
bindAction($('attackBtn'), () => game.requestAttack()); bindAction($('cancelBtn'), () => game.cancelAttack());
bindAction($('jumpBtn'), () => game.jump()); bindAction($('dashBtn'), () => game.dash()); bindAction($('lockBtn'), () => game.lockNearest());
bindAction($('pickupBtn'), () => { game.pickup(); save(); });
document.querySelectorAll('[data-skill]').forEach(b => bindAction(b, () => game.requestAttack(b.dataset.skill)));
bindAction($('reviveSpot'), () => { game.revive('spot'); save(); }); bindAction($('reviveSafe'), () => { game.revive('safe'); save(); });

const stick = $('joystick');
function moveStick(event) {
  if (event.pointerId !== joy.owner) return;
  const r = stick.getBoundingClientRect(); let x = (event.clientX - r.left - r.width / 2) / (r.width * 0.34), z = (event.clientY - r.top - r.height / 2) / (r.height * 0.34);
  const length = Math.hypot(x, z); if (length > 1) { x /= length; z /= length; }
  joy.x = x; joy.z = z; $('knob').style.transform = `translate(${x * r.width * 0.28}px,${z * r.height * 0.28}px)`;
}
stick.addEventListener('pointerdown', e => { if (joy.owner !== null) return; e.preventDefault(); joy.owner = e.pointerId; stick.setPointerCapture(e.pointerId); moveStick(e); });
stick.addEventListener('pointermove', moveStick);
function releaseStick(e) { if (e.pointerId !== joy.owner) return; joy.owner = null; joy.x = joy.z = 0; $('knob').style.transform = ''; save(); }
for (const event of ['pointerup', 'pointercancel', 'lostpointercapture']) stick.addEventListener(event, releaseStick);
const canvas = $('world');
canvas.addEventListener('wheel', e => { e.preventDefault(); forest?.zoom(Math.exp(e.deltaY * 0.001)); }, { passive: false });
const pinchDistance = () => { const [a, b] = [...cameraPointers.values()]; return Math.hypot(a.x - b.x, a.y - b.y); };
canvas.addEventListener('pointerdown', e => {
  if (e.pointerType === 'mouse' && e.button > 0) return;
  canvas.setPointerCapture(e.pointerId); cameraPointers.set(e.pointerId, { x: e.clientX, y: e.clientY, distance: 0, gesture: false });
  if (cameraPointers.size > 1) cameraPointers.forEach(p => p.gesture = true);
});
canvas.addEventListener('pointermove', e => {
  const point = cameraPointers.get(e.pointerId); if (!point) return;
  const oldDistance = cameraPointers.size === 2 ? pinchDistance() : null, dx = e.clientX - point.x, dy = e.clientY - point.y;
  point.x = e.clientX; point.y = e.clientY; point.distance += Math.hypot(dx, dy);
  if (oldDistance) { const next = pinchDistance(); if (next > 2) forest?.zoom(oldDistance / next); }
  else if (point.distance > 5) forest?.rotate(dx, dy);
});
canvas.addEventListener('pointerup', e => {
  const point = cameraPointers.get(e.pointerId);
  if (point && !point.gesture && point.distance < 8) game.select(forest?.pick(e.clientX, e.clientY));
  cameraPointers.delete(e.pointerId);
});
for (const event of ['pointercancel', 'lostpointercapture']) canvas.addEventListener(event, e => cameraPointers.delete(e.pointerId));

function refresh() {
  const p = game.player, maxHP = game.maxHP();
  $('playerName').textContent = p.name; $('playerLevel').textContent = `LV ${p.level} · CLASS ${p.class} · HEIGHT ${Math.round(levelHeightScale(p.level) * 100)}%`;
  $('hpBar').style.width = `${p.hp / maxHP * 100}%`; $('spBar').style.width = `${p.sp}%`; $('xpBar').style.width = `${p.xp / (p.level * 100) * 100}%`;
  $('hpText').textContent = `HP ${Math.ceil(p.hp)}/${maxHP}`; $('spText').textContent = `SP ${Math.floor(p.sp)}/100`; $('xpText').textContent = `EXP ${p.xp}/${p.level * 100}`;
  for (const key of ['gold', 'cash', 'cp']) $(key).textContent = p[key].toLocaleString();
  $('questText').textContent = `กำจัดมอนสเตอร์ ${Math.min(5, p.kills)}/5${p.starterClaimed ? ' · รับรางวัลแล้ว' : p.kills >= 5 ? ' · รับรางวัลในเควสต์' : ''}`;
  const target = game.target(); $('targetInfo').hidden = !target;
  if (target) { $('targetName').textContent = `${target.elite ? 'Elite' : 'Murmurline'} · Lv.${target.level}`; $('targetBar').style.width = `${target.hp / target.maxHp * 100}%`; $('targetHP').textContent = `HP ${target.hp}/${target.maxHp}`; }
  $('deathPanel').hidden = p.hp > 0;
  if (p.hp <= 0) $('deathText').textContent = `กลับ Safe Zone อัตโนมัติใน ${Math.max(0, Math.ceil(30 - (game.time - game.deadAt)))} วินาที · ${game.buff('exp') ? 'EXP ×2: ชุบ ณ จุดตายฟรี' : 'ใช้ Revive Leaf เพื่อชุบ ณ จุดตาย'}`;
  const second = Math.floor(game.now / 1000);
  if (second !== buffAt) {
    buffAt = second; $('buffs').replaceChildren();
    const icons = { exp: 'icon.spell-book', attack: 'icon.crystal-growth', defense: 'icon.shield-reflect', hp: 'icon.heart-plus' };
    for (const [key, buff] of Object.entries(p.buffs)) if (game.buff(key)) {
      const block = ui.element('div', null, $('buffs'), 'buff'); block.title = key.toUpperCase(); block.dataset.buff = key;
      const img = ui.element('img', null, block); img.src = assets[icons[key]].path; img.alt = key === 'exp' ? 'EXP ×2' : key;
      const secs = Math.max(0, Math.ceil((buff.endsAt - game.now) / 1000));
      ui.element('small', `${Math.floor(secs / 3600)}:${String(Math.floor(secs % 3600 / 60)).padStart(2, '0')}:${String(secs % 60).padStart(2, '0')}`, block);
    }
  }
  const map = $('minimap'), ctx = map.getContext('2d'); ctx.clearRect(0, 0, 120, 120); ctx.fillStyle = '#476b58'; ctx.fillRect(0, 0, 120, 120);
  ctx.strokeStyle = '#b6a580'; ctx.lineWidth = 6; ctx.beginPath(); ctx.moveTo(60, 0); ctx.lineTo(60, 120); ctx.stroke();
  const dot = (x, z, color, size = 2) => { ctx.fillStyle = color; ctx.beginPath(); ctx.arc(60 + x * 1.2, 60 + z * 1.2, size, 0, Math.PI * 2); ctx.fill(); };
  game.monsters.filter(m => m.hp > 0).forEach(m => dot(m.x, m.z, m.elite ? '#eeb16e' : '#f4d9b4'));
  game.drops.forEach(d => dot(d.x, d.z, '#ffe871')); dot(p.x, p.z, '#b2ebfb', 4);
  $('damageNumbers').replaceChildren();
  for (const event of game.events) {
    const pos = forest.project(event.x, event.z, 1.7 + (game.time - event.at));
    if (pos.visible) { const n = ui.element('span', String(event.value), $('damageNumbers'), 'damage-number'); n.style.left = `${pos.x}px`; n.style.top = `${pos.y}px`; }
  }
}
function loop(now) {
  try {
    const dt = Math.max(0, Math.min(0.1, (now - last) / 1000)); last = now;
    let x = Number(keys.has('d')) - Number(keys.has('a')) + joy.x, z = Number(keys.has('s')) - Number(keys.has('w')) + joy.z;
    const c = Math.cos(forest.yaw), s = Math.sin(forest.yaw);
    if ($('modal').hidden) game.update(dt, { x: x * c + z * s, z: -x * s + z * c, run: keys.has('r') });
    else game.now = Date.now();
    forest.render(dt);
    if (now - hudAt > 100) { hudAt = now; refresh(); }
    requestAnimationFrame(loop);
  } catch (error) { window.showGameError(error); }
}
// Read-only diagnostics for reproducible QA. No commands, GM grants, or writable game reference.
Object.defineProperty(window, '__LEO_DIAGNOSTICS__', { value: Object.freeze({
  snapshot: () => game.player ? { player: game.snapshot(), monsters: game.monsters.map(m => ({ ...m, screen: forest?.project(m.x, m.z, 0.6) })), drops: game.drops.map(d => ({ ...d })), selected: game.selected, attack: !!game.attack, jumping: game.jumpY, joystick: { x: joy.x, z: joy.z }, camera: forest ? { distance: forest.distance, yaw: forest.yaw } : null,
    scene: forest ? { ready: !!forest.ready, frameCount: forest.frameCount, drawCalls: forest.renderer.info.render.calls, triangles: forest.renderer.info.render.triangles, weapon: forest.weaponKey, weaponAttached: forest.weaponObject?.parent?.name, weaponBounds: forest.weaponBounds(), petVisible: !!forest.pet?.root.visible, petPose: forest.pet?.pose, playerPose: forest.player?.pose } : null } : null
}), writable: false });
