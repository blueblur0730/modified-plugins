#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sourcescramble>

#undef REQUIRE_EXTENSIONS
#include <midhook>

#include <gamedata_wrapper>

#define GAMEDATA_FILE "l4d2_shove_kill_adjustment"
#define OFFSET_NAME "CTerrorPlayer->m_nMaxShoveCount__relative_offset"
#define OFFSET_NAME2 "CTerrorPlayer->m_nCurrentShoveCount__relative_offset"
#define DETOUR_FUNCTION "CTerrorPlayer::UpdateStagger"
#define MIDHOOK_FUNCTION "CTerrorPlayer::UpdateStagger__OnCheckTimestamp"
#define SDKCALL_FUNCTION "CBaseEntity::GetBaseEntity"
#define PATCH_NAME "CTerrorPlayer::UpdateStagger__PatchGreaterOrEqual"
#define PATCH_NAME2 "CTerrorPlayer::OnShovedBySurvivor__PatchJumpNoCondition"

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
 * Thus, m_nMaxShoveCount will be only set once by plugin cvar on post spawn during the SI its whole life time (or anytime you want).
 * At last, the shove kill mechanics is fully controlled by plugin cvars.
 * 
 * Additionaly, to make the SI "invunerable", which means they can't be killed by shove, we will patch here on CTerrorPlayer::OnShovedBySurvivor:
 * 
 * `if ( m_nCurrentShoveCount < m_nMaxShoveCount )`
 * 
 * from `JL` to `JMP`, so the following take damage logic will never be excuted.
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

MidHook g_hMidHook;
DynamicDetour g_hDetour;
Handle g_hSDKCall_GetBaseEntity;
MemoryPatch g_hPatch__OnCheckTimestamp;
MemoryPatch g_hPatch__PreventAccumulating;

ConVar g_hCvar_ShoveCountToggle;

ConVar g_hCvar_SmokerShoveCount;
ConVar g_hCvar_BoomerShoveCount;
ConVar g_hCvar_HunterShoveCount;
ConVar g_hCvar_SpitterShoveCount;
ConVar g_hCvar_JockeyShoveCount;
ConVar g_hCvar_ChargerShoveCount;

ConVar g_hCvar_SmokerShoveInterval;
ConVar g_hCvar_BoomerShoveInterval;
ConVar g_hCvar_HunterShoveInterval;
ConVar g_hCvar_SpitterShoveInterval;
ConVar g_hCvar_JockeyShoveInterval;
ConVar g_hCvar_ChargerShoveInterval;

bool g_bShouldAdjust[MAXPLAYERS + 1] = { false, ... };
bool g_bMidHookAvailable = false;

#define PLUGIN_VERSION "2.2.0"

public Plugin myinfo = 
{
	name = "[L4D2] Shove Kill Adjustment",
	author = "blueblur",
	description = "Provides ability to modify the mechanics of \"shoving special infecteds to death\".",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins",
}

public void OnPluginStart()
{
    g_bMidHookAvailable = LibraryExists("midhooks");

    LoadGameData();
    CreateConVars();
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void OnPluginEnd()
{
    delete g_hMidHook;
    delete g_hDetour;   // well whatever disable it or not, it dosen't do anything.
    delete g_hPatch__OnCheckTimestamp;
    delete g_hPatch__PreventAccumulating;
}

// m_nMaxShoveCount is initialized in CTerrorPlayer::Spawn, player_spawn is called after it.
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client <= 0 || client > MaxClients)
        return;

    if (!IsClientInGame(client) || GetClientTeam(client) != 3)
        return;

    SetMaxShoveCount(client);
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
            float flDifferential = flCurtime[0] - g_hCvar_SmokerShoveInterval.FloatValue;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Boomer:
        {
            float flDifferential = flCurtime[0] - g_hCvar_BoomerShoveInterval.FloatValue;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Hunter:
        {
            float flDifferential = flCurtime[0] - g_hCvar_HunterShoveInterval.FloatValue;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Spitter:
        {
            float flDifferential = flCurtime[0] - g_hCvar_SpitterShoveInterval.FloatValue;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Jockey:
        {
            float flDifferential = flCurtime[0] - g_hCvar_JockeyShoveInterval.FloatValue;
            if (flDifferential > flShoveTimestamp)
            {
                if (GetCurrentShoveCount(client) - 1 >= 0)
                    SetCurrentShoveCount(client, GetCurrentShoveCount(client) - 1);
            }
        }

        case SIType_Charger:
        {
            float flDifferential = flCurtime[0] - g_hCvar_ChargerShoveInterval.FloatValue;
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

    if (!g_hCvar_ShoveCountToggle.BoolValue)
    {
        static ConVar z_exploding_shove_min = null;
        static ConVar z_exploding_shove_max = null;
        if (!z_exploding_shove_min)
            z_exploding_shove_min = FindConVar("z_exploding_shove_min");

        if (!z_exploding_shove_max)
            z_exploding_shove_max = FindConVar("z_exploding_shove_max");

        SetEntData(entity, s_iOff_m_nMaxShoveCount, GetRandomInt(z_exploding_shove_min.IntValue, z_exploding_shove_max.IntValue), true);
    }
    else
    {
        switch (GetEntProp(entity, Prop_Send, "m_zombieClass"))
        {
            case SIType_Smoker:
                SetEntData(entity, s_iOff_m_nMaxShoveCount, g_hCvar_SmokerShoveCount.IntValue, true);

            case SIType_Boomer:
                SetEntData(entity, s_iOff_m_nMaxShoveCount, g_hCvar_BoomerShoveCount.IntValue, true);

            case SIType_Hunter:
                SetEntData(entity, s_iOff_m_nMaxShoveCount, g_hCvar_HunterShoveCount.IntValue, true);

            case SIType_Spitter:
                SetEntData(entity, s_iOff_m_nMaxShoveCount, g_hCvar_SpitterShoveCount.IntValue, true);

            case SIType_Jockey:
                SetEntData(entity, s_iOff_m_nMaxShoveCount, g_hCvar_JockeyShoveCount.IntValue, true);

            case SIType_Charger:
                SetEntData(entity, s_iOff_m_nMaxShoveCount, g_hCvar_ChargerShoveCount.IntValue, true);
        }
    }
}

void OnEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!g_bMidHookAvailable)
        return;

    if (!g_hMidHook && g_bMidHookAvailable)
    {
        GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);
        g_hMidHook = gd.CreateMidHookOrFail(MIDHOOK_FUNCTION, MidHook_CTerrorPlayer_UpdateStagger__OnCheckTimestamp, false);
        delete gd;
    }

    static bool bDetoured = false;
    if (convar.BoolValue)
    {
        if (g_hMidHook && !g_hMidHook.Enabled)
        {
            g_hMidHook.Enable();
            Patch(g_hPatch__OnCheckTimestamp, true);
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
            Patch(g_hPatch__OnCheckTimestamp, false);
        }

        if (g_hDetour && bDetoured)
        {
            g_hDetour.Disable(Hook_Pre, DTR_OnUpdateStagger_Pre);
            g_hDetour.Disable(Hook_Post, DTR_OnUpdateStagger_Post);
            bDetoured = false;
        }
    }
}

void OnPreventShoveKillChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    convar.BoolValue ?
    Patch(g_hPatch__PreventAccumulating, true) :
    Patch(g_hPatch__PreventAccumulating, false);
}

void LoadGameData()
{
    GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);

    g_iOS = gd.OS;
    if (g_iOS == OS_UnknownPlatform) SetFailState("Unknown platform.");

    g_iOff_m_nMaxShoveCount = gd.GetOffset(OFFSET_NAME);
    g_iOff_m_nCurrentShoveCount = gd.GetOffset(OFFSET_NAME2);

    if (g_bMidHookAvailable)
        g_hMidHook = gd.CreateMidHookOrFail(MIDHOOK_FUNCTION, MidHook_CTerrorPlayer_UpdateStagger__OnCheckTimestamp, false);

    g_hDetour = gd.CreateDetourOrFail(DETOUR_FUNCTION, false, DTR_OnUpdateStagger_Pre, DTR_OnUpdateStagger_Post);

    g_hPatch__OnCheckTimestamp = gd.CreateMemoryPatchOrFail(PATCH_NAME, false);
    g_hPatch__PreventAccumulating = gd.CreateMemoryPatchOrFail(PATCH_NAME2, false);

    SDKCallParamsWrapper ret = { SDKType_CBaseEntity, SDKPass_Pointer };
    g_hSDKCall_GetBaseEntity = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_FUNCTION, _, _, true, ret);

    delete gd;
}

void CreateConVars()
{
    CreateConVar("l4d2_shove_kill_adjustment_version", PLUGIN_VERSION, "Plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    CreateConVarHookEx("l4d2_shove_kill_adjustment_enable", 
                        "1", 
                        "Enable plugin's shove interval logic? \
                        1=plugin logic, 0=game cvar (z_exploding_shove_interval).", 
                        _, 
                        true, 0.0, true, 1.0,
                        OnEnableChanged);

    CreateConVarHookEx("l4d2_shove_kill_adjustment_prevent_shove_kill", 
                        "0", 
                        "Prevent the shove count from accumulating.", 
                        _, 
                        true, 0.0, true, 1.0,
                        OnPreventShoveKillChanged);

    g_hCvar_ShoveCountToggle = CreateConVar("l4d2_shove_kill_adjustment_toggle", 
                                            "1", 
                                            "Enable plugin's shove count logic?\
                                            1=plugin logic, 0=game cvar (z_exploding_shove_max/min).", 
                                            _, 
                                            true, 1.0, false, 0.0);

    g_hCvar_SmokerShoveCount = CreateConVar("z_smoker_max_shove_count", 
                                            "5", 
                                            "Adjust the max shove count to get killed for smokers.", 
                                            FCVAR_CHEAT|FCVAR_SPONLY, 
                                            true, 1.0, false, 0.0);

    g_hCvar_BoomerShoveCount = CreateConVar("z_boomer_max_shove_count",
                                            "5", 
                                            "Adjust the max shove count to get killed for boomers.", 
                                            FCVAR_CHEAT|FCVAR_SPONLY, 
                                            true, 1.0, false, 0.0);

    g_hCvar_HunterShoveCount = CreateConVar("z_hunter_max_shove_count", 
                                            "5", 
                                            "Adjust the max shove count to get killed for hunters.", 
                                            FCVAR_CHEAT|FCVAR_SPONLY, 
                                            true, 1.0, false, 0.0);

    g_hCvar_SpitterShoveCount = CreateConVar("z_spitter_max_shove_count", 
                                            "5", 
                                            "Adjust the max shove count to get killed for spitters.", 
                                            FCVAR_CHEAT|FCVAR_SPONLY, 
                                            true, 1.0, false, 0.0);

    g_hCvar_JockeyShoveCount = CreateConVar("z_jockey_max_shove_count", 
                                            "5", "Adjust the max shove count to get killed for jockeys.", 
                                            FCVAR_CHEAT|FCVAR_SPONLY, 
                                            true, 1.0, false, 0.0);

    g_hCvar_ChargerShoveCount = CreateConVar("z_charger_max_shove_count", 
                                            "5", 
                                            "Adjust the max shove count to get killed for chargers.", 
                                            FCVAR_CHEAT|FCVAR_SPONLY, 
                                            true, 1.0, false, 0.0);

    g_hCvar_SmokerShoveInterval = CreateConVar("z_smoker_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for smokers.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0);

    g_hCvar_HunterShoveInterval = CreateConVar("z_hunter_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for hunters.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0);

    g_hCvar_SpitterShoveInterval = CreateConVar("z_spitter_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for spitters.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0);

    g_hCvar_JockeyShoveInterval = CreateConVar("z_jockey_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for jockeys.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0);

    g_hCvar_ChargerShoveInterval = CreateConVar("z_charger_shove_interval",
                                                "10.0", 
                                                "Adjust the interval of decrementing a shove count for chargers.", 
                                                FCVAR_CHEAT|FCVAR_SPONLY, 
                                                true, 0.1, false, 0.0);

    g_hCvar_BoomerShoveInterval = FindConVar("z_exploding_shove_interval");
}

public void OnLibraryAdded(const char[] name) { if (StrEqual("midhooks", name)) g_bMidHookAvailable = true; }
public void OnLibraryRemoved(const char[] name) 
{ 
    if (StrEqual("midhooks", name)) 
        g_bMidHookAvailable = false;

    if (!g_bMidHookAvailable && g_hPatch__OnCheckTimestamp)
        Patch(g_hPatch__OnCheckTimestamp, false);
}

stock void Patch(MemoryPatch hPatch, bool bPatch)
{
	static bool bPatched = false;
	if (bPatch && !bPatched)
	{
		hPatch.Enable();
		bPatched = true;
	}
	else if (!bPatch && bPatched)
	{
		hPatch.Disable();
		bPatched = false;
	}
}

stock ConVar CreateConVarHookEx(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}