

Action tmrBotsUpdate(Handle timer)
{
	g_hBotsTimer = null;

	if (!PrepRestoreBots())
		SpawnCheck();
	else
		g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);

	return Plugin_Continue;
}

void SpawnCheck()
{
	if (!g_bRoundStart)
		return;

	int iSurvivor	   = GetTeamPlayers(TEAM_SURVIVOR, true);
	int iHumanSurvivor = GetTeamPlayers(TEAM_SURVIVOR, false);
	int iSurvivorLimit = g_iBotLimit;
	int iSurvivorMax   = iHumanSurvivor > iSurvivorLimit ? iHumanSurvivor : iSurvivorLimit;

	if (iSurvivor > iSurvivorMax)
		PrintToConsoleAll("Kicking %d bot(s)", iSurvivor - iSurvivorMax);

	if (iSurvivor < iSurvivorLimit)
		PrintToConsoleAll("Spawning %d bot(s)", iSurvivorLimit - iSurvivor);

	for (; iSurvivorMax < iSurvivor; iSurvivorMax++)
		KickUnusedSurBot();

	for (; iSurvivor < iSurvivorLimit; iSurvivor++)
		SpawnExtraSurBot();
}

void KickUnusedSurBot()
{
	int bot = FindUnusedSurBot();	 // 优先踢出没有对应真实玩家且后生成的Bot
	if (bot)
	{
		RemoveAllWeapons(bot);
		KickClient(bot, "Kicking Useless Client.");
	}
}

void SpawnExtraSurBot()
{
	int bot = SpawnSurBot();
	if (bot != -1)
	{
		if (!IsPlayerAlive(bot))
			RespawnPlayer(bot);

		TeleportPlayer(bot);
		SetInvulnerable(bot, 1.5);
	}
}

void ResetPlugin()
{
	delete g_hBotsTimer;
	g_smSteamIDs.Clear();
	g_bRoundStart = false;
}

void RecordSteamID(int client)
{
	if (CacheSteamID(client))
		g_smSteamIDs.SetValue(g_esPlayer[client].AuthId, true);
}

bool IsFirstTime(int client)
{
	if (!CacheSteamID(client))
		return false;

	return !g_smSteamIDs.ContainsKey(g_esPlayer[client].AuthId);
}

bool CacheSteamID(int client)
{
	if (g_esPlayer[client].AuthId[0])
		return true;

	if (GetClientAuthId(client, AuthId_Steam2, g_esPlayer[client].AuthId, sizeof Player::AuthId))
		return true;

	g_esPlayer[client].AuthId[0] = '\0';
	return false;
}

void GiveMelee(int client, const char[] meleeName)
{
	char buffer[64];
	if (g_aMeleeScripts.FindString(meleeName) != -1)
		strcopy(buffer, sizeof buffer, meleeName);
	else
	{
		int num = g_aMeleeScripts.Length;
		if (num)
			g_aMeleeScripts.GetString(Math_GetRandomInt(0, num - 1), buffer, sizeof buffer);
	}

	GivePlayerItem(client, buffer);
}

enum struct Zombie
{
	int idx;
	int class;
	int client;
}

Handle g_hPanelTimer[MAXPLAYERS + 1];
void DrawTeamPanel(int client, bool autoRefresh)
{
	static const char ZombieName[][] = {
		"Smoker",
		"Boomer",
		"Hunter",
		"Spitter",
		"Jockey",
		"Charger",
		"Witch",
		"Tank",
		"None"
	};

	Panel panel = new Panel();
	panel.SetTitle("团队信息");

	static char info[MAX_NAME_LENGTH];
	static char name[MAX_NAME_LENGTH];

	FormatEx(info, sizeof info, "旁观 [%d]", GetTeamPlayers(TEAM_SPECTATOR, false));
	panel.DrawItem(info);

	int i = 1;
	for (; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SPECTATOR)
			continue;

		GetClientName(i, name, sizeof name);
		FormatEx(info, sizeof info, "%s - %s", GetBotOfIdlePlayer(i) ? "闲置" : "观众", name);
		panel.DrawText(info);
	}

	FormatEx(info, sizeof info, "生还 [%d/%d] - %d Bot(s)", GetTeamPlayers(TEAM_SURVIVOR, false), g_iBotLimit, GetSurBotsCount());
	panel.DrawItem(info);

	static ConVar cv;
	if (!cv)
		cv = FindConVar("survivor_max_incapacitated_count");

	int maxInc = cv.IntValue;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		GetClientName(i, name, sizeof name);

		if (!IsPlayerAlive(i))
			FormatEx(info, sizeof info, "死亡 - %s", name);
		else
		{
			if (GetEntProp(i, Prop_Send, "m_isIncapacitated"))
				FormatEx(info, sizeof info, "倒地 - %dHP - %s", GetClientHealth(i) + GetTempHealth(i), name);
			else if (GetEntProp(i, Prop_Send, "m_currentReviveCount") >= maxInc)
				FormatEx(info, sizeof info, "黑白 - %dHP - %s", GetClientHealth(i) + GetTempHealth(i), name);
			else
				FormatEx(info, sizeof info, "%dHP - %s", GetClientHealth(i) + GetTempHealth(i), name);
		}

		panel.DrawText(info);
	}

	FormatEx(info, sizeof info, "感染 [%d]", GetTeamPlayers(TEAM_INFECTED, false));
	panel.DrawItem(info);

	Zombie	  zombie;
	ArrayList aClients = new ArrayList(sizeof Zombie);
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_INFECTED)
			continue;

		zombie.class = GetEntProp(i, Prop_Send, "m_zombieClass");
		if (zombie.class != 8 && IsFakeClient(i))
			continue;

		zombie.client = i;
		zombie.idx	  = zombie.class == 8 ? (!IsFakeClient(i) ? 0 : 1) : 2;
		aClients.PushArray(zombie);
	}

	int num = aClients.Length;
	if (num)
	{
		aClients.Sort(Sort_Ascending, Sort_Integer);
		for (i = 0; i < num; i++)
		{
			aClients.GetArray(i, zombie);
			GetClientName(zombie.client, name, sizeof name);

			if (IsPlayerAlive(zombie.client))
			{
				if (GetEntProp(zombie.client, Prop_Send, "m_isGhost"))
					FormatEx(info, sizeof info, "(%s)鬼魂 - %s", ZombieName[zombie.class - 1], name);
				else
					FormatEx(info, sizeof info, "(%s)%dHP - %s", ZombieName[zombie.class - 1], GetEntProp(zombie.client, Prop_Data, "m_iHealth"), name);
			}
			else
				FormatEx(info, sizeof info, "(%s)死亡 - %s", ZombieName[zombie.class - 1], name);

			panel.DrawText(info);
		}
	}

	delete aClients;

	FormatEx(info, sizeof info, "刷新 [%s]", autoRefresh ? "●" : "○");
	panel.DrawItem(info);

	panel.Send(client, Panel_Handler, 15);
	delete panel;

	delete g_hPanelTimer[client];
	if (autoRefresh)
		g_hPanelTimer[client] = CreateTimer(1.0, tmrPanel, client);
}

int Panel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (param2 == 4 && !g_hPanelTimer[param1])
				DrawTeamPanel(param1, true);
			else
				delete g_hPanelTimer[param1];
		}

		case MenuAction_Cancel:
			delete g_hPanelTimer[param1];
	}

	return 0;
}

Action tmrPanel(Handle timer, int client)
{
	g_hPanelTimer[client] = null;

	DrawTeamPanel(client, true);
	return Plugin_Continue;
}

// [L4D1 & L4D2] SM Respawn Improved (https://forums.alliedmods.net/showthread.php?t=323220)
void StatsConditionPatch(bool patch)
{
	static bool patched;
	if (!patched && patch)
	{
		patched = true;
		StoreToAddress(g_pStatsCondition, 0xEB, NumberType_Int8);
	}
	else if (patched && !patch) {
		patched = false;
		StoreToAddress(g_pStatsCondition, 0x75, NumberType_Int8);
	}
}

// Left 4 Dead 2 - CreateSurvivorBot (https://forums.alliedmods.net/showpost.php?p=2729883&postcount=16)
int SpawnSurBot()
{
	g_bInSpawnTime = true;
	int bot		   = SDKCall(g_hSDK_NextBotCreatePlayerBot_SurvivorBot, "");
	if (bot != -1)
		ChangeClientTeam(bot, TEAM_SURVIVOR);

	g_bInSpawnTime = false;
	return bot;
}

void RespawnPlayer(int client)
{
	StatsConditionPatch(true);
	g_bInSpawnTime = true;
	SDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, client);
	g_bInSpawnTime = false;
	StatsConditionPatch(false);
}

/**
// https://github.com/bcserv/smlib/blob/2c14acb85314e25007f5a61789833b243e7d0cab/scripting/include/smlib/clients.inc#L203-L215
// Spectator Movement modes
enum Obs_Mode
{
	OBS_MODE_NONE = 0,	// not in spectator mode
	OBS_MODE_DEATHCAM,	// special mode for death cam animation
	OBS_MODE_FREEZECAM,	// zooms to a target, and freeze-frames on them
	OBS_MODE_FIXED,		// view from a fixed camera position
	OBS_MODE_IN_EYE,	// follow a player in first person view
	OBS_MODE_CHASE,		// follow a player in third person view
	OBS_MODE_ROAMING,	// free roaming

	NUM_OBSERVER_MODES
};
**/
void SetHumanSpec(int bot, int client)
{
	SDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, bot, client);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", bot);
	if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 6)
		SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
}

void TakeOverBot(int client)
{
	SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);
}

void State_Transition(int client, int state)
{
	SDKCall(g_hSDK_CCSPlayer_State_Transition, client, state);
}

// 模拟CDirector::NewPlayerPossessBot(int, int, SurvivorBot *)中的接管方式
bool CheckForTake(int bot, int target)
{
	return !GetEntProp(bot, Prop_Send, "m_isIncapacitated") && !GetEntData(target, g_iOff_m_isOutOfCheckpoint);
}

bool OnEndScenario()
{
	return view_as<float>(LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_RestartScenarioTimer + 8), NumberType_Int32)) > 0.0;
}

bool PrepRestoreBots()
{
	return SDKCall(g_hSDK_CDirector_IsInTransition, g_pDirector) && LoadFromAddress(g_pSavedSurvivorBotsCount, NumberType_Int32);
}

void ClearRestoreWeapons(int client)
{
	SetEntData(client, g_iOff_m_hWeaponHandle, 0, _, true);
	SetEntData(client, g_iOff_m_iRestoreAmmo, -1, _, true);
	SetEntData(client, g_iOff_m_restoreWeaponID, 0, _, true);
}

void GiveDefaultItems(int client)
{
	RemoveAllWeapons(client);
	for (int i = 4; i >= 2; i--)
	{
		if (!g_esWeapon[i].Count)
			continue;

		GivePlayerItem(client, g_sWeaponName[i][g_esWeapon[i].Allowed[Math_GetRandomInt(0, g_esWeapon[i].Count - 1)]]);
	}

	GiveSecondary(client);
	switch (g_hCvar_GiveType.IntValue)
	{
		case 1:
			GivePresetPrimary(client);

		case 2:
			GiveAveragePrimary(client);
	}
}

void GiveSecondary(int client)
{
	if (g_esWeapon[1].Count)
	{
		int val = g_esWeapon[1].Allowed[Math_GetRandomInt(0, g_esWeapon[1].Count - 1)];
		if (val > 2)
			GiveMelee(client, g_sWeaponName[1][val]);
		else
			GivePlayerItem(client, g_sWeaponName[1][val]);
	}
}

void GivePresetPrimary(int client)
{
	if (g_esWeapon[0].Count)
		GivePlayerItem(client, g_sWeaponName[0][g_esWeapon[0].Allowed[Math_GetRandomInt(0, g_esWeapon[0].Count - 1)]]);
}

void GiveAveragePrimary(int client)
{
	int i = 1, tier, total, weapon;
	if (g_bRoundStart)
	{
		for (; i <= MaxClients; i++)
		{
			if (i == client || !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i))
				continue;

			total += 1;
			weapon = GetPlayerWeaponSlot(i, 0);
			if (weapon <= MaxClients || !IsValidEntity(weapon))
				continue;

			tier += IsWeaponTier1(weapon) ? 1 : 2;
		}
	}

	switch (total > 0 ? RoundToNearest(float(tier) / float(total)) : 0)
	{
		case 1:
			GivePlayerItem(client, g_sWeaponName[0][Math_GetRandomInt(0, 4)]);

		case 2:
			GivePlayerItem(client, g_sWeaponName[0][Math_GetRandomInt(5, 14)]);
	}
}

void RemoveAllWeapons(int client)
{
	int weapon;
	for (int i; i < MAX_SLOT; i++)
	{
		if ((weapon = GetPlayerWeaponSlot(client, i)) <= MaxClients)
			continue;

		RemovePlayerItem(client, weapon);
		RemoveEntity(weapon);
	}

	weapon = GetEntDataEnt2(client, g_iOff_m_hHiddenWeapon);
	SetEntDataEnt2(client, g_iOff_m_hHiddenWeapon, -1, true);
	if (weapon > MaxClients && IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity") == client)
	{
		RemovePlayerItem(client, weapon);
		RemoveEntity(weapon);
	}
}