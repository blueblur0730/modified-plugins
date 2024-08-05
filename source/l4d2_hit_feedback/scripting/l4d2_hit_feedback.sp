#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <colors>

#define PL_VERSION "1.0"

// Changeable variables are below the defined convars.

// Time for HitMarker to show
ConVar g_hCvTimeForKillMarker, g_hCvTimeForHitMarker;
float g_flTimeForKillMarker, g_flTimeForHitMarker;

// ConVar to enable sound globally
ConVar g_hCvEnableSound;
bool g_bCvEnableSound;

// ConVars for sound path
ConVar g_hCvSoundPathHeadShot, g_hCvSoundPathBodyHit, g_hCvSoundPathKill;
char g_sSoundHeadShot[64], g_sSoundBodyHit[64], g_sSoundKill[64];

// ConVars for defualt sound path
ConVar g_hCvSoundPathHeadShotDefualt, g_hCvSoundPathBodyHitDefualt, g_hCvSoundPathKillDefualt;
char g_sSoundHeadShotDefualt[64], g_sSoundBodyHitDefualt[64], g_sSoundKillDefualt[64];

// ConVars for overlay path
ConVar g_hCvOverlayPathHeadShot, g_hCvOverlayPathBodyHit, g_hCvOverlayPathKill;
char g_sOverlayHeadShot[64], g_sOverlayBodyHit[64], g_sOverlayKill[64];

// ConVars for hit feedbacks on SI
ConVar g_hCvEnableSIKillOverlay, g_hCvEnableSIHitOverlay, g_hCvEnableSIHitSnd, g_hCvEnableSIKillSnd;
bool g_bCvEnableSIKillOverlay, g_bCvEnableSIHitOverlay, g_bCvEnableSIHitSnd, g_bCvEnableSIKillSnd;

// ConVars for hit feedbacks on CI
ConVar g_hCvEnableCIKillOverlay, g_hCvEnableCIHitOverlay, g_hCvEnableCIHitSnd, g_hCvEnableCIKillSnd;
bool g_bCvEnableCIKillOverlay, g_bCvEnableCIHitOverlay, g_bCvEnableCIHitSnd, g_bCvEnableCIKillSnd;

// ConVars for certain damage types
ConVar g_hCvEnableBlast, g_hCvEnableFire, g_hCvEnableMelee;
bool g_bCvEnableBlast, g_bCvEnableFire, g_bCvEnableMelee;

// ConVars for entity sprites
ConVar g_hCvSpriteScale, g_hCvFadeDistance;
char g_sSpriteScale[32], g_sFadeDistance[32];

// ConVars for entity sprite (damage number) resource path.
ConVar g_hCvCustomModelVMT, g_hCvCustomModelVTF;
char g_sCustomModelVMT[64], g_sCustomModelVTF[64];

// Cookie
Cookie g_hCookie;

#define MAX_ENTITIES 2048

// it checks activated weapon of the map. used for events.
int	g_iActiveWO = -1;

// arrays for storing the hit feedback styles per client.
int g_iStyle[MAXPLAYERS + 1] = { 1, ... };

// arrays for entity references.
int g_iSpriteEntRef[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };
int g_iSpriteFrameEntRef[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };

// arrays for entity relations.
int g_iOwner[MAX_ENTITIES + 1] = { -1, ... };
int g_iRelation[MAX_ENTITIES + 1] = { -1, ... };

bool g_bHideSprite[MAXPLAYERS + 1] = { false, ... };

enum 
{
	kill,
	kill_1,
	hit_armor
};

enum
{
	Style_Static,
	Style_Animated,
	Style_None
}

Handle g_hTimerClean[MAXPLAYERS + 1] = { null, ... };

// Modules are defined here.
#include "l4d2_hit_feedback/file.inc"
#include "l4d2_hit_feedback/setup.inc"
#include "l4d2_hit_feedback/menu.inc"
#include "l4d2_hit_feedback/events.inc"
#include "l4d2_hit_feedback/actions.inc"
#include "l4d2_hit_feedback/cookie.inc"
#include "l4d2_hit_feedback/utils.inc"

public Plugin myinfo =
{
	name = "[L4D2] Hit Feedback",
	author = "TsukasaSato, blueblur, Entity References by Mart",
	description = "Customize hit sound and hit marker for L4D2.",
	version	= PL_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only supports \"Left 4 Dead 2\".");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
	SetupConVars();
	RegCookies();
	RegCommands();
	HookEvents();
}

public void OnPluginEnd()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		if (g_hTimerClean[i] != null)
			delete g_hTimerClean[i];
	}
}

public void OnMapStart()
{
	g_iActiveWO	= FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	LoadResources();
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

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEntity(entity))
		return;

	if (strcmp(classname, "infected") == 0)
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnCITakeDamagePost);
}

public void OnEntityDestroyed(int entity)
{
	if (!IsValidEntity(entity))
		return;

	char sClassname[32];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));
	if (strcmp(sClassname, "infected") == 0)
		SDKUnhook(entity, SDKHook_OnTakeDamagePost, OnCITakeDamagePost);
}