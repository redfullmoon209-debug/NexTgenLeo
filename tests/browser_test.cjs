const { chromium } = require('playwright');
const {spawn} = require('child_process');
async function openPlayerMenu(page,entryName){
 const old=await page.evaluate(()=>window.leoDiagnostics);
 const sx=old.screen_size[0]/old.viewport_size[0];
 const sy=old.screen_size[1]/old.viewport_size[1];
 const [x,y,w,h]=old.menu_button_rect;
 await page.mouse.click((x+w/2)*sx,(y+h/2)*sy);
 await page.waitForFunction(()=>window.leoDiagnostics.menu_open,null,{timeout:15000});
 const opened=await page.evaluate(()=>window.leoDiagnostics);
 if(!opened.gm_button_visible)throw Error('Offline sandbox should show red local GM test orb');
 if(opened.menu_dropdown_rect[0]+opened.menu_dropdown_rect[2]>opened.viewport_size[0]-180)throw Error('Dropdown overlaps minimap');
 if(!opened.menu_entry_rects[entryName])throw Error('Player menu missing '+entryName);
 if(entryName==='Bag' && opened.screen_size[0]===1280)
  await page.screenshot({path:'build/leo-yellow-main-dropdown.png'});
 const point=opened.menu_entry_rects[entryName];
 await page.mouse.click(point[0]*sx,point[1]*sy);
 await page.waitForFunction(name=>window.leoDiagnostics.panel===name,entryName,{timeout:15000});
}
(async()=>{
 const server=spawn('python',['-m','http.server','8060','--bind','127.0.0.1','--directory','build/web']);
 let browser; let currentPage; let completed=false;
 const logs=[];
 try{
 browser=await chromium.launch({headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:{width:1280,height:720}});
 const page=await context.newPage();currentPage=page;
 page.on('console',m=>logs.push({type:m.type(),text:m.text()}));page.on('pageerror',e=>logs.push({type:'pageerror',text:e.message}));
 await page.goto('http://127.0.0.1:8060');
 await page.waitForFunction(()=>window.leoDiagnostics,null,{timeout:60000});
 let start=await page.evaluate(()=>window.leoDiagnostics);
 if(!start.gm_button_visible)throw Error('Offline red GM test button is missing');
 if(!(start.gm_button_rect[0]<start.menu_button_rect[0] && start.gm_button_rect[1]===start.menu_button_rect[1]))throw Error('Red GM button must sit immediately left of gold menu: '+JSON.stringify(start));
 await page.locator('canvas').click({position:{x:600,y:400}});
 await page.keyboard.down('w');try{await page.waitForFunction(s=>Math.hypot(window.leoDiagnostics.position[0]-s[0],window.leoDiagnostics.position[2]-s[2])>1.2,start.position,{timeout:20000});}finally{await page.keyboard.up('w');}
 let moved=await page.evaluate(()=>window.leoDiagnostics);
 if(Math.hypot(moved.position[0]-start.position[0],moved.position[2]-start.position[2])<1)throw Error('WASD failed');
 const [gx,gy,gw,gh]=start.gm_button_rect;
 await page.mouse.click(gx+gw/2,gy+gh/2);
 await page.waitForFunction(()=>window.leoDiagnostics.panel==='GM',null,{timeout:15000});
 const offlineGM=await page.evaluate(()=>window.leoDiagnostics);
 if(Object.keys(offlineGM.gm_controls||{}).length!==3)throw Error('Offline GM selectors unavailable');
 await page.screenshot({path:'build/leo-offline-gm-restored.png'});
 await page.keyboard.press('Escape');
 await page.waitForFunction(()=>window.leoDiagnostics.panel==='',null,{timeout:15000});
 await openPlayerMenu(page,'Bag');
 const drawer=await page.evaluate(()=>window.leoDiagnostics);
 if(drawer.drawer_rect[0]>16||drawer.drawer_rect[1]>16||drawer.drawer_rect[2]<540||drawer.drawer_rect[2]>620||drawer.drawer_rect[3]<680||drawer.drawer_rect[3]>710||drawer.drawer_z<50)throw Error('Full-height narrow bag geometry failed: '+JSON.stringify(drawer.drawer_rect));
 if(drawer.drawer_rect[1]+drawer.drawer_rect[3]>720||drawer.drawer_rect[1]+drawer.drawer_rect[3]<700)throw Error('Bag does not reach viewport bottom: '+JSON.stringify(drawer.drawer_rect));
 if(drawer.drawer_rect[0]+drawer.drawer_rect[2]>drawer.player_screen[0]-20)throw Error('Inventory panel obscures the 3D player: '+JSON.stringify(drawer));
 if(!(drawer.bag_left_rect[0]+drawer.bag_left_rect[2]<=drawer.bag_right_rect[0]+1)&&drawer.bag_left_rect[2]>0)throw Error('Character pane must stay left of inventory: '+JSON.stringify(drawer));
 if(drawer.bag_right_rect[0]<200||drawer.bag_right_rect[0]>355||drawer.bag_columns!==5)throw Error('Inventory must occupy compact right column: '+JSON.stringify(drawer));
 if(drawer.bag_preview_parts<6||drawer.bag_preview_rect[2]<90||drawer.bag_preview_rect[3]<180)throw Error('Center character 3D preview is missing or too small: '+JSON.stringify(drawer));
 if(drawer.bag_equipment_count!==19||drawer.bag_equipment_visible!==19)throw Error('All nineteen equipment slots must fit on screen: '+JSON.stringify(drawer));
 const equip=drawer.bag_equipment_rects;
 const region=drawer.bag_equipment_regions;
 const order=['hat','shirt','gloves','pants','shoes'];
 const accessory=['ring','bracelet_left','accessory','bracelet_right','ring_right'];
 const fashion=['fashion_hat','fashion_shirt','fashion_gloves','fashion_pants','fashion_shoes'];
 for(const [id,area] of [...order.map(id=>[id,'armor']),...['weapon','weapon_left'].map(id=>[id,'weapon']),['mount','mount'],['loot_pet','pet'],...accessory.map(id=>[id,'jewelry']),...fashion.map(id=>[id,'fashion'])]){
  if(!equip[id]||region[id]!==area)throw Error('Missing equipment region: '+id+' '+JSON.stringify(region));
 }
 for(let i=1;i<order.length;i++)if(equip[order[i]][1]<=equip[order[i-1]][1])throw Error('Armor needs to descend vertically on the right');
 if(equip.weapon[0]+equip.weapon[2]>drawer.bag_preview_rect[0]+2||equip.weapon_left[0]+equip.weapon_left[2]>drawer.bag_preview_rect[0]+2)throw Error('Weapons not left of character preview');
 if(equip.hat[0]<drawer.bag_preview_rect[0]+drawer.bag_preview_rect[2]-2)throw Error('Armor not right of the character preview');
 if(equip.mount[1]<=equip.weapon_left[1]||equip.loot_pet[1]<=equip.mount[1])throw Error('Mount and loot pet must follow weapons downwards');
 for(const row of [accessory,fashion]){
   for(let i=1;i<row.length;i++)if(equip[row[i]][0]<=equip[row[i-1]][0])throw Error('Equipment row must read left to right: '+row);
 }
 if(equip.fashion_hat[1]<=equip.ring[1])throw Error('Fashion row should be below jewelry row');
 if(drawer.bag_preview_rect[0]<drawer.bag_left_rect[0]||drawer.bag_preview_rect[0]+drawer.bag_preview_rect[2]>drawer.bag_left_rect[0]+drawer.bag_left_rect[2]+2)throw Error('Player preview spills outside stat pane');
 if(drawer.drawer_close[0]<12||drawer.drawer_close[0]>drawer.drawer_rect[0]+drawer.drawer_rect[2])throw Error('Close button is outside the bag window');
 await page.screenshot({path:'build/leo-dual-bag-desktop.png'});
 await page.mouse.click(...drawer.drawer_close);await page.waitForFunction(()=>window.leoDiagnostics.panel==='',null,{timeout:15000});
 for(const [button,x] of [['left',340],['right',780]]){
  const beforeYaw=(await page.evaluate(()=>window.leoDiagnostics)).yaw;
  await page.mouse.move(x,460);await page.mouse.down({button});await page.mouse.move(x+130,470,{steps:8});await page.mouse.up({button});
  await page.waitForFunction(y=>Math.abs(window.leoDiagnostics.yaw-y)>.2,beforeYaw,{timeout:15000});
 }
 await page.keyboard.press('b');await page.waitForFunction(()=>window.leoDiagnostics.panel==='Bag',null,{timeout:15000});
 let bag=await page.evaluate(()=>window.leoDiagnostics);if(bag.panel!=='Bag')throw Error('Bag menu failed');
 await page.keyboard.press('Escape');await page.waitForFunction(()=>window.leoDiagnostics.panel==='',null,{timeout:15000});await page.mouse.move(700,400);await page.mouse.wheel(0,-300);await page.waitForFunction(z=>window.leoDiagnostics.camera_zoom<z,start.camera_zoom,{timeout:15000});
 let zoomed=await page.evaluate(()=>window.leoDiagnostics);if(zoomed.camera_zoom>=start.camera_zoom)throw Error('Wheel zoom failed');
 await page.keyboard.press('Tab');await page.waitForFunction(()=>window.leoDiagnostics.target>=0,null,{timeout:15000});
 let target=await page.evaluate(()=>window.leoDiagnostics);if(target.target<0)throw Error('Target select failed');
 await openPlayerMenu(page,'Settings');
 const publicSettings=await page.evaluate(()=>window.leoDiagnostics);
 if(!publicSettings.gm_button_visible||Object.keys(publicSettings.menu_entry_rects).includes('GM'))throw Error('Offline GM must be a separate red button, not a player dropdown item');
 console.log('OFFLINE UI TESTS: gold dropdown navigation and separate red GM test button pass');
 await page.keyboard.press('Escape');await page.waitForFunction(()=>window.leoDiagnostics.panel==='',null,{timeout:15000});
 await page.screenshot({path:'build/leo-desktop.png'});
 console.log(JSON.stringify({start,moved,bag:bag.panel,zoom:zoomed.camera_zoom,target:target.target,logs},null,2));
 await page.setViewportSize({width:1920,height:1080});
 await page.waitForFunction(()=>window.leoDiagnostics.screen_size[0]===1920,null,{timeout:15000});
 await openPlayerMenu(page,'Bag');
 const wideBag=await page.evaluate(()=>window.leoDiagnostics);
 if(wideBag.bag_right_rect[0]<=wideBag.bag_left_rect[0])throw Error('1920 wide bag is not split');
 // Godot may keep its 1280x720 virtual viewport when Chromium is resized.
 // Verify the dock against Godot's actual viewport, not the browser's CSS size.
 if(wideBag.drawer_rect[2]>620||wideBag.drawer_rect[3]<wideBag.viewport_size[1]-30||wideBag.drawer_rect[0]+wideBag.drawer_rect[2]>wideBag.player_screen[0]-20)throw Error('Resized-browser bag does not fill Godot viewport or hides avatar: '+JSON.stringify(wideBag));
 if(wideBag.drawer_rect[1]+wideBag.drawer_rect[3]>wideBag.viewport_size[1]-8)throw Error('Bag extends outside Godot viewport: '+JSON.stringify(wideBag));
 await page.keyboard.press('Escape');await page.waitForFunction(()=>window.leoDiagnostics.panel==='',null,{timeout:15000});
 console.log('MOUSE TESTS: native menu clicks, close, left/right world drag, 1920x1080 click passed');
 await context.close();
 const mobile=await browser.newContext({viewport:{width:1280,height:720},isMobile:true,hasTouch:true});
 const p=await mobile.newPage();currentPage=p;p.on('console',m=>{if(m.type()==='error')logs.push({type:'mobile-error',text:m.text()})});
 await p.goto('http://127.0.0.1:8060');await p.waitForFunction(()=>window.leoDiagnostics,null,{timeout:60000});
 const cdp=await mobile.newCDPSession(p);
 const touch=(type,points)=>cdp.send('Input.dispatchTouchEvent',{type,touchPoints:points.map(([id,x,y])=>({id,x,y}))});
 const mstart=await p.evaluate(()=>window.leoDiagnostics);
 if(!mstart.gm_button_visible)throw Error('Mobile offline GM button is missing');
 const [mx,my,mw,mh]=mstart.menu_button_rect;
 await p.touchscreen.tap(mx+mw/2,my+mh/2);
 await p.waitForFunction(()=>window.leoDiagnostics.menu_open,null,{timeout:15000});
 const mobileMenu=await p.evaluate(()=>window.leoDiagnostics);
 const point=mobileMenu.menu_entry_rects.Bag;
 if(!point)throw Error('Touch menu has no Bag item');
 await p.touchscreen.tap(point[0],point[1]);
 await p.waitForFunction(()=>window.leoDiagnostics.panel==='Bag',null,{timeout:15000});
 await p.keyboard.press('Escape');
 await p.waitForFunction(()=>window.leoDiagnostics.panel==='',null,{timeout:15000});
 await p.touchscreen.tap(980,500);await p.waitForFunction(()=>window.leoDiagnostics.target>=0,null,{timeout:15000});
 await touch('touchStart',[[1,90,610]]);await touch('touchMove',[[1,135,610]]);await p.waitForFunction(()=>window.leoDiagnostics.joystick[0]>.3,null,{timeout:15000});
 let stick=await p.evaluate(()=>window.leoDiagnostics);
 await touch('touchStart',[[1,135,610],[2,1180,500]]);await p.waitForFunction(()=>window.leoDiagnostics.attacking && window.leoDiagnostics.joystick[0]>.3,null,{timeout:15000});
 let multitouch=await p.evaluate(()=>window.leoDiagnostics);
 await touch('touchEnd',[]);await p.waitForFunction(()=>Math.abs(window.leoDiagnostics.joystick[0])<.01,null,{timeout:15000});
 let released=await p.evaluate(()=>window.leoDiagnostics);
 if(Math.abs(stick.joystick[0])<.3)throw Error('Mobile joystick failed');
 if(Math.abs(multitouch.joystick[0])<.3)throw Error('Second finger stole joystick');
 if(Math.abs(released.joystick[0])>.01)throw Error('Joystick release failed');
 await touch('touchStart',[[3,700,230],[4,880,230]]);
 await touch('touchMove',[[3,700,230],[4,900,230]]);await p.waitForTimeout(50);
 await touch('touchMove',[[3,700,230],[4,1000,230]]);await p.waitForFunction(z=>window.leoDiagnostics.camera_zoom<z,mstart.camera_zoom,{timeout:15000});
 const pinch=await p.evaluate(()=>window.leoDiagnostics);
 await touch('touchEnd',[]);
 if(pinch.camera_zoom>=mstart.camera_zoom)throw Error('Pinch zoom failed');
 if(pinch.player_screen[1]<100 || pinch.player_screen[1]>600)throw Error('Zoom moves player out of frame');
 await p.screenshot({path:'build/leo-mobile.png'});
 console.log(JSON.stringify({mobile:{mstart,stick,multitouch,released,pinch},errors:logs.filter(x=>['error','pageerror','mobile-error'].includes(x.type))},null,2));
 const errors=logs.filter(x=>x.type==='pageerror'||(x.type==='error' && /SCRIPT ERROR|Parse Error|ERROR:/.test(x.text)));
 if(errors.length)throw Error(JSON.stringify(errors));
 completed=true;
 console.log('BROWSER TESTS: PC movement, offline red GM, gold dropdown, touch dropdown, mobile joystick, concurrent action touch, release, pinch passed');
 }finally{if(!completed && currentPage && !currentPage.isClosed()){console.log('FAILURE_DIAGNOSTICS',JSON.stringify(await currentPage.evaluate(()=>window.leoDiagnostics||{status:document.body.innerText})));console.log('FAILURE_LOGS',JSON.stringify(logs));await currentPage.screenshot({path:'build/browser-failure.png'});}if(browser)await browser.close();server.kill();}
})().catch(e=>{console.error(e);process.exit(1)});
