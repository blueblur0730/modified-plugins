#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define PLUGIN_VERSION "3.0"
#define CONFIG_PATH	"configs/l4d2_scav_gascan_selfburn.txt"

#define DEBUG 0
#define MAX_ENTITIES 2048

ConVar
	g_hcvarEnableLimit,
	g_hcvarBurnLimit;

StringMap g_hCoordinateMap;
Handle g_hTimer[MAX_ENTITIES] = {null, ...};

bool g_bEnableLimit, g_bIsOutBound[MAX_ENTITIES];
int g_iBurnLimit, g_iBurnedCount = 0;

char g_sPath[128];
bool g_bLateLoad;

public Plugin myinfo =
{
	name = "[L4D2] Scavenge Gascan Self Burn",
	author = "ratchetx, blueblur",
	description = "Burn unreachable gascans with custom settings in scavenge mode.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_scav_gascan_selfburn_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hcvarEnableLimit = CreateConVar("l4d2_scav_gascan_burned_limit_enable", "0", "Enable Limited Gascan burn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarBurnLimit = CreateConVar("l4d2_scav_gascan_burned_limit", "4", "Limits the max amount of gascan that can get burned if they are out of bounds.", FCVAR_NOTIFY, true, 0.0);

	g_hcvarEnableLimit.AddChangeHook(OnCvarChanged);
	g_hcvarBurnLimit.AddChangeHook(OnCvarChanged);
	SetCvar();

	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), CONFIG_PATH);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	LoadTranslations("l4d2_scav_gascan_selfburn.phrases");

	if (g_bLateLoad)
	{
		OnMapStart_Post();
		HookEntityPost();
	}
}

void OnCvarChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	SetCvar();
}

void SetCvar()
{
	g_bEnableLimit = g_hcvarEnableLimit.BoolValue;
	g_iBurnLimit = g_hcvarBurnLimit.IntValue;
}

public void OnMapStart()
{
	OnMapStart_Post();
}

void OnMapStart_Post()
{
	if (!IsScavengeMode())
		return;

	if (g_hCoordinateMap == null)
		g_hCoordinateMap = new StringMap();

	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));

#if DEBUG
	ParseMapCoordinateInfo_DEBUG(sMapName);
#else
	ParseMapCoordinateInfo(sMapName);
#endif
}

void HookEntityPost()
{
	if (!IsScavengeMode())
		return;

	for (int i = 0; i < MAX_ENTITIES; i++)
	{
		if (!IsValidEntity(i))
			continue;

		char sBuffer[64];
		if (i != 0 && i > MaxClients && GetEntityClassname(i, sBuffer, sizeof(sBuffer)))
		{
			if (strcmp(sBuffer, "weapon_gascan") == 0)
				SDKHook(i, SDKHook_VPhysicsUpdatePost, OnVPhysicsUpdatePost);
		}
	}
}

public void OnMapEnd()
{
	if (g_hCoordinateMap != null)
		delete g_hCoordinateMap;
}

public void OnPluginEnd()	// you wont unload this plugin during the map right?
{
	if (g_hCoordinateMap != null)
		delete g_hCoordinateMap;
}

// reset count on every round start, which is triggered in every scavenge round start.
void Event_RoundStart(Event hEvent, const char[] sName, bool dontBroadcast)
{
	g_iBurnedCount = 0;
}

// if a repeatted timer is created and the round is end, free all timer handles.
void Event_RoundEnd(Event hEvent, const char[] sName, bool dontBroadcast)
{
	for (int i = 0; i < MAX_ENTITIES; i++)
	{
		if (g_hTimer[i - 1] != null && g_hTimer[i - 1] != INVALID_HANDLE)
			delete g_hTimer[i];
	}
}

public void OnEntityCreated(int entity, const char[] className)
{
	if (!IsScavengeMode())
		return;

	if (!IsValidEntity(entity))
		return;

	if (strcmp(className, "weapon_gascan") == 0)
	{
	#if !DEBUG
		SDKHook(entity, SDKHook_VPhysicsUpdatePost, OnVPhysicsUpdatePost);	// track gascans's movement.
	#else
		SDKHook(entity, SDKHook_VPhysicsUpdatePost, OnVPhysicsUpdatePost_DEBUG);
	#endif
	}
}

#if !DEBUG
void OnVPhysicsUpdatePost(int entity)
{
	if (!IsValidEntity(entity))
		return;

	if (IsReachedLimit() && g_bEnableLimit)
		return;

	// https://forums.alliedmods.net/showthread.php?t=336632
	// In the scavenge mode case, if a survivor is holding a gascan (entity gascan is attaching to entity player), m_vecOrigin returns vector by player's origin,
	// it could possibly make something wrong since we use coordinate to check gascan.
	// knowing this, we use m_vecAbsOrigin to obtain gascans' absolute vector.
	float vec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vec);

	if (g_hTimer[entity] == null)
		g_hTimer[entity] = CreateTimer(3.0, Timer_Ignite, entity, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);	// set up a repeatted timer with 3.0s countdown.

	float z[2], x[2], y[2];
	if (g_hCoordinateMap.GetValue("z_min", z[0]))	// if key is not set (set as a string when parsing keyvalues), we do nothing on this coodinate boundery.
	{
		if (vec[2] < z[0])
		{
			g_bIsOutBound[entity] = true;			// found gascan out of bound, return for next check
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("z_max", z[1]))
	{
		if (vec[2] > z[1])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("x_min", x[0]))
	{
		if (vec[0] < x[0])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("x_max", x[1]))
	{
		if (vec[0] > x[1])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("y_min", y[0]))
	{
		if (vec[1] < y[0])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("y_max", y[1]))
	{
		if (vec[1] > y[1])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	g_bIsOutBound[entity] = false;		// eventually gascan goes back to the valid position, reset the boolean and dont let the timer ignite it.
}
#else
void OnVPhysicsUpdatePost_DEBUG(int entity)
{
	if (!IsValidEntity(entity))
		return;

	float vec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vec);
	PrintToServer("Entity %d is at %f %f %f", entity, vec[0], vec[1], vec[2]);
}
#endif

Action Timer_Ignite(Handle hTimer, int entity)
{
	if (!g_bIsOutBound[entity])
		return Plugin_Continue;
	else
		Ignite(entity);

	return Plugin_Stop;
}

void Ignite(int entity)
{
	if (g_bEnableLimit)
	{
		if (IsReachedLimit())
			return;

		g_iBurnedCount++;
		if (IsReachedLimit())
			CPrintToChatAll("%t", "ReachedLimit");

		CPrintToChatAll("%t", "IgniteInLimit", g_iBurnedCount, g_iBurnLimit);	
	}
	else
		CPrintToChatAll("%t", "Ignite");

	AcceptEntityInput(entity, "ignite");
}

#if !DEBUG
void ParseMapCoordinateInfo(const char[] sMapName)
{
	KeyValues Kv = new KeyValues("");

	if (!Kv.ImportFromFile(g_sPath))
		SetFailState("Failed to import from file '%s'!", g_sPath);

	if (Kv.JumpToKey(sMapName))
	{
		// directly assign a keyvalue to 0.0 resulting to ignore this boundery since Kv.GetFloat set the defualt value to 0.0.
		if (FloatCompare(Kv.GetFloat("height_zlimit_min"), 0.0) == 0)
			g_hCoordinateMap.SetString("z_min", "none");
		else
			g_hCoordinateMap.SetValue("z_min", Kv.GetFloat("height_zlimit_min"));

		if (FloatCompare(Kv.GetFloat("height_zlimit_max"), 0.0) == 0)
			g_hCoordinateMap.SetString("z_max", "none");
		else
			g_hCoordinateMap.SetValue("z_max", Kv.GetFloat("height_zlimit_max"));

		if (FloatCompare(Kv.GetFloat("width_xlimit_max"), 0.0) == 0)
			g_hCoordinateMap.SetString("x_max", "none");
		else
			g_hCoordinateMap.SetValue("x_max", Kv.GetFloat("width_xlimit_max"));

		if (FloatCompare(Kv.GetFloat("width_xlimit_min"), 0.0) == 0)
			g_hCoordinateMap.SetString("x_min", "none");
		else
			g_hCoordinateMap.SetValue("x_min", Kv.GetFloat("width_xlimit_min"));

		if (FloatCompare(Kv.GetFloat("width_ylimit_max"), 0.0) == 0)
			g_hCoordinateMap.SetString("y_max", "none");
		else
			g_hCoordinateMap.SetValue("y_max", Kv.GetFloat("width_ylimit_max"));

		if (FloatCompare(Kv.GetFloat("width_ylimit_min"), 0.0) == 0)
			g_hCoordinateMap.SetString("y_min", "none");
		else
			g_hCoordinateMap.SetValue("y_min", Kv.GetFloat("width_ylimit_min"));
	}
	else
		LogError("Couldn't find map name '%s' in the config file!", sMapName);

	delete Kv;
}
#else
void ParseMapCoordinateInfo_DEBUG(const char[] sMapName)
{
	KeyValues Kv = new KeyValues("");

	if (!Kv.ImportFromFile(g_sPath))
		SetFailState("Failed to import from file '%s'!", g_sPath);

	if (!Kv.JumpToKey(sMapName))
		LogError("Couldn't find map name '%s' in the config file!", sMapName);

	PrintToServer("Successfully parsed info.");
	PrintToServer("--------------- Parsed mapname %s and coordinates. ---------------", sMapName);
	PrintToServer("z_max = %f\nz_min = %f", Kv.GetFloat("height_zlimit_max"), Kv.GetFloat("height_zlimit_min"));
	PrintToServer("x_max = %f\nx_min = %f", Kv.GetFloat("width_xlimit_max"), Kv.GetFloat("width_xlimit_min"));
	PrintToServer("y_max = %f\ny_min = %f", Kv.GetFloat("width_ylimit_max"), Kv.GetFloat("width_ylimit_min"));
	PrintToServer("------------------------------------------------------------------");
}
#endif

bool IsReachedLimit()
{
	return (g_iBurnedCount >= g_iBurnLimit);
}

bool IsScavengeMode()
{
	char sGameMode[32];
	ConVar hcvarGameMode = FindConVar("mp_gamemode");
	hcvarGameMode.GetString(sGameMode, sizeof(sGameMode));

	return (strcmp(sGameMode, "scavenge") == 0);
}