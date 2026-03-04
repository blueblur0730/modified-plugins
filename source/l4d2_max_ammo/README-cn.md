**[English](./README.md) | [中文](./README-cn.md)**

# [L4D2] Max Ammo

绕过游戏原生convar，为每一把抢单独实现最大备弹数。

## 要求

- [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696) (运行时需要)
- [l4d_transition_entity](https://github.com/Target5150/MoYu_Server_Stupid_Plugins/tree/master/The%20Last%20Stand/l4d_transition_entity) (运行时需要)

- [gamedata_wrapper.inc](https://github.com/blueblur0730/modified-plugins/blob/main/include/gamedata_wrapper.inc)
(编译时需要)
- [l4d2util.inc](https://github.com/SirPlease/L4D2-Competitive-Rework/tree/master/addons/sourcemod/scripting/include) (编译时需要)

## ConVars

```
l4d2_max_ammo_rifle_ak47 400  // Max ammo for rifle_ak47 weapon.
l4d2_max_ammo_smg_silenced 650  // Max ammo for smg_silenced weapon.
l4d2_max_ammo_sniper_awp 150  // Max ammo for sniper_awp weapon.
l4d2_max_ammo_sniper_scout 150  // Max ammo for sniper_scout weapon.
l4d2_max_ammo_rifle 360          // Max ammo for rifle weapon.
l4d2_max_ammo_rifle_m60 150      // Max ammo for rifle_m60 weapon.
l4d2_max_ammo_autoshotgun 90  // Max ammo for autoshotgun weapon.
l4d2_max_ammo_rifle_sg552 360  // Max ammo for rifle_sg552 weapon.
l4d2_max_ammo_pumpshotgun 72  // Max ammo for pumpshotgun weapon.
l4d2_max_ammo_grenade_launcher 30 // Max ammo for grenade_launcher weapon.
l4d2_max_ammo_sniper_military 180 // Max ammo for sniper_military weapon.
l4d2_max_ammo_shotgun_chrome 72  // Max ammo for shotgun_chrome weapon.
l4d2_max_ammo_shotgun_spas 90  // Max ammo for shotgun_spas weapon.
l4d2_max_ammo_smg_mp5 650      // Max ammo for smg_mp5 weapon.
l4d2_max_ammo_smg 650          // Max ammo for smg weapon.
l4d2_max_ammo_hunting_rifle 150  // Max ammo for hunting_rifle weapon.
l4d2_max_ammo_rifle_desert 360  // Max ammo for rifle_desert weapon.
```
