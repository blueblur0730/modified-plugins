#if defined _l4d2_hit_feedback_setup_included
	#endinput
#endif
#define _l4d2_hit_feedback_setup_included

void SetupConVars()
{
	CreateConVar("l4d2_hit_feedback_version", PL_VERSION, "Plugin version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hCvTimeForKillMarker		  = CreateConVarHook("hit_feedback_showtime_kill", "0.2", "Time for kill marker to exist (seconds).", FCVAR_NONE, true, 0.0, false, _, OnCvarChanged_FloatValue);
	g_hCvTimeForHitMarker		  = CreateConVarHook("hit_feedback_showtime_hit", "0.1", "Time for hit marker to exist (seconds).", FCVAR_NONE, true, 0.0, false, _, OnCvarChanged_FloatValue);

	g_hCvEnableSound			  = CreateConVarHook("hit_feedback_enable_sound", "1", "Enable sounds.", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvSoundPathHeadShot		  = CreateConVarHook("hit_feedback_sound_headshot", "hitsound/headshot.mp3", "Sound path for headshot.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);
	g_hCvSoundPathBodyHit		  = CreateConVarHook("hit_feedback_sound_hit", "hitsound/hit.mp3", "Sound path for body hit.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);
	g_hCvSoundPathKill			  = CreateConVarHook("hit_feedback_sound_kill", "hitsound/kill.mp3", "Sound path for kill.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);

	g_hCvSoundPathHeadShotDefualt = CreateConVarHook("hit_feedback_defualt_sound_headshot", "level/timer_bell.wav", "Defualt sound path for headshot.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);
	g_hCvSoundPathBodyHitDefualt  = CreateConVarHook("hit_feedback_defualt_sound_hit", "buttons/button22.wav", "Defualt sound path for body hit.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);
	g_hCvSoundPathKillDefualt	  = CreateConVarHook("hit_feedback_defualt_sound_kill", "level/pointscored.wav", "Defualt sound path for kill.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);

	g_hCvOverlayPathHeadShot	  = CreateConVarHook("hit_feedback_overlay_headshot", "l4d2_hit_feedback/overlays", "Overlay path for headshot.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);
	//g_hCvOverlayPathBodyHit		  = CreateConVarHook("hit_feedback_overlay_hit", "overlays/body2", "Overlay path for body hit.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);
	//g_hCvOverlayPathKill		  = CreateConVarHook("hit_feedback_overlay_kill", "overlays/head2", "Overlay path for kill.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);

	g_hCvEnableSIKillOverlay	  = CreateConVarHook("hit_feedback_si_kill_overlay_enable", "1", "Enable kill overlays for SI (Special Infected).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvEnableSIHitOverlay		  = CreateConVarHook("hit_feedback_si_hit_overlay_enable", "1", "Enable hit overlays for SI (Special Infected).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvEnableSIHitSnd			  = CreateConVarHook("hit_feedback_si_hit_sound_enable", "1", "Enable hit sound for SI (Special Infected).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvEnableSIKillSnd		  = CreateConVarHook("hit_feedback_si_kill_sound_enable", "1", "Enable kill sound for SI (Special Infected).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);

	g_hCvEnableCIKillOverlay	  = CreateConVarHook("hit_feedback_ci_kill_overlay_enable", "1", "Enable kill overlays for CI (Common Infected).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvEnableCIHitOverlay		  = CreateConVarHook("hit_feedback_ci_hit_overlay_enable;", "1", "Enable hit overlays for CI (Common Infected).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvEnableCIHitSnd			  = CreateConVarHook("hit_feedback_ci_hit_sound_enable", "1", "Enable hit sound for CI (Common Infected).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvEnableCIKillSnd		  = CreateConVarHook("hit_feedback_ci_kill_sound_enable", "1", "Enable kill sound for CI (Common Infected).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);

	g_hCvEnableBlast			  = CreateConVarHook("hit_feedback_blast_enable", "0", "Enable overlay when getting blast damage by attacker.", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvEnableFire				  = CreateConVarHook("hit_feedback_fire_enable", "0", "Enable overlay when getting fire damage by attacker.", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvEnableMelee			  = CreateConVarHook("hit_feedback_melee_enable", "1", "Enable overlay when using melee weapon to hit or kill.", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);

	g_hCvHideSprite				  = CreateConVarHook("hit_feedback_hide_sprite", "0", "Hide sprite (Damage number).", FCVAR_NONE, true, 0.0, true, 1.0, OnCvarChanged_BoolValue);
	g_hCvCustomModelVMT			  = CreateConVarHook("hit_feedback_custom_model_vmt", "models/weapons/v_models/v_models_cig.vmt", "Custom model VMT path.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);
	g_hCvCustomModelVTF			  = CreateConVarHook("hit_feedback_custom_model_vtf", "models/weapons/v_models/v_models_cig.vtf", "Custom model VTF path.", FCVAR_NONE, _, _, _, _, OnCvarChanged_StringValue);
	g_hCvSpriteScale			  = CreateConVarHook("hit_feedback_alive_scale", "0.25", "Scale of sprite (increases both height and width).\nNote: Some range values maintain the same size. (e.g. from 0.0 to 0.38 the size doesn't change).", FCVAR_NONE, true, 0.0, false, _, OnCvarChanged_StringValue);
	g_hCvFadeDistance			  = CreateConVarHook("hit_feedback_fade_distance", "-1", "Minimum distance that a client must be from another client to see the sprite. -1 = Always visiable", FCVAR_NONE, true, -1.0, false, _, OnCvarChanged_StringValue);
}

void RegCookies()
{
	g_hCookie = RegClientCookie("hm_style", "", CookieAccess_Protected);
}

void RegCommands()
{
	RegConsoleCmd("sm_hitmarker", Command_HM);
}

void HookEvents()
{
	HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
	HookEvent("infected_death", Event_InfectedDeath, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	// HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
	HookEvent("player_incapacitated", Event_PlayerIncap, EventHookMode_Post);
}

void OnCvarChanged_BoolValue(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCvEnableSound		 = g_hCvEnableSound.BoolValue;

	g_bCvEnableSIKillOverlay = g_hCvEnableSIKillOverlay.BoolValue;
	g_bCvEnableSIHitOverlay	 = g_hCvEnableSIHitOverlay.BoolValue;
	g_bCvEnableSIHitSnd		 = g_hCvEnableSIHitSnd.BoolValue;
	g_bCvEnableSIKillSnd	 = g_hCvEnableSIKillSnd.BoolValue;

	g_bCvEnableCIKillOverlay = g_hCvEnableCIKillOverlay.BoolValue;
	g_bCvEnableCIHitOverlay	 = g_hCvEnableCIHitOverlay.BoolValue;
	g_bCvEnableCIHitSnd		 = g_hCvEnableCIHitSnd.BoolValue;
	g_bCvEnableCIKillSnd	 = g_hCvEnableCIKillSnd.BoolValue;

	g_bCvEnableBlast		 = g_hCvEnableBlast.BoolValue;
	g_bCvEnableFire			 = g_hCvEnableFire.BoolValue;
	g_bCvEnableMelee		 = g_hCvEnableMelee.BoolValue;

	g_bCvHideSprite			 = g_hCvHideSprite.BoolValue;
}

void OnCvarChanged_FloatValue(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTimeForKillMarker = g_hCvTimeForKillMarker.FloatValue;
	g_flTimeForHitMarker  = g_hCvTimeForHitMarker.FloatValue;
}

void OnCvarChanged_StringValue(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_hCvSoundPathHeadShot.GetString(g_sSoundHeadShot, sizeof(g_sSoundHeadShot));
	g_hCvSoundPathHeadShotDefualt.GetString(g_sSoundHeadShotDefualt, sizeof(g_sSoundHeadShotDefualt));
	g_hCvSoundPathBodyHit.GetString(g_sSoundBodyHit, sizeof(g_sSoundBodyHit));
	g_hCvSoundPathBodyHitDefualt.GetString(g_sSoundBodyHitDefualt, sizeof(g_sSoundBodyHitDefualt));
	g_hCvSoundPathKill.GetString(g_sSoundKill, sizeof(g_sSoundKill));
	g_hCvSoundPathKillDefualt.GetString(g_sSoundKillDefualt, sizeof(g_sSoundKillDefualt));

	g_hCvOverlayPathHeadShot.GetString(g_sOverlayHeadShot, sizeof(g_sOverlayHeadShot));
	g_hCvOverlayPathBodyHit.GetString(g_sOverlayBodyHit, sizeof(g_sOverlayBodyHit));
	g_hCvOverlayPathKill.GetString(g_sOverlayKill, sizeof(g_sOverlayKill));

	g_hCvSpriteScale.GetString(g_sSpriteScale, sizeof(g_sSpriteScale));
	g_hCvFadeDistance.GetString(g_sDadeDistance, sizeof(g_sDadeDistance));
	g_hCvCustomModelVMT.GetString(g_sCustomModelVMT, sizeof(g_sCustomModelVMT));
	g_hCvCustomModelVTF.GetString(g_sCustomModelVTF, sizeof(g_sCustomModelVTF));
}