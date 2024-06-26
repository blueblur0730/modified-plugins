# [ANY] Find ConVar Owner

### Introduction
 - A lite version of "dump_all_cmds_cvars" by Bacardi, this plugin dumps all sourcemod generated convars into a keyvalue file.  
 - The dumpped file is located at sourcemod/data/dumpped_convars.txt .

### Source
 - https://forums.alliedmods.net/showthread.php?p=2688799  

### Requirements
 - None  

<hr>

### ConVars
```
// Plugin Version
find_convar_owner_version

// hide the cvar of this plugin
find_convar_owner_hide 1

// 1 = File and path name, 2 = Descriptive name (It's not recommended to use 1 :p since the format looks pretty bad)
find_convar_owner_storenametype 2
```
<hr>

<hr>

### Server Commands
```
sm_dumpcvar
```
<hr>

### Notice
 - BUG: the number loopped through the function is totally not correct. But it dosen's affect the readability of the dumpped file.