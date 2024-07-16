#if defined _l4d2_scav_dhooks_stock_included
	#endinput
#endif
#define _l4d2_scav_dhooks_stock_included

#include <sourcemod>
#include <sdktools>

methodmap ScavStocksWrapper
{
	/**
 	 * Is now scavenge mode?
	 * 
 	 * @return 	true if now scavenge mode, false otherwise.
	*/
	public bool IsScavengeMode() {
		char sGameMode[32];
		FindConVar("mp_gamemode").GetString(sGameMode, sizeof(sGameMode));
		return (strcmp(sGameMode, "scavenge") == 0);
	}

	/**
	 * Is round in second half ?
	 * 
	 * @return 	true if round in second half, false otherwise.
	*/
	property bool m_bInSecondHalfOfRound {
		public get() {
			return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
		}
	}

	/**
	 * Is teams flipped?
	 * 
	 * @return 	true if teams flipped, false otherwise.
	*/
	property bool m_bAreTeamsFlipped {
		public get() {
			return view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped"));
		}
	}

	/**
	 * Is currently in intro?
	 * 
	 * @return 	true if in intro, false otherwise.
	*/
	property bool m_bInIntro {
		public get() {
			return view_as<bool>(GameRules_GetProp("m_bInIntro"));
		}
	}

	/** 
 	 * Get or set the round number.
 	 *
	 * @param round		round number to set. valid round number is from 1 to 5.
	 * @note			invalid round number will be ignored and set nothing.
 	*/
	property int m_nRoundNumber {
		public get() {
			return GameRules_GetProp("m_nRoundNumber");
		}
		public set(int round) {
			if (round <= 0 || round > 5)
				return;

			GameRules_SetProp("m_nRoundNumber", round);
		}
	}

	/** 
 	 * Get or set the round limit.
 	 *
 	 * @param limit		round number to set. valid round limit is 1, 3, 5.
	 * @note			invalid limit will be ignored and set nothing.
 	*/
	property int m_nRoundLimit {
		public get() {
			return GameRules_GetProp("m_nRoundLimit");
		}
		public set(int limit) {
			if (limit != 1 || limit != 3 || limit != 5)
				return;

			GameRules_SetProp("m_nRoundLimit", limit);
		}
	}

	/** 
 	 * Get the remaining number of scavenge items.
 	*/
	property int m_nScavengeItemsRemaining {
		public get() {
			return GameRules_GetProp("m_nScavengeItemsRemaining");
		}
	}

	/**
	 * Get the goal amount of current round.
	*/
	property int m_nScavengeItemsGoal {
		public get() {
			return GameRules_GetProp("m_nScavengeItemsGoal");
		}
	}

	/**
	 * Get or set accumulated time of current round.
	 * 
	 * @param time		time to set.
	 * @note			invalid time, smaller than 0.0, will be ignored and set nothing.
	*/
	property float m_flAccumulatedTime {
		public get() {
			return GameRules_GetPropFloat("m_flAccumulatedTime");
		}
		public set(float time) {
			if (time < 0.0)
				return;

			GameRules_SetPropFloat("m_flAccumulatedTime", time);
		}
	}

	/** 
 	 * Returns the winning team index of a specific round.
 	 *
 	 * @param round		round to find. valide number is 1 to 5.
	 * 
 	 * @return 			the winning team index of a specific round, 0 or 1.
	 * 					-1 on invalid round number.
 	*/
	public int GetWinningTeamIndex(int round) {
		if (round <= 0 || round > 5)
			return -1;

		return GameRules_GetProp("m_iWinningTeamNumber", _, round - 1);
	}

	/**
	 * Returns the duration of current round
	 * 
	 * @param team		team number to get the duration time. valid value are 2 or 3.
	 * 
	 * @return 			the duration of current round.
	 * @note			invalid team number will auto return the duration time of current infected team.
	*/
	public float GetRoundDuration(int team) {
		float m_flRoundStartTime = GameRules_GetPropFloat("m_flRoundStartTime");

		if (team == 2 && m_flRoundStartTime != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
			return (GetGameTime() - m_flRoundStartTime); // Survivor team still playing round.

		if (L4D2_TeamNumberToTeamIndex(team) == -1)
			return GameRules_GetPropFloat("m_flRoundDuration", L4D2_TeamNumberToTeamIndex(3));

		return GameRules_GetPropFloat("m_flRoundDuration", team);
	}

	/** 
 	 * Returns the team score of this round.
 	 *
 	 * @param team 		team number to find. valid value  are 2 or 3.
 	 * @param round		round number to find.
 	 *
 	 * @return 			the team score of this round. invalide team number will return -1.
 	*/
	public int GetTeamScore(int team, int round) {
		if (round <= 0 || round > 5)
			round = GameRules_GetProp("m_nRoundNumber");

		L4D2_TeamNumberToTeamIndex(team);

		return GameRules_GetProp("m_iScavengeTeamScore", _, (2 * (round - 1)) + team);
		/*
		team index has been converted to 0 and 1 from 2 and 3.
		m_iScavengeTeamScore has 10 elements for team and each round.
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
	}

	/**
 	 * Sets the round score on specific round.
 	 *
 	 * @param team 		team number, valid index is 2 or 3
 	 * @param round		round number to set the score, valid number is 1 to 5
 	 * @param score		round score to set
	 * @note			score shouldn't be greater than goal amount of current round.
	 * @note			invalid round number will be set as current round number.
 	 *
 	 * @return			invalid team number will be ignored and set nothing.
 	 */
	public void SetTeamScore(int team, int round, int score) {
		if (round <= 0 || round > 5)
			round = GameRules_GetProp("m_nRoundNumber");

		if (L4D2_TeamNumberToTeamIndex(team) == -1)
			return;

		GameRules_SetProp("m_iScavengeTeamScore", score, 4, (2 * (round - 1)) + team);
	}

	/**
 	 * Returns the team's match score of this match.
 	 *
 	 * @param team 		team number. valid value is 2 and 3
 	 *
 	 * @return 			the team match score of this match.
 	 *					return -1 on invalid team number.
 	 */
	public int GetMatchScore(int team) {
		if (L4D2_TeamNumberToTeamIndex(team) == -1)
			return -1;

		return GameRules_GetProp("m_iScavengeMatchScore", _, team);
	}
	/**
 	 * Sets the team's match score of this match.
 	 *
 	 * @param team 		team number. valid value is 2 and 3
 	 *
 	 * @return 			invalid team number will be ignored and set nothing.
 	 */
	public void SetMatchScore(int team, int score) {
		if (L4D2_TeamNumberToTeamIndex(team) == -1)
			return;

		GameRules_SetProp("m_iScavengeMatchScore", score, _, team);
	}
}

/** 
 * Formats the current scavenge round duration time as a string.
 * 
 * @note						from plugin SpecHUD by Visor, Forgetest.
 *
 * @param buffer				buffer to store the round and time
 * @param maxlen				maxlenth of buffer.
 * @param team					team number, valide value see enum TeamNumber.
 * @param nodecimalpoint		true to print seconds without decimal point, false otherwise, also prints 5 digits in front of decimal point.
 *
 * @return 						number of characters written to the buffer, not including the null terminator.
*/
stock int FormatDurationTime(char[] buffer, int maxlen, int team, bool nodecimalpoint = false) 
{
	ScavStocksWrapper scav;
	float flRoundStartTime = scav.GetRoundDuration(team);
	int	  minutes = RoundToFloor(flRoundStartTime) / 60;
	float seconds = 60 * minutes - flRoundStartTime;

	return nodecimalpoint ? Format(buffer, maxlen, "%d:%02.0f", minutes, seconds) :
							Format(buffer, maxlen, "%d:%05.2f", minutes, seconds);
}

/*
 * Convert "2" or "3" to "0" or "1" for global static indices.
 * Defaultly recongnise 2 as team survivors and 3 as team infected.
 * 
 * @note			from plugin Scavenge Quick End by ProdigySim.
 *
 * @param team 		team number. valid value is 2 or 3.
 *
 * @return 			1 if the team survivors flipped or team is infected,
 *  				0 if the team is survivors or team infected flipped,
 *  				-1 if the team number is invalid.
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
	bool flipped = view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped"));
	if (flipped) ++team;
	return team % 2;
}

/*
 * Returns current gascan count.
 *
 * @note			from plugin Scavenge Hardcore by Eyal828.
 * 
 * @return			gascan count
 */
stock int GetGasCanCount()
{
	int count;
	for (int i = MaxClients + 1; i < GetEntityCount(); i++)
	{
		if (!IsValidEdict(i))
			continue;

		char sClassname[64];
		GetEdictClassname(i, sClassname, sizeof(sClassname));

		if (StrEqual(sClassname, "weapon_gascan") || StrEqual(sClassname, "weapon_gascan_spawn"))
			count++;
	}

	return count;
}
/**
 * Returns the number of cans for current round to win.
 * 
 * @return 			the number of cans to win this round for survivors, -1 if the gamemode is not scavenge.
*/
stock int GetNumCansToWin()
{
	ScavStocksWrapper scav;
	if (scav.IsScavengeMode())
	{
		if (scav.m_bInSecondHalfOfRound)
		{
			int surScore = scav.GetTeamScore(2, scav.m_nRoundNumber);
			int infScore = scav.GetTeamScore(3, scav.m_nRoundNumber);
			return (infScore - surScore + 1);
		}
		else
		{
			int surScore = scav.GetTeamScore(2, scav.m_nRoundNumber);
			return (scav.m_nScavengeItemsGoal - surScore);
		}
	}

	return -1;
	/*
	int GetNumCansToWin(void)
	{
  		int ScavengeTeamScore; // esi
  		int v1; // ebx

  		ScavengeTeamScore = CTerrorGameRules::GetScavengeTeamScore(g_pGameRules, 2, -1);
  		v1 = CTerrorGameRules::GetScavengeItemsGoal(g_pGameRules) - ScavengeTeamScore;
  		if ( CTerrorGameRules::IsScavengeMode() && *((_BYTE *)g_pGameRules + 1169) )
    		return CTerrorGameRules::GetScavengeTeamScore(g_pGameRules, 3, -1) - ScavengeTeamScore + 1;
  		return v1;
	}
	*/
}

