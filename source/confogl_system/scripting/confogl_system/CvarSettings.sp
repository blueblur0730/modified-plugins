#if defined __cvar_settings_included
	#endinput
#endif
#define __cvar_settings_included

#define CVS_MODULE_NAME			"CvarSettings"

#define CVARS_DEBUG				0
#define CVS_CVAR_MAXLEN			64

enum struct CVSEntry
{
	ConVar CVSE_cvar;
	char CVSE_oldval[CVS_CVAR_MAXLEN];
	char CVSE_newval[CVS_CVAR_MAXLEN];
}

static bool
	bTrackingStarted = false;

static ArrayList
	CvarSettingsArray = null;

void CVS_OnModuleStart()
{
	CVSEntry cvsetting;
	CvarSettingsArray = new ArrayList(sizeof(cvsetting));

	RegConsoleCmd("confogl_cvarsettings", CVS_CvarSettings_Cmd, "List all ConVars being enforced by Confogl");
	RegConsoleCmd("confogl_cvardiff", CVS_CvarDiff_Cmd, "List any ConVars that have been changed from their initialized values");

	RegServerCmd("confogl_addcvar", CVS_AddCvar_Cmd, "Add a ConVar to be set by Confogl");
	RegServerCmd("confogl_setcvars", CVS_SetCvars_Cmd, "Starts enforcing ConVars that have been added.");
	RegServerCmd("confogl_resetcvars", CVS_ResetCvars_Cmd, "Resets enforced ConVars.  Cannot be used during a match!");
}

void CVS_OnModuleEnd()
{
	ClearAllSettings();
}

void CVS_OnConfigsExecuted()
{
	if (bTrackingStarted)
		SetEnforcedCvars();
}

static Action CVS_SetCvars_Cmd(int args)
{
	if (!IsPluginEnabled())
		return Plugin_Handled;

	if (bTrackingStarted) 
	{
		PrintToServer("Tracking has already been started");
		return Plugin_Handled;
	}

#if CVARS_DEBUG
	LogMessage("[%s] No longer accepting new ConVars", CVS_MODULE_NAME);
#endif

	SetEnforcedCvars();
	bTrackingStarted = true;

	return Plugin_Handled;
}

static Action CVS_AddCvar_Cmd(int args)
{
	if (args != 2) 
	{
		PrintToServer("Usage: confogl_addcvar <cvar> <newValue>");

		if (IsDebugEnabled()) 
		{
			char cmdbuf[MAX_NAME_LENGTH];
			GetCmdArgString(cmdbuf, sizeof(cmdbuf));
			Debug_LogError(CVS_MODULE_NAME, "Invalid Cvar Add: %s", cmdbuf);
		}

		return Plugin_Handled;
	}

	char cvar[CVS_CVAR_MAXLEN], newval[CVS_CVAR_MAXLEN];
	GetCmdArg(1, cvar, sizeof(cvar));
	GetCmdArg(2, newval, sizeof(newval));

	AddCvar(cvar, newval);

	return Plugin_Handled;
}

static Action CVS_ResetCvars_Cmd(int args)
{
	if (IsPluginEnabled()) 
	{
		PrintToServer("Can't reset tracking in the middle of a match");
		return Plugin_Handled;
	}

	ClearAllSettings();
	PrintToServer("Server CVar Tracking Information Reset!");

	return Plugin_Handled;
}

static Action CVS_CvarSettings_Cmd(int client, int args)
{
	if (!IsPluginEnabled())
		return Plugin_Handled;

	if (!bTrackingStarted) 
	{
		CReplyToCommand(client, "%t %t", "Tag", "NotStarted");
		return Plugin_Handled;
	}

	char buffer[CVS_CVAR_MAXLEN], name[CVS_CVAR_MAXLEN];
	int cvscount = CvarSettingsArray.Length;

	CReplyToCommand(client, "%t %t", "Tag", "EnforcedCvars", cvscount);

	GetCmdArg(1, buffer, sizeof(buffer));
	int offset = StringToInt(buffer);

	if (offset < 0 || offset > cvscount)
		return Plugin_Handled;

	int temp = cvscount;
	if ((offset + 20) < cvscount)
		temp = offset + 20;

	CVSEntry cvsetting;
	for (int i = offset; i < temp && i < cvscount; i++) 
	{
		CvarSettingsArray.GetArray(i, cvsetting, sizeof(cvsetting));

		(cvsetting.CVSE_cvar).GetString(buffer, sizeof(buffer));
		(cvsetting.CVSE_cvar).GetName(name, sizeof(name));

		CReplyToCommand(client, "%t %t", "Tag", "CvarInfo", name, cvsetting.CVSE_newval, buffer);
	}

	if ((offset + 20) < cvscount)
		CReplyToCommand(client, "%t %t", "Tag", "ToSeeMore", offset + 20);

	return Plugin_Handled;
}

static Action CVS_CvarDiff_Cmd(int client, int args)
{
	if (!IsPluginEnabled())
		return Plugin_Handled;

	if (!bTrackingStarted) 
	{
		CReplyToCommand(client, "%t %t", "Tag", "NotStarted");
		return Plugin_Handled;
	}

	char buffer[CVS_CVAR_MAXLEN], name[CVS_CVAR_MAXLEN];
	int cvscount = CvarSettingsArray.Length;

	GetCmdArg(1, buffer, sizeof(buffer));
	int offset = StringToInt(buffer);

	if (offset > cvscount)
		return Plugin_Handled;

	int foundCvars = 0;

	CVSEntry cvsetting;

	while (offset < cvscount && foundCvars < 20) 
	{
		CvarSettingsArray.GetArray(offset, cvsetting, sizeof(cvsetting));

		(cvsetting.CVSE_cvar).GetString(buffer, sizeof(buffer));
		(cvsetting.CVSE_cvar).GetName(name, sizeof(name));

		if (strcmp(cvsetting.CVSE_newval, buffer) != 0) 
		{
			CReplyToCommand(client, "%t %t", "Tag", "CvarInfo", name, cvsetting.CVSE_newval, buffer);
			foundCvars++;
		}

		offset++;
	}

	if (offset < cvscount) 
		CReplyToCommand(client, "%t %t", "Tag", "ToSeeMore", offset);

	return Plugin_Handled;
}

static void ClearAllSettings()
{
	bTrackingStarted = false;
	int iSize = CvarSettingsArray.Length;
	CVSEntry cvsetting;

	for (int i = 0; i < iSize; i++) 
	{
		CvarSettingsArray.GetArray(i, cvsetting, sizeof(cvsetting));

		(cvsetting.CVSE_cvar).RemoveChangeHook(CVS_ConVarChange);
		(cvsetting.CVSE_cvar).SetString(cvsetting.CVSE_oldval);
	}

	CvarSettingsArray.Clear();
}

static void SetEnforcedCvars()
{
	int iSize = CvarSettingsArray.Length;

	CVSEntry cvsetting;
	for (int i = 0; i < iSize; i++) 
	{
		CvarSettingsArray.GetArray(i, cvsetting, sizeof(cvsetting));

		#if CVARS_DEBUG
			char debug_buffer[CVS_CVAR_MAXLEN];
			(cvsetting.CVSE_cvar).GetName(debug_buffer, sizeof(debug_buffer));
			LogMessage("[%s] cvar = %s, newval = %s", CVS_MODULE_NAME, debug_buffer, cvsetting.CVSE_newval);
		#endif

		(cvsetting.CVSE_cvar).SetString(cvsetting.CVSE_newval);
	}
}

static void AddCvar(const char[] cvar, const char[] newval)
{
	if (bTrackingStarted) 
	{
		#if CVARS_DEBUG
			LogMessage("[%s] Attempt to track new cvar %s during a match!", CVS_MODULE_NAME, cvar);
		#endif
		return;
	}

	if (strlen(cvar) >= CVS_CVAR_MAXLEN) 
	{
		Debug_LogError(CVS_MODULE_NAME, "CVar Specified (%s) is longer than max cvar/value length (%d)", cvar, CVS_CVAR_MAXLEN);
		return;
	}

	if (strlen(newval) >= CVS_CVAR_MAXLEN) 
	{
		Debug_LogError(CVS_MODULE_NAME, "New Value Specified (%s) is longer than max cvar/value length (%d)", newval, CVS_CVAR_MAXLEN);
		return;
	}

	ConVar newCvar = FindConVar(cvar);

	if (newCvar == null) 
	{
		Debug_LogError(CVS_MODULE_NAME, "Could not find CVar specified (%s)", cvar);
		return;
	}

	char cvarBuffer[CVS_CVAR_MAXLEN];
	int iSize = CvarSettingsArray.Length;

	CVSEntry newEntry;

	for (int i = 0; i < iSize; i++) 
	{
		CvarSettingsArray.GetArray(i, newEntry, sizeof(newEntry));

		(newEntry.CVSE_cvar).GetName(cvarBuffer, CVS_CVAR_MAXLEN);

		if (strcmp(cvar, cvarBuffer, false) == 0) {
			Debug_LogError(CVS_MODULE_NAME, "Attempt to track ConVar %s, which is already being tracked.", cvar);
			return;
		}
	}

	newCvar.GetString(cvarBuffer, CVS_CVAR_MAXLEN);

	newEntry.CVSE_cvar = newCvar;
	strcopy(newEntry.CVSE_oldval, CVS_CVAR_MAXLEN, cvarBuffer);
	strcopy(newEntry.CVSE_newval, CVS_CVAR_MAXLEN, newval);

	newCvar.AddChangeHook(CVS_ConVarChange);

#if CVARS_DEBUG
	LogMessage("[%s] cvar = %s, newval = %s, oldval = %s", CVS_MODULE_NAME, cvar, newval, cvarBuffer);
#endif

	CvarSettingsArray.PushArray(newEntry, sizeof(newEntry));
}

static void CVS_ConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (bTrackingStarted) {
		char sName[CVS_CVAR_MAXLEN];
		hConVar.GetName(sName, sizeof(sName));

		PrintToServer("[Confogl] Tracked Server CVar '%s' changed from '%s' to '%s' !!!", sName, sOldValue, sNewValue);
		CPrintToChatAll("%t %t", "Tag", "TrackedChange", sName, sOldValue, sNewValue);
	}
}
