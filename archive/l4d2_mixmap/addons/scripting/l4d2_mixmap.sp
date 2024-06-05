/*
 * Plugin info:
 * * Original plugin source and overhual map pool logic construction:
 * 		- Name: Custom Map Transitions
 * 		- Author: Stabby (2013)
 * 		- Further work: czim (2020)
 * 		- Url: https://github.com/Stabbath/L4D2-Stuff
 * 		- Description: Makes games more fun and varied! Yay! By allowing players to select a custom map sequence, replacing the normal campaign map sequence.
 * 		- Version: 15
 *
 * * New Syntax, translations and more feature support:
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
 * 		- Version: r2.8
 */

/*
 * changelog by Bred. 
 *	# v2.5（2023/5/27）
 *		- Support custom limit of same campaign missions, check cfg/sourcemod/l4d2_mixmap.cfg
 *		- Optimize some grammar logic
 *		- Continue mixmap after a mixmap campaign finishes
 *		- Allow starting a mixmap when a mixmap is playing. No need to type !stopmixmap first.
 *
 *	# v2.4.2（2023/5/2）
 *		- Alternative to show maplist and nextmap (create mystery). Thanks to sway's idear.
 *
 *	# v2.4.1（2023/4/26）
 *		- Attempting to optimize random algorithms again
 *		- Only allow two missions which are from the same campaign
 *
 *	# v2.4（2023/4/14）
 *		- Fix some errors
 *		- Optimize command'stopmixmap'
 *		- Adjust 'disorder' mode. M1 stays m1. Finale stays finale. But m2,m3 and m4 will disorder.
 *
 *	# v2.3（2023/1/23）
 *		- Adjust 'default' maps pool. Delete C13、C9/C14. And add a mapspool containing all official campaign.并增加一个所有官方地图的地图池
 *		- Attempting to optimize random algorithms
 *		- Cancel vote CDT. Allow starting a mixmap in midgame.
 *
 *	# v2.2（2023/1/09）
 *		- Fix the team with lower scores will playing survivors first after changing map to c7m1/c14m1
 *
 *	# v2.1（2022/12/06）
 *		- Delete some unused codes
 *		- Fix a timer bug
 */

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
 * 		- added support for scavenge mode.
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
 *
 * r2.8: 9/27/23
 * 		- added support for coop and realism mode.
 * 			* save player infos, including: weapons, items, health, revive count, ammo.
 * 			* added back coop level change logic by czim.
 * 			* independent map pool cfgs. (wtf really?)
 * 		- proper changelevel: introducing l4d2_changelevel to reduce director issues when using sourcemod internal method to change map. 
 * 		  (ForceChangeLevel() was replaced by L4D2_ChangeLevel()).
 * 		- updated scavenge team switching logic.
 * 		- added 3 natives, changed forward names.
 * 			* native void GetMixmapMapSequence(ArrayList hArray)
 * 			* native int GetMixmapPlayedMapCount()
 * 			* native bool IsInMixmap()
 * 		- removed l4d2_playstats stuff.
 * 		- removed nextmap stuff. this plugin is not loaded in l4d2 now.
 * 
 * 		@ to do: support AnneHappy (or any other gauntlet versus-liked modified coop modes).
 * 		@ to do: special ammo type need to be test.
 * 		@ to do: check in-saferoom gascans or gastanks.
 * 
 * r2.8.1: 9/30/23
 * 		- added back sm_nextmap stuff (ok I dont know it is actually a sourcemod internal cvar...)
 * 			* https://github.com/alliedmodders/sourcemod/blob/master/core/NextMap.cpp#L160
 * 		- some logic fixed.
 * 		- moved events to a specific module.
 * 
 * r2.8.2: 10/2/23
 * 		- fixed scavenge_match_end check.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <builtinvotes>			// for creating vote. (is there gonna be a nativevote version in the future? builtinvotes is not available now in windows (or perhaps someone fixed it))
#include <colors>				// simplified and editable chat colors
#include <l4d2util>				// weapon stuff
#undef REQUIRE_PLUGIN
#include <l4d2_changelevel>		// director need to be triggered.
#undef REQUIRE_PLUGIN
#include <l4d2_saferoom_detect>	// for coop check use

#define SECTION_NAME "CTerrorGameRules::SetCampaignScores"
#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2"

public Plugin myinfo =
{
	name = "[L4D2] Mixmap",
	author = "Stabby, Bred, blueblur",
	description = "Randomly select five maps to build a mixed campaign or match.",
	version = "r2.8.2",
	url = "https://github.com/blueblur0730/modified-plugins"
};

// Map info and basic path to load
#define DIR_CFGS 					"mixmap/"
#define DIR_CFGS_SCAV				"mixmap/scav/"
//#define DIR_CFGS_COOP				"mixmap/coop/"
#define PATH_KV  					"cfg/mixmap/mapnames.txt"
#define PATH_KV_SCAV				"cfg/mixmap/scav/mapnames.txt"
//#define PATH_KV_COOP				"cfg/mixmap/coop/mapnames.txt"

/* yeah it's tired to do this
// Coop/Realism map pool
#define CFG_DEFAULT_COOP			"default_coop"
#define CFG_DODEFAULT_COOP			"disorderdefault_coop"
#define CFG_DODEFAULT_ST_COOP		"do_coop"
#define CFG_ALLOF_COOP				"official_versus_coop"
#define CFG_ALLOF_ST_COOP			"of_coop"
#define	CFG_DOALLOF_COOP			"disorderofficial_coop"
#define	CFG_DOALLOF_ST_COOP			"doof_coop"
#define	CFG_UNOF_COOP				"unofficial_coop"
#define	CFG_UNOF_ST_COOP			"uof_coop"
#define	CFG_DOUNOF_COOP				"disorderunofficial_coop"
#define	CFG_DOUNOF_ST_COOP			"douof_coop"
*/

// Versus map pool
#define CFG_DEFAULT					"default"
#define CFG_DODEFAULT				"disorderdefault"
#define CFG_DODEFAULT_ST			"do"
#define CFG_ALLOF					"official_versus"
#define CFG_ALLOF_ST				"of"
#define	CFG_DOALLOF					"disorderofficial"
#define	CFG_DOALLOF_ST				"doof"
#define	CFG_UNOF					"unofficial"
#define	CFG_UNOF_ST					"uof"
#define	CFG_DOUNOF					"disorderunofficial"
#define	CFG_DOUNOF_ST				"douof"

// Scavenge map pool
#define CFG_DEFAULT_SCAV			"default_scav"
#define CFG_DODEFAULT_SCAV			"disorderdefault_scav"
#define CFG_DODEFAULT_ST_SCAV		"do_scav"
#define	CFG_UNOF_SCAV				"unofficial_scav"
#define	CFG_UNOF_ST_SCAV			"uof_scav"
#define	CFG_DOUNOF_SCAV				"disorderunofficial_scav"
#define	CFG_DOUNOF_ST_SCAV			"douof_scav"

#define BUF_SZ   					64

ConVar
	g_cvNextMapPrint,
	g_cvMaxMapsNum,
	g_cvSaveStatus,
	g_cvSaveStatusBot,
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
	g_hArrayMatchInfo;			// Stores whole scavenge match info.

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

enum struct PlayerInfo
{
	int 	health;
	float 	temp_health;
	int  	revive_count;
	bool 	alive;
	int 	client_index;

	int 	slot0;
	int 	ammo;
	int 	ammo_type;
	int 	ammo_reserved;

	int 	slot1;
	int 	ammo_pistol;
	bool	IsMelee;

	int 	slot2;
	int 	slot3;
	int 	slot4;
}

// Modules
#include <l4d2_mixmap/setup.inc>
#include <l4d2_mixmap/events.inc>
#include <l4d2_mixmap/actions.inc>
#include <l4d2_mixmap/commands.inc>
#include <l4d2_mixmap/logic.inc>
#include <l4d2_mixmap/util.inc>
#include <l4d2_mixmap/vote.inc>

// ----------------------------------------------------------
// 		Setup
// ----------------------------------------------------------

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	SetupForwards();
	SetupNatives();
	RegPluginLibrary("l4d2_mixmap");

	return APLRes_Success;
}

public void OnPluginStart()
{
	SetupConVars();
	SetupCommands();
	HookEvents();

	PluginStartInit();
	LoadSDK();

	LoadTranslations("l4d2_mixmap.phrases");

	AutoExecConfig(true, "l4d2_mixmap");
}

// ----------------------------------------------------------
// 		Global Forwards
// ----------------------------------------------------------
public void OnClientPutInServer(int client)
{
	if (g_bMapsetInitialized)
		CreateTimer(10.0, Timer_ShowMaplist, client);//玩家加入服务器后，10s后提示正在使用mixmap插件。
}

public Action Timer_ShowMaplist(Handle timer, int client)
{
	if (IsClientInGame(client))
		CPrintToChat(client, "%t", "Auto_Show_Maplist");

	return Plugin_Handled;
}

// Otherwise nextmap would be stuck and people wouldn't be able to play normal campaigns without the plugin 结束后初始化sm_nextmap的值
public void OnPluginEnd() 
{
	ServerCommand("sm_nextmap ''");
}

public void OnMapStart()
{
	if (g_bCMapTransitioned)
	{
		CreateTimer(1.0, Timer_OnMapStartDelay, _, TIMER_FLAG_NO_MAPCHANGE); //Clients have issues connecting if team swap happens exactly on map start, so we delay it
		g_bCMapTransitioned = false;
	}
#if DEBUG
	PrintToServer("[Mixmap] OnMapStart called.");
#endif

	ToggleEvents();

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

	HookEntityOutput("info_director", "OnGameplayStart", EntEvent_OnGameplayStart);

	// let other plugins know what the map *after* this one will be (unless it is the last map)
	if (!g_bMaplistFinalized || g_iMapsPlayed >= g_iMapCount - 1)
		return;

	g_hArrayMapOrder.GetString(g_iMapsPlayed + 1, sBuffer, BUF_SZ);

	Call_StartForward(g_hForwardNext);
	Call_PushString(sBuffer);
	Call_Finish();
}

public Action Timer_OnMapStartDelay(Handle hTimer)
{
	if (L4D_IsVersusMode() && !InSecondHalfOfRound() && g_bMapsetInitialized)
		SetVersusScores();
	else if (L4D2_IsScavengeMode() && !InSecondHalfOfRound() && g_bMapsetInitialized && GetScavengeRoundNumber() > 1)
	{
		SetWinningTeam();
		SetScavengeScores();
		SetTeam();
	}	

	return Plugin_Handled;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	if (InSecondHalfOfRound() && g_bMapsetInitialized)
		PerformMapProgression();
}