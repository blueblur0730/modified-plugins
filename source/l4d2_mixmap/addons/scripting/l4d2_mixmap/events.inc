#if defined _l4d2_mixmap_events_included
	#endinput
#endif
#define _l4d2_mixmap_events_included

#define DEBUG 1

static bool
	s_bIsMissionFailed		 = false,
	s_bSwitchingForCoop		 = false,
	s_bCoopEndSaferoomClosed = false;

void HookEvents()
{
	// scavenge game check
	HookEvent("scavenge_round_finished", Event_ScavRoundFinished, EventHookMode_Post);
	HookEvent("scavenge_match_finished", Event_ScavMatchFinished, EventHookMode_Post);

	// coop game check
	HookEvent("mission_lost", Event_MissionLost, EventHookMode_Post);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
	HookEvent("door_close", Event_DoorClose, EventHookMode_Post);
	HookEvent("door_open", Event_DoorOpen, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

void ToggleEvents()
{
	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
	{
		UnhookEvent("map_transition", Event_MapTransition);
		UnhookEvent("door_close", Event_DoorClose);
		UnhookEvent("door_open", Event_DoorOpen);
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

public void Event_ScavRoundFinished(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (InSecondHalfOfRound() && g_bMapsetInitialized)
		PerformMapProgression();
}

public void Event_ScavMatchFinished(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (g_bMapsetInitialized)
	{
		PluginStartInit();
		CPrintToChatAll("%t", "Scav_Match_End");

		Call_StartForward(g_hForwardEnd);
		Call_Finish();
	}
}

public void Event_MissionLost(Event hEvent, char[] sName, bool dontBroadcast)
{
	s_bIsMissionFailed = true;
}

public Action Event_MapTransition(Event hEvent, char[] sName, bool dontBroadcast)
{
	// block this event in coop.
	if (g_bMapsetInitialized && L4D2_IsGenericCooperativeMode())
		return Plugin_Handled;

	return Plugin_Continue;
}

// Coop game fix: when the end saferoom door closes, we instantly move to the next map,
// avoiding issues that happen in coop when changing maps at the normal time on actual round end.
public void Event_DoorClose(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (L4D2_IsGenericCooperativeMode())
	{
		if (!hEvent.GetBool("checkpoint"))
			return;

		s_bCoopEndSaferoomClosed = true;

		CreateTimer(0.25, Timed_PostOnDoorCloseMapSwitch);
	}
}

// When the end saferoom door opens (again), we shouldn't end the map.
public void Event_DoorOpen(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (L4D2_IsGenericCooperativeMode())
	{
		if (!hEvent.GetBool("checkpoint") || s_bSwitchingForCoop)
			return;

		s_bCoopEndSaferoomClosed = false;
	}
}

// If a survivor dies, while the end saferoom door is closed, and all living survivors are in the end saferoom,
// that's when we should do a mapswitch.
public Action Event_PlayerDeath(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (L4D2_IsGenericCooperativeMode())
	{
		if (!s_bCoopEndSaferoomClosed)
			return Plugin_Continue;

		int victim = GetClientOfUserId(hEvent.GetInt("userid"));

		if (!IsSurvivorClient(victim))
			return Plugin_Continue;

		PerformMapProgressionPre();
	}

	return Plugin_Continue;
}

void PerformMapProgressionPre()
{
	if (!AreAllLivingSurivorsInEndSafeRoom())
		return;

	s_bSwitchingForCoop = true;
	PerformMapProgression();
}

public Action Timed_PostOnDoorCloseMapSwitch(Handle timer)
{
	PerformMapProgressionPre();

	return Plugin_Continue;
}

public void EntEvent_OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
#if DEBUG
	PrintToServer("[Mixmap] OnGameplayStart fired.");
#endif
	// it need to be delayed, it need to be set after you notice you were in the game.
	CreateTimer(13.0, Timer_OnGameplayStartDelay);
}

Action Timer_OnGameplayStartDelay(Handle Timer)
{
#if DEBUG
	PrintToServer("[Mixmap] Timer_OnGameplayStartDelay called.");
#endif

	if (L4D2_IsGenericCooperativeMode() && !s_bIsMissionFailed)
		if (g_cvSaveStatus.BoolValue)
			SetPlayerInfo();

	s_bIsMissionFailed = false;

	return Plugin_Continue;
}