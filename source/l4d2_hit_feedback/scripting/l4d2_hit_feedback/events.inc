#if defined _l4d2_hit_feedback_events_included
	#endinput
#endif
#define _l4d2_hit_feedback_events_included

static const char s_sWeaponName[10][] = {
	"sniper_awp",
	"sniper_scout",
	"pistol_magnum",
	"shotgun_spas",
	"hunting_rifle",
	"sniper_military",
	"autoshotgun",
	"pumpshotgun",
	"shotgun_chrome",
	"pistol",
};

void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int Client				   = GetClientOfUserId(event.GetInt("userid"));
	IsVictimDeadPlayer[Client] = false;
}

void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(victim) && GetClientTeam(victim) == 3 && GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)
		IsVictimDeadPlayer[victim] = true;
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int tank				 = GetClientOfUserId(GetEventInt(event, "userid"));
	IsVictimDeadPlayer[tank] = false;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int	 victim		= GetClientOfUserId(event.GetInt("userid"));
	int	 attacker	= GetClientOfUserId(event.GetInt("attacker"));
	bool bHeadShout = event.GetBool("headshot");
	int	 damagetype = event.GetInt("type");
	char sWeaponName[64];
	event.GetString("weapon", sWeaponName, sizeof(sWeaponName));

	if (!g_hCvEnableFire.BoolValue && damagetype & DMG_BURN)
		return;

	if (!g_hCvEnableBlast.BoolValue && damagetype & DMG_BLAST)
		return;

	if (IsFakeClient(attacker))
		return;

	if (!IsValidClient(victim) && IsValidClient(attacker))
		return;

	if (GetClientTeam(victim) != 3 && GetClientTeam(attacker) != 2)
		return;

	if (!g_hCvEnableMelee.BoolValue && (strcmp(sWeaponName, "melee", false) == 0 || strcmp(sWeaponName, "chainsaw", false) == 0))
		return;

	if (g_hCvEnableInfectedPic.BoolValue)
		ShowKillMessage(attacker, bHeadShout ? kill_1 : kill);

	if (g_hCvEnableSound.BoolValue)
	{
		switch (g_iStyle[attacker])
		{
			case 1: EmitSoundToClient(attacker, bHeadShout ? g_sSoundHeadShot : g_sSoundKill, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			case 2: EmitSoundToClient(attacker, bHeadShout ? g_sSoundHeadShotDefualt : g_sSoundKillDefualt, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
		}
	}

	ManageTimer(g_hCvTimeForKillMarker, attacker);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int	 victim		= GetClientOfUserId(event.GetInt("userid"));
	int	 attacker	= GetClientOfUserId(event.GetInt("attacker"));
	int	 damagetype = event.GetInt("type");
	char sWeaponName[64];
	GetEventString(event, "weapon", sWeaponName, sizeof(sWeaponName));

	if (!g_hCvEnableFire.BoolValue && damagetype & DMG_BURN)
		return;

	if (!g_hCvEnableBlast.BoolValue && damagetype & DMG_BLAST)
		return;

	if (!IsValidClient(victim) && !IsValidClient(attacker))
		return;

	if (IsFakeClient(attacker))
		return;

	if (GetClientTeam(victim) != 3)
		return;

	if (!IsVictimDeadPlayer[victim])
		return;

	if (!g_hCvEnableMelee.BoolValue && strcmp(sWeaponName, "melee", false) == 0 || strcmp(sWeaponName, "chainsaw", false) == 0)
		return;

	bool bIsWeaponMatched = false;
	for (int i = 0; i < sizeof(sWeaponName); i++)
	{
		if (strcmp(sWeaponName, s_sWeaponName[i]))
		{
			bIsWeaponMatched = true;
			break;
		}
	}

	if (g_hCvEnableInfectedPic.BoolValue)
		ShowKillMessage(attacker, bIsWeaponMatched ? hit_armor : hit_armor_1);

	if (g_hCvEnableSound.BoolValue)
	{
		switch (g_iStyle[attacker])
		{
			case 1: EmitSoundToClient(attacker, g_sSoundBodyHit, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			case 2: EmitSoundToClient(attacker, g_sSoundBodyHitDefualt, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
		}
	}

	ManageTimer(g_hCvTimeForHitMarker, attacker);
}

void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int	 attacker	= GetClientOfUserId(event.GetInt("attacker"));
	bool bHeadShout = event.GetBool("headshot");
	bool damagetype = event.GetBool("blast");
	int	 WeaponID	= event.GetInt("weapon_id");

	if (!g_hCvEnableFire.BoolValue && WeaponID == 0)
		return;

	if (!g_hCvEnableBlast.BoolValue && damagetype)
		return;

	if (!IsValidClient(attacker) || IsFakeClient(attacker))
		return;

	if (GetClientTeam(attacker) != 2)
		return;

	if (!g_hCvEnableMelee.BoolValue && IsWepIdMeleeWeapon(attacker))
		return;

	if (g_hCvEnableInfKillPic.BoolValue)
		ShowKillMessage(attacker, bHeadShout ? kill_1 : kill);

	if (g_hCvEnableSound.BoolValue && g_hCvEnableOnInfectedKill.BoolValue)
	{
		switch (g_iStyle[attacker])
		{
			case 1: EmitSoundToClient(attacker, bHeadShout ? g_sSoundHeadShot : g_sSoundKill, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			case 2: EmitSoundToClient(attacker, bHeadShout ? g_sSoundHeadShotDefualt : g_sSoundKillDefualt, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
		}
	}

	ManageTimer(g_hCvTimeForKillMarker, attacker);
}

void Event_InfectedHurt(Event event, const char[] event_name, bool dontBroadcast)
{
	int victim		= event.GetInt("entityid");
	int attacker	= GetClientOfUserId(event.GetInt("attacker"));
	int dmg			= event.GetInt("amount");
	int damagetype	= event.GetInt("type");
	int eventhealth = GetEntProp(victim, Prop_Data, "m_iHealth");
	int entity		= event.GetInt("entityid");

	if (!g_hCvEnableFire.BoolValue && damagetype & DMG_BURN)
		return;

	if (!g_hCvEnableBlast.BoolValue && damagetype & DMG_BLAST)
		return;

	if (!IsValidClient(attacker) || IsFakeClient(attacker))
		return;

	if (eventhealth <= dmg)
		return;

	if (!g_hCvEnableMelee.BoolValue && IsWepIdMeleeWeapon(attacker))
		return;

	if (g_hCvEnableOnInfectedHit.BoolValue)
		ShowKillMessage(attacker, IsWitch(entity) ? hit_armor : hit_armor_1);

	if (g_hCvEnableSound.BoolValue && g_hCvEnableOnInfectedHit.BoolValue)
	{
		switch (g_iStyle[attacker])
		{
			case 1: EmitSoundToClient(attacker, g_sSoundBodyHit, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			case 2: EmitSoundToClient(attacker, g_sSoundBodyHitDefualt, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
		}
	}

	ManageTimer(g_hCvTimeForHitMarker, attacker);
}