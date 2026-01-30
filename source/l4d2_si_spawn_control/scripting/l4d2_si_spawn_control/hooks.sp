
void SetupEvents()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy);

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea, EventHookMode_PostNoCopy);

	// from l4d_skip_intro.
	HookEvent("gameinstructor_nodraw", Event_NoDraw, EventHookMode_PostNoCopy); // Because round_start can be too early when clients are not in-game. This triggers when the cutscene starts.
}

static void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Reset();
}

static void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Reset();
}

static void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	g_bLeftSafeArea = true;

	delete g_hSpawnTimer[SPAWN_MAX_PRE];
	g_hSpawnTimer[SPAWN_MAX_PRE] = CreateTimer(g_fFirstSpawnTime, SpawnSpecial_Timer, SPAWN_MAX_PRE);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if (g_bEnable && g_bLeftSafeArea && g_bMark[client] && client > 0 && IsClientInGame(client) && (GetClientTeam(client) == 3 || !strcmp(name, "shit")) && IsFakeClient(client))
	{
		int iClass = GetZombieClass(client);
		if (iClass > 0 && iClass < SI_CLASS_SIZE)
		{
			// Kick the bot to release client index.
			// Exclude SPITTER to avoid sputum without sound.
			if (iClass != SPITTER)
				CreateTimer(0.1, KickBot_Timer, userid);
			
			if (!g_hSpawnTimer[SPAWN_MAX_PRE])
			{
				if (g_bTogetherSpawn)
					RequestFrame(PlayerDeath_NextFrame);
				else
				{
					static int num = SPAWN_REVIVE;
					if (++num >= MAXPLAYERS) num = SPAWN_REVIVE;
					g_hSpawnTimer[num] = CreateTimer(g_fSpawnTime, SpawnSpecial_Timer, num);
				}
			}
		}
	}

	g_bMark[client] = false;
}

static void PlayerDeath_NextFrame()
{
	if (GetAllSpecialsTotal() == 0)
	{
		delete g_hSpawnTimer[SPAWN_MAX_PRE];
		g_hSpawnTimer[SPAWN_MAX_PRE] = CreateTimer(g_fSpawnTime, SpawnSpecial_Timer, SPAWN_MAX_PRE);
	}
}

public void Event_NoDraw(Event event, const char[] name, bool dontBroadcast)
{
	if (L4D_IsFirstMapInScenario())
	{
		// Block finale
		if (FindEntityByClassname(-1, "trigger_finale") != INVALID_ENT_REFERENCE )
			return;

		g_bFinishedIntro = false;
	}
}

public void L4D_OnFinishIntro()
{
	g_bFinishedIntro = true;
}

public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
	if (!g_bCanSpawn && g_bBlockSpawn)
	{
		LogMessage("%s not spawned by this plugin, blocked.", g_sSpecialName[zombieClass]);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public void L4D_OnSpawnSpecial_Post(int client, int zombieClass, const float vecPos[3], const float vecAng[3])
{
	if (client > 0)
		g_fSpecialActionTime[client] = GetEngineTime();
}

Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	static float fEngineTime;
	fEngineTime = GetEngineTime();

	if (attacker > 0 && attacker <= MaxClients)
		g_fSpecialActionTime[attacker] = fEngineTime;

	g_fSpecialActionTime[victim] = fEngineTime;

	return Plugin_Continue;
}