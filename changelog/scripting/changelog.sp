#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define CONFIG_PATH "configs/changelog.txt"

KeyValues 
	kv;

ConVar
	cvarReadyUpCfgName;

public Plugin myinfo =
{
	name = "L4D2 Change Log Command",
	description = "Does things :) and show changelog message for each confogl configs.",
	author = "Spoon, blueblur",
	version = "4.0",
	url = "https://github.com/spoon-l4d2/"
};

public void OnPluginStart()
{
	char g_sBuffer[128];
	RegConsoleCmd("sm_info", ChangeLog_CMD);
	//linkCVar = CreateConVar("l4d2_cl_link", "https://github.com/spoon-l4d2/NextMod", "The to your change log");
	kv = CreateKeyValues("MOTD", "", "");
	BuildPath(Path_SM, g_sBuffer, 128, CONFIG_PATH);

	if (!FileToKeyValues(kv, g_sBuffer))
	{
		SetFailState("File %s may be missed!", CONFIG_PATH);
	}

	LoadTranslations("changelog.phrases");
}

public void OnAllPluginsLoaded()
{
	cvarReadyUpCfgName = FindConVar("l4d_ready_cfg_name");
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
	return Plugin_Handled;
}