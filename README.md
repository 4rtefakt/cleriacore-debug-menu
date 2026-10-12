# Debug Menu

For **Ys Origin** on CleriaCore. One page, **F1 > Mods > Debug Menu**, that changes anything about your game, up or
down:

| Section | What you can change |
|---|---|
| **Player** | Level (1 to 60), weapon tier, full HP, SP (add or empty the wallet) |
| **Skills** | Wind, Thunder and Fire: not owned, or level 1 to 3 |
| **Armor and leggings** | Each of your character's twelve pieces: owned or not, strengthened or not |
| **Items** | Every accessory, key, medallion, crest and tool: give one, take one |
| **Blessings** | Each of the 24 statue blessings, on or off |
| **Statue warps** | Unlock or lock every statue; warp to any of them |
| **Game flags** | Read and write any of the game's 512 flags |

The changes apply at once and are saved with the game like anything else. Nothing checks that they make sense for
the story: a key taken away after its door was opened is just gone, and a story flag set by hand is the story as
far as the game knows. Keep a save from before.

There is no hotkey: a mod can not read the keyboard in CleriaCore yet, so the menu is the mod's page in the F1
panel.

## Install

1. Download `4rtefakt.debug-1.0.0.cleriamod` from the [releases](../../releases).
2. Double-click it (or use F1 > Mods > *Install a mod file...*).
3. Turn **Debug Menu** on in F1 > Mods and restart CleriaCore.

Needs a CleriaCore with mod API 6.

## How it works

One Lua file, [main.lua](main.lua), about 190 lines: a dozen three-line functions, and a page whose rows call them.

```lua
-- a skill is three things: its artifact, the power it grants, and a level cell
local SKILLS = {{"Wind", 0x6B, 0x74, 0xB6}, {"Thunder", 0x6C, 0x75, 0xB7}, {"Fire", 0x6D, 0x76, 0xB8}}
function D.set_skill(k, level)
    local s = SKILLS[k]
    if level <= 0 then
        G.set_flag(s[2], 0) G.set_flag(s[3], 0) G.set_flag(s[4], 0)
    else
        G.set_flag(s[2], 1) G.set_flag(s[3], 1) G.set_flag(s[4], math.min(3, level) - 1)
    end
    P.refresh()
end
```

| Part | API |
|---|---|
| Level, SP, HP, weapon | `player.set_level`, `add_sp`, `set_hp`, `set_weapon_tier`, `refresh` |
| Items, skills, blessings, flags | `game.flag` / `set_flag`, `content.give`, `game.item_name` |
| Armor and leggings upgrades | `game.upgrade` / `set_upgrade` |
| Warps | `game.warp_unlocked` / `set_warp_unlocked`, `game.warp_to` |
| The menu | `cleria.ui.page`: sliders, choices, toggles, buttons, text fields |

## Tests

`python .dev/run.py` runs two cases through CleriaCore's headless harness, calling the same functions the page's
rows call: level 30 gives the game's own numbers (max HP 227, ATK 139, DEF 126), SP is set, weapon tier 4 raises
ATK to 168, a heal fills the HP; the Bronze Key is given and taken, an armor is given and strengthened, the wind
skill goes to level 2 and is removed, a blessing is set and cleared, every statue is unlocked.

Not covered: the page itself (the harness can not click it), the warp button, and what each change does to a real
playthrough.

## About

Written with AI assistance (Claude Code) as a showcase of the CleriaCore mod API, and tested as described above.
MIT license.
