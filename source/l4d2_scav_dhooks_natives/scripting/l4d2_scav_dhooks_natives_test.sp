#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <l4d2_scav_stocks>
#undef REQUIRE_PLUGIN
#include <l4d2_scav_dhooks_natives>

#define PL_VERSION "1.0"

bool g_bAllowed;
bool g_bLibraryActive;
ScavStocksWrapper g_Wrapper;
ConVar g_hCvTesterNumber, g_hCvAllowed;
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
    g_hCvAllowed = CreateConVar("allowed", "0", "Set 1 to allow bosses.");
    g_hCvTesterNumber.AddChangeHook(OnCvarChanged);
    g_hCvAllowed.AddChangeHook(OnCvarChanged);

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

        case 2: L4D2_UpdateScavengeOvertimeState();
        case 3: L4D2_ResetScavengeRoundNumber();
        case 4:
        {
            float time = GetCmdArgFloat(1);
            float oldduration = g_Wrapper.GetRoundDuration(2);
            L4D2_AccumulateScavengeRoundTime(time);
            float newduration = g_Wrapper.GetRoundDuration(2);
            PrintToServer("L4D2_AccumulateScavengeRoundTime called. Time: %f, OldDuration: %f, NewDuration: %f", time, oldduration, newduration);
        }

        case 5: L4D2_RestartScavengeRound();
        case 6:
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

        case 7: L4D2_EndScavengeRound();
        case 8:
        {
            if (!IsClientInGame(client))
                return Plugin_Handled;

            int team = GetCmdArgInt(1);
            if (team != 2 && team != 3)
            {
                ReplyToCommand(client, "Invalid team. Please enter 2 or 3.");
                return Plugin_Handled;
            }

            int oldteamscore = g_Wrapper.GetTeamScore(team);
            float oldduration = g_Wrapper.GetRoundDuration(team);

            L4D2_CDirector_IncrementScavengeTeamScore(team, client);

            int newteamscore = g_Wrapper.GetTeamScore(team);
            float newduration = g_Wrapper.GetRoundDuration(team);
            PrintToServer("L4D2_CDirector_IncrementScavengeTeamScore called. Team: %d, OldTeamScore: %d, NewTeamScore: %d, OldDuration: %f, NewDuration: %f", team, oldteamscore, newteamscore, oldduration, newduration);
        }

        case 9:
        {
            int team = GetCmdArgInt(1);
            int oldteamscore = g_Wrapper.GetTeamScore(team);
            L4D2_CTerrorGameRules_IncrementScavengeTeamScore(team);
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

public void L4D2_OnBeginScavengeRoundSetupTime()
{
    PrintToServer("L4D2_OnBeginScavengeRoundSetupTime called. GameTime: %f", GetGameTime());
}

public void L4D2_OnEndScavengeOvertime()
{
    PrintToServer("L4D2_OnEndScavengeOvertime called. GameTime: %f", GetGameTime());
}

public Action L4D2_AreBossesProhibited(bool prohibited)
{
    //PrintToServer("L4D2_AreBossesProhibited called. Prohibited: %d", prohibited);

    if (g_bAllowed)
        return Plugin_Continue;
    else
        return Plugin_Changed;
}

void OnCvarChanged(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
    g_iTesterNumber = g_hCvTesterNumber.IntValue;
    g_bAllowed = g_hCvAllowed.BoolValue;
}