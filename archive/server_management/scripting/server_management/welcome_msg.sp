#if defined _server_management_welcome_msg_included
 #endinput
#endif
#define _server_management_welcome_msg_included

#undef REQUIRE_PLUGIN
#include "neko/nekonative.inc"

#undef REQUIRE_PLUGIN
#include <readyup>

enum
{
	NS_SpawnMode_None = -1,
	NS_SpawnMode_Director = 0,
	NS_SpawnMode_Normal = 1,
	NS_SpawnMode_Nightmare = 2,
	NS_SpawnMode_Hell = 3,
	NS_SpawnMode_Flexible = 4,

	NS_SpawnMode_Size = 5, // NS_SpawnMode_None is not included
}

/* welcome_msg */
static ConVar
	g_hCvar_cvSwitch,
	g_hCvar_cvWaitTime,
	g_hCvar_cvPrintRound,
	g_hCvar_cvPrintRoundWaitTime,
	g_hCvar_cvMoreLine,
	//g_hCvar_cvHostname,
	g_hCvar_cvMaxSlots;

static int g_iMaxPlayers = 0;

void _welcome_message_OnPluginStart()
{
	LoadTranslation("server_management.welcome_msg.phrases");
	RegConsoleCmd("sm_serverinfo", Cmd_svInfo, "Print server info");

	g_hCvar_cvSwitch = CreateConVar("welcome_message_switch", "1", "Turn on the welcome");
	g_hCvar_cvWaitTime	= CreateConVar("welcome_wait_time", "5.0", "Wait this time to print the welcome message");
	g_hCvar_cvPrintRound = CreateConVar("welcome_print_round_status", "1", "Print the round status");
	g_hCvar_cvPrintRoundWaitTime = CreateConVar("welcome_print_round_wait_time", "2.0", "Wait this time to print round status");
	g_hCvar_cvMoreLine	= CreateConVar("welcome_more_line", "0", "Optional. If you want to print more message on client connected. set 0 to turn off.");

	//g_hCvar_cvHostname	= FindConVar("hostname");

	// for confogl_system
	if (g_bIsConfoglAvailable) g_hCvar_cvMaxSlots = FindConVar("mv_maxplayers")
	else g_hCvar_cvMaxSlots = FindConVar("sv_maxplayers");

	g_hCvar_cvMaxSlots.AddChangeHook(OnCvarChanged);
	OnCvarChanged(null, "", "");
}

void _welcome_message_OnClientPutInServer(int client)
{
	if (g_hCvar_cvSwitch.BoolValue && IsValidClient(client))
		CreateTimer(g_hCvar_cvWaitTime.FloatValue, Timer_WelcomeMessage, client);
}

static void OnCvarChanged(ConVar convar, const char[] sNewValue, const char[] sOldValue)
{
	g_iMaxPlayers = g_hCvar_cvMaxSlots.IntValue;
}

static Action Timer_WelcomeMessage(Handle Timer, int client)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	char name[128];
	GetClientName(client, name, sizeof(name));
	CPrintToChat(client, "%t", "Message", name);

	if (g_hCvar_cvMoreLine.IntValue != 0)
	{
		char buffer[128];
		for (int i = 1; i < g_hCvar_cvMoreLine.IntValue; i++)
		{
			Format(buffer, sizeof(buffer), "MoreMessage%d", i);
			CPrintToChat(client, "%t", buffer);
		}
	}

	if (g_hCvar_cvPrintRound.BoolValue && IsValidClient(client))
		CreateTimer(g_hCvar_cvPrintRoundWaitTime.FloatValue, Timer_RoundStatus, client);

	return Plugin_Handled;
}

static Action Timer_RoundStatus(Handle Timer, int client)
{
	PrintMessage(client);
	return Plugin_Handled;
}

static Action Cmd_svInfo(int client, int arg)
{
	PrintMessage(client);
	return Plugin_Handled;
}

static void PrintMessage(int client)
{
	if (!IsValidClient(client))
		return;

	char Mapname[128];
	//g_hCvar_cvHostname.GetString(Buffer, sizeof(Buffer));
	GetCurrentMap(Mapname, sizeof(Mapname));

	CPrintToChatEx(client, client, "%t", "Header");
	CPrintToChatEx(client, client, "%t", "PlayerNum", (GetTotalPlayers() == g_iMaxPlayers) ? "{green}" : "{olive}", GetTotalPlayers(), g_iMaxPlayers);
	CPrintToChatEx(client, client, "%t", "MapName", Mapname);

	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
	{
		char firsthalf[64], secondhalf[64], round[16];
		Format(firsthalf, sizeof(firsthalf), "%T", "FirstHalf", client);
		Format(secondhalf, sizeof(secondhalf), "%T", "SecondHalf", client);
		Format(round, sizeof(round), "#R%d / ", GetScavengeRoundNumber());

		char sGameMode[64];
		GetGameModeString(sGameMode, sizeof(sGameMode), client);
		CPrintToChatEx(	client, client, "%t", "GameMode_RoundStatus", 
						sGameMode,
						L4D2_IsScavengeMode() ? round : "",
						!InSecondHalfOfRound() ? firsthalf : secondhalf);
	}
	else
	{
		if (g_bNekoSpecials)
		{
			char sGameMode[64], sDifficulty[64];
			GetGameModeString(sGameMode, sizeof(sGameMode), client);
			GetDifficultyString(sDifficulty, sizeof(sDifficulty), client);
			CPrintToChatEx(	client, client, "%t", "GameMode_NekoSpecials",
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
			GetGameModeString(sGameMode, sizeof(sGameMode), client);
			GetDifficultyString(sDifficulty, sizeof(sDifficulty), client);
			CPrintToChatEx(client, client, "%t", "GameMode_GeneralCoop", sGameMode, sDifficulty);
		}
	}
		

	if (g_bReadyUpAvailable)
	{
		char sBuffer[64];
		g_bIsInReady ? 	Format(sBuffer, sizeof(sBuffer), "%T", "InReady", client) :
						Format(sBuffer, sizeof(sBuffer), "%T", "OutReady", client);

		CPrintToChatEx(client, client, "%t", "ReadyUpStatus", sBuffer);

		FindConVar("l4d_ready_cfg_name").GetString(sBuffer, sizeof(sBuffer));
		if (sBuffer[0] == '\0')
			Format(sBuffer, sizeof(sBuffer), "%T", "Empty", client);

		CPrintToChatEx(client, client, "%t", "ReadyUpCfgNameStatus", sBuffer);
	}
}

static stock void GetGameModeString(char[] sGameMode, int maxlen, int client)
{
	switch (L4D_GetGameModeType())
	{
		case GAMEMODE_UNKNOWN:	Format(sGameMode, maxlen, "%T", "unknown", client);
		case GAMEMODE_COOP:		Format(sGameMode, maxlen, "%T", "coop", client);
		case GAMEMODE_VERSUS:	Format(sGameMode, maxlen, "%T", "versus", client);
		case GAMEMODE_SCAVENGE:	Format(sGameMode, maxlen, "%T", "scavenge", client);
		case GAMEMODE_SURVIVAL:	Format(sGameMode, maxlen, "%T", "survival", client);
	}
}

static stock void GetDifficultyString(char[] sDifficulty, int maxlen, int client)
{
	char sDifficultyName[12];
	FindConVar("z_difficulty").GetString(sDifficultyName, sizeof(sDifficultyName));
	if (sDifficultyName[0] != '\0')
	{
		switch(sDifficultyName[0])
		{
			case 'E','e': Format(sDifficulty, maxlen, "%T", "Easy", client);
			case 'N','n': Format(sDifficulty, maxlen, "%T", "Normal", client);
			case 'H','h': Format(sDifficulty, maxlen, "%T", "Hard", client);
			case 'I','i': Format(sDifficulty, maxlen, "%T", "Impossible", client);
		}
	}
}

static stock void GetNSSpawnModeString(char[] sSpawnMode, int maxlen, int client)
{
	switch (NekoSpecials_GetSpawnMode())
	{
		case NS_SpawnMode_Director:		Format(sSpawnMode, maxlen, "%T", "Director_NS", client);
		case NS_SpawnMode_Normal:		Format(sSpawnMode, maxlen, "%T", "Normal_NS", client);
		case NS_SpawnMode_Nightmare:	Format(sSpawnMode, maxlen, "%T", "Nightmare_NS", client);
		case NS_SpawnMode_Hell:			Format(sSpawnMode, maxlen, "%T", "Hell_NS", client);
		case NS_SpawnMode_Flexible:		Format(sSpawnMode, maxlen, "%T", "Flexible_NS", client);
		default: Format(sSpawnMode, maxlen, "%T", "unknown", client);
	}
}