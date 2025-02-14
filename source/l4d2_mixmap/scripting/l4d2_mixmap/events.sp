#if defined _l4d2_mixmap_events_included
	#endinput
#endif
#define _l4d2_mixmap_events_included

void HookEvents()
{
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
}

void Event_MapTransition(Event hEvent, char[] sName, bool dontBroadcast)
{
	// block this event in coop.
	if (g_bMapsetInitialized && L4D2_IsGenericCooperativeMode())
		return;
}
