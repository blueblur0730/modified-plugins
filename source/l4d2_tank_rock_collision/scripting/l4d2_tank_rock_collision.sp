#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.1"

public Plugin myinfo =
{
	name = "[L4D2] Tank Rock Collision",
    author = "blueblur",
	description = "Detonate tank rocks when they collide with the another tank.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void L4D_TankRock_BounceTouch_Post(int tank, int rock, int entity)
{
    if (entity <= 0 || entity > MaxClients)
        return;

    if (!IsValidEntity(entity) || GetClientTeam(entity) != 3 || !IsTank(entity))
        return;

    if (!IsValidEntity(rock))
        return;

    L4D_DetonateProjectile(rock);
}

stock bool IsTank(int client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}
