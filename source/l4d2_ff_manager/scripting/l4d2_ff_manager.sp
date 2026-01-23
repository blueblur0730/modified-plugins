#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2util>
#include <colors>

#define CONFIG_PATH "configs/l4d2_ff_manager.cfg"

ConVar
	g_hCvar_Enable,
	g_hCvar_ShouldBlockFF,
	g_hCvar_AnnounceType,
	g_hCvar_EnableModifier;

char g_sConfigPath[64];

enum struct DamageData_t
{
	int iBasic;
	int iRange;
	float flRangeModifier;
	int iGainRange;
	int iDifficultyMultipler;
}

enum struct WeaponData_t
{
	bool bInitialized;
	StringMap hMapGun;
	StringMap hMapMelee;

	void Init(){
		KeyValues kv = new KeyValues("");
		if (!kv.ImportFromFile(g_sConfigPath)) {
			LogError("Could not load config file: %s", g_sConfigPath);
			this.bInitialized = false;
			delete kv;
			return; 
		}

		if (this.hMapGun) 
			delete this.hMapGun;

		this.hMapGun = new StringMap();

		if (this.hMapMelee)
			delete this.hMapMelee;

		this.hMapMelee = new StringMap();

		char z_difficulty[64];
		FindConVar("z_difficulty").GetString(z_difficulty, sizeof(z_difficulty));

		if (kv.GotoFirstSubKey())
		{
			do
			{
				char sName[64];
				kv.GetSectionName(sName, sizeof(sName));

				if (strcmp(sName, "weapon_melee") == 0)
				{
					int node;
					kv.GetSectionSymbol(node);
					if (kv.GotoFirstSubKey())
					{
						do
						{
							DamageData_t data;
							kv.GetSectionName(sName, sizeof(sName));
							data.iBasic = kv.GetNum("basic", -1);
							data.iRange = kv.GetNum("range", -1);
							data.flRangeModifier = kv.GetFloat("range_modifier", -1.0);
							data.iGainRange = kv.GetNum("gain_range", -1);

							if (kv.JumpToKey("difficulty"))
							{
								data.iDifficultyMultipler = kv.GetNum(z_difficulty, -1);
								// PrintToServer("Found difficulty key %s for weapon %s, got multiplier %d", z_difficulty, sName, iMultipler);
								kv.GoBack();
							}

							this.hMapMelee.SetArray(sName, data, sizeof(DamageData_t));
						}
						while (kv.GotoNextKey());
					}
					kv.JumpToKeySymbol(node);
				}
				else 
				{
					DamageData_t data;
					data.iBasic = kv.GetNum("basic", -1);
					data.iRange = kv.GetNum("range", -1);
					data.flRangeModifier = kv.GetFloat("range_modifier", -1.0);
					data.iGainRange = kv.GetNum("gain_range", -1);

					if (kv.JumpToKey("difficulty"))
					{
						data.iDifficultyMultipler = kv.GetNum(z_difficulty, -1);
						// PrintToServer("Found difficulty key %s for weapon %s, got multiplier %d", z_difficulty, sName, iMultipler);
						kv.GoBack();
					}

					this.hMapGun.SetArray(sName, data, sizeof(DamageData_t));
				}
			}
			while (kv.GotoNextKey());
		}

		delete kv;
		this.bInitialized = true;
	}

	void Free()
	{
		delete this.hMapGun;
		delete this.hMapMelee;
	}

	float GetGunDamage(const char[] sWeaponName)
	{
		if (!this.bInitialized || sWeaponName[0] == '\0')
			return -1.0;

		DamageData_t data;
		float flFFDamage;
		if (!this.hMapGun.GetArray(sWeaponName, data, sizeof(DamageData_t)))
			return -1.0;

		if (data.iBasic == -1 || data.iDifficultyMultipler == -1)
			return -1.0;

		//PrintToServer("Basic: %d, Difficulty Multipler: %d", data.iBasic, data.iDifficultyMultipler);
		flFFDamage = float(data.iBasic) * float(data.iDifficultyMultipler);
		flFFDamage = float(RoundToNearest(flFFDamage));
		return flFFDamage;
	}

	float GetRangeDecayedDamage(float flDamage, float flDistance, const char[] sWeaponName)
	{
		if (!this.bInitialized || sWeaponName[0] == '\0')
			return -1.0;

		if (flDamage <= 0 || flDistance <= 0)
			return -1.0;

		DamageData_t data;
		if (!this.hMapGun.GetArray(sWeaponName, data, sizeof(DamageData_t)))
			return -1.0;

		int iRange = data.iRange;
		float flRangeModifier = data.flRangeModifier;
		int iGainRange = data.iGainRange;
		//PrintToServer("Range: %d, Modifier: %.02f, Gain Range: %d", iRange, flRangeModifier, iGainRange);

		if (FloatCompare(flRangeModifier, -1.0) <= 0)
			return -1.0;

		float flRangeDecayedDamage = flDamage * Pow(flRangeModifier, flDistance / 500.0);
		//PrintToServer("Range Decayed Damage: %.2f", flRangeDecayedDamage);
		if ((iRange != -1 && iGainRange != -1) && flDistance > iGainRange)
		{
			flRangeDecayedDamage *= ((float(iRange) - flDistance) / float(iRange - iGainRange)); 
			//PrintToServer("Finale Range Decayed Damage: %.2f", flRangeDecayedDamage);
		}

		flRangeDecayedDamage = float(RoundToNearest(flRangeDecayedDamage));
		return flRangeDecayedDamage;
	}

	float GetMeleeDamage(const char[] sWeaponName)
	{
		if (!this.bInitialized || sWeaponName[0] == '\0')
			return -1.0;

		DamageData_t data;
		float flFFDamage;
		if (!this.hMapMelee.GetArray(sWeaponName, data, sizeof(DamageData_t)))
			return -1.0;

		if (data.iBasic == -1 || data.iDifficultyMultipler == -1)
			return -1.0;

		flFFDamage = float(data.iBasic) * float(data.iDifficultyMultipler);
		return flFFDamage;
	}
}
WeaponData_t g_WeaponData;

int			 g_iDamageCache[MAXPLAYERS + 1][MAXPLAYERS + 1];	// Used to temporarily store Friendly Fire Damage between teammates
Handle		 g_hFFTimer[MAXPLAYERS + 1] = { null, ... };		// Used to be able to disable the FF timer when they do more FF

#define PLUGIN_VERSION "r2.0"

public Plugin myinfo =
{
	name = "[L4D2] Friendly Fire Manager",
	author = "Frustian, HarryPotter, blueblur",
	description = "FF Announcer, Controller, Modifier merger.",
	version = PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	if (!BuildConfigPath())
		SetFailState("Config File \"" ... CONFIG_PATH... "\" Not Found.");

	LoadTranslation("l4d2_ff_manager.phrases");

	CreateConVar("l4d2_ff_manager_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvar_Enable		   = CreateConVar("l4d2_ff_manager_enable", "1", "0=Plugin off, 1=Plugin on.", _, true, 0.0, true, 1.0);
	g_hCvar_AnnounceType   = CreateConVar("l4d2_ff_manager_type", "1", "Changes how ff announce displays FF damage (0: Disable, 1:In chat; 2: In Hint Box; 3: In center text)", _, true, 0.0, true, 3.0);
	g_hCvar_ShouldBlockFF  = CreateConVar("l4d2_ff_manager_blockff", "0", "0=keep FF damage, 1=block. If off, also turn off notice.", _, true, 0.0, true, 1.0);
	g_hCvar_EnableModifier = CreateConVar("l4d2_ff_manager_enable_modifier", "1", "0=Disable FF Modifier, 1=Enable FF Modifier", _, true, 0.0, true, 1.0);

	RegAdminCmd("sm_reload_ff", Command_ReloadFF, ADMFLAG_CONFIG, "Reloads the FF config file.");
	RegAdminCmd("sm_ff_config", Command_FFConfig, ADMFLAG_CONFIG, "Displays the FF config file.");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_hurt_concise", Event_HurtConcise, EventHookMode_Post);
	HookEvent("player_incapacitated_start", Event_IncapacitatedStart, EventHookMode_Post);

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);				  // trigger twice in versus mode, one when all survivors wipe out or make it to saferom, one when first round ends (second round_start begins).
	HookEvent("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy);			  // all survivors make it to saferoom, and server is about to change next level in coop mode (does not trigger round_end)
	HookEvent("mission_lost", Event_RoundEnd, EventHookMode_PostNoCopy);			  // all survivors wipe out in coop mode (also triggers round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy);	  // final map final rescue vehicle leaving  (does not trigger round_end)

	for (int i = 1; i <= MaxClients; i++)
		OnClientPutInServer(i);

	g_WeaponData.Init();
}

Action Command_ReloadFF(int client, int args)
{
	g_WeaponData.Init();
	PrintToServer("FF Config Reloaded.");
	return Plugin_Handled;
}

Action Command_FFConfig(int client, int args)
{
	StringMapSnapshot hGunSnapshot	 = g_WeaponData.hMapGun.Snapshot();
	StringMapSnapshot hMeleeSnapshot = g_WeaponData.hMapMelee.Snapshot();

	for (int i = 0; i < hGunSnapshot.Length; i++)
	{
		char  sWeaponName[64];
		hGunSnapshot.GetKey(i, sWeaponName, sizeof(sWeaponName));

		DamageData_t data;
		g_WeaponData.hMapGun.GetArray(sWeaponName, data, sizeof(DamageData_t));
		PrintToServer("[FF Config] Gun: %s => Basic Damage: %d, Difficulty Multipler: %d, Range: %d, Range Modifier: %.02f, Gain Range: %d", sWeaponName, data.iBasic, data.iDifficultyMultipler, data.iRange, data.flRangeModifier, data.iGainRange);
	}

	for (int j = 0; j < hMeleeSnapshot.Length; j++)
	{
		char  sWeaponName[64];
		hMeleeSnapshot.GetKey(j, sWeaponName, sizeof(sWeaponName));

		DamageData_t data;
		g_WeaponData.hMapMelee.GetArray(sWeaponName, data, sizeof(DamageData_t));
		PrintToServer("[FF Config] Melee: %s => Basic Damage: %d, Difficulty Multipler: %d", sWeaponName, data.iBasic, data.iDifficultyMultipler);
	}

	delete hGunSnapshot;
	delete hMeleeSnapshot;
	return Plugin_Handled;
}

public void OnPluginEnd()
{
	ResetTimer();
	g_WeaponData.Free();
	// g_hCvar_ShouldBlockFF.RestoreDefault();
}

public void OnClientPutInServer(int client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
		return;

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);	  // process melee damage.
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public void OnMapEnd()
{
	ResetTimer();
}

/**
 * We introduced range decay mechanism here (works in the original game too)
 * Within the Shoot Range, damages are done.
 * Splict it into two ranges.
 * 1. Shoot Range: 0 - 1500 units
 * 2. Gain Range: 1500 - 3000 units (most cases 3000, maybe 2500 or 3500.)
 * 
 * See finale damage as f(x), distance as x, basic damage as d, range modifier as r, gain range as g (ussually 1500)
 * In shoot range the formula is:
 * f(x) = d * (r ^ (x / 500)), 0 < x <= g
 * 
 * See max range as m (usually 3000), in gain range the formula is:
 * f(x_gain) = f(x) * (m - x / m - g), g < x <= m
*/

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (victim < 1 || victim > MaxClients)
		return Plugin_Continue;

	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(victim) || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2 || GetClientTeam(victim) != 2)
		return Plugin_Continue;

	if (!g_hCvar_ShouldBlockFF.BoolValue)
	{
		if (g_hCvar_EnableModifier.BoolValue)
		{
			// we left shotguns to alive callback only.
			int wepid = IdentifyWeapon(weapon);
			if (wepid != WEPID_MELEE && wepid != WEPID_PUMPSHOTGUN && wepid != WEPID_AUTOSHOTGUN && wepid != WEPID_SHOTGUN_CHROME && wepid != WEPID_SHOTGUN_SPAS)
			{
				char sName[64];
				GetWeaponName(wepid, sName, sizeof(sName));

				float flDamage = g_WeaponData.GetGunDamage(sName);
				//PrintToServer("Gun: %s, Damage: %.2f, Original Damage: %.2f", sName, flDamage, damage);

				if (flDamage != -1.0)
				{
					float vecMyPosition[3], vecLength[3];
					GetClientAbsOrigin(attacker, vecMyPosition);
					MakeVectorFromPoints(vecMyPosition, damagePosition, vecLength);
					float flDistance = GetVectorLength(vecLength);
					float flRangeDecayedDamage = g_WeaponData.GetRangeDecayedDamage(flDamage, flDistance, sName);
					//PrintToServer("Got Rounded Range Decayed Damage: %.2f", flRangeDecayedDamage);
					if (flRangeDecayedDamage != -1.0)
					{
						damage = flRangeDecayedDamage;
						return Plugin_Changed;
					}
					else
					{
						damage = flDamage;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	else
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (victim < 1 || victim > MaxClients)
		return Plugin_Continue;

	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(victim) || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2 || GetClientTeam(victim) != 2)
		return Plugin_Continue;

	if (!g_hCvar_ShouldBlockFF.BoolValue)
	{
		if (g_hCvar_EnableModifier.BoolValue)
		{
			int wepid = IdentifyWeapon(weapon);
			if (wepid == WEPID_MELEE)
			{
				int meleeid = IdentifyMeleeWeapon(weapon);
				if (meleeid != WEPID_MELEE_NONE)
				{
					// melee damage triggers multiple times in alive callback same as normal callback, but only once is effective damage.
					// we only prcesses the real damage number.
					if (FloatCompare(damage, 0.0) <= 0.0)
						return Plugin_Continue;

					char sName[64];
					GetMeleeWeaponName(meleeid, sName, sizeof(sName));

					float flDamage = g_WeaponData.GetMeleeDamage(sName);
					//PrintToServer("Melee: %s, Damage: %.2f, Original Damage: %.2f", sName, flDamage, damage);
					if (flDamage != -1.0)
					{
						damage = flDamage;
						return Plugin_Changed;
					}
				}
			}
			else if (wepid == WEPID_PUMPSHOTGUN || wepid == WEPID_AUTOSHOTGUN || wepid == WEPID_SHOTGUN_CHROME || wepid == WEPID_SHOTGUN_SPAS)
			{
				char sName[64];
				GetWeaponName(wepid, sName, sizeof(sName));

				float flDamage = g_WeaponData.GetGunDamage(sName);
				//PrintToServer("Gun: %s, Damage: %.2f, Original Damage: %.2f", sName, flDamage, damage);

				if (flDamage != -1.0)
				{
					float vecMyPosition[3], vecLength[3];
					GetClientAbsOrigin(attacker, vecMyPosition);
					MakeVectorFromPoints(vecMyPosition, damagePosition, vecLength);
					float flDistance = GetVectorLength(vecLength);
					float flRangeDecayedDamage = g_WeaponData.GetRangeDecayedDamage(flDamage, flDistance, sName);
					if (flRangeDecayedDamage != -1.0)
					{
						damage = flRangeDecayedDamage;
						return Plugin_Changed;
					}
					else
					{
						damage = flDamage;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	else
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!g_hCvar_ShouldBlockFF.BoolValue)
		return Plugin_Continue;

	if (victim < 1 || victim > MaxClients)
		return Plugin_Continue;

	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(victim) || !IsClientInGame(attacker))
		return Plugin_Continue;

	if (GetClientTeam(attacker) != 2 || GetClientTeam(victim) != 2)
		return Plugin_Continue;

	return Plugin_Handled;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		OnClientPutInServer(i);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetTimer();
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hCvar_ShouldBlockFF.BoolValue || !g_hCvar_Enable.BoolValue)
		return;

	int victim	 = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if ((attacker <= 0 || attacker > MaxClients) || (victim <= 0 || victim > MaxClients))
		return;

	if (attacker == victim)
		return;

	if (!IsClientInGame(attacker) || !IsClientInGame(victim))
		return;

	if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2)
		CPrintToChatAll("%t", "KILL", attacker, victim);
}

void Event_HurtConcise(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hCvar_ShouldBlockFF.BoolValue || !g_hCvar_Enable.BoolValue)
		return;

	int attacker = event.GetInt("attackerentid");
	int victim	 = GetClientOfUserId(event.GetInt("userid"));

	if ((attacker <= 0 || attacker > MaxClients) || (victim <= 0 || victim > MaxClients))
		return;

	if (attacker == victim)
		return;

	if (!IsClientInGame(attacker) || !IsClientInGame(victim))
		return;

	if (IsFakeClient(attacker))
		return;

	if (GetClientTeam(attacker) != 2 || GetClientTeam(victim) != 2)
		return;

	// If the player is already friendly firing teammates, resets the announce timer and adds to the damage
	int damage = event.GetInt("dmg_health");
	if (g_hFFTimer[attacker])
	{
		g_iDamageCache[attacker][victim] += damage;
		//PrintToServer("Adding damage to cache. g_iDamageCache[%d][%d] = %d", attacker, victim, g_iDamageCache[attacker][victim]);
		g_hFFTimer[attacker] = null;
		delete g_hFFTimer[attacker];
		g_hFFTimer[attacker] = CreateTimer(1.0, Timer_AnnounceFF, attacker);
	}
	// If it's the first friendly fire by that player, it will start the announce timer and store the damage done.
	else
	{
		g_iDamageCache[attacker][victim] = damage;
		//PrintToServer("Adding damage to cache. g_iDamageCache[%d][%d] = %d", attacker, victim, g_iDamageCache[attacker][victim]);
		g_hFFTimer[attacker]			 = CreateTimer(1.0, Timer_AnnounceFF, attacker);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i != attacker && i != victim)
				g_iDamageCache[attacker][i] = 0;
		}
	}
}

void Event_IncapacitatedStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hCvar_ShouldBlockFF.BoolValue || !g_hCvar_Enable.BoolValue)
		return;

	int victim	 = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if ((attacker <= 0 || attacker > MaxClients) || (victim <= 0 || victim > MaxClients))
		return;

	if (attacker == victim)
		return;

	if (!IsClientInGame(attacker) || !IsClientInGame(victim))
		return;

	if (IsFakeClient(attacker))
		return;

	if (GetClientTeam(attacker) != 2 || GetClientTeam(victim) != 2)
		return;

	int damage = GetClientHealth(victim) + GetSurvivorTempHealth(victim);

	// If the player is already friendly firing teammates, resets the announce timer and adds to the damage
	if (g_hFFTimer[attacker])
	{
		g_iDamageCache[attacker][victim] += damage;
		g_hFFTimer[attacker] = null;
		delete g_hFFTimer[attacker];
		g_hFFTimer[attacker] = CreateTimer(1.0, Timer_AnnounceFF, attacker);
	}
	// If it's the first friendly fire by that player, it will start the announce timer and store the damage done.
	else
	{
		g_iDamageCache[attacker][victim] = damage;
		g_hFFTimer[attacker]			 = CreateTimer(1.0, Timer_AnnounceFF, attacker);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i != attacker && i != victim)
				g_iDamageCache[attacker][i] = 0;
		}
	}
}

// Called if the attacker did not friendly fire recently, and announces all FF they did
Action Timer_AnnounceFF(Handle timer, int attackerc)
{
	char victimName[128];
	char attackerName[128];

	IsClientInGame(attackerc) ? view_as<int>(GetClientName(attackerc, attackerName, sizeof(attackerName))) : Format(attackerName, sizeof(attackerName), "N/A");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2)
			continue;

		//PrintToServer("Checking FF for %d: g_iDamageCache[%d][%d] = %d", i, attackerc, i, g_iDamageCache[attackerc][i]);
		if (!g_iDamageCache[attackerc][i] || attackerc == i)
			continue;

		GetClientName(i, victimName, sizeof(victimName));
		switch (g_hCvar_AnnounceType.IntValue)
		{
			case 1:
			{
				CPrintToChat(attackerc, "%t", "FF_dealt_coloured", g_iDamageCache[attackerc][i], victimName);
				CPrintToChat(i, "%t", "FF_receive_coloured", attackerName, g_iDamageCache[attackerc][i]);
			}
			case 2:
			{
				PrintHintText(attackerc, "%t", "FF_dealt", g_iDamageCache[attackerc][i], victimName);
				PrintHintText(i, "%t", "FF_receive", g_iDamageCache[attackerc][i]);
			}
			case 3:
			{
				PrintCenterText(attackerc, "%t", "FF_dealt", g_iDamageCache[attackerc][i], victimName);
				PrintCenterText(i, "%t", "FF_receive", attackerName, g_iDamageCache[attackerc][i]);
			}
		}

		g_iDamageCache[attackerc][i] = 0;
	}

	g_hFFTimer[attackerc] = null;
	return Plugin_Continue;
}

void ResetTimer()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_hFFTimer[i])
		{
			g_hFFTimer[i] = null;
			//delete g_hFFTimer[i];
		}
	}
}

stock int GetSurvivorTempHealth(int client)
{
	float		  fHealthBuffer			= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float		  fHealthBufferDuration = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");

	static ConVar pain_pills_decay_rate;
	if (!pain_pills_decay_rate)
		pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");

	int iTempHp = RoundToCeil(fHealthBuffer - (fHealthBufferDuration * pain_pills_decay_rate.FloatValue)) - 1;

	return (iTempHp > 0) ? iTempHp : 0;
}

stock bool BuildConfigPath()
{
	BuildPath(Path_SM, g_sConfigPath, sizeof(g_sConfigPath), CONFIG_PATH);
	return FileExists(g_sConfigPath);
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