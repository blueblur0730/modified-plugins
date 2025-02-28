#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION	   "1.4.1"

#define BLOCKTYPE_WALKING  (1 << 0)
#define BLOCKTYPE_ONLADDER (1 << 1)
#define BLOCKTYPE_BYHEALTH (1 << 2)

// 20 frames / 30 fps = 0.6666... seconds, sequence 5, name: melee, model: v_medkit.mdl, total frames: 21.
// this number is a little bit bigger than 0.6667 (frame 20), make this float point number: frame 20 < x < frame 21.
// this makes sure we only add a count in the last frame call.
//#define SHOVE_ANIMATION_TIME 0.6777	

#define DEBUG			   0

ConVar
	g_hCvar_WayToBlock,
	g_hCvar_BlockedType,
	g_hCvar_CoolDown,
	g_hCvar_CoolDownTime,
	g_hCvar_BlockTime,
	g_hCvar_VelMax,
	g_hCvar_HealthThreshold,
	g_hCvar_AllowedClientType,
	g_hCvar_ShouldPrintMessage,
	g_hCvar_InSaferoom;

float
	g_flVelMax,
	g_flCoolDownTime,
	g_flBlockTime;

float g_flLastUseTime[MAXPLAYERS + 1];

int
	g_iWayToBlock,
	g_iBlockedType,
	g_iCoolDownLimit,
	g_iHealthThreshold,
	g_iAllowedClientType;

int g_iUseCount[MAXPLAYERS + 1];

bool g_bHasInitialized[MAXPLAYERS + 1] = { false, ... };
bool g_bInBlocked[MAXPLAYERS + 1] = { false, ...};

bool
	g_bShouldPrintMessage,
	g_bInSaferoom;

public Plugin myinfo =
{
	name = "[L4D2] Block Aid-Healing",
	author = "blueblur",
	description = "Block annoying aid-healing from your lovely teammates.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_block_aid_healing_version", PLUGIN_VERSION, "Block Aid-Healing plugin version", FCVAR_DEVELOPMENTONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hCvar_WayToBlock		   = CreateConVarHook(	"aid_healing_way_to_block",
	 												"1",
													"Way to block aid-healing.\
													0 = disable the plugin,\
													1 = by rules set below (default),\
													2 = by use counts.",
													_, true, 0.0, true, 2.0, OnConVarChanged);

	g_hCvar_BlockedType		   = CreateConVarHook(	"aid_healing_blocked_type",
												  	"7",
												  	"Type of status for target to have aid-healing blocked.\
													0 = do nothing,\
													1 = walking (more spcifically, velocity is taken into account),\
													2 = on a ladder,\
													4 = decided by health.\
													Add numbers together.",
												  	_, true, 0.0, true, 7.0, OnConVarChanged);

	g_hCvar_AllowedClientType  = CreateConVarHook(	"aid_healing_not_allowed_client_type",
												  	"3",
												  	"Type of client NOT allowed to use aid-healing under the rules we set.\
													0 = no one,\
													1 = bots,\
													2 = players,\
													3 = all disabled.",
												  	_, true, 0.0, true, 3.0, OnConVarChanged);

	g_hCvar_CoolDown		   = CreateConVarHook("aid_healing_cooldown", "3", "Limit of how many times a client try to aid-heal to enter a cooldown state.", _, true, 0.0, _, _, OnConVarChanged);
	g_hCvar_CoolDownTime	   = CreateConVarHook("aid_healing_cooldown_time", "10.0", "Time in seconds for the cooldown state to last.", _, true, 0.0, _, _, OnConVarChanged);
	g_hCvar_BlockTime		   = CreateConVarHook("aid_healing_block_time", "10.0", "Time in seconds for the target to be blocked when has reached maximum limit of cooldown.", _, true, 0.0, _, _, OnConVarChanged);
	g_hCvar_VelMax			   = CreateConVarHook("aid_healing_vel_max", "10.0", "Max velocity magnitude for target who had reached to have aid-healing blocked (when walking).", _, _, _, _, _, OnConVarChanged);
	g_hCvar_HealthThreshold	   = CreateConVarHook("aid_healing_health_threshold", "40", "Max health threshold for target who had reached to have aid-healing blocked (when decided by health).", _, _, _, _, _, OnConVarChanged);
	g_hCvar_ShouldPrintMessage = CreateConVarHook("aid_healing_should_print_message", "1", "Print a message to the chat when a client trys aid-healing.", _, true, 0.0, true, 1.0, OnConVarChanged);
	g_hCvar_InSaferoom		   = CreateConVarHook("aid_healing_in_saferoom", "1", "Enable/Disable aid-healing in saferoom.", _, true, 0.0, true, 1.0, OnConVarChanged);

	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);

	GetValues();
	LoadTranslation("l4d2_block_aid_healing.phrases");
}

void GetValues()
{
	g_iWayToBlock		  = g_hCvar_WayToBlock.IntValue;
	g_iBlockedType		  = g_hCvar_BlockedType.IntValue;
	g_iCoolDownLimit	  = g_hCvar_CoolDown.IntValue;
	g_flCoolDownTime	  = g_hCvar_CoolDownTime.FloatValue;
	g_flBlockTime		  = g_hCvar_BlockTime.FloatValue;
	g_iHealthThreshold	  = g_hCvar_HealthThreshold.IntValue;
	g_iAllowedClientType  = g_hCvar_AllowedClientType.IntValue;
	g_bShouldPrintMessage = g_hCvar_ShouldPrintMessage.BoolValue;
	g_flVelMax			  = g_hCvar_VelMax.FloatValue;
	g_bInSaferoom		  = g_hCvar_InSaferoom.BoolValue;
}

void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_flLastUseTime[i] = 0.0;
		g_iUseCount[i] = 0;
		g_bHasInitialized[i] = false;
		g_bInBlocked[i] = false;
	}
}

public Action L4D2_BackpackItem_StartAction(int client, int entity, any type)
{
	// plugin disabled.
	if (!g_iWayToBlock)
		return Plugin_Continue;

	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return Plugin_Continue;

#if DEBUG
	PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction called: client %d, entity %d, type %d", client, entity, type);
#endif

	static char sClassname[64];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));

#if DEBUG
	PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction entity classname: %s", sClassname);
#endif

	// our focus point is first-aid kit!
	if (type != L4D2WeaponId_FirstAidKit || strcmp(sClassname, "weapon_first_aid_kit") != 0)
		return Plugin_Continue;

	// we only care about the player who is being targeted by.
	int target = L4D_FindUseEntity(client, true);
	if (target <= 0 || target > MaxClients || !IsClientInGame(target))
		return Plugin_Continue;

	// for safe, these two should both on saferoom. this check is always applied beyond any other checks.
	if (g_bInSaferoom && IsClientInSaferoom(client) && IsClientInSaferoom(target))
		return Plugin_Continue;

#if DEBUG
	PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction target: %N", target);
#endif

	if (g_iWayToBlock == 2)
	{
		// reached max limit, block it.
		if (g_iUseCount[client] > g_iCoolDownLimit)
		{
			g_bHasInitialized[client] = false;
			g_iUseCount[client] = 0;
			g_bInBlocked[client] = true;
			return Plugin_Handled;
		}
		else
		{
			// you are in blocked now.
			if (g_bInBlocked[client])
			{
				// still in block time, block it
				if (GetGameTime() - g_flLastUseTime[client] < g_flBlockTime)
					return Plugin_Handled;
				else
					g_bInBlocked[client] = false;	// have passed the block time, keep on.
			}

			// initialize the last use time.
			if (g_iUseCount[client] == 0 && !g_bHasInitialized[client])
			{
				g_flLastUseTime[client] = GetGameTime();
				g_bHasInitialized[client] = true;
			}
/*
			// thought too much.

			// L4D2_BackpackItem_StartAction calls in frames.
			// we need to know if the target has complete the animation or not.
			// after the Current Time - Last Use Time > Animation Time (20th frame), take this as a count.
			if ((GetGameTime() - g_flLastUseTime[client]) < SHOVE_ANIMATION_TIME)
				return Plugin_Continue;
*/
			// in the cooldown time range we set, add count.
			if ((GetGameTime() - g_flLastUseTime[client]) < g_flCoolDownTime)
			{
				g_flLastUseTime[client] = GetGameTime();
				g_iUseCount[client]++;
				return Plugin_Continue;
			}
			else
			{
				// long gone the time range, reset.
				// but now that you have reached here, take this as your first attempt.
				g_iUseCount[client] = 1;
				g_flLastUseTime[client] = GetGameTime();
				return Plugin_Continue;
			}
		}
	}

	if (g_iWayToBlock == 1 && (g_iBlockedType & BLOCKTYPE_WALKING))
	{
		if (GetEntityMoveType(target) == MOVETYPE_WALK && (GetEntityFlags(target) & FL_ONGROUND))
		{
			// MOVETYPE_WALK is always applied even if you don't move just standing on the ground.
			// so we need to check if the target is actually moving.
			// simply checking if the velocity is greater than 0.0 is quite strict, add it up a llitle bit bigger.
			float vel[3]; float fMagnitude;
			GetEntPropVector(target, Prop_Data, "m_vecAbsVelocity", vel);	// velocity vector of the target.
			fMagnitude = GetVectorLength(vel);								// we are retriving the magnitude of the velocity vector.

			if (fMagnitude <= g_flVelMax)
				return Plugin_Continue;

			if (g_iAllowedClientType == 3 || (g_iAllowedClientType == 1 && IsFakeClient(client)) || (g_iAllowedClientType == 2 && !IsFakeClient(client)))
			{
#if DEBUG
				PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction blocked by moving.");
#endif
				if (g_bShouldPrintMessage)
					CPrintToChat(client, "%t", "BlockedByMoving");

				return Plugin_Handled;
			}
			else if (!g_iAllowedClientType)
				return Plugin_Continue;
		}
	}

	if (g_iWayToBlock == 1 && (g_iBlockedType & BLOCKTYPE_ONLADDER))
	{
		// as long as you are sticking on the ladder, this statement is true.
		if (GetEntityMoveType(target) == MOVETYPE_LADDER)
		{
#if DEBUG
			PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction blocked by on a ladder.");
#endif
			if (g_iAllowedClientType == 3 || (g_iAllowedClientType == 1 && IsFakeClient(client)) || (g_iAllowedClientType == 2 && !IsFakeClient(client)))
			{
				if (g_bShouldPrintMessage)
					CPrintToChat(client, "%t", "BlockedByOnALadder");

				return Plugin_Handled;
			}
			else if (!g_iAllowedClientType)
				return Plugin_Continue;
		}
	}

	// health is always the last condition to check since this status is always constantly existed.
	if (g_iWayToBlock == 1 && (g_iBlockedType & BLOCKTYPE_BYHEALTH))
	{
		int iTempHealth = GetSurvivorTemporaryHealth(target);
		int iHealth		= GetClientHealth(target) + iTempHealth;
		if (iHealth > g_iHealthThreshold)
		{
#if DEBUG
			PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction blocked by health, health + temphealth: %d.", iHealth);
#endif
			if (g_iAllowedClientType == 3 || (g_iAllowedClientType == 1 && IsFakeClient(client)) || (g_iAllowedClientType == 2 && !IsFakeClient(client)))
			{
				if (g_bShouldPrintMessage)
					CPrintToChat(client, "%t", "BlockedByHealth", g_iHealthThreshold);

				return Plugin_Handled;
			}
			else if (!g_iAllowedClientType)
				return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetValues();
}

/**
 * Returns the amount of temporary health a survivor has.
 * From l4d2utils.
 *
 * @param client client ID
 * @return int
 */
stock int GetSurvivorTemporaryHealth(int client)
{
	static ConVar pain_pills_decay_rate = null;
	if (pain_pills_decay_rate == null)
		pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");

	float fDecayRate			 = pain_pills_decay_rate.FloatValue;
	float fHealthBuffer			 = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float fHealthBufferTimeStamp = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealthBufferDuration	 = GetGameTime() - fHealthBufferTimeStamp;
	int	  iTempHp				 = RoundToCeil(fHealthBuffer - (fHealthBufferDuration * fDecayRate)) - 1;

	return (iTempHp > 0) ? iTempHp : 0;
}

// from plugin l4d2_SafeAreaDetect.
// checks if the client is in start or end saferoom.
stock bool IsClientInSaferoom(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return false;

	Address nav = L4D_GetLastKnownArea(client);
	if (!nav)
		return false;

	int iAttr = L4D_GetNavArea_SpawnAttributes(view_as<Address>(nav));
	bool bInStartPoint = !!(iAttr & NAV_SPAWN_PLAYER_START);
	bool bInCheckPoint = !!(iAttr & NAV_SPAWN_CHECKPOINT);
	if (!bInStartPoint && !bInCheckPoint)
		return false;

	return true;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client));
}

ConVar CreateConVarHook(const char[] name,
						const char[] defaultValue,
						const char[] description = "",
						int	 flags				 = 0,
						bool hasMin = false, float min = 0.0,
						bool hasMax = false, float max = 0.0,
						ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	cv.AddChangeHook(callback);

	return cv;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}