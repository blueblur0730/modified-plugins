#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PL_VERSION "1.1"
ConVar g_hCvarEnable;
ConVar g_hCvarBlockVGUI;
ConVar g_hCvarFreelyMove;

bool g_bScav;

// https://github.com/Attano/Left4Downtown2/blob/944994f916617201680c100d372c1074c5f6ae42/l4d2sdk/director.h#L121
enum
{
	RESTART_FINALE_WON = 3,
	RESTART_VERSUS_SOMETHING1 = 5,
	RESTART_VERSUS_FROMVOTE = 7,
	RESTART_VERSUS_SOMETHING2 = 8,
	RESTART_SCAVENGE_ROUND = 9, // Halftime or round end
	RESTART_SCAVENGE_ROUND_TIE = 10, // exact tie (cans+time
	RESTART_VERSUS_CHANGELEVEL,
	RESTART_SCAVENGE_MATCH_FINISHED = 12,
	RESTART_SCAVENGE_SOMETHING3 = 13,
	RESTART_SURVIVAL_ROUND1 = 14,
	RESTART_SURVIVAL_ROUND2 = 16,
	RESTART_MISSION_ABORTED = 18,
};

public Plugin myinfo =
{
	name = "[L4D2] Scavenge Round End Miscs",
	author = "blueblur",
	description = "Scavenge Round End Miscs.",
	version	= PL_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    CreateConVar("l4d2_scav_round_end_miscs_version", PL_VERSION, "Version of the plugin", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_hCvarEnable = CreateConVar("l4d2_scav_remove_blur_rumble_enable", "1", "Enable/Disable the plugin", _, true, 0.0, true, 1.0);
    g_hCvarBlockVGUI = CreateConVar("l4d2_scav_remove_VGUI_penal", "1", "Enable/Disable removing the summery vgui penal.", _, true, 0.0, true, 1.0);
    g_hCvarFreelyMove = CreateConVar("l4d2_scav_freely_move_on_round_end", "1", "Enable/Disable freely move on round end.", _, true, 0.0, true, 1.0);

    FindConVar("mp_gamemode").AddChangeHook(OnGameModeChanged);
    OnGameModeChanged(FindConVar("mp_gamemode"), "", "");

    HookUserMessage(GetUserMessageId("BlurFade"), UsgHook_BlurFade_Intercept, true);
    HookUserMessage(GetUserMessageId("Rumble"), UsgHook_Rumble_Intercept, true);
    HookUserMessage(GetUserMessageId("VGUIMenu"), Usg_VGUIMenu_Intercept, true);

    HookEvent("round_end", Event_RoundEnd);
}

void OnGameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    char sMode[64];
    convar.GetString(sMode, sizeof(sMode));
    g_bScav = (strcmp(sMode, "scavenge") == 0);
}

Action UsgHook_BlurFade_Intercept(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (!g_bScav)
        return Plugin_Continue;

    if (!g_hCvarEnable.BoolValue)
        return Plugin_Continue;

    char sBuffer[16];
    if (GetUserMessageName(msg_id, sBuffer, sizeof(sBuffer)) && strcmp(sBuffer, "BlurFade") == 0)
        return Plugin_Handled;

    return Plugin_Continue;
}

Action UsgHook_Rumble_Intercept(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (!g_bScav)
        return Plugin_Continue;

    if (!g_hCvarEnable.BoolValue)
        return Plugin_Continue;

    char sBuffer[16];
    if (GetUserMessageName(msg_id, sBuffer, sizeof(sBuffer)) && strcmp(sBuffer, "Rumble") == 0)
        return Plugin_Handled;

    return Plugin_Continue;
}

Action Usg_VGUIMenu_Intercept(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (!g_bScav)
        return Plugin_Continue;

    if (!g_hCvarBlockVGUI.BoolValue)
        return Plugin_Continue;

    char sBuffer[16];
    if (GetUserMessageName(msg_id, sBuffer, sizeof(sBuffer)) && strcmp(sBuffer, "VGUIMenu") == 0)
    {
        // https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/server/player.cpp#L2055
        char name[32];
        msg.ReadString(name, sizeof(name));
        //PrintToServer("### Usg_VGUIMenu_Intercept, VGUI name: %s", name);
        if (strcmp(name, "fullscreen_scavenge_scoreboard") == 0)
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

// from l4d_freely_round_end by ForgeTest.
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bScav)
        return;

	switch (event.GetInt("reason")) 
	{
		case RESTART_SCAVENGE_ROUND, RESTART_SCAVENGE_ROUND_TIE, RESTART_SCAVENGE_MATCH_FINISHED, RESTART_SCAVENGE_SOMETHING3:
		{
			RequestFrame(OnNextFrame);
		}
	}
}

void OnNextFrame()
{
    if (!g_hCvarFreelyMove.BoolValue)
        return;

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			SetEntityFlags(i, GetEntityFlags(i) & ~(FL_FROZEN|FL_GODMODE));
		}
	}
}