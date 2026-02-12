#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2util_weapons>

static const char g_sShortName[6][5][] = 
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

int g_iInitAmmo[17] = {90, 90, 72, 72, 650, 650, 650, 180, 150, 150, 150, 360, 400, 360, 360, 150, 30};

enum struct WeaponAmmo_t
{
    int weapon;
    int currentAmmo;
}

ArrayList g_hWeaponAmmoList;

#define PLUGIN_VERSION "1.0"
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
	return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("l4d2_max_ammo_version", PLUGIN_VERSION, "L4D2 Max Ammo version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    char sName[32], sDesc[64], sNum[16];
    for (int i = 0; i < sizeof(g_sShortName); i++)
    {
        for (int j = 0; j < sizeof(g_sShortName[i]); j++)
        {
            if (strlen(g_sShortName[i][j]) == 0)
                continue;

            static int index = -1;
            index++;

            FormatEx(sName, sizeof(sName), "l4d2_max_ammo_%s", g_sShortName[i][j]);
            FormatEx(sDesc, sizeof(sDesc), "Max ammo for %s weapon.", g_sShortName[i][j]);
            IntToString(g_iInitAmmo[index], sNum, sizeof(sNum));
            CreateConVar(sName, sNum, sDesc, _, true, 0.0);
        }   
    }

    g_hWeaponAmmoList = new ArrayList(sizeof(WeaponAmmo_t));
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy); 

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

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEdict(entity))
        return;

    if (entity <= MaxClients)
        return;

    if (!IsTargetWeapon(entity))
        return;

    int wepref = EntIndexToEntRef(entity);
    int index = g_hWeaponAmmoList.FindValue(wepref, WeaponAmmo_t::weapon);
    if (index != -1)
    {
        g_hWeaponAmmoList.Erase(index);
        //PrintToServer("Weapon %d destroyed, removed from list", entity);
    }
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
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
    data.WriteCell(weapon);
    data.WriteCell(client);
    RequestFrame(OnNextFrame_OnEquipWeaponPost, data);  // m_iAmmo needs to be set on the next frame.
    PrintToServer("Client %d equipped weapon %d", client, weapon);
}

void OnNextFrame_OnEquipWeaponPost(DataPack data)
{
    data.Reset();
    int weapon = data.ReadCell();
    int client = data.ReadCell();
    delete data;

   int wepref = EntIndexToEntRef(weapon);
    int index = g_hWeaponAmmoList.FindValue(wepref, WeaponAmmo_t::weapon);
    if (index != -1)
    {
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        int maxAmmo = weaponAmmo.currentAmmo;
        GetOrSetPlayerAmmo(client, weapon, maxAmmo);
        //PrintToServer("Client %d max ammo for weapon %d is %d", client, weapon, maxAmmo);
    }
    else
    {
        char sBuffer[128];
        GetEntityClassname(weapon, sBuffer, sizeof(sBuffer));
        ReplaceString(sBuffer, sizeof(sBuffer), "weapon_", "");
        Format(sBuffer, sizeof(sBuffer), "l4d2_max_ammo_%s", sBuffer);

        int maxAmmo = FindConVar(sBuffer).IntValue;
        GetOrSetPlayerAmmo(client, weapon, maxAmmo);

        WeaponAmmo_t weaponAmmo;
        weaponAmmo.weapon = wepref;
        weaponAmmo.currentAmmo = maxAmmo;
        g_hWeaponAmmoList.PushArray(weaponAmmo);
        //PrintToServer("Init. Client %d max ammo for weapon %d is %d", client, weapon, maxAmmo);
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

    if (!IsTargetWeapon(weapon))
        return;

    int wepref = EntIndexToEntRef(weapon);
    int index = g_hWeaponAmmoList.FindValue(wepref, WeaponAmmo_t::weapon);
    if (index != -1)
    {
        WeaponAmmo_t weaponAmmo;
        g_hWeaponAmmoList.GetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
        int currentAmmo = GetOrSetPlayerAmmo(client, weapon, -1);
        weaponAmmo.currentAmmo = currentAmmo;
        //PrintToServer("Client %d dropped weapon %d, current ammo is %d", client, weapon, currentAmmo);
        g_hWeaponAmmoList.SetArray(index, weaponAmmo, sizeof(WeaponAmmo_t));
    }
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

stock int GetOrSetPlayerAmmo(int client, int weapon, int ammo = -1) 
{
	int m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    int m_iAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");

    int iOffset = m_iAmmo + (m_iPrimaryAmmoType * 4);
	if (m_iPrimaryAmmoType != -1) 
    {
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
