#if defined __confogl_predictable_unloader_included
	#endinput
#endif
#define __confogl_predictable_unloader_included

void PU_OnPluginStart()
{
	RegServerCmd("pred_unload_plugins", UnloadPlugins, "Unload Plugins!");
}

void PU_OnPluginEnd()
{
	// we merged this together, so dont let it confuse the loading process.
	if (!RM_bIsLoadingConfig)
		ServerCommand("sm plugins refresh");
}

static Action UnloadPlugins(int args)
{
	ArrayStack aReservedPlugins = new ArrayStack();
	Handle mySelf = GetMyHandle();

	// Thanks to Forgetest.
	if (args == -1)
	{
		// Ourself as the last to unload.
		aReservedPlugins.Push(mySelf);
	}
	else
	{
		Handle currentPlugin = null;
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

	// this is going to need a hook. some status should be reset if we dont want to unload ourselves.
	if (args != -1) 
	{
		CVS_OnModuleEnd();
		PS_OnModuleEnd();
		RequestFrame(NextFrame_RefreshPlugins);
	}

	return Plugin_Handled;
}

static void NextFrame_RefreshPlugins()
{
	UnloadPlugins(-1);
}