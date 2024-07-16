#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PL_VERSION "1.0"
ConVar g_hCvarEnable;
int g_iEnablle;
bool g_bBlurHooked, g_bRumbleHooked;

public Plugin myinfo =
{
	name = "[L4D2] Remove Scavenge Round End Blur and Rumble",
	author = "blueblur",
	description = "Remove blur and rumble effect after a scavenge round ends.",
	version	= PL_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    CreateConVar("l4d2_scav_remove_blur_rumble_version", PL_VERSION, "Version of the plugin", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);

    g_hCvarEnable = CreateConVar("l4d2_scav_remove_blur_rumble_enable", "3", "Enable/Disable the plugin, \
                                                                                   0 - Disable, \
                                                                                   1 - Remove rumble effect, \
                                                                                   2 - Remove blur effect, \
                                                                                   3 - Remove both effects.");
    SetCvar();
    g_hCvarEnable.AddChangeHook(OnPluginConVarChanged);
    ConVar convar = FindConVar("mp_gamemode");
    if (convar != null)
    {
        convar.AddChangeHook(OnGameModeChanged);
        
        char sBuffer[16];
        convar.GetString(sBuffer, sizeof(sBuffer));
        if (strcmp(sBuffer, "scavenge") == 0)
        {
            switch (g_iEnablle)
            {
                case 0: {g_bRumbleHooked = false; g_bBlurHooked = false;}
                case 1: {HookUserMessage(GetUserMessageId("Rumble"), UsgHook_Rumble_Intercept, true); g_bRumbleHooked = true;}
                case 2: {HookUserMessage(GetUserMessageId("BlurFade"), UsgHook_BlurFade_Intercept, true); g_bBlurHooked = true;}
                case 3: 
                {
                    HookUserMessage(GetUserMessageId("BlurFade"), UsgHook_BlurFade_Intercept, true);
                    HookUserMessage(GetUserMessageId("Rumble"), UsgHook_Rumble_Intercept, true);
                    g_bRumbleHooked = true;
                    g_bBlurHooked = true;
                }
            }
        }
    }
}

void OnGameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (strcmp(newValue, "scavenge") == 0)
    {
        ChangeHook();
        return;
    }
    else if (g_bRumbleHooked)
        UnhookUserMessage(GetUserMessageId("Rumble"), UsgHook_Rumble_Intercept, true);
    else if (g_bBlurHooked)
        UnhookUserMessage(GetUserMessageId("BlurFade"), UsgHook_BlurFade_Intercept, true);
    g_bRumbleHooked = false;
    g_bBlurHooked = false;
}

void OnPluginConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    SetCvar();
}

void SetCvar()
{
    g_iEnablle = g_hCvarEnable.IntValue;
    ChangeHook();
}

void ChangeHook()
{
    switch (g_iEnablle)
    {
        case 0: 
        {
            if (g_bRumbleHooked)
                UnhookUserMessage(GetUserMessageId("Rumble"), UsgHook_Rumble_Intercept, true);
            if (g_bBlurHooked)
                UnhookUserMessage(GetUserMessageId("BlurFade"), UsgHook_BlurFade_Intercept, true);
            g_bRumbleHooked = false;
            g_bBlurHooked = false;
        }
        case 1: 
        {   
            if (!g_bRumbleHooked)
                HookUserMessage(GetUserMessageId("Rumble"), UsgHook_Rumble_Intercept, true);
            if (g_bBlurHooked)
                UnhookUserMessage(GetUserMessageId("BlurFade"), UsgHook_Rumble_Intercept, true);
            g_bRumbleHooked = true;
            g_bBlurHooked = false;
        }
        case 2: 
        {
            if (!g_bBlurHooked)
                HookUserMessage(GetUserMessageId("BlurFade"), UsgHook_BlurFade_Intercept, true);
            if (g_bRumbleHooked)
                UnhookUserMessage(GetUserMessageId("Rumble"), UsgHook_Rumble_Intercept, true);
            g_bBlurHooked = true;
            g_bRumbleHooked = false;
        }
        case 3: 
        {
            if (!g_bBlurHooked)
                HookUserMessage(GetUserMessageId("BlurFade"), UsgHook_BlurFade_Intercept, true);
            if (!g_bRumbleHooked)
                HookUserMessage(GetUserMessageId("Rumble"), UsgHook_Rumble_Intercept, true);
            g_bRumbleHooked = true;
            g_bBlurHooked = true;
        }
    }
}

Action UsgHook_BlurFade_Intercept(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    char sBuffer[64];
    if (GetUserMessageName(msg_id, sBuffer, sizeof(sBuffer)) && strcmp(sBuffer, "BlurFade") == 0)
        return Plugin_Handled;
    return Plugin_Continue;
}

Action UsgHook_Rumble_Intercept(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    char sBuffer[64];
    if (GetUserMessageName(msg_id, sBuffer, sizeof(sBuffer)) && strcmp(sBuffer, "Rumble") == 0)
        return Plugin_Handled;
    return Plugin_Continue;
}