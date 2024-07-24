#if defined _l4d2_hit_feedback_actions_included
	#endinput
#endif
#define _l4d2_hit_feedback_actions_included

// you shouldn't be on the screen for too long!
void ManageTimer(ConVar cvar, int attacker)
{
	if (g_hTimerClean[attacker] != null)
		delete g_hTimerClean[attacker];

	g_hTimerClean[attacker] = CreateTimer(cvar.FloatValue, Timer_Remove, attacker);
}

Action Timer_Remove(Handle Timer, int client)
{
	KillTimer(Timer);
	g_hTimerClean[client] = INVALID_HANDLE;
	int iFlags			  = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"\"");
	SetCommandFlags("r_screenoverlay", iFlags);	   // do not spoiler this.

	return Plugin_Handled;
}

void ShowKillMessage(int client, int type)
{
	int iFlags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);

	switch (type)
	{
		case (kill_1): ClientCommand(client, "r_screenoverlay \"%s\"", g_sPic1);
		case (kill): ClientCommand(client, "r_screenoverlay \"%s\"", g_sPic3);
		case (hit_armor): ClientCommand(client, "r_screenoverlay \"%s\"", g_sPic2);
		case (hit_armor_1): ClientCommand(client, "r_screenoverlay \"%s\"", g_sPic4);
	}

	SetCommandFlags("r_screenoverlay", iFlags);	   // do not spoiler this.
}

bool IsWepIdMeleeWeapon(int attacker)
{
	char sWeaponName[21];
	int	 iWeapon = GetEntDataEnt2(attacker, g_iActiveWO);
	if (!IsValidEntity(iWeapon)) return false;

	GetEntityNetClass(iWeapon, sWeaponName, sizeof(sWeaponName));
	return (StrEqual(sWeaponName, "CTerrorMeleeWeapon", false));
}

bool IsWitch(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

// future use.
stock bool IsCommonInfected(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "infected");
	}
	return false;
}

bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client));
}