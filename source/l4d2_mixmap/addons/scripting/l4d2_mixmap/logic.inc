#if defined _l4d2_mixmap_logic_included
 #endinput
#endif
#define _l4d2_mixmap_logic_included

// ----------------------------------------------------------
// 		Map pool logic
// ----------------------------------------------------------
void SelectRandomMap() 
{
	g_bMaplistFinalized = true;
	SetRandomSeed(view_as<int>(GetEngineTime()));

	int i, mapIndex, mapsmax = g_cvMaxMapsNum.IntValue;
	ArrayList hArrayPool;
	char tag[BUF_SZ], map[BUF_SZ];

	// Select 1 random map for each rank out of the remaining ones
	for (i = 0; i < g_hArrayTagOrder.Length; i++) 
	{
		g_hArrayTagOrder.GetString(i, tag, BUF_SZ);
		g_hTriePools.GetValue(tag, hArrayPool);
		hArrayPool.Sort(Sort_Random, Sort_String);	//randomlize the array
		mapIndex = GetRandomInt(0, hArrayPool.Length - 1);

		hArrayPool.GetString(mapIndex, map, BUF_SZ);
		hArrayPool.Erase(mapIndex);
		if (mapsmax)	//if limit the number of missions in one campaign, check the number.
		{
			if (CheckSameCampaignNum(map) >= mapsmax)
			{
				while (hArrayPool.Length > 0)	// Reselect if the number will exceed the limit 
				{
					mapIndex = GetRandomInt(0, hArrayPool.Length - 1);
					hArrayPool.GetString(mapIndex, map, BUF_SZ);
					hArrayPool.Erase(mapIndex);
					if (CheckSameCampaignNum(map) < mapsmax) break;
				}
				if (CheckSameCampaignNum(map) >= mapsmax)	//Reselect some missions (like only 1 mission4, the mission4 can't select)
				{
					g_hTriePools.GetValue(tag, hArrayPool);
					hArrayPool.Sort(Sort_Random, Sort_String);
					mapIndex = GetRandomInt(0, hArrayPool.Length - 1);
					hArrayPool.GetString(mapIndex, map, BUF_SZ);
					ReSelectMapOrder(map);
				}
			}
		}
		g_hArrayMapOrder.PushString(map);
	}

	// Clear things because we only need the finalised map order in memory
	g_hTriePools.Clear();
	g_hArrayTagOrder.Clear();

	// Show final maplist to everyone
	for (i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
			FakeClientCommand(i, "sm_maplist");
	}

	CPrintToChatAll("%t", "Change_Map_First", g_bServerForceStart ? 5 : 15);	//Alternative for remixmap
	g_hCountDownTimer = CreateTimer(g_bServerForceStart ? 5.0 : 15.0, Timed_GiveThemTimeToReadTheMapList);	//Alternative for remixmap
}

void ReSelectMapOrder(char[] confirm)	//hope this will work
{
	char buffer[BUF_SZ];
	ArrayList hArrayPool;
	int mapindex;
	
	for (int i = g_hArrayMapOrder.Length - 1; i >= 0; i--) 
	{
		g_hArrayMapOrder.GetString(i, buffer, BUF_SZ);
		if (IsSameCampaign(confirm, buffer)) 
		{
			g_hArrayTagOrder.GetString(i, buffer, BUF_SZ);
			g_hTriePools.GetValue(buffer, hArrayPool);
			hArrayPool.Erase(hArrayPool.FindString(confirm));
			for (int j = 0; j <= i; j++) 
			{
				hArrayPool.Sort(Sort_Random, Sort_String);	//randomlize the array
				mapindex = GetRandomInt(0, hArrayPool.Length - 1);
				hArrayPool.GetString(mapindex, buffer, BUF_SZ);
				hArrayPool.Erase(mapindex);
				if (CheckSameCampaignNum(buffer) < g_cvMaxMapsNum.IntValue) 
				{
					g_hArrayMapOrder.SetString(i, buffer);
					break;
				}
			}
			return;
		}
	}
}

public Action Timed_GiveThemTimeToReadTheMapList(Handle timer)
{
	if (IsBuiltinVoteInProgress() && !g_bServerForceStart)
	{
		CPrintToChatAll("%t", "Vote_Progress_delay");
		g_hCountDownTimer = CreateTimer(20.0, Timed_GiveThemTimeToReadTheMapList);
		return Plugin_Handled;
	}
	if (g_bServerForceStart) g_bServerForceStart = false;
	g_hCountDownTimer = null;

	// call starting forward
	char sBuffer[BUF_SZ];
	g_hArrayMapOrder.GetString(0, sBuffer, BUF_SZ);

	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_iMapCount);
	Call_PushString(sBuffer);
	Call_Finish();

	GotoNextMap(true);
	return Plugin_Handled;
}
