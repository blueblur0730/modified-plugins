#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define CONFIG_PATH	"configs/l4d2_scav_gascan_selfburn.txt"
#define MAX_ENTITIES 2048

StringMap g_hCoordinateMap;
KeyValues g_hKv;
Handle g_hTimer[MAX_ENTITIES + 1];

bool g_bIsOutBound[MAX_ENTITIES + 1];
bool g_bIgnited[MAX_ENTITIES + 1];
int g_iBurnedCount = 0;

char g_sPath[128];
bool g_bLateLoad;

float g_flFrequency;
bool g_bEnableLimit;
int g_iBurnLimit;

#define PLUGIN_VERSION "3.1"

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
	LoadTranslation("l4d2_scav_gascan_selfburn.phrases");

	g_hCoordinateMap = new StringMap();
	g_hKv = new KeyValues("");

	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), CONFIG_PATH);
	if (!g_hKv.ImportFromFile(g_sPath))
		SetFailState("Failed to import from file '%s'!", g_sPath);

	CreateConVar("l4d2_scav_gascan_selfburn_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	CreateConVarHook("l4d2_scav_gascan_burned_limit_enable", "0", "Enable Limited Gascan burn", FCVAR_NOTIFY, true, 0.0, true, 1.0, OnEnableLimitChanged);
	CreateConVarHook("l4d2_scav_gascan_burned_limit", "4", "Limits the max amount of gascan that can get burned if they are out of bounds.", FCVAR_NOTIFY, true, 0.0, false, 0.0, OnLimitChanged);
	CreateConVarHook("l4d2_scav_gascan_check_frequency", "3.0", "The frequency on checking the igniting condition", FCVAR_NOTIFY, true, 0.1, false, 0.0, OnFrequencyChanged);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	if (g_bLateLoad)
	{
		OnMapStart();
		HookEntities();
	}
}

void OnEnableLimitChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_bEnableLimit = hConVar.BoolValue;
}

void OnLimitChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_iBurnLimit = hConVar.IntValue;
}

void OnFrequencyChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_flFrequency = hConVar.FloatValue;
}

public void OnMapStart()
{
	if (!IsScavengeMode())
		return;

	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));
	ParseMapCoordinateInfo(sMapName);
}

void HookEntities()
{
	if (!IsScavengeMode())
		return;

	int ent = INVALID_ENT_REFERENCE;
	while ((ent = FindEntityByClassname(-1, "weapon_gascan")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(ent))
			continue;

		SDKHook(ent, SDKHook_VPhysicsUpdatePost, OnVPhysicsUpdatePost);
		g_hTimer[ent] = CreateTimer(g_flFrequency, Timer_Ignite, ent, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

public void OnPluginEnd()
{
	delete g_hCoordinateMap;
	delete g_hKv;
}

// reset count on every round start, which is triggered in every scavenge round start.
void Event_RoundStart(Event hEvent, const char[] sName, bool dontBroadcast)
{
	g_iBurnedCount = 0;
}

public void OnEntityCreated(int entity, const char[] className)
{
	if (!IsScavengeMode())
		return;

	if (!IsValidEntity(entity))
		return;

	// track gascans's movement.
	if (strcmp(className, "weapon_gascan") == 0)
	{
		// set up a repeatted timer.
		g_hTimer[entity] = CreateTimer(g_flFrequency, Timer_Ignite, entity, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		SDKHook(entity, SDKHook_VPhysicsUpdatePost, OnVPhysicsUpdatePost);
		g_bIgnited[entity] = false;
	}
}

public void OnEntityDestroyed(int entity)
{
	static char classname[256];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (strcmp(classname, "weapon_gascan") == 0 && !g_bIgnited[entity])
		KillTimer(g_hTimer[entity]);
}

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

	float vecMax[3], vecMin[3];
	// if key is not set (set as a string when parsing keyvalues), we do nothing on this coodinate boundery.
	if (g_hCoordinateMap.GetValue("x_max", vecMax[0])) 
	{
		if (vec[0] > vecMax[0])
		{
			// found gascan out of bound, return for next check
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("y_max", vecMax[1]))
	{
		if (vec[1] > vecMax[1])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("z_max", vecMax[2]))
	{
		if (vec[2] > vecMax[2])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("x_min", vecMin[0]))
	{
		if (vec[0] < vecMin[0])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("y_min", vecMin[1]))
	{
		if (vec[1] < vecMin[1])
		{
			g_bIsOutBound[entity] = true;
			return;
		}
	}

	if (g_hCoordinateMap.GetValue("z_min", vecMin[2]))
	{
		if (vec[2] < vecMin[2])
		{
			g_bIsOutBound[entity] = true;			
			return;
		}
	}

	// eventually gascan goes back to the valid position, reset the boolean and dont let the timer ignite it.
	g_bIsOutBound[entity] = false;
}

Action Timer_Ignite(Handle hTimer, int entity)
{
	if (!g_bIsOutBound[entity])
		return Plugin_Continue;

	if (!IsValidEntity(entity))
		return Plugin_Stop;

	if (IsReachedLimit() && g_bEnableLimit)
		return Plugin_Stop;

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
	{
		CPrintToChatAll("%t", "Ignite");
	}

	g_bIgnited[entity] = true;
	AcceptEntityInput(entity, "ignite");
}

void ParseMapCoordinateInfo(const char[] sMapName)
{
	if (g_hKv.JumpToKey(sMapName))
	{
		// directly assign a keyvalue to 0.0 resulting to ignore this boundery since Kv.GetFloat set the defualt value to 0.0.
		if (FloatCompare(g_hKv.GetFloat("height_zlimit_min"), 0.0) == 0)
			g_hCoordinateMap.SetString("z_min", "none");
		else
			g_hCoordinateMap.SetValue("z_min", g_hKv.GetFloat("height_zlimit_min"));

		if (FloatCompare(g_hKv.GetFloat("height_zlimit_max"), 0.0) == 0)
			g_hCoordinateMap.SetString("z_max", "none");
		else
			g_hCoordinateMap.SetValue("z_max", g_hKv.GetFloat("height_zlimit_max"));

		if (FloatCompare(g_hKv.GetFloat("width_xlimit_max"), 0.0) == 0)
			g_hCoordinateMap.SetString("x_max", "none");
		else
			g_hCoordinateMap.SetValue("x_max", g_hKv.GetFloat("width_xlimit_max"));

		if (FloatCompare(g_hKv.GetFloat("width_xlimit_min"), 0.0) == 0)
			g_hCoordinateMap.SetString("x_min", "none");
		else
			g_hCoordinateMap.SetValue("x_min", g_hKv.GetFloat("width_xlimit_min"));

		if (FloatCompare(g_hKv.GetFloat("width_ylimit_max"), 0.0) == 0)
			g_hCoordinateMap.SetString("y_max", "none");
		else
			g_hCoordinateMap.SetValue("y_max", g_hKv.GetFloat("width_ylimit_max"));

		if (FloatCompare(g_hKv.GetFloat("width_ylimit_min"), 0.0) == 0)
			g_hCoordinateMap.SetString("y_min", "none");
		else
			g_hCoordinateMap.SetValue("y_min", g_hKv.GetFloat("width_ylimit_min"));
	}
	else
	{
		LogError("Couldn't find map name '%s' in the config file!", sMapName);
	}

	g_hKv.Rewind();
}

bool IsReachedLimit()
{
	return (g_iBurnedCount >= g_iBurnLimit);
}

stock bool IsScavengeMode()
{
	char sGameMode[32];
	ConVar hcvarGameMode = FindConVar("mp_gamemode");
	hcvarGameMode.GetString(sGameMode, sizeof(sGameMode));

	return (strcmp(sGameMode, "scavenge") == 0);
}

stock void CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();

	cv.AddChangeHook(callback);
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