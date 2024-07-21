# [L4D2] Scavenge Quick End

### Introduction
 - Original Author: ProdigySim.
 - This plugin checks various tiebreaker win conditions mid-round and ends the round as necessary.
 - New Features:
   - Command "sm_time" now supports to check previous round data.
   - Winning Condition is explictly stated in the plugin (3 types).
   - Translation supported. Syntax is up to date.

### Source
 - https://github.com/HouseHse/Scavogl/blob/master/addons/sourcemod/scripting/scavenge_quick_end.sp

### Requiements
 - l4d2_scav_stocks.inc
 - colors.inc

### ConVars
```
// Plugin Version
scavenge_quick_end_version

// Only enable quick end or not, Printing time is not included by this cvar.
l4d2_enable_scavenge_quick_end 1
```

### Commands
```
// Check round status.
// Empty argument for current round,
// <round> argument for a round specified, valid range is 1-5. (based on the round limit your server has.)
// Example: sm_time 3 for checking round 3.
// Notice: You cannot check a round that has not started yet or higher than the round range.
sm_time <round>
```

### Notice
 - For best user experience, please do not load this plugin during the game.