#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <gamedata_wrapper>
#include <colors>

#define SAFE_ROOM		(1 << 0)
#define RESCUE_VEHICLE	(1 << 1)
#define SOUND_COUNTDOWN "buttons/blip1.wav"
#define L4D2Team_Survivor 2
#define GAMEDATA_FILE "saferoom_teleport"

#define DEBUG_ST		0

Handle g_hTimer;

ArrayList
	g_hArrayEndNavArea,
	g_hArrayRescueVehicle;

ConVar
	g_hCvarAllow,
	g_hCvarSafeAreaFlags,
	g_hCvarSafeAreaType,
	g_hCvarSafeAreaTime,
	g_hCvarMinSurvivorPercent,
	g_hCvarShouldRefillStatus,
	g_hCvarShouldRestore,
	g_hCvarAutoLocked;

int
	g_iOff_m_flow,
	g_iTheCount,
	g_iCountdown,
	g_iChangelevel,
	g_iRescueVehicle,
	g_iTriggerFinale,
	g_iSafeAreaFlags,
	g_iSafeAreaType,
	g_iSafeAreaTime,
	g_iMinSurvivorPercent;

Address g_pTheCount;

float
	g_vMins[3],
	g_vMaxs[3],
	g_vOrigin[3];

bool
	g_bCvarAllow,
	g_bIsFinalMap,
	g_bIsTriggered,
	g_bIsSacrificeFinale,
	g_bShouldRefillTeleportedStatus,
	g_bShouldRestore,
	g_bAutoLocked,
	g_bFinaleVehicleReady;

Handle
	g_hSDKCall_CTerrorPlayer_CleanupPlayerState,
	g_hSDKCall_TerrorNavMesh_GetLastCheckpoint,
	g_hSDKCall_Checkpoint_ContainsArea,
	g_hSDKCall_Checkpoint_GetLargestArea,
	g_hSDKCall_CDirectorChallengeMode_FindRescueAreaTrigger,
	g_hSDKCall_CBaseTrigger_IsTouching;

enum struct Door {
	int entRef;
	float m_flSpeed;
}
Door g_LastDoor;

methodmap TerrorNavArea {
	public bool IsNull() {
		return view_as<Address>(this) == Address_Null;
	}

	public void Mins(float result[3]) {
		result[0] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(4), NumberType_Int32));
		result[1] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(8), NumberType_Int32));
		result[2] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(12), NumberType_Int32));
	}

	public void Maxs(float result[3]) {
		result[0] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(16), NumberType_Int32));
		result[1] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(20), NumberType_Int32));
		result[2] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(24), NumberType_Int32));
	}

	public void Center(float result[3]) {
		float vMins[3];
		float vMaxs[3];
		this.Mins(vMins);
		this.Maxs(vMaxs);

		AddVectors(vMins, vMaxs, result);
		ScaleVector(result, 0.5);
	}

	public void FindRandomSpot(float result[3]) {
		L4D_FindRandomSpot(view_as<int>(this), result);
	}

	property float m_flow {
		public get() {
			return view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_flow), NumberType_Int32));
		}
	}
	
	property int m_attributeFlags {
		public get() {
			return L4D_GetNavArea_AttributeFlags(view_as<Address>(this));
		}
	}

	property int m_spawnAttributes {
		public get() {
			return L4D_GetNavArea_SpawnAttributes(view_as<Address>(this));
		}
	}
};

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo = {
	name = "[L4D2] Saferoom Teleport",
	author = "sorallll, blueblur",
	description = "Teleport players to end saferoom",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	LoadGameData();
	LoadTranslation("saferoom_teleport.phrases");
	g_hArrayEndNavArea			  = new ArrayList();
	g_hArrayRescueVehicle		  = new ArrayList();

	CreateConVar("saferoom_teleport_version", PLUGIN_VERSION, "Saferoom Teleport version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvarAllow			  = CreateConVar("st_allow", "1", "Enable saferoom teleport? 0=disable, 1=enable.");
	g_hCvarSafeAreaFlags	  = CreateConVar("st_enable", "1", "when to teleport? 1=end safe room, 2=final rescue vehicle, 3=both.");
	g_hCvarSafeAreaType		  = CreateConVar("st_type", "1", "how do we deal with those who are not in the safe room until the countdown ends? 1=teleport, 2=die.");
	g_hCvarSafeAreaTime		  = CreateConVar("st_time", "15", "countdown timer.");
	g_hCvarMinSurvivorPercent = CreateConVar("st_min_percent", "50", "the percentage of survivors required to trigger the teleport or death.");
	g_hCvarShouldRefillStatus = CreateConVar("st_refill_status", "1", "refill the teleported player's status after teleport.");
	g_hCvarShouldRestore	  = CreateConVar("st_restore", "1", "restore the all player's health after round end/teleportation.");
	g_hCvarAutoLocked		  = CreateConVar("st_auto_locked", "1", "automatically lock the safe room when the countdown ends? 0=no, 1=yes.");

	g_hCvarAllow.AddChangeHook(CvarChanged_Allow);
	g_hCvarSafeAreaFlags.AddChangeHook(CvarChanged);
	g_hCvarSafeAreaType.AddChangeHook(CvarChanged);
	g_hCvarSafeAreaTime.AddChangeHook(CvarChanged);
	g_hCvarMinSurvivorPercent.AddChangeHook(CvarChanged);
	g_hCvarShouldRefillStatus.AddChangeHook(CvarChanged);
	g_hCvarShouldRestore.AddChangeHook(CvarChanged);
	g_hCvarAutoLocked.AddChangeHook(CvarChanged);

	RegAdminCmd("sm_warpend", cmdWarpEnd, ADMFLAG_RCON, "Send all survivors to the destination safe area");
	RegAdminCmd("sm_st", cmdSt, ADMFLAG_ROOT, "Test");

	HookEntityOutput("trigger_finale", "FinaleStart", OnFinaleStart);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void OnMapStart()
{
	PrecacheSound(SOUND_COUNTDOWN);
	g_bIsFinalMap = L4D_IsMissionFinalMap();
}

public void OnMapEnd()
{
	ResetPlugin();

	if (g_hTimer)
		g_hTimer = null;

	g_iTheCount = 0;
	g_hArrayEndNavArea.Clear();
}

void OnFinaleStart(const char[] output, int caller, int activator, float delay)
{
#if DEBUG_ST
	PrintToServer("### SAFE_ROOM_TELEPORT: OnFinaleStart");
#endif

	if (!g_bIsFinalMap || g_iSafeAreaFlags & RESCUE_VEHICLE == 0 || IsValidEntRef(g_iTriggerFinale))
		return;

	g_iTriggerFinale	 = EntIndexToEntRef(caller);
	g_bIsSacrificeFinale = !!GetEntProp(g_iTriggerFinale, Prop_Data, "m_bIsSacrificeFinale");

	if (g_bIsSacrificeFinale)
	{
		CPrintToChatAll("%t", "IsSacrificeFinale");

		int entRef;
		int count = g_hArrayRescueVehicle.Length;
		for (int i; i < count; i++)
		{
			if (EntRefToEntIndex((entRef = g_hArrayRescueVehicle.Get(i))) != INVALID_ENT_REFERENCE)
			{
				UnhookSingleEntityOutput(entRef, "OnStartTouch", OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}
	}
}

Action cmdWarpEnd(int client, int args)
{
	if (!g_hArrayEndNavArea.Length)
	{
		ReplyToCommand(client, "No endpoint nav area found");
		return Plugin_Handled;
	}

	Perform(1);
	return Plugin_Handled;
}

Action cmdSt(int client, int args)
{
	ReplyToCommand(client, "ChangeLevel->%d RescueAreaTrigger->%d EndNavArea->%d", g_iChangelevel ? EntRefToEntIndex(g_iChangelevel) : -1, SDKCall(g_hSDKCall_CDirectorChallengeMode_FindRescueAreaTrigger), g_hArrayEndNavArea.Length);
	return Plugin_Handled;
}

void CvarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	int last			  = g_iSafeAreaFlags;
	g_iSafeAreaFlags	  = g_hCvarSafeAreaFlags.IntValue;
	g_iSafeAreaType		  = g_hCvarSafeAreaType.IntValue;
	g_iSafeAreaTime		  = g_hCvarSafeAreaTime.IntValue;
	g_iMinSurvivorPercent = g_hCvarMinSurvivorPercent.IntValue;
	g_bShouldRestore	  = g_hCvarShouldRestore.BoolValue;
	g_bAutoLocked		  = g_hCvarAutoLocked.BoolValue;
	g_bShouldRefillTeleportedStatus = g_hCvarShouldRefillStatus.BoolValue;


	if (last != g_iSafeAreaFlags)
	{
		if (IsValidEntRef(g_iChangelevel))
		{
			UnhookSingleEntityOutput(g_iChangelevel, "OnStartTouch", OnStartTouch);
			UnhookSingleEntityOutput(g_iChangelevel, "OnEndTouch", OnEndTouch);
		}

		int i;
		int entRef;
		int count = g_hArrayRescueVehicle.Length;
		for (; i < count; i++)
		{
			if ((entRef = g_hArrayRescueVehicle.Get(i)) != g_iRescueVehicle && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE)
			{
				UnhookSingleEntityOutput(entRef, "OnStartTouch", OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}

		CreateTimer(6.5, tmrInitPlugin, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

// credit to Silvers
void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	GetCvars();

	if (!g_bCvarAllow && bCvarAllow)
	{
		g_bCvarAllow = true;

		CreateTimer(6.5, tmrInitPlugin, _, TIMER_FLAG_NO_MAPCHANGE);

		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("round_start_post_nav", Event_RoundStartPostNav, EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady, EventHookMode_PostNoCopy);
	}
	else if (g_bCvarAllow && !bCvarAllow)
	{
		g_bCvarAllow = false;

		UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("round_start_post_nav", Event_RoundStartPostNav, EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_ready", Event_FinaleVehicleReady, EventHookMode_PostNoCopy);

		ResetPlugin();

		if (g_hTimer)
			g_hTimer = null;

		if (IsValidEntRef(g_iChangelevel))
		{
			UnhookSingleEntityOutput(g_iChangelevel, "OnStartTouch", OnStartTouch);
			UnhookSingleEntityOutput(g_iChangelevel, "OnEndTouch", OnEndTouch);
		}

		int i;
		int entRef;
		int count = g_hArrayRescueVehicle.Length;
		for (; i < count; i++)
		{
			if ((entRef = g_hArrayRescueVehicle.Get(i)) != g_iRescueVehicle && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE)
			{
				UnhookSingleEntityOutput(entRef, "OnStartTouch", OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}
	}
}

void ResetPlugin()
{
	g_bIsTriggered		  = false;
	g_bIsSacrificeFinale  = false;
	g_bFinaleVehicleReady = false;
}

// right before game saving entities. we refill the status.
public Action L4D2_OnSavingEntities(int info_changelevel)
{
#if DEBUG_ST
		PrintToServer("### SAFE_ROOM_TELEPORT: L4D2_OnSavingEntities refill status.");
#endif

	if (!g_bShouldRestore)
		return Plugin_Continue;

	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != L4D2Team_Survivor)
			continue;

		RefillStatus(i);
	}

    return Plugin_Continue;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (strcmp(name, "round_end") == 0)
		ResetPlugin();

	if (g_hTimer)
		g_hTimer = null;
}

void Event_RoundStartPostNav(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(6.5, tmrInitPlugin, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_FinaleVehicleReady(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinaleVehicleReady = true;
}

void tmrInitPlugin(Handle timer)
{
	InitPlugin();
}

void InitPlugin()
{
#if DEBUG_ST
	PrintToServer("### SAFE_ROOM_TELEPORT: InitPlugin");
#endif
	if (!g_bIsFinalMap)
		g_bFinaleVehicleReady = true;

	if (GetNavAreaCount() && FindEndNavAreas())
	{
		HookEndAreaEntity();
		FindSafeRoomDoors();
	}
}

bool FindEndNavAreas()
{
	if (g_hArrayEndNavArea.Length)
		return true;

	if (g_bIsFinalMap)
	{
		bool bVehicle = !!(g_iSafeAreaFlags & RESCUE_VEHICLE);
		if (!bVehicle) return false;
	}
	else
	{
		bool bSafe = !!(g_iSafeAreaFlags & SAFE_ROOM);
		if (!bSafe) return false;
	}

	int			  spawnAttributes;
	TerrorNavArea area;

	Address		  pLastCheckpoint;
	if (!g_bIsFinalMap)
		pLastCheckpoint = SDKCall(g_hSDKCall_TerrorNavMesh_GetLastCheckpoint, L4D_GetPointer(POINTER_NAVMESH));

	Address pTheNavAreas = view_as<Address>(LoadFromAddress(g_pTheCount + view_as<Address>(4), NumberType_Int32));
	if (!pTheNavAreas)
	{
		LogError("Failed to find address: TheNavAreas");
		return false;
	}

	for (int i; i < g_iTheCount; i++)
	{
		if ((area = view_as<TerrorNavArea>(LoadFromAddress(pTheNavAreas + view_as<Address>(i * 4), NumberType_Int32))).IsNull())
			continue;

		if (area.m_flow == -9999.0)
			continue;

		if (area.m_attributeFlags & NAV_BASE_OUTSIDE_WORLD)
			continue;

		spawnAttributes = area.m_spawnAttributes;
		if (g_bIsFinalMap)
		{
			if (spawnAttributes & NAV_SPAWN_RESCUE_VEHICLE)
				g_hArrayEndNavArea.Push(area);
		}
		else
		{
			if (spawnAttributes & NAV_SPAWN_CHECKPOINT == 0 || spawnAttributes & NAV_SPAWN_DESTROYED_DOOR)
				continue;

			if (view_as<int>(pLastCheckpoint) <= 0)
				continue;

			if (SDKCall(g_hSDKCall_Checkpoint_ContainsArea, pLastCheckpoint, area))
				g_hArrayEndNavArea.Push(area);
		}
	}
#if DEBUG_ST
	PrintToServer("### SAFE_ROOM_TELEPORT: FindEndNavAreas, End nav areas: %d", g_hArrayEndNavArea.Length);
#endif
	return g_hArrayEndNavArea.Length > 0;
}

void HookEndAreaEntity()
{
#if DEBUG_ST
	PrintToServer("### SAFE_ROOM_TELEPORT: HookEndAreaEntity");
#endif
	g_iChangelevel	 = 0;
	g_iTriggerFinale = 0;
	g_iRescueVehicle = 0;

	g_hArrayRescueVehicle.Clear();

	g_vMins	  = NULL_VECTOR;
	g_vMaxs	  = NULL_VECTOR;
	g_vOrigin = NULL_VECTOR;

	if (!g_iSafeAreaFlags)
		return;

	int entity = INVALID_ENT_REFERENCE;
	if ((entity = FindEntityByClassname(MaxClients + 1, "info_changelevel")) == INVALID_ENT_REFERENCE)
		entity = FindEntityByClassname(MaxClients + 1, "trigger_changelevel");

	if (entity != INVALID_ENT_REFERENCE)
	{
		if (g_iSafeAreaFlags & SAFE_ROOM)
		{
			GetBrushEntityVector((g_iChangelevel = EntIndexToEntRef(entity)));
			HookSingleEntityOutput(entity, "OnStartTouch", OnStartTouch);
			HookSingleEntityOutput(entity, "OnEndTouch", OnEndTouch);
		}
	}
	else if (g_iSafeAreaFlags & RESCUE_VEHICLE)
	{
		entity = FindEntityByClassname(MaxClients + 1, "trigger_finale");
		if (entity != INVALID_ENT_REFERENCE)
		{
			g_iTriggerFinale	 = EntIndexToEntRef(entity);
			g_bIsSacrificeFinale = !!GetEntProp(g_iTriggerFinale, Prop_Data, "m_bIsSacrificeFinale");
		}

		if (g_bIsSacrificeFinale)
			PrintToChatAll("%t", "IsSacrificeFinale");
		else
		{
			entity = MaxClients + 1;
			while ((entity = FindEntityByClassname(entity, "trigger_multiple")) != INVALID_ENT_REFERENCE)
			{
				if (GetEntProp(entity, Prop_Data, "m_iEntireTeam") != 2)
					continue;

				g_hArrayRescueVehicle.Push(EntIndexToEntRef(entity));
				HookSingleEntityOutput(entity, "OnStartTouch", OnStartTouch);
				HookSingleEntityOutput(entity, "OnEndTouch", OnEndTouch);
			}

			if (g_hArrayRescueVehicle.Length == 1)
				GetBrushEntityVector((g_iRescueVehicle = g_hArrayRescueVehicle.Get(0)));
		}
	}
}

void GetBrushEntityVector(int entity)
{
	GetEntPropVector(entity, Prop_Send, "m_vecMins", g_vMins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", g_vMaxs);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_vOrigin);
}

void FindSafeRoomDoors()
{
#if DEBUG_ST
	PrintToServer("### SAFE_ROOM_TELEPORT: FindSafeRoomDoors");
#endif
	g_LastDoor.entRef	 = 0;
	g_LastDoor.m_flSpeed = 0.0;

	if (g_bIsFinalMap || g_iSafeAreaFlags & SAFE_ROOM == 0)
		return;

	if (!IsValidEntRef(g_iChangelevel))
		return;

	int ent = L4D_GetCheckpointLast();

#if DEBUG_ST
	PrintToServer("### SAFE_ROOM_TELEPORT: FindSafeRoomDoors,  End safe room door: %d", ent);
#endif

	if (ent != -1)
	{
		g_LastDoor.entRef	 = EntIndexToEntRef(ent);
		g_LastDoor.m_flSpeed = GetEntPropFloat(ent, Prop_Data, "m_flSpeed");
	}
}

void OnStartTouch(const char[] output, int caller, int activator, float delay)
{
	if (activator < 1 || activator > MaxClients)
		return;

#if DEBUG_ST
	char sCaller[64], sActivator[64];
	GetEntityClassname(caller, sCaller, sizeof sCaller);
	GetEntityClassname(activator, sActivator, sizeof sActivator);
	PrintToServer("### SAFE_ROOM_TELEPORT: OnStartTouch, caller: %d, caller name: %s, activator: %d, activator name: %s", caller, sCaller, activator, sActivator);
#endif

	if (!IsClientInGame(activator) || GetClientTeam(activator) != 2 || !IsPlayerAlive(activator))
		return;

	if (g_bIsTriggered || g_bIsSacrificeFinale || !g_bFinaleVehicleReady || !g_iSafeAreaTime)
		return;

	int value;
	if (!g_iChangelevel && !g_iRescueVehicle)
	{
		if (caller != SDKCall(g_hSDKCall_CDirectorChallengeMode_FindRescueAreaTrigger))
			return;

		GetBrushEntityVector((g_iRescueVehicle = EntIndexToEntRef(caller)));

		value = 0;
		int entRef;
		int count = g_hArrayRescueVehicle.Length;
		for (; value < count; value++)
		{
			if ((entRef = g_hArrayRescueVehicle.Get(value)) != g_iRescueVehicle && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE)
			{
				UnhookSingleEntityOutput(entRef, "OnStartTouch", OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}

		float vMins[3];
		float vMaxs[3];
		float vOrigin[3];
		vMins	= g_vMins;
		vMaxs	= g_vMaxs;
		vOrigin = g_vOrigin;

		vMins[0] -= 33.0;
		vMins[1] -= 33.0;
		vMins[2] -= 33.0;
		vMaxs[0] += 33.0;
		vMaxs[1] += 33.0;
		vMaxs[2] += 33.0;
		CalculateBoundingBoxSize(vMins, vMaxs, vOrigin);

		value = 0;
		count = g_hArrayEndNavArea.Length;
		while (value < count)
		{
			view_as<TerrorNavArea>(g_hArrayEndNavArea.Get(value)).Center(vOrigin);
			if (!IsPosInArea(vOrigin, vMins, vMaxs))
			{
				g_hArrayEndNavArea.Erase(value);
				count--;
			}
			else
				value++;
		}
	}

	if (!g_hArrayEndNavArea.Length)
	{
		g_bIsTriggered = true;
		return;
	}

	value = 0;
	int reached;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			value++;
			if (IsPlayerInEndArea(i, false))
				reached++;
		}
	}

	value = RoundToCeil(g_iMinSurvivorPercent / 100.0 * value);
	if (reached < value)
	{
		if (reached)
			PrintHintToSurvivor("%t", "SurvivorReached", reached, value);

		return;
	}

	g_bIsTriggered = true;
	g_iCountdown   = g_iSafeAreaTime;

	if (g_hTimer)
		delete g_hTimer;

	g_hTimer = CreateTimer(1.0, tmrCountdown, _, TIMER_REPEAT);
}

void OnEndTouch(const char[] output, int caller, int activator, float delay)
{
	if (activator < 1 || activator > MaxClients)
		return;

#if DEBUG_ST
	char sCaller[64], sActivator[64];
	GetEntityClassname(caller, sCaller, sizeof sCaller);
	GetEntityClassname(activator, sActivator, sizeof sActivator);
	PrintToServer("### SAFE_ROOM_TELEPORT: OnEndTouch, caller: %d, caller name: %s, activator: %d, activator name: %s", caller, sCaller, activator, sActivator);
#endif

	if (!IsClientInGame(activator) || GetClientTeam(activator) != 2)
		return;

	if (g_bIsTriggered || g_bIsSacrificeFinale || !g_bFinaleVehicleReady || !g_iSafeAreaTime)
		return;

	int value;
	if (!g_iChangelevel && !g_iRescueVehicle)
	{
		if (caller != SDKCall(g_hSDKCall_CDirectorChallengeMode_FindRescueAreaTrigger))
			return;

		GetBrushEntityVector((g_iRescueVehicle = EntIndexToEntRef(caller)));

		value = 0;
		int entRef;
		int count = g_hArrayRescueVehicle.Length;
		for (; value < count; value++)
		{
			if ((entRef = g_hArrayRescueVehicle.Get(value)) != g_iRescueVehicle && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE)
			{
				UnhookSingleEntityOutput(entRef, "OnStartTouch", OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}

		float vMins[3];
		float vMaxs[3];
		float vOrigin[3];
		vMins	= g_vMins;
		vMaxs	= g_vMaxs;
		vOrigin = g_vOrigin;

		vMins[0] -= 33.0;
		vMins[1] -= 33.0;
		vMins[2] -= 33.0;
		vMaxs[0] += 33.0;
		vMaxs[1] += 33.0;
		vMaxs[2] += 33.0;
		CalculateBoundingBoxSize(vMins, vMaxs, vOrigin);

		value = 0;
		count = g_hArrayEndNavArea.Length;
		while (value < count)
		{
			view_as<TerrorNavArea>(g_hArrayEndNavArea.Get(value)).Center(vOrigin);
			if (!IsPosInArea(vOrigin, vMins, vMaxs))
			{
				g_hArrayEndNavArea.Erase(value);
				count--;
			}
			else
				value++;
		}
	}

	if (!g_hArrayEndNavArea.Length)
	{
		g_bIsTriggered = true;
		return;
	}

	value = 0;
	int reached;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			value++;
			if (IsPlayerInEndArea(i, false))
				reached++;
		}
	}

	value = RoundToCeil(g_iMinSurvivorPercent / 100.0 * value);
	if (reached < value)
	{
		if (reached)
			PrintHintToSurvivor("%t", "SurvivorReached", reached, value);

		return;
	}

	g_bIsTriggered = true;
	g_iCountdown   = g_iSafeAreaTime;

	if (g_hTimer)
		delete g_hTimer;

	g_hTimer = CreateTimer(1.0, tmrCountdown, _, TIMER_REPEAT);
}

Action tmrCountdown(Handle timer)
{
	if (g_iCountdown > 0)
	{
		switch (g_iSafeAreaType)
		{
			case 1: PrintHintToSurvivor("%t", "Countdown_Send", g_iCountdown--);
			case 2: PrintHintToSurvivor("%t", "Countdown_Slay", g_iCountdown--);
		}

		EmitSoundToSurvivor(SOUND_COUNTDOWN,
							SOUND_FROM_PLAYER,
		  					SNDCHAN_STATIC,
		   					SNDLEVEL_NORMAL,
		    				SND_NOFLAGS,
			 				SNDVOL_NORMAL,
			  				SNDPITCH_NORMAL,
			   				-1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	else if (g_iCountdown <= 0)
	{
		Perform(g_iSafeAreaType);

		if (g_hTimer)
			g_hTimer = null;

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void Perform(int type)
{
	switch (type)
	{
		case 1:
		{
			// teleport them first. in case you spawning out side of the map.
			CreateTimer(0.1, tmrTeleportToEndArea, _, TIMER_FLAG_NO_MAPCHANGE);

			if (!g_bIsFinalMap && g_bAutoLocked)
				CloseAndLockLastSafeDoor();
		}

		case 2:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsPlayerInEndArea(i, false))
				{
					if (!g_bIsFinalMap && g_bAutoLocked)
						CloseAndLockLastSafeDoor();	   // in case of *INVASION*

					ForcePlayerSuicide(i);
				}
			}
		}
	}
}

void CloseAndLockLastSafeDoor()
{
	int entRef = g_LastDoor.entRef;
	if (EntRefToEntIndex(entRef) > 0)
	{
		if (!HasEntProp(entRef, Prop_Data, "m_hasUnlockSequence"))
			return;

		char buffer[64];
		SetEntPropFloat(entRef, Prop_Data, "m_flSpeed", 1000.0);
		SetEntProp(entRef, Prop_Data, "m_hasUnlockSequence", 0);
		AcceptEntityInput(entRef, "DisableCollision");
		AcceptEntityInput(entRef, "Unlock");
		AcceptEntityInput(entRef, "Close");
		AcceptEntityInput(entRef, "forceclosed");
		AcceptEntityInput(entRef, "Lock");
		SetEntProp(entRef, Prop_Data, "m_hasUnlockSequence", 1);

		SetVariantString("OnUser1 !self:EnableCollision::1.0:-1");
		AcceptEntityInput(entRef, "AddOutput");
		SetVariantString("OnUser1 !self:Unlock::5.0:-1");
		AcceptEntityInput(entRef, "AddOutput");
		FloatToString(g_LastDoor.m_flSpeed, buffer, sizeof buffer);
		Format(buffer, sizeof buffer, "OnUser1 !self:SetSpeed:%s:5.0:-1", buffer);
		SetVariantString(buffer);
		AcceptEntityInput(entRef, "AddOutput");
		AcceptEntityInput(entRef, "FireUser1");
	}
}

void tmrTeleportToEndArea(Handle timer)
{
	TeleportToEndArea();
}

void TeleportToEndArea()
{
	int count = g_hArrayEndNavArea.Length;
	if (count > 0)
	{
		RemoveInfecteds();

		int i = 1;
		for (; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
			{
				// force SI Suicide.
				SDKCall(g_hSDKCall_CTerrorPlayer_CleanupPlayerState, i);
				ForcePlayerSuicide(i);
			}
		}

		float		  vPos[3];
		TerrorNavArea largest;

		if (!g_bIsFinalMap)
			largest = SDKCall(	g_hSDKCall_Checkpoint_GetLargestArea, 
								SDKCall(g_hSDKCall_TerrorNavMesh_GetLastCheckpoint,
								L4D_GetPointer(POINTER_NAVMESH)));

		(!largest.IsNull()) ? largest.FindRandomSpot(vPos) : view_as<TerrorNavArea>(g_hArrayEndNavArea.Get(GetRandomInt(0, count - 1))).FindRandomSpot(vPos);

		for (i = 1; i <= MaxClients; i++)
		{
			// respawn, teleport, then restore health.
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if (!IsPlayerAlive(i) && g_bShouldRefillTeleportedStatus)
					L4D_RespawnPlayer(i);

				if (!IsPlayerInEndArea(i))
				{
					TeleportFix(i);
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR);
					if (g_bShouldRefillTeleportedStatus)
					{
#if DEBUG_ST
						PrintToServer("### SAFE_ROOM_TELEPORT: Refilling status for player %d", i);
#endif
						RefillStatus(i);
					}
				}
			}
		}
	}
}

void RefillStatus(int client)
{
	if (client < 1 || client > MaxClients)
		return;

	if (!IsClientInGame(client))
		return;

	if (IsIncapacitated(client))
		L4D_ReviveSurvivor(client);

	if (!IsPlayerAlive(client))
		L4D_RespawnPlayer(client);

	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth"));
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
	StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
}

void TeleportFix(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
		L4D_ReviveSurvivor(client);

	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") & ~FL_FROZEN);
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") | FL_DUCKING);
}

void RemoveInfecteds()
{
	float vMins[3];
	float vMaxs[3];
	float vOrigin[3];
	vMins	= g_vMins;
	vMaxs	= g_vMaxs;
	vOrigin = g_vOrigin;

	vMins[0] -= 33.0;
	vMins[1] -= 33.0;
	vMins[2] -= 33.0;
	vMaxs[0] += 33.0;
	vMaxs[1] += 33.0;
	vMaxs[2] += 33.0;
	CalculateBoundingBoxSize(vMins, vMaxs, vOrigin);

	char classname[9];
	int	 maxEnts = GetMaxEntities();
	for (int i = MaxClients + 1; i <= maxEnts; i++)
	{
		if (!IsValidEntity(i))
			continue;

		GetEntityClassname(i, classname, sizeof classname);
		if (strcmp(classname, "infected") != 0 && strcmp(classname, "witch") != 0)
			continue;

		GetEntPropVector(i, Prop_Send, "m_vecOrigin", vOrigin);
		if (!IsPosInArea(vOrigin, vMins, vMaxs))
			continue;

		RemoveEntity(i);
	}
}

bool GetNavAreaCount()
{
	if (g_iTheCount)
		return true;

	g_iTheCount = LoadFromAddress(g_pTheCount, NumberType_Int32);
#if DEBUG_ST
	PrintToServer("g_iTheCount: %d", g_iTheCount);
#endif
	if (!g_iTheCount)
		return false;

	return true;
}

bool IsPlayerInEndArea(int client, bool checkArea = true)
{
	int area = L4D_GetLastKnownArea(client);
	if (!area)
		return false;

	if (checkArea && g_hArrayEndNavArea.FindValue(area) == -1)
		return false;

	if (g_bIsFinalMap)
		return IsValidEntRef(g_iRescueVehicle) && SDKCall(g_hSDKCall_CBaseTrigger_IsTouching, g_iRescueVehicle, client);

	return IsValidEntRef(g_iChangelevel) && SDKCall(g_hSDKCall_CBaseTrigger_IsTouching, g_iChangelevel, client);
}

stock bool IsPosInArea(const float vPos[3], const float vMins[3], const float vMaxs[3]) 
{
	return (vMins[0] <= vPos[0] <= vMaxs[0] && vMins[1] <= vPos[1] <= vMaxs[1] && vMins[2] <= vPos[2] <= vMaxs[2]);
}

stock bool IsValidEntRef(int entity) 
{
	return (entity && (EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE));
}

stock void CalculateBoundingBoxSize(float vMins[3], float vMaxs[3], const float vOrigin[3]) 
{
	AddVectors(vOrigin, vMins, vMins);
	AddVectors(vOrigin, vMaxs, vMaxs);
}

stock bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}

stock void EmitSoundToSurvivor(const char[] sample,
				 int entity = SOUND_FROM_PLAYER,
				 int channel = SNDCHAN_AUTO,
				 int level = SNDLEVEL_NORMAL,
				 int flags = SND_NOFLAGS,
				 float volume = SNDVOL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int speakerentity = -1,
				 const float origin[3] = NULL_VECTOR,
				 const float dir[3] = NULL_VECTOR,
				 bool updatePos = true,
				 float soundtime = 0.0)
{
	int[] clients = new int[MaxClients];
	int total;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			int iBot = IsClientIdle(i);
		
			if(iBot != 0)
			{
				if(!IsFakeClient(iBot))
				{
					clients[total++] = iBot;
				}
			}
			else
			{
				if(!IsFakeClient(i))
				{
					clients[total++] = i;
				}
			}
		}
	}

	if (total) {
		EmitSound(clients, total, sample, entity, channel,
			level, flags, volume, pitch, speakerentity,
			origin, dir, updatePos, soundtime);
	}
}

stock void PrintHintToSurvivor(const char[] format, any ...) 
{
	static char buffer[254];
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2) 
		{
			int iBot = IsClientIdle(i);
		
			if(iBot != 0)
			{
				if(!IsFakeClient(iBot))
				{
					SetGlobalTransTarget(iBot);
					VFormat(buffer, sizeof buffer, format, 2);
					PrintHintText(iBot, "%s", buffer);
				}
			}
			else
			{
				if(!IsFakeClient(i))
				{
					SetGlobalTransTarget(i);
					VFormat(buffer, sizeof buffer, format, 2);
					PrintHintText(i, "%s", buffer);
				}
			}
		}
	}
}

stock int IsClientIdle(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

void LoadGameData()
{
	GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);

	g_pTheCount = gd.GetAddress("TheNavAreas.Count()");
	g_iOff_m_flow = gd.GetOffset("TerrorNavArea->m_flow");

	g_hSDKCall_CTerrorPlayer_CleanupPlayerState 			= gd.CreateSDKCallOrFail(SDKCall_Player, 	SDKConf_Signature, "CTerrorPlayer::CleanupPlayerState");

	SDKCallParamsWrapper ret 								= {SDKType_PlainOldData, SDKPass_Plain};
	g_hSDKCall_TerrorNavMesh_GetLastCheckpoint				= gd.CreateSDKCallOrFail(SDKCall_Raw, 		SDKConf_Signature, "TerrorNavMesh::GetLastCheckpoint", _, _, true, ret);

	SDKCallParamsWrapper params[] 							= {{SDKType_PlainOldData, SDKPass_Plain}};
	SDKCallParamsWrapper ret2 								= {SDKType_Bool, SDKPass_Plain};
	g_hSDKCall_Checkpoint_ContainsArea						= gd.CreateSDKCallOrFail(SDKCall_Raw, 		SDKConf_Signature, "Checkpoint::ContainsArea", params, sizeof(params), true, ret2);

	SDKCallParamsWrapper ret3 								= {SDKType_PlainOldData, SDKPass_Plain};
	g_hSDKCall_Checkpoint_GetLargestArea					= gd.CreateSDKCallOrFail(SDKCall_Raw, 		SDKConf_Signature, "Checkpoint::GetLargestArea", _, _, true, ret3);

	SDKCallParamsWrapper ret4 								= {SDKType_CBaseEntity, SDKPass_Pointer};
	g_hSDKCall_CDirectorChallengeMode_FindRescueAreaTrigger = gd.CreateSDKCallOrFail(SDKCall_GameRules, SDKConf_Signature, "CDirectorChallengeMode::FindRescueAreaTrigger", _, _, true, ret4);

	SDKCallParamsWrapper params2[] 							= {{SDKType_CBaseEntity, SDKPass_Pointer}};
	SDKCallParamsWrapper ret5 								= {SDKType_Bool, SDKPass_Plain};
	g_hSDKCall_CBaseTrigger_IsTouching						= gd.CreateSDKCallOrFail(SDKCall_Entity, 	SDKConf_Signature, "CBaseTrigger::IsTouching", params2, sizeof(params2), true, ret5);

	delete gd;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}