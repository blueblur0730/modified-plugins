#if defined _l4d2_mixmap_setup_included
	#endinput
#endif
#define _l4d2_mixmap_setup_included

#define LOGGER_NAME								   "Mixmap"
#define LOGGER_ERROR_FILE						   "logs/l4d2_mixmap_errors.log"
#define TRANSLATION_FILE						   "l4d2_mixmap.phrases"
#define GAMEDATA_FILE							   "l4d2_mixmap"
#define CONFIG_BLACKLIST						   "configs/l4d2_mixmap_blacklist.cfg"
#define CONFIG_PRESET_FOLDER					   "configs/mixmap_presets"

#define ADDRESS_MATCHEXTL4D						   "g_pMatchExtL4D"
#define ADDRESS_NEEDTORESTORE					   "g_bNeedRestore"

#define SDKCALL_GETALLMISSIONS					   "CMatchExtL4D::GetAllMissions"
#define SDKCALL_GETALLMODES						   "CMatchExtL4D::GetAllModes"
#define SDKCALL_ONCHANGEMISSIONVOTE				   "CDirector::OnChangeMissionVote"
#define SDKCALL_ONCHANGECHAPTERVOTE				   "CDirector::OnChangeChapterVote"

#define DETOUR_TRANSITIONRESTORE				   "CTerrorPlayer::TransitionRestore"
#define DETOUR_DIRECTORCHANGELEVEL				   "CDirector::DirectorChangeLevel"
#define DETOUR_CTERRORGAMERULES_ONBEGINCHANGELEVEL "CTerrorGameRules::OnBeginChangeLevel"
#define DETOUR_RESTORETRANSITIONEDSURVIVORBOTS	   "RestoreTransitionedSurvivorBots"

#define MIDHOOK_RESTORETRANSITIONEDSURVIVORBOTS	   "RestoreTransitionedSurvivorBots__ChangeCharacter"

#define MEMPATCH_BLOCKRESTORING					   "RestoreTransitionedSurvivorBots__BlockRestoring"

GlobalForward
	g_hForwardStart,
	g_hForwardNext,
	g_hForwardInterrupt,
	g_hForwardEnd;

Address
	g_pMatchExtL4D,
	g_pTheDirector,
	g_bNeedRestore;

Handle
	g_hSDKCall_GetAllMissions,
	g_hSDKCall_GetAllModes,
	g_hSDKCall_OnChangeMissionVote,
	g_hSDKCall_OnChangeChapterVote;

MidHook g_hMidhook_ChangeCharacter;
MemoryPatch g_hPatch_BlockRestoring;

ConVar
	g_hCvar_Enable,
	g_hCvar_NextMapPrint,
	g_hCvar_SecondsToRead,
	g_hCvar_ManualSelectDelay,
	g_hCvar_PresetLoadDelay,
	g_hCvar_SaveStatus,
	g_hCvar_SaveStatus_Bot,
	g_hCvar_CheckPointSearchCount,
	g_hCvar_ShouldSearchAgain,
	g_hCvar_SearchAgainCount,
	g_hCvar_MapPoolCapacity,
	g_hCvar_EnableBlackList,
	g_hCvar_BlackListLimit;

void SetUpGameData()
{
	GameDataWrapper gd			  				= new GameDataWrapper(GAMEDATA_FILE);
	g_pMatchExtL4D				  				= gd.GetAddress(ADDRESS_MATCHEXTL4D);
	g_bNeedRestore								= gd.GetAddress(ADDRESS_NEEDTORESTORE);

	SDKCallParamsWrapper ret	  				= { SDKType_PlainOldData, SDKPass_Plain };
	g_hSDKCall_GetAllMissions	  				= gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_GETALLMISSIONS, _, _, true, ret);

	// use this to change to the first map of a mission.
	SDKCallParamsWrapper params[] 				= {{ SDKType_String, SDKPass_Pointer }};
	g_hSDKCall_OnChangeMissionVote 				= gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_ONCHANGEMISSIONVOTE, params, sizeof(params));

	SDKCallParamsWrapper ret1	   				= { SDKType_PlainOldData, SDKPass_Plain };
	g_hSDKCall_GetAllModes		   				= gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_GETALLMODES, _, _, true, ret1);

	// use this to change to a give map.
	SDKCallParamsWrapper params1[] 				= {{ SDKType_String, SDKPass_Pointer }};
	g_hSDKCall_OnChangeChapterVote 				= gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_ONCHANGECHAPTERVOTE, params1, sizeof(params1));

	gd.CreateDetourOrFailEx(DETOUR_TRANSITIONRESTORE, DTR_CTerrorPlayer_OnTransitionRestore);
	gd.CreateDetourOrFailEx(DETOUR_DIRECTORCHANGELEVEL, DTR_CDirector_OnDirectorChangeLevel);
	gd.CreateDetourOrFailEx(DETOUR_CTERRORGAMERULES_ONBEGINCHANGELEVEL, DTR_CTerrorGameRules_OnBeginChangeLevel);
	gd.CreateDetourOrFailEx(DETOUR_RESTORETRANSITIONEDSURVIVORBOTS, _, DTR_RestoreTransitionedSurvivorBots_Post)

	g_hMidhook_ChangeCharacter 					= gd.CreateMidHookOrFail(MIDHOOK_RESTORETRANSITIONEDSURVIVORBOTS, MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter, true);
	g_hPatch_BlockRestoring 					= gd.CreateMemoryPatchOrFail(MEMPATCH_BLOCKRESTORING);

	delete gd;
}

void SetupConVars()
{
	CreateConVar("l4d2_mixmap_version", PLUGIN_VERSION, "Version of the plugin.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	// global
	g_hCvar_Enable				  = CreateConVar("l4d2mm_enable", "1", "Whether to enable the plugin.", _, true, 0.0, true, 1.0);
	g_hCvar_NextMapPrint		  = CreateConVar("l4d2mm_nextmap_print", "1", "Whether to show what the next map will be.", _, true, 0.0, true, 1.0);
	g_hCvar_SecondsToRead		  = CreateConVar("l4d2mm_seconds_to_read", "5.0", "Determine how many seconds before change level to read maplist result.", _, true, 1.0);
	g_hCvar_ManualSelectDelay	  = CreateConVar("l4d2mm_manual_select_delay", "3.0", "Determine how many seconds before change level to manual select map.", _, true, 1.0)
	g_hCvar_PresetLoadDelay		  = CreateConVar("l4d2mm_preset_load_delay", "3.0", "Determine how many seconds before change level to load preset.", _, true, 1.0);

	// gameplay
	g_hCvar_SaveStatus		      = CreateConVar("l4d2mm_save_status", "1", "Whether to save player status in coop or realism mode after changing map.", _, true, 0.0, true, 1.0);
	g_hCvar_SaveStatus_Bot		  = CreateConVar("l4d2mm_save_status_bot", "1", "Whether to save bot status in coop or realism mode after changing map.", _, true, 1.0, false);
	g_hCvar_CheckPointSearchCount = CreateConVar("l4d2mm_checkpoint_search_count", "50", "Determine how many times to search for the checkpoint.", _, true, 1.0);
	g_hCvar_ShouldSearchAgain	  = CreateConVar("l4d2mm_should_re_search", "1", "Whether to re-search for the checkpoint if it is not found.", _, true, 0.0, true, 1.0);
	g_hCvar_SearchAgainCount	  = CreateConVar("l4d2mm_search_again_count", "3", "Determine how many times to re-search for the checkpoint.", _, true, 1.0);

	// map pool
	g_hCvar_MapPoolCapacity		  = CreateConVar("l4d2mm_map_pool_capacity", "5", "Determine how many maps can be selected in one pool.", _, true, 1.0);
	g_hCvar_EnableBlackList		  = CreateConVar("l4d2mm_enable_blacklist", "0", "Determine whether to enable blacklist.", _, true, 0.0, true, 1.0);
	g_hCvar_BlackListLimit		  = CreateConVar("l4d2mm_blacklist_limit", "10", "Determine how many maps can be listed into blacklist.", _, true, 1.0);
}

void SetupCommands()
{
	RegConsoleCmd("sm_mixmap", Command_Mixmap, "Vote to start a mixmap");
	RegConsoleCmd("sm_stopmixmap", Command_StopMixmap, "Stop a mixmap.");
	RegAdminCmd("sm_fmixmap", Command_ForceMixmap, ADMFLAG_BAN, "Force start mixmap");
	RegAdminCmd("sm_fstopmixmap", Command_ForceStopMixmap, ADMFLAG_BAN, "Force stop a mixmap");

	RegConsoleCmd("sm_mixmap_maplist", Command_Maplist, "Show the map list");
	RegAdminCmd("sm_mixmap_reload_blacklist", Command_ReloadBlackList, ADMFLAG_CONFIG, "Reload the blacklist file");
	RegConsoleCmd("sm_mixmap_blacklist", Commnad_ShowBlackList, "Show the blacklist");
	RegAdminCmd("sm_mixmap_reload_presetlist", Command_ReloadPresetList, ADMFLAG_CONFIG, "Reload all preset files.");
	RegConsoleCmd("sm_mixmap_presetlist", Command_PresetList, "Show the preset list");
}

void SetupLogger()
{
	g_hLogger = Logger.Get(LOGGER_NAME);
	if (!g_hLogger)
	{
		g_hLogger = ServerConsoleSink.CreateLogger(LOGGER_NAME);
		if (!g_hLogger)
			SetFailState("[Mixmap] Failed to create logger!")
	}

	// to not spam the console, default info.
	// you can set its level through log4sp_manager to real time debug.
	g_hLogger.SetLevel(LogLevel_Info);
	g_hLogger.FlushOn(LogLevel_Info);

	char sBuffer[64];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), LOGGER_ERROR_FILE);
	BasicFileSink sink = new BasicFileSink(sBuffer);
	sink.SetLevel(LogLevel_Warn);
	g_hLogger.AddSinkEx(sink);
}

void SetupForwards()
{
	g_hForwardStart		= new GlobalForward("Mixmap_OnStart", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hForwardNext		= new GlobalForward("Mixmap_OnKnownNext", ET_Ignore, Param_String);
	g_hForwardInterrupt = new GlobalForward("Mixmap_OnInterrupted", ET_Ignore);
	g_hForwardEnd		= new GlobalForward("Mixmap_OnEnd", ET_Ignore);
}

void SetupNatives()
{
	CreateNative("Mixmap_GetMapPool", Native_GetMapPool);
	CreateNative("Mixmap_GetMapCount", Native_GetMapCount);
	CreateNative("Mixmap_GetPlayedMapCount", Native_GetPlayedMapCount);
	CreateNative("Mixmap_HasStarted", Native_HasStarted);
	CreateNative("Mixmap_GetMapSetType", Native_GetMapSetType);
	CreateNative("Mixmap_GetPresetName", Native_GetPresetName); 
}

any Native_GetMapPool(Handle plugin, int numParams)
{
	if (!g_bMapsetInitialized)
		ThrowNativeError(SP_ERROR_NATIVE, "Mixmap hasn't started yet.");

	if (!plugin) ThrowNativeError(SP_ERROR_PARAM, "Invalid plugin handle: %d", plugin)

	return CloneHandle(g_hArrayPools, plugin);
}

int Native_GetMapCount(Handle plugin, int numParams)
{
	if (!g_bMapsetInitialized)
		ThrowNativeError(SP_ERROR_NATIVE, "Mixmap hasn't started yet.");

	return g_hArrayPools.Length;
}

int Native_GetPlayedMapCount(Handle plugin, int numParams)
{
	return g_iMapsPlayed;
}

any Native_HasStarted(Handle plugin, int numParams)
{
	return g_bMapsetInitialized;
}

any Native_GetMapSetType(Handle plugin, int numParams)
{
	return g_iMapsetType;
}

int Native_GetPresetName(Handle plugin, int numParams)
{
	int iLen = GetNativeCell(2);

	int iNewLen = iLen + 1;
	char[] sBuffer = new char[iNewLen];
	strcopy(sBuffer, iNewLen, g_sPresetName);
	SetNativeString(1, sBuffer, iNewLen);

	return 0;
}