#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo =
{
	name = "[L4D2] Throw Announce",
	author = "blueblur",
	description = "Throwing something.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    CreateConVar("l4d2_throw_announce_version", PLUGIN_VERSION, "Throw Announce Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    LoadTranslation("l4d2_throw_announce.phrases");
}

public void L4D_MolotovProjectile_Post(int client)
{
    if (!IsClientAndInGame(client) || IsFakeClient(client))
        return;

    CPrintToChatAll("%t", "MolotovThrown", client);
}

public void L4D_PipeBombProjectile_Post(int client)
{
    if (!IsClientAndInGame(client) || IsFakeClient(client))
        return;
    
    CPrintToChatAll("%t", "PipeBombThrown", client);
}

public void L4D2_VomitJarProjectile_Post(int client)
{
    if (!IsClientAndInGame(client) || IsFakeClient(client))
        return;

    CPrintToChatAll("%t", "VomitJarThrown", client);
}

bool IsClientAndInGame(int client)
{
	return (client > 0 && client < MaxClients && IsClientInGame(client));
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