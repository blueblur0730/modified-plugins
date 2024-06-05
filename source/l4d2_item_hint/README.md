# [L4D2] Item Hint

- Edited version from https://github.com/fbef0102/L4D2-Plugins/tree/master/l4d2_item_hint. Use before checking his documentation entirely.

<hr>

### Introduction

- This plugin mainly added 2 commands to manager your color of the spot and item hint. Color data can be saved through the config file.
- Config file uses keyvalues to store data and identify every player through SteamId, which means this function is only suitable for a small server played by several 10-20 players. Once data is stored, next time they will use the stored color when they enter the server. Of course you can edit file manually.

### Cvar

l4d2_item_hint_use_config <1/0>
- Should we use config file to specify every players' color? 1=on 0=off

### Commands

sm_setcolor
- Usage: sm_setcolor <spot/item> <r> <g> <b>. RGB Number must between 0-255. "l4d2_item_hint_use_config" must be on.
- Example: /setcolor spot 241 12 69

sm_resetcolor
- Clear all stored data in the config file. Note that the key SteamID won't be delete if you have set color before.

### Last
- Inspired(Requested?) by a friend.
- I didn't learn the database method of soucepawn and I don't have the such need so I just simply used keyvalues.
- Actually data can be stored in arrays to make this function more handy to use in rounds or times of game temporarily.
- multicolor.inc was replaced with color.inc.