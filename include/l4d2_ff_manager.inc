#if defined _l4d2_ff_manager_included
 #endinput
#endif
#define _l4d2_ff_manager_included

/**
 * OnTakeDamage/Alive hook whether processed by ff manager or not.
*/
forward void FFManager_OnFriendlyFire(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, float damageForce[3], float damagePosition[3])

public SharedPlugin __pl_l4d2_ff_manager =
{
	name = "l4d2_ff_manager",
	file = "l4d2_ff_manager.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};