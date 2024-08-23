#if defined _l4d_stats_natives_included
	#endinput
#endif
#define _l4d_stats_natives_included

static bool s_bIsNotFound = false;
static ArrayList s_hArray = null;

enum L4DStats_SelectMethod
{
    ByRank = 1,
    BySteamID = 2,
    ByClientIndex = 3
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
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");
	}

	int iCount = 0;
	s_hArray.Get(0, iCount);
	delete s_hArray;
	return iCount;
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

// Check if a player is already in the DB.
any Native_CheckPlayer(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	L4DStats_SelectMethod method = view_as<L4DStats_SelectMethod>(GetNativeCell(1));

	switch (method)
	{
		case ByRank:
		{
			int rank = GetNativeCell(4);
			if (rank == -1)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT steamid FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_CheckPlayerByRank, query, rank);
		}

		case BySteamID:
		{
			int maxlength1;
			GetNativeStringLength(3, maxlength1);
			maxlength1 += 1;
			char[] SteamID = new char[maxlength1];
			GetNativeString(2, SteamID, maxlength1);

			if (strlen(SteamID) == 0 || (maxlength1 - 1) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string or 0 string length to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT * FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_CheckPlayerBySteamID, query);
		}

		case ByClientIndex:
		{
			int client = GetNativeCell(5);
			if (IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char SteamID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, SteamID, sizeof(SteamID));

			char query[512];
			Format(query, sizeof(query), "SELECT * FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, SteamID);
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

	IniArrayList();

	int maxlength;
	GetNativeStringLength(3, maxlength);
	maxlength += 1;
	char[] SteamID = new char[maxlength];

	int rank = GetNativeCell(1);
	if (rank == -1)
		ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

	char query[512];
	Format(query, sizeof(query), "SELECT steamid FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, NativeQuery_GetPlayerSteamID, query, rank);

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
	SetNativeString(1, SteamID, maxlength);
	delete s_hArray;
	return 0;
}

any Native_GetPlayerName(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	IniArrayList();

	int maxlength;
	GetNativeStringLength(3, maxlength);
	maxlength += 1;
	char[] Name = new char[maxlength];

	L4DStats_SelectMethod method = view_as<L4DStats_SelectMethod>(GetNativeCell(1));

	switch (method)
	{
		case ByRank:
		{
			int rank = GetNativeCell(6);
			if (rank == -1)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT name FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerNameByRank, query, rank);
		}

		case BySteamID:
		{
			int maxlength1;
			GetNativeStringLength(5, maxlength1);
			maxlength1 += 1;
			char[] SteamID = new char[maxlength1];
			GetNativeString(4, SteamID, maxlength1);

			if (strlen(SteamID) == 0 || (maxlength1 - 1) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string or 0 string length to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT name FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_GetPlayerNameBySteamID, query);
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
		
	s_hArray.GetString(0, Name, maxlength);
	SetNativeString(2, Name, maxlength);
	delete s_hArray;
	return 0;
}

any Native_GetPlayerPoints(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	IniArrayList();

	L4DStats_SelectMethod method = view_as<L4DStats_SelectMethod>(GetNativeCell(1));

	switch (method)
	{
		case ByRank:
		{
			int rank = GetNativeCell(4);
			if (rank == -1)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers ORDER BY %s DESC", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerPointsByRank, query, rank);
		}

		case BySteamID:
		{
			int maxlength1;
			GetNativeStringLength(3, maxlength1);
			maxlength1 += 1;
			char[] SteamID = new char[maxlength1];
			GetNativeString(2, SteamID, maxlength1);

			if (strlen(SteamID) == 0 || (maxlength1 - 1) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string or 0 string length to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_GetPlayerPointsBySteamID, query);
		}

		case ByClientIndex:
		{
			int client = GetNativeCell(5);
			if (IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char SteamID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, SteamID, sizeof(SteamID));

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix, SteamID);
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

	IniArrayList();

	L4DStats_SelectMethod method = view_as<L4DStats_SelectMethod>(GetNativeCell(1));

	switch (method)
	{
		case ByRank:
		{
			int rank = GetNativeCell(4);
			if (rank == -1)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers ORDER BY %s DESC", DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerTimerByRank, query, rank);
		}

		case BySteamID:
		{
			int maxlength1;
			GetNativeStringLength(3, maxlength1);
			maxlength1 += 1;
			char[] SteamID = new char[maxlength1];
			GetNativeString(2, SteamID, maxlength1);

			if (strlen(SteamID) == 0 || (maxlength1 - 1) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string or 0 string length to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_GetPlayerTimerBySteamID, query);
		}

		case ByClientIndex:
		{
			int client = GetNativeCell(5);
			if (IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char SteamID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, SteamID, sizeof(SteamID));

			char query[512];
			Format(query, sizeof(query), "SELECT %s FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, SteamID);
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

	IniArrayList();

	L4DStats_SelectMethod method = view_as<L4DStats_SelectMethod>(GetNativeCell(1));

	switch (method)
	{
		case ByRank:
		{
			int rank = GetNativeCell(4);
			if (rank == -1)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid rank number(%i) to query.", rank);

			char query[512];
			Format(query, sizeof(query), "SELECT (%s) / (%s) AS ppm FROM %splayers ORDER BY ppm DESC", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
			SQL_TQuery(db, NativeQuery_GetPlayerPPMByRank, query, rank);
		}

		case BySteamID:
		{
			int maxlength1;
			GetNativeStringLength(3, maxlength1);
			maxlength1 += 1;
			char[] SteamID = new char[maxlength1];
			GetNativeString(2, SteamID, maxlength1);

			if (strlen(SteamID) == 0 || (maxlength1 - 1) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string or 0 string length to query.");

			char query[512];
			Format(query, sizeof(query), "SELECT (%s) / (%s) FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, SteamID);
			SQL_TQuery(db, NativeQuery_GetPlayerPPMBySteamID, query);
		}

		case ByClientIndex:
		{
			int client = GetNativeCell(5);
			if (IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char SteamID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, SteamID, sizeof(SteamID));

			char query[512];
			Format(query, sizeof(query), "SELECT (%s) / (%s) FROM %splayers WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, SteamID);
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
		return 0;
	}

	int iPPM = 0;
	iPPM = s_hArray.Get(0);
	delete s_hArray;
	return iPPM;
}

any Native_GetPlayerRank(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	IniArrayList();

	L4DStats_SelectMethod method = view_as<L4DStats_SelectMethod>(GetNativeCell(1));

	switch (method)
	{
		case BySteamID:
		{
			int maxlength1;
			GetNativeStringLength(3, maxlength1);
			maxlength1 += 1;
			char[] SteamID = new char[maxlength1];
			GetNativeString(2, SteamID, maxlength1);

			if (strlen(SteamID) == 0 || (maxlength1 - 1) == 0)
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an empty string or 0 string length to query.");

			DataPack dp = new DataPack();

			dp.Reset();
			dp.WriteString(SteamID);

			char query[512];
			Format(query, sizeof(query), "SELECT * FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPLAYTIME);
			SQL_TQuery(db, NativeQuery_GetPlayerRankBySteamID, query, dp);
		}

		case ByClientIndex:
		{
			int client = GetNativeCell(4);
			if (IsClientBot(client))
				ThrowNativeError(SP_ERROR_PARAM, "[L4D Stats]: You shall not pass an invalid client index to query.");

			char SteamID[MAX_LINE_WIDTH];
			GetClientRankAuthString(client, SteamID, sizeof(SteamID));

			DataPack dp = new DataPack();

			dp.Reset();
			dp.WriteString(SteamID);

			char query[512];
			Format(query, sizeof(query), "SELECT * FROM %splayers ORDER BY %s DESC", g_sDbPrefix, DB_PLAYERS_TOTALPLAYTIME);
			SQL_TQuery(db, NativeQuery_GetPlayerRankBySteamID, query, dp);
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

	int iRank = 0;
	iRank = s_hArray.Get(0);
	delete s_hArray;
	return iRank;
}

void NativeQuery_GetTotalPlayer(Handle owner, DBResultSet hndl, const char[] error, any data)
{
	if (!hndl.RowCount)
	{
		s_bIsNotFound = true;
		return;
	}
	else
		s_hArray.Push(hndl.RowCount);
}


void NativeQuery_CheckMap(Handle owner, DBResultSet hndl, const char[] error, any data)
{
	if (!hndl.RowCount) s_bIsNotFound = true;
	else s_bIsNotFound = false;
}

void NativeQuery_CheckPlayerByRank(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	if (!hndl.RowCount) s_bIsNotFound = true;
	else s_bIsNotFound = false;
}

void NativeQuery_CheckPlayerBySteamID(Handle owner, DBResultSet hndl, const char[] error, any data)
{
	if (!hndl.RowCount) s_bIsNotFound = true;
	else s_bIsNotFound = false;
}

void NativeQuery_GetPlayerSteamID(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	FetchStringData(hndl, data);
}

void NativeQuery_GetPlayerNameByRank(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	FetchStringData(hndl, data);
}

void NativeQuery_GetPlayerNameBySteamID(Handle owner, DBResultSet hndl, const char[] error, any data)
{
	if (!hndl.RowCount) s_bIsNotFound = true;
	else s_bIsNotFound = false;

	if (!s_hArray)
		return;

	char Name[512];
	if (hndl.FetchRow())
	{
		hndl.FetchString(0, Name, sizeof(Name));
		s_hArray.PushString(Name);
	}
}

void NativeQuery_GetPlayerPointsByRank(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	FetchIntData(hndl, data);
}

void NativeQuery_GetPlayerPointsBySteamID(Handle owner, DBResultSet hndl, const char[] error, any data)
{
	FetchIntDataEx(hndl);
}

void NativeQuery_GetPlayerTimerByRank(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	FetchIntData(hndl, data);
}

void NativeQuery_GetPlayerTimerBySteamID(Handle owner, DBResultSet hndl, const char[] error, any data)
{
	FetchIntDataEx(hndl);
}

void NativeQuery_GetPlayerPPMByRank(Handle owner, DBResultSet hndl, const char[] error, int data)
{
	FetchIntData(hndl, data);
}

void NativeQuery_GetPlayerPPMBySteamID(Handle owner, DBResultSet hndl, const char[] error, any data)
{
	FetchIntDataEx(hndl);
}

void NativeQuery_GetPlayerRankBySteamID(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl.RowCount) s_bIsNotFound = true;
	else s_bIsNotFound = false;

	if (!s_hArray)
		return;

	char SteamID[MAX_AUTHID_LENGTH];
	dp.Reset();
	dp.ReadString(SteamID, sizeof(SteamID));

	int count = 0;
	char sBuffer[MAX_AUTHID_LENGTH]
	while (hndl.FetchRow())
	{
		count++;
		hndl.FetchString(0, sBuffer, sizeof(sBuffer));
		if (strcmp(sBuffer, SteamID) == 0)
		{
			s_hArray.Push(count);
			delete dp;
			break;
		}
	}
}

void FetchStringData(DBResultSet hndl, int data)
{
	if (!hndl.RowCount) s_bIsNotFound = true;
	else s_bIsNotFound = false;
	
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
	if (!hndl.RowCount) s_bIsNotFound = true;
	else s_bIsNotFound = false;

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