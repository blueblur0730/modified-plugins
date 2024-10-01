#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <midhook>
#include <left4dhooks>
#include <colors>

#define DEBUG			   		0
#define GAMEDATA_FILE	   		"l4d2_stucked_tank_teleport"
#define ADDRESS_NAME	   		"TankAttack::Update__OnSuicide"
#define SDKCALL_FUNCTION   		"CBaseEntity::GetBaseEntity"
#define TRANSLATION_FILE   		"l4d2_stucked_tank_teleport.phrases"
#define TELEPORT_NOTICE_SOUND 	"ui/pickup_secret01.wav"
#define NAV_MESH_HEIGHT	   		20.0

#define PLUGIN_VERSION	   		"1.3"

int g_iTankCount = 0;
bool g_bHasTeleported[MAXPLAYERS + 1] = { false, ... };

MidHook		  g_hMidHook = null;
Handle		  g_hSDKCall_GetBaseEntity = null;
GlobalForward g_hFWD_OnTankSuicide;

ConVar
	g_hCvar_TeleportTimer,
	g_hCvar_ShouldTeleport,
	g_hCvar_SuicideDamage,
	g_hCvar_PathSearchCount,
	g_hCvar_ShouldCheckVisibility,
	g_hCvar_TeleportDistance;

ConVar
	g_hCvar_NoticeSound,
	g_hCvar_HighlightTank,
	g_hCvar_HighLightTime;

public Plugin myinfo =
{
	name = "[L4D2] Stucked Tank Teleport",
	author	= "blueblur, 东",
	description = "MidHook to prevent stucked tank from death and teleport them.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_hFWD_OnTankSuicide = new GlobalForward("MidHook_OnTankSuicide", ET_Event, Param_Cell);

	return APLRes_Success;
}

public void OnPluginStart()
{
	InitGameData();
	LoadTranslation(TRANSLATION_FILE);

	CreateConVar("l4d2_stucked_tank_teleport_version", PLUGIN_VERSION, "Version of the plugin.", FCVAR_NOTIFY | FCVAR_DEVELOPMENTONLY | FCVAR_DONTRECORD);

	// core
	g_hCvar_TeleportTimer = CreateConVar("l4d2_stucked_tank_teleport_timer", "3.0", "Teleport the tank after stoping the suicide in this seconds.", _, true, 0.1);
	g_hCvar_ShouldTeleport = CreateConVar("l4d2_stucked_tank_teleport_should_teleport", "1", "Should teleport the tank or not. Set 0 will allow the tank to suicide.", _, true, 0.0, true, 1.0);
	g_hCvar_SuicideDamage = CreateConVar("l4d2_stucked_tank_teleport_suicide_damage", "0.0", "How many damage the tank should be panished after stucked for too long.", _, true, 0.0);
	g_hCvar_PathSearchCount = CreateConVar("l4d2_stucked_tank_teleport_path_search_count", "20", "How many times to search for a spawn point to teleport the tank.", _, true, 1.0);
	g_hCvar_ShouldCheckVisibility = CreateConVar("l4d2_stucked_tank_teleport_should_check_visibility", "0", "Should check the visibility from tank to survivors of the spawn point or not.", _, true, 0.0, true, 1.0);
	g_hCvar_TeleportDistance = CreateConVar("l4d2_stucked_tank_teleport_distance", "1000.0", "Distance from the choosen survivor to make a spawn point the tank. Recommended: 500.0 < x < 2000.0", _, true, 1.0);

	// misc
	g_hCvar_NoticeSound = CreateConVar("l4d2_stucked_tank_teleport_notice_sound", "1", "Play notice sound when the tank is teleported.", _, true, 0.0, true, 1.0);
	g_hCvar_HighlightTank = CreateConVar("l4d2_stucked_tank_teleport_highlight_tank", "1", "Highlight the tank when it is teleported.", _, true, 0.0, true, 1.0);
	g_hCvar_HighLightTime = CreateConVar("l4d2_stucked_tank_teleport_highlight_time", "3.0", "Time to highlight the tank when it is teleported.", _, true, 0.1);

	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("tank_killed", Event_TankDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

#if DEBUG
	RegAdminCmd("sm_checkhook", Cmd_CheckHook, ADMFLAG_ROOT, "Check if the hook is enabled or not.");
#endif
}

#if DEBUG
Action Cmd_CheckHook(int client, int args)
{
	ReplyToCommand(client, "### Hook States: %s", g_hMidHook.Enabled ? "Enabled" : "Disabled");
	return Plugin_Handled;
}
#endif

public void OnPluginEnd()
{
	if (g_hMidHook.Enabled)
		g_hMidHook.Disable();

	if (g_hMidHook)
		delete g_hMidHook;
}

public void OnMapStart()
{
	PrecacheSound(TELEPORT_NOTICE_SOUND);
}

//--------
// Events
//--------

void Event_TankSpawn(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

#if DEBUG
	PrintToServer("### Event: TankSpawn called. client: %d", client);
#endif

	if (!IsTank(client))
		return;

	g_iTankCount++;
	g_bHasTeleported[client] = false;	// just in case, initialize it.

	ToggleHook(true);
}

void Event_TankDeath(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

#if DEBUG
	PrintToServer("### Event: TankKilled called. client: %d", client);
#endif

	if (!IsTank(client))
		return;

	g_iTankCount--;
	g_bHasTeleported[client] = false;	// those died are removed.

	ToggleHook(false);
}

// reset count. if tank crashes survivors it will be no tank on the new round.
void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	g_iTankCount = 0;

	for (int i = 1; i <= MaxClients; i++)
		g_bHasTeleported[i] = false;
}

void ToggleHook(bool bShouldHook)
{
	// multiple tank exsists or already existed one, do not enable/disable the hook again.
	if (g_iTankCount >= 1)
		return;

	if (bShouldHook)
	{
		if (!g_hMidHook.Enable())
			LogError("Failed to enable midhook. Tank Count: %d", g_iTankCount);
#if DEBUG
		PrintToServer("### MidHook: Enabled.");
#endif
	}
	else
	{
		if (!g_hMidHook.Disable())
			LogError("Failed to disable midhook. Tank Count: %d", g_iTankCount);
#if DEBUG
		PrintToServer("### MidHook: Disabled.");
#endif
	}
}

//-------------------
// Mid Function Hook
//-------------------

/**
 * This part is completely depended on MidHook extension by Scag. Big Thanks for him to make this possible.
 * Tanks get suicided when they are stucked for too long, but this is happened inside a complex function: TankAttack::Update.
 * By simply detouring and patching this function is quite hacky, which needs a lot more steps.
 * By the way we make our own timer detection using sourcemod, which it is not accurate and resource consuming.
 * This extension resolves the both. It is a effective way to handle the little things in a giant.
 */

/**
 	// TankAttack::Update(Tank *,float)      this            = dword ptr  8		// TankAttack *
	// TankAttack::Update(Tank *,float)      arg_4           = dword ptr  0Ch	// Tank *  		// wont work for sdkcall, reason unknow.
	// TankAttack::Update(Tank *,float)      arg_8           = dword ptr  10h	// CMultiPlayerAnimState ** (a4) // this turns out is a CBaseEntity pointer in the view of L4D1 binaries.
	
	CTakeDamageInfo::CTakeDamageInfo(
	(CTakeDamageInfo *)&v117,
	(CBaseEntity *)a4,
	(CBaseEntity *)a4,
	(float)(int)a4[64],
	2,
	0);

	CTakeDamageInfo( CBaseEntity *pInflictor, CBaseEntity *pAttacker, float flDamage, int bitsDamageType, int iKillType = 0 );

	As you can see this damage is coming from tank itself.
*/

void OnTankSuicide(MidHookRegisters regs)
{
#if DEBUG
	PrintToServer("### MidHook: OnTankSuicide called.");
#endif
	Address pAdr = regs.Load(DHookRegister_EBP, 0x10, NumberType_Int32);

	// And I really get exhusted with this. too dumb.
	// The purpose we call CBaseEntity::GetBaseEntity is to let sourcemod set the return type as CBaseEntity to get the actual client index.
	// which is to convey the address to client index.
	// https://forums.alliedmods.net/showthread.php?t=278009
	int tank = SDKCall(g_hSDKCall_GetBaseEntity, pAdr);

	float flDamage = regs.GetFloat(DHookRegister_XMM0);

#if DEBUG
	// works. the damage should be equal to tank's health. e.g. 4000.0 for normal.
	PrintToServer("### MidHook: TakeDamage: %f", flDamage);
#endif

	// what awaits for those not choose to teleport is only death.
	// v1.2 edit: seems that tank still gets 'suiciding' multiple times after teleportation. so there is still a need to check here.
	if (g_hCvar_ShouldTeleport.BoolValue)
	{
		// only do reduction once. in case the damage getting overlapping.
		if (!g_bHasTeleported[tank])
		{
			flDamage = g_hCvar_SuicideDamage.FloatValue;

			// reduce the damage.
			regs.SetFloat(DHookRegister_XMM0, flDamage);
		}
	}

	// only call once.
	if (!g_bHasTeleported[tank])
	{
		Call_StartForward(g_hFWD_OnTankSuicide);
		Call_PushCell(tank);
		Call_Finish();
	}

#if DEBUG
	PrintToServer("### MidHook: Tank: %d", tank);
#endif

	CPrintToChatAll("%t", "TeleportTank", g_hCvar_TeleportTimer.FloatValue);
	CreateTimer(g_hCvar_TeleportTimer.FloatValue, Timer_TeleportTank, tank);
}

Action Timer_TeleportTank(Handle timer, int client)
{
	// only teleport once.
	if (!g_bHasTeleported[client])
		TeleportTank(client);

	return Plugin_Handled;
}

//---------------
// Teleport Tank
//---------------

/**
 * Everything about teleportation is done by 东, big shout out to him.
 * https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/addons/sourcemod/scripting/AnneHappy/l4d2_Anne_stuck_tank_teleport.sp
*/

void TeleportTank(int client)
{
	float fSpawnPos[3] = { 0.0 }, fSurvivorPos[3] = { 0.0 };
	float fDirection[3] = { 0.0 }, fEndPos[3] = { 0.0 };
	float fMins[3] = { 0.0 }, fMaxs[3] = { 0.0 };
	int	  iTargetSurvivor = GetRandomSurvivor(1, -1);
	if (IsValidSurvivor(iTargetSurvivor))
	{
		// make a coordinate based on a random survivor's position.
		GetClientEyePosition(iTargetSurvivor, fSurvivorPos);

		float fTeleportDistance = g_hCvar_TeleportDistance.FloatValue;

		fMins[0]	  = fSurvivorPos[0] - fTeleportDistance;
		fMaxs[0]	  = fSurvivorPos[0] + fTeleportDistance;

		fMins[1]	  = fSurvivorPos[1] - fTeleportDistance;
		fMaxs[1]	  = fSurvivorPos[1] + fTeleportDistance;

		fMaxs[2]	  = fSurvivorPos[2] + fTeleportDistance;
		fDirection[0] = 90.0;
		fDirection[1] = fDirection[2] = 0.0;

		// first attempt to find a random position in this coordinate.
		fSpawnPos[0]				  = GetRandomFloat(fMins[0], fMaxs[0]);
		fSpawnPos[1]				  = GetRandomFloat(fMins[1], fMaxs[1]);
		fSpawnPos[2]				  = GetRandomFloat(fSurvivorPos[2], fMaxs[2]);

		// check count should not be static in case there are multiple tanks.
		int count					  = 0;

		// try at least this times to find a valid position. if all attempts fail, tank will be forced to die.
		while (CheckDistance(fSpawnPos) || !IsOnValidMesh(fSpawnPos) || IsPlayerStuck(fSpawnPos))
		{
			// give up now, no place to hold you !
			count++;
			if (count > g_hCvar_PathSearchCount.IntValue)
				break;

			// try again with a new position on each searching failure.
			fSpawnPos[0] = GetRandomFloat(fMins[0], fMaxs[0]);
			fSpawnPos[1] = GetRandomFloat(fMins[1], fMaxs[1]);
			fSpawnPos[2] = GetRandomFloat(fSurvivorPos[2], fMaxs[2]);

			TR_TraceRay(fSpawnPos, fDirection, MASK_SOLID, RayType_Infinite);
			if (TR_DidHit())
			{
				// let's bring these result to the next check circle.
				TR_GetEndPosition(fEndPos);
				fSpawnPos = fEndPos;
				fSpawnPos[2] += NAV_MESH_HEIGHT;
			}
		}

		// now we have the valid position in this times. let's find the NavArea to teleport.
		if (count <= g_hCvar_PathSearchCount.IntValue)
		{
			for (int i = 0; i < MaxClients; i++)
			{
				if (!IsValidSurvivor(i))
					continue;

				// re-retrieve the survivor's position and put this point to the ground.
				GetClientEyePosition(i, fSurvivorPos);
				fSurvivorPos[2] -= 60.0;

				// get the NavArea of the spawn position and the survivor's position.
				Address nav1 = L4D_GetNearestNavArea(fSpawnPos, 120.0, false, false, false, 3);
				Address nav2 = L4D_GetNearestNavArea(fSurvivorPos, 120.0, false, false, false, 3);

				// make sure that these two NavAreas is connected for tank to approach.
				if (L4D2_NavAreaBuildPath(nav1, nav2, fTeleportDistance * 1.73, L4D_TEAM_INFECTED, false) && GetVectorDistance(fSurvivorPos, fSpawnPos) >= 400.0 && nav1 != nav2)
				{
					// finally this is a desired position to teleport. let's do it.
					TeleportEntity(client, fSpawnPos, NULL_VECTOR, NULL_VECTOR);

					// HEY THERE IS A GIFT FOR YOU!
					if (g_hCvar_NoticeSound.BoolValue)
						EmitSoundToAll(TELEPORT_NOTICE_SOUND);

					if (g_hCvar_HighlightTank.BoolValue)
						SetGlow(client);

					// this this tank been teleported.
					g_bHasTeleported[client] = true;

					// after teleport, set a new target for the tank.
					int newtarget = GetClosetMobileSurvivor(client);
					if (IsValidSurvivor(newtarget))
					{
						// reset the bot tank's action, find the new target to attack.
						L4D2_CommandABot(client, newtarget, BOT_CMD_RESET);
						L4D2_CommandABot(client, newtarget, BOT_CMD_ATTACK);
					}
				}
			}
		}
		else
		{
			ForcePlayerSuicide(client);
			CPrintToChatAll("%t", "FailedToTeleport");
		}
	}
}

void SetGlow(int entity)
{
	L4D2_SetEntityGlow(entity, L4D2Glow_Constant, 0, 0, { 255, 255, 255 }, false);
	CreateTimer(g_hCvar_HighLightTime.FloatValue, Timer_RemoveGlow, entity);
}

Action Timer_RemoveGlow(Handle timer, int entity)
{
	L4D2_RemoveEntityGlow(entity);
	return Plugin_Handled;
}

//-----------------------------
// Helper and method functions
//-----------------------------

/**
 * Everything about these methods functions are done by 东 and 夜羽真白, big shout out to them.
 * https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/addons/sourcemod/scripting/AnneHappy/l4d2_Anne_stuck_tank_teleport.sp
 * https://github.com/GlowingTree880/L4D2_LittlePlugins/blob/main/lib/treeutil.inc
*/

// check if teleported position is in range of 400.0 from at least one survivor's position.
bool CheckDistance(float spawnpos[3])
{
	static float pos[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidSurvivor(i) && IsPlayerAlive(i))
		{
			// considering resource consumption, we will not use trace ray to check visibility.
			GetClientEyePosition(i, pos);
			if (GetVectorDistance(spawnpos, pos) < 400.0)
			{
				if (g_hCvar_ShouldCheckVisibility.BoolValue)
				{
					if (PosIsVisibleTo(i, spawnpos))
						return true;
				}
				else
				{
					return true;
				}
			}	
		}
	}

	return false;
}

// check if the position is visible to the client. note: this is optional.
stock bool PosIsVisibleTo(int client, const float targetposition[3])
{
	bool   			isVisible = false;
	static float 	position[3], vAngles[3], vLookAt[3], spawnPos[3];
	GetClientEyePosition(client, position);
	MakeVectorFromPoints(targetposition, position, vLookAt);
	GetVectorAngles(vLookAt, vAngles);
	Handle trace = TR_TraceRayFilterEx(targetposition, vAngles, MASK_VISIBLE, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		static float vStart[3];
		TR_GetEndPosition(vStart, trace);
		if ((GetVectorDistance(targetposition, vStart, false) + 75.0) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true;
		}
		else
		{
			spawnPos = targetposition;
			spawnPos[2] += 20.0;
			MakeVectorFromPoints(spawnPos, position, vLookAt);
			GetVectorAngles(vLookAt, vAngles);
			Handle trace2 = TR_TraceRayFilterEx(spawnPos, vAngles, MASK_VISIBLE, RayType_Infinite, TraceFilter, client);
			if (TR_DidHit(trace2))
			{
				TR_GetEndPosition(vStart, trace2);
				if ((GetVectorDistance(spawnPos, vStart, false) + 75.0) >= GetVectorDistance(position, spawnPos))
					isVisible = true;
			}
			else
			{
				isVisible = true;
			}

			delete trace2;
		}
	}
	else
	{
		isVisible = true;
	}

	delete trace;
	return isVisible;
}

bool TraceFilter(int entity, int contentsMask, any data)
{
	return (entity == data || (entity >= 1 && entity <= MaxClients)) ? false : true;
}

// check if the position is on valid mesh.
bool IsOnValidMesh(float fReferencePos[3])
{
	Address pNavArea = L4D2Direct_GetTerrorNavArea(fReferencePos);
	return (pNavArea != Address_Null && !(L4D_GetNavArea_SpawnAttributes(pNavArea) & NAV_SPAWN_CHECKPOINT)) ? true : false;
}

// check if the spawn position will stuck the player.
bool IsPlayerStuck(float fSpawnPos[3])
{
	// almost every survivor has the same size ?
	static const float fClientMinSize[3] = { -16.0, -16.0, 0.0 };
	static const float fClientMaxSize[3] = { 16.0, 16.0, 72.0 };

	static bool		   bHit;
	static Handle	   hTrace;

	hTrace = TR_TraceHullFilterEx(fSpawnPos, fSpawnPos, fClientMinSize, fClientMaxSize, MASK_PLAYERSOLID, TraceFilter_Stuck);
	bHit   = TR_DidHit(hTrace);

	delete hTrace;
	return bHit;
}

// filter the undesired entity on the path.
bool TraceFilter_Stuck(int entity, int contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return false;
	}
	else
	{
		static char sClassName[20];
		GetEntityClassname(entity, sClassName, sizeof(sClassName));
		if (strcmp(sClassName, "env_physics_blocker") == 0 && !EnvBlockType(entity))
			return false;
	}

	return true;
}

// block ai infected.
bool EnvBlockType(int entity)
{
	int BlockType = GetEntProp(entity, Prop_Data, "m_nBlockType");
	return (BlockType == 1 || BlockType == 2) ? true : false;
}

// find the closet, valid, alive, non-incapacitated, non-pinned survivor.
// credits to: 夜羽真白
stock int GetClosetMobileSurvivor(int client, int exclude_client = -1)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		int	  target	 = -1;
		float selfPos[3] = { 0.0 }, targetPos[3] = { 0.0 };
		GetClientAbsOrigin(client, selfPos);

		// find all survivors and push them into a list. we will use the list to sort them by distance and find the closet one.
		ArrayList targetList = new ArrayList(2);
		for (int newTarget = 1; newTarget <= MaxClients; newTarget++)
		{
			if (IsValidSurvivor(newTarget) && IsPlayerAlive(newTarget) && !IsClientIncapped(newTarget) && !L4D_GetPinnedInfected(newTarget) && newTarget != client && newTarget != exclude_client)
			{
				GetClientAbsOrigin(newTarget, targetPos);
				float dist = GetVectorDistance(selfPos, targetPos);
				targetList.Set(targetList.Push(dist), newTarget, 1);	// each cell has 2 blocks, client index and distance.
			}
		}

		// nothing found, return 0.
		if (targetList.Length == 0)
		{
			delete targetList;
			return 0;
		}

		// sort the list by distance, return the closet one.
		targetList.Sort(Sort_Ascending, Sort_Float);
		target = targetList.Get(0, 1);
		delete targetList;
		return target;
	}

	return 0;
}

bool IsValidSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == L4D_TEAM_SURVIVOR);
}

// are you the big guy ?
bool IsTank(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == 8)
			return true;
	}
	return false;
}

bool IsClientIncapped(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

//----------------
// Initialization
//----------------
stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}

void InitGameData()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd) SetFailState("Failed to load gamedata file \"" ... GAMEDATA_FILE... "\".");

	Address pAdr = gd.GetAddress(ADDRESS_NAME);
	if (pAdr == Address_Null) SetFailState("Failed to find address from section \"" ... ADDRESS_NAME... "\".");

	g_hMidHook = new MidHook(pAdr, OnTankSuicide, false);
	if (!g_hMidHook) SetFailState("Failed to create midhook.");

	// the purpose is to convey pointer address to client index.
	// CBaseEntity::GetBaseEntity(CBaseEntity *this)
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, SDKCALL_FUNCTION)) SetFailState("Failed to set SDK call signature \""...SDKCALL_FUNCTION... "\".");

	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKCall_GetBaseEntity = EndPrepSDKCall();

	if (!g_hSDKCall_GetBaseEntity) SetFailState("Failed to create SDK call for \""...SDKCALL_FUNCTION... "\".");

	delete gd;
}