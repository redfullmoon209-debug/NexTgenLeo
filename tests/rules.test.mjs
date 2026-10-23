import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Game, readSave, writeSave, levelHeightScale, visibleScale } from '../src/gameplay.js';
const rules = JSON.parse(await readFile(new URL('../data/rules.json', import.meta.url)));
const catalog = JSON.parse(await readFile(new URL('../data/items.json', import.meta.url)));
function fresh() { const g = new Game(rules, catalog); g.create('TestHero', 'male'); return g; }
function step(g, seconds, input = {}) { for (let i = 0; i < seconds * 20; i++) g.update(0.05, input, g.now + 50); }
const find = (g, id) => g.player.inventory.find(i => i.id === id);

test('startup survives corrupted or blocked storage and reports the problem', () => {
  assert.match(readSave({ getItem: () => '{broken' }).warning, /เซฟเดิม/);
  assert.match(readSave({ getItem: () => { throw new Error('SecurityError'); } }).warning, /ไม่อนุญาต/);
  assert.equal(writeSave({ setItem: () => { throw new Error('Quota'); } }, {}), false);
});
test('legacy save migrates, clamps invalid values, and ignores client GM properties', () => {
  const g = fresh();
  assert.equal(g.restore({ name: 'TestHero', level: 999, x: null, z: 1e100, scale: 3, gmDemo: true, inventory: [{ name: 'Novice Sword', count: 1, plus: 4 }] }, 'TestHero', 'male'), true);
  assert.equal(g.player.level, 100); assert.equal(g.player.x, 0); assert.equal(g.player.z, 42); assert.equal(g.weapon().plus, 4);
  assert.equal(g.player.gmDemo, undefined); assert.equal(g.player.scale, undefined);
});
test('height growth is 70–100% and independent of combat ranges and a separate scale multiplier', () => {
  assert.equal(levelHeightScale(1), 0.7); assert.equal(levelHeightScale(100), 1); assert.equal(visibleScale(100, 2), 2);
  const g = fresh(), range = g.job().range; g.player.level = 100; assert.equal(g.job().range, range);
  assert.equal(rules.jobs.Sword.baseDamage, rules.jobs.Gun.baseDamage); assert.equal(rules.jobs.Gun.baseDamage, rules.jobs.Kunai.baseDamage);
});
test('inventory caps at 200, consumables stack at 99, and a failed purchase is atomic', () => {
  const g = fresh(); g.player.inventory = []; assert.equal(g.addItem('material', 199), true);
  assert.deepEqual(g.player.inventory.map(i => i.count), [99, 99, 1]);
  assert.equal(g.addItem('sword', 197), true); assert.equal(g.player.inventory.length, 200);
  const cash = g.player.cash; assert.equal(g.buy('exp_1h'), false); assert.equal(g.player.cash, cash);
  assert.equal(g.addItem('material', 98), true); assert.equal(g.addItem('material', 1), false);
});
test('all four EXP durations/prices work, consume an item, and extend the same non-stacking ×2 buff', () => {
  const g = fresh(); g.player.cash = 5000;
  for (const [id, hours, cost] of [['exp_1h',1,50],['exp_6h',6,250],['exp_12h',12,450],['exp_24h',24,750]]) {
    const balance = g.player.cash, end = Math.max(g.now, g.player.buffs.exp?.endsAt || 0);
    assert.equal(g.buy(id), true); assert.equal(g.player.cash, balance - cost); assert.equal(g.use(find(g,id).uid), true);
    assert.equal(g.player.buffs.exp.endsAt, end + hours * 36e5); assert.equal(find(g,id), undefined);
  }
  g.now = g.player.buffs.exp.endsAt + 1; assert.equal(g.buff('exp'), false);
});
test('no-target ATK and skill spend no SP and cause no damage', () => {
  const g = fresh(); assert.equal(g.requestAttack(), false); assert.equal(g.requestAttack('cleave'), false); step(g, 1);
  assert.equal(g.player.sp, 100); assert.equal(g.monsters[0].hp, 48);
});
test('ATK from a second finger overrides an already held stick and a new movement intent cancels it', () => {
  const g=fresh();step(g,0.1,{x:0.5,z:0});g.select('mob-0');g.requestAttack();step(g,3,{x:0.5,z:0});
  assert.equal(g.player.kills,1);assert.equal(g.autoAttack,false);
  g.lockNearest();g.requestAttack();step(g,0.05,{x:-0.5,z:0});assert.equal(g.autoAttack,false);
});
test('auto approach executes actual hits, stops on death, awards EXP, and creates uncollected loot', () => {
  const g = fresh(); g.select('mob-0'); g.requestAttack(); step(g, 3);
  assert.equal(g.monsters[0].hp, 0); assert.equal(g.player.kills, 1); assert.equal(g.player.xp, 20); assert.equal(g.player.gold, 1000);
  assert.equal(g.drops.length, 1); assert.equal(g.autoAttack, false); assert.equal(g.selected, null);
  assert.ok(g.player.z < -2); assert.equal(g.pickup(), true); assert.equal(g.player.gold, 1005); assert.equal(find(g,'material').count, 2);
});
test('EXP buff doubles actual kill reward; PvE damage buff changes real damage', () => {
  const g = fresh(); g.player.z = -4; g.addItem('exp_1h'); g.use(find(g,'exp_1h').uid);
  g.addItem('buff_attack'); g.use(find(g,'buff_attack').uid); g.select('mob-0'); g.requestAttack(); step(g, 0.35);
  assert.equal(g.monsters[0].hp, 19); step(g, 1); assert.equal(g.player.xp, 40);
});
test('attacks lock movement, queue Jump, and Dash interrupts before the hit', () => {
  const g = fresh(); g.player.z = -4; g.select('mob-0'); g.requestAttack(); step(g,0.05);
  const pos = g.player.x; g.jump(); step(g,0.1,{x:1}); assert.equal(g.player.x,pos); assert.equal(g.jumpY,0);
  g.dash(); step(g,0.1); assert.equal(g.monsters[0].hp,48); assert.equal(g.autoAttack,false);
  const h=fresh(); h.player.z=-4; h.select('mob-0'); h.requestAttack(); step(h,0.05); h.jump(); step(h,0.6); assert.ok(h.jumpY>0);
});
test('three weapons equip by item ID and persist with enhancement', () => {
  const g = fresh(); for (const id of ['sword','gun','kunai']) { g.use(find(g,id).uid); assert.equal(g.weapon().id,id); assert.equal(g.job(),rules.jobs[g.items[id].job]); }
  g.enhance(g.weapon().uid,()=>0); const saved=g.snapshot(); const loaded=fresh(); loaded.restore(saved,'TestHero','male');
  assert.equal(loaded.weapon().id,'kunai'); assert.equal(loaded.weapon().plus,1);
});
test('enhance can reach +10 and failure drops one tier without destroying equipment', () => {
  const g=fresh();g.player.gold=100000;const sword=find(g,'sword'),id=sword.uid;
  for(let i=0;i<10;i++)assert.equal(g.enhance(id,()=>0),true);
  assert.equal(sword.plus,10);assert.equal(g.enhance(id),false);g.addItem('enhance_stone');sword.plus=6;g.enhance(id,()=>0.99);
  assert.equal(sword.plus,5);assert.equal(find(g,'sword').uid,id);
});
test('pet walks to actual loot, collects it once, gains EXP and persists; disabled/hungry pets do not loot', () => {
  const g=fresh();g.use(find(g,'pet_fox').uid);g.use(find(g,'loot_stone').uid);
  g.drops.push({id:'real-loot',x:4,z:0,gold:17,itemId:'enhance_stone'});step(g,2);
  assert.equal(g.drops.length,0);assert.equal(g.player.gold,1017);assert.equal(find(g,'enhance_stone').count,11);assert.equal(g.player.pet.xp,10);
  step(g,1);assert.equal(g.player.gold,1017);
  g.player.pet.hunger=0;g.drops.push({id:'second',x:1,z:0,gold:3,itemId:'material'});step(g,1);assert.equal(g.drops.length,1);
  g.use(find(g,'pet_food').uid);assert.ok(g.player.pet.hunger>0);step(g,1);assert.equal(g.drops.length,0);
  const h=fresh();h.restore(g.snapshot(),'TestHero','male');assert.equal(h.player.pet.autoLoot,true);assert.equal(h.player.pet.active,true);
});
test('pet food/bond items and full bags preserve loot without silent deletion', () => {
  const g=fresh(),food=find(g,'pet_food').count;assert.equal(g.use(find(g,'pet_food').uid),false);assert.equal(find(g,'pet_food').count,food);
  g.use(find(g,'pet_fox').uid);g.use(find(g,'bond_treat').uid);assert.equal(g.player.pet.bond,10);
  g.player.inventory=[];g.addItem('sword',200);const d={id:'full',x:0,z:0,gold:10,itemId:'material'};g.drops.push(d);
  assert.equal(g.collectDrop(d),false);assert.equal(g.drops.length,1);assert.equal(g.player.gold,1000);
});
test('revival honors EXP privilege, consumes normal items, and Safe Zone costs EXP without level loss', () => {
  const g=fresh();g.player.hp=0;assert.equal(g.revive('spot'),true);assert.equal(find(g,'revive'),undefined);assert.equal(g.player.hp,50);
  g.addItem('exp_1h');g.use(find(g,'exp_1h').uid);g.player.xp=50;
  for(let i=0;i<3;i++){g.player.hp=0;assert.equal(g.revive('spot'),true);assert.equal(g.player.xp,50);}
  g.player.hp=0;g.revive('safe');assert.equal(g.player.xp,48);assert.equal(g.player.level,1);assert.equal(g.player.z,5);
});
test('Speed Run unlocks correct tier, drains SP and stops boost at zero', () => {
  const g=fresh();g.player.level=60;g.player.sp=10;step(g,1,{x:1,run:true});assert.ok(Math.abs(g.player.x-6.4)<0.01);assert.ok(Math.abs(g.player.sp-7)<0.01);
  const h=fresh();h.player.level=1;step(h,1,{x:1,run:true});assert.ok(Math.abs(h.player.x-4)<0.01);
  const e=fresh();e.player.level=60;e.player.sp=0;step(e,1,{x:1,run:true});assert.ok(Math.abs(e.player.x-4)<0.01);assert.equal(e.runExhausted,true);
});
test('corrupt timing cannot create a phantom dash or move a stationary character', () => {
  const g=fresh();g.update(-0.2);assert.equal(g.player.z,0);assert.equal(g.player.x,0);
});
test('all three skills spend SP, use real multipliers, and enforce cooldowns', () => {
  for(const skill of rules.skillSlots){
    const g=fresh();g.player.z=-4;g.monsters[0].hp=g.monsters[0].maxHp=300;
    g.select('mob-0');g.requestAttack(skill.id);step(g,0.3);
    assert.equal(g.monsters[0].hp,300-Math.round(24*skill.multiplier));
    assert.ok(g.player.sp<=100-skill.sp+1);assert.equal(g.requestAttack(skill.id),false);
  }
});
test('PvE HP/Defense buffs expire, pet HP bonus and starter quest reward are functional', () => {
  const g=fresh();g.addItem('buff_hp');g.use(find(g,'buff_hp').uid);assert.equal(g.maxHP(),120);
  g.use(find(g,'pet_fox').uid);assert.equal(g.maxHP(),126);
  g.now=g.player.buffs.hp.endsAt+1;g.player.hp=126;step(g,0.05);assert.equal(g.maxHP(),105);assert.equal(g.player.hp,105);
  g.player.kills=5;assert.equal(g.claimStarterQuest(),true);assert.equal(g.claimStarterQuest(),false);assert.equal(g.player.cp,10);assert.equal(g.player.gold,1100);
  const a=fresh(),b=fresh();for(const t of [a,b]){t.player.x=5;t.player.z=-5;t.monsters[0].x=5;t.monsters[0].z=-5;t.monsters[0].elite=true;}
  b.addItem('buff_defense');b.use(find(b,'buff_defense').uid);step(a,0.05);step(b,0.05);assert.ok(b.player.hp>a.player.hp);
});
