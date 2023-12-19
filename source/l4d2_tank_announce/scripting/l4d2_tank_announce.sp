#pragma semicolon 1
#pragma newdecls required

#define L4D2Team_Infected 3
#define L4D2Infected_Tank 8

#include <sourcemod>
#include <sdktools_sound>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d_tank_control_eq>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.4.3"
#define DANG "ui/pickup_secret01.wav"

#define	CHAT_MSG		(1 << 0)
#define HINT_MSG		(1 << 1)

#define DEBUG 0

ConVar g_hPrintStyle;

int g_iPrintStyle;

public Plugin myinfo = 
{
	name = "L4D2 Tank Announcer",
	author = "Visor, Forgetest, xoxo, blueblur",
	description = "Announce in chat & hint and via a sound when a Tank has spawned, compatiable with coop.",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_tank_announce_version", PLUGIN_VERSION, "Plugin Version");

	g_hPrintStyle = CreateConVar("l4d2_tank_announce_print_style",\
								"2",\
								"Print style for announcement when tank spawned. Add numbers together if multiply print. 0=disable, 1=chat, 2=hint.",\
								FCVAR_NOTIFY);

	g_iPrintStyle = g_hPrintStyle.IntValue;

	g_hPrintStyle.AddChangeHook(OnConVarChanged);

	LoadTranslations("l4d2_tank_announce.phrases");
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPrintStyle = StringToInt(newValue);
}

public void OnMapStart()
{
	PrecacheSound(DANG);
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	int tankClient = client;
	char nameBuf[MAX_NAME_LENGTH];
	
#if DEBUG
	PrintToChatAll("[Tank Announcer] L4D_OnSpawnTank_Post called");
#endif

	if (IsTankSelection())
	{
		if (IsTank(tankClient) && !IsFakeClient(tankClient)) 
		{
			FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
		} 
		else 
		{
			tankClient = GetTankSelection();
			if (tankClient > 0 
			&& IsClientInGame(tankClient)) 
			{
				FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
			} 
			else 
			{
				FormatEx(nameBuf, sizeof(nameBuf), "AI");
			}
		}
	}
	else
	{
	#if DEBUG
		PrintToChatAll("[Tank Announcer] Hooked Event 'player_spawn' for tank spawn.");
	#endif
		HookEvent("player_spawn", Event_PlayerSpawn);
		return;
	}

	if (g_iPrintStyle != 0)
	{
		if (g_iPrintStyle & CHAT_MSG)
			CPrintToChatAllEx(tankClient, "%t", "Spawned", nameBuf);
	
		if (g_iPrintStyle & HINT_MSG)
			PrintHintTextToAll("%t", "Spawned_Hint", nameBuf);
	}

	EmitSoundToAll(DANG);
}

public void Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Tanky Client?
	if (IsTank(client))
	{
		#if DEBUG
			PrintToChatAll("[Tank Announcer] Client %d is tank", client);
		#endif

		if (!IsFakeClient(client))
		{
			if (g_iPrintStyle != 0)
			{
				if (g_iPrintStyle & CHAT_MSG)
					CPrintToChatAllEx(client, "%t", "Spawned2", client);

				if (g_iPrintStyle & HINT_MSG)
					PrintHintTextToAll("%t", "Spawned2_Hint", client);
			}
		}
		else
		{
			if (g_iPrintStyle != 0)
			{
				if (g_iPrintStyle & CHAT_MSG)
					CPrintToChatAllEx(client, "%t", "Spawned3");

				if (g_iPrintStyle & HINT_MSG)
					PrintHintTextToAll("%t", "Spawned3_Hint");
			}
		}

		EmitSoundToAll(DANG);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
	}
}

/**
 * Is the player the tank? 
 *
 * @param client client ID
 * @return bool
 */
bool IsTank(int client)
{
	return (IsClientInGame(client)
		&& GetClientTeam(client) == L4D2Team_Infected
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2Infected_Tank);
}

/*
 * @return			true if GetTankSelection exist false otherwise.
 */
bool IsTankSelection()
{
	return (GetFeatureStatus(FeatureType_Native, "GetTankSelection") != FeatureStatus_Unknown);
}