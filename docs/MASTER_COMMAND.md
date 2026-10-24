# MASTER COMMAND — NEX TGEN LEO MMORPG
## สั่ง GPT Work พัฒนาเกม NexTgenLeo แบบครบโปรเจกต์

### 1. ภารกิจหลัก

ให้รับหน้าที่เป็นทีมพัฒนาเกม MMORPG มืออาชีพ ประกอบด้วย Game Director, Game Designer, Godot Developer, 3D Technical Artist, UI/UX Designer, Backend Engineer, Network Engineer, QA Engineer และ DevOps Engineer

**เป้าหมาย:** พัฒนาเกม **NexTgenLeo** ให้ครบตามระบบที่ตกลงไว้ทั้งหมด โดยดำเนินงานต่อเนื่องตั้งแต่ตรวจสอบโปรเจกต์จนถึงสร้างเกมที่ทดสอบได้บน PC และมือถือ

**ข้อกำหนดสำคัญ**
- ไม่ต้องให้ผู้ใช้สั่งสร้างทีละแพตช์
- ไม่ต้องหยุดถามหลังทำระบบย่อยเสร็จ
- ให้จัดลำดับงานและดำเนินการต่อโดยอัตโนมัติภายในงานเดียว
- แก้ไขโค้ดและไฟล์จริงใน GitHub ไม่ใช่แค่เขียนคำแนะนำ
- ตรวจสอบ Build และทดสอบทุกระบบที่สามารถทดสอบได้
- ห้ามรายงานว่าระบบเสร็จสมบูรณ์ถ้ายังไม่ได้ทดสอบ
- ห้ามลบไฟล์เดิมหรือเปลี่ยนข้อสรุปสำคัญโดยไม่มีเหตุผลและไม่ได้รับอนุญาต
- ถ้าพบข้อผิดพลาดให้ตรวจสอบสาเหตุ แก้ไข และทดสอบซ้ำ
- หากพบงานที่ต้องใช้สิทธิ์ผู้ใช้ ให้แจ้งเฉพาะขั้นตอนที่ต้องได้รับอนุญาต แล้วทำงานส่วนอื่นต่อ

### 2. Repository และเทคโนโลยี

**GitHub Repository:**  
https://github.com/redfullmoon209-debug/NexTgenLeo

**Engine:** Godot 4.4.1  
**ภาษา:** GDScript เป็นหลัก  
**Rendering:** GL Compatibility สำหรับ Web  
**แพลตฟอร์ม:** PC Browser และ Mobile Browser โดยรองรับ Android และ iPhone ตามข้อจำกัดของเบราว์เซอร์

ใช้ Repository นี้เป็นโปรเจกต์หลัก ห้ามสร้าง Repository ใหม่โดยไม่จำเป็น

ให้ตรวจสอบโครงสร้างไฟล์และประวัติการพัฒนาปัจจุบันก่อนแก้ไข และรักษาระบบที่ใช้งานได้อยู่แล้ว

### 3. ระบบเปิดเล่นผ่านเว็บ

แก้ปัญหา GitHub Pages ที่ปัจจุบันแสดง README แทนเกม

ต้องดำเนินการดังนี้:
1. ตรวจสอบ GitHub Actions และ GitHub Pages
2. ตั้งค่า Deployment ให้เผยแพร่ Web Export ของ Godot จริง
3. แก้ Workflow ที่ซ้ำซ้อนหรือขัดแย้งกัน
4. Build และ Export เกมด้วย Godot 4.4.1
5. ตรวจสอบว่าไฟล์ `index.html` ของเกมถูกเผยแพร่จริง
6. เปิดเว็บทดสอบและตรวจสอบการโหลดฉาก 3D
7. ตรวจสอบ JavaScript Console และข้อผิดพลาด WebGL
8. ทดสอบการควบคุมบน PC และมือถือเท่าที่เครื่องมือรองรับ

**ลิงก์เป้าหมายสำหรับเล่นเกม:**  
https://redfullmoon209-debug.github.io/NexTgenLeo/

ให้ใช้ลิงก์นี้เป็นลิงก์ทดสอบหลัก และอัปเดตเกมผ่าน CI/CD อัตโนมัติ

### 4. ตัวละครและโมเดล 3D

ใช้ตัวละครหลักสองเพศ ได้แก่ Male และ Female

ไฟล์ฐานที่เคยกำหนด:
- `Male_Modular_Rigged_Textured.fbx`
- `Female_Modular_Rigged_Textured.fbx`

ให้ค้นหาไฟล์จากทรัพยากรที่ผู้ใช้อนุญาตให้เข้าถึงก่อน หากไม่มีไฟล์จริง ให้ระบุว่าไม่มีและใช้โมเดลชั่วคราวเฉพาะส่วนที่จำเป็น ห้ามอ้างว่านำเข้าโมเดลจริงแล้ว

ระบบตัวละครต้องรองรับ:
- เลือกเพศชาย/หญิง
- Skeleton และ Animation
- Idle, Walk, Run, Jump, Attack, Hit, Death
- ระบบกล้อง Third Person
- การปรับความสูงตาม Class และ Level ตามข้อกำหนดเดิม
- การเปลี่ยนอาวุธและอุปกรณ์
- การเปลี่ยนทรงผมและหมวก
- การเปลี่ยนชุดแบบ Modular

ชิ้นส่วนอุปกรณ์:
- Hair
- Hat
- Shirt
- Gloves
- Pants
- Shoes
- Weapon Right
- Weapon Left
- Accessories

ต้องใช้ Skeleton และ Skinning ที่เข้ากันได้กับโมเดลฐานจริง หลีกเลี่ยงการสร้างกระดูกใหม่โดยไม่จำเป็น

**สำคัญ:** ห้ามซ่อนผิวหน้าท้องทั้งหมดเมื่อใส่เสื้อเอวลอย ต้องรองรับชุดที่เปิดเผยหน้าท้อง และป้องกัน Mesh ทะลุหรือชิ้นส่วนร่างกายหาย

### 5. ระบบ Class และ Level

สร้างระบบ Class 0–10 โดยแต่ละ Class มี Level 1–100

เมื่อผ่านเงื่อนไขเลื่อน Class ให้เปลี่ยนเป็น Class ถัดไปและเริ่ม Level 1

ต้องมี:
- EXP
- Level Up
- Class Advancement
- Character Stats
- HP
- Stamina
- Attack
- Defense
- Critical
- Movement Speed
- ระบบคำนวณความเสียหาย
- ระบบเพิ่มค่าสถานะ
- ระบบบันทึกความก้าวหน้า

ให้แยกข้อมูล Balance ออกจากโค้ด เพื่อปรับสมดุลภายหลังได้ง่าย

ตรวจสอบเงื่อนไขเควสต์และการปลดล็อก Class จากข้อสรุปเดิมก่อนกำหนดรายละเอียดสุดท้าย

### 6. ระบบธาตุ อาชีพ และฝ่าย

**ธาตุ 6 ประเภท**
- Earth
- Water
- Wind
- Fire
- Lightning
- Wood

สร้างโครงสร้างระบบธาตุ ความสัมพันธ์ระหว่างธาตุ เอฟเฟกต์ และการคำนวณความเสียหาย

**ระบบอาชีพ**

รองรับ 12 อาชีพตามข้อสรุปเดิม โดยตรวจสอบชื่ออาชีพและเงื่อนไขการปลดล็อกจากข้อมูลเดิมก่อนนำไปใช้งานจริง

แนวทางการปลดล็อก:
- Class 3: ระบบเลือกสายพัฒนา
- Class 5: ระบบเลือกอาชีพ
- Class 7: ระบบเลือกฝ่าย
- Class 10: ขั้นสูงสุด

**ระบบฝ่าย**
- Light
- Dark

สร้างระบบฝ่าย สกิลเฉพาะฝ่าย เอฟเฟกต์ UI และข้อจำกัดการต่อสู้

### 7. ระบบต่อสู้และสกิล

สร้างระบบต่อสู้แบบ Third Person Action MMORPG

ต้องมี:
- Basic Attack
- Skill 1, Skill 2, Skill 3
- Target Lock
- Auto Approach
- Auto Attack
- Auto Hunt
- Cooldown
- Skill Range
- Area of Effect
- Single Target
- Damage Calculation
- Critical Hit
- Stamina Consumption
- Hit Reaction
- Death
- Revive
- PvE และ PvP แยกการปรับสมดุล

ระบบ Auto Hunt ต้องเลือกเป้าหมายและกำหนดสกิลที่จะใช้ได้

ให้รองรับทั้งการควบคุมด้วยเมาส์/คีย์บอร์ดและหน้าจอสัมผัส

### 8. แผนที่และโลกเกม

สร้างโลก 3D แบบแฟนตาซีที่เหมาะกับเกมมือถือ

เริ่มจาก Starter Forest และขยายเป็นอย่างน้อย 5 แผนที่ตามแผนเดิม

ต้องมี:
- พื้นดิน ต้นไม้ หิน หญ้า
- ถนนและทางเดิน
- เมืองและ Safe Zone
- NPC
- Monster Spawn
- Elite Monster
- Boss
- World Boss
- Portal
- Minimap
- World Map
- ระบบเดินทางระหว่างแผนที่
- ระบบ Warp

ใช้ Asset ที่มีสิทธิ์ใช้งานอย่างถูกต้อง และออกแบบระบบ LOD, Culling และ Optimization เพื่อรองรับมือถือ

### 9. มอนสเตอร์และเควสต์

สร้างระบบมอนสเตอร์แบบ Data-Driven

รองรับ:
- มอนสเตอร์ทั่วไป
- Elite
- Boss
- World Boss
- Level
- HP
- Attack
- Defense
- AI
- Aggro
- Chase
- Return to Spawn
- Loot Drop
- Respawn Timer

สร้างระบบเควสต์:
- รับเควสต์
- ติดตามความคืบหน้า
- ล่ามอนสเตอร์
- เก็บไอเทม
- ส่งเควสต์
- รับ EXP และรางวัล
- Auto Navigate ไปยัง NPC

### 10. กระเป๋า อุปกรณ์ และร้านค้า

**Inventory**
- 200 ช่อง แบ่งเป็น 2 หน้า
- ไอเทมที่ซ้อนกันได้สูงสุด 99 ชิ้น
- ระบบจัดเรียงไอเทม
- ใช้ไอเทม
- ทิ้งไอเทม
- ขายไอเทม
- สวมใส่อุปกรณ์
- ถอดอุปกรณ์
- เปลี่ยนชุดและอาวุธจริงบนตัวละคร

**Equipment**
- Hat
- Shirt
- Gloves
- Pants
- Shoes
- Weapons
- Accessories

**Item Rarity**
- Common
- Uncommon
- Rare
- Epic
- Legendary

สร้างระบบ Equipment Evolution และ Enhancement ตามข้อกำหนดเดิม โดยเริ่มจากระดับ +0

**Shop**
- NPC Shop
- Cash Shop
- Gold
- Cash
- ระบบซื้อขายและตรวจสอบยอดเงิน

ตัวอย่างไอเทม:
- EXP ×2 ระยะเวลา 1, 6, 12, 24 ชั่วโมง
- Attack +20%
- Defense +20%
- Max HP +20%
- City Warp Scroll

สร้างไอคอนชั่วคราวที่เหมาะกับ UI และสามารถเปลี่ยนเป็น Asset จริงภายหลัง

### 11. ระบบสัตว์เลี้ยง

สร้างระบบ Pet สำหรับ MMORPG

รองรับ:
- เรียกสัตว์เลี้ยง
- เดินตามผู้เล่น
- Auto Loot
- Pet Level 1–100
- Pet EXP
- Pet Evolution 5 ขั้น
- Pet Status
- Pet Inventory หรือความสามารถตามข้อกำหนดเดิม
- ระบบแสดงโมเดลและอนิเมชันสัตว์เลี้ยง

### 12. ระบบ Multiplayer

สร้างสถาปัตยกรรม Multiplayer แบบ Server-Authoritative

ต้องมี:
- Multiplayer Networking
- Player Synchronization
- Character Movement Synchronization
- Combat Validation
- Monster State Synchronization
- Inventory Persistence
- Database
- Authentication
- Character Save/Load
- Party
- Guild
- Chat
- Trading
- PvP
- Guild War
- Element War
- Faction War
- ระบบป้องกัน Item Duplication
- ระบบตรวจสอบคำสั่งจาก Client

ห้ามใช้ Client เป็นแหล่งข้อมูลที่เชื่อถือได้สำหรับเงิน ไอเทม EXP หรือผลการต่อสู้

ให้แยก Web Client และ Dedicated Server ตามความเหมาะสม และจัดทำวิธีติดตั้งเซิร์ฟเวอร์สำหรับการทดสอบจริง

### 13. HUD และ UI มือถือ

สร้าง UI แนวแฟนตาซี MMORPG ที่ดูเป็นเกมจริง ไม่ใช่เพียงหน้าจอ Debug

**HUD**
- Character Portrait
- HP Bar
- Stamina Bar
- EXP Bar
- Class และ Level
- Target Frame
- Minimap
- Quest
- Bag
- Shop
- Character Status
- Skills
- Settings
- Auto Hunt
- GM Tools สำหรับทดสอบ

**Mobile Controls**
- จอยสติกซ้าย
- Basic Attack ขวา
- Skill 1–3
- Jump
- Dash
- Target Lock
- Auto Hunt
- Camera Rotation
- Pinch Zoom

**PC Controls**
- WASD
- Shift
- Space
- Mouse Camera
- Mouse Wheel Zoom
- ปุ่มลัดสำหรับสกิลและเมนู

ต้องรองรับการปรับตำแหน่งปุ่มและขนาด UI ให้เหมาะกับหน้าจอ

### 14. เครื่องมือ GM สำหรับทดสอบ

สร้าง GM Panel เฉพาะโหมดพัฒนา

ต้องสามารถ:
- ปรับ Class
- ปรับ Level
- เพิ่ม EXP
- เพิ่ม Gold/Cash ทดสอบ
- Spawn Monster
- Spawn Boss
- Kill Target
- Revive
- Teleport
- เปลี่ยนอาชีพ
- เปลี่ยนฝ่าย
- เปลี่ยนธาตุ
- ทดสอบไอเทม
- เปิด/ปิดการบิน
- ทดสอบระบบเควสต์

ห้ามเปิดคำสั่ง GM ที่ส่งผลต่อ Server Production ให้ผู้เล่นทั่วไปใช้งาน

### 15. คุณภาพกราฟิกและประสิทธิภาพ

เน้นความสวยงามแบบเกมแฟนตาซี 3D มืออาชีพ แต่ต้องรักษาประสิทธิภาพสำหรับ Web และ Mobile

ให้พัฒนา:
- แสงและเงา
- Materials
- Textures
- เอฟเฟกต์สกิล
- อนิเมชันต่อเนื่อง
- การเคลื่อนไหวสมจริง
- กล้องติดตามตัวละคร
- LOD
- Occlusion/Culling
- Asset Compression
- Texture Optimization
- Memory Optimization
- ระบบตั้งค่าคุณภาพกราฟิก

ต้องตรวจสอบ Frame Rate และ Memory Usage ระหว่างทดสอบ ไม่ใช่รับประกันประสิทธิภาพโดยไม่มีผลทดสอบ

### 16. ระบบบันทึกข้อมูล

สร้างระบบ Save/Load ที่รองรับ:
- Character
- Class
- Level
- EXP
- Stats
- Inventory
- Equipment
- Currency
- Skills
- Quest
- Pet
- Location
- Settings

ข้อมูลสำคัญต้องจัดเก็บและตรวจสอบโดยเซิร์ฟเวอร์เมื่อใช้งาน Multiplayer จริง

### 17. ขั้นตอนทำงานของ GPT Work

ให้ดำเนินการทั้งหมดเป็นงานเดียวแบบต่อเนื่อง โดยไม่ต้องรอคำสั่งทีละแพตช์

**ลำดับดำเนินการ**
1. ตรวจสอบ Repository และระบบที่มีอยู่
2. แก้ GitHub Pages ให้เปิดเกมจริง
3. ตรวจสอบ Build บน Godot 4.4.1
4. สร้างสถาปัตยกรรมเกมทั้งหมด
5. สร้างระบบตัวละครและการควบคุม
6. สร้างระบบ Progression และ Combat
7. สร้างระบบ World, Monster, Quest
8. สร้างระบบ Inventory, Equipment, Shop
9. สร้างระบบ Pet และ Evolution
10. สร้างระบบ UI/HUD ครบชุด
11. สร้าง Backend และ Multiplayer
12. เชื่อมระบบทั้งหมดเข้าด้วยกัน
13. ทดสอบ End-to-End
14. แก้ข้อผิดพลาดจนผ่านเกณฑ์ทดสอบที่กำหนด
15. Deploy เวอร์ชันทดสอบ
16. จัดทำรายงานระบบที่เสร็จ ระบบที่ยังไม่เสร็จ และปัญหาที่ต้องแก้

**ข้อบังคับในการทำงาน**
- ให้จัดการหลายไฟล์และหลายระบบในรอบเดียวได้
- Commit งานอย่างเป็นระบบเพื่อย้อนกลับได้
- ห้ามอ้างว่าเสร็จทั้งเกมเพียงเพราะ Build ผ่าน
- ห้ามใช้ Placeholder แล้วรายงานว่าเป็นโมเดลจริง
- ให้สร้าง Automated Tests เท่าที่เหมาะสม
- ต้องตรวจสอบลิงก์เล่นเกมหลัง Deploy
- หากติดข้อจำกัดด้านสิทธิ์ ทรัพยากร หรือระยะเวลาการทำงาน ให้ระบุอย่างชัดเจน
- อย่าลบหรือเขียนทับไฟล์โมเดลต้นฉบับของผู้ใช้
- ไม่ต้องหยุดเพื่อขออนุมัติทุก Commit แต่ให้ขออนุมัติสำหรับการลบข้อมูลสำคัญ ค่าใช้จ่าย การเผยแพร่ Production หรือการกระทำที่มีผลกระทบสูง

### 18. ผลลัพธ์ที่ต้องส่งมอบ

1. Repository NexTgenLeo ที่มีโค้ดและทรัพยากรเกม
2. Web Build ที่เปิดเล่นได้จริง
3. ลิงก์ทดสอบผ่าน Chrome บน PC และมือถือ
4. ระบบตัวละครและการควบคุม
5. ระบบเกม MMORPG ตามข้อกำหนด
6. ระบบ Multiplayer และวิธีเปิดเซิร์ฟเวอร์
7. ระบบ UI/HUD
8. ระบบ Save/Load
9. รายงานการทดสอบและข้อจำกัด
10. รายการงานคงเหลือที่ระบุอย่างตรงไปตรงมา

**คำสั่งสุดท้าย**

เริ่มดำเนินการกับ Repository ที่กำหนดทันที ใช้ความสามารถของ GPT Work ในการจัดการไฟล์ GitHub และกระบวนการพัฒนาที่รองรับให้มากที่สุด

ไม่ต้องตอบกลับเพียงแผนงาน ให้ลงมือแก้ไขไฟล์จริง สร้างเกมจริง ทดสอบจริง และ Deploy จริง

ทำงานต่อเนื่องภายในขอบเขตที่เครื่องมือและระยะเวลารองรับ โดยไม่ต้องรอให้ผู้ใช้สั่งทีละแพตช์

เป้าหมายสูงสุดคือ **NexTgenLeo MMORPG 3D ที่มีระบบครบตามข้อกำหนด และสามารถเปิดทดสอบได้ทั้ง PC และมือถือ**