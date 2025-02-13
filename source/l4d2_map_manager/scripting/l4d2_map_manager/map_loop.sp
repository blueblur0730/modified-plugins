#if defined _map_loop_included
    #endinput
#endif
#define _map_loop_included

bool g_bSwitched = false;

void _map_loop_OnPluginStart()
{
    RegConsoleCmdEx("sm_preservemap", Cmd_PreserveMap, "Preserve map.");
	//HookUserMessage(GetUserMessageId("DisconnectToLobby"), OnDisconnectToLobby);
    //HookEntityOutput("trigger_finale", "FinaleWon", OnFinaleWon);
    //HookEntityOutput("trigger_finale", "OnFinalStart", OnFinalStart); 
}

/*
static void OnFinaleWon(const char[] output, int caller, int activator, float delay)
{
    if (!g_bIsFinalMap)
        return;

	g_sPreservedMap[0] == '\0' ?  CPrintToChatAll("%t", "SwitchingMapRandom")
	:  CPrintToChatAll("%t", "SwitchingMap", g_sPreservedMap);

    !g_bPreserved ? CreateTimer(3.0, Timer_SwitchMap) :
    (g_sPreservedMap[0] == '\0' ? CreateTimer(3.0, Timer_SwitchMap) : CreateTimer(3.0, Timer_SwitchPreservedMap))

    g_bPreserved = false;
}
*/

MRESReturn DTR_CDirector_OnFinishScenarioExit()
{
	if (g_bSwitched)
		return MRES_Supercede;

	g_sPreservedMap[0] == '\0' ?  CPrintToChatAll("%t", "SwitchingMapRandom")
	:  CPrintToChatAll("%t", "SwitchingMap", g_sPreservedMap);

    !g_bPreserved ? CreateTimer(3.0, Timer_SwitchMap) :
    (g_sPreservedMap[0] == '\0' ? CreateTimer(1.0, Timer_SwitchMap) : CreateTimer(1.0, Timer_SwitchPreservedMap))

	if (!g_bSwitched)
		g_bSwitched = true;

    g_bPreserved = false;
	return MRES_Supercede;
}

void _map_loop_OnClientPutInServer(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

    if (!g_bIsFinalMap)
        return;

    CreateTimer(5.0, Timer_NotifyPreserve, client);
}

/*
static Action OnDisconnectToLobby(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	g_sPreservedMap[0] == '\0' ?  CPrintToChatAll("%t", "SwitchingMapRandom")
	:  CPrintToChatAll("%t", "SwitchingMap", g_sPreservedMap);

    !g_bPreserved ? CreateTimer(3.0, Timer_SwitchMap) :
    (g_sPreservedMap[0] == '\0' ? CreateTimer(3.0, Timer_SwitchMap) : CreateTimer(3.0, Timer_SwitchPreservedMap))

    g_bPreserved = false;
	return Plugin_Handled;
}
*/
/*
static void OnFinalStart(const char[] output, int caller, int activator, float delay)
{

}
*/
static void Timer_NotifyPreserve(Handle timer, int client)
{
    CPrintToChat(client, "%t", "NotifyPreserve");
}

static void Timer_SwitchMap(Handle timer)
{
	g_bSwitched = false;
    SwitchToOfficialMap();
}

static void Timer_SwitchPreservedMap(Handle timer)
{
    char sMissionName[256];
    if (g_smFirstMap.GetString(g_sPreservedMap, sMissionName, sizeof(sMissionName)))
		SDKCall(g_hSDKChangeMission, g_pTheDirector, sMissionName);
    else
        SwitchToOfficialMap();

	g_bSwitched = false;

	for (int i = 0; i < strlen(g_sPreservedMap); i++)
      g_sPreservedMap[i] = '\0' ; 
}

static void SwitchToOfficialMap()
{
    int iFactor = GetRandomInt(1, 14);
    char sMissionName[256];
    switch (iFactor)
    {
        case 1: g_smFirstMap.GetString("c1m1_hotel", sMissionName, sizeof(sMissionName));
        case 2: g_smFirstMap.GetString("c2m1_highway", sMissionName, sizeof(sMissionName));
        case 3: g_smFirstMap.GetString("c3m1_plankcountry", sMissionName, sizeof(sMissionName));
        case 4: g_smFirstMap.GetString("c4m1_milltown_a", sMissionName, sizeof(sMissionName));
        case 5: g_smFirstMap.GetString("c5m1_waterfront", sMissionName, sizeof(sMissionName));
        case 6: g_smFirstMap.GetString("c6m1_riverbank", sMissionName, sizeof(sMissionName));
        case 7: g_smFirstMap.GetString("c7m1_docks", sMissionName, sizeof(sMissionName));
        case 8: g_smFirstMap.GetString("c8m1_apartment", sMissionName, sizeof(sMissionName));
        case 9: g_smFirstMap.GetString("c9m1_alleys", sMissionName, sizeof(sMissionName));
        case 10: g_smFirstMap.GetString("c10m1_caves", sMissionName, sizeof(sMissionName));
        case 11: g_smFirstMap.GetString("c11m1_greenhouse", sMissionName, sizeof(sMissionName));
        case 12: g_smFirstMap.GetString("c12m1_hilltop", sMissionName, sizeof(sMissionName));
        case 13: g_smFirstMap.GetString("c13m1_alpincreek", sMissionName, sizeof(sMissionName));
        case 14: g_smFirstMap.GetString("c14m1_junkyard", sMissionName, sizeof(sMissionName));
    }

    if (!strlen(sMissionName))
        return;

    SDKCall(g_hSDKChangeMission, g_pTheDirector, sMissionName);
}

static Action Cmd_PreserveMap(int client, int args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (!IsValidTeamFlags(client, g_MvAttr.MenuTeamFlags))
		return Plugin_Handled;

	Menu menu = new Menu(PreserveMap_MenuHandler);
    static char sBuffer[256];
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "ChoosePreserveMapType", client);
	menu.SetTitle(sBuffer);

    FormatEx(sBuffer, sizeof(sBuffer), "%T", "OfficialMaps", client);
	menu.AddItem("", sBuffer);

    FormatEx(sBuffer, sizeof(sBuffer), "%T", "ThirdPartyMaps", client);
	menu.AddItem("", sBuffer);
	menu.Display(client, 20);

    return Plugin_Handled;
}

static int PreserveMap_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			g_iType[client] = itemNum;
			g_iPos[client][0] = 0;
			g_iPos[client][1] = 0;

			ShowMapMenu(client);
		}
        
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

static void ShowMapMenu(int client)
{
	static char sSubName[256], sTitle[256], sKey[256];
    static char sBuffer[256];
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "ChooseMap", client);
	Menu menu = new Menu(NextMap_MenuHandler);
	menu.SetTitle(sBuffer);

	SourceKeyValues kvMissions = SDKCall(g_hSDKGetAllMissions, g_pMatchExtL4D);
	for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey())
	{
		kvSub.GetName(sSubName, sizeof(sSubName));
		if (g_smExcludeMissions.ContainsKey(sSubName))
			continue;

		FormatEx(sKey, sizeof(sKey), "modes/%s", g_sMode);
		if (kvSub.FindKey(sKey).IsNull())
			continue;

		if (g_iType[client] == 0 && kvSub.GetInt("builtin"))
		{
			kvSub.GetString("DisplayTitle", sTitle, sizeof(sTitle), "N/A");
			g_smTranslate.GetString(sTitle, sTitle, sizeof(sTitle));
			menu.AddItem(sSubName, sTitle);
		}
		else if (g_iType[client] == 1 && !kvSub.GetInt("builtin"))
		{
			kvSub.GetString("DisplayTitle", sTitle, sizeof(sTitle), "N/A");
			menu.AddItem(sSubName, sTitle);
		}
	}
	
	menu.ExitBackButton = true;
	menu.DisplayAt(client, g_iPos[client][g_iType[client]], 30);
}

static int NextMap_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			g_iPos[client][g_iType[client]] = menu.Selection;

			static char sTitle[256], sSubName[256];
			if (menu.GetItem(itemNum, sSubName, sizeof(sSubName), _, sTitle, sizeof(sTitle)))
				PreserveMap(client, sSubName, sTitle);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
				Cmd_PreserveMap(client, 0);
		}
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

static void PreserveMap(int client, const char[] sSubName, const char[] sTitle)
{
	static char sMap[256], sKey[256];
	
	FormatEx(sKey, sizeof(sKey), "%s/modes/%s", sSubName, g_sMode);
	SourceKeyValues kvMissions = SDKCall(g_hSDKGetAllMissions, g_pMatchExtL4D);
	SourceKeyValues kvChapters = kvMissions.FindKey(sKey);

	if (!kvChapters.IsNull())
	{
		SourceKeyValues kvSub = kvChapters.GetFirstTrueSubKey();
		if (!kvSub.IsNull())
		{
			kvSub.GetString("Map", sMap, sizeof(sMap), "N/A");
	        if (!L4D2NativeVote_IsAllowNewVote())
	        {
		        CPrintToChat(client, "%t", "VoteInProgress");
		        return;
	        }
	
	        L4D2NativeVote vote = L4D2NativeVote(Vote_Handler);
	        vote.SetDisplayText("预定一下战役: %s (%s)", sTitle, sMap);
	        vote.Initiator = client;
	        vote.SetInfoString(sMap);

	        int iPlayerCount = 0;
	        int[] iClients = new int[MaxClients];

	        for (int i = 1; i <= MaxClients; i++)
	        {
		        if (IsClientInGame(i) && !IsFakeClient(i))
			        iClients[iPlayerCount++] = i;
	        }

	        if (!vote.DisplayVote(iClients, iPlayerCount, 20))
            {
                CPrintToChat(client, "%t", "FailedToVote");
		        LogMessage("Failed to start vote");
            }
		}
	}
}

static void Vote_Handler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
	switch (action)
	{
		case VoteAction_Start:
		{
			char sDisplay[256];
			vote.GetDisplayText(sDisplay, sizeof(sDisplay));
			CPrintToChatAll("%t", "InitiatedVote", param1, sDisplay);
		}
		case VoteAction_PlayerVoted:
		{
			CPrintToChatAll("%t", "Voted", param1);

			if (!CheckCommandAccess(param1, "sm_admin", ADMFLAG_ROOT))
				return;

			if (param2 == VOTE_YES && g_MvAttr.bAdminOneVotePassed)
			{
				vote.YesCount = vote.PlayerCount;
				vote.NoCount = 0;
			}
			else if (param2 == VOTE_NO && g_MvAttr.bAdminOneVoteAgainst)
			{
				vote.YesCount = 0;
				vote.NoCount = vote.PlayerCount;
			}
		}
		case VoteAction_End:
		{
			if (vote.YesCount > vote.PlayerCount/2)
			{
				vote.SetPass("已设置预定章节地图...");

				char sMap[256];
				vote.GetInfoString(sMap, sizeof(sMap));

                strcopy(g_sPreservedMap, sizeof(g_sPreservedMap), sMap);
                g_bPreserved = true;

                Call_StartForward(g_hFWD_OnPreservedMap);
                Call_PushString(sMap);
                Call_Finish();
			}
			else
            {
                CPrintToChatAll("%t", "VoteFailed");
                vote.SetFail();
            }
		}
	}
}