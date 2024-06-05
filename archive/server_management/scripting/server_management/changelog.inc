#if defined _server_management_changelog_included
 #endinput
#endif
#define _server_management_changelog_included

#define TRANSLATIONS_CHANGELOG         "changelog.phrases"
#define CHANGELOG_CONFIG_PATH          "configs/changelog.txt"

static KeyValues 
	kv;

static Handle
	AdTimer;

/* changelog */
static ConVar
    cl_cvEnableStatus, cl_cvAdvertisement, cl_cvAdvertisementInterval, cl_cvShowMOTD;

/* plugin cvar */
static ConVar
    cl_cvReadyUpCfgName = null;

void CL_OnPluginStart()
{
	char sBuffer[128];
	// Cmd
	RegConsoleCmd("sm_config", ChangeLog_CMD);

	// ConVars
	cl_cvEnableStatus = CreateConVar("sm_enable_changelog", "1", "Enable the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cl_cvAdvertisement = CreateConVar("sm_changelog_advertisement", "1", "Enable advertisement function", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cl_cvAdvertisementInterval = CreateConVar("sm_changelog_advertisement_interval", "60.0", "Interval that the notice message appears on the chat", _, true, 0.0);
	cl_cvShowMOTD = CreateConVar("sm_changelog_cmd_show_MOTD", "0", "Type /info to show MOTD?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Hook
	cl_cvAdvertisementInterval.AddChangeHook(OnIntervalChanged);

	// KeyValue
	kv = CreateKeyValues("MOTD", "", "");
	BuildPath(Path_SM, sBuffer, 128, CHANGELOG_CONFIG_PATH);

	if (!FileToKeyValues(kv, sBuffer))
	{
		SetFailState("File %s may be missed!", CHANGELOG_CONFIG_PATH);
	}

	// Translations
	LoadTranslations("changelog.phrases");
}

void CL_OnAllPluginsLoaded()
{
	cl_cvReadyUpCfgName = FindConVar("l4d_ready_cfg_name");
}

public void OnIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(cl_cvAdvertisement.BoolValue && cl_cvEnableStatus.BoolValue)
		Timer_Ad();
}

public Action ChangeLog_CMD(int client, int args)
{
	char message[128];
	if(GetLinkString(message, sizeof(message)))
		CPrintToChat(client, "%t", "ChatAnnounce", message);
	else
		CPrintToChat(client, "%t", "NoLink");

	if(cl_cvShowMOTD.BoolValue)
	{
		char title[128];
		cl_cvReadyUpCfgName.GetString(title, sizeof(title));
		ShowMOTDPanel(client, title, message, MOTDPANEL_TYPE_URL);
	}

	return Plugin_Handled;
}

void Timer_Ad()
{
    delete AdTimer;
    AdTimer = CreateTimer(cl_cvAdvertisementInterval.FloatValue, ChangeLog_Timer, _, TIMER_REPEAT);
}

public Action ChangeLog_Timer(Handle Timer)
{
	if (cl_cvReadyUpCfgName != null && cl_cvEnableStatus.BoolValue)
	{
		char CfgName[128];
		cl_cvReadyUpCfgName.GetString(CfgName, sizeof(CfgName));
		CPrintToChatAll("%t", "PleaseTypeIn", CfgName);
	}

	return Plugin_Handled;
}

stock bool GetLinkString(char[] link, int maxlength)
{
	char buffer[128];
	cl_cvReadyUpCfgName.GetString(buffer, sizeof(buffer));

	KvRewind(kv);
	if(KvJumpToKey(kv, buffer))
	{
		KvGetString(kv, "link", link, maxlength);
		return true;
	}

	return false;
}