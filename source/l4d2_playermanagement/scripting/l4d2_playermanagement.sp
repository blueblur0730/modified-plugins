#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define ZC_TANK 8
#define GAMEDATA_FILE "l4d2_playermanagement"
#define TRANSLATION_FILE_COMMON "common.phrases"
#define TRANSLATION_FILE "l4d2_playermanagement.phrases"
#define OFFSET_NAME "CTerrorPlayer->m_queuedPummelAttacker"
#define SDKCALL_FUNCTION "CTerrorPlayer::GoAwayFromKeyboard"
#define BOT_NAME "k9Q6CK42"

#define PLUGIN_VERSION "1.1.1" // 7

// This is a modified version from Competitive Rework Team.
public Plugin myinfo =
{
	name = "[L4D2] Player Management",
	author = "CanadaRox, blueblur",
	description = "Team swapper avaliable for all gamemodes.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,
	L4D2Team_L4D1_Survivor, // Probably for maps that contain survivors from the first part and from part 2

	L4D2Team_Size // 5 size
}

static const L4D2Team oppositeTeamMap[view_as<int>(L4D2Team_Size)] =
{
	L4D2Team_None,
	L4D2Team_Spectator,
	L4D2Team_Infected,
	L4D2Team_Survivor,
	L4D2Team_L4D1_Survivor
};

// game internal cvars
ConVar 
	survivor_limit,
	z_max_player_zombies;

// plugin cvars
ConVar
	g_hCvar_Allowed,
	g_hCvar_Supress,
	g_hCvar_ShouldFixBotCount,
	g_hCvar_ShouldIdleWhileCapped,
	g_hCvar_ShouldSpecWhileCapped,
	g_hCvar_ShouldSuicideWhileCapped;

// Offset
int g_iOff_m_queuedPummelAttacker = -1;

// SDKCall
Handle g_hSDKCall_GoAwayFromKeyboard = null;

// Timer
Handle g_hSpecTimer[MAXPLAYERS+1] = {null, ...};

L4D2Team g_L4D2Team_pendingSwaps[MAXPLAYERS+1];
bool g_bBlockVotes[MAXPLAYERS+1];
bool g_bIsMapActive;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_bIsMapActive = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadGamedata();

	LoadTranslation(TRANSLATION_FILE_COMMON);
	LoadTranslation(TRANSLATION_FILE);

	CreateConVar("playermanagement_version", PLUGIN_VERSION, "Version of the player management plugin", FCVAR_NOTIFY | FCVAR_DEVELOPMENTONLY | FCVAR_DONTRECORD);

	// swap functions, only affected on PVP modes.
	RegAdminCmd("sm_swap", Swap_Cmd, ADMFLAG_KICK, "Swap all listed players to opposite teams");
	RegAdminCmd("sm_swapto", SwapTo_Cmd, ADMFLAG_KICK, "Swap all listed players to <teamnum>. 1 = spectator, 2 = survivor, 3 = infected.");
	RegAdminCmd("sm_swapteams", SwapTeams_Cmd, ADMFLAG_KICK, "Swap the players between both teams");
	RegAdminCmd("sm_fixbots", FixBots_Cmd, ADMFLAG_BAN, "Spawns survivor bots to match survivor_limit");

	// move to spectator team
	RegConsoleCmd("sm_spectate", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_spec", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_s", Spectate_Cmd, "Moves you to the spectator team");

	// idle
	RegConsoleCmd("sm_idle", Idle_Cmd, "Puts you in idle mode.");
	RegConsoleCmd("sm_i", Idle_Cmd, "Puts you in idle mode.");
	RegConsoleCmd("sm_away", Idle_Cmd, "Puts you in idle mode.");
	RegConsoleCmd("sm_afk", Idle_Cmd, "Puts you in idle mode.");

	// takeover a bot
	RegConsoleCmd("sm_takeover", Takeover_Cmd, "Takeover a survivor bot.");
	RegConsoleCmd("sm_t", Takeover_Cmd, "Takeover a survivor bot.");

	// suicide
	RegConsoleCmd("sm_zs", Suicide_Cmd, "Kill your self.");
	RegConsoleCmd("sm_suicide", Suicide_Cmd, "Kill your self.");

	g_hCvar_Allowed = CreateConVar("playermanagement_allowed", "1", "Allow players to use !spectate/!spec/!s");
	g_hCvar_Supress = CreateConVar("playermanagement_supress_spectate", "1", "Should print message when player spectate or suicide or idle?");
	g_hCvar_ShouldFixBotCount = CreateConVar("playermanagement_fixbot", "1", "Should we fix bot counts when survivor_limit changes?");
	g_hCvar_ShouldIdleWhileCapped = CreateConVar("playermanagement_idle_while_capped", "0", "Should player idle while capped?");
	g_hCvar_ShouldSpecWhileCapped = CreateConVar("playermanagement_spec_while_capped", "0", "Should player spectate while capped?");
	g_hCvar_ShouldSuicideWhileCapped = CreateConVar("playermanagement_suicide_while_capped", "0", "Should player suicide while capped?");

	// prevent player jockey from switching team when riding.
	AddCommandListener(TeamChange_Listener, "jointeam");

	survivor_limit = FindConVar("survivor_limit");
	survivor_limit.AddChangeHook(OnSurvivorLimitChanged);

	z_max_player_zombies = FindConVar("z_max_player_zombies");
}

public void OnPluginEnd()
{
	char name[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientConnected(i) && IsFakeClient(i) && GetClientName(i, name, sizeof name) && StrContains(name, BOT_NAME) != -1)
			KickClient(i);
	}
}

public void OnClientPutInServer(int client)
{
	g_bBlockVotes[client] = false;
}

public void OnMapStart()
{
	g_bIsMapActive = true;
	HookEntityOutput("info_director", "OnGameplayStart", OnGameplayStart);
}

public void OnMapEnd()
{
	g_bIsMapActive = false;
}

void OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
	if (GetHumanCount()) FixBotCount(false);
}

void OnSurvivorLimitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_bIsMapActive && GetHumanCount()) FixBotCount(false);
}

public Action L4D_OnEnterGhostStatePre(int client)
{
	return g_bBlockVotes[client] ? Plugin_Handled : Plugin_Continue;
}

public Action OnClientCommand(int client, int args)
{
	return g_bBlockVotes[client] ? Plugin_Handled : Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	return g_bBlockVotes[client] ? Plugin_Stop : Plugin_Continue;
}

Action FixBots_Cmd(int client, int args)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	CPrintToChatAll("%t", "TryingFixBot", client != 0 ? name : "Console");
	FixBotCount(true);

	return Plugin_Handled;
}

Action Spectate_Cmd(int client, int args)
{
	if (!g_hCvar_Allowed.BoolValue)
	{
		CReplyToCommand(client, "%t", "NotAllowed");
		return Plugin_Handled;
	}

	L4D2Team team = GetClientTeamEx(client);
	if (team == L4D2Team_Survivor)
	{
		// is player dominated or incapped?
		if (((L4D2_GetInfectedAttacker(client) != -1 && !L4D_IsPlayerIncapacitated(client)) || GetPummelQueueAttacker(client) != -1) && !g_hCvar_ShouldSpecWhileCapped.BoolValue)
		{
			CPrintToChat(client, "%t", "NoCappedSpec");
			return Plugin_Handled;
		}
		else
			ChangeClientTeamEx(client, L4D2Team_Spectator, true);
	}
	else if (team == L4D2Team_Infected)
	{
		// Player Tank is not allowed.
		if (IsTank(client)) 
			return Plugin_Handled;

		// alive infected should be commited to suicide when spectating.
		if (!IsGhost(client))
			ForcePlayerSuicide(client);

		ChangeClientTeamEx(client, L4D2Team_Spectator, true);
	}
	else
	{
		g_bBlockVotes[client] = true;
		ChangeClientTeamEx(client, L4D2Team_Infected, true);
		CreateTimer(0.1, RespecDelay_Timer, client);
	}
	
	if (g_hCvar_Supress.BoolValue && team != L4D2Team_Spectator && !g_hSpecTimer[client])
		CPrintToChatAllEx(client, "%t", "PlayerSpectated", client);
	
	if (!g_hSpecTimer[client]) g_hSpecTimer[client] = CreateTimer(7.0, SecureSpec_Timer, client);
	return Plugin_Handled;
}

Action Idle_Cmd(int client, int args)
{
	if (!g_hCvar_Allowed.BoolValue)
	{
		CReplyToCommand(client, "%t", "NotAllowed");
		return Plugin_Handled;
	}

	L4D2Team team = GetClientTeamEx(client);
	if (team != L4D2Team_Survivor)
	{
		CReplyToCommand(client, "%t", "NotSurvivor");
		return Plugin_Handled;
	}

	if (L4D_HasPlayerControlledZombies())
	{
		CReplyToCommand(client, "%t", "NotAllowedInPVPModes");
		return Plugin_Handled;
	}

	// is player dominated or incapped?
	if (((L4D2_GetInfectedAttacker(client) != -1 && !L4D_IsPlayerIncapacitated(client)) || GetPummelQueueAttacker(client) != -1) && !g_hCvar_ShouldIdleWhileCapped.BoolValue)
	{
		CPrintToChat(client, "%t", "NoCappedIdle");
		return Plugin_Handled;
	}

	SDKCall(g_hSDKCall_GoAwayFromKeyboard, client);

	if (g_hCvar_Supress.BoolValue && team != L4D2Team_Spectator && !g_hSpecTimer[client])
		CPrintToChatAllEx(client, "%t", "GoAwayFromKeyboard", client);

	if (!g_hSpecTimer[client]) g_hSpecTimer[client] = CreateTimer(7.0, SecureSpec_Timer, client);

	return Plugin_Handled;
}

// prevent message being spammed.
Action SecureSpec_Timer(Handle timer, any client)
{
	KillTimer(g_hSpecTimer[client]);
	g_hSpecTimer[client] = INVALID_HANDLE;
	return Plugin_Handled;
}

Action RespecDelay_Timer(Handle timer, any client)
{
	if (IsClientInGame(client)) 
	{
		ChangeClientTeamEx(client, L4D2Team_Spectator, true);
		g_bBlockVotes[client] = false;
	}

	return Plugin_Stop;
}

Action TeamChange_Listener(int client, const char[] command, int argc)
{
	// Invalid 
	if(!IsClientInGame(client) || argc < 1) 
		return Plugin_Handled;

	// Not a jockey with a victim, don't care
	if (GetClientTeamEx(client) != L4D2Team_Infected
	|| GetZombieClass(client) != 5
	|| GetEntProp(client, Prop_Send, "m_jockeyVictim") < 1)
		return Plugin_Continue;
 
 	// Block Jockey from switching team.
	return Plugin_Handled;
}

Action SwapTeams_Cmd(int client, int args)
{
	if (!L4D_HasPlayerControlledZombies())
	{
		CReplyToCommand(client, "%t", "OnlyPVP");
		return Plugin_Handled;
	}

	// if there is a player tank in the game, do not swap teams.
	bool bHasTank = false;
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if (IsTank(i))
				bHasTank = true;
		}
	}

	if (L4D2_IsTankInPlay() && bHasTank)
	{
		CReplyToCommand(client, "%t", "TankInPlay");
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayer(i))
			g_L4D2Team_pendingSwaps[i] = oppositeTeamMap[GetClientTeam(i)];
	}

	ApplySwaps(client, false);
	return Plugin_Handled;
}

Action Swap_Cmd(int client, int args)
{
	if (!L4D_HasPlayerControlledZombies())
	{
		CReplyToCommand(client, "%t", "OnlyPVP");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		CReplyToCommand(client, "%t", "SwapUsage");
		return Plugin_Handled;
	}

	char argbuf[MAX_NAME_LENGTH], target_name[MAX_TARGET_LENGTH];
	int[] targets = new int[MaxClients+1];
	int target, targetCount;
	bool tn_is_ml;

	for (int i = 1; i <= args; i++)
	{
		GetCmdArg(i, argbuf, sizeof(argbuf));
		targetCount = ProcessTargetString(
				argbuf,
				0,
				targets,
				MaxClients+1,
				COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml);
		
		for (int j = 0; j < targetCount; j++)
		{
			target = targets[j];

			if (IsTank(target))
			{
				CReplyToCommand(client, "%t", "NoTankSwap");
				return Plugin_Handled;
			}

			if(IsClientInGame(target))
				g_L4D2Team_pendingSwaps[target] = oppositeTeamMap[GetClientTeamEx(target)];
		}
	}

	ApplySwaps(client, false);

	return Plugin_Handled;
}

Action SwapTo_Cmd(int client, int args)
{
	if (!L4D_HasPlayerControlledZombies())
	{
		CReplyToCommand(client, "%t", "OnlyPVP");	// [SM] Only pvp mode is allowed.
		return Plugin_Handled;
	}

	if (args < 2)
	{
		CReplyToCommand(client, "%t", "SwapToUsage", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		CReplyToCommand(client, "%t", "SwapToForceUsage", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		return Plugin_Handled;
	}

	char argbuf[MAX_NAME_LENGTH];
	bool force = false;

	GetCmdArg(1, argbuf, sizeof(argbuf));
	if (StrEqual(argbuf, "force"))
	{
		force = true;
		GetCmdArg(2, argbuf, sizeof(argbuf));
	}

	L4D2Team team = view_as<L4D2Team>(StringToInt(argbuf));
	if (team < L4D2Team_Spectator || team > L4D2Team_Infected)
	{
		CReplyToCommand(client, "%t", "ValidTeams", L4D2Team_Spectator, L4D2Team_Survivor, L4D2Team_Infected);
		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients+1];
	int target, targetCount;
	char target_name[MAX_TARGET_LENGTH];
	bool tn_is_ml;

	for (int i = force ? 3 : 2; i <= args; i++)
	{
		GetCmdArg(i, argbuf, sizeof(argbuf));
		targetCount = ProcessTargetString(
				argbuf,
				0,
				targets,
				MaxClients+1,
				COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml);
		
		for (int j = 0; j < targetCount; j++)
		{
			target = targets[j];

			if (IsTank(target))
			{
				CReplyToCommand(client, "%t", "NoTankSwap");
				return Plugin_Handled;
			}

			if(IsClientInGame(target))
				g_L4D2Team_pendingSwaps[target] = team;
		}
	}

	ApplySwaps(client, force);

	return Plugin_Handled;
}

void ApplySwaps(int sender, bool force)
{
	L4D2Team clientTeam;
	/* Swap everyone to spec first so we know the correct number of slots on the teams */
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			clientTeam = GetClientTeamEx(client);
			if (clientTeam != g_L4D2Team_pendingSwaps[client] && g_L4D2Team_pendingSwaps[client] != L4D2Team_None)
			{
				if (clientTeam == L4D2Team_Infected && !IsTank(client))
					ForcePlayerSuicide(client);

				ChangeClientTeamEx(client, L4D2Team_Spectator, true);
			}
		}
	}

	/* Now lets try to put them on teams */
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && g_L4D2Team_pendingSwaps[client] != L4D2Team_None)
		{
			if (!ChangeClientTeamEx(client, g_L4D2Team_pendingSwaps[client], force))
			{
				if (sender > 0)
					CPrintToChat(sender, "%t", "CouldNotSwitch", client);
			}
			g_L4D2Team_pendingSwaps[client] = L4D2Team_None;

		}
	}

	/* Just in case MaxClients ever changes */
	for (int i = MaxClients+1; i <= MAXPLAYERS; i++)
		g_L4D2Team_pendingSwaps[i] = L4D2Team_None;
}

Action Takeover_Cmd(int client, int args)
{
	if (GetClientTeamEx(client) == L4D2Team_Survivor)
	{
		CReplyToCommand(client, "%t", "AlreadySurvivor");
		return Plugin_Handled;
	}

	if (GetClientTeamEx(client) == L4D2Team_Infected && L4D_HasPlayerControlledZombies())
	{
		CReplyToCommand(client, "%t", "AlreadyInfected");
		return Plugin_Handled;
	}
/*
	if (IsPlayerIdle(client))
	{
		CReplyToCommand(client, "%t", "PlayerIdle");
		return Plugin_Handled;
	}
*/
	int bot = FindSurvivorBot();
	if (bot > 0)
	{
		// should we use CTerrorPlayer::TakeOverBot()?
		int flags = GetCommandFlags("sb_takecontrol");
		SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "sb_takecontrol");
		SetCommandFlags("sb_takecontrol", flags);
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

// from l4d2_afk_commands by fdxx.
Action Suicide_Cmd(int client, int args)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return Plugin_Handled;

	// is player dominated or incapped?
	if (((L4D2_GetInfectedAttacker(client) != -1 && !L4D_IsPlayerIncapacitated(client)) || GetPummelQueueAttacker(client) != -1) && !g_hCvar_ShouldSuicideWhileCapped.BoolValue)
	{
		CPrintToChat(client, "%t", "NoCappedSuicide");
		return Plugin_Handled;
	}
	
	switch (GetClientTeam(client))
	{
		case 2, 3:
		{
			if (IsPlayerAlive(client))
				ForcePlayerSuicide(client);

			if (g_hCvar_Supress.BoolValue)
				CPrintToChatAllEx(client, "%t", "PlayerSuicide", client);
		}
	}
	
	return Plugin_Handled;
}

bool ChangeClientTeamEx(int client, L4D2Team team, bool force)
{
	if (GetClientTeamEx(client) == team)
		return true;

	else if (!force && GetTeamHumanCount(team) == GetTeamMaxHumans(team))
		return false;

	if (team != L4D2Team_Survivor)
	{
		ChangeClientTeam(client, view_as<int>(team));
		return true;
	}
	else
	{
		int bot = FindSurvivorBot();
		if (bot > 0)
		{
			// should we use CTerrorPlayer::TakeOverBot()?
			int flags = GetCommandFlags("sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags);
			return true;
		}
	}
	return false;
}

void FixBotCount(bool bIsCommand)
{
	if (!g_hCvar_ShouldFixBotCount.BoolValue && !bIsCommand)
		return;

	int survivor_count = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
			survivor_count++;
	}

	int limit = survivor_limit.IntValue;
	if (survivor_count < limit)
	{
		int bot;
		for (; survivor_count < limit; survivor_count++)
		{
			bot = CreateFakeClient(BOT_NAME);
			if (bot != 0)
			{
				ChangeClientTeam(bot, view_as<int>(L4D2Team_Survivor));
				RequestFrame(OnFrame_KickBot, GetClientUserId(bot));
			}
		}
	}
	else if (survivor_count > limit)
	{
		for (int client = 1; client <= MaxClients && survivor_count > limit; client++)
		{
			if(IsClientInGame(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
			{
				if (IsFakeClient(client))
				{
					survivor_count--;
					KickClient(client);
				}
			}
		}
	}
}

void OnFrame_KickBot(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0) KickClient(client);
}

bool IsGhost(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isGhost", 1);
}

int GetTeamHumanCount(L4D2Team team)
{
	int humans = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeamEx(client) == team)
			humans++;
	}
	
	return humans;
}

int GetHumanCount()
{
	int humans = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client))
			humans++;
	}
	
	return humans;
}

int GetTeamMaxHumans(L4D2Team team)
{
	if (team == L4D2Team_Survivor) return survivor_limit.IntValue;
	else if (team == L4D2Team_Infected) return z_max_player_zombies.IntValue;
	return MaxClients;
}

/* return -1 if no bot found, clientid otherwise */
int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsFakeClient(client) && GetClientTeamEx(client) == L4D2Team_Survivor && IsPlayerAlive(client))
			return client;
	}
	return -1;
}

bool IsPlayer(int client)
{
	L4D2Team team = GetClientTeamEx(client);
	return (team == L4D2Team_Survivor || team == L4D2Team_Infected);
}

bool IsTank(int client)
{
	return (IsClientInGame(client)
		&& GetClientTeamEx(client) == L4D2Team_Infected
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK);
}

int GetZombieClass(int client) {return GetEntProp(client, Prop_Send, "m_zombieClass");}

// from l4d2_afk_commands by fdxx.
stock bool IsPlayerIdle(int player)
{
	int offset;
	char sNetClass[12];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && IsPlayerAlive(i))
		{
			if (!GetEntityNetClass(i, sNetClass, sizeof(sNetClass)))
				continue;

			offset = FindSendPropInfo(sNetClass, "m_humanSpectatorUserID");
			if (offset > 0 && GetClientOfUserId(GetEntData(i, offset)) == player)
				return true;
		}
	}
	return false;
}

int GetPummelQueueAttacker(int client)
{
	return GetEntDataEnt2(client, g_iOff_m_queuedPummelAttacker);
}

L4D2Team GetClientTeamEx(int client)
{
	return view_as<L4D2Team>(GetClientTeam(client));
}

void LoadGamedata()
{
	GameData hGameData = new GameData(GAMEDATA_FILE);

	if (!hGameData) SetFailState("Gamedata \""... GAMEDATA_FILE ..."\" missing or corrupt.");
	
	g_iOff_m_queuedPummelAttacker = hGameData.GetOffset(OFFSET_NAME);
	if (g_iOff_m_queuedPummelAttacker == -1) SetFailState("Failed to get offset \""... OFFSET_NAME ..."\".");

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SDKCALL_FUNCTION))
		SetFailState("Failed to set SDKCall for \""... SDKCALL_FUNCTION ..."\" from conf.");

	g_hSDKCall_GoAwayFromKeyboard = EndPrepSDKCall();
	if (!g_hSDKCall_GoAwayFromKeyboard) SetFailState("Failed to create SDKCall \""... SDKCALL_FUNCTION ..."\"");

	delete hGameData;
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