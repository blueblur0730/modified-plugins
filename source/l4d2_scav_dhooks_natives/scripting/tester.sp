#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <l4d2_scav_dhooks_natives>

#define PL_VERSION "1.0"

bool g_bHandled;
bool g_bChanged;
bool g_bLibraryActive;
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
        case 1: L4D2_ResetScavengeRoundNumber();
        case 2: 
        {
            float time = GetCmdArgFloat(1);
            L4D2_AccumulateScavengeRoundTime(time);
        }
        case 3: L4D2_RestartRound();
        case 4: L4D2_EndScavengeRound();
    }

    return Plugin_Handled;
}

public void L4D2_OnStartScavengeIntro()
{
    PrintToServer("L4D2_OnStartScavengeIntro called. GameTime: %f", GetGameTime());
}

public void L4D2_OnBeginScavengeRoundSetupTime()
{
    PrintToServer("L4D2_OnBeginScavengeRoundSetupTime called. GameTime: %f", GetGameTime());
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
    PrintToServer("L4D2_OnScavengeRoundTimeExpired_Post called. GameTime: %f", GetGameTime());
}


public void L4D2_OnScavengeRoundTimeExpired_PostHandled()
{
    PrintToServer("L4D2_OnScavengeRoundTimeExpired_PostHandled called. GameTime: %f", GetGameTime());
}

void OnCvarChanged(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
    g_iTesterNumber = g_hCvTesterNumber.IntValue;
    g_bHandled = g_hCvHandled.BoolValue;
    g_bChanged = g_hCvChanged.BoolValue;
}