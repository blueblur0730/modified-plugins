#if defined __confogl_predictable_unloader_included
	#endinput
#endif
#define __confogl_predictable_unloader_included

#define MODULE_PREDICTABLE_UNLOADER_NAME "PredictableUnloader"

void PU_OnPluginEnd()
{
	// we merged this together, so dont let it confuse the loading process.
	if (!RM_bIsLoadingConfig)
	{
		g_hLogger.InfoEx("[%s] All plugins have been unloaded and refreshed.", MODULE_PREDICTABLE_UNLOADER_NAME);
		ServerCommand("sm plugins refresh");
	}
}

void UnloadPlugins(int args)
{
	ArrayStack aReservedPlugins;
	Handle	   mySelf			= GetMyHandle();
	char sReserved[PLATFORM_MAX_PATH];

	// Thanks to Forgetest.
	if (args != -1)
	{
		aReservedPlugins = new ArrayStack();
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

		ServerCommand("sm plugins load_unlock");

		while (!aReservedPlugins.Empty)
		{
			Handle hPlugin = aReservedPlugins.Pop();
			GetPluginFilename(hPlugin, sReserved, sizeof(sReserved));

			if (StrContains(sReserved, "nativevotes.smx") != -1)
				continue;

			PrintToServer("[%s] Unloading plugin: %s", MODULE_PREDICTABLE_UNLOADER_NAME, sReserved);
			ServerCommand("sm plugins unload %s", sReserved);
		}

		delete aReservedPlugins;

		CVS_OnModuleEnd();
		PS_OnModuleEnd();
		g_hLogger.InfoEx("[%s] Preparing for self unloading.", MODULE_PREDICTABLE_UNLOADER_NAME);
		RequestFrame(NextFrame_RefreshPlugins);
	}
	else
	{
		GetPluginFilename(mySelf, sReserved, sizeof(sReserved));
		ServerCommand("sm plugins unload %s", sReserved);
	}
}

static void NextFrame_RefreshPlugins()
{
	UnloadPlugins(-1);
}