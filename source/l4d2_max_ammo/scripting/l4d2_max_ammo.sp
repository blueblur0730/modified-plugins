#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <l4d2util_weapons>
#include <l4d_transition_entity>
#include <dhooks>
#include <gamedata_wrapper>

enum struct WeaponAmmo_t
{
    int weapon;
    int weaponRef;
    int currentAmmo;
    bool bToBeTransitioned;

}
ArrayList g_hWeaponAmmoList;
DynamicHook g_hHook_FinishReload;

#define PLUGIN_VERSION "1.4.4"
public Plugin myinfo =
{
	name = "[L4D2] Max Ammo",
	author = "blueblur",
	description = "Max Ammo per Weapon.",
	version = PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

bool g_bLateLoad = false;
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;
    RegPluginLibrary("l4d2_max_ammo");
	return APLRes_Success;
}

public void OnPluginStart()
{
    GameDataWrapper gd = new GameDataWrapper("l4d2_max_ammo");
    gd.CreateDetourOrFailEx("__l4d2_max_ammo__CAmmoDef::MaxCarry", DTR_CAmmoDef_MaxCarry_Pre);
    gd.CreateDetourOrFailEx("__l4d2_max_ammo__CWeaponSpawn::Use", DTR_CWeaponSpawn_Use_Pre, DTR_CWeaponSpawn_Use_Post);
    gd.CreateDetourOrFailEx("__l4d2_max_ammo__CWeaponAmmoSpawn::Use", DTR_CWeaponAmmoSpawn_Use_Pre, DTR_CWeaponAmmoSpawn_Use_Post);
    g_hHook_FinishReload = gd.CreateDynamicHookOrFail("__l4d2_max_ammo__CBaseCombatWeapon::FinishReload", _, _, _, false);
    delete gd;

    CreateConVar("l4d2_max_ammo_version", PLUGIN_VERSION, "L4D2 Max Ammo version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    char sShortName[6][5][] = 
    {
        {
            "shotgun_spas", "autoshotgun", "", "", ""
        },
        {
            "pumpshotgun", "shotgun_chrome", "", "", ""
        },
        {
            "smg", "smg_mp5", "smg_silenced", "", ""
        },
        {
            "sniper_military", "hunting_rifle", "sniper_awp", "sniper_scout", ""
        },
        {
            "rifle_desert", "rifle_ak47" , "rifle_sg552", "rifle", "rifle_m60"
        },
        {
            "grenade_launcher", "", "", "", ""
        },
    };

    int iInitAmmo[17] = {90, 90, 72, 72, 650, 650, 650, 180, 150, 150, 150, 360, 400, 360, 360, 150, 30};
    char sName[32], sDesc[64], sNum[16];
    int index = -1;

    for (int i = 0; i < sizeof(sShortName); i++)
    {
        for (int j = 0; j < sizeof(sShortName[i]); j++)
        {
            if (strlen(sShortName[i][j]) == 0)
                continue;

            index++;

            FormatEx(sName, sizeof(sName), "l4d2_max_ammo_%s", sShortName[i][j]);
            FormatEx(sDesc, sizeof(sDesc), "Max ammo for %s weapon.", sShortName[i][j]);
            IntToString(iInitAmmo[index], sNum, sizeof(sNum));
            CreateConVar(sName, sNum, sDesc, _, true, 0.0);
        }   
    }

    g_hWeaponAmmoList = new ArrayList(sizeof(WeaponAmmo_t));
    HookEvent("mission_lost", Event_MissionLost, EventHookMode_PostNoCopy);

    if (g_bLateLoad)
    {
        for (int i = 1; i <= MaxClients; i++)
            OnClientPutInServer(i);
    }
}

public void OnPluginEnd()
{
    delete g_hWeaponAmmoList;
}

public void OnClientPutInServer(int client)
{
	if (!IsClientInGame(client))
		return;

    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
    SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
}

public void OnMapStart()
{
    for (int i = 0; i < g_hWeaponAmmoList.Length; i++)
    {
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(i, weaponAmmo, sizeof(WeaponAmmo_t));
        if (weaponAmmo.bToBeTransitioned)
            continue;
        
        g_hWeaponAmmoList.Erase(i);
    }
}

void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
    g_hWeaponAmmoList.Clear();
}

void OnWeaponEquipPost(int client, int weapon)
{
    if (client <= 0 || client > MaxClients)
        return;

    if (!IsClientInGame(client) || GetClientTeam(client) != 2)
        return;

    if (!IsValidEdict(weapon))
        return;

    if (!IsTargetWeapon(weapon))
        return;

    DataPack data = new DataPack();
    data.WriteCell(EntIndexToEntRef(weapon));
    data.WriteCell(client);
    RequestFrame(OnNextFrame_OnEquipWeaponPost, data);  // m_iAmmo needs to be set on the next frame.
    //PrintToServer("[Max Ammo] Client %d equipped weapon %d", client, weapon);
}

void OnNextFrame_OnEquipWeaponPost(DataPack data)
{
    data.Reset();
    int weaponRef = data.ReadCell();
    int weapon = EntRefToEntIndex(weaponRef);
    int client = data.ReadCell();
    delete data;

    int index = g_hWeaponAmmoList.FindValue(weaponRef, WeaponAmmo_t::weaponRef);
    if (index != -1)
    {
        bool bToBeTransitioned = false;
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        bToBeTransitioned = weaponAmmo.bToBeTransitioned;
        if (bToBeTransitioned)
        {
            weaponAmmo.bToBeTransitioned = false;
            g_hHook_FinishReload.HookEntity(Hook_Post, weapon, DHook_FinishReload_Post);
        }

        int maxAmmo = weaponAmmo.currentAmmo;
        GetOrSetPlayerAmmo(client, weapon, maxAmmo);
        g_hWeaponAmmoList.SetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        //PrintToServer("[Max Ammo] Client %d max ammo for weapon %d is %d, Transitioned: %d", client, weapon, maxAmmo, bToBeTransitioned);
    }
    else
    {
        char sBuffer[128];
        GetEdictClassname(weapon, sBuffer, sizeof(sBuffer));
        ReplaceString(sBuffer, sizeof(sBuffer), "weapon_", "");
        Format(sBuffer, sizeof(sBuffer), "l4d2_max_ammo_%s", sBuffer);

        int maxAmmo = FindConVar(sBuffer).IntValue;
        GetOrSetPlayerAmmo(client, weapon, maxAmmo);

        WeaponAmmo_t weaponAmmo;
        weaponAmmo.weapon = weapon;
        weaponAmmo.weaponRef = weaponRef;
        weaponAmmo.currentAmmo = maxAmmo;
        g_hWeaponAmmoList.PushArray(weaponAmmo);
        g_hHook_FinishReload.HookEntity(Hook_Post, weapon, DHook_FinishReload_Post);
        //PrintToServer("[Max Ammo] Init. Client %d max ammo for weapon %d is %d", client, weapon, maxAmmo);
    }
}

void OnWeaponDropPost(int client, int weapon)
{
    if (client <= 0 || client > MaxClients)
        return;

    if (!IsClientInGame(client) || GetClientTeam(client) != 2)
        return;

    if (!IsValidEdict(weapon))
        return;

    if (!IsShotgunWeapon(weapon))
        return;

    int index = g_hWeaponAmmoList.FindValue(weapon, WeaponAmmo_t::weapon);
    if (index != -1)
    {
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        
        int maxAmmo = GetOrSetPlayerAmmo(client, weapon, -1);
        weaponAmmo.currentAmmo = maxAmmo;
        g_hWeaponAmmoList.SetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
    }
}

// before map changing.
public void L4D_OnPlayerItemTransitioning(int client, int weapon)
{
    if (client <= 0 || client > MaxClients)
        return;

    int weaponRef = EntIndexToEntRef(weapon);
    int index = g_hWeaponAmmoList.FindValue(weaponRef, WeaponAmmo_t::weaponRef);
    //PrintToServer("[Max Ammo] Client %d transitioning weapon %d, index %d", client, weapon, index);
    if (index != -1)
    {
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        weaponAmmo.bToBeTransitioned = true;
        g_hWeaponAmmoList.SetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
    }
}

// after map changing.
// early than weaponequip.
public void L4D_OnPlayerItemTransitioned(int client, int weapon, int oldindex)
{
    if (client <= 0 || client > MaxClients)
        return;

    int index = g_hWeaponAmmoList.FindValue(oldindex, WeaponAmmo_t::weapon);
    //PrintToServer("[Max Ammo] Client %d transitioned weapon %d to %d, index %d", client, oldindex, weapon, index);
    if (index != -1)
    {
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        weaponAmmo.weapon = weapon;
        weaponAmmo.weaponRef = EntIndexToEntRef(weapon);
        g_hWeaponAmmoList.SetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
    }
}

public void L4D_OnEntityTransitioning(int entity)
{
    int weaponRef = EntIndexToEntRef(entity);
    int index = g_hWeaponAmmoList.FindValue(weaponRef, WeaponAmmo_t::weaponRef);
    if (index != -1)
    {
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        weaponAmmo.bToBeTransitioned = true;
        g_hWeaponAmmoList.SetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
    }
}

public void L4D_OnEntityTransitioned(int entity, int oldindex)
{
    int index = g_hWeaponAmmoList.FindValue(oldindex, WeaponAmmo_t::weapon);
    if (index != -1)
    {
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        weaponAmmo.weapon = entity;
        weaponAmmo.weaponRef = EntIndexToEntRef(entity);
        g_hWeaponAmmoList.SetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
    }
}

bool g_bWeaponSpawn = false;
bool g_bWeaponAmmoSpawn = false;
MRESReturn DTR_CAmmoDef_MaxCarry_Pre(DHookReturn hReturn, DHookParam hParams)
{
    if (g_bWeaponAmmoSpawn || g_bWeaponSpawn)
    {
        //PrintToServer("[Max Ammo] CAmmoDef::MaxCarry called");
        int client = hParams.Get(2);
        if (client <= 0 || client > MaxClients)
            return MRES_Ignored;

        if (!IsClientInGame(client)) 
            return MRES_Ignored;

        // always reload primary weapon.
        int primaryWeapon = GetPlayerWeaponSlot(client, 0);
        if (primaryWeapon == -1 || !IsValidEdict(primaryWeapon))
            return MRES_Ignored;

        char sBuffer[128];
        GetEdictClassname(primaryWeapon, sBuffer, sizeof(sBuffer));
        //PrintToServer("[Max Ammo] Client %d using weapon %d, %s", client, primaryWeapon, sBuffer);

        ReplaceString(sBuffer, sizeof(sBuffer), "weapon_", "");
        Format(sBuffer, sizeof(sBuffer), "l4d2_max_ammo_%s", sBuffer);
        int maxCarry = FindConVar(sBuffer).IntValue;

        hReturn.Value = maxCarry;
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn DTR_CWeaponSpawn_Use_Pre()
{
    //PrintToServer("[Max Ammo] CWeaponSpawn::Use_Pre called");
    g_bWeaponSpawn = true;
    return MRES_Ignored;
}

MRESReturn DTR_CWeaponSpawn_Use_Post()
{
    //PrintToServer("[Max Ammo] CWeaponSpawn::Use_Post called");
    g_bWeaponSpawn = false;
    return MRES_Ignored;
}

MRESReturn DTR_CWeaponAmmoSpawn_Use_Pre()
{
    //PrintToServer("[Max Ammo] CWeaponAmmoSpawn::Use_Pre called");
    g_bWeaponAmmoSpawn = true;
    return MRES_Ignored;
}

MRESReturn DTR_CWeaponAmmoSpawn_Use_Post()
{
    //PrintToServer("[Max Ammo] CWeaponAmmoSpawn::Use_Post called");
    g_bWeaponAmmoSpawn = false;
    return MRES_Ignored;
}

MRESReturn DHook_FinishReload_Post(int pThis)
{
    //PrintToServer("[Max Ammo] DHook_FinishReload_Post called");
    int weaponRef = EntIndexToEntRef(pThis);
    int index = g_hWeaponAmmoList.FindValue(weaponRef, WeaponAmmo_t::weaponRef);
    if (index != -1)
    {
        int iAmmo = GetOrSetPlayerAmmo(GetEntPropEnt(pThis, Prop_Send, "m_hOwner"), pThis, -1);

        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        weaponAmmo.currentAmmo = iAmmo;
        g_hWeaponAmmoList.SetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
    }

    return MRES_Ignored;
}

stock bool IsTargetWeapon(int weapon)
{
    int wepid = IdentifyWeapon(weapon);

    switch (wepid)
    {
        case    WEPID_SMG, 
                WEPID_PUMPSHOTGUN, 
                WEPID_AUTOSHOTGUN, 
                WEPID_RIFLE, 
                WEPID_HUNTING_RIFLE, 
                WEPID_SMG_SILENCED,
                WEPID_SHOTGUN_CHROME,
                WEPID_RIFLE_DESERT,
                WEPID_SNIPER_MILITARY,
                WEPID_SHOTGUN_SPAS,
                WEPID_GRENADE_LAUNCHER,
                WEPID_RIFLE_AK47,
                WEPID_SMG_MP5,
                WEPID_RIFLE_SG552,
                WEPID_SNIPER_AWP,
                WEPID_SNIPER_SCOUT,
                WEPID_RIFLE_M60:
        {
            return true;
        }

        default: return false;
    }
}

stock bool IsShotgunWeapon(int weapon)
{
    int wepid = IdentifyWeapon(weapon);

    switch (wepid)
    {
        case    WEPID_PUMPSHOTGUN, 
                WEPID_AUTOSHOTGUN, 
                WEPID_SHOTGUN_CHROME,
                WEPID_SHOTGUN_SPAS:
        {
            return true;
        }

        default: return false;
    }
}

stock int GetOrSetPlayerAmmo(int client, int weapon, int ammo = -1) 
{
    static int m_iAmmo = -1;
    if (m_iAmmo == -1)
        m_iAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");

    int m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (m_iPrimaryAmmoType != -1) 
    {
        int iOffset = m_iAmmo + (m_iPrimaryAmmoType * 4);
        if (ammo != -1)
        {
            SetEntData(client, iOffset, ammo, 4, true);
        }
        else
        {
            return GetEntData(client, iOffset, 4);
        }
	}

	return 0;
}