#if defined __confogl_predictable_unloader_included
	#endinput
#endif
#define __confogl_predictable_unloader_included

/******************************************************************
*
* v1.0
* ------------------------
* ------- Details: -------
* ------------------------
* - Establishes Server Commands for the following:
* --> Unloading Plugins with the argument being the folder you want to unload the plugins from, leave the argument empty if you wish to unload just the main folder.
* --> Reserving Plugins, meaning these plugins will not be unloaded when the previously mentioned Plugin Unload is unloading the folder these plugins reside in.
* --> Unloading Reserved Plugins, this function will unload the reserved plugins in the order from "Last Reserved" to "First Reserved".

* v1.1
* ------------------------
* ------- Details: -------
* ------------------------
* - Overhauled it with keyCat's feedback in mind.
* --> Unloading Plugins with the pred_unload_plugins will push all currently loaded plugins to the Array and unloads them from Last loaded to First loaded. This way, dependencies should'nt be an issue.
* --> Removed the possibility of just Unloading Reserved Plugins... as there's no need for it?
*
*
* v1.2
* ------------------------
* ------- Details: -------
* ------------------------
* - Removed the unnecessary "ReservePlugin" function.
* - Added a failsafe after plugins are supposed to be unloaded, as we've seen some cases where this plugin would be the only one refusing to unload, thus never refreshing the plugins.
* - Added a less messy way of preventing double pushing, as this plugin is the only one that could possibly be double pushed. (StrEqual instead of FindInArray for every single plugin)
*
*
* v1.2.1
* ------------------------
* ------- Details: -------
* ------------------------
* - Removed the unnecessary "ReservePlugin" function.
* - Added a failsafe after plugins are supposed to be unloaded, as we've seen some cases where this plugin would be the only one refusing to unload, thus never refreshing the plugins.
* - Added a less messy way of preventing double pushing, as this plugin is the only one that could possibly be double pushed. (StrEqual instead of FindInArray for every single plugin)
*
* v1.2.2
* ------------------------
* ------- Details: -------
* ------------------------
* - Added sPlugin which will store this plugin's path on load, rather than looking it up during the "UnloadPlugins" function.
* - Added Timers for closing functionality of UnloadPlugins to ensure accuracy.
*
***************************************************************************************************************************************************************************************************
* ------------------------
* -------- NOTES: --------
* ------------------------
* - The plugin doesn't currently care about capitalization other than the Directory of the plugin, not sure if I can be bothered adding this :P
*
******************************************************************/

static ArrayList aReservedPlugins;
static char		 sPlugin[PLATFORM_MAX_PATH];
static bool		 bIsChMatch = false;

void PU_OnPluginStart()
{
	RegServerCmd("pred_unload_plugins", UnloadPlugins, "Unload Plugins!");

	// Gotta reserve ourself of course.
	// - Supports moving the plugin to another folder. (INVALID_HANDLE simply gets the calling plugin)
	GetPluginFilename(INVALID_HANDLE, sPlugin, sizeof(sPlugin));

	// Reserved Plugins
	aReservedPlugins = new ArrayList(PLATFORM_MAX_PATH);
}

public void LGO_OnChMatch()
{
	bIsChMatch = true;
}

public void LGO_OnMatchModeLoaded()
{
	bIsChMatch = false;
}

static Action UnloadPlugins(int args)
{
	if (bIsChMatch)
		return Plugin_Handled;

	char stockpluginname[64];
	Handle currentPlugin = null;
	PluginIterator pluginIterator = new PluginIterator();

	while (pluginIterator.Next())
	{
		currentPlugin = pluginIterator.Plugin;
		if (!currentPlugin)
			continue;

		GetPluginFilename(currentPlugin, stockpluginname, sizeof(stockpluginname));

		// We're not pushing this plugin itself into the array as we'll unload it on a timer at the end.
		if (!StrEqual(sPlugin, stockpluginname))
			aReservedPlugins.PushString(stockpluginname);
	}

	delete currentPlugin;	 // This one I probably don't have to close, but whatevs.
	delete pluginIterator;

	ServerCommand("sm plugins load_unlock");

	for (int iSize = aReservedPlugins.Length; iSize > 0; iSize--)
	{
		char sReserved[PLATFORM_MAX_PATH];
		aReservedPlugins.GetString(iSize - 1, sReserved, sizeof(sReserved));	// -1 because of how arrays work. :)
		ServerCommand("sm plugins unload %s", sReserved);
	}

	// Refresh first, then unload this plugin.
	// Using Timers because these are time crucial and ServerCommands aren't a 100% reliable in terms of execution order.
	CreateTimer(0.1, RefreshPlugins);
	CreateTimer(0.5, UnloadSelf);

	return Plugin_Handled;
}

static Action RefreshPlugins(Handle timer)
{
	ServerCommand("sm plugins refresh");

	return Plugin_Stop;
}

static Action UnloadSelf(Handle timer)
{
	ServerCommand("sm plugins unload %s", sPlugin);

	return Plugin_Stop;
}
