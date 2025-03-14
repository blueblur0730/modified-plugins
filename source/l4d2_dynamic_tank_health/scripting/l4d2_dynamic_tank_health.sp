#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

/**
 * Tank's health is defined by the mathmatical function below
 * 
 * health = H * n + (Cn - k) * l
 * 
 * H = base health.
 * n = difficulty coefficient.
 * Cn = current survivor count.
 * k = Base survivor count.
 * l = extra health per extra survivor to be added.
 * 
 * In my case I would set H = 4000, k = 4, l = 1000, which is
 * 
 * health = 4000 * n + (Cn - 4) * 1000
 * 
 * all the codes below follow this formula.
*/

enum {
	Difficulty_Unknown = -1,
    Difficulty_Easy = 0,
    Difficulty_Normal = 1,
    Difficulty_Advanced = 2,
    Difficulty_Expert = 3,

	Difficulty_Count = 4
}

ConVar
    g_hCvar_BaseHealth,
    g_hCvar_BaseSurvivorCount,
    g_hCvar_ExtraHealthPerSurvivor;

ConVar g_hCvar_DifficultyCoefficient[Difficulty_Count];

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[L4D2] Dynamic Tank Health",
	author = "blueblur",
	description = "Adjust tank's health by survivor count and difficulty.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    LoadTranslation("l4d2_dynamic_tank_health.phrases");

    CreateConVar("l4d2_dynamic_tank_health_version", PLUGIN_VERSION, "Version of the plugin.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_hCvar_BaseHealth = CreateConVar("l4d2_dth_base_health", "4000.0", "Base health of the tank.", _, true, 0.0);
    g_hCvar_BaseSurvivorCount = CreateConVar("l4d2_dth_base_survivor_count", "4", "Base survivor count to be devided by the current survivor count.", _, true, 0.0, _, _);
    g_hCvar_ExtraHealthPerSurvivor = CreateConVar("l4d2_dth_extra_health_per_survivor", "1000.0", "Extra health per extra survivor to be added to the base health.", _, true, 0.0, _, _);
    g_hCvar_DifficultyCoefficient[Difficulty_Easy] = CreateConVar("l4d2_dth_difficulty_coef_easy", "0.75", "Easy Difficulty coefficient for the given difficulty level.", _, true, 0.0, _, _);
    g_hCvar_DifficultyCoefficient[Difficulty_Normal] = CreateConVar("l4d2_dth_difficulty_coef_normal", "1.0", "Normal Difficulty coefficient for the given difficulty level.", _, true, 0.0, _, _);
    g_hCvar_DifficultyCoefficient[Difficulty_Advanced] = CreateConVar("l4d2_dth_difficulty_coef_advanced", "2.0", "Advanced Difficulty coefficient for the given difficulty level.", _, true, 0.0, _, _);
    g_hCvar_DifficultyCoefficient[Difficulty_Expert] = CreateConVar("l4d2_dth_difficulty_coef_expert", "2.0", "Expert Difficulty coefficient for the given difficulty level.", _, true, 0.0, _, _);
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
    if (client <= 0)
        return;

    if (!IsClientInGame(client))
        return;

    // right after tank announce.
    CreateTimer(0.2, Timer_HealthAnnounce, GetClientUserId(client));
}

void Timer_HealthAnnounce(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
		return;

    float flMultipler = 1.0;
    switch (GetDifficulty())
    {
        case Difficulty_Easy: flMultipler = g_hCvar_DifficultyCoefficient[Difficulty_Easy].FloatValue;
        case Difficulty_Normal: flMultipler = g_hCvar_DifficultyCoefficient[Difficulty_Normal].FloatValue;
        case Difficulty_Advanced: flMultipler = g_hCvar_DifficultyCoefficient[Difficulty_Advanced].FloatValue;
        case Difficulty_Expert: flMultipler = g_hCvar_DifficultyCoefficient[Difficulty_Expert].FloatValue;
        default: flMultipler = 1.0;
    }

    float flHealth = g_hCvar_BaseHealth.FloatValue * flMultipler + (GetSurvivorCount() - g_hCvar_BaseSurvivorCount.IntValue) * g_hCvar_ExtraHealthPerSurvivor.FloatValue;
    int iHealth = RoundToFloor(flHealth);

    SetEntProp(client, Prop_Send, "m_iMaxHealth", iHealth);
    SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
 
    CPrintToChatAll("%t", "AnnounceTankHealth", iHealth);
}

stock int GetDifficulty()
{
	char sDifficultyName[12];
	FindConVar("z_difficulty").GetString(sDifficultyName, sizeof(sDifficultyName));
	if (sDifficultyName[0] != '\0')
	{
		switch (sDifficultyName[0])
		{
			case 'E','e': return Difficulty_Easy;
			case 'N','n': return Difficulty_Normal;
			case 'H','h': return Difficulty_Advanced;
			case 'I','i': return Difficulty_Expert;
			default: return Difficulty_Unknown;
		}
	}

    return Difficulty_Unknown;
}

stock int GetSurvivorCount()
{
    int count;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
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