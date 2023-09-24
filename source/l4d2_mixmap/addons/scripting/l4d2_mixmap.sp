/*
 * rework changelog.
 *
 * r2.5.1: 9/19/23 rework
 * 		- syntax reformatted.
 *
 * r2.6: 9/20/23
 * 		- structure reformed. now we use modules to place functions.
 * 		- added include for forward api. (to do: more forwards, add natives.)
 *
 * r2.7: 9/22/23
 * 		- added support for scavenge.
 * 			* set scores every map start
 * 			* independent map pool cfgs
 * 		- optimized translations.
 * 		- added a new forward OnCMTInterrupted()
 * 
 * r2.7.1: 9/24/23
 *		- optimized scavenge scores setting logic.
 *		- more chat phrases.
 *		- (unfinished)team switch logic of scavenge mixmap.
 *		- end mixmap when scavenge match finished ahead.
 */

/*
 * Plugin info:
 * * Original plugin source:
 * 		- Name: Custom Map Transitions
 * 		- Author: Stabby (2013)
 * 		- Further versus work: czim (2020)
 * 		- Url: https://github.com/Stabbath/L4D2-Stuff
 * 		- Description: Makes games more fun and varied! Yay! By allowing players to select a custom map sequence, replacing the normal campaign map sequence.
 * 		- Version: 15
 *
 * * New Syntax and more feature support:
 * 		- Name: l4d2_mixmap
 * 		- Author: Bred (2023)
 * 		- Url: https://gitee.com/honghl5/open-source-plug-in
 * 		- Description: Randomly select five maps for versus. Adding for fun and reference from CMT
 * 		- Version: 2.5
 *
 * * Extended feature support:
 * 		- Name: [L4D2] Mixmap
 * 		- Author: blueblur (2023)
 * 		- Url: https://github.com/blueblur0730/modified-plugins
 * 		- Description: Randomly select five maps to build a mixed campaign or match.
 * 		- Version: r2.7.1
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <builtinvotes>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d2_playstats>

#define SECTION_NAME "CTerrorGameRules::SetCampaignScores"
#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2"

#define DEBUG 1

public Plugin myinfo =
{
	name = "[L4D2] Mixmap",
	author = "Stabby, Bred, blueblur",
	description = "Randomly select five maps to build a mixed campaign or match.",
	version = "r2.7.1",
	url = "https://github.com/blueblur0730/modified-plugins"
};

// Map info and basic path to load
#define DIR_CFGS 				"mixmap/"
#define DIR_CFGS_SCAV			"mixmap/scav/"
#define PATH_KV  				"cfg/mixmap/mapnames.txt"
#define PATH_KV_SCAV			"cfg/mixmap/scav/mapnames.txt"

// Versus/Coop/Realism map pool
#define CFG_DEFAULT				"default"
#define CFG_DODEFAULT			"disorderdefault"
#define CFG_DODEFAULT_ST		"do"
#define CFG_ALLOF				"official_versus"
#define CFG_ALLOF_ST			"of"
#define	CFG_DOALLOF				"disorderofficial"
#define	CFG_DOALLOF_ST			"doof"
#define	CFG_UNOF				"unofficial"
#define	CFG_UNOF_ST				"uof"
#define	CFG_DOUNOF				"disorderunofficial"
#define	CFG_DOUNOF_ST			"douof"

// Scavenge map pool
#define CFG_DEFAULT_SCAV		"default_scav"
#define CFG_DODEFAULT_SCAV		"disorderdefault_scav"
#define CFG_DODEFAULT_ST_SCAV	"do_scav"
#define	CFG_UNOF_SCAV			"unofficial_scav"
#define	CFG_UNOF_ST_SCAV		"uof_scav"
#define	CFG_DOUNOF_SCAV			"disorderunofficial_scav"
#define	CFG_DOUNOF_ST_SCAV		"douof_scav"

#define BUF_SZ   				64

ConVar
	g_cvNextMapPrint,
	g_cvMaxMapsNum,
	g_cvFinaleEndStart;

GlobalForward
	g_hForwardStart,
	g_hForwardNext,
	g_hForwardInterrupt,
	g_hForwardEnd;

StringMap
	g_hTriePools;				// Stores pool array handles by tag name 存放由标签分类的地图

ArrayList
	g_hArrayTags,				// Stores tags for indexing g_hTriePools 存放地图池标签
	g_hArrayTagOrder,			// Stores tags by rank 存放标签顺序
	g_hArrayMapOrder,			// Stores finalised map list in order 存放抽取完成后的地图顺序
	g_hArrayMatchInfo;			// Stores whole scavenge match info

Handle
	g_hCountDownTimer,			// timer
	g_hCMapSetCampaignScores;	// sdkcall

bool
	g_bMaplistFinalized,
	g_bMapsetInitialized,
	g_bCMapTransitioned = false,
	g_bServerForceStart = false;

int
	g_iMapsPlayed,
	g_iMapCount;

char cfg_exec[BUF_SZ];

enum struct MatchInfo
{
	int rs_TeamA;
	int rs_TeamB;

	int ms_TeamA;
	int ms_TeamB;

	int winner;
}

// Modules
#include <l4d2_mixmap/actions.inc>
#include <l4d2_mixmap/command.inc>
#include <l4d2_mixmap/logic.inc>
#include <l4d2_mixmap/setup.inc>
#include <l4d2_mixmap/util.inc>
#include <l4d2_mixmap/vote.inc>

// ----------------------------------------------------------
// 		Setup
// ----------------------------------------------------------

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	SetupForwards();
	MarkNatives();
	RegPluginLibrary("l4d2_mixmap");

	return APLRes_Success;
}

public void OnPluginStart()
{
	SetupConVars();
	SetupCommands();

	PluginStartInit();
	LoadSDK();

	LoadTranslations("l4d2_mixmap.phrases");

	// maybe someday we can replace these by un-created forwards.
	HookEvent("scavenge_round_finished", Event_ScavRoundFinished, EventHookMode_Post);
	HookEvent("scavenge_match_finished", Event_ScavMatchFinished, EventHookMode_Post);

	AutoExecConfig(true, "l4d2_mixmap");
}

// ----------------------------------------------------------
// 		Hooks
// ----------------------------------------------------------

// Otherwise nextmap would be stuck and people wouldn't be able to play normal campaigns without the plugin 结束后初始化sm_nextmap的值
public void OnPluginEnd()
{
	ServerCommand("sm_nextmap ''");
}

public void OnClientPutInServer(int client)
{
	if (g_bMapsetInitialized)
		CreateTimer(10.0, Timer_ShowMaplist, client);//玩家加入服务器后，10s后提示正在使用mixmap插件。

	char sBuffer[128];
	if (L4D2_IsScavengeMode() && !InSecondHalfOfRound() && g_bMapsetInitialized && GetScavengeRoundNumber() > 1 && IsClientAndInGame(client))
	{
		GetClientName(client, sBuffer, sizeof(sBuffer));
		SetTeam(client, sBuffer);
	}
}

public Action Timer_ShowMaplist(Handle timer, int client)
{
	if (IsClientInGame(client))
		CPrintToChat(client, "%t", "Auto_Show_Maplist");

	return Plugin_Handled;
}

public void OnMapStart()
{
	if (g_bCMapTransitioned)
	{
		CreateTimer(1.0, Timer_OnMapStartDelay, _, TIMER_FLAG_NO_MAPCHANGE); //Clients have issues connecting if team swap happens exactly on map start, so we delay it
		g_bCMapTransitioned = false;
	}

	ServerCommand("sm_nextmap ''");

	char sBuffer[BUF_SZ];

	//判断currentmap与预计的map的name是否一致，如果不一致就stopmixmap
	if (g_bMapsetInitialized)
	{
		char sOriginalSetMapName[BUF_SZ];
		GetCurrentMap(sBuffer, BUF_SZ);
		g_hArrayMapOrder.GetString(g_iMapsPlayed, sOriginalSetMapName, BUF_SZ);

		if (!StrEqual(sBuffer,sOriginalSetMapName) && g_bMaplistFinalized)
		{
			PluginStartInit();
			CPrintToChatAll("%t", "Differ_Abort");
			Call_StartForward(g_hForwardInterrupt);
			Call_Finish();
			return;
		}
	}

	if (L4D2_IsScavengeMode())
		HookEntityOutput("info_director", "OnGameplayStart", EntEvent_OnGameplayStart);

	// let other plugins know what the map *after* this one will be (unless it is the last map)
	if (!g_bMaplistFinalized || g_iMapsPlayed >= g_iMapCount - 1)
		return;

	g_hArrayMapOrder.GetString(g_iMapsPlayed + 1, sBuffer, BUF_SZ);

	Call_StartForward(g_hForwardNext);
	Call_PushString(sBuffer);
	Call_Finish();
}

public void Event_ScavRoundFinished(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (InSecondHalfOfRound() && g_bMapsetInitialized)
		PerformMapProgression();
}

public void Event_ScavMatchFinished(Event hEvent, char[] sName, bool dontBroadcast)
{
	PluginStartInit();
	CPrintToChatAll("%t", "Scav_Match_End");

	Call_StartForward(g_hForwardEnd);
	Call_Finish();
}

public Action Timer_OnMapStartDelay(Handle hTimer)
{
	if (L4D_IsVersusMode())
		SetVersusScores();
	else if (L4D2_IsScavengeMode())
		SetScavengeScores();

	return Plugin_Handled;
}

public void EntEvent_OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
	CreateTimer(3.0, Timer_OnGameplayStartDelay);
}

Action Timer_OnGameplayStartDelay(Handle Timer)
{
	if (L4D2_IsScavengeMode() && !InSecondHalfOfRound() && g_bMapsetInitialized && GetScavengeRoundNumber() > 1)
		SetWinningTeam();

	return Plugin_Continue;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	if (InSecondHalfOfRound() && g_bMapsetInitialized)
		PerformMapProgression();
}