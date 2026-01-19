
void SetupConVars()
{
	CreateConVar("bots_version", PLUGIN_VERSION, "bots(coop) plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hCvar_BotLimit	= CreateConVar("bots_limit", "4", "开局Bot的数量", FCVAR_NOTIFY, true, 1.0, true, float(MaxClients));
	g_hCvar_JoinLimit	= CreateConVar("bots_join_limit", "-1", "生还者玩家数量达到该值后将禁用sm_join命令和本插件的自动加入功能(不会影响游戏原有的加入功能). \n-1=插件不进行处理.", FCVAR_NOTIFY, true, -1.0, true, float(MaxClients));
	g_hCvar_JoinFlags	= CreateConVar("bots_join_flags", "3", "额外玩家加入生还者的方法. \n0=插件不进行处理, 1=输入!join手动加入, 2=进服后插件自动加入, 3=手动+自动.", FCVAR_NOTIFY);
	g_hCvar_JoinRespawn = CreateConVar("bots_join_respawn", "1", "玩家加入生还者时如果没有存活的Bot可以接管是否复活. \n0=否, 1=是, -1=总是复活(该值为-1时将允许玩家通过切换队伍/退出重进刷复活).", FCVAR_NOTIFY);
	g_hCvar_SpecNotify	= CreateConVar("bots_spec_notify", "3", "完全旁观玩家点击鼠标左键时, 提示加入生还者的方式 \n0=不提示, 1=聊天栏, 2=屏幕中央, 3=弹出菜单.", FCVAR_NOTIFY);
	g_esWeapon[0].Flags = CreateConVar("bots_give_slot0", "131071", "主武器给什么. \n0=不给, 131071=所有, 7=微冲, 1560=霰弹, 30720=狙击, 31=Tier1, 32736=Tier2, 98304=Tier0.", FCVAR_NOTIFY);
	g_esWeapon[1].Flags = CreateConVar("bots_give_slot1", "1064", "副武器给什么. \n0=不给, 131071=所有.(如果选中了近战且该近战在当前地图上未解锁,则会随机给一把).", FCVAR_NOTIFY);
	g_esWeapon[2].Flags = CreateConVar("bots_give_slot2", "0", "投掷物给什么. \n0=不给, 7=所有.", FCVAR_NOTIFY);
	g_esWeapon[3].Flags = CreateConVar("bots_give_slot3", "1", "医疗品给什么. \n0=不给, 15=所有.", FCVAR_NOTIFY);
	g_esWeapon[4].Flags = CreateConVar("bots_give_slot4", "3", "药品给什么. \n0=不给, 3=所有.", FCVAR_NOTIFY);
	g_hCvar_GiveType	= CreateConVar("bots_give_type", "2", "根据什么来给玩家装备. \n0=不给, 1=每个槽位的设置, 2=当前存活生还者的平均装备质量(仅主副武器).", FCVAR_NOTIFY);
	g_hCvar_GiveTime	= CreateConVar("bots_give_time", "0", "什么时候给玩家装备. \n0=每次出生时, 1=只在本插件创建Bot和复活玩家时.", FCVAR_NOTIFY);

	g_hCvar_SurLimit	= FindConVar("survivor_limit");
	g_hCvar_SurLimit.Flags &= ~FCVAR_NOTIFY;
	g_hCvar_SurLimit.SetBounds(ConVarBound_Upper, true, float(MaxClients));

	g_hCvar_BotLimit.AddChangeHook(CvarChanged_Limit);
	g_hCvar_SurLimit.AddChangeHook(CvarChanged_Limit);

	g_hCvar_JoinLimit.AddChangeHook(CvarChanged_General);
	g_hCvar_JoinFlags.AddChangeHook(CvarChanged_General);
	g_hCvar_JoinRespawn.AddChangeHook(CvarChanged_General);
	g_hCvar_SpecNotify.AddChangeHook(CvarChanged_General);

	g_esWeapon[0].Flags.AddChangeHook(CvarChanged_Weapon);
	g_esWeapon[1].Flags.AddChangeHook(CvarChanged_Weapon);
	g_esWeapon[2].Flags.AddChangeHook(CvarChanged_Weapon);
	g_esWeapon[3].Flags.AddChangeHook(CvarChanged_Weapon);
	g_esWeapon[4].Flags.AddChangeHook(CvarChanged_Weapon);

	g_hCvar_GiveType.AddChangeHook(CvarChanged_Weapon);
	g_hCvar_GiveTime.AddChangeHook(CvarChanged_Weapon);
}

void InitData()
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(buffer))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_pDirector = hGameData.GetAddress("CDirector");
	if (!g_pDirector)
		SetFailState("Failed to find address: \"CDirector\" (%s)", PLUGIN_VERSION);

	g_pSavedSurvivorBotsCount = hGameData.GetAddress("SavedSurvivorBotsCount");
	if (!g_pSavedSurvivorBotsCount)
		SetFailState("Failed to find address: \"SavedSurvivorBotsCount\"");

	int m_knockdownTimer		= FindSendPropInfo("CTerrorPlayer", "m_knockdownTimer");
	g_iOff_m_hWeaponHandle		= m_knockdownTimer + 100;
	/*g_iOff_m_hWeaponHandle = hGameData.GetOffset("g_iOff_m_hWeaponHandle");
	if (g_iOff_m_hWeaponHandle == -1)
		SetFailState("Failed to find offset: \"g_iOff_m_hWeaponHandle\" (%s)", PLUGIN_VERSION);*/

	g_iOff_m_iRestoreAmmo		= m_knockdownTimer + 104;
	/*g_iOff_m_iRestoreAmmo = hGameData.GetOffset("g_iOff_m_iRestoreAmmo");
	if (g_iOff_m_iRestoreAmmo == -1)
		SetFailState("Failed to find offset: \"g_iOff_m_iRestoreAmmo\" (%s)", PLUGIN_VERSION);*/

	g_iOff_m_restoreWeaponID	= m_knockdownTimer + 108;
	/*g_iOff_m_restoreWeaponID = hGameData.GetOffset("g_iOff_m_restoreWeaponID");
	if (g_iOff_m_restoreWeaponID == -1)
		SetFailState("Failed to find offset: \"g_iOff_m_restoreWeaponID\" (%s)", PLUGIN_VERSION);*/

	g_iOff_m_hHiddenWeapon		= m_knockdownTimer + 116;
	/*g_iOff_m_hHiddenWeapon = hGameData.GetOffset("g_iOff_m_hHiddenWeapon");
	if (g_iOff_m_hHiddenWeapon == -1)
		SetFailState("Failed to find offset: \"g_iOff_m_hHiddenWeapon\" (%s)", PLUGIN_VERSION);*/

	g_iOff_m_isOutOfCheckpoint	= FindSendPropInfo("CTerrorPlayer", "m_jumpSupressedUntil") + 4;
	/*g_iOff_m_isOutOfCheckpoint = hGameData.GetOffset("g_iOff_m_isOutOfCheckpoint");
	if (g_iOff_m_isOutOfCheckpoint == -1)
		SetFailState("Failed to find offset: \"g_iOff_m_isOutOfCheckpoint\" (%s)", PLUGIN_VERSION);*/

	g_iOff_RestartScenarioTimer = hGameData.GetOffset("RestartScenarioTimer");
	if (g_iOff_RestartScenarioTimer == -1)
		SetFailState("Failed to find offset: \"RestartScenarioTimer\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Static);
	Address addr = hGameData.GetMemSig("NextBotCreatePlayerBot<SurvivorBot>");
	if (!addr)
		SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" in \"CDirector::AddSurvivorBot\" (%s)", PLUGIN_VERSION);
	if (!hGameData.GetOffset("OS"))
	{
		Address offset = view_as<Address>(LoadFromAddress(addr + view_as<Address>(1), NumberType_Int32));	 // (addr+5) + *(addr+1) = call function addr
		if (!offset)
			SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);

		addr += offset + view_as<Address>(5);	 // sizeof(instruction)
	}
	if (!PrepSDKCall_SetAddress(addr))
		SetFailState("Failed to find address: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	if (!(g_hSDK_NextBotCreatePlayerBot_SurvivorBot = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"NextBotCreatePlayerBot<SurvivorBot>\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn"))
		SetFailState("Failed to find signature: \"CTerrorPlayer::RoundRespawn\" (%s)", PLUGIN_VERSION);
	if (!(g_hSDK_CTerrorPlayer_RoundRespawn = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CTerrorPlayer::RoundRespawn\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::State_Transition"))
		SetFailState("Failed to find signature: \"CCSPlayer::State_Transition\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	if (!(g_hSDK_CCSPlayer_State_Transition = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CCSPlayer::State_Transition\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator"))
		SetFailState("Failed to find signature: \"SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	if (!(g_hSDK_SurvivorBot_SetHumanSpectator = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverBot"))
		SetFailState("Failed to find signature: \"CTerrorPlayer::TakeOverBot\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	if (!(g_hSDK_CTerrorPlayer_TakeOverBot = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CTerrorPlayer::TakeOverBot\" (%s)", PLUGIN_VERSION);

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsInTransition"))
		SetFailState("Failed to find signature: \"CDirector::IsInTransition\" (%s)", PLUGIN_VERSION);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if (!(g_hSDK_CDirector_IsInTransition = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: \"CDirector::IsInTransition\" (%s)", PLUGIN_VERSION);

	InitPatchs(hGameData);
	SetupDetours(hGameData);

	delete hGameData;
}

void SetupDetours(GameData hGameData = null)
{
	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "DD::CTerrorPlayer::GoAwayFromKeyboard");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CTerrorPlayer::GoAwayFromKeyboard\" (%s)", PLUGIN_VERSION);

	if (!dDetour.Enable(Hook_Pre, DD_CTerrorPlayer_GoAwayFromKeyboard_Pre))
		SetFailState("Failed to detour pre: \"DD::CTerrorPlayer::GoAwayFromKeyboard\" (%s)", PLUGIN_VERSION);

	if (!dDetour.Enable(Hook_Post, DD_CTerrorPlayer_GoAwayFromKeyboard_Post))
		SetFailState("Failed to detour post: \"DD::CTerrorPlayer::GoAwayFromKeyboard\" (%s)", PLUGIN_VERSION);

	dDetour = DynamicDetour.FromConf(hGameData, "DD::SurvivorBot::SetHumanSpectator");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);

	if (!dDetour.Enable(Hook_Pre, DD_SurvivorBot_SetHumanSpectator_Pre))
		SetFailState("Failed to detour pre: \"DD::SurvivorBot::SetHumanSpectator\" (%s)", PLUGIN_VERSION);

	dDetour = DynamicDetour.FromConf(hGameData, "DD::CBasePlayer::SetModel");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CBasePlayer::SetModel\" (%s)", PLUGIN_VERSION);

	if (!dDetour.Enable(Hook_Post, DD_CBasePlayer_SetModel_Post))
		SetFailState("Failed to detour post: \"DD::CBasePlayer::SetModel\" (%s)", PLUGIN_VERSION);

	dDetour = DynamicDetour.FromConf(hGameData, "DD::CTerrorPlayer::GiveDefaultItems");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CTerrorPlayer::GiveDefaultItems\" (%s)", PLUGIN_VERSION);

	if (!dDetour.Enable(Hook_Pre, DD_CTerrorPlayer_GiveDefaultItems_Pre))
		SetFailState("Failed to detour pre: \"DD::CTerrorPlayer::GiveDefaultItems\" (%s)", PLUGIN_VERSION);
}

void InitPatchs(GameData hGameData = null)
{
	int iOffset = hGameData.GetOffset("RoundRespawn_Offset");
	if (iOffset == -1)
		SetFailState("Failed to find offset: \"RoundRespawn_Offset\" (%s)", PLUGIN_VERSION);

	int iByteMatch = hGameData.GetOffset("RoundRespawn_Byte");
	if (iByteMatch == -1)
		SetFailState("Failed to find byte: \"RoundRespawn_Byte\" (%s)", PLUGIN_VERSION);

	g_pStatsCondition = hGameData.GetMemSig("CTerrorPlayer::RoundRespawn");
	if (!g_pStatsCondition)
		SetFailState("Failed to find address: \"CTerrorPlayer::RoundRespawn\" (%s)", PLUGIN_VERSION);

	g_pStatsCondition += view_as<Address>(iOffset);
	int iByteOrigin = LoadFromAddress(g_pStatsCondition, NumberType_Int8);
	if (iByteOrigin != iByteMatch)
		SetFailState("Failed to load \"CTerrorPlayer::RoundRespawn\", byte mis-match @ %d (0x%02X != 0x%02X) (%s)", iOffset, iByteOrigin, iByteMatch, PLUGIN_VERSION);
}

void CvarChanged_Limit(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars_Limit();
}

void GetCvars_Limit()
{
	g_iBotLimit = g_hCvar_SurLimit.IntValue = g_hCvar_BotLimit.IntValue;
}

void CvarChanged_General(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars_General();
}

void GetCvars_General()
{
	g_iJoinLimit   = g_hCvar_JoinLimit.IntValue;
	g_iJoinFlags   = g_hCvar_JoinFlags.IntValue;
	g_iJoinRespawn = g_hCvar_JoinRespawn.IntValue;
	g_iSpecNotify  = g_hCvar_SpecNotify.IntValue;
}

void CvarChanged_Weapon(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars_Weapon();
}

void GetCvars_Weapon()
{
	int num;
	for (int i; i < MAX_SLOT; i++)
	{
		g_esWeapon[i].Count = 0;
		if (!g_esWeapon[i].Flags.BoolValue || IsNullSlot(i))
			num++;
	}

	g_bGiveType = num < MAX_SLOT ? g_hCvar_GiveType.BoolValue : false;
	g_bGiveTime = g_hCvar_GiveTime.BoolValue;
}