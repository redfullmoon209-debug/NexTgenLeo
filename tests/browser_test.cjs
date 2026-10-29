const { chromium } = require('playwright');
const { spawn } = require('child_process');
const { PNG } = require('pngjs');

const URL = 'http://127.0.0.1:8060';
async function diagnostics(page) {
  return page.evaluate(() => window.leoDiagnostics);
}
// Require visible pixels, not merely MeshInstance3D nodes. Prior CI
// accepted a completely blank PC portrait because the meshes existed.
async function inspectAvatarPixels(page, bounds) {
  const current = await diagnostics(page);
  const screenshot = PNG.sync.read(await page.screenshot());
  const sx = screenshot.width / current.viewport_size[0];
  const sy = screenshot.height / current.viewport_size[1];
  const x0 = Math.max(0, Math.floor((bounds[0] + 0.22*bounds[2])*sx));
  const x1 = Math.min(screenshot.width, Math.ceil((bounds[0] + 0.78*bounds[2])*sx));
  const y0 = Math.max(0, Math.floor((bounds[1] + 0.17*bounds[3])*sy));
  const y1 = Math.min(screenshot.height, Math.ceil((bounds[1] + 0.86*bounds[3])*sy));
  let skinPixels=0, colourPixels=0;
  for(let y=y0;y<y1;y++) for(let x=x0;x<x1;x++) {
    const i=(screenshot.width*y+x)*4;
    const [red,green,blue,alpha]=screenshot.data.slice(i,i+4);
    if(alpha<220)continue;
    if(red>96 && green>64 && blue>38 && red>green*1.09 && green>blue*1.06)skinPixels++;
    if((red>85 && green<red*.8 && blue>red*.7)||(blue>105 && blue>red*1.3 && blue>green*1.08))colourPixels++;
  }
  return {skinPixels,colourPixels,region:[x0,y0,x1,y1]};
}
async function clickGodot(page, point) {
  if (!point || point.length < 2) throw Error('Missing Godot control coordinates');
  const d = await diagnostics(page);
  await page.mouse.click(point[0] * d.screen_size[0] / d.viewport_size[0],
                         point[1] * d.screen_size[1] / d.viewport_size[1]);
}
async function openBag(page) {
  await page.keyboard.press('b');
  await page.waitForFunction(() => window.leoDiagnostics?.silver?.open === true, null, {timeout:15000});
}
async function closeBag(page) {
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => window.leoDiagnostics?.silver?.open === false, null, {timeout:15000});
}
(async () => {
  const server = spawn('python', ['-m','http.server','8060','--bind','127.0.0.1','--directory','build/web']);
  let browser, currentPage;
  let completed = false;
  const errors = [];
  try {
    browser = await chromium.launch({headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
    const context = await browser.newContext({viewport:{width:1280,height:720}});
    const page = await context.newPage();
    currentPage = page;
    page.on('pageerror', error => errors.push('Desktop: ' + error.message));
    page.on('console', m => {if (m.type() === 'error' && /SCRIPT ERROR|Parse Error/i.test(m.text())) errors.push(m.text());});
    await page.goto(URL);
    await page.waitForFunction(()=>window.leoDiagnostics, null, {timeout:60000});
    const start = await diagnostics(page);
    if (!start.hud_status_rect || !start.hud_quest_rect || !start.gm_button_visible)
      throw Error('Existing gameplay HUD or offline GM control missing');
    // Settings-only acceptance: verify the header is separate from the GM button,
    // opens 10 actual Godot rows, renders golden fill, and collapses again.
    const settingsReady = await page.evaluate(() => window.leoSettingsRich);
    if(!settingsReady || settingsReady.open || settingsReady.rows !== 10)
      throw Error('Settings component did not initialize: '+JSON.stringify(settingsReady));
    if(settingsReady.native_caption !== 'ตั้งค่า')
      throw Error('Closed Settings must have a native, localizable caption over blank illustrated plate: '+JSON.stringify(settingsReady));
    if(start.gm_button_rect[0] + start.gm_button_rect[2] > settingsReady.header[0] + 2)
      throw Error('GM must be left of Settings with no overlap: '+JSON.stringify({gm:start.gm_button_rect,settings:settingsReady.header}));
    await clickGodot(page, [settingsReady.header[0] + settingsReady.header[2]/2,
                             settingsReady.header[1] + settingsReady.header[3]/2]);
    await page.waitForFunction(() => window.leoSettingsRich?.open === true,null,{timeout:6000});
    const openedSettings = await page.evaluate(() => window.leoSettingsRich);
    if(openedSettings.panel[1] < openedSettings.header[1] + openedSettings.header[3] - 2)
      throw Error('Settings rows do not drop underneath the gear header');
    await page.waitForTimeout(300);
    const settingsCapture = PNG.sync.read(await page.screenshot({path:'build/leo-settings-rich-desktop.png'}));
    const sample = (x,y) => {
      const pixel = (Math.round(y) * settingsCapture.width + Math.round(x)) * 4;
      return [...settingsCapture.data.slice(pixel,pixel+3)];
    };
    const goldSamples = [[openedSettings.panel[0]+openedSettings.panel[2]-80,openedSettings.panel[1]+30],
                         [openedSettings.panel[0]+openedSettings.panel[2]-80,openedSettings.panel[1]+88]];
    const goldPixels = goldSamples.map(([x,y])=>sample(x,y));
    if(!goldPixels.some(([r,g,b])=>r>155 && g>80 && b<140))
      throw Error('Settings does not render a gold background layer: '+JSON.stringify({openedSettings,goldPixels}));
    await clickGodot(page,[openedSettings.header[0] + openedSettings.header[2]/2,
                           openedSettings.header[1] + openedSettings.header[3]/2]);
    await page.waitForFunction(() => window.leoSettingsRich?.open === false,null,{timeout:6000});
    // Eight-button nav: illustrated transparent PNGs with native Godot GridContainer Label overlays.
    const navStart = await page.evaluate(() => window.leoMainRichNav);
    const requiredIcons = ['Bag','Menu','Guild','Party','Friends','Notice'];
    if(!navStart || requiredIcons.some(id => !navStart.buttons[id]) || !navStart.legacy_menu_hidden)
      throw Error('Rich main icons or legacy hamburger replacement missing: '+JSON.stringify(navStart));
    await page.waitForFunction(() => window.leoMainRichNav?.native_grid && window.leoMainRichNav.buttons.Bag[2] >= 70, null, {timeout:10000});
    // Eight distinct original artworks and eight real clickable buttons: ONE identical Y.
    const rowCheck = await page.evaluate(() => window.leoMainRichNav);
    if(!rowCheck.standalone_art || !rowCheck.same_row || rowCheck.all_slots.length !== 8)
      throw Error('Shared eight-icon row missing: '+JSON.stringify(rowCheck));
    const inOrder=[start.gm_button_rect,settingsReady.header,...['Bag','Menu','Guild','Party','Friends','Notice'].map(k=>rowCheck.buttons[k])];
    for(let i=0;i<inOrder.length;i++){
      const r=inOrder[i];
      if(Math.abs(r[1]-inOrder[0][1])>2 || Math.abs(r[3]-inOrder[0][3])>2)
        throw Error('Eight main buttons must share the SAME vertical level/height: '+JSON.stringify(inOrder));
      if(i>0 && r[0]<inOrder[i-1][0]+inOrder[i-1][2]-2)
        throw Error('Main icons overlap or are not ordered GM,Settings,Bag,Menu,Guild,Party,Friends,Notice: '+JSON.stringify(inOrder));
    }
    const nativeCaptions = await page.evaluate(() => window.leoMainRichNav.caption_texts);
    const navRectangles = await page.evaluate(() => window.leoMainRichNav.buttons);
    const overlaps = (a,b) => a[0] < b[0]+b[2] && a[0]+a[2] > b[0] && a[1] < b[1]+b[3] && a[1]+a[3] > b[1];
    for(const [name, rect] of Object.entries(navRectangles)) {
      if(overlaps(rect,start.gm_button_rect) || overlaps(rect,settingsReady.header))
        throw Error('Illustrated main icon overlaps protected GM/Settings: '+name+' '+JSON.stringify({rect,gm:start.gm_button_rect,settings:settingsReady.header}));
    }
    for(const [id, expected] of Object.entries({Bag:'กระเป๋า',Menu:'เมนู',Guild:'กิลด์',Party:'ปาร์ตี้',Friends:'เพื่อน',Notice:'ประกาศ'}))
      if(nativeCaptions[id] !== expected) throw Error('Native Godot label missing: '+id+' '+JSON.stringify(nativeCaptions));
    // Independent original PNG assets, all with transparent background and native text overlays.
    const fs = require('fs');
    const srcHashes = new Set();
    for(const asset of ['gm','settings','bag','menu','guild','party','friends','notice']) {
      const p='assets/ui/main_nav/standalone/'+asset+'.png';
      if(!fs.existsSync(p))throw Error('Standalone icon missing: '+p);
      const bytes=fs.readFileSync(p);
      const png=PNG.sync.read(bytes);
      if(png.data[3]>5 || png.width!==320 || png.height!==320)
        throw Error('Each independent standalone icon must have 320x320 transparent PNG backing: '+p);
      const hash=require('crypto').createHash('sha256').update(bytes).digest('hex');
      if(srcHashes.has(hash))throw Error('Two buttons share a duplicated/cropped sprite: '+p);
      srcHashes.add(hash);
    }
    const pressIcon = async id => {
      const state = await page.evaluate(() => window.leoMainRichNav);
      const r = state.buttons[id];
      await clickGodot(page, [r[0]+r[2]/2, r[1]+r[3]/2]);
      await page.waitForFunction(expected => window.leoMainRichNav?.menu === expected,id,{timeout:15000});
    };
    await page.screenshot({path:'build/leo-primary-icons-desktop.png'});
    await pressIcon('Bag');
    let bagNav = await page.evaluate(() => window.leoMainRichNav);
    const expectedBag = ['Bag','Storage','Trade','Status','Shop','Cash','Pet','Skills'];
    if(bagNav.rows !== 8 || JSON.stringify(bagNav.items) !== JSON.stringify(expectedBag))
      throw Error('Bag rich menu contents changed: '+JSON.stringify(bagNav));
    await page.screenshot({path:'build/leo-bag-rich-desktop.png'});
    await pressIcon('Menu');
    let mainNav = await page.evaluate(() => window.leoMainRichNav);
    if(mainNav.rows !== 5 || JSON.stringify(mainNav.items) !== JSON.stringify(['World','Warp','Quest','Auto','Connect']))
      throw Error('Main menu must preserve map, warp, quest, auto-hunt, connect: '+JSON.stringify(mainNav));
    await page.screenshot({path:'build/leo-main-menu-rich-desktop.png'});
    for(const [name, count] of [['Guild',3],['Party',2],['Friends',2],['Notice',2]]) {
      await pressIcon(name);
      const social = await page.evaluate(() => window.leoMainRichNav);
      if(social.rows !== count)throw Error('Independent '+name+' main button not functional: '+JSON.stringify(social));
    }
    { // Clicking the already-open Notice icon collapses to the EMPTY menu id.
      const nav = await page.evaluate(() => window.leoMainRichNav);
      const r = nav.buttons.Notice;
      await clickGodot(page, [r[0] + r[2] / 2, r[1] + r[3] / 2]);
      await page.waitForFunction(() => window.leoMainRichNav?.open === false, null, {timeout:15000});
    }
    await page.locator('canvas').click({position:{x:600,y:400}});
    await openBag(page);
    await page.waitForFunction(() => window.leoMainRichNav?.icons_visible === false, null, {timeout:10000});
    let d = await diagnostics(page);
    if (!d.silver.open || d.silver.extension || d.silver.slots !== 100 || d.silver.pages !== 2 || d.silver.equipment !== 14)
      throw Error('Silver Bag did not render seven parallel equipment pairs and 100 slots: '+JSON.stringify(d.silver));
    if (d.silver.menus !== 14 || d.silver.menu_icons !== 14 || d.silver.accessories !== 5)
      throw Error('Sidebar must have 14 original PNG icons and jewelry row needs five slots: '+JSON.stringify(d.silver));
    if (!d.silver.portrait_meshes || d.silver.portrait_meshes < 6)
      throw Error('Live character preview is missing its meshes');
    // The portrait must actually be rendered before calling desktop QA green.
    // This is the blank yellow-highlighted region the player reported.
    await page.waitForTimeout(1000);
    const portraitImage = await inspectAvatarPixels(page,d.silver.portrait_rect);
    if(portraitImage.skinPixels<80)
      throw Error('Character portrait is blank on PC despite mesh nodes: '+JSON.stringify(portraitImage));
    const portraitBounds=d.silver.portrait_rect;
    const warrior=d.silver.warrior_rects.hat;
    const fashion=d.silver.fashion_rects.fashion_hat;
    if(!warrior||!fashion||warrior[0]+warrior[2]>portraitBounds[0]+2 || fashion[0]<portraitBounds[0]+portraitBounds[2]-2)
      throw Error('Warrior equipment must be LEFT of portrait and fashion RIGHT: '+JSON.stringify({warrior,portraitBounds,fashion}));
    let lastX=-Infinity;
    for(const id of ['ring','bracelet_left','accessory','bracelet_right','ring_right']){
      const rect=d.silver.accessory_rects[id];
      if(!rect||rect[0]<=lastX)throw Error('Jewelry missing or in wrong order: '+id+' '+JSON.stringify(d.silver.accessory_rects));
      lastX=rect[0];
    }
    await page.screenshot({path:'build/leo-silver-character-and-jewelry.png'});
    if (d.silver.main_rect[0] < 0 || d.silver.main_rect[2] > d.viewport_size[0]+1)
      throw Error('Main base outside screen: '+JSON.stringify(d.silver.main_rect));
    await page.screenshot({path:'build/leo-dual-bag-desktop.png'});
    const initialCamera = d.camera_zoom;
    await page.mouse.move(600,400);
    await page.mouse.wheel(0,-300);
    await page.waitForTimeout(250);
    if (Math.abs((await diagnostics(page)).camera_zoom - initialCamera) > .02)
      throw Error('Inventory scroll must not zoom world camera');
    await clickGodot(page,d.silver.actions.SilverNextPage);
    await page.waitForFunction(()=>window.leoDiagnostics.silver.page === 2,null,{timeout:15000});
    d=await diagnostics(page);
    if(d.silver.slots !== 100)throw Error('Second inventory page does not contain 100 slots');
    await clickGodot(page,d.silver.actions.SilverPrevPage);
    await page.waitForFunction(()=>window.leoDiagnostics.silver.page === 1,null,{timeout:15000});
    for(const [button,mode] of [['SilverNavStorage','Storage'],['SilverNavTrade','Trade'],['SilverNavQuest','Quest']]){
      d=await diagnostics(page);
      await clickGodot(page,d.silver.actions[button]);
      await page.waitForFunction(m=>window.leoDiagnostics.silver.extension && window.leoDiagnostics.silver.mode === m,mode,{timeout:15000});
    }
    d=await diagnostics(page);
    if (d.silver.main_rect[0] + d.silver.main_rect[2] > d.silver.extension_rect[0]+2)
      throw Error('Extension overlaps the main panel');
    await page.screenshot({path:'build/leo-inventory-extension-desktop.png'});
    await closeBag(page);
    await page.mouse.move(700,400);
    await page.mouse.wheel(0,-300);
    await page.waitForFunction(z=>window.leoDiagnostics.camera_zoom < z,initialCamera,{timeout:15000});
    await page.screenshot({path:'build/leo-desktop.png'});
    // Existing GM controls remain available.
    d=await diagnostics(page);
    await clickGodot(page,[d.gm_button_rect[0]+d.gm_button_rect[2]/2,d.gm_button_rect[1]+d.gm_button_rect[3]/2]);
    await page.waitForFunction(()=>window.leoDiagnostics.panel==='GM',null,{timeout:15000});
    await page.screenshot({path:'build/leo-offline-gm-restored.png'});
    await page.keyboard.press('Escape');
    await page.waitForFunction(()=>window.leoDiagnostics.panel==='',null,{timeout:15000});
    // At large desktop sizes, the inventory retains its correct internal model.
    await page.setViewportSize({width:1920,height:1080});
    await page.waitForFunction(()=>window.leoDiagnostics.screen_size[0]===1920,null,{timeout:15000});
    await openBag(page);
    d=await diagnostics(page);
    if(d.silver.slots!==100 || d.silver.equipment!==14 || d.silver.extension)
      throw Error('Resized desktop inventory lost controls');
    await closeBag(page);
    await context.close();
    // Landscape touch.
    const mobile=await browser.newContext({viewport:{width:1280,height:720},isMobile:true,hasTouch:true});
    const touchPage=await mobile.newPage();currentPage=touchPage;
    touchPage.on('pageerror',e=>errors.push('Landscape touch: '+e.message));
    await touchPage.goto(URL);
    await touchPage.waitForFunction(()=>window.leoDiagnostics,null,{timeout:60000});
    await openBag(touchPage);
    d=await diagnostics(touchPage);
    if(!d.silver.open || d.silver.slots!==100 || d.silver.equipment!==14)
      throw Error('Landscape mobile Bag failed');
    await touchPage.screenshot({path:'build/leo-mobile.png'});
    await closeBag(touchPage);
    await mobile.close();
    // Portrait 430x932.
    const portrait=await browser.newContext({viewport:{width:430,height:932},isMobile:true,hasTouch:true});
    const portraitPage=await portrait.newPage();currentPage=portraitPage;
    portraitPage.on('pageerror',e=>errors.push('Portrait: '+e.message));
    await portraitPage.goto(URL);
    await portraitPage.waitForFunction(()=>window.leoDiagnostics?.orientation==='portrait',null,{timeout:60000});
    // Portrait GridContainer icons and editable Thai Label overlays remain touch-sized.
    await portraitPage.waitForFunction(()=>window.leoMainRichNav?.native_grid && window.leoMainRichNav.buttons.Bag[2] > 0,null,{timeout:15000});
    const portraitNav = await portraitPage.evaluate(()=>window.leoMainRichNav);
    const portraitDiag = await diagnostics(portraitPage);
    const portraitSettings = await portraitPage.evaluate(()=>window.leoSettingsRich);
    const sameY=[portraitDiag.gm_button_rect,portraitSettings.header,...['Bag','Menu','Guild','Party','Friends','Notice'].map(k=>portraitNav.buttons[k])];
    if(sameY.some(r=>Math.abs(r[1]-sameY[0][1])>3))
      throw Error('Portrait eight-button nav must stay on one horizontal level: '+JSON.stringify(sameY));
    const mobileIconWidth = portraitNav.buttons.Bag[2] * portraitDiag.screen_size[0] / portraitDiag.viewport_size[0];
    if (mobileIconWidth < 35 || mobileIconWidth > 95)
      throw Error('New main icon must be touch-sized on portrait phones: '+JSON.stringify({mobileIconWidth,portraitNav,portraitDiag}));
    await portraitPage.screenshot({path:'build/leo-portrait.png'});
    const touchBag = portraitNav.buttons.Bag;
    await clickGodot(portraitPage,[touchBag[0]+touchBag[2]/2,touchBag[1]+touchBag[3]/2]);
    await portraitPage.waitForFunction(()=>window.leoMainRichNav?.menu==='Bag',null,{timeout:15000});
    await portraitPage.screenshot({path:'build/leo-portrait-rich-bag.png'});
    await clickGodot(portraitPage,[touchBag[0]+touchBag[2]/2,touchBag[1]+touchBag[3]/2]);
    await portraitPage.waitForFunction(()=>window.leoMainRichNav?.open===false,null,{timeout:15000});
    await openBag(portraitPage);
    d=await diagnostics(portraitPage);
    if(d.silver.slots!==100 || d.silver.equipment!==14 || d.silver.extension)
      throw Error('Portrait silver inventory not initialized: '+JSON.stringify(d.silver));
    await portraitPage.screenshot({path:'build/leo-portrait-bag.png'});
    await closeBag(portraitPage);
    await portrait.close();
    if(errors.length)throw Error(errors.join('\n'));
    completed=true;
    console.log('BROWSER TESTS: silver inventory 100+100, 14 equipment slots, 3 extension modes, GM, camera input, desktop, landscape touch and portrait passed');
  } finally {
    if(!completed && currentPage && !currentPage.isClosed()){
      try{
        console.log('FAILURE_DIAGNOSTICS',JSON.stringify(await diagnostics(currentPage)));
        await currentPage.screenshot({path:'build/browser-failure.png'});
      }catch(e){console.log('Could not capture failure screenshot',e.message);}
      console.log('FAILURE_ERRORS',JSON.stringify(errors));
    }
    if(browser)await browser.close();
    server.kill();
  }
})().catch(e=>{console.error(e);process.exit(1)});
