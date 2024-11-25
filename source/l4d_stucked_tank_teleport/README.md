# [L4D1 & 2] Stucked Tank Teleport

### Introduction

- This plugins stops tank from death when gets stucked or loses its target for too long, and finally teleport them to somewhere near survivors.
- Credits to:
  - Scag, for MidHook extension.
  - 东, for his algorithms of choosing a spawn point to teleport a tank.
  - 夜羽真白, for various methods used in teleportation.

### Requirements

- [MidHook Extension](https://github.com/Scags/SM-MidHooks).
  - [Alliedmodders](https://forums.alliedmods.net/showthread.php?t=343973).
- SourceScarmble Extention.
- DHook.
- Left 4 DHooks Direct.
- colors.inc

### Note

- This plugin is recommended to use with vanilla gameplay, becuase the way this plugin to know whether a tank is stucked is completly depends on game itself. Or you know what you need.

### Convars

```
// Teleport the tank after stoping the suicide in this seconds.
// default: 3.0
// min: 0.1
l4d2_stucked_tank_teleport_timer

// Should teleport the tank or not. Set 0 will allow the tank to suicide.
// default: 1
l4d2_stucked_tank_teleport_should_teleport

// How many damage the tank should be panished after stucked for too long.
// default: 0.0 (prevent suicide)
// min: 0.0
l4d2_stucked_tank_teleport_suicide_damage

// How many times to search for a spawn point to teleport the tank.
// default: 20
// min: 1
l4d2_stucked_tank_teleport_path_search_count

// Should check the visibility from tank to survivors of the spawn point or not.
// defualt: 0
l4d2_stucked_tank_teleport_should_check_visibility

// Distance from the choosen survivor to make a spawn point the tank. Recommended: 500.0 < x < 2000.0
// default: 1000.0
// min: 1.0
l4d2_stucked_tank_teleport_distance

// Play notice sound when the tank is teleported.
// deafault: 1
l4d2_stucked_tank_teleport_notice_sound

// Highlight the tank when it is teleported.
// default: 1
l4d2_stucked_tank_teleport_highlight_tank

// Time to highlight the tank when it is teleported
// default: 3.0
l4d2_stucked_tank_teleport_highlight_time
```

### API

```sourcepawn
/**
 * Called when a bot tank tried to suicide for stucked or lost its target for too long.
 * 
 * @note This is a hook using MidHook to hook the middle of the function call: TankAttack::Update.
 * @note Called when passing the aruguments to CTakeDamageInfo::CTakeDamageInfo,
 * @note Specifically, when the damage value has been moved into register xmm0 and this plugin has set the damage to some value.
 * 
 * @param tank      client index of the tank.
 * 
 * @noreturn  
*/
forward void MidHook_OnTankSuicide(int tank);
```

### ChangeLog

- 10/1/24 v1.0
  - Initial release.

- 10/1/24 v1.1
  - Added more convars.
  - Fixed translation error.

- 10/2/24 v1.2
  - Fixed a bug that tank keeps 'suiciding' and teleporting after first teleportation.
  - Now should support the sence where multiple tank exists.
  - Now logs error message when failed to enable/disable the hook, just for the general gameplay.
  - Use 'L4D2_CommandABot' to replace 'Logic_RunScript'.

- 10/2/24 v1.3
  - Added 3 convars. Options for below.
  - Added a notice sound when the tank is teleported.
  - Added a highlight effect when the tank is teleported.

- 11/22/24 v1.4
  - Fixed byte pathing on L4D2 windows.
  - Removed some useless event code and comments.
  - Added supports for L4D1.

- 11/23/24 v1.4.2
  - Fixed some logic bugs.

- 11/23/24 v1.4.3
  - Fixed unused memory. Thanks to Lin for notification.

- 11/26/24 v1.4.4
  - Fixed a memory leak when unloading the plugin.
  - Make the failure notification not that annoyingly get printed.

### Some Thoughts

``
Tanks get suicided when they are stucked for too long, but this is happened inside a complex function: TankAttack::Update.
By simply detouring and patching this function is quite hacky, which needs a lot more steps.
By the way we make our own timer detection using sourcemod, which it is not accurate and resource consuming.
MidHook extension resolves the both. It is a effective way to handle the little things in a giant.
``
