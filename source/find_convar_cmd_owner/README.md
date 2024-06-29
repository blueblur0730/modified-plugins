# [ANY] Find ConVar/Cmd Owner

### Introduction
 - An Alternative and extended version of "dump_all_cmds_cvars" by Bacardi, this plugin dumps all sourcemod generated convars and cmds into a keyvalue file.  
 - This plugin can find the plugin by given a cvar/cmd, or find the cvar/cmd by given the plugin name.
 - The dumpped file is located at `sourcemod/data/find_convar_cmd_owner/..`. Create the folder if you dont have it.

### Source
 - https://forums.alliedmods.net/showthread.php?p=2688799  

### Requirements
 - None  

<hr>

### ConVars
```
// Plugin Version
find_convar_cmd_owner_version

// hide the cvar of this plugin
find_convar_cmd_owner_hide 1

// 1 = File and path name, 2 = Descriptive name
find_convar_cmd_owner_storenametype 1

// dump description and flags of the cvar and cmd, and the bounds of cvar.
// by defualt, cvars have values and cmds have flags in the keyvalue file.
find_convar_cmd_owner_dumpmore 1
```

### Server Commands
```
// dump all convars into a keyvalue file.
sm_dumpcvar

// dump all cmds into a keyvalue file.
sm_dumpcmd

// find a cvar/cmd's owner. Usage: sm_find_its_owner <cvar/cmd>, the result will appear on the server console.
sm_find_its_owner

// Usage: sm_find_its_concvar <plugin_file_name.smx>, the result will appear on the data/find_convar_cmd_owner/<plugin_name>.txt.
// Note: just type in the file name with .smx and you dont need to fill the path to it.
// Example: sm_find_its_concvar left4dhooks.smx
// It's especially useful when you have dont have the plugin's source file.
sm_find_its_concvar
```
<hr>

### Changelog
```
/** changelog:
 * 1.0: 
 * 	- initial release.
 * 
 * 1.1: 
 * 	- fixed a problem when plugin name has the '/' slash character.
 * 	- fixed that there's only one cvar printed per plugin.
 * 
 * 1.2: 
 * 	- support cmd dumpping.
 *  - variables renamed.
 *  - logics improved.
 *  - path key now use ' | ' to replace '_'
 *  - added a new convar 'find_convar_cmd_owner_dumpmore'.
 * 
 * 1.2.1:
 *  - unneeded code removed.
 * 
 * 1.2.2:
 *  - fixed convars don't have a defualt flag.
 *  - fixed flags are overlapping in the convars dumpping.
 *  - formatted cvar flag output.
 *
 *  - BUG: flags are overlapping when outputting cmds.
 * 
 * 2.0:
 *  - added cmd 'sm_find_its_owner' to find a cvar/cmd's owner.
 *  - added cmd 'sm_find_its_concvar' to find a plugin's cvar/cmd.
 *
 *  - BUG 'sm_find_its_concvar' casues server crash when specifiying some certain plugin, most probably caused when a plugin have 
 *    multiple source files. such as NekoSpecials.
 *    
 */ 
```