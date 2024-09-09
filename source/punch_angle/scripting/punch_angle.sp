#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION			"1.1.0"
#define GAMEDATA				"punch_angle"

ConVar
	g_cvZGunVerticalPu,
	g_cvToggle;

public Plugin myinfo = 
{
	name = "[L4D2] Punch Angle",
	author = "sorallll, blueblur",
	description = "Remove recoil when shooting and getting hit.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

bool g_bEnable = true;

//Startup
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion version = GetEngineVersion();
	if (version != Engine_Left4Dead2)
	{
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
	}

	//API
	RegPluginLibrary("punch_angle");
	return APLRes_Success;
}

public void OnPluginStart() 
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(buffer))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, "DD::CBasePlayer::SetPunchAngle");
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CBasePlayer::SetPunchAngle\"");

	if (!dDetour.Enable(Hook_Pre, DD_CBasePlayer_SetPunchAngle_Pre))
		SetFailState("Failed to detour pre: \"DD::CBasePlayer::SetPunchAngle\"");

	delete hGameData;

	g_cvZGunVerticalPu = FindConVar("z_gun_vertical_punch");
	g_cvToggle = CreateConVar("punch_angle_toggle", "1", "Toggles recoil on or off.", _, true, 0.0, true, 1.0);
	g_cvToggle.AddChangeHook(OnToggle);
	g_bEnable = g_cvToggle.BoolValue;
}

public void OnPluginEnd() 
{
	g_cvZGunVerticalPu.RestoreDefault();
}

// reduce recoil when getting hit by zombies.
public void OnConfigsExecuted() 
{
	g_cvZGunVerticalPu.IntValue = 0;
}

MRESReturn DD_CBasePlayer_SetPunchAngle_Pre(int pThis, DHookReturn hReturn, DHookParam hParams) 
{
	/*if (pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis))
		return MRES_Ignored;*/

	if (GetClientTeam(pThis) != 2 || !IsPlayerAlive(pThis))
		return MRES_Ignored;

	if (g_bEnable)
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

void OnToggle(ConVar convar, char[] old_value, char[] new_value)
{
	g_bEnable = convar.BoolValue;

	if (g_bEnable) g_cvZGunVerticalPu.IntValue = 0;
	else g_cvZGunVerticalPu.IntValue = 1;
}