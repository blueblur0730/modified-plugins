
stock bool GetCrosshairPos(int client, float fPos[3])
{
	float fClientAng[3], fClientPos[3];
	GetClientEyeAngles(client, fClientAng);
	GetClientEyePosition(client, fClientPos);

	Handle hTrace = TR_TraceRayFilterEx(fClientPos, fClientAng, MASK_SHOT, RayType_Infinite, TraceFilter);
	if (TR_DidHit(hTrace))
	{
		TR_GetEndPosition(fPos, hTrace);	//获得碰撞点
		fPos[2] += 20.0;					// 避免产生在地下
		delete hTrace;
		return true;
	}

	delete hTrace;
	return false;
}

static bool TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients;
}

stock bool TwentyPercentTrue()
{
    return (GetRandomFloat(0.0, 1.0) > 0.8);
}

enum ZombieType
{
	ZOMBIE_SHAMBLER,
	ZOMBIE_RUNNER,
	ZOMBIE_KID
}

stock int CreateZombie( ZombieType type,
                        float fPos[3] = {0.0, 0.0, 0.0}, 
                        float fAngle[3] = {0.0, 0.0, 0.0},
                        RenderMode renderMode = RENDER_WORLDGLOW,
                        RenderFx renderFx = RENDERFX_NONE,
                        int color[4] = {255, 255, 255, 255},
                        int spawnflags = 1,
                        bool bNoShadow = false,
                        bool bNoRecieveShadow = false,
                        bool bIgnoreUnseenEnemies = false,
                        const char[] sModelOverride = "",
                        bool bCanCrawl = false,
                        bool bCanArmored = false,
                        bool bCanGrab = true)
{
	int ent = INVALID_ENT_REFERENCE;
	switch (type)
	{
		case ZOMBIE_SHAMBLER:
			ent = CreateEntityByName("npc_nmrih_shamblerzombie");
		case ZOMBIE_RUNNER:
			ent = CreateEntityByName("npc_nmrih_runnerzombie");
		case ZOMBIE_KID:
			ent = CreateEntityByName("npc_nmrih_kidzombie");
	}

	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
	{
		DispatchKeyValueVector(ent, "origin", fPos);
		DispatchKeyValueVector(ent, "angle", fAngle);

		if (type == ZOMBIE_RUNNER || type == ZOMBIE_SHAMBLER)
		{
			DispatchKeyValue(ent, "model", "models/nmr_zombie/zombie_shared.mdl");
		}
		else if (type == ZOMBIE_KID)
		{
			DispatchKeyValue(ent, "model", GetRandomInt(0, 1) ? "models/nmr_zombie/zombiekid_boy.mdl" : "models/nmr_zombie/zombiekid_gril.mdl");
		}

		SetEntityRenderMode(ent, renderMode);
		SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
		SetEntityRenderFx(ent, renderFx);

		DispatchKeyValueInt(ent, "spawnflags", spawnflags);
		DispatchKeyValue(ent, "disablereceiveshadows", bNoRecieveShadow ? "1" : "0");
		DispatchKeyValue(ent, "disableshadows", bNoShadow ? "1" : "0");
		DispatchKeyValue(ent, "ignoreunseenenemies", bIgnoreUnseenEnemies ? "1" : "0");

		if (sModelOverride[0] != '\0' && PrecacheModel(sModelOverride))
		{
			DispatchKeyValue(ent, "modeloverride", sModelOverride);
		}

		DispatchKeyValue(ent, "spawncrawler", bCanCrawl ? "1" : "0");
		DispatchKeyValue(ent, "spawnarmor", bCanArmored ? "1" : "0");
		DispatchKeyValue(ent, "cangrab", bCanGrab ? "1" : "0");

		SetVariantString("player D_HT");
		AcceptEntityInput(ent, "SetRelationship");

		DispatchSpawn(ent);
		ActivateEntity(ent);
		return ent;
	}

	return INVALID_ENT_REFERENCE;
}

// from nmrih-better-tools by Dysphie. Credits to them.
// https://github.com/dysphie/nmrih-better-tools/blob/a02f6a8740ff11a7fcf198bf326081c18f92d551/scripting/nmrih-bettertools.sp#L453
stock bool CreateDesiredThingFromRandomSpawner(const char[] classname,
											   float fPos[3]	= { 0.0, 0.0, 0.0 },
											   float fAngle[3]	= { 0.0, 0.0, 0.0 },
											   int	 ammo_max	= 0,
											   int	 ammo_min	= 0,
											   int	 spawnflags = 0)
{
	int spawner = CreateEntityByName("random_spawner");
	if (spawner == INVALID_ENT_REFERENCE || !IsValidEntity(spawner))
		return false;

	DispatchKeyValue(spawner, classname, "100");	// the number is the percentage.
	DispatchKeyValueInt(spawner, "spawnflags", spawnflags);
	DispatchKeyValueInt(spawner, "ammo_fill_pct_max", ammo_max);	// also the percentage.
	DispatchKeyValueInt(spawner, "ammo_fill_pct_min", ammo_min);

	if (!DispatchSpawn(spawner))
	{
		RemoveEntity(spawner);
		return false;
	}

	TeleportEntity(spawner, fPos, fAngle);
	AcceptEntityInput(spawner, "InputSpawn");
	RemoveEntity(spawner);

	return true;
}

stock int CreateHealthStation(float fPos[3] = { 0.0, 0.0, 0.0 }, float fAngle[3] = { 0.0, 0.0, 0.0 })
{
	int ent = CreateEntityByName("nmrih_health_station");
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
	{
		DispatchKeyValueVector(ent, "origin", fPos);
		DispatchKeyValueVector(ent, "angle", fAngle);
		DispatchSpawn(ent);
		return ent;
	}

	return INVALID_ENT_REFERENCE;
}

stock int CreateSupplyBox(float fPos[3] = { 0.0, 0.0, 0.0 }, float fAngle[3] = { 0.0, 0.0, 0.0 }, int uses = 9999)
{
	int ent = CreateEntityByName("nmrih_safezone_supply");
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
	{
		DispatchKeyValueVector(ent, "origin", fPos);
		DispatchKeyValueVector(ent, "angle", fAngle);
		DispatchKeyValueInt(ent, "uses", uses);
		DispatchSpawn(ent);
		return ent;
	}

	return INVALID_ENT_REFERENCE;
}

stock int CreateInventoryBox(float fPos[3] = { 0.0, 0.0, 0.0 }, float fAngle[3] = { 0.0, 0.0, 0.0 })
{
	int ent = CreateEntityByName("item_inventory_box");
	if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent))
	{
		DispatchKeyValueVector(ent, "origin", fPos);
		DispatchKeyValueVector(ent, "angle", fAngle);
		DispatchSpawn(ent);
		return ent;
	}

	return INVALID_ENT_REFERENCE;
}

stock void DropAllWeapons(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int i = 0; i < size; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Data, "m_hMyWeapons", i);
		if (weapon != INVALID_ENT_REFERENCE && IsValidEntity(weapon))
		{
			char weaponClass[64];
			GetEntityClassname(weapon, weaponClass, sizeof(weaponClass));

			if (strcmp(weaponClass, "me_fists") == 0 || strcmp(weaponClass, "item_zippo") == 0)
				continue;

			SDKHooks_DropWeapon(client, weapon);
		}
	}
}

stock int FindFists(int client)
{
	int ent = INVALID_ENT_REFERENCE;
	while ((ent = FindEntityByClassname(ent, "me_fists")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity") == client)
		{
			return ent;
		}
	}

	return INVALID_ENT_REFERENCE;
}

/**
 * Changes the active/current weapon of a player by Index.
 * Note: No changing animation will be played !
 *
 * @param client		Client Index.
 * @param weapon		Index of a valid weapon.
 */
// from smlib.inc
stock void SetActiveWeapon(int client, int weapon)
{
	if (weapon == INVALID_ENT_REFERENCE || !IsValidEntity(weapon))
	{
		LogError("[SetActiveWeapon] Invalid weapon entity %d for client %d", weapon, client);
		return;
	}

	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapInfo(client, "m_hActiveWeapon"));
}

enum struct FuncZombieSpawnInfo
{
	int index;
	float vecOrigin[3];
	char targetname[128];
}

stock ArrayList CollectFuncZombieSpawnEntities()
{
	ArrayList array = new ArrayList(sizeof(FuncZombieSpawnInfo));

	int ent = INVALID_ENT_REFERENCE;
	while ((ent = FindEntityByClassname(ent, "func_zombie_spawn")) != INVALID_ENT_REFERENCE)
	{
		if (IsValidEntity(ent))
		{
			FuncZombieSpawnInfo info;

			info.index = ent;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", info.vecOrigin);
			GetEntPropString(ent, Prop_Data, "m_iName", info.targetname, sizeof(info.targetname));

			array.PushArray(info);
		}
	}

	return array;
}

// from Fallout Limbo Manager by Dysphie
stock int FindEntityByTargetname(const char[] classname, const char[] targetname)
{
	int e = -1;
	while ((e = FindEntityByClassname(e, classname)) != -1)
	{
		char buffer[32];
		GetEntPropString(e, Prop_Data, "m_iName", buffer, sizeof(buffer));

		if (StrEqual(buffer, targetname))
		{
			return e;
		}
	}

	return -1;
}