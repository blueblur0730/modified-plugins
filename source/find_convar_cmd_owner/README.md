# [ANY] Find ConVar/Cmd Owner

### Introduction
 - An Alternative version of "dump_all_cmds_cvars" by Bacardi, this plugin dumps all sourcemod generated convars and cmds into a keyvalue file.  
 - The dumpped file is located at [sourcemod/data/dumpped_convars.txt | data/dumpped_commands.txt].

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

// 1 = File and path name, 2 = Descriptive name (It's not recommended to use 1 :p since the format looks pretty bad)
find_convar_cmd_owner_storenametype 2

// dump description and flags of the cvar and cmd, and the bounds of cvar. (by defualt, cvars have values and cmds have flags in the keyvalue file.)
find_convar_cmd_owner_dumpmore 1
```

### Server Commands
```
sm_dumpcvar
sm_dumpcmd
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
 *  - BUG: flags are overlapping when outputting cmds.
 */ 
```