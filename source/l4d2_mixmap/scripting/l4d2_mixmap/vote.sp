#if defined _l4d2_mixmap_vote_included
 #endinput
#endif
#define _l4d2_mixmap_vote_included

void CreateMixmapVote(int client, MapSetType type)
{
	if (!L4D2NativeVote_IsAllowNewVote())
	{
		CPrintToChat(client, "%t", "VoteInProgress");
		return;
	}

	char sInfo[8];
	L4D2NativeVote vote = L4D2NativeVote(CreateMixMapVoteHandler);
	vote.SetTitle("Start Mixmap Vote?");
	IntToString(view_as<int>(type), sInfo, sizeof(sInfo));
	vote.SetInfo(sInfo);
	vote.Initiator = client;

	int iPlayerCount = 0;
	int[] iClients	 = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 1)
				continue;

			iClients[iPlayerCount++] = i;
		}
	}

	if (!vote.DisplayVote(iClients, iPlayerCount, 20))
		CPrintToChat(client, "%t", "FailedToDisplayVote");
}

void CreateMixMapVoteHandler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
	switch (action)
	{
		case VoteAction_Start:
			CPrintToChatAllEx(param1, "%t", "HasInitiated", param1);

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
			if (vote.YesCount > vote.PlayerCount / 2)
			{
				char sInfo[8];
				vote.GetInfo(sInfo, sizeof(sInfo));
				vote.SetPass("Pass vote.")
				MapSetType type = view_as<MapSetType>(StringToInt(sInfo));
				InitiateMixmap(type);
			}
			else
			{
				vote.SetFail();
			}
		}
	}
}

void CreateStopMixmapVote(int client)
{
	if (!L4D2NativeVote_IsAllowNewVote())
	{
		CPrintToChat(client, "%t", "VoteInProgress");
		return;
	}

	L4D2NativeVote vote = L4D2NativeVote(CreateStopMixMapVoteHandler);
	vote.SetTitle("Stop Mixmap?");
	vote.Initiator = client;

	int iPlayerCount = 0;
	int[] iClients	 = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == 1)
				continue;

			iClients[iPlayerCount++] = i;
		}
	}

	if (!vote.DisplayVote(iClients, iPlayerCount, 20))
		CPrintToChat(client, "%t", "FailedToDisplayVote");
}

void CreateStopMixMapVoteHandler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
	switch (action)
	{
		case VoteAction_Start:
			CPrintToChatAllEx(param1, "%t", "HasInitiated", param1);

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
			if (vote.YesCount > vote.PlayerCount / 2)
			{
				vote.SetPass("Pass vote.")
				PluginStartInit();
			}
			else
			{
				vote.SetFail();
			}
		}
	}
}