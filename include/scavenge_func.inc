#if defined _scavenge_func_included
 #endinput
#endif
#define _scavenge_func_included

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/*
* Returns if the current gamemode is scavenge.
*
* @return 			true if the current gamemode is scavenge, false otherwise
*/
stock bool IsScavengeMode()
{
	ConVar CurGameMode = FindConVar("mp_gamemode");
	if(strcmp(CurGameMode, "scavenge") == 0)
		return true;
	else 
		return false;
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
* @param round		round number to set. invalid round number is from 1 to 5
* @noreturn
*/
stock void SetScavengeRoundNumber(int round)
{
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
* @param round		round limit to set. invalid round number is from 1 to 5
* @noreturn
*/
stock void SetScavengeRoundLimit(int round)
{
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
* Returns the goal amount of this match.
*
* @return 			goal amount of this match
*/
stock int GetScavengeItemsGoal()
{
	return GameRules_GetProp("m_nScavengeItemsGoal");
}

/* InSecondHalfOfRound() Credit to Forgetest from plugin 'Hyper-V HUD Manager(spechud)' */

/*
* Returns the boolean value of the current round.
*
* @return			true if the current round is in second half, false otherwise.
*/
stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}

/* GetRoundDuration(), GetScavengeTeamScore(), GetScavengeTeamScore(), L4D2_TeamNumberToTeamIndex() */
/* Credit to ProdigySim from plugin 'Scavenge Quick End' */
/* GetScavengeMatchScore() way derived from these functions. */

/*
* Returns the float value of the this round duration.
* If the round has not ended yet, returns the current duration.
*
* @param team		team index. valid value is 2 or 3
* @return			float value of this round duration
*					if the team index is not 2 or 3, return -1.0
*/
stock float GetRoundDuration(int team)
{
	float flRoundStartTime = GameRules_GetPropFloat("m_flRoundStartTime");
	if(team == 2 && flRoundStartTime != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
	{
		// Survivor team still playing round.
		return GetGameTime()-flRoundStartTime;
	}
	
	team = L4D2_TeamNumberToTeamIndex(team);
	if(team == -1) return -1.0;
	
	return GameRules_GetPropFloat("m_flRoundDuration", team);
}

/*
* Returns the team score of this round.
*
* @param team 		team index. valid value is 2 and 3
* @param round		current round number. default value is -1
* @return 			the team score of this round
* 					if the team index is not 2 or 3, return -1
*/
stock int GetScavengeTeamScore(int team, int round=-1)
{
	team = L4D2_TeamNumberToTeamIndex(team);
	if(team == -1) return -1;
	
	if(round <= 0 || round > 5)
	{
		round = GameRules_GetProp("m_nRoundNumber");
	}

	return GameRules_GetProp("m_iScavengeTeamScore", _, (2*(round-1))+team);
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
	*/

	// '(2*(round-1))+team' can just be the result from 0 to 9. each number represents the round score a survivor team scured.
	// In this formula, interger round = 1 to 5, interger team = 1 or 0.
}

/*
* Returns the team match score of this match.
*
* @param team 		team index. valid value is 2 and 3
* @return 			the team match score of this match
* 					if the team index is not 2 or 3, return -1
*/
stock int GetScavengeMatchScore(int team)
{
	team = L4D2_TeamNumberToTeamIndex(team);
	if(team == -1) return -1;
	
	return GameRules_GetProp("m_iScavengeMatchScore", _, team);
}

/*
* Convert "2" or "3" to "0" or "1" for global static indices.
* Defaultly recongnise 2 as team survivors and 3 as team infected.
*
* @param team 		team index. valid value is 2 and 3. other values returns -1
* @return 			1 if the team survivors flipped or team infected haven't flipped
*					0 if the team survivors haven't flipped or team infected flipped
*					-1 if the team index value is not 2 or 3
*/
stock int L4D2_TeamNumberToTeamIndex(int team)
{
	// must be team 2 or 3 for this stupid function
	if(team != 2 && team != 3) return -1;

	// Tooth table:
	// Team | Flipped | Correct index
	// 2	   0		 0
	// 2	   1		 1
	// 3	   0		 1
	// 3	   1		 0
	// index = (team & 1) ^ flipped
	// index = team-2 XOR flipped, or team%2 XOR flipped, or this...	
	bool flipped;
	flipped = GameRules_GetProp("m_bAreTeamsFlipped", 1);
	if(flipped) ++team;
	return team % 2;
}

/* GetCasCanCout() and Scavenge_FixNoGascanSpawnBug() Credit to Eyal282 from plugin '[L4D2] Scavenge Hardcore' */

/*
* Returns current gascan count.
*
* @param count		index to return
* @return			gascan count
*/
stock int GetGasCanCount(int count)
{
    int entCount = GetEntityCount();

    for(int ent=MaxClients+1;ent < entCount;ent++)
    {
        if(!IsValidEdict(ent))
            continue;

        char sClassname[64];
        GetEdictClassname(ent, sClassname, sizeof(sClassname));

        if(StrEqual(sClassname, "weapon_gascan") || StrEqual(sClassname, "weapon_gascan_spawn"))
            count++;
    }

    return count;
}

/*
* Called to fix the bug when first round begins, no gascan spawned.
*
* @noreturn
*/
stock void Scavenge_FixNoGascanSpawnBug()
{   
    char sSignature[128];
    sSignature = "@_ZN9CDirector21SpawnAllScavengeItemsEv";
   
	Handle Call = INVALID_HANDLE;
	if (Call == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, sSignature, strlen(sSignature)-1))
		{
			return;
		}

		Call = EndPrepSDKCall();
		if (Call == INVALID_HANDLE)
		{
			return;
		}
	}

	SDKCall(Call, L4D_GetPointer(POINTER_DIRECTOR));
}

