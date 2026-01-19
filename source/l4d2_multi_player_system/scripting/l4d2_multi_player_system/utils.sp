
stock bool IsNullSlot(int slot)
{
	int flags = g_esWeapon[slot].Flags.IntValue;
	for (int i; i < sizeof g_sWeaponName[]; i++)
	{
		if (!g_sWeaponName[slot][i][0])
			break;

		if ((1 << i) & flags)
			g_esWeapon[slot].Allowed[g_esWeapon[slot].Count++] = i;
	}
	return !g_esWeapon[slot].Count;
}

stock bool CheckJoinLimit()
{
	if (g_iJoinLimit == -1)
		return false;

	int num;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && (!IsFakeClient(i) || GetIdlePlayerOfBot(i)))
			num++;
	}

	return num >= g_iJoinLimit;
}

stock int FindUnusedSurBot()
{
	int		  client   = MaxClients;
	ArrayList aClients = new ArrayList(2);

	for (; client >= 1; client--)
	{
		if (!IsValidSurBot(client))
			continue;

		aClients.Set(aClients.Push(IsSpecInvalid(GetClientOfUserId(g_esPlayer[client].Player)) ? 0 : 1), client, 1);
	}

	if (!aClients.Length)
		client = 0;
	else
	{
		aClients.Sort(Sort_Ascending, Sort_Integer);
		client = aClients.Get(0, 1);
	}

	delete aClients;
	return client;
}

stock int FindUselessSurBot(bool alive)
{
	int		  client;
	ArrayList aClients = new ArrayList(2);

	for (int i = MaxClients; i >= 1; i--)
	{
		if (!IsValidSurBot(i))
			continue;

		client = GetClientOfUserId(g_esPlayer[i].Player);
		aClients.Set(aClients.Push(IsPlayerAlive(i) == alive ? (IsSpecInvalid(client) ? 0 : 1) : (IsSpecInvalid(client) ? 2 : 3)), i, 1);
	}

	if (!aClients.Length)
		client = 0;
	else
	{
		aClients.Sort(Sort_Descending, Sort_Integer);

		client = aClients.Length - 1;
		client = aClients.Get(Math_GetRandomInt(aClients.FindValue(aClients.Get(client, 0)), client), 1);
	}

	delete aClients;
	return client;
}

stock void GetMeleeStringTable()
{
	g_aMeleeScripts.Clear();
	int table = FindStringTable("meleeweapons");
	if (table != INVALID_STRING_TABLE)
	{
		int	 num = GetStringTableNumStrings(table);
		char str[64];
		for (int i; i < num; i++)
		{
			ReadStringTable(table, i, str, sizeof str);
			g_aMeleeScripts.PushString(str);
		}
	}
}

stock int IsTeamAllowed(int client)
{
	int team = GetClientTeam(client);
	switch (team)
	{
		case TEAM_SPECTATOR:
		{
			if (GetBotOfIdlePlayer(client))
				team = 0;
		}

		case TEAM_SURVIVOR:
		{
			if (IsPlayerAlive(client))
				team = 0;
		}
	}
	return team;
}

stock int GetBotOfIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && GetIdlePlayerOfBot(i) == client)
			return i;
	}

	return 0;
}

stock int GetIdlePlayerOfBot(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

stock int GetTeamPlayers(int team, bool includeBots)
{
	int num;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != team)
			continue;

		if (!includeBots && IsFakeClient(i) && !GetIdlePlayerOfBot(i))
			continue;

		num++;
	}
	return num;
}

stock void WriteTakeoverPanel(int client, int bot)
{
	char buf[2];
	IntToString(GetCharacter(bot) /*GetEntProp(bot, Prop_Send, "m_survivorCharacter")*/, buf, sizeof buf);
	BfWrite bf = view_as<BfWrite>(StartMessageOne("VGUIMenu", client, USERMSG_RELIABLE));
	bf.WriteString("takeover_survivor_bar");
	bf.WriteByte(true);
	bf.WriteByte(1);
	bf.WriteString("character");
	bf.WriteString(buf);
	EndMessage();
}

// L4D2_Adrenaline_Recovery (https://github.com/LuxLuma/L4D2_Adrenaline_Recovery/blob/ac3f62eebe95d80fcf610fb6c7c1ed56bf4b31d2/%5BL4D2%5DAdrenaline_Recovery.sp#L96-L177)
stock int GetCharacter(int client)
{
	char model[31];
	GetClientModel(client, model, sizeof model);
	switch (model[29])
	{
		case 'b':	 // nick
			return 0;
		case 'd':	 // rochelle
			return 1;
		case 'c':	 // coach
			return 2;
		case 'h':	 // ellis
			return 3;
		case 'v':	 // bill
			return 4;
		case 'n':	 // zoey
			return 5;
		case 'e':	 // francis
			return 6;
		case 'a':	 // louis
			return 7;
		default:
			return GetEntProp(client, Prop_Send, "m_survivorCharacter");
	}
}

stock bool ShouldIgnore(int client)
{
	if (IsFakeClient(client))
		return !!GetIdlePlayerOfBot(client);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SPECTATOR)
			continue;

		if (GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iTeam", _, i) == TEAM_SURVIVOR && GetIdlePlayerOfBot(i) == client)
			return true;
	}

	return false;
}

stock bool IsWeaponTier1(int weapon)
{
	char cls[32];
	GetEntityClassname(weapon, cls, sizeof cls);
	for (int i; i < 5; i++)
	{
		if (strcmp(cls, g_sWeaponName[0][i], false) == 0)
			return true;
	}
	return false;
}

// https://github.com/bcserv/smlib/blob/2c14acb85314e25007f5a61789833b243e7d0cab/scripting/include/smlib/math.inc#L144-L163
#define SIZE_OF_INT 2147483647	  // without 0
stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();
	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

stock bool IsValidSurBot(int client)
{
	return IsClientInGame(client) && !IsClientInKickQueue(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR && !GetIdlePlayerOfBot(client);
}

stock bool IsSpecInvalid(int client)
{
	return !client || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) == TEAM_SURVIVOR;
}

stock int TeleportPlayer(int client)
{
	int		  target   = 1;
	ArrayList aClients = new ArrayList(2);

	for (; target <= MaxClients; target++)
	{
		if (target == client || !IsClientInGame(target) || GetClientTeam(target) != TEAM_SURVIVOR || !IsPlayerAlive(target))
			continue;

		aClients.Set(aClients.Push(!GetEntProp(target, Prop_Send, "m_isIncapacitated") ? 0 : !GetEntProp(target, Prop_Send, "m_isHangingFromLedge") ? 1
																																					: 2),
					 target, 1);
	}

	if (!aClients.Length)
		target = 0;
	else
	{
		aClients.Sort(Sort_Descending, Sort_Integer);

		target = aClients.Length - 1;
		target = aClients.Get(Math_GetRandomInt(aClients.FindValue(aClients.Get(target, 0)), target), 1);
	}

	delete aClients;

	if (target)
	{
		SetEntProp(client, Prop_Send, "m_bDucked", 1);
		SetEntityFlags(client, GetEntityFlags(client) | FL_DUCKING);

		float vPos[3];
		GetClientAbsOrigin(target, vPos);
		TeleportEntity(client, vPos);
		return target;
	}

	return client;
}

stock void SetInvulnerable(int client, float flDuration)
{
	static int m_invulnerabilityTimer = -1;
	if (m_invulnerabilityTimer == -1)
		m_invulnerabilityTimer = FindSendPropInfo("CTerrorPlayer", "m_noAvoidanceTimer") - 12;

	SetEntDataFloat(client, m_invulnerabilityTimer + 4, flDuration);
	SetEntDataFloat(client, m_invulnerabilityTimer + 8, GetGameTime() + flDuration);
}

stock int GetSurBotsCount()
{
	int num;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurBot(i))
			num++;
	}

	return num;
}

stock int GetTempHealth(int client)
{
	static ConVar cPainPillsDecay;
	if (!cPainPillsDecay)
		cPainPillsDecay = FindConVar("pain_pills_decay_rate");

	int tempHealth = RoundToFloor(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * cPainPillsDecay.FloatValue);
	return tempHealth < 0 ? 0 : tempHealth;
}
