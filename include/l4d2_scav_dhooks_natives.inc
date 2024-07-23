#if defined _l4d2_scav_dhooks_native_included
 #endinput
#endif
#define _l4d2_scav_dhooks_native_included

/**
 * Called when the intro cutscene starting to play on the beginning of a scavenge match.
 * 
 * @noreturn
*/
forward void L4D2_OnStartScavengeIntro()

/**
 * Called when The Director trying to check if bosses are prohibited.
 * 
 * @param prohibited   The bool value after the check. True on prohibition, false on allowed.
 * 
 * @return             Plugin_Continue or Plugin_Handled to prohibit bosses. Plugin_Changed to allow bosses.
*/
forward Action L4D2_AreBossesProhibited(bool prohibited)

/**
 * Called when the scavenge round setup countdown timer begins.
 * 
 * @noreturn
*/
forward void L4D2_OnBeginScavengeRoundSetupTime()

/**
 * Called when a scavenge round ended the overtime status.
 * @note This can be called whether a survivor filled the generator or lost it in the overtime status. 
 * 
 * @noreturn
*/
forward void L4D2_OnEndScavengeOvertime()

/**
 * Increments the scavenge match score for one team.
 * 
 * @param team   The team number to increment the score for.
 * 				 1 for survivors, 2 for infected.
 * 
 * @note This function calls CGameRulesProxy::NotifyNetworkStateChanged internally.
 * @noreturn
*/
native void L4D2_IncrementScavengeMatchScore(int team)

/**
 * Update the overtime state.
 * 
 * @noreturn
*/
native void L4D2_UpdateScavengeOvertimeState()

/**
 * Resets the scavenge round number to 0.
 * 
 * @note This function calls CGameRulesProxy::NotifyNetworkStateChanged internally.
 * @noreturn
*/
native void L4D2_ResetScavengeRoundNumber()

/**
 * Add time to the scavenge round timer.
 * 
 * @param time   The time to add to the timer.
 * 
 * @note This function calls CGameRulesProxy::NotifyNetworkStateChanged internally except the condition when argument time = 0.0.
 * @note You can pass a negative value to subtract time.
 * @noreturn
*/
native void L4D2_AccumulateScavengeRoundTime(float time)

/**
 * Restarts the scavenge round.
 * 
 * @noreturn
*/
native void L4D2_RestartScavengeRound()

/**
 * Update a scavenge mode mob spawn.
 * 
 * @return true on success, false on failure.
*/
native bool L4D2_UpdateScavengeMobSpawns()

/**
 * End the scavenge round.
 * 
 * @note This function dose the same as command "scenario_end", but more directly.
 * @noreturn
*/
native void L4D2_EndScavengeRound()

/**
 * Increments the scavenge team score through The Director.
 * 
 * @param team		Team number to increment. 2 for survivors or 3 for infected.
 * @param client	Client index who act as if he poured the gascan.
 * 
 * @note This function increnments both score and round timer, like a normal gascan poured.
 * @note This function calls CTerrorGameRules::IncrementScavengeTeamScore and CGameRulesProxy::NotifyNetworkStateChanged internally.
 * @noreturn
*/
native void L4D2_CDirector_IncrementScavengeTeamScore(int team, int client)

/**
 * Increments the scavenge team score through GameRule object.
 * 
 * @param team		Team number to increment. 2 for survivors or 3 for infected.
 * 
 * @note This function increnments only score.
 * @note This function calls CGameRulesProxy::NotifyNetworkStateChanged internally.
 * @noreturn
*/
native void L4D2_CTerrorGameRules_IncrementScavengeTeamScore()

public SharedPlugin __pl_l4d2_scav_dhooks_natives = 
{
	name = "l4d2_scav_dhooks_natives",
	file = "l4d2_scav_dhooks_natives.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};