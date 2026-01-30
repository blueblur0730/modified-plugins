
methodmap TheNavAreas
{
    public TheNavAreas(Address pThis) {
        return view_as<TheNavAreas>(pThis);
    }

	public int Count() {
		return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iNavCountOffset), NumberType_Int32);
	}

	public Address Dereference() {
		return LoadFromAddress(view_as<Address>(this), NumberType_Int32);
	}

	public NavArea GetArea(int i, bool bDereference = true) {
		if (!bDereference)
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(i*4), NumberType_Int32);
		return LoadFromAddress(this.Dereference() + view_as<Address>(i*4), NumberType_Int32);
	}
}

methodmap NavArea
{
	public bool IsNull() {
		return view_as<Address>(this) == Address_Null;
	}
	
	public void GetSpawnPos(float fPos[3]) {
		SDKCall(g_hSDKFindRandomSpot, this, fPos);
	}

	property int SpawnAttributes {
		public get() {
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iSpawnAttributesOffset), NumberType_Int32);
		}
	
		public set(int value) {
			StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iSpawnAttributesOffset), value, NumberType_Int32);
		}
	}
	
	public float GetFlow() {
		return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iFlowDistanceOffset), NumberType_Int32);
	}
}

stock bool HasSurVictim(int client, int iClass)
{
	switch (iClass)
	{
		case SMOKER:
			return GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0;
		case HUNTER:
			return GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0;
		case JOCKEY:
			return GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") > 0;
		case CHARGER:
			return GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0;
	}
	return false;
}

stock int GetZombieClass(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock bool GetSpawnPosByNavArea(float fPos[3], float fSpawnRange, bool bNearest = false)
{
	static TheNavAreas pTheNavAreas;
	static NavArea pArea;
	static float fSpawnPos[3], fFlow, fDist, fMapMaxFlowDist;
	static bool bFound, bFinaleArea;
	static int i, iAreaCount, iArrayLen, iMaxRandomBound;
	static SpawnData data;

	if (!GetSurPosData())
		return false;

	ArrayList array = new ArrayList(sizeof(data));
	pTheNavAreas = view_as<TheNavAreas>(g_pTheNavAreas.Dereference());
	fMapMaxFlowDist = L4D2Direct_GetMapMaxFlowDistance();
	iAreaCount = g_pTheNavAreas.Count();
	bFinaleArea = g_bFinalMap && L4D2_GetCurrentFinaleStage() < 18;

	for (i = 0; i < iAreaCount; i++)
	{
		pArea = pTheNavAreas.GetArea(i, false);
		if (!pArea || !IsValidFlags(pArea.SpawnAttributes, bFinaleArea))
			continue;

		fFlow = pArea.GetFlow();
		if (fFlow < 0.0 || fFlow > fMapMaxFlowDist)
			continue;

		pArea.GetSpawnPos(fSpawnPos);
		if (IsNearTheSur(fSpawnRange, fFlow, fSpawnPos, fDist))
		{
			if (!IsVisible(fSpawnPos, pArea) && !WillStuck(fSpawnPos))
			{
				data.fDist = fDist;
				data.fPos = fSpawnPos;
				array.PushArray(data);
			}
		}
	}

	iArrayLen = array.Length;
	if (iArrayLen > 0)
	{
		if (bNearest)
		{
			array.Sort(Sort_Ascending, Sort_Float);
			iMaxRandomBound = iArrayLen > 2 ? 2 : 0;
		}
		else
			iMaxRandomBound = iArrayLen-1;
		
		array.GetArray(GetRandomIntEx(0, iMaxRandomBound), data);
		fPos = data.fPos;
		if (bNearest)
			g_fNearestSpawnRange = data.fDist + NEAREST_RANGE_ADD;
		bFound = true;
	}
	else
	{
		if (bNearest)
			g_fNearestSpawnRange = L4D2_GetScriptValueFloat("ZombieDiscardRange", z_discard_range.FloatValue);
		bFound = false;
	}

	delete array;
	return bFound;
}

stock bool GetSurPosData()
{
	static SurPosData data;
	static int i, type;

	ArrayList array[2];
	array[BOT] = new ArrayList(sizeof(data));
	array[PLAYER] = new ArrayList(sizeof(data));

	g_iSurPosDataLen = 0;
	g_iSurCount = 0;

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated"))
		{
			data.fFlow = L4D2Direct_GetFlowDistance(i);
			GetClientEyePosition(i, data.fPos);

			if (IsFakeClient(i))
				array[BOT].PushArray(data);
			else
				array[PLAYER].PushArray(data);

			g_iSurvivors[g_iSurCount++] = i;
		}
	}

	// Prioritize spawning near real players.
	type = array[PLAYER].Length > 0 ? PLAYER : BOT;

	if (type || array[type].Length > 0)
	{
		delete g_aSurPosData;
		g_aSurPosData = array[type].Clone();
		g_iSurPosDataLen = g_aSurPosData.Length;
	}

	delete array[BOT];
	delete array[PLAYER];
	return g_iSurPosDataLen > 0;
}

stock bool IsValidFlags(int iFlags, bool bFinaleArea)
{
	if (!iFlags)
		return true;

	if (bFinaleArea && (iFlags & TERROR_NAV_FINALE) == 0)
		return false;

	return (iFlags & (TERROR_NAV_RESCUE_CLOSET|TERROR_NAV_RESCUE_VEHICLE)) == 0;
}

stock bool IsNearTheSur(float fSpawnRange, float fFlow, const float fPos[3], float &fDist)
{
	static SurPosData data;
	static int i;

	for (i = 0; i < g_iSurPosDataLen; i++)
	{
		g_aSurPosData.GetArray(i, data);
		if (FloatAbs(fFlow - data.fFlow) < fSpawnRange)
		{
			fDist = GetVectorDistance(data.fPos, fPos);
			if (fDist < fSpawnRange)
				return true;
		}
	}
	return false;
}

stock bool IsVisible(const float fPos[3], NavArea pArea)
{
	static int i;
	static float fTargetPos[3];

	fTargetPos = fPos;
	fTargetPos[2] += 62.0; // Eye position.

	for (i = 0; i < g_iSurCount; i++)
	{
		if (SDKCall(g_hSDKIsVisibleToPlayer, fTargetPos, g_iSurvivors[i], 2, 3, 0.0, 0, pArea, true))
			return true;
	}

	return false;
}

stock bool WillStuck(const float fPos[3])
{
	// All clients seem to be the same size.
	static const float fClientMinSize[3] = {-16.0, -16.0, 0.0};
	static const float fClientMaxSize[3] = {16.0, 16.0, 71.0};

	static bool bHit;
	static Handle hTrace;

	hTrace = TR_TraceHullFilterEx(fPos, fPos, fClientMinSize, fClientMaxSize, MASK_PLAYERSOLID, TraceFilter_Stuck);
	bHit = TR_DidHit(hTrace);

	delete hTrace;
	return bHit;
}

static bool TraceFilter_Stuck(int entity, int contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
		return false;
	return true;
}

stock int GetRandomSur()
{
	ArrayList array = new ArrayList();
	int client;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !GetEntProp(i, Prop_Send, "m_isIncapacitated"))
			array.Push(i);
	}

	if (array.Length > 0)
		client = array.Get(GetRandomIntEx(0, array.Length-1));

	delete array;
	return client;
}

stock int GetSpawnClass()
{
	int iCount[SI_CLASS_SIZE];
	int iClass, i;
	ArrayList array = new ArrayList();

	for (i = 1; i <= MaxClients; i++)
	{
		if (!g_bMark[i] || !IsClientInGame(i) || GetClientTeam(i) != 3 || !IsPlayerAlive(i) || !IsFakeClient(i))
			continue;

		iClass = GetZombieClass(i);
		if (iClass < 1 || iClass > 6)
			continue;

		iCount[iClass]++;
	}

	for (i = 1; i < SI_CLASS_SIZE; i++)
	{
		if (iCount[i] < g_iSpecialLimit[i])
			array.Push(i);
	}

	iClass = -1;
	if (array.Length > 0)
		iClass = array.Get(GetRandomIntEx(0, array.Length-1));

	delete array;
	return iClass;
}

stock int GetAllSpecialsTotal()
{
	int iCount, iClass;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bMark[i] || !IsClientInGame(i) || GetClientTeam(i) != 3 || !IsPlayerAlive(i) || !IsFakeClient(i))
			continue;

		iClass = GetZombieClass(i);
		if (iClass < 1 || iClass > 6)
			continue;

		iCount++;
	}

	return iCount;
}

stock int GetRandomIntEx(int min, int max)
{
	return GetURandomInt() % (max - min + 1) + min;
}