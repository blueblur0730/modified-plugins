#if defined _l4d2_block_gun_sound_included
 #endinput
#endif
#define _l4d2_block_gun_sound_included

/**
 * @brief Stops the sound of a weapon by a weapon entity index.
 * 
 * @param weapon    The weapon entity index.
 * @noreturn
 * @error           Invalid weapon entity index.
*/
native void StopWeaponSound(int weapon)

public SharedPlugin __pl_l4d2_block_gun_sound = 
{
	name = "l4d2_block_gun_sound",
	file = "l4d2_block_gun_sound.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};