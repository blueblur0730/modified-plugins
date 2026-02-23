#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <gamedata_wrapper>

#define MULTIPLE_MEDKIT 1
#define MULTIPLE_PAIN_PILLS 2
#define MULTIPLE_ADRENALINE 4
#define MULTIPLE_DEFIB 8
#define MULTIPLE_VOMITJAR 16
#define MULTIPLE_PIPEBOMB 32
#define MULTIPLE_MOLOTOV 64
#define MULTIPLE_INCENDIARY 128
#define MULTIPLE_EXPLOSIVE 256

#define L4D2Team_Spectator 1
#define L4D2Team_Survivor 2

/**
 * M = Cn / b.
 * Cn = current survivor count.
 * b = base survivor count. should be 4 by default.
 * Spectators are not counted.
 */

#define PLUGIN_VERSION "r1.3.1"

public Plugin myinfo =
{
	name = "[L4D2] Player Count Based Supplies",
	author = "奈, blueblur",
	description = "Multiple the count one supply item can have based on player count.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

Handle g_hSDKCall_GetSpawnedWeaponName;
ConVar g_hCvar_Enable, g_hCvar_MultipleType, g_hCvar_BaseCount;

int g_iMultiple = 0;
int g_iMultipleType = 0;

public void OnPluginStart()
{
	LoadTranslation("l4d2_playercount_based_supplies.phrases");

	GameDataWrapper gd = new GameDataWrapper("l4d2_playercount_based_supplies");

	SDKCallParamsWrapper ret2 = { SDKType_String, SDKPass_Pointer };
	g_hSDKCall_GetSpawnedWeaponName = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Virtual, "CWeaponSpawn::GetSpawnedWeaponName", _, _, true, ret2);

	delete gd;

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	CreateConVar("l4d2_playercount_based_supplies_version", PLUGIN_VERSION, "Player Count Based Supplies version.", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	g_hCvar_Enable		= CreateConVar("l4d2_playercount_based_supplies_enable", "1", "enable multiple medic?", _, true, 0.0, true, 1.0);
	g_hCvar_MultipleType 	= CreateConVar("l4d2_playercount_based_supplies_type", "15", "which type to enable? 0=nothing, 1=medkit, 2=pain pills, 4=adrenaline, 8=defib, 16=vomitjar, 32=pipebomb, 64=molotov, 128=incendiary pack, 256=explosive pack, Add numbers together.", _, true, 0.0, true, 511.0);
	g_hCvar_BaseCount		= CreateConVar("l4d2_playercount_based_supplies_basecount", "4", "base survivor count for caculation.", _, true, 1.0, true, 32.0);

	g_hCvar_MultipleType.AddChangeHook(OnMultipleTypeChanged);
	OnMultipleTypeChanged(null, "", "");
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

	if (!g_hTimer)
		g_hTimer = CreateTimer(1.0, Timer_SetCount, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
			if ((g_iMultipleType & MULTIPLE_MEDKIT) && StrEqual(entName, "weapon_first_aid_kit_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}
				
			if ((g_iMultipleType & MULTIPLE_PAIN_PILLS) && StrEqual(entName, "weapon_pain_pills_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}

			if ((g_iMultipleType & MULTIPLE_ADRENALINE) && StrEqual(entName, "weapon_adrenaline_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}

			if ((g_iMultipleType & MULTIPLE_DEFIB) && StrEqual(entName, "weapon_defibrillator_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}

			if ((g_iMultipleType & MULTIPLE_VOMITJAR) && StrEqual(entName, "weapon_vomitjar_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}

			if ((g_iMultipleType & MULTIPLE_PIPEBOMB) && StrEqual(entName, "weapon_pipe_bomb_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}

			if ((g_iMultipleType & MULTIPLE_MOLOTOV) && StrEqual(entName, "weapon_molotov_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}

			if ((g_iMultipleType & MULTIPLE_INCENDIARY) && StrEqual(entName, "weapon_upgradepack_incendiary_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}

			if ((g_iMultipleType & MULTIPLE_EXPLOSIVE) && StrEqual(entName, "weapon_upgradepack_explosive_spawn"))
			{
				DispatchKeyValueInt(ent, "count", iMultiple);
			}

			if (StrEqual(entName, "weapon_spawn"))
			{
				char weaponName[64];
				GetSpawnedWeaponName(ent, weaponName, sizeof(weaponName));
				if ((g_iMultipleType & MULTIPLE_MEDKIT) && StrEqual(weaponName, "first_aid_kit"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
				else if ((g_iMultipleType & MULTIPLE_PAIN_PILLS) && StrEqual(weaponName, "pain_pills"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
				else if ((g_iMultipleType & MULTIPLE_ADRENALINE) && StrEqual(weaponName, "adrenaline"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
				else if ((g_iMultipleType & MULTIPLE_DEFIB) && StrEqual(weaponName, "defibrillator"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
				else if ((g_iMultipleType & MULTIPLE_VOMITJAR) && StrEqual(weaponName, "vomitjar"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
				else if ((g_iMultipleType & MULTIPLE_PIPEBOMB) && StrEqual(weaponName, "pipe_bomb"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
				else if ((g_iMultipleType & MULTIPLE_MOLOTOV) && StrEqual(weaponName, "molotov"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
				else if ((g_iMultipleType & MULTIPLE_INCENDIARY) && StrEqual(weaponName, "upgradepack_incendiary"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
				else if ((g_iMultipleType & MULTIPLE_EXPLOSIVE) && StrEqual(weaponName, "upgradepack_explosive"))
				{
					DispatchKeyValueInt(ent, "count", iMultiple);
				}
			}

			CPrintToChatAll("%t", "Changed", iMultiple);
		}
	}
}

stock int GetSurvivorCount()
{
    int count;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == L4D2Team_Survivor && IsPlayerAlive(i))
            count++;
    }

    return count;
}
/*
// s_WeaponAlias.
static const char g_sWeaponAlias[][] = {
	//"none","pistol","smg","pumpshotgun","autoshotgun","rifle","hunting_rifle","smg_silenced","shotgun_chrome","rifle_desert","sniper_military","shotgun_spas",
	"first_aid_kit",
	"molotov",
	"pipe_bomb",
	"pain_pills",
	//"gascan","propanetank","oxygentank","melee","chainsaw","grenade_launcher","ammo_pack",
	"adrenaline",
	"defibrillator",
	"vomitjar",
	//"rifle_ak47","gnome","cola_bottles","fireworkcrate",
	"upgradepack_incendiary",
	"upgradepack_explosive",
	//"pistol_magnum","smg_mp5","rifle_sg552","sniper_awp","sniper_scout","rifle_m60","tank_claw","hunter_claw","charger_claw","boomer_claw","smoker_claw","spitter_claw","jockey_claw","machinegun","vomit","splat","pounce","lounge","pull","rock","physics","ammo"
}
*/
void GetSpawnedWeaponName(int entity, char[] buffer, int maxlength)
{
	SDKCall(g_hSDKCall_GetSpawnedWeaponName, entity, buffer, maxlength);
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