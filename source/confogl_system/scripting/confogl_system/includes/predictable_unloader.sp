#if defined __confogl_predictable_unloader_included
	#endinput
#endif
#define __confogl_predictable_unloader_included

static ArrayList aReservedPlugins;
static bool		 bIsChMatch = false;
static char		 sPlugin[PLATFORM_MAX_PATH];

void PU_OnPluginStart(const char[] sPluginName)
{

#if DEBUG_ALL
	PrintToServer("### PU_OnPluginStart: %s", sPluginName);
#endif

	strcopy(sPlugin, sizeof(sPlugin), sPluginName);
	RegServerCmd("pred_unload_plugins", UnloadPlugins, "Unload Plugins!");

	// Reserved Plugins
	aReservedPlugins = new ArrayList(PLATFORM_MAX_PATH);
}

void PU_OnPluginEnd()
{
	delete aReservedPlugins;
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
	Handle pluginIterator = GetPluginIterator();

	while (MorePlugins(pluginIterator))
	{
		currentPlugin = ReadPlugin(pluginIterator);
		if (!currentPlugin)
			continue;

		GetPluginFilename(currentPlugin, stockpluginname, sizeof(stockpluginname));

		// previously, predictable_unloader dose not depend it.
		// but now, predictable_unloader depends it (confogl_system depends on it). so, we will not unload this plugin.
		if (StrContains(stockpluginname, "left4dhooks.smx") != -1)
			continue;

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
	CreateTimer(0.1, Timer_RefreshPlugins);
	//CreateTimer(0.5, Timer_UnloadSelf);	// no need.

	return Plugin_Handled;
}

static Action Timer_RefreshPlugins(Handle timer)
{
#if DEBUG_ALL
	PrintToServer("### Timer_RefreshPlugins: Refreshing plugins now");
#endif
	ServerCommand("sm plugins refresh");

	return Plugin_Stop;
}

/*
static Action Timer_UnloadSelf(Handle timer)
{
#if DEBUG_ALL
	PrintToServer("### Timer_UnloadSelf: Unload self now");
#endif
	ServerCommand("sm plugins unload %s", sPlugin);

	return Plugin_Stop;
}
*/