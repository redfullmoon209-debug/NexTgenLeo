const { chromium } = require('playwright');
const { spawn } = require('child_process');

const URL = 'http://127.0.0.1:8060';
async function diagnostics(page) {
  return page.evaluate(() => window.leoDiagnostics);
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
    await page.locator('canvas').click({position:{x:600,y:400}});
    await openBag(page);
    let d = await diagnostics(page);
    if (!d.silver.open || d.silver.extension || d.silver.slots !== 100 || d.silver.pages !== 2 || d.silver.equipment !== 14)
      throw Error('Silver Bag did not render seven parallel equipment pairs and 100 slots: '+JSON.stringify(d.silver));
    if (d.silver.menus !== 14 || d.silver.menu_icons !== 14 || d.silver.accessories !== 5)
      throw Error('Sidebar must have 14 original PNG icons and jewelry row needs five slots: '+JSON.stringify(d.silver));
    if (!d.silver.portrait_meshes || d.silver.portrait_meshes < 6)
      throw Error('Live character preview is missing its meshes');
    const portrait=d.silver.portrait_rect;
    const warrior=d.silver.warrior_rects.hat;
    const fashion=d.silver.fashion_rects.fashion_hat;
    if(!warrior||!fashion||warrior[0]+warrior[2]>portrait[0]+2 || fashion[0]<portrait[0]+portrait[2]-2)
      throw Error('Warrior equipment must be LEFT of portrait and fashion RIGHT: '+JSON.stringify({warrior,portrait,fashion}));
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
    await portraitPage.screenshot({path:'build/leo-portrait.png'});
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
