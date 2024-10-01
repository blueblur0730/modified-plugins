#if defined _l4d2_stucked_tank_teleport_included
 #endinput
#endif
#define _l4d2_stucked_tank_teleport_included

/**
 * Called when a bot tank tried to suicide for stucked or lost its target for too long.
 * 
 * @note This is a hook using MidHook to hook the middle of the function call: TankAttack::Update.
 * @note Called when passing the aruguments to CTakeDamageInfo::CTakeDamageInfo,
 * @note Specifically, when the damage value has been moved into register xmm0 and this plugin has set the damage to 0.0.
 * 
 * @param tank      client index of the tank.s
 * 
 * @noreturn  
*/
forward void MidHook_OnTankSuicide(int tank);

public SharedPlugin __pl_l4d2_stucked_tank_teleport =
{
	name = "l4d2_stucked_tank_teleport",
	file = "l4d2_stucked_tank_teleport.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};