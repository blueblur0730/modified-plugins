#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.3"

public Plugin:myinfo =
{
	name = "L4D2 VS Survival Autolaunch",
	author = " AtomicStryker",
	description = " Auto Launch for Versus Survival ",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=131266"
};

static const Float:SPAWNDELAY = 10.0;

static bool:isVersusSurvival = false;
static bool:roundHandled = false;
static Handle:countDownTimer = INVALID_HANDLE;
static Handle:countDownCvar = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("l4d2_vs_sv_autolaunch_version", PLUGIN_VERSION, "L4D2 VS Survival Autolaunch Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	countDownCvar = CreateConVar("l4d2_vs_sv_autolaunch_time", "45", " Time after which an Auto Launch is done ", FCVAR_PLUGIN);
	
	HookEvent("player_first_spawn", _PlayerFirstSpawn_Event, EventHookMode_PostNoCopy);
	HookEvent("round_start", _RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", _RoundEnd_Event, EventHookMode_PostNoCopy);
}

public Action:_PlayerFirstSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!roundHandled && isVersusSurvival && countDownTimer == INVALID_HANDLE)
	{
		countDownTimer = CreateTimer(SPAWNDELAY, _Spawn_Timer);
		roundHandled = true;
	}
}

public Action:_RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:mode[36];
	GetConVarString(FindConVar("mp_gamemode"), mode, sizeof(mode));
	isVersusSurvival = StrEqual(mode, "mutation15");

	if (!roundHandled && isVersusSurvival && countDownTimer == INVALID_HANDLE)
	{
		countDownTimer = CreateTimer(SPAWNDELAY, _Spawn_Timer);
		roundHandled = true;
	}
}

public Action:_RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundHandled = false;
	
	if (countDownTimer != INVALID_HANDLE)
	{
		KillTimer(countDownTimer);
		countDownTimer = INVALID_HANDLE;
	}
}

public Action:_Spawn_Timer(Handle:timer)
{
	new Float:countdowntime = GetConVarFloat(countDownCvar);

	PrintToChatAll("Auto Starting Versus Survival Round in %i seconds", RoundToNearest(countdowntime));
	countDownTimer = CreateTimer(countdowntime, _AutoStart_Timer);
}

public Action:_AutoStart_Timer(Handle:timer)
{
	new trigger = FindSurvivalButton();
	if (trigger == -1)
	{
		return;
	}
	
	AcceptEntityInput(trigger, "Press");
	PrintToChatAll("Versus Survival Auto Start!");
	countDownTimer = INVALID_HANDLE;
}

static FindSurvivalButton()
{
	decl String:buffer[96];
	
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "func_button")) != -1)
	{
		if (ent)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if (StrEqual(buffer, "survival_alarm_button", false) || StrEqual(buffer, "survival_button", false))
			{
				return ent;
			}
		}
	}

	return -1;
}