#if defined __cvar_settings_included
	#endinput
#endif
#define __cvar_settings_included

#define CVS_MODULE_NAME "CvarSettings"

#define CVS_CVAR_MAXLEN 64

enum struct CVSEntry
{
	ConVar CVSE_cvar;
	char   CVSE_oldval[CVS_CVAR_MAXLEN];
	char   CVSE_newval[CVS_CVAR_MAXLEN];
}

static bool
	bTrackingStarted = false;

static ArrayList
	CvarSettingsArray = null;

static ConVar
	 hShouldPrint = null;

void CVS_APL()
{
	CreateNative("LGO_GetTrackedCvars", Native_GetTrackedCvars);	// int LGO_GetTrackedCvars(ArrayList &hCvarArray)
}

void CVS_OnModuleStart()
{
	CvarSettingsArray = new ArrayList(sizeof(CVSEntry));

	RegConsoleCmd("confogl_cvarsettings", CVS_CvarSettings_Cmd, "List all ConVars being enforced by Confogl");
	RegConsoleCmd("confogl_cvardiff", CVS_CvarDiff_Cmd, "List any ConVars that have been changed from their initialized values");

	RegServerCmd("confogl_addcvar", CVS_AddCvar_Cmd, "Add a ConVar to be set by Confogl");
	RegServerCmd("confogl_setcvars", CVS_SetCvars_Cmd, "Starts enforcing ConVars that have been added.");
	RegServerCmd("confogl_resetcvars", CVS_ResetCvars_Cmd, "Resets enforced ConVars.  Cannot be used during a match!");

	hShouldPrint = CreateConVarEx("cvarchange_shouldprint", "1", "Whether or not to print changes to ConVars", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

void CVS_OnModuleEnd()
{
	ClearAllSettings();
	delete CvarSettingsArray;
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
		g_hLogger_ServerConsole.Info("[Confogl] Tracking has already been started");
		return Plugin_Handled;
	}

	g_hLogger.InfoEx("[%s] No longer accepting new ConVars", CVS_MODULE_NAME);

	SetEnforcedCvars();
	bTrackingStarted = true;

	return Plugin_Handled;
}

static Action CVS_AddCvar_Cmd(int args)
{
	if (args != 2)
	{
		g_hLogger_ServerConsole.Info("Usage: confogl_addcvar <cvar> <newValue>");

		if (g_hLogger.GetLevel() <= LogLevel_Warn)
		{
			char cmdbuf[MAX_NAME_LENGTH];
			GetCmdArgString(cmdbuf, sizeof(cmdbuf));
			g_hLogger.WarnEx("[%s] Invalid Cvar Add: %s", CVS_MODULE_NAME, cmdbuf);
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
		g_hLogger_ServerConsole.Info("[Confogl] Can't reset tracking in the middle of a match");
		return Plugin_Handled;
	}

	ClearAllSettings();
	g_hLogger_ServerConsole.Info("[Confogl] Server CVar Tracking Information Reset!");

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
	int	 cvscount = CvarSettingsArray.Length;

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
	int	 cvscount = CvarSettingsArray.Length;

	GetCmdArg(1, buffer, sizeof(buffer));
	int offset = StringToInt(buffer);

	if (offset > cvscount)
		return Plugin_Handled;

	int		 foundCvars = 0;

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
	int		 iSize	 = CvarSettingsArray.Length;
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
	int		 iSize = CvarSettingsArray.Length;

	CVSEntry cvsetting;
	for (int i = 0; i < iSize; i++)
	{
		CvarSettingsArray.GetArray(i, cvsetting, sizeof(cvsetting));

		if (g_hLogger.GetLevel() <= LogLevel_Debug)
		{
			char debug_buffer[CVS_CVAR_MAXLEN];
			(cvsetting.CVSE_cvar).GetName(debug_buffer, sizeof(debug_buffer));
			g_hLogger.DebugEx("[%s] cvar = %s, newval = %s", CVS_MODULE_NAME, debug_buffer, cvsetting.CVSE_newval);
		}

		(cvsetting.CVSE_cvar).SetString(cvsetting.CVSE_newval);
	}
}

static void AddCvar(const char[] cvar, const char[] newval)
{
	if (bTrackingStarted)
	{
		g_hLogger.WarnEx("[%s] Attempt to track new cvar %s during a match!", CVS_MODULE_NAME, cvar);
		return;
	}

	if (strlen(cvar) >= CVS_CVAR_MAXLEN)
	{
		g_hLogger.ErrorEx("[%s] CVar Specified (%s) is longer than max cvar/value length (%d)", CVS_MODULE_NAME, cvar, CVS_CVAR_MAXLEN);
		return;
	}

	if (strlen(newval) >= CVS_CVAR_MAXLEN)
	{
		g_hLogger.ErrorEx("[%s] New Value Specified (%s) is longer than max cvar/value length (%d)", CVS_MODULE_NAME, newval, CVS_CVAR_MAXLEN);
		return;
	}

	ConVar newCvar = FindConVar(cvar);

	if (newCvar == null)
	{
		g_hLogger.ErrorEx("[%s] Could not find CVar specified (%s)", CVS_MODULE_NAME, cvar);
		return;
	}

	char	 cvarBuffer[CVS_CVAR_MAXLEN];
	int		 iSize = CvarSettingsArray.Length;

	CVSEntry newEntry;

	for (int i = 0; i < iSize; i++)
	{
		CvarSettingsArray.GetArray(i, newEntry, sizeof(newEntry));

		(newEntry.CVSE_cvar).GetName(cvarBuffer, CVS_CVAR_MAXLEN);

		if (strcmp(cvar, cvarBuffer, false) == 0)
		{
			g_hLogger.WarnEx("[%s] Attempt to track ConVar %s, which is already being tracked.", CVS_MODULE_NAME, cvar);
			return;
		}
	}

	newCvar.GetString(cvarBuffer, CVS_CVAR_MAXLEN);

	newEntry.CVSE_cvar = newCvar;
	strcopy(newEntry.CVSE_oldval, CVS_CVAR_MAXLEN, cvarBuffer);
	strcopy(newEntry.CVSE_newval, CVS_CVAR_MAXLEN, newval);
	newCvar.AddChangeHook(CVS_ConVarChange);

	g_hLogger.DebugEx("[%s] cvar = %s, newval = %s, oldval = %s", CVS_MODULE_NAME, cvar, newval, cvarBuffer);
	CvarSettingsArray.PushArray(newEntry, sizeof(newEntry));
}

static void CVS_ConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (bTrackingStarted && hShouldPrint.BoolValue)
	{
		char sName[CVS_CVAR_MAXLEN];
		hConVar.GetName(sName, sizeof(sName));

		g_hLogger_ServerConsole.InfoEx("[Confogl] Tracked Server CVar '%s' changed from '%s' to '%s' !!!", sName, sOldValue, sNewValue);
		CPrintToChatAll("%t %t", "Tag", "TrackedChange", sName, sOldValue, sNewValue);
	}
}

static int Native_GetTrackedCvars(Handle plugin, int numParams)
{
	if (!bTrackingStarted)
		return -1;

	SetNativeCellRef(1, CvarSettingsArray);
	return CvarSettingsArray.Length;
}
