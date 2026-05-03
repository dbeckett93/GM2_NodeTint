<p align="center">
  <img src="Media/nodetint-256.png" alt="GM2 NodeTint" width="256" height="256">
</p>

# GM2 NodeTint

Per-node colour overrides for [GatherMate2](https://www.curseforge.com/wow/addons/gathermate2) gathering pins on the World of Warcraft retail client (Midnight 12.0.5).

GM2 NodeTint sits on top of GatherMate2 and recolours its world-map and minimap pins on a per-category and per-individual-node basis, so you can tell similar nodes apart at a glance — for example colouring "Bismuth Deposit" differently from the rest of "Mining".

## Requirements

- World of Warcraft Retail (Interface 120005, patch 12.0.5)
- [GatherMate2](https://www.curseforge.com/wow/addons/gathermate2) — required
- [GatherMate2_Data](https://www.curseforge.com/wow/addons/gathermate2_data) — optional but recommended (full per-node list in the options panel)

## Install

1. Download or clone the repo into your `World of Warcraft\_retail_\Interface\AddOns\GM2_NodeTint\` folder.
2. Restart the client (or `/reload` if it's already running).

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

## Licence

MIT.
