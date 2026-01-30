
void Reset()
{
	g_bLeftSafeArea = false;
	g_fNearestSpawnRange = L4D2_GetScriptValueFloat("ZombieDiscardRange", z_discard_range.FloatValue);

	for (int i; i <= MAXPLAYERS; i++)
	{
		delete g_hSpawnTimer[i];
		g_bMark[i] = false;
	}
}

void SpawnSpecial()
{
	if (!g_bLeftSafeArea || !g_bEnable)
		return;

	static float fSpawnPos[3];
	static int iClass, iPanicEventStage, index;
	static bool bFound;

	bFound = false;
	index = -1;

	if (GetAllSpecialsTotal() >= g_iMaxSILimit)
		return;

	iClass = GetSpawnClass();
	if (iClass <= 0)
		return;

	switch (g_iSpawnMode)
	{
		case SpawnMode_Normal:
			bFound = L4D_GetRandomPZSpawnPosition(GetRandomSur(), iClass, 30, fSpawnPos);
		
		case SpawnMode_NormalEnhanced:
		{
			iPanicEventStage = LoadFromAddress(g_pPanicEventStage, NumberType_Int8);

			if (!g_bFinalMap && iPanicEventStage > 0)
			{
				// After the panic event starts,
				// The GetRandomPZSpawnPosition function spawn SI very far away.
				// c8m3, c3m2...
				bFound = GetSpawnPosByNavArea(fSpawnPos, g_fNormalSpawnRange);
			}
			else
			{
				bFound = L4D_GetRandomPZSpawnPosition(GetRandomSur(), iClass, 7, fSpawnPos);
				if (!bFound)
				{
					// Use GetRandomPZSpawnPosition first, use GetSpawnPosByNavArea when it fails.
					bFound = GetSpawnPosByNavArea(fSpawnPos, g_fNormalSpawnRange);
				}
			}
		}

		case SpawnMode_NavArea:
			bFound = GetSpawnPosByNavArea(fSpawnPos, g_fNavAreaSpawnRange);

		case SpawnMode_NavAreaNearest:
			bFound = GetSpawnPosByNavArea(fSpawnPos, g_fNearestSpawnRange, true);
	}
	
	if (bFound)
	{
		g_bCanSpawn = true;
		index = L4D2_SpawnSpecial(iClass, fSpawnPos, NULL_VECTOR);
		g_bCanSpawn = false;

		if (index > 0)
		{
			g_bMark[index] = true;
			return;
		}
	}

	if (!bFound || index < 1)
	{
		CreateTimer(1.0, SpawnSpecial_Timer, SPAWN_NO_HANDLE, TIMER_FLAG_NO_MAPCHANGE);

		#if DEBUG
		char sMap[128];
		GetCurrentMap(sMap, sizeof(sMap));
		LogMessage("Failed to SpawnSpecial, map = %s, SpawnMode = %i, bFound = %b, index = %i", sMap, g_iSpawnMode, bFound, index);
		#endif
	}
}

Action SpawnSpecial_Timer(Handle timer, int num)
{
	if (g_bLeftSafeArea && g_bEnable)
	{
		static int iSpawnCount;

		switch (num)
		{
			case SPAWN_MAX_PRE:
			{
				iSpawnCount = 0;
				delete g_hSpawnTimer[SPAWN_MAX];
				g_hSpawnTimer[SPAWN_MAX] = CreateTimer(0.1, SpawnSpecial_Timer, SPAWN_MAX, TIMER_REPEAT);
			}

			case SPAWN_MAX:
			{
				if (iSpawnCount++ < g_iMaxSILimit)
				{
					SpawnSpecial();
					return Plugin_Continue;
				}
			}

			default:
				SpawnSpecial();
		}
	}

	g_hSpawnTimer[num] = null;
	return Plugin_Stop;
}

Action KillSICheck_Timer(Handle timer)
{
	if (!g_bLeftSafeArea || !g_bEnable)
		return Plugin_Continue;

	float fEngineTime = GetEngineTime();
	int class;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 3 || !IsPlayerAlive(i) || !IsFakeClient(i))
			continue;

		class = GetZombieClass(i);
		if (class < 1 || class > 6)
			continue;

		if (fEngineTime - g_fSpecialActionTime[i] > g_fKillSITime)
		{
			if (!GetEntProp(i, Prop_Send, "m_hasVisibleThreats") && !HasSurVictim(i, class))
				ForcePlayerSuicide(i);
			else
				g_fSpecialActionTime[i] = fEngineTime;
		}
	}
	return Plugin_Continue;
}

Action KickBot_Timer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && IsFakeClient(client) && !IsClientInKickQueue(client))
		KickClient(client);

	return Plugin_Continue;
}