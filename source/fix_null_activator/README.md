# [ANY] Fix Null Activator

### Introduction

- This plugin Fixes a crash caused by null activator when calling AcceptInput.
- Original Author: [GoD-Tony](https://forums.alliedmods.net/showthread.php?t=261173)
- [Previous Discussion](https://forums.alliedmods.net/showthread.php?t=261039)
- Currently supported games:
  - css
  - hl2dm
  - dods
  - tf2
  - l4d
  - l4d2
  - csgo

### How dose this become a bug?

- When calling `CBaseEntity::AcceptInput`, there could be chance that the activator player was disconnected or the activator entity was destroyed, which will cause the activator pointer to be null to pass to `CBaseEntity::AcceptInput`.
`CBaseEntity::AcceptInput` dose not perform any check for the null activator pointer, so once this null pointer is passed to the target input function and this function try to access the pointer, the game crashes. This could be existed in any source games and any entity that is related to this logic such as `game_ui`, `filter_* entity`, etc.

- This plugin detours the `CBaseEntity::AcceptInput` function and checks if the activator pointer is null before calling the target input function. If the activator pointer is null, `CBaseEntity::AcceptInput` will be skipped and won't call the target input function.