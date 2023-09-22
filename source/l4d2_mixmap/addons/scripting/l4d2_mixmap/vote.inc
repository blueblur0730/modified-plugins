#if defined _l4d2_mixmap_vote_included
 #endinput
#endif
#define _l4d2_mixmap_vote_included

void CreateMixmapVote(int client)
{
	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientAndInGame(i) || (GetClientTeam(i) == 1))
			continue;

		iPlayers[iNumPlayers++] = i;
	}

	char cVoteTitle[32];
	Format(cVoteTitle, sizeof(cVoteTitle), "%T", "Cvote_Title", LANG_SERVER, cfg_exec);

	g_hVoteMixmap = CreateBuiltinVote(VoteMixmapActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

	SetBuiltinVoteArgument(g_hVoteMixmap, cVoteTitle);
	SetBuiltinVoteInitiator(g_hVoteMixmap, client);
	SetBuiltinVoteResultCallback(g_hVoteMixmap, VoteMixmapResultHandler);
	DisplayBuiltinVote(g_hVoteMixmap, iPlayers, iNumPlayers, 20);

	CPrintToChatAllEx(client, "%t", "Start_Mixmap", client, cfg_exec);
	FakeClientCommand(client, "Vote Yes");
}

void CreateStopMixmapVote(int client)
{
	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientAndInGame(i) || (GetClientTeam(i) == 1))
			continue;

		iPlayers[iNumPlayers++] = i;
	}

	char cVoteTitle[32];
	Format(cVoteTitle, sizeof(cVoteTitle), "%T", "Cvote_Title_Off", LANG_SERVER);

	g_hVoteStopMixmap = CreateBuiltinVote(VoteStopMixmapActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

	SetBuiltinVoteArgument(g_hVoteStopMixmap, cVoteTitle);
	SetBuiltinVoteInitiator(g_hVoteStopMixmap, client);
	SetBuiltinVoteResultCallback(g_hVoteStopMixmap, VoteStopMixmapResultHandler);
	DisplayBuiltinVote(g_hVoteStopMixmap, iPlayers, iNumPlayers, 20);

	CPrintToChatAllEx(client, "%t", "Vote_Stop", client);
	FakeClientCommand(client, "Vote Yes");
}

void VoteMixmapActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_hVoteMixmap = null;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
			/* 		case BuiltinVoteAction_Select:
					{
						char cItemVal[64];
						char cItemName[64];
						GetBuiltinVoteItem(vote, param2, cItemVal, sizeof(cItemVal), cItemName, sizeof(cItemName));
					} */
	}
}

void VoteMixmapResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
				if (vote == g_hVoteMixmap)
				{
					char cExecTitle[32];
					Format(cExecTitle, sizeof(cExecTitle), "%T", "Cexec_Title", LANG_SERVER);
					DisplayBuiltinVotePass(vote, cExecTitle);
					if (g_hCountDownTimer)
					{
						// interrupt any upcoming transitions
						KillTimer(g_hCountDownTimer);
					}
					PluginStartInit();
					CreateTimer(3.0, StartVoteMixmap_Timer);
					return;
				}
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

void VoteStopMixmapActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_hVoteStopMixmap = null;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
			/* 		case BuiltinVoteAction_Select:
					{
						char cItemVal[64];
						char cItemName[64];
						GetBuiltinVoteItem(vote, param2, cItemVal, sizeof(cItemVal), cItemName, sizeof(cItemName));
					} */
	}
}

void VoteStopMixmapResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
				if (vote == g_hVoteStopMixmap)
				{
					DisplayBuiltinVotePass(vote, "stop Mixmap……");
					CreateTimer(1.0, StartVoteStopMixmap_Timer);
					return;
				}
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

Action StartVoteMixmap_Timer(Handle timer)
{
	Mixmap();

	return Plugin_Handled;
}

// Load a mixmap cfg
Action Mixmap()
{
	if (!L4D2_IsScavengeMode() && !L4D_IsSurvivalMode())
		ServerCommand("exec %s%s.cfg", DIR_CFGS, cfg_exec);
	else if (L4D2_IsScavengeMode())
		ServerCommand("exec %s%s.cfg", DIR_CFGS_SCAV, cfg_exec);

	g_bMapsetInitialized = true;
	CreateTimer(0.1, Timed_PostMapSet);

	return Plugin_Handled;
}

Action StartVoteStopMixmap_Timer(Handle timer)
{
	if (g_hCountDownTimer)
	{
		// interrupt any upcoming transitions
		KillTimer(g_hCountDownTimer);
	}
	PluginStartInit();

	CPrintToChatAll("%t", "Stop_Mixmap");
	return Plugin_Handled;
}

// ----------------------------------------------------------
// 		Map set picking
// ----------------------------------------------------------

// creates the initial map list after a map set has been loaded
public Action Timed_PostMapSet(Handle timer)
{
	int mapnum	 = g_hArrayTagOrder.Length;
	int triesize = g_hTriePools.Size;

	if (mapnum == 0)
	{
		g_bMapsetInitialized = false;	 // failed to load it on the exec
		CPrintToChatAll("%t", "Fail_Load_Preset");
		return Plugin_Handled;
	}

	if (g_iMapCount < triesize)
	{
		g_bMapsetInitialized = false;	 // bad preset format
		CPrintToChatAll("%t", "Maps_Not_Match_Rank");
		return Plugin_Handled;
	}

	CPrintToChatAll("%t", "Select_Maps_Succeed");

	SelectRandomMap();
	return Plugin_Handled;
}