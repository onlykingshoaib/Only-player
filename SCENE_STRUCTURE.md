# Main.tscn Scene Structure - "Only King" Battle Royale

## SCENE HIERARCHY (Create this manually in Godot Editor)

```
Main (Node3D)
├── WorldEnvironment
│   └── Environment (WorldEnvironment resource)
├── DirectionalLight3D (Sun)
├── Player (CharacterBody3D) [Add PlayerController.gd script]
│   ├── CollisionShape3D (CapsuleShape3D: radius=1.0, height=4.0)
│   ├── Camera3D [Add SmoothCamera.gd script]
│   │   └── RayCast3D (for shooting)
│   ├── AnimationPlayer (for animations)
│   └── Area3D (body area, for item pickup detection)
│       └── CollisionShape3D (CapsuleShape3D)
├── SafeZone (Node3D) [Add SafeZone.gd script] [Add to "safe_zone" group]
│   ├── MeshInstance3D (TorusMesh for visualization)
│   ├── Area3D (for damage detection)
│   │   └── CollisionShape3D (CylinderShape3D)
│   └── ShapeCast3D (optional, for performance checking)
├── GameMap (Node3D)
│   ├── Ground (MeshInstance3D: PlaneMesh 500x500)
│   │   └── CollisionShape3D (BoxShape3D)
│   ├── Buildings (MultiMeshInstance3D) [Zero-lag environment]
│   │   └── [Populated via script with MultiMesh data]
│   ├── Trees (MultiMeshInstance3D) [Zero-lag vegetation]
│   │   └── [Populated via script with MultiMesh data]
│   └── Props (MultiMeshInstance3D) [Zero-lag props]
│       └── [Populated via script with MultiMesh data]
├── Enemies (Node3D) [Container for AI players]
│   ├── EnemyPlayer_1 (CharacterBody3D)
│   ├── EnemyPlayer_2 (CharacterBody3D)
│   └── ... (more enemies)
├── ItemPickups (Node3D) [Container for loot]
│   ├── AmmoPickup_1 (Area3D with CollisionShape3D)
│   ├── HealthPickup_1 (Area3D with CollisionShape3D)
│   └── ... (more items)
├── MobileHUD (CanvasLayer) [Instance of MobileHUD.tscn]
└── GameManager (Node3D) [Script for game logic]
    └── UI (CanvasLayer)
        └── DebugInfo (Label)
```

---

## DETAILED NODE CONFIGURATION

### Main (Node3D)
- **Script**: Optional GameManager.gd for game flow control
- **Properties**:
  - Position: (0, 0, 0)
  - Rotation: (0, 0, 0)

### WorldEnvironment
- **Properties**:
  - Create a new Environment resource:
    - Ambient Light Enabled: true
    - Ambient Light Energy: 1.2
    - Background Mode: Canvas (for custom skybox)
    - Tone Mapper: ACES (for 120 FPS optimization)

### DirectionalLight3D (Sun)
- **Properties**:
  - Position: (100, 100, 0)
  - Rotation: (-45°, 45°, 0)
  - Energy: 2.0
  - Shadows Enabled: true
  - Shadow Map Size: 2048
  - Directional Shadow Mode: Orthogonal

### Player (CharacterBody3D)
- **Script**: res://scripts/PlayerController.gd
- **Position**: (0, 2, 0)
- **Collision Layer**: 1 (Players)
- **Collision Mask**: All
- **Physics Material**: Custom friction=0.8, bounce=0.0
- **Children**:
  - CollisionShape3D (CapsuleShape3D)
    - Radius: 1.0
    - Height: 4.0
  - Camera3D (Main camera)
    - Script: res://scripts/SmoothCamera.gd
    - Position: (0, 1.5, 0)
    - Children:
      - RayCast3D
        - Position: (0, 0, 0)
        - Enabled: true
        - Cast To: (0, 0, -1000) for far raycast
  - AnimationPlayer
    - Animations: shoot, death, walk, run
  - Area3D (for item detection)
    - CollisionShape3D (CapsuleShape3D, slightly larger than main collider)

### SafeZone (Node3D)
- **Script**: res://scripts/SafeZone.gd
- **Groups**: "safe_zone"
- **Position**: (0, 0.5, 0)
- **Children**:
  - MeshInstance3D
    - Mesh: TorusMesh (radius=200, inner_radius=2, height=1)
  - Area3D
    - Collision Layer: 2 (Zones)
    - Collision Mask: 1 (Players)
    - Children:
      - CollisionShape3D (CylinderShape3D)
        - Radius: 200
        - Height: 500

### GameMap (Node3D)
- **Position**: (0, 0, 0)
- **Children**:
  - Ground (MeshInstance3D)
    - Mesh: PlaneMesh (size_x=500, size_z=500)
    - Material: Standard (albedo color = green)
    - CollisionShape3D (BoxShape3D: 500x1x500)
    - Collision Layer: 3 (Terrain)
  - Buildings (MultiMeshInstance3D) [FOR ZERO-LAG RENDERING]
    - MultiMesh: Multiple identical building models
    - Material: Standard material for all instances
  - Trees (MultiMeshInstance3D)
    - MultiMesh: Multiple tree models
  - Props (MultiMeshInstance3D)
    - MultiMesh: Multiple prop models

### Enemies (Node3D)
- **Position**: (50, 2, 50), (100, 2, 100), etc.
- **Children**: Multiple CharacterBody3D nodes with AI controllers

### ItemPickups (Node3D)
- **Position**: Various across map
- **Children**: Multiple Area3D nodes for pickups
  - Each with:
    - CollisionShape3D (SphereShape3D: radius=1.0)
    - Collision Layer: 4 (Items)
    - Signal connection to Player Inventory

### MobileHUD (CanvasLayer)
- **Instance**: res://ui/MobileHUD.tscn
- **Layer**: 100 (above everything)
- **Scripts**: res://scripts/MobileHUD.gd

### GameManager (Node3D)
- **Optional Script**: res://scripts/GameManager.gd
- **Responsibilities**:
  - Player spawn logic
  - Game start/end conditions
  - Safe zone timeline management
  - Enemy spawn management
  - Victory/defeat UI

---

## CREATION STEPS (Godot Editor)

1. **Create new 3D scene**, name it "Main"
2. **Add Node3D children** as outlined above
3. **Attach scripts** to appropriate nodes
4. **Create collision shapes** for each physics object
5. **Instance MobileHUD.tscn** as child of Main
6. **Configure environment** and lighting
7. **Test with keyboard** (emulate_touch_from_mouse enabled)
8. **Deploy to mobile** tablet with 120 FPS support

---

## MULTIMESH ZERO-LAG OPTIMIZATION EXAMPLE

```gdscript
# Script to populate buildings with zero-lag MultiMesh
extends MultiMeshInstance3D

func _ready():
    var multi_mesh = MultiMesh.new()
    multi_mesh.mesh = load("res://assets/models/building.obj")
    multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
    multi_mesh.instance_count = 50
    
    for i in range(50):
        var transform = Transform3D()
        transform.origin = Vector3(i * 10, 0, (i % 5) * 10)
        multi_mesh.set_instance_transform(i, transform)
    
    self.multimesh = multi_mesh
```

---

## MOBILE OPTIMIZATION TIPS

- **Disable shadow quality**: Set DirectionalLight3D shadow quality to QUALITY_LOW
- **Use MultiMesh for buildings**: Reduces draw calls from hundreds to 1
- **Lower resolution on mobile**: Set display resolution to 1080p, render at 60% then upscale
- **Disable SDFGI**: Global illumination disabled in project.godot
- **Enable VRS** (Variable Rate Shading) if device supports it
- **Batch particle effects**: Use GPUParticles3D with shared material

---

## SCENE SAVE PATH
Save this scene to: `res://scenes/Main.tscn`

Then set it as the main scene in:
Project Settings > General > Run > Main Scene > res://scenes/Main.tscn
