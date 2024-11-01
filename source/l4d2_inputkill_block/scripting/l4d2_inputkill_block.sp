#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA_FILE "l4d2_inputkill_block"
#define DETOUR_INPUTKILL "CBaseEntity::InputKill"
#define DETOUR_INPUTKILLHIERARCHY "CBaseEntity::InputKillHierarchy"
#define TEAM_SURVIVOR 2
#define TEAM_L4D1_SURVIVORS 4

#define PLUGIN_VERSION "1.0"

DynamicDetour g_hDTR_InputKill = null;
DynamicDetour g_hDTR_InputKillHierarchy = null;

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

	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd) SetFailState("Failed to load gamedata file \""...GAMEDATA_FILE..."\".");

	g_hDTR_InputKill = DynamicDetour.FromConf(gd, DETOUR_INPUTKILL);
	if (!g_hDTR_InputKill) SetFailState("Failed to create detour for \""...DETOUR_INPUTKILL..."\".");

	g_hDTR_InputKillHierarchy = DynamicDetour.FromConf(gd, DETOUR_INPUTKILLHIERARCHY);
	if (!g_hDTR_InputKillHierarchy) SetFailState("Failed to create detour for \""...DETOUR_INPUTKILLHIERARCHY..."\".");

	delete gd;

	if (!g_hDTR_InputKill.Enable(Hook_Pre, DTR_CBaseEntity_InputKill))
		SetFailState("Failed to enable detour \""...DETOUR_INPUTKILL..."\".");

	if (!g_hDTR_InputKillHierarchy.Enable(Hook_Pre, DTR_CBaseEntity_InputKillHierarchy))
		SetFailState("Failed to enable detour \""...DETOUR_INPUTKILLHIERARCHY..."\".");
}

public void OnPluginEnd()
{
	if (g_hDTR_InputKill)
	{
		g_hDTR_InputKill.Disable(Hook_Pre, DTR_CBaseEntity_InputKill);
		delete g_hDTR_InputKill;
	} 

	if (g_hDTR_InputKillHierarchy)
	{
		g_hDTR_InputKillHierarchy.Disable(Hook_Pre, DTR_CBaseEntity_InputKillHierarchy);
		delete g_hDTR_InputKillHierarchy;
	} 
}

// we just dont want this to kick a human survivor player.
MRESReturn DTR_CBaseEntity_InputKill(int pThis)
{
	if (CheckThis(pThis))
		return MRES_Supercede;
		
	return MRES_Ignored;
}

MRESReturn DTR_CBaseEntity_InputKillHierarchy(int pThis)
{
	if (CheckThis(pThis))
		return MRES_Supercede;
		
	return MRES_Ignored;
}

bool CheckThis(int client)
{
	// a human survivor player, kepp it going.
	if (IsHumanSurvivor(client))
		return false;

	// else it's a L4D1 Survivor bot or fake survivor bot, skip it.
	return true;
}

bool IsHumanSurvivor(int client)
{
	if (client < 1 || client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (GetClientTeam(client) != TEAM_SURVIVOR)	
		return false;

	// a human survivor player.
	if (!IsFakeClient(client))
		return true;

	// here is an exception for L4D1 survivors. this is the bot that should be kicked.
	if (IsFakeClient(client) && GetClientTeam(client) == TEAM_L4D1_SURVIVORS)
		return false;

	// what if you are just an idle bot?
	if (IsFakeClient(client))
	{
		int target = GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
		if (target < 1 || target > MaxClients) 
			return false;
	}

	// alright you are an idle bot.
	return true;
}
