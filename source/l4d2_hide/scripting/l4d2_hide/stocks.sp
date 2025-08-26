
stock bool IsHoldingMeds(int client)
{
	int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int	activeWepId	 = IdentifyWeapon(activeWep);

	switch (activeWepId)
	{
		case WEPID_FIRST_AID_KIT, WEPID_PAIN_PILLS, WEPID_ADRENALINE, WEPID_DEFIBRILLATOR:
			return true;

		default:
			return false;
	}
}

stock bool CheckPrefsBit(int client, int prefsBit)
{
    return (GetCookieValue(client) & prefsBit) != 0;
}

stock int GetCookieValue(int client)
{
    char buffer[16];
    g_hCookie_Misc.Get(client, buffer, sizeof(buffer));
    if (!buffer[0])
        return BIT_ALL;
    
    int value;
    if (!StringToIntEx(buffer, value))
        return BIT_ALL;
    
    return value;
}

stock bool IsBlackAndWhite(int client)
{
	return (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= survivor_max_incapacitated_count);
}

stock void CreateConVarHook(const char[] name,
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
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}

stock Cookie FindOrCreateCookie(const char[] name, const char[] description = "", CookieAccess access = CookieAccess_Public)
{
	Cookie hCookie = Cookie.Find(name);
	if (!hCookie)
	{
		hCookie = new Cookie(name, description, access);
		if (!hCookie)
			SetFailState("Unable to create cookie: %s.", name);
	}

	return hCookie;
}