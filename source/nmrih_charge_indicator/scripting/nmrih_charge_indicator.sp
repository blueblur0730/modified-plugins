#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <uservector>

#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "[NMRiH] Charge Indicator",
	author = "blueblur",
	description = "Indicates the charge damage when charging.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

bool g_bLateLoad;

enum struct ChargeData_t {
    int weapon_ref;
    int client;
    int weapon;
}

UserVector g_hArrayChargeData;
StringMap g_hMeleeMap;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoad = late;
    return APLRes_Success;
}

Handle g_hTimer = INVALID_HANDLE;

public void OnPluginStart()
{
    CreateConVar("nmrih_charger_indicator_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    g_hArrayChargeData = new UserVector(sizeof(ChargeData_t));
    g_hMeleeMap = InitHashMap();
    g_hTimer = CreateTimer(0.1, Timer_CheckCharging, _, TIMER_REPEAT);

    if (g_bLateLoad)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                OnClientPutInServer(i);
            }
        }
    }
}

public void OnPluginEnd()
{
    delete g_hArrayChargeData;
    delete g_hTimer;
    delete g_hMeleeMap;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
    SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
}

void OnWeaponEquipPost(int client, int weapon)
{
    //PrintToServer("Equipped weapon %d", weapon);
    if (weapon <= MaxClients || !IsValidEntity(weapon))
        return;

    if (!IsMeleeWeapon(weapon))
        return;

    int weapon_ref = EntIndexToEntRef(weapon);
    g_hArrayChargeData.FindOrCreate(weapon_ref, true);
    g_hArrayChargeData.Set(weapon_ref, client, ChargeData_t::client);
    g_hArrayChargeData.Set(weapon_ref, weapon, ChargeData_t::weapon);
}

void OnWeaponDropPost(int client, int weapon)
{
    //PrintToServer("Dropped weapon %d", weapon);
    if (weapon <= MaxClients || !IsValidEntity(weapon))
        return;

    if (!IsMeleeWeapon(weapon))
        return;

    int weapon_ref = EntIndexToEntRef(weapon);
    g_hArrayChargeData.Erase(weapon_ref);
}

public void OnEntityDestroyed(int entity)
{
    if (entity <= MaxClients || !IsValidEntity(entity))
        return;

    if (!IsMeleeWeapon(entity))
        return;

    int weapon_ref = EntIndexToEntRef(entity);
    g_hArrayChargeData.Erase(weapon_ref);
}

void Timer_CheckCharging(Handle timer)
{
    if (g_hArrayChargeData.Length == 0)
        return;

    g_hArrayChargeData.ForEach(IterCallBack);
}

bool IterCallBack(int weapon_ref)
{
    int weapon_data = -1;
    int weapon = EntRefToEntIndex(weapon_ref);
    g_hArrayChargeData.Get(weapon_ref, weapon_data, ChargeData_t::weapon);
    if (weapon <= MaxClients || !IsValidEntity(weapon) || weapon != weapon_data)
        return true;
    
    int client = -1;
    int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
    g_hArrayChargeData.Get(weapon_ref, client, ChargeData_t::client);
    if (owner <= 0 || owner > MaxClients || !IsClientInGame(owner) || owner != client)
        return true;

    bool bIsCharging = view_as<bool>(GetEntProp(weapon, Prop_Send, "m_bIsCharging"));
    if (!bIsCharging)
        return true;
    
    float m_flLastBeginCharge = GetEntPropFloat(weapon, Prop_Send, "m_flLastBeginCharge");
    //PrintToServer("m_flLastBeginCharge: %.02f, now: %.02f", m_flLastBeginCharge, GetGameTime());
    if (m_flLastBeginCharge <= 0.0 || GetGameTime() < m_flLastBeginCharge)
        return true;

    char sName[64]; int damage = 0;
    GetEntityClassname(weapon, sName, sizeof(sName));
    g_hMeleeMap.GetValue(sName, damage);

    static ConVar sv_max_charge_length = null;
    static ConVar sv_melee_dmg_per_sec = null;

    if (sv_max_charge_length == null)
        sv_max_charge_length = FindConVar("sv_max_charge_length");

    if (sv_melee_dmg_per_sec == null)
        sv_melee_dmg_per_sec = FindConVar("sv_melee_dmg_per_sec");

    float charge_duration = GetGameTime() - m_flLastBeginCharge;
    float multiple = sv_melee_dmg_per_sec.FloatValue;

    charge_duration = fminf(charge_duration, sv_max_charge_length.FloatValue);
    int charge_damage = RoundToNearest(damage + (damage * (charge_duration * multiple)));

    int g, b = 0;
    if (charge_damage > 500)
    {
        g = 0;
    }
    else if (charge_damage <= 50)
    {
        b = 255;
    }
    else
    {
        g = RoundToNearest(255.0 * (500 - charge_damage) / (500 - 50));
    }

    SetHudTextParams(0.02, 0.86, 2.0, 255, g, b, 225, 1, 1.0, _, 0.5);
    ShowHudText(owner, 2, "Charging: %d", charge_damage);

    return true;
}

/**
 * Return true if classname is a melee weapon.
 * Or call CBaseCombatWeapon::IsMeleeWeapon().
 * From weapon_config.sp by Ryan.
 * https://forums.alliedmods.net/showthread.php?p=2628691
 */
stock bool IsMeleeWeapon(int weapon)
{
    static const char tool_prefix[] = "tool_";
    static const char melee_prefix[] = "me_";
    static const char item_maglite[] = "item_maglite";

    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));

    return  (
                StrEqual(classname, item_maglite) ||
                !strncmp(classname, melee_prefix, sizeof(melee_prefix) - 1) ||
                (
                    !strncmp(classname, tool_prefix, sizeof(tool_prefix) - 1) && 
                    !StrEqual(classname[sizeof(tool_prefix) - 1], "flare_gun")
                )
            );
}

stock StringMap InitHashMap()
{
    StringMap map = new StringMap();
    map.SetValue("me_abrasivesaw", 120);
    map.SetValue("me_fists", 50);
    map.SetValue("me_axe_fire", 400);
    map.SetValue("me_bat_metal", 225);
    map.SetValue("me_chainsaw", 160);
    map.SetValue("me_cleaver", 200);
    map.SetValue("me_crowbar", 320);
    map.SetValue("me_etool", 230);
    map.SetValue("me_fubar", 680);
    map.SetValue("me_hatchet", 280);
    map.SetValue("me_kitknife", 140);
    map.SetValue("me_machete", 350);
    map.SetValue("me_pickaxe", 500);
    map.SetValue("me_pipe_lead", 320);
    map.SetValue("me_shovel", 270);
    map.SetValue("me_sledge", 600);
    map.SetValue("me_wrench", 190);
    map.SetValue("tool_barricade", 210);
    map.SetValue("tool_extinguisher", 240);
    map.SetValue("tool_welder", 180);
    map.SetValue("item_maglite", 55);
    return map;
}

stock float fminf(float a, float b)
{
    return (a < b) ? a : b;
}