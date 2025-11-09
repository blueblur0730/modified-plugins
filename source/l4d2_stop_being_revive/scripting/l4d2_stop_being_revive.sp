#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks_silver>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D2] Stop Being Revive",
	author = "blueblur",
	description = "I don't like you.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_stoprevive", Cmd_StopRevive, "Stop being revived.");
}

Action Cmd_StopRevive(int client, int args)
{
    if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2)
        return Plugin_Handled;

    if (IsBeingRevived(client))
        L4D_StopReviveAction(client);

    return Plugin_Handled;
}

stock bool IsBeingRevived(int client)
{
    return (GetEntPropEnt(client, Prop_Send, "m_reviveOwner") != -1);
}