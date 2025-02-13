#if defined _l4d2_mixmap_events_included
	#endinput
#endif
#define _l4d2_mixmap_events_included

static bool
	s_bIsMissionFailed		 = false,
	s_bSwitchingForCoop		 = false,
	s_bCoopEndSaferoomClosed = false;

void HookEvents()
{
	HookEvent("mission_lost", Event_MissionLost, EventHookMode_Post);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

void Event_MissionLost(Event hEvent, char[] sName, bool dontBroadcast)
{
	s_bIsMissionFailed = true;
}

void Event_MapTransition(Event hEvent, char[] sName, bool dontBroadcast)
{
	// block this event in coop.
	if (g_bMapsetInitialized && L4D2_IsGenericCooperativeMode())
		return;
}

// If a survivor dies, while the end saferoom door is closed, and all living survivors are in the end saferoom,
// that's when we should do a mapswitch.
void Event_PlayerDeath(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (L4D2_IsGenericCooperativeMode())
	{
		if (!s_bCoopEndSaferoomClosed)
			return;

		int victim = GetClientOfUserId(hEvent.GetInt("userid"));

		if (!IsSurvivorClient(victim))
			return;

		PerformMapProgressionPre();
	}
}

void PerformMapProgressionPre()
{
	s_bSwitchingForCoop = true;
	PerformMapProgression();
}

Action Timed_PostOnDoorCloseMapSwitch(Handle timer)
{
	PerformMapProgressionPre();

	return Plugin_Continue;
}