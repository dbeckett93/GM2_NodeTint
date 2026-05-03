<p align="center">
  <img src="Media/nodetint-256.png" alt="GM2 NodeTint" width="256" height="256">
</p>

# GM2 NodeTint

**A companion addon for [GatherMate2](https://www.curseforge.com/wow/addons/gathermate2).** GM2 NodeTint does not replace GatherMate2 — it sits on top of it, hooks its existing pin pipeline, and adds per-node and per-category colour customisation to the pins GatherMate2 already shows. GatherMate2 is a hard dependency; GM2 NodeTint cannot run on its own.

What you get on top of GatherMate2: per-category and per-individual-node colour overrides on both the world map and the minimap, so you can tell similar nodes apart at a glance — for example colouring "Bismuth Deposit" differently from other nodes.

## Requirements

- [GatherMate2](https://www.curseforge.com/wow/addons/gathermate2) — required
- [GatherMate2_Data](https://www.curseforge.com/wow/addons/gathermate2_data) — optional but recommended (full per-node list in the options panel)

## Install

### From a release (recommended)

1. Grab the latest `GM2_NodeTint-<version>.zip` from the [Releases page](https://github.com/dbeckett93/GM2_NodeTint/releases).
2. Extract the `GM2_NodeTint` folder inside the zip into `World of Warcraft\_retail_\Interface\AddOns\`.
3. Restart the client (or `/reload` if it's already running).

The release zip contains only the runtime files (Lua, TOC, embedded Ace3, textures, in-game icon). It's ready to drop into the AddOns folder as-is.

### From source

```
git clone https://github.com/dbeckett93/GM2_NodeTint.git "World of Warcraft\_retail_\Interface\AddOns\GM2_NodeTint"
```

The source tree includes development-only files (`.github/`, `Media/*.png`, etc.) that the game ignores but that bloat the install slightly compared to the release zip.

## Usage

- `/gmnt` — open the options panel
- `/gmnt toggle` — flip the master enable/disable switch
- `/gmnt reset` — reset the active profile to defaults
- `/gm2nodetint` — long-form alias

The options panel has four tabs:

- **General** — master toggle, world-map / minimap toggles, profile reset.
- **Categories** — one colour swatch per category (Mining, Herb Gathering, Fishing, Logging, Extract Gas, Treasure, Archaeology). Applied to every node in the category unless overridden.
- **Per-Node** — drill into a category and assign a colour to a specific node. Per-node values override category defaults.
- **Profiles** — standard AceDB profile management (per-character by default, with copy / share between characters).

## Caveat: GatherMate2 tracking circles

When GatherMate2's *Track Distance* feature is enabled, close-range pins switch to a generic ring icon rather than the per-node icon. The colour you set in GM2 NodeTint still applies, but the visual icon distinction is lost in close range. Disable Track Distance in GatherMate2's own options if you want the icons back.

## Acknowledgements

GM2 NodeTint is built entirely on the foundation of [GatherMate2](https://www.curseforge.com/wow/addons/gathermate2). Sincere thanks to their development team for years of work on GatherMate and GatherMate2 — the data collection, the pin lifecycle, and the public hooks this addon depends on. None of GM2 NodeTint exists without their groundwork.

## Licence

MIT.
