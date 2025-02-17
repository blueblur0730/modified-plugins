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

MRESReturn DTR_CTerrorPlayer_OnTransitionRestore(int pThis, DHookReturn hReturn)
{
	g_hLogger.Trace("### DTR_CTerrorPlayer_OnTransitionRestore Called.");

	if (!g_bMapsetInitialized)
		return MRES_Ignored;
	
	// this only block human player's status.
	if (!g_hCvar_SaveStatus.BoolValue)
	{
		// returns a keyvalues pointer. it's ok to set 0.
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

/*
MRESReturn DTR_CTerrorPlayer_OnTransitionRestore_Post(int pThis) 
{
	g_hLogger.Trace("### DTR_CTerrorPlayer_OnTransitionRestore_Post Called.");

	if (!g_bMapsetInitialized)
		return MRES_Ignored;

	if (GetClientTeam(pThis) > 2)
		return MRES_Ignored;

	// in case the size of the saferoom dose not match the size before the transition, we teleport them back.
	// CTerrorPlayer seems only calls for human player. we loop it?
	//g_hLogger.Trace("### DTR_CTerrorPlayer_OnTransitionRestore_Post: Warpping players.");
	//CheatCommand(pThis, "warp_to_start_area");

	return MRES_Ignored;
}
*/

// redirect the map name to our desired map.
MRESReturn DTR_CDirector_OnDirectorChangeLevel(DHookParam hParams)
{
	g_hLogger.Trace("### DTR_CDirector_OnDirectorChangeLevel Called.");

	if (g_bMapsetInitialized)
	{
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

        // clear the transitioned landmark name.
        SDKCall(g_hSDKCall_ClearTransitionedLandmarkName);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

// three onbeginchangelevel should be set to the right map.
MRESReturn DTR_CTerrorGameRules_OnBeginChangeLevel(DHookParam hParams)
{
    g_hLogger.Trace("### DTR_CTerrorGameRules_OnBeginChangeLevel Called.");

	if (g_bMapsetInitialized)
	{
		if (!IsValidHandle(hParams))
		{
			g_hLogger.ErrorEx("### DTR_CTerrorGameRules_OnBeginChangeLevel: !IsValidHandle(hParams): true. hParams: %d.", hParams);
			return MRES_Ignored;
		}

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