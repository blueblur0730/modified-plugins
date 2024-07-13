#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.2"
#define KV_PATH "configs/map_configs.txt"
#define MAX_MESSAGE_LENGTH 250

char 
    g_sFilePath[128],
    g_sMapName[MAX_MESSAGE_LENGTH];

ArrayList g_hArrayCfg;

ConVar g_hCvarRestore;

bool g_bIsMapEnd = false;

public Plugin myinfo = 
{
	name = "[ANY] Map Configs",
	author = "blueblur",
	version = PLUGIN_VERSION,
    description = "Configuration excutor for specified map via keyvalue.",
    url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    CreateConVar("map_configs_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    g_hCvarRestore = CreateConVar("map_configs_restore", "1", "Restore the cvars changed on map end? (requires configs prepared by yourself)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), KV_PATH);
}

public void OnMapStart()
{
    g_bIsMapEnd = false;
    GetCurrentMap(g_sMapName, sizeof(g_sMapName));
    GetSectionCfg(g_bIsMapEnd);
    ExecuteCfg();
}

public void OnMapEnd()
{
    if (g_hCvarRestore.BoolValue)
    {
        g_bIsMapEnd = true;
        GetSectionCfg(g_bIsMapEnd);
        ExecuteCfg();
    }
}

void GetSectionCfg(bool bIsMapEnd)
{
    char sBuffer[MAX_MESSAGE_LENGTH];

    KeyValues Kv = new KeyValues("Execute");
    Kv.SetEscapeSequences(true);

    if (!Kv.ImportFromFile(g_sFilePath))
		SetFailState("Failed to load: %s", g_sFilePath);

    Format(sBuffer, sizeof(sBuffer), "%s/%s", g_sMapName, bIsMapEnd ? "restore" : "change");

    if (Kv.JumpToKey(sBuffer) && Kv.GotoFirstSubKey(false))
    {
        if (g_hArrayCfg == null)
            g_hArrayCfg = new ArrayList(ByteCountToCells(MAX_MESSAGE_LENGTH));

        do
        {
			Kv.GetString(NULL_STRING, sBuffer, sizeof(sBuffer));
			g_hArrayCfg.PushString(sBuffer);
        }
        while (Kv.GotoNextKey(false));
    }

    delete Kv;
}

void ExecuteCfg()
{
    if (!g_hArrayCfg || !g_hArrayCfg.Length)
        return;

    char sBuffer[MAX_MESSAGE_LENGTH];
    for (int i = 0; i < g_hArrayCfg.Length; i++)
    {
        g_hArrayCfg.GetString(i, sBuffer, sizeof(sBuffer));
        ServerCommand("exec %s", sBuffer);
    }

    delete g_hArrayCfg;
}