#if defined __reg_match_included
	#endinput
#endif
#define __reg_match_included

#define RM_DEBUG	   false
#define RM_MODULE_NAME "ReqMatch"

#define MAPRESTARTTIME 3.0
#define RESETMINTIME   60.0

static bool
	RM_bDebugEnabled = RM_DEBUG,
	// RM_bMatchRequest[2] = {false, ...},
	RM_bIsMatchModeLoaded = false,
	RM_bIsAMatchActive	  = false,
	RM_bIsPluginsLoaded	  = false,
	RM_bIsMapRestarted	  = false,
	RM_bIsChmatchRequest = false;

static Handle
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
	RM_hFwdMatchLoad   = CreateGlobalForward("LGO_OnMatchModeLoaded", ET_Ignore);
	RM_hFwdMatchUnload = CreateGlobalForward("LGO_OnMatchModeUnloaded", ET_Ignore);

	CreateNative("LGO_IsMatchModeLoaded", native_IsMatchModeLoaded);
}



void RM_OnModuleStart()
{
	RM_hDoRestart		   = CreateConVarEx("match_restart", "1", "Sets whether the plugin will restart the map upon match mode being forced or requested", _, true, 0.0, true, 1.0);
	RM_hAutoLoad		   = CreateConVarEx("match_autoload", "0", "Has match mode start up automatically when a player connects and the server is not in match mode", _, true, 0.0, true, 1.0);
	RM_hAutoCfg			   = CreateConVarEx("match_autoconfig", "", "Specify which config to load if the autoloader is enabled");
	RM_hConfigFile_On	   = CreateConVarEx("match_execcfg_on", "confogl.cfg", "Execute this config file upon match mode starts and every map after that.");
	RM_hConfigFile_Plugins = CreateConVarEx("match_execcfg_plugins", "generalfixes.cfg;confogl_plugins.cfg;sharedplugins.cfg", "Execute this config file upon match mode starts. This will only get executed once and meant for plugins that needs to be loaded.");	   // rework
	RM_hConfigFile_Off	   = CreateConVarEx("match_execcfg_off", "confogl_off.cfg", "Execute this config file upon match mode ends.");

	RegAdminCmd("sm_forcematch", RM_Cmd_ForceMatch, ADMFLAG_CONFIG, "Forces the game to use match mode");
	RegAdminCmd("sm_fm", RM_Cmd_ForceMatch, ADMFLAG_CONFIG, "Forces the game to use match mode");
	RegAdminCmd("sm_resetmatch", RM_Cmd_ResetMatch, ADMFLAG_CONFIG, "Forces match mode to turn off REGRADLESS for always on or forced match");
	RegAdminCmd("sm_forcechangematch", RM_CMD_ChangeMatch, ADMFLAG_CONFIG, "Forces the match to be changed");
	RegAdminCmd("sm_fchmatch", RM_CMD_ChangeMatch, ADMFLAG_CONFIG, "Forces the match to be changed");

	RM_hSbAllBotGame = FindConVar("sb_all_bot_game");
	RM_hReloaded	 = FindConVarEx("match_reloaded");

	if (RM_hReloaded == null)
		RM_hReloaded = CreateConVarEx("match_reloaded", "0", "DONT TOUCH THIS CVAR! This is to prevent match feature keep looping, however the plugin takes care of it. Don't change it!", FCVAR_DONTRECORD | FCVAR_UNLOGGED);

	RM_hChangeMap = FindConVarEx("match_map");

	if (RM_hChangeMap == null)
		RM_hChangeMap = CreateConVarEx("match_map", "", "DONT TOUCH THIS CVAR! This is to store the map that we'll be changing to", FCVAR_DONTRECORD | FCVAR_UNLOGGED);

	if (RM_hReloaded.BoolValue)
	{
		if (RM_bDebugEnabled || IsDebugEnabled())
			LogMessage("[%s] Plugin was reloaded from match mode, executing match load", RM_MODULE_NAME);

		RM_bIsPluginsLoaded = true;
		RM_hReloaded.SetInt(0);
		RM_Match_Load();
	}

	// ChangeLevel
	g_bIsChangeLevelAvailable = LibraryExists("l4d2_changelevel");
}

void RM_OnMapStart()
{
	if (!RM_bIsMatchModeLoaded)
		return;

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] New map, executing match config...", RM_MODULE_NAME);

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
	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Match Load", RM_MODULE_NAME);

	if (!RM_bIsAMatchActive)
		RM_bIsAMatchActive = true;

	RM_hSbAllBotGame.SetInt(1);
	char sBuffer[128];

	if (!RM_bIsPluginsLoaded)
	{
		if (RM_bDebugEnabled || IsDebugEnabled())
			LogMessage("[%s] Loading plugins and reload self", RM_MODULE_NAME);

		RM_hReloaded.SetInt(1);
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

	RM_hConfigFile_On.GetString(sBuffer, sizeof(sBuffer));
	ExecuteCfg(sBuffer);

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Match config executed", RM_MODULE_NAME);

	if (RM_bIsMatchModeLoaded)
		return;

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Setting match mode active", RM_MODULE_NAME);

	RM_bIsMatchModeLoaded = true;
	IsPluginEnabled(true, true);

	CPrintToChatAll("%t %t", "Tag", "MatchModeLoaded");

	if (!RM_bIsMapRestarted && RM_hDoRestart.BoolValue)
	{
		char sMap[PLATFORM_MAX_PATH];
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

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Match mode loaded!", RM_MODULE_NAME);

	RM_bIsChmatchRequest = false;

	Call_StartForward(RM_hFwdMatchLoad);
	Call_Finish();
}

static void RM_Match_Unload(bool bForced = false)
{
	bool bIsHumansOnServer = IsHumansOnServer();

	if (!bIsHumansOnServer || bForced)
	{
		if (RM_bDebugEnabled || IsDebugEnabled())
			LogMessage("[%s] Match is no longer active, sb_all_bot_game reset to 0, IsHumansOnServer %b, bForced %b", RM_MODULE_NAME, bIsHumansOnServer, bForced);

		RM_bIsAMatchActive = false;
		RM_hSbAllBotGame.SetInt(0);
	}

	if (bIsHumansOnServer && !bForced)
		return;

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Unloading match mode...", RM_MODULE_NAME);

	char sBuffer[128];
	RM_bIsMatchModeLoaded = false;
	IsPluginEnabled(true, false);
	RM_bIsMapRestarted	= false;
	RM_bIsPluginsLoaded = false;

	Call_StartForward(RM_hFwdMatchUnload);
	Call_Finish();

	CPrintToChatAll("%t %t", "Tag", "MatchModeUnloaded");

	RM_hConfigFile_Off.GetString(sBuffer, sizeof(sBuffer));

	if (!RM_bIsChmatchRequest)
		ExecuteCfg(sBuffer);
	else
	{
		// if we are using chmatch, don't let predictable_unloader unload confogl itself.
		// all plugins will be unload and load when the new config excuted.
		ServerCommand("sm plugins load_unlock");
		ServerCommand("sm plugins unload optional/predictable_unloader.smx");
		ExecuteCfg(sBuffer);
	}

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Match mode unloaded!", RM_MODULE_NAME);
}

static Action RM_Match_MapRestart_Timer(Handle hTimer, DataPack hDp)
{
	ServerCommand("sm plugins load_lock");	  // rework

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Restarting map...", RM_MODULE_NAME);

	char sMap[PLATFORM_MAX_PATH];
	hDp.Reset();
	hDp.ReadString(sMap, sizeof(sMap));

	if (g_bIsChangeLevelAvailable) L4D2_ChangeLevel(sMap);
	else ServerCommand("changelevel %s", sMap);

	RM_bIsMapRestarted = true;

	return Plugin_Stop;
}

static bool RM_UpdateCfgOn(const char[] cfgfile, bool bIsPrint = true)
{
	if (SetCustomCfg(cfgfile))
	{
		CPrintToChatAll("%t %t", "Tag", "LoadingConfig", cfgfile);

		if (RM_bDebugEnabled || IsDebugEnabled())
			LogMessage("[%s] Starting match on config %s", RM_MODULE_NAME, cfgfile);

		return true;
	}

	if (bIsPrint)
		CPrintToChatAll("%t %t", "Tag", "UsingDefault", cfgfile);

	return false;
}

static Action RM_Cmd_ForceMatch(int client, int args)
{
	if (RM_bIsMatchModeLoaded)
		return Plugin_Handled;

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Match mode forced to load!", RM_MODULE_NAME);

	if (args < 1)
	{
		// SetCustomCfg(""); //old code
		// RM_Match_Load(); //old code

		if (client == 0)
			PrintToServer("[Confogl] Please specify a config to load.");
		else
			CPrintToChat(client, "%t %t", "Tag", "SpecifyConfig");
		return Plugin_Handled;
	}

	char sBuffer[128];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));

	// RM_UpdateCfgOn(sBuffer); //old code

	if (!RM_UpdateCfgOn(sBuffer, false))
	{
		if (client == 0)
			PrintToServer("[Confogl] Config %s not found!", sBuffer);
		else
			CPrintToChat(client, "%t %t", "Tag", "RE_ConfigNotFound", sBuffer);

		return Plugin_Handled;
	}

	char sMap[PLATFORM_MAX_PATH], sDisplayName[PLATFORM_MAX_PATH];

	if (args == 2)
	{
		GetCmdArg(2, sMap, sizeof(sMap));

		if (FindMap(sMap, sDisplayName, sizeof(sDisplayName)) == FindMap_NotFound)
		{
			if (client == 0)
				PrintToServer("[Confogl] Map %s not found!", sMap);
			else
				CPrintToChat(client, "%t %t", "Tag", "MapNotFound", sMap);

			return Plugin_Handled;
		}

		GetMapDisplayName(sDisplayName, sDisplayName, sizeof(sDisplayName));
		RM_hChangeMap.SetString(sDisplayName);
	}

	RM_Match_Load();

	return Plugin_Handled;
}

static Action RM_Cmd_ResetMatch(int client, int args)
{
	if (!RM_bIsMatchModeLoaded)
		return Plugin_Handled;

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Match mode forced to unload!", RM_MODULE_NAME);

	RM_Match_Unload(true);

	return Plugin_Handled;
}

static Action RM_CMD_ChangeMatch(int client, int args)
{
	if (args < 1)
	{
		if (client == 0)
			PrintToServer("[Confogl] Please specify a config to load.");
		else
			CPrintToChat(client, "%t %t", "Tag", "SpecifyConfig");

		return Plugin_Handled;
	}

	char sBuffer[128];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));

	if (!RM_UpdateCfgOn(sBuffer, false))
	{
		if (client == 0)
			PrintToServer("[Confogl] Config %s not found!", sBuffer);
		else
			CPrintToChat(client, "%t %t", "Tag", "RE_ConfigNotFound", sBuffer);

		return Plugin_Handled;
	}

	char sMap[PLATFORM_MAX_PATH], sDisplayName[PLATFORM_MAX_PATH];

	if (args == 2)
	{
		GetCmdArg(2, sMap, sizeof(sMap));

		if (FindMap(sMap, sDisplayName, sizeof(sDisplayName)) == FindMap_NotFound)
		{
			if (client == 0)
				PrintToServer("[Confogl] Map %s not found!", sMap);
			else
					CPrintToChat(client, "%t %t", "Tag", "MapNotFound", sMap);

			return Plugin_Handled;
		}

		GetMapDisplayName(sDisplayName, sDisplayName, sizeof(sDisplayName));
		RM_hChangeMap.SetString(sDisplayName);
	}

	// Unload
	if (!RM_bIsMatchModeLoaded)
		return Plugin_Handled;

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Match mode forced to unload! [Change in this case!]", RM_MODULE_NAME);

	RM_bIsChmatchRequest = true;
	RM_Match_Unload(true);

	// give time to fully finish unloading.
	CreateTimer(1.0, Timer_DelayToLoadMatchMode);

	return Plugin_Handled;
}

static Action Timer_DelayToLoadMatchMode(Handle timer)
{
	// Load
	if (RM_bIsMatchModeLoaded)
		return Plugin_Handled;

	if (RM_bDebugEnabled || IsDebugEnabled())
		LogMessage("[%s] Match mode forced to load! [Change in this case!]", RM_MODULE_NAME);

	RM_Match_Load();

	return Plugin_Handled;
}

void RM_OnClientDisconnect(int client)
{
	if (!RM_bIsMatchModeLoaded || IsFakeClient(client))
		return;

	CreateTimer(RESETMINTIME, RM_MatchResetTimer);
}

static Action RM_MatchResetTimer(Handle hTimer)
{
	RM_Match_Unload();

	return Plugin_Stop;
}

stock bool IsAMatchActive()
{
	return RM_bIsAMatchActive;
}

static int native_IsMatchModeLoaded(Handle plugin, int numParams)
{
	return RM_bIsMatchModeLoaded;
}
