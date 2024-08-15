#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <left4dhooks>
#include <l4d2_scav_stocks>

#define DEBUG		  1
#define PL_VERSION	  "1.0"
#define GAMEDATA_FILE "l4d2_scav_dhooks_natives"

Handle
	g_hSDKCall_ResetRoundNumber,
	g_hSDKCall_AccumulateTime,
	g_hSDKCall_RestartRound,
	g_hSDKCall_EndScavengeRound;

GlobalForward
	g_hForward_OnStartIntro,
	g_hForward_OnBeginRoundSetupTime,
	g_hForward_OnStartOvertime,
	g_hForward_OnEndOvertime,
	g_hForward_OnUpdateOvertimeState,
	g_hForward_OnUpdateOvertimeState_Post,
	g_hForward_OnUpdateOvertimeState_PostHandled,
	g_hForward_OnScavengeUpdateScenarioState,
	g_hForward_OnScavengeUpdateScenarioState_Post,
	g_hForward_OnScavengeUpdateScenarioState_PostHandled,
	g_hForward_OnRoundTimeExpired,
	g_hForward_OnRoundTimeExpired_Post,
	g_hForward_OnRoundTimeExpired_PostHandled;

ArrayList g_hArrayDetours;
bool	  g_bStartedIntro = false;

methodmap SDKCall_Wrapper {
    public void PrepCall(SDKCallType type) {
		StartPrepSDKCall(type);
	}
    public void SetFromConf(Handle gameconf, SDKFuncConfSource source, const char[] name) {
		if (!PrepSDKCall_SetFromConf(gameconf, source, name))
			LogError("Failed to set SDK call from conf for '%s'", name);
	}
    public void AddParam(SDKType type, SDKPassMethod pass, int decflags = 0, int encflags = 0) {
		PrepSDKCall_AddParameter(type, pass, decflags, encflags);
	}
    public void SetReturn(SDKType type, SDKPassMethod pass, int decflags = 0, int encflags = 0) {
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
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("l4d2_scav_dhooks_natives");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_scav_dhooks_natives_version", PL_VERSION, "L4D2 Scavenge Direct Hooks Natives version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);

	PrepareSDKCalls();
	SetupDetours();
	SetupForwardsNatives();
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
		LogError("Failed to load gamedata file \"" ... GAMEDATA_FILE... "\"");

	g_hSDKCall_ResetRoundNumber							   = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::ResetRoundNumber", false, _, _, false, _, _);
	g_hSDKCall_AccumulateTime							   = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::AccumulateTime", true, SDKType_Float, SDKPass_Plain, false, _, _);
	g_hSDKCall_RestartRound						   		   = CreateSDKCall(SDKCall_GameRules, gd, SDKConf_Signature, "CTerrorGameRules::RestartRound", false,  _, _, false, _, _);
	g_hSDKCall_EndScavengeRound							   = CreateSDKCall(SDKCall_Raw,       gd, SDKConf_Signature, "CDirectorScavengeMode::EndScavengeRound", false, _, _, false, _, _);

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

stock Handle CreateSDKCallEx(SDKCallType type, GameData gd, SDKFuncConfSource source, const char[] name,
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
	GameData gd		= new GameData(GAMEDATA_FILE);
	g_hArrayDetours = new ArrayList();

	if (!gd)
		LogError("Failed to load gamedata file \"" ... GAMEDATA_FILE... "\"");

	CreateDetour(gd, "CDirectorScavengeMode::OnStartIntro", Hook_Post, _, DTR_CDirectorScavengeMode_OnStartIntro);
	CreateDetour(gd, "CDirectorScavengeMode::OnBeginRoundSetupTime", Hook_Post, _, DTR_CDirectorScavengeMode_OnBeginRoundSetupTime);
	CreateDetour(gd, "CDirectorScavengeMode::OnEndOvertime", Hook_Post, _, DTR_CDirectorScavengeMode_OnEndOvertime);
	CreateDetour(gd, "CDirectorScavengeMode::OnStartOvertime", Hook_Post, _, DTR_CDirectorScavengeMode_OnStartOvertime);
	CreateDetour(gd, "CDirectorScavengeMode::UpdateOvertimeState", Hook_Pre, DTR_CDirectorScavengeMode_OnUpdateOvertimeState);
	CreateDetour(gd, "CDirectorScavengeMode::UpdateOvertimeState", Hook_Post, _, DTR_CDirectorScavengeMode_OnUpdateOvertimeState_Post, true);
	CreateDetour(gd, "CDirectorScavengeMode::ScavengeUpdateScenarioState", Hook_Pre, DTR_CDirectorScavengeMode_OnScavengeUpdateScenarioState);
	CreateDetour(gd, "CDirectorScavengeMode::ScavengeUpdateScenarioState", Hook_Post, _, DTR_CDirectorScavengeMode_OnScavengeUpdateScenarioState_Post, true);
	CreateDetour(gd, "CDirectorScavengeMode::OnRoundTimeExpired", Hook_Pre, DTR_CDirectorScavengeMode_OnRoundTimeExpired);
	CreateDetour(gd, "CDirectorScavengeMode::OnRoundTimeExpired", Hook_Post, _, DTR_CDirectorScavengeMode_OnRoundTimeExpired_Post, true);

	delete gd;
}

int	 g_iIndex = 0;
void CreateDetour(GameData gd, const char[] name, HookMode mode, DHookCallback cb = INVALID_FUNCTION, DHookCallback postcb = INVALID_FUNCTION, bool bUseLast = false)
{
	if (!bUseLast)
	{
		DynamicDetour hDetour = DynamicDetour.FromConf(gd, name);
		if (!hDetour)
			LogError("Failed to set up detour for '%s'", name);

		g_hArrayDetours.Push(hDetour);
	}

	if (cb != INVALID_FUNCTION && mode == Hook_Pre)
	{
		DynamicDetour hDetour = g_hArrayDetours.Get(g_iIndex);
		if (!hDetour.Enable(mode, cb))
			LogError("Failed to enable pre detour for '%s'", name);
	}

	if (postcb != INVALID_FUNCTION && mode == Hook_Post)
	{
		DynamicDetour hDetour = g_hArrayDetours.Get(bUseLast ? g_iIndex - 1 : g_iIndex);
		if (!hDetour.Enable(mode, postcb))
			LogError("Failed to enable post detour for '%s'", name);

		if (bUseLast)
			return;
	}

#if DEBUG
	PrintToServer("g_iIndex = %d", g_iIndex);
#endif
	g_iIndex++;
}

void SetupForwardsNatives()
{
	g_hForward_OnStartIntro								 = new GlobalForward("L4D2_OnStartScavengeIntro", ET_Event);
	g_hForward_OnBeginRoundSetupTime					 = new GlobalForward("L4D2_OnBeginScavengeRoundSetupTime", ET_Event, Param_Float);
	g_hForward_OnEndOvertime							 = new GlobalForward("L4D2_OnEndScavengeOvertime", ET_Event, Param_Cell);
	g_hForward_OnStartOvertime							 = new GlobalForward("L4D2_OnStartScavengeOvertime", ET_Event, Param_Array);
	g_hForward_OnUpdateOvertimeState					 = new GlobalForward("L4D2_OnUpdateScavengeOvertimeState", ET_Event);
	g_hForward_OnUpdateOvertimeState_Post				 = new GlobalForward("L4D2_OnUpdateScavengeOvertimeState_Post", ET_Event);
	g_hForward_OnUpdateOvertimeState_PostHandled		 = new GlobalForward("L4D2_OnUpdateScavengeOvertimeState_PostHandled", ET_Event);
	g_hForward_OnScavengeUpdateScenarioState			 = new GlobalForward("L4D2_OnScavengeUpdateScenarioState", ET_Event);
	g_hForward_OnScavengeUpdateScenarioState_Post		 = new GlobalForward("L4D2_OnScavengeUpdateScenarioState_Post", ET_Event);
	g_hForward_OnScavengeUpdateScenarioState_PostHandled = new GlobalForward("L4D2_OnScavengeUpdateScenarioState_PostHandled", ET_Event);
	g_hForward_OnRoundTimeExpired						 = new GlobalForward("L4D2_OnScavengeRoundTimeExpired", ET_Event);
	g_hForward_OnRoundTimeExpired_Post					 = new GlobalForward("L4D2_OnScavengeRoundTimeExpired_Post", ET_Event);
	g_hForward_OnRoundTimeExpired_PostHandled			 = new GlobalForward("L4D2_OnScavengeRoundTimeExpired_PostHandled", ET_Event);

	CreateNative("L4D2_ResetScavengeRoundNumber", Native_ResetScavengeRoundNumber);
	CreateNative("L4D2_AccumulateScavengeRoundTime", Native_AccumulateScavengeRoundTime);
	CreateNative("L4D2_RestartRound", Native_RestartRound);
	CreateNative("L4D2_EndScavengeRound", Native_EndScavengeRound);
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
		//Action aResult	= Plugin_Continue;
		//CountdownTimer timer = L4D2Direct_GetScavengeRoundSetupTimer();
		//float duration = (timer == CTimer_Null ? 0.0 : CTimer_GetCountdownDuration(timer));
		Call_StartForward(g_hForward_OnBeginRoundSetupTime);
		//Call_PushFloat(duration);
		Call_Finish();
/*
		if (aResult == Plugin_Handled)
		{
			hReturn.Value = true;
			g_bBlock_OnBeginRoundSetupTime = true;
			return MRES_Supercede;
		}
*/
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnEndOvertime(DHookParam hParam)
{
	bool bEndStatus = hParam.Get(1);
#if DEBUG
	PrintToServer("### DTR_CDirectorScavengeMode_OnEndOvertime, bEndStatus = %s", bEndStatus ? "true" : "false");
#endif

	Call_StartForward(g_hForward_OnEndOvertime);
	Call_PushCell(bEndStatus);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnStartOvertime()
{
#if DEBUG
	PrintToServer("### DTR_CDirectorScavengeMode_OnStartOvertime");
#endif
	int client[32];
	for (int i = 0; i < MaxClients; i++)
	{
		if (i == 0 || !IsClientInGame(i))
			continue;

		if (GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		int ent = INVALID_ENT_REFERENCE;
		while ((ent = FindEntityByClassname(ent, "weapon_gascan")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity") == i)
			{
				client[i] = i;
				break;
			}
		}
	}

	Call_StartForward(g_hForward_OnStartOvertime);
	Call_PushArray(client, sizeof(client));
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_OnUpdateOvertimeState = false;
MRESReturn DTR_CDirectorScavengeMode_OnUpdateOvertimeState(DHookReturn hReturn)
{
#if DEBUG
	// PrintToServer("### DTR_CDirectorScavengeMode_OnUpdateOvertimeState, hReturn.Value = %d", hReturn.Value);
#endif

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnUpdateOvertimeState);
	Call_Finish(aResult);

	if (aResult == Plugin_Handled)
	{
		hReturn.Value				   = false;
		g_bBlock_OnUpdateOvertimeState = true;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnUpdateOvertimeState_Post()
{
#if DEBUG
	// PrintToServer("### DTR_CDirectorScavengeMode_OnUpdateOvertimeState_Post");
#endif

	Call_StartForward(g_bBlock_OnUpdateOvertimeState ? g_hForward_OnUpdateOvertimeState_PostHandled : g_hForward_OnUpdateOvertimeState_Post);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_OnScavengeUpdateScenarioState = false;
MRESReturn DTR_CDirectorScavengeMode_OnScavengeUpdateScenarioState()
{
#if DEBUG
	// PrintToServer("### DTR_CDirectorScavengeMode_OnScavengeUpdateScenarioState");
#endif

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnScavengeUpdateScenarioState);
	Call_Finish(aResult);

	if (aResult == Plugin_Handled)
	{
		g_bBlock_OnScavengeUpdateScenarioState = true;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnScavengeUpdateScenarioState_Post()
{
#if DEBUG
	// PrintToServer("### DTR_CDirectorScavengeMode_OnScavengeUpdateScenarioState_Post");
#endif

	Call_StartForward(g_bBlock_OnScavengeUpdateScenarioState ? g_hForward_OnScavengeUpdateScenarioState_PostHandled : g_hForward_OnScavengeUpdateScenarioState_Post);
	Call_Finish();

	return MRES_Ignored;
}

bool	   g_bBlock_OnRoundTimeExpired = false;
MRESReturn DTR_CDirectorScavengeMode_OnRoundTimeExpired(DHookReturn hReturn)
{
#if DEBUG
	PrintToServer("### DTR_CDirectorScavengeMode_OnRoundTimeExpired");
#endif

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnRoundTimeExpired);
	Call_Finish(aResult);

	if (aResult == Plugin_Handled)
	{
		hReturn.Value = true;
		g_bBlock_OnRoundTimeExpired = true;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorScavengeMode_OnRoundTimeExpired_Post()
{
#if DEBUG
	PrintToServer("### DTR_CDirectorScavengeMode_OnRoundTimeExpired_Post");
#endif

	Call_StartForward(g_bBlock_OnRoundTimeExpired ? g_hForward_OnRoundTimeExpired_PostHandled : g_hForward_OnRoundTimeExpired_Post);
	Call_Finish();
	return MRES_Ignored;
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

int Native_RestartRound(Handle plugin, int numParams)
{
	if (L4D2_IsScavengeMode())
	{
		ScavStocksWrapper wrapper;

		// this native increase round number and item goal.
		int iCurRound = wrapper.m_nRoundNumber;
		int iCurSurScore = wrapper.GetTeamScore(2);
		int iCurInfScore = wrapper.GetTeamScore(3);
		int iCurSurMatch = wrapper.GetMatchScore(2);
		int iCurInfMatch = wrapper.GetMatchScore(3);
		int iCurMapGoal = wrapper.m_nScavengeItemsGoal;
		bool bHalf = wrapper.m_bInSecondHalfOfRound;

		// this native overspawns the gascan.
		int ent = INVALID_ENT_REFERENCE;
		while ((ent = FindEntityByClassname(ent, "weapon_gascan")) != INVALID_ENT_REFERENCE)
		{
			if (!IsValidEntity(ent))
				continue;

			AcceptEntityInput(ent, "Kill");
		}

		ValidateNatives(g_hSDKCall_RestartRound, "L4D2_RestartRound");
		SDKCall(g_hSDKCall_RestartRound);

		L4D_NotifyNetworkStateChanged();
		wrapper.m_nRoundNumber = iCurRound;
		L4D_NotifyNetworkStateChanged();
		wrapper.SetTeamScore(2, iCurRound, (bHalf ? iCurSurScore : 0));
		L4D_NotifyNetworkStateChanged();
		wrapper.SetTeamScore(3, iCurRound, iCurInfScore);
		L4D_NotifyNetworkStateChanged();
		wrapper.SetMatchScore(2, iCurSurMatch);
		L4D_NotifyNetworkStateChanged();
		wrapper.SetMatchScore(3, iCurInfMatch);
		L4D_NotifyNetworkStateChanged();
		wrapper.m_nScavengeItemsGoal = iCurMapGoal;

		return 0;
	}

	ValidateNatives(g_hSDKCall_RestartRound, "L4D2_RestartRound");
	SDKCall(g_hSDKCall_RestartRound);

	return 0;
}

int Native_EndScavengeRound(Handle plugin, int numParams)
{
	Address pDirector = L4D_GetPointer(POINTER_SCAVENGEMODE);
	ValidateNatives(g_hSDKCall_EndScavengeRound, "L4D2_EndScavengeRound");
	SDKCall(g_hSDKCall_EndScavengeRound, pDirector);
	return 0;
}

void ValidateNatives(Handle test, const char[] name)
{
	if (!test)
		ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available.", name);
}