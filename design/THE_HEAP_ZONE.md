# The Heap — First Zone Design Document (POC)

## Overview

**The Heap** is the starting (and for the entire POC, the *only*) zone in Crushers.

It is a small, self-contained, atmospheric 3D area representing a corrupted region of memory. The goal is not size — it is *mood and memorability*. Players should want to just stand around in it with friends, even when there are no bugs to crush.

**Size Target**: Roughly 60–90 seconds to run across at normal speed. Intentionally intimate.

---

## Visual & Atmospheric Direction

**Core Aesthetic**:
- Low-poly + slightly overgrown digital ruin
- Color palette: Deep void indigo (#0a0a1f), neon cyan/magenta for "active data", warm warning orange for hazards
- Heavy use of fog + subtle god rays / light shafts
- Glowing wireframe edges on important geometry
- Floating and half-sunken "memory blocks" (rectangular prisms) as both platforms and obstacles

**Lighting**:
- One strong directional light (dramatic, slightly raking angle)
- Many small emissive "data motes" and error glyphs floating in the air
- Red/orange glow from hazardous zones
- Very subtle pulsing on "live" memory blocks

**Sound Direction (Post-POC but plan for it)**:
- Low, distant "data wind" — like wind chimes made of modem sounds
- Occasional soft "allocation" chimes when near stable ground
- Ominous low drone near hazard zones

---

## Layout & Landmarks

The zone is roughly circular with a few raised platforms and chasms.

**Key Landmarks** (all POC scale):

1. **The Allocation Plateau** (central safe spawn area)
   - Largest flat area
   - Several large, stable glowing memory blocks
   - Players spawn here
   - Feels like "town" — where you meet other Crushers

2. **The Dangling Pointer Chasm**
   - A gap with floating, unstable platforms
   - Red "error" particles rising from below
   - Crossing it should feel slightly risky even for experienced players

3. **The Leak Grove**
   - A cluster of smaller memory blocks being slowly consumed by glowing orange "leak" material
   - Home to most MemoryLeak spawns
   - Slowing hazard terrain here

4. **The Fragmentation Ruins**
   - Broken, misaligned blocks at odd angles
   - Good verticality for Python AoE or JavaScript dashes
   - Ambush-friendly for NullPointers

5. **The Core (visual focal point)**
   - A large, cracked, still-pulsing "heap root" structure in the distance
   - Not interactable in POC, but clearly the heart of the zone
   - Perfect for screenshots and "we should go there one day" conversations

---

## Enemies (POC)

### NullPointer
- **Behavior**: Fast, appears with a small distortion effect, runs straight at the nearest player, melee attack
- **Flavor on death**: "NullPointerException: tried to access property 'existence' of undefined"
- **Spawn points**: Hidden behind fragmented geometry, near the chasm edges

### MemoryLeak
- **Behavior**: Slow, very tanky, grows 20–30% larger every 8 seconds it's alive. Leaves behind slowing residue on death.
- **Flavor on death**: "MemoryLeak closed. 47 references were still held."
- **Spawn points**: The Leak Grove primarily

**POC Combat Rules**:
- Enemies do not respawn instantly. There is a slow respawn timer or they only respawn when no players are in the zone.
- Goal: Fighting 1–3 at a time should feel good with the three classes.

---

## Gameplay Loops in The Heap (POC)

**Solo Loop**:
Run around → find bugs → use class ability + basic attacks → gain Crush XP orbs → level up → feel powerful for 30 seconds

**Social Loop** (the real goal):
Two or more players meet on the Allocation Plateau → chat → decide to go "hunting" together → coordinate abilities (Rust tanks, Python slows the pack, JS finishes) → celebrate the kill with dumb jokes → repeat

**Exploration Loop**:
"Just walking around and looking at the pretty broken code" should be genuinely pleasant for 5–10 minutes.

---

## Technical Requirements (for later implementation)

- One `NavigationRegion3D` covering the walkable area
- Several `StaticBody3D` + `MeshInstance3D` for the memory blocks (start with BoxMesh + CSG, upgrade to imported low-poly later)
- Hazard areas as `Area3D` that apply slow when entered
- Enemy spawners as simple `Node3D` with timer + `MultiplayerSpawner` later
- Good collision layers so the SpringArm camera doesn't freak out

---

## Success Criteria for The Heap in POC

When a player loads in for the first time, within 60 seconds they should think:
- "This place feels cool and weird"
- "I want to show this to my friends who write [language]"

If we achieve that, the zone has done its job.

---

*This is the only world that exists for the entire proof of concept. It must carry an enormous amount of the "this is a real game" feeling. Invest heavily in atmosphere here.*