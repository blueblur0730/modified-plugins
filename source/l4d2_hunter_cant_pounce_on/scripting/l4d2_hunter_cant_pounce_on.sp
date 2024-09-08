#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define GAMEDATA_FILE	"l4d2_hunter_cant_pounce_on"
#define DETOUR_FUNCTION "CTerrorPlayer::OnLungeStart"
#define PLUGIN_VERSION	"1.0"

ConVar g_hCvar_CanPounceOn = null;
// GlobalForward g_hForward_OnLungeStart = null;

public Plugin myinfo =
{
	name = "[L4D2] Hunter Cant Pounce On",
	author = "blueblur",
	description = "Hunters are trying to pounce on you but they can't.",
	version = PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_hunter_cant_pounce_on_version", PLUGIN_VERSION, "Version of the L4D2 Hunter Cant Pounce On plugin.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvar_CanPounceOn = CreateConVar("l4d2_hunter_cant_pounce_on", "1", "Enable/Disable the hunter to pounce on a survivor.", _, true, 0.0, true, 1.0);

	GameData gd	= new GameData(GAMEDATA_FILE);
	if (!gd)
		SetFailState("Failed to load gamedata file:\"" ... GAMEDATA_FILE... "\".");

	DynamicDetour hDetour = DynamicDetour.FromConf(gd, DETOUR_FUNCTION);
	if (!hDetour)
		SetFailState("Failed to create dynamic detour for \"" ... DETOUR_FUNCTION... "\".");

	if (!hDetour.Enable(Hook_Pre, DTR_CTerrorPlayer_OnLungeStart))
		SetFailState("Failed to enable dynamic detour for \"" ... DETOUR_FUNCTION... "\".");

	delete hDetour;
	delete gd;
}

MRESReturn DTR_CTerrorPlayer_OnLungeStart(int pHunter)
{
	// PrintToServer("### DTR_CTerrorPlayer_OnLungeStart called. client: %d", pHunter);

	return g_hCvar_CanPounceOn.BoolValue ? MRES_Supercede : MRES_Ignored;
}

/*
bool IsHunter(int client)
{
	return (IsPlayerAlive(client)
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 3);
}
*/