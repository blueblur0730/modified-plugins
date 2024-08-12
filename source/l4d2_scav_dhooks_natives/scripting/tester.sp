#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <l4d2_scav_stocks>
#undef REQUIRE_PLUGIN
#include <l4d2_scav_dhooks_natives>

#define PL_VERSION "1.0"

bool g_bHandled;
bool g_bChanged;
bool g_bLibraryActive;
ScavStocksWrapper g_Wrapper;
ConVar g_hCvTesterNumber, g_hCvHandled, g_hCvChanged;
int g_iTesterNumber;
bool g_bLateLoad;

public Plugin myinfo =
{
	name = "[L4D2] Scavenge Direct Hooks Natives Test Plugin",
	author = "blueblur",
	description = "Tester.",
	version	= PL_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

    g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
    RegAdminCmd("sm_tester", Tester, ADMFLAG_ROOT);
    g_hCvTesterNumber = CreateConVar("tester_number", "0", "Set number to test.");
    g_hCvHandled = CreateConVar("Handled", "0", "Set 1 to return Plugin_Handled for all forwards.");
    g_hCvChanged = CreateConVar("Changed", "0", "Set 1 to return Plugin_Changed for all forwards.");
    g_hCvTesterNumber.AddChangeHook(OnCvarChanged);
    g_hCvHandled.AddChangeHook(OnCvarChanged);
    g_hCvChanged.AddChangeHook(OnCvarChanged);

    if (g_bLateLoad)
    {
        if (!LibraryExists("l4d2_scav_dhooks_natives"))
            SetFailState("Required plugin \"l4d2_scav_dhooks_natives\" is missing.");
    }
}

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "l4d2_scav_dhooks_natives") == 0)
		g_bLibraryActive = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "l4d2_scav_dhooks_natives") == 0)
		g_bLibraryActive = false;
}

public void OnAllPluginsLoaded()
{
    g_bLibraryActive = LibraryExists("l4d2_scav_dhooks_natives");

	if (!g_bLibraryActive)
		SetFailState("Required plugin \"l4d2_scav_dhooks_natives\" is missing.");
}

Action Tester(int client, int args)
{
    switch (g_iTesterNumber)
    {
        case 1:
        {
            int team = GetCmdArgInt(1);
            int oldscore = g_Wrapper.GetMatchScore(team);
            L4D2_IncrementScavengeMatchScore(team);
            int newscore = g_Wrapper.GetMatchScore(team);
            PrintToServer("L4D2_IncrementScavengeMatchScore called. Team: %d, OldScore: %d, NewScore: %d", team, oldscore, newscore);
        }

        case 2: L4D2_ResetScavengeRoundNumber();
        case 3:
        {
            float time = GetCmdArgFloat(1);
            float oldduration = g_Wrapper.GetRoundDuration(2);
            L4D2_AccumulateScavengeRoundTime(time);
            float newduration = g_Wrapper.GetRoundDuration(2);
            PrintToServer("L4D2_AccumulateScavengeRoundTime called. Time: %f, OldDuration: %f, NewDuration: %f", time, oldduration, newduration);
        }

        case 4: L4D2_RestartScavengeRound();
        case 5:
        {
            int oldcount;
            for (int i = 0; i < GetEntityCount(); i++)
            {
		        if (!IsValidEntity(i))
			        continue;

		        char sClassname[64];
		        GetEdictClassname(i, sClassname, sizeof(sClassname));

		        if (StrEqual(sClassname, "infected"))
			        oldcount++;
            }

            bool bIsUpdated = L4D2_UpdateScavengeMobSpawns();

            int newcount;
            for (int x = 0; x < GetEntityCount(); x++)
            {
		        if (!IsValidEntity(x))
			        continue;

		        char sClassname[64];
		        GetEdictClassname(x, sClassname, sizeof(sClassname));

		        if (StrEqual(sClassname, "infected"))
			        newcount++;
            }
            PrintToServer("L4D2_UpdateScavengeMobSpawns called. IsUpdated: %s, OldCount: %d, NewCount: %d", bIsUpdated ? "true" : "false", oldcount, newcount);
        }

        case 6: L4D2_EndScavengeRound();
        case 7:
        {
            int oldteamscore = g_Wrapper.GetTeamScore(2);
            float oldduration = g_Wrapper.GetRoundDuration(2);
            L4D2_IncrementScavengeTeamScoreAndDuration();
            int newteamscore = g_Wrapper.GetTeamScore(2);
            float newduration = g_Wrapper.GetRoundDuration(2);
            PrintToServer("L4D2_CDirector_IncrementScavengeTeamScore called. OldTeamScore: %d, NewTeamScore: %d, OldDuration: %f, NewDuration: %f", oldteamscore, newteamscore, oldduration, newduration);
        }

        case 8:
        {
            int team = GetCmdArgInt(1);
            int oldteamscore = g_Wrapper.GetTeamScore(team);
            L4D2_IncrementScavengeTeamScore(team);
            int newteamscore = g_Wrapper.GetTeamScore(team);
            PrintToServer("L4D2_CTerrorGameRules_IncrementScavengeTeamScore called. Team: %d, OldTeamScore: %d, NewTeamScore: %d", team, oldteamscore, newteamscore);
        }
    }

    return Plugin_Handled;
}

public void L4D2_OnStartScavengeIntro()
{
    PrintToServer("L4D2_OnStartScavengeIntro called. GameTime: %f", GetGameTime());
}

public Action L4D2_OnBeginScavengeRoundSetupTime(float &time)
{
    PrintToServer("L4D2_OnBeginScavengeRoundSetupTime called. GameTime: %f, Setup Round Timer: %f", GetGameTime(), time);

    if (g_bHandled)
        return Plugin_Handled;

    if (g_bChanged)
    {
        time = 120.0;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public void L4D2_OnBeginScavengeRoundSetupTime_Post(float time)
{
    PrintToServer("L4D2_OnBeginScavengeRoundSetupTime called. GameTime: %f, Setup Round Timer: %f", GetGameTime(), time);
}

public void L4D2_OnBeginScavengeRoundSetupTime_PostHandled(float time)
{
    PrintToServer("L4D2_OnBeginScavengeRoundSetupTime called. GameTime: %f, Setup Round Timer: %f", GetGameTime(), time);
}

public void L4D2_OnStartScavengeOvertime(int client[32])
{
    PrintToServer("L4D2_OnStartScavengeOvertime called. GameTime: %f", GetGameTime());

    for (int i = 0; i < sizeof(client); i++)
    {
        if (client[i] == 0)
            continue;
            
        PrintToServer("Client %d is holding the gascan.", client[i]);
    }
}

public void L4D2_OnEndScavengeOvertime(bool bEndStatus)
{
    PrintToServer("L4D2_OnEndScavengeOvertime called. GameTime: %f, EndStatus: %s", GetGameTime(), bEndStatus ? "true" : "false");
}

public Action L4D2_OnUpdateScavengeOvertimeState()
{
    //PrintToServer("L4D2_OnUpdateScavengeOvertimeState called. GameTime: %f", GetGameTime());

    if (g_bHandled)
        return Plugin_Handled;

    return Plugin_Continue;
}

public void L4D2_OnUpdateScavengeOvertimeState_Post()
{
    //PrintToServer("L4D2_OnUpdateScavengeOvertimeState called. GameTime: %f", GetGameTime());
}

public void L4D2_OnUpdateScavengeOvertimeState_PostHandled()
{
    //PrintToServer("L4D2_OnUpdateScavengeOvertimeState called. GameTime: %f", GetGameTime());
}

public Action L4D2_OnScavengeUpdateScenarioState()
{
    //PrintToServer("L4D2_OnScavengeUpdateScenarioState called. GameTime: %f", GetGameTime());

    if (g_bHandled)
        return Plugin_Handled;

    return Plugin_Continue;
}

public void L4D2_OnScavengeUpdateScenarioState_Post()
{
    //PrintToServer("L4D2_OnScavengeUpdateScenarioState called. GameTime: %f", GetGameTime());
}

public void L4D2_OnScavengeUpdateScenarioState_PostHandled()
{
    //PrintToServer("L4D2_OnScavengeUpdateScenarioState called. GameTime: %f", GetGameTime());
}

public Action L4D2_OnScavengeRoundTimeExpired()
{
    PrintToServer("L4D2_OnScavengeRoundTimeExpired called. GameTime: %f", GetGameTime());

    if (g_bHandled)
        return Plugin_Handled;

    return Plugin_Continue;
}

public void L4D2_OnScavengeRoundTimeExpired_Post()
{
    PrintToServer("L4D2_OnScavengeRoundTimeExpired called. GameTime: %f", GetGameTime());
}


public void L4D2_OnScavengeRoundTimeExpired_PostHandled()
{
    PrintToServer("L4D2_OnScavengeRoundTimeExpired called. GameTime: %f", GetGameTime());
}

void OnCvarChanged(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
    g_iTesterNumber = g_hCvTesterNumber.IntValue;
    g_bHandled = g_hCvHandled.BoolValue;
    g_bChanged = g_hCvChanged.BoolValue;
}