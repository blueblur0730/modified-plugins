#if defined _l4d2_mixmap_util_included
 #endinput
#endif
#define _l4d2_mixmap_util_included

// ----------------------------------------------------------
// 		Basic helpers
// ----------------------------------------------------------
// Return false if pretty name not found, ture otherwise
stock bool GetPrettyName(char[] map) 
{
	static KeyValues hKvMapNames = null;
	if (hKvMapNames == null) 
	{
		hKvMapNames = new KeyValues("Mixmap Map Names");
		if (!hKvMapNames.ImportFromFile(PATH_KV)) 
		{
			LogMessage("Couldn't create KV for map names.");
			hKvMapNames = null;
			return false;
		}
	}
	
	char buffer[BUF_SZ];
	hKvMapNames.GetString(map, buffer, BUF_SZ, "no");
		
	if (!StrEqual(buffer, "no")) 
	{
		strcopy(map, BUF_SZ, buffer);
		return true;
	}
	return false;
}

stock bool IsClientAndInGame(int index) 
{
	return (index > 0 && index <= MaxClients && IsClientInGame(index) && IsClientConnected(index) && !IsFakeClient(index) && GetClientTeam(index) != 1);
}

stock int CheckSameCampaignNum(char[] map)
{
	int count = 0;
	char buffer[BUF_SZ];
	
	for (int i = 0; i < g_hArrayMapOrder.Length; i++)
	{
		g_hArrayMapOrder.GetString(i, buffer, sizeof(buffer));
		if (IsSameCampaign(map, buffer))
			count ++;
	}
	
	return count;
}

stock bool IsSameCampaign(char[] map1, char[] map2)
{
	char buffer1[BUF_SZ], buffer2[BUF_SZ];
	
	strcopy(buffer1, BUF_SZ, map1);
	strcopy(buffer2, BUF_SZ, map2);
	
	if (GetPrettyName(buffer1)) SplitString(buffer1, "_", buffer1, sizeof(buffer1));
	if (GetPrettyName(buffer2)) SplitString(buffer2, "_", buffer2, sizeof(buffer2));
	
	if (StrEqual(buffer1, buffer2)) 
		return true;

	return false;
}

// Returns a handle to the first array which is found to contain the specified mapname
// (should be the first and only one) (will this be used?)
stock ArrayList GetPoolThatContainsMap(char[] map, int index, char[] tag) 
{
	ArrayList hArrayMapPool;

	for (int i = 0; i < g_hArrayTags.Length; i++) 
	{
		g_hArrayTags.GetString(i, tag, BUF_SZ);
		g_hTriePools.GetValue(tag, hArrayMapPool);
		if ((index = hArrayMapPool.FindString(map)) >= 0) {
			return hArrayMapPool;
		}
	}
	return null;
}

stock bool InSecondHalfOfRound()
{
    return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}