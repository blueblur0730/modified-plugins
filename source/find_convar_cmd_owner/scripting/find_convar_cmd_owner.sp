#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PL_VERSION	"1.2.2"
#define DUMP_PATH_CONVAR	"data/dumpped_convars.txt"
#define DUMP_PATH_COMMAND	"data/dumpped_commands.txt"
#define DEBUG 0
#define DEBUG_MSG 0

enum struct ConVarInfo
{
	char PluginName[256];
	char cvar[256];
	char value[64];
	char flags[256];
	char description[256];
	char min[64];
	char max[64];
}

enum struct CmdInfo
{
	char PluginName[256];
	char cmd[256];
	char flags[256];
	char description[256];	
}

static const char g_sFlags[][] = {
	"FCVAR_UNREGISTERED", "FCVAR_DEVELOPMENTONLY", "FCVAR_GAMEDLL", "FCVAR_CLIENTDLL", //"FCVAR_MATERIAL_SYSTEM",
	"FCVAR_HIDDEN", "FCVAR_PROTECTED", "FCVAR_SPONLY", "FCVAR_ARCHIVE", "FCVAR_NOTIFY",
	"FCVAR_USERINFO", "FCVAR_PRINTABLEONLY", "FCVAR_UNLOGGED", "FCVAR_NEVER_AS_STRING",
	"FCVAR_REPLICATED", "FCVAR_CHEAT", "FCVAR_SS", "FCVAR_DEMO", "FCVAR_DONTRECORD",
	"FCVAR_SS_ADDED", "FCVAR_RELEASE", "FCVAR_RELOAD_MATERIALS", "FCVAR_RELOAD_TEXTURES",
	"FCVAR_NOT_CONNECTED", "FCVAR_MATERIAL_SYSTEM_THREAD", //"FCVAR_ARCHIVE_XBOX",
	"FCVAR_ARCHIVE_GAMECONSOLE", "FCVAR_ACCESSIBLE_FROM_THREADS", "_", "_", "FCVAR_SERVER_CAN_EXECUTE",
	"FCVAR_SERVER_CANNOT_QUERY", "FCVAR_CLIENTCMD_CAN_EXECUTE"
};

bool	  g_bIsPluginLoaded = false, g_bIsConfigExecuted = false;

ConVar g_hcvarHide, g_hcvarStoreNameType, g_hcvarDumpMore;

KeyValues kv;

ArrayList g_harrConVarInfo, g_harrCmdInfo;

public Plugin myinfo =
{
	name = "[ANY] Find ConVar/Command Owner",
	author = "blueblur, basic method by Bacardi",
	description = "Finds the owner of convars and cmds generated by SourceMod. (An alternative version of dump_all_cmds_cvars by Bacardi)",
	version = PL_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
}

public void OnPluginStart()
{
	CreateConVar("find_convar_cmd_owner_version", PL_VERSION, "Version of the plugin.", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);

	g_hcvarHide			 = CreateConVar("find_convar_cmd_owner_hide", "1", "hide the cvar of this plugin.", _, true, 0.0, true, 1.0);
	g_hcvarStoreNameType = CreateConVar("find_convar_cmd_owner_storenametype", "2", "1 = File and path name, 2 = Descriptive name", _, true, 1.0, true, 2.0);

	// by defualt, cvars have values and cmds have flags in the keyvalue file.
	g_hcvarDumpMore		 = CreateConVar("find_convar_cmd_owner_dumpmore", "1", "dump description and flags of the cvar and cmd, and the bounds of cvar.", _, true, 0.0, true, 1.0);
	
	RegServerCmd("sm_dumpcvar", Command_DumpCvar, "Dump");
	RegServerCmd("sm_dumpcmd", Command_DumpCmd, "Dump");

	kv = new KeyValues("ConVars");
	g_harrConVarInfo = new ArrayList(sizeof(ConVarInfo));
}

public void OnAllPluginsLoaded()
{
	g_bIsPluginLoaded = true;
}

public void OnConfigsExecuted()
{
	g_bIsConfigExecuted = true;
}

public void OnMapEnd()
{
	g_bIsPluginLoaded	= false;
	g_bIsConfigExecuted = false;
}

Action Command_DumpCvar(int args)
{
	if (!g_bIsPluginLoaded || !g_bIsConfigExecuted)
	{
		PrintToServer("All plugin is not loaded or all config is not executed yet.");
		return Plugin_Handled;
	}

	PrintToServer("Dumpping convars...");
	CollectConVars();
	FinaleOutput(false);

	return Plugin_Handled;
}

Action Command_DumpCmd(int args)
{
	if (!g_bIsPluginLoaded || !g_bIsConfigExecuted)
	{
		PrintToServer("All plugin is not loaded or all config is not executed yet.");
		return Plugin_Handled;
	}

	PrintToServer("Dumpping cmds...");
	CollectCmds();
	FinaleOutput(true);

	return Plugin_Handled;
}

// from dump_all_cmds_cvars by Bacardi https://forums.alliedmods.net/showthread.php?p=2688799
void CollectConVars()
{
	char sBuffer[256];
	bool bIsCommand = false;
	int	flags = 0;
	char sDescription[256];
	Handle hConCmdIter;			// im expecting a convar iterator

	sBuffer[0]		= '\0';
	sDescription[0] = '\0';

	if (hConCmdIter == null)
	{
		hConCmdIter = FindFirstConCommand(sBuffer, sizeof(sBuffer), bIsCommand, flags, sDescription, sizeof(sDescription));

		if (hConCmdIter == null)
		{
			PrintToServer("No convars or cmds found.");
			return;
		}
	}

	bool bNext;

	do
	{
		if (sBuffer[0] != '\0' && !bIsCommand)
			StoreBuffers(sBuffer, flags);
	}
	while ((bNext = FindNextConCommand(hConCmdIter, sBuffer, sizeof(sBuffer), bIsCommand, flags, sDescription, sizeof(sDescription))));

	if (!bNext)
		delete hConCmdIter;

	SetKvString_ConVars();
}

void StoreBuffers(const char[] sBuffer, int flags)
{
	if (g_hcvarHide.BoolValue)
	{
		if (strcmp(sBuffer, "find_convar_cmd_owner_version") == 0
			|| strcmp(sBuffer, "find_convar_cmd_owner_hide") == 0
			|| strcmp(sBuffer, "find_convar_cmd_owner_storenametype") == 0
			|| strcmp(sBuffer, "find_convar_cmd_owner_dumpmore") == 0)
			return;
	}

	if (kv == null)
		kv = new KeyValues("ConVars");

	if (g_harrConVarInfo == null)
		g_harrConVarInfo = new ArrayList(sizeof(ConVarInfo));

	ConVar hCvar = FindConVar(sBuffer);
	if (hCvar == null)
		return;

	ConVarInfo esConVarInfo;
	char sPluginName[256];
	if (hCvar.Plugin != null)
	{
		if (g_hcvarStoreNameType.IntValue == 1)
			GetPluginFilename(hCvar.Plugin, sPluginName, sizeof(sPluginName));
		else
			GetPluginInfo(hCvar.Plugin, PlInfo_Name, sPluginName, sizeof(sPluginName));

		if (StrContains(sPluginName, "/") > -1)
			ReplaceString(sPluginName, sizeof(sPluginName), "/", " | ");
		
		hCvar.GetDefault(esConVarInfo.value, sizeof(esConVarInfo.value));
		esConVarInfo.PluginName = sPluginName;
		hCvar.GetName(esConVarInfo.cvar, sizeof(esConVarInfo.cvar));

		if (g_hcvarDumpMore.BoolValue)
		{
			hCvar.GetDescription(esConVarInfo.description, sizeof(esConVarInfo.description));
			if (flags == 0)
				Format(esConVarInfo.flags, sizeof(esConVarInfo.flags), "FCVAR_NONE");
			else
			{
				for (int i = 0; i < sizeof(g_sFlags); i++)
				{
					if (flags & (1 << i))
					{
						#if DEBUG_MSG
							PrintToServer("i: %d, flags: %s", i, g_sFlags[i]);
						#endif
						Format(esConVarInfo.flags, sizeof(esConVarInfo.flags), "%s | %s", esConVarInfo.flags, g_sFlags[i]);
					}	
				}
				// wtf
				ReplaceStringEx(esConVarInfo.flags, sizeof(esConVarInfo.flags), " | ", "", 1);
				ReplaceStringEx(esConVarInfo.flags, sizeof(esConVarInfo.flags), "|", "");
				ReplaceStringEx(esConVarInfo.flags, sizeof(esConVarInfo.flags), " ", "");
			}

			float fMin, fMax;
			if (hCvar.GetBounds(ConVarBound_Lower, fMin))
				Format(esConVarInfo.min, sizeof(esConVarInfo.min), "%.02f", fMin);
			else
				esConVarInfo.min = "no limit";
			if (hCvar.GetBounds(ConVarBound_Upper, fMax))
				Format(esConVarInfo.max, sizeof(esConVarInfo.max), "%.02f", fMax);
			else
				esConVarInfo.max = "no limit";
		}
		g_harrConVarInfo.PushArray(esConVarInfo);
	}
}

void CollectCmds()
{
	char sBuffer[256];
	CmdInfo esCmdInfo;

	if (g_harrCmdInfo == null)
		g_harrCmdInfo = new ArrayList(sizeof(CmdInfo));

	CommandIterator CmdIter = new CommandIterator();
	while (CmdIter.Next())
	{
		CmdIter.GetName(sBuffer, sizeof(sBuffer));

		if (g_hcvarHide.BoolValue)
		{
			if (StrContains(sBuffer, "sm_dumpcvar") > -1
				|| StrContains(sBuffer, "sm_dumpcmd") > -1)
				continue;
		}

		if (g_hcvarDumpMore.BoolValue)
			CmdIter.GetDescription(esCmdInfo.description, sizeof(esCmdInfo.description));

		esCmdInfo.cmd = sBuffer;

		if (CmdIter.Plugin != null)
		{
			char sPluginName[256];
			if (g_hcvarStoreNameType.IntValue == 1)
				GetPluginFilename(CmdIter.Plugin, sPluginName, sizeof(sPluginName));
			else
				GetPluginInfo(CmdIter.Plugin, PlInfo_Name, sPluginName, sizeof(sPluginName));

			if (StrContains(sPluginName, "/") > -1)
				ReplaceString(sPluginName, sizeof(sPluginName), "/", " | ");

			esCmdInfo.PluginName = sPluginName;

			if (CmdIter.Flags == 0)
				Format(esCmdInfo.flags, sizeof(esCmdInfo.flags), "FCVAR_NONE");
			else
			{	
				int flags = CmdIter.Flags; int i = 0;
				while (i < sizeof(g_sFlags))
				{
					if (flags & (1 << i))
					{
						#if DEBUG_MSG
							PrintToServer("i: %d, flags: %s", i, g_sFlags[i]);
						#endif
						Format(esCmdInfo.flags, sizeof(esCmdInfo.flags), "%s | %s", esCmdInfo.flags, g_sFlags[i]);
					}
					i++;
				}

				if (StrContains(esCmdInfo.flags, "FCVAR_NONE | ") > -1)
					ReplaceString(esCmdInfo.flags, sizeof(esCmdInfo.flags), "FCVAR_NONE | ", "");
			}
		}
		g_harrCmdInfo.PushArray(esCmdInfo);
	}
	delete CmdIter;
	SetKvString_Cmds();
}

void SetKvString_ConVars()
{
	ConVarInfo esConVarInfo;
	char key[128], value[128], flags[128], description[128], min[128], max[128];
	for (int i = 0; i < g_harrConVarInfo.Length; i++)
	{
		g_harrConVarInfo.GetArray(i, esConVarInfo);
		#if DEBUG
			PrintToServer("Plugin: %s, Cvar: %s", esConVarInfo.PluginName, esConVarInfo.cvar);
		#endif
 		if (kv.JumpToKey(esConVarInfo.PluginName, true))
		{
			#if DEBUG
				PrintToServer("jumping to: %s", esConVarInfo.PluginName);
			#endif
			if (g_hcvarDumpMore.BoolValue)
			{
				kv.Rewind();
				Format(value, sizeof(value), "%s/%s/defvalue", esConVarInfo.PluginName, esConVarInfo.cvar);
				kv.SetString(value, esConVarInfo.value);
				Format(flags, sizeof(flags), "%s/%s/flags", esConVarInfo.PluginName, esConVarInfo.cvar);
				kv.SetString(flags, esConVarInfo.flags);
				Format(description, sizeof(description), "%s/%s/description", esConVarInfo.PluginName, esConVarInfo.cvar);
				kv.SetString(description, esConVarInfo.description);
				Format(min, sizeof(min), "%s/%s/min", esConVarInfo.PluginName, esConVarInfo.cvar);
				kv.SetString(min, esConVarInfo.min);
				Format(max, sizeof(max), "%s/%s/max", esConVarInfo.PluginName, esConVarInfo.cvar);
				kv.SetString(max, esConVarInfo.max);
			}
			else
			{
				kv.Rewind();
				Format(key, sizeof(key), "%s/%s", esConVarInfo.PluginName, esConVarInfo.cvar);
				kv.SetString(key, esConVarInfo.value);
			}
		}
		kv.Rewind();
	}
	delete g_harrConVarInfo;
}

void SetKvString_Cmds()
{
	if (kv == null)
		kv = new KeyValues("Commands");

	CmdInfo esCmdInfo;
	char key[128], flags[128], description[128];
	for (int i = 0; i < g_harrCmdInfo.Length; i++)
	{
		g_harrCmdInfo.GetArray(i, esCmdInfo);
		#if DEBUG
			PrintToServer("Plugin: %s, Cmd: %s", esCmdInfo.PluginName, esCmdInfo.cmd);
		#endif
		if (kv.JumpToKey(esCmdInfo.PluginName, true))
		{
			#if DEBUG
				PrintToServer("jumping to: %s", esCmdInfo.PluginName);
			#endif
			if (g_hcvarDumpMore.BoolValue)
			{
				kv.Rewind();
				Format(flags, sizeof(flags), "%s/%s/flags", esCmdInfo.PluginName, esCmdInfo.cmd);
				kv.SetString(flags, esCmdInfo.flags);
				Format(description, sizeof(description), "%s/%s/description", esCmdInfo.PluginName, esCmdInfo.cmd);
				kv.SetString(description, esCmdInfo.description);
			}
			else
			{
				kv.Rewind();
				Format(key, sizeof(key), "%s/%s", esCmdInfo.PluginName, esCmdInfo.cmd);
				kv.SetString(key, esCmdInfo.flags);
			}
		}
		kv.Rewind();
	}
	delete g_harrCmdInfo;
}

void FinaleOutput(bool bIsCommand)
{
	char sDumpPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sDumpPath, sizeof(sDumpPath), bIsCommand ? DUMP_PATH_COMMAND: DUMP_PATH_CONVAR);
	kv.Rewind();
	kv.ExportToFile(sDumpPath);
	PrintToServer("Dumpping completed.");
	delete kv;
}

/**
 * BUG: there's an unsolved problem with kv.GoToNextKey() loop function. The keyvalue has already jumpped onto the key we need to check,
 * While there's no any other sub key under the current key, kv.GoToNextKey() should return false and integer a should no longer increase. but it dosen't.
 * I've checked it has nothing to do with arraylist nor enum struct, it's a pure keyvalue problem of kv.GoToNextKey() or kv.JumpToKey() function, or the speed of the loop maybe.
 * This problem finally cause the dumpped keyvalue file has a unregular sequence of cvar keys.
*/

/**
 * 
 * 		if (kv.JumpToKey(esConVarInfo.PluginName, true))
		{
			#if DEBUG
				PrintToServer("jumping to: %s", esConVarInfo.PluginName);
			#endif
				
			int a = 0;
			while (kv.GotoNextKey())
			{
				a += 1;
				#if DEBUG
					PrintToServer("time we loopped: %d", a);
				#endif
			}

			kv.Rewind();
			Format(key, sizeof(key), "%s/cvar%d", esConVarInfo.PluginName, a);
			kv.SetString(key, esConVarInfo.cvar);
		}
*/