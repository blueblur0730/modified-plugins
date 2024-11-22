#if defined _l4d_stats_natives_others_included
	#endinput
#endif
#define _l4d_stats_natives_others_included

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

static bool s_bIsError = false;

any Native_IsMuted(Handle plugin, int numParams)
{
	int maxlength1;
	GetNativeStringLength(2, maxlength1);
	maxlength1 += 1;
	char[] SteamID = new char[maxlength1];
	GetNativeString(1, SteamID, maxlength1);

	char query[512]; bool bResult = false;
	Format(query, sizeof(query), "SELECT muted FROM %ssettings WHERE steamid = '%s'", g_sDbPrefix, SteamID);
	SQL_TQuery(db, NativeQuery_IsMuted, query, bResult);

	char error[128];
	if (SQL_GetError(db, error, sizeof(error)))
		ThrowNativeError(SP_ERROR_NOT_FOUND, "[L4D Stats]: An error occured on last query. Error: %s", error);

	if (s_bIsError)
	{
		s_bIsError = false;
		LogError("[L4D Stats]: Query succeeded but no player found.");
		return false;
	}

	return bResult;
}

void NativeQuery_IsMuted(Database owner, DBResultSet hndl, const char[] error, bool bResult)
{
	if (!hndl.RowCount)
	{
		s_bIsError = true;
		return;
	}

	if (hndl.FetchRow())
	{
		if (!hndl.IsFieldNull(0))
			bResult = view_as<bool>(hndl.FetchInt(0));
		else
			s_bIsError = true;
	}	
}