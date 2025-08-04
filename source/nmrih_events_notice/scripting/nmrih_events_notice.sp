#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <nmrih_player>
#include <multicolors>

#define TRANSLATION_FILE "nmrih_events_notice.phrases"

float g_flRoundTime;

enum NPCType {
	Type_Shambler = 1,
	Type_Runner = 2,
	Type_Kid = 3,
	Type_Turned = 4
}

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[NMRiH] Events Notices",
	author = "blueblur",
	description = "In association with nmrih-notice by F1F88.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	CreateConVar("nmrih_events_notice_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	LoadTranslation(TRANSLATION_FILE);

    HookEvent("player_death", Event_PlayerDeath);
	HookEvent("map_complete", Event_MapComplete);
	HookEvent("nmrih_round_begin", Event_NMRiH_RoundBegin);
	HookEvent("player_extracted", Event_PlayerExtracted);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = event.GetInt("attacker");
    int npc = event.GetInt("npctype");

	if (!IsValidClient(victim))
		return;

	// killed by ourselves.
    if (npc == 0)
    {
		if (victim == GetClientOfUserId(attacker))
		{
			CPrintToChatAll("%t", "Suicided", victim);
			return;
		}

		// by this time you are killed by something else.
		if (attacker > MaxClients)
			CPrintToChatAll("%t", "Killed", victim);
	}
	// by npc.
	else
	{
		switch (npc)
		{
			case Type_Shambler: CPrintToChatAll("%t", "KilledByShambler", victim);
			case Type_Runner: CPrintToChatAll("%t", "KilledByRunner", victim);
			case Type_Kid: CPrintToChatAll("%t", "KilledByKid", victim);
			case Type_Turned: CPrintToChatAll("%t", "KilledByTurned", victim);
		}

		return;
	}
}

void Event_MapComplete(Event event, const char[] name, bool dontBroadcast)
{
	char sTime[64];
	FormatSeconds((GetGameTime() - g_flRoundTime), sTime, sizeof(sTime));
	CPrintToChatAll("%t", "MapCompleted", sTime);
}

void Event_NMRiH_RoundBegin(Event event, const char[] name, bool dontBroadcast)
{
	g_flRoundTime = GetGameTime();
}

void Event_PlayerExtracted(Event event, const char[] name, bool dontBroadcast)
{
	int player = event.GetInt("player_id");
	if (!IsValidClient(player))
		return;

	CPrintToChatAll("%t", "Extracted", player);
}

public void OnPlayerTakePillsPost(int client)
{
	if (!IsValidClient(client))
		return;

	CPrintToChatAll("%t", "TokenPills", client);
}

public void OnPlayerApplyBandagePost(int client)
{
	if (!IsValidClient(client))
		return;

	CPrintToChatAll("%t", "AppliedBandage", client);
}

public void OnPlayerApplyFirstAidKitPost(int client)
{
	if (!IsValidClient(client))
		return;

	CPrintToChatAll("%t", "AppliedFirstAidKit", client);
}

public void OnPlayerApplyVaccinePost(int client)
{
	if (!IsValidClient(client))
		return;

	CPrintToChatAll("%t", "AppliedVaccine", client);
}

stock void FormatSeconds(float flSeconds, char[] string, int size)
{
    int hours = RoundToFloor(flSeconds / 3600.0);
    int mins = RoundToFloor((flSeconds - (hours * 3600)) / 60.0);
    int secs = RoundToFloor(flSeconds) % 60;

    if (hours > 0)
    {
        Format(string, size, "%02d:%02d:%02d", hours, mins, secs);
    }
    else
    {
        Format(string, size, "%02d:%02d", mins, secs);
    }
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}