#if defined _server_management_prefix
    #endinput
#endif
#define _server_management_prefix

//---------------------------------------------------------------
// Spectator Prefix by Nana & Harry Potter, modified by blueblur
//---------------------------------------------------------------

static char g_sPrefixType[32], g_sAdminPrefixType[32];
static ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hPrefixType, g_hCvarAdminPrefixType;
static ConVar g_hCvarMPGameMode;
static bool g_bCvarAllow, g_bMapStarted;

void _prefix_OnPluginStart()
{
	g_hCvarAllow 	        = CreateConVar(	"l4d_spectator_prefix_allow",			"1",	"0=Plugin off, 1=Plugin on.", _, true, 0.0, true, 1.0);
	g_hCvarModes 	        = CreateConVar( "l4d_spectator_prefix_modes",			"",		"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).");
	g_hCvarModesOff         = CreateConVar( "l4d_spectator_prefix_modes_off",		"",		"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).");
	g_hCvarModesTog         = CreateConVar( "l4d_spectator_prefix_modes_tog",   	"0",	"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.");
	g_hPrefixType 	        = CreateConVar( "l4d_spectator_prefix_type", 			"(S)",  "Determine your preferred type of Spectator Prefix");
    g_hCvarAdminPrefixType  = CreateConVar( "l4d_spectator_prefix_admin_type", 	    "(A)",  "Determine your preferred type of Admin Spectator Prefix");
	
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hPrefixType.AddChangeHook(ConVarChanged_PrefixType);
    g_hCvarAdminPrefixType.AddChangeHook(ConVarChanged_PrefixType);
}

void _prefix_OnPluginEnd()
{
	RemoveAllClientPrefix();
}

void _prefix_OnMapStart()
{
	g_bMapStarted = true;
}

void _prefix_OnMaEnd()
{
	g_bMapStarted = false;
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
void _prefix_OnConfigsExecuted()
{
	IsAllowed();
}

static void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

static void ConVarChanged_PrefixType(ConVar convar, const char[] oldValue, const char[] newValue)
{
	RemoveAllClientPrefix();
	GetCvars();
	AddAllClientPrefix();
}

static void GetCvars()
{
	g_hPrefixType.GetString(g_sPrefixType, sizeof(g_sPrefixType));
    g_hCvarAdminPrefixType.GetString(g_sAdminPrefixType, sizeof(g_sAdminPrefixType));
}

static void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if(!g_bCvarAllow && bCvarAllow && bAllowMode)
	{
		g_bCvarAllow = true;

		HookEvent("player_team", Event_PlayerTeam, EventHookMode_PostNoCopy);
		HookEvent("player_changename", Event_NameChanged, EventHookMode_Pre);

		AddAllClientPrefix();
	}

	else if( g_bCvarAllow && (!bCvarAllow || !bAllowMode) )
	{
		g_bCvarAllow = false;

		UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_PostNoCopy);
		UnhookEvent("player_changename", Event_NameChanged, EventHookMode_Pre);

		RemoveAllClientPrefix();
	}
}

static int g_iCurrentMode;
static bool IsAllowedGameMode()
{
	if( g_bMapStarted == false )
		return false;

	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	g_iCurrentMode = 0;

	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
	}

	if( iCvarModesTog != 0 )
	{
		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

static void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 ) g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 ) g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 ) g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 ) g_iCurrentMode = 8;
}

//event
static Action Event_NameChanged(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client <= 0 || client > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(client))
		return Plugin_Continue;

	char sOldname[256], sNewname[256];
	event.GetString("oldname", sOldname, sizeof(sOldname));
	event.GetString("newname", sNewname, sizeof(sNewname));

	if (StrContains(sNewname, g_sPrefixType) != -1 || StrContains(sNewname, g_sAdminPrefixType) != -1)
		return Plugin_Handled;

	return Plugin_Continue;
}

static void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	CreateTimer(0.8, PlayerNameCheck, userid, TIMER_FLAG_NO_MAPCHANGE);
}

//timer
static void PlayerNameCheck(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client)) return;
	
	int team = GetClientTeam(client);
	
	//PrintToChatAll("client: %N - %d",client,team);
	if (IsClientAndInGame(client) && !IsFakeClient(client))
	{
		char sOldname[256], sNewname[256];
		GetClientName(client, sOldname, sizeof(sOldname));
		if (team == L4D2Team_Spectator)
		{
			if (IsClientAdmin(client))
			{
				if (!CheckClientHasPreFixAdmin(sOldname))
				{
					Format(sNewname, sizeof(sNewname), "%s%s", g_sAdminPrefixType, sOldname);
					CS_SetClientName(client, sNewname);
				}
			}
			else
			{
				if(!CheckClientHasPreFix(sOldname))
				{
                	Format(sNewname, sizeof(sNewname), "%s%s", g_sPrefixType, sOldname);
					CS_SetClientName(client, sNewname);
					//PrintToChatAll("sNewname: %s",sNewname);
				}
			}
		}
		else
		{
			if (IsClientAdmin(client))
			{
				if (CheckClientHasPreFixAdmin(sOldname))
				{
					ReplaceString(sOldname, sizeof(sOldname), g_sAdminPrefixType, "", true);
					strcopy(sNewname, sizeof(sOldname), sOldname);
					CS_SetClientName(client, sNewname);
				}
			}
			else
			{
				if (CheckClientHasPreFix(sOldname))
				{
					ReplaceString(sOldname, sizeof(sOldname), g_sPrefixType, "", true);
					strcopy(sNewname, sizeof(sOldname), sOldname);
					CS_SetClientName(client, sNewname);
					//PrintToChatAll("sNewname: %s",sNewname);
				}
			}
		}
	}
}

static stock bool CheckClientHasPreFix(const char[] sOldname)
{
	for(int i =0 ; i < strlen(g_sPrefixType); ++i)
	{
		if(sOldname[i] == g_sPrefixType[i])
		{
			//PrintToChatAll("%d-%c",i,g_sPrefixType[i]);
			continue;
		}
		else
			return false;
	}
	return true;
}

static stock bool CheckClientHasPreFixAdmin(const char[] sOldname)
{
	for(int i =0 ; i < strlen(g_sAdminPrefixType); ++i)
	{
		if(sOldname[i] == g_sAdminPrefixType[i])
		{
			//PrintToChatAll("%d-%c",i,g_sAdminPrefixType[i]);
			continue;
		}
		else
			return false;
	}
	return true;
}


static void AddAllClientPrefix()
{
	char sOldname[256],sNewname[256];
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == L4D2Team_Spectator)
		{
			GetClientName(i, sOldname, sizeof(sOldname));
			if(!CheckClientHasPreFix(sOldname))
			{
                if (IsClientAdmin(i))
                    Format(sNewname, sizeof(sNewname), "%s%s", g_sAdminPrefixType, sOldname);
                else 
                    Format(sNewname, sizeof(sNewname), "%s%s", g_sPrefixType, sOldname);

				CS_SetClientName(i, sNewname);
			}
		}
	}
}

static void RemoveAllClientPrefix()
{
	char sOldname[256],sNewname[256];
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i, sOldname, sizeof(sOldname));
			if(CheckClientHasPreFix(sOldname))
			{
                if (IsClientAdmin(i))
                    ReplaceString(sOldname, sizeof(sOldname), g_sAdminPrefixType, "", true);
                else 
				    ReplaceString(sOldname, sizeof(sOldname), g_sPrefixType, "", true);

				strcopy(sNewname,sizeof(sOldname),sOldname);
				CS_SetClientName(i, sNewname);
			}
		}
	}
}