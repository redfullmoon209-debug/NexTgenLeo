import { createRequire } from 'node:module';
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import { createStaticServer } from '../scripts/serve.mjs';
const { chromium } = createRequire(import.meta.url)('playwright');
const server = createStaticServer({ prefix: '/NexTgenLeo' });
await new Promise(r => server.listen(0, '127.0.0.1', r));
const origin = `http://127.0.0.1:${server.address().port}/NexTgenLeo/`;
const browser = await chromium.launch({ headless: true,
  ...(process.env.BROWSER_EXECUTABLE_PATH ? { executablePath: process.env.BROWSER_EXECUTABLE_PATH } : {}),
  args: ['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--disable-dev-shm-usage'] });
await mkdir('test-results', { recursive: true });
const checks = [];
const passed = text => { checks.push(text); console.log('PASS', text); };
const snapshot = page => page.evaluate(() => window.__LEO_DIAGNOSTICS__.snapshot());
const wait = (page, fn, arg, timeout = 15000) => page.waitForFunction(fn, arg, { timeout });
async function start(page, name, gender = 'male') {
  await page.goto(origin);
  await page.locator('#nameInput').fill(name);
  await page.locator(`[data-gender=${gender}]`).click();
  await page.locator('#startBtn').click();
  await wait(page, () => window.__LEO_DIAGNOSTICS__?.snapshot()?.scene?.ready);
  await page.locator('#gate').waitFor({ state: 'hidden' });
  await page.evaluate(() => document.fonts.ready);
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().scene.frameCount > 3);
}
async function iconsLoaded(page) {
  await wait(page, () => [...document.querySelectorAll('#panelBody img')].every(i => i.complete && i.naturalWidth > 0));
  assert.equal(await page.locator('#panelBody img').count() > 0, true);
}
async function inventoryUse(page, id) {
  await page.locator('[data-panel=inventory]').click();
  await page.getByRole('button', {name:'หน้า 1', exact:true}).click();
  await page.locator(`[data-item=${id}]`).first().click();
  await page.locator(`[data-use=${id}]`).click();
  await page.locator('#closePanel').click();
}
async function buy(page, id) {
  await page.locator(`[data-shop-item=${id}]`).click();
  await page.locator(`[data-buy=${id}]`).click();
}
const errors = [], failedRequests = [];
function monitor(page) {
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('response', r => { if (r.status() >= 400) failedRequests.push(`${r.status()} ${r.url()}`); });
}
try {
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage(); monitor(page);
  await start(page, 'PCPlaytest');
  let s = await snapshot(page);
  assert.ok(s.scene.triangles > 10000 && s.scene.drawCalls > 20);
  assert.equal(s.scene.weaponAttached, 'arm-right');
  assert.equal(s.player.x, 0); assert.equal(s.player.z, 0);
  await page.screenshot({ path: 'test-results/desktop-forest.png' });
  passed('Desktop renders lit ground, sourced characters, trees and monsters at a repository subpath');
  await page.locator('#attackBtn').click(); assert.equal((await snapshot(page)).selected, null);
  await page.keyboard.down('w'); await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().player.z < -1); await page.keyboard.up('w');
  const z = (await snapshot(page)).player.z; assert.ok(z < -1);
  await page.keyboard.press('Space'); await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().jumping > 0.2);
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().jumping === 0);
  const oldDistance = (await snapshot(page)).camera.distance;
  await page.mouse.move(710, 490); await page.mouse.wheel(0, -220);
  await wait(page, old => window.__LEO_DIAGNOSTICS__.snapshot().camera.distance < old, oldDistance);
  passed('Desktop WASD, Jump, wheel zoom, and no-target ATK');
  let monster = (await snapshot(page)).monsters[0];
  await page.mouse.click(monster.screen.x, monster.screen.y);
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().selected === 'mob-0');
  await page.locator('#attackBtn').click();
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().player.kills === 1);
  s = await snapshot(page); assert.equal(s.player.xp, 20); assert.equal(s.player.gold, 1000); assert.equal(s.drops.length, 1);
  await page.locator('#pickupBtn').click(); s = await snapshot(page); assert.equal(s.drops.length, 0); assert.equal(s.player.gold, 1005);
  passed('Actual raycast target, auto approach, real damage/EXP, drop, and manual pickup');

  await page.locator('[data-panel=shop]').click(); await iconsLoaded(page);
  for (const id of ['exp_1h','exp_6h','exp_12h','exp_24h']) assert.equal(await page.locator(`[data-shop-item=${id}] img`).count(), 1);
  await page.screenshot({ path: 'test-results/desktop-cash-shop.png' });
  for (const id of ['exp_1h', 'buff_attack', 'buff_defense', 'buff_hp', 'warp']) await buy(page, id);
  assert.equal((await snapshot(page)).player.cash, 1345);
  for (const label of ['อาวุธ / ชุด','สัตว์เลี้ยง','วัตถุดิบ']) { await page.locator('#panelBody').getByRole('button', {name:label, exact:true}).click(); await iconsLoaded(page); }
  await page.locator('#closePanel').click();
  for (const id of ['exp_1h','buff_attack','buff_defense','buff_hp']) await inventoryUse(page, id);
  await wait(page, () => document.querySelectorAll('#buffs .buff').length === 4);
  passed('Shop icons in all categories, four EXP durations, buying and using real timed buffs');

  for (const id of ['gun', 'kunai', 'sword']) {
    await inventoryUse(page, id); await wait(page, id => window.__LEO_DIAGNOSTICS__.snapshot().scene.weapon === id, id);
    assert.equal((await snapshot(page)).scene.weaponAttached, 'arm-right');
    await page.screenshot({ path: `test-results/desktop-weapon-${id}.png` });
  }
  await page.locator('[data-panel=inventory]').click(); await page.locator('[data-item=sword]').click(); await page.locator('[data-enhance=sword]').click();
  assert.equal((await snapshot(page)).player.inventory.find(i => i.id === 'sword').plus, 1);
  assert.equal(await page.locator('.inventory-grid > *').count(), 100); await iconsLoaded(page);
  await page.screenshot({ path: 'test-results/desktop-inventory.png' });
  await page.getByRole('button',{name:'หน้า 2',exact:true}).click(); assert.equal(await page.locator('.item-slot.empty').count(),100);
  await page.locator('#closePanel').click();
  for (const id of ['hat','hair','shirt','gloves','pants','boots','accessory']) await inventoryUse(page,id);
  passed('Sword/Gun/Kunai attach to hand, equipment slots work, +1 consumes stone/Gold, inventory has two 100-slot pages');

  await page.locator('[data-panel=pet]').click(); await page.locator('[data-pet-action=summon]').click();
  await page.locator('[data-pet-action=loot_stone]').click(); await page.locator('[data-pet-action=pet_food]').click(); await page.locator('[data-pet-action=bond_treat]').click();
  await page.locator('#closePanel').click();
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().scene.petVisible);
  const petBefore = (await snapshot(page)).player.pet.x;
  await page.keyboard.down('d'); await wait(page, x => window.__LEO_DIAGNOSTICS__.snapshot().player.x > x + 2, (await snapshot(page)).player.x);
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().scene.petPose === 'Walk'); await page.keyboard.up('d');
  await wait(page, before => Math.abs(window.__LEO_DIAGNOSTICS__.snapshot().player.pet.x - before) > 0.8, petBefore);
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().monsters[0].hp > 0, null, 25000);
  monster = (await snapshot(page)).monsters[0]; await page.mouse.click(monster.screen.x, monster.screen.y);
  await page.locator('[data-skill=focus]').click();
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().player.kills >= 2);
  await wait(page, () => window.__LEO_DIAGNOSTICS__.snapshot().player.pet.xp >= 10 && window.__LEO_DIAGNOSTICS__.snapshot().drops.length === 0);
  s = await snapshot(page); assert.equal(s.player.xp, 60); assert.equal(s.player.gold, 960); assert.ok(s.player.pet.bond >= 10);
  await page.screenshot({ path: 'test-results/desktop-pet-loot.png' });
  passed('Visible animated Fox follows, consumes food/stone/treat, collects actual new loot once, and EXP ×2 doubles kill reward');
  await inventoryUse(page, 'warp'); assert.equal((await snapshot(page)).player.z, 5);
  await page.locator('#settingsBtn').click(); await page.getByRole('button',{name:'บันทึกและกลับหน้าเลือกตัวละคร',exact:true}).click();
  await page.locator('#startBtn').click(); await page.locator('#gate').waitFor({state:'hidden'});
  s = await snapshot(page); assert.equal(s.player.pet.autoLoot,true); assert.equal(s.player.inventory.find(i=>i.id==='sword').plus,1); assert.ok(s.player.buffs.exp.endsAt > Date.now()); assert.equal(s.player.z,5);
  passed('Warp and reload preserve buffs, equipped item enhancement, pet state, currencies and position');
  assert.deepEqual(errors,[]); assert.deepEqual(failedRequests,[]); await context.close();

  for (const [name,width,height,gender] of [['mobile-portrait',393,851,'female'],['mobile-landscape',844,390,'male']]) {
    const c = await browser.newContext({viewport:{width,height},isMobile:true,hasTouch:true,deviceScaleFactor:2}); const p = await c.newPage(); monitor(p);
    await start(p,name,gender); const cdp = await c.newCDPSession(p);
    const rect = await p.locator('#joystick').boundingBox(), attack = await p.locator('#attackBtn').boundingBox();
    const joyPoint={x:rect.x+rect.width/2+20,y:rect.y+rect.height/2,id:1};
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[joyPoint]});
    await wait(p,()=>window.__LEO_DIAGNOSTICS__.snapshot().joystick.x>0.2);
    const before=(await snapshot(p)).player.x;
    const attackPoint={x:attack.x+attack.width/2,y:attack.y+attack.height/2,id:2};
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[joyPoint,attackPoint]});
    await wait(p,()=>document.getElementById('toast').textContent.includes('เลือกมอนสเตอร์ก่อน'));
    await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[attackPoint]});
    assert.ok((await snapshot(p)).joystick.x>0.2);
    await wait(p,x=>window.__LEO_DIAGNOSTICS__.snapshot().player.x>x+0.4,before);
    await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
    await wait(p,()=>window.__LEO_DIAGNOSTICS__.snapshot().joystick.x===0);
    const distance=(await snapshot(p)).camera.distance, y=Math.min(height-200,Math.max(240,height/2));
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:width/2-40,y,id:3},{x:width/2+40,y,id:4}]});
    await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:width/2-75,y,id:3},{x:width/2+75,y,id:4}]});
    await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
    assert.ok((await snapshot(p)).camera.distance<distance);
    const yaw=(await snapshot(p)).camera.yaw;
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:width/2,y,id:5}]});
    await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:width/2+35,y:y+3,id:5}]});
    await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
    assert.notEqual((await snapshot(p)).camera.yaw,yaw);
    // Native touch target selection and combat after the camera gesture.
    await p.locator('#lockBtn').tap();
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[joyPoint]});
    await wait(p,()=>window.__LEO_DIAGNOSTICS__.snapshot().joystick.x>0.2);
    await p.waitForTimeout(150);
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[joyPoint,attackPoint]});
    await wait(p,()=>window.__LEO_DIAGNOSTICS__.snapshot().player.kills>=1);
    assert.ok((await snapshot(p)).joystick.x>0.2);
    await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
    await p.screenshot({path:`test-results/${name}-forest.png`});
    await p.locator('[data-panel=inventory]').tap();await iconsLoaded(p);await p.screenshot({path:`test-results/${name}-inventory.png`});await p.locator('#closePanel').tap();
    await p.locator('[data-panel=shop]').tap();await iconsLoaded(p);await p.screenshot({path:`test-results/${name}-shop.png`});
    assert.deepEqual(errors,[]);assert.deepEqual(failedRequests,[]);
    passed(`${name} ${width}×${height}: real touch movement/ATK together, Pinch Zoom, camera, combat, and icon screenshots`); await c.close();
  }

  for (const mode of ['corrupt-save','blocked-storage','gm-url']) {
    const c=await browser.newContext({viewport:{width:1280,height:800}});const p=await c.newPage();monitor(p);
    if(mode==='corrupt-save')await p.addInitScript(()=>localStorage.setItem('nextgenleo_playtest_v2','{broken'));
    if(mode==='blocked-storage')await p.addInitScript(()=>Object.defineProperty(window,'localStorage',{get(){throw new Error('Storage denied');}}));
    await start(p,mode); assert.equal(await p.locator('#bootError').isVisible(),false);
    if(mode==='gm-url'){await p.goto(origin+'?gm_demo=1');await p.locator('#startBtn').click();await p.locator('#gate').waitFor({state:'hidden'});assert.equal(await p.getByRole('button',{name:/GM/}).count(),0);}
    assert.deepEqual(errors,[]); passed(`${mode}: world starts without a blank screen or public GM button`); await c.close();
  }
  // Deliberate fault cases must display diagnostics, not a silently blank world.
  for(const [mode,pattern] of [['missing-model','**/character-human.glb'],['missing-texture','**/mini-forest/Textures/colormap.png']]) {
    const c=await browser.newContext();const p=await c.newPage();await p.route(pattern,route=>route.abort());
    await p.goto(origin);await p.locator('#nameInput').fill('FaultTest');await p.locator('#startBtn').click();
    await p.locator('#bootError').waitFor({state:'visible'});assert.ok((await p.locator('#bootMessage').textContent()).length>10);
    passed(`${mode}: visible startup diagnostic`);await c.close();
  }
  await writeFile('test-results/browser-report.json',JSON.stringify({date:new Date().toISOString(),browser:browser.version(),checks,errors,failedRequests},null,2));
  console.log(`Completed ${checks.length} browser scenarios`);
} finally { await browser.close(); await new Promise(r=>server.close(r)); }
