#if defined _l4d2_scav_dhooks_native_included
 #endinput
#endif
#define _l4d2_scav_dhooks_native_included

/**
 * Called when the intro cutscene is starting to play on the beginning of a scavenge match.
 * 
 * @noreturn
*/
forward void L4D2_OnStartScavengeIntro()

/**
 * Called when the scavenge round setup countdown timer begins.
 * 
 * @param time   	The time duration of the round setup countdown timer. (ConVar value "scavenge_round_setup_time")
 * 
 * @note 			time will be 0.0 if the countdown timer is null.
 * @return 			Plugin_Handled to hide VGUI Panel 'ready_countdown' (but it wont stop the round setup countdown timer). 
 * 		   			Plugin_Changed to use the value from plugin on the timer.
 * 		   			Plugin_Continue to do nothing.
*/
forward Action L4D2_OnBeginScavengeRoundSetupTime(float &time)

/**
 * Called when the scavenge round setup countdown timer begins.
 * 
 * @param time   	The time duration of the round setup countdown timer.
 * 
 * @note 			This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * @noreturn
*/
forward void L4D2_OnBeginScavengeRoundSetupTime_Post(float time)

/**
 * Called when the scavenge round setup countdown timer begins.
 * 
 * @param time   	The time duration of the round setup countdown timer.
 * 
 * @note 			This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * @noreturn
*/
forward void L4D2_OnBeginScavengeRoundSetupTime_PostHandled(float time)

/**
 * Called when a scavenge overtime status starts.
 * 
 * @param client	An array of client indexes of who is holding the gascan.
 * 
 * @note 			same as event "scavenge_overtime_start". This function fires output "OnScavengeOvertimeStart" of entity "info_director".
 * @noreturn
*/
forward void L4D2_OnStartScavengeOvertime(int[] client)

/**
 * Called when a scavenge overtime status ends.
 * 
 * @param bEndStatus   True if the overtime status ended with a gascan filled, false otherwise (the round ended).
 * 
 * @note 			This function fires output "OnScavengeOvertimeCancel" of entity "info_director".
 * @note 			This function calls after CDirectorScavengeMode::UpdateOvertimeState, which is called after the gascan filling or round ending.
 * @noreturn
*/
forward void L4D2_OnEndScavengeOvertime(bool bEndStatus)

/**
 * Called when the scavenge overtime state updated.
 * 
 * @return			Plugin_Handled to prevent the overtime state from ending.
*/
forward Action L4D2_OnUpdateScavengeOvertimeState()

/**
 * Called when the scavenge overtime state updated.
 * 
 * @note 			This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * @noreturn
*/
forward void L4D2_OnUpdateScavengeOvertimeState_Post()

/**
 * Called when the scavenge overtime state updated.
 * 
 * @note 			This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * @noreturn
*/
forward void L4D2_OnUpdateScavengeOvertimeState_PostHandled()

/**
 * Called when the game is trying to end the scavenge round by comparing the team scores or by the status of the overtime.
 * 
 * @return			Plugin_Handled to prevent the round from ending.
*/
forward Action L4D2_OnScavengeUpdateScenarioState()

/**
 * Called when the game is trying to end the scavenge round by comparing the team scores or by the status of the overtime.
 * 
 * @note 			This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * @noreturn
*/
forward void L4D2_OnScavengeUpdateScenarioState_Post()

/**
 * Called when the game is trying to end the scavenge round by comparing the team scores or by the status of the overtime.
 * 
 * @note 			This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * @noreturn
*/
forward void L4D2_OnScavengeUpdateScenarioState_PostHandled()

/**
 * 
 * 
*/
forward void L4D2_OnScavengeRoundTimeExpired()

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
 * @note This function dose the same as cheat command "scenario_end", but more directly.
 * @noreturn
*/
native void L4D2_EndScavengeRound()

/**
 * Increments both survivors' scavenge team score and round timer.
 * 
 * @note This function increnments both score and round timer, like a normal gascan poured.
 * @note This function calls CTerrorGameRules::IncrementScavengeTeamScore and CGameRulesProxy::NotifyNetworkStateChanged internally.
 * @noreturn
*/
native void L4D2_IncrementScavengeTeamScoreAndDuration()

/**
 * Increments one team's scavenge team score.
 * 
 * @param team		Team number to increment. 2 for survivors or 3 for infected.
 * 
 * @note This function increnments only score.
 * @note This function calls CGameRulesProxy::NotifyNetworkStateChanged internally.
 * @noreturn
*/
native void L4D2_IncrementScavengeTeamScore(int team)

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