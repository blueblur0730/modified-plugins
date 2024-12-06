#if defined __confogl_predictable_unloader_included
	#endinput
#endif
#define __confogl_predictable_unloader_included

static ArrayList aReservedPlugins;
static bool		 bIsChMatch = false;
static char		 sPlugin[PLATFORM_MAX_PATH];

void PU_OnPluginStart()
{
	// here we retrieve the plugin path for predictable unloader to use.
	GetPluginFilename(INVALID_HANDLE, sPlugin, sizeof(sPlugin));

#if DEBUG_ALL
	PrintToServer("### PU_OnPluginStart: %s", sPlugin);
#endif

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

		// We're not pushing ourselves into the array as we'll unload it on a timer at the end.
		if (!StrEqual(sPlugin, stockpluginname))
			aReservedPlugins.PushString(stockpluginname);
	}

	delete currentPlugin;	 // This one I probably don't have to close, but whatevs.
	delete pluginIterator;

	ServerCommand("sm plugins load_unlock");

	for (int iSize = aReservedPlugins.Length; iSize > 0; iSize--)
	{
		static char sReserved[PLATFORM_MAX_PATH];
		aReservedPlugins.GetString(iSize - 1, sReserved, sizeof(sReserved));	// -1 because of how arrays work. :)
		ServerCommand("sm plugins unload %s", sReserved);
	}

	// clear all buffers.
	aReservedPlugins.Clear();

	// this is going to need a hook. some status should be reset if we dont want to unload ourselves.
	CVS_OnModuleEnd();
	PS_OnModuleEnd();

	// Refresh first, then unload this plugin.
	// Using Timers because these are time crucial and ServerCommands aren't a 100% reliable in terms of execution order.
	CreateTimer(0.1, Timer_RefreshPlugins);

	return Plugin_Handled;
}

static void Timer_RefreshPlugins(Handle timer)
{
#if DEBUG_ALL
	PrintToServer("### Timer_RefreshPlugins: Refreshing plugins now");
#endif
	ServerCommand("sm plugins refresh");
}