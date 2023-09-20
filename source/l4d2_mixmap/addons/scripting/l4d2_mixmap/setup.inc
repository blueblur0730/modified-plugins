#if defined _l4d2_mixmap_setup_included
	#endinput
#endif
#define _l4d2_mixmap_setup_included

void SetupForwards()
{
	g_hForwardStart = new GlobalForward("OnCMTStart", ET_Ignore, Param_Cell, Param_String);
	g_hForwardNext	= new GlobalForward("OnCMTNextKnown", ET_Ignore, Param_String);
	g_hForwardEnd	= new GlobalForward("OnCMTEnd", ET_Ignore);
}

void MarkNatives()
{
	MarkNativeAsOptional("PLAYSTATS_BroadcastRoundStats");
	MarkNativeAsOptional("PLAYSTATS_BroadcastGameStats");
}

void SetupConVars()
{
	g_cvNextMapPrint   = CreateConVar("l4d2mm_nextmap_print",       "1", "Determine whether to show what the next map will be", _, true, 0.0, true, 1.0);
	g_cvMaxMapsNum	   = CreateConVar("l4d2mm_max_maps_num",        "2", "Determine how many maps of one campaign can be selected; 0 = no limits;", _, true, 0.0, true, 5.0);
	g_cvFinaleEndStart = CreateConVar("l4d2mm_finale_end_start",    "1", "Determine whether to remixmap in the end of finale; 0 = disable;1 = enable", _, true, 0.0, true, 1.0);
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
	RegAdminCmd(    "sm_allmaps",       ShowAllMaps,   ADMFLAG_ROOT,   "Show all official maps code; 展示所有官方地图的地图代码");
}

void PluginStartInit()
{
	g_hArrayTags		 = new ArrayList(BUF_SZ / 4);	 // 1 block = 4 characters => X characters = X/4 blocks
	g_hTriePools		 = new StringMap();
	g_hArrayTagOrder	 = new ArrayList(BUF_SZ / 4);
	g_hArrayMapOrder	 = new ArrayList(BUF_SZ / 4);

	g_bMapsetInitialized = false;
	g_bMaplistFinalized	 = false;

	g_hCountDownTimer	 = null;

	g_iMapsPlayed		 = 0;
	g_iMapCount			 = 0;
}

void LoadSDK()
{
	Handle hGameData = LoadGameConfigFile(LEFT4FRAMEWORK_GAMEDATA);
	if (hGameData == null)
	{
		SetFailState("Could not load gamedata/%s.txt", LEFT4FRAMEWORK_GAMEDATA);
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SECTION_NAME))
	{
		SetFailState("Function '%s' not found.", SECTION_NAME);
	}

	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hCMapSetCampaignScores = EndPrepSDKCall();

	if (g_hCMapSetCampaignScores == null)
	{
		SetFailState("Function '%s' found, but something went wrong.", SECTION_NAME);
	}

	delete hGameData;
}