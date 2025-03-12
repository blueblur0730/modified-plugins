#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

static const char g_sZClassName[][] = {
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
};

static const char g_sRewardEventName[][] = {
	"protect_friendly",
	"saved_from_si_control",
};

enum {
	SIType_Smoker = 1,
	SIType_Boomer,
	SIType_Hunter,
	SIType_Spitter,
	SIType_Jockey,
	SIType_Charger,

	SIType_Size	   // 6 size
}

enum {
	RewordType_ProtectFriendly = 67,
	RewardType_SavedFromSIControl = 76,
}

enum {
	ProtectFriendly = 0,
	SavedFromSIControl = 1,

	RewardType_Size = 2
}

ConVar g_hCvar_MaxmuimHealth;
ConVar g_hCvar_Enable;
ConVar g_hCvar_SIReward[SIType_Size];
ConVar g_hCvar_RewardEvent[RewardType_Size];

ConVar
	g_hCvar_KillTankReward,
	g_hCvar_KillWitchReward,
	g_hCvar_DefibReward,
	g_hCvar_ReviveReward,
	g_hCvar_LedgeReviveReward,
	g_hCvar_HealReward,
	g_hCvar_RescureReward,
	g_hCvar_SoloTankReward,
	g_hCvar_OneShotWitch;

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "[L4D2] HP Distributing",
	author = "blueblur",
	description = "Distributing health based on a series of events.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	LoadTranslation("l4d2_hp_distributing.phrases");

	CreateConVar("l4d2_hp_distributing_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvar_Enable = CreateConVar("l4d2_hp_distributing_enable", "1", "Enable or disable plugin.");
	g_hCvar_MaxmuimHealth = CreateConVar("l4d2_hp_distributing_max_health", "120", "Max health to stop rewarding.", _, true, 0.0);

	char sBuffer[128];
	for (int i = 0; i < SIType_Size - 1; i++)
	{
		StrToLowerCase(g_sZClassName[i], sBuffer, sizeof(sBuffer));
		Format(sBuffer, sizeof(sBuffer), "l4d2_hp_distributing_si_reward_%s", sBuffer);
		g_hCvar_SIReward[i] = CreateConVar(sBuffer, "2", "SI Reward Health", _, true, 0.0);
	}

	for (int i = 0; i < RewardType_Size; i++)
	{
		Format(sBuffer, sizeof(sBuffer), "l4d2_hp_distributing_%s", g_sRewardEventName[i]);
		g_hCvar_RewardEvent[i] = CreateConVar(sBuffer, "0", "Event Reward Health", _, true, 0.0);
	}

	g_hCvar_KillTankReward = CreateConVar("l4d2_hp_distributing_kill_tank_reward", "10", "Kill Tank Reward Health", _, true, 0.0);
	g_hCvar_KillWitchReward = CreateConVar("l4d2_hp_distributing_kill_witch_reward", "10", "Kill Witch Reward Health", _, true, 0.0);
	g_hCvar_DefibReward = CreateConVar("l4d2_hp_distributing_defiber_reward", "10", "Defiber Reward Health", _, true, 0.0);
	g_hCvar_ReviveReward = CreateConVar("l4d2_hp_distributing_revive_reward", "5", "Revive Reward Health", _, true, 0.0);
	g_hCvar_LedgeReviveReward = CreateConVar("l4d2_hp_distributing_ledge_revive_reward", "3", "Ledge Revive Reward Health", _, true, 0.0);
	g_hCvar_RescureReward = CreateConVar("l4d2_hp_distributing_rescure_reward", "10", "Rescure Reward Health", _, true, 0.0);
	g_hCvar_HealReward = CreateConVar("l4d2_hp_distributing_heal_reward", "2", "Heal Reward Health", _, true, 0.0);
	g_hCvar_SoloTankReward = CreateConVar("l4d2_hp_distributing_solo_tank_reward", "10", "Solo Tank Reward Health", _, true, 0.0);
	g_hCvar_OneShotWitch = CreateConVar("l4d2_hp_distributing_one_shot_witch_reward", "10", "One Shot Witch Reward Health", _, true, 0.0);
	
	g_hCvar_Enable.AddChangeHook(OnEnableChanged);
	ToggleEnable();
}

public void OnConfigsExecuted()
{
	ToggleEnable();
}

void OnEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ToggleEnable();
}

void ToggleEnable()
{
	static bool bEnable = false;
	if (g_hCvar_Enable.BoolValue && !bEnable)
	{
		HookEvent("witch_killed", Event_Witchkilled);
		HookEvent("tank_killed", Event_TankKilled);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("award_earned", Event_AwardEarned);
		HookEvent("defibrillator_used", Event_DefibrillatorUsed);
		HookEvent("revive_success", Event_ReviveSuccess);
		HookEvent("survivor_rescued", Event_SurvivorRescued);
		HookEvent("heal_success", Event_HealSuccess);

		bEnable = true;
	}
	else if (!g_hCvar_Enable.BoolValue && bEnable)
	{
		UnhookEvent("witch_killed", Event_Witchkilled);
		UnhookEvent("tank_killed", Event_TankKilled);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("award_earned", Event_AwardEarned);
		UnhookEvent("defibrillator_used", Event_DefibrillatorUsed);
		UnhookEvent("revive_success", Event_ReviveSuccess);
		UnhookEvent("survivor_rescued", Event_SurvivorRescued);
		UnhookEvent("heal_success", Event_HealSuccess);

		bEnable = false;
	}
}

void Event_Witchkilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hCvar_KillWitchReward.IntValue)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!ValidatePlayer(client, 2))
		return;

	if (GetEntProp(client, Prop_Send, "m_iHealth") >= g_hCvar_MaxmuimHealth.IntValue)
		return;

	bool bOneShot = event.GetBool("oneshot");
	if (!IsFakeClient(client))
		CPrintToChat(client, "%t", "WitchKilled", g_hCvar_KillWitchReward.IntValue + (bOneShot ? g_hCvar_OneShotWitch.IntValue : 0), bOneShot ? "by one shot" : "");

	RewardHealth(client, g_hCvar_KillWitchReward.IntValue + (bOneShot ? g_hCvar_OneShotWitch.IntValue : 0));
}

void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hCvar_KillTankReward.IntValue)
		return;

	bool bL4D1 = event.GetBool("l4d1_only");
	if (bL4D1) return;

	int client = GetClientOfUserId(event.GetInt("attacker"));
	if (!ValidatePlayer(client, 2))
		return;

	if (GetEntProp(client, Prop_Send, "m_iHealth") >= g_hCvar_MaxmuimHealth.IntValue)
		return;

	bool bSolo = event.GetBool("solo");
	if (!IsFakeClient(client))
		CPrintToChat(client, "%t", "TankKilled", g_hCvar_KillTankReward.IntValue + (bSolo ? g_hCvar_SoloTankReward.IntValue : 0), bSolo ? "by solo" : "");

	RewardHealth(client, g_hCvar_KillTankReward.IntValue + (bSolo ? g_hCvar_SoloTankReward.IntValue : 0));
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!ValidatePlayer(attacker, 2))
		return;

	if (GetEntProp(attacker, Prop_Send, "m_iHealth") >= g_hCvar_MaxmuimHealth.IntValue)
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!ValidatePlayer(victim, 3))
		return;

	int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
	if (zClass > 6 || !g_hCvar_SIReward[zClass - 1].IntValue)
		return;

	if (!IsFakeClient(attacker))
		CPrintToChat(attacker, "%t", "KillSI", g_hCvar_SIReward[zClass - 1].IntValue, g_sZClassName[zClass - 1]);

	RewardHealth(attacker, g_hCvar_SIReward[zClass - 1].IntValue);
}

void Event_DefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hCvar_DefibReward.IntValue)
		return;

	int savior = GetClientOfUserId(event.GetInt("userid"));
	if (!ValidatePlayer(savior, 2))
		return;

	if (GetEntProp(savior, Prop_Send, "m_iHealth") >= g_hCvar_MaxmuimHealth.IntValue)
		return;

	int patient = GetClientOfUserId(event.GetInt("subject"));
	if (!ValidatePlayer(patient, 2))
		return;

	if (!IsFakeClient(savior))
		CPrintToChat(savior, "%t", "DefibUsed", g_hCvar_DefibReward.IntValue, patient);

	RewardHealth(savior, g_hCvar_DefibReward.IntValue);
}

void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	bool bLedged = event.GetBool("ledge_hang");

	if (bLedged)
	{
		if (!g_hCvar_LedgeReviveReward.IntValue)
			return;
	}
	else
	{
		if (!g_hCvar_ReviveReward.IntValue)
			return;
	}

	int savior = GetClientOfUserId(event.GetInt("userid"));
	if (!ValidatePlayer(savior, 2))
		return;

	if (GetEntProp(savior, Prop_Send, "m_iHealth") >= g_hCvar_MaxmuimHealth.IntValue)
		return;

	int patient = GetClientOfUserId(event.GetInt("subject"));
	if (!ValidatePlayer(patient, 2))
		return;

	if (!IsFakeClient(savior))
		CPrintToChat(savior, "%t", bLedged ? "LedgeRevive" : "Revive", bLedged ? g_hCvar_LedgeReviveReward.IntValue : g_hCvar_ReviveReward.IntValue, patient);

	bLedged ? 
	RewardHealth(savior, g_hCvar_LedgeReviveReward.IntValue) : 
	RewardHealth(savior, g_hCvar_ReviveReward.IntValue);
}

void Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hCvar_RescureReward.IntValue)
		return;

	int savior = GetClientOfUserId(event.GetInt("rescure"));
	if (!ValidatePlayer(savior, 2))
		return;

	if (GetEntProp(savior, Prop_Send, "m_iHealth") >= g_hCvar_MaxmuimHealth.IntValue)
		return;

	int patient = GetClientOfUserId(event.GetInt("victim"));
	if (!ValidatePlayer(patient, 2))
		return;

	if (!IsFakeClient(savior))
		CPrintToChat(savior, "%t", "Rescured", g_hCvar_RescureReward.IntValue, patient);

	RewardHealth(savior, g_hCvar_RescureReward.IntValue);
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hCvar_HealReward.IntValue)
		return;

	int healer = GetClientOfUserId(event.GetInt("userid"));
	if (!ValidatePlayer(healer, 2))
		return;

	if (GetEntProp(healer, Prop_Send, "m_iHealth") >= g_hCvar_MaxmuimHealth.IntValue)
		return;

	int patient = GetClientOfUserId(event.GetInt("subject"));
	if (!ValidatePlayer(patient, 2))
		return;

	if (!IsFakeClient(healer))
		CPrintToChat(healer, "%t", "HealSuccess", g_hCvar_HealReward.IntValue, patient);

	RewardHealth(healer, g_hCvar_HealReward.IntValue);
}

void Event_AwardEarned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!ValidatePlayer(client, 2))
		return;

	if (GetEntProp(client, Prop_Send, "m_iHealth") >= g_hCvar_MaxmuimHealth.IntValue)
		return;

	int award = event.GetInt("award");
	switch (award)
	{
		case RewordType_ProtectFriendly:
		{
			if (!g_hCvar_RewardEvent[ProtectFriendly].IntValue)
				return;

			int teammate = event.GetInt("subjectentid");
			if (!IsFakeClient(client))
				CPrintToChat(client, "%t", "ProtectFriendly", g_hCvar_RewardEvent[ProtectFriendly].IntValue, teammate);

			RewardHealth(client, g_hCvar_RewardEvent[ProtectFriendly].IntValue);
		}

		case RewardType_SavedFromSIControl:
		{
			if (!g_hCvar_RewardEvent[SavedFromSIControl].IntValue)
				return;

			int teammate = event.GetInt("subjectentid");
			if (!IsFakeClient(client))
				CPrintToChat(client, "%t", "SavedFromSIControl", g_hCvar_RewardEvent[SavedFromSIControl].IntValue, teammate);

			RewardHealth(client, g_hCvar_RewardEvent[SavedFromSIControl].IntValue);
		}
	}
}

// from l4d2_health_rewards by 豆瓣酱な
void RewardHealth(int client, int iReward)
{
	int realHealth = GetClientHealth(client);
	int tempHealth = GetPlayerTempHealth(client);

	if (tempHealth == -1)
		tempHealth = 0;
	
	if (realHealth + tempHealth + iReward > g_hCvar_MaxmuimHealth.IntValue)
	{
		float overflowHealth, occupiedHealth;
		overflowHealth = float(realHealth + tempHealth + iReward - g_hCvar_MaxmuimHealth.IntValue);
		occupiedHealth = (tempHealth < overflowHealth) ? 0.0 : (float(tempHealth) - overflowHealth);
		
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", occupiedHealth);
	}
		
	((realHealth + iReward) < g_hCvar_MaxmuimHealth.IntValue) ?
	SetEntProp(client, Prop_Send, "m_iHealth", realHealth + iReward) :
	SetEntProp(client, Prop_Send, "m_iHealth", realHealth > g_hCvar_MaxmuimHealth.IntValue ? realHealth : g_hCvar_MaxmuimHealth.IntValue);
}

// from left4dhooks_stocks by Silvers
stock int GetPlayerTempHealth(int client)
{
    static ConVar pain_pills_decay_rate = null;
    if (!pain_pills_decay_rate)
    {
        pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
        if (!pain_pills_decay_rate)
            return -1;
    }

    int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - 
								((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * 
								pain_pills_decay_rate.FloatValue)) - 1;
    return tempHealth < 0 ? 0 : tempHealth;
}

stock bool ValidatePlayer(int client, int team)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientInGame(client) || GetClientTeam(client) != team)
		return false;

	return true;
}

// from attachment_api by Silvers
stock void StrToLowerCase(const char[] input, char[] output, int maxlength)
{
	int pos;
	while( input[pos] != 0 && pos < maxlength )
	{
		output[pos] = CharToLower(input[pos]);
		pos++;
	}

	output[pos] = 0;
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