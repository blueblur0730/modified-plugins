#if defined __confogl_predictable_unloader_included
	#endinput
#endif
#define __confogl_predictable_unloader_included

#define MODULE_PREDICTABLE_UNLOADER_NAME "PredictableUnloader"

void PU_OnPluginStart()
{
	RegServerCmd("pred_unload_plugins", Command_UnloadPlugins, "Unload Plugins!");
}

void PU_OnPluginEnd()
{
	// we merged this together, so dont let it confuse the loading process.
	if (!RM_bIsLoadingConfig)
	{
		g_hLogger.InfoEx("[%s] All plugins have been unloaded and refreshed.", MODULE_PREDICTABLE_UNLOADER_NAME);
		ServerCommand("sm plugins refresh");
	}
}

static Action Command_UnloadPlugins(int args)
{
	UnloadPlugins(args);
	return Plugin_Handled;
}

static void UnloadPlugins(int args)
{
	ArrayStack aReservedPlugins = new ArrayStack();
	Handle	   mySelf			= GetMyHandle();

	// Thanks to Forgetest.
	if (args == -1)
	{
		// Ourself as the last to unload.
		aReservedPlugins.Push(mySelf);
	}
	else
	{
		Handle currentPlugin  = null;
		Handle pluginIterator = GetPluginIterator();
		while (MorePlugins(pluginIterator))
		{
			currentPlugin = ReadPlugin(pluginIterator);
			if (!currentPlugin)
				continue;

			// We're not pushing ourselves into the array as we'll unload it on a timer at the end.
			if (currentPlugin != mySelf)
				aReservedPlugins.Push(currentPlugin);
		}

		delete pluginIterator;
	}

	ServerCommand("sm plugins load_unlock");

	char sReserved[PLATFORM_MAX_PATH];
	while (!aReservedPlugins.Empty)
	{
		Handle hPlugin = aReservedPlugins.Pop();
		GetPluginFilename(hPlugin, sReserved, sizeof(sReserved));
		ServerCommand("sm plugins unload %s", sReserved);
	}

	delete aReservedPlugins;

	if (args != -1)
	{
		CVS_OnModuleEnd();
		PS_OnModuleEnd();
		g_hLogger.InfoEx("[%s] Preparing for self unloading.", MODULE_PREDICTABLE_UNLOADER_NAME);
		RequestFrame(NextFrame_RefreshPlugins);
	}
}

static void NextFrame_RefreshPlugins()
{
	UnloadPlugins(-1);
}