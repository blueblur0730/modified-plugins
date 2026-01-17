#if defined __match_vote_included
	#endinput
#endif
#define __match_vote_included

#define MODULE_MATCHVOTE "MatchVote"

#include <nativevotes>

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
		SetFailState("[Confogl] \"" ... MATCHMODES_PATH... "\" dose not exist.");

	g_hEnabled		   = CreateConVarEx("match_vote_enabled", "1", "Plugin enabled", _, true, 0.0, true, 1.0);
	g_hCvarPlayerLimit = CreateConVarEx("match_player_limit", "1", "Minimum # of players in game to start the vote", _, true, 1.0, true, 32.0);

	RegConsoleCmd("sm_match", MatchRequest);
	RegConsoleCmd("sm_rmatch", MatchReset);
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

	char sBuffer[64];
	kv[iClient].Rewind();
	if (kv[iClient].GotoFirstSubKey())
	{
		do
		{
			kv[iClient].GetSectionName(sBuffer, sizeof(sBuffer));
			hMenu.AddItem(sBuffer, sBuffer);
		}
		while (kv[iClient].GotoNextKey());

		if (!hMenu.ItemCount)
		{
			CPrintToChat(iClient, "%t %t", "Tag", "NoVoteItem");
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
		CPrintToChat(iClient, "%t %t", "Tag", "NoVoteItem");
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
		char sBuffer[MAX_MESSAGE_LENGTH];
		menu.GetItem(param2, sBuffer, sizeof(sBuffer));

		kv[param1].Rewind();
		if (kv[param1].JumpToKey(sBuffer) && kv[param1].GotoFirstSubKey())
		{
			char sName[256], sValue[256];
			Menu menu2 = new Menu(SlectMenuHandler);
			Format(sBuffer, sizeof(sBuffer), "%T", "VoteMenuTitle2", param1, sBuffer);
			menu2.SetTitle(sBuffer);

			do
			{
				kv[param1].GetSectionName(sName, sizeof(sName));
				kv[param1].GetString("name", sValue, sizeof(sValue));
				menu2.AddItem(sName, sValue);
			}
			while (kv[param1].GotoNextKey());

			if (!menu2.ItemCount)
			{
				CPrintToChat(param1, "%t %t", "Tag", "NoVoteItem");
				MatchModeMenu(param1);
				delete menu2;
				delete kv[param1];
			}
			else
			{
				menu2.ExitBackButton = true;
				menu2.Display(param1, 30);
			}
		}
	}
}

static void SlectMenuHandler(Menu menu, MenuAction action, int param1, int param2)
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
		if (NativeVotes_IsVoteInProgress())
		{
			CPrintToChat(param1, "%t %t", "Tag", "VoteInProgress");
			return;
		}

		int iPlayerCount	= 0;
		int iConnectedCount = 0;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (GetClientTeam(i) <= 1)
					continue;

				iPlayerCount++;
			}

			if (!IsClientInGame(i) && IsClientConnected(i))
				iConnectedCount++;
		}

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

		char sBuffer[MAX_MESSAGE_LENGTH], sDisplayBuffer[MAX_MESSAGE_LENGTH];
		menu.GetItem(param2, sBuffer, sizeof(sBuffer), _, sDisplayBuffer, sizeof(sDisplayBuffer));

		NativeVote vote = new NativeVote(LoadVoteHandler, NativeVotesType_Custom_YesNo, MenuAction_VoteStart|MenuAction_VoteCancel|MenuAction_VoteEnd|MenuAction_End|MenuAction_Display|MenuAction_Select);
		vote.SetTitle("Load game config: %s?", sDisplayBuffer);
		vote.Initiator = param1;
		vote.SetDetails(sBuffer);

		if (!vote.DisplayVoteToAll(20))
		{
			CPrintToChat(param1, "%t %t", "Tag", "VoteFailedDisPlay");
			g_hLogger.ErrorEx("[%s] Vote failed to display.", MODULE_MATCHVOTE);
		}
	}
}

static int LoadVoteHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}
	
		case MenuAction_Display:
		{
			CPrintToChatAllEx(param1, "%t %t", "Tag", "HasInitiatedVote", param1);
		}

		case MenuAction_Select:
		{
			CPrintToChatAllEx(param1, "%t", "Voted", param1);
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

		case MenuAction_VoteEnd:
		{
			if (param1 == NATIVEVOTES_VOTE_NO)
			{
				CPrintToChatAll("%t %t", "Tag", "VoteFailed");
				vote.DisplayFail(NativeVotesFail_Loses);
			}
			else
			{
				vote.DisplayPass("Executing vote...");
				CPrintToChatAll("%t %t", "Tag", "PassingVote");

				char sInfo[256], sMap[256];
				vote.GetDetails(sInfo, sizeof(sInfo));
				GetCurrentMap(sMap, sizeof(sMap));
				PrepareLoad(0, sInfo, sMap);
			}
		}
	}

	return 0;
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
	if (NativeVotes_IsVoteInProgress())
	{
		CPrintToChat(iClient, "%t", "VoteInProgress");
		return;
	}

	int iPlayerCount	= 0;
	int iConnectedCount = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) <= 1)
				continue;

			iPlayerCount++;
		}

		if (!IsClientInGame(i) && IsClientConnected(i))
			iConnectedCount++;
	}

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

	NativeVote vote = new NativeVote(ResetVoteHandler, NativeVotesType_Custom_YesNo, MenuAction_VoteStart|MenuAction_VoteCancel|MenuAction_VoteEnd|MenuAction_End|MenuAction_Display|MenuAction_Select);
	vote.SetTitle("Unload current config?");
	vote.Initiator = iClient;

	if (!vote.DisplayVoteToAll(20))
	{
		CPrintToChat(iClient, "%t %t", "Tag", "VoteFailedDisPlay");
		g_hLogger.ErrorEx("[%s] Vote failed to display.", MODULE_MATCHVOTE);
	}
}

static int ResetVoteHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}

		case MenuAction_Display:
		{
			CPrintToChatAllEx(param1, "%t %t", "Tag", "HasInitiatedVote", param1);
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
			CPrintToChatAllEx(param1, "%t %t", "Tag", "Voted", param1);
		}

		case MenuAction_VoteEnd:
		{
			if (param1 == NATIVEVOTES_VOTE_NO)
			{
				CPrintToChatAll("%t %t", "Tag", "VoteFailed");
				vote.DisplayFail(NativeVotesFail_Loses);
			}
			else
			{
				vote.DisplayPass("Unloading...");
				CPrintToChatAll("%t %t", "Tag", "VotePass_Unloading");
				RM_Match_Unload(true);
			}
		}
	}

	return 0;
}