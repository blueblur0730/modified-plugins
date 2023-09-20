/*
 * rework changelog.
 *
 * r2.5.1: 9/19/23 rework
 * 		- reformatted.
 * 
 * r2.6: 9/20/23
 * 		- structure reformed. now we use modules to place functions.
 * 		- added include for forward api. (to do: more forwards, add natives.)
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
 * 		- Version: r2.6
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <builtinvotes>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d2_playstats>

#define SECTION_NAME "CTerrorGameRules::SetCampaignScores"
#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2"

public Plugin myinfo =
{
	name = "[L4D2] Mixmap",
	author = "Stabby, Bred, blueblur",
	description = "Randomly select five maps to build a mixed campaign or match.",
	version = "r2.6",
	url = "https://github.com/blueblur0730/modified-plugins"
};

#define DIR_CFGS 			"mixmap/"
#define PATH_KV  			"cfg/mixmap/mapnames.txt"
#define CFG_DEFAULT			"default"
#define CFG_DODEFAULT		"disorderdefault"
#define CFG_DODEFAULT_ST	"do"
#define CFG_ALLOF			"official"
#define CFG_ALLOF_ST		"of"
#define	CFG_DOALLOF			"disorderofficial"
#define	CFG_DOALLOF_ST		"doof"
#define	CFG_UNOF			"unofficial"
#define	CFG_UNOF_ST			"uof"
#define	CFG_DOUNOF			"disorderunofficial"
#define	CFG_DOUNOF_ST		"douof"
#define BUF_SZ   			64

ConVar 	
	g_cvNextMapPrint,
	g_cvMaxMapsNum,
	g_cvFinaleEndStart;

GlobalForward
	g_hForwardStart,
	g_hForwardNext,
	g_hForwardEnd;

//与随机抽签相关的变量
StringMap
	g_hTriePools;				// Stores pool array handles by tag name 存放由标签分类的地图

ArrayList
	g_hArrayTags,				// Stores tags for indexing g_hTriePools 存放地图池标签
	g_hArrayTagOrder,			// Stores tags by rank 存放标签顺序
	g_hArrayMapOrder;			// Stores finalised map list in order 存放抽取完成后的地图顺序

Handle 
	g_hCountDownTimer,
	g_hVoteMixmap,
	g_hVoteStopMixmap,
	g_hCMapSetCampaignScores;

bool 
	g_bMaplistFinalized,
	g_bMapsetInitialized,
	g_bCMapTransitioned = false,
	g_bServerForceStart = false;
int 
	g_iMapsPlayed,
	g_iMapCount,
	g_iPointsTeam_A = 0,
	g_iPointsTeam_B = 0;

char cfg_exec[BUF_SZ];

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
			return;
		}
	}

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
	SetScores();

	return Plugin_Handled;
}

public void L4D2_OnEndVersusModeRound_Post() 
{
	if (InSecondHalfOfRound() && g_bMapsetInitialized) {PerformMapProgression();}
}