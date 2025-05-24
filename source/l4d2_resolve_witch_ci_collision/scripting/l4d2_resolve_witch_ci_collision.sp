#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <midhook>
#include <actions>
#include <gamedata_wrapper>

#define GAMEDATA_FILE "l4d2_resolve_witch_ci_collision"

OperatingSystem g_iOS = OS_UnknownPlatform;
int g_iOff_NextBotGroundLocomotion__m_moveVector = -1;
Handle g_hSDKCall_MyNextBotPointer;
Handle g_hSDKCall_GetLocomotionInterface;
Handle g_hSDKCall_GetSpeedLimit;
Handle g_hSDKCall_GetBaseEntity;

MidHook g_hMidHook;
ConVar g_hCvar_Scale;
ConVar g_hCvar_ScaleDirection;

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

methodmap NextBotGroundLocomotion < ILocomotion {
    public void GetMoveVector(float vec[3]) {
        vec[0] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_NextBotGroundLocomotion__m_moveVector), NumberType_Int32);
        vec[1] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_NextBotGroundLocomotion__m_moveVector) + view_as<Address>(4), NumberType_Int32);
        vec[2] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_NextBotGroundLocomotion__m_moveVector) + view_as<Address>(8), NumberType_Int32);
    }
}

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

#define PLUGIN_VERSION "1.2.2"

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

    g_iOS = gd.OS;
    g_iOff_NextBotGroundLocomotion__m_moveVector = gd.GetOffset("NextBotGroundLocomotion::m_moveVector");

    SDKCallParamsWrapper ret = {SDKType_PlainOldData, SDKPass_Plain};
    g_hSDKCall_MyNextBotPointer = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer", _, _,true, ret);

    SDKCallParamsWrapper ret1 = {SDKType_PlainOldData, SDKPass_Plain};
    g_hSDKCall_GetLocomotionInterface = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, "INextBot::GetLocomotionInterface", _, _, true, ret1);

    SDKCallParamsWrapper ret2 = {SDKType_CBaseEntity, SDKPass_Pointer};
    g_hSDKCall_GetBaseEntity = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, "CBaseEntity::GetBaseEntity", _, _, true, ret2);

    SDKCallParamsWrapper ret3 = {SDKType_Float, SDKPass_Plain};
    g_hSDKCall_GetSpeedLimit = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, "WitchLocomotion::GetSpeedLimit", _, _, true, ret3);

    g_hMidHook = gd.CreateMidHookOrFail("ZombieBotLocomotion_Update__OnSetAbsVelocity", MidHook_ZombieBotLocomotion_Update__OnSetAbsVelocity);

    delete gd;

    CreateConVar("l4d2_resolve_witch_ci_collision_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DEVELOPMENTONLY);
    CreateConVarHook("z_witch_collision_neutralize_enable", "1", "Enable plugin.", FCVAR_CHEAT, true, 0.0, true, 1.0, OnEnableChanged);
    g_hCvar_ScaleDirection = CreateConVar("z_witch_collision_scale_direction", "1", "Scale the direction so that witch will keeps her own way forward.", FCVAR_CHEAT, true, 0.0, true, 1.0);
    g_hCvar_Scale = CreateConVar("z_witch_collision_neutralize_scale", "0.95", "The scale to scale the length of the velocity vector. The greater closer to 1, the milder the speed.", FCVAR_CHEAT, true, 0.0, true, 1.0);
}

public void OnPluginEnd()
{
    delete g_hMidHook;
}

// test case would be: c4m2 a witch with a horde.
// void NextBotGroundLocomotion::Update( void )
// https://forums.alliedmods.net/showpost.php?p=2836030&postcount=74
void MidHook_ZombieBotLocomotion_Update__OnSetAbsVelocity(MidHookRegisters regs)
{
    Address pEntity = Address_Null;

    // load from stack.
    switch (g_iOS)
    {
        case OS_Linux: 
            pEntity = regs.Load(DHookRegister_ESP, 0, NumberType_Int32);
        
        case OS_Windows:
            pEntity = regs.Load(DHookRegister_ECX, 0, NumberType_Int32);
    }
    
    if (pEntity == Address_Null)
        return;

    int entity = SDKCall(g_hSDKCall_GetBaseEntity, pEntity);
    if (entity <= MaxClients || !IsValidEntity(entity))
        return;

    // the most simple way. do not complicate it.
    BehaviorAction action = ActionsManager.GetAction(entity, "WitchWander");
    if (action == INVALID_ACTION)
        return;

    WitchLocomotion pLocomotion = view_as<WitchLocomotion>(INextBot.MyNextBotPointer(entity).GetLocomotionInterface());

    if (!pLocomotion)
        return;

    // The reference of the vector.
    Address pVector = Address_Null;

    switch (g_iOS)
    {
        case OS_Linux:
            pVector = regs.Load(DHookRegister_ESP, 4, NumberType_Int32);

        case OS_Windows:
            pVector = regs.Load(DHookRegister_EDI, 0, NumberType_Int32);
    }

    if (pVector == Address_Null)
        return;

    // m_velocity, but we load it from the stack.
    float vecVelocity[3];
    vecVelocity[0] = LoadFromAddress(pVector, NumberType_Int32);
    vecVelocity[1] = LoadFromAddress(pVector + view_as<Address>(4), NumberType_Int32);
    vecVelocity[2] = LoadFromAddress(pVector + view_as<Address>(8), NumberType_Int32);

    if (g_hCvar_ScaleDirection.BoolValue)
    {
        float vecMove[3];

        // m_moveVector is always a 2D normal vector, indicates the direction in (X,Y) plain.
        view_as<NextBotGroundLocomotion>(pLocomotion).GetMoveVector(vecMove);

        // not in the same direction, rotate velocity.
        if (!AreVectorsInSameDirection2D(vecVelocity, vecMove))
        {
            // here we only rotate velocity's (X,Y) plain, equivalent to rotate velocity about z axis.
            // so we use 2x2 matrix.
            float flAngle = AngleBetweenVectors(vecVelocity, vecMove);
            RotateVector2D(vecVelocity, flAngle);
        }
    }

    float flLength = GetVectorLength(vecVelocity);
    float flScale = g_hCvar_Scale.FloatValue;

    // should never be 0.0 or 1.0.
    flScale = clamp(flScale, 0.01, 0.99);

    // scale the speed below 35.0.
    while (flLength >= pLocomotion.GetSpeedLimit())
    {
        ScaleVector(vecVelocity, flScale);
        flLength = GetVectorLength(vecVelocity);
    }

    StoreToAddress(pVector, vecVelocity[0], NumberType_Int32);
    StoreToAddress(pVector + view_as<Address>(4), vecVelocity[1], NumberType_Int32);
    StoreToAddress(pVector + view_as<Address>(8), vecVelocity[2], NumberType_Int32);
}

void OnEnableChanged(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
    if (hConVar.BoolValue && !g_hMidHook.Enabled)
    {
        g_hMidHook.Enable();
    }
    else if (!hConVar.BoolValue && g_hMidHook.Enabled)
    {
        g_hMidHook.Disable();
    }
}

stock float AngleBetweenVectors(const float vector1[3], const float vector2[3], const float direction[3] = {0.0, 0.0, 0.0}, bool bRadOrDeg = true)
{
	float vector1_n[3], vector2_n[3];
    
    // set z 0.0.
    vector1_n = vector1; vector2_n = vector2;
    vector1_n[2] = vector2_n[2] = 0.0;

    // normalize in place first.
    NormalizeVector( vector1_n, vector1_n );
    NormalizeVector( vector2_n, vector2_n );
    float radiant = ArcCosine( clamp(GetVectorDotProduct( vector1_n, vector2_n ), -1.0, 1.0) );

    if (bRadOrDeg)
        return radiant;
    
    float direction_n[3];
    NormalizeVector( direction, direction_n );
	
    float cross[3];
	GetVectorCrossProduct( vector1_n, vector2_n, cross );
    
    float degree = radiant * (180 / FLOAT_PI);   // 180/Pi
	if( GetVectorDotProduct( cross, direction_n ) < 0.0 )
		degree *= -1.0;

	return degree;
}

stock bool AreVectorsInSameDirection2D(const float vec1[3], const float vec2[3], float epsilon = 0.001)
{
    float vector1_n[3], vector2_n[3];

    // set z 0.0.
    vector1_n = vec1; vector2_n = vec2;
    vector1_n[2] = vector2_n[2] = 0.0;

    // normalize a plain vector.
    NormalizeVector(vector1_n, vector1_n);
    NormalizeVector(vector2_n, vector2_n);

    return (FloatAbs( FloatAbs( clamp(GetVectorDotProduct( vector1_n, vector2_n ), -1.0, 1.0) ) - 1.0) < epsilon);
}

stock void RotateVector2D(float vecInput[3], float angle /* in radiant */)
{
    /**
     *             | X | | cosθ  -sinθ | 
​     *   OP·R(θ)=  | Y | | sinθ  cosθ  | 
     */
    vecInput[0] = vecInput[0] * Cosine(angle) - vecInput[1] * Sine(angle);
    vecInput[1] = vecInput[0] * Sine(angle) + vecInput[1] * Cosine(angle);
}

stock float clamp(float inc, float low, float high)
{
	return (inc > high) ? high : ((inc < low) ? low : inc);
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
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();

    cv.AddChangeHook(callback);
	return cv;
}
