#if defined _l4d2_mixmap_setup_included
	#endinput
#endif
#define _l4d2_mixmap_setup_included

GlobalForward
	g_hForwardStart,
	g_hForwardNext,
	g_hForwardInterrupt,
	g_hForwardEnd;

Address
	g_pMatchExtL4D;
	g_pTheDirector;

Handle
	g_hSDKCall_GetAllMissions,
	g_hSDKCall_OnChangeMissionVote,
	g_hSDKCall_ClearTransitionedLandmarkName;

ConVar
	g_hCvar_Enable,
	g_hCvar_NextMapPrint,
	g_hCvar_MapPoolCapacity,
	g_hCvar_SecondsToRead;
	//g_hCvar_SaveStatus;

void SetUpGameData()
{
	GameDataWrapper gd 							= new GameDataWrapper(GAMEDATA_FILE);
	g_pMatchExtL4D	   							= gd.GetAddress(ADDRESS_MATCHEXTL4D);
	g_pTheDirector								= gd.GetAddress(ADDRESS_THEDIRECTOR);

	SDKCallParamsWrapper ret	  				= { SDKType_PlainOldData, SDKPass_Plain };
	g_hSDKCall_GetAllMissions	  				= gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_GETALLMISSIONS, _, _, true, ret);

	// use this to change to the first map of a mission.
	SDKCallParamsWrapper params[] 				= {{ SDKType_String, SDKPass_Pointer }};
	g_hSDKCall_OnChangeMissionVote 				= gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_ONCHANGEMISSIONVOTE, params, sizeof(params));

	g_hSDKCall_ClearTransitionedLandmarkName 	= gd.CreateSDKCallOrFail(SDKCall_Static, SDKConf_Signature, SDKCALL_CLEARTRANSITIONEDLANDMARKNAME);

	gd.CreateDetourOrFailEx(DETOUR_RESTORETRANSITIONEDENTITIES, DTR_OnRestoreTransitionedEntities);
	gd.CreateDetourOrFailEx(DETOUR_TRANSITIONRESTORE, _, DTR_CTerrorPlayer_OnTransitionRestore_Post);
	gd.CreateDetourOrFailEx(DETOUR_DIRECTORCHANGELEVEL, DTR_CDirector_OnDirectorChangeLevel);
	gd.CreateDetourOrFailEx(DETOUR_CTERRORGAMERULES_ONBEGINCHANGELEVEL, DTR_CTerrorGameRules_OnBeginChangeLevel);

	delete gd;
}

void SetupConVars()
{
	CreateConVar("l4d2mm_version", PLUGIN_VERSION, "Version of the plugin.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hCvar_Enable			= CreateConVar("l4d2mm_enable", "1", "Determine whether to enable the plugin.", _, true, 0.0, true, 1.0);
	g_hCvar_NextMapPrint	= CreateConVar("l4d2mm_nextmap_print", "1", "Determine whether to show what the next map will be.", _, true, 0.0, true, 1.0);
	g_hCvar_MapPoolCapacity = CreateConVar("l4d2mm_map_pool_capacity", "5", "Determine how many maps can be selected in one pool.", _, true, 1.0, true, 10.0);
	g_hCvar_SecondsToRead	= CreateConVar("l4d2mm_seconds_to_read", "5", "Determine how many seconds before change level to read maplist result.", _, true, 5.0, true, 30.0);
	//g_hCvar_SaveStatus		= CreateConVar("l4d2mm_save_status", "1", "Determine whether to save player status in coop or realism mode after changing map.", _, true, 0.0, true, 1.0);
}

void SetupCommands()
{
	RegConsoleCmd("sm_mixmap", Command_Mixmap, "Vote to start a mixmap");
	RegConsoleCmd("sm_stopmixmap", Command_StopMixmap, "Stop a mixmap.");
	RegAdminCmd("sm_fmixmap", Command_ForceMixmap, ADMFLAG_BAN, "Force start mixmap");
	RegAdminCmd("sm_fstopmixmap", Command_ForceStopMixmap, ADMFLAG_BAN, "Force stop a mixmap");

	RegConsoleCmd("sm_maplist", Command_Maplist, "Show the map list");
}

/*
void SetupLogger()
{
	g_hLogger = Logger.Get(LOGGER_NAME);
	if (!g_hLogger)
	{
		g_hLogger = ServerConsoleSink.CreateLogger(LOGGER_NAME);
		if (!g_hLogger)
			SetFailState("[Mixmap] Failed to create logger!")
	}

	g_hLogger.SetLevel(LogLevel_Trace);
	g_hLogger.FlushOn(LogLevel_Info);
}
*/
void SetupForwards()
{
	g_hForwardStart		= new GlobalForward("Mixmap_OnStart", ET_Ignore, Param_Cell);
	g_hForwardNext		= new GlobalForward("Mixmap_OnTransitioningNext", ET_Ignore, Param_String);
	g_hForwardInterrupt = new GlobalForward("Mixmap_OnInterrupted", ET_Ignore);
	g_hForwardEnd		= new GlobalForward("Mixmap_OnEnd", ET_Ignore);
}

void SetupNatives()
{
	CreateNative("Mixmap_GetMapSequence", Native_GetMapSequence);
	CreateNative("Mixmap_GetPlayedMapCount", Native_GetPlayedMapCount);
	CreateNative("Mixmap_HasStarted", Native_HasStarted);
	CreateNative("Mixmap_GetMapSetType", Native_GetMapSetType);
}

any Native_GetMapSequence(Handle plugin, int numParams)
{
	if (!g_bMapsetInitialized)
		ThrowNativeError(SP_ERROR_NATIVE, "Mixmap hasn't started yet.");

	if (!plugin) ThrowNativeError(SP_ERROR_PARAM, "Invalid plugin handle: %d", plugin)

	return CloneHandle(g_hArrayPools, plugin);
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