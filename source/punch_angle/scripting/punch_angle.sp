#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <clientprefs>

#define PLUGIN_VERSION 		"1.2"
#define GAMEDATA_FILE  		"punch_angle"
#define COOKIE_NAME	   		"punch_angle_cookie"
#define TRANSLATION_FILE 	"punch_angle.phrases"

ConVar
	g_cvZGunVerticalPu,
	g_cvToggle;

Cookie g_hCookie = null;

public Plugin myinfo =
{
	name = "[L4D2] Punch Angle",
	author = "sorallll, blueblur",
	description = "Remove recoil when shooting and getting hit.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

bool g_bEnable = true;
bool g_bClientCookie[MAXPLAYERS + 1] = { false, ... };

// Startup
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion version = GetEngineVersion();
	if (version != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
		return APLRes_SilentFailure;
	}

	// API
	RegPluginLibrary("punch_angle");
	return APLRes_Success;
}

public void OnPluginStart()
{
	IniGameData();
	LoadTranslation(TRANSLATION_FILE);
	CreateConVar("punch_angle_version", PLUGIN_VERSION, "Version of the Punch Angle plugin.", FCVAR_NOTIFY | FCVAR_DEVELOPMENTONLY | FCVAR_DONTRECORD);

	g_hCookie = new Cookie(COOKIE_NAME, "Toggles recoil on or off.", CookieAccess_Protected);
	g_hCookie.SetPrefabMenu(CookieMenu_OnOff, "Punch Angle Toggle", CookieSelected, g_hCookie);

	// this cvar reduces recoil when shooting.
	g_cvZGunVerticalPu			= FindConVar("z_gun_vertical_punch");
	g_cvZGunVerticalPu.IntValue = 0;
	g_cvToggle					= CreateConVar("punch_angle_toggle", "1", "Toggles recoil on or off.", _, true, 0.0, true, 1.0);
	g_cvToggle.AddChangeHook(OnToggle);
	g_bEnable = g_cvToggle.BoolValue;
}

public void OnPluginEnd()
{
	// prevent this from replicating to clients.
	g_cvZGunVerticalPu.RestoreDefault(true, false);
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;

	char value[4];
	g_hCookie.Get(client, value, sizeof(value));

	if (value[0] == '\0')
	{
		g_hCookie.Set(client, "On");
		g_cvZGunVerticalPu.ReplicateToClient(client, "0");
		g_bClientCookie[client] = true;
	}

	if (StrEqual(value, "On"))
	{
		g_cvZGunVerticalPu.ReplicateToClient(client, "0");
		g_bClientCookie[client] = true;
	}
	else if (StrEqual(value, "Off"))
	{
		g_cvZGunVerticalPu.ReplicateToClient(client, "1");
		g_bClientCookie[client] = false;
	}
}

void CookieSelected(int client, CookieMenuAction action, Cookie info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		PrintToChat(client, "%t", "Select");
	}
	else
	{
		char value[4];
		info.Get(client, value, sizeof(value));
		PrintToChat(client, "%t", "CookieSlected", value);	  // Punch Angle Toggle: %s
	}
}

// This removed recoil when you are getting hit.
MRESReturn DD_CBasePlayer_SetPunchAngle_Pre(int pThis, DHookReturn hReturn)
{
	/*if (pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis))
		return MRES_Ignored;*/

	if (GetClientTeam(pThis) != 2 || !IsPlayerAlive(pThis))
		return MRES_Ignored;

	if (g_bEnable && g_bClientCookie[pThis])
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

void OnToggle(ConVar convar, char[] old_value, char[] new_value)
{
	g_bEnable = convar.BoolValue;
}

void IniGameData()
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", GAMEDATA_FILE);
	if (!FileExists(buffer))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);

	GameData hGameData = new GameData(GAMEDATA_FILE);
	if (!hGameData)
		SetFailState("Failed to load gamedata file \"" ... GAMEDATA_FILE... "\".");

	DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "DD::CBasePlayer::SetPunchAngle");
	if (!hDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CBasePlayer::SetPunchAngle\"");

	if (!hDetour.Enable(Hook_Pre, DD_CBasePlayer_SetPunchAngle_Pre))
		SetFailState("Failed to detour pre: \"DD::CBasePlayer::SetPunchAngle\"");

	delete hDetour;
	delete hGameData;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}