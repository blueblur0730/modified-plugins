#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <left4dhooks>

#define DEBUG 1
#define PL_VERSION "1.1"
#define GAMEDATA_FILE "l4d2_scav_dhooks_natives"

Handle 
    g_hSDKCall_IncrementScavengeMatchScore, 
    g_hSDKCall_UpdateOvertimeState, 
    g_hSDKCall_ResetRoundNumber,
    g_hSDKCall_AccumulateTime, 
    g_hSDKCall_RestartScavengeRound,
    g_hSDKCall_UpdateScavengeMobSpawns, 
    g_hSDKCall_EndScavengeRound, 
    g_hSDKCall_CDirector_IncrementScavengeTeamScore,
    g_hSDKCall_CTerrorGameRules_IncrementScavengeTeamScore;

DynamicDetour 
    g_hDetour_OnStartIntro, 
    g_hDetour_OnBeginRoundSetupTime,
    g_hDetour_OnStartOvertime,
    g_hDetour_OnEndOvertime, 
    g_hDetour_OnUpdateOvertimeState, 
    g_hDetour_OnScavengeUpdateScenarioState,
    g_hDetour_OnRoundTimeExpired;

GlobalForward 
    g_hForward_OnStartIntro, 
    g_hForward_OnBeginRoundSetupTime,
    g_hForward_OnBeginRoundSetupTime_Post,
    g_hForward_OnBeginRoundSetupTime_PostHandled,
    g_hForward_OnEndOvertime, 
    g_hForward_OnUpdateOvertimeState, 
    g_hForward_OnScavengeUpdateScenarioState,
    g_hForward_OnStartOvertime,
    g_hForward_OnRoundTimeExpired;

bool g_bStartedIntro = false;

methodmap SDKCall_Wrapper
{
    public void PrepCall(SDKCallType type) {
        StartPrepSDKCall(type);
    }
    public void SetFromConf(Handle gameconf, SDKFuncConfSource source, const char[] name) {
        if (!PrepSDKCall_SetFromConf(gameconf, source, name))
            LogError("Failed to set SDK call from conf for '%s'", name);
    }
    public void AddParam(SDKType type, SDKPassMethod pass, int decflags=0, int encflags=0) {
        PrepSDKCall_AddParameter(type, pass, decflags, encflags);
    }
    public void SetReturn(SDKType type, SDKPassMethod pass, int decflags=0, int encflags=0) {
        PrepSDKCall_SetReturnInfo(type, pass, decflags, encflags);
    }
    public Handle EndPrep(const char[] name) {
        Handle h = EndPrepSDKCall();
        if (!h)
            LogError("Failed to end SDK call prep for '%s'", name);
        return h;
    }
}

public Plugin myinfo =
{
	name = "[L4D2] Scavenge Direct Hooks Natives",
	author = "blueblur",
	description = "Provides hooks and natives for functions in L4D2 Scavenge.",
	version	= PL_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("l4d2_scav_dhooks_natives_version", PL_VERSION, "L4D2 Scavenge Direct Hooks Natives version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);

    PrepareSDKCalls();
    SetupDetours();
    SetupForwardsNatives();

    RegPluginLibrary("l4d2_scav_dhooks_natives");
}

public void OnMapStart()
{
    // reset on every map start.
    g_bStartedIntro = false;
}

void PrepareSDKCalls()
{
    GameData gd = new GameData(GAMEDATA_FILE);
    if (!gd)
        LogError("Failed to load gamedata file \""...GAMEDATA_FILE..."\"");

    g_hSDKCall_IncrementScavengeMatchScore                  = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::IncrementScavengeMatchScore"     , true, SDKType_PlainOldData, SDKPass_Plain, false, _, _);
    g_hSDKCall_UpdateOvertimeState                          = CreateSDKCall(SDKCall_Raw,       gd, SDKConf_Signature, "CDirectorScavengeMode::UpdateOvertimeState"        , false, _, _ , false, _, _);
    g_hSDKCall_ResetRoundNumber                             = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::ResetRoundNumber"                , false, _, _ , false, _, _);
    g_hSDKCall_AccumulateTime                               = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::AccumulateTime"                  , true, SDKType_Float, SDKPass_Plain, false, _, _);
    g_hSDKCall_RestartScavengeRound                         = CreateSDKCall(SDKCall_Raw,       gd, SDKConf_Signature, "CDirectorScavengeMode::RestartScavengeRound"       , true, SDKType_PlainOldData, SDKPass_Plain, false, _, _);
    g_hSDKCall_UpdateScavengeMobSpawns                      = CreateSDKCall(SDKCall_Static,    gd, SDKConf_Signature, "CDirectorScavengeMode::UpdateScavengeMobSpawns"    , false, _, _ , true, SDKType_Bool, SDKPass_Plain);
    g_hSDKCall_EndScavengeRound                             = CreateSDKCall(SDKCall_Raw,       gd, SDKConf_Signature, "CDirectorScavengeMode::EndScavengeRound"           , false, _, _ , false, _, _);
    g_hSDKCall_CTerrorGameRules_IncrementScavengeTeamScore  = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::IncrementScavengeTeamScore"      , true, SDKType_PlainOldData, SDKPass_Plain, false, _, _);

    SDKType[] paramType = new SDKType[2]; SDKPassMethod[] paramPass = new SDKPassMethod[2];
    paramType[0] = SDKType_PlainOldData; paramType[1] = SDKType_CBaseEntity;
    paramPass[0] = SDKPass_Plain;        paramPass[1] = SDKPass_Pointer;
    g_hSDKCall_CDirector_IncrementScavengeTeamScore         = CreateSDKCallEx(SDKCall_Raw,     gd, SDKConf_Signature, "CDirector::IncrementScavengeTeamScore"             , true, 2, paramType, paramPass, false, _, _);

    delete gd;
}

Handle CreateSDKCall(SDKCallType type, GameData gd, SDKFuncConfSource source, const char[] name, 
                    bool bHasParam, SDKType paramType = SDKType_CBaseEntity, SDKPassMethod paramPass = SDKPass_Plain,
                    bool bHasReturn, SDKType returnType = SDKType_CBaseEntity, SDKPassMethod returnPass = SDKPass_Plain)
{
    SDKCall_Wrapper SetUp;
    SetUp.PrepCall(type);
    SetUp.SetFromConf(gd, source, name);
    if (bHasParam)
        SetUp.AddParam(paramType, paramPass);
    if (bHasReturn)
        SetUp.SetReturn(returnType, returnPass);
    return SetUp.EndPrep(name);
}

Handle CreateSDKCallEx(SDKCallType type, GameData gd, SDKFuncConfSource source, const char[] name, 
                    bool bHasParam, int ParamNum, SDKType[] paramType, SDKPassMethod[] paramPass,
                    bool bHasReturn, SDKType returnType = SDKType_CBaseEntity, SDKPassMethod returnPass = SDKPass_Plain)
{
    SDKCall_Wrapper SetUp;
    SetUp.PrepCall(type);
    SetUp.SetFromConf(gd, source, name);
    if (bHasParam)
    {
        for (int i = 0; i < ParamNum; i++)
        {
            SetUp.AddParam(paramType[i], paramPass[i]);
        }
    }
    if (bHasReturn)
        SetUp.SetReturn(returnType, returnPass);
    return SetUp.EndPrep(name);
}

void SetupDetours()
{
    GameData gd = new GameData(GAMEDATA_FILE);
    if (!gd)
        LogError("Failed to load gamedata file \""...GAMEDATA_FILE..."\"");

    CreateDetour(g_hDetour_OnStartIntro,                    gd, "CDirectorScavengeMode::OnStartIntro",                  Hook_Pre, DTR_CDirectorScavengeMode_OnStartIntro);
    CreateDetour(g_hDetour_OnBeginRoundSetupTime,           gd, "CDirectorScavengeMode::OnBeginRoundSetupTime",         Hook_Pre, DTR_CDirectorScavengeMode_OnBeginRoundSetupTime);
    CreateDetour(g_hDetour_OnBeginRoundSetupTime,           gd, "CDirectorScavengeMode::OnBeginRoundSetupTime",         Hook_Post, _, DTR_CDirectorScavengeMode_OnBeginRoundSetupTime_Post, true);
    CreateDetour(g_hDetour_OnEndOvertime,                   gd, "CDirectorScavengeMode::OnEndOvertime",                 Hook_Post, DTR_CDirectorScavengeMode_OnEndOvertime);
    CreateDetour(g_hDetour_OnStartOvertime,                 gd, "CDirectorScavengeMode::OnStartOvertime",               Hook_Post, DTR_CDirectorScavengeMode_OnStartOvertime);
    CreateDetour(g_hDetour_OnUpdateOvertimeState,           gd, "CDirectorScavengeMode::OnUpdateOvertimeState",         Hook_Post, DTR_CDirectorScavengeMode_OnUpdateOvertimeState);
    CreateDetour(g_hDetour_OnScavengeUpdateScenarioState,   gd, "CDirectorScavengeMode::ScavengeUpdateScenarioState",   Hook_Post, DTR_CDirectorScavengeMode_OnScavengeUpdateScenarioState);
    CreateDetour(g_hDetour_OnRoundTimeExpired,              gd, "CTerrorGameRules::RoundTimeExpired",                   Hook_Post, DTR_CTerrorGameRules_RoundTimeExpired);

    delete gd;
}

void CreateDetour(DynamicDetour hDetour, GameData gd, const char[] name, HookMode mode, DHookCallback cb = INVALID_FUNCTION, DHookCallback postcb = INVALID_FUNCTION, bool bUseLast = false)
{
    if (!bUseLast)
    {
        hDetour = DynamicDetour.FromConf(gd, name);
        if (!hDetour)
        {
            LogError("Failed to set up detour for '%s'", name);
            return;
        }
    }

    if (cb != INVALID_FUNCTION)
    {
        if (!hDetour.Enable(mode, cb))
            LogError("Failed to enable pre detour for '%s'", name);
    }

    if (postcb != INVALID_FUNCTION)
    {
        if (!hDetour.Enable(mode, postcb))
        LogError("Failed to enable post detour for '%s'", name);
    }
}  

void SetupForwardsNatives()
{
    g_hForward_OnStartIntro = new GlobalForward("L4D2_OnStartScavengeIntro", ET_Event);
    g_hForward_OnBeginRoundSetupTime = new GlobalForward("L4D2_OnBeginScavengeRoundSetupTime", ET_Event, Param_FloatByRef);
    g_hForward_OnBeginRoundSetupTime_Post = new GlobalForward("L4D2_OnEndScavengeRoundSetupTime_Post", ET_Event, Param_Float);
    g_hForward_OnBeginRoundSetupTime_PostHandled = new GlobalForward("L4D2_OnEndScavengeRoundSetupTime_PostHandled", ET_Event, Param_Float);
    g_hForward_OnEndOvertime = new GlobalForward("L4D2_OnEndScavengeOvertime", ET_Event);
    g_hForward_OnUpdateOvertimeState = new GlobalForward("L4D2_OnUpdateScavengeOvertimeState", ET_Event);
    g_hForward_OnScavengeUpdateScenarioState = new GlobalForward("L4D2_OnScavengeUpdateScenarioState", ET_Event, Param_Cell);

    CreateNative("L4D2_IncrementScavengeMatchScore", Native_IncrementScavengeMatchScore);
    CreateNative("L4D2_UpdateScavengeOvertimeState", Native_UpdateScavengeOvertimeState);
    CreateNative("L4D2_ResetScavengeRoundNumber", Native_ResetScavengeRoundNumber);
    CreateNative("L4D2_AccumulateScavengeRoundTime", Native_AccumulateScavengeRoundTime);
    CreateNative("L4D2_RestartScavengeRound", Native_RestartScavengeRound);
    CreateNative("L4D2_UpdateScavengeMobSpawns", Native_UpdateScavengeMobSpawns);
    CreateNative("L4D2_EndScavengeRound", Native_EndScavengeRound);
    CreateNative("L4D2_CDirector_IncrementScavengeTeamScore", Native_CDirector_IncrementScavengeTeamScore);
    CreateNative("L4D2_CTerrorGameRules_IncrementScavengeTeamScore", Native_CTerrorGameRules_IncrementScavengeTeamScore);
}

MRESReturn DTR_CDirectorScavengeMode_OnStartIntro(DHookReturn hReturn)
{
#if DEBUG
    PrintToServer("### DTR_CDirectorScavengeMode_OnStartIntro");
#endif

    // if the gamemode is scavenge mode.
    if (hReturn.Value)
    {
        Call_StartForward(g_hForward_OnStartIntro);
        Call_Finish();
        g_bStartedIntro = true;
    }

    return MRES_Ignored;
}

bool g_bBlock_OnBeginRoundSetupTime = false;
MRESReturn DTR_CDirectorScavengeMode_OnBeginRoundSetupTime(DHookReturn hReturn)
{
#if DEBUG
    PrintToServer("### DTR_CDirectorScavengeMode_OnBeginRoundSetupTime");
#endif

    // this function called at the same time with CDirectorScavengeMode::OnStartIntro (even a little bit faster) when the first round start.
    // so we let it calls later as the real call.
    // might be CDirector::OnTeamsReady calling it.
    if (g_bStartedIntro)
    {
        Action aResult = Plugin_Continue;
        CountdownTimer timer = L4D2Direct_GetScavengeRoundSetupTimer();
        float duration = (timer == CTimer_Null ? 0.0 : CTimer_GetCountdownDuration(timer));
        Call_StartForward(g_hForward_OnBeginRoundSetupTime);
        Call_PushFloatRef(duration);
        Call_Finish(aResult);

        if (aResult == Plugin_Handled)
        {
            hReturn.Value = false;
            g_bBlock_OnBeginRoundSetupTime = true;
            return MRES_Override;
        }

        if (aResult == Plugin_Changed)
        {
            if (CTimer_HasStarted(timer))
            {
                CTimer_Invalidate(timer);
                CTimer_Start(timer, duration);
                return MRES_Handled;
            }
        }
    }

    return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnBeginRoundSetupTime_Post()
{
    if (g_bStartedIntro)
    {
        CountdownTimer timer = L4D2Direct_GetScavengeRoundSetupTimer();
        Call_StartForward(g_bBlock_OnBeginRoundSetupTime ? g_hForward_OnBeginRoundSetupTime_PostHandled : g_hForward_OnBeginRoundSetupTime_Post);
        Call_PushFloat(timer == CTimer_Null ? 0.0 : CTimer_GetCountdownDuration(timer));
        Call_Finish();  
    }
}

MRESReturn DTR_CDirectorScavengeMode_OnEndOvertime()
{
#if DEBUG
    PrintToServer("### DTR_CDirectorScavengeMode_OnEndOvertime");
#endif

    Call_StartForward(g_hForward_OnEndOvertime);
    Call_Finish();

    return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnStartOvertime()
{

}

MRESReturn DTR_CDirectorScavengeMode_OnUpdateOvertimeState()
{

}

MRESReturn DTR_CDirectorScavengeMode_OnScavengeUpdateScenarioState()
{

}

MRESReturn DTR_CTerrorGameRules_RoundTimeExpired()
{

}

void ValidateNatives(Handle test, const char[] name)
{
	if(!test)
		ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available.", name);
}

int Native_IncrementScavengeMatchScore(Handle plugin, int numParams)
{
    int team = GetNativeCell(1);
    if (team != 1 && team != 2)
        ThrowNativeError(SP_ERROR_PARAM, "Invalid team number: %d", team);

    ValidateNatives(g_hSDKCall_IncrementScavengeMatchScore, "L4D2_IncrementScavengeMatchScore");
    SDKCall(g_hSDKCall_IncrementScavengeMatchScore, team);
    return 0;
}

int Native_UpdateScavengeOvertimeState(Handle plugin, int numParams)
{
    Address pDirector = L4D_GetPointer(POINTER_SCAVENGEMODE);
    ValidateNatives(g_hSDKCall_UpdateOvertimeState, "L4D2_UpdateScavengeOvertimeState");
    SDKCall(g_hSDKCall_UpdateOvertimeState, pDirector);
    return 0;
}

int Native_ResetScavengeRoundNumber(Handle plugin, int numParams)
{
    ValidateNatives(g_hSDKCall_ResetRoundNumber, "L4D2_ResetScavengeRoundNumber");
    SDKCall(g_hSDKCall_ResetRoundNumber);
    return 0;
}

int Native_AccumulateScavengeRoundTime(Handle plugin, int numParams)
{
    float time = GetNativeCell(1);
    ValidateNatives(g_hSDKCall_AccumulateTime, "L4D2_AccumulateScavengeRoundTime");
    SDKCall(g_hSDKCall_AccumulateTime, time);
    return 0;
}

int Native_RestartScavengeRound(Handle plugin, int numParams)
{
    Address pDirector = L4D_GetPointer(POINTER_SCAVENGEMODE);
    ValidateNatives(g_hSDKCall_RestartScavengeRound, "L4D2_RestartScavengeRound");
    SDKCall(g_hSDKCall_RestartScavengeRound, pDirector);
    return 0;
}

any Native_UpdateScavengeMobSpawns(Handle plugin, int numParams)
{
    ValidateNatives(g_hSDKCall_UpdateScavengeMobSpawns, "L4D2_UpdateScavengeMobSpawns");
    bool result = SDKCall(g_hSDKCall_UpdateScavengeMobSpawns);
    return result;
}

int Native_EndScavengeRound(Handle plugin, int numParams)
{
    Address pDirector = L4D_GetPointer(POINTER_SCAVENGEMODE);
    ValidateNatives(g_hSDKCall_EndScavengeRound, "L4D2_EndScavengeRound");
    SDKCall(g_hSDKCall_EndScavengeRound, pDirector);
    return 0;
}

int Native_CDirector_IncrementScavengeTeamScore(Handle plugin, int numParams)
{
    Address pDirector = L4D_GetPointer(POINTER_SCAVENGEMODE);

    ValidateNatives(g_hSDKCall_CDirector_IncrementScavengeTeamScore, "L4D2_CDirector_IncrementScavengeTeamScore");
    SDKCall(g_hSDKCall_CDirector_IncrementScavengeTeamScore, pDirector, 2, 0);   // it needs an entity index to be passed, the game chooses 0 (world) as the trigger.
    return 0;

    //CDirectorScavengeMode *__cdecl scavenge_increment_score()
    //{
    //    return CDirector::IncrementScavengeTeamScore((CDirectorScavengeMode **)TheDirector, 2, 0);
    //}
}

int Native_CTerrorGameRules_IncrementScavengeTeamScore(Handle plugin, int numParams)
{
    int team = GetNativeCell(1);
    if (team != 2 && team != 3)
        ThrowNativeError(SP_ERROR_PARAM, "Invalid team number: %d", team);

    ValidateNatives(g_hSDKCall_CTerrorGameRules_IncrementScavengeTeamScore, "L4D2_CTerrorGameRules_IncrementScavengeTeamScore");
    SDKCall(g_hSDKCall_CTerrorGameRules_IncrementScavengeTeamScore, team);
    return 0;
}