#if defined _l4d2_hit_feedback_events_included
	#endinput
#endif
#define _l4d2_hit_feedback_events_included

static bool bIsVictimDeadPlayer[MAXPLAYERS + 1] = { false, ... };

void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int Client = GetClientOfUserId(event.GetInt("userid"));
	bIsVictimDeadPlayer[Client] = false;
}

void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(victim) && GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)
		bIsVictimDeadPlayer[victim] = true;
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	bIsVictimDeadPlayer[tank] = false;
}

// this is left for both SI and survivors.
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int	 victim		= GetClientOfUserId(event.GetInt("userid"));
	int	 attacker	= GetClientOfUserId(event.GetInt("attacker"));
	bool bHeadShot = event.GetBool("headshot");
	int	 damagetype = event.GetInt("type");
	char sWeaponName[64];
	event.GetString("weapon", sWeaponName, sizeof(sWeaponName));

	if (!CheckDamageType(damagetype))
		return;

	if (!IsSurvivor(attacker) || !IsInfected(victim) || IsFakeClient(attacker))
		return;

	if (!g_bCvEnableMelee && (strcmp(sWeaponName, "melee", false) == 0 || strcmp(sWeaponName, "chainsaw", false) == 0))
		return;

	if (g_bCvEnableSIKillOverlay && GetEntProp(victim, Prop_Send, "m_zombieClass") != 0)
		ShowKillMessage(attacker, bHeadShot ? kill_1 : kill);

	if (g_bCvEnableSound && g_bCvEnableSIKillSnd)
	{
		switch (g_iStyle[attacker])
		{
			case 1: EmitSoundToClient(attacker, bHeadShot ? g_sSoundHeadShot : g_sSoundKill, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			case 2: EmitSoundToClient(attacker, bHeadShot ? g_sSoundHeadShotDefualt : g_sSoundKillDefualt, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
		}
	}

	ManageTimer(g_flTimeForKillMarker, attacker);
}

// this is left for survivors in the future.
/*
void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int	 victim		= GetClientOfUserId(event.GetInt("userid"));
	int	 attacker	= GetClientOfUserId(event.GetInt("attacker"));
	int	 damagetype = event.GetInt("type");
	char sWeaponName[64];
	event.GetString("weapon", sWeaponName, sizeof(sWeaponName));

	if (!CheckDamageType(damagetype))
		return;

	if (!IsSurvivor(attacker) || !IsInfected(victim) || IsFakeClient(attacker))
		return;

	if (!bIsVictimDeadPlayer[victim])
		return;

	if (!g_bCvEnableMelee && strcmp(sWeaponName, "melee", false) == 0 || strcmp(sWeaponName, "chainsaw", false) == 0)
		return;

	if (g_bCvEnableInfectedPic)
		ShowKillMessage(attacker, hit_armor);

	if (g_bCvEnableSound)
	{
		switch (g_iStyle[attacker])
		{
			case 1: EmitSoundToClient(attacker, g_sSoundBodyHit, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			case 2: EmitSoundToClient(attacker, g_sSoundBodyHitDefualt, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
		}
	}

	ManageTimer(g_flTimeForHitMarker, attacker);
}
*/

// this part is for CIs and witch.
void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int	 attacker	= GetClientOfUserId(event.GetInt("attacker"));
	bool bHeadShot = event.GetBool("headshot");
	bool damagetype = event.GetBool("blast");
	int	 WeaponID	= event.GetInt("weapon_id");

	if (!g_bCvEnableFire && WeaponID == 0)
		return;

	if (!g_bCvEnableBlast && damagetype)
		return;

	if (!IsSurvivor(attacker) || IsFakeClient(attacker))
		return;

	if (!g_bCvEnableMelee && IsWepIdMeleeWeapon(attacker))
		return;

	if (g_bCvEnableCIKillOverlay)
		ShowKillMessage(attacker, bHeadShot ? kill_1 : kill);

	if (g_bCvEnableSound && g_bCvEnableCIKillSnd)
	{
		switch (g_iStyle[attacker])
		{
			case 1: EmitSoundToClient(attacker, bHeadShot ? g_sSoundHeadShot : g_sSoundKill, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			case 2: EmitSoundToClient(attacker, bHeadShot ? g_sSoundHeadShotDefualt : g_sSoundKillDefualt, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
		}
	}

	ManageTimer(g_flTimeForKillMarker, attacker);
}

// this part if for both CIs and witch and SIs.
void Event_InfectedHurt(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim		= event.GetInt("entityid");
	int attacker	= GetClientOfUserId(event.GetInt("attacker"));
	int dmg			= event.GetInt("amount");
	int damagetype	= event.GetInt("type");
	int entity		= event.GetInt("entityid");
	int eventhealth = GetEntProp(victim, Prop_Data, "m_iHealth");

	if (!CheckDamageType(damagetype))
		return;

	if (!IsValidClient(attacker) || IsFakeClient(attacker))
		return;

	// on last hit, play the kill sound instead of hit sound. Infected Death will be triggered.
	if (eventhealth <= dmg)
		return;

	if (!g_bCvEnableMelee && IsWepIdMeleeWeapon(attacker))
		return;

	char sClassname[32];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));
	if ((strcmp(sClassname, "infected") == 0 && g_bCvEnableCIHitOverlay) ||
		(GetEntProp(entity, Prop_Send, "m_zombieClass") != 0 && g_bCvEnableSIHitOverlay))
	{
		ShowKillMessage(attacker, hit_armor);
	}

	if (g_bCvEnableSound && ((g_bCvEnableCIHitSnd && strcmp(sClassname, "infected") == 0) ||
	 	(GetEntProp(entity, Prop_Send, "m_zombieClass") != 0 && g_bCvEnableSIHitSnd)))
	{
		switch (g_iStyle[attacker])
		{
			case 1: EmitSoundToClient(attacker, g_sSoundBodyHit, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			case 2: EmitSoundToClient(attacker, g_sSoundBodyHitDefualt, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
		}
	}

	ManageTimer(g_flTimeForHitMarker, attacker);
}