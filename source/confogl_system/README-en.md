# [L4D2/Any?] Confogl System

This is a simple guide on what is, and how to use the Confogl system.  

## Requirements

1. [log4sp extension](https://github.com/F1F88/sm-ext-log4sp).
2. (optional) l4d2_changelevel plugin.

## Installation

1. Put things on the sourcemod folder.  

2. Create your own configuration on `../cfg/cfgogl/<your_config>`, [See examples here](./source/confogl_system/cfg_template/).

3. Edit `matchmode.txt` to match the names.

## Functionality

### Choosing a configuration (MatchVote.sp/ReqMatch.sp)

Confogl System uses vote to choose a configuration using command `sm_match` from a text file called `matchmode.txt` on `addons/sourcemod/configs/`. The file is a KeyValues strcuture with a list of configurations. Normally, the strcuture is like this:  

```

"MatchModes"
{
    "ExampleConfig" // a basic class of a serious of configurations
    {
        // the folder name where the configurations exists: ../cfg/cfgogl/<folder_name>
        "example_type"  
        {
            // The configuration name displayed on the vote menu: "Example Name"
            "name"  "Example Name"
        }

        ""
        {
            "name"  ""
        }
        ...
    }

    ""
    {
        ...
    }
    ...
}
```  

Only strcuture like above is successfully displayed on the vote menu.  
Admins can use command `sm_forcematch <config_folder_name> <[optional] map_name>` to force loading a configuration.  
Confogl System uses built-in nativevote method to manage voting, not depending on builtinvote extension and nativevote plugin anymore.

### Loading a configuration (ReqMatch.sp)

This part introduces the process of loading a configuration.  

After choosing a config through `sm_match` or `sm_forcematch`, plugin will first check the folder `../cfg/cfgogl/<config_name>/...`. One config folder usually have 3 cfg files which is `confogl.cfg`, `confogl_off.cfg`, `confogl_plugins.cfg`. First, Confogl will execute command `sm plugins load_unlock` and `sm plugins unload_all` to remove all plugins, then execute the pre-set cfg file set by accessing convar `confogl_match_execcfg_plugins`. The value of the convar point to the cfg file that contains the list of plugins to load. By default, Confogl will search the file under the path `../cfg/cfgogl/<config_name>/confogl_pluigns.cfg`, if failed, Confogl will try searching default path `../cfg/confogl_pluigns.cfg`. Make sure all API plugins loaded first, respect the relation of loading dependence, and always make `confogl_system.smx` be the last one to be loaded, otherwise nothing will happen. Notice: you don't have to write `sm plugins load_lock` inside of the file, Confogl will do it automatically after.  
Then Confogl will search the file under the path `../cfg/cfgogl/<config_name>/confogl.cfg` by accessing convar `confogl_match_execcfg_on`, if failed, Confogl will try searching default path `../cfg/confogl.cfg`. The cfg file contains the list of convars to monitor and restrict. 
Finally, Confogl will restart the current map or load a specific map to complete loading, and uses `sm plugins load_lock` to lock loading.

### Unloading a configuration (ReqMatch.sp/MatchVote.sp/predictable_unloader.sp)

Uses command `sm_rmatch` to call a vote to unload the current loaded configuration. Admins can use command `sm_resetmatch` to force unloading.  
When unloading, Confogl will search the file under the path `../cfg/cfgogl/<config_name>/confogl_off.cfg`, if failed, Confogl will try searching default path `../cfg/confogl_off.cfg`. The cfg file provides a space for user defined commands used to reset the change to the game. Then Confogl will unload all current loaded plugins one by one except itself, and finally push itself to be the last one to unload, then execute the command `sm plugins refresh` to load the default plugins. Here that is why I recommend you put `confogl_system.smx` beyond the folder `optional` or `disabled`.

### ConVar Monitoring and Restricting (CvarSetting.sp/ClientSettings.sp)

You can use server command `confogl_addcvar <cvar> <value>` to add a convar into the list. You can use server command `confogl_trackclientcvar <client_cvar> <hasMin> <min> [<hasMax> <max> [<action>]]` to track and restrict some certain client convars. After all lists complete, use server command `confogl_setcvars` to activate the monitoring and set the value for the convars, use server command `confogl_startclientchecking` to start a checking loop for client convars. These commands are usaully writen in `confogl.cfg`.  
To reset, uses server command `confogl_resetcvars` and `confogl_resetclientcvars` to clear the lists and stop tracking. These commands are usally writen in `confogl_off.cfg`.

### Other (BotKick.sp/PasswordSystem.sp/UnreserveLobby.sp)

1. Unreserve Lobby: Provides server command `sm_killlobbyers` to remove lobby reservation manually. Provides convar `confogl_match_killlobbyres` to determine whether to remove lobby reservation automatically when loaded a configuration.

2. Bot Kick: Kicks connected survivor and infected bots in L4D2.

3. Password System: Setting convar `sv_password` for players in the server and checks it when a new client connected through convar `confogl_password`.

## What is Confogl?

Confogl is a sourcemod plugin for managing plugin loading, monitoring and restrcting convar values during gameplay based on a configuration framework for choosing. It was first created by [Confogl Team](https://github.com/ConfoglTeam), which is a project mainly leading by [ProdigySim](https://github.com/ProdigySim). Confogl is composed with two parts: the framework of loading plugins and managing convars for specific configs which was called [LGOFNOC (League and Gaming Organization Framework for Normalized)](https://github.com/ConfoglTeam/LGOFNOC) and other functional plugins related to l4d2 the game itself. This project has gone through more than 14 years with many many contributors in L4D2 community to help fix and improve, enhance itself. This project was desinged to be used for l4d2 competitive versus game mode. It is now more wildly known as [confoglcompmod (Confogl's Competitive Mod)](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/confoglcompmod.sp) maintained and used by [L4D2 Competitive Rework community](https://github.com/SirPlease/L4D2-Competitive-Rework).  

Confogl System is a branch from [confoglcompmod (Confogl's Competitive Mod)](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/confoglcompmod.sp), the framework part that only keep the functionality to manage plugins and convars with configuration file with more enhancements and improvements.  

To be compatible with l4d2 competitive versus, the rest of confoglcompmod was made alone on the repo. Always load this part confoglcompmod.smx before confogl_system.smx can ensure configuration such as zomemod to work properly.  

Confogl System and its framework is a good choice for making multiple gameplay on one server. L4D2 for example, you can play coop, versus, scavenge, and other modes with different configurations defining which plugin to load and protecting convars both on server and client side from changing.

## What's new

1. Added logging system for the plugin, requires extension [log4sp](https://github.com/F1F88/sm-ext-log4sp).
2. Merged MatchVote and Predictable Unloader into Confogl.
3. Automatically unload plugins when unloading a configuration.
4. Uses built-in nativevote to replace builtinvote extension.
5. Full translation provided.
6. More details added and changed.
7. More to come..

## Credits to

1. [Confogl Team](https://github.com/ConfoglTeam), especially [ProdigySim](https://github.com/ProdigySim) for the overall framework construction.

2. [L4D2 Competitive Rework community](https://github.com/SirPlease/L4D2-Competitive-Rework) for the long term maintaining.

3. Forgetest, for his [improved code](https://github.com/Target5150/MoYu_Server_Stupid_Plugins/tree/master/The%20Last%20Stand/predictable_unloader) on predictable unloader.

4. Powerlord and fdxx for the codes of [nativevote](https://github.com/fdxx/l4d2_nativevote)

5. F1F88 for the extension [log4sp](https://github.com/F1F88/sm-ext-log4sp).

6. Many others that have contributed to confogl project that were not mentioned.

