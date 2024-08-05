#if defined _l4d2_hit_feedback_utils_included
	#endinput
#endif
#define _l4d2_hit_feedback_utils_included

ConVar CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}

bool CheckDamageType(int damagetype)
{
	if (!g_bCvEnableFire && (damagetype & DMG_BURN))
		return false;

	if (!g_bCvEnableBlast && (damagetype & DMG_BLAST))
		return false;

	return true;
}

bool IsWepIdMeleeWeapon(int attacker)
{
	char sWeaponName[21];
	int	 iWeapon = GetEntDataEnt2(attacker, g_iActiveWO);
	if (!IsValidEntity(iWeapon)) return false;

	GetEntityNetClass(iWeapon, sWeaponName, sizeof(sWeaponName));
	return (StrEqual(sWeaponName, "CTerrorMeleeWeapon", false));
}

stock bool IsWitch(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

bool IsCommonInfected(int iEntity)
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

bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

float[] GetEntityOrigin(int entity, bool center = false)
{
	float vec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vec)

	if (center)
	{
		float min[3], max[3]
		GetEntPropVector(entity, Prop_Send, "m_vecMins", min)
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", max)
		vec[0] += ( min[0] + max[0] ) / 2.0
		vec[1] += ( min[1] + max[1] ) / 2.0
		vec[2] += ( min[2] + max[2] ) / 2.0
	}

	return vec;
}

bool IsPlayerIncapacitated(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}