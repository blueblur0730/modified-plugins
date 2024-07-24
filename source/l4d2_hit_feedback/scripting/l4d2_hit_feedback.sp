#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define PL_VERSION "1.0"

// ConVars for enable or not
ConVar g_hCvEnable, g_hCvEnableSound, g_hCvEnableInfectedPic, g_hCvEnableInfKillPic, g_hCvEnableInfHitPic;

// Resources Path ConVars
ConVar g_hCvSoundPathHeadShot, g_hCvSoundPathBodyHit, g_hCvSoundPathKill, g_hCvSoundPathHeadShotDefualt, g_hCvSoundPathBodyHitDefualt, g_hCvSoundPathKillDefualt,
	g_hCvPicPathHeadShot, g_hCvPicPathBodyHit, g_hCvPicPathKill, g_hCvPicPathBodyHitAuto;

// Time for HitMarker to show
ConVar g_hCvTimeForKillMarker, g_hCvTimeForHitMarker;

// ConVars for conditions
ConVar g_hCvEnableBlast, g_hCvEnableFire, g_hCvEnableOnInfectedHit, g_hCvEnableOnInfectedKill, g_hCvEnableMelee;

// Cookies
Cookie g_hStyleCookie;

int	g_iActiveWO = -1;

int g_iStyle[MAXPLAYERS + 1] = { 1, ... };

char g_sSoundHeadShot[64], g_sSoundBodyHit[64], g_sSoundKill[64];
char g_sSoundHeadShotDefualt[64], g_sSoundBodyHitDefualt[64], g_sSoundKillDefualt[64];

char g_sPic1[32], g_sPic2[32], g_sPic3[32], g_sPic4[32];

enum 
{
	kill_1,
	hit_armor,
	kill,
	hit_armor_1
};

Handle g_hTimerClean[MAXPLAYERS + 1] = { null, ... };
bool   IsVictimDeadPlayer[MAXPLAYERS + 1] = { false, ... };

#include "l4d2_hit_feedback/setup.inc"
#include "l4d2_hit_feedback/commands.inc"
#include "l4d2_hit_feedback/events.inc"
#include "l4d2_hit_feedback/actions.inc"
#include "l4d2_hit_feedback/cookies.inc"

public Plugin myinfo =
{
	name = "[L4D2] Hit Feedback",
	author = "TsukasaSato, blueblur",
	description = "Customize hit sound and hit marker for L4D2.",
	version	= PL_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	SetupConVars();
	RegCookies();
	RegCommands();
	HookEvents();
}

public void OnMapStart()
{
	g_iActiveWO	= FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	PreCacheResources();
}

public void OnPluginEnd()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		if (g_hTimerClean[i] != null)
			delete g_hTimerClean[i];
	}
}

public void OnMapEnd()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		if (g_hTimerClean[i] != null)
			delete g_hTimerClean[i];
	}
}

public void OnClientDisconnect(int client)
{
	SetClientCookies(client);
}

public void OnClientDisconnect_Post(int client)
{
	if (g_hTimerClean[client] != null)
		delete g_hTimerClean[client];
}

public void OnClientCookiesCached(int client)
{
	ReadClientCookies(client);
}

public void OnClientPutInServer(int client)
{
	if (AreClientCookiesCached(client))
		ReadClientCookies(client);
}