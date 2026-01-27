#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <gamedata_wrapper>

#define GAMEDATA_FILE "l4d2_inputkill_block"
#define DETOUR_INPUTKILL "CBaseEntity::InputKill"
#define DETOUR_INPUTKILLHIERARCHY "CBaseEntity::InputKillHierarchy"

#define PLUGIN_VERSION "1.3"
ConVar g_hCvar_ShouldKickBot;

public Plugin myinfo = 
{
	name = "[L4D2] InputKill Block",
	author = "blueblur",
	description = "I'm not a bot you stupid! >.<",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_inputkill_block_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvar_ShouldKickBot = CreateConVar("l4d2_inputkill_block_kickbot", "1", "Should prevent bots from being kicked?", _, true, 0.0, true, 1.0);

	GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);
	gd.CreateDetourOrFailEx(DETOUR_INPUTKILL, DTR_CBaseEntity_InputKill);
	gd.CreateDetourOrFailEx(DETOUR_INPUTKILLHIERARCHY, DTR_CBaseEntity_InputKillHierarchy);
}

MRESReturn DTR_CBaseEntity_InputKill(int pThis)
{
	return CheckPlayer(pThis) ? MRES_Supercede : MRES_Ignored;
}

MRESReturn DTR_CBaseEntity_InputKillHierarchy(int pThis)
{
	return CheckPlayer(pThis) ? MRES_Supercede : MRES_Ignored;
}

bool CheckPlayer(int client)
{
	// not a client, let the input kills.
	// not taking the world into account.
	if (client < 0 || client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	// we only want to kick bots.
	if (IsFakeClient(client))
	{
		// bot lives matter.
		if (g_hCvar_ShouldKickBot.BoolValue)
			return true;

		// or you are just an idle human? if so, dont let the input kills you.
		int target = GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
		if (target >= 1 && target <= MaxClients) 
			return true;

		// you are bot.
		return false;
	}

	// a human player. dont let the input kills you.
	return true;
}