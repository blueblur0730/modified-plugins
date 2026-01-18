#if defined _map_vote_included
    #endinput
#endif
#define _map_vote_included

void _map_vote_OnPluginStart()
{
    RegAdminCmdEx("sm_mapvote_attribute", Cmd_SetAttribute, ADMFLAG_ROOT);
	RegAdminCmdEx("sm_missions_export", Cmd_Rxport, ADMFLAG_ROOT);
	RegAdminCmdEx("sm_missions_reload", Cmd_Reload, ADMFLAG_ROOT);
	RegAdminCmdEx("sm_clear_scores", Cmd_ClearScores, ADMFLAG_ROOT);

	RegConsoleCmdEx("sm_mapvote", Cmd_VoteMap);
	RegConsoleCmdEx("sm_votemap", Cmd_VoteMap);
	RegConsoleCmdEx("sm_v3", Cmd_VoteMap);
}

static Action Cmd_SetAttribute(int client, int args)
{
	if (args != 2)
	{
		char cmd[128];
		GetCmdArg(0, cmd, sizeof(cmd));
		ReplyToCommand(client, "Syntax: %s <MenuTeamFlags|VoteTeamFlags|AdminOneVotePassed|AdminOneVoteAgainst> <value>", cmd);
		return Plugin_Handled;
	}

	char attribute[32];
	GetCmdArg(1, attribute, sizeof(attribute));
	int value = GetCmdArgInt(2);

	if (StrContains(attribute, "MenuTeamFlags", false) != -1)
		g_MvAttr.MenuTeamFlags = value;
		
	else if (StrContains(attribute, "VoteTeamFlags", false) != -1)
		g_MvAttr.VoteTeamFlags = value;

	else if (StrContains(attribute, "AdminOneVotePassed", false) != -1)
		g_MvAttr.bAdminOneVotePassed = value > 0;

	else if (StrContains(attribute, "AdminOneVoteAgainst", false) != -1)
		g_MvAttr.bAdminOneVoteAgainst = value > 0;

	else
		ReplyToCommand(client, "Bad attribute name: %s ", attribute);
	
	return Plugin_Handled;
}

static Action Cmd_Rxport(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "sm_missions_export <sFileName>");
		return Plugin_Handled;
	}

	char sFile[256];
	GetCmdArg(1, sFile, sizeof(sFile));
	SourceKeyValues kv = SDKCall(g_hSDKGetAllMissions, g_pMatchExtL4D);

	if (kv.SaveToFile(sFile))
		ReplyToCommand(client, "Save to file succeeded: %s", sFile);
	
	return Plugin_Handled;
}

static Action Cmd_Reload(int client, int args)
{
	ServerCommand("update_addon_paths");
	ServerCommand("mission_reload");
	ServerExecute();
	SetFirstMapString();

	ReplyToCommand(client, "Updated vpk files.");
	return Plugin_Handled;
}

static Action Cmd_ClearScores(int client, int args)
{
	SDKCall(g_hSDKClearTeamScores, g_pTheDirector, true);
	ReplyToCommand(client, "Cleared scores.");
	return Plugin_Handled;
}

static Action Cmd_VoteMap(int client, int args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	if (!IsValidTeamFlags(client, g_MvAttr.MenuTeamFlags))
		return Plugin_Handled;

    char sBuffer[256];
	Menu menu = new Menu(MapType_MenuHandler);
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "ChooseMapType", client);
	menu.SetTitle(sBuffer);

    FormatEx(sBuffer, sizeof(sBuffer), "%T", "OfficialMaps", client);
	menu.AddItem("", sBuffer);

    FormatEx(sBuffer, sizeof(sBuffer), "%T", "ThirdPartyMaps", client);
	menu.AddItem("", sBuffer);

	menu.Display(client, 20);
	return Plugin_Handled;
}

static int MapType_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
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
	Menu menu = new Menu(Title_MenuHandler);
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

static int Title_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			g_iPos[client][g_iType[client]] = menu.Selection;
			static char sTitle[256], sSubName[256];
			if (menu.GetItem(itemNum, sSubName, sizeof(sSubName), _, sTitle, sizeof(sTitle)))
				ShowChaptersMenu(client, sSubName, sTitle);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
				Cmd_VoteMap(client, 0);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

static void ShowChaptersMenu(int client, const char[] sSubName, const char[] sTitle)
{
	static char sMap[256], sKey[256];
	
	FormatEx(sKey, sizeof(sKey), "%s/modes/%s", sSubName, g_sMode);
	SourceKeyValues kvMissions = SDKCall(g_hSDKGetAllMissions, g_pMatchExtL4D);
	SourceKeyValues kvChapters = kvMissions.FindKey(sKey);

	if (!kvChapters.IsNull())
	{
        char sBuffer[256];
        FormatEx(sBuffer, sizeof(sBuffer), "%T", "ChooseLevel", client);
		Menu menu = new Menu(Chapters_MenuHandler);
		menu.SetTitle(sBuffer);

		for (SourceKeyValues kvSub = kvChapters.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey())
		{
			kvSub.GetString("Map", sMap, sizeof(sMap), "N/A");
			menu.AddItem(sTitle, sMap);
		}

		menu.ExitBackButton = true;
		menu.Display(client, 30);
	}
}

static int Chapters_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			static char sTitle[256], sMap[256];
			if (menu.GetItem(itemNum, sTitle, sizeof(sTitle), _, sMap, sizeof(sMap)))
				StartVoteMap(client, sTitle, sMap);
		}
		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
				ShowMapMenu(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

static void StartVoteMap(int client, const char[] sTitle, const char[] sMap)
{
	if (NativeVotes_IsVoteInProgress())
	{
		CPrintToChat(client, "%t", "VoteInProgress");
		return;
	}
	
	NativeVote vote = new NativeVote(Vote_Handler, NativeVotesType_Custom_YesNo, MenuAction_VoteStart|MenuAction_VoteCancel|MenuAction_VoteEnd|MenuAction_End|MenuAction_Display|MenuAction_Select);
	vote.SetTitle("Change map: %s (%s)", sTitle, sMap);
	vote.Initiator = client;
	vote.SetDetails(sMap);

	if (!vote.DisplayVoteToAll(20))
    {
        CPrintToChat(client, "%t", "FailedToVote");
        //LogMessage("Failed to start vote");
    }
		
}

static int Vote_Handler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}

		case MenuAction_Display:
		{
			char sDisplay[256];
			vote.GetDetails(sDisplay, sizeof(sDisplay));
			CPrintToChatAll("%t", "InitiatedVote", param1, sDisplay);
		}

		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
			}
			else
			{
				vote.DisplayFail(NativeVotesFail_Generic);
			}
		}

		case MenuAction_Select:
		{
			CPrintToChatAll("%t", "Voted", param1);
		}

		case MenuAction_VoteEnd:
		{
			if (param1 == NATIVEVOTES_VOTE_NO)
			{
				CPrintToChatAll("%t", "VoteFailed");
                vote.DisplayFail(NativeVotesFail_Loses);
			}
            else
            {
				vote.DisplayPass("Loading...");

				char sMap[256], sMissionName[256];
				vote.GetDetails(sMap, sizeof(sMap));

				if (g_smFirstMap.GetString(sMap, sMissionName, sizeof(sMissionName)))
					SDKCall(g_hSDKChangeMission, g_pTheDirector, sMissionName);
				else
					ServerCommand("changelevel %s", sMap);
            }
		}
	}

	return 0;
}