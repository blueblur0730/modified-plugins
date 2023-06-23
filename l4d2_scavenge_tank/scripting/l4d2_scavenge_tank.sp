#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>
#include <readyup>
#undef REQUIRE_PLUGIN
#include <l4d_tank_control_eq>

#define CVAR_FLAGS FCVAR_NOTIFY

#define MAX_GASCANS 16
#define MAX_SURVIVORS 8
#define MAX_WITCHES 16

#define PLUGIN_NAME			"Scavenge Tank"
#define PLUGIN_AUTHOR		"Mrs. Campanula, Die Teetasse, modified by blueblur"
#define PLUGIN_DESC			"Allow to spawn tank in scavenge mode"
#define PLUGIN_VERSION		"1.0.12"
#define PLUGIN_URL			"http://forums.alliedmods.net/showthread.php?p=1058610"
#define PLUGIN_TAG			"[{olive}ScavTank{default}]"

#define SOUND_TANK 			"./music/tank/tank.wav"

/*
To Do:
- changing wandering witch spawning
- changing witch spawn logic -> Trace
- spawn arrays cvar = "1, 5, 16" and "0:20, 1:20"

Changelog:
v1.0.12:
- Added support to new syntax.
- Added support to translations.
- Added 3 cvars to control wether a specific event get spawned.

v1.0.11:
- rewrote tank logic
- little revision

v1.0.10:
- fixed bug that prevents the lottery from working

v1.0.9:
- added witch spawning (command, cvar, logic)
	if there are standing gascans without survivors and witches => spawn sitting witch
	else spawn a wandering witch at a autospawn position
- added notfication cvar
- fixed multiple count of one gas can

v1.0.8:
- fixed bugging can count on new map

v1.0.7:
- fixed possible error log for unhooking events if the gamemode changed
- (maybe) fixed tank sound

v1.0.6:
- fixed bug, where infected switched class on tank spawn without a reason

v1.0.5:
- changed logic
	if score tied tank is enabled a tank will spawn for the second team at 15 gas cans poured in
- changed name of tank spawn command
- added horde cvars, commands etc pp
- fixed bot tank

v1.0.4:
- fixed tank spawn
- added tank music on spawn
- added chat notification on spawn
- changed convar descriptions
- changed convar flags
- added gamecheck
- added version cvar
*/

public Plugin myinfo =
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESC,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

ConVar hNotification;

ConVar hHordeEnable;
ConVar hHordeAfterScoreTied;
ConVar hHordeAfterOvertime;
ConVar hHordeAfterCanCount;

ConVar hTankEnable;
ConVar hTankAfterScoreTied;
ConVar hTankAfterOvertime;
ConVar hTankAfterCanCount;

ConVar hWitchEnable;
ConVar hWitchAfterScoreTied;
ConVar hWitchAfterOvertime;
ConVar hWitchAfterCanCount;

bool bUnhook = false;
bool bOvertime;
bool bFirstTeam;
bool bPooredIn = false;

int nGasCount;
int Candidate;

public void OnPluginStart()
{
	char game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Scavenge Tank will only work with Left 4 Dead 2!");

	RegServerCmd("l4d2_scavengetank_force_tank_spawn", Server_ForceTankSpawn, "Force tank spawn");
	RegServerCmd("l4d2_scavengetank_force_horde_spawn", Server_ForceTankSpawn, "Force horde spawn");
	RegServerCmd("l4d2_scavengetank_force_witch_spawn", Server_ForceWitchSpawn, "Force witch spawn");

	CreateConVar("l4d2_scavengetank_version", PLUGIN_VERSION, "Scavenge tank version", CVAR_FLAGS|FCVAR_DONTRECORD);

	hNotification 			= CreateConVar("l4d2_scavengetank_notifications", "1", "Notify the players when something is spawned", CVAR_FLAGS);

	hHordeEnable 			= CreateConVar("l4d2_scavengetank_horde_enabled", "0", "Enable horde spawn?", CVAR_FLAGS);
	hHordeAfterOvertime 	= CreateConVar("l4d2_scavengetank_spawn_horde_after_overtime", "1", "Spawn horde after first overtime", CVAR_FLAGS);
	hHordeAfterScoreTied 	= CreateConVar("l4d2_scavengetank_spawn_horde_after_score_tied", "1", "Spawn horde after score tied (only for second team)", CVAR_FLAGS);
	hHordeAfterCanCount 	= CreateConVar("l4d2_scavengetank_spawn_horde_after_cans_count", "0", "Spawn horde after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);

	hTankEnable				= CreateConVar("l4d2_scavengetank_tank_enabled", "1", "Enable Tank Spawn?", CVAR_FLAGS);
	hTankAfterOvertime 		= CreateConVar("l4d2_scavengetank_spawn_tank_after_overtime", "0", "Spawn tank after first overtime", CVAR_FLAGS);
	hTankAfterScoreTied 	= CreateConVar("l4d2_scavengetank_spawn_tank_after_score_tied", "0", "Spawn tank after score tied (only for second team)", CVAR_FLAGS);
	hTankAfterCanCount 		= CreateConVar("l4d2_scavengetank_spawn_tank_after_cans_count", "5", "Spawn tank after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);

	hWitchEnable 			= CreateConVar("l4d2_scavengetank_witch_enable", "0", "Enable witch spawn?", CVAR_FLAGS);
	hWitchAfterOvertime 	= CreateConVar("l4d2_scavengetank_spawn_witch_after_overtime", "0", "Spawn witch after first overtime", CVAR_FLAGS);
	hWitchAfterScoreTied 	= CreateConVar("l4d2_scavengetank_spawn_witch_after_score_tied", "0", "Spawn witch after score tied (only for second team)", CVAR_FLAGS);
	hWitchAfterCanCount 	= CreateConVar("l4d2_scavengetank_spawn_witch_after_cans_count", "5", "Spawn witch after specified count of poured cans ( 0 to disable )", CVAR_FLAGS);

	LoadTranslations("l4d2_scavenge_tank.phrases")

	SetRandomSeed(GetTime());
}

public void OnAllPluginsLoaded()
{
	Candidate = GetTankSelection()
}

public void OnMapStart()
{
	if(L4D2_IsScavengeMode())
	{
		HookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_Pre);
		HookEvent("scavenge_round_halftime", Event_Halftime, EventHookMode_Pre);
		HookEvent("scavenge_score_tied", Event_ScoreTied, EventHookMode_Pre);
		HookEvent("begin_scavenge_overtime", Event_Overtime, EventHookMode_Pre);
		HookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_Pre);

		PrefetchSound(SOUND_TANK);
		PrecacheSound(SOUND_TANK);

		bUnhook = true;

		//fix for roundstart be triggered befor mapstart
		bOvertime = false;
		nGasCount = 0;
		bFirstTeam = true;
	}

	bUnhook = false;
}

public void OnMapEnd()
{
	if(bUnhook)
	{
		UnhookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_Pre);
		UnhookEvent("scavenge_round_halftime", Event_Halftime, EventHookMode_Pre);
		UnhookEvent("scavenge_score_tied", Event_ScoreTied, EventHookMode_Pre);
		UnhookEvent("begin_scavenge_overtime", Event_Overtime, EventHookMode_Pre);
		UnhookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_Pre);
	}
}

public Action Event_RoundStart(Handle event, char[] name, bool nobroadcast)
{
	bOvertime = false;
	nGasCount = 0;
	bFirstTeam = true;
	return Plugin_Continue;
}

public Action Event_Overtime(Handle event, char[] name, bool nobroadcast)
{
	if( !bOvertime )
	{
		if(GetConVarBool(hHordeAfterOvertime) && GetConVarBool(hHordeEnable))
			SpawnHorde();

		if(GetConVarBool(hTankAfterOvertime) && GetConVarBool(hTankEnable))
			SpawnTank();

		if(GetConVarBool(hWitchAfterOvertime) && GetConVarBool(hWitchEnable))
			SpawnWitch();

		bOvertime = true;
	}
	return Plugin_Continue;
}

public Action Event_Halftime(Handle event, char[] name, bool nobroadcast)
{
	bOvertime = false;
	nGasCount = 0;
	bFirstTeam = false;
	return Plugin_Continue;
}

public Action Event_ScoreTied(Handle event, char[] name, bool nobroadcast)
{
	if(GetConVarBool(hHordeAfterScoreTied) && GetConVarBool(hHordeEnable))
		SpawnHorde();

	if(GetConVarBool(hTankAfterScoreTied) && GetConVarBool(hTankEnable))
		SpawnTank();

	if(GetConVarBool(hWitchAfterScoreTied) && GetConVarBool(hWitchEnable))
		SpawnWitch();

	return Plugin_Continue;
}

public Action Event_GasCanPourCompleted(Handle event, char[] name, bool nobroadcast)
{
	if (bPooredIn == true) return Plugin_Continue;

	nGasCount++;

	if(nGasCount == 15 && !bFirstTeam)
	{
		if(GetConVarBool(hHordeAfterScoreTied) && GetConVarBool(hHordeEnable))
			SpawnHorde();

		if(GetConVarBool(hTankAfterScoreTied) && GetConVarBool(hTankEnable))
			SpawnTank();

		if(GetConVarBool(hWitchAfterScoreTied) && GetConVarBool(hWitchEnable))
			SpawnWitch();
	}

	int hordecount = GetConVarInt(hHordeAfterCanCount);
	int tankcount = GetConVarInt(hTankAfterCanCount);
	int witchcount = GetConVarInt(hWitchAfterCanCount);

	if(hordecount > 0 && (nGasCount % hordecount == 0))
		SpawnHorde();

	if(tankcount > 0 && (nGasCount % tankcount == 0))
		SpawnTank();

	if(witchcount > 0 && (nGasCount % witchcount == 0))
		SpawnWitch();

	bPooredIn = true;
	CreateTimer(0.5, PouredInDelay);

	return Plugin_Continue;
}

public Action PouredInDelay(Handle timer, any data)
{
	bPooredIn = false;
	return Plugin_Continue;
}

public Action Server_ForceHordeSpawn(int args)
{
	SpawnHorde();
	return Plugin_Continue;
}

public Action Server_ForceTankSpawn(int args)
{
	SpawnTank();
	return Plugin_Continue;
}

public Action Server_ForceWitchSpawn(int args)
{
	SpawnWitch();
	return Plugin_Continue;
}

/*
public void chooseTank(any data)
{
    //Let other plugins to override tank selection
    char sOverrideTank[64];
    sOverrideTank[0] = '\0';
    Call_StartForward(hForwardOnTankSelection);
    Call_PushStringEx(sOverrideTank, sizeof(sOverrideTank), SM_PARAM_STRING_UTF8, SM_PARAM_COPYBACK);
    Call_Finish();

    if (StrEqual(sOverrideTank, ""))
    {
        // Create our pool of players to choose from
        ArrayList infectedPool = new ArrayList(ByteCountToCells(64));
        addTeamSteamIdsToArray(infectedPool, L4D2Team_Infected);

        // If there is nobody on the infected team, return (otherwise we'd be stuck trying to select forever)
        if (GetArraySize(infectedPool) == 0)
        {
            delete infectedPool;
            return;
        }

        // Remove players who've already had tank from the pool.
        removeTanksFromPool(infectedPool, h_whosHadTank);

        // If the infected pool is empty, remove infected players from pool
        if (GetArraySize(infectedPool) == 0) // (when nobody on infected ,error)
        {
            ArrayList infectedTeam = new ArrayList(ByteCountToCells(64));
            addTeamSteamIdsToArray(infectedTeam, L4D2Team_Infected);
            if (GetArraySize(infectedTeam) > 1)
            {
                removeTanksFromPool(h_whosHadTank, infectedTeam);
                chooseTank(0);
            }
            else
            {
                queuedTankSteamId = "";
            }

            delete infectedTeam;
            delete infectedPool;
            return;
        }

        // Select a random person to become tank
        int rndIndex = GetRandomInt(0, GetArraySize(infectedPool) - 1);
        GetArrayString(infectedPool, rndIndex, queuedTankSteamId, sizeof(queuedTankSteamId));
        delete infectedPool;
    } else {
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), sOverrideTank);
    }
}
*/

public void SpawnHorde()
{
	int flags = GetCommandFlags("z_spawn");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(GetClientTeam(i) != 2) continue;

		SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
		FakeClientCommand(i, "z_spawn mob auto");
		SetCommandFlags("z_spawn", flags);
		break;
	}

	if (GetConVarInt(hNotification) == 1) CPrintToChatAll("%t", "SpawnHorde", PLUGIN_TAG);
	// %s A {orange}horde{default} spawned! Pay attention!
}

public void SpawnTank()
{
	int[] infectedAlive = new int[MaxClients];
	int infectedAliveCount = 0;
	int[] infectedDead = new int[MaxClients];
	int infectedDeadCount = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;

		// infected?
		if(GetClientTeam(i) == 3)
		{
			/*
			Dead:
				Alive: 0
				Ghost: 0
				LifeState: 1

			Waiting:
				Alive: 0
				Ghost: 0
				LifeState: 2

			Spawning:
				Alive: 1
				Ghost: 1
				LifeState: 0

			Alive:
				Alive: 1
				Ghost: 0
				LifeState: 0
			*/
			if (!IsPlayerAlive(i) || GetEntProp(i, Prop_Send, "m_isGhost") == 1)
			{
				// Dead / Waiting / Ghost
				infectedDead[infectedDeadCount] = i;
				infectedDeadCount++;
			}
			else {
				// Alive
				infectedAlive[infectedAliveCount] = i;
				infectedAliveCount++;
			}
		}
	}

	int chosenTank = -1;

	// Tank bot fix (if everyone is alive)
	if (infectedDeadCount < 1)
	{
		// choose tank
		int choice = GetRandomInt(0, infectedAliveCount-1);
		chosenTank = infectedAlive[choice];

		// move to spec and back
		ChangeClientTeam(chosenTank, 1);
		ChangeClientTeam(chosenTank, 3);
	}
	else
	{
		// somebody random spawns the tank
		int choice = GetRandomInt(0, infectedDeadCount-1);
		chosenTank = infectedDead[choice];
	}

	// spawn tank
	int flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	FakeClientCommand(chosenTank, "z_spawn tank auto");
	SetCommandFlags("z_spawn", flags);

	if (GetConVarInt(hNotification) == 1) CPrintToChatAll("%t", "SpawnTank", PLUGIN_TAG);
	// %s A {orange}tank{default} spawned! Be ready!
	EmitSoundToAll(SOUND_TANK);
}

public void SpawnWitch()
{
	int entitycount = GetEntityCount();
	int gascans = 0, i, j, possiblegascans = 0, survivors = 0, witches = 0;
	bool tempcan;
	float cans[MAX_GASCANS][3], entpos[MAX_GASCANS][3], survivorpos[MAX_SURVIVORS][3], witchespos[MAX_WITCHES][3];
	float z_entpos[MAX_GASCANS], z_survivorpos[MAX_SURVIVORS], z_witchespos[MAX_WITCHES];
	char entname[50];

	// find gascans and witches
	for (i = 1; i < entitycount; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, entname, sizeof(entname));

			/*
				m_iState:
					0 = standing
					2 = in survivor hands
			*/
			if (StrContains(entname, "weapon_gascan") > -1)
			{
				if (GetEntProp(i, Prop_Send, "m_iState") == 0)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", entpos[gascans]);

					// save the z-coordinate (height) special
					z_entpos[gascans] = entpos[gascans][2];
					entpos[gascans][2] = 0.0;
					gascans++;
				}
			}

			if (StrContains(entname, "witch") > -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", witchespos[witches]);
				z_witchespos[witches] = witchespos[witches][2];
				witchespos[witches][2] = 0.0;
				witches++;
			}
		}
	}

	//PrintToChatAll("Found %d gascans and %d witches!", gascans, witches);

	// find survivors
	for(i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(GetClientTeam(i) != 2) continue;

		GetEntPropVector(i, Prop_Send, "m_vecOrigin", survivorpos[survivors]);
		z_survivorpos[survivors] = survivorpos[survivors][2];
		survivorpos[survivors][2] = 0.0;
		survivors++;
	}

	//PrintToChatAll("Found %d survivors!", survivors);

	// find a gascan without survivors and witches nearby
	for (i = 0; i < gascans; i++)
	{
		tempcan = true;

		// survivors
		for (j = 0; j < survivors; j++)
		{
			// gascan survivor distance < 450.0 and gascan survivor height < 75.0
			if (FloatCompare(GetVectorDistance(entpos[i], survivorpos[j]), 450.0) == -1 && FloatCompare(FloatAbs(z_entpos[i] - z_survivorpos[j]), 75.0) == -1)
			{
				tempcan = false;
				break;
			}
		}

		// witches
		for (j = 0; j < witches; j++)
		{
			// gascan witch distance < 250.0 and gascan witch height < 75.0
			if (FloatCompare(GetVectorDistance(entpos[i], witchespos[j]), 250.0) == -1 && FloatCompare(FloatAbs(z_entpos[i] - z_witchespos[j]), 75.0) == -1)
			{
				tempcan = false;
				break;
			}
		}

		// if possible save pos
		if (tempcan == true)
		{
			cans[possiblegascans] = entpos[i];
			cans[possiblegascans][2] = z_entpos[i];
			possiblegascans++;
		}
	}

	//PrintToChatAll("Found %d possible gascans!", possiblegascans);

	int choice;
	// no possible cans?
	if (possiblegascans == 0)
	{
		// spawn wandering witch
		SpawnWitchAtPos(false);

		if (GetConVarInt(hNotification) == 1) CPrintToChatAll("%t", "SpawnWitch", PLUGIN_TAG);
		// %s A {orange}witch{default} spawned! She is wandering around!
	}
	// spawn to gascan randomly
	else
	{
		choice = GetRandomInt(0, possiblegascans-1);
		SpawnWitchAtPos(true, cans[choice]);

		if (GetConVarInt(hNotification) == 1) CPrintToChatAll("%t", "SpawnWitch2", PLUGIN_TAG);
		// %s A {orange}witch{default} spawned! Flashlights out!
	}


}

void SpawnWitchAtPos(bool ispos, float pos[3] = {0.0, 0.0, 0.0})
{
	int commander = -1;
	int flags_pos, flags_spawn;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i)) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(GetClientTeam(i) != 2) continue;

		commander = i;
		break;
	}

	// no commander => no suvivors => leave
	if (commander == -1) return;

	if (ispos == true)
	{
		// change the spawn (x, y) a little bit so the witch will not spawn on top of a gas can
		pos[0] += 25.0;
		pos[1] += 25.0;

		// enable pos
		flags_pos = GetCommandFlags("z_spawn_const_pos");
		SetCommandFlags("z_spawn_const_pos", flags_pos & ~FCVAR_CHEAT);
		FakeClientCommand(commander, "z_spawn_const_pos %f %f %f", pos[0], pos[1], pos[2]);

		// spawn
		flags_spawn = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", flags_spawn & ~FCVAR_CHEAT);
		FakeClientCommand(commander, "z_spawn witch");
		SetCommandFlags("z_spawn", flags_spawn);

		// disable
		FakeClientCommand(commander, "z_spawn_const_pos");
		SetCommandFlags("z_spawn_const_pos", flags_pos);
	}
	else
	{
		// enable wandering
		flags_pos = GetCommandFlags("witch_force_wander");
		SetCommandFlags("witch_force_wander", flags_pos & ~FCVAR_CHEAT);
		SetConVarInt(FindConVar("witch_force_wander"), 1);

		// spawn random
		flags_spawn = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", flags_spawn & ~FCVAR_CHEAT);
		FakeClientCommand(commander, "z_spawn witch auto");
		SetCommandFlags("z_spawn", flags_spawn);

		CreateTimer(1.0, WitchWanderingDelay);
	}
}

public Action WitchWanderingDelay(Handle timer)
{
		// disable wandering
		SetConVarInt(FindConVar("witch_force_wander"), 0);
		int flags_pos = GetCommandFlags("witch_force_wander");
		SetCommandFlags("witch_force_wander", flags_pos & FCVAR_CHEAT);
		return Plugin_Handled;
}