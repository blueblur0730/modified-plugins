#if defined _l4d2_mixmap_setup_included
	#endinput
#endif
#define _l4d2_mixmap_setup_included

void SetUpGameData()
{
	GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);
	g_pMatchExtL4D = gd.GetAddress(ADDRESS_MATCHEXTL4D);

	g_pTheDirector = L4D_GetPointer(POINTER_DIRECTOR);
	if (g_pTheDirector == Address_Null)
		SetFailState("[MixMap] Failed to get director pointer!");

	SDKCallParamsWrapper ret = { SDKType_PlainOldData, SDKPass_Plain };
	g_hSDKCall_GetAllMissions = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_GETALLMISSIONS, _, _, true, ret);

	SDKCallParamsWrapper params[] = {{ SDKType_String, SDKPass_Pointer }};
	g_hSDKCall_OnChangeMissionVote = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_ONCHANGEMISSIONVOTE, params, sizeof(params));

	SDKCallParamsWrapper params1[] = {{ SDKType_Bool, SDKPass_Plain }};
    g_hSDKCall_IsFirstMapInScenario = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_ISFIRSTMAPINSCENARIO, params1, sizeof(params1));

	g_hDetour_RestoreTransitionedEntities = gd.CreateDetourOrFail(DETOUR_RESTORETRANSITIONEDENTITIES, true, DTR_OnRestoreTransitionedEntities);
	g_hDetour_TransitionRestore = gd.CreateDetourOrFail(DETOUR_TRANSITIONRESTORE, true, _, DTR_CTerrorPlayer_OnTransitionRestore_Post);

	delete gd;
}

void SetupConVars()
{
	mp_gamemode = FindConVar("mp_gamemode");

	g_cvNextMapPrint   = CreateConVar("l4d2mm_nextmap_print",       "1", "Determine whether to show what the next map will be", _, true, 0.0, true, 1.0);
	g_cvMapPoolCapacity = CreateConVar("l4d2mm_map_pool_capacity",    "5", "Determine how many maps can be selected in one pool; 0 = no limits;", _, true, 0.0, true, 10.0);
	g_cvMaxMapsNum	   = CreateConVar("l4d2mm_max_maps_num",        "2", "Determine how many maps of one campaign can be selected; 0 = no limits;", _, true, 0.0, true, 5.0);
	g_cvSaveStatus     = CreateConVar("l4d2mm_save_status", 		"1", "Determine whether to save player status in coop or realism mode after changing map.", _, true, 0.0, true, 1.0);
	g_cvSaveStatusBot  = CreateConVar("l4d2mm_save_status_bot", 	"1", "Determine whether to save bot satuts in coop or realism mode", _, true, 0.0, true, 1.0);
	g_cvFinaleEndStart = CreateConVar("l4d2mm_finale_end_start",    "0", "Determine whether to remixmap in the end of finale; 0 = disable;1 = enable", _, true, 0.0, true, 1.0);
}

void SetupCommands()
{
	RegConsoleCmd("sm_mixmap", Mixmap_Cmd, "Vote to start a mixmap (arg1 empty for 'default' maps pool);通过投票启用Mixmap, 并可加载特定的地图池；无参数则启用官图顺序随机");
	RegConsoleCmd("sm_stopmixmap", StopMixmap_Cmd, "Stop a mixmap;中止mixmap, 并初始化地图列表");
	RegAdminCmd("sm_fmixmap", ForceMixmap, ADMFLAG_ROOT, "Force start mixmap (arg1 empty for 'default' maps pool) 强制启用mixmap (随机官方地图)");
	RegAdminCmd("sm_fstopmixmap", StopMixmap, ADMFLAG_ROOT, "Force stop a mixmap ;强制中止mixmap, 并初始化地图列表");

	//RegConsoleCmd("sm_maplist", Command_Maplist, "Show the map list; 展示mixmap最终抽取出的地图列表");
	RegConsoleCmd("sm_allmaps", Command_ShowAllMaps, ADMFLAG_ROOT, "Show all official maps code; 展示所有官方地图的地图代码");
}

void PluginStartInit()
{
	g_bMapsetInitialized = false;
	g_bMaplistFinalized	 = false;

	g_iMapsPlayed		 = 0;
	g_iMapCount			 = 0;
}

void SetupForwards()
{
	g_hForwardStart 		= new GlobalForward("OnMixmapStart", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardNext			= new GlobalForward("OnMixmapNextKnown", ET_Ignore, Param_String);
	g_hForwardInterrupt 	= new GlobalForward("OnMixmapInterrupted", ET_Ignore);
	g_hForwardEnd			= new GlobalForward("OnMixmapEnd", ET_Ignore);
}

void SetupNatives()
{
	CreateNative("GetMixmapMapSequence", Native_GetMixmapMapSequence);
	CreateNative("GetMixmapPlayedMapCount", Native_GetMixmapPlayedMapCount);
	CreateNative("IsInMixmap", Native_IsInMixmap);
}

int Native_GetMixmapMapSequence(Handle plugin, int numParams)
{
	char sBuffer[64];
	ArrayList hArray = view_as<ArrayList>(GetNativeCell(1));

	if (!g_bMaplistFinalized)
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

int Native_GetMixmapPlayedMapCount(Handle plugin, int numParams)
{
	return g_iMapsPlayed;
}

int Native_IsInMixmap(Handle plugin, int numParams)
{
	return g_bMapsetInitialized ? true : false;
}