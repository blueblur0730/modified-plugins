#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>

#undef REQUIRE_PLUGIN
#include "neko/nekonative.inc"

#undef REQUIRE_PLUGIN
#include <readyup>

enum
{
	NS_SpawnMode_None	   = -1,
	NS_SpawnMode_Director  = 0,
	NS_SpawnMode_Normal	   = 1,
	NS_SpawnMode_Nightmare = 2,
	NS_SpawnMode_Hell	   = 3,
	NS_SpawnMode_Flexible  = 4,

	NS_SpawnMode_Size	   = 5,	   // NS_SpawnMode_None is not included
}

/* welcome_msg */
ConVar
	g_hCvar_Enable,
	g_hCvar_WaitTime,
	g_hCvar_PrintRound,
	g_hCvar_PrintRoundWaitTime,
	g_hCvar_MoreLine,
	// g_hCvar_cvHostname,
	g_hCvar_MaxSlots;

int g_iMaxPlayers = 0;
bool g_bReadyUpAvailable = false;
bool g_bIsConfoglAvailable = false;
bool g_bNekoSpecials = false;
bool g_bIsInReady = false;

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo =
{
	name = "[L4D2] Welcome Message",
	author = "blueblur",
	description = "Simple and quick information transimission when a player connects.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("L4D2_GetSurvivalStartTime");	// this is a fucking bullshit
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("l4d2_welcome_msg.phrases");
	RegConsoleCmd("sm_serverinfo", Cmd_svInfo, "Print server info");

	g_hCvar_Enable			   = CreateConVar("welcome_message_enable", "1", "Turn on the welcome or not.");
	g_hCvar_WaitTime		   = CreateConVar("welcome_wait_time", "5.0", "Wait this time to print the welcome message");
	g_hCvar_PrintRound		   = CreateConVar("welcome_print_round_status", "1", "Print the round status");
	g_hCvar_PrintRoundWaitTime = CreateConVar("welcome_print_round_wait_time", "2.0", "Wait this time to print round status");
	g_hCvar_MoreLine		   = CreateConVar("welcome_more_line", "0", "Optional. If you want to print more message on client connected. set 0 to turn off.");
	g_hCvar_MaxSlots		   = FindConVar("sv_maxplayers");

	g_hCvar_MaxSlots.AddChangeHook(OnCvarChanged);
	OnCvarChanged(null, "", "");
}

public void OnAllPluginsLoaded() 
{ 
	g_bIsConfoglAvailable = LibraryExists("confogl_system");
	g_bReadyUpAvailable	= LibraryExists("readyup");
	g_bNekoSpecials = LibraryExists("nekospecials");
}

public void OnLibraryAdded(const char[] name)
{ 
	if (StrEqual(name, "confogl_system")) g_bIsConfoglAvailable = true;
	if (StrEqual(name, "readyup")) g_bReadyUpAvailable = true;
	if (StrEqual(name, "nekospecials")) g_bNekoSpecials = true;
}

public void OnLibraryRemoved(const char[] name)
{ 
	if (StrEqual(name, "confogl_system")) g_bIsConfoglAvailable = false;
	if (StrEqual(name, "readyup")) g_bReadyUpAvailable = false;
	if (StrEqual(name, "nekospecials")) g_bNekoSpecials = false;
}

public void OnReadyUpInitiate()
{
	g_bIsInReady = true;
}

public void OnRoundIsLive()
{
	g_bIsInReady = false;
}

public void OnClientPutInServer(int client)
{
	if (g_hCvar_Enable.BoolValue && IsValidClient(client))
		CreateTimer(g_hCvar_WaitTime.FloatValue, Timer_WelcomeMessage, client);
}

void OnCvarChanged(ConVar convar, const char[] sNewValue, const char[] sOldValue)
{
	g_iMaxPlayers = g_hCvar_MaxSlots.IntValue;
}

void Timer_WelcomeMessage(Handle Timer, int client)
{
	if (!IsValidClient(client))
		return;

	char name[128];
	GetClientName(client, name, sizeof(name));
	CPrintToChat(client, "%t", "Message", name);

	if (g_hCvar_MoreLine.IntValue != 0)
	{
		char buffer[128];
		for (int i = 1; i < g_hCvar_MoreLine.IntValue; i++)
		{
			Format(buffer, sizeof(buffer), "MoreMessage%d", i);
			CPrintToChat(client, "%t", buffer);
		}
	}

	if (g_hCvar_PrintRound.BoolValue && IsValidClient(client))
		CreateTimer(g_hCvar_PrintRoundWaitTime.FloatValue, Timer_RoundStatus, client);
}

void Timer_RoundStatus(Handle Timer, int client)
{
	PrintMessage(client);
}

Action Cmd_svInfo(int client, int arg)
{
	PrintMessage(client);
	return Plugin_Handled;
}

void PrintMessage(int client)
{
	if (!IsValidClient(client))
		return;

	char Mapname[128];
	// g_hCvar_cvHostname.GetString(Buffer, sizeof(Buffer));
	GetCurrentMap(Mapname, sizeof(Mapname));

	CPrintToChatEx(client, client, "%t", "Header");
	CPrintToChatEx(client, client, "%t", "PlayerNum", (GetTotalPlayers() == g_iMaxPlayers) ? "{green}" : "{olive}", GetTotalPlayers(), g_iMaxPlayers);
	CPrintToChatEx(client, client, "%t", "MapName", Mapname);

	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
	{
		char half[64], round[16];
		!InSecondHalfOfRound() ?
		Format(half, sizeof(half), "%T", "FirstHalf", client) :
		Format(half, sizeof(half), "%T", "SecondHalf", client);

		if (L4D2_IsScavengeMode())
			Format(round, sizeof(round), "#R%d / ", GetScavengeRoundNumber());

		char sGameMode[64];
		FindConVar("mp_gamemode").GetString(sGameMode, sizeof(sGameMode));
		CPrintToChatEx(client, client, "%t", "GameMode_RoundStatus",
					   sGameMode,
					   round,
					   half);
	}
	else if (L4D2_IsGenericCooperativeMode())
	{
		if (g_bNekoSpecials)
		{
			char sGameMode[64], sDifficulty[64];
			FindConVar("mp_gamemode").GetString(sGameMode, sizeof(sGameMode));
			GetDifficultyString(sDifficulty, sizeof(sDifficulty), client);
			CPrintToChatEx(client, client, "%t", "GameMode_NekoSpecials",
						   sGameMode,
						   sDifficulty,
						   NekoSpecials_GetSpecialsNum(),
						   NekoSpecials_GetSpecialsTime());

			char sSpawnMode[64];
			GetNSSpawnModeString(sSpawnMode, sizeof(sSpawnMode), client);
			CPrintToChatEx(client, client, "%t", "GameMode_NekoSpecialsStatus", sSpawnMode);
		}
		else
		{
			char sGameMode[64], sDifficulty[64];
			FindConVar("mp_gamemode").GetString(sGameMode, sizeof(sGameMode));
			GetDifficultyString(sDifficulty, sizeof(sDifficulty), client);
			CPrintToChatEx(client, client, "%t", "GameMode_GeneralCoop", sGameMode, sDifficulty);
		}
	}
	else if (L4D_IsSurvivalMode())
	{
		if (L4D_HasPlayerControlledZombies())
		{
			char half[64];
			!InSecondHalfOfRound() ?
			Format(half, sizeof(half), "%T", "FirstHalf", client) :
			Format(half, sizeof(half), "%T", "SecondHalf", client);

			char sGameMode[64];
			FindConVar("mp_gamemode").GetString(sGameMode, sizeof(sGameMode));
			CPrintToChatEx(client, client, "%t", "GameMode_RoundStatus",
					   sGameMode,
					   "",
					   half);

			int time = L4D2_GetSurvivalStartTime();
			if (time != 0)
				CPrintToChatEx(client, client, "%t", "GameMode_SurvivalStartTime", time);
		}

		CPrintToChatEx(client, client, "%t", "GameMode_SurvivalTime", 
					GameRules_GetPropFloat("m_flTeamRoundTime", L4D2_TeamNumberToTeamIndex(2)));
	}

	char sBuffer[64];
	if (g_bReadyUpAvailable)
	{
		g_bIsInReady ?
		Format(sBuffer, sizeof(sBuffer), "%T", "InReady", client) :
		Format(sBuffer, sizeof(sBuffer), "%T", "OutReady", client);

		CPrintToChatEx(client, client, "%t", "ReadyUpStatus", sBuffer);

		FindConVar("l4d_ready_cfg_name").GetString(sBuffer, sizeof(sBuffer));
		if (sBuffer[0] == '\0')
		{
			if (g_bIsConfoglAvailable)
			{
				FindConVar("confogl_match_name").GetString(sBuffer, sizeof(sBuffer));
				if (sBuffer[0] == '\0')
					Format(sBuffer, sizeof(sBuffer), "%T", "Empty", client);
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Empty", client);
			}
		}

		CPrintToChatEx(client, client, "%t", "ReadyUpCfgNameStatus", sBuffer);
	}

	if (g_bIsConfoglAvailable && strlen(sBuffer) <= 0)
	{
		FindConVar("confogl_match_name").GetString(sBuffer, sizeof(sBuffer));
		if (sBuffer[0] == '\0')
			Format(sBuffer, sizeof(sBuffer), "%T", "Empty", client);

		CPrintToChatEx(client, client, "%t", "ReadyUpCfgNameStatus", sBuffer);
	}
}

void GetNSSpawnModeString(char[] sSpawnMode, int maxlen, int client)
{
	switch (NekoSpecials_GetSpawnMode())
	{
		case NS_SpawnMode_Director: Format(sSpawnMode, maxlen, "%T", "Director_NS", client);
		case NS_SpawnMode_Normal: Format(sSpawnMode, maxlen, "%T", "Normal_NS", client);
		case NS_SpawnMode_Nightmare: Format(sSpawnMode, maxlen, "%T", "Nightmare_NS", client);
		case NS_SpawnMode_Hell: Format(sSpawnMode, maxlen, "%T", "Hell_NS", client);
		case NS_SpawnMode_Flexible: Format(sSpawnMode, maxlen, "%T", "Flexible_NS", client);
		default: Format(sSpawnMode, maxlen, "%T", "unknown", client);
	}
}

stock void GetDifficultyString(char[] sDifficulty, int maxlen, int client)
{
	char sDifficultyName[12];
	FindConVar("z_difficulty").GetString(sDifficultyName, sizeof(sDifficultyName));
	if (sDifficultyName[0] != '\0')
	{
		switch (sDifficultyName[0])
		{
			case 'E', 'e': Format(sDifficulty, maxlen, "%T", "Easy", client);
			case 'N', 'n': Format(sDifficulty, maxlen, "%T", "Normal", client);
			case 'H', 'h': Format(sDifficulty, maxlen, "%T", "Hard", client);
			case 'I', 'i': Format(sDifficulty, maxlen, "%T", "Impossible", client);
			default: strcopy(sDifficulty, maxlen, "Unknown");
		}
	}
}

stock int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}

stock int GetTotalPlayers()
{
	int players = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			players++;
	}

	return players;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;
}

stock int L4D2_TeamNumberToTeamIndex(int team, bool bIsPreviousRound = false)
{
	if (team != 2 && team != 3) return -1;

	if (!bIsPreviousRound)
	{
		bool flipped = view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped"));
		if (flipped) ++team;
	}
	else 
		++team;

	return team % 2;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}