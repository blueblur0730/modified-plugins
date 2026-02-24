#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo =
{
	name = "[L4D2] Charger Carry Glow",
	author = "blueblur",
	description = "Glows the charger when carrying a survivor.",
	version = PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

ConVar g_hCvar_Glow;
public void OnPluginStart()
{
    HookEvent("charger_carry_start", Event_ChargerCarryStart);
    HookEvent("charger_pummel_start", Event_ChargerPummelStart);

    g_hCvar_Glow = CreateConVar("l4d2_charger_carry_glow", "255", "Glow color.", _, true, 0.0, true, 255.0);
}

void Event_ChargerCarryStart(Event event, const char[] name, bool dontBroadcast)
{
    int charger = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (charger <= 0 || victim <= 0 || charger > MaxClients || victim > MaxClients)
        return;

    if (!IsClientInGame(charger) || !IsClientInGame(victim))
        return;

    SetGlow(charger, true);
}

void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
    int charger = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (charger <= 0 || victim <= 0 || charger > MaxClients || victim > MaxClients)
        return;

    if (!IsClientInGame(charger) || !IsClientInGame(victim))
        return;

    SetGlow(charger, false);
}

stock void SetGlow(int client, bool toggle)
{
    if (toggle)
    {
        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
        SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
        SetEntProp(client, Prop_Send, "m_nGlowRange", 1000);
        SetEntProp(client, Prop_Send, "m_glowColorOverride", g_hCvar_Glow.IntValue);
    }
    else
    {
        SetEntProp(client, Prop_Send, "m_iGlowType", 0);
        SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
        SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
        SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
    }
}