/**
 * changelog.
 * 
 *  # Introduction.
 *    - This is a merged and renewed plugin. Original version is below here:
 *    - [L4D] Survival Event Timer by Raoul Duk
 *       https://forums.alliedmods.net/showthread.php?t=92175

 *     - [L4D] Exact Player Lifetime in Survival by msleeper
 *       https://forums.alliedmods.net/showthread.php?t=91241

 *   # Logs.
 *      r1.0: 9/13/23
 *      - initial merge.
 * 
 *       
 *
 *  
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

float 
    SvStartTime;
    SvDuration[MAXPLAYERS + 1];

bool 
    SvRunning = false,
    SvPlayersDead = false,
    timerOn = false,
    timerDisabled[MAXPLAYERS + 1];

Handle 
    autoStart = INVALID_HANDLE;
    useHints = INVALID_HANDLE;
    Timers[25];

int currentTimer = 1;

#define PLUGIN_NAME         "[L4D] Survival Announcer"
#define PLUGIN_AUTHOR       "Raoul Duke, msleeper, blueblur"
#define PLUGIN_VERSION      "r1.0"
#define PLUGIN_DESCRIPTION  "General announcer for survival mode"
#define PLUGIN_URL          "https://github.com/blueblur0730/modified-plugins"

#define MAX_PLAYERS	        8		
#define MAX_LINE_WIDTH      64
#define PLUGIN_TAG  	  "[{olive}Announcer{default}]"

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
    autoStart = CreateConVar("survival_timer_auto", "1", "The Survival Event Timer is automatically on for players by default but can be manual.", FCVAR_PLUGIN);
	useHints = CreateConVar("survival_timer_hints", "1", "The Survival Event Timer displays hints by default but can display chat messages instead.", FCVAR_PLUGIN);

	RegConsoleCmd("sm_showtimer", Cmd_TimerSwitch);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("create_panic_event", Event_TimerStart);
	HookEvent("tank_killed", Event_TankKilled);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);

    SvStartTime = GetEngineTime();
}

public Action Event_PlayerDeath(Handle hEvent, const char[] name, bool dontBroadcast)
{
    if (!SvRunning || SvPlayersDead)
        return;

    int Victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!Victim || IsFakeClient(Victim))
        return;

    char VictimName[32];
    GetClientName(Victim, VictimName, sizeof(VictimName));

    SvDuration[Victim] = FloatSub(GetEngineTime(), SvStartTime);
    float tmp[3];

    tmp[0] = float(RoundToFloor(FloatDiv(SvDuration[Victim], 60.0)));
    tmp[1] = FloatSub(SvDuration[Victim], FloatMul(tmp[0], 60.0));
    tmp[2] = FloatFraction(tmp[1]);

    PrintToChatAll("\x04%s \x01has died!", VictimName);
    PrintToChatAll("Time: \x04%f", SvDuration[Victim]);
    PrintToChatAll("Time: \x04%2.0f:%2.2f", tmp[0], tmp[1]);
}

public Action Event_PanicEvent(Handle hEvent, const char[] name, bool dontBroadcast)
{
    if (SvRunning)
        return;

    for (int i = 1; i <= MaxClients; i++)
        SvDuration[i] = 0.0;

    SvStartTime = GetEngineTime();
    SvRunning = true;
}

public Action Event_RoundStart(Handle hEvent, const char[] name, bool dontBroadcast)
{
    SvRunning = false;
    SvPlayersDead = false;
}

public Action Event_RoundEnd(Handle hEvent, const char[] name, bool dontBroadcast)
{
    float RoundTime = GetEventFloat(event, "time");

    if (RoundTime == 0)
        return;

    char Name[32];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
        {
            if (!SvDuration[i])
                SvDuration[i] = RoundTime;

            GetClientName(i, Name, sizeof(Name));
            PrintToChatAll("\x04%s \x01duration: %f", Name, SvDuration[i]);
        }
    }

    SvPlayersDead = true;
}

// Switch client settings and vocalize
public Action cmd_TimerSwitch(int client, int args) 
{
	if(IsClientInGame(client) && !IsFakeClient(client))
    {
		if(autoStart.BoolValue)
        {	
			PrintToChatAll(client, "\x01[\x05SM\x01] \x05Survival Event Timer Disabled.");
			PrintToChatAll(client, "\x01[\x05SM\x01] \x05Type \x01!showtimer \x05to enable.");
		}
		else
        {
			PrintToChatAll(client, "\x01[\x05SM\x01] \x05Survival Event Timer Enabled.");
			PrintToChatAll(client, "\x01[\x05SM\x01] \x05Type \x01!showtimer \x05to disable.");
		}
	}
	return Plugin_Handled;
}