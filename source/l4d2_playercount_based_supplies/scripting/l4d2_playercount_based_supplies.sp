#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

#define MULTIPLE_MEDKIT 1
#define MULTIPLE_PAIN_PILLS 2
#define MULTIPLE_ADRENALINE 4

#define L4D2Team_Spectator 1
#define L4D2Team_Survivor 2

/**
 * M = Cn / b.
 * Cn = current survivor count.
 * b = base survivor count. should be 4 by default.
 * Spectators are not counted.
 */

#define PLUGIN_VERSION "r1.2"

public Plugin myinfo =
{
	name = "[L4D2] Player Count Based Supplies",
	author = "奈, blueblur",
	description = "Multiple the count one supply item can have based on player count.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

ConVar g_hCvar_AutoEnable, g_hCvar_MultipleType, g_hCvar_BaseCount;
bool	  g_bEnable;
int	  g_iMultiple, g_iMultipleType;

public void OnPluginStart()
{
	LoadTranslation("l4d2_playercount_based_supplies.phrases");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	CreateConVar("l4d2_playercount_based_supplies_version", PLUGIN_VERSION, "Player Count Based Supplies version.", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	g_hCvar_AutoEnable		= CreateConVar("l4d2_playercount_based_supplies_enable", "1", "enable multiple medic?", _, true, 0.0, true, 1.0);
	g_hCvar_MultipleType 	= CreateConVar("l4d2_playercount_based_supplies_type", "1", "which type to enable? 0=nothing, 1=medkit, 2=pain pills, 4=adrenaline, Add numbers together.", _, true, 0.0, true, 7.0);
	g_hCvar_BaseCount		= CreateConVar("l4d2_playercount_based_supplies_basecount", "4", "base survivor count for caculation.", _, true, 1.0, true, 32.0);

	g_hCvar_AutoEnable.AddChangeHook(CvarChanged);
	g_hCvar_MultipleType.AddChangeHook(CvarChanged);
	CvarChanged(null, "", "");
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnable		 = g_hCvar_AutoEnable.BoolValue;
	g_iMultipleType = g_hCvar_MultipleType.IntValue;
}

public void OnMapStart()
{
	g_iMultiple		= 0;
}

public void OnMapEnd()
{
	g_iMultiple		= 0;
}

Handle g_hTimer = null;
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iMultiple = 0;

	if (!g_hTimer)
		g_hTimer = CreateTimer(1.0, Timer_SetCount, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Timer_SetCount(Handle timer)
{
	SetMedicCount();
}

void SetMedicCount()
{
	if (!g_bEnable || !g_iMultipleType)
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
		bool bFirstAidKit = false;
		bool bPainPills = false;
		bool bAdrenaline = false;
		int ent = INVALID_ENT_REFERENCE;
		while ((ent = FindEntityByClassname(ent, "weapon_*")) != INVALID_ENT_REFERENCE)
		{
			char entName[64];
			GetEntityClassname(ent, entName, sizeof(entName));
			if ((g_iMultipleType & MULTIPLE_MEDKIT) && StrEqual(entName, "weapon_first_aid_kit_spawn"))
			{
				// prevent from chat spamming.
				if (!bFirstAidKit)
					CPrintToChatAll("%t", "Changed", iMultiple, "first_aid_kit");

				bFirstAidKit = true;
				CreateEntityIO(ent, iMultiple);
			}
				
			if ((g_iMultipleType & MULTIPLE_PAIN_PILLS) && StrEqual(entName, "weapon_pain_pills_spawn"))
			{
				if (!bPainPills)
					CPrintToChatAll("%t", "Changed", iMultiple, "pain_pills");

				bPainPills = true;
				CreateEntityIO(ent, iMultiple);
			}

			if ((g_iMultipleType & MULTIPLE_ADRENALINE) && StrEqual(entName, "weapon_adrenaline_spawn"))
			{
				if (!bAdrenaline)
					CPrintToChatAll("%t", "Changed", iMultiple, "adrenaline");

				bAdrenaline = true;
				CreateEntityIO(ent, iMultiple);
			}
		}
	}
}

// from l4d_wam by Eärendil.
void CreateEntityIO(int entity, int amount)
{
	char sBuffer[64];

	// Using entity I/O allows to call outputs with delay of 0.01s and avoid timers :D
	Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:AddOutput:count %i:0.01:0", amount);
	SetVariantString(sBuffer);
	AcceptEntityInput(entity, "Addoutput");
	AcceptEntityInput(entity, "FireUser1");
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

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}