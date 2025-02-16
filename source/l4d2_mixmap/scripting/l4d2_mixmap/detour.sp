#if defined _l4d2_mixmap_detour_included
 #endinput
#endif
#define _l4d2_mixmap_detour_included

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

MRESReturn DTR_CTerrorPlayer_OnTransitionRestore_Post(int pThis) 
{
	g_hLogger.Trace("### DTR_CTerrorPlayer_OnTransitionRestore_Post Called.");

	if (GetClientTeam(pThis) > 2 || !g_bMapsetInitialized)
		return MRES_Ignored;

	// in case the size of the saferoom dose not match the size before the transition, we teleport them back.
	CheatCommand(pThis, "warp_to_start_area");
	return MRES_Ignored;
}

// redirect the map name to our desired map.
MRESReturn DTR_CDirector_OnDirectorChangeLevel(DHookParam hParams)
{
	g_hLogger.Trace("### DTR_CDirector_OnDirectorChangeLevel Called.");

	if (g_bMapsetInitialized)
	{
		if (hParams.IsNull(1))
		{
			g_hLogger.Error("### DTR_CDirector_OnDirectorChangeLevel: hParams.IsNull(1): true.");
			return MRES_Ignored;
		}

		char sMap[128];
		hParams.GetString(1, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_CDirector_OnDirectorChangeLevel: Original Map Name: %s.", sMap);

		g_hArrayPools.GetString(g_iMapsPlayed, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_CDirector_OnDirectorChangeLevel: Transition Map Name: %s.", sMap);
		hParams.SetString(1, sMap);

        // clear the transitioned landmark name.
        SDKCall(g_hSDKCall_ClearTransitionedLandmarkName);
	}

	return MRES_ChangedHandled;
}

// three onbeginchangelevel should be set to the right map.
MRESReturn DTR_CTerrorGameRules_OnBeginChangeLevel(DHookParam hParams)
{
    g_hLogger.Trace("### DTR_CTerrorGameRules_OnBeginChangeLevel Called.");

	if (g_bMapsetInitialized)
	{
		if (hParams.IsNull(1))
		{
			g_hLogger.Error("### DTR_CTerrorGameRules_OnBeginChangeLevel: hParams.IsNull(1): true.");
			return MRES_Ignored;
		}

		char sMap[128];
		hParams.GetString(1, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_CTerrorGameRules_OnBeginChangeLevel: Original Map Name: %s.", sMap);

		g_hArrayPools.GetString(g_iMapsPlayed, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_CTerrorGameRules_OnBeginChangeLevel: Transition Map Name: %s.", sMap);
		hParams.SetString(1, sMap);
    }

    return MRES_ChangedHandled;
}

MRESReturn DTR_SurvivorBots_OnBeginChangeLevel(DHookParam hParams)
{
    g_hLogger.Trace("### DTR_SurvivorBots_OnBeginChangeLevel Called.");

	if (g_bMapsetInitialized)
	{
		if (hParams.IsNull(1))
		{
			g_hLogger.Error("### DTR_SurvivorBots_OnBeginChangeLevel: hParams.IsNull(1): true.");
			return MRES_Ignored;
		}

		char sMap[128];
		hParams.GetString(1, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_SurvivorBots_OnBeginChangeLevel: Original Map Name: %s.", sMap);

		g_hArrayPools.GetString(g_iMapsPlayed, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_SurvivorBots_OnBeginChangeLevel: Transition Map Name: %s.", sMap);
		hParams.SetString(1, sMap);
    }

    return MRES_ChangedHandled;
}

MRESReturn DTR_CTerrorPlayer_OnBeginChangeLevel(DHookParam hParams)
{
    g_hLogger.Trace("### DTR_CTerrorPlayer_OnBeginChangeLevel Called.");

	if (g_bMapsetInitialized)
	{
		if (hParams.IsNull(1))
		{
			g_hLogger.Error("### DTR_CTerrorPlayer_OnBeginChangeLevel: hParams.IsNull(1): true.");
			return MRES_Ignored;
		}

		char sMap[128];
		hParams.GetString(1, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_CTerrorPlayer_OnBeginChangeLevel: Original Map Name: %s.", sMap);

		g_hArrayPools.GetString(g_iMapsPlayed, sMap, sizeof(sMap));
		g_hLogger.DebugEx("### DTR_CTerrorPlayer_OnBeginChangeLevel: Transition Map Name: %s.", sMap);
		hParams.SetString(1, sMap);
    }

    return MRES_ChangedHandled;
}