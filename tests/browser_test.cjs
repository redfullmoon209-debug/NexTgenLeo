const { chromium } = require('playwright');
const {spawn} = require('child_process');
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
 await page.locator('canvas').click({position:{x:600,y:400}});
 await page.keyboard.down('w');try{await page.waitForFunction(s=>Math.hypot(window.leoDiagnostics.position[0]-s[0],window.leoDiagnostics.position[2]-s[2])>1.2,start.position,{timeout:20000});}finally{await page.keyboard.up('w');}
 let moved=await page.evaluate(()=>window.leoDiagnostics);
 if(Math.hypot(moved.position[0]-start.position[0],moved.position[2]-start.position[2])<1)throw Error('WASD failed');
 await page.mouse.click(55,305);await page.waitForFunction(()=>window.leoDiagnostics.panel==='Bag',null,{timeout:15000});
 const drawer=await page.evaluate(()=>window.leoDiagnostics);
 if(drawer.drawer_rect[0]>16||drawer.drawer_rect[1]>16||drawer.drawer_rect[2]<540||drawer.drawer_rect[2]>620||drawer.drawer_rect[3]<680||drawer.drawer_rect[3]>710||drawer.drawer_z<50)throw Error('Full-height narrow bag geometry failed: '+JSON.stringify(drawer.drawer_rect));
 if(drawer.drawer_rect[1]+drawer.drawer_rect[3]>720||drawer.drawer_rect[1]+drawer.drawer_rect[3]<700)throw Error('Bag does not reach viewport bottom: '+JSON.stringify(drawer.drawer_rect));
 if(drawer.drawer_rect[0]+drawer.drawer_rect[2]>drawer.player_screen[0]-20)throw Error('Inventory panel obscures the 3D player: '+JSON.stringify(drawer));
 if(!(drawer.bag_left_rect[0]+drawer.bag_left_rect[2]<=drawer.bag_right_rect[0]+1)&&drawer.bag_left_rect[2]>0)throw Error('Character pane must stay left of inventory: '+JSON.stringify(drawer));
 if(drawer.bag_right_rect[0]<200||drawer.bag_right_rect[0]>355||drawer.bag_columns!==5)throw Error('Inventory must occupy compact right column: '+JSON.stringify(drawer));
 if(drawer.bag_preview_parts<6||drawer.bag_preview_rect[2]<150||drawer.bag_preview_rect[3]<150)throw Error('Left character 3D preview is missing or too small: '+JSON.stringify(drawer));
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
 await page.mouse.click(240,393);await page.waitForFunction(()=>window.leoDiagnostics.panel==='GM',null,{timeout:15000});
 for(const [kind,expected] of [['gender','Female'],['job','forest_lord'],['faction','Dark']]){
  await page.waitForFunction(k=>!!window.leoDiagnostics.gm_controls[k],kind,{timeout:15000});
  const point=(await page.evaluate(()=>window.leoDiagnostics)).gm_controls[kind];
  if(point[0]<12||point[0]>400)throw Error('GM dropdown outside left drawer: '+kind+' '+JSON.stringify(point));
  await page.mouse.click(point[0],point[1]);
  await page.waitForFunction(k=>window.leoDiagnostics.gm_popups[k].visible,kind,{timeout:15000});
  const popup=(await page.evaluate(()=>window.leoDiagnostics)).gm_popups[kind];
  await page.mouse.click(popup.position[0]+popup.size[0]/2,popup.position[1]+popup.size[1]-14);
  await page.waitForFunction(({k,v})=>window.leoDiagnostics[k]===v,{k:kind,v:expected},{timeout:15000});
 }
 await page.waitForFunction(()=>window.leoDiagnostics.class_rank>=7,null,{timeout:15000});
 console.log('GM BROWSER TESTS: choose Female, profession and Dark via dropdowns passed');
 await page.keyboard.press('Escape');await page.waitForFunction(()=>window.leoDiagnostics.panel==='',null,{timeout:15000});
 await page.screenshot({path:'build/leo-desktop.png'});
 console.log(JSON.stringify({start,moved,bag:bag.panel,zoom:zoomed.camera_zoom,target:target.target,logs},null,2));
 await page.setViewportSize({width:1920,height:1080});
 await page.waitForFunction(()=>window.leoDiagnostics.screen_size[0]===1920,null,{timeout:15000});
 await page.mouse.click(55*1.5,305*1.5);await page.waitForFunction(()=>window.leoDiagnostics.panel==='Bag',null,{timeout:15000});
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
 console.log('BROWSER TESTS: PC movement, menu, wheel, target, mobile joystick, concurrent action touch, release, pinch passed');
 }finally{if(!completed && currentPage && !currentPage.isClosed()){console.log('FAILURE_DIAGNOSTICS',JSON.stringify(await currentPage.evaluate(()=>window.leoDiagnostics||{status:document.body.innerText})));console.log('FAILURE_LOGS',JSON.stringify(logs));await currentPage.screenshot({path:'build/browser-failure.png'});}if(browser)await browser.close();server.kill();}
})().catch(e=>{console.error(e);process.exit(1)});
