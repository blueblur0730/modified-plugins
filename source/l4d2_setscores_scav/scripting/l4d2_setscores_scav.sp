#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <builtinvotes>
#include <colors>

#define L4D_TEAM_SPECTATE 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3

bool
	b_inFirstReadyUpOfRound;

int
	g_rounds,
	g_team,
	g_roundscores,
	g_matchscores,
	g_goal;

Handle
	g_voteHandler_round,
	g_voteHandler_teamscores,
	g_voteHandler_matchscores,
	g_voteHandler_goal;

ConVar
	g_minimumPlayersForVote,
	g_allowPlayersToVote,
	g_forceAdminsToVote;

public Plugin myinfo =
{
	name		= "[L4D2] Set Scores Scavenge",
	author		= "blueblur, inspired by plugin 'l4d2_setscores'",
	description = "Provide votes and commanders to set scavenge scores, round numbers and total goal.",
	version		= "1.0",
	url			= "https://github.com/blueblur0730/modified-plugins"

}

public void OnPluginStart()
{
	CheckGame();

	g_minimumPlayersForVote = CreateConVar("l4d2_setscore_scav_player_limit", "2", "Minimum # of players in game to start the vote");
	g_allowPlayersToVote	= CreateConVar("l4d2_setscore_scav_allow_player_vote", "1", "Whether player initiated votes are allowed, 1 to allow (default), 0 to disallow.");
	g_forceAdminsToVote		= CreateConVar("l4d2_setscore_scav_force_admin_vote", "0", "Whether admin score changes require a vote, 1 vote required, 0 vote not required (default).");

	RegConsoleCmd("sm_setrounds", Cmd_SetRounds);
	RegConsoleCmd("sm_setroundscores", Cmd_SetRoundScores);
	RegConsoleCmd("sm_setmatchscores", Cmd_SetMatchScores);
	RegConsoleCmd("sm_setgaol", Cmd_SetGoal);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	LoadTranslations("l4d2_setscores_scav.phrases");
}

void CheckGame()
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		SetFailState("Plugin 'SetScores' supports Left 4 Dead 2 only!");
	}
}

/***************************
 *
 *   Events and Forwards
 *
 ***************************/

// Disables score changes once round goes live
public void OnRoundIsLive()
{
	b_inFirstReadyUpOfRound = false;
}

// Enables scores changes when round is started
public void Event_RoundStart(Event hEvent, const char[] eName, bool dontBroadcast)
{
	b_inFirstReadyUpOfRound = true;
}

/******************
 *
 *   Commanders
 *
 ******************/

Action Cmd_SetRounds(int client, int args)
{
	// Only allow during the first ready up of the round
	if (!b_inFirstReadyUpOfRound)
	{
		ReplyToCommand(client, "%t", "ReadyupStatusRequired");
		// Scores can only be changed during readyup before the round starts.
		return Plugin_Handled;
	}

	char iargs[64];
	int	 rounds;
	if (args != 1)
	{
		ReplyToCommand(client, "%t", "Usage1");	   //[SM] Usage: sm_setrounds <num>
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, iargs, sizeof(iargs));
		if (StringToInt(iargs) > 5 || StringToInt(iargs) < 1)
		{
			ReplyToCommand(client, "%t", "OutOfBounds1");	 // [SM]: Round number can only be the zone [1, 5]
			return Plugin_Handled;
		}
		rounds = StringToInt(iargs);
	}

	bool IsAdmin = false;

	// Determine whether the user is admin and what action to take
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		// If we are forcing admins to start votes, start a vote
		if (!g_forceAdminsToVote.BoolValue)
		{
			SetRounds(rounds, client);
			return Plugin_Handled;
		}

		IsAdmin = true;	   // else, ignore setscore_allow_player_vote convar for admins
	}

	if (IsAdmin || g_allowPlayersToVote.BoolValue)
	{
		// If players are allowed to vote, start a vote
		StartRoundVote(rounds, client, IsAdmin);
	}

	return Plugin_Handled;
}

Action Cmd_SetRoundScores(int client, int args)
{
	if (!b_inFirstReadyUpOfRound)
	{
		ReplyToCommand(client, "%t", "ReadyupStatusRequired");
		return Plugin_Handled;
	}

	char iargs[64], jargs[64], kargs[64];
	int	 rounds, teamindex, scores;
	if (args != 3)
	{
		ReplyToCommand(client, "%t", "Usage2");	   //[SM] Usage: sm_setroundscores <team> <round num> <score>
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, iargs, sizeof(iargs));
		GetCmdArg(2, jargs, sizeof(jargs));
		GetCmdArg(3, kargs, sizeof(kargs));
		if (StringToInt(iargs) > 3 || StringToInt(jargs) < 2)
		{
			ReplyToCommand(client, "%t", "OutOfBounds2");	 // [SM]: team index can only be 2 (survivors) or 3 (infected)
			return Plugin_Handled;
		}

		if (StringToInt(jargs) > 5 || StringToInt(jargs) < 1)
		{
			ReplyToCommand(client, "%t", "OutOfBounds1");	 // [SM]: Round number can only be the zone [1, 5]
			return Plugin_Handled;
		}

		teamindex = StringToInt(iargs);
		rounds	  = StringToInt(jargs);
		scores	  = StringToInt(kargs);
	}

	bool IsAdmin = false;

	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		if (!g_forceAdminsToVote.BoolValue)
		{
			SetTeamScores(rounds, teamindex, scores, client);
			return Plugin_Handled;
		}

		IsAdmin = true;
	}

	if (IsAdmin || g_allowPlayersToVote.BoolValue)
	{
		StartTeamScoreVote(rounds, teamindex, scores, client, IsAdmin);
	}

	return Plugin_Handled;
}

Action Cmd_SetMatchScores(int client, int args)
{
	if (!b_inFirstReadyUpOfRound)
	{
		ReplyToCommand(client, "%t", "ReadyupStatusRequired");
		return Plugin_Handled;
	}

	char iargs[64], jargs[64];
	int	 teamindex, scores;
	if (args != 2)
	{
		ReplyToCommand(client, "%t", "Usage3");	   //[SM] Usage: sm_setmatchscores <team> <score>
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, iargs, sizeof(iargs));
		GetCmdArg(2, jargs, sizeof(jargs));
		if (StringToInt(iargs) > 3 || StringToInt(iargs) < 2)
		{
			ReplyToCommand(client, "%t", "OutOfBounds2");	 // [SM]: team index can only be 2 (survivors) or 3 (infected)
			return Plugin_Handled;
		}

		teamindex = StringToInt(iargs);
		scores	  = StringToInt(jargs);
	}

	bool IsAdmin = false;

	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		if (!g_forceAdminsToVote.BoolValue)
		{
			SetMatchScores(teamindex, scores, client);
			return Plugin_Handled;
		}

		IsAdmin = true;
	}

	if (IsAdmin || g_allowPlayersToVote.BoolValue)
	{
		StartMatchScoreVote(teamindex, scores, client, IsAdmin);
	}

	return Plugin_Handled;
}

Action Cmd_SetGoal(int client, int args)
{
	if (!b_inFirstReadyUpOfRound)
	{
		ReplyToCommand(client, "%t", "ReadyupStatusRequired");
		return Plugin_Handled;
	}

	char iargs[64];
	int	 goals;
	if (args != 1)
	{
		ReplyToCommand(client, "%t", "Usage4");	   //[SM] Usage: sm_setgoal <goal>
	}
	else
	{
		GetCmdArg(1, iargs, sizeof(iargs));
		goals = StringToInt(iargs);
	}

	bool IsAdmin = false;

	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		if (!g_forceAdminsToVote.BoolValue)
		{
			SetGoal(goals, client);
			return Plugin_Handled;
		}

		IsAdmin = true;
	}

	if (IsAdmin || g_allowPlayersToVote.BoolValue)
	{
		StartGoalVote(goals, client, IsAdmin);
	}

	return Plugin_Handled;
}

/*********************
 *
 *   Start to Vote
 *
 *********************/

// Starts a vote to change rounds
void StartRoundVote(int round, const int initiator, bool IsAdmin)
{
	// Disallow spectator voting
	if (!IsAdmin && GetClientTeam(initiator) == L4D_TEAM_SPECTATE)
	{
		CPrintToChat(initiator, "%t", "NoSpec");
		// Score voting isn't allowed for spectators.
		return;
	}

	if (IsNewBuiltinVoteAllowed())
	{
		// Determine the number of voting players (non-spectator) and store their client ids
		int iNumPlayers;
		int[] iPlayers = new int[MaxClients];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
				continue;

			iPlayers[iNumPlayers++] = i;
		}

		// If there aren't enough players for the vote indicate so to the user
		if (iNumPlayers < g_minimumPlayersForVote.IntValue)
		{
			CPrintToChat(initiator, "%t", "EnoughPlayersRequired");
			return;
		}

		g_rounds			= round;

		// Create the vote
		g_voteHandler_round = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

		// Set the text for the vote, initiating client and handler
		char sBuffer[256];
		Format(sBuffer, sizeof(sBuffer), "%t", "ChangeRound", GetScavengeRoundNumber(), round);
		// Change round from %d to %d?
		// 设置局数由 %d 变为 %d?
		SetBuiltinVoteArgument(g_voteHandler_round, sBuffer);
		SetBuiltinVoteInitiator(g_voteHandler_round, initiator);
		SetBuiltinVoteResultCallback(g_voteHandler_round, VoteResultHandler);

		// Display the vote and make the initiator automatically vote yes
		DisplayBuiltinVote(g_voteHandler_round, iPlayers, iNumPlayers, 20);
		FakeClientCommand(initiator, "Vote Yes");
		return;
	}

	CPrintToChat(initiator, "%t", "CannotVoteNow");
	// Score vote cannot be started now.
}

void StartTeamScoreVote(int round, int team, int score, const int initiator, bool IsAdmin)
{
	if (!IsAdmin && GetClientTeam(initiator) == L4D_TEAM_SPECTATE)
	{
		CPrintToChat(initiator, "%t", "NoSpec");
		return;
	}

	if (IsNewBuiltinVoteAllowed())
	{
		int iNumPlayers;
		int[] iPlayers = new int[MaxClients];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
				continue;

			iPlayers[iNumPlayers++] = i;
		}

		if (iNumPlayers < g_minimumPlayersForVote.IntValue)
		{
			CPrintToChat(initiator, "%t", "EnoughPlayersRequired");
			return;
		}

		g_rounds				 = round;
		g_team					 = team;
		g_roundscores			 = score;

		g_voteHandler_teamscores = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

		char sBuffer[512];
		Format(sBuffer, sizeof(sBuffer), "%t", "ChangeTeamScore", team, GetScavengeTeamScore(team, round), score, round);
		// Change team%d's round score from %d to %d on round %d?
		// 将队伍%d在第%d局的小局分数从%d 设置为 %d?
		SetBuiltinVoteArgument(g_voteHandler_teamscores, sBuffer);
		SetBuiltinVoteInitiator(g_voteHandler_teamscores, initiator);
		SetBuiltinVoteResultCallback(g_voteHandler_teamscores, VoteResultHandler);
		DisplayBuiltinVote(g_voteHandler_teamscores, iPlayers, iNumPlayers, 20);
		FakeClientCommand(initiator, "Vote Yes");
		return;
	}

	CPrintToChat(initiator, "%t", "CannotVoteNow");
}

void StartMatchScoreVote(int team, int score, const int initiator, bool IsAdmin)
{
	if (!IsAdmin && GetClientTeam(initiator) == L4D_TEAM_SPECTATE)
	{
		CPrintToChat(initiator, "%t", "NoSpec");
		return;
	}

	if (IsNewBuiltinVoteAllowed())
	{
		int iNumPlayers;
		int[] iPlayers = new int[MaxClients];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
				continue;

			iPlayers[iNumPlayers++] = i;
		}

		if (iNumPlayers < g_minimumPlayersForVote.IntValue)
		{
			CPrintToChat(initiator, "%t", "EnoughPlayersRequired");
			return;
		}

		g_team					  = team;
		g_matchscores			  = score;

		g_voteHandler_matchscores = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

		char sBuffer[256];
		Format(sBuffer, sizeof(sBuffer), "%t", "ChangeMatchScore", team, GetScavengeMatchScore(team), score);
		// Change team%d's match score from %d to %d?
		// 将队伍%d的比赛分数从%d 设置为 %d?
		SetBuiltinVoteArgument(g_voteHandler_matchscores, sBuffer);
		SetBuiltinVoteInitiator(g_voteHandler_matchscores, initiator);
		SetBuiltinVoteResultCallback(g_voteHandler_matchscores, VoteResultHandler);
		DisplayBuiltinVote(g_voteHandler_matchscores, iPlayers, iNumPlayers, 20);
		FakeClientCommand(initiator, "Vote Yes");
		return;
	}

	CPrintToChat(initiator, "%t", "CannotVoteNow");
}

void StartGoalVote(int goal, const int initiator, bool IsAdmin)
{
	if (!IsAdmin && GetClientTeam(initiator) == L4D_TEAM_SPECTATE)
	{
		CPrintToChat(initiator, "%t", "NoSpec");
		return;
	}

	if (IsNewBuiltinVoteAllowed())
	{
		int iNumPlayers;
		int[] iPlayers = new int[MaxClients];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D_TEAM_SPECTATE))
				continue;

			iPlayers[iNumPlayers++] = i;
		}

		if (iNumPlayers < g_minimumPlayersForVote.IntValue)
		{
			CPrintToChat(initiator, "%t", "EnoughPlayersRequired");
			return;
		}

		g_goal			   = goal;

		g_voteHandler_goal = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

		char sBuffer[256];
		Format(sBuffer, sizeof(sBuffer), "%t", "ChangeGoal", GetScavengeItemsGoal(), goal);
		// Change gascan goal from %d to %d?
		// 将油桶目标数从%d 设置为 %d?
		SetBuiltinVoteArgument(g_voteHandler_goal, sBuffer);
		SetBuiltinVoteInitiator(g_voteHandler_goal, initiator);
		SetBuiltinVoteResultCallback(g_voteHandler_goal, VoteResultHandler);
		DisplayBuiltinVote(g_voteHandler_goal, iPlayers, iNumPlayers, 20);
		FakeClientCommand(initiator, "Vote Yes");
		return;
	}

	CPrintToChat(initiator, "%t", "CannotVoteNow");
}

// Handler for the vote
public void VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			vote = null;
			delete vote;
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Generic);
		}
	}
}

// Handles a score vote's results, if a majority voted for the score change then set the scores
public void VoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
				if (g_voteHandler_round == vote)
				{
					char ChangingRound[256];
					Format(ChangingRound, sizeof(ChangingRound), "%t", "ChangingRound");
					DisplayBuiltinVotePass(vote, ChangingRound);
					SetRounds(g_rounds, -1);
					return;
				}

				if (g_voteHandler_teamscores == vote)
				{
					char ChangingTeamScores[256];
					Format(ChangingTeamScores, sizeof(ChangingTeamScores), "%t", "ChangingTeamScores");
					DisplayBuiltinVotePass(vote, ChangingTeamScores);
					SetTeamScores(g_rounds, g_team, g_roundscores, -1);
					return;
				}

				if (g_voteHandler_matchscores == vote)
				{
					char ChangingMatchScores[256];
					Format(ChangingMatchScores, sizeof(ChangingMatchScores), "%t", "ChangingMatchScores");
					DisplayBuiltinVotePass(vote, ChangingMatchScores);
					SetMatchScores(g_team, g_matchscores, -1);
					return;
				}

				if (g_voteHandler_goal == vote)
				{
					char ChangingGoal[256];
					Format(ChangingGoal, sizeof(ChangingGoal), "%t", "ChangingGoal");
					DisplayBuiltinVotePass(vote, ChangingGoal);
					SetGoal(g_goal, -1);
					return;
				}
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

/******************
 *
 *   Set Info
 *
 ******************/

void SetRounds(int round, const int iAdminIndex)
{
	int old_round = GetScavengeRoundNumber();
	SetScavengeRoundNumber(round);

	if (iAdminIndex != -1)	  // This works well for an index '0' as well, if the initiator is CONSOLE
	{
		char client_name[32];
		GetClientName(iAdminIndex, client_name, sizeof(client_name));
		CPrintToChatAll("%t", "WhoSetRound", client_name, old_round, round);
		// %s has changed round number from %d to %d
		// %s 已将局数从%d 设置为 %d
	}
	else
	{
		CPrintToChatAll("%t", "VoteSetRound", round);
		// round number has been set from %d to %d
		// 局数已由投票从%d 设置为 %d
	}

	g_rounds = 0;
}

void SetTeamScores(int round, int team, int score, const int iAdminIndex)
{
	int old_score = GetScavengeTeamScore(team, round);
	SetScavengeTeamScore(team, round, score);

	if (iAdminIndex != -1)
	{
		char client_name[32];
		GetClientName(iAdminIndex, client_name, sizeof(client_name));
		switch (team)
		{
			case L4D_TEAM_SURVIVOR:
			{
				CPrintToChatAll("%t", "WhoSetTeamScoresSurvivor", client_name, round, old_score, score);
				// %s has changed survivors' round score on round %d from %d to %d
				// %s 已将生还者在第 %d 局的小局分数从%d 设置为 %d
			}

			case L4D_TEAM_INFECTED:
			{
				CPrintToChatAll("%t", "WhoSetTeamScoresInfected", client_name, round, old_score, score);
				// %s has changed infected's round score on round %d from %d to %d
				// %s 已将感染者在第 %d 局的小局分数从%d 设置为 %d
			}
		}
	}
	else
	{
		switch (team)
		{
			case L4D_TEAM_SURVIVOR:
			{
				CPrintToChatAll("%t", "VoteSetTeamScoresSurvivor", round, old_score, score);
				// survivors' round score on round %d has been changed from %d to %d by vote
				// 生还者在第 %d 局的小局分数已由投票从%d 设置为 %d
			}

			case L4D_TEAM_INFECTED:
			{
				CPrintToChatAll("%t", "VoteSetTeamScoresInfected", round, old_score, score);
				// infected's round score on round %d has been changed from %d to %d by vote
				// 感染者在第 %d 局的小局分数已由投票从%d 设置为 %d
			}
		}
	}

	g_rounds	  = 0;
	g_team		  = 0;
	g_roundscores = 0;
}

void SetMatchScores(int team, int score, const int iAdminIndex)
{
	int old_score = GetScavengeMatchScore(team);
	SetScavengeMatchScore(team, score);

	if (iAdminIndex != -1)
	{
		char client_name[32];
		GetClientName(iAdminIndex, client_name, sizeof(client_name));
		switch (team)
		{
			case L4D_TEAM_SURVIVOR:
			{
				CPrintToChatAll("%t", "WhoSetMatchScoresSurvivor", client_name, old_score, score);
				// %s has changed survivors' match score from %d to %d
				// %s 已将生还者的比赛得分从 %d 设置为 %d
			}

			case L4D_TEAM_INFECTED:
			{
				CPrintToChatAll("%t", "WhoSetMatchScoresInfected", client_name, old_score, score);
				// %s has changed infected's match score from %d to %d
				// %s 已将感染者的比赛得分从%d 设置为 %d
			}
		}
	}
	else
	{
		switch (team)
		{
			case L4D_TEAM_SURVIVOR:
			{
				CPrintToChatAll("%t", "VoteSetMatchScoresSurvivor", old_score, score);
				// survivors' match score has been changed from %d to %d by vote
				// 生还者的比赛得分已由投票从%d 设置为 %d
			}

			case L4D_TEAM_INFECTED:
			{
				CPrintToChatAll("%t", "VoteSetMatchScoresInfected", old_score, score);
				// infected's match score has been changed from %d to %d by vote
				// 感染者的比赛得分已由投票从%d 设置为 %d
			}
		}
	}

	g_team		  = 0;
	g_matchscores = 0;
}

void SetGoal(int goal, const int iAdminIndex)
{
	int old_goal = GetScavengeItemsGoal();
	SetScavengeItemsGoal(goal);

	if (iAdminIndex != -1)
	{
		char client_name[32];
		GetClientName(iAdminIndex, client_name, sizeof(client_name));
		CPrintToChatAll("%t", "WhoSetGoal", client_name, old_goal, goal);
		// %s has changed gascan goal from %d to %d
		// %s 已将油桶目标数从 %d 设置为 %d
	}
	else
	{
		CPrintToChatAll("%t", "VoteSetGoal", old_goal, goal);
		// gascan goal has been changed from %d to %d by vote
		// 油桶目标数已由投票从%d 设置为 %d
	}

	g_goal = 0;
}