#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <gamedata_wrapper>

#define MAX_EDICTS					(1 << 11)

/**
 * M = Cn / b.
 * Cn = current survivor count.
 * b = base survivor count. should be 4 by default.
 * Spectators are not counted.
 */

#define PLUGIN_VERSION "r1.4.0"
public Plugin myinfo =
{
	name = "[L4D2] Player Count Based Supplies",
	author = "奈, blueblur",
	description = "Multiple the supply item's count based on then number of player count.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

ConVar g_hCvar_Enable, g_hCvar_MultipleType, g_hCvar_BaseCount;

int g_iMultiple = 0;
int g_iMultipleType = 0;
bool g_bUsed[MAX_EDICTS + 1] = {false, ...};

StringMap g_hMapSpawner;

public void OnPluginStart()
{
	LoadTranslation("l4d2_playercount_based_supplies.phrases");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	CreateConVar("l4d2_playercount_based_supplies_version", PLUGIN_VERSION, "Player Count Based Supplies version.", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	g_hCvar_Enable = CreateConVar("l4d2_playercount_based_supplies_enable", "1", "enable multiple medic?", _, true, 0.0, true, 1.0);
	g_hCvar_MultipleType = CreateConVar("l4d2_playercount_based_supplies_type", "15", "which type to enable? 0=nothing, 1=medkit, 2=pain pills, 4=adrenaline, 8=defib, 16=vomitjar, 32=pipebomb, 64=molotov, 128=incendiary pack, 256=explosive pack, Add numbers together.", _, true, 0.0, true, 511.0);
	g_hCvar_BaseCount = CreateConVar("l4d2_playercount_based_supplies_basecount", "4", "base survivor count for caculation.", _, true, 1.0, true, 32.0);

	g_hCvar_MultipleType.AddChangeHook(OnMultipleTypeChanged);
	OnMultipleTypeChanged(null, "", "");

	g_hMapSpawner = SetupSpawnerMap();
}

public void OnPluginEnd()
{
	delete g_hMapSpawner;
}

void OnMultipleTypeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMultipleType = g_hCvar_MultipleType.IntValue;
}

Handle g_hTimer = null;
public void OnMapEnd()
{
	g_iMultiple		= 0;
	g_hTimer		= null;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iMultiple = 0;

	for (int i = 0; i < MAX_EDICTS; i++)
		g_bUsed[i] = false;

	if (!g_hTimer)
		g_hTimer = CreateTimer(1.0, Timer_SetCount, 0, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hTimer)
	{
		KillTimer(g_hTimer);
		g_hTimer = null;
	}

	g_iMultiple = 0;
}

void Timer_SetCount(Handle timer)
{
	SetMedicCount();
}

void SetMedicCount()
{
	if (!g_hCvar_Enable.BoolValue || !g_hCvar_MultipleType.IntValue)
		return;

	// do count bots.
	float fMultiple = float(GetSurvivorCount()) / g_hCvar_BaseCount.FloatValue;
	int iMultiple = RoundToFloor(fMultiple);

	//PrintToServer("iMultiple: %i, fMultiple: %.02f, g_iMultiple: %i", iMultiple, fMultiple, g_iMultiple);

	if (iMultiple <= 0)
		iMultiple = 1;

	if (iMultiple != g_iMultiple)
	{
		g_iMultiple = iMultiple;
		int ent = INVALID_ENT_REFERENCE;
		while ((ent = FindEntityByClassname(ent, "weapon_*")) != INVALID_ENT_REFERENCE)
		{
			if (!IsValidEntity(ent))
				continue;

			char entName[64];
			GetEntityClassname(ent, entName, sizeof(entName));

			int value = 0;
			if (g_hMapSpawner.ContainsKey(entName))
			{
				// if it's already used (case when count >= 2), do not reset its count again.
				if (g_bUsed[ent])
					return;

				SDKHook(ent, SDKHook_UsePost, OnUse);
				g_hMapSpawner.GetValue(entName, value);
				if ((g_iMultipleType & value))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
			}
		}

		CPrintToChatAll("%t", "Changed", iMultiple);
	}
}

void OnUse(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsValidEdict(entity))
		return;

	if (g_bUsed[entity])
		return;

	g_bUsed[entity] = true;
}

stock int GetSurvivorCount()
{
    int count;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2)
            count++;
    }

    return count;
}

StringMap SetupSpawnerMap()
{
	StringMap map = new StringMap();
	map.SetValue("weapon_first_aid_kit_spawn", 1);
	map.SetValue("weapon_pain_pills_spawn", 2);
	map.SetValue("weapon_adrenaline_spawn", 4);
	map.SetValue("weapon_defibrillator_spawn", 8);
	map.SetValue("weapon_vomitjar_spawn", 16);
	map.SetValue("weapon_pipe_bomb_spawn", 32);
	map.SetValue("weapon_molotov_spawn", 64);
	map.SetValue("weapon_upgradepack_incendiary_spawn", 128);
	map.SetValue("weapon_upgradepack_explosive_spawn", 256);
	return map;
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