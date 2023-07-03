#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
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
	version = "4.3",
	url = "https://github.com/spoon-l4d2/"
};

public void OnPluginStart()
{
	char g_sBuffer[128];
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
	BuildPath(Path_SM, g_sBuffer, 128, CONFIG_PATH);

	if (!FileToKeyValues(kv, g_sBuffer))
	{
		SetFailState("File %s may be missed!", CONFIG_PATH);
	}

	// Translations
	LoadTranslations("changelog.phrases");

	// Check Enable Status
	CheckEnableStatus();
}

public Action CheckEnableStatus()
{
	if(!GetConVarBool(cvarEnableStatus))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnAllPluginsLoaded()
{
	cvarReadyUpCfgName = FindConVar("l4d_ready_cfg_name");
}

public void OnIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(GetConVarBool(cvarAdvertisement))
	{
		Timer_Ad();
	}
}

public void GetLinkString(char[] link, int maxlength)
{
	char buffer[128];
	GetConVarString(cvarReadyUpCfgName, buffer, sizeof(buffer));
	KvRewind(kv);
	if(KvJumpToKey(kv, buffer))
	{
		KvGetString(kv, "link", link, maxlength);
	}
	else
	{
		Format(link, maxlength, "%t", "Empty");
	}
}

public Action ChangeLog_CMD(int client, int args)
{
	char message[128];
	GetLinkString(message, sizeof(message));
	CPrintToChat(client, "%t", "ChatAnnounce", message);
	// {blue}[{green}ChangeLog{blue}]{default} For more infomation, pleases check out the {orange}link {default}below:\n%s

	// MOTD
	if(GetConVarBool(cvarShowMOTD))
	{
		char title[128];
		GetConVarString(cvarReadyUpCfgName, title, sizeof(title));
		ShowMOTDPanel(client, title, message, MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}

public Action ChangeLog_Timer(Handle Timer)
{
	char CfgName[128];
	GetConVarString(cvarReadyUpCfgName, CfgName, sizeof(CfgName));
	CPrintToChatAll("%t", "PleaseTypeIn", CfgName);
	return Plugin_Handled;
}

void Timer_Ad()
{
    delete AdTimer;
    AdTimer = CreateTimer(float(cvarAdvertisementInterval.IntValue), ChangeLog_Timer, _, TIMER_REPEAT);
}
