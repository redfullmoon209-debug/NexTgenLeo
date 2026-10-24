"""NexTgenLeo development authority. Run behind TLS for remote browser testing.
SQLite transactions serialize every economy mutation. Client supplies intentions only.
Not production authentication: opaque guest tokens are bearer credentials.
"""
import asyncio
import hashlib
import json
import math
import os
from pathlib import Path
import secrets
import sqlite3
import time
from aiohttp import web, WSMsgType

ROOT = Path(__file__).resolve().parents[1]
BALANCE = json.loads((ROOT / 'data/balance.json').read_text())

class Rejected(ValueError):
    pass

class Authority:
    def __init__(self, db_path='characters.sqlite3', clock=time.monotonic):
        self.db = sqlite3.connect(db_path)
        self.db.execute('PRAGMA journal_mode=WAL')
        self.db.executescript('''CREATE TABLE IF NOT EXISTS characters
            (id TEXT PRIMARY KEY, token_hash TEXT UNIQUE, state TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS receipts
            (player TEXT, request TEXT, response TEXT, PRIMARY KEY(player,request));''')
        self.clock = clock
        self.players = {}
        self.mobs = []
        for i in range(14):
            level = 1 + i % 3
            self.mobs.append(dict(id=i, x=math.cos(i*2.4)*(10+i%4*4), z=math.sin(i*2.4)*(10+i%4*4),
                                  hp=60+level*12, max_hp=60+level*12, level=level, respawn=0))
        self.homes = [(m['x'],m['z']) for m in self.mobs]
        self.cooldowns = {}
        self.movement_times = {}
        self.movement_credit = {}
        self.attack_times = {}
        self.last_tick = self.clock()

    @staticmethod
    def digest(token):
        return hashlib.sha256(token.encode()).hexdigest()

    def login(self, token=None):
        if token:
            row = self.db.execute('SELECT id,state FROM characters WHERE token_hash=?',(self.digest(token),)).fetchone()
            if not row:
                raise Rejected('Invalid session token')
            player_id, raw = row
            state = json.loads(raw)
        else:
            token = secrets.token_urlsafe(32)
            player_id = secrets.token_hex(8)
            state = dict(id=player_id, x=0.0,z=0.0,hp=100,stamina=100.0,level=1,class_rank=0,exp=0,
                         gold=150,cash=0,inventory=[dict(id='potion',count=5,enhancement=0)],equipped={},
                         quest_state='available',quest_kills=0,selected_element='',selected_job='',faction='',
                         skill_loadout=[0,1,2],party='',guild='',pet_level=1,pet_exp=0,pet_enabled=True)
            with self.db:
                self.db.execute('INSERT INTO characters VALUES (?,?,?)',(player_id,self.digest(token),json.dumps(state)))
        if player_id in self.players:
            raise Rejected('Session already connected')
        self.players[player_id] = state
        self.movement_times[player_id] = self.clock()
        self.movement_credit[player_id] = 0.6
        return token,state

    def save(self, player_id):
        self.db.execute('UPDATE characters SET state=? WHERE id=?',(json.dumps(self.players[player_id]),player_id))

    def disconnect(self, player_id):
        if player_id in self.players:
            with self.db:
                self.save(player_id)
            del self.players[player_id]
            self.movement_times.pop(player_id,None)
            self.cooldowns.pop(player_id,None)

    @staticmethod
    def add_item(state,item_id,count=1):
        item = BALANCE['items'].get(item_id)
        if not item or not isinstance(count,int) or isinstance(count,bool) or count < 1 or count > 99:
            raise Rejected('Invalid item or quantity')
        bag = state['inventory']
        limit = item['stack']
        capacity = (200-len(bag))*limit + sum(limit-s['count'] for s in bag if s['id']==item_id)
        if capacity < count:
            raise Rejected('Bag full')
        for slot in bag:
            if slot['id']==item_id:
                n=min(count,limit-slot['count']);slot['count']+=n;count-=n
        while count:
            n=min(count,limit);bag.append(dict(id=item_id,count=n,enhancement=0));count-=n

    def command(self, player_id, message):
        if not isinstance(message,dict):
            raise Rejected('Object expected')
        request = message.get('request')
        if not isinstance(request,str) or not 1 <= len(request) <= 80:
            raise Rejected('Request ID required')
        previous = self.db.execute('SELECT response FROM receipts WHERE player=? AND request=?',(player_id,request)).fetchone()
        if previous:
            return json.loads(previous[0])
        state=self.players[player_id]
        before=json.loads(json.dumps(state))
        mobs_before=json.loads(json.dumps(self.mobs))
        cooldown_before=dict(self.cooldowns.get(player_id,{}))
        move_before=self.movement_times.get(player_id,self.clock())
        credit_before=self.movement_credit.get(player_id,0.6)
        try:
            with self.db:
                result=self._apply(state,message)
                self.save(player_id)
                response={'type':'result','request':request,'ok':True,'message':result}
                self.db.execute('INSERT INTO receipts VALUES (?,?,?)',(player_id,request,json.dumps(response)))
            return response
        except Exception:
            self.players[player_id]=before
            self.mobs=mobs_before
            self.cooldowns[player_id]=cooldown_before
            self.movement_times[player_id]=move_before
            self.movement_credit[player_id]=credit_before
            raise

    @staticmethod
    def integer(value,minimum,maximum):
        if type(value) is not int or not minimum <= value <= maximum:
            raise Rejected('Invalid integer')
        return value

    def _apply(self,s,m):
        op=m.get('op')
        now=self.clock()
        if op=='move':
            x,z=m.get('x'),m.get('z')
            if type(x) not in (int,float) or type(z) not in (int,float) or not math.isfinite(x) or not math.isfinite(z):
                raise Rejected('Invalid position')
            elapsed=min(1,max(0,now-self.movement_times[s['id']]))
            credit=min(1.5,self.movement_credit.get(s['id'],0.6)+8.5*elapsed)
            distance=math.hypot(x-s['x'],z-s['z'])
            if abs(x)>38 or abs(z)>38 or distance > credit or s['hp']<=0:
                raise Rejected('Movement rejected')
            self.movement_credit[s['id']]=credit-distance
            s['x'],s['z']=x,z
            self.movement_times[s['id']]=now
        elif op=='buy':
            item_id=m.get('item'); item=BALANCE['items'].get(item_id)
            if not item or item.get('cash'):
                raise Rejected('Item unavailable for online test')
            count=self.integer(m.get('count',1),1,99)
            price=item['price']*count
            if s['gold']<price:
                raise Rejected('Insufficient Gold')
            self.add_item(s,item_id,count);s['gold']-=price
        elif op in ('sell','use','equip'):
            index=self.integer(m.get('slot'),0,len(s['inventory'])-1)
            slot=s['inventory'][index]; item=BALANCE['items'][slot['id']]
            count=self.integer(m.get('count',1),1,slot['count'])
            if op=='sell':
                s['gold']+=item['sell']*count;slot['count']-=count
            elif op=='equip' and item['kind']=='equipment':
                old=s['equipped'].get(item['slot'])
                s['equipped'][item['slot']]=dict(slot);s['equipped'][item['slot']]['count']=1
                slot['count']-=1
                if old:
                    self.add_item(s,old['id'])
            elif op=='use' and item['kind'] in ('heal','stamina') and s['hp']>0:
                key='hp' if item['kind']=='heal' else 'stamina'
                s[key]=min(self.max_hp(s) if key=='hp' else 100,s[key]+item['value']);slot['count']-=1
            else:
                raise Rejected('Invalid item operation')
            s['inventory']=[v for v in s['inventory'] if v['count']>0]
        elif op=='attack':
            if s['hp']<=0: raise Rejected('Dead')
            index=self.integer(m.get('target'),0,len(self.mobs)-1)
            skill_index=self.integer(m.get('skill',0),0,3)
            skill=BALANCE['skills'][skill_index]
            if skill_index>0 and s['class_rank']>=3 and s['selected_element']:
                source=skill_index-1 if s['class_rank']>=5 else s.get('skill_loadout',[0,1,2])[skill_index-1]
                skill=BALANCE['element_skills'][s['selected_element']][source]
            mob=self.mobs[index]
            reach=skill['range']; interval=skill['cooldown']
            job=next((j for j in BALANCE['professions'] if j['id']==s['selected_job']),None)
            if skill_index==0 and job: reach=job['range'];interval=job['interval']
            cooldown=self.cooldowns.setdefault(s['id'],{})
            if mob['hp']<=0 or math.hypot(s['x']-mob['x'],s['z']-mob['z'])>reach:
                raise Rejected('Target out of range')
            if cooldown.get(skill_index,0)>now or s['stamina']<skill['cost']:
                raise Rejected('Cooldown or stamina')
            s['stamina']-=skill['cost'];cooldown[skill_index]=now+interval
            # Server owns damage, loot, EXP. No client damage, Gold, or EXP field is read.
            damage=max(1,int((18+s['level']*3+s['class_rank']*25)*skill['power'])-mob['level']*2)
            victims=[mob]
            if skill['radius']:
                victims += [v for v in self.mobs if v is not mob and v['hp']>0 and math.hypot(v['x']-mob['x'],v['z']-mob['z'])<=skill['radius']]
            for victim in victims:
                victim['hp']=max(0,victim['hp']-damage)
                if victim['hp']==0:
                    victim['respawn']=now+12
                    s['gold']+=5+victim['level'];self.gain_exp(s,35+victim['level']*10)
                    try: self.add_item(s,'herb')
                    except Rejected: pass
                    if s['quest_state']=='active':s['quest_kills']=min(5,s['quest_kills']+1)
            return f'Damage {damage}'
        elif op=='quest':
            if math.hypot(s['x']+5,s['z']+4)>4: raise Rejected('Move near Elara')
            if s['quest_state']=='available':s['quest_state']='active'
            elif s['quest_state']=='active' and s['quest_kills']>=5:
                s['quest_state']='complete';s['gold']+=100;self.gain_exp(s,300)
            else: raise Rejected('Quest requirements not met')
        elif op=='advance':
            if s['level']!=100 or s['class_rank']>=10 or (s['class_rank']<=2 and s['quest_state']!='complete'):
                raise Rejected('Advancement requirements not met')
            s['class_rank']+=1;s['level']=1;s['exp']=0
            if s['class_rank']<=2:s['quest_state']='available';s['quest_kills']=0
            s['hp']=self.max_hp(s)
        elif op=='element':
            if s['class_rank']<3 or m.get('value') not in BALANCE['elements']:raise Rejected('Element locked')
            if s['selected_element'] and s['selected_element']!=m['value']:raise Rejected('Element already chosen')
            s['selected_element']=m['value']
        elif op=='job':
            job=next((j for j in BALANCE['professions'] if j['id']==m.get('value')),None)
            if s['class_rank']<5 or not job or job['element']!=s['selected_element']:raise Rejected('Profession locked')
            if s['selected_job']:
                if s['selected_job']!=job['id']:raise Rejected('Profession already chosen')
                return 'Already selected'
            if 'weapon' in s['equipped']:
                if len(s['inventory'])>=200:raise Rejected('Bag full')
                s['inventory'].append(s['equipped']['weapon'])
            s['selected_job']=job['id']
            s['equipped']['weapon']=dict(id=job['weapon'],count=1,enhancement=0)
        elif op=='skill':
            if not 3<=s['class_rank']<5 or not s['selected_element']:raise Rejected('Free skill selection requires Class 3–4')
            slot=self.integer(m.get('slot'),0,2);source=self.integer(m.get('source'),0,2)
            s.setdefault('skill_loadout',[0,1,2])[slot]=source
        elif op=='faction':
            if s['class_rank']<7 or m.get('value') not in ('Light','Dark'):raise Rejected('Faction locked')
            if s['faction'] and s['faction']!=m['value']:raise Rejected('Faction already chosen')
            s['faction']=m['value']
        elif op=='revive':
            if s['hp']>0:raise Rejected('Already alive')
            s['x'],s['z']=-3,-2;s['hp']=self.max_hp(s);s['exp']=max(0,s['exp']-int(self.required_exp(s)*.02))
        elif op=='party':
            # Explicit opt-in room code. Test party only, no privileged permissions.
            code=m.get('code','')
            if not isinstance(code,str) or not code.isalnum() or not 1<=len(code)<=16:raise Rejected('Invalid party code')
            s['party']=code
        else:
            raise Rejected('Unsupported command; GM and client state uploads forbidden')
        return 'OK'

    @staticmethod
    def max_hp(s):return 100+(s['level']-1)*10+s['class_rank']*100
    @staticmethod
    def required_exp(s):return 100+(s['level']-1)*35+s['class_rank']*250
    def gain_exp(self,s,n):
        if s['level']>=100:return
        s['exp']+=n
        while s['level']<100 and s['exp']>=self.required_exp(s):
            s['exp']-=self.required_exp(s);s['level']+=1;s['hp']=self.max_hp(s)
        if s['level']==100:s['exp']=0

    def tick(self):
        now=self.clock();dt=min(.2,max(0,now-self.last_tick));self.last_tick=now
        for s in self.players.values():s['stamina']=min(100,s['stamina']+dt*7)
        for mob in self.mobs:
            if mob['hp']<=0:
                if now>=mob['respawn']:mob['hp']=mob['max_hp'];mob['x'],mob['z']=self.homes[mob['id']]
                continue
            victims=[s for s in self.players.values() if s['hp']>0 and not (-10<s['x']<2 and -7<s['z']<3)]
            target=min(victims,key=lambda s:math.hypot(s['x']-mob['x'],s['z']-mob['z']),default=None)
            home=self.homes[mob['id']]
            tx,tz=home
            if target and math.hypot(target['x']-mob['x'],target['z']-mob['z'])<12 and math.hypot(mob['x']-home[0],mob['z']-home[1])<17:
                tx,tz=target['x'],target['z']
                distance=math.hypot(tx-mob['x'],tz-mob['z'])
                if distance<1.9 and self.attack_times.get(mob['id'],0)<=now:
                    target['hp']=max(0,target['hp']-max(1,mob['level']*3+8-(3+target['level'])))
                    self.attack_times[mob['id']]=now+1.5
            distance=math.hypot(tx-mob['x'],tz-mob['z'])
            if distance>1.5:mob['x']+=(tx-mob['x'])/distance*dt*2;mob['z']+=(tz-mob['z'])/distance*dt*2

async def create_app(db_path=None):
    authority=Authority(db_path or os.environ.get('LEO_DB','characters.sqlite3'))
    app=web.Application(client_max_size=16384)
    app['authority']=authority;app['sockets']={}
    allowed=set(os.environ.get('LEO_ORIGINS','http://localhost:8060,http://127.0.0.1:8060,https://redfullmoon209-debug.github.io').split(','))
    async def health(request):return web.json_response({'status':'ok','mode':'development','players':len(authority.players)})
    async def socket(request):
        if request.headers.get('Origin') and request.headers['Origin'] not in allowed:raise web.HTTPForbidden()
        ws=web.WebSocketResponse(heartbeat=20,max_msg_size=16384)
        await ws.prepare(request)
        player_id=None;last_message=time.monotonic();budget=80.0
        try:
            async for msg in ws:
                if msg.type != WSMsgType.TEXT:continue
                now=time.monotonic();budget=min(80,budget+(now-last_message)*30)-1;last_message=now
                if budget<0:await ws.close(code=1008,message=b'Rate limited');break
                try:
                    data=json.loads(msg.data)
                    if not isinstance(data,dict):raise Rejected('Object expected')
                    if player_id is None:
                        if data.get('op')!='hello':raise Rejected('Authenticate first')
                        token,state=authority.login(data.get('token'));player_id=state['id'];app['sockets'][player_id]=ws
                        await ws.send_json({'type':'welcome','token':token,'id':player_id})
                    elif data.get('op')=='chat':
                        text=data.get('text','')
                        if not isinstance(text,str) or not 1<=len(text)<=250:raise Rejected('Invalid chat')
                        for peer in list(app['sockets'].values()):await peer.send_json({'type':'chat','id':player_id,'text':text})
                    else:
                        await ws.send_json(authority.command(player_id,data))
                except (Rejected,ValueError,TypeError,KeyError) as exc:
                    await ws.send_json({'type':'error','message':str(exc)})
        finally:
            if player_id:
                app['sockets'].pop(player_id,None);authority.disconnect(player_id)
        return ws
    async def ticks(app):
        async def run():
            counter=0
            while True:
                authority.tick();counter+=1
                for player_id,ws in list(app['sockets'].items()):
                    peers=[dict(id=s['id'],x=s['x'],z=s['z'],hp=s['hp'],level=s['level']) for s in authority.players.values()]
                    try:await ws.send_json({'type':'snapshot','self':authority.players[player_id],'players':peers,'mobs':authority.mobs})
                    except (ConnectionError,RuntimeError):pass
                if counter%50==0:
                    with authority.db:
                        for player_id in authority.players:authority.save(player_id)
                await asyncio.sleep(.1)
        task=asyncio.create_task(run());yield;task.cancel()
        try:await task
        except asyncio.CancelledError:pass
        with authority.db:
            for player_id in authority.players:authority.save(player_id)
        authority.db.close()
    app.cleanup_ctx.append(ticks)
    app.router.add_get('/health',health);app.router.add_get('/ws',socket)
    return app

if __name__=='__main__':
    web.run_app(create_app(),host=os.environ.get('LEO_HOST','127.0.0.1'),port=int(os.environ.get('PORT','8765')))
