#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define CONFIG_PATH "configs/changelog.txt"

KeyValues 
	kv;

ConVar
	cvarEnableStatus,
	cvarReadyUpCfgName,
	cvarAdvertisement,
	cvarAdvertisementInterval,
	cvarShowMOTD;

Handle
	AdTimer;

public Plugin myinfo =
{
	name = "L4D2 Change Log Command",
	description = "Does things :) and show changelog message for each confogl configs.",
	author = "Spoon, blueblur",
	version = "5.0",
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	char sBuffer[128];
	// Cmd
	RegConsoleCmd("sm_info", ChangeLog_CMD);

	// ConVars
	cvarEnableStatus = CreateConVar("sm_enable_changelog", "1", "Enable the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarAdvertisement = CreateConVar("sm_changelog_advertisement", "1", "Enable advertisement function", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarAdvertisementInterval = CreateConVar("sm_changelog_advertisement_interval", "60.0", "Interval that the notice message appears on the chat", _, true, 0.0);
	cvarShowMOTD = CreateConVar("sm_changelog_cmd_show_MOTD", "0", "Type /info to show MOTD?", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Hook
	cvarAdvertisementInterval.AddChangeHook(OnIntervalChanged);

	// KeyValue
	kv = CreateKeyValues("MOTD", "", "");
	BuildPath(Path_SM, sBuffer, 128, CONFIG_PATH);

	if (!FileToKeyValues(kv, sBuffer))
	{
		SetFailState("File %s may be missed!", CONFIG_PATH);
	}

	// Translations
	LoadTranslations("changelog.phrases");
}

public void OnAllPluginsLoaded()
{
	cvarReadyUpCfgName = FindConVar("l4d_ready_cfg_name");
}

public void OnIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(cvarAdvertisement.BoolValue && cvarEnableStatus.BoolValue)
		Timer_Ad();
}

public Action ChangeLog_CMD(int client, int args)
{
	char message[128];
	if(GetLinkString(message, sizeof(message)))
		CPrintToChat(client, "%t", "ChatAnnounce", message);
	else
		CPrintToChat(client, "%t", "NoLink");

	if(cvarShowMOTD.BoolValue)
	{
		char title[128];
		cvarReadyUpCfgName.GetString(title, sizeof(title));
		ShowMOTDPanel(client, title, message, MOTDPANEL_TYPE_URL);
	}

	return Plugin_Handled;
}

void Timer_Ad()
{
    delete AdTimer;
    AdTimer = CreateTimer(cvarAdvertisementInterval.FloatValue, ChangeLog_Timer, _, TIMER_REPEAT);
}

public Action ChangeLog_Timer(Handle Timer)
{
	if (cvarReadyUpCfgName != null && cvarEnableStatus.BoolValue)
	{
		char CfgName[128];
		cvarReadyUpCfgName.GetString(CfgName, sizeof(CfgName));
		CPrintToChatAll("%t", "PleaseTypeIn", CfgName);
	}

	return Plugin_Handled;
}

stock bool GetLinkString(char[] link, int maxlength)
{
	char buffer[128];
	cvarReadyUpCfgName.GetString(buffer, sizeof(buffer));

	KvRewind(kv);
	if(KvJumpToKey(kv, buffer))
	{
		KvGetString(kv, "link", link, maxlength);
		return true;
	}

	return false;
}