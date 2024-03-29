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

	r1.3: 8/6/23
		* Optimized code format.
		* Added in round check. We allow players to ues cheer or jeer in scavenge or versus mode while round is live, switch and limits is controlled by new added cvar.

	r1.3.1: 8/6/23
		* Added a cvar to control wether a client should download sound files. (there's more other effecient ways to download files, we don't recommend to do this on this plugin.)

	r1.3.2: 8/7/23
		* Added a cvar to control the interval we can cheer or jeer next time, preventing chat spamming.
		* more mutation gamemode detections.

	r1.3.3: 9/13/23
		* Added a cvar to control the sound file number we can load. Now we can load each cheer or jeer files up to 128 at a time. (still confusing if there is anyway to turn this 128 into a valid varible.)

	to do:
		* unlock the limit sound files we can load.
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION	   	"r1.3.3"

#define L4D_TEAM_SPECTATOR 	1
#define L4D_TEAM_SURVIVOR  	2
#define L4D_TEAM_INFECTED  	3

// Plugin definitions
public Plugin myinfo =
{
	name		= "[L4D2] Cheer!",
	author		= "dalto, L4D2 modified version by blueblur",
	description = "The Cheer! plugin allows players to cheer random cheers per round",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/blueblur0730/modified-plugins"
};

int
	g_iCheerCount[MAXPLAYERS + 1],
	g_iJeerCount[MAXPLAYERS + 1],
	g_iCheerInRoundCount[MAXPLAYERS + 1],
	g_iJeerInRoundCount[MAXPLAYERS + 1];

float
	g_fLastTimeCheer[MAXPLAYERS + 1],
	g_fLastTimeJeer[MAXPLAYERS + 1];

ConVar
	g_hCvarEnabled,
	g_hCvarMaxCheers,
	g_hCvarChat,
	g_hCvarColors,
	g_hCvarJeer,
	g_hCvarMaxJeers,
	g_hCvarJeerVolume,
	g_hCvarCheerVolume,
	g_hCvarSoundNumber,
	g_hCvarInRoundEnable,
	g_hCvarInRoundMaxCheers,
	g_hCvarInRoundMaxJeers,
	g_hCvarDownloadEnable,
	g_hCvarCmdIntervalueEnable,
	g_hCvarCmdInterval;

#define NUM_SOUNDS		   	(GetConVarInt(g_hCvarSoundNumber))

char
	g_soundsList[128][PLATFORM_MAX_PATH],
	g_soundsListJeer[128][PLATFORM_MAX_PATH];

bool
	// g_bReadyUpAvailable 	= false,
	g_bIsRoundAlive = false;

public void OnPluginStart()
{
	// ConVars
	CreateConVar("sm_cheer_version", PLUGIN_VERSION, "Cheer Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

	g_hCvarEnabled			   = CreateConVar("sm_cheer_enable", "1", "Enables the Cheer! plugin");
	g_hCvarJeer				   = CreateConVar("sm_cheer_jeer", "1", "0 to disable jeers, 1 to enable for all, 2 for admin only");
	g_hCvarColors			   = CreateConVar("sm_cheer_colors", "1", "1 to turn chat colors on, 0 for off");
	g_hCvarChat				   = CreateConVar("sm_cheer_chat", "1", "1 to turn enable chat messages, 0 for off");

	g_hCvarMaxCheers		   = CreateConVar("sm_cheer_limit", "10", "The maximum number of cheers per round");
	g_hCvarMaxJeers			   = CreateConVar("sm_cheer_jeer_limit", "10", "The maximum number of jeers per round");
	g_hCvarJeerVolume		   = CreateConVar("sm_cheer_jeer_volume", "1.0", "Jeer volume: should be a number between 0.0. and 1.0");
	g_hCvarCheerVolume		   = CreateConVar("sm_cheer_volume", "1.0", "Cheer volume: should be a number between 0.0. and 1.0");

	g_hCvarCmdIntervalueEnable = CreateConVar("sm_cheer_cmd_interval_enable", "1", "Enable commander interval? (Prevent chat spamming)");
	g_hCvarCmdInterval		   = CreateConVar("sm_cheer_cmd_interval", "5.0", "Interval we can cheer or jeer next time");

	g_hCvarInRoundEnable	   = CreateConVar("sm_cheer_in_round_enable", "1", "Enables the Cheer! plugin in round");
	g_hCvarInRoundMaxCheers	   = CreateConVar("sm_cheer_in_round_cheer_limit", "5", "The maximum number of cheers in round");
	g_hCvarInRoundMaxJeers	   = CreateConVar("sm_cheer_in_round_jeer_limit", "5", "The maximum number of jeers in round");

	g_hCvarSoundNumber   	   = CreateConVar("sm_cheer_sound_number", "12", "Maximum sound number to load on the list (max number is 128)", _, _, _, true, 128.0);
	g_hCvarDownloadEnable	   = CreateConVar("sm_cheer_download_enable", "0", "Enable download generated by Cheer! plugin ?");

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
	g_hCvarSoundNumber.AddChangeHook(OnLoadNumberChanged);
}

public void OnMapStart()
{
	for (int sound = 0; sound < NUM_SOUNDS; sound++)
	{
		char downloadFile[PLATFORM_MAX_PATH];

		if (!StrEqual(g_soundsList[sound], ""))
		{
			PrecacheSound(g_soundsList[sound], true);

			if (g_hCvarDownloadEnable.BoolValue)
			{
				Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", g_soundsList[sound]);
				AddFileToDownloadsTable(downloadFile);
			}
		}

		if (!StrEqual(g_soundsListJeer[sound], ""))
		{
			PrecacheSound(g_soundsListJeer[sound], true);

			if (g_hCvarDownloadEnable.BoolValue)
			{
				Format(downloadFile, PLATFORM_MAX_PATH, "sound/%s", g_soundsListJeer[sound]);
				AddFileToDownloadsTable(downloadFile);
			}
		}
	}
}

public void OnLoadNumberChanged(ConVar convar, const char[] sOldGameMode, const char[] sNewGameMode)
{
	LoadSounds();
}

// Initializations to be done at the beginning of the round
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		g_iCheerCount[i]		= 0;
		g_iJeerCount[i]			= 0;
		g_iCheerInRoundCount[i] = 0;
		g_iJeerInRoundCount[i]	= 0;
		g_fLastTimeCheer[i] 	= 0.0;
		g_fLastTimeJeer[i]		= 0.0;
	}

	g_bIsRoundAlive = false;
}

public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		g_iCheerCount[i]		= 0;
		g_iJeerCount[i]			= 0;
		g_iCheerInRoundCount[i] = 0;
		g_iJeerInRoundCount[i]	= 0;
		g_fLastTimeCheer[i] 	= 0.0;
		g_fLastTimeJeer[i]		= 0.0;
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
		g_iCheerCount[client]		 = 0;
		g_iJeerCount[client]		 = 0;
		g_iCheerInRoundCount[client] = 0;
		g_iJeerInRoundCount[client]	 = 0;
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
	if (!g_hCvarEnabled.BoolValue)
	{
		return Plugin_Handled;
	}

	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if (g_iCheerCount[client] >= g_hCvarMaxCheers.IntValue)
	{
		CPrintToChat(client, "%t", "over cheer limit", g_hCvarMaxCheers.IntValue);
		return Plugin_Handled;
	}

	if (g_hCvarCmdIntervalueEnable.BoolValue)
	{
		float fDelayTime = g_hCvarCmdInterval.FloatValue;

		if (g_iCheerCount[client] == 0)
		{
			g_fLastTimeCheer[client] = GetEngineTime();
		}
		else if (GetEngineTime() - g_fLastTimeCheer[client] < fDelayTime) // if (current time - last time cheered < interval we set previously) ?
		{
			int iTimeLeft = RoundToNearest(fDelayTime - (GetEngineTime() - g_fLastTimeCheer[client]));
			CPrintToChat(client, "%t", "cheer interval limited", iTimeLeft);
			return Plugin_Handled;
		}
	}

	if (IsVersusMode() || IsScavengeMode())
	{
		if (g_bIsRoundAlive)
		{
			if (g_hCvarInRoundEnable.IntValue == 1)
			{
				if (g_iCheerInRoundCount[client] >= g_hCvarInRoundMaxCheers.IntValue)
				{
					CPrintToChat(client, "%t", "over in round cheer limit", g_hCvarInRoundMaxCheers.IntValue);
					return Plugin_Handled;
				}
				else
				{
					ExcuteCheer(client);
					g_fLastTimeCheer[client] = GetEngineTime();
				}
			}
			else
			{
				CPrintToChat(client, "%t", "round is live");
				return Plugin_Handled;
			}
		}
		else
		{
			ExcuteCheer(client);
			g_fLastTimeCheer[client] = GetEngineTime();
		}
	}
	else
	{
		ExcuteCheer(client);
		g_fLastTimeCheer[client] = GetEngineTime();
	}

	return Plugin_Handled;
}

Action CommandJeer(int client, int args)
{
	if (!g_hCvarEnabled.BoolValue)
	{
		return Plugin_Handled;
	}

	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	if (g_iJeerCount[client] >= g_hCvarMaxJeers.IntValue)
	{
		CPrintToChat(client, "%t", "over jeer limit", g_hCvarMaxJeers.IntValue);
		return Plugin_Handled;
	}

	if (g_hCvarCmdIntervalueEnable.BoolValue)
	{
		float fDelayTime = g_hCvarCmdInterval.FloatValue;

		if (g_iJeerCount[client] == 0)
		{
			g_fLastTimeJeer[client] = GetEngineTime();
		}
		else if (GetEngineTime() - g_fLastTimeJeer[client] < fDelayTime)
		{
			int iTimeLeft = RoundToNearest(fDelayTime - (GetEngineTime() - g_fLastTimeJeer[client]));
			CPrintToChat(client, "%t", "jeer interval limited", iTimeLeft);
			return Plugin_Handled;
		}
	}

	if (IsVersusMode() || IsScavengeMode())
	{
		if (g_bIsRoundAlive)
		{
			if (g_hCvarInRoundEnable.IntValue == 1)
			{
				if (g_iJeerInRoundCount[client] >= g_hCvarInRoundMaxJeers.IntValue)
				{
					CPrintToChat(client, "%t", "over in round Jeer limit", g_hCvarInRoundMaxJeers.IntValue);
					return Plugin_Handled;
				}
				else
				{
					ExcuteJeer(client);
					g_fLastTimeJeer[client] = GetEngineTime();
				}
			}
			else
			{
				CPrintToChat(client, "%t", "round is live");
				return Plugin_Handled;
			}
		}
		else
		{
			ExcuteJeer(client);
			g_fLastTimeJeer[client] = GetEngineTime();
		}
	}
	else
	{
		ExcuteJeer(client);
		g_fLastTimeJeer[client] = GetEngineTime();
	}

	return Plugin_Handled;
}

void ExcuteCheer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			EmitSoundToClient(i, g_soundsList[GetRandomInt(0, NUM_SOUNDS - 1)], _, _, _, _, g_hCvarCheerVolume.FloatValue);
		}
	}

	if (g_hCvarChat.BoolValue)
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

		if (g_hCvarColors.BoolValue)
		{
			CPrintToChatAllEx(client, "%t", "C Cheered!!!", team, name);
		}
		else
		{
			PrintToChatAll("%t", "Cheered!!!", team, name);	   //*%s* %s cheered!!
		}
	}

	g_iCheerCount[client]++;

	if (g_bIsRoundAlive)
	{
		g_iCheerInRoundCount[client]++;
	}
}

void ExcuteJeer(int client)
{
	if (g_hCvarJeer.IntValue == 1 || (g_hCvarJeer.IntValue == 2 && GetUserAdmin(client) != INVALID_ADMIN_ID))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				EmitSoundToClient(i, g_soundsListJeer[GetRandomInt(0, NUM_SOUNDS - 1)], _, _, _, _, g_hCvarJeerVolume.FloatValue);
			}
		}

		if (g_hCvarChat.BoolValue)
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

			if (g_hCvarColors.BoolValue)
			{
				CPrintToChatAllEx(client, "%t", "C Jeered!!!", team, name);
			}
			else
			{
				PrintToChatAll("%t", "Jeered!!!", team, name);
			}
		}

		g_iJeerCount[client]++;

		if (g_bIsRoundAlive)
		{
			g_iCheerInRoundCount[client]++;
		}
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

stock bool IsVersusMode()
{
	char   sCurGameMode[64];
	ConVar CurGameMode = FindConVar("mp_gamemode");
	GetConVarString(CurGameMode, sCurGameMode, sizeof(sCurGameMode));
	if (strcmp(sCurGameMode, "versus") == 0 || \
	strcmp(sCurGameMode, "mutation11") == 0 || \
	strcmp(sCurGameMode, "mutation12") == 0 || \
	strcmp(sCurGameMode, "mutation18") == 0 || \
	strcmp(sCurGameMode, "mutation19") == 0)
		return true;
	else
		return false;
}

stock bool IsScavengeMode()
{
	char   sCurGameMode[64];
	ConVar CurGameMode = FindConVar("mp_gamemode");
	GetConVarString(CurGameMode, sCurGameMode, sizeof(sCurGameMode));
	if (strcmp(sCurGameMode, "scavenge") == 0 || \
	strcmp(sCurGameMode, "mutation13") == 0)		// follow the liter (liner scavenge)
		return true;
	else
		return false;
}