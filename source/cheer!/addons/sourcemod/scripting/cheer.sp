/*
cheer.sp

Description:
	The Cheer! plugin allows players to cheer random cheers per round.

Versions:
	1.0
		* Initial Release

	1.1
		* Added cvar to control colors
		* Added cvar to control chat
		* Added team color to name

	1.2
		* Added jeers
		* Added admin only support for jeers
		* Made config file autoload

	1.3
		* Added *DEAD* in front of dead people's jeers
		* Added volume control cvar sm_cheer_jeer_volume
		* Added jeer limit cvat sm_cheer_jeer_limit
		* Added count infomation to limit displays
2007
------------------------------------------------------------
2023
	r1.0: 8/1/23
		* updated to sm1.11 new syntax.
		* reformatted to support L4D2.

	r1.1: 8/2/23
		* check the gamemode in L4D2. we dont ues this plugin if the round has already started in versus or scavenge.
		* split cheer and jeer into two commands saperately rather than checking wether a player is dead or not.

	r1.1.1: 8/2/23
		* if round is lived, tell them we cannot use commands.

	r1.2: 8/2/23
		* fix an issue message didn't print to chat.
		* add team descriptions.

	r1.2.1: 8/2/23
		* now cheer or jeer counts restore to 0 if round ends.
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>

#define PLUGIN_VERSION "r1.2.1"
#define NUM_SOUNDS	   12

#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3

// Plugin definitions
public Plugin myinfo =
{
	name		= "[L4D2] Cheer!",
	author		= "dalto, L4D2 modified version by blueblur",
	description = "The Cheer! plugin allows players to cheer random cheers per round",
	version		=  PLUGIN_VERSION,
	url			= "https://github.com/blueblur0730/modified-plugins"
};

int
	g_cheerCount[MAXPLAYERS + 1],
	g_jeerCount[MAXPLAYERS + 1];

ConVar
	g_hCvarEnabled,
	g_hCvarMaxCheers,
	g_hCvarChat,
	g_hCvarColors,
	g_hCvarJeer,
	g_hCvarMaxJeers,
	g_hCvarJeerVolume,
	g_hCvarCheerVolume;

char
	g_soundsList[NUM_SOUNDS][PLATFORM_MAX_PATH],
	g_soundsListJeer[NUM_SOUNDS][PLATFORM_MAX_PATH];

bool
	//g_bReadyUpAvailable 	= false,
	g_bIsRoundAlive			= false;

public void OnPluginStart()
{
	// ConVars
	CreateConVar("sm_cheer_version", PLUGIN_VERSION, "Cheer Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hCvarEnabled	   = CreateConVar("sm_cheer_enable", "1", "Enables the Cheer! plugin");
	g_hCvarMaxCheers   = CreateConVar("sm_cheer_limit", "3", "The maximum number of cheers per round");
	g_hCvarColors	   = CreateConVar("sm_cheer_colors", "1", "1 to turn chat colors on, 0 for off");
	g_hCvarChat		   = CreateConVar("sm_cheer_chat", "1", "1 to turn enable chat messages, 0 for off");
	g_hCvarJeer		   = CreateConVar("sm_cheer_jeer", "1", "0 to disable jeers, 1 to enable for all, 2 for admin only");
	g_hCvarMaxJeers	   = CreateConVar("sm_cheer_jeer_limit", "1", "The maximum number of jeers per round");
	g_hCvarJeerVolume  = CreateConVar("sm_cheer_jeer_volume", "1.0", "Jeer volume: should be a number between 0.0. and 1.0");
	g_hCvarCheerVolume = CreateConVar("sm_cheer_volume", "1.0", "Cheer volume: should be a number between 0.0. and 1.0");

	// Cmd
	RegConsoleCmd("sm_cheer", CommandCheer);
	RegConsoleCmd("sm_jeer", CommandJeer);

	// Execute the config file
	AutoExecConfig(true, "cheer");

	// Translations
	LoadTranslations("cheer.phrases");

	// Load Sounds
	LoadSounds();

	// Hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	for (int sound = 0; sound < NUM_SOUNDS; sound++)
	{
		char downloadFile[PLATFORM_MAX_PATH];

		if (!StrEqual(g_soundsList[sound], ""))
		{
			PrecacheSound(g_soundsList[sound], true);
			Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", g_soundsList[sound]);
			AddFileToDownloadsTable(downloadFile);
		}
		if (!StrEqual(g_soundsListJeer[sound], ""))
		{
			PrecacheSound(g_soundsListJeer[sound], true);
			Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", g_soundsListJeer[sound]);
			AddFileToDownloadsTable(downloadFile);
		}
	}
}

// Initializations to be done at the beginning of the round
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		g_cheerCount[i] = 0;
		g_jeerCount[i]	= 0;
	}

	g_bIsRoundAlive = false;
}

public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		g_cheerCount[i] = 0;
		g_jeerCount[i]	= 0;
	}

	g_bIsRoundAlive = false;
}

public void Event_PlayerLeftStartArea(Handle event, char[] name, bool dontBroadcast)
{
	g_bIsRoundAlive = true;
}

// When a new client is put in the server we reset their cheer count
public void OnClientPutInServer(int client)
{
	if (client && !IsFakeClient(client))
	{
		g_cheerCount[client] = 0;
		g_jeerCount[client]	 = 0;
	}
}

/*
public void OnAllPluginsLoaded()
{
	g_bReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "readyup"))
	{
		g_bReadyUpAvailable = false;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "readyup"))
	{
		g_bReadyUpAvailable = true;
	}
}

public void OnRoundIsLive()
{
	g_bReadyUpAvailable = false;
}

public void OnReadyUpInitiate()
{
	g_bReadyUpAvailable = true;
}
*/

Action CommandCheer(int client, int args)
{
	if (!GetConVarBool(g_hCvarEnabled))
	{
		return Plugin_Handled;
	}

	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if (g_cheerCount[client] >= GetConVarInt(g_hCvarMaxCheers))
	{
		CPrintToChat(client, "%t", "over cheer limit", GetConVarInt(g_hCvarMaxCheers));
		return Plugin_Handled;
	}

	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
	{
		if (g_bIsRoundAlive)
		{
			CPrintToChat(client, "%t", "round is live");
			return Plugin_Handled;
		}

		ExcuteCheer(client);
	}
	else
	{
		ExcuteCheer(client);
	}

	return Plugin_Handled;
}

Action CommandJeer(int client, int args)
{
	if (!GetConVarBool(g_hCvarEnabled))
	{
		return Plugin_Handled;
	}

	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if (g_jeerCount[client] >= GetConVarInt(g_hCvarMaxJeers))
	{
		CPrintToChat(client, "%t", "over jeer limit", GetConVarInt(g_hCvarMaxJeers));
		return Plugin_Handled;
	}

	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
	{
		if (g_bIsRoundAlive)
		{
			CPrintToChat(client, "%t", "round is live");
			return Plugin_Handled;
		}

		ExcuteJeer(client);
	}
	else
	{
		ExcuteJeer(client);
	}

	return Plugin_Handled;
}

void ExcuteCheer(int client)
{
	float vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(g_soundsList[GetRandomInt(0, 12)], vec, SOUND_FROM_WORLD, SNDLEVEL_SCREAMING, _, GetConVarFloat(g_hCvarCheerVolume));
	if (GetConVarBool(g_hCvarChat))
	{
		char name[64];
		char team[64];

		switch (GetClientTeam(client))
		{
			case L4D_TEAM_SPECTATOR:
			{
				Format(team, sizeof(team), "%t", "Spectator");
			}

			case L4D_TEAM_SURVIVOR:
			{
				Format(team, sizeof(team), "%t", "Survivor");
			}

			case L4D_TEAM_INFECTED:
			{
				Format(team, sizeof(team), "%t", "Infected");
			}
		}

		GetClientName(client, name, sizeof(name));

		if (GetConVarBool(g_hCvarColors))
		{
			CPrintToChatAllEx(client, "%t", "C Cheered!!!", team, name);
		}
		else 
		{
			PrintToChatAll("%t", "Cheered!!!", team, name);		//*%s* %s cheered!!
		}
	}

	g_cheerCount[client]++;
}

void ExcuteJeer(int client)
{
	if (GetConVarInt(g_hCvarJeer) == 1 || (GetConVarInt(g_hCvarJeer) == 2 && GetUserAdmin(client) != INVALID_ADMIN_ID))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				EmitSoundToClient(i, g_soundsListJeer[GetRandomInt(0, 12)], _, _, _, _, GetConVarFloat(g_hCvarJeerVolume));
			}
		}

		if (GetConVarBool(g_hCvarChat))
		{
			char team[64];
			char name[64];

			switch (GetClientTeam(client))
			{
				case L4D_TEAM_SPECTATOR:
				{
					Format(team, sizeof(team), "%t", "Spectator");
				}

				case L4D_TEAM_SURVIVOR:
				{
					Format(team, sizeof(team), "%t", "Survivor");
				}

				case L4D_TEAM_INFECTED:
				{
					Format(team, sizeof(team), "%t", "Infected");
				}
			}

			GetClientName(client, name, sizeof(name));

			if (GetConVarBool(g_hCvarColors))
			{
				CPrintToChatAllEx(client, "%t", "C Jeered!!!", team, name);
			}
			else 
			{
				PrintToChatAll("%t", "Jeered!!!", team, name);
			}
		}
		g_jeerCount[client]++;
	}
}

// Loads the soundsList array with the sounds
public void LoadSounds()
{
	Handle kv = CreateKeyValues("CheerSoundsList");
	char   filename[PLATFORM_MAX_PATH];
	char   buffer[30];

	BuildPath(Path_SM, filename, PLATFORM_MAX_PATH, "configs/cheersoundlist.cfg");
	FileToKeyValues(kv, filename);

	if (!KvJumpToKey(kv, "cheer sounds"))
	{
		SetFailState("configs/cheersoundlist.cfg missing cheer sounds");
		CloseHandle(kv);
		return;
	}

	for (int i = 0; i < NUM_SOUNDS; i++)
	{
		Format(buffer, sizeof(buffer), "cheer sound %i", i + 1);
		KvGetString(kv, buffer, g_soundsList[i], PLATFORM_MAX_PATH);
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "jeer sounds"))
	{
		SetFailState("configs/cheersoundlist.cfg missing jeer sounds");
		CloseHandle(kv);
		return;
	}

	for (int i = 0; i < NUM_SOUNDS; i++)
	{
		Format(buffer, sizeof(buffer), "jeer sound %i", i + 1);
		KvGetString(kv, buffer, g_soundsListJeer[i], PLATFORM_MAX_PATH);
	}

	CloseHandle(kv);
}