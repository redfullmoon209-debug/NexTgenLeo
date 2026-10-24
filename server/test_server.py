import asyncio
import json
import tempfile
import unittest
from pathlib import Path
from aiohttp import ClientSession, web
from server import Authority, Rejected, create_app

class AuthorityTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.path=str(Path(self.tmp.name)/'test.db')
        self.now=100.0;self.a=Authority(self.path,lambda:self.now)
        self.token,self.s=self.a.login();self.id=self.s['id'];self.seq=0
    def tearDown(self):self.a.db.close();self.tmp.cleanup()
    def command(self,op,**fields):
        self.seq+=1
        return self.a.command(self.id,dict(op=op,request=str(self.seq),**fields))
    def test_buy_and_idempotency(self):
        m=dict(op='buy',request='once',item='potion',count=2)
        a=self.a.command(self.id,m);b=self.a.command(self.id,m)
        self.assertEqual(a,b);self.assertEqual(self.s['gold'],120)
        self.assertEqual(self.s['inventory'][0]['count'],7)
    def test_invalid_counts_never_charge(self):
        for value in (-1,0,100,True,1.5,'2'):
            with self.assertRaises(Rejected):self.command('buy',item='potion',count=value)
        self.assertEqual(self.a.players[self.id]['gold'],150)
    def test_client_cannot_grant_money_or_gm(self):
        with self.assertRaises(Rejected):self.command('gm',gold=999999)
        self.command('buy',item='potion',gold=999999)
        self.assertEqual(self.a.players[self.id]['gold'],135)
    def test_overflow_transaction(self):
        self.s['inventory']=[dict(id='sword',count=1,enhancement=0) for _ in range(200)]
        with self.assertRaises(Rejected):self.command('buy',item='herb',count=1)
        self.assertEqual(self.a.players[self.id]['gold'],150)
        self.assertEqual(len(self.a.players[self.id]['inventory']),200)
    def test_move_distance_and_nonfinite(self):
        with self.assertRaises(Rejected):self.command('move',x=30,z=30)
        with self.assertRaises(Rejected):self.command('move',x=float('nan'),z=0)
        self.now+=.1;self.command('move',x=.8,z=0)
        with self.assertRaises(Rejected):self.command('move',x=2,z=0)
    def test_attack_authority_cooldown_range(self):
        with self.assertRaises(Rejected):self.command('attack',target=0,skill=0,damage=999999)
        self.a.mobs[0]['x']=1;self.a.mobs[0]['z']=0
        self.command('attack',target=0,skill=0,damage=999999)
        self.assertEqual(self.a.mobs[0]['hp'],53)
        with self.assertRaises(Rejected):self.command('attack',target=0,skill=0)
    def test_quest_requires_acceptance_and_proximity(self):
        with self.assertRaises(Rejected):self.command('quest')
        self.a.players[self.id]['x']=-5;self.a.players[self.id]['z']=-4
        self.command('quest')
        with self.assertRaises(Rejected):self.command('quest')
        self.a.players[self.id]['quest_kills']=5
        self.command('quest')
        self.assertEqual(self.a.players[self.id]['quest_state'],'complete')
        with self.assertRaises(Rejected):self.command('quest')
    def test_save_reconnect_and_session_exclusion(self):
        with self.assertRaises(Rejected):self.a.login(self.token)
        self.command('buy',item='hat')
        self.a.disconnect(self.id)
        _,s=self.a.login(self.token)
        self.assertEqual(s['gold'],110);self.assertEqual(s['inventory'][-1]['id'],'hat')
    def test_class_element_profession_faction(self):
        with self.assertRaises(Rejected):self.command('element',value='Wind')
        self.a.players[self.id]['class_rank']=3
        self.command('element',value='Wind')
        with self.assertRaises(Rejected):self.command('job',value='wind_assassin')
        self.a.players[self.id]['class_rank']=5
        with self.assertRaises(Rejected):self.command('job',value='water_mage')
        self.command('job',value='wind_assassin')
        with self.assertRaises(Rejected):self.command('faction',value='Light')
        self.a.players[self.id]['class_rank']=7
        self.command('faction',value='Light')
    def test_sale_equipment_and_item_validation(self):
        self.command('buy',item='hat')
        self.command('equip',slot=1)
        self.assertEqual(self.s['equipped']['hat']['id'],'hat')
        self.command('sell',slot=0,count=2)
        self.assertEqual(self.s['inventory'][0]['count'],3)
        with self.assertRaises(Rejected):self.command('sell',slot=-1,count=1)

class TransportTests(unittest.IsolatedAsyncioTestCase):
    async def test_two_clients_sync_chat_and_persistence(self):
        with tempfile.TemporaryDirectory() as tmp:
            app=await create_app(str(Path(tmp)/'net.db'))
            runner=web.AppRunner(app);await runner.setup();site=web.TCPSite(runner,'127.0.0.1',0);await site.start()
            port=site._server.sockets[0].getsockname()[1];url=f'http://127.0.0.1:{port}'
            try:
                async with ClientSession() as http:
                    self.assertEqual((await (await http.get(url+'/health')).json())['status'],'ok')
                    async with http.ws_connect(url+'/ws') as a,http.ws_connect(url+'/ws') as b:
                        await a.send_json({'op':'hello'});wa=await a.receive_json()
                        await b.send_json({'op':'hello'});wb=await b.receive_json()
                        self.assertNotEqual(wa['id'],wb['id'])
                        async def until(ws,kind):
                            for _ in range(30):
                                data=await asyncio.wait_for(ws.receive_json(),2)
                                if data['type']==kind:return data
                            self.fail('message not received')
                        snapshot=await until(a,'snapshot');self.assertEqual(len(snapshot['players']),2)
                        await a.send_json({'op':'chat','text':'hello'})
                        self.assertEqual((await until(b,'chat'))['text'],'hello')
                        await a.send_json({'op':'buy','item':'potion','request':'test','count':1})
                        self.assertTrue((await until(a,'result'))['ok'])
            finally:await runner.cleanup()

if __name__=='__main__':unittest.main()
