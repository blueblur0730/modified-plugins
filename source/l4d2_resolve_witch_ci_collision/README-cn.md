**[English](./README.md) | [中文](./README-cn.md)**

# [L4D2] Resolve Witch CI Collision

## 简介

尝试抵消由游荡的Witch与普通小僵尸碰撞产生的大幅位移现象.

## 依赖

- [MidHook Extension](https://github.com/Scags/SM-MidHooks) by Scags.
- [Action Extension](https://forums.alliedmods.net/showthread.php?t=336374) by BHaType.
- [gamedata_wrapper.inc](https://github.com/blueblur0730/modified-plugins/blob/main/include/gamedata_wrapper.inc)

## 推荐一起安装

- [resolve-collision-fix (nb_update_frequency 修复)](https://forums.alliedmods.net/showthread.php?t=344019) by BHaType.

## ConVar

```
// 开启修复.
z_witch_collision_neutralize_enable 1

// 修正Witch的速度方向, 这样他就可以在她的路径下一直走下去.
z_witch_collision_scale_direction 1

// 修正Witch速度向量的大小. 值越接近1, 速度变化越缓和.
z_witch_collision_neutralize_scale 0.95
```

## 演示

- [Link](https://www.bilibili.com/video/BV1VvJnzUEy1/)

## 解释

这个插件没有根源上解决碰撞问题, 相反, 这是一个抵消Witch与普通僵尸碰撞带来的额外的速度的折中方案. Witch仍然会被普通僵尸推开, 但已经不会从碰撞点上漂移至远方.

推荐随同该插件一起安装 BHaType 的 resolve-collision-fix. 这样可以最小化碰撞漂移现象.
