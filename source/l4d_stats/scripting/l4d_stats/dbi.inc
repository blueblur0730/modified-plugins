#if defined _l4d_stats_dbi_included
	#endinput
#endif
#define _l4d_stats_dbi_included

// Make connection to database.
bool ConnectDB()
{
	// database has connected already.
	if (db)
		return true;

	if (SQL_CheckConfig(DB_CONF_NAME))
	{
		char Error[256];
		db = SQL_Connect(DB_CONF_NAME, true, Error, sizeof(Error));

		if (!db)
		{
			LogError("Failed to connect to database: %s", Error);
			return false;
		}
		else if (!SQL_FastQuery(db, "SET NAMES 'utf8'"))
		{
			if (SQL_GetError(db, Error, sizeof(Error)))
				LogError("Failed to update encoding to UTF8: %s", Error);
			else
				LogError("Failed to update encoding to UTF8: unknown");
		}

		if (!CheckDatabaseValidity(g_sDbPrefix))
		{
			LogError("Database is missing required table or tables.");
			return false;
		}
	}
	else
	{
		LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
		return false;
	}

	return true;
}

void QueryClientPoints(int Client, SQLTCallback callback = INVALID_FUNCTION)
{
	char SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientPointsSteamID(Client, SteamID, callback);
}

void QueryClientPointsSteamID(int Client, const char[] SteamID, SQLTCallback callback = INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetClientPoints;

	char query[512];
	Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, SteamID);
	SQL_TQuery(db, callback, query, Client);
}

void QueryClientPointsDP(DataPack dp, SQLTCallback callback)
{
	char query[1024], SteamID[MAX_LINE_WIDTH];

	dp.Reset();
	dp.ReadCell();
	dp.ReadString(SteamID, sizeof(SteamID));

	Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, SteamID);
	SQL_TQuery(db, callback, query, dp);
}

void QueryClientRank(int Client, SQLTCallback callback = INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetClientRank;

	char query[256];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE %s >= %i", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS, g_iClientPoints[Client]);
	SQL_TQuery(db, callback, query, Client);
}

void QueryClientRankDP(DataPack dp, SQLTCallback callback)
{
	char query[256];

	dp.Reset();
	int Client = dp.ReadCell();

	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE %s >= %i", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS, g_iClientPoints[Client]);
	SQL_TQuery(db, callback, query, dp);
}

/*
void QueryClientGameModeRank(Client, SQLTCallback callback = INVALID_FUNCTION)
{
	if (!InvalidGameMode())
	{
		if (callback == INVALID_HANDLE)
			callback = Getg_iClientGameModeRank;

		char query[256];

		switch (g_iCurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_versus > 0 AND points_survivors + points_infected >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_VERSUS]);
			}
			case GAMEMODE_REALISM:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realism > 0 AND points_realism >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_REALISM]);
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_survival > 0 AND points_survival >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_SURVIVAL]);
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_scavenge > 0 AND points_scavenge_survivors + points_scavenge_infected >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_SCAVENGE]);
			}
			case GAMEMODE_REALISMVERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realismversus > 0 AND points_realism_survivors + points_realism_infected >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_REALISMVERSUS]);
			}
			case GAMEMODE_OTHERMUTATIONS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_mutations > 0 AND points_mutations >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_OTHERMUTATIONS]);
			}
			default:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime > 0 AND points >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_COOP]);
			}
		}

		SQL_TQuery(db, callback, query, Client);
	}
}
*/

void QueryClientGameModeRankDP(DataPack dp, SQLTCallback callback)
{
	if (!InvalidGameMode())
	{
		char query[1024];

		dp.Reset();

		int Client = dp.ReadCell();

		switch (g_iCurrentGamemodeID)
		{
			case GAMEMODE_VERSUS: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_versus > 0 AND points_survivors + points_infected >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_VERSUS]);
			case GAMEMODE_REALISM: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realism > 0 AND points_realism >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_REALISM]);
			case GAMEMODE_SURVIVAL: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_survival > 0 AND points_survival >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_SURVIVAL]);
			case GAMEMODE_SCAVENGE: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_scavenge > 0 AND points_scavenge_survivors + points_scavenge_infected >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_SCAVENGE]);
			case GAMEMODE_REALISMVERSUS: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realismversus > 0 AND points_realism_survivors + points_realism_infected >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_REALISMVERSUS]);
			case GAMEMODE_OTHERMUTATIONS: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_mutations > 0 AND points_mutations >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_OTHERMUTATIONS]);
			default:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime > 0 AND points >= %i", g_sDbPrefix, g_iClientGameModePoints[Client][GAMEMODE_COOP]);
			}
		}

		SQL_TQuery(db, callback, query, dp);
	}
}
/*
void QueryClientGameModePoints(Client, SQLTCallback:callback=INVALID_FUNCTION)
{
	char SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientGameModePointsStmID(Client, SteamID, callback);
}

void QueryClientGameModePointsStmID(Client, const char[] SteamID, SQLTCallback:callback=INVALID_FUNCTION)
{
	if (cbGetRankTotal == INVALID_HANDLE)
		callback = GetClientGameModePoints;

	char query[1024];

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected, points_realism, points_survival, points_scavenge_survivors + points_scavenge_infected + points_realism_survivors + points_realism_infected, points_mutations FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, SteamID);

	SQL_TQuery(db, callback, query, Client);
}
*/
void QueryClientGameModePointsDP(DataPack dp, SQLTCallback callback)
{
	char query[1024], SteamID[MAX_LINE_WIDTH];

	dp.Reset();
	dp.ReadCell();
	dp.ReadString(SteamID, sizeof(SteamID));

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected, points_realism, points_survival, points_scavenge_survivors + points_scavenge_infected, points_realism_survivors + points_realism_infected, points_mutations FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, SteamID);
	SQL_TQuery(db, callback, query, dp);
}
/*
void QueryRanks()
{
	QueryRank_1();
	QueryRank_2();
}
*/
void QueryRank_1(DataPack dp = null, SQLTCallback callback = INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetRankTotal;

	char query[1024];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	SQL_TQuery(db, callback, query, dp);
}

void QueryRank_2(DataPack dp = null, SQLTCallback callback = INVALID_FUNCTION)
{
	if (callback == INVALID_FUNCTION)
		callback = GetGameModeRankTotal;

	char query[1024];

	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_versus > 0", g_sDbPrefix);
		case GAMEMODE_REALISM: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realism > 0", g_sDbPrefix);
		case GAMEMODE_SURVIVAL: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_survival > 0", g_sDbPrefix);
		case GAMEMODE_SCAVENGE: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_scavenge > 0", g_sDbPrefix);
		case GAMEMODE_REALISMVERSUS: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_realismversus > 0", g_sDbPrefix);
		case GAMEMODE_OTHERMUTATIONS: Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime_mutations > 0", g_sDbPrefix);
		default:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers WHERE playtime > 0", g_sDbPrefix);
		}
	}

	SQL_TQuery(db, callback, query, dp);
}

void QueryClientStats(int Client, int CallingMethod = CM_UNKNOWN)
{
	char SteamID[MAX_LINE_WIDTH];

	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	QueryClientStatsSteamID(Client, SteamID, CallingMethod);
}

void QueryClientStatsSteamID(int Client, const char[] SteamID, int CallingMethod = CM_UNKNOWN)
{
	DataPack dp = new DataPack();

	dp.WriteCell(Client);
	dp.WriteString(SteamID);
	dp.WriteCell(CallingMethod);

	QueryClientStatsDP(dp);
}

void QueryClientStatsDP(DataPack dp)
{
	QueryClientGameModePointsDP(dp, QueryClientStatsDP_1);
}

void QueryClientStatsDP_1(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl)
	{
		LogError("QueryClientStatsDP_1 Query failed: %s", error);
		return;
	}

	dp.Reset();
	GetClientGameModePoints(hndl, error, dp.ReadCell());
	QueryClientPointsDP(dp, QueryClientStatsDP_2);
}

void QueryClientStatsDP_2(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl)
	{
		LogError("QueryClientStatsDP_2 Query failed: %s", error);
		return;
	}

	dp.Reset();
	GetClientPoints(owner, hndl, error, dp.ReadCell());
	QueryClientGameModeRankDP(dp, QueryClientStatsDP_3);
}

void QueryClientStatsDP_3(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl)
	{
		LogError("QueryClientStatsDP_3 Query failed: %s", error);
		return;
	}

	dp.Reset();
	GetClientGameModeRank(hndl, error, dp.ReadCell());
	QueryClientRankDP(dp, QueryClientStatsDP_4);
}

void QueryClientStatsDP_4(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl)
	{
		LogError("QueryClientStatsDP_4 Query failed: %s", error);
		return;
	}

	dp.Reset();
	GetClientRank(owner, hndl, error, dp.ReadCell());
	QueryRank_1(dp, QueryClientStatsDP_5);
}

void QueryClientStatsDP_5(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl)
	{
		LogError("QueryClientStatsDP_5 Query failed: %s", error);
		return;
	}

	dp.Reset();
	GetRankTotal(owner, hndl, error, dp.ReadCell());
	QueryRank_2(dp, QueryClientStatsDP_6);
}

void QueryClientStatsDP_6(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl)
	{
		if (dp)
			delete dp;

		LogError("QueryClientStatsDP_6 Query failed: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];

	dp.Reset();

	int Client = dp.ReadCell();
	dp.ReadString(SteamID, sizeof(SteamID));
	int CallingMethod = dp.ReadCell();

	GetGameModeRankTotal(owner, hndl, error, Client);

	// Callback
	if (CallingMethod == CM_RANK) QueryClientStatsDP_Rank(Client, SteamID);
	else if (CallingMethod == CM_TOP10) QueryClientStatsDP_Top10(Client, SteamID);
	else if (CallingMethod == CM_NEXTRANK) QueryClientStatsDP_NextRank(Client, SteamID);
	else if (CallingMethod == CM_NEXTRANKFULL) QueryClientStatsDP_NextRankFull(Client, SteamID);

	// Clean your mess up
	delete dp;
}

void QueryClientStatsDP_Rank(int Client, const char[] SteamID)
{
	char query[1024];
	Format(query, sizeof(query), "SELECT name, %s, %s, kills, versus_kills_survivors + scavenge_kills_survivors + realism_kills_survivors + mutations_kills_survivors, headshots FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, SteamID);
	SQL_TQuery(db, DisplayRank, query, Client);
}

void QueryClientStatsDP_Top10(int Client, const char[] SteamID)
{
	char query[1024];
	Format(query, sizeof(query), "SELECT name, %s, %s, kills, versus_kills_survivors + scavenge_kills_survivors + realism_kills_survivors + mutations_kills_survivors, headshots FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, SteamID);
	SQL_TQuery(db, DisplayRank, query, Client);
}

void QueryClientStatsDP_NextRank(int Client, const char[] SteamID)
{
	char query[1024];
	Format(query, sizeof(query), "SELECT (%s + 1) - %i FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY (%s) ASC LIMIT 1", DB_PLAYERS_TOTALPOINTS, g_iClientPoints[Client], g_sDbPrefix, DB_PLAYERS_TOTALPOINTS, g_iClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, DisplayClientNextRank, query, Client);

	if (g_hTimerRankChangeCheck[Client] != null)
		TriggerTimer(g_hTimerRankChangeCheck[Client], true);
}

void QueryClientStatsDP_NextRankFull(int Client, const char[] SteamID)
{
	char query[2048];
	Format(query, sizeof(query), "SELECT (%s + 1) - %i FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY (%s) ASC LIMIT 1", DB_PLAYERS_TOTALPOINTS, g_iClientPoints[Client], g_sDbPrefix, DB_PLAYERS_TOTALPOINTS, g_iClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, GetClientNextRank, query, Client);

	char query1[1024], query2[256], query3[1024];
	Format(query1, sizeof(query1), "SELECT name, (%s) AS totalpoints FROM %splayers WHERE (%s) >= %i AND steamid <> '%s' ORDER BY totalpoints ASC LIMIT 3", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, DB_PLAYERS_TOTALPOINTS, g_iClientPoints[Client], SteamID);
	Format(query2, sizeof(query2), "SELECT name, %i AS totalpoints FROM %splayers WHERE steamid = '%s'", g_iClientPoints[Client], g_sDbPrefix, SteamID);
	Format(query3, sizeof(query3), "SELECT name, (%s) as totalpoints FROM %splayers WHERE (%s) < %i ORDER BY totalpoints DESC LIMIT 3", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, DB_PLAYERS_TOTALPOINTS, g_iClientPoints[Client]);
	Format(query, sizeof(query), "(%s) UNION (%s) UNION (%s) ORDER BY totalpoints DESC", query1, query2, query3);
	SQL_TQuery(db, DisplayNextRankFull, query, Client);

	if (g_hTimerRankChangeCheck[Client] != null)
		TriggerTimer(g_hTimerRankChangeCheck[Client], true);
}

// Insert a map into the database if they do not already exist.
void InsertMapDB(Handle owner, DBResultSet hndl, const char[] error, any data)
{
	if (!db)
		return;

	if (StatsDisabled(true))
		return;

	if (!hndl.RowCount)
	{
		char MapName[MAX_LINE_WIDTH];
		GetCurrentMap(MapName, sizeof(MapName));

		char query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO %smaps SET name = LOWER('%s'), custom = 1, gamemode = %i", g_sDbPrefix, MapName, GetCurrentGamemodeID());
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}
}

void ReadClientRankMuteSteamID(int Client, const char[] SteamID)
{
	// Check stats disabled and is client bot before calling this method!
	char query[512];
	Format(query, sizeof(query), "SELECT mute FROM %ssettings WHERE steamid = '%s'", g_sDbPrefix, SteamID);
	SQL_TQuery(db, GetClientRankMute, query, Client);
}

// Insert a player into the database if they do not already exist.
void InsertPlayerDB(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!db || IsClientBot(client))
		return;

	if (!hndl)
	{
		LogError("InsertPlayerDB failed! Reason: %s", error);
		return;
	}

	if (StatsDisabled())
		return;

	if (!hndl.RowCount)
	{
		char SteamID[MAX_LINE_WIDTH];
		GetClientRankAuthString(client, SteamID, sizeof(SteamID));

		char query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO %splayers SET steamid = '%s'", g_sDbPrefix, SteamID);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}

	UpdatePlayer(client);
}

// Insert a player into the settings database if they do not already exist.
void SetClientRankMute(DBResultSet owner, Handle hndl, const char[] error, int client)
{
	if (!db || IsClientBot(client))
		return;

	if (!hndl)
	{
		LogError("SetClientRankMute failed! Reason: %s", error);
		return;
	}

	if (StatsDisabled())
		return;

	if (owner.AffectedRows == 0)
	{
		// Something went wrong!
		g_bClientRankMute[client] = false;
		return;
	}

	ReadClientRankMute(client);
}

void ReadClientRankMute(int Client)
{
	// Check stats disabled and is client bot before calling this method!
	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, SteamID, sizeof(SteamID));
	ReadClientRankMuteSteamID(Client, SteamID);
}

// Insert a player into the settings database if they do not already exist.
void GetClientRankMute(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!db || IsClientBot(client))
		return;

	if (!hndl)
	{
		LogError("GetClientRankMute failed! Reason: %s", error);
		return;
	}

	if (StatsDisabled())
		return;

	if (!hndl.RowCount)
	{
		char SteamID[MAX_LINE_WIDTH];
		GetClientRankAuthString(client, SteamID, sizeof(SteamID));

		char query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO %ssettings SET steamid = '%s'", g_sDbPrefix, SteamID);
		SQL_TQuery(db, SetClientRankMute, query, client);
	}
	else
	{
		while (hndl.FetchRow())
		{
			g_bClientRankMute[client] = (hndl.FetchInt(0) != 0);
		}
	}
}

// Run a SQL query, used for UPDATE's only.
void SendSQLUpdate(const char[] query, SQLTCallback callback = INVALID_FUNCTION)
{
	if (!db)
		return;

	if (callback == INVALID_FUNCTION)
		callback = SQLErrorCheckCallback;

#if DEBUG
	if (g_iQueryCounter >= 256)
		g_iQueryCounter = 0;

	int queryid = g_iQueryCounter++;

	Format(g_sQueryBuffer[queryid], MAX_QUERY_COUNTER, query);

	SQL_TQuery(db, callback, query, queryid);
#else
	SQL_TQuery(db, callback, query);
#endif
}

// Report error on sql query;
void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, int queryid)
{
	if (!db)
		return;

	if (!StrEqual("", error))
	{
#if DEBUG
		LogError("SQL Error: %s (Query: \"%s\")", error, g_sQueryBuffer[queryid]);
#else
		LogError("SQL Error: %s", error);
#endif
	}
}

// Perform player update of name, playtime, and timestamp.
void UpdatePlayer(int client)
{
	if (!IsClientConnected(client))
		return;

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	char Name[MAX_LINE_WIDTH];
	GetClientName(client, Name, sizeof(Name));

	ReplaceString(Name, sizeof(Name), "<?php", "");
	ReplaceString(Name, sizeof(Name), "<?PHP", "");
	ReplaceString(Name, sizeof(Name), "?>", "");
	ReplaceString(Name, sizeof(Name), "\\", "");
	ReplaceString(Name, sizeof(Name), "\"", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), ";", "");
	ReplaceString(Name, sizeof(Name), "�", "");
	ReplaceString(Name, sizeof(Name), "`", "");

	UpdatePlayerFull(client, SteamID, Name);
}

// Perform player update of name, playtime, and timestamp.
void UpdatePlayerFull(int Client, const char[] SteamID, const char[] Name)
{
	// Client can be ZERO! Look at UpdatePlayerCallback.
	char Playtime[32];
	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS: Format(Playtime, sizeof(Playtime), "playtime_versus");
		case GAMEMODE_REALISM: Format(Playtime, sizeof(Playtime), "playtime_realism");
		case GAMEMODE_SURVIVAL: Format(Playtime, sizeof(Playtime), "playtime_survival");
		case GAMEMODE_SCAVENGE: Format(Playtime, sizeof(Playtime), "playtime_scavenge");
		case GAMEMODE_REALISMVERSUS: Format(Playtime, sizeof(Playtime), "playtime_realismversus");
		case GAMEMODE_OTHERMUTATIONS: Format(Playtime, sizeof(Playtime), "playtime_mutations");
		default:
		{
			Format(Playtime, sizeof(Playtime), "playtime");
		}
	}

	char IP[16];
	GetClientIP(Client, IP, sizeof(IP));

	char query[512];
	Format(query, sizeof(query), "UPDATE %splayers SET lastontime = UNIX_TIMESTAMP(), %s = %s + 1, lastgamemode = %i, name = '%s', ip = '%s' WHERE steamid = '%s'", g_sDbPrefix, Playtime, Playtime, g_iCurrentGamemodeID, Name, IP, SteamID);
	SQL_TQuery(db, UpdatePlayerCallback, query, Client);
}

// Report error on sql query;
void UpdatePlayerCallback(Handle owner, Handle hndl, const char[] error, int client)
{
	if (!db)
		return;

	if (!StrEqual("", error))
	{
		if (client > 0)
		{
			char SteamID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, SteamID, sizeof(SteamID));
			UpdatePlayerFull(0, SteamID, "INVALID_CHARACTERS");
			return;
		}

		LogError("SQL Error: %s", error);
	}
}

// Perform a map stat update.
void UpdateMapStat(const char[] Field, int Score)
{
	if (Score <= 0)
		return;

	char MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	char DiffSQL[MAX_LINE_WIDTH];
	char Difficulty[MAX_LINE_WIDTH];
	g_hCvar_Difficulty.GetString(Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	else return;

	char FieldSQL[MAX_LINE_WIDTH];
	Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

	char query[512];
	Format(query, sizeof(query), "UPDATE %smaps SET %s = %s + %i WHERE LOWER(name) = LOWER('%s') and gamemode = %i", g_sDbPrefix, FieldSQL, FieldSQL, Score, MapName, GetCurrentGamemodeID());
	SendSQLUpdate(query);
}

// Perform a map stat update.
void UpdateMapStatFloat(const char[] Field, float Value)
{
	if (Value <= 0)
		return;

	char MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	char DiffSQL[MAX_LINE_WIDTH];
	char Difficulty[MAX_LINE_WIDTH];
	g_hCvar_Difficulty.GetString(Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	else return;

	char FieldSQL[MAX_LINE_WIDTH];
	Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

	char query[512];
	Format(query, sizeof(query), "UPDATE %smaps SET %s = %s + %f WHERE LOWER(name) = LOWER('%s') and gamemode = %i", g_sDbPrefix, FieldSQL, FieldSQL, Value, MapName, GetCurrentGamemodeID());
	SendSQLUpdate(query);
}

void ReadDb()
{
	ReadDbMotd();
}

void ReadDbMotd()
{
	char query[512];
	Format(query, sizeof(query), "SELECT svalue FROM %sserver_settings WHERE sname = 'motdmessage' LIMIT 1", g_sDbPrefix);
	SQL_TQuery(db, ReadDbMotdCallback, query);
}

void ReadDbMotdCallback(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	if (!hndl)
	{
		LogError("ReadDbMotdCallback Query failed: %s", error);
		return;
	}

	if (hndl.FetchRow())
		hndl.FetchString(0, g_sMessageOfTheDay, sizeof(g_sMessageOfTheDay));
}

bool UpdateServerSettings(Client, const char[] Key, const char[] Value, const char[] Desc)
{
	DBStatement statement = null;
	char error[1024], query[2048];

	// Add a row if it does not previously exist
	if (!DoFastQuery(Client, "INSERT IGNORE INTO %sserver_settings SET sname = '%s', svalue = ''", g_sDbPrefix, Key))
	{
		PrintToConsole(Client, "[RANK] %s: Setting a new MOTD value failure!", Desc);
		return false;
	}

	Format(query, sizeof(query), "UPDATE %sserver_settings SET svalue = ? WHERE sname = '%s'", g_sDbPrefix, Key);
	statement = SQL_PrepareQuery(db, query, error, sizeof(error));

	if (!statement)
	{
		PrintToConsole(Client, "[RANK] %s: Update failed! (Reason: Cannot create SQL statement)");
		return false;
	}

	bool retval = true;
	statement.BindString(0, Value, false);

	if (!SQL_Execute(statement))
	{
		if (SQL_GetError(db, error, sizeof(error)))
		{
			PrintToConsole(Client, "[RANK] %s: Update failed! (Error = \"%s\")", Desc, error);
			LogError("%s: Update failed! (Error = \"%s\")", Desc, error);
		}
		else
		{
			PrintToConsole(Client, "[RANK] %s: Update failed!", Desc);
			LogError("%s: Update failed!", Desc);
		}

		retval = false;
	}
	else
	{
		PrintToConsole(Client, "[RANK] %s: Update successful!", Desc);

		if (StrEqual(Key, "motdmessage", false))
		{
			strcopy(g_sMessageOfTheDay, sizeof(g_sMessageOfTheDay), Value);
			ShowMOTDAll();
		}
	}

	delete statement;
	return retval;
}

void UpdateMapTimingStat(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl)
	{
		if (dp)
			delete dp;

		LogError("UpdateMapTimingStat Query failed: %s", error);
		return;
	}

	dp.Reset();

	char  MapName[MAX_LINE_WIDTH], ClientID[MAX_LINE_WIDTH], query[512], TimeLabel[32], Mutation[MAX_LINE_WIDTH];
	int GamemodeID, Client, PlayerCounter, GameDifficulty;
	float TotalTime, OldTime;

	dp.ReadString(MapName, sizeof(MapName));
	GamemodeID = dp.ReadCell();
	dp.ReadString(ClientID, sizeof(ClientID));
	TotalTime	   = dp.ReadFloat();
	Client		   = dp.ReadCell();
	PlayerCounter  = dp.ReadCell();
	GameDifficulty = dp.ReadCell();
	dp.ReadString(Mutation, sizeof(Mutation));

	delete dp;

	// Return if client is not a human player
	if (IsClientBot(Client) || !IsClientInGame(Client))
		return;

	int Mode = g_hCvar_AnnounceMode.IntValue;

	if (hndl.RowCount > 0)
	{
		hndl.FetchRow();
		OldTime = hndl.FetchFloat(0);

		if ((g_iCurrentGamemodeID != GAMEMODE_SURVIVAL && OldTime <= TotalTime) || (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && OldTime >= TotalTime))
		{
			if (Mode)
			{
				SetTimeLabel(OldTime, TimeLabel, sizeof(TimeLabel));
				StatsPrintToChat(Client, "You did not improve your best time {green}%s {default}to finish this map!", TimeLabel);
			}

			Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s'", g_sDbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID);
		}
		else
		{
			if (Mode)
			{
				SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
				StatsPrintToChat(Client, "Your new best time to finish this map is {green}%s{default}!", TimeLabel);
			}

			Format(query, sizeof(query), "UPDATE %stimedmaps SET plays = plays + 1, time = %f, players = %i, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s'", g_sDbPrefix, TotalTime, PlayerCounter, MapName, GamemodeID, GameDifficulty, Mutation, ClientID);

			if (g_bEnableSounds_Maptime_Improve && g_hCvar_SoundsEnabled.BoolValue)
				EmitSoundToClient(Client, g_SStatsSound_MapTime_Improve);
		}
	}
	else
	{
		if (Mode)
		{
			SetTimeLabel(TotalTime, TimeLabel, sizeof(TimeLabel));
			StatsPrintToChat(Client, "It took {green}%s {default}to finish this map!", TimeLabel);
		}

		Format(query, sizeof(query), "INSERT INTO %stimedmaps (map, gamemode, difficulty, mutation, steamid, plays, time, players, modified, created) VALUES ('%s', %i, %i, '%s', '%s', 1, %f, %i, NOW(), NOW())", g_sDbPrefix, MapName, GamemodeID, GameDifficulty, Mutation, ClientID, TotalTime, PlayerCounter);
	}

	SendSQLUpdate(query);
}

// Find a player from Top 10 ranking.
void GetClientFromTop10(int client, int rank)
{
	char query[512];
	Format(query, sizeof(query), "SELECT (%s) as totalpoints, steamid FROM %splayers ORDER BY totalpoints DESC LIMIT %i,1", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, rank);
	SQL_TQuery(db, GetClientTop10, query, client);
}

// Find a player from Top 10 PPM ranking.
void GetClientFromTop10PPM(int client, int rank)
{
	char query[1024];
	Format(query, sizeof(query), "SELECT (%s) AS totalpoints, steamid, (%s) AS totalplaytime FROM %splayers WHERE (%s) >= %i ORDER BY (totalpoints / totalplaytime) DESC, totalplaytime DESC LIMIT %i,1", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, DB_PLAYERS_TOTALPLAYTIME, GetConVarInt(g_hCvar_Top10PPMMin), rank);
	SQL_TQuery(db, GetClientTop10, query, client);
}

// Send the Top 10 player's info to the client.
void GetClientTop10(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("GetClientTop10 failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	while (hndl.FetchRow())
	{
		hndl.FetchString(1, SteamID, sizeof(SteamID));
		QueryClientStatsSteamID(client, SteamID, CM_TOP10);
	}
}

// Generate client's point total.
void GetClientPointsPlayerJoined(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	GetClientPointsWorker(owner, hndl, error, client, GetClientRankPlayerJoined);
}

// Generate client's point total.
void GetClientPointsRankChange(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	GetClientPointsWorker(owner, hndl, error, client, GetClientRankRankChange);
}

// Generate client's point total.
void GetClientPointsWorker(Handle owner, DBResultSet hndl, const char[] error, int client, SQLTCallback callback = INVALID_FUNCTION)
{
	if (!client)
		return;

	if (callback == INVALID_FUNCTION)
	{
		LogError("GetClientPointsWorker method invoke failed: SQLTCallback:callback=INVALID_FUNCTION");
		return;
	}

	if (!hndl)
	{
		LogError("GetClientPointsWorker Query failed: %s", error);
		return;
	}

	GetClientPoints(owner, hndl, error, client);
	QueryClientRank(client, callback);
}

// Generate client's point total.
void GetClientPoints(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("GetClientPoints Query failed: %s", error);
		return;
	}

	if (hndl.FetchRow())
		g_iClientPoints[client] = hndl.FetchInt(0);
}

// Generate client's gamemode point total.
void GetClientGameModePoints(DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("GetClientGameModePoints Query failed: %s", error);
		return;
	}

	while (hndl.FetchRow())
	{
		g_iClientGameModePoints[client][GAMEMODE_COOP]			 = hndl.FetchInt(GAMEMODE_COOP);
		g_iClientGameModePoints[client][GAMEMODE_VERSUS]		 = hndl.FetchInt(GAMEMODE_VERSUS);
		g_iClientGameModePoints[client][GAMEMODE_REALISM]		 = hndl.FetchInt(GAMEMODE_REALISM);
		g_iClientGameModePoints[client][GAMEMODE_SURVIVAL]		 = hndl.FetchInt(GAMEMODE_SURVIVAL);
		g_iClientGameModePoints[client][GAMEMODE_SCAVENGE]		 = hndl.FetchInt(GAMEMODE_SCAVENGE);
		g_iClientGameModePoints[client][GAMEMODE_REALISMVERSUS]	 = hndl.FetchInt(GAMEMODE_REALISMVERSUS);
		g_iClientGameModePoints[client][GAMEMODE_OTHERMUTATIONS] = hndl.FetchInt(GAMEMODE_OTHERMUTATIONS);
	}
}

// Generate client's next rank.
void DisplayClientNextRank(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}

	GetClientNextRank(owner, hndl, error, client);
	DisplayNextRank(client);
}

// Generate client's next rank.
void GetClientNextRank(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}

	if (hndl.FetchRow())
		g_iClientNextRank[client] = hndl.FetchInt(0);
	else
		g_iClientNextRank[client] = 0;
}

// Generate client's rank.
void GetClientRankRankChange(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}

	GetClientRank(owner, hndl, error, client);

	if (g_iRankChangeLastRank[client] != g_iClientRank[client])
	{
		int RankChange = g_iRankChangeLastRank[client] - g_iClientRank[client];

		if (!g_bRankChangeFirstCheck[client] && RankChange == 0)
			return;

		g_iRankChangeLastRank[client] = g_iClientRank[client];

		if (g_bRankChangeFirstCheck[client])
		{
			g_bRankChangeFirstCheck[client] = false;
			return;
		}

		if (!g_hCvar_AnnounceMode.IntValue || !g_hCvar_AnnounceRankChange.BoolValue)
			return;

		char Label[16];
		if (RankChange > 0)
			Format(Label, sizeof(Label), "GAINED");
		else
		{
			RankChange *= -1;
			Format(Label, sizeof(Label), "DROPPED");
		}

		if (!IsClientBot(client) && IsClientConnected(client) && IsClientInGame(client))
			StatsPrintToChat(client, "You've {green}%s {default}rank for {green}%i position%s{default}! {olive}(Rank: %i)", Label, RankChange, (RankChange > 1 ? "s" : ""), g_iRankChangeLastRank[client]);
	}
}

// Generate client's rank.
void GetClientRankPlayerJoined(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("GetClientRankPlayerJoined Query failed: %s", error);
		return;
	}

	GetClientRank(owner, hndl, error, client);

	char userName[MAX_LINE_WIDTH];
	GetClientName(client, userName, sizeof(userName));

	if (g_iClientRank[client] > 0) StatsPrintToChatAll("Player {olive}%s {default}joined the game! (Rank: {lightgreen}%i {default}/ Points: {lightgreen}%i{default})", userName, g_iClientRank[client], g_iClientPoints[client]);
	else StatsPrintToChatAll("Player {olive}%s {default}joined the game! (No ranking yet)", userName);
}

// Generate client's rank.
void GetClientRank(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("GetClientRank Query failed: %s", error);
		return;
	}

	if (hndl.FetchRow())
		g_iClientRank[client] = hndl.FetchInt(0);
}

// Generate client's rank.
void GetClientGameModeRank(DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("GetClientGameModeRank Query failed: %s", error);
		return;
	}

	while (hndl.FetchRow())
		g_iClientGameModeRank[client] = hndl.FetchInt(0);
}

// Generate total rank amount.
void GetRankTotal(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	if (!hndl)
	{
		LogError("GetRankTotal Query failed: %s", error);
		return;
	}

	while (hndl.FetchRow())
		g_iRankTotal = hndl.FetchInt(0);
}

// Generate total gamemode rank amount.
void GetGameModeRankTotal(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	if (!hndl)
	{
		LogError("GetGameModeRankTotal Query failed: %s", error);
		return;
	}

	while (hndl.FetchRow())
		g_iGameModeRankTotal = hndl.FetchInt(0);
}

void ClearStatsMapsHandler(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!hndl)
	{
		PrintToConsole(client, "[RANK] Clear Stats: Query failed! (%s)", error);
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
		return;
	}

	int	 FieldCount = hndl.FieldCount;
	char FieldName[MAX_LINE_WIDTH];
	char FieldSet[MAX_LINE_WIDTH];

	int	 Counter = 0;
	char query[4096];
	Format(query, sizeof(query), "UPDATE %smaps SET", g_sDbPrefix);

	for (int i = 0; i < FieldCount; i++)
	{
		hndl.FieldNumToName(i, FieldName, sizeof(FieldName));

		if (StrEqual(FieldName, "name", false) || StrEqual(FieldName, "gamemode", false) || StrEqual(FieldName, "custom", false))
			continue;

		if (Counter++ > 0)
			StrCat(query, sizeof(query), ",");

		Format(FieldSet, sizeof(FieldSet), " %s = 0", FieldName);
		StrCat(query, sizeof(query), FieldSet);
	}

	if (!DoFastQuery(client, query))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing maps table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
	}
	else
	{
		DoFastQuery(client, "COMMIT");
		PrintToConsole(client, "[RANK] Clear Stats: Stats succesfully cleared!", query);
	}
}

void ExecuteTeamShuffle(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	if (!hndl)
	{
		LogError("ExecuteTeamShuffle failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	int	i, team, client, topteam;
	int	SurvivorsLimit = g_hCvar_SurvivorLimit.IntValue, InfectedLimit = g_hCvar_InfectedLimit.IntValue;
	StringMap PlayersTrie	= new StringMap();
	ArrayList InfectedArray = new ArrayList();
	ArrayList SurvivorArray = new ArrayList();

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			GetClientRankAuthString(i, SteamID, sizeof(SteamID));
			if (!PlayersTrie.SetValue(SteamID, i, false))
			{
				LogError("ExecuteTeamShuffle failed! Reason: Duplicate SteamID while generating shuffled teams.");
				StatsPrintToChatAllPreFormatted2(true, "Team shuffle failed in an error.");
				g_hCvar_EnableRankVote.BoolValue = false;

				PlayersTrie.Clear();
				delete PlayersTrie;
				delete hndl;
				return;
			}

			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS: SurvivorArray.Push(i);
				case TEAM_INFECTED: InfectedArray.Push(i);
			}
		}
	}

	int SurvivorCounter = SurvivorArray.Length;
	int InfectedCounter = InfectedArray.Length;

	i = 0;
	topteam	= 0;

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, SteamID, sizeof(SteamID));

		if (PlayersTrie.GetValue(SteamID, client))
		{
			team = GetClientTeam(client);
			if (i == 0)
			{
				if (team == TEAM_SURVIVORS) SurvivorArray.Erase(SurvivorArray.FindValue(client));
				else if (team == TEAM_INFECTED) InfectedArray.Erase(InfectedArray.FindValue(client));

				topteam = team;
				i++;

				continue;
			}

			if (i++ % 2)
			{
				if (topteam == TEAM_SURVIVORS && team == TEAM_INFECTED) InfectedArray.Erase(InfectedArray.FindValue(client));
				else if (topteam == TEAM_INFECTED && team == TEAM_SURVIVORS) SurvivorArray.Erase(SurvivorArray.FindValue(client));
			}
			else
			{
				if (topteam == TEAM_SURVIVORS && team == TEAM_SURVIVORS) SurvivorArray.Erase(SurvivorArray.FindValue(client));
				else if (topteam == TEAM_INFECTED && team == TEAM_INFECTED) InfectedArray.Erase(InfectedArray.FindValue(client));
			}
		}
	}

	if (SurvivorArray.Length > 0 || InfectedArray.Length > 0)
	{
		int NewSurvivorCounter = SurvivorCounter - SurvivorArray.Length + InfectedArray.Length;
		int NewInfectedCounter = InfectedCounter - InfectedArray.Length + SurvivorArray.Length;

		if (NewSurvivorCounter > SurvivorsLimit || NewInfectedCounter > InfectedLimit)
		{
			LogError("ExecuteTeamShuffle failed! Reason: Team size limits block Rank Vote functionality. (Survivors Limit = %i [%i] / Infected Limit = %i [%i])", SurvivorsLimit, NewSurvivorCounter, InfectedLimit, NewInfectedCounter);
			StatsPrintToChatAllPreFormatted2(true, "Team shuffle failed in an error.");

			g_hCvar_EnableRankVote.BoolValue = false;
		}
		else
		{
			g_bCampaignOver = true;

			char Name[32];

			// Change Survivors team to Spectators (TEMPORARILY)
			for (i = 0; i < SurvivorArray.Length; i++)
				ChangeRankPlayerTeam(SurvivorArray.Get(i), TEAM_SPECTATORS);

			// Change Infected team to Survivors
			for (i = 0; i < InfectedArray.Length; i++)
			{
				client = InfectedArray.Get(i);
				GetClientName(client, Name, sizeof(Name));
				ChangeRankPlayerTeam(client, TEAM_SURVIVORS);
				StatsPrintToChatAll2(true, "{olive}%s {default}was swapped to team {lightgreen}Survivors{default}!", Name);
			}

			// Change Spectators (TEMPORARILY) team to Infected
			for (i = 0; i < SurvivorArray.Length; i++)
			{
				client = SurvivorArray.Get(i);
				GetClientName(client, Name, sizeof(Name));
				ChangeRankPlayerTeam(client, TEAM_INFECTED);
				StatsPrintToChatAll2(true, "{olive}%s {default}was swapped to team {lightgreen}Infected{default}!", Name);
			}

			StatsPrintToChatAllPreFormatted2(true, "Team shuffle by player PPM {lightgreen}DONE{default}.");

			if (g_bEnableSounds_Rankvote && g_hCvar_SoundsEnabled.BoolValue)
				EmitSoundToAll(SOUND_RANKVOTE);
		}
	}
	else
		StatsPrintToChatAllPreFormatted2(true, "Teams are already even by player PPM.");

	SurvivorArray.Clear();
	InfectedArray.Clear();
	PlayersTrie.Clear();

	delete SurvivorArray;
	delete InfectedArray;
	delete PlayersTrie;

	delete hndl;
}