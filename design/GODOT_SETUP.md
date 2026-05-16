# Godot 4 Setup Instructions for Crushers (Linux)

This document walks you through getting a correctly configured Godot 4.4+ project for the Crushers POC.

## 1. Install Godot 4.4+ (Recommended Methods on Linux)

### Best Option: Flatpak (easiest updates, sandboxed)
```bash
flatpak install flathub org.godotengine.Godot
flatpak run org.godotengine.Godot
```

### Alternative: Official AppImage
1. Go to https://godotengine.org/download
2. Download the latest 4.4+ Linux 64-bit (standard, not .NET unless you want C#)
3. Make it executable:
   ```bash
   chmod +x Godot_v4.4.x-stable_linux.x86_64
   ```
4. Run it directly or create a symlink in `~/.local/bin`

### Alternative: Steam
- Search for "Godot Engine" in Steam. Good for automatic updates.

Verify the version:
```bash
flatpak run org.godotengine.Godot --version
# or
./Godot_v4.4* --version
```

You should see something like `4.4.1.stable` or newer.

## 2. Create the Project (Critical Settings)

1. Open Godot
2. Click **New Project**
3. Set **Project Path** to:  
   `/home/francesco/workspace/crushers/client`
4. Project Name: `Crushers`
5. **Renderer**: Choose **Forward+** (this is the default for desktop 3D and what we want)
6. Click **Create & Edit**

## 3. Apply Project Settings Immediately

Go to **Project → Project Settings** (or press F4)

### Rendering
- **Rendering → Renderer → Rendering Method** → `forward_plus`

### Physics (Very Important for 3D Character Controller)
- **Physics → 3D → Physics Engine** → `JoltPhysics` (or `Jolt` in some versions)

If you don't see Jolt, it is usually the default improved option in 4.4+. Use it over the old Godot Physics for better character behavior.

### Input Map (Create these actions)
Navigate to **Input Map** tab and add:

| Action Name   | Keys / Buttons                  |
|---------------|---------------------------------|
| `move_forward` | W, Up Arrow                     |
| `move_back`    | S, Down Arrow                   |
| `move_left`    | A, Left Arrow                   |
| `move_right`   | D, Right Arrow                  |
| `jump`         | Space                           |
| `ability_1`    | 1, Q                            |
| `ability_2`    | 2, E                            |
| `interact`     | F                               |

Also consider adding mouse buttons later for attack.

### Other Recommended Settings
- **Display → Window → Size**: Start with 1280x720 or 1920x1080 (you can change later)
- **Display → Window → Stretch → Mode**: `viewport` (good for 3D)
- Enable **Occlusion Culling** under Rendering (performance win even for small scenes)

Save the project (Ctrl+S).

## 4. Folder Structure You Should Have After Creation

```
client/
├── .godot/               ← Godot will create this (add to .gitignore)
├── scenes/
│   ├── player/
│   ├── levels/
│   └── ui/
├── scripts/
│   ├── player/
│   └── managers/
├── assets/
└── project.godot
```

## 5. First Test Scene (Minimal)

After project creation, create a quick test scene to verify 3D works:
1. Create a new scene with a `Node3D` root
2. Add a `MeshInstance3D` (make it a box or capsule)
3. Add a `Camera3D`
4. Add a `DirectionalLight3D`
5. Press F5 — you should see something rendered in Forward+ with nice lighting.

If it looks good, you're ready for the real Phase 1 work (Player controller + The Heap).

## 6. Export Presets (Later)

Once you have a working character, you will create export presets for Linux and Windows so friends can play without installing Godot.

## Troubleshooting

- **Jolt not available**: In some Godot builds it is under a different name or you may need to use the "standard" download. It is not critical — Godot Physics also works fine for the POC.
- **Poor performance**: Make sure you're not accidentally on the Compatibility renderer.
- **Mouse capture issues**: In the player script we explicitly set `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`.

---

Once you have completed steps 1–3 above, open this project and tell me (or mark the todo), and we will begin building the `Player.tscn` + `player.gd` exactly as specified in the main plan.

This setup gives us the best possible foundation for a smooth 3D third-person experience in Godot 4.4+.