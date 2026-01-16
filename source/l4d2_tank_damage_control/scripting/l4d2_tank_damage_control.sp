#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

/**
 * An extension of l4d2_tank_damage_cvars by Visor, A1m`.
 */
#define PLUGIN_VERSION "1.0"
#define DEBUG		   0

/*
 * @remarks	sequences, for L4D2:
 * @remarks	sequences(punches)	40 uppercut), 43 (right hook), 45 (left hook), 46 and 47 (pounding the ground)
 * @remarks	sequences(throws)	48 undercut), 49 (1handed overhand), 50 (throw from the hip), 51 (2handed overhand)
 */
enum PunchType
{
	PunchType_UpperCut		 = 0,
	PunchType_RightHook		 = 1,
	PunchType_LeftHook		 = 2,
	PunchType_PoundingGround = 3,

	PunchTypeSize			 = 4
}

enum ThrowType
{
	ThrowType_UnderCut		  = 0,
	ThrowType_1HandedOverhand = 1,
	ThrowType_ThrowFromHip	  = 2,
	ThrowType_2HandedOverhand = 3,

	ThrowTypeSize			  = 4
}

enum DifficultyType
{
	DifficultyType_Easy		= 0,
	DifficultyType_Normal	= 1,
	DifficultyType_Advanced = 2,
	DifficultyType_Expert	= 3,

	DifficultyTypeSize		= 4
}

int			   g_iCurrentPunchType = 0;
int			   g_iCurrentThrowType = 0;
DifficultyType g_iDifficulty;

ConVar		   g_hCvar_TankDamage_Puch[PunchTypeSize]			= { null, ... };
ConVar		   g_hCvar_TankDamage_Rock[ThrowTypeSize]			= { null, ... };
ConVar		   g_hCvar_DifficultyMultiplier[DifficultyTypeSize] = { null, ... };
ConVar		   g_hCvar_ObeyDifficulty							= null;

public Plugin myinfo =
{
	name = "[L4D2] Tank Damage Control",
	author = "blueblur",
	description = "Quanitizes the damage of tanks based on the punch and throw animations used.",
	version	= PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_tank_damage_control_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DEVELOPMENTONLY | FCVAR_NOTIFY);

	g_hCvar_TankDamage_Puch[PunchType_UpperCut]			  = CreateConVar("tank_punch_damage_uppercut", "24.0", "Tank Punch Damage for Uppercut animation. Set a float value in it");
	g_hCvar_TankDamage_Puch[PunchType_LeftHook]			  = CreateConVar("tank_punch_damage_lefthook", "24.0", "Tank Punch Damage for Left Hook animation. Set a float value in it");
	g_hCvar_TankDamage_Puch[PunchType_RightHook]		  = CreateConVar("tank_punch_damage_righthook", "24.0", "Tank Punch Damage for Right Hook animation. Set a float value in it");
	g_hCvar_TankDamage_Puch[PunchType_PoundingGround]	  = CreateConVar("tank_punch_damage_poundingground", "24.0", "Tank Punch Damage for Pounding Ground animation. Set a float value in it");

	g_hCvar_TankDamage_Rock[ThrowType_UnderCut]			  = CreateConVar("tank_rock_damage_undercut", "24.0", "Tank Rock Damage for Undercut animation. Set a float value in it");
	g_hCvar_TankDamage_Rock[ThrowType_1HandedOverhand]	  = CreateConVar("tank_rock_damage_overhand_1handed", "24.0", "Tank Rock Damage for 1Handed Overhand animation. Set a float value in it");
	g_hCvar_TankDamage_Rock[ThrowType_ThrowFromHip]		  = CreateConVar("tank_rock_damage_throwfromhip", "24.0", "Tank Rock Damage for Throw From Hip animation. Set a float value in it");
	g_hCvar_TankDamage_Rock[ThrowType_2HandedOverhand]	  = CreateConVar("tank_rock_damage_overhand_2handed", "24.0", "Tank Rock Damage for 2Handed Overhand animation. Set a float value in it");

	g_hCvar_DifficultyMultiplier[DifficultyType_Easy]	  = CreateConVar("tank_damage_difficulty_easy", "0.1", "Difficulty Multiplier for Easy Difficulty. Set a float value in it");
	g_hCvar_DifficultyMultiplier[DifficultyType_Normal]	  = CreateConVar("tank_damage_difficulty_normal", "0.2", "Difficulty Multiplier for Normal Difficulty. Set a float value in it");
	g_hCvar_DifficultyMultiplier[DifficultyType_Advanced] = CreateConVar("tank_damage_difficulty_advanced", "0.5", "Difficulty Multiplier for Advanced Difficulty. Set a float value in it");
	g_hCvar_DifficultyMultiplier[DifficultyType_Expert]	  = CreateConVar("tank_damage_difficulty_expert", "1.0", "Difficulty Multiplier for Expert Difficulty. Set a float value in it");

	g_hCvar_ObeyDifficulty								  = CreateConVar("tank_damage_obey_difficulty", "0", "Obey Difficulty Multiplier. Set 1 to enable, 0 to disable", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2_tank_damage_control");

	FindConVar("z_difficulty").AddChangeHook(OnDifficultyChanged);
	HookEvent("tank_killed", Event_TankKilled, EventHookMode_PostNoCopy);
	HookSurvivors();
}

void HookSurvivors()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	g_iCurrentPunchType = 0;
	g_iCurrentThrowType = 0;
}

public void OnClientPutInServer(int client)
{
	if (GetClientTeam(client) == 2)
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
/*
public void OnClientDisconnect(int client)
{
	if (GetClientTeam(client) == 2)
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
*/
public Action L4D2_OnSelectTankAttack(int client, int &sequence)
{
	if (sequence < 48)
		g_iCurrentPunchType = sequence;
	else
		g_iCurrentThrowType = sequence;

	return Plugin_Continue;
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damagetype != DMG_CLUB)
		return Plugin_Continue;

	if (!IsSurvivor(victim) || !IsTank(attacker))
		return Plugin_Continue;

	// this is rock
	if (inflictor <= MaxClients || !IsValidEdict(inflictor))
		return Plugin_Continue;

	char sClassName[64];
	GetEdictClassname(inflictor, sClassName, sizeof(sClassName));

#if DEBUG
	PrintToChatAll("Before Change:iVictim: %N, iAttacker: %N, iInflictor, %s (%d), fDamage: %f, iDamagetype: %d",
				   victim, attacker, sClassName, inflictor, damage, damagetype);
#endif

	// punch
	if (strcmp("weapon_tank_claw", sClassName) == 0)
	{
		switch (g_iCurrentPunchType)
		{
			case 40:	// uppercut
				damage = g_hCvar_TankDamage_Puch[PunchType_UpperCut].FloatValue;

			case 43:	// right hook
				damage = g_hCvar_TankDamage_Puch[PunchType_RightHook].FloatValue;

			case 45:	// left hook
				damage = g_hCvar_TankDamage_Puch[PunchType_LeftHook].FloatValue;

			case 46:	// pounding ground
				damage = g_hCvar_TankDamage_Puch[PunchType_PoundingGround].FloatValue;
		}

		if (g_hCvar_ObeyDifficulty.BoolValue)
		{
			switch (g_iDifficulty)
			{
				case DifficultyType_Easy:
					damage *= g_hCvar_DifficultyMultiplier[DifficultyType_Easy].FloatValue;

				case DifficultyType_Normal:
					damage *= g_hCvar_DifficultyMultiplier[DifficultyType_Normal].FloatValue;

				case DifficultyType_Advanced:
					damage *= g_hCvar_DifficultyMultiplier[DifficultyType_Advanced].FloatValue;

				case DifficultyType_Expert:
					damage *= g_hCvar_DifficultyMultiplier[DifficultyType_Expert].FloatValue;
			}
		}
#if DEBUG
		PrintToChatAll("After Change:iVictim: %N, iAttacker: %N, iInflictor, %s (%d), fDamage: %f, iDamagetype: %d",
					   victim, attacker, sClassName, inflictor, damage, damagetype);
#endif
		return Plugin_Changed;
	}
	else if (strcmp("tank_rock", sClassName) == 0)
	{
		switch (g_iCurrentThrowType)
		{
			case 48:	// undercut
				damage = g_hCvar_TankDamage_Rock[ThrowType_UnderCut].FloatValue;

			case 49:	// 1handed overhand
				damage = g_hCvar_TankDamage_Rock[ThrowType_1HandedOverhand].FloatValue;

			case 50:	// throw from the hip
				damage = g_hCvar_TankDamage_Rock[ThrowType_ThrowFromHip].FloatValue;

			case 51:	// 2handed overhand
				damage = g_hCvar_TankDamage_Rock[ThrowType_2HandedOverhand].FloatValue;
		}

		if (g_hCvar_ObeyDifficulty.BoolValue)
		{
			switch (g_iDifficulty)
			{
				case DifficultyType_Easy:
					damage *= g_hCvar_DifficultyMultiplier[DifficultyType_Easy].FloatValue;

				case DifficultyType_Normal:
					damage *= g_hCvar_DifficultyMultiplier[DifficultyType_Normal].FloatValue;

				case DifficultyType_Advanced:
					damage *= g_hCvar_DifficultyMultiplier[DifficultyType_Advanced].FloatValue;

				case DifficultyType_Expert:
					damage *= g_hCvar_DifficultyMultiplier[DifficultyType_Expert].FloatValue;
			}
		}
#if DEBUG
		PrintToChatAll("After Change:iVictim: %N, iAttacker: %N, iInflictor, %s (%d), fDamage: %f, iDamagetype: %d",
					   victim, attacker, sClassName, inflictor, damage, damagetype);
#endif
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

bool IsTank(int client)
{
	return (client > 0 && client <= MaxClients
			&& IsClientInGame(client)
			&& GetClientTeam(client) == 3
			&& GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients
			&& IsClientInGame(client)
			&& GetClientTeam(client) == 2);
}

void OnDifficultyChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char sDifficulty[32];
	strcopy(sDifficulty, sizeof(sDifficulty), newValue);

	// are you case sensitive?
	if (strcmp(sDifficulty, "Easy", false) == 0)
		g_iDifficulty = DifficultyType_Easy;
	else if (strcmp(sDifficulty, "Normal", false) == 0)
		g_iDifficulty = DifficultyType_Normal;
	else if (strcmp(sDifficulty, "Hard", false) == 0)
		g_iDifficulty = DifficultyType_Advanced;
	else if (strcmp(sDifficulty, "Impossible", false) == 0)
		g_iDifficulty = DifficultyType_Expert;
}