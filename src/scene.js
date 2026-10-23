import * as THREE from 'three';
import { GLTFLoader } from '../vendor/three/GLTFLoader.js';
import { clone } from '../vendor/three/SkeletonUtils.js';
import { levelHeightScale } from './gameplay.js';

export class ForestScene {
  constructor(canvas, assets, game, onFailure) {
    this.canvas = canvas; this.assets = assets; this.game = game; this.onFailure = onFailure;
    this.yaw = 0; this.pitch = 0.48; this.distance = 11; this.frameCount = 0;
    this.models = new Map(); this.mobs = new Map(); this.drops = new Map();
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'low-power' });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio || 1, 1.5));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.0;
    this.scene = new THREE.Scene(); this.scene.background = new THREE.Color('#b8d8e5');
    this.scene.fog = new THREE.Fog('#b8d8e5', 30, 82);
    this.camera = new THREE.PerspectiveCamera(48, 1, 0.1, 150);
    this.scene.add(new THREE.HemisphereLight('#f0f7ff', '#44623e', 1.8));
    const sun = new THREE.DirectionalLight('#fff0cc', 2.6); sun.position.set(12, 24, 10); this.scene.add(sun);
    const ground = new THREE.Mesh(new THREE.PlaneGeometry(150, 150), new THREE.MeshLambertMaterial({ color: '#6f9864' }));
    ground.rotation.x = -Math.PI / 2; ground.name = 'Starter Forest ground'; this.scene.add(ground);
    const path = new THREE.Mesh(new THREE.PlaneGeometry(5, 92), new THREE.MeshLambertMaterial({ color: '#b2a184' }));
    path.rotation.x = -Math.PI / 2; path.position.set(0, 0.012, -20); this.scene.add(path);
    const safe = new THREE.Mesh(new THREE.RingGeometry(2.8, 3, 48), new THREE.MeshBasicMaterial({ color: '#aee6e9', transparent: true, opacity: 0.7, side: THREE.DoubleSide }));
    safe.rotation.x = -Math.PI / 2; safe.position.set(0, 0.025, 5); this.scene.add(safe);
    this.selection = new THREE.Mesh(new THREE.RingGeometry(0.65, 0.76, 40), new THREE.MeshBasicMaterial({ color: '#ffd97b', side: THREE.DoubleSide }));
    this.selection.rotation.x = -Math.PI / 2; this.selection.visible = false; this.scene.add(this.selection);
    this.assetErrors = [];
    const manager = new THREE.LoadingManager(); manager.onError = url => this.assetErrors.push(url);
    this.loader = new GLTFLoader(manager); this.raycaster = new THREE.Raycaster();
    canvas.addEventListener('webglcontextlost', event => { event.preventDefault(); onFailure(new Error('การแสดงผล 3D หยุดทำงาน กรุณาโหลดหน้าใหม่')); });
    this.resizeObserver = new ResizeObserver(() => this.resize()); this.resizeObserver.observe(canvas);
    this.resize(); this.render(0); // Paint a lit world before loading models, never an empty buffer.
  }
  resize() {
    const { width, height } = this.canvas.getBoundingClientRect();
    if (width < 1 || height < 1) return; // Hidden character gate must not create a zero-size render target.
    this.renderer.setSize(Math.round(width), Math.round(height), false);
    this.camera.aspect = width / height; this.camera.updateProjectionMatrix();
  }
  async model(id) {
    if (!this.models.has(id)) {
      const asset = this.assets[id]; if (!asset) throw new Error(`ไม่พบ Asset ID: ${id}`);
      this.models.set(id, this.loader.loadAsync(asset.path));
    }
    return this.models.get(id);
  }
  actor(gltf, height) {
    const object = clone(gltf.scene); const root = new THREE.Group(); root.add(object);
    object.updateMatrixWorld(true);
    const bounds = new THREE.Box3().setFromObject(object), size = bounds.getSize(new THREE.Vector3());
    const scale = height / Math.max(0.01, size.y); object.scale.multiplyScalar(scale); object.position.y -= bounds.min.y * scale;
    object.traverse(node => { if (node.isMesh) node.frustumCulled = false; });
    const mixer = new THREE.AnimationMixer(object);
    const actions = Object.fromEntries(gltf.animations.map(clip => [clip.name, mixer.clipAction(clip)]));
    const shadow = new THREE.Mesh(new THREE.CircleGeometry(height * 0.24, 24), new THREE.MeshBasicMaterial({ color: '#183b2c', transparent: true, opacity: 0.2, depthWrite: false }));
    shadow.rotation.x = -Math.PI / 2; shadow.position.y = 0.02; root.add(shadow);
    const actor = { root, object, mixer, actions, pose: null };
    this.scene.add(root); return actor;
  }
  pose(actor, name) {
    if (!actor || actor.pose === name) return;
    const action = actor.actions[name] || actor.actions.idle || actor.actions.Survey;
    if (!action) return;
    if (actor.current) actor.current.fadeOut(0.12);
    action.reset().fadeIn(0.12).play(); actor.current = action; actor.pose = name;
  }
  async load() {
    let timer;
    const pending = Promise.all(['character.male', 'character.female', 'monster.orc', 'pet.fox', 'forest.tree', 'forest.tree-high', 'forest.rocks', 'forest.plant', 'forest.tent', 'weapon.sword', 'weapon.gun', 'weapon.kunai', 'drop.chest'].map(id => this.model(id)));
    let loaded;
    try { loaded = await Promise.race([pending, new Promise((_, reject) => { timer = setTimeout(() => reject(new Error('โหลดโมเดลเกิน 30 วินาที กรุณาตรวจสอบเครือข่ายและลองใหม่')), 30000); })]); }
    finally { clearTimeout(timer); }
    const [male, female, orc, fox, tree, tall, rock, plant, tent, sword, gun, kunai, chest] = loaded;
    if (this.assetErrors.length) throw new Error(`โหลด Texture ไม่สำเร็จ: ${this.assetErrors.join(', ')}`);
    this.weaponModels = { sword, gun, kunai }; this.chestModel = chest;
    this.player = this.actor(this.game.player.gender === 'female' ? female : male, 1.9);
    this.player.root.name = 'Player'; this.pose(this.player, 'idle');
    this.pet = this.actor(fox, 0.65); this.pet.root.name = 'Auto Loot Fox'; this.pose(this.pet, 'Survey');
    for (const m of this.game.monsters) {
      const actor = this.actor(orc, m.elite ? 1.9 : 1.3); actor.root.name = m.id;
      actor.object.traverse(n => { if (n.isMesh) n.userData.monsterId = m.id; });
      this.mobs.set(m.id, actor); this.pose(actor, 'idle');
    }
    for (let i = 0; i < 68; i++) {
      const x = Math.sin(i * 19.8) * (12 + i * 0.5), z = Math.cos(i * 9.37) * (12 + i * 0.5) - 8;
      if (Math.abs(x) < 4 || Math.hypot(x, z) < 7) continue;
      const object = clone((i % 3 === 0 ? tall : tree).scene); object.position.set(x, 0, z);
      object.scale.setScalar(2 + (i % 4) * 0.3); object.rotation.y = i * 2; this.scene.add(object);
    }
    for (let i = 0; i < 32; i++) {
      const object = clone((i % 3 === 0 ? rock : plant).scene);
      const x = Math.sin(i * 7.4) * (8 + i), z = Math.cos(i * 4.5) * (9 + i) - 8;
      if (Math.abs(x) < 3 || Math.hypot(x, z) < 4) continue;
      object.position.set(x, 0, z); object.scale.setScalar(i % 3 === 0 ? 1.4 : 1); this.scene.add(object);
    }
    const camp = clone(tent.scene); camp.position.set(-4, 0, 7); camp.scale.setScalar(2); this.scene.add(camp);
    this.ready = true;
  }
  equipWeapon(entry) {
    const key = entry?.id || 'sword'; if (key === this.weaponKey) return;
    if (this.weaponObject) this.weaponObject.removeFromParent();
    const gltf = this.weaponModels[key]; if (!gltf) return;
    this.weaponKey = key;
    this.weaponObject = clone(gltf.scene);
    const box = new THREE.Box3().setFromObject(this.weaponObject), size = box.getSize(new THREE.Vector3());
    this.weaponObject.scale.setScalar((key === 'gun' ? 0.85 : key === 'kunai' ? 0.48 : 1.05) / Math.max(size.x, size.y, size.z) / this.player.object.scale.x);
    const arm = this.player.object.getObjectByName('arm-right') || this.player.object;
    // Kenney rigid hand anchor. Model dimensions remain independent of combat reach.
    // The right arm's grip extends along local -X in Kenney's bind pose.
    this.weaponObject.position.set(-0.14, 0, key === 'gun' ? 0.06 : 0.025);
    this.weaponObject.rotation.set(0, key === 'gun' ? Math.PI : 0, 0);
    arm.add(this.weaponObject);
  }
  pick(clientX, clientY) {
    const rect = this.canvas.getBoundingClientRect();
    this.raycaster.setFromCamera(new THREE.Vector2((clientX - rect.left) / rect.width * 2 - 1, -(clientY - rect.top) / rect.height * 2 + 1), this.camera);
    const objects = [...this.mobs.entries()].filter(([id]) => this.game.monsters.find(m => m.id === id)?.hp > 0).map(([, actor]) => actor.root);
    return this.raycaster.intersectObjects(objects, true)[0]?.object.userData.monsterId || null;
  }
  project(x, z, y = 1) {
    const p = new THREE.Vector3(x, y, z).project(this.camera), r = this.canvas.getBoundingClientRect();
    return { x: r.left + (p.x + 1) * r.width / 2, y: r.top + (1 - p.y) * r.height / 2, visible: p.z < 1 && Math.abs(p.x) < 1 && Math.abs(p.y) < 1 };
  }
  rotate(dx, dy) { this.yaw -= dx * 0.006; this.pitch = THREE.MathUtils.clamp(this.pitch + dy * 0.003, 0.22, 1.18); }
  zoom(factor) { this.distance = THREE.MathUtils.clamp(this.distance * factor, 4, 25); }
  weaponBounds() {
    if (!this.weaponObject) return null;
    const bounds = new THREE.Box3().setFromObject(this.weaponObject);
    return { min: bounds.min.toArray(), max: bounds.max.toArray(), size: bounds.getSize(new THREE.Vector3()).toArray(), anchor: this.weaponObject.parent.getWorldPosition(new THREE.Vector3()).toArray() };
  }
  render(dt) {
    const g = this.game, p = g.player;
    if (p) {
      const h = this.distance * Math.sin(this.pitch), r = this.distance * Math.cos(this.pitch);
      this.camera.position.set(p.x + Math.sin(this.yaw) * r, h + 1.2, p.z + Math.cos(this.yaw) * r);
      this.camera.lookAt(p.x, 0.9, p.z);
    }
    if (this.ready) {
      this.player.root.position.set(p.x, g.jumpY, p.z); this.player.root.rotation.y = p.yaw; this.player.root.scale.setScalar(levelHeightScale(p.level));
      this.equipWeapon(g.weapon());
      this.pose(this.player, p.hp <= 0 ? 'die' : g.jumpY > 0 ? 'jump' : g.attack ? g.job().animation : g.moving ? 'walk' : 'idle'); this.player.mixer.update(dt);
      this.pet.root.visible = p.pet.active; this.pet.root.position.set(p.pet.x, 0, p.pet.z); this.pet.root.rotation.y = g.petYaw || 0;
      this.pose(this.pet, g.petMoving ? 'Walk' : 'Survey'); this.pet.mixer.update(dt);
      for (const m of g.monsters) {
        const actor = this.mobs.get(m.id); actor.root.visible = m.hp > 0; actor.root.position.set(m.x, 0, m.z);
        if (m.pose === 'walk') actor.root.rotation.y = Math.atan2(p.x - m.x, p.z - m.z);
        this.pose(actor, m.pose); actor.mixer.update(dt);
      }
      for (const d of g.drops) {
        if (!this.drops.has(d.id)) { const object = clone(this.chestModel.scene); object.scale.setScalar(0.45); this.scene.add(object); this.drops.set(d.id, object); }
        const object = this.drops.get(d.id); object.position.set(d.x, 0.12 + Math.sin(g.time * 3) * 0.04, d.z); object.rotation.y = g.time * 0.4;
      }
      for (const [id, object] of this.drops) if (!g.drops.some(d => d.id === id)) { object.removeFromParent(); this.drops.delete(id); }
      const target = g.target(); this.selection.visible = !!target;
      if (target) this.selection.position.set(target.x, 0.04, target.z);
    }
    this.renderer.render(this.scene, this.camera); this.frameCount++;
  }
}
