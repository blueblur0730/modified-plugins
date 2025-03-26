#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <midhook>
#include <left4dhooks>
#include <gamedata_wrapper>

#define GAMEDATA_FILE "l4d2_shove_kill_adjustment"
#define OFFSET_NAME "CTerrorPlayer->m_nMaxShoveCount__relative_offset"
#define OFFSET_NAME2 "CTerrorPlayer->m_nCurrentShoveCount__relative_offset"
#define DETOUR_FUNCTION "CTerrorPlayer::UpdateStagger"
#define MIDHOOK_FUNCTION "CTerrorPlayer::UpdateStagger__OnCheckTimestamp"
#define SDKCALL_FUNCTION "CBaseEntity::GetBaseEntity"
#define PATCH_OFFSET "MidHook__patch_offset"

#define JGE_JUMPNEAR_OPCODE 0x8D // 0F 8D, linux
#define JGE_JUMPSHORT_OPCODE 0x7D // 7D, windows
#define JBE_JUMPNEAR_OPCODE 0x86 // 0F 86, linux
#define JBE_JUMPSHORT_OPCODE 0x76 // 76, widows

OperatingSystem g_iOS = OS_UnknownPlatform;

/**
 * ## Brief.
 * Something that need to clarify ahead.
 * 
 * The three cvars below:
 * 
 *  z_exploding_shove_interval               : 10       : , "sv", "cheat"
 *  z_exploding_shove_max                    : 5        : , "sv", "cheat"
 *  z_exploding_shove_min                    : 4        : , "sv", "cheat"
 * 
 * was meant to be designed for boomers only.
 * 
 * `z_exploding_shove_interval` controls the time the game decreaments the m_nCurrentShoveCount.
 * `z_exploding_shove_max/min` controls the m_nMaxShoveCount.
 * 
 * But actually it is applied for every SI. Another nice job valve.
 * The goal of this plugin is to adjust the shove count and decreament time for every single SI.
 * 
 * ## Additional comments.
 * For chargers: need `z_charger_allow_shove` to be set to 1.
 * For boomers: the original `z_exploding*` cvar will be boomers only. For shove count, use `z_boomer_max_shove_count`. For shove interval, use game's original cvar: `z_exploding_shove_interval`.
 * For tanks: is this neccesary? (it also has m_nMaxShoveCount and m_nCurrentShoveCount xd) (would it be a to do?)
 * 
 * ## Note: 
 * Every time a SI get shoved, this count and its specific timestamp is stored into the CUtlVector `m_aShovedTimes`
 * and being checked on CTerrorPlayer::UpdateStagger.
 * Should be something like this:
 * 
 * if (m_nCurrentShoveCount > 0)
 * {
 *      // actually `<=` in both platform's assembly (jbe), here this is only for understanding.
 *      while (gpGlobal->curtime - z_exploding_shove_interval.GetFloat() > m_aShovedTimes[m_nCurrentShoveCount])    
 *      {
 *          if (--m_nCurrentShoveCount > 0)
 *              m_aShovedTimes.ShiftElementsLeft(m_nCurrentShoveCount, 1);
 *          
 *          // which means when the shove count was purged out completely, resetting the max shove count.
 *          if (!m_nCurrentShoveCount)
 *          {
 *              m_nMaxShoveCount = RandomInt(z_exploding_shove_min.GetInt(), z_exploding_shove_max.GetInt());
 *              break;
 *          }
 *      }
 * }
 * 
 * Linux for example,
 * In this plugin, we will patch
 * ```
 * if ( (float)(gpGlobals->curtime - *(float *)(z_exploding_shove_interval + 44)) <= *v2 )
 *      break;
 * ```
 * to
 * ```
 * if ( (float)gpGlobals->curtime >= *v2 )
 *      break;
 * ```
 * to make the loop always be true and breakable, 
 * then jumps to plugin's trampline function, compare the timestamp with plugin cvar value, finally m_nCurrentShoveCount - 1.
 * 
 * Easy to understand, the code below:
 * 
 * `m_nMaxShoveCount = RandomInt(z_exploding_shove_min.GetInt(), z_exploding_shove_max.GetInt());`
 * 
 * won't be executed either.
 * Thus, m_nMaxShoveCount will be only set once by cvar on post spawn during the SI life time.
 * At last, the shove kill mechanics is fully controlled by plugin cvars.
*/

enum {
	SIType_Smoker = 1,
	SIType_Boomer = 2,
	SIType_Hunter = 3,
	SIType_Spitter = 4,
	SIType_Jockey = 5,
	SIType_Charger = 6,

	SIType_Size	   // 6 size
}

int g_iOff_m_nMaxShoveCount = -1;
int g_iOff_m_nCurrentShoveCount = -1;
int g_iOff_PatchOffset = -1;

MidHook g_hMidHook;
DynamicDetour g_hDetour;
Handle g_hSDKCall_GetBaseEntity;

ConVar g_hCvar_SmokerShoveCount;
ConVar g_hCvar_BoomerShoveCount;
ConVar g_hCvar_HunterShoveCount;
ConVar g_hCvar_SpitterShoveCount;
ConVar g_hCvar_JockeyShoveCount;
ConVar g_hCvar_ChargerShoveCount;

int g_iSmokerShoveCount;
int g_iBoomerShoveCount;
int g_iHunterShoveCount;
int g_iSpitterShoveCount;
int g_iJockeyShoveCount;
int g_iChargerShoveCount;

ConVar g_hCvar_PreventAccumulating;
ConVar g_hCvar_IntervalAdjustment;

bool g_bPreventAccumulating;
bool g_bIntervalAdjustment;

ConVar g_hCvar_SmokerShoveInterval;
ConVar g_hCvar_BoomerShoveInterval;
ConVar g_hCvar_HunterShoveInterval;
ConVar g_hCvar_SpitterShoveInterval;
ConVar g_hCvar_JockeyShoveInterval;
ConVar g_hCvar_ChargerShoveInterval;

float g_flSmokerShoveInterval;
float g_flBoomerShoveInterval;
float g_flHunterShoveInterval;
float g_flSpitterShoveInterval;
float g_flJockeyShoveInterval;
float g_flChargerShoveInterval;

bool g_bShouldAdjust[MAXPLAYERS + 1] = { false, ... };

#define PLUGIN_VERSION "2.0.0"

public Plugin myinfo = 
{
	name = "[L4D2] Shove Kill Adjustment",
	author = "blueblur",
	description = "Adjust the shove count of getting killed for SIs.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins",
}

public void OnPluginStart()
{
    LoadGameData();
    CreateConVar("l4d2_shove_kill_adjustment_version", PLUGIN_VERSION, "Plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    CreateConVars();
}

public void OnPluginEnd()
{
    delete g_hMidHook;
    delete g_hDetour;   // well whatever disable it or not, it dosen't do anything.
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity <= 0 || entity > MaxClients)
        return;

    if (!IsValidEntity(entity))
        return;

    SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);    
}

void OnSpawnPost(int entity)
{
    if (!IsValidEntity(entity))
        return;

    if (!IsClientInGame(entity) || GetClientTeam(entity) != 3)
        return;

    RequestFrame(SetMaxShoveCount, entity);
}

public void L4D_OnShovedBySurvivor_Post(int client, int victim, const float vecDir[3])
{
    if (!g_bPreventAccumulating)
        return;

	if (!IsClientInGame(victim))
		return;
	
	if (GetClientTeam(victim) != 3 || !IsPlayerAlive(victim))
		return;
	
	if (!L4D_IsPlayerStaggering(victim))
		return;

	SetCurrentShoveCount(victim, 0);
}

// need a inline hook here, cause this function is called in frames and literally for every SIs, and we only have one cvar.
MRESReturn DTR_OnUpdateStagger_Pre(int pThis)
{
    if (!IsClientInGame(pThis) || GetClientTeam(pThis) != 3)
        return MRES_Ignored;

    if (g_bShouldAdjust[pThis])
        return MRES_Ignored;

    g_bShouldAdjust[pThis] = true;
    return MRES_Ignored;
}

void MidHook_CTerrorPlayer_UpdateStagger__OnCheckTimestamp(MidHookRegisters reg)
{
    Address ptr = reg.Get(DHookRegister_EBX, NumberType_Int32);
    int client = SDKCall(g_hSDKCall_GetBaseEntity, ptr);
    //PrintToServer("[DEBUG] midhook: client: %d, %N", client, client);

    if (client == -1)
        return;
    
    if (!IsClientInGame(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client))
        return;

    if (!g_bShouldAdjust[client])
        return;

    // the midhook trampoline overrides this operation:
    // subss   xmm0, dword ptr [ecx+2Ch]
    // which is:
    // gpGlobal->curtime - z_exploding_shove_interval.GetFloat();

    float flCurtime[1];
    reg.GetXmmWord(DHookRegister_XMM0, flCurtime, sizeof(flCurtime));
    //PrintToServer("[DEBUG] midhook: curtime: %.02f", flCurtime[0]);

    float flShoveTimestamp = reg.LoadFloat(DHookRegister_EDX, 0);
    //PrintToServer("[DEBUG] midhook: edx: %.02f", flShoveTimestamp);

    switch (GetEntProp(client, Prop_Send, "m_zombieClass"))
    {
        case SIType_Smoker:
        {
            float flDifferential = flCurtime[0] - g_flSmokerShoveInterval;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Boomer:
        {
            float flDifferential = flCurtime[0] - g_flBoomerShoveInterval;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Hunter:
        {
            float flDifferential = flCurtime[0] - g_flHunterShoveInterval;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Spitter:
        {
            float flDifferential = flCurtime[0] - g_flSpitterShoveInterval;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Jockey:
        {
            float flDifferential = flCurtime[0] - g_flJockeyShoveInterval;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Charger:
        {
            float flDifferential = flCurtime[0] - g_flChargerShoveInterval;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }
    }
}

MRESReturn DTR_OnUpdateStagger_Post(int pThis)
{
    if (!IsClientInGame(pThis) || GetClientTeam(pThis) != 3)
        return MRES_Ignored;

    if (!g_bShouldAdjust[pThis])
        return MRES_Ignored;

    g_bShouldAdjust[pThis] = false;
    return MRES_Ignored;
}

void SetCurrentShoveCount(int entity, int count)
{
    static int s_iOff_m_nCurrentShoveCount = -1;
    if (s_iOff_m_nCurrentShoveCount == -1)
        s_iOff_m_nCurrentShoveCount = (FindSendPropInfo("CTerrorPlayer", "m_shoveForce") - g_iOff_m_nCurrentShoveCount);

    SetEntData(entity, s_iOff_m_nCurrentShoveCount, count, true);
}

int GetCurrentShoveCount(int entity)
{
    static int s_iOff_m_nCurrentShoveCount = -1;
    if (s_iOff_m_nCurrentShoveCount == -1)
        s_iOff_m_nCurrentShoveCount = (FindSendPropInfo("CTerrorPlayer", "m_shoveForce") - g_iOff_m_nCurrentShoveCount);

    return GetEntData(entity, s_iOff_m_nCurrentShoveCount);
}

void SetMaxShoveCount(int entity)
{
    static int s_iOff_m_nMaxShoveCount = -1;
    if (s_iOff_m_nMaxShoveCount == -1)
        s_iOff_m_nMaxShoveCount = (FindSendPropInfo("CTerrorPlayer", "m_shoveForce") - g_iOff_m_nMaxShoveCount); 

    switch (GetEntProp(entity, Prop_Send, "m_zombieClass"))
    {
        case SIType_Smoker:
            SetEntData(entity, s_iOff_m_nMaxShoveCount, g_iSmokerShoveCount, true);

        case SIType_Boomer:
            SetEntData(entity, s_iOff_m_nMaxShoveCount, g_iBoomerShoveCount, true);

        case SIType_Hunter:
            SetEntData(entity, s_iOff_m_nMaxShoveCount, g_iHunterShoveCount, true);

        case SIType_Spitter:
            SetEntData(entity, s_iOff_m_nMaxShoveCount, g_iSpitterShoveCount, true);

        case SIType_Jockey:
            SetEntData(entity, s_iOff_m_nMaxShoveCount, g_iJockeyShoveCount, true);

        case SIType_Charger:
            SetEntData(entity, s_iOff_m_nMaxShoveCount, g_iChargerShoveCount, true);
    }
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bPreventAccumulating = g_hCvar_PreventAccumulating.BoolValue;
    g_bIntervalAdjustment = g_hCvar_IntervalAdjustment.BoolValue;

    static bool bDetoured = false;
    if (g_bIntervalAdjustment)
    {
        if (g_hMidHook && !g_hMidHook.Enabled)
        {
            g_hMidHook.Enable();
            Patch(g_hMidHook.TargetAddress + view_as<Address>(g_iOff_PatchOffset), true);
        }

        if (g_hDetour && !bDetoured)
        {
            g_hDetour.Enable(Hook_Pre, DTR_OnUpdateStagger_Pre);
            g_hDetour.Enable(Hook_Post, DTR_OnUpdateStagger_Post);
            bDetoured = true;
        }
    }
    else
    {
        if (g_hMidHook && g_hMidHook.Enabled)
        {
            g_hMidHook.Disable();
            Patch(g_hMidHook.TargetAddress + view_as<Address>(g_iOff_PatchOffset), false);
        }

        if (g_hDetour && bDetoured)
        {
            g_hDetour.Disable(Hook_Pre, DTR_OnUpdateStagger_Pre);
            g_hDetour.Disable(Hook_Post, DTR_OnUpdateStagger_Post);
            bDetoured = false;
        }
    }
}

void OnShoveCountChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_iSmokerShoveCount = g_hCvar_SmokerShoveCount.IntValue;
    g_iBoomerShoveCount = g_hCvar_BoomerShoveCount.IntValue;
    g_iHunterShoveCount = g_hCvar_HunterShoveCount.IntValue;
    g_iSpitterShoveCount = g_hCvar_SpitterShoveCount.IntValue;
    g_iJockeyShoveCount = g_hCvar_JockeyShoveCount.IntValue;
    g_iChargerShoveCount = g_hCvar_ChargerShoveCount.IntValue;
}

void OnShoveIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_flSmokerShoveInterval = g_hCvar_SmokerShoveInterval.FloatValue;
    g_flBoomerShoveInterval = g_hCvar_BoomerShoveInterval.FloatValue;
    g_flHunterShoveInterval = g_hCvar_HunterShoveInterval.FloatValue;
    g_flSpitterShoveInterval = g_hCvar_SpitterShoveInterval.FloatValue;
    g_flJockeyShoveInterval = g_hCvar_JockeyShoveInterval.FloatValue;
    g_flChargerShoveInterval = g_hCvar_ChargerShoveInterval.FloatValue;
}

stock void Patch(Address pAdr, bool bPatch)
{
	static bool bPatched = false;
	if (bPatch && !bPatched)
	{
        switch (g_iOS)
        {
            case OS_Linux:
            {
		        if (LoadFromAddress(pAdr, NumberType_Int8) == JBE_JUMPNEAR_OPCODE)
                {
                    StoreToAddress(pAdr, JGE_JUMPNEAR_OPCODE, NumberType_Int8);
                    bPatched = true;
                }
            }

            case OS_Windows:
            {
		        if (LoadFromAddress(pAdr, NumberType_Int8) == JBE_JUMPSHORT_OPCODE)
                {
                    StoreToAddress(pAdr, JGE_JUMPSHORT_OPCODE, NumberType_Int8);
                    bPatched = true;
                }
            }
        }

	}
	else if (!bPatch && bPatched)
	{
        switch (g_iOS)
        {
            case OS_Linux:
            {
		        if (LoadFromAddress(pAdr, NumberType_Int8) == JGE_JUMPNEAR_OPCODE)
                {
                    StoreToAddress(pAdr, JBE_JUMPNEAR_OPCODE, NumberType_Int8);
                    bPatched = false;
                }
            }

            case OS_Windows:
            {
		        if (LoadFromAddress(pAdr, NumberType_Int8) == JGE_JUMPSHORT_OPCODE)
                {
                    StoreToAddress(pAdr, JBE_JUMPSHORT_OPCODE, NumberType_Int8);
                    bPatched = false;
                }
            }
        }
	}
}

void LoadGameData()
{
    GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);

    g_iOS = gd.OS;
    if (g_iOS == OS_UnknownPlatform) SetFailState("Unknown platform.");

    g_iOff_m_nMaxShoveCount = gd.GetOffset(OFFSET_NAME);
    g_iOff_m_nCurrentShoveCount = gd.GetOffset(OFFSET_NAME2);
    g_iOff_PatchOffset = gd.GetOffset(PATCH_OFFSET);
             
    g_hMidHook = gd.CreateMidHookOrFail(MIDHOOK_FUNCTION, MidHook_CTerrorPlayer_UpdateStagger__OnCheckTimestamp, false);
    g_hDetour = gd.CreateDetourOrFail(DETOUR_FUNCTION, false, DTR_OnUpdateStagger_Pre, DTR_OnUpdateStagger_Post);

    SDKCallParamsWrapper ret = { SDKType_CBaseEntity, SDKPass_Pointer };
    g_hSDKCall_GetBaseEntity = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_FUNCTION, _, _, true, ret);

    delete gd;
}

void CreateConVars()
{
    g_hCvar_IntervalAdjustment = CreateConVarHook("l4d2_shove_kill_adjustment_enable", 
                                                "0", 
                                                "Enable plugins shove kill logic? \
                                                1=plugin logic, 0=game cvar (z_exploding_shove_interval).", 
                                                _, 
                                                true, 0.0, true, 1.0,
                                                OnConVarChanged);

    g_hCvar_PreventAccumulating = CreateConVarHook("l4d2_shove_kill_adjustment_prevent_shove_kill", 
                                                "0", 
                                                "Prevent the shove count from accumulating.\
                                                Note: This cvar is independent of l4d2_shove_kill_adjustment_enable.", 
                                                _, 
                                                true, 0.0, true, 1.0,
                                                OnConVarChanged);

    g_hCvar_SmokerShoveCount = CreateConVarHook("z_smoker_max_shove_count", 
                                                "5", 
                                                "Adjust the max shove count to get killed for smokers.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 1.0, false, 0.0,
                                                OnShoveCountChanged);

    g_hCvar_BoomerShoveCount = CreateConVarHook("z_boomer_max_shove_count",
                                                "5", 
                                                "Adjust the max shove count to get killed for boomers.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 1.0, false, 0.0,
                                                OnShoveCountChanged);

    g_hCvar_HunterShoveCount = CreateConVarHook("z_hunter_max_shove_count", 
                                                "5", 
                                                "Adjust the max shove count to get killed for hunters.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 1.0, false, 0.0,
                                                OnShoveCountChanged);

    g_hCvar_SpitterShoveCount = CreateConVarHook("z_spitter_max_shove_count", 
                                                "4", 
                                                "Adjust the max shove count to get killed for spitters.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 1.0, false, 0.0,
                                                OnShoveCountChanged);

    g_hCvar_JockeyShoveCount = CreateConVarHook("z_jockey_max_shove_count", 
                                                "5", "Adjust the max shove count to get killed for jockeys.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 1.0, false, 0.0,
                                                OnShoveCountChanged);

    g_hCvar_ChargerShoveCount = CreateConVarHook("z_charger_max_shove_count", 
                                                "6", 
                                                "Adjust the max shove count to get killed for chargers.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 1.0, false, 0.0,
                                                OnShoveCountChanged);

    g_hCvar_SmokerShoveInterval = CreateConVarHook("z_smoker_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for smokers.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0,
                                                OnShoveIntervalChanged);

    g_hCvar_HunterShoveInterval = CreateConVarHook("z_hunter_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for hunters.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0,
                                                OnShoveIntervalChanged);

    g_hCvar_SpitterShoveInterval = CreateConVarHook("z_spitter_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for spitters.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0,
                                                OnShoveIntervalChanged);

    g_hCvar_JockeyShoveInterval = CreateConVarHook("z_jockey_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for jockeys.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0,
                                                OnShoveIntervalChanged);

    g_hCvar_ChargerShoveInterval = CreateConVarHook("z_charger_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for chargers.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0,
                                                OnShoveIntervalChanged);

    g_hCvar_BoomerShoveInterval = FindConVar("z_exploding_shove_interval");
    g_hCvar_BoomerShoveInterval.AddChangeHook(OnShoveIntervalChanged);

    OnConVarChanged(null, "", "");
    OnShoveCountChanged(null, "", "");
    OnShoveIntervalChanged(null, "", "");
}

stock ConVar CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	cv.AddChangeHook(callback);
	
	return cv;
}