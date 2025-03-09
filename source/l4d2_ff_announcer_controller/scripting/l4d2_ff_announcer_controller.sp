#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

ConVar 
    g_hCvarEnable,
    g_hCvar_ShouldBlockFF,
    g_hCvarAnnounceType;

bool g_bLateLoad = false;

bool g_bCvarEnable;
int g_iCvarAnnounceType;
bool g_bShouldBlockFF;

int g_iDamageCache[MAXPLAYERS + 1][MAXPLAYERS+1]; // Used to temporarily store Friendly Fire Damage between teammates
Handle g_hFFTimer[MAXPLAYERS + 1] = { null, ... }; // Used to be able to disable the FF timer when they do more FF

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo =
{
	name = "[L4D/2] Friendly Fire Announcer & Controller",
	author = "Frustian, HarryPotter, blueblur",
	description = "FF Announcer and Controller merger.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("l4d2_ff_announcer_controller.phrases");

	CreateConVar("l4d2_ff_announcer_controller_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvarEnable 			= CreateConVar( "l4dffannounce_enable",     "1",   	"0=Plugin off, 1=Plugin on.", _, true, 0.0, true, 1.0);
	g_hCvarAnnounceType 	= CreateConVar( "l4dffannounce_type", 		"1", 	"Changes how ff announce displays FF damage (0: Disable, 1:In chat; 2: In Hint Box; 3: In center text)", _, true, 0.0, true, 3.0);
    g_hCvar_ShouldBlockFF 	= CreateConVar( "l4dffannounce_blockff", 	"1", 	"0=keep FF damage, 1=block. If off, also turn off notice.", _, true, 0.0, true, 1.0);

	GetCvars();
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAnnounceType.AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_ShouldBlockFF.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("player_hurt_concise", Event_HurtConcise, EventHookMode_Post);
	HookEvent("player_incapacitated_start", Event_IncapacitatedStart, EventHookMode_Post);

	HookEvent("player_death", 			Event_PlayerDeath,  EventHookMode_Post);
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy); //trigger twice in versus mode, one when all survivors wipe out or make it to saferom, one when first round ends (second round_start begins).
	HookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy); //all survivors make it to saferoom, and server is about to change next level in coop mode (does not trigger round_end) 
	HookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy); //all survivors wipe out in coop mode (also triggers round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd,		EventHookMode_PostNoCopy); //final map final rescue vehicle leaving  (does not trigger round_end)

	HookEntityOutput("info_director", "OnGameplayStart", OnGameplayStart);

	if (g_bLateLoad)
		HookPlayers();
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public void OnMapEnd()
{
	ResetTimer();
}

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
    g_bCvarEnable = g_hCvarEnable.BoolValue;
    g_iCvarAnnounceType = g_hCvarAnnounceType.IntValue;
	g_bShouldBlockFF = g_hCvar_ShouldBlockFF.BoolValue;
}

void OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
	HookPlayers();
}

void HookPlayers()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
		{
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
		}
	}  
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bShouldBlockFF)
        return Plugin_Continue;

	if (victim < 1 || victim > MaxClients)
        return Plugin_Continue;

	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;

    if (!IsClientInGame(victim) || !IsClientInGame(attacker))
        return Plugin_Continue;

    if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2)
	{
		damage = 0.0;
		damagetype = DMG_GENERIC;
        return Plugin_Changed;
	}

    return Plugin_Continue;
}

Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (!g_bShouldBlockFF)
        return Plugin_Continue;

	if (victim < 1 || victim > MaxClients)
        return Plugin_Continue;

	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;

    if (!IsClientInGame(victim) || !IsClientInGame(attacker))
        return Plugin_Continue;

    if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2)
	{
		damage = 0.0;
		damagetype = DMG_GENERIC;
        return Plugin_Handled;
	}

    return Plugin_Continue;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	ResetTimer();
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
    if (g_bShouldBlockFF)
        return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if ( !victim || !IsClientInGame(victim) || attacker == victim ) return;
	if ( !attacker || !IsClientInGame(attacker) ) return;

	if(GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2)
		CPrintToChatAll("%t", "KILL", attacker, victim);
}

void Event_HurtConcise(Event event, const char[] name, bool dontBroadcast) 
{
    if (g_bShouldBlockFF || !g_bCvarEnable)
        return;

	int attacker = event.GetInt("attackerentid");
	int victim = GetClientOfUserId(event.GetInt("userid"));

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
	
	//If the player is already friendly firing teammates, resets the announce timer and adds to the damage
	int damage = event.GetInt("dmg_health");
	if (g_hFFTimer[attacker])  
	{
		g_iDamageCache[attacker][victim] += damage;
		g_hFFTimer[attacker] = null;
		delete g_hFFTimer[attacker];
		g_hFFTimer[attacker] = CreateTimer(1.0, AnnounceFF, attacker);
	}
	//If it's the first friendly fire by that player, it will start the announce timer and store the damage done.
	else 
	{
		g_iDamageCache[attacker][victim] = damage;
		g_hFFTimer[attacker] = CreateTimer(1.0, AnnounceFF, attacker);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i != attacker && i != victim)
				g_iDamageCache[attacker][i] = 0;
		}
	}
}

void Event_IncapacitatedStart(Event event, const char[] name, bool dontBroadcast) 
{
    if (g_bShouldBlockFF || !g_bCvarEnable)
        return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
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

	//If the player is already friendly firing teammates, resets the announce timer and adds to the damage
	if (g_hFFTimer[attacker])  
	{
		g_iDamageCache[attacker][victim] += damage;
		g_hFFTimer[attacker] = null;
		delete g_hFFTimer[attacker];
		g_hFFTimer[attacker] = CreateTimer(1.0, AnnounceFF, attacker);
	}
	//If it's the first friendly fire by that player, it will start the announce timer and store the damage done.
	else 
	{
		g_iDamageCache[attacker][victim] = damage;
		g_hFFTimer[attacker] = CreateTimer(1.0, AnnounceFF, attacker);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i != attacker && i != victim)
				g_iDamageCache[attacker][i] = 0;
		}
	}
}

//Called if the attacker did not friendly fire recently, and announces all FF they did
Action AnnounceFF(Handle timer, int attackerc) 
{
    if (g_bShouldBlockFF)
        return Plugin_Stop;

	char victim[128];
	char attacker[128];

	if (IsClientInGame(attackerc))
		GetClientName(attackerc, attacker, sizeof(attacker));
	else
		Format(attacker, sizeof(attacker), "%T", "Disconnected_Player", attackerc);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iDamageCache[attackerc][i] != 0 && attackerc != i)
		{
			if (IsClientInGame(i))
			{
				GetClientName(i, victim, sizeof(victim));
				switch(g_iCvarAnnounceType)
				{
					case 1:
					{
						if (IsClientInGame(attackerc) && !IsFakeClient(attackerc))
							CPrintToChat(attackerc, "%t", "FF_dealt_coloured", g_iDamageCache[attackerc][i], victim);
						if (IsClientInGame(i) && !IsFakeClient(i))
							CPrintToChat(i, "%t", "FF_receive_coloured", attacker, g_iDamageCache[attackerc][i]);
					}
					case 2:
					{
						if (IsClientInGame(attackerc) && !IsFakeClient(attackerc))
							PrintHintText(attackerc, "%t", "FF_dealt", g_iDamageCache[attackerc][i], victim);
						if (IsClientInGame(i) && !IsFakeClient(i))
							PrintHintText(i, "%t", "FF_receive", g_iDamageCache[attackerc][i]);
					}
					case 3:
					{
						if (IsClientInGame(attackerc) && !IsFakeClient(attackerc))
							PrintCenterText(attackerc, "%t", "FF_dealt", g_iDamageCache[attackerc][i], victim);
						if (IsClientInGame(i) && !IsFakeClient(i))
							PrintCenterText(i, "%t", "FF_receive", attacker, g_iDamageCache[attackerc][i]);
					}
					default:
					{
						//nothing
					}
				}
			}
			g_iDamageCache[attackerc][i] = 0;
		}
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
			delete g_hFFTimer[i];
		}
	}
}

stock int GetSurvivorTempHealth(int client)
{
	float fHealthBuffer			= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float fHealthBufferDuration = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");

	ConVar hCvarPainPillsDecayRate = FindConVar("pain_pills_decay_rate");

	int	  iTempHp				= RoundToCeil(fHealthBuffer - (fHealthBufferDuration * hCvarPainPillsDecayRate.FloatValue)) - 1;

	return (iTempHp > 0) ? iTempHp : 0;
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