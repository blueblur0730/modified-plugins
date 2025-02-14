#if defined _l4d2_mixmap_actions_included
 #endinput
#endif
#define _l4d2_mixmap_actions_included

MRESReturn DTR_OnRestoreTransitionedEntities()
{
#if DEBUG
	PrintToServer("### DTR_OnRestoreTransitionedEntities Called.");
#endif
	//return MRES_Supercede;
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnTransitionRestore_Post(int pThis) 
{
#if DEBUG
	PrintToServer("### DTR_CTerrorPlayer_OnTransitionRestore_Post Called.");
#endif

	if (GetClientTeam(pThis) > 2 || !g_bMapsetInitialized)
		return MRES_Ignored;

	// in case the size of the saferoom dose not match the size before the transition, we teleport them back.
	CheatCommand(pThis, "warp_to_start_area");
	return MRES_Ignored;
}

MRESReturn DTR_CDirector_OnDirectorChangeLevel(DHookParam hParams)
{
#if DEBUG
	PrintToServer("### DTR_CDirector_OnDirectorChangeLevel Called.");
#endif

	// SDKCall(g_hSDKCall_IsFirstMapInScenario, g_pTheDirector);
	if (g_bMapsetInitialized)
	{
		if (hParams.IsNull(1))
		{
			LogError("DTR_CDirector_OnDirectorChangeLevel: hParams.IsNull(1): true.");
			return MRES_Ignored;
		}

		char sMap[128];
		
#if DEBUG
		hParams.GetString(1, sMap, sizeof(sMap));
		PrintToServer("### DTR_CDirector_OnDirectorChangeLevel: Original Map Name: %s.", sMap);
#endif

		g_hArrayPools.GetString(g_iMapsPlayed, sMap, sizeof(sMap));

#if DEBUG
		PrintToServer("### DTR_CDirector_OnDirectorChangeLevel: Transition Map Name: %s.", sMap);
#endif

		hParams.SetString(1, sMap);
	}

	return MRES_Handled;
}

/*

 * Thanks to Yuzumi for all of the transferation code.
 * The comments below is made by Yuzumi.


// find info_changelevel and info_landmark
bool FindMapEntity() 
{
	**
	 * @Yuzumi:
	 * Check if there's a changelevel entity, if not, then this is the finale map
	 * some third party map may have more than one changelevel entity.
	 * To transfer the gear in the last round, there's must be a landmark entity which is not bound to changelevel entity, 
	 * the name of the landmark entity is the name we use to transfer the data to this chapter
	 *
	int info_changelevel, info_landmark, iModifyLandMarkID = INVALID_ENT_REFERENCE;
	char sLandMarkName[128], sBindName[128];
	bool bChangeLevelAvailable = true;

	// set fail if not found.
	if ((info_changelevel = FindEntityByClassname(info_changelevel, "info_changelevel")) == INVALID_ENT_REFERENCE) 
	{
		bChangeLevelAvailable = false;
	} 
	else 
	{
		// get the name of info_landmark that bound to this info_changelevel.
		GetEntPropString(info_changelevel, Prop_Data, "m_slandmarkName", sBindName, sizeof sBindName);
		if (sBindName[0] == '\0') 
			bChangeLevelAvailable = false;
	}

	// Loop through it, find all info_landmark that has not bound to or can be modified.
	while ((info_landmark = FindEntityByClassname(info_landmark, "info_landmark")) != INVALID_ENT_REFERENCE) 
	{
		// check its name. if this is same as the name that info_changelevel bound to, then it's the landmark entity used to modify. save the id.
		GetEntPropString(info_landmark, Prop_Data, "m_iName", sLandMarkName, sizeof sLandMarkName);
		if (StrEqual(sLandMarkName, sBindName, false)) 
		{
			iModifyLandMarkID = info_landmark;
		} 
		else 
		{
			if (!g_bFirstMap) 
			{
				// put the name used to transition to the certain map of the landmark entity into the global variable.
				Format(g_sValidsLandMarkName, sizeof (g_sValidsLandMarkName), "%s", sLandMarkName); // 用于写配置项
			}
		}
	}

	// if no avaiable modified entity or already failed, return false.
	if (iModifyLandMarkID == INVALID_ENT_REFERENCE || ! bChangeLevelAvailable) 
		return false;
	
	// store these globally.
	g_iEnt_ChangeLevelID = info_changelevel;
	g_iEnt_LandMarkID = iModifyLandMarkID;

	return true;
}

// change the netprop of the entity, to the gaol map we need to transision to.
void ChangeEntityProp() 
{
	char sMapName[64];
	g_sTransitionMap[0] = '\0';

	if (g_iEnt_ChangeLevelID == INVALID_ENT_REFERENCE || ! IsValidEntity(g_iEnt_ChangeLevelID)) 
		return;
	
	if (g_iEnt_LandMarkID == INVALID_ENT_REFERENCE || ! IsValidEntity(g_iEnt_LandMarkID)) 
		return;

	if (! GetChangeLevelMap(sMapName, sizeof sMapName)) 
	{
		PrintToChatAll("Currently in a single timeline without any temporal fluctuations.");
		return;
	}

	char sLandMarkName[128];
	g_mMapLandMarkSet.GetString(sMapName, sLandMarkName, sizeof sLandMarkName);
	SetEntPropString(g_iEnt_ChangeLevelID, Prop_Data, "m_mapName", sMapName);
	SetEntPropString(g_iEnt_ChangeLevelID, Prop_Data, "m_landmarkName", sLandMarkName);
	SetEntPropString(g_iEnt_LandMarkID, Prop_Data, "m_iName", sLandMarkName);
	g_sTransitionMap = sMapName;
	PrintToChatAll("An uncharted rift in space-time has appeared. After changeLevel, you will travel to %s ...", sMapName);
}
*/

/*
// here we store the match or game info for the next map.
Action Timed_NextMapInfo(Handle timer)
{
	char ssMapName_New[64], ssMapName_Old[64];
	g_hArrayPools.GetString(g_iMapsPlayed, ssMapName_New, 64);
	g_hArrayPools.GetString(g_iMapsPlayed - 1, ssMapName_Old, 64);

	g_cvNextMapPrint.BoolValue ? CPrintToChatAll("%t", "Show_Next_Map",  ssMapName_New) : CPrintToChatAll("%t%t", "Show_Next_Map",  "", "Secret");

	if (L4D_IsVersusMode())
	{
		if ((StrEqual(ssMapName_Old, "c6m2_bedlam") && !StrEqual(ssMapName_New, "c7m1_docks"))
		|| (StrEqual(ssMapName_Old, "c9m2_lots") && !StrEqual(ssMapName_New, "c14m1_junkyard")))
		{
			s_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			s_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;
#if DEBUG
			PrintToServer("[Mixmap] Timer_Gotomap creating.");
#endif
			CreateTimer(9.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
		else if ((!StrEqual(ssMapName_Old, "c6m2_bedlam") && StrEqual(ssMapName_New, "c7m1_docks"))
		|| (!StrEqual(ssMapName_Old, "c9m2_lots") && StrEqual(ssMapName_New, "c14m1_junkyard")))
		{
			s_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			s_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;
#if DEBUG
			PrintToServer("[Mixmap] Timer_Gotomap creating.");
#endif
			CreateTimer(10.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
	}

	return Plugin_Handled;
}
*/