#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>
#include <nmrih_player>
#include <gamedata_wrapper>

#include "nmrih_equip_same_weapon/consts.sp"

#define PLUGIN_VERSION "1.2"

public Plugin myinfo = 
{
    name = "[NMRiH] Equip Same Weapon/item",
    author = "blueblur",
    description = "Allows you to equip the same weapon you already have.",
    version = PLUGIN_VERSION,
    url = "https://github.com/blueblur0730/modified-plugins"
};

DynamicDetour g_hDetour_OwnsThisType = null;
DynamicDetour g_hDetour_CBasePlayer_BumpWeapon = null;

Handle g_hSDKCall_OwnsThisType = null;
Handle g_hSDKCall_CBasePlayer_BumpWeapon = null;
//Handle g_hSDKCall_GetWeight = null;
Handle g_hSDKCall_PickedUp = null;

int g_iOff_m_iSubType = -1;
//int g_Off_m_iWeight = -1;

ConVar g_hCvar_Enable = null;
StringMap g_hWeightMap = null;

bool g_bLateLoad = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    GameDataWrapper gd = new GameDataWrapper("nmrih_equip_same_weapon");

    g_hDetour_OwnsThisType = gd.CreateDetourOrFail("CBaseCombatCharacter::Weapon_OwnsThisType", true, _, DTR_OwnsThisType_Post);
    g_hDetour_CBasePlayer_BumpWeapon = gd.CreateDetourOrFail("CBasePlayer::BumpWeapon", true, DTR_CBasePlayer_BumpWeapon_Pre, DTR_CBasePlayer_BumpWeapon_Post);

    g_iOff_m_iSubType = gd.GetOffset("CBaseCombatWeapon->m_iSubType");
    //g_Off_m_iWeight = gd.GetOffset("CNMRiH_WeaponBase->m_iWeight");   // why not working? returning -1 always.

    SDKCallParamsWrapper param1[] = {{SDKType_String, SDKPass_Pointer}, {SDKType_PlainOldData, SDKPass_Plain}};
    SDKCallParamsWrapper ret1 = {SDKType_CBaseEntity, SDKPass_Pointer};
    g_hSDKCall_OwnsThisType = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Signature, "CBaseCombatCharacter::Weapon_OwnsThisType", param1, sizeof(param1), true, ret1);

    SDKCallParamsWrapper param2[] = {{SDKType_CBaseEntity, SDKPass_Pointer}, {SDKType_Bool, SDKPass_Plain}};
    SDKCallParamsWrapper ret2 = {SDKType_Bool, SDKPass_Plain};
    g_hSDKCall_CBasePlayer_BumpWeapon = gd.CreateSDKCallOrFail(SDKCall_Player, SDKConf_Signature, "CBasePlayer::BumpWeapon", param2, sizeof(param2), true, ret2);

    // why not working? returning 0 always.
    //g_hSDKCall_GetWeight = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Virtual, "CBaseCombatWeapon::GetWeight");

    SDKCallParamsWrapper param3[] = {{SDKType_CBaseEntity, SDKPass_Pointer}};
    g_hSDKCall_PickedUp = gd.CreateSDKCallOrFail(SDKCall_Player, SDKConf_Signature, "CNMRiH_Player::Weapon_PickedUp", param3, sizeof(param3));

    delete gd;

    CreateConVar("nmrih_equip_same_weapon_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DEVELOPMENTONLY);

    g_hCvar_Enable = CreateConVar("nmrih_equip_same_weapon_enable", "1", "Enable/Disable the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    InitMap();

    if (g_bLateLoad)
    {
        for (int i = 1; i < MaxClients; i++)
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnPluginEnd()
{
    g_hDetour_OwnsThisType.Disable(Hook_Post, DTR_OwnsThisType_Post);
    delete g_hDetour_OwnsThisType;

    g_hDetour_CBasePlayer_BumpWeapon.Disable(Hook_Pre, DTR_CBasePlayer_BumpWeapon_Pre);
    g_hDetour_CBasePlayer_BumpWeapon.Disable(Hook_Post, DTR_CBasePlayer_BumpWeapon_Post);
    delete g_hDetour_CBasePlayer_BumpWeapon;

    delete g_hWeightMap;
}

public void OnClientPutInServer(int client)
{
    if (!IsClientInGame(client))
        return;

    SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

bool g_bCBasePlayer_BumpWeapon_Called = false;
MRESReturn DTR_CBasePlayer_BumpWeapon_Pre()
{
    g_bCBasePlayer_BumpWeapon_Called = true;
    return MRES_Ignored;
}

bool g_bIgnorePluginCall = false;
MRESReturn DTR_OwnsThisType_Post(int pThis, DHookReturn hReturn)
{
    if (!g_hCvar_Enable.BoolValue)
        return MRES_Ignored;

    if (g_bIgnorePluginCall)
        return MRES_Ignored;

    if (!IsClientInGame(pThis))
        return MRES_Ignored;

    if (g_bCBasePlayer_BumpWeapon_Called)
    {
        if (hReturn.Value != INVALID_ENT_REFERENCE)
        {
            hReturn.Value = INVALID_ENT_REFERENCE;  // return null, tell the game we should equip it.
            return MRES_Supercede;
        }
    }

    return MRES_Ignored;
}

MRESReturn DTR_CBasePlayer_BumpWeapon_Post()
{
    g_bCBasePlayer_BumpWeapon_Called = false;
    return MRES_Ignored;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    for (int i = 0; i < sizeof(g_sWeapons); i++)
    {
        if (strcmp(classname, g_sWeapons[i]) == 0)
        {
            SDKHook(entity, SDKHook_Use, OnUse);
        }
    }
}

Action OnUse(int entity, int activator, int caller, UseType type, float value)
{
    if (!g_hCvar_Enable.BoolValue)
        return Plugin_Continue;

    if (!IsValidEntity(entity) || !IsValidEntity(activator))
        return Plugin_Continue;

    // no more slots for this player. ignore.
    if (IsWeaponSlotFull(activator))
        return Plugin_Continue; 

    char sClassname[64];
    GetEntityClassname(entity, sClassname, sizeof(sClassname));
    
    int weight;
    bool bSuccess = g_hWeightMap.GetValue(sClassname, weight);
    if (!bSuccess)
        return Plugin_Continue;

    // check if the player has enough weight to carry the weapon.
    // player can't carry this weapon. just pick it up.
    NMR_Player player = NMR_Player(activator);
    if (player.GetCarriedWeight() + weight > player.GetMaxCarriedWeight())
        return Plugin_Continue;
    
    g_bIgnorePluginCall = true;

    // player doesn't own this weapon. just let everything go normal.
    int subtype = GetEntData(entity, g_iOff_m_iSubType);
    if (SDKCall(g_hSDKCall_OwnsThisType, activator, sClassname, subtype) == INVALID_ENT_REFERENCE)
        return Plugin_Continue; 

    g_bIgnorePluginCall = false;

    if (strcmp(sClassname, "exp_grenade") == 0 || strcmp(sClassname, "exp_molotov") == 0 || strcmp(sClassname, "exp_tnt") == 0)
    {
        // basically, grenades only takes one slot.
        int weapon = INVALID_ENT_REFERENCE;
        if (HasWeapon(activator, sClassname, weapon))
        {
            // for grenades, we don't want it to occupy another weapon slot, instead, we add the ammo count on it.
            SetPlayerWeaponAmmo(activator, weapon, GetAmmo(activator, entity) + 1);

            // finally tell the game to add weight to the player, and send the event.
            SDKCall(g_hSDKCall_PickedUp, activator, entity);

            // remove grenade on the next frame.
            RequestFrame(OnNextFrame_RemoveEntity, entity);
        }
    }
    else
    {
        // we had it. but we need more!
        bool b = SDKCall(g_hSDKCall_CBasePlayer_BumpWeapon, activator, entity, true);

        // finally tell the game to add weight to the player, and send the event.
        if (b) SDKCall(g_hSDKCall_PickedUp, activator, entity); 
    }

    // this must be superceded, othewise you will go PickUpObject().
    return Plugin_Handled;
}

Action OnWeaponDrop(int client, int weapon)
{
    PrintToServer("OnWeaponDrop called");

    char sClassname[64];
    GetEntityClassname(weapon, sClassname, sizeof(sClassname));
    if (strcmp(sClassname, "exp_grenade") == 0 || strcmp(sClassname, "exp_molotov") == 0 || strcmp(sClassname, "exp_tnt") == 0)
    {
        int ammo = GetAmmo(client, weapon);
        PrintToServer("ammo: %d", ammo);
        if (ammo > 1)   // only handle if grenades > 1.
        {
            int weight;
            bool bSuccess = g_hWeightMap.GetValue(sClassname, weight);
            if (!bSuccess)
                return Plugin_Continue;

			float vecOrigin[3];
			GetClientAbsOrigin(client, vecOrigin);

			float vecAngles[3];
			GetClientAbsAngles(client, vecAngles);

            // create one instead of dropping.
			if (CreateDesiredThingFromRandomSpawner(sClassname, vecOrigin, vecAngles, 100, 100, 6))
            {
                // dropped one, reduce the ammo count.
                SetPlayerWeaponAmmo(client, weapon, ammo - 1);
                PrintToServer("Dropped one grenade. ammo: %d, weight: %d", ammo - 1, weight);

                // remove the weight.
                NMR_Player(client).RemoveCarriedWeight(weight);

                // prevent this weapon slot from dropping.
                return Plugin_Handled;
            }
        }
    }

    return Plugin_Continue;
}

void OnNextFrame_RemoveEntity(int entity)
{
    RemoveEntity(entity);
}

void InitMap()
{
    g_hWeightMap = new StringMap();
    for (int i = 0; i < sizeof(g_sWeaponWeights); i++)
    {
        g_hWeightMap.SetValue(g_sWeaponWeights[i][0], StringToInt(g_sWeaponWeights[i][1]));
    }
}

stock bool IsWeaponSlotFull(int client)
{
    int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

    for (int i = 0; i < size; i++)
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
        if (weapon == INVALID_ENT_REFERENCE || !IsValidEntity(weapon))
            return false; 
    }

    return true;
}

stock bool HasWeapon(int client, const char[] weaponName, int &weaponSelected)
{
    int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

    for (int i = 0; i < size; i++)
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
        if (weapon == INVALID_ENT_REFERENCE || !IsValidEntity(weapon))
            continue;

        char sClassname[64];
        GetEntityClassname(weapon, sClassname, sizeof(sClassname));

        if (strcmp(sClassname, weaponName) == 0)
        {
            weaponSelected = weapon;
            return true;
        }
    }

    return false;
}

// from sourcemod-misc.inc
stock bool SetPlayerWeaponAmmo(int client, int weapon, int ammo = -1)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || weapon == 0 || weapon <= MaxClients || !IsValidEntity(weapon))
		return false;
	
	if (ammo > -1)
	{
		int iOffset = FindSendPropInfo("CNMRiH_Player", "m_iAmmo") + (GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType") * 4);
		SetEntData(client, iOffset, ammo, 4, true);
	}

	return true;
}

stock int GetAmmo(int client, int weapon)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || weapon == 0 || weapon <= MaxClients || !IsValidEntity(weapon) || !HasEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"))
		return -1;

	int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
	int iAmmoTable = FindSendPropInfo("CNMRiH_Player", "m_iAmmo");
	return GetEntData(client, iAmmoTable + iOffset);
}

stock bool CreateDesiredThingFromRandomSpawner(const char[] classname,
											   float fPos[3]	= { 0.0, 0.0, 0.0 },
											   float fAngle[3]	= { 0.0, 0.0, 0.0 },
											   int	 ammo_max	= 0,
											   int	 ammo_min	= 0,
											   int	 spawnflags = 0)
{
	int spawner = CreateEntityByName("random_spawner");
	if (spawner == INVALID_ENT_REFERENCE || !IsValidEntity(spawner))
		return false;

	DispatchKeyValue(spawner, classname, "100");	// the number is the percentage.
	DispatchKeyValueInt(spawner, "spawnflags", spawnflags);
	DispatchKeyValueInt(spawner, "ammo_fill_pct_max", ammo_max);	// also the percentage.
	DispatchKeyValueInt(spawner, "ammo_fill_pct_min", ammo_min);

	if (!DispatchSpawn(spawner))
	{
		RemoveEntity(spawner);
		return false;
	}

	TeleportEntity(spawner, fPos, fAngle);
	AcceptEntityInput(spawner, "InputSpawn");
	RemoveEntity(spawner);

	return true;
}