#if defined _l4d2_mixmap_actions_included
 #endinput
#endif
#define _l4d2_mixmap_actions_included

#define DEBUG 1

static ArrayList
	s_hArrayPlayerInfo = null;

static int
	s_iPointsTeam_A = 0,
	s_iPointsTeam_B = 0,
	s_iEntityIndex[MAXPLAYERS + 1];

static bool
	s_IsMeleeWeapon[MAXPLAYERS + 1];

	
// ----------------------------------------------------------
// 		Map switching logic
// ----------------------------------------------------------
Action PerformMapProgression()
{
	if (++g_iMapsPlayed < g_iMapCount)
	{
		GotoNextMap(false);
		return Plugin_Handled;
	}
	else if (g_cvFinaleEndStart.IntValue)
	{
		CPrintToChatAll("%t", "Plugin_Continue");
		CreateTimer(9.0, Timed_ContinueMixmap);
	}

	CPrintToChatAll("%t", "Plugin_End");

	Call_StartForward(g_hForwardEnd);
	Call_Finish();

	return Plugin_Handled;
}

void GotoNextMap(bool force = false)
{
	char sMapName[BUF_SZ];
	g_hArrayMapOrder.GetString(g_iMapsPlayed, sMapName, BUF_SZ);

	GotoMap(sMapName, force);
}

void GotoMap(const char[] sMapName, bool force = false)
{
	if (force)
	{
		L4D2_ChangeLevel(sMapName, false);		// set false to not reset the scores.
		return;
	}

	// go faster in coop mode. you know how speedy the game is.
	CreateTimer(((L4D_IsVersusMode() && L4D2_IsScavengeMode()) ? 5.0 : 0.1), Timed_NextMapInfo);
}

// here we store the match or game info for the next map.
public Action Timed_NextMapInfo(Handle timer)
{
	char sMapName_New[BUF_SZ], sMapName_Old[BUF_SZ];
	g_hArrayMapOrder.GetString(g_iMapsPlayed, sMapName_New, BUF_SZ);
	g_hArrayMapOrder.GetString(g_iMapsPlayed - 1, sMapName_Old, BUF_SZ);

	g_cvNextMapPrint.BoolValue ? CPrintToChatAll("%t", "Show_Next_Map",  sMapName_New) : CPrintToChatAll("%t%t", "Show_Next_Map",  "", "Secret");

	if (L4D_IsVersusMode())
	{
		if ((StrEqual(sMapName_Old, "c6m2_bedlam") && !StrEqual(sMapName_New, "c7m1_docks"))
		|| (StrEqual(sMapName_Old, "c9m2_lots") && !StrEqual(sMapName_New, "c14m1_junkyard")))
		{
			s_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			s_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;
			CreateTimer(9.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
		else if ((!StrEqual(sMapName_Old, "c6m2_bedlam") && StrEqual(sMapName_New, "c7m1_docks"))
		|| (!StrEqual(sMapName_Old, "c9m2_lots") && StrEqual(sMapName_New, "c14m1_junkyard")))
		{
			s_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			s_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;
			CreateTimer(10.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
	}
	else if (L4D2_IsScavengeMode())
	{
		MatchInfo esMatchInfo;

		// currently we are flipped.
		esMatchInfo.rs_TeamA = GetScavengeTeamScore(2, GetScavengeRoundNumber());		// team index 1, score 2, match score 0
		esMatchInfo.rs_TeamB = GetScavengeTeamScore(3, GetScavengeRoundNumber());		// team index 0, score 8, match score 1
		esMatchInfo.ms_TeamA = GetScavengeMatchScore(2);
		esMatchInfo.ms_TeamB = GetScavengeMatchScore(3);
		esMatchInfo.winner	 = GetWinningTeamNumber(GetScavengeRoundNumber());

		g_hArrayMatchInfo.PushArray(esMatchInfo);

#if DEBUG
		PrintToServer("[Mixmap] Survivor Round Score: %d", esMatchInfo.rs_TeamA);
		PrintToServer("[Mixmap] Infected Round Score: %d", esMatchInfo.rs_TeamB);
		PrintToServer("[Mixmap] Survivor Match Score: %d", esMatchInfo.ms_TeamA);
		PrintToServer("[Mixmap] Infected Match Score: %d", esMatchInfo.ms_TeamB);
		PrintToServer("[Mixmap] Winner Team Index: %d", esMatchInfo.winner);
#endif
		g_bCMapTransitioned = true;
		CreateTimer(5.0, Timed_Gotomap);
	}
	else if (L4D2_IsGenericCooperativeMode())
	{
		if (g_cvSaveStatus.BoolValue)
		{
			PlayerInfo esPlayerInfo;

			if (s_hArrayPlayerInfo == null)
				s_hArrayPlayerInfo = new ArrayList(sizeof(PlayerInfo));

			for (int i = 1; i < MaxClients; i++)
			{
				if (g_cvSaveStatusBot.BoolValue)
				{
					if(!IsClientOrBotAndInGame(i))
						continue;
				}
				else if (!IsClientAndInGame(i))
						continue;

				if (!IsPlayerAlive(i))
				{
					esPlayerInfo.health 	 = 50;
					esPlayerInfo.alive 		 = false;
					continue;
				}
					
				esPlayerInfo.health		 	 = GetClientHealth(i);
				esPlayerInfo.temp_health 	 = L4D_GetTempHealth(i);
				esPlayerInfo.revive_count 	 = GetEntProp(i, Prop_Send, "m_currentReviveCount");
				esPlayerInfo.alive 			 = true;

				esPlayerInfo.slot0 			 = IdentifyWeapon(			GetPlayerWeaponSlot(i, L4D2WeaponSlot_Primary));
				esPlayerInfo.ammo 			 = GetWeaponClipAmmo(		GetPlayerWeaponSlot(i, L4D2WeaponSlot_Primary));
				esPlayerInfo.ammo_reserved 	 = L4D_GetReserveAmmo(i, 	GetPlayerWeaponSlot(i, L4D2WeaponSlot_Primary));
				esPlayerInfo.ammo_type		 = GetEntProp(				GetPlayerWeaponSlot(i, L4D2WeaponSlot_Primary), Prop_Data, "m_iPrimaryAmmoType");

				s_iEntityIndex[i]			 =							GetPlayerWeaponSlot(i, L4D2WeaponSlot_Primary);

				esPlayerInfo.slot1 			 = IdentifyWeapon(			GetPlayerWeaponSlot(i, L4D2WeaponSlot_Secondary));
				if (esPlayerInfo.slot1 == WEPID_MELEE)
				{
					esPlayerInfo.slot1		 = IdentifyMeleeWeapon(		GetPlayerWeaponSlot(i, L4D2WeaponSlot_Secondary));
					s_IsMeleeWeapon[i] 		 = true;
					esPlayerInfo.ammo_pistol = 0;
				}
				else
					esPlayerInfo.ammo_pistol = GetWeaponClipAmmo(		GetPlayerWeaponSlot(i, L4D2WeaponSlot_Secondary));
					
				esPlayerInfo.slot2 			 = IdentifyWeapon(			GetPlayerWeaponSlot(i, L4D2WeaponSlot_Throwable));
				esPlayerInfo.slot3 			 = IdentifyWeapon(			GetPlayerWeaponSlot(i, L4D2WeaponSlot_HeavyHealthItem));
				esPlayerInfo.slot4 			 = IdentifyWeapon(			GetPlayerWeaponSlot(i, L4D2WeaponSlot_LightHealthItem));

				s_hArrayPlayerInfo.PushArray(esPlayerInfo);
			}

			g_bCMapTransitioned = true;
			CreateTimer(1.0, Timed_Gotomap);
		}
	}

	return Plugin_Handled;
}

public Action Timed_Gotomap(Handle timer)
{
	char sMapName_New[BUF_SZ];
	g_hArrayMapOrder.GetString(g_iMapsPlayed, sMapName_New, BUF_SZ);

	GotoMap(sMapName_New, true);
	return Plugin_Handled;
}

public Action Timed_ContinueMixmap(Handle timer)
{
	ServerCommand("sm_fmixmap %s", cfg_exec);
	return Plugin_Handled;
}

//-----------------------------------------------------------
//			Set Info
//-----------------------------------------------------------
void SetVersusScores()
{
	// If team B is winning, swap teams. Does not change how scores are set.
	if (s_iPointsTeam_A < s_iPointsTeam_B)
		L4D2_SwapTeams();

	// Set scores on scoreboard.
	SDKCall(g_hCMapSetCampaignScores, s_iPointsTeam_A, s_iPointsTeam_B);

	// Set actual scores.
	L4D2Direct_SetVSCampaignScore(0, s_iPointsTeam_A);
	L4D2Direct_SetVSCampaignScore(1, s_iPointsTeam_B);
}

void SetScavengeScores()
{
	MatchInfo esMatchInfo;
	for (int i = 0; i < g_iMapsPlayed; i++)
	{
		g_hArrayMatchInfo.GetArray(i, esMatchInfo);

		SetScavengeRoundNumber(g_iMapsPlayed + 1);
		SetScavengeTeamScore(2, i + 1, esMatchInfo.rs_TeamA);
		SetScavengeTeamScore(3, i + 1, esMatchInfo.rs_TeamB);

		if (i == g_iMapsPlayed - 1)		// we only set the score at the end of array
		{
			SetScavengeMatchScore(2, esMatchInfo.ms_TeamA);			
			SetScavengeMatchScore(3, esMatchInfo.ms_TeamB);
		}
	}
}

void SetWinningTeam()
{
	MatchInfo esMatchInfo;

	for (int i = 0; i < GetScavengeRoundNumber(); i++)
	{
		if (i == GetScavengeRoundNumber() - 1)
			break;

		g_hArrayMatchInfo.GetArray(i, esMatchInfo);

		SetWinningTeamNumber(i, esMatchInfo.winner);
	}
}

void SetTeam()
{
	MatchInfo esMatchInfo;
	g_hArrayMatchInfo.GetArray(GetScavengeRoundNumber() - 2, esMatchInfo);

	// winner go ghost, loser grab guns.
	if (esMatchInfo.rs_TeamA > esMatchInfo.rs_TeamB)
		L4D2_SwapTeams();
}

void SetCompaignInfo()
{
	char slot0[64], slot1[64], slot2[64], slot3[64], slot4[64];
	PlayerInfo esPlayerInfo;

	for (int i = 1; i < MaxClients; i++)
	{
		if (g_cvSaveStatusBot.BoolValue)
		{
			if(!IsClientOrBotAndInGame(i))
				continue;
		}
		else if (!IsClientAndInGame(i))
				continue;
				
		s_hArrayPlayerInfo.GetArray(i, esPlayerInfo);

		if (!esPlayerInfo.alive)
		{
			SetEntProp(i, Prop_Send, "m_iHealth", esPlayerInfo.health);
			continue;
		}

		SetEntProp(i, Prop_Send, "m_iHealth", esPlayerInfo.health);
		L4D_SetTempHealth(i, esPlayerInfo.temp_health);
		SetEntProp(i, Prop_Send, "m_currentReviveCount", esPlayerInfo.revive_count);

		GetWeaponName(esPlayerInfo.slot0, slot0, sizeof(slot0));

		if (s_IsMeleeWeapon[i])
			GetMeleeWeaponName(esPlayerInfo.slot1, slot1, sizeof(slot1));
		else
			GetWeaponName(esPlayerInfo.slot1, slot1, sizeof(slot1));

		GetWeaponName(esPlayerInfo.slot2, slot2, sizeof(slot2));
		GetWeaponName(esPlayerInfo.slot3, slot3, sizeof(slot3));
		GetWeaponName(esPlayerInfo.slot4, slot4, sizeof(slot4));

		GivePlayerItem(i, slot0);
		GivePlayerItem(i, slot1);
		GivePlayerItem(i, slot2);
		GivePlayerItem(i, slot3);
		GivePlayerItem(i, slot4);

		SetWeaponClipAmmo(s_iEntityIndex[i], esPlayerInfo.ammo);
		L4D_SetReserveAmmo(i, s_iEntityIndex[i], esPlayerInfo.ammo_reserved);
	}

	delete s_hArrayPlayerInfo;
}