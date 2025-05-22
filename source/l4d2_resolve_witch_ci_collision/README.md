# [L4D2] Resolve Witch CI Collision

## Introduction

Attemp to neutralize the collision between wandering witch and common infected.

## Requirement

- [MidHook Extension](https://github.com/Scags/SM-MidHooks) by Scags.
- [Action Extension](https://forums.alliedmods.net/showthread.php?t=336374) by BHaType.
- [gamedata_wrapper.inc](https://github.com/blueblur0730/modified-plugins/blob/main/include/gamedata_wrapper.inc)

## Recommend to Install With

- [resolve-collision-fix (nb_update_frequency fix)](https://forums.alliedmods.net/showthread.php?t=344019) by BHaType.

## ConVar

```
// The scale to scale the velocity vector. The greater closer to 1, the milder the speed changes.
z_witch_collision_neutralize_scale 0.95
```

## Explaination

This plugin dose not resolve the collision problem, instead, This is a compromise solution to minimize the force from the CI collision to witch. Witch will still being push away by CI but no longer shift away far from the original position.

This plugin is recommended to install with BHaType's resolve-collision-fix. This will most minimize the collision and shifting phonamenon.