# Crushers

<img width="664" height="387" alt="image" src="https://github.com/user-attachments/assets/a2bedc1e-c7bf-4f5d-81b4-7d276619d0d6" />


**A dev-themed 3D MMORPG proof of concept** — programming languages as character classes in a corrupted digital underworld.

> "Crush the bugs. Refactor the realm. Rise through the stack."

## Current Status (April 2026)

**Excellent progress on foundations.** We have completed:

- Full workspace structure + .gitignore
- Three rich design documents (`design/LORE.md`, `CLASS_ABILITIES.md`, `THE_HEAP_ZONE.md`)
- Detailed Godot 4.4+ setup guide + folder structure inside `client/`
- `SETUP_CHECKLIST.md` for when you first open the project

**Next step (requires your action):**
Install Godot 4.4+ and create the project in the `client/` folder following the exact instructions in `design/GODOT_SETUP.md`.

Once that is done and you have a blank Godot project open with Forward+ + Jolt configured, we will immediately begin building the `Player.tscn` + third-person SpringArm controller (the heart of Phase 1).

## Philosophy
- Go extremely slow. Every step must feel good.
- Strong theming and humor from day one.
- Desktop client first (Godot 4 export). Web is a future stretch goal.
- One small, atmospheric zone to start ("The Heap").

## Project Structure
```
crushers/
├── client/          # The Godot 4 project (Forward+ + Jolt)
├── design/          # Lore, class specs, zone documentation
├── assets_source/   # Original asset files before import
├── scripts_shared/  # Future shared logic
└── README.md
```

## Getting Started (Once Phase 1 is complete)
1. Install Godot 4.4+
2. Open the `client/` folder as a Godot project
3. Run the main scene

See the detailed execution plan in the project memory / plan file for exact steps.

## The Vision (Short)
You are a **Crusher** — a legendary coder who enters **The Crushed Stack** to fight manifestations of terrible code. Your class is your programming language. Python, Rust, and JavaScript are the first three.

See `design/LORE.md`, `design/CLASS_ABILITIES.md`, and `design/THE_HEAP_ZONE.md` for the full flavor.

---

*Built with love for devs who have suffered through enough legacy code.*# crushers
