#if defined __match_vote_included
	#endinput
#endif
#define __match_vote_included

static KeyValues
	kv[MAXPLAYERS + 1] = { null, ... };

static ConVar
	g_hEnabled		   = null,
	g_hCvarPlayerLimit = null;

static char
	g_sConfigPath[PLATFORM_MAX_PATH];

void MV_OnModuleStart()
{
	BuildPath(Path_SM, g_sConfigPath, sizeof(g_sConfigPath), MATCHMODES_PATH);

	if (!FileExists(g_sConfigPath))
		SetFailState("[Confogl] \""...MATCHMODES_PATH..."\" dose not exist.");

	g_hEnabled		   = CreateConVarEx("match_vote_enabled", "1", "Plugin enabled", _, true, 0.0, true, 1.0);
	g_hCvarPlayerLimit = CreateConVarEx("match_player_limit", "1", "Minimum # of players in game to start the vote", _, true, 1.0, true, 32.0);

	RegConsoleCmd("sm_match", MatchRequest);
	RegConsoleCmd("sm_rmatch", MatchReset);
}

void MV_OnConfigsExecuted()
{

}

void MV_OnPluginEnd()
{
	for (int i = 1; i < MaxClients; i++)
		if (kv[i]) delete kv[i];
}

static Action MatchRequest(int iClient, int iArgs)
{
	if (!g_hEnabled.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disabled");
		return Plugin_Handled;
	}

	if (GetClientTeam(iClient) <= TEAM_SPECTATE)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoSpec");
		return Plugin_Handled;
	}

	if (!iClient)
	{
		ReplyToCommand(iClient, "%t %t", "Tag", "NoConsole");
		return Plugin_Handled;
	}

	if (RM_bIsMatchModeLoaded)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "MatchLoaded");
		return Plugin_Handled;
	}

	// show main menu
	MatchModeMenu(iClient);
	return Plugin_Handled;
}

static void MatchModeMenu(int iClient)
{
	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "Title_Match", iClient);
	Menu hMenu = new Menu(MatchModeMenuHandler);
	hMenu.SetTitle(sTitle);

    if (!kv[iClient])
    {
        kv[iClient] = new KeyValues("");
        kv[iClient].ImportFromFile(g_sConfigPath);
    }

	kv[iClient].Rewind();
	if (kv[iClient].GotoFirstSubKey(false))
	{
		do
		{
			TraverseKeys(hMenu, iClient);
		}
		while (kv[iClient].GotoNextKey(false));

		if (!hMenu.ItemCount)
        {
            CPrintToChat(iClient, "%t", "NoVoteItem");
            delete hMenu;
            delete kv[iClient];
            return;
        }
        else
        {
            hMenu.Display(iClient, 30);
        }
	}
	else
	{
        CPrintToChat(iClient, "%t", "NoVoteItem");
        delete hMenu;
        delete kv[iClient];
        return;
	}
}

static void MatchModeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;

	if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack)
            MatchModeMenu(param1);
    }

	if (action == MenuAction_Select)
	{
        char sBuffer[MAX_MESSAGE_LENGTH], sDisplayBuffer[MAX_MESSAGE_LENGTH];
        menu.GetItem(param2, sBuffer, sizeof(sBuffer), _, sDisplayBuffer, sizeof(sDisplayBuffer));

		if (kv[param1].JumpToKey(sBuffer))
		{
			kv[param1].SavePosition();
            if (kv[param1].GotoFirstSubKey(false))
            {
                Menu menu2 = new Menu(MatchModeMenuHandler);
                Format(sBuffer, sizeof(sBuffer), "%T", "VoteMenuTitle2", param1, sDisplayBuffer);
                menu2.SetTitle(sBuffer);

                do
                {
                    TraverseKeys(menu2, param1);
                }
                while (kv[param1].GotoNextKey(false));
                kv[param1].GoBack();

                if (!menu2.ItemCount)
                {
                    CPrintToChat(param1, "%t", "NoVoteItem");
                    MatchModeMenu(param1);
                    delete menu2;
                }
                else
                {
                    menu2.ExitBackButton = true;
                    menu2.Display(param1, 30);
                }
            }
		}
		else
		{
            if (!L4D2NativeVote_IsAllowNewVote())
            {
                CPrintToChat(param1, "%t", "VoteInProgress");
                return;
            }

            int iPlayerCount = 0;
	        int[] iClients = new int[MaxClients];
			int iConnectedCount = ProcessPlayers(iClients, iPlayerCount);

			if (iConnectedCount > 0)
			{
				CPrintToChat(param1, "%t %t", "Tag", "PlayersConnecting");
				return;
			}

			if (iPlayerCount < g_hCvarPlayerLimit.IntValue)
			{
				CPrintToChat(param1, "%t %t", "Tag", "NotEnoughPlayers", iPlayerCount, g_hCvarPlayerLimit.IntValue);
				return;
			}

	        for (int i = 1; i <= MaxClients; i++)
	        {
		        if (IsClientInGame(i) && !IsFakeClient(i))
		        {
			        if (GetClientTeam(i) == L4D2Team_Spectator)
				         continue;

			        iClients[iPlayerCount++] = i;
		        }
	        }

		    L4D2NativeVote vote = L4D2NativeVote(LoadVoteHandler);
            vote.SetTitle("加载 %s?", sDisplayBuffer);
            vote.Initiator = param1;
            vote.SetInfo(sBuffer);

            if (!vote.DisplayVote(iClients, iPlayerCount, 20))
            {
                CPrintToChat(param1, "%t", "VoteFailedDisPlay");
                LogError("[Confogl] Vote failed to display.");
            } 
		}
	}
}

static void LoadVoteHandler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
    switch (action)
    {
		case VoteAction_Start:
			CPrintToChatAllEx(param1, "%t", "HasInitiatedVote", param1);

		case VoteAction_PlayerVoted:
		{
			CPrintToChatAllEx(param1, "%t", "Voted", param1);

			switch (param2)
			{
				case VOTE_YES: vote.YesCount++;
				case VOTE_NO: vote.NoCount++;
			}
		}

		case VoteAction_End:
		{
			if (vote.YesCount >= vote.PlayerCount / 2)
			{
				vote.SetPass("正在执行...");
                CPrintToChatAll("%t", "PassingVote");

				char sInfo[256];
				vote.GetInfo(sInfo, sizeof(sInfo));
				PrepareLoad(0, sInfo, "");
			}
			else
            {
                CPrintToChatAll("%t", "VoteFailed");
                vote.SetFail();
            }
		}
    }
}

static Action MatchReset(int iClient, int iArgs)
{
	if (!g_hEnabled.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disabled");
		return Plugin_Handled;
	}

	if (GetClientTeam(iClient) <= TEAM_SPECTATE)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoSpec");
		return Plugin_Handled;
	}

	if (!iClient)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsole");
		return Plugin_Handled;
	}

	if (!RM_bIsMatchModeLoaded)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "MatchNotLoaded");
		return Plugin_Handled;
	}

	// voting for resetmatch
	StartResetMatchVote(iClient);
	return Plugin_Handled;
}

static void StartResetMatchVote(int iClient)
{
    if (!L4D2NativeVote_IsAllowNewVote())
    {
        CPrintToChat(iClient, "%t", "VoteInProgress");
        return;
    }

    int iPlayerCount = 0;
	int[] iClients = new int[MaxClients];
	int iConnectedCount = ProcessPlayers(iClients, iPlayerCount);

	if (iConnectedCount > 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "PlayersConnecting");
		return;
	}

	if (iPlayerCount < g_hCvarPlayerLimit.IntValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NotEnoughPlayers", iPlayerCount, g_hCvarPlayerLimit.IntValue);
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == L4D2Team_Spectator)
				    continue;

			iClients[iPlayerCount++] = i;
		}
	}

	L4D2NativeVote vote = L4D2NativeVote(ResetVoteHandler);
    vote.SetTitle("卸载当前配置?");
    vote.Initiator = iClient;

    if (!vote.DisplayVote(iClients, iPlayerCount, 20))
    {
        CPrintToChat(iClient, "%t", "VoteFailedDisPlay");
        LogError("[Confogl] Vote failed to display.");
    } 
}

static void ResetVoteHandler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
    switch (action)
    {
		case VoteAction_Start:
			CPrintToChatAllEx(param1, "%t", "HasInitiatedVote", param1);

		case VoteAction_PlayerVoted:
		{
			CPrintToChatAllEx(param1, "%t", "Voted", param1);

			switch (param2)
			{
				case VOTE_YES: vote.YesCount++;
				case VOTE_NO: vote.NoCount++;
			}
		}

		case VoteAction_End:
		{
			if (vote.YesCount >= vote.PlayerCount / 2)
			{
				vote.SetPass("正在卸载...");
                CPrintToChatAll("%t", "VotePass_Unloading");
				RM_Match_Unload(true);
			}
			else
            {
                CPrintToChatAll("%t", "VoteFailed");
                vote.SetFail();
            }
		}
    }
}

static void TraverseKeys(Menu menu, int client)
{
    static char sBuffer[MAX_MESSAGE_LENGTH], sKeyValue[MAX_MESSAGE_LENGTH]; //sTranslated[MAX_MESSAGE_LENGTH];
	if (kv[client].GetSectionName(sBuffer, sizeof(sBuffer)))
    {
        kv[client].GetString(NULL_STRING, sKeyValue, sizeof(sKeyValue), "NoKeyValue");

        //Format(sTranslated, sizeof(sTranslated), "%T", client, sBuffer);
        if (StrEqual(sKeyValue, "NoKeyValue"))
            menu.AddItem(sBuffer, sBuffer);
        else
            menu.AddItem(sKeyValue, sBuffer);
    }
}