#if defined _l4d_stats_natives_timedmaps_included
	#endinput
#endif
#define _l4d_stats_natives_players_timedmaps_included

static bool s_bIsCreated = false;
static ArrayList s_harray = null;

enum GameModeID
{
    COOP = 0,
    VERSUS = 1,
    TEAMVERSUS = 2,
    REALISM = 3,
    SURVIVAL = 4,
    SCAVENGE = 5,
    TEAMSCAVENGE = 6,
    REALISMVERSUS = 7,
    TEAMREALISMVERSUS = 8,
    OTHERMUTATIONS = 9,
};

enum DifficultyID
{
    EASY = 0,
    NORMAL = 1,
    HARD = 2,
    IMPOSSIBLE = 3,
};

any Native_L4DStasts_Map(Handle plugin, int numParams)
{
	if (s_bIsCreated)
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is already created.");

	DataPack dp = new DataPack();

	dp.Reset();

	int maxlength1;
	GetNativeStringLength(2, maxlength1);
	maxlength1 += 1;
	char[] SteamID = new char[maxlength1];
	GetNativeString(1, SteamID, maxlength1);

	int maxlength2;
	GetNativeStringLength(4, maxlength2);
	maxlength2 += 1;
	char[] MapName = new char[maxlength2];
	GetNativeString(3, MapName, maxlength2);

	dp.WriteString(SteamID);
	dp.WriteString(MapName);
	dp.WriteCell(GetNativeCell(5));
	dp.WriteCell(GetNativeCell(6));

	s_bIsCreated = true;
	return dp;
}

any Native_L4DStasts_Map_deleteThis(Handle plugin, int numParams)
{
	DataPack dp = GetNativeCell(1);

	if (dp)
	{
		delete dp;
		s_bIsCreated = false;
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor DataPack Handle is already null.")

	return 0;
}

any Native_L4DStasts_Map_Rewrite(Handle plugin, int numParams)
{
	DataPack dp = GetNativeCell(1);

	if (dp)
	{
		dp.Reset();

		int maxlength1;
		GetNativeStringLength(3, maxlength1);
		maxlength1 += 1;
		char[] SteamID = new char[maxlength1];
		GetNativeString(2, SteamID, maxlength1);

		int maxlength2;
		GetNativeStringLength(5, maxlength2);
		maxlength2 += 1;
		char[] MapName = new char[maxlength2];
		GetNativeString(4, MapName, maxlength2);

		dp.WriteString(SteamID);
		dp.WriteString(MapName);
		dp.WriteCell(GetNativeCell(6));
		dp.WriteCell(GetNativeCell(7));
	}
	else ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Constructor Datapack Handle is null.");
	return 0;
}

any Native_HasPlayedMap(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	DataPack dp = GetNativeCell(1);
	char SteamID[MAX_AUTHID_LENGTH], MapName[256];
	dp.Reset();
	dp.ReadString(SteamID, sizeof(SteamID));
	dp.ReadString(MapName, sizeof(MapName));
	GameModeID GameMode = view_as<GameModeID>(dp.ReadCell());
	DifficultyID Difficulty = view_as<DifficultyID>(dp.ReadCell());
	
	char query[512]; bool bIsNotFound = false;
	Format(query, sizeof(query), "SELECT * FROM %stimedmaps WHERE steamid = '%s' AND map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = ''", g_sDbPrefix, SteamID, MapName, GameMode, Difficulty);
	SQL_TQuery(db, NativeQuery_HasPlayedMap, query, bIsNotFound);

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);

	if (bIsNotFound)
	{
		bIsNotFound = false;
		return false;
	}

	return true;
}

any Native_GetBestTime(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	IniArrayList(s_harray);

	DataPack dp = GetNativeCell(1);
	char SteamID[MAX_AUTHID_LENGTH], MapName[256];
	dp.Reset();
	dp.ReadString(SteamID, sizeof(SteamID));
	dp.ReadString(MapName, sizeof(MapName));
	GameModeID GameMode = view_as<GameModeID>(dp.ReadCell());
	DifficultyID Difficulty = view_as<DifficultyID>(dp.ReadCell());

	char query[512]; bool bIsNotFound = false;
	Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE steamid = '%s' AND map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = ''", g_sDbPrefix, SteamID, MapName, GameMode, Difficulty);
	SQL_TQuery(db, NativeQuery_GetBestTime, query, bIsNotFound);

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_harray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (bIsNotFound)
	{
		delete s_harray;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		return 0.0;
	}

	float bestTime = 0.0;
	bestTime = s_harray.Get(0);
	delete s_harray;
	return bestTime;
}

any Native_GetPlayCount(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	IniArrayList(s_harray);

	DataPack dp = GetNativeCell(1);
	char SteamID[MAX_AUTHID_LENGTH], MapName[256];
	dp.Reset();
	dp.ReadString(SteamID, sizeof(SteamID));
	dp.ReadString(MapName, sizeof(MapName));
	GameModeID GameMode = view_as<GameModeID>(dp.ReadCell());
	DifficultyID Difficulty = view_as<DifficultyID>(dp.ReadCell());

	char query[512]; bool bIsNotFound = false;
	Format(query, sizeof(query), "SELECT plays FROM %stimedmaps WHERE steamid = '%s' AND map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = ''", g_sDbPrefix, SteamID, MapName, GameMode, Difficulty);
	SQL_TQuery(db, NativeQuery_GetPlayCount, query, bIsNotFound);

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_harray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (bIsNotFound)
	{
		delete s_harray;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		return 0;
	}

	int count = 0;
	count = s_harray.Get(0);
	delete s_harray;
	return count;
}

any Native_GetPlayersCount(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	IniArrayList(s_harray);

	DataPack dp = GetNativeCell(1);
	char SteamID[MAX_AUTHID_LENGTH], MapName[256];
	dp.Reset();
	dp.ReadString(SteamID, sizeof(SteamID));
	dp.ReadString(MapName, sizeof(MapName));
	GameModeID GameMode = view_as<GameModeID>(dp.ReadCell());
	DifficultyID Difficulty = view_as<DifficultyID>(dp.ReadCell());

	char query[512]; bool bIsNotFound = false;
	Format(query, sizeof(query), "SELECT players FROM %stimedmaps WHERE steamid = '%s' AND map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = ''", g_sDbPrefix, SteamID, MapName, GameMode, Difficulty);
	SQL_TQuery(db, NativeQuery_GetPlayersCount, query, bIsNotFound);

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_harray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (bIsNotFound)
	{
		delete s_harray;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		return 0;
	}

	int count = 0;
	count = s_harray.Get(0);
	delete s_harray;
	return count;
}

any Native_GetBestTimeDate(Handle plugin, int numParams)
{
	if (!ValidatDataBase())
		ThrowNativeError(SP_ERROR_ABORTED, "[L4D Stats]: Database Handle is null.");

	IniArrayList(s_harray);

	DataPack dp = GetNativeCell(1);
	char SteamID[MAX_AUTHID_LENGTH], MapName[256];
	dp.Reset();
	dp.ReadString(SteamID, sizeof(SteamID));
	dp.ReadString(MapName, sizeof(MapName));
	GameModeID GameMode = view_as<GameModeID>(dp.ReadCell());
	DifficultyID Difficulty = view_as<DifficultyID>(dp.ReadCell());

	char query[512]; bool bIsNotFound = false;
	Format(query, sizeof(query), "SELECT modified FROM %stimedmaps WHERE steamid = '%s' AND map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = ''", g_sDbPrefix, SteamID, MapName, GameMode, Difficulty);
	SQL_TQuery(db, NativeQuery_GetBestTimeDate, query, bIsNotFound);

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
	{
		delete s_harray;
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);
	}

	if (bIsNotFound)
	{
		delete s_harray;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		return 0;
	}

	int maxlength1;
	GetNativeStringLength(3, maxlength1);
	maxlength1 += 1;
	char[] date = new char[maxlength1];

	s_harray.GetString(0, date, maxlength1);
	delete s_harray;

	SetNativeString(2, date, maxlength1);
	return 0;
}

void NativeQuery_HasPlayedMap(Database owner, DBResultSet hndl, const char[] error, bool bIsNotFound)
{
	if (!hndl.RowCount)
	{
		bIsNotFound = true;
		return;
	}
}

void NativeQuery_GetBestTime(Database owner, DBResultSet hndl, const char[] error, bool bIsNotFound)
{
	if (!hndl.RowCount)
	{
		bIsNotFound = true;
		return;
	}

	if (!s_harray)
		return;

	if (hndl.FetchRow())
	{
		if (!hndl.IsFieldNull(0))
			s_harray.Push(hndl.FetchFloat(0));
		else
			bIsNotFound = true;
	}
}

void NativeQuery_GetPlayCount(Database owner, DBResultSet hndl, const char[] error, bool bIsNotFound)
{
	if (!hndl.RowCount)
	{
		bIsNotFound = true;
		return;
	}

	if (!s_harray)
		return;

	if (hndl.FetchRow())
	{
		if (!hndl.IsFieldNull(0))
			s_harray.Push(hndl.FetchInt(0));
		else
			bIsNotFound = true;
	}
}

void NativeQuery_GetPlayersCount(Database owner, DBResultSet hndl, const char[] error, bool bIsNotFound)
{
	if (!hndl.RowCount)
	{
		bIsNotFound = true;
		return;
	}

	if (!s_harray)
		return;

	if (hndl.FetchRow())
	{
		if (!hndl.IsFieldNull(0))
			s_harray.Push(hndl.FetchInt(0));
		else
			bIsNotFound = true;
	}
}

void NativeQuery_GetBestTimeDate(Database owner, DBResultSet hndl, const char[] error, bool bIsNotFound)
{
	if (!hndl.RowCount)
	{
		bIsNotFound = true;
		return;
	}

	if (!s_harray)
		return;

	char date[128];
	if (hndl.FetchRow())
	{
		if (!hndl.IsFieldNull(0))
		{
			hndl.FetchString(0, date, sizeof(date));
			s_harray.PushString(date);
		}
		else
			bIsNotFound = true;
	}
}