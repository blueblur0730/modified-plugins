#include <gamedata_wrapper>

void Init()
{
	GameDataWrapper hGameData = new GameDataWrapper("l4d2_si_spawn_control");

    g_iSpawnAttributesOffset = hGameData.GetOffset("TerrorNavArea::SpawnAttributes");
    g_iFlowDistanceOffset = hGameData.GetOffset("TerrorNavArea::FlowDistance");
    g_iNavCountOffset = hGameData.GetOffset("TheNavAreas::Count");

    g_pTheNavAreas = TheNavAreas(hGameData.GetAddress("TheNavAreas"));
    g_pPanicEventStage = hGameData.GetAddress("CDirectorScriptedEventManager::m_PanicEventStage");

    // Vector CNavArea::GetRandomPoint( void ) const
    SDKCallParamsWrapper ret = { SDKType_Vector, SDKPass_ByValue };
    g_hSDKFindRandomSpot = hGameData.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, "TerrorNavArea::FindRandomSpot", _, _, true, ret);


	// IsVisibleToPlayer(Vector const&, CBasePlayer *, int, int, float, CBaseEntity const*, TerrorNavArea **, bool *);
	// SDKCall(g_hSDKIsVisibleToPlayer, fTargetPos, i, 2, 3, 0.0, 0, pArea, true);
    SDKCallParamsWrapper params[] = { 
                                    { SDKType_Vector, SDKPass_ByRef },          // target position
                                    { SDKType_CBasePlayer, SDKPass_Pointer },   // client
                                    { SDKType_PlainOldData, SDKPass_Plain },    // client team
                                    { SDKType_PlainOldData, SDKPass_Plain },    // target position team, related to the client's angle.
                                    { SDKType_Float, SDKPass_Plain },           // unknown
                                    { SDKType_PlainOldData, SDKPass_Plain },    // unknown
                                    { SDKType_PlainOldData, SDKPass_Plain },    // target position NavArea
                                    { SDKType_Bool, SDKPass_Pointer }           // if false, will auto get the NavArea of the target position (GetNearestNavArea)
                                                                            };
    SDKCallParamsWrapper ret1 = { SDKType_Bool, SDKPass_Plain };
    g_hSDKIsVisibleToPlayer = hGameData.CreateSDKCallOrFail(SDKCall_Static, SDKConf_Signature, "IsVisibleToPlayer", params, sizeof(params), true, ret1);

	// Unlock Max SI limit.
    g_hPatch = hGameData.CreateMemoryPatchOrFail("CDirector::GetMaxPlayerZombies", true);

	delete hGameData;
}

void SetupConVars()
{
	CreateConVar("l4d2_si_spawn_control_version", PLUGIN_VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	z_special_limit[SMOKER] =		FindConVar("z_smoker_limit");
	z_special_limit[BOOMER] =		FindConVar("z_boomer_limit");
	z_special_limit[HUNTER] =		FindConVar("z_hunter_limit");
	z_special_limit[SPITTER] =		FindConVar("z_spitter_limit");
	z_special_limit[JOCKEY] =		FindConVar("z_jockey_limit");
	z_special_limit[CHARGER] =		FindConVar("z_charger_limit");
	z_attack_flow_range =			FindConVar("z_attack_flow_range");
	z_spawn_flow_limit =			FindConVar("z_spawn_flow_limit");
	director_spectate_specials =	FindConVar("director_spectate_specials");
	z_spawn_safety_range =			FindConVar("z_spawn_safety_range");
	z_finale_spawn_safety_range =	FindConVar("z_finale_spawn_safety_range");
	z_spawn_range =					FindConVar("z_spawn_range");
	z_discard_range =				FindConVar("z_discard_range");

	g_hCvar_SpecialLimit[HUNTER] =	CreateConVar("l4d2_si_spawn_control_hunter_limit",	"1", "Hunter limit.", FCVAR_NONE, true, 0.0, true, 32.0);
	g_hCvar_SpecialLimit[JOCKEY] =	CreateConVar("l4d2_si_spawn_control_jockey_limit",	"1", "Jockey limit.", FCVAR_NONE, true, 0.0, true, 32.0);
	g_hCvar_SpecialLimit[SMOKER] =	CreateConVar("l4d2_si_spawn_control_smoker_limit",	"1", "Smoker limit.", FCVAR_NONE, true, 0.0, true, 32.0);
	g_hCvar_SpecialLimit[BOOMER] =	CreateConVar("l4d2_si_spawn_control_boomer_limit",	"1", "Boomer limit.", FCVAR_NONE, true, 0.0, true, 32.0);
	g_hCvar_SpecialLimit[SPITTER] = CreateConVar("l4d2_si_spawn_control_spitter_limit",	"1", "Spitter limit.", FCVAR_NONE, true, 0.0, true, 32.0);
	g_hCvar_SpecialLimit[CHARGER] =	CreateConVar("l4d2_si_spawn_control_charger_limit",	"1", "Charger limit.", FCVAR_NONE, true, 0.0, true, 32.0);

	g_hCvar_MaxSILimit =		CreateConVar("l4d2_si_spawn_control_max_specials",			"6",	"Max SI limit.", FCVAR_NONE, true, 0.0, true, 32.0);
	g_hCvar_SpawnTime =			CreateConVar("l4d2_si_spawn_control_spawn_time",			"10.0",	"SI spawn time.", FCVAR_NONE, true, 1.0);
	g_hCvar_FirstSpawnTime =	CreateConVar("l4d2_si_spawn_control_first_spawn_time",		"10.0",	"SI first spawn time (after leaving the safe area).", FCVAR_NONE, true, 0.1);
	g_hCvar_KillSITime =		CreateConVar("l4d2_si_spawn_control_kill_si_time",			"25.0",	"Auto kill SI time. if it 'slack off'.", FCVAR_NONE, true, 0.1);
	g_hCvar_BlockSpawn = 		CreateConVar("l4d2_si_spawn_control_block_other_si_spawn",	"1",	"Block other SI spawn (by L4D_OnSpawnSpecial).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCvar_SpawnMode =			CreateConVar("l4d2_si_spawn_control_spawn_mode",			"0",	"Spawn mode, See enum SpawnMode_*");
	g_hCvar_NormalSpawnRange =	CreateConVar("l4d2_si_spawn_control_spawn_range_normal",	"1500", "Normal mode spawn range, randomly spawn from 1 to this range.", FCVAR_NONE, true, 1.0);
	g_hCvar_NavAreaSpawnRange =	CreateConVar("l4d2_si_spawn_control_spawn_range_navarea",	"1500", "NavArea mode spawn range, randomly spawn from 1 to this range.", FCVAR_NONE, true, 1.0);
	g_hCvar_TogetherSpawn =		CreateConVar("l4d2_si_spawn_control_together_spawn",		"0",	"After SI dies, wait for other SI to spawn together.", FCVAR_NONE, true, 0.0, true, 1.0);

	GetCvars();

	for (int i = 1; i < SI_CLASS_SIZE; i++)
	{
		g_hCvar_SpecialLimit[i].AddChangeHook(ConVarChanged);
	}
	g_hCvar_MaxSILimit.AddChangeHook(ConVarChanged);
	g_hCvar_SpawnTime.AddChangeHook(ConVarChanged);
	g_hCvar_FirstSpawnTime.AddChangeHook(ConVarChanged);
	g_hCvar_KillSITime.AddChangeHook(ConVarChanged);
	g_hCvar_BlockSpawn.AddChangeHook(ConVarChanged);
	g_hCvar_SpawnMode.AddChangeHook(ConVarChanged);
	g_hCvar_NormalSpawnRange.AddChangeHook(ConVarChanged);
	g_hCvar_NavAreaSpawnRange.AddChangeHook(ConVarChanged);
	g_hCvar_TogetherSpawn.AddChangeHook(ConVarChanged);
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();

	if (!g_bLeftSafeArea)
		return;
		
	if (convar == g_hCvar_MaxSILimit)
	{
		if (StringToInt(newValue) > StringToInt(oldValue))
		{
			for (int i; i <= MAXPLAYERS; i++)
				delete g_hSpawnTimer[i];

			SpawnSpecial_Timer(null, SPAWN_MAX_PRE);
		}
	}

	else if (convar == g_hCvar_SpawnTime)
	{
		for (int i; i <= MAXPLAYERS; i++)
			delete g_hSpawnTimer[i];

		g_hSpawnTimer[SPAWN_MAX_PRE] = CreateTimer(g_fSpawnTime, SpawnSpecial_Timer, SPAWN_MAX_PRE);
	}
}

void GetCvars()
{
	for (int i = 1; i < SI_CLASS_SIZE; i++)
	{
		g_iSpecialLimit[i] = g_hCvar_SpecialLimit[i].IntValue;
	}

	g_iMaxSILimit = g_hCvar_MaxSILimit.IntValue;
	g_fSpawnTime = g_hCvar_SpawnTime.FloatValue;
	g_fFirstSpawnTime = g_hCvar_FirstSpawnTime.FloatValue;
	g_fKillSITime = g_hCvar_KillSITime.FloatValue;
	g_bBlockSpawn = g_hCvar_BlockSpawn.BoolValue;
	g_iSpawnMode = g_hCvar_SpawnMode.IntValue;
	g_fNormalSpawnRange = g_hCvar_NormalSpawnRange.FloatValue;
	g_fNavAreaSpawnRange = g_hCvar_NavAreaSpawnRange.FloatValue;
	g_bTogetherSpawn = g_hCvar_TogetherSpawn.BoolValue;

	z_spawn_range.IntValue = RoundToNearest(g_fNormalSpawnRange);
}

void RestoreConVars()
{
	for (int i = 1; i < SI_CLASS_SIZE; i++)
		z_special_limit[i].RestoreDefault();

	z_attack_flow_range.RestoreDefault();
	z_spawn_flow_limit.RestoreDefault();
	director_spectate_specials.RestoreDefault();
	z_spawn_safety_range.RestoreDefault();
	z_finale_spawn_safety_range.RestoreDefault();
	z_spawn_range.RestoreDefault();
	z_discard_range.RestoreDefault();
}

void SetConVars()
{
	for (int i = 1; i < SI_CLASS_SIZE; i++)
		z_special_limit[i].IntValue = 0;

	z_attack_flow_range.IntValue = 50000;
	z_spawn_flow_limit.IntValue = 50000;
	director_spectate_specials.IntValue = 1;
	z_spawn_safety_range.IntValue = 1;
	z_finale_spawn_safety_range.IntValue = 1;
}