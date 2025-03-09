#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

#define CFG_PATH "data/sm_advertisement.cfg"

#define AD_SEQUENTIAL	0
#define AD_RANDOM		1

ConVar g_hCvar_PrintType, g_hCvar_Time, g_hCvar_CfgPath;
ArrayList g_aAdList = null;
Handle g_hTimer = null;
int g_iPrintType;
float g_fTime;
char g_sCfgPath[PLATFORM_MAX_PATH];
bool g_bLate = false;

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo =
{
	name = "[ANY] Advertisement",
	author = "Tsunami, fdxx, blueblur",
	description = "Advertisement with translation and server port specified.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("sm_advertisements_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    LoadTranslation("sm_advertisement.phrases");
	g_hCvar_PrintType = CreateConVar("sm_advertisements_type", "0", "Print type. 0=Sequential, 1=Random");
	g_hCvar_Time = CreateConVar("sm_advertisements_time", "120.0", "Print interval time");
	g_hCvar_CfgPath = CreateConVar("sm_advertisements_cfg", CFG_PATH, "config file path");

	OnConVarChanged(null, "", "");

	g_hCvar_PrintType.AddChangeHook(OnConVarChanged);
	g_hCvar_Time.AddChangeHook(OnConVarChanged);
	g_hCvar_CfgPath.AddChangeHook(OnConVarChanged);

	RegAdminCmd("sm_adreload", Cmd_AdReload, ADMFLAG_CONFIG);
	RegAdminCmd("sm_adreprint", Cmd_AdRePrint, ADMFLAG_CONFIG);

	LoadAdvertisements();

	if (g_bLate)
	{
		if (g_fTime >= 0.1)
			g_hTimer = CreateTimer(g_fTime, PrintAd_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnPluginEnd()
{
	if (g_hTimer != INVALID_HANDLE) 
    {
		g_hTimer = null;
        delete g_hTimer;
    }
}

public void OnMapStart()
{
	if (g_fTime >= 0.1)
		g_hTimer = CreateTimer(g_fTime, PrintAd_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPrintType = g_hCvar_PrintType.IntValue;
	g_fTime = g_hCvar_Time.FloatValue;
	g_hCvar_CfgPath.GetString(g_sCfgPath, sizeof(g_sCfgPath));

	if (convar == g_hCvar_CfgPath)
		LoadAdvertisements();
}

void LoadAdvertisements()
{
	char sBuffer[MAX_MESSAGE_LENGTH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "%s", g_sCfgPath);

	KeyValues kv = new KeyValues("");
	kv.SetEscapeSequences(true); // Allow newline characters to be read.

	if (!kv.ImportFromFile(sBuffer))
    {
        delete kv;
		LogError("Failed to load: %s", sBuffer);
        return;
    }

	FindConVar("hostport").GetString(sBuffer, sizeof(sBuffer)); // Get config by port
	Format(sBuffer, sizeof(sBuffer), "%s/advertisements", sBuffer);

	if (kv.JumpToKey(sBuffer) && kv.GotoFirstSubKey(false))
	{
		if (g_aAdList) delete g_aAdList;
		g_aAdList = new ArrayList(ByteCountToCells(MAX_MESSAGE_LENGTH));

		do
		{
			kv.GetString(NULL_STRING, sBuffer, sizeof(sBuffer));
			g_aAdList.PushString(sBuffer);
		}
		while (kv.GotoNextKey(false));
	}

	delete kv;
}

void PrintAd_Timer(Handle timer)
{
	if (!g_aAdList || !g_aAdList.Length)
		return;

	char buffer[MAX_MESSAGE_LENGTH];
	char time[128], sMap[128];
	char sTranlated[MAX_MESSAGE_LENGTH];
	FormatTime(time, sizeof(time), "%F %T");
    GetCurrentMap(sMap, sizeof(sMap));
    g_aAdList.GetString(GetIndex(), buffer, sizeof(buffer));

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;

        Format(sTranlated, sizeof(sTranlated), "%T", buffer, i);
	    ReplaceString(sTranlated, sizeof(sTranlated), "{time}", time);
        ReplaceString(sTranlated, sizeof(sTranlated), "{map}", sMap);
	    CPrintToChat(i, "%s", sTranlated);
    }
}

int GetIndex()
{
	if (g_iPrintType == AD_RANDOM)
		return GetRandomIntEx(0, g_aAdList.Length-1);

	if (g_iPrintType == AD_SEQUENTIAL)
	{
		int index = -1;
		if (++index >= g_aAdList.Length)
			index = 0;
		return index;
	}

	return -1;
}

stock int GetRandomIntEx(int min, int max)
{
	return GetURandomInt() % (max - min + 1) + min;
}

Action Cmd_AdReload(int client, int args)
{
	LoadAdvertisements();
	return Plugin_Handled;
}

Action Cmd_AdRePrint(int client, int args)
{
	if (g_hTimer != INVALID_HANDLE) KillTimer(g_hTimer);

	if (g_fTime >= 0.1)
		g_hTimer = CreateTimer(g_fTime, PrintAd_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
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