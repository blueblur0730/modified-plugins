#if defined _l4d2_hit_feedback_setup_included
	#endinput
#endif
#define _l4d2_hit_feedback_setup_included

void SetupConVars()
{
	CreateConVar("l4d2_hit_feedback_version", PL_VERSION, "Plugin version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hCvTimeForKillMarker		  = CreateConVar("sm_hitsound_showtime_kill", "0.2", "击杀图标存在的时长(默认为0.3)");
	g_hCvTimeForHitMarker		  = CreateConVar("sm_hitsound_showtime_hit", "0.1", "击中图标存在的时长(默认为0.1)");

	g_hCvEnableSound			  = CreateConVar("sm_hitsound_g_hCvEnableSound", "1", "是否开启音效(0-关, 1-开)");
	g_hCvSoundPathHeadShot		  = CreateConVar("sm_hitsound_mp3_headshot", "hitsound/headshot.mp3", "爆头音效的地址");
	g_hCvSoundPathBodyHit		  = CreateConVar("sm_hitsound_mp3_hit", "hitsound/hit.mp3", "击中音效的地址");
	g_hCvSoundPathKill			  = CreateConVar("sm_hitsound_mp3_kill", "hitsound/kill.mp3", "击杀音效的地址");

	g_hCvSoundPathHeadShotDefualt = CreateConVar("sm_hitsound_classic_headshot", "level/timer_bell.wav", "无需下载内容的爆头音效的地址");
	g_hCvSoundPathBodyHitDefualt  = CreateConVar("sm_hitsound_classic_hit", "buttons/button22.wav", "无需下载内容的击中音效的地址");
	g_hCvSoundPathKillDefualt	  = CreateConVar("sm_hitsound_classic_kill", "level/pointscored.wav", "无需下载内容的击杀音效的地址");

	g_hCvPicPathHeadShot		  = CreateConVar("sm_hitsound_pic_headshot", "overlays/head2", "爆头图标的地址");
	g_hCvPicPathBodyHit			  = CreateConVar("sm_hitsound_pic_hit", "overlays/body2", "击中图标的地址");
	g_hCvPicPathKill			  = CreateConVar("sm_hitsound_pic_kill", "overlays/head2", "击杀图标的地址");
	g_hCvPicPathBodyHitAuto		  = CreateConVar("sm_hitsound_pic_hit_auto", "overlays/body2", "自动武器击杀图标的地址");

	g_hCvEnableInfectedPic		  = CreateConVar("hit_feedback_SIPic_enable", "1", "是否开启特感的击杀图标(0-关, 1-开)");
	g_hCvEnableInfKillPic		  = CreateConVar("hit_feedback_InfKillPic_enable", "1", "是否开启感染者的击杀图标(0-关, 1-开)");
	g_hCvEnableInfHitPic		  = CreateConVar("hit_feedback_InfDeathPic_enable;", "1", "是否开启感染者的命中图标(0-关, 1-开)");
	g_hCvEnableOnInfectedHit	  = CreateConVar("hit_feedback_hit_inf_sound_enable", "1", "是否开启感染者击中反馈声音(0-关, 1-开 建议开启)");
	g_hCvEnableOnInfectedKill	  = CreateConVar("hit_feedback_kill_inf_sound_enable", "1", "是否开启感染者击杀反馈声音(0-关, 1-开 建议开启)");

	g_hCvEnableBlast			  = CreateConVar("hit_feedback_blast_enable", "0", "是否开启爆炸反馈提示(0-关, 1-开 建议关闭)");
	g_hCvEnableFire				  = CreateConVar("hit_feedback_fire_enable", "0", "是否开启火烧反馈提示");
	g_hCvEnableMelee			  = CreateConVar("hit_feedback_melee_enable", "1", "是否开启近战反馈(0-关, 1-开 建议开启)");

	g_hCvEnable					  = CreateConVar("hit_feedback_enable", "1", "是否开启本插件(0-关, 1-开)");
}

void RegCookies()
{
	g_hStyleCookie = RegClientCookie("hm_style", "", CookieAccess_Protected);
}

void RegCommands()
{
	RegConsoleCmd("sm_hitmarker", Command_HM);
}

void PreCacheResources()
{
	g_hCvSoundPathHeadShot.GetString(g_sSoundHeadShot, sizeof(g_sSoundHeadShot));
	g_hCvSoundPathHeadShotDefualt.GetString(g_sSoundHeadShotDefualt, sizeof(g_sSoundHeadShotDefualt));
	g_hCvSoundPathBodyHit.GetString(g_sSoundBodyHit, sizeof(g_sSoundBodyHit));
	g_hCvSoundPathBodyHitDefualt.GetString(g_sSoundBodyHitDefualt, sizeof(g_sSoundBodyHitDefualt));
	g_hCvSoundPathKill.GetString(g_sSoundKill, sizeof(g_sSoundKill));
	g_hCvSoundPathKillDefualt.GetString(g_sSoundKillDefualt, sizeof(g_sSoundKillDefualt));

	PrecacheSound(g_sSoundHeadShot, true);
	PrecacheSound(g_sSoundHeadShotDefualt, true);
	PrecacheSound(g_sSoundBodyHit, true);
	PrecacheSound(g_sSoundBodyHitDefualt, true);
	PrecacheSound(g_sSoundKill, true);
	PrecacheSound(g_sSoundKillDefualt, true);

	char overlays_file[64];
	g_hCvPicPathHeadShot.GetString(g_sPic1, sizeof(g_sPic1));
	g_hCvPicPathBodyHit.GetString(g_sPic2, sizeof(g_sPic2));
	g_hCvPicPathKill.GetString(g_sPic3, sizeof(g_sPic3));
	g_hCvPicPathBodyHitAuto.GetString(g_sPic4, sizeof(g_sPic4));

	Format(overlays_file, sizeof(overlays_file), "%s.vtf", g_sPic1);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vtf", g_sPic2);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vtf", g_sPic3);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vtf", g_sPic4);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vmt", g_sPic1);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vmt", g_sPic2);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vmt", g_sPic3);
	PrecacheDecal(overlays_file, true);

	Format(overlays_file, sizeof(overlays_file), "%s.vmt", g_sPic4);
	PrecacheDecal(overlays_file, true);
}

void HookEvents()
{
	HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
	HookEvent("infected_death", Event_InfectedDeath, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
	HookEvent("player_incapacitated", Event_PlayerIncap, EventHookMode_Post);
}