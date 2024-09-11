#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION	   "1.3.2"

#define BLOCKTYPE_WALKING  (1 << 0)
#define BLOCKTYPE_ONLADDER (1 << 1)
#define BLOCKTYPE_BYHEALTH (1 << 2)

#define DEBUG			   0

ConVar
	g_hCvar_BlockedType,
	g_hCvar_HealthThreshold,
	g_hCvar_AllowedClientType,
	g_hCvar_ShouldPrintMessage;

ConVar
	g_hCvar_VelMax;

float
	g_flVelMax;

int
	g_iBlockedType,
	g_iHealthThreshold,
	g_iAllowedClientType;

bool
	g_bShouldPrintMessage;

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

	g_hCvar_BlockedType		   = CreateConVarHook(	"aid_healing_blocked_type",
												  	"7",
												  	"Type of status for target to have aid-healing blocked.\
													0 = do nothing,\
													1 = walking (more spcifically, velocity is taken into account),\
													2 = on a ladder,\
													4 = decided by health.\
													Add numbers together.",
												  	_, true, 7.0, true, 0.0, OnConVarChanged);

	g_hCvar_AllowedClientType  = CreateConVarHook(	"aid_healing_not_allowed_client_type",
												  	"3",
												  	"Type of client NOT allowed to use aid-healing under the rules we set.\
													0 = no one,\
													1 = bots,\
													2 = players,\
													3 = all disabled.",
												  	_, true, 3.0, true, 0.0, OnConVarChanged);

	g_hCvar_VelMax			   = CreateConVarHook("aid_healing_vel_max", "10.0", "Max velocity magnitude for target who had reached to have aid-healing blocked (when walking).", _, _, _, _, _, OnConVarChanged);
	g_hCvar_HealthThreshold	   = CreateConVarHook("aid_healing_health_threshold", "40", "Max health threshold for target who had reached to have aid-healing blocked (when decided by health).", _, _, _, _, _, OnConVarChanged);
	g_hCvar_ShouldPrintMessage = CreateConVarHook("aid_healing_should_print_message", "1", "Print a message to the chat when a client trys aid-healing.", _, true, 0.0, true, 1.0, OnConVarChanged);

	GetValues();
	LoadTranslation("l4d2_block_aid_healing.phrases");
}

void GetValues()
{
	g_iBlockedType		  = g_hCvar_BlockedType.IntValue;
	g_iHealthThreshold	  = g_hCvar_HealthThreshold.IntValue;
	g_iAllowedClientType  = g_hCvar_AllowedClientType.IntValue;
	g_bShouldPrintMessage = g_hCvar_ShouldPrintMessage.BoolValue;
	g_flVelMax			  = g_hCvar_VelMax.FloatValue;
}

public Action L4D2_BackpackItem_StartAction(int client, int entity, any type)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return Plugin_Continue;

#if DEBUG
	PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction called: client %d, entity %d, type %d", client, entity, type);
#endif

	// we only care about the player who is being targeted by.
	int target = L4D_FindUseEntity(client, true);
	if (target <= 0 || target > MaxClients || !IsClientInGame(client))
		return Plugin_Continue;

#if DEBUG
	PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction target: %N", target);
#endif

	char sClassname[64];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));

#if DEBUG
	PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction entity classname: %s", sClassname);
#endif

	float vel[3]; float fMagnitude;
	GetEntPropVector(target, Prop_Data, "m_vecAbsVelocity", vel);	// velocity vector of the target.
	fMagnitude = GetVectorLength(vel);								// we are retriving the magnitude of the velocity vector.

	// our focus point is first-aid kit!
	if (type == L4D2WeaponId_FirstAidKit && strcmp(sClassname, "weapon_first_aid_kit") == 0)
	{
		if (g_iBlockedType & BLOCKTYPE_WALKING)
		{
			// MOVETYPE_WALK is always applied even if you don't move just standing on the ground.
			// so we need to check if the target is actually moving.
			// simply checking if the velocity is greater than 0.0 is quite strict, add it up a llitle bit bigger.
			if (GetEntityMoveType(target) == MOVETYPE_WALK && (GetEntityFlags(target) & FL_ONGROUND) && (fMagnitude > g_flVelMax))
			{
#if DEBUG
				PrintToServer("[DEBUG] L4D2_BackpackItem_StartAction blocked by moving.");
#endif
				if (g_iAllowedClientType == 3 || (g_iAllowedClientType == 1 && IsFakeClient(client)) || (g_iAllowedClientType == 2 && !IsFakeClient(client)))
				{
					if (g_bShouldPrintMessage)
						CPrintToChat(client, "%t", "BlockedByMoving");

					return Plugin_Handled;
				}
				else if (!g_iAllowedClientType)
					return Plugin_Continue;
			}
		}

		if (g_iBlockedType & BLOCKTYPE_ONLADDER)
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
		if (g_iBlockedType & BLOCKTYPE_BYHEALTH)
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
	{
		pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
	}

	float fDecayRate			 = pain_pills_decay_rate.FloatValue;

	float fHealthBuffer			 = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float fHealthBufferTimeStamp = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");

	float fHealthBufferDuration	 = GetGameTime() - fHealthBufferTimeStamp;

	int	  iTempHp				 = RoundToCeil(fHealthBuffer - (fHealthBufferDuration * fDecayRate)) - 1;

	return (iTempHp > 0) ? iTempHp : 0;
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