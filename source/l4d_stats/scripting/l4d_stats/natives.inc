#if defined _l4d_stats_natives_included
	#endinput
#endif
#define _l4d_stats_natives_included

static bool s_bIsNotFound = false;
static ArrayList s_hArray = null;

enum L4DStats_PlayerDataType
{
    ByRank = 1,
    BySteamID = 2,
    ByClientIndex = 3
};

enum CaculatorType
{
    Add = 1,
    Subtract = 2,
    Multiply = 3,
    Divide = 4
};


bool ValidatDataBase()
{
	if (!db)
		return false;

	return true;
}

void IniArrayList()
{
	if (!s_hArray)
		s_hArray = new ArrayList();

	if (s_hArray.Length != 0)
		s_hArray.Clear();
}

// Check connection to database.
any Native_IsConnected(Handle plugin, int numParams)
{
	return (db != null) ? true : false;
}

// Check the validity of DB table(s)
any Native_CheckDBValidity(Handle plugin, int numParams)
{
	return CheckDatabaseValidity(g_sDbPrefix);
}

any Native_Prepare(Handle plugin, int numParams)
{
	DataPack dp = new DataPack();
	dp.Reset();
	dp.WriteCell(GetNativeCell(1));
	dp.WriteCell(GetNativeCell(2));

	int maxlength1;
	GetNativeStringLength(4, maxlength1);
	maxlength1 += 1;
	char[] SteamID = new char[maxlength1];
	GetNativeString(3, SteamID, maxlength1);
	dp.WriteString(SteamID);

	return dp;
}

any Native_deleteThis(Handle plugin, int numParams)
{
	DataPack dp = GetNativeCell(1);

	if (dp)
		delete dp;

	return 0;
}

any Native_Rewrite(Handle plugin, int numParams)
{
	DataPack dp = GetNativeCell(1);

	if (dp)
	{
		dp.Reset();
		dp.WriteCell(GetNativeCell(2));
		dp.WriteCell(GetNativeCell(3));

		int maxlength1;
		GetNativeStringLength(5, maxlength1);
		maxlength1 += 1;
		char[] SteamID = new char[maxlength1];
		GetNativeString(4, SteamID, maxlength1);
		dp.WriteString(SteamID);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");
	return 0;
}

any Native_GetTotalPlayer(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	IniArrayList();

	char query[128];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	SQL_TQuery(db, NativeQuery_GetTotalPlayer, query);

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		delete s_hArray;
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Query succeeded but no player found.");
	}

	int iCount = 0;
	s_hArray.Get(0, iCount);
	delete s_hArray;
	return iCount;
}

// Check if a player is already in the DB.
any Native_CheckPlayer(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	L4DStats_PlayerDataType method;

	if (dp)
	{
		dp.Reset();
		method = GetNativeCell(2);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is null.");

	int rank = dp.ReadCell();
	int client = dp.ReadCell();

	char SteamID[MAX_AUTHID_LENGTH];
	dp.ReadString(SteamID, sizeof(SteamID));

	switch (method)
	{
		case ByRank:
		{
			if (rank < 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT * FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_CheckPlayerByRank, query, rank);
		}

		case BySteamID:
		{
			if (!strlen(SteamID))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT * FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_CheckPlayerBySteamID, query);
		}

		case ByClientIndex:
		{
			if (!IsClientInGame(client) || IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char AuthID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, AuthID, sizeof(AuthID));

			char query[512];
			Format(query, sizeof(query), "SELECT * FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, AuthID);
			SQL_TQuery(db, NativeQuery_CheckPlayerBySteamID, query);
		}
	}

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		return false;
	}

	return true;
}

any Native_GetPlayerSteamID(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	L4DStats_PlayerDataType method;

	if (dp)
	{
		dp.Reset();
		method = GetNativeCell(2);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is null.");

	if (method == BySteamID)
		ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: Why did you choose to query SteamID by SteamID?");

	int rank = dp.ReadCell();
	int client = dp.ReadCell();

	IniArrayList();

	int maxlength;
	GetNativeStringLength(4, maxlength);
	maxlength += 1;
	char[] SteamID = new char[maxlength];

	if (method == ByClientIndex)
	{
		if (IsClientBot(client) || !IsClientInGame(client))
			ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

		GetClientRankAuthString(client, SteamID, maxlength);
		SetNativeString(2, SteamID, maxlength);
		return 0;
	}

	if (method == ByRank)
	{
		if (rank == -1)
			ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

		char query[512];
		Format(query, sizeof(query), "SELECT steamid FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
		SQL_TQuery(db, NativeQuery_GetPlayerSteamID, query, rank);
	}

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		delete s_hArray;
		return 0;
	}

	s_hArray.GetString(0, SteamID, maxlength);
	SetNativeString(3, SteamID, maxlength);
	delete s_hArray;
	return 0;
}

any Native_GetPlayerName(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	L4DStats_PlayerDataType method;

	if (dp)
	{
		dp.Reset();
		method = GetNativeCell(2);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is null.");

	int rank = dp.ReadCell();
	int client = dp.ReadCell();

	char SteamID[MAX_AUTHID_LENGTH];
	dp.ReadString(SteamID, sizeof(SteamID));

	IniArrayList();

	int maxlength;
	GetNativeStringLength(4, maxlength);
	maxlength += 1;
	char[] Name = new char[maxlength];

	switch (method)
	{
		case ByRank:
		{
			if (rank < 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT name FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerNameByRank, query, rank);
		}

		case BySteamID:
		{
			if (strlen(SteamID) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT name FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_GetPlayerNameBySteamID, query);
		}

		case ByClientIndex:
		{
			if (!IsClientInGame(client) || IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index.");

			char sName[MAX_LINE_WIDTH];
			GetClientName(client, sName, sizeof(sName));
			SetNativeString(3, Name, maxlength);
			return 0;
		}
	}

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: Query succeeded but no player found.");
	}
		
	s_hArray.GetString(0, Name, maxlength);
	SetNativeString(3, Name, maxlength);
	delete s_hArray;
	return 0;
}

any Native_GetPlayerPoints(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	L4DStats_PlayerDataType method;

	if (dp)
	{
		dp.Reset();
		method = GetNativeCell(2);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is null.");

	int rank = dp.ReadCell();
	int client = dp.ReadCell();

	char SteamID[MAX_AUTHID_LENGTH];
	dp.ReadString(SteamID, sizeof(SteamID));

	IniArrayList();

	switch (method)
	{
		case ByRank:
		{
			if (rank < 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers ORDER BY %s DESC", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerPointsByRank, query, rank);
		}

		case BySteamID:
		{
			if (strlen(SteamID) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_GetPlayerPointsBySteamID, query);
		}

		case ByClientIndex:
		{
			if (!IsClientInGame(client) || IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char AuthID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, AuthID, sizeof(AuthID));

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, AuthID);
			SQL_TQuery(db, NativeQuery_GetPlayerPointsBySteamID, query);
		}
	}

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		delete s_hArray;
		return 0;
	}

	int iPoints = 0;
	iPoints = s_hArray.Get(0);
	delete s_hArray;
	return iPoints;
}

any Native_GetPlayerTime(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	L4DStats_PlayerDataType method;

	if (dp)
	{
		dp.Reset();
		method = GetNativeCell(2);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is null.");

	int rank = dp.ReadCell();
	int client = dp.ReadCell();

	char SteamID[MAX_AUTHID_LENGTH];
	dp.ReadString(SteamID, sizeof(SteamID));

	IniArrayList();

	switch (method)
	{
		case ByRank:
		{
			if (rank < 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers ORDER BY %s DESC", DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerTimerByRank, query, rank);
		}

		case BySteamID:
		{
			if (strlen(SteamID) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string or 0 string length to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_GetPlayerTimerBySteamID, query);
		}

		case ByClientIndex:
		{
			if (!IsClientInGame(client) || IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char AuthID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, AuthID, sizeof(AuthID));

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, AuthID);
			SQL_TQuery(db, NativeQuery_GetPlayerTimerBySteamID, query);
		}
	}

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		delete s_hArray;
		return 0;
	}

	int iplaytime = 0;
	iplaytime = s_hArray.Get(0);
	delete s_hArray;
	return iplaytime;
}

any Native_GetPlayerPPM(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	L4DStats_PlayerDataType method;

	if (dp)
	{
		dp.Reset();
		method = GetNativeCell(2);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is null.");

	int rank = dp.ReadCell();
	int client = dp.ReadCell();

	char SteamID[MAX_AUTHID_LENGTH];
	dp.ReadString(SteamID, sizeof(SteamID));

	IniArrayList();

	switch (method)
	{
		case ByRank:
		{
			if (rank < 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT (%s) / (%s) AS ppm FROM %splayers ORDER BY ppm DESC", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix);
			SQL_TQuery(db, NativeQuery_GetPlayerPPMByRank, query, rank);
		}

		case BySteamID:
		{
			if (strlen(SteamID) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string or 0 string length to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT (%s) / (%s) AS ppm FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_GetPlayerPPMBySteamID, query);
		}

		case ByClientIndex:
		{
			if (!IsClientInGame(client) || IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char AuthID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, AuthID, sizeof(AuthID));

			char query[512];
			Format(query, sizeof(query), "SELECT (%s) / (%s) AS ppm FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, AuthID);
			SQL_TQuery(db, NativeQuery_GetPlayerPPMBySteamID, query);
		}
	}

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		delete s_hArray;
		return 0.0;
	}

	float iPPM = 0.0;
	iPPM = s_hArray.Get(0);
	delete s_hArray;
	return iPPM;
}

any Native_GetPlayerRank(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	L4DStats_PlayerDataType method;

	if (dp)
	{
		dp.Reset();
		method = GetNativeCell(2);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is null.");

	int rank = dp.ReadCell();
	int client = dp.ReadCell();

	// i hate warning 204
	if (rank > 0)
		rank = 0;

	IniArrayList();

	switch (method)
	{
		case BySteamID:
		{
			char query[512];
			Format(query, sizeof(query), "SELECT steamid FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerRankBySteamID, query, dp);
		}

		case ByClientIndex:
		{
			if (!IsClientInGame(client) || IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT steamid FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerRankBySteamIDEx, query, client);
		}

		case ByRank: ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: Why did you query rank number by rank number?.");
	}

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		delete s_hArray;
		return 0;
	}

	int iRank = 0;
	iRank = s_hArray.Get(0);
	delete s_hArray;
	return iRank;
}

any Native_UpdatePoints(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	L4DStats_PlayerDataType method;

	if (dp)
	{
		dp.Reset();
		method = GetNativeCell(2);
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is null.");

	int rank = dp.ReadCell();
	int client = dp.ReadCell();

	char SteamID[MAX_AUTHID_LENGTH];
	dp.ReadString(SteamID, sizeof(SteamID));

	CaculatorType type = view_as<CaculatorType>(GetNativeCell(3));
	int points = GetNativeCell(4);

	char expression[8];
	switch (type)
	{
		case Add: Format(expression, sizeof(expression), "+");
		case Subtract: Format(expression, sizeof(expression), "-");
		case Multiply: Format(expression, sizeof(expression), "*");
		case Divide: Format(expression, sizeof(expression), "/");
	}

	switch (method)
	{
		case BySteamID:
		{
			if (strlen(SteamID) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string to query.");

			char query[512];
			Format(query, sizeof(query), "UPDATE %splayers SET points = points %s %i WHERE steamid = '%s'", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS, expression, points, SteamID);
			SQL_TQuery(db, NativeQuery_ErrorReport, query);
		}

		case ByClientIndex:
		{
			if (!IsClientInGame(client) || IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char AuthID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, AuthID, sizeof(AuthID));

			char query[512];
			Format(query, sizeof(query), "UPDATE %splayers SET points = points %s %i WHERE steamid = '%s'", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS, expression, points, AuthID);
			SQL_TQuery(db, NativeQuery_ErrorReport, query);
		}

		case ByRank:
		{
			if (rank < 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			DataPack datapack = new DataPack();
			datapack.Reset();
			datapack.WriteCell(rank);
			datapack.WriteString(expression);
			datapack.WriteCell(points);

			char query[512];
			Format(query, sizeof(query), "SELECT steamid FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_UpdatePointsByRank, query, datapack);
		}
	}

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		return 0;
	}

	return 0;
}

// Check if a map is already in the DB.
any Native_CheckMap(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] ParamNameMap = new char[maxlength];
	GetNativeString(1, ParamNameMap, maxlength);

	int maxlength1;
	GetNativeStringLength(2, maxlength1);
	maxlength1 += 1;
	char[] ParamNameGameMode = new char[maxlength1];
	GetNativeString(2, ParamNameGameMode, maxlength1);

	char query[512];
	Format(query, sizeof(query), "SELECT name FROM %smaps WHERE LOWER(name) = LOWER('%s') AND gamemode = %i AND mutation = '%s'", g_sDbPrefix, ParamNameMap, ParamNameGameMode, g_sCurrentMutation);
	SQL_TQuery(db, NativeQuery_CheckMap, query);

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_hArray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (s_bIsNotFound)
	{
		s_bIsNotFound = false;
		return false;
	}

	return true;
}

void NativeQuery_GetTotalPlayer(Database owner, DBResultSet hndl, const char[] error, any data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	}
	else
		s_hArray.Push(hndl.RowCount);
}


void NativeQuery_CheckMap(Database owner, DBResultSet hndl, const char[] error, any data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 
}

void NativeQuery_CheckPlayerByRank(Database owner, DBResultSet hndl, const char[] error, int data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 

	int count = 0;
	while (hndl.FetchRow())
	{
		count++;
		
		if (data == count)
		{
			s_bIsNotFound = false;
			break;
		}
	}

	if (!s_bIsNotFound)	return;
	else s_bIsNotFound = true;
}

void NativeQuery_CheckPlayerBySteamID(Database owner, DBResultSet hndl, const char[] error, any data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 
}

void NativeQuery_GetPlayerSteamID(Database owner, DBResultSet hndl, const char[] error, int data)
{
	FetchStringData(hndl, data);
}

void NativeQuery_GetPlayerNameByRank(Database owner, DBResultSet hndl, const char[] error, int data)
{
	FetchStringData(hndl, data);
}

void NativeQuery_GetPlayerNameBySteamID(Database owner, DBResultSet hndl, const char[] error, any data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 

	if (!s_hArray)
		return;

	char Name[512];
	if (hndl.FetchRow())
	{
		hndl.FetchString(0, Name, sizeof(Name));
		s_hArray.PushString(Name);
	}
}

void NativeQuery_GetPlayerPointsByRank(Database owner, DBResultSet hndl, const char[] error, int data)
{
	FetchIntData(hndl, data);
}

void NativeQuery_GetPlayerPointsBySteamID(Database owner, DBResultSet hndl, const char[] error, any data)
{
	FetchIntDataEx(hndl);
}

void NativeQuery_GetPlayerTimerByRank(Database owner, DBResultSet hndl, const char[] error, int data)
{
	FetchIntData(hndl, data);
}

void NativeQuery_GetPlayerTimerBySteamID(Database owner, DBResultSet hndl, const char[] error, any data)
{
	FetchIntDataEx(hndl);
}

void NativeQuery_GetPlayerPPMByRank(Database owner, DBResultSet hndl, const char[] error, int data)
{
	FetchFloatData(hndl, data);
}

void NativeQuery_GetPlayerPPMBySteamID(Database owner, DBResultSet hndl, const char[] error, any data)
{
	FetchFloatDataEx(hndl);
}

void NativeQuery_GetPlayerRankBySteamID(Database owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 

	if (!s_hArray)
		return;

	char SteamID[MAX_AUTHID_LENGTH];
	dp.ReadString(SteamID, sizeof(SteamID));

	if (strlen(SteamID) == 0)
		ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string to query.");

	int count = 0;
	char sBuffer[MAX_AUTHID_LENGTH]
	while (hndl.FetchRow())
	{
		count++;
		hndl.FetchString(0, sBuffer, sizeof(sBuffer));
		if (strcmp(sBuffer, SteamID) == 0)
		{
			s_hArray.Push(count);
			break;
		}
	}
}

void NativeQuery_GetPlayerRankBySteamIDEx(Database owner, DBResultSet hndl, const char[] error, int data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 

	if (!s_hArray)
		return;

	char AuthID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, AuthID, sizeof(AuthID));

	int count = 0;
	char sBuffer[MAX_AUTHID_LENGTH]
	while (hndl.FetchRow())
	{
		count++;
		hndl.FetchString(0, sBuffer, sizeof(sBuffer));
		if (strcmp(sBuffer, AuthID) == 0)
		{
			s_hArray.Push(count);
			break;
		}
	}
}

void NativeQuery_ErrorReport(Database owner, DBResultSet hndl, const char[] error, any data)
{
	if (strlen(error) != 0)
		LogError("SQL Error: %s", error);
}

void NativeQuery_UpdatePointsByRank(Database owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	}

	int data = 0;
	char expression[8];
	int points = 0;

	if (dp)
	{
		dp.Reset();
		data = dp.ReadCell();
		dp.ReadString(expression, sizeof(expression));
		points = dp.ReadCell();
		delete dp;
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: DataPack Handle is null on NativeQuery_UpdatePointsByRank.");

	int count = 0;
	char Name[512];
	bool bFound = false;
	while (hndl.FetchRow())
	{
		count++;
		
		if (data == count)
		{
			bFound = true;
			hndl.FetchString(0, Name, sizeof(Name));
			break;
		}
	}

	if (bFound)
	{
		char query[512];
		Format(query, sizeof(query), "UPDATE %splayers SET points = points %s %i WHERE steamid = '%s'", g_sDbPrefix, expression, points, Name);
		SQL_TQuery(db, NativeQuery_ErrorReport, query);
	}
	else s_bIsNotFound = true;
}

void FetchStringData(DBResultSet hndl, int data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 
	
	if (!s_hArray)
		return;

	int count = 0;
	char Name[512];
	while (hndl.FetchRow())
	{
		count++;
		
		if (data == count)
		{
			hndl.FetchString(0, Name, sizeof(Name));
			s_hArray.PushString(Name);
			break;
		}
	}
}

void FetchIntData(DBResultSet hndl, int data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 

	if (!s_hArray)
		return;

	int count = 0;
	while (hndl.FetchRow())
	{
		count++;
		
		if (data == count)
		{
			s_hArray.Push(hndl.FetchInt(0));
			break;
		}
	}
}

void FetchIntDataEx(DBResultSet hndl)
{
	if (!hndl.RowCount) s_bIsNotFound = true;
	else s_bIsNotFound = false;

	if (!s_hArray)
		return;

	if (hndl.FetchRow())
		s_hArray.Push(hndl.FetchInt(0));
}

void FetchFloatData(DBResultSet hndl, int data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 

	if (!s_hArray)
		return;

	int count = 0;
	while (hndl.FetchRow())
	{
		count++;
		
		if (data == count)
		{
			s_hArray.Push(hndl.FetchFloat(0));
			break;
		}
	}
}

void FetchFloatDataEx(DBResultSet hndl)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	} 

	if (!s_hArray)
		return;

	if (hndl.FetchRow())
		s_hArray.Push(hndl.FetchFloat(0));
}