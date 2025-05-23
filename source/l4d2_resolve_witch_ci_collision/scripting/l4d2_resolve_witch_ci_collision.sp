#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <midhook>
#include <actions>
#include <gamedata_wrapper>

#define GAMEDATA_FILE "l4d2_resolve_witch_ci_collision"

Handle g_hSDKCall_MyNextBotPointer;
Handle g_hSDKCall_GetLocomotionInterface;
Handle g_hSDKCall_GetSpeedLimit;
Handle g_hSDKCall_GetBaseEntity;

MidHook g_hMidHook_ZombieBotLocomotion_Update__OnSetAbsVelocity;
ConVar g_hCvar_Scale;

methodmap INextBot {
    public static INextBot MyNextBotPointer(int entity) {
        return SDKCall(g_hSDKCall_MyNextBotPointer, entity);
    }

	public ILocomotion GetLocomotionInterface() {
        if (view_as<Address>(this) == Address_Null)
            return view_as<ILocomotion>(Address_Null);

		return SDKCall(g_hSDKCall_GetLocomotionInterface, this);
	}
}

methodmap ILocomotion {}

methodmap WitchLocomotion < ILocomotion {
    public float GetSpeedLimit() {
        return SDKCall(g_hSDKCall_GetSpeedLimit, view_as<Address>(this));
    }
    /*
	property float m_velocityLimit {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_WitchLocomotion__m_velocity), NumberType_Int32); }
		public set(float value) { StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_WitchLocomotion__m_velocity), value, NumberType_Int32); }
	}
    */
}

#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "[L4D2] Resolve Witch CI Collision",
	author = "blueblur",
	description = "Attempt to neutralize the collision force between witch and CI.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);

    SDKCallParamsWrapper ret = {SDKType_PlainOldData, SDKPass_Plain};
    g_hSDKCall_MyNextBotPointer = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer", _, _,true, ret);

    SDKCallParamsWrapper ret1 = {SDKType_PlainOldData, SDKPass_Plain};
    g_hSDKCall_GetLocomotionInterface = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, "INextBot::GetLocomotionInterface", _, _, true, ret1);

    SDKCallParamsWrapper ret2 = {SDKType_CBaseEntity, SDKPass_Pointer};
    g_hSDKCall_GetBaseEntity = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, "CBaseEntity::GetBaseEntity", _, _, true, ret2);

    SDKCallParamsWrapper ret3 = {SDKType_Float, SDKPass_Plain};
    g_hSDKCall_GetSpeedLimit = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, "WitchLocomotion::GetSpeedLimit", _, _, true, ret3);

    g_hMidHook_ZombieBotLocomotion_Update__OnSetAbsVelocity = gd.CreateMidHookOrFail("ZombieBotLocomotion_Update__OnSetAbsVelocity", MidHook_ZombieBotLocomotion_Update__OnSetAbsVelocity);

    delete gd;

    CreateConVar("l4d2_resolve_witch_ci_collision_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DEVELOPMENTONLY);
    g_hCvar_Scale = CreateConVar("z_witch_collision_neutralize_scale", "0.95", "The scale to scale the velocity vector. The greater closer to 1, the milder the speed.", FCVAR_CHEAT, true, 0.0, true, 1.0);
}

public void OnPluginEnd()
{
    delete g_hMidHook_ZombieBotLocomotion_Update__OnSetAbsVelocity;
}

// test case would be: c4m2 a witch with a horde.
// void NextBotGroundLocomotion::Update( void )
void MidHook_ZombieBotLocomotion_Update__OnSetAbsVelocity(MidHookRegisters regs)
{
    // load from stack.
    Address pEntity = regs.Load(DHookRegister_ESP, 0, NumberType_Int32);
    if (pEntity == Address_Null)
        return;

    int entity = SDKCall(g_hSDKCall_GetBaseEntity, pEntity);
    if (entity <= MaxClients || !IsValidEntity(entity))
        return;

    BehaviorAction action = ActionsManager.GetAction(entity, "WitchWander");
    if (action == INVALID_ACTION)
        return;

    WitchLocomotion pLocomotion = view_as<WitchLocomotion>(INextBot.MyNextBotPointer(entity).GetLocomotionInterface());

    if (!pLocomotion)
        return;

    // The reference of the vector.
    Address pVector = regs.Load(DHookRegister_ESP, 4, NumberType_Int32);
    if (pVector == Address_Null)
        return;

    float vecVelocity[3];
    vecVelocity[0] = LoadFromAddress(pVector, NumberType_Int32);
    vecVelocity[1] = LoadFromAddress(pVector + view_as<Address>(4), NumberType_Int32);
    vecVelocity[2] = LoadFromAddress(pVector + view_as<Address>(8), NumberType_Int32);

    float flLentgh = GetVectorLength(vecVelocity);
    float flScale = g_hCvar_Scale.FloatValue;
    flScale = ( flScale >= 1.0 ? 0.99 : ( flScale <= 0.0 ? 0.01 : flScale ) );
    while (flLentgh >= pLocomotion.GetSpeedLimit())
    {
        ScaleVector(vecVelocity, flScale);
        flLentgh = GetVectorLength(vecVelocity);
    }

    StoreToAddress(pVector, vecVelocity[0], NumberType_Int32);
    StoreToAddress(pVector + view_as<Address>(4), vecVelocity[1], NumberType_Int32);
    StoreToAddress(pVector + view_as<Address>(8), vecVelocity[2], NumberType_Int32);
}