#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <left4dhooks>

#define DEBUG 1
#define PL_VERSION "1.0"
#define GAMEDATA_FILE "l4d2_scav_dhooks_natives"

Handle g_hSDKCall_IncrementScavengeMatchScore, g_hSDKCall_UpdateOvertimeState, g_hSDKCall_ResetRoundNumber,
g_hSDKCall_AccumulateTime, g_hSDKCall_RestartScavengeRound,
g_hSDKCall_UpdateScavengeMobSpawns, g_hSDKCall_EndScavengeRound, g_hSDKCall_CDirector_IncrementScavengeTeamScore,
g_hSDKCall_CTerrorGameRules_IncrementScavengeTeamScore;

DynamicDetour g_hDetour_OnStartIntro, g_hDetour_AreBossesProhibited, g_hDetour_OnBeginRoundSetupTime, g_hDetour_OnEndOvertime;
GlobalForward g_hOnStartIntro, g_hAreBossesProhibited, g_hOnBeginRoundSetupTime, g_hOnEndOvertime;

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

public void OnPluginStart()
{
    CreateConVar("l4d2_scav_dhooks_version", PL_VERSION, "L4D2 Scavenge Direct Hooks version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);

    PrepareSDKCalls();
    SetupDetours();
    SetupForwards();
    SetupNatives();
}

void PrepareSDKCalls()
{
    GameData gd = new GameData(GAMEDATA_FILE);
    if (!gd)
        LogError("Failed to load gamedata file \""...GAMEDATA_FILE..."\"");

    g_hSDKCall_IncrementScavengeMatchScore                  = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::IncrementScavengeMatchScore"     , true, SDKType_PlainOldData, SDKPass_Plain, false, _, _);
    g_hSDKCall_UpdateOvertimeState                          = CreateSDKCall(SDKCall_Raw,       gd, SDKConf_Signature, "CDirectorScavengeMode::UpdateOvertimeState"        , false, _, _ , false, _, _);
    g_hSDKCall_ResetRoundNumber                             = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::ResetRoundNumber"                , false, _, _ , false, _, _);
    g_hSDKCall_AccumulateTime                               = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::AccumulateTime"                  , false, _, _ , false, _, _);
    g_hSDKCall_RestartScavengeRound                         = CreateSDKCall(SDKCall_Raw,       gd, SDKConf_Signature, "CDirectorScavengeMode::RestartScavengeRound"       , true, SDKType_PlainOldData, SDKPass_Plain, false, _, _);
    g_hSDKCall_UpdateScavengeMobSpawns                      = CreateSDKCall(SDKCall_Static,    gd, SDKConf_Signature, "CDirectorScavengeMode::UpdateScavengeMobSpawns"    , false, _, _ , true, SDKType_Bool, SDKPass_Plain);
    g_hSDKCall_EndScavengeRound                             = CreateSDKCall(SDKCall_Raw,       gd, SDKConf_Signature, "CDirectorScavengeMode::EndScavengeRound"           , false, _, _ , false, _, _);

    SDKType[] paramType = new SDKType[2]; SDKPassMethod[] paramPass = new SDKPassMethod[2];
    paramType[0] = SDKType_PlainOldData; paramType[1] = SDKType_CBaseEntity;
    paramPass[0] = SDKPass_Plain;        paramPass[1] = SDKPass_Pointer;
    g_hSDKCall_CDirector_IncrementScavengeTeamScore         = CreateSDKCallEx(SDKCall_Raw,     gd, SDKConf_Signature, "CDirector::IncrementScavengeTeamScore"             , true, 2, paramType, paramPass, false, _, _);

    g_hSDKCall_CTerrorGameRules_IncrementScavengeTeamScore  = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::IncrementScavengeTeamScore"      , true, SDKType_PlainOldData, SDKPass_Plain, false, _, _);

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
            SetUp.AddParam(paramType[i - 1], paramPass[i - 1]);
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

    CreateDetour(g_hDetour_OnStartIntro, gd, "CDirectorScavengeMode::OnStartIntro", Hook_Post, DTR_CDirectorScavengeMode_OnStartIntro);
    CreateDetour(g_hDetour_AreBossesProhibited, gd, "CDirector::AreBossesProhibited", Hook_Post, DTR_CDirector_AreBossesProhibited);
    CreateDetour(g_hDetour_OnBeginRoundSetupTime, gd, "CDirectorScavengeMode::OnBeginRoundSetupTime", Hook_Post, DTR_CDirectorScavengeMode_OnBeginRoundSetupTime);
    CreateDetour(g_hDetour_OnEndOvertime, gd, "CDirectorScavengeMode::OnEndOvertime", Hook_Post, DTR_CDirectorScavengeMode_OnEndOvertime);

    delete gd;
}

void CreateDetour(DynamicDetour hDetour, GameData gd, const char[] name, HookMode mode, DHookCallback callback = INVALID_FUNCTION)
{
    hDetour = DynamicDetour.FromConf(gd, name);
    if (!hDetour)
        LogError("Failed to set up detour for '%s'", name);
    if (!hDetour.Enable(mode, callback))
        LogError("Failed to enable detour for '%s'", name);
}

void SetupForwards()
{
    g_hOnStartIntro = new GlobalForward("L4D2_OnStartScavengeIntro", ET_Ignore);
    g_hAreBossesProhibited = new GlobalForward("L4D2_AreBossesProhibited", ET_Hook, Param_Cell);
    g_hOnBeginRoundSetupTime = new GlobalForward("L4D2_OnBeginScavengeRoundSetupTime", ET_Ignore);
    g_hOnEndOvertime = new GlobalForward("L4D2_OnEndScavengeOvertime", ET_Ignore);
}

void SetupNatives()
{
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

MRESReturn DTR_CDirectorScavengeMode_OnStartIntro()
{
#if DEBUG
    PrintToServer("### DTR_CDirectorScavengeMode_OnStartIntro");
#endif
    Call_StartForward(g_hOnStartIntro);
    Call_Finish();

    return MRES_Ignored;
}

MRESReturn DTR_CDirector_AreBossesProhibited(DHookReturn hReturn, DHookParam hParams)
{

#if DEBUG
    // PrintToServer("### DTR_CDirector_AreBossesProhibited");
#endif

    bool prohibitbosses = hParams.Get(1);

    Action aResult = Plugin_Continue;
    Call_StartForward(g_hAreBossesProhibited);
    Call_PushCell(prohibitbosses);
    Call_Finish(aResult);

    if (aResult == Plugin_Changed)
    {
        hReturn.Value = true;
        hParams.Set(1, false);
        return MRES_ChangedOverride;    
    }

    return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnBeginRoundSetupTime()
{
#if DEBUG
    PrintToServer("### DTR_CDirectorScavengeMode_OnBeginRoundSetupTime");
#endif

    Call_StartForward(g_hOnBeginRoundSetupTime);
    Call_Finish();

    return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnEndOvertime()
{
#if DEBUG
    PrintToServer("### DTR_CDirectorScavengeMode_OnEndOvertime");
#endif

    Call_StartForward(g_hOnEndOvertime);
    Call_Finish();

    return MRES_Ignored;
}

void ValidateNatives(Handle test, const char[] name)
{
	if( test == null )
	{
		ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available.", name);
	}
}

int Native_IncrementScavengeMatchScore(Handle plugin, int numParams)
{
    int team = GetNativeCell(1);
    if (team != 1 || team != 2)
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
    int team = GetNativeCell(1);
    if (team != 2 || team != 3)
        ThrowNativeError(SP_ERROR_PARAM, "Invalid team number: %d", team);
    
    int client = GetNativeCell(2);
    if (!IsClientInGame(client))
        ThrowNativeError(SP_ERROR_PARAM, "Invalid client Index: %d", client);

    Address pDirector = L4D_GetPointer(POINTER_SCAVENGEMODE);

    ValidateNatives(g_hSDKCall_CDirector_IncrementScavengeTeamScore, "L4D2_CDirector_IncrementScavengeTeamScore");
    SDKCall(g_hSDKCall_CDirector_IncrementScavengeTeamScore, pDirector, team, client);
    return 0;
}

int Native_CTerrorGameRules_IncrementScavengeTeamScore(Handle plugin, int numParams)
{
    int team = GetNativeCell(1);
    if (team != 2 || team != 3)
        ThrowNativeError(SP_ERROR_PARAM, "Invalid team number: %d", team);

    ValidateNatives(g_hSDKCall_CTerrorGameRules_IncrementScavengeTeamScore, "L4D2_CTerrorGameRules_IncrementScavengeTeamScore");
    SDKCall(g_hSDKCall_CTerrorGameRules_IncrementScavengeTeamScore, team);
    return 0;
}