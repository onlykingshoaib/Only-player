# Godot 4.3 Battle Royale - "Only King" Setup Guide

## 📋 PROJECT STRUCTURE

```
/workspaces/Only-player/
├── project.godot                 # Project configuration (120 FPS, mobile optimized)
├── SCENE_STRUCTURE.md           # Main.tscn scene hierarchy documentation
├── README_SETUP.md              # This file
├── scenes/
│   └── Main.tscn                # Main game scene (CREATE MANUALLY)
├── scripts/
│   ├── PlayerController.gd      # Player movement & shooting (3D, 360° camera)
│   ├── SmoothCamera.gd          # Professional camera follow system
│   ├── SafeZone.gd              # Battle royale shrinking circle logic
│   ├── Inventory.gd             # Weapon & ammo pickup system
│   ├── PickupItem.gd            # World item base class
│   ├── EnvironmentGenerator.gd  # Zero-lag MultiMesh environment
│   └── GameManager.gd           # (Optional) Game flow control
├── ui/
│   └── MobileHUD.tscn           # Mobile UI with touch joysticks
└── assets/
    ├── models/
    ├── textures/
    └── sounds/
```

---

## 🚀 SETUP INSTRUCTIONS

### Step 1: Open Project in Godot 4.3

```bash
# Open the Only-player folder as a Godot project
cd /workspaces/Only-player
# Open with Godot 4.3+
godot --path .
```

### Step 2: Configure Project Settings

1. **Go to Project > Project Settings**
2. **Verify display configuration**:
   - Display > Window > Stretch > Mode: `canvas_items` ✓
   - Display > Window > Vsync Mode: `Disabled` ✓
   - Run > Max FPS: `120` ✓
3. **Input Devices**:
   - Pointing > Emulate Touch from Mouse: `Enabled` ✓
4. **Rendering**:
   - Renderer: `Forward+` (for mobile) ✓

### Step 3: Create Main Scene Manually

**Follow the detailed structure in `SCENE_STRUCTURE.md`**

1. **Create new 3D scene**, name it "Main"
2. **Add root node**: Node3D (name: "Main")
3. **Add children** in this order:
   - WorldEnvironment
   - DirectionalLight3D (Sun)
   - Player (CharacterBody3D) with PlayerController.gd script
   - SafeZone (Node3D) with SafeZone.gd script
   - GameMap (Node3D)
   - MobileHUD (Instance of ui/MobileHUD.tscn)

4. **Save as**: `res://scenes/Main.tscn`

### Step 4: Attach Scripts to Nodes

| Node | Script | Purpose |
|------|--------|---------|
| Player | PlayerController.gd | 3D movement, camera, shooting |
| Player/Camera3D | SmoothCamera.gd | Smooth camera follow |
| SafeZone | SafeZone.gd | Shrinking circle & damage |
| GameMap | EnvironmentGenerator.gd | Zero-lag environment |
| MobileHUD | MobileHUD.gd | Touch UI controller |

### Step 5: Set Main Scene

1. **Project > Project Settings > General > Run > Main Scene**
2. **Select**: `res://scenes/Main.tscn`
3. **Click "Select"**

### Step 6: Test Controls

**Keyboard Test** (emulate_touch_from_mouse enabled):
- **WASD**: Movement
- **Mouse Move**: Camera look
- **Space**: Jump
- **Left Click**: Shoot

**Mobile Test**:
- **Left Side**: Movement joystick
- **Right Side**: Camera look joystick
- **Buttons**: Jump, Aim, Shoot, Sprint

---

## ⚙️ CORE COMPONENTS EXPLAINED

### PlayerController.gd
**Features**:
- Smooth 3D character movement with acceleration/deceleration
- 360-degree touch camera look with configurable sensitivity
- RayCast3D weapon system for shooting
- Health & ammo management
- Signals for UI updates (health_changed, ammo_changed)

**Usage**:
```gdscript
# Called from MobileHUD
player.set_movement_input(Vector2.ZERO)  # Joystick input
player.set_look_input(Vector2(1, 0))      # Camera input
player.jump()                              # Jump action
player.shoot()                             # Fire weapon
```

### SmoothCamera.gd
**Features**:
- Predictive camera positioning
- Collision detection (camera behind walls)
- Smooth lerp following (120 FPS optimized)
- Look-ahead based on player velocity

**Exports**:
```gdscript
follow_distance = 8.0          # Distance behind player
follow_height = 6.0            # Height above player
follow_smoothness = 0.12       # Lerp factor
collision_enabled = true       # Wall collision check
```

### SafeZone.gd
**Features**:
- Configurable shrinking circle over time
- Torus visualization (MeshInstance3D)
- Area3D damage detection
- Dynamic zone movement support

**Events**:
```gdscript
zone_shrink_started()           # First shrink starts
zone_shrink_progress(progress)  # Progress 0-1
player_in_danger(player)        # Player in damage zone
player_safe(player)             # Player left danger zone
```

### Inventory.gd
**Features**:
- Weapon & ammo management
- Health item system
- Slot-based inventory
- Weapon equipping/swapping

**Methods**:
```gdscript
add_item(item_id, quantity)         # Add to inventory
equip_weapon(slot_index)             # Equip weapon
use_health_item(slot_index)          # Use bandage/medkit
add_ammo(weapon_type, amount)        # Add ammo to weapon
get_equipped_weapon()                # Get current weapon
```

### MobileHUD.gd
**Features**:
- Virtual movement & look joysticks
- Action buttons (Jump, Shoot, Aim, Sprint)
- Touch input parsing (multitouch ready)
- HUD info display (Health, Ammo, Zone)

**Touch Areas**:
- **Left 50%**: Movement joystick
- **Right 50%**: Look joystick
- **Bottom-Right**: Action buttons

---

## 🎮 MOBILE OPTIMIZATION TIPS

### Zero-Lag Rendering with MultiMesh
**Current Implementation**:
- Buildings: 1 draw call (instead of 20+)
- Trees: 1 draw call (instead of 100+)
- Props: 1 draw call (instead of 50+)

**How it works**:
```gdscript
var multimesh = MultiMesh.new()
multimesh.mesh = building_model
multimesh.instance_count = 20
for i in range(20):
    multimesh.set_instance_transform(i, transform)
multimesh_instance.multimesh = multimesh
```

### Performance Tips
1. **Disable Advanced Lighting**: SDFGI already disabled in project.godot
2. **Use LOD (Level of Detail)**: Swap models at distance
3. **Batch Particles**: Use single GPU Particles3D with shared material
4. **Monitor FPS**: Enable Debug > Monitor in editor
5. **Profile with Profiler**: Tools > Profiler during play

### Recommended Settings for 120 FPS
```gdscript
# In project.godot
[rendering]
renderer/rendering_method = "forward_plus"
textures/vram_compression/import_etc2_astc = true
anti_aliasing/quality/msaa_3d = 2
lights_and_shadows/positional_shadow/atlas_size = 2048
```

---

## 🔧 ADDING CUSTOM CONTENT

### Add a Weapon
```gdscript
# In Inventory.gd - weapons_data dictionary
"plasma_rifle": {
    "name": "Plasma Rifle",
    "damage": 50.0,
    "fire_rate": 0.15,
    "ammo_capacity": 200,
    "type": ItemType.WEAPON
}
```

### Add a Pickup Item
```gdscript
# Create instance in Main.tscn or via script
var pickup = preload("res://scripts/PickupItem.gd").new()
pickup.item_id = "rifle_ammo"
pickup.quantity = 60
pickup.global_position = Vector3(100, 1, 50)
get_node("ItemPickups").add_child(pickup)
```

### Customize Player Stats
```gdscript
# In PlayerController.gd exports
walk_speed = 20.0        # Increase for faster movement
sprint_speed = 35.0      # Sprint multiplier
jump_force = 15.0        # Jump height
camera_sensitivity = 0.003  # Mouse/touch look speed
```

---

## 🐛 DEBUGGING

### Enable Debug Output
```gdscript
# Print inventory state
inventory.debug_print_inventory()

# Check zone info
var zone_info = safe_zone.get_zone_info()
print("Zone Radius: ", zone_info.radius)
print("Time Remaining: ", zone_info.time_remaining)

# Monitor FPS
print("Current FPS: ", Engine.get_frames_per_second())
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Camera not following | Ensure SmoothCamera.gd is attached to Camera3D |
| Player falls through map | Check Ground CollisionShape3D bounds |
| Touch input not working | Enable emulate_touch_from_mouse in project.godot |
| Low FPS on mobile | Reduce building/tree/prop count in EnvironmentGenerator |
| Weapons not firing | Verify RayCast3D is enabled and in correct position |

---

## 📱 TESTING ON MOBILE

### Export to Android
1. **Setup Android SDK** in Godot settings
2. **Project > Export > Add... > Android**
3. **Configure**: Orientation, Resolution, Permissions
4. **Export as APK**
5. **Deploy to tablet**: Run APK on device

### Tablet Requirements
- **Resolution**: 2560x1440+ (iPad Pro / Galaxy Tab S8+)
- **Refresh Rate**: 120 Hz support
- **RAM**: 4GB+
- **GPU**: Mali-G78 or Adreno 660+

---

## 📚 ADDITIONAL RESOURCES

- **Godot 4.3 Docs**: https://docs.godotengine.org/en/stable/
- **GDScript 2.0**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- **Mobile Optimization**: https://docs.godotengine.org/en/stable/tutorials/performance/

---

## 🎯 NEXT STEPS

1. ✅ Create Main.tscn scene manually (follow SCENE_STRUCTURE.md)
2. ✅ Attach all scripts to nodes
3. ✅ Test keyboard controls
4. ✅ Test mobile touch controls
5. ✅ Add custom player models and animations
6. ✅ Implement AI enemies
7. ✅ Add sound effects and music
8. ✅ Export to Android/iOS

---

**Happy Developing! 🚀**

Made with ❤️ for "Only King" - The Ultimate Mobile Battle Royale
