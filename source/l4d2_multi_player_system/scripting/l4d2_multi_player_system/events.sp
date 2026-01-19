
void SetupEvents()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
}

static void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();

	int player;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		player = GetIdlePlayerOfBot(i);
		if (player && IsClientInGame(player) && !IsFakeClient(player) && GetClientTeam(player) == TEAM_SPECTATOR)
		{
			SetHumanSpec(i, player);
			TakeOverBot(player);
		}
	}
}

static void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundStart = true;
}

static void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR)
		return;

	delete g_hBotsTimer;
	g_hBotsTimer = CreateTimer(2.0, tmrBotsUpdate);

	SetEntProp(client, Prop_Send, "m_isGhost", 0);
	if (!IsFakeClient(client) && IsFirstTime(client))
		RecordSteamID(client);
}

static void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR)
		return;

	int player = GetIdlePlayerOfBot(client);
	if (player && IsClientInGame(player) && !IsFakeClient(player) && GetClientTeam(player) == TEAM_SPECTATOR)
	{
		SetHumanSpec(client, player);
		TakeOverBot(player);
	}
}

static void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return;

	switch (event.GetInt("team"))
	{
		case TEAM_SPECTATOR:
		{
			g_esPlayer[client].Notify = true;

			if (g_iJoinFlags & JOIN_AUTOMATIC && event.GetInt("oldteam") == TEAM_NOTEAM)
				CreateTimer(1.0, tmrJoinTeam2, event.GetInt("userid"), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}

		case TEAM_SURVIVOR:
			SetEntProp(client, Prop_Send, "m_isGhost", 0);
	}
}

static Action tmrJoinTeam2(Handle timer, int client)
{
	if (!(g_iJoinFlags & JOIN_AUTOMATIC))
		return Plugin_Stop;

	client = GetClientOfUserId(client);
	if (!client || !IsClientInGame(client))
		return Plugin_Stop;

	if (GetClientTeam(client) > TEAM_SPECTATOR || GetBotOfIdlePlayer(client))
		return Plugin_Stop;

	if (CheckJoinLimit())
		return Plugin_Stop;

	if (!g_bRoundStart || PrepRestoreBots() || GetClientTeam(client) <= TEAM_NOTEAM)
		return Plugin_Continue;

	JoinSurTeam(client);
	return Plugin_Stop;
}

static void Event_PlayerBotReplace(Event event, char[] name, bool dontBroadcast)
{
	int playerId = event.GetInt("player");
	int player	 = GetClientOfUserId(playerId);

	if (!player || !IsClientInGame(player) || IsFakeClient(player) || GetClientTeam(player) != TEAM_SURVIVOR)
		return;

	int botId			   = event.GetInt("bot");
	int bot				   = GetClientOfUserId(botId);

	g_esPlayer[bot].Player = playerId;
	g_esPlayer[player].Bot = botId;

	if (!g_esPlayer[player].Model[0])
		return;

	SetEntProp(bot, Prop_Send, "m_survivorCharacter", GetEntProp(player, Prop_Send, "m_survivorCharacter"));
	SetEntityModel(bot, g_esPlayer[player].Model);
	for (int i; i < sizeof g_sSurvivorModels; i++)
	{
		if (strcmp(g_esPlayer[player].Model, g_sSurvivorModels[i], false) == 0)
		{
			g_bBlockUserMsg = true;
			SetClientInfo(bot, "name", g_sSurvivorNames[i]);
			g_bBlockUserMsg = false;
			break;
		}
	}
}

static void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	if (!player || !IsClientInGame(player) || IsFakeClient(player) || GetClientTeam(player) != TEAM_SURVIVOR)
		return;

	int bot = GetClientOfUserId(event.GetInt("bot"));
	SetEntProp(player, Prop_Send, "m_survivorCharacter", GetEntProp(bot, Prop_Send, "m_survivorCharacter"));

	char model[128];
	GetClientModel(bot, model, sizeof model);
	SetEntityModel(player, model);
}

static void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	int iEnt = -1;
	int loop = MaxClients + 1;
	while ((loop = FindEntityByClassname(loop, "info_survivor_position")) != -1)
	{
		if (iEnt == -1)
			iEnt = loop;

		if (1 <= GetEntProp(loop, Prop_Send, "m_order") <= 4)
		{
			iEnt = loop;
			break;
		}
	}

	if (iEnt != -1)
	{
		float vPos[3];
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos);

		loop						= -1;
		static const char Order[][] = { "1", "2", "3", "4" };
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR)
				continue;

			if (++loop < 4)
				continue;

			iEnt = CreateEntityByName("info_survivor_position");
			if (iEnt != -1)
			{
				DispatchKeyValue(iEnt, "Order", Order[loop % 4]);
				TeleportEntity(iEnt, vPos);
				DispatchSpawn(iEnt);
			}
		}
	}
}