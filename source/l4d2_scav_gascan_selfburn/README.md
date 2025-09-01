# [L4D2] Scavenge Gascan Self Burn

### Introduction
 - Original author: ratchetx
 - This plugin ignites the gascan that is unreachable caused by boomer blast/dropping or throwing manully in scavenge mode.
 - New feature:
   - Added a convar to set the limit of burned gascans.
   - All map is supported by setting safe boundery through keyvalues.
   - Translation supported.

### Source
 - https://forums.alliedmods.net/showthread.php?p=1648508

### Requirements
  - [colors.inc](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/include/colors.inc) to compile
  - Configs are set manully otherwise plugin wont do anything.

### ConVars
```
// plugin version
l4d2_scav_gascan_selfburn_version

// Enable limited gascan burn
l4d2_scav_gascan_burned_limit_enable 1

// Limits the max amout ofgascan that can get burned if they are out of bounds.
l4d2_scav_gascan_burned_limit 4

// The frequency on checking the igniting condition
l4d2_scav_gascan_check_frequency 3.0
```

### Notice
 - The value in the config file should be float point value and should not be 0.0 or nothing. 0.0 or nothing will be considered as an ignorance on this boundery check. Know what you are doing if you want to set it to 0.0 or nothing.