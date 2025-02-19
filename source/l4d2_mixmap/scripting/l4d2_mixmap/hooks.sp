#if defined _l4d2_mixmap_hooks_included
 #endinput
#endif
#define _l4d2_mixmap_hooks_included

// prevent weapons and items in the last saferoom spawned in this saferoom.
MRESReturn DTR_OnRestoreTransitionedEntities()
{
    if (g_bMapsetInitialized)
    {
	    g_hLogger.Trace("### DTR_OnRestoreTransitionedEntities Called. Superceded.");
	    return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnTransitionRestore(int pThis, DHookReturn hReturn)
{
	if (!g_bMapsetInitialized)
		return MRES_Ignored;

	g_hLogger.TraceEx("### DTR_CTerrorPlayer_OnTransitionRestore Called for %d, %N.", pThis, pThis);
	CheatCommand(pThis, "warp_to_start_area");

	if (GetPlayerWeaponSlot(pThis, 1) == -1)
		CheatCommand(pThis, "give", "pistol");

	// this only block human player's status.
	if (!g_hCvar_SaveStatus.BoolValue)
	{
		// returns a keyvalues pointer. it's ok to set 0.
		hReturn.Value = 0;
		g_hLogger.Trace("### DTR_CTerrorPlayer_OnTransitionRestore Superceded.");
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

// redirect the map name to our desired map.
MRESReturn DTR_CDirector_OnDirectorChangeLevel(DHookParam hParams)
{
	if (g_bMapsetInitialized)
	{
		g_hLogger.Trace("### DTR_CDirector_OnDirectorChangeLevel Called.");

		char sMap[128];
		if (g_hLogger.GetLevel() <= LogLevel_Debug)
		{
			if (hParams.IsNull(1))
			{
				g_hLogger.Error("### DTR_CDirector_OnDirectorChangeLevel: hParams.IsNull(1): true.");
				return MRES_Ignored;
			}
			else
			{
				hParams.GetString(1, sMap, sizeof(sMap));
				g_hLogger.DebugEx("### DTR_CDirector_OnDirectorChangeLevel: Original Map Name: %s.", sMap);
			}
		}

		g_hArrayPools.GetString(g_iMapsPlayed, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_CDirector_OnDirectorChangeLevel: Transition Map Name: %s.", sMap);
		hParams.SetString(1, sMap);

		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

// three onbeginchangelevel should be set to the right map.
MRESReturn DTR_CTerrorGameRules_OnBeginChangeLevel(DHookParam hParams)
{
	if (g_bMapsetInitialized)
	{
		g_hLogger.Trace("### DTR_CTerrorGameRules_OnBeginChangeLevel Called.");

		char sMap[128];
		if (g_hLogger.GetLevel() <= LogLevel_Debug)
		{
			if (hParams.IsNull(1))
			{
				g_hLogger.Error("### DTR_CTerrorGameRules_OnBeginChangeLevel: hParams.IsNull(1): true.");
				return MRES_Ignored;
			}
			else
			{
				hParams.GetString(1, sMap, sizeof(sMap));
				g_hLogger.DebugEx("### DTR_CTerrorGameRules_OnBeginChangeLevel: Original Map Name: %s.", sMap);
			}
		}
		
		g_hArrayPools.GetString(g_iMapsPlayed, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_CTerrorGameRules_OnBeginChangeLevel: Transition Map Name: %s.", sMap);
		hParams.SetString(1, sMap);

		return MRES_ChangedHandled;
    }

    return MRES_Ignored;
}

// prevent survivor bot disodering when map change using survivor set between l4d2 and l4d1.
// https://github.com/blueblur0730/modified-plugins/pull/20#issuecomment-2665756873
void MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter(MidHookRegisters reg)
{
	if (!g_bMapsetInitialized)
		return;
	
	g_hLogger.Trace("### MidHook_RestoreTransitionedSurvivorBots__ChangeCharacter: Called");

	if (g_iMapsPlayed > 0)
		g_hCvar_SaveStatus_Bot.BoolValue ? Patch(false) : Patch(true);

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

	kvPlayerData.SetInt("SurvivorSet", newSet);	// next map's survivor set.

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
		
	int userid = kvPlayerData.GetInt("userID", 0);
	DataPack dp = new DataPack();
	dp.WriteCell(index);
	dp.WriteCell(userid);
		
	// one frame after, as the hook is before the bot creation.
	RequestFrame(OnNextFrame_ChangeName, dp);
}

void OnNextFrame_ChangeName(DataPack dp)
{
	dp.Reset();
	int index = dp.ReadCell();
	int userid = dp.ReadCell();
	delete dp;

	char sName[32];
	GetCorrespondingName(index, sName, sizeof(sName));
	int client = GetClientOfUserId(userid);
	if (client > 0 && client <= MaxClients)
	{
    	SetClientInfo(client, "name", sName);
    	SetEntPropString(client, Prop_Data, "m_szNetname", sName);
	}
}