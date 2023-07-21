#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <scavenge_func>

/*
* A plugin to test wether you can set scavenge round, scavenge round scores, scavenge match scores.
* (perhaps scavenge item remaining and scavenge goal is ok too)
* result is all ok.
*/

public void OnPluginStart()
{
    RegAdminCmd("sm_setrounds", SetRounds, ADMFLAG_SLAY);
    RegAdminCmd("sm_setroundscores", SetRoundScores, ADMFLAG_SLAY);
    RegAdminCmd("sm_setmatchscores", SetMatchScores, ADMFLAG_SLAY);
}

Action SetRounds(int client, int args)
{
    char iargs[64];
    if(args != 1)
    {
		PrintToChat(client, "[SM] Usage: sm_setrounds <num>");
		return Plugin_Handled;
    }
    else
    {
        GetCmdArg(1, iargs, sizeof(iargs));
        SetScavengeRoundNumber(StringToInt(iargs));
    }

    return Plugin_Handled;
}

Action SetRoundScores(int client, int args)
{
    char iargs[64], jargs[64], kargs[64];
    if(args != 3)
    {
		PrintToChat(client, "[SM] Usage: sm_setroundscores <team> <round num> <score>");
		return Plugin_Handled;
    }
    else
    {
        GetCmdArg(1, iargs, sizeof(iargs));
        GetCmdArg(2, jargs, sizeof(jargs));
        GetCmdArg(3, kargs, sizeof(kargs));
        SetScavengeTeamScore(StringToInt(iargs), StringToInt(jargs), StringToInt(kargs));
    }

    return Plugin_Handled;
}

Action SetMatchScores(int client, int args)
{
    char iargs[64], jargs[64];
    if(args != 2)
    {
		PrintToChat(client, "[SM] Usage: sm_setmatchscores <team> <score>");
		return Plugin_Handled;
    }
    else
    {
        GetCmdArg(1, iargs, sizeof(iargs));
        GetCmdArg(2, jargs, sizeof(jargs));
        SetScavengeMatchScore(StringToInt(iargs), StringToInt(jargs));
    }

    return Plugin_Handled;
}