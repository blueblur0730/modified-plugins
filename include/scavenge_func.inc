/*
	Scavenge Functions
	- A useful collection of functions related to L4D2 Scavenge
	- Collected and authorized by blueblur
*/

#if defined _scavenge_func_included
	#endinput
#endif
#define _scavenge_func_included

#include <sourcemod>
#include <sdktools>

/*
 * Returns if the current gamemode is scavenge.
 *
 * @return 			true if the current gamemode is scavenge, false otherwise
 */
stock bool IsScavengeMode()
{
	char   sCurGameMode[64];
	ConVar CurGameMode = FindConVar("mp_gamemode");
	CurGameMode.GetString(sCurGameMode, sizeof(sCurGameMode));
	return (strcmp(sCurGameMode, "scavenge") == 0) ? true : false;
}

/*
 * Returns the current round number of current scavenge match.
 *
 * @return       	Round numbers
 */
stock int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

/*
 * Set the round number.
 *
 * @param round		round number to set. valid round number is from 1 to 5
 *
 * @return			if 0 >= round > 5.
 */
stock void SetScavengeRoundNumber(int round)
{
	if (round <= 0 || round > 5)
		return;

	GameRules_SetProp("m_nRoundNumber", round);
}

/*
 * Returns the current round limit number.
 *
 * @return 			round limit number
 */
stock int GetScavengeRoundLimit()
{
	return GameRules_GetProp("m_nRoundLimit");
}

/*
 * Sets the round limit.
 *
 * @param round		round limit to set. valid round number is 1, 3, 5.
 *
 * @return			if 0 >= round > 5.
 */
stock void SetScavengeRoundLimit(int round)
{
	if (round <= 0 || round > 5)
		return;

	GameRules_SetProp("m_nRoundLimit", round);
}

/*
 * Returns the amount of current remaining gascans.
 *
 * @return 			amount of current remaining gascans
 */
stock int GetScavengeItemsRemaining()
{
	return GameRules_GetProp("m_nScavengeItemsRemaining");
}

/*
 * Sets the amount of current round's items(gas cans) remaining
 *
 * @param count		amount to set
 *
 * @noreturn
 */
stock void SetScavengeItemsRemaining(int count)
{
	GameRules_SetProp("m_nScavengeItemsRemaining", count);
}

/*
 * Returns the goal amount of this match.
 *
 * @return 			goal amount of this match
 */
stock int GetScavengeItemsGoal()
{
	return GameRules_GetProp("m_nScavengeItemsGoal");
}

/*
 * Sets the goal amount of current round.
 *
 * @param count		amount to set
 *
 * @noreturn
 */
stock void SetScavengeItemsGoal(int count)
{
	GameRules_SetProp("m_nScavengeItemsGoal", count)
}

/*
 * Returns the winning team index of a specific round.
 *
 * @param round		round to return. valide number is 1 to 5
 * @return 			the winning team index of a specific round, 1 or 2.
 */
stock int GetWinningTeamNumber(int round)
{
	return GameRules_GetProp("m_iWinningTeamNumber", _, round - 1);
}

/*
 * Set a winning team index of a specific round.
 *
 * @param round		round to set
 * @param team		team number to set. valid values is 1 or 2
 *
 * @return			if team != 2 or 3, 0 >= round > 5.
 */
stock void SetWinningTeamNumber(int round, int team)
{
	if (round <= 0 || round > 5)
		return;

	if (team != 1 || team != 2)
		return;

	GameRules_SetProp("m_iWinningTeamNumber", team, _, round - 1);
}

/* FormatScavengeRoundTime() */
/* Credit to Forgetest from plugin 'Hyper-V HUD Manager(spechud)' */

/*
 * Returns the boolean value of the current round.
 *
 * @return			true if the current round is in second half, false otherwise.
 */

/* Already existed in l4d2util_rounds.inc
stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}
*/

/*
 * Returns number of characters of scavenge format time.
 *
 * @param buffer				buffer to store the round and time
 * @param maxlen				maxlenth of buffer
 * @param team					team number, valide value is 2 and 3
 * @param nodecimalpoint		if true, returns time of first half of the round.
 *								if false, returns time of second half of the round
 *
 * @return 						number of characters of scavenge format time
 */
stock int FormatScavengeRoundTime(char[] buffer, int maxlen, int team, bool nodecimalpoint = false)
{
	float seconds = GetScavengeRoundDuration(team);
	int	  minutes = RoundToFloor(seconds) / 60;
	seconds -= 60 * minutes;

	return nodecimalpoint ? Format(buffer, maxlen, "%d:%02.0f", minutes, seconds) : Format(buffer, maxlen, "%d:%05.2f", minutes, seconds);
}

/* GetRoundDuration(), GetScavengeTeamScore(), L4D2_TeamNumberToTeamIndex() */
/* Credit to ProdigySim from plugin 'Scavenge Quick End' */
/* GetScavengeMatchScore(), SetScavengeMatchScore() and SetScavengeTeamScore() was derived from these functions. */

/*
 * Returns the float value of the this round duration.
 * If the round has not ended yet, returns the current duration.
 *
 * @param team		team number. valid value is 2 or 3
 *
 * @return			float value of this round duration. invalide team number will return -1.0
 */
stock float GetScavengeRoundDuration(int team)
{
	float flRoundStartTime = GameRules_GetPropFloat("m_flRoundStartTime");

	if (team == 2 && flRoundStartTime != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
		return GetGameTime() - flRoundStartTime; // Survivor team still playing round.

	team = L4D2_TeamNumberToTeamIndex(team);

	return GameRules_GetPropFloat("m_flRoundDuration", team);
}

/*
 * Returns the team score of this round.
 *
 * @param team 		team number to return. valid value is 2 and 3
 * @param round		current round number.
 *
 * @return 			the team score of this round. invalide team number will return -1.
 */
stock int GetScavengeTeamScore(int team, int round)
{
	if (round <= 0 || round > 5)
	{
		round = GameRules_GetProp("m_nRoundNumber");
	}

	team = L4D2_TeamNumberToTeamIndex(team);

	return GameRules_GetProp("m_iScavengeTeamScore", _, (2 * (round - 1)) + team);
	// this is because:

	/*
	  Sub-Class Table (3 Deep): m_iScavengeTeamScore
		-Member: 000 (offset 0) (type integer) (bits 6)
		-Member: 001 (offset 4) (type integer) (bits 6)
		-Member: 002 (offset 8) (type integer) (bits 6)
		-Member: 003 (offset 12) (type integer) (bits 6)
		-Member: 004 (offset 16) (type integer) (bits 6)
		-Member: 005 (offset 20) (type integer) (bits 6)
		-Member: 006 (offset 24) (type integer) (bits 6)
		-Member: 007 (offset 28) (type integer) (bits 6)
		-Member: 008 (offset 32) (type integer) (bits 6)
		-Member: 009 (offset 36) (type integer) (bits 6)

	  the property has 10 elements.
	*/

	/*
	 team index has been converted to 0 and 1 from 2 and 3.
	 Tooth table:
		team | round | result
		  2	  	 1 	  	 0
		  2		 2		 2
		  2		 3	 	 4
		  2		 4		 6
		  2		 5		 8
		---------------------
		  3		 1		 1
		  3		 2		 3
		  3		 3		 5
		  3		 4		 7
		  3		 5		 9
	*/

	// '(2*(round-1))+team' can just be the result from 0 to 9. each number represents the round score a team secured.
	// In this formula, interger round = 1 to 5, interger team = 2 or 3.
}

/*
 * Sets the round score on specific round.
 *
 * @param team 		team number, valid index is 2 or 3
 * @param round		round index to set the score, valid index is 1 to 5
 * @param score		round score to set
 *
 * @return			if team != 2 or 3,  0 >= round or round> 5.
 */
stock void SetScavengeTeamScore(int team, int round, int score)
{
	if (round <= 0 || round > 5)
		return;

	team = L4D2_TeamNumberToTeamIndex(team);

	GameRules_SetProp("m_iScavengeTeamScore", score, 4, (2 * (round - 1)) + team);
}

/*
 * Returns the team match score of this match.
 *
 * @param team 		team number. valid value is 2 and 3
 *
 * @return 			the team match score of this match.
 *					if the team number is not 2 or 3, return -1
 */
stock int GetScavengeMatchScore(int team)
{
	team = L4D2_TeamNumberToTeamIndex(team);

	return GameRules_GetProp("m_iScavengeMatchScore", _, team);
}

/*
 * Sets the match score of one team.
 *
 * @param team 		team number. valid value is 2 and 3
 * @param score		score to set
 *
 * @return			if team != 2 or 3.
 */
stock void SetScavengeMatchScore(int team, int score)
{
	team = L4D2_TeamNumberToTeamIndex(team);

	GameRules_SetProp("m_iScavengeMatchScore", score, 4, team);
}

/*
 * Convert "2" or "3" to "0" or "1" for global static indices.
 * Defaultly recongnise 2 as team survivors and 3 as team infected.
 *
 * @param team 		team number. valid value is 2 or 3.
 *
 * @return 			1 if the team survivors flipped or team is infected,
 *  				0 if the team is survivors or team infected flipped,
 *  				-1 if the team number in invalide.
 */
stock int L4D2_TeamNumberToTeamIndex(int team)
{
	// must be team 2 or 3 for this stupid function
	if (team != 2 && team != 3) return -1;

	// Tooth table:
	// Team | Flipped | Correct index
	// 2	   0		 0
	// 2	   1		 1
	// 3	   0		 1
	// 3	   1		 0
	// index = (team & 1) ^ flipped
	// index = team-2 XOR flipped, or team%2 XOR flipped, or this...
	bool flipped = view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped", 1));
	if (flipped) ++team;
	return team % 2;
}

/* GetCasCanCout() Credit to Eyal282 from plugin '[L4D2] Scavenge Hardcore' */

/*
 * Returns current gascan count.
 *
 * @param count		index to return
 *
 * @return			gascan count
 */
stock int GetGasCanCount()
{
	int count;
	int entCount = GetEntityCount();

	for (int ent = MaxClients + 1; ent < entCount; ent++)
	{
		if (!IsValidEdict(ent))
			continue;

		char sClassname[64];
		GetEdictClassname(ent, sClassname, sizeof(sClassname));

		if (StrEqual(sClassname, "weapon_gascan") || StrEqual(sClassname, "weapon_gascan_spawn"))
			count++;
	}

	return count;
}

/*
 * On second half of round, which team won the match?
 *
 * @return      1 if the survivor team won the match.
 * 	    		0 if the infected team won the match.
 * 	    		-1 if we are currently not in second half of the round.
 * 			    -2 if currently no winner showing up on this match.
 */
stock int GetMatchWinner()
{
	bool IsSurvWin, IsInfecWin, IsNoWinner, IsSecondHalfOfRound;

	if (view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1)) == true)
	{
		int TeamSurvivor = GetScavengeMatchScore(2);	// converted team index is 1
		int TeamInfected = GetScavengeMatchScore(3);	// converted team index is 0

		switch (GetScavengeRoundLimit())
		{
			case 5:
			{
				if (TeamSurvivor == 3) IsSurvWin = true;
				else if (TeamInfected == 3) IsInfecWin = true;
				else IsNoWinner = true;
			}

			case 3:
			{
				if (TeamSurvivor == 2) IsSurvWin = true;
				else if (TeamInfected == 2) IsInfecWin = true;
				else IsNoWinner = true;
			}

			case 1:			// one round draw the winner out.
			{
				if (TeamSurvivor == 1) IsSurvWin = true;
				if (TeamInfected == 1) IsInfecWin = true;
			}
		}
	}
	else
	{
		IsSecondHalfOfRound = false;
	}

	return IsSecondHalfOfRound ? (IsSurvWin ? 1 : (IsInfecWin ? 0 : (IsNoWinner ? -1 : -1))) : -2;
}