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

### How to use

- Open gamedata file "fix_null_activator.games.txt"
- Find "Key" section, add the potential server-crashed entity that is related to pass null activator pointer to CBaseEntity::AcceptInput to the list, following the format:

```
	"Keys"
	{
        // here to define how many entity we want to hook. should be equal to the number of "HookEntityx" below.
		"MaxEntityCount"	"10"

        // fill in the first blank with "HookEntityx", x means the number, has to be sequential.
		"HookEntity1"	"game_ui"   // the second blank is the entity name.
        "HookEntity2"	"filter_*"
        "HookEntityx"	"..."

        // here to define how many input command we want to check in the plugin. should be equal to the number of "Commandx" below.
		"MaxCommandCount"	"2"

        // fill in the first blank with "Commandx", x means the number, has to be sequential.
		"Command1"	"Deactivate"	    // entity 'game_ui' inputs "Deactivate".
		"Command2"	"TestActivator"		// entity 'filter_*' inputs "TestActivator".
	}
```

- Every change applys on next map start.

### How dose this become a bug?

- When calling `CBaseEntity::AcceptInput`, there could be chance that the activator player was disconnected or the activator entity was destroyed, which will cause the activator pointer to be null to pass to `CBaseEntity::AcceptInput`.
`CBaseEntity::AcceptInput` dose not perform any check for the null activator pointer, so once this null pointer is passed to the target input function and this function try to access the pointer, the game crashes. This could be existed in any source games and any entity that is related to this logic such as `game_ui`, `filter_* entity`, etc.

- This plugin detours the `CBaseEntity::AcceptInput` function and checks if the activator pointer is null before calling the target input function. If the activator pointer is null, `CBaseEntity::AcceptInput` will be skipped and won't call the target input function.