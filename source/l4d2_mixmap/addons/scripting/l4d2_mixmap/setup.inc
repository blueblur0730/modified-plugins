#if defined _l4d2_mixmap_setup_included
	#endinput
#endif
#define _l4d2_mixmap_setup_included

void SetupForwards()
{
	g_hForwardStart 		= new GlobalForward("OnMixmapStart", ET_Ignore, Param_Cell, Param_String);
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

void SetupConVars()
{
	g_cvNextMapPrint   = CreateConVar("l4d2mm_nextmap_print",       "1", "Determine whether to show what the next map will be", _, true, 0.0, true, 1.0);
	g_cvMaxMapsNum	   = CreateConVar("l4d2mm_max_maps_num",        "2", "Determine how many maps of one campaign can be selected; 0 = no limits;", _, true, 0.0, true, 5.0);
	g_cvSaveStatus     = CreateConVar("l4d2mm_save_status", 		"1", "Determine whether to save player status in coop or realism mode after changing map.", _, true, 0.0, true, 1.0);
	g_cvSaveStatusBot  = CreateConVar("l4d2mm_save_status_bot", 	"1", "Determine whether to save bot satuts in coop or realism mode", _, true, 0.0, true, 1.0);
	g_cvFinaleEndStart = CreateConVar("l4d2mm_finale_end_start",    "0", "Determine whether to remixmap in the end of finale; 0 = disable;1 = enable", _, true, 0.0, true, 1.0);
}

void SetupCommands()
{
	// Servercmd 服务器指令（用于cfg文件）
	RegServerCmd(   "sm_addmap",        AddMap);
	RegServerCmd(   "sm_tagrank",       TagRank);

	// Start/Stop 启用/中止指令
	RegConsoleCmd(  "sm_mixmap",        Mixmap_Cmd,                     "Vote to start a mixmap (arg1 empty for 'default' maps pool);通过投票启用Mixmap, 并可加载特定的地图池；无参数则启用官图顺序随机");
	RegConsoleCmd(  "sm_stopmixmap",    StopMixmap_Cmd,                 "Stop a mixmap;中止mixmap, 并初始化地图列表");
	RegAdminCmd(    "sm_manualmixmap",  ManualMixmap,   ADMFLAG_ROOT,   "Start mixmap with specified maps 启用mixmap加载特定地图顺序的地图组");
	RegAdminCmd(    "sm_fmixmap",       ForceMixmap,    ADMFLAG_ROOT,   "Force start mixmap (arg1 empty for 'default' maps pool) 强制启用mixmap (随机官方地图)");
	RegAdminCmd(    "sm_fstopmixmap",   StopMixmap,     ADMFLAG_ROOT,   "Force stop a mixmap ;强制中止mixmap, 并初始化地图列表");

	// Midcommand 插件启用后可使用的指令
	RegConsoleCmd(  "sm_maplist",       Maplist,                        "Show the map list; 展示mixmap最终抽取出的地图列表");
	RegAdminCmd(    "sm_allmap",        ShowAllMaps,    ADMFLAG_ROOT,   "Show all official maps code; 展示所有官方地图的地图代码");
	RegAdminCmd(    "sm_allmaps",       ShowAllMaps,   	ADMFLAG_ROOT,   "Show all official maps code; 展示所有官方地图的地图代码");
}

void PluginStartInit()
{
	g_hTriePools		 = new StringMap();
	g_hArrayTags		 = new ArrayList(BUF_SZ / 4);	 // 1 block = 4 characters => X characters = X/4 blocks
	g_hArrayTagOrder	 = new ArrayList(BUF_SZ / 4);
	g_hArrayMapOrder	 = new ArrayList(BUF_SZ / 4);
	g_hArrayMatchInfo	 = new ArrayList(sizeof(MatchInfo));

	g_bMapsetInitialized = false;
	g_bMaplistFinalized	 = false;

	g_hCountDownTimer	 = null;

	g_iMapsPlayed		 = 0;
	g_iMapCount			 = 0;
}

void LoadSDK()
{
	GameData hGameData = new GameData(LEFT4FRAMEWORK_GAMEDATA);

	if (hGameData == null)
		SetFailState("Could not load gamedata/%s.txt", LEFT4FRAMEWORK_GAMEDATA);

	StartPrepSDKCall(SDKCall_GameRules);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SECTION_NAME))
		SetFailState("Function '%s' not found.", SECTION_NAME);

	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hCMapSetCampaignScores = EndPrepSDKCall();

	if (g_hCMapSetCampaignScores == null)
		SetFailState("Function '%s' found, but something went wrong.", SECTION_NAME);

	delete hGameData;
}

public int Native_GetMixmapMapSequence(Handle plugin, int numParams)
{
	char sBuffer[BUF_SZ];
	ArrayList hArray = view_as<ArrayList>(GetNativeCell(1));

	if (!g_bMaplistFinalized)
		ThrowError("Mixmap hasn't started yet.");
	else
	{
		if (hArray == null)
			return 0

		for (int i = 0; i < g_hArrayMapOrder.Length; i++) 
		{
			g_hArrayMapOrder.GetString(i, sBuffer, BUF_SZ);
			hArray.PushString(sBuffer);
		}
	}

	return 0;
}

public int Native_GetMixmapPlayedMapCount(Handle plugin, int numParams)
{
	return g_iMapsPlayed;
}

public int Native_IsInMixmap(Handle plugin, int numParams)
{
	return g_bMapsetInitialized ? true : false;
}