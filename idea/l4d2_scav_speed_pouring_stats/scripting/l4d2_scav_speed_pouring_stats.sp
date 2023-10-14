#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <scavenge_func>
#include <colors>

#define DB_NAME "scav_speed_pouring"

enum struct Player
{
	int id;
	float time;
	char date[32];
	char map[64];
}

Player
	g_tPlayers[MAXPLAYERS + 1];

bool
	g_bShowMenu;

int
	g_iRoundDuration,
	g_iTeamScore;

public Plugin myinfo =
{
	name		= "[L4D2] Scavenge Speed Pouring Stats",
	author		= "blueblur",
	description = "Records, Displays the time of a map players scavenged.",
	version		= "1.0",
	url			= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_pourrank", Cmd_PourRank);

	HookeEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookeEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookeEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);

	// Init MySQL connections
	if (!ConnectDB())
	{
		SetFailState("Connecting to database failed. Read error log for further details.");
		return;
	}
}

bool ConnectDB()
{
	if (SQL_CheckConfig(DB_NAME))
	{
		char error[255];
		db = SQL_Connect(DB_NAME, true, error, sizeof(error));
		if (db == null)
		{
			PrintToServer("Could not connect: %s", error);
			return false;
		}
		else
		{
			db.SetCharset("utf8mb4");
			db.Query(SQL_CallBack, "\
			CREATE TABLE IF NOT EXISTS `scavenge_time`(\
				`id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, \
				`playerid` varchar(255) NOT NULL,\
				`time` int(32) NOT NULL,\
				`date` varchar(255) NOT NULL\
				PRIMARY KEY (`id`) USING BTREE \
			) \
			DEFAULT CHARSET='utf8mb4' \
			ENGINE=InnoDB \
			;");
			delete db;
		}
	}
	else
	{
		LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
		delete db;
		return false;
	}

	return true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bShowMenu		 = true;
	g_iRoundDuration = 0;
	g_iTeamScore	 = 0;

	if (GetScavengeRoundNumber() == 1 && InSecondHalfOfRound() || GetScavengeRoundNumber() > 1)
	{
		CreateMenu();
	}
}

public void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	g_bShowMenu = false;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	char sDuration[128], sDate[128], sName[128], sMapName[128];
	g_bShowMenu = true;

	g_iTeamScore = GetScavengeTeamScore(2, GetScavengeRoundNumber());

	FormatScavengeRoundTime(sDuration, sizeof(sDuration), 2);
	FormatTime(sDate, sizeof(sDate), "%Y-%m-%d");
	GetCurrentMap(sMapName, sizeof(sMapName));

	SavePlayerData();
	UpdatePlayerRank();
}

public void OnClientDisconnect(int iClient)
{
	
}

void SavePlayerData()
{
	if (g_iTeamScore == GetScavengeItemsGoal())		// if we didn't scavenge the map, abort data.
	{
		db.Format(sDuration, sizeof(sDuration), "INSERT INTO scavenge_time (playerid, time, date) VALUES (%N, %s, %s)", sPlayerid, sDuration, sDate);
		db.Query(SQL_RoundEndDataCallBack, sDuration);
	}
	else
	{
		CPrintToChatAll("%t", "DataAborted");
	}
}

void UpdatePlayerRank();
{

}

void CreateMenu()
{
	Menu menu = new Menu(MenuHandler, MENU_ACTIONS_ALL)
	menu.SetTitle("%t", "Title");
	for (int i = 0; i < ; i++)
	{
		
	}
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock bool IsPlayer(int client)
{
	int team = GetClientTeam(client);
	return (team == 2 || team == 3);
}

bool IsNewPlayer(int iClient) {
	return g_tPlayers[iClient].id == 0;
}

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}