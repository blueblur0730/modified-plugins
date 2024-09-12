#if defined __confogl_functions_included
	#endinput
#endif
#define __confogl_functions_included

#define CVAR_PREFIX			"confogl_"
#define CVAR_FLAGS			FCVAR_NONE
#define CVAR_PRIVATE		(FCVAR_DONTRECORD|FCVAR_PROTECTED)

//static ConVar
	//g_hCvarMpGameMode = null;

static bool
	bIsPluginEnabled = false;

void Fns_OnModuleStart()
{
	//g_hCvarMpGameMode = FindConVar("mp_gamemode");
}

stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}

stock ConVar CreateConVarEx(const char[] name, const char[] defaultValue, const char[] description = "", int flags = FCVAR_NONE, \
								bool hasMin = false, float min = 0.0, bool hasMax = false, float max = 0.0)
{
	char sBuffer[128];
	ConVar cvar = null;

	Format(sBuffer, sizeof(sBuffer), "%s%s", CVAR_PREFIX, name);
	flags = flags | CVAR_FLAGS;
	cvar = CreateConVar(sBuffer, defaultValue, description, flags, hasMin, min, hasMax, max);

	return cvar;
}

stock ConVar FindConVarEx(const char[] name)
{
	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "%s%s", CVAR_PREFIX, name);

	return FindConVar(sBuffer);
}

/**
 * Processes the players in the game and populates the given array with their indices.
 *
 * @param iPlayers The array to store the indices of the players.
 * @param iNumPlayers A reference to the variable that will hold the number of players.
 * @return The number of connected clients in the game.
 */
stock int ProcessPlayers(int[] iPlayers, int &iNumPlayers)
{
	int iConnectedCount = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			if (IsClientConnected(i))
				iConnectedCount++;
		}
		else
		{
			if (!IsFakeClient(i) && GetClientTeam(i) > TEAM_SPECTATE)
				iPlayers[iNumPlayers++] = i;
		}
	}

	return iConnectedCount;
}

stock bool IsHumansOnServer()
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			return true;
	}

	return false;
}

stock bool IsPluginEnabled(bool bSetStatus = false, bool bStatus = false)
{
	if (bSetStatus)
		bIsPluginEnabled = bStatus;

	return bIsPluginEnabled;
}

stock void ZeroVector(float vector[3])
{
	vector = NULL_VECTOR;
}

stock void AddToVector(float to[3], float from[3])
{
	to[0] += from[0];
	to[1] += from[1];
	to[2] += from[2];
}

stock void CopyVector(float to[3], float from[3])
{
	to = from;
}

stock int GetURandomIntRange(int min, int max)
{
	return RoundToNearest((GetURandomFloat() * (max - min)) + min);
}

/**
 * Finds the first occurrence of a pattern in another string.
 *
 * @param str			String to search in.
 * @param pattern		String pattern to search for
 * @param reverse		False (default) to search forward, true to search
 *						backward.
 * @return				The index of the first character of the first
 *						occurrence of the pattern in the string, or -1 if the
 *						character was not found.
 */
/*stock int FindPatternInString(const char[] str, const char[] pattern, bool reverse = false)
{
	int i = 0, len = strlen(pattern);
	char c = pattern[0];

	while (i < len && (i = FindCharInString(str[i], c, reverse)) != -1) {
		if (strncmp(str[i], pattern, len)) {
			return i;
		}
	}

	return -1;
}*/

/**
 * Counts the number of occurences of pattern in another string.
 *
 * @param str			String to search in.
 * @param pattern		String pattern to search for
 * @param overlap		False (default) to count only non-overlapping
 *						occurences, true to count matches within other
 *						occurences.
 * @return				The number of occurences of the pattern in the string
 */
/*stock int CountPatternsInString(const char[] str, const char[] pattern, bool overlap = false)
{
	int off = 0, i = 0, delta = 0, cnt = 0;
	int len = strlen(str);

	delta = (overlap) ? strlen(pattern) : 1;

	while (i < len && (off = FindPatternInString(str[i], pattern)) != -1) {
		cnt++;
		i += off + delta;
	}

	return cnt;
}*/

/**
 * Counts the number of occurences of pattern in another string.
 *
 * @param str			String to search in.
 * @param c				Character to search for.
 * @return				The number of occurences of the pattern in the string
 */
/*stock int CountCharsInString(const char[] str, int c)
{
	int off, i, cnt, len = strlen(str);

	while (i < len && (off = FindCharInString(str[i], c)) != -1) {
		cnt++;
		i += off + 1;
	}

	return cnt;
}*/
