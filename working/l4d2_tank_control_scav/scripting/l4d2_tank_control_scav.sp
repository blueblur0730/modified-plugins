#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>
#include <scavenge_func>
#undef REQUIRE_PLUGIN
#include <caster_system>

#define CVAR_FLAGS FCVAR_NOTIFY

#define MAX_GASCANS 16
#define MAX_SURVIVORS 8
#define MAX_WITCHES 16

#define PLUGIN_NAME			"[L4D2] Scavenge Tank Control"
#define PLUGIN_AUTHOR		"Mrs. Campanula, Die Teetasse, Conttributors from l4d_tank_control_eq, modified by blueblur"
#define PLUGIN_DESC			"Allow to spawn and control tank in scavenge mode"
#define PLUGIN_VERSION		"1.1.0"
#define PLUGIN_URL_OLD		"http://forums.alliedmods.net/showthread.php?p=1058610"
#define PLUGIN_URL_NEW      ""

/*
Changelog:
v1.1.0:
- rewrote whole plugin, merged most part from l4d_tank_control_eq, delete function to spawn horde and witch.
- now tank spawns only if the gascan score reached the score we've gotten randomly on round start.

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

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_VALID_CASTER(%1)     (IS_VALID_INGAME(%1) && casterSystemAvailable && IsClientCaster(%1))

#define SOUND_TANK 			"./music/tank/tank.wav"

public Plugin myinfo =
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESC,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL_NEW,
}

enum L4D2Team
{
    L4D2Team_None = 0,
    L4D2Team_Spectator,
    L4D2Team_Survivor,
    L4D2Team_Infected
}

//#define DANG "ui/pickup_secret01.wav"

ConVar hTankEnable;
ConVar hTankPrint;

bool bPooredIn = false;
bool casterSystemAvailable;

int nGasCount;
int RandomGasCan;

char queuedTankSteamId[64];

ArrayList h_whosHadTank;

enum ZClass
{
    ZClass_Smoker = 1,
    ZClass_Boomer = 2,
    ZClass_Hunter = 3,
    ZClass_Spitter = 4,
    ZClass_Jockey = 5,
    ZClass_Charger = 6,
    ZClass_Witch = 7,
    ZClass_Tank = 8
}

public void OnPluginStart()
{
	// Check Game
	char game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Scavenge Tank will only work with Left 4 Dead 2!");

	// Initialise the tank arrays/data values
    h_whosHadTank   = new ArrayList(ByteCountToCells(64));

	// ConVars
	hTankEnable	    = CreateConVar("l4d2_tank_control_scav_enabled", "1", "Enable Tank Spawn?", CVAR_FLAGS);
	hTankPrint 	    = CreateConVar("tankcontrol_print_all", "0", "Who gets to see who will become the tank? (0 = Infected, 1 = Everyone)");

	// Translations
	LoadTranslations("l4d2_tank_control_scav.phrases");
	CreateConVar("l4d2_tank_control_scav_version", PLUGIN_VERSION, "Scavenge tank version", CVAR_FLAGS|FCVAR_DONTRECORD);

    CheckEnableStatus();
}

public Action CheckEnableStatus()
{
    if(!IsScavengeMode() && !GetConVarBool(hTankEnable))
        return Plugin_Handled;
    else
        return Plugin_Continue;
}

public void OnAllPluginsLoaded()
{
	casterSystemAvailable = LibraryExists("caster_system");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "caster_system")) casterSystemAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "caster_system")) casterSystemAvailable = false;
}

public void OnMapStart()
{
	if(IsScavengeMode())
	{
		HookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_Pre);
		HookEvent("scavenge_round_finished", Event_RoundFinished, EventHookMode_PostNoCopy);
		HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
		HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_PostNoCopy);
		HookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_Pre);

		//PrecacheSound(DANG);

		//fix for roundstart be triggered befor mapstart
		nGasCount = 0;
	}
}

/**
 * When a player wants to find out whos becoming tank,
 * output to them.
 */
 
public Action Tank_Cmd(int client, int args)
{
    if (!IsClientInGame(client)) 
      return Plugin_Handled;

    int tankClientId;
    char tankClientName[128];
    
    // Only output if we have a queued tank
    if (! strcmp(queuedTankSteamId, ""))
    {
        return Plugin_Handled;
    }
    
    tankClientId = getInfectedPlayerBySteamId(queuedTankSteamId);
    if (tankClientId != -1)
    {
        GetClientName(tankClientId, tankClientName, sizeof(tankClientName));
        
        // If on infected, print to entire team
        if (view_as<L4D2Team>(GetClientTeam(client)) == L4D2Team_Infected || (casterSystemAvailable && IsClientCaster(client)))
        {
            if (client == tankClientId) CPrintToChat(client, "%t", "YouAreTheTank");
            else CPrintToChat(client, "%t", "TankSelection", tankClientName);
        }
    }
    
    return Plugin_Handled;
}

public void Event_RoundStart(Event hEvent, char[] name, bool nobroadcast)
{
	nGasCount = 0;
	RandomGasCan = GetRandomInt(10, GetScavengeItemsGoal());		// starting from 10, in case the tank spawns too early
	CreateTimer(10.0, newGame);
}

public void Event_PlayerLeftStartArea(Event hEvent, const char[] eName, bool dontBroadcast)
{
    SetTank(0);
    outputTankToAll(0);
}

public void Event_RoundFinished(Event hEvent, char[] name, bool nobroadcast)
{
	RandomGasCan = 0;		// reset gascan count
	queuedTankSteamId = "";
}

public Action Event_GasCanPourCompleted(Event hEvent, char[] name, bool nobroadcast)
{
	if (bPooredIn == true) return Plugin_Continue;

	nGasCount++;

	if(RandomGasCan % nGasCount == 0)
	{
		CreateTimer(3.0, SpawnTank);
	}
	
/*
	if(nGasCount == 15 && !bFirstTeam)
	{
		if(GetConVarBool(hTankAfterScoreTied) && GetConVarBool(hTankEnable))
			SetTank(0);
	}

	int tankcount = GetConVarInt(hTankAfterCanCount);

	if(tankcount > 0 && (nGasCount % tankcount == 0))
		SetTank(0);
*/

	bPooredIn = true;
	CreateTimer(0.5, PouredInDelay);

	return Plugin_Continue;
}

/**
 * When the queued tank switches teams, choose a new one
 */
 
public void Event_PlayerTeam(Event hEvent, const char[] name, bool dontBroadcast)
{
	L4D2Team oldTeam = view_as<L4D2Team>(hEvent.GetInt("oldteam"));
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	char tmpSteamId[64];

	if (client && oldTeam == view_as<L4D2Team>(L4D2Team_Infected))
	{
		GetClientAuthId(client, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
		if (strcmp(queuedTankSteamId, tmpSteamId) == 0)
		{
			RequestFrame(SetTank, 0);
			RequestFrame(outputTankToAll, 0);
		}
	}
}

/**
 * When the tank dies, requeue a player to become tank (for finales)
 */
 
public void PlayerDeath_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    int zombieClass = 0;
    int victimId = hEvent.GetInt("userid");
    int victim = GetClientOfUserId(victimId);
    
    if (victimId && IsClientInGame(victim)) 
    {
        zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        if (view_as<ZClass>(zombieClass) == ZClass_Tank) 
        {
            SetTank(0);
        }
    }
}

public void TankKilled_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
    SetTank(0);
}

public Action newGame(Handle timer)
{
	int teamAScore = GetScavengeTeamScore(2, GetScavengeRoundNumber());		// survivor
	int teamBScore = GetScavengeTeamScore(3, GetScavengeRoundNumber());		// infected

	// If it's a new game, reset the tank pool
	if (teamAScore == 0 && teamBScore == 0 && GetScavengeRoundNumber() == 1)
	{
		h_whosHadTank.Clear();
		queuedTankSteamId = "";
	}

	return Plugin_Stop;
}

public Action PouredInDelay(Handle timer, any data)
{
	bPooredIn = false;
	return Plugin_Continue;
}

public void SetTank(any data)
{
    char sOverrideTank[64];
    sOverrideTank[0] = '\0';

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
                SetTank(0);
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

public Action SpawnTank(Handle Timer)
{
	//EmitSoundToAll(DANG);

	// spawn tank
	int flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	FakeClientCommand(getInfectedPlayerBySteamId(queuedTankSteamId), "z_spawn tank auto");
	SetCommandFlags("z_spawn", flags);

	return Plugin_Handled;
}

/**
 * Make sure we give the tank to our queued player.
 */
 
public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStatis)
{    
    // Reset the tank's frustration if need be
    if (! IsFakeClient(tank_index)) 
    {
        PrintHintText(tank_index, "%t", "RageRefilledHintText");
        for (int i = 1; i <= MaxClients; i++) 
        {
            if (! IsClientInGame(i) || GetClientTeam(i) != 3)
                continue;

            if (tank_index == i) CPrintToChat(i, "%t", "BotRageRefilledText");
            else CPrintToChat(i, "%t", "HumanRageRefilledText", tank_index);
        }
        
        SetTankFrustration(tank_index, 100);
        L4D2Direct_SetTankPassedCount(L4D2Direct_GetTankPassedCount() + 1);
        
        return Plugin_Handled;
    }
    
    //Allow third party plugins to override tank selection
    char sOverrideTank[64];
    sOverrideTank[0] = '\0';

    if (!StrEqual(sOverrideTank, "")) {
        strcopy(queuedTankSteamId, sizeof(queuedTankSteamId), sOverrideTank);
    }

    // If we don't have a queued tank, choose one
    if (! strcmp(queuedTankSteamId, ""))
        SetTank(0);

/*
    // Mark the player as having had tank
    if (strcmp(queuedTankSteamId, "") != 0)
    {
        setTankTickets(queuedTankSteamId, 20000);
        PushArrayString(h_whosHadTank, queuedTankSteamId);
    }
*/

    return Plugin_Continue;
}

/**
 * Output who will become tank
 */
 
public void outputTankToAll(any data)
{
    char tankClientName[MAX_NAME_LENGTH];
    int tankClientId = getInfectedPlayerBySteamId(queuedTankSteamId);
    
    if (tankClientId != -1)
    {
        GetClientName(tankClientId, tankClientName, sizeof(tankClientName));
        if (GetConVarBool(hTankPrint))
        {
            CPrintToChatAll("%t", "TankSelection", tankClientName);        //{red}<{default}Tank Selection{red}> {olive}%s {default}will become the {red}Tank!
        }
        else
        {
            for (int i = 1; i <= MaxClients; i++) 
            {
                if (!IS_VALID_INFECTED(i) && !IS_VALID_CASTER(i))
                continue;

                if (tankClientId == i) CPrintToChat(i, "%t", "YouAreTheTank");       //{red}<{default}Tank Selection{red}> {green}You {default}will become the {red}Tank{default}!
                else CPrintToChat(i, "%t", "TankSelection", tankClientName);
            }
        }
    }
	
	CPrintToChatAll("%t", "GasCanSelection", RandomGasCan);
}

stock void PrintToInfected(const char[] Message, any ... )
{
    char sPrint[256];
    VFormat(sPrint, sizeof(sPrint), Message, 2);

    for (int i = 1; i <= MaxClients; i++) 
    {
        if (!IS_VALID_INFECTED(i) && !IS_VALID_CASTER(i)) 
        { 
            continue; 
        }

        CPrintToChat(i, "{default}%s", sPrint);
    }
}

public void removeTanksFromPool(ArrayList steamIdTankPool, ArrayList tanks)
{
    int index;
    char steamId[64];
    
    int ArraySize = GetArraySize(tanks);
    for (int i = 0; i < ArraySize; i++)
    {
        GetArrayString(tanks, i, steamId, sizeof(steamId));
        index = FindStringInArray(steamIdTankPool, steamId);
        
        if (index != -1)
        {
            RemoveFromArray(steamIdTankPool, index);
        }
    }
}

public void addTeamSteamIdsToArray(ArrayList steamIds, L4D2Team team)
{
    char steamId[64];

    for (int i = 1; i <= MaxClients; i++)
    {
        // Basic check
        if (IsClientInGame(i) && ! IsFakeClient(i))
        {
            // Checking if on our desired team
            if (view_as<L4D2Team>(GetClientTeam(i)) != team)
                continue;
        
            GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
            PushArrayString(steamIds, steamId);
        }
    }
}

public int getInfectedPlayerBySteamId(const char[] steamId) 
{
    char tmpSteamId[64];
   
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 3)
            continue;
        
        GetClientAuthId(i, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));     
        
        if (strcmp(steamId, tmpSteamId) == 0)
            return i;
    }
    
    return -1;
}

void SetTankFrustration(int iTankClient, int iFrustration) {
    if (iFrustration < 0 || iFrustration > 100) {
        return;
    }
    
    SetEntProp(iTankClient, Prop_Send, "m_frustration", 100-iFrustration);
}