#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <caster_system>

#define PLUGIN_VERSION "2.2.1-2025/3/9"

ConVar
	g_hCvar_Allow,
	g_hCvar_Broadcast,
	g_hCvar_PrefixType,
	g_hCvar_AdminPrefixType,
	g_hCvar_CasterPrefixType;

bool	  g_bCasterAvailable;
StringMap g_hMapPrefix;
bool	  g_bLateLoad;

public Plugin myinfo =
{
	name = "[L4D/2] Spectator Prefix",
	author = "Forgetest, Harry Potter, blueblur",
	description = "Brand-fresh views in Server Browser where spectators are clear to identify.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvar_Allow			 = CreateConVar("l4d_spectator_prefix_allow", "1", "0=Plugin off, 1=Plugin on.", _, true, 0.0, true, 1.0);
	g_hCvar_Broadcast		 = CreateConVar("l4d_spectator_prefix_broadcast", "0", "0=No broadcast, 1=Broadcast to all players the name change.");
	g_hCvar_PrefixType		 = CreateConVar("l4d_spectator_prefix_type", "(S)", "Determine your preferred type of Spectator Prefix");
	g_hCvar_AdminPrefixType	 = CreateConVar("l4d_spectator_prefix_admin_type", "(A)", "Determine your preferred type of Admin Spectator Prefix");
	g_hCvar_CasterPrefixType = CreateConVar("l4d_spectator_prefix_caster_type", "(C)", "Determine your preferred type of Caster Spectator Prefix");

	g_hCvar_Allow.AddChangeHook(OnAllowedChanged);

	g_hMapPrefix = new StringMap();

	if (g_bLateLoad)
		ToggleAllowed();
}

public void OnPluginEnd()
{
	RemovePrefixFromAllClients();
	delete g_hMapPrefix;
}

public void OnAllPluginsLoaded() { g_bCasterAvailable = LibraryExists("caster_system"); }
public void OnLibraryAdded(const char[] name){ if (StrEqual(name, "caster_system")) g_bCasterAvailable = true; }
public void OnLibraryRemoved(const char[] name){ if (StrEqual(name, "caster_system")) g_bCasterAvailable = false; }

public void OnCasterRegistered(int client)
{
	// delay it at least for 2s because you could be castered by yourself.
	PrepareTimer(client, 2.0);
}

public void OnCasterUnregistered(int client)
{
	PrepareTimer(client, 0.5);
}

public void OnClientPutInServer(int client)
{
	PrepareTimer(client, 0.5);
}

void PrepareTimer(int client, float time)
{
	if (!g_hCvar_Allow.BoolValue)
		return;

	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;

	CreateTimer(time, Timer_PrefixChange, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConfigsExecuted()
{
	ToggleAllowed();
}

void OnAllowedChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ToggleAllowed();
}

void ToggleAllowed()
{
	static bool bEnabled = false;
	if (g_hCvar_Allow.BoolValue && !bEnabled)
	{
		HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
		HookEvent("player_changename", Event_NameChanged, EventHookMode_Pre);

		AddPrefixToAllClients();
		bEnabled = true;
	}
	else if (!g_hCvar_Allow.BoolValue && bEnabled)
	{
		UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
		UnhookEvent("player_changename", Event_NameChanged, EventHookMode_Pre);

		RemovePrefixFromAllClients();
		bEnabled = false;
	}
}

Action Event_NameChanged(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if (client <= 0 || client > MaxClients)
		return Plugin_Continue;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	char authID[64];
	if (!GetClientAuthId(client, AuthId_SteamID64, authID, sizeof(authID)))
		return Plugin_Continue;

	char sName[256];
	event.GetString("newname", sName, sizeof(sName));

	// case: you changed your prefixed name on spectator team, we add it back.
	int team = GetClientTeam(client); 
	if (team == 1 && HasPrefix(authID) && !NameContainsPrefix(client, sName))
	{
		char sPrefix[16];
		g_hMapPrefix.GetString(authID, sPrefix, sizeof(sPrefix));
		Format(sName, sizeof(sName), "%s%s", sPrefix, sName);
		SetClientInfo(client, "name", sName);
		SetEntPropString(client, Prop_Data, "m_szNetname", sName);
		return Plugin_Continue;	// return here, as we should broadcast this.
	}

	// a prefix changing event.
	if (HasPrefix(authID))
	{
		// should broadcast the prefix change?
		if (!g_hCvar_Broadcast.BoolValue)
			return Plugin_Handled;
	}

	// we let the normal name change event keep on.
	return Plugin_Continue;
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	CreateTimer(0.5, Timer_PrefixChange, userid, TIMER_FLAG_NO_MAPCHANGE);
}

void Timer_PrefixChange(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;

	char authID[64];
	if (!GetClientAuthId(client, AuthId_SteamID64, authID, sizeof(authID)))
		return;

	char sName[256];
	int	 team = GetClientTeam(client);
	GetClientName(client, sName, sizeof(sName));

	if (team == 1)
	{
		if (!HasPrefix(authID))
		{
			char sPrefix[16];

			// if you changed your name through `setinfo` with prefix or you already have it, ignore.
			if (NameContainsPrefix(client, sName))
			{
				// setting yes for you, cause you already have it.
				SetPrefix(client, sPrefix, sizeof(sPrefix));
				return;
			}

			SetPrefix(client, sPrefix, sizeof(sPrefix));
			Format(sName, sizeof(sName), "%s%s", sPrefix, sName);
			SetClientNameEx(client, sName);
		}
		else
		{
			// on map transition, our names are restored. but we kept the prefix in the database.
			char sPrefix[16];
			if (!NameContainsPrefix(client, sName))
			{
				GetPrefix(client, sPrefix, sizeof(sPrefix));
				Format(sName, sizeof(sName), "%s%s", sPrefix, sName);
				SetClientNameEx(client, sName);
			}
		}
	}
	else
	{
		if (HasPrefix(authID))
		{
			char sPrefix[16];
			g_hMapPrefix.GetString(authID, sPrefix, sizeof(sPrefix));
			ReplaceString(sName, sizeof(sName), sPrefix, "", true);
			g_hMapPrefix.Remove(authID);
		}

		// or you already have it but not registered.
		if (NameContainsPrefix(client, sName))
		{
			char sPrefix[16];
			GetPrefix(client, sPrefix, sizeof(sPrefix));
			ReplaceString(sName, sizeof(sName), sPrefix, "", true);
		}

		SetClientNameEx(client, sName);
	}
}

void AddPrefixToAllClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 1)
			continue;

		char authID[64];
		if (!GetClientAuthId(i, AuthId_SteamID64, authID, sizeof(authID)))
			continue;

		char sName[128];
		GetClientName(i, sName, sizeof(sName));

		if (HasPrefix(authID) || NameContainsPrefix(i, sName))
			continue;

		char sPrefix[16];
		SetPrefix(i, sPrefix, sizeof(sPrefix));
		Format(sName, sizeof(sName), "%s%s", sPrefix, sName);

		SetClientNameEx(i, sName);
	}
}

void RemovePrefixFromAllClients()
{
	if (!g_hMapPrefix.Size)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 1)
			continue;

		char authID[64];
		if (!GetClientAuthId(i, AuthId_SteamID64, authID, sizeof(authID)))
			continue;

		char sName[256];
		GetClientName(i, sName, sizeof(sName));

		if (!HasPrefix(authID) || !NameContainsPrefix(i, sName))
			continue;

		char sPrefix[16];
		g_hMapPrefix.GetString(authID, sPrefix, sizeof(sPrefix));
		ReplaceString(sName, sizeof(sName), sPrefix, "", true);
		g_hMapPrefix.Remove(authID);

		SetClientNameEx(i, sName);
	}
}

bool HasPrefix(const char[] auth)
{
	return g_hMapPrefix.ContainsKey(auth);
}

bool NameContainsPrefix(int client, const char[] name)
{
	char sPrefix[16];
	GetPrefix(client, sPrefix, sizeof(sPrefix));

	return !strncmp(name, sPrefix, strlen(sPrefix));
}

void SetPrefix(int client, char[] sPrefix, int length)
{
	char authID[64];
	if (!GetClientAuthId(client, AuthId_SteamID64, authID, sizeof(authID)))
		return;

	GetPrefix(client, sPrefix, length);
	g_hMapPrefix.SetString(authID, sPrefix, true);
}

void GetPrefix(int client, char[] sPrefix, int length)
{
	if (g_bCasterAvailable && IsClientCaster(client))
	{
		g_hCvar_CasterPrefixType.GetString(sPrefix, length);
	}
	else if (IsClientAdmin(client))
	{
		g_hCvar_AdminPrefixType.GetString(sPrefix, length);
	}
	else
	{
		g_hCvar_PrefixType.GetString(sPrefix, length);
	}
}

stock void SetClientNameEx(int client, const char[] name)
{
	char oldname[MAX_NAME_LENGTH];
	GetClientName(client, oldname, sizeof(oldname));

	SetClientInfo(client, "name", name);
	SetEntPropString(client, Prop_Data, "m_szNetname", name);

	Event event = CreateEvent("player_changename");
	if (!event) return;

	event.SetInt("userid", GetClientUserId(client));
	event.SetString("oldname", oldname);
	event.SetString("newname", name);
	event.Fire();
}

stock bool IsClientAdmin(int client)
{
	if (!IsClientInGame(client)) return false;
	return (GetUserAdmin(client) != INVALID_ADMIN_ID && GetUserFlagBits(client) != 0);
}