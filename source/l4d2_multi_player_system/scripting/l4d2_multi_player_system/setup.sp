
void SetupConVars()
{
	CreateConVar("bots_version", PLUGIN_VERSION, "bots(coop) plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hCvar_BotLimit	= CreateConVar("bots_limit", "4", "Maximun number of bots allowed in the server.", FCVAR_NOTIFY, true, 1.0, true, float(MaxClients));
	g_hCvar_JoinLimit	= CreateConVar("bots_join_limit", "-1", "sm_join and auto join functionality will be disabled once bots reached this limit. (not affected the original game joining logic.). \n-1 = do nothing about this.", FCVAR_NOTIFY, true, -1.0, true, float(MaxClients));
	g_hCvar_JoinFlags	= CreateConVar("bots_join_flags", "3", "the ways extra players to join. \n0=do nothing, 1=by typing !join, 2=auto join once connected with server, 3=manual + auto.", FCVAR_NOTIFY);
	g_hCvar_JoinRespawn = CreateConVar("bots_join_respawn", "1", "If there's not living bots when joining, should the bots be respawned?. \n0=no, 1=yes, -1=always respawn (when -1, players can respawn by switching teams or rejoining the server).", FCVAR_NOTIFY);
	g_hCvar_SpecNotify	= CreateConVar("bots_spec_notify", "3", "The ways to show the join notification when spectator players click their M1: \n0=no notification, 1=chat, 2=screen center, 3=popup menu.", FCVAR_NOTIFY);
	g_esWeapon[0].Flags = CreateConVar("bots_give_slot0", "131071", "Primary weapon to give. \n0=nothing, 131071=all, 7=smg, 1560=shotgun, 30720=sniper, 31=Tier1, 32736=Tier2, 98304=Tier0.", FCVAR_NOTIFY);
	g_esWeapon[1].Flags = CreateConVar("bots_give_slot1", "1064", "Secondary weapon to give. \n0=nothing, 131071=all.(if melee is selected and it's not unlocked on the current map, a random one will be given).", FCVAR_NOTIFY);
	g_esWeapon[2].Flags = CreateConVar("bots_give_slot2", "0", "Grenades to give. \n0=nothing, 7=all.", FCVAR_NOTIFY);
	g_esWeapon[3].Flags = CreateConVar("bots_give_slot3", "1", "Medical items to give. \n0=nothing, 15=all.", FCVAR_NOTIFY);
	g_esWeapon[4].Flags = CreateConVar("bots_give_slot4", "3", "Pills to give. \n0=nothing, 3=all.", FCVAR_NOTIFY);
	g_hCvar_GiveType	= CreateConVar("bots_give_type", "2", "How to determine what equipment to give players. \n0=nothing, 1=per slot settings, 2=average equipment quality of current living survivors (primary and secondary only).", FCVAR_NOTIFY);
	g_hCvar_GiveTime	= CreateConVar("bots_give_time", "0", "When to give players equipment. \n0=every spawn, 1=only when this plugin creates bots or respawns players.", FCVAR_NOTIFY);

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