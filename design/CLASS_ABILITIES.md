# Crushers — Class & Ability Design (POC Version)

**Scope**: This document defines the three starter classes for the proof of concept only. Everything is deliberately small in scope but high in flavor.

---

## Python — The Versatile Sage

**Visual Identity (3D POC)**
- Flowing, organic silhouette with soft glowing cyan/blue data ribbons that trail behind movement.
- Simple hood or "script" mantle.
- When casting, floating Python syntax glyphs appear briefly around them.

**Playstyle Feel**
Versatile, good at area control and adaptation. Slightly slower but very forgiving. Excels when the situation is messy (which it always is in The Heap).

**POC Signature Ability: `list_comp()`**

- **Type**: Short-range cone / small AoE
- **Effect**: Deals moderate damage in a forward cone + applies "Slowed" (reduced movement speed) for 3 seconds to affected targets.
- **Cooldown**: 8 seconds
- **Visual**: A burst of list-comprehension-like syntax (`[x for x in enemies if x.buggy]`) that resolves into a wave of force. Cyan particles.
- **Flavor Text**: "There must be a more Pythonic way to do this."

**Basic Attack**
A simple "interpreted blast" — a quick, low-damage projectile or melee swat that feels lightweight but spammable.

**Fantasy Strength**
Adapts to many situations. Good at fighting groups of small bugs.

**Fantasy Weakness**
Lower burst damage. Can feel "squishy" if caught alone.

---

## Rust — The Iron Guardian

**Visual Identity (3D POC)**
- Geometric, armored, heavy silhouette.
- Subtle orbiting "ownership rings" (thin glowing circles) that rotate around the character when idle or blocking.
- When using abilities, the rings expand into a protective shell.

**Playstyle Feel**
Tanky, deliberate, high skill ceiling. Rewards good positioning and timing. Feels the most "solid" of the three.

**POC Signature Ability: `borrow_check()`**

- **Type**: Personal defensive stance + counter
- **Effect**: For 4 seconds, gain a strong damage reduction shield (60-70%). If an enemy attacks you during this window, they take reflected damage and are briefly stunned ("cannot mutate borrowed data").
- **Cooldown**: 14 seconds
- **Visual**: The ownership rings snap outward into a glowing polyhedral shell. On counter, a satisfying "compile success" chime + red error particles on the attacker.
- **Flavor Text**: "The borrow checker has spoken."

**Basic Attack**
Heavy, slower "ownership strike" — high damage melee swing that feels weighty.

**Fantasy Strength**
Survives situations that would delete other classes. Excellent at holding attention of dangerous single targets.

**Fantasy Weakness**
Slow to reposition. Punished hard for misusing the ability (wasted cooldown feels terrible).

---

## JavaScript — The Chaotic Trickster

**Visual Identity (3D POC)**
- Lean, fast silhouette with chaotic "prototype chains" — glowing, shifting line segments that occasionally reconfigure around the character.
- Colors are vibrant and slightly unstable (hot pink, electric yellow, cyan flickers).
- Movement has a slight "glitch" or double-image on dash abilities.

**Playstyle Feel**
Fast, high mobility, burst damage, high variance. The "glass cannon rogue" of the set. Feels the most "fun and stupid" in the best way.

**POC Signature Ability: `hoist()`**

- **Type**: Reposition + small AoE
- **Effect**: Quick dash forward (or in facing direction) + small damage + brief "confused" debuff on nearby enemies (they attack randomly or move slowly for 2s).
- **Cooldown**: 6 seconds
- **Visual**: The prototype chains stretch and "hoist" the character forward in a blur of syntax. On landing, a small explosion of `var` and `function` keywords.
- **Flavor Text**: "This should probably be hoisted…"

**Basic Attack**
Fast, spammy "event loop strikes" — quick jabs or thrown "callbacks" that do low damage but have very short cooldowns.

**Fantasy Strength**
Incredible mobility and ability to escape or reposition. Great at disrupting groups and finishing low-health targets.

**Fantasy Weakness**
Fragile. Bad positioning = instant deletion. The most "feast or famine" class.

---

## Shared Systems (POC)

**"Crush" Basic Attack**
Every class has a default attack (bound to left click or a dedicated key). It is intentionally generic so the class fantasy lives in the signature ability + visual identity.

**Leveling (1–5 in POC)**
Each level gives a small, noticeable power bump + a funny message:
- Level 2: "You have learned to read the error messages."
- Level 3: "Your code now passes the linter (sometimes)."
- etc.

**Death Messages (Examples)**
- Python: "NameError: name 'self_preservation' is not defined"
- Rust: "error[E0502]: cannot borrow `life` as mutable because it is also borrowed as immutable"
- JavaScript: "TypeError: Cannot read property 'will_to_live' of undefined"

---

## Future Expansion Notes (Post-POC)

- Go: Multi-target / "goroutine" summons, channel-based coordination buffs
- TypeScript: Interface shields, "type-safe" damage reduction, strict mode = higher crit
- C++: Massive damage + self-damage risk on "raw pointer" overextension
- Haskell: Delayed but extremely powerful abilities ("lazy evaluation"), monad-based CC

---

*These three classes must feel meaningfully different after 5 minutes of play. If a new player cannot tell Python from Rust from JavaScript just by watching someone else play, we have failed the core fantasy.*