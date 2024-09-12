#if defined __match_vote_included
	#endinput
#endif
#define __match_vote_included

static Handle
	g_hVote = null;

static KeyValues
	g_hModesKV = null;

static ConVar
	g_hEnabled		   = null,
	g_hCvarPlayerLimit = null,
	g_hMaxPlayers	   = null,
	g_hSvMaxPlayers	   = null;

static char
	g_sCfg[32];

static bool
	g_bOnSet	= false,
	g_bShutdown = false;

void MV_OnModuleStart()
{
	char sBuffer[PLATFORM_MAX_PATH];
	g_hModesKV = new KeyValues("MatchModes");
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), MATCHMODES_PATH);

	if (!g_hModesKV.ImportFromFile(sBuffer))
		SetFailState("Couldn't load matchmodes.txt!");

	g_hEnabled		   = CreateConVarEx("match_vote_enabled", "1", "Plugin enabled", _, true, 0.0, true, 1.0);
	g_hMaxPlayers	   = CreateConVarEx("mv_maxplayers", "30", "How many slots would you like the Server to be at Config Load/Unload?", _, true, 1.0, true, 32.0);
	g_hCvarPlayerLimit = CreateConVarEx("match_player_limit", "1", "Minimum # of players in game to start the vote", _, true, 1.0, true, 32.0);

	RegConsoleCmd("sm_match", MatchRequest);
	RegConsoleCmd("sm_chmatch", ChangeMatchRequest);
	RegConsoleCmd("sm_rmatch", MatchReset);

	AddCommandListener(Listener_Quit, "quit");
	AddCommandListener(Listener_Quit, "_restart");
	AddCommandListener(Listener_Quit, "crash");

	g_hSvMaxPlayers = FindConVar("sv_maxplayers");
}

void MV_OnConfigsExecuted()
{
	if (!g_bOnSet)
	{
		g_hSvMaxPlayers.SetInt(g_hMaxPlayers.IntValue);
		g_bOnSet = true;
	}
}

void MV_OnPluginEnd()
{
	if (g_bShutdown)
		return;

	delete g_hModesKV;
	g_hSvMaxPlayers.SetInt(g_hMaxPlayers.IntValue);
}

static Action Listener_Quit(int iClient, const char[] sCommand, int iArgc)
{
	g_bShutdown = true;
	return Plugin_Continue;
}

static Action MatchRequest(int iClient, int iArgs)
{
	if (!g_hEnabled.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disabled");
		return Plugin_Handled;
	}

	if (!iClient)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsole");
		return Plugin_Handled;
	}

	if (LGO_IsMatchModeLoaded())
	{
		ChangeMatchRequest(iClient, iArgs);
		// CPrintToChat(iClient, "%t %t", "Tag", "MatchLoaded");
		return Plugin_Handled;
	}

	if (iArgs > 0)
	{
		// config specified
		char sCfg[64], sName[64];
		GetCmdArg(1, sCfg, sizeof(sCfg));

		if (FindConfigName(sCfg, sName, sizeof(sName)))
		{
			if (StartMatchVote(iClient, sName))
			{
				strcopy(g_sCfg, sizeof(g_sCfg), sCfg);

				// caller is voting for
				FakeClientCommand(iClient, "Vote Yes");
			}

			return Plugin_Handled;
		}
	}

	// show main menu
	MatchModeMenu(iClient);
	return Plugin_Handled;
}

static bool FindConfigName(const char[] sConfig, char[] sName, const int iMaxLength)
{
	g_hModesKV.Rewind();

	if (g_hModesKV.GotoFirstSubKey())
	{
		do
		{
			if (g_hModesKV.JumpToKey(sConfig))
			{
				g_hModesKV.GetString("name", sName, iMaxLength);
				return true;
			}
		}
		while (g_hModesKV.GotoNextKey(false));
	}

	return false;
}

static void MatchModeMenu(int iClient)
{
	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%t", "Title_Match");

	Menu hMenu = new Menu(MatchModeMenuHandler);
	hMenu.SetTitle(sTitle);

	char sBuffer[64];
	g_hModesKV.Rewind();

	if (g_hModesKV.GotoFirstSubKey())
	{
		do
		{
			g_hModesKV.GetSectionName(sBuffer, sizeof(sBuffer));
			hMenu.AddItem(sBuffer, sBuffer);
		}
		while (g_hModesKV.GotoNextKey(false));
	}

	hMenu.Display(iClient, 20);
}

static int MatchModeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;

	else if (action == MenuAction_Select)
	{
		char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo));

		g_hModesKV.Rewind();

		if (g_hModesKV.JumpToKey(sInfo) && g_hModesKV.GotoFirstSubKey())
		{
			char sTitle[64];
			Format(sTitle, sizeof(sTitle), "%t", "Title_Config", sInfo);

			Menu hMenu = new Menu(ConfigsMenuHandler);
			hMenu.SetTitle(sTitle);

			do
			{
				g_hModesKV.GetSectionName(sInfo, sizeof(sInfo));
				g_hModesKV.GetString("name", sBuffer, sizeof(sBuffer));

				hMenu.AddItem(sInfo, sBuffer);
			}
			while (g_hModesKV.GotoNextKey());

			hMenu.Display(param1, 20);
		}
		else
		{
			CPrintToChat(param1, "%t %t", "Tag", "ConfigNotFound");
			MatchModeMenu(param1);
		}
	}

	return 0;
}

static int ConfigsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;

	else if (action == MenuAction_Cancel)
		MatchModeMenu(param1);

	else if (action == MenuAction_Select)
	{
		char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));

		if (StartMatchVote(param1, sBuffer))
		{
			strcopy(g_sCfg, sizeof(g_sCfg), sInfo);
			// caller is voting for
			FakeClientCommand(param1, "Vote Yes");
		}
		else MatchModeMenu(param1);
	}

	return 0;
}

static bool StartMatchVote(int iClient, const char[] sCfgName)
{
	if (GetClientTeam(iClient) <= TEAM_SPECTATE)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoSpec");
		return false;
	}

	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(iClient, "%t %t", "Tag", "VoteInProgress", CheckBuiltinVoteDelay());
		return false;
	}

	int[] iPlayers		= new int[MaxClients];
	int iNumPlayers		= 0;
	int iConnectedCount = ProcessPlayers(iPlayers, iNumPlayers);

	if (iConnectedCount > 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "PlayersConnecting");
		return false;
	}

	if (iNumPlayers < g_hCvarPlayerLimit.IntValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NotEnoughPlayers", iNumPlayers, g_hCvarPlayerLimit.IntValue);
		return false;
	}

	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "Title_LoadConfig", LANG_SERVER, sCfgName);

	g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, sTitle);
	SetBuiltinVoteInitiator(g_hVote, iClient);
	SetBuiltinVoteResultCallback(g_hVote, MatchVoteResultHandler);
	DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
	return true;
}

static void VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			delete vote;
			g_hVote = null;
		}
		case BuiltinVoteAction_Cancel:
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
	}
}

static void MatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				char sVotepass[64];
				Format(sVotepass, sizeof(sVotepass), "%T", "VotePass_Loading", LANG_SERVER);

				DisplayBuiltinVotePass(vote, sVotepass);
				ServerCommand("sm_forcematch %s", g_sCfg);
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

static Action MatchReset(int iClient, int iArgs)
{
	if (!g_hEnabled.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disabled");
		return Plugin_Handled;
	}

	if (!iClient)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsole");
		return Plugin_Handled;
	}

	if (!LGO_IsMatchModeLoaded())
	{
		CPrintToChat(iClient, "%t %t", "Tag", "MatchNotLoaded");
		return Plugin_Handled;
	}

	// voting for resetmatch
	StartResetMatchVote(iClient);
	return Plugin_Handled;
}

static bool StartResetMatchVote(int iClient)
{
	if (GetClientTeam(iClient) <= TEAM_SPECTATE)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoSpec");
		return false;
	}

	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(iClient, "%t %t", "Tag", "VoteInProgress", CheckBuiltinVoteDelay());
		return false;
	}

	int[] iPlayers		= new int[MaxClients];
	int iNumPlayers		= 0;
	int iConnectedCount = ProcessPlayers(iPlayers, iNumPlayers);

	if (iConnectedCount > 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "PlayersConnecting");
		return false;
	}

	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "Title_OffConfogl", LANG_SERVER);

	g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, sTitle);
	SetBuiltinVoteInitiator(g_hVote, iClient);
	SetBuiltinVoteResultCallback(g_hVote, ResetMatchVoteResultHandler);
	DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);

	FakeClientCommand(iClient, "Vote Yes");
	return true;
}

static void ResetMatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				char sVotepass[24];
				Format(sVotepass, sizeof(sVotepass), "%T", "VotePass_Unloading", LANG_SERVER);

				DisplayBuiltinVotePass(vote, sVotepass);
				ServerCommand("sm_resetmatch");
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

static Action ChangeMatchRequest(int iClient, int iArgs)
{
	if (!g_hEnabled.BoolValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disabled");
		return Plugin_Handled;
	}

	if (!iClient)
	{
		CReplyToCommand(iClient, "%t %t", "Tag", "NoConsole");
		return Plugin_Handled;
	}

	if (!LGO_IsMatchModeLoaded())
	{
		MatchRequest(iClient, iArgs);
		// CPrintToChat(iClient, "%t %t", "Tag", "MatchNotLoaded");
		return Plugin_Handled;
	}

	if (iArgs > 0)
	{
		// config specified
		char sCfg[64], sName[64];
		GetCmdArg(1, sCfg, sizeof(sCfg));
		if (FindConfigName(sCfg, sName, sizeof(sName)))
		{
			if (StartChMatchVote(iClient, sName))
			{
				strcopy(g_sCfg, sizeof(g_sCfg), sCfg);

				// caller is voting for
				FakeClientCommand(iClient, "Vote Yes");
			}
			return Plugin_Handled;
		}
	}

	// show main menu
	ChMatchModeMenu(iClient);
	return Plugin_Handled;
}

static void ChMatchModeMenu(int iClient)
{
	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%t", "Title_Match");

	Menu hMenu = new Menu(ChMatchModeMenuHandler);
	hMenu.SetTitle(sTitle);

	char sBuffer[64];
	g_hModesKV.Rewind();

	if (g_hModesKV.GotoFirstSubKey())
	{
		do
		{
			g_hModesKV.GetSectionName(sBuffer, sizeof(sBuffer));
			hMenu.AddItem(sBuffer, sBuffer);
		}
		while (g_hModesKV.GotoNextKey(false));
	}

	hMenu.Display(iClient, 20);
}

static int ChMatchModeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;

	else if (action == MenuAction_Select)
	{
		char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo));

		g_hModesKV.Rewind();

		if (g_hModesKV.JumpToKey(sInfo) && g_hModesKV.GotoFirstSubKey())
		{
			char sTitle[64];
			Format(sTitle, sizeof(sTitle), "%t", "Title_Config", sInfo);

			Menu hMenu = new Menu(ChConfigsMenuHandler);
			hMenu.SetTitle(sTitle);

			do
			{
				g_hModesKV.GetSectionName(sInfo, sizeof(sInfo));
				g_hModesKV.GetString("name", sBuffer, sizeof(sBuffer));

				hMenu.AddItem(sInfo, sBuffer);
			}
			while (g_hModesKV.GotoNextKey());

			hMenu.Display(param1, 20);
		}
		else
		{
			CPrintToChat(param1, "%t %t", "Tag", "ConfigNotFound");
			ChMatchModeMenu(param1);
		}
	}

	return 0;
}

static int ChConfigsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;

	else if (action == MenuAction_Cancel)
		ChMatchModeMenu(param1);

	else if (action == MenuAction_Select)
	{
		char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));

		if (StartChMatchVote(param1, sBuffer))
		{
			strcopy(g_sCfg, sizeof(g_sCfg), sInfo);
			// caller is voting for
			FakeClientCommand(param1, "Vote Yes");
		}
		else ChMatchModeMenu(param1);
	}

	return 0;
}

static bool StartChMatchVote(int iClient, const char[] sCfgName)
{
	if (GetClientTeam(iClient) <= TEAM_SPECTATE)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NoSpec");
		return false;
	}

	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(iClient, "%t %t", "Tag", "VoteInProgress", CheckBuiltinVoteDelay());
		return false;
	}

	int[] iPlayers		= new int[MaxClients];
	int iNumPlayers		= 0;
	int iConnectedCount = ProcessPlayers(iPlayers, iNumPlayers);

	if (iNumPlayers < g_hCvarPlayerLimit.IntValue)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "NotEnoughPlayers");
		return false;
	}

	if (iConnectedCount > 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "PlayersConnecting");
		return false;
	}

	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "Title_ChangeConfogl", LANG_SERVER, sCfgName);

	g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, sTitle);
	SetBuiltinVoteInitiator(g_hVote, iClient);
	SetBuiltinVoteResultCallback(g_hVote, ChMatchVoteResultHandler);
	DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);

	return true;
}

static void ChMatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				char sVotepass[24];
				Format(sVotepass, sizeof(sVotepass), "%T", "VotePass_Changed", LANG_SERVER);

				DisplayBuiltinVotePass(vote, sVotepass);
				ServerCommand("sm_forcechangematch %s", g_sCfg);
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}