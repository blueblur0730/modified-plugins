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
		* add team preflexes.

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
		* unlock the limit of sound files we can load.
------------------------------------------------------------
2024
	r2.0.0: 6/7/24
		* Finshed to do. Credits to MapChanger by Alex Dragokas.
			- Removed config file. Now plugin will precache file automatically by the preset path in the sound/.. directory.
				- Added new convar "cheer_sound_dir" and "jeer_sound_dir" to specify the sound path to precache.
				- Removed convar "sm_cheer_sound_number" and "sm_cheer_colors" 谁不在colors啊我也在colors啊colors就得应该是colors而不是不colors
		* Renamed convars.
		* Reformatted codes.
		* Code optimizations and simplifizations.
		* Translations reformatted. Removed two non-color phrases.
		* Added Left4DHooks to identify gamemode. (More directly isn't ?)
		* Removed sourcemod cfg cvar file. I dont like it.
	  + to do:
		* New choice. Added more convar to control the way we use.
		* Add a way to use. Player only have 3 chances to use commands, but the chance will regain with the time passing. Like what ExG ze dose.
		* Let user himself choose wether to unlimit the chance or other things in competitive gamemodes.
	
	r2.1.0: 6/9/24
		* Added cvar change hook.
		* Removed cvar "cheer_in_round_limit", "jeer_in_round_limit".
		* Added cvar "cheer_way_to_play", "cheer_regain_time", "cheer_max_chance" (to do *3/1).
		* Renamed cvar "cheer_in_round_enable" to "cheer_competitive_mode_enable".
		* No longer limit while round began when in competitive mod.

	r2.1.1: 6/10/24
		* Removed team name preflex tag translations and unused translations.
		* Finished to do *2
		* Added new translation phrase "Rechargeing"
		* If "cheer_competitive_mode_enable" is on, ignore cvar "cheer_cmd_interval_enable" "cheer_limit" "jeer_limit"
		* Logic optimized.
		* Removed unecessary library sdktools. (why is it here?)
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>
#include <left4dhooks>

#define PLUGIN_VERSION	   	"r2.1.1"

// Plugin definitions
public Plugin myinfo =
{
	name = "[L4D2] Cheer!",
	author = "dalto, blueblur",
	description = "The Cheer! plugin allows players to cheer random cheers per round",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

int
	g_iCheerCount[MAXPLAYERS + 1],
	g_iJeerCount[MAXPLAYERS + 1],
	g_iCurrentCheerChance[MAXPLAYERS + 1],
	g_iCurrentJeerChance[MAXPLAYERS + 1];

float
	g_fLastTimeCheer[MAXPLAYERS + 1],
	g_fLastTimeJeer[MAXPLAYERS + 1];

ConVar
	g_hCvarWayToPlay, g_hCvarRegainTime, g_hCvarMaxChance, g_hCvarCheerSoundDir, g_hCvarCheer, g_hCvarMaxCheers, 
	g_hCvarChat, g_hCvarJeerSoundDir, g_hCvarJeer, g_hCvarMaxJeers, g_hCvarJeerVolume,
	g_hCvarCheerVolume, g_hCvarCompetitiveEnable, g_hCvarDownloadEnable, g_hCvarCmdIntervalueEnable, g_hCvarCmdInterval;

int
	g_iCvarWayToPlay, g_iCvarMaxChance, g_iCvarMaxCheers, g_iCvarMaxJeers;
	
float
	g_fCvarRegainTime, g_fCvarJeerVolume, g_fCvarCheerVolume, g_fCvarCmdInterval;

bool
	g_bCvarCheer, g_bCvarChat, g_bCvarJeer, g_bCvarCompetitiveEnable, g_bCvarDownloadEnable, g_bCvarCmdIntervalueEnable;

char
	g_sCvarCheerSoundDir[PLATFORM_MAX_PATH], g_sCvarJeerSoundDir[PLATFORM_MAX_PATH];

StringMap
	g_hMapCheerFile, g_hMapJeerFile;

bool
	g_bIsRoundAlive = false;

public void OnPluginStart()
{
	// ConVars
	CreateConVar("cheer_version", PLUGIN_VERSION, "Cheer Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

	g_hCvarWayToPlay = CreateConVar("cheer_way_to_play", "2",
									 "The way to play sounds. \
									 1 = global chances is limited by cvars below, \
									 2 = global chance will regain with the time passing, which means global chance is only affected by these 3 cvars below.");
	g_hCvarRegainTime = CreateConVar("cheer_regain_time", "20.0", "The time to regain a chance to use command");
	g_hCvarMaxChance = CreateConVar("cheer_max_chance", "3", "Max chance to use command. The chance will regain");

	g_hCvarCheer = CreateConVar("cheer_enable", "1", "Enables the cheer");
	g_hCvarCheerSoundDir = CreateConVar("cheer_sound_dir", "sound/nepu/cheer", "Sound file directory");
	g_hCvarMaxCheers = CreateConVar("cheer_limit", "10", "The maximum number of cheers per round. This cvar is ignored if 'cheer_way_to_play' is set to 2 or 'cheer_competitive_mode_enable' is on");
	g_hCvarCheerVolume = CreateConVar("cheer_volume", "1.0", "Cheer volume: should be a number between 0.0. and 1.0");

	g_hCvarJeer	= CreateConVar("jeer_enable", "1", "Enables the jeer");
	g_hCvarJeerSoundDir = CreateConVar("jeer_sound_dir", "sound/nepu/jeer", "Sound file directory");
	g_hCvarMaxJeers	= CreateConVar("jeer_limit", "10", "The maximum number of jeers per round. This cvar is ignored if 'cheer_way_to_play' is set to 2 or 'cheer_competitive_mode_enable' is on");
	g_hCvarJeerVolume = CreateConVar("jeer_volume", "1.0", "Jeer volume: should be a number between 0.0. and 1.0");

	g_hCvarChat	= CreateConVar("cheer_chat", "1", "1 to turn enable chat messages, 0 for off");
	g_hCvarCmdIntervalueEnable = CreateConVar("cheer_cmd_interval_enable", "0", "Enable command interval? This cvar is ignored if 'cheer_competitive_mode_enable' is enabled");
	g_hCvarCmdInterval = CreateConVar("cheer_cmd_interval", "3.0", "Interval to cheer or jeer next time");
	g_hCvarCompetitiveEnable = CreateConVar("cheer_competitive_mode_enable", "0", "Enables the command in competitive mode when the round begins? This cvar is ignored if 'cheer_way_to_play' is set to 2");

	g_hCvarDownloadEnable = CreateConVar("cheer_download_enable", "0", "Enable download generated by Cheer! plugin ?");

	AddCvarChangeHook();

	// Cmd
	RegConsoleCmd("sm_cheer", CommandCheer);
	RegConsoleCmd("sm_jeer", CommandJeer);

	// Translations
	LoadTranslations("cheer.phrases");

	// Load Sounds
	g_hMapCheerFile = new StringMap();
	g_hMapJeerFile = new StringMap();
	LoadSounds();

	// Hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_PostNoCopy);
}

void AddCvarChangeHook()
{
	g_hCvarWayToPlay.AddChangeHook(OnCvarChanged);
	g_hCvarRegainTime.AddChangeHook(OnCvarChanged);
	g_hCvarMaxChance.AddChangeHook(OnCvarChanged);
	g_hCvarCheerSoundDir.AddChangeHook(OnCvarChanged);
	g_hCvarCheer.AddChangeHook(OnCvarChanged);
	g_hCvarMaxCheers.AddChangeHook(OnCvarChanged);
	g_hCvarChat.AddChangeHook(OnCvarChanged);
	g_hCvarJeerSoundDir.AddChangeHook(OnCvarChanged);
	g_hCvarJeer.AddChangeHook(OnCvarChanged);
	g_hCvarMaxJeers.AddChangeHook(OnCvarChanged);
	g_hCvarJeerVolume.AddChangeHook(OnCvarChanged);
	g_hCvarCheerVolume.AddChangeHook(OnCvarChanged);
	g_hCvarCompetitiveEnable.AddChangeHook(OnCvarChanged);
	g_hCvarDownloadEnable.AddChangeHook(OnCvarChanged);
	g_hCvarCmdIntervalueEnable.AddChangeHook(OnCvarChanged);
	g_hCvarCmdInterval.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarWayToPlay = g_hCvarWayToPlay.IntValue;
	g_iCvarMaxChance = g_hCvarMaxChance.IntValue;
	g_iCvarMaxCheers = g_hCvarMaxCheers.IntValue;
	g_iCvarMaxJeers = g_hCvarMaxJeers.IntValue;

	g_fCvarRegainTime = g_hCvarRegainTime.FloatValue;
	g_fCvarCheerVolume = g_hCvarCheerVolume.FloatValue;
	g_fCvarJeerVolume = g_hCvarJeerVolume.FloatValue;
	g_fCvarCmdInterval = g_hCvarCmdInterval.FloatValue;

	g_bCvarCheer = g_hCvarCheer.BoolValue;
	g_bCvarChat = g_hCvarChat.BoolValue;
	g_bCvarJeer = g_hCvarJeer.BoolValue;
	g_bCvarCompetitiveEnable = g_hCvarCompetitiveEnable.BoolValue;
	g_bCvarDownloadEnable = g_hCvarDownloadEnable.BoolValue;
	g_bCvarCmdIntervalueEnable = g_hCvarCmdIntervalueEnable.BoolValue;

	g_hCvarCheerSoundDir.GetString(g_sCvarCheerSoundDir, sizeof(g_sCvarCheerSoundDir));
	g_hCvarJeerSoundDir.GetString(g_sCvarJeerSoundDir, sizeof(g_sCvarJeerSoundDir));
}

public void OnMapStart()
{
	if (g_hMapCheerFile.Size != 0)
		OnMapStart_Do(true);

	if (g_hMapJeerFile.Size != 0)
		OnMapStart_Do(false);
}

void OnMapStart_Do(bool bCheerOrJeer)
{
	char sPath[PLATFORM_MAX_PATH];
	for (int i = 0; i < (bCheerOrJeer ? g_hMapCheerFile.Size : g_hMapJeerFile.Size); i++)
	{
		char sNumber[128];
		IntToString(i, sNumber, sizeof(sNumber));
		if (bCheerOrJeer)
		{
			if (g_hMapCheerFile.GetString(sNumber, sPath, sizeof(sPath)))
				PrecacheSound(sPath, true);
		}
		else
		{
			if (g_hMapJeerFile.GetString(sNumber, sPath, sizeof(sPath)))
				PrecacheSound(sPath, true);
		}

		if (g_bCvarDownloadEnable)
			AddFileToDownloadsTable(sPath);
	}
}

public void Event_PlayerLeftStartArea(Event event, char[] name, bool dontBroadcast)
{
	g_bIsRoundAlive = true;
}

// Initializations to be done at the beginning of the round
public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	RestoreIndexes();
}

public void Event_RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	RestoreIndexes();
}

// When a new client is put in the server we reset their cheer count
public void OnClientPutInServer(int client)
{
	if (client && !IsFakeClient(client))
	{
		g_iCheerCount[client] = 0;
		g_iJeerCount[client] = 0;
		g_iCurrentCheerChance[client] = 3;
		g_iCurrentJeerChance[client] =3;
	}
}

void RestoreIndexes()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		g_iCheerCount[i] = 0;
		g_iJeerCount[i]	= 0;
		g_fLastTimeCheer[i] = 0.0;
		g_fLastTimeJeer[i] = 0.0;
		g_iCurrentCheerChance[i] = 3;
		g_iCurrentJeerChance[i] =3;
	}

	g_bIsRoundAlive = false;
}

// to pass the bool value we defined two functions here, this will make the code shorter.
Action CommandCheer(int client, int args)
{
	Command_CheerOrJeer(client, true);
	return Plugin_Handled;
}

Action CommandJeer(int client, int args)
{
	Command_CheerOrJeer(client, false);
	return Plugin_Handled;
}

void Command_CheerOrJeer(int client, bool bCheerOrJeer)
{
	if (!(bCheerOrJeer ? g_bCvarCheer : g_bCvarJeer))
	{
		ReplyToCommand(client, "%t", bCheerOrJeer ? "cheer_disabled" :"jeer_disabled");
		return;
	}

	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return;

	if (g_iCvarWayToPlay == 2)
	{
		float fRegainTime = g_fCvarRegainTime;
		if (bCheerOrJeer ? (g_iCurrentCheerChance[client] < g_iCvarMaxChance) : (g_iCurrentJeerChance[client] < g_iCvarMaxChance))
		{
			if (RoundToNearest(fRegainTime - (GetEngineTime() - (bCheerOrJeer ? g_fLastTimeCheer[client] : g_fLastTimeJeer[client]))) <= 0)
				bCheerOrJeer ? g_iCurrentCheerChance[client]++ : g_iCurrentJeerChance[client]++;

			if (bCheerOrJeer ? (g_iCurrentCheerChance[client] == 0) : (g_iCurrentJeerChance[client] == 0))
			{
				CPrintToChat(client, "%t", "Rechargeing");
				return;
			}
		}
		else
		{
			ExcuteCheerOrJeer(bCheerOrJeer, client);
			if (bCheerOrJeer) g_fLastTimeJeer[client] = GetEngineTime();
			else g_fLastTimeCheer[client] = GetEngineTime();
			return;
		}
	}

	if (g_bCvarCmdIntervalueEnable && g_iCvarWayToPlay == 1)
	{
		float fDelayTime = g_fCvarCmdInterval;

		if (bCheerOrJeer ? (g_iCheerCount[client] == 0) : (g_iJeerCount[client] == 0))
			g_fLastTimeCheer[client] = GetEngineTime();
		else
			g_fLastTimeJeer[client] = GetEngineTime();


		if (GetEngineTime() - (bCheerOrJeer ? g_fLastTimeCheer[client] : g_fLastTimeJeer[client]) < fDelayTime)
		{
			int iTimeLeft = RoundToNearest(fDelayTime - (GetEngineTime() - (bCheerOrJeer ? g_fLastTimeCheer[client] : g_fLastTimeJeer[client])));
			CPrintToChat(client, "%t", bCheerOrJeer ? "cheer_interval_limited" : "jeer_interval_limited", iTimeLeft);
			return;
		}
	}

	if (g_bCvarCompetitiveEnable && g_iCvarWayToPlay == 1)	
	{
		if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
		{
			if (!g_bIsRoundAlive)
			{
				ExcuteCheerOrJeer(bCheerOrJeer, client);
				if (bCheerOrJeer) g_fLastTimeJeer[client] = GetEngineTime();
				else g_fLastTimeCheer[client] = GetEngineTime();
				return;
			}
			else
			{
				CPrintToChat(client, "%t", "round_is_live");
				return;
			}
		}
	}

	if ((bCheerOrJeer ? (g_iCheerCount[client] >= g_iCvarMaxCheers) : (g_iJeerCount[client] >= g_iCvarMaxJeers)) && g_iCvarWayToPlay == 1)
	{
		CPrintToChat(client, "%t", bCheerOrJeer ? "over_cheer_limit" :"over_jeer_limit", bCheerOrJeer ? g_iCvarMaxCheers : g_iCvarMaxJeers);
		return;
	}
	else
	{
		ExcuteCheerOrJeer(bCheerOrJeer, client);
		if (bCheerOrJeer) g_fLastTimeJeer[client] = GetEngineTime();
		else g_fLastTimeCheer[client] = GetEngineTime();
	}
}

void ExcuteCheerOrJeer(bool bCheerOrJeer, int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			char sBuffer[PLATFORM_MAX_PATH]; char sNumber[128];
			IntToString(GetRandomInt(0, (bCheerOrJeer ? g_hMapCheerFile.Size : g_hMapJeerFile.Size)), sNumber, sizeof(sNumber));

			if (bCheerOrJeer) g_hMapCheerFile.GetString(sNumber, sBuffer, PLATFORM_MAX_PATH);
			else g_hMapJeerFile.GetString(sNumber, sBuffer, PLATFORM_MAX_PATH);

			EmitSoundToClient(i, sBuffer, _, _, _, _, bCheerOrJeer ? g_fCvarCheerVolume : g_fCvarJeerVolume);
		}
	}

	if (g_bCvarChat)
	{
		char name[64];
		GetClientName(client, name, sizeof(name));
		CPrintToChatAllEx(client, "%t", bCheerOrJeer ? "Cheered!!!" : "Jeered!!!", name);
	}

	if (g_iCvarWayToPlay == 2)
		bCheerOrJeer ? g_iCurrentCheerChance[client]-- : g_iCurrentJeerChance[client]--;
	else
		bCheerOrJeer ? g_iCheerCount[client]++ : g_iJeerCount[client]++;
}

// from MapChanger by Alex Dragokas
void LoadSounds()
{
	DirectoryListing hDir;
	LoadSounds_Do(hDir, g_sCvarCheerSoundDir, true);
	LoadSounds_Do(hDir, g_sCvarJeerSoundDir, false);
	delete hDir;
}

void LoadSounds_Do(DirectoryListing hDir, char[] sPath, bool bCheerOrJeer)
{
	int iLen; char SoundFile[PLATFORM_MAX_PATH];
	FileType fileType;

	hDir = OpenDirectory(sPath, false);
	if (hDir)
	{
		while (hDir.GetNext(SoundFile, PLATFORM_MAX_PATH, fileType))
		{
			static int i = 0;
			if (fileType == FileType_File)
			{
				iLen = strlen(SoundFile);
					
				if ( iLen >= 4 && (strcmp(SoundFile[iLen - 4], ".mp3") == 0 || strcmp(SoundFile[iLen - 4], ".wav") == 0))
				{
					char sNumber[128];
					IntToString(i, sNumber, sizeof(sNumber));
					Format(SoundFile, sizeof(SoundFile), "%s/%s", sPath, SoundFile);

					if (bCheerOrJeer) g_hMapCheerFile.SetString(sNumber, SoundFile, false);
					else g_hMapJeerFile.SetString(sNumber, SoundFile, false);
				}
			}
			i++;
		}
	}
}