# Crushers — Godot Project Setup Checklist

Use this when you first open the `client/` folder in Godot 4.4+.

## Immediate Project Settings (Do This First)

- [ ] Set Renderer to **Forward+**
- [ ] Set Physics Engine to **JoltPhysics** (or Jolt)
- [ ] Configure the Input Map with these exact actions:
  - `move_forward`, `move_back`, `move_left`, `move_right`
  - `jump`
  - `ability_1`, `ability_2`
  - `interact`

## Folder Structure (Already Created for You)

All the folders you need already exist:
- `scenes/player/`
- `scenes/levels/`
- `scenes/ui/`
- `scripts/player/`
- `scripts/managers/`
- `scripts/utils/`
- `assets/...`

## Next Work Items (After Settings)

1. Create `scenes/player/Player.tscn` following the exact node hierarchy in the main plan (section 13)
2. Create `scripts/player/player.gd` with the SpringArm third-person controller
3. Create `scenes/levels/TheHeap.tscn` with basic geometry + lighting + fog
4. Create a minimal `scenes/Main.tscn` that loads TheHeap

## Design Documents Reference

The creative direction lives in the sibling `design/` folder at the workspace root:
- `design/LORE.md`
- `design/CLASS_ABILITIES.md`
- `design/THE_HEAP_ZONE.md`

Read these before writing any flavor text or ability code.

## Verification Goal for Phase 1

When you press F5, you should have a controllable third-person character that can walk around a moody, low-poly "corrupted memory" environment with a camera that feels good (no clipping, nice mouse sensitivity, spring arm working).

---

Once the above checklist is complete and you can move a character around in The Heap, come back and tell me. We will then move to **Phase 2: First Multiplayer**.

This is deliberately the slowest, most careful start possible. Good work getting this far.