#if defined __reg_match_included
	#endinput
#endif
#define __reg_match_included

#define RM_MODULE_NAME "ReqMatch"

#define MAPRESTARTTIME 3.0
#define RESETMINTIME   60.0

static bool
	// RM_bMatchRequest[2] = {false, ...},
	RM_bIsAMatchActive	= false,
	RM_bIsPluginsLoaded = false,
	RM_bIsMapRestarted	= false;

static GlobalForward
	RM_hFwdMatchLoad   = null,
	RM_hFwdMatchUnload = null;

static ConVar
	RM_hSbAllBotGame	   = null,
	RM_hDoRestart		   = null,
	RM_hReloaded		   = null,
	RM_hChangeMap		   = null,
	RM_hAutoLoad		   = null,
	RM_hAutoCfg			   = null,
	RM_hConfigFile_On	   = null,
	RM_hConfigFile_Plugins = null,
	RM_hConfigFile_Off	   = null;

void RM_APL()
{
	RM_hFwdMatchLoad   = CreateGlobalForward("LGO_OnMatchModeLoaded", ET_Ignore, Param_String, Param_String);	 // LGO_OnMatchModeLoaded(const char[] config, const char[] maps)
	RM_hFwdMatchUnload = CreateGlobalForward("LGO_OnMatchModeUnloaded", ET_Ignore, Param_String);				 // LGO_OnMatchModeUnloaded(const char[] config)

	CreateNative("LGO_IsMatchModeLoaded", native_IsMatchModeLoaded);
}

void RM_OnModuleStart()
{
	RM_hDoRestart		   = CreateConVarEx("match_restart", "1", "Sets whether the plugin will restart the map upon match mode being forced or requested", _, true, 0.0, true, 1.0);
	RM_hAutoLoad		   = CreateConVarEx("match_autoload", "0", "Has match mode start up automatically when a player connects and the server is not in match mode", _, true, 0.0, true, 1.0);
	RM_hAutoCfg			   = CreateConVarEx("match_autoconfig", "", "Specify which config to load if the autoloader is enabled");
	RM_hConfigFile_On	   = CreateConVarEx("match_execcfg_on", "confogl.cfg", "Execute this config file upon match mode starts and every map after that.");
	RM_hConfigFile_Plugins = CreateConVarEx("match_execcfg_plugins", "confogl_plugins.cfg;sharedplugins.cfg", "Execute this config file upon match mode starts. This will only get executed once and meant for plugins that needs to be loaded.");	  // rework
	RM_hConfigFile_Off	   = CreateConVarEx("match_execcfg_off", "confogl_off.cfg", "Execute this config file upon match mode ends.");

	CreateConVarEx("match_name", "", "The name of the match mode, only used for presentation globally.");

	RegAdminCmd("sm_forcematch", RM_Cmd_ForceMatch, ADMFLAG_CONFIG, "Forces the game to use match mode");
	RegAdminCmd("sm_resetmatch", RM_Cmd_ResetMatch, ADMFLAG_CONFIG, "Forces match mode to turn off REGRADLESS for always on or forced match");

	RM_hSbAllBotGame = FindConVar("sb_all_bot_game");
	RM_hReloaded	 = FindConVarEx("match_reloaded");

	if (RM_hReloaded == null)
		RM_hReloaded = CreateConVarEx("match_reloaded", "0", "DONT TOUCH THIS CVAR! This is to prevent match feature keep looping, however the plugin takes care of it. Don't change it!", FCVAR_DONTRECORD | FCVAR_UNLOGGED);

	RM_hChangeMap = FindConVarEx("match_map");

	if (RM_hChangeMap == null)
		RM_hChangeMap = CreateConVarEx("match_map", "", "DONT TOUCH THIS CVAR! This is to store the map that we'll be changing to", FCVAR_DONTRECORD | FCVAR_UNLOGGED);

	if (RM_hReloaded.BoolValue)
	{
		g_hLogger.DebugEx("[%s] Plugin was reloaded from match mode, executing match load", RM_MODULE_NAME);
		RM_bIsPluginsLoaded	   = true;
		RM_hReloaded.BoolValue = false;
		RM_Match_Load();
	}

	// ChangeLevel
	g_bIsChangeLevelAvailable = LibraryExists("l4d2_changelevel");
}

void RM_OnMapStart()
{
	if (!RM_bIsMatchModeLoaded)
		return;

	g_hLogger.TraceEx("[%s] RM_OnMapStart() called, executing match config...", RM_MODULE_NAME);
	RM_Match_Load();
}

void RM_OnClientPutInServer()
{
	if (!RM_hAutoLoad.BoolValue || RM_bIsAMatchActive)
		return;

	char buffer[128];
	RM_hAutoCfg.GetString(buffer, sizeof(buffer));

	RM_UpdateCfgOn(buffer);
	RM_Match_Load();
}

static void RM_Match_Load()
{
	g_hLogger.TraceEx("[%s] RM_Match_Load() called.", RM_MODULE_NAME);

	if (!RM_bIsAMatchActive)
		RM_bIsAMatchActive = true;

	RM_hSbAllBotGame.SetInt(1);
	char sBuffer[128];

	if (!RM_bIsPluginsLoaded)
	{
		g_hLogger.TraceEx("[%s] Loading plugins and reload self", RM_MODULE_NAME);

		RM_bIsLoadingConfig	   = true;
		RM_hReloaded.BoolValue = true;
		RM_hConfigFile_Plugins.GetString(sBuffer, sizeof(sBuffer));

		// ExecuteCfg(sBuffer); //original
		// rework
		char sPieces[32][256];
		int	 iNumPieces = ExplodeString(sBuffer, ";", sPieces, sizeof(sPieces), sizeof(sPieces[]));

		// Unlocking and Unloading Plugins.
		ServerCommand("sm plugins load_unlock");
		ServerCommand("sm plugins unload_all");

		// Loading Plugins.
		for (int i = 0; i < iNumPieces; i++)
			ExecuteCfg(sPieces[i]);

		// rework end
		return;
	}

	if (RM_bIsMatchModeLoaded)
		return;

	RM_hConfigFile_On.GetString(sBuffer, sizeof(sBuffer));
	ExecuteCfg(sBuffer);

	g_hLogger.TraceEx("[%s] Match config executed", RM_MODULE_NAME);
	g_hLogger.TraceEx("[%s] Setting match mode active", RM_MODULE_NAME);

	RM_bIsMatchModeLoaded = true;
	IsPluginEnabled(true, true);

	CPrintToChatAll("%t %t", "Tag", "MatchModeLoaded");

	char sMap[PLATFORM_MAX_PATH];
	if (!RM_bIsMapRestarted && RM_hDoRestart.BoolValue)
	{
		RM_hChangeMap.GetString(sMap, sizeof(sMap));

		if (strlen(sMap) > 0)
			CPrintToChatAll("%t %t", "Tag", "ChangeMapTo", sMap);
		else
		{
			GetCurrentMap(sMap, sizeof(sMap));
			CPrintToChatAll("%t %t", "Tag", "RestartingMap");
		}

		DataPack hDp;
		CreateDataTimer(MAPRESTARTTIME, RM_Match_MapRestart_Timer, hDp);
		hDp.WriteString(sMap);
	}

	g_hLogger.InfoEx("[%s] Match mode loaded!", RM_MODULE_NAME);

	hCustomConfig.GetString(sBuffer, sizeof(sBuffer));
	Call_StartForward(RM_hFwdMatchLoad);
	Call_PushString(sBuffer);
	Call_PushString(sMap);
	Call_Finish();

	RM_bIsLoadingConfig = false;
}

void RM_Match_Unload(bool bForced = false)
{
	bool bIsHumansOnServer = IsHumansOnServer();

	if (!bIsHumansOnServer || bForced)
	{
		g_hLogger.TraceEx("[%s] Match is no longer active, sb_all_bot_game reset to 0, IsHumansOnServer %b, bForced %b", RM_MODULE_NAME, bIsHumansOnServer, bForced);
		RM_bIsAMatchActive = false;
		// RM_hSbAllBotGame.SetInt(0);
	}

	if (bIsHumansOnServer && !bForced)
		return;

	g_hLogger.TraceEx("[%s] Unloading match mode...", RM_MODULE_NAME);

	char sBuffer[128];
	RM_bIsMatchModeLoaded = false;
	IsPluginEnabled(true, false);
	RM_bIsMapRestarted	= false;
	RM_bIsPluginsLoaded = false;

	hCustomConfig.GetString(sBuffer, sizeof(sBuffer));
	Call_StartForward(RM_hFwdMatchUnload);
	Call_PushString(sBuffer);
	Call_Finish();

	CPrintToChatAll("%t %t", "Tag", "MatchModeUnloaded");

	RM_hConfigFile_Off.GetString(sBuffer, sizeof(sBuffer));
	ExecuteCfg(sBuffer);

	g_hLogger.InfoEx("[%s] Match mode unloaded!", RM_MODULE_NAME);
}

static Action RM_Match_MapRestart_Timer(Handle hTimer, DataPack hDp)
{
	ServerCommand("sm plugins load_lock");	  // rework
	g_hLogger.InfoEx("[%s] Restarting map...", RM_MODULE_NAME);

	char sMap[PLATFORM_MAX_PATH];
	hDp.Reset();
	hDp.ReadString(sMap, sizeof(sMap));

	if (g_bIsChangeLevelAvailable) L4D2_ChangeLevel(sMap);
	else ServerCommand("changelevel %s", sMap);

	RM_bIsMapRestarted = true;

	return Plugin_Stop;
}

bool RM_UpdateCfgOn(const char[] cfgfile, bool bPrint = true)
{
	if (SetCustomCfg(cfgfile))
	{
		CPrintToChatAll("%t %t", "Tag", "LoadingConfig", cfgfile);
		g_hLogger.InfoEx("[%s] Starting match on config %s", RM_MODULE_NAME, cfgfile);
		return true;
	}

	if (bPrint)
		CPrintToChatAll("%t %t", "Tag", "UsingDefault", cfgfile);

	return false;
}

static Action RM_Cmd_ForceMatch(int client, int args)
{
	if (RM_bIsMatchModeLoaded)
		return Plugin_Handled;

	g_hLogger.InfoEx("[%s] Match mode forced to load!", RM_MODULE_NAME);

	if (args < 1)
	{
		if (!client)
			g_hLogger_ServerConsole.Info("[Confogl] Please specify a config to load.");
		else
			CPrintToChat(client, "%t %t", "Tag", "SpecifyConfig");

		return Plugin_Handled;
	}

	char sBuffer[128];
	char sMap[PLATFORM_MAX_PATH];
	switch (GetCmdArgs())
	{
		case 1:
			GetCmdArg(1, sBuffer, sizeof(sBuffer));

		case 2:
		{
			GetCmdArg(1, sBuffer, sizeof(sBuffer));
			GetCmdArg(2, sMap, sizeof(sMap));
		}
	}

	PrepareLoad(client, sBuffer, sMap);
	return Plugin_Handled;
}

void PrepareLoad(int client, const char[] sBuffer, const char[] sMap)
{
	if (!RM_UpdateCfgOn(sBuffer, false))
	{
		if (!client)
			g_hLogger_ServerConsole.InfoEx("[Confogl] Config %s not found!", sBuffer);
		else
			CPrintToChat(client, "%t %t", "Tag", "RE_ConfigNotFound", sBuffer);

		return;
	}

	if (!strlen(sMap))
	{
		RM_Match_Load();
		return;
	}

	char sDisplayName[PLATFORM_MAX_PATH];
	if (FindMap(sMap, sDisplayName, sizeof(sDisplayName)) == FindMap_NotFound)
	{
		if (!client)
			g_hLogger_ServerConsole.InfoEx("[Confogl] Map %s not found!", sMap);
		else
			CPrintToChat(client, "%t %t", "Tag", "MapNotFound", sMap);

		return;
	}
	else
	{
		GetMapDisplayName(sDisplayName, sDisplayName, sizeof(sDisplayName));
		RM_hChangeMap.SetString(sDisplayName);
		RM_Match_Load();
	}
}

static Action RM_Cmd_ResetMatch(int client, int args)
{
	if (!RM_bIsMatchModeLoaded)
		return Plugin_Handled;

	g_hLogger.InfoEx("[%s] Match mode forced to unload!", RM_MODULE_NAME);
	RM_Match_Unload(true);

	return Plugin_Handled;
}

void RM_OnClientDisconnect(int client)
{
	if (!RM_bIsMatchModeLoaded || IsFakeClient(client))
		return;

	CreateTimer(RESETMINTIME, RM_MatchResetTimer);
}

static void RM_MatchResetTimer(Handle hTimer)
{
	RM_Match_Unload();
}

static any native_IsMatchModeLoaded(Handle plugin, int numParams)
{
	return RM_bIsMatchModeLoaded;
}
