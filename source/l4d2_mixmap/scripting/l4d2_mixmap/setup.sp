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
	g_pMatchExtL4D,
	g_pTheDirector;

Handle
	g_hSDKCall_GetAllMissions,
	g_hSDKCall_OnChangeMissionVote,
	g_hSDKCall_IsFirstMapInScenario,
	g_hSDKCall_DirectorChangeLevel,
	g_hSDKCall_ClearTransitionedLandmarkName;

DynamicDetour
	g_hDetour_RestoreTransitionedEntities,
	g_hDetour_TransitionRestore,
	g_hDetour_DirectorChangeLevel;

ConVar
	g_cvNextMapPrint,
	g_cvMapPoolCapacity,
	g_cvMaxMapsNum,
	g_cvSaveStatus;

void SetUpGameData()
{
	GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);
	g_pMatchExtL4D	   = gd.GetAddress(ADDRESS_MATCHEXTL4D);

	SDKCallParamsWrapper ret	  = { SDKType_PlainOldData, SDKPass_Plain };
	g_hSDKCall_GetAllMissions	  = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_GETALLMISSIONS, _, _, true, ret);

	// use this to change to the first map of a mission.
	SDKCallParamsWrapper params[] = {{ SDKType_String, SDKPass_Pointer }};
	g_hSDKCall_OnChangeMissionVote = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_ONCHANGEMISSIONVOTE, params, sizeof(params));

	SDKCallParamsWrapper ret1 = { SDKType_Bool, SDKPass_Plain };
	g_hSDKCall_IsFirstMapInScenario		  = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_ISFIRSTMAPINSCENARIO, _, _, true, ret1);

	g_hSDKCall_ClearTransitionedLandmarkName = gd.CreateSDKCallOrFail(SDKCall_Static, SDKConf_Signature, SDKCALL_CLEARTRANSITIONEDLANDMARKNAME);

	g_hDetour_RestoreTransitionedEntities = gd.CreateDetourOrFail(DETOUR_RESTORETRANSITIONEDENTITIES, true, DTR_OnRestoreTransitionedEntities);
	g_hDetour_TransitionRestore			  = gd.CreateDetourOrFail(DETOUR_TRANSITIONRESTORE, true, _, DTR_CTerrorPlayer_OnTransitionRestore_Post);
	g_hDetour_DirectorChangeLevel		  = gd.CreateDetourOrFail(DETOUR_DIRECTORCHANGELEVEL, true, DTR_CDirector_OnDirectorChangeLevel);

	delete gd;
}

void SetupConVars()
{
	g_cvNextMapPrint	= CreateConVar("l4d2mm_nextmap_print", "1", "Determine whether to show what the next map will be", _, true, 0.0, true, 1.0);
	g_cvMapPoolCapacity = CreateConVar("l4d2mm_map_pool_capacity", "5", "Determine how many maps can be selected in one pool; 0 = no limits;", _, true, 0.0, true, 10.0);
	g_cvMaxMapsNum		= CreateConVar("l4d2mm_max_maps_num", "2", "Determine how many maps of one campaign can be selected; 0 = no limits;", _, true, 0.0, true, 5.0);
	g_cvSaveStatus		= CreateConVar("l4d2mm_save_status", "1", "Determine whether to save player status in coop or realism mode after changing map.", _, true, 0.0, true, 1.0);
}

void SetupCommands()
{
	RegConsoleCmd("sm_mixmap", Command_Mixmap, "Vote to start a mixmap (arg1 empty for 'default' maps pool);通过投票启用Mixmap, 并可加载特定的地图池；无参数则启用官图顺序随机");
	RegConsoleCmd("sm_stopmixmap", Command_StopMixmap, "Stop a mixmap;中止mixmap, 并初始化地图列表");
	RegAdminCmd("sm_fmixmap", Command_ForceMixmap, ADMFLAG_ROOT, "Force start mixmap (arg1 empty for 'default' maps pool) 强制启用mixmap (随机官方地图)");
	RegAdminCmd("sm_fstopmixmap", Command_ForceStopMixmap, ADMFLAG_ROOT, "Force stop a mixmap ;强制中止mixmap, 并初始化地图列表");

	// RegConsoleCmd("sm_maplist", Command_Maplist, "Show the map list; 展示mixmap最终抽取出的地图列表");
	RegConsoleCmd("sm_allmaps", Command_ShowAllMaps, "Show all official maps code; 展示所有官方地图的地图代码");
}

void SetupForwards()
{
	g_hForwardStart		= new GlobalForward("Mixmap_OnStart", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardNext		= new GlobalForward("Mixmap_OnTransitioningNext", ET_Ignore, Param_String);
	g_hForwardInterrupt = new GlobalForward("Mixmap_OnInterrupted", ET_Ignore);
	g_hForwardEnd		= new GlobalForward("Mixmap_OnEnd", ET_Ignore);
}

void SetupNatives()
{
	CreateNative("Mixmap_GetMapSequence", Native_GetMapSequence);
	CreateNative("Mixmap_GetPlayedMapCount", Native_GetPlayedMapCount);
	CreateNative("Mixmap_HasStarted", Native_HasStarted);
}

int Native_GetMapSequence(Handle plugin, int numParams)
{
	char	  sBuffer[64];
	ArrayList hArray = view_as<ArrayList>(GetNativeCell(1));

	if (!g_bMapsetInitialized)
		ThrowNativeError(SP_ERROR_NATIVE, "Mixmap hasn't started yet.");
	else
	{
		if (hArray == null)
			return 0;

		for (int i = 0; i < g_hArrayPools.Length; i++)
		{
			g_hArrayPools.GetString(i, sBuffer, 64);
			hArray.PushString(sBuffer);
		}
	}

	return 0;
}

int Native_GetPlayedMapCount(Handle plugin, int numParams)
{
	return g_iMapsPlayed;
}

int Native_HasStarted(Handle plugin, int numParams)
{
	return g_bMapsetInitialized ? true : false;
}