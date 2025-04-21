#if defined _l4d2_mixmap_hooks_included
	#endinput
#endif
#define _l4d2_mixmap_hooks_included

public Action L4D2_OnTransitionRestore(int pThis)
{
	if (!g_bMapsetInitialized)
		return Plugin_Continue;

	g_hLogger.DebugEx("### L4D2_OnTransitionRestore Called for %d, %N.", pThis, pThis);

	// not first map.
	if (!L4D_IsFirstMapInScenario() && g_iMapsPlayed != 1)
		SetGod(pThis, true);

	RequestFrame(OnNextFrame_ResetPlayers, pThis);	  // bots have not created, only player. same as midhook callback.
	Patch(g_hPatch_Player_BlockRestoring, g_hCvar_SaveStatus.BoolValue ? false : true);

	return Plugin_Continue;
}

// redirect the map name to our desired map.
MRESReturn DTR_CDirector_OnDirectorChangeLevel(DHookParam hParams)
{
	return RedirectMap(hParams);
}

// three onbeginchangelevel should be set to the right map.
MRESReturn DTR_CTerrorGameRules_OnBeginChangeLevel(DHookParam hParams)
{
	return RedirectMap(hParams);
}

MRESReturn RedirectMap(DHookParam hParams)
{
	if (g_bMapsetInitialized)
	{
		if (L4D2_IsScavengeMode())
			return MRES_Ignored;

		g_hLogger.Trace("### RedirectMap Called.");

		char sMap[128];
		if (g_hLogger.GetLevel() <= LogLevel_Debug)
		{
			if (hParams.IsNull(1))
			{
				g_hLogger.Error("### RedirectMap: hParams.IsNull(1): true.");
				return MRES_Ignored;
			}
			else
			{
				hParams.GetString(1, sMap, sizeof(sMap));
				g_hLogger.DebugEx("### RedirectMap: Original Map Name: \"%s\".", sMap);
			}
		}

		if (g_iMapsPlayed >= g_hArrayPools.Length)
			return MRES_Ignored;

		g_hArrayPools.GetString(g_iMapsPlayed, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### RedirectMap: Transition Map Name: \"%s\".", sMap);
		hParams.SetString(1, sMap);

		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

// bots have created.
public void L4D2_OnRestoreTransitionedSurvivorBots_Post()
{
	if (!g_bMapsetInitialized)
		return;

	g_hLogger.Trace("### L4D2_RestoreTransitionedSurvivorBots_Post Called.");

	// rarely, bots died before we teleport them.
	// need to set them god like.
	for (int i = 1; i < MaxClients; i++)
	{
		if (i <= 0 || i > MaxClients)
			continue;

		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsFakeClient(i))
			continue;

		// not first map.
		if (!L4D_IsFirstMapInScenario() && g_iMapsPlayed != 1)
			SetGod(i, true);
	}

	RequestFrame(OnNextFrame_ResetPlayers, 0);
}

// prevent survivor bot disodering when map change using survivor set between l4d2 and l4d1.
// https://github.com/blueblur0730/modified-plugins/pull/20#issuecomment-2665756873
// why not read g_SavedSurvivorBots? it is probably a Keyvalues array, or a CultVector.
// been tried to read it from memory but the thing we read from looks like not a KeyValues pointer, crashes server, no idea.
// so we use midhook to read the KeyValues pointer from the register.
void MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter(MidHookRegisters reg)
{
	if (!g_bMapsetInitialized)
		return;

	g_hLogger.Trace("### MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter: Called");

	// patch bots from restoring gears.
	Patch(g_hPatch_Bot_BlockRestoring, g_hCvar_SaveStatus_Bot.BoolValue ? false : true);

	SourceKeyValues kvPlayerData = reg.Load(DHookRegister_EDI, _, NumberType_Int32);
	g_hLogger.DebugEx("### MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter: kvPlayerData: %d", kvPlayerData);
	if (!kvPlayerData || kvPlayerData.IsNull())
	{
		g_hLogger.Error("### MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter: kvPlayerData.IsNull: true.");
		return;
	}

	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));
	kvPlayerData.SetString("targetMap", sMap);

	int oldSet = kvPlayerData.GetInt("SurvivorSet", 2);
	int newSet = g_hArraySurvivorSets.Get(g_iMapsPlayed - 1);
	g_hLogger.DebugEx("### MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter: Comparing survivor set. oldSet: %d, newSet: %d", oldSet, newSet);

	if (oldSet == newSet)
		return;

	kvPlayerData.SetInt("SurvivorSet", newSet);	   // next map's survivor set.

	int index = kvPlayerData.GetInt("character", 0);
	g_hLogger.DebugEx("### MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter: index: %d", index);

	if (newSet == 1)
	{
		if (index <= 3)
			index += 4;
	}
	else if (newSet == 2)
	{
		if (index >= 4)
			index -= 4;
	}

	g_hLogger.DebugEx("### MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter: Changed index: %d", index);

	char modelName[128];
	GetCorrespondingModel(index, modelName, sizeof(modelName));
	kvPlayerData.SetString("modelName", modelName);
	g_hLogger.DebugEx("### MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter: Setting index: %d, modelName: %s", index, modelName);

	kvPlayerData.SetInt("character", index);

	char idealName[32];
	GetCorrespondingName(index, idealName, sizeof(idealName));
	kvPlayerData.SetString("idealName", idealName);

	int		 userid = kvPlayerData.GetInt("userID", 0);
	DataPack dp		= new DataPack();
	dp.WriteCell(index);
	dp.WriteCell(userid);

	// one frame after, as the hook is before the bot creation.
	RequestFrame(OnNextFrame_ChangeName, dp);
}

void OnNextFrame_ChangeName(DataPack dp)
{
	dp.Reset();
	int index  = dp.ReadCell();
	int userid = dp.ReadCell();
	delete dp;

	int client = GetClientOfUserId(userid);
	if (client <= 0 || client > MaxClients)
		return;

	char sName[32];
	GetCorrespondingName(index, sName, sizeof(sName));

	SetClientInfo(client, "name", sName);
	SetEntPropString(client, Prop_Data, "m_szNetname", sName);
}

void OnNextFrame_ResetPlayers(int client)
{
	// this should be always safe if a first map appears in the middle of the pool.
	if (L4D_IsFirstMapInScenario())
	{
		SetGod(client, false);
		return;
	}

	if (client > 0)
	{
		ResetPlayer(client);
	}
	else
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (i <= 0 || i > MaxClients)
				continue;

			if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsFakeClient(i))
				continue;

			ResetPlayer(i);
		}
	}
}

void ResetPlayer(int client)
{
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	g_hLogger.DebugEx("### OnNextFrame_ResetPlayer: Checking %N.", client);
	
	if (!IsClientInSafeArea(client) || !IsOnValidMesh(vecOrigin))
	{
		g_hLogger.DebugEx("### OnNextFrame_ResetPlayer: Client %N is not in saferoom.", client);

		float vec[3];
		GetSafeAreaOrigin(vec);
		g_hLogger.DebugEx("### OnNextFrame_ResetPlayer: Found teleport destination: %.2f, %.2f, %.2f.", vec[0], vec[1], vec[2]);
		if (vec[0] != 0.0 && vec[1] != 0.0 && vec[2] != 0.0)
		{
			TeleportEntity(client, vec, NULL_VECTOR, NULL_VECTOR);


			//if (!IsClientInSafeArea(client))
				//CheatCommand(client, "warp_to_start_area");
		}
	}

	// only available when player is not inside the wall (have a valid nav.), that's why we need to teleport them first by searching the valid point then this.
	// so this is used to teleport player twice in case they were teleported outside the saferoom.
	// edit: no matter what, this should be called just in case.
	CheatCommand(client, "warp_to_start_area");

	if (GetPlayerWeaponSlot(client, 1) == -1)
		CheatCommand(client, "give", "pistol");

	SetGod(client, false);
}