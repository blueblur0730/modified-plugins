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
  - (colors.inc)[https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/include/colors.inc] to compile
  - Configs are set manully otherwise plugin wont do anything.

### ConVars
```
// plugin version
l4d2_scav_gascan_selfburn_version

// Enable limited gascan burn
l4d2_scav_gascan_burned_limit_enable 1

// Limits the max amout ofgascan that can get burned if they are out of bounds.
l4d2_scav_gascan_burned_limit 4
```

### Notice
 - The value in the config file should be float point value and should not be 0.0 or nothing. 0.0 or nothing will be considered as an ignorance on this boundery check. Know what you are doing if you want to set it to 0.0 or nothing.

### CHANGELOG
```
/* Change log:
 * 
 * - 3.0: 7/13/24
 *  - Use OnVPhysicsUpdatePost (SDKHook) to track gascan's position instead of globally retriving all gascans' coordinates by repeatable timer during the whole round.
 *  - Use StringMap to store the config informations instead of using enum struct.
 *  - Removed coordinate related convars. Now if nothing is found in the given key, plugin will skip the check on this coodinate boundery.
 *  - Removed convar "l4d2_scav_gascan_burn_interval", now check time is hardcoded as 3.0 (SAFE_BUFFER_TIME). (will consider if there is need to make it a convar.)
 *  - Use "m_vecAbsOrigin" instead of "m_vecOrigin" to retrive the position of gascan.
 * 
 * - 2.8: 12/23/23
 *  - optimized the logic of detect count and Kv.
 *  - optimized varibles' name and code format.
 *  - added cvar change hook.
 *  - removed plugin enable cvar
 *  - removed event hook "scavenge_round_end"
 *  - added cvar "plugin version"
 * 
 * - 2.7.1: 9/26/23
 *  - Fixed a bug on comparing two float coordinates.
 *  - Sperated cvars.
 *  - Enable status adjusted.
 *
 * - 2.7: 9/18/23
 *	- Reconstructed codes.
 *   - Remove player auto suicide.
 *   - Change event "scavenge_round_start" to "round_start"
 *   - Fixed a bug the gascan don't get burned.
 *
 * - 2.6.4
 *	- Optimized the logic
 *		- CheckDetectCountThenIgnite() is no longer public.
 * 	- Cancelled the nessarity of left4dhooks. Made IsScavengeMode() function alone.
 *
 * - 2.6.3
 *	- Optimized the logic.
 *		- Fixed when current map name can not parse with coodinate, it caused players' death.
 *		- Coordinate parsing functions are no longer public. KillPlayer() function are no longer public.
 *
 * - 2.6.2
 *	- Optimized the logic.
 *
 * - 2.6.1
 *	- Now if a gascan were crossed two axies(such as x and z), it would be only seen as the same one transborder.
 *	- Added a new translation for noticing player the limit has been reached.
 *
 * - 2.6
 *	- Added two ConVars to control the limit of burned gascan to decide wether we choose to stop the igniting optionally.
 *	- Added optional translations
 *
 * - 2.5.2
 *	- Made the ConVar EnableKillPlayer control the g_hTimerK instead of controlling the function KillPlayer() itself.
 *	- Added back the detection of mapname c8m5 to decide whether the g_hTimerK should be activated.
 *
 * - 2.5.1
 *	- Changed varibles' name.
 *   - Added a new ConVar to control function KillPlayer().
 *
 * - 2.5
 *	- Added 2 ConVars to control the time every detection dose.
 *	- Saperated Square ConVar into 2 individual ConVars to detect x and y.
 *	- Deleted a function that is never being uesed.
 *	- Optimized the logic.
 *
 * - 2.4
 *	- Added a ConVar to debug the parse result.
 *   - Optimized the logic.
 *
 * - 2.3
 *	- Added 3 ConVars to control the coordinate detections
 *	- Added more coordinate detections to control the boundray the gascan will not get burned (or will get burned in another way to say).
 *	- Added coordinate detection to control the function KillPlayer(), which decided wether a player should die under the detection of z axie, instead of only detecting mapname c8m5.
 *
 * - 2.2
 * 	- Added a config file to configurate the height boundray where a gascan will be burned.
 *
 * - 2.1
 *	- Optimized codes.
 *	- supprted translations.
 *
 * - 2.0
 * 	- player will die under the c8m5 rooftop.
 * 	- supported new syntax.
 *
 */
```