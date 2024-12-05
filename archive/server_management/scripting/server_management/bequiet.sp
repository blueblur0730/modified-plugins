#if defined _server_management_bequiet_included
    #endinput
#endif
#define _server_management_bequiet_included

//------------------
// Be Quiet by Sir.
//------------------

static ConVar g_hCvar_CvarChange, g_hCvar_NameChange, g_hCvar_SpecNameChange, g_hCvar_SpecSeeChat;
static bool g_bCvarChange, g_bNameChange, g_bSpecNameChange, g_bSpecSeeChat;

void _bequiet_OnPluginStart()
{
    LoadTranslation("server_management.bequiet.phrases");
    AddCommandListener(Say_Callback, "say");
    AddCommandListener(TeamSay_Callback, "say_team");

    //Server CVar
    HookEvent("server_cvar", Event_ServerConVar, EventHookMode_Pre);
    HookEvent("player_changename", Event_NameChange, EventHookMode_Pre);

    //Cvars
    g_hCvar_CvarChange = CreateConVar("bq_cvar_change_suppress", "1", "Silence Server Cvars being changed, this makes for a clean chat with no disturbances.");
    g_hCvar_NameChange = CreateConVar("bq_name_change_suppress", "1", "Silence Player name Changes.");
    g_hCvar_SpecNameChange = CreateConVar("bq_name_change_spec_suppress", "1", "Silence Spectating Player name Changes.");
    g_hCvar_SpecSeeChat = CreateConVar("bq_show_player_team_chat_spec", "1", "Show Spectators Survivors and Infected Team chat?");

    g_bCvarChange = g_hCvar_CvarChange.BoolValue;
    g_bNameChange = g_hCvar_NameChange.BoolValue;
    g_bSpecNameChange = g_hCvar_SpecNameChange.BoolValue;
    g_bSpecSeeChat = g_hCvar_SpecSeeChat.BoolValue;

    g_hCvar_CvarChange.AddChangeHook(cvarChanged);
    g_hCvar_NameChange.AddChangeHook(cvarChanged);
    g_hCvar_SpecNameChange.AddChangeHook(cvarChanged);
    g_hCvar_SpecSeeChat.AddChangeHook(cvarChanged);

    AutoExecConfig(true);
}

static Action Say_Callback(int client, char[] command, int args)
{
    char sayWord[MAX_NAME_LENGTH];
    GetCmdArg(1, sayWord, sizeof(sayWord));
    
    if(sayWord[0] == '!' || sayWord[0] == '/')
        return Plugin_Handled;

    return Plugin_Continue; 
}

static Action TeamSay_Callback(int client, char[] command, int args)
{
    char sayWord[MAX_NAME_LENGTH];
    GetCmdArg(1, sayWord, sizeof(sayWord));
    
    if(sayWord[0] == '!' || sayWord[0] == '/')
        return Plugin_Handled;
    
    if (g_bSpecSeeChat && GetClientTeam(client) != 1)
    {
        char sChat[256];
        GetCmdArgString(sChat, 256);
        StripQuotes(sChat);
        int i = 1;
        while (i <= 65)
        {
            if (IsValidClient(i) && GetClientTeam(i) == 1)
            {
                if (IsClientAdmin(client))
                {
                    CPrintToChatEx(i, client, "%t", "AdminSay", client, sChat);
                    i++;
                    continue;
                }

                if (GetClientTeam(client) == 2) CPrintToChat(i, "%t", "SurvivorSay", client, sChat);
                else CPrintToChat(i, "%t", "InfectedSay", client, sChat);
            }
            i++;
        }
    }
    return Plugin_Continue;
}

static Action Event_ServerConVar(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bCvarChange) return Plugin_Handled;
    return Plugin_Continue;
}

static Action Event_NameChange(Event event, const char[] name, bool dontBroadcast)
{
    int clientid = event.GetInt("userid");
    int client = GetClientOfUserId(clientid); 

    if (IsValidClient(client))
    {
        if (GetClientTeam(client) == 1 && g_bSpecNameChange) return Plugin_Handled;
        else if (g_bNameChange) return Plugin_Handled;
    }
    return Plugin_Continue;
}

static void cvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
    g_bCvarChange = g_hCvar_CvarChange.BoolValue;
    g_bNameChange = g_hCvar_NameChange.BoolValue;
    g_bSpecNameChange = g_hCvar_SpecNameChange.BoolValue;
    g_bSpecSeeChat = g_hCvar_SpecSeeChat.BoolValue;
}