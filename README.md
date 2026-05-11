# # 🎮 Only King - Professional Battle Royale for Godot 4.3

A high-performance, mobile-optimized Battle Royale game engine built with **Godot 4.3** and **GDScript 2.0**. Designed for high-end mobile tablets with 120 FPS support.

---

## ✨ Key Features

### 🚀 Performance
- **120 FPS locked** on compatible devices
- **Zero-Lag** rendering with MultiMesh environment (1 draw call for 100+ objects)
- Mobile-optimized Forward+ renderer
- MSAA 2x anti-aliasing for crisp visuals

### 🎮 Gameplay
- **3D Player Movement** with smooth acceleration/deceleration
- **360-Degree Touch Camera** with customizable sensitivity
- **RayCast3D Weapon System** with configurable fire rates
- **Battle Royale Safe Zone** with shrinking circle mechanics
- **Inventory System** with weapons, ammo, and health items
- **Damage & Health System** with visual feedback

### 📱 Mobile UI
- **Virtual Joysticks** for movement and camera control
- **Action Buttons** for Jump, Shoot, Aim, Sprint
- **Real-time HUD** showing health, ammo, zone info
- **Touch Optimization** for fast input response (< 16ms)

### 🎨 Professional Features
- **Smooth Camera Follow** with collision detection
- **Dynamic Safe Zone** with visual Torus representation
- **Pickup Items** with auto-despawn and visual effects
- **Game State Management** with proper lifecycle
- **Signal-Based Architecture** for clean code organization

---

## 📁 Project Structure

```
Only-player/
├── project.godot                    # Godot 4.3+ project config
├── README.md                        # This file
├── README_SETUP.md                 # Detailed setup guide
├── SCENE_STRUCTURE.md              # Main.tscn hierarchy
│
├── scenes/
│   └── Main.tscn                   # Main game scene (create manually)
│
├── scripts/
│   ├── PlayerController.gd         # Player movement (3D, shooting, health)
│   ├── SmoothCamera.gd             # Professional camera system
│   ├── SafeZone.gd                 # Shrinking circle logic
│   ├── Inventory.gd                # Weapon & ammo management
│   ├── PickupItem.gd               # Pickupable items in world
│   ├── EnvironmentGenerator.gd     # Zero-lag environment
│   └── GameManager.gd              # Game flow & state
│
├── ui/
│   ├── MobileHUD.tscn              # Mobile UI scene
│   └── MobileHUD.gd                # HUD controller script
│
└── assets/
    ├── models/                     # 3D models (buildings, trees, etc.)
    ├── textures/                   # PBR textures
    └── sounds/                     # Audio effects
```

---

## 🚀 Quick Start

### Prerequisites
- **Godot 4.3+** (https://godotengine.org/)
- **GDScript 2.0** (built into Godot 4.x)
- **Target Device**: High-end mobile tablet (iPad Pro, Galaxy Tab S8+)

### Installation

1. **Clone/Open Project**
   ```bash
   cd /workspaces/Only-player
   godot --path .
   ```

2. **Create Main Scene**
   - Follow the detailed steps in `SCENE_STRUCTURE.md`
   - Create `res://scenes/Main.tscn` with proper node hierarchy

3. **Verify Configuration**
   - Open Project Settings
   - Confirm 120 FPS target
   - Verify mobile display settings
   - Enable touch emulation from mouse

4. **Run Project**
   - F5 to play (or Project > Run)
   - Use WASD + Mouse for keyboard control
   - Use joysticks for touch simulation

---

## 🎮 Controls

### Keyboard (Testing)
| Key | Action |
|-----|--------|
| W/A/S/D | Move forward/left/back/right |
| Mouse Move | Look around |
| Space | Jump |
| Left Click | Shoot |
| Shift | Sprint |

### Mobile Touch
| Area | Action |
|------|--------|
| Left Joystick (Bottom-Left) | Movement |
| Right Joystick (Bottom-Right) | Camera Look |
| Jump Button | Jump |
| Shoot Button | Fire weapon |
| Aim Button | Zoom camera |
| Sprint Button | Toggle sprint |

---

## 📚 Core Systems

### PlayerController.gd
**Handles all player mechanics**
- Smooth 3D movement with physics
- Touch camera control (360°)
- RayCast3D shooting system
- Health & damage system
- Ammo management

**Key Methods**:
```gdscript
set_movement_input(Vector2)      # Joystick input
set_look_input(Vector2)          # Camera input
jump()                            # Jump action
shoot()                           # Fire weapon
take_damage(float)               # Receive damage
heal(float)                      # Restore health
```

### SmoothCamera.gd
**Professional camera following**
- Predictive positioning
- Wall collision detection
- Smooth lerp (120 FPS ready)
- Look-ahead based on velocity

**Exports**:
- `follow_distance`: Distance behind player (default: 8.0)
- `follow_smoothness`: Lerp factor (default: 0.12)
- `collision_enabled`: Wall detection toggle

### SafeZone.gd
**Battle Royale shrinking circle**
- Configurable shrink duration
- Torus mesh visualization
- Area3D damage detection
- Dynamic zone movement

**Signals**:
- `zone_shrink_started`
- `zone_shrink_progress(progress: float)`
- `player_in_danger(player)`
- `player_safe(player)`

### Inventory.gd
**Weapon & item management**
- Weapon equipping/swapping
- Ammo tracking
- Health item system
- Slot-based inventory

**Methods**:
```gdscript
add_item(item_id, quantity)
equip_weapon(slot_index)
use_health_item(slot_index)
add_ammo(weapon_type, amount)
get_equipped_weapon()
```

### MobileHUD.gd
**Touch UI controller**
- Virtual joysticks
- Action buttons
- Real-time HUD updates
- Touch input parsing

---

## ⚙️ Configuration

### Performance Settings (project.godot)

```ini
[rendering]
renderer/rendering_method="forward_plus"
anti_aliasing/quality/msaa_3d=2
lights_and_shadows/positional_shadow/atlas_size=2048
global_illumination/gi/enabled=false
textures/vram_compression/import_etc2_astc=true

[run]
max_fps=120
physics_fps=120

[display]
window/stretch/mode="canvas_items"
window/vsync_mode=0

[input_devices/pointing]
emulate_touch_from_mouse=true
```

### Customization

**Adjust Player Stats**:
```gdscript
# In PlayerController.gd
@export var walk_speed = 20.0
@export var sprint_speed = 35.0
@export var jump_force = 15.0
@export var camera_sensitivity = 0.003
```

**Change Safe Zone**:
```gdscript
# In SafeZone.gd
@export var initial_radius = 200.0
@export var final_radius = 10.0
@export var shrink_duration = 300.0  # seconds
@export var damage_per_tick = 5.0
```

---

## 🎯 Zero-Lag Optimization

### MultiMesh Implementation
Instead of rendering 100+ individual meshes (100+ draw calls), we use MultiMesh to render all instances in **1 draw call**:

```gdscript
var multimesh = MultiMesh.new()
multimesh.mesh = building_model
multimesh.transform_format = MultiMesh.TRANSFORM_3D
multimesh.instance_count = 50

for i in range(50):
    var transform = Transform3D()
    transform.origin = Vector3(i * 10, 0, 0)
    multimesh.set_instance_transform(i, transform)

multimesh_instance.multimesh = multimesh
```

**Result**: ~99% reduction in draw calls!

### Additional Optimizations
- MSAA 2x (lower quality but faster)
- Shadow atlas size 2048 (balanced quality/performance)
- GI disabled for mobile
- Texture compression enabled

---

## 🐛 Troubleshooting

### FPS Issues
- [ ] Reduce building/tree/prop count in EnvironmentGenerator
- [ ] Lower MSAA to 1x or disable
- [ ] Enable profiler (Tools > Profiler)
- [ ] Check GPU utilization in device settings

### Touch Input Not Working
- [ ] Enable `input_devices/pointing/emulate_touch_from_mouse` in project settings
- [ ] Verify MobileHUD script is attached to CanvasLayer
- [ ] Check joystick input handling in MobileHUD._input()

### Camera Not Following
- [ ] Ensure SmoothCamera.gd is attached to Camera3D node
- [ ] Check that Camera3D is child of Player
- [ ] Verify PlayerController.gd is on Player node

### Weapons Not Firing
- [ ] Verify RayCast3D is enabled and positioned correctly
- [ ] Check raycast collision mask and layers
- [ ] Ensure ammo count > 0
- [ ] Debug: Call `player.shoot()` manually

---

## 📱 Mobile Export

### Android
1. Project > Export > Add > Android
2. Configure keystore & signing
3. Set target API 31+, min API 21
4. Set screen orientation to landscape
5. Export as APK

### iOS
1. Project > Export > Add > iOS
2. Configure provisioning profile
3. Set bundle identifier
4. Export as .ipa

---

## 🎓 Learning Resources

### Godot Documentation
- [Godot 4.3 Docs](https://docs.godotengine.org/en/stable/)
- [GDScript 2.0 Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
- [Physics Engine](https://docs.godotengine.org/en/stable/tutorials/physics/introduction_to_3d_physics.html)

### Battle Royale Mechanics
- Safe zone calculation
- Player elimination tracking
- Loot distribution
- Map design best practices

---

## 🔄 Next Steps

### Immediate
- [ ] Create Main.tscn manually (follow SCENE_STRUCTURE.md)
- [ ] Test keyboard/mouse controls
- [ ] Verify 120 FPS lock
- [ ] Test touch input

### Short Term
- [ ] Add player animations (walk, run, shoot, death)
- [ ] Implement AI enemies
- [ ] Add sound effects
- [ ] Create weapon models

### Medium Term
- [ ] Network multiplayer (Godot Netcode)
- [ ] In-game cosmetics/skins
- [ ] Leaderboard system
- [ ] Custom map editor

### Long Term
- [ ] Mobile app stores (Google Play, App Store)
- [ ] Cross-platform play
- [ ] Seasonal battle pass
- [ ] Premium content

---

## 📝 License

This project is provided as-is for educational and development purposes.

---

## 💬 Support

For issues or questions:
1. Check SCENE_STRUCTURE.md and README_SETUP.md
2. Review script comments and exports
3. Enable debug mode in GameManager
4. Check Godot editor Output console

---

**Built with ❤️ for the Only King Battle Royale**

*Godot 4.3 | GDScript 2.0 | 120 FPS Mobile Gaming*
Only player
