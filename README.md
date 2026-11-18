# Brainrot Bazaar 🎪

[![Competition](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?ref=jhz85756)
[![Rank](https://make.fun/badge/roblox-brainrot-01/Aji2306/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01?ref=jhz85756)
[![Reward](https://make.fun/badge/roblox-brainrot-01/Aji2306/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?ref=jhz85756)

**Brainrot Bazaar** is an original 3D Steal-a-Brainrot experience built for the make.fun competition (`roblox-brainrot-01`). Players step into a vibrant 3D plaza, collect absurd meme characters marching along a central conveyor belt, display them across 8 base pedestals to generate coins per second, defend against rival thieves with timed forcefield locks, survive the map-sweeping **Meme Storm**, and rebirth for permanent income multipliers!

---

## 🌟 Game Highlights & Core Systems

- **Full 3D World & Plaza:**
  - Dynamic central conveyor belt with custom spawn and despawn portals.
  - 4 player base plots featuring entrance archways, claim pads, defense security consoles, and 8 individual display pedestals with floating BillboardGui stats.
  - Central Plaza monument ("Statue of the Brainrot King"), market stalls, Victorian street lamps, park benches, and lush geometric trees (>400 instances).
  - Full Roblox character movement in 3D with default third-person controls.

- **Absurd Original Brainrot Cast (8 Characters Across 6 Rarities):**
  1. **Sir Barksalot** (*Common*, $5/s) — A distinguished canine wearing a dapper black silk top hat.
  2. **Captain Croissant** (*Rare*, $12/s) — Buttery, flaky hero wielding a miniature golden butter sword.
  3. **Professor Pigeon** (*Rare*, $25/s) — Academic avian carrying wire spectacles and a tiny briefcase.
  4. **DJ Pickle** (*Epic*, $55/s) — The brine beatmaker with oversized sunglasses and neon headphones.
  5. **Baron von Banana** (*Epic*, $110/s) — Aristocratic yellow peel with a golden monocle and crimson bowtie.
  6. **Grandma's Flying Toaster** (*Legendary*, $260/s) — Chrome toaster hovering with rooftop rotors and launching toast.
  7. **The Infinite Sandwich** (*Mythic*, $750/s) — Multidimensional cosmic club sandwich with an emerald particle aura.
  8. **Emperor of the Lost Socks** (*Brainrot God*, $2,500/s) — Celestial monarch of all lost laundry with a spinning vortex ring.

- **Mutations on Spawn:**
  - **Normal** (x1 Income)
  - **Golden** (x2 Income, gleaming gold metal finish & sparkles)
  - **Diamond** (x5 Income, crystalline cyan ice & sparkles)
  - **Rainbow** (x10 Income, prismatic neon glow & vibrant aura)

- **Interactive Buying & Base Economy:**
  - Walk up to any brainrot on the conveyor and press `[E]` (or click) to purchase it for its price.
  - Owned brainrots are placed atop your base pedestals, generating continuous coins per second.
  - 8 available base slots per player.

- **Stealing & Base Lock Defense:**
  - Unlocked bases are vulnerable! Sneak into a rival player's base and hold `[E]` near their pedestal to steal their brainrot.
  - Activate your **Base Lock** (press `[L]` or interact with the base security console) for $100 coins to deploy a 60-second impenetrable forcefield gate, blocking thieves.
  - Balanced with a 30-second cooldown after expiring.

- **Hazard Wave: "The Meme Storm":**
  - Every 3 minutes, warning sirens wail 15 seconds in advance: `⚠️ WARNING: MEME STORM IN 15s! RUN TO YOUR BASE!`.
  - During the 25-second active storm, eerie atmospheric lighting settles over the plaza.
  - Players caught outside in the plaza are slowed to a crawl (`WalkSpeed = 8`) and have coins stripped away by violent wind gusts.
  - Claimed bases serve as safe zones!

- **Rebirth Progression:**
  - Press `[R]` to open the Rebirth Modal.
  - Reset coins and base brainrots to claim a permanent **+25% income boost per rebirth** across all present and future earnings.

- **Clean ScreenGui HUD:**
  - Keeps top-left corner completely clear for Roblox's default menu, chat, and playerlist buttons.
  - Displays Coins, $/s Income rate, Rebirth count & multiplier, Base Lock status with countdown timers, owned brainrot mini-cards dock, top earners leaderboard, and hazard warnings.

---

## 🛠️ Architecture & Rojo Layout

```
roblox-brainrot-01/
├── default.project.json       # 3D DataModel tree: Plaza, Conveyor, 4 Bases, Props, Lighting (>400 instances)
├── main.ts                    # Packaging script copying files to /output and writing dossier.json
├── PLAY.json                  # Experience link metadata (place_id, universe_id)
├── TOUR.json                  # Interactive tour step sequence
├── SCREENSHOTS-NOTE.md        # Instructions for capturing in-game Studio screenshots
├── screenshots/               # 16:9 gameplay preview captures (placeholder PNGs)
├── vendor/
│   └── makefun-roblox.ts      # make.fun place inspection and canonical dossier generator
└── src/
    ├── client/
    │   └── Game.client.luau   # Client HUD, ContextActionService input (E, L, R), state listeners
    ├── server/
    │   ├── init.server.luau   # Server bootstrap, RemoteEvent handlers, periodic state sync
    │   ├── Config.luau        # Server configuration module
    │   ├── PlayerService.luau # Player data, Roblox leaderstats, coin transactions, rebirths
    │   ├── BaseService.luau   # 4 base plots, slot management, 60s base lock, stealing mechanics
    │   ├── BrainrotService.luau # Dynamic 3D model generation, conveyor walking, buying, $/s income
    │   └── EventService.luau  # Meme Storm hazard cycle, warning broadcasts, danger zone penalty
    └── shared/
        ├── Config.luau        # Character rosters, rarities, mutations, economy & hazard constants
        └── Util.luau          # Formatting ($1.2K, $1.5M, time strings), income math, cloning
```

---

## 🚀 Building & Validation

1. **Build binary place:**
   ```bash
   /home/hatch/.local/bin/rojo build default.project.json --output game.rbxl
   ```

2. **Compile check all Luau scripts:**
   ```bash
   for f in $(find src -name "*.luau"); do /home/hatch/.local/bin/luau-compile "$f" > /dev/null; done
   ```

3. **Package & test determinism:**
   ```bash
   mkdir -p out out2
   MAKEFUN_OUTPUT_DIR=out node main.ts
   MAKEFUN_OUTPUT_DIR=out2 node main.ts
   diff -r out out2
   ```

4. **Run makefun intake checks:**
   ```bash
   node /home/hatch/workspace/makefun/roblox-brainrot-01-kit/roblox-brainrot-01-kit/cli/makefun.mjs check \
     --kit /home/hatch/workspace/makefun/roblox-brainrot-01-kit/roblox-brainrot-01-kit \
     --repo /home/hatch/workspace/makefun/roblox-brainrot-01 \
     --worktree
   ```

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.
