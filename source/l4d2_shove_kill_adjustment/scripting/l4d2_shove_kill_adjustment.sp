#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <left4dhooks>

#undef REQUIRE_EXTENSIONS
#include <midhook>

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
 * For chargers: need z_charger_allow_shove to be set to 1.
 * 
 * For boomers: set 
 *  z_exploding_shove_interval               : 10       : , "sv", "cheat"
 *  z_exploding_shove_max                    : 5        : , "sv", "cheat"
 *  z_exploding_shove_min                    : 4        : , "sv", "cheat"
 * 
 * For tanks: is this neccesary? (it also has m_nMaxShoveCount and m_nCurrentShoveCount xd) (would it be a to do?)
 * 
 * Note: 
 * it turns out that cvar `z_exploding_shove_interval` is applied for every SIs, not just boomer.
 * 
 * Every time a SI get shoved, this count and its specific timestamp is stored into the CultVector `m_aShovedTimes`
 * and being checked on CTerrorPlayer::UpdateStagger.
 * 
 * v2 = *(float **)&this->CTerrorPlayer.unknown2248[112];   // m_aShovedTimes
 * if ( (float)(gpGlobals->curtime - *(float *)(z_exploding_shove_interval + 44)) <= *v2 )
 * 
 * To specify the SI Class we need to overide z_exploding_shove_interval, which is a hard work.
*/

#define DEBUG 1

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

ConVar g_hCvar_SmokerShoveCount;
ConVar g_hCvar_HunterShoveCount;
ConVar g_hCvar_SpitterShoveCount;
ConVar g_hCvar_JockeyShoveCount;
ConVar g_hCvar_ChargerShoveCount;

int g_iSmokerShoveCount;
int g_iHunterShoveCount;
int g_iSpitterShoveCount;
int g_iJockeyShoveCount;
int g_iChargerShoveCount;

ConVar g_hCvar_PreventAccumulating;
ConVar g_hCvar_IntervalAdjustment;

bool g_bPreventAccumulating;

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
bool g_bMidHookAvailable = false;

#define PLUGIN_VERSION "1.0.0"

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
    g_bMidHookAvailable = LibraryExists("midhooks");

    CreateConVars();
}

public void OnLibraryAdded(const char[] name) { if (StrEqual(name, "midhooks")) g_bMidHookAvailable = true; }
public void OnLibraryRemoved(const char[] name) { if (StrEqual(name, "midhooks")) g_bMidHookAvailable = false; }

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

    if (GetClientTeam(entity) != 3)
        return;

    SetMaxShoveCount(entity);
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
    if (!IsClientInGame(pThis) || GetClientTeam(pThis) !=3)
        return MRES_Ignored;

    if (g_bShouldAdjust[pThis])
        return MRES_Ignored;

    g_bShouldAdjust[pThis] = true;
    return MRES_Ignored;
}

// since z_exploding_shove_interval is applied for every SIs, 
// let's just say we don't need these patches, 
// after all this is a cvar in a data section, 
// we need to retrieve the float value by `dword ptr[reg + offset]`, 
// which is a little bit complicated to alter the address through source scramble.
void MidHook_CTerrorPlayer_UpdateStagger__OnCheckTimestamp(MidHookRegisters reg)
{
    // load CTerrorPlayer* pointer
    Address pThis = reg.Get(DHookRegister_EBX, NumberType_Int32);
    int client = GetBaseEntity(pThis);
    //PrintToServer("[DEBUG] midhook: client: %d, %N", client, client);

    if (client == -1)
        return;
    
    if (!IsClientInGame(client) || GetClientTeam(client) != 3)
        return;

    if (!g_bShouldAdjust[client])
        return;

    // the midhook overrides this operation:
    // subss   xmm0, dword ptr [ecx+2Ch]
    // which is:
    // gpGlobal->curtime - z_exploding_shove_interval.GetFloat();

    float flCurtime[1];
    reg.GetXmmWord(DHookRegister_XMM0, flCurtime, sizeof(flCurtime));
    //PrintToServer("[DEBUG] midhook: curtime: %.02f", flCurtime[0]);

    float flShoveTimestamp = reg.LoadFloat(DHookRegister_EDX, 0);
    //PrintToServer("[DEBUG] midhook: edx: %.02f", flShoveTimestamp);

    // here we make a little trick.
    // we change the original jump logic, make the while loop always break.
    // we insert here our own logic.
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
    if (!IsClientInGame(pThis) || GetClientTeam(pThis) !=3)
        return MRES_Ignored;

    if (!g_bShouldAdjust[pThis])
        return MRES_Ignored;

    g_bShouldAdjust[pThis] = false;
    return MRES_Ignored;
}

void OnIntervalAdjustmentChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!g_bMidHookAvailable)
    {
        LogError("Midhook is not available.");
        return;
    }

    static MidHook hMidHook = null;
    static DynamicDetour hDetour = null;
    static int iOff_PatchOffset = -1;
    static bool bDetoured = false;

    if (!hMidHook || !hDetour || iOff_PatchOffset == -1)
    {
        GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);

        if (!hMidHook)
             hMidHook = gd.CreateMidHookOrFail(MIDHOOK_FUNCTION, MidHook_CTerrorPlayer_UpdateStagger__OnCheckTimestamp, false);
        
        if (!hDetour)
            hDetour = gd.CreateDetourOrFail(DETOUR_FUNCTION, false, DTR_OnUpdateStagger_Pre, DTR_OnUpdateStagger_Post);

        if (iOff_PatchOffset == -1)
            iOff_PatchOffset = gd.GetOffset(PATCH_OFFSET);

        delete gd;
    }

    if (g_hCvar_IntervalAdjustment.IntValue == 2)
    {
        if (hDetour && bDetoured)
        {
            hDetour.Disable(Hook_Pre, DTR_OnUpdateStagger_Pre);
            hDetour.Disable(Hook_Post, DTR_OnUpdateStagger_Post);
            bDetoured = false;
            delete hDetour;
        }

        // disabled when deleted.
        if (hMidHook)
        {
            Patch(hMidHook.TargetAddress + view_as<Address>(iOff_PatchOffset), false);
            delete hMidHook;
        }
 
        return;
    }

    if (g_hCvar_IntervalAdjustment.IntValue == 1)
    {
        if (hMidHook && !hMidHook.Enabled)
        {
            hMidHook.Enable();
            Patch(hMidHook.TargetAddress + view_as<Address>(iOff_PatchOffset), true);
        }

        if (hDetour && !bDetoured)
        {
            hDetour.Enable(Hook_Pre, DTR_OnUpdateStagger_Pre);
            hDetour.Enable(Hook_Post, DTR_OnUpdateStagger_Post);
            bDetoured = true;
        }
    }
    else if (g_hCvar_IntervalAdjustment.IntValue == 0)
    {
        if (hMidHook && hMidHook.Enabled)
        {
            hMidHook.Disable();
            Patch(hMidHook.TargetAddress + view_as<Address>(iOff_PatchOffset), false);
        }

        if (hDetour && bDetoured)
        {
            hDetour.Disable(Hook_Pre, DTR_OnUpdateStagger_Pre);
            hDetour.Disable(Hook_Post, DTR_OnUpdateStagger_Post);
            bDetoured = false;
        }
    }
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

public void OnPluginEnd()
{
    g_hCvar_IntervalAdjustment.IntValue = 2;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bPreventAccumulating = g_hCvar_PreventAccumulating.BoolValue;
}

void OnShoveCountChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_iSmokerShoveCount = g_hCvar_SmokerShoveCount.IntValue;
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

int GetBaseEntity(Address ptr)
{
    if (!g_bMidHookAvailable)
        return -1;

    static Handle hSDKCall_GetBaseEntity = null;
    if (!hSDKCall_GetBaseEntity)
    {
        GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);
        SDKCallParamsWrapper ret = { SDKType_CBaseEntity, SDKPass_Pointer };
        hSDKCall_GetBaseEntity = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, SDKCALL_FUNCTION, _, _, true, ret);
        delete gd;
    }

    return view_as<int>(SDKCall(hSDKCall_GetBaseEntity, ptr));
}

void LoadGameData()
{
    GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);

    g_iOS = gd.OS;
    if (g_iOS == OS_UnknownPlatform) SetFailState("Unknown platform.");

    g_iOff_m_nMaxShoveCount = gd.GetOffset(OFFSET_NAME);
    g_iOff_m_nCurrentShoveCount = gd.GetOffset(OFFSET_NAME2);

    delete gd;
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

// if ( (float)(gpGlobals->curtime /* - *(float *)(z_exploding_shove_interval + 44)) */ <= *v2 )
// ->
// if ( (float)(gpGlobals->curtime /* - *(float *)(z_exploding_shove_interval + 44)) */ >= *v2 )
// this is always true, which means we have blocked the logic of decrementing the shove count.
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

void CreateConVars()
{
    g_hCvar_IntervalAdjustment = CreateConVarHook(  "l4d2_shove_kill_adjustment_interval_adjust", 
                                                    "0", 
                                                    "Adjust the interval by original game cvar or plugin cvar \
                                                    1=plugin cvar (Requires midhook.), 0=game cvar (z_exploding_shove_interval).", 
                                                    _, 
                                                    true, 0.0, true, 2.0,
                                                    OnIntervalAdjustmentChanged);

    g_hCvar_PreventAccumulating = CreateConVarHook("l4d2_shove_kill_adjustment_prevent_shove_kill", 
                                                    "0", 
                                                    "Prevent the shove count from accumulating.", 
                                                    _, 
                                                    true, 0.0, true, 1.0,
                                                    OnConVarChanged);

    g_hCvar_SmokerShoveCount = CreateConVarHook("z_smoker_max_shove_count", "5", 
                                                "Adjust the max shove count to get killed for smokers.", 
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
    OnIntervalAdjustmentChanged(null, "", "");
}