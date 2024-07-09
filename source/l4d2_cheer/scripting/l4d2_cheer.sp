#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sdktools>

#define PLUGIN_VERSION	   	"r2.2.0"

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

ArrayList
	g_hArrayCheerFile, g_hArrayJeerFile;

bool
	g_bIsFileLoadingFailed_Cheer = false,
	g_bIsFileLoadingFailed_Jeer = false,
	g_bIsRoundAlive = false;

/* cvar variables below all*/
ConVar
	g_hCvarWayToPlay, g_hCvarRegainTime, g_hCvarMaxChance, g_hCvarCheerSoundDir, g_hCvarEnable, g_hCvarMaxCheers, 
	g_hCvarChat, g_hCvarJeerSoundDir, g_hCvarMaxJeers, g_hCvarJeerVolume,
	g_hCvarCheerVolume, g_hCvarCompetitiveEnable, g_hCvarPlayToWho, g_hCvarCmdIntervalueEnable, g_hCvarCmdInterval;

int
	g_iCvarWayToPlay, g_iCvarEnable, g_iCvarMaxChance, g_iCvarMaxCheers, g_iCvarMaxJeers, g_iCvarChat, g_iCvarPlayToWho;
	
float
	g_fCvarRegainTime, g_fCvarJeerVolume, g_fCvarCheerVolume, g_fCvarCmdInterval;

bool
	g_bCvarCompetitiveEnable, g_bCvarCmdIntervalueEnable;

char
	g_sCvarCheerSoundDir[PLATFORM_MAX_PATH], g_sCvarJeerSoundDir[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	// ConVars
	CreateConVar("l4d2_cheer_version", PLUGIN_VERSION, "Cheer Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

	g_hCvarWayToPlay = CreateConVar("cheer_way_to_play", "2",
									 "The way to play sounds. \
									 1 = global chances is limited by cvars below, \
									 2 = global chance will regain with the time passing, which means global chance is only affected by these 2 cvars below.");
									 
	g_hCvarRegainTime = CreateConVar("cheer_regain_time", "20.0", "The time to regain a chance to use command");
	g_hCvarMaxChance = CreateConVar("cheer_max_chance", "3", "Max chance to use command. The chance will regain");

	g_hCvarEnable = CreateConVar("cheer_enable", "3",
								"Enables the cheer. \
								0 = disable all, \
								1 = enable cheer, \
								2 = enable jeer, \
								3 = enable both cheer and jeer.");

	g_hCvarCheerSoundDir = CreateConVar("cheer_sound_dir", "nepu/cheer", "Sound file directory under the directory 'sound/...'");
	g_hCvarMaxCheers = CreateConVar("cheer_limit", "10", "The maximum number of cheers per round. This cvar is ignored if 'cheer_way_to_play' is set to 2 or 'cheer_competitive_mode_enable' is on");
	g_hCvarCheerVolume = CreateConVar("cheer_volume", "1.0", "Cheer volume: should be a number between 0.0. and 1.0");
	g_hCvarJeerSoundDir = CreateConVar("jeer_sound_dir", "nepu/jeer", "Sound file directory under the directory 'sound/...'");
	g_hCvarMaxJeers	= CreateConVar("jeer_limit", "10", "The maximum number of jeers per round. This cvar is ignored if 'cheer_way_to_play' is set to 2 or 'cheer_competitive_mode_enable' is on");
	g_hCvarJeerVolume = CreateConVar("jeer_volume", "1.0", "Jeer volume: should be a number between 0.0. and 1.0");

	g_hCvarChat	= CreateConVar("cheer_chat", "2",
								"The way we print chat messages. \
								0 = Dont print message at all, \
								1 = Print to teammates, \
								2 = To all players");

	g_hCvarPlayToWho = CreateConVar("cheer_play_to_who", "2", 
									"Play sounds only to who?\
									1 = to the player that used the command, \
									2 = to the team that the player that used the command is on, \
									3 = to all players.");

	g_hCvarCmdIntervalueEnable = CreateConVar("cheer_cmd_interval_enable", "0", "Enable command interval? This cvar is ignored if 'cheer_competitive_mode_enable' is enabled");
	g_hCvarCmdInterval = CreateConVar("cheer_cmd_interval", "3.0", "Interval to cheer or jeer next time");
	g_hCvarCompetitiveEnable = CreateConVar("cheer_competitive_mode_enable", "0", "Enables the command in competitive mode when the round begins? This cvar is ignored if 'cheer_way_to_play' is set to 2");

	AddCvarChangeHook();
	SetCvar();
	InitIndex();

	// Cmd
	RegConsoleCmd("sm_cheer", CommandCheer);
	RegConsoleCmd("sm_jeer", CommandJeer);

	// Translations
	LoadTranslations("l4d2_cheer.phrases");

	// Load Sounds
	g_hArrayCheerFile = new ArrayList(PLATFORM_MAX_PATH);
	g_hArrayJeerFile = new ArrayList(PLATFORM_MAX_PATH);
	LoadSounds();

	// Hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

void AddCvarChangeHook()
{
	g_hCvarWayToPlay.AddChangeHook(OnCvarChanged);
	g_hCvarRegainTime.AddChangeHook(OnCvarChanged);
	g_hCvarMaxChance.AddChangeHook(OnCvarChanged);
	g_hCvarCheerSoundDir.AddChangeHook(OnCvarChanged);
	g_hCvarEnable.AddChangeHook(OnCvarChanged);
	g_hCvarMaxCheers.AddChangeHook(OnCvarChanged);
	g_hCvarChat.AddChangeHook(OnCvarChanged);
	g_hCvarJeerSoundDir.AddChangeHook(OnCvarChanged);
	g_hCvarMaxJeers.AddChangeHook(OnCvarChanged);
	g_hCvarJeerVolume.AddChangeHook(OnCvarChanged);
	g_hCvarCheerVolume.AddChangeHook(OnCvarChanged);
	g_hCvarCompetitiveEnable.AddChangeHook(OnCvarChanged);
	g_hCvarPlayToWho.AddChangeHook(OnCvarChanged);
	g_hCvarCmdIntervalueEnable.AddChangeHook(OnCvarChanged);
	g_hCvarCmdInterval.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetCvar();
}

void SetCvar()
{
	g_iCvarWayToPlay = g_hCvarWayToPlay.IntValue;
	g_iCvarMaxChance = g_hCvarMaxChance.IntValue;
	g_iCvarEnable = g_hCvarEnable.IntValue;
	g_iCvarMaxCheers = g_hCvarMaxCheers.IntValue;
	g_iCvarMaxJeers = g_hCvarMaxJeers.IntValue;
	g_iCvarChat = g_hCvarChat.IntValue;
	g_iCvarPlayToWho = g_hCvarPlayToWho.IntValue;

	g_fCvarRegainTime = g_hCvarRegainTime.FloatValue;
	g_fCvarCheerVolume = g_hCvarCheerVolume.FloatValue;
	g_fCvarJeerVolume = g_hCvarJeerVolume.FloatValue;
	g_fCvarCmdInterval = g_hCvarCmdInterval.FloatValue;
	
	g_bCvarCompetitiveEnable = g_hCvarCompetitiveEnable.BoolValue;
	g_bCvarCmdIntervalueEnable = g_hCvarCmdIntervalueEnable.BoolValue;

	g_hCvarCheerSoundDir.GetString(g_sCvarCheerSoundDir, sizeof(g_sCvarCheerSoundDir));
	g_hCvarJeerSoundDir.GetString(g_sCvarJeerSoundDir, sizeof(g_sCvarJeerSoundDir));
}

public void OnMapStart()
{
	OnMapStart_Do(true);
	OnMapStart_Do(false);
}

void OnMapStart_Do(bool bCheerOrJeer)
{
	if (bCheerOrJeer)
	{
		if (g_hArrayCheerFile.Length == 0)
		{
			g_bIsFileLoadingFailed_Cheer = true;
			return;
		}
	}
	else
	{
		if (g_hArrayJeerFile.Length == 0)
		{
			g_bIsFileLoadingFailed_Jeer = true;
			return;
		}
	}

	char sPath[PLATFORM_MAX_PATH];
	for (int i = 0; i < (bCheerOrJeer ? g_hArrayCheerFile.Length : g_hArrayJeerFile.Length); i++)
	{
		if (bCheerOrJeer)
		{
			if (g_hArrayCheerFile.GetString(i, sPath, sizeof(sPath)))
			{
				if (PrecacheSound(sPath, true))
					PrintToServer("[Cheer!] File %s precached successfully!", sPath);
			}
		}
		else
		{
			if (g_hArrayJeerFile.GetString(i, sPath, sizeof(sPath)))
			{
				if (PrecacheSound(sPath, true))
					PrintToServer("[Cheer!] File %s precached successfully!", sPath);
			}
		}
	}
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
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
		g_fLastTimeCheer[client] = GetEngineTime();
		g_fLastTimeJeer[client] = GetEngineTime();
		g_iCurrentCheerChance[client] = g_iCvarMaxChance;
		g_iCurrentJeerChance[client] = g_iCvarMaxChance;
	}
}

void RestoreIndexes()
{
	SetIndex();
	g_bIsRoundAlive = false;
}

void InitIndex()
{
	SetIndex();
}

void SetIndex()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		g_iCheerCount[i] = 0;
		g_iJeerCount[i]	= 0;
		g_fLastTimeCheer[i] = GetEngineTime();
		g_fLastTimeJeer[i] = GetEngineTime();
		g_iCurrentCheerChance[i] = g_iCvarMaxChance;
		g_iCurrentJeerChance[i] = g_iCvarMaxChance;
	}
}

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
	switch (g_iCvarEnable)
	{
		case 0:
		{
			CReplyToCommand(client, "%t", "disabled");
			return;
		}

		case 1:
		{
			if (!bCheerOrJeer)
			{
				CReplyToCommand(client, "%t", "jeer_disabled");
				return;
			}
		}

		case 2:
		{
			if (bCheerOrJeer)
			{
				CReplyToCommand(client, "%t", "cheer_disabled");
				return;
			}
		}
	}

	if (g_bCvarCmdIntervalueEnable)
	{
		if ((GetEngineTime() - (bCheerOrJeer ? g_fLastTimeCheer[client] : g_fLastTimeJeer[client])) < g_fCvarCmdInterval)
		{
			int iTimeLeft = RoundToNearest(g_fCvarCmdInterval - (GetEngineTime() - (bCheerOrJeer ? g_fLastTimeCheer[client] : g_fLastTimeJeer[client])));
			CPrintToChat(client, "%t", bCheerOrJeer ? "cheer_interval_limited" : "jeer_interval_limited", iTimeLeft);
			return;
		}
	}

	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return;

	if (g_iCvarWayToPlay == 2)
	{
		if (bCheerOrJeer ? (g_iCurrentCheerChance[client] == 0) : (g_iCurrentJeerChance[client] == 0))
		{
			CPrintToChat(client, "%t", "Recharging");
			return;
		}
		else
		{
			ExcuteCheerOrJeer(bCheerOrJeer, client);
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
	}
}

void ExcuteCheerOrJeer(bool bCheerOrJeer, int client)
{
	if (!(bCheerOrJeer ? g_bIsFileLoadingFailed_Cheer : g_bIsFileLoadingFailed_Jeer))
	{
		char sBuffer[PLATFORM_MAX_PATH];
		if (bCheerOrJeer) g_hArrayCheerFile.GetString(GetRandomInt(0, g_hArrayCheerFile.Length - 1), sBuffer, PLATFORM_MAX_PATH);
		else g_hArrayJeerFile.GetString(GetRandomInt(0, g_hArrayCheerFile.Length - 1), sBuffer, PLATFORM_MAX_PATH);

		/* EmitSound*() plays a sound on an entity (of course, client is an entity as well),
		 * which means the sound will be emitted and spread out from the entity's position.
		 * g_iCvarPlayToWho decides how many sound will be emitted, which avoids this to be noisy..
		 */
		switch (g_iCvarPlayToWho)
		{
			case 1: EmitSoundToClient(client, sBuffer, _, _, _, _, bCheerOrJeer ? g_fCvarCheerVolume : g_fCvarJeerVolume);
			case 2:
			{
				L4DTeam team = L4D_GetClientTeam(client);
				for (int i = 0; i < MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && team == L4D_GetClientTeam(i))
					{
						EmitSoundToClient(i, sBuffer, _, _, _, _, bCheerOrJeer ? g_fCvarCheerVolume : g_fCvarJeerVolume);
					}
				}
			}
			case 3: EmitSoundToAll(sBuffer, _, _, _, _, bCheerOrJeer ? g_fCvarCheerVolume : g_fCvarJeerVolume);
		}
	}

	switch (g_iCvarChat)
	{
		case 2:
		{
			if (g_iCvarPlayToWho)
			{
				L4DTeam team = L4D_GetClientTeam(client);
				for (int i = 0; i < MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && team == L4D_GetClientTeam(i) )
						CPrintToChatEx(client, client, bCheerOrJeer ? "Cheered!!!" : "Jeered!!!", client);
				}
			}
		}
		case 3: CPrintToChatAllEx(client, "%t", bCheerOrJeer ? "Cheered!!!" : "Jeered!!!", client);
	}

	if (bCheerOrJeer) g_fLastTimeCheer[client] = GetEngineTime();
	else g_fLastTimeJeer[client] = GetEngineTime();
	 
	if (g_iCvarWayToPlay == 2) 
	{
		bCheerOrJeer ? g_iCurrentCheerChance[client]-- : g_iCurrentJeerChance[client]--;
		if ((bCheerOrJeer ? g_iCurrentCheerChance[client] : g_iCurrentJeerChance[client]) < g_iCvarMaxChance)
		{
			DataPack dp;
			CreateDataTimer(g_fCvarRegainTime, DPTimer_RegainChance, dp);
			dp.WriteCell(client);
			dp.WriteCell(bCheerOrJeer);
		}	
	}
	else bCheerOrJeer ? g_iCheerCount[client]++ : g_iJeerCount[client]++;
}

Action DPTimer_RegainChance(Handle Timer, DataPack dp)
{
	dp.Reset();
	int client = dp.ReadCell();
	bool bCheerOrJeer = dp.ReadCell();
	bCheerOrJeer ? g_iCurrentCheerChance[client]++ : g_iCurrentJeerChance[client]++;
	return Plugin_Handled;
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
	char sBuffer[PLATFORM_MAX_PATH];
	int iLen; char SoundFile[PLATFORM_MAX_PATH];
	FileType fileType;

	/**
	 * Note: When use OpenDirectory(), you need to specify concisely the folder in the base game dir.
	 * When use PrecacheSound() and EmitSound*(), the path string dose not need the prefix 'sound/',
	 * the function will automatically search the file under the dir 'sound/' based on the path you put in.
	 */
	Format(sBuffer, PLATFORM_MAX_PATH, sPath);
	Format(sPath, PLATFORM_MAX_PATH, "sound/%s", sPath);
	hDir = OpenDirectory(sPath, false);
	if (hDir)
	{
		int i = 0;
		while (hDir.GetNext(SoundFile, PLATFORM_MAX_PATH, fileType))
		{
			if (fileType == FileType_File)
			{
				iLen = strlen(SoundFile);
				
				// maybe we should use .wav instead? issues with .mp3 really messed me up.
				if (iLen >= 4 && (strcmp(SoundFile[iLen - 4], ".mp3") == 0 || strcmp(SoundFile[iLen - 4], ".wav") == 0))
				{
					Format(SoundFile, sizeof(SoundFile), "%s/%s", sBuffer, SoundFile);
					if (bCheerOrJeer) g_hArrayCheerFile.PushString(SoundFile);
					else g_hArrayJeerFile.PushString(SoundFile);
					i++;
				}
			}
		}
		if (i == 0)
			LogError("[Cheer!] No sound files found in '%s'.", sPath);
	}
	else
		LogError("[Cheer!] handle 'hDir' is null! '%s' is not a valid directory.", sPath);
}