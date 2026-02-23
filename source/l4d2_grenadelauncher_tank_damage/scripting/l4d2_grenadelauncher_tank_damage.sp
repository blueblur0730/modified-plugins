#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

ConVar g_hCvar_Scale;

#define PLUGIN_VERSION "1.0"
public Plugin myinfo =
{
	name = "[L4D2] Genade Launcher Tank Damage",
	author = "blueblur",
	description = "Control the damage dealt to the tank.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
    CreateConVar("l4d2_grenadelauncher_tank_damage_version", PLUGIN_VERSION, "Version of the plugin.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_hCvar_Scale = CreateConVar("l4d2_grenadelauncher_tank_damage_scale", "1.0", "Scale the damage dealt to the tank by this factor.", _, true, 0.0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "tank"))
    {
        SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTankTakeDamageAlive);
    }
}

Action OnTankTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (victim <= 0 || victim > MaxClients || inflictor <= MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(victim) || !IsValidEdict(inflictor))
        return Plugin_Continue;

    if (!(damagetype & DMG_BLAST))
        return Plugin_Continue;

    char inflictor_classname[64];
    GetEntityClassname(inflictor, inflictor_classname, sizeof(inflictor_classname));
    if (strcmp(inflictor_classname, "grenade_launcher_projectile") != 0)
        return Plugin_Continue;

    //PrintToServer("OnTankTakeDamageAlive called: Inflictor: %d/%s, Original Damage: %.02f, Scaled Damage: %.02f, DamageType: %d",inflictor, inflictor_classname, damage, damage * g_hCvar_Scale.FloatValue, damagetype);
    damage *= g_hCvar_Scale.FloatValue;
    return Plugin_Changed;
}