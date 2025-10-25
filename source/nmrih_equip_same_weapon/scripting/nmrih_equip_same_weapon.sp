#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>
#include <nmrih_player>
#include <gamedata_wrapper>

#include "nmrih_equip_same_weapon/consts.sp"

#define PLUGIN_VERSION "1.0"

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

bool g_bCBasePlayer_BumpWeapon_Called = false;
MRESReturn DTR_CBasePlayer_BumpWeapon_Pre()
{
    //PrintToServer("// DTR_CBasePlayer_BumpWeapon_Pre called");
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
        //PrintToServer("## DTR_OwnsThisType_Post triggered for hook. hReturn.Value: %d", hReturn.Value);
        if (hReturn.Value != INVALID_ENT_REFERENCE)
        {
            //PrintToServer("## DTR_OwnsThisType_Post returning INVALID_ENT_REFERENCE");
            hReturn.Value = INVALID_ENT_REFERENCE;  // return null, tell the game we should equip it.
            return MRES_Supercede;
        }
    }

    return MRES_Ignored;
}

MRESReturn DTR_CBasePlayer_BumpWeapon_Post()
{
    //PrintToServer("// DTR_CBasePlayer_BumpWeapon_Post called");
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

    if (IsWeaponSlotFull(activator))
        return Plugin_Continue; // no more slots for this player. ignore.

    char sClassname[64];
    GetEntityClassname(entity, sClassname, sizeof(sClassname));
    
    int weight;
    bool bSuccess = g_hWeightMap.GetValue(sClassname, weight);
    if (!bSuccess)
        return Plugin_Continue;

    // check if the player has enough weight to carry the weapon.
    NMR_Player player = NMR_Player(activator);
    PrintToServer("%d, %d, %d", player.GetCarriedWeight(), weight, player.GetMaxCarriedWeight());
    if (player.GetCarriedWeight() + weight > player.GetMaxCarriedWeight())
        return Plugin_Continue; // player can't carry this weapon. just pick it up.
    
    g_bIgnorePluginCall = true;

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));
    int subtype = GetEntData(entity, g_iOff_m_iSubType);
    if (SDKCall(g_hSDKCall_OwnsThisType, activator, classname, subtype) == INVALID_ENT_REFERENCE)
        return Plugin_Continue; // player doesn't own this weapon. just let everything go normal.

    g_bIgnorePluginCall = false;

    // we had it. but we need more!
    bool b = SDKCall(g_hSDKCall_CBasePlayer_BumpWeapon, activator, entity, true);
    if (b) SDKCall(g_hSDKCall_PickedUp, activator, entity); // finally tell the game to add weight to the player, and send the event.
    return Plugin_Handled;  // this must be superceded, othewise you will go PickUpObject().
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
        if (weapon == INVALID_ENT_REFERENCE)
            return false; 
    }

    return true;
}