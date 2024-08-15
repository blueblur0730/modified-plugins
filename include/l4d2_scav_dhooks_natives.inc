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
 * Called when the scavenge round setup countdown timer is about to begin.
 * 
 * @noreturn	   			
*/
forward void L4D2_OnBeginScavengeRoundSetupTime()

/**
 * Called when a scavenge overtime status starts.
 * 
 * @param client	An array of client indexes of who is holding the gascan.
 * 
 * @note 			same as event "scavenge_overtime_start". This function fires output "OnScavengeOvertimeStart" of entity "info_director".
 * @noreturn
*/
forward void L4D2_OnStartScavengeOvertime(int client[32])

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
 * @note 			L4D2_OnUpdateScavengeOvertimeState is always called during the overtime status around per seconds from cvar "scavenge_overtime_grace_time".
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
 * @note 			L4D2_OnScavengeUpdateScenarioState() is always called during the game around per seconds, and is always calls before
 * 		 			L4D2_OnUpdateScavengeOvertimeState() and L4D2_OnScavengeRoundTimeExpired(). make sure you know the sequence when returing Plugin_Handled.
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
 * Called every time when the round timer has elapsed to 0.
 * 
 * @return			Plugin_Handled to prevent the round from entering the overtime state, then end the round.
*/
forward Action L4D2_OnScavengeRoundTimeExpired()

/**
 * Called every time when the round timer has elapsed to 0.
 * 
 * @note 			This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * @noreturn
*/
forward void L4D2_OnScavengeRoundTimeExpired_Post()

/**
 * Called every time when the round timer has elapsed to 0.
 * 
 * @note 			This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 * @noreturn
*/
forward void L4D2_OnScavengeRoundTimeExpired_PostHandled()

/**
 * Resets the scavenge round number to 0.
 * 
 * @note Do not call this native alone.
 * @noreturn
*/
native void L4D2_ResetScavengeRoundNumber()

/**
 * Add time to the scavenge round timer.
 * 
 * @param time   The time to add to the timer.
 * 
 * @note You can pass a negative value to subtract time.
 * @noreturn
*/
native void L4D2_AccumulateScavengeRoundTime(float time)

/**
 * Restarts the round.
 * 
 * @note You can't use this native before the game starts on versus and scavenge.
 * @noreturn
*/
native void L4D2_RestartRound()

/**
 * End the scavenge round.
 * 
 * @note This function dose the same as cheat command "scenario_end", but more directly.
 * @noreturn
*/
native void L4D2_EndScavengeRound()

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