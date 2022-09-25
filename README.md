# Fireproof's Map Editor Tool updated by Korboy

### Getting started:
1. Download this repo and replace your current scripts (back them up first if you have changed anything you want to keep).
2. Launch game in dev mode.
3. Enter this command in console:

    `bind X "loadouts_devset character_selection character_bloodhound; ToggleThirdPerson; ToggleHUD; give mp_weapon_editor"; bind V "+offhand1"; bind T "ToggleThirdPerson"; bind F "noclip"; bind Q "+reload"; bind E "+use"; bind 3 "weapon_inspect"; bind 4 "+scriptCommand1"; bind 5 "+scriptCommand6"; bind R "+melee"; bind 6 "+offhand3"`

   * (Optional) This command is to bind F5 to refresh a map after making a change:

        `bind "F5" "changelevel mapname"`

        (replace `mapname` with the actual map's name)

        For example: `bind "F5" "changelevel mp_rr_desertlands_64k_x_64k"`

        You can also bind other keys to other map names as well.
4. Now press `X` and then `V` to start editing.

### Keybinds:
* `X` Switch legend to Bloodhound, switch to third person mode, and obtain prop tool.
* `V` Equip the prop tool.
* `T` Change perspective mode.
* `F` Toggle noclip.
* `MOUSE1` Place prop.
* `E` Cycle to next prop.
* `Q` Cycle to previous prop.
* `1` Raise prop.
* `2` Lower prop.
* `3` Change Yaw (z).
* `4` Change Pitch (y).
* `5` Change Roll (x).
* `6` Change snap size.
* `Z` Open the model menu.

### Saving and loading:
* Before you start editing, open the console
* [To save and load, use the tool and follow the instructions here](https://github.com/mostlyfireproof/R5Edit)
* __PLEASE SAVE FREQUENTLY__, as the game can and will crash at the worst possible time
* To use the map when hosting, copy the `mp_rr_<map>_common.nut` somewhere else (like your desktop), install the scripts with which you will host, then copy it back in

### Known Issues:
* You can't go in to the prop menu when the zipline is equipped (unintended feature)
* Doesn't work on KC S2 or Ash's Redemption

### Huge thanks to `mostly fireproof#2095`, `M͢1ke̵̲ͅp̴͖̙̞#9446`, and `Bogass#1210` for helping me with this.
#### <sub>If you want Fireproof's original map editor scripts, go [here](https://github.com/mostlyfireproof/scripts_r5/tree/SalEditor)<sub>
