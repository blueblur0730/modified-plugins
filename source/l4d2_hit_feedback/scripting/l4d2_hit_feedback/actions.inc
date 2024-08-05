#if defined _l4d2_hit_feedback_actions_included
	#endinput
#endif
#define _l4d2_hit_feedback_actions_included

// you shouldn't be on the screen for too long!
void ManageTimer(float time, int attacker)
{
	if (g_hTimerClean[attacker] != null)
		delete g_hTimerClean[attacker];

	g_hTimerClean[attacker] = CreateTimer(time, Timer_Remove, attacker);
}

Action Timer_Remove(Handle Timer, int client)
{
	KillTimer(Timer);
	int iFlags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"\"");
	SetCommandFlags("r_screenoverlay", iFlags);	   // do not spoiler this.

	return Plugin_Handled;
}

void ShowKillMessage(int client, int type)
{
	int iFlags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);

	switch (type)
	{
		case (kill_1): ClientCommand(client, "r_screenoverlay \"%s\"", g_sOverlayHeadShot);
		case (kill): ClientCommand(client, "r_screenoverlay \"%s\"", g_sOverlayKill);
		case (hit_armor): ClientCommand(client, "r_screenoverlay \"%s\"", g_sOverlayBodyHit);
	}

	SetCommandFlags("r_screenoverlay", iFlags);	   // do not spoiler this.
}

// Credit to Mart from plugin "[L4D1 & L4D2] HP Sprite"
void OnCITakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
	if (!IsCommonInfected(victim) || !IsSurvivor(attacker) || damage <= 0.0)
		return;

	char targetname[17];
	FormatEx(targetname, sizeof(targetname), "%s-%02i", "l4d2_hit_feedback", victim);

	int entity = INVALID_ENT_REFERENCE;

	if (g_iSpriteEntRef[victim] != INVALID_ENT_REFERENCE)
		entity = EntRefToEntIndex(g_iSpriteEntRef[victim]);

	if (entity == INVALID_ENT_REFERENCE)
	{
		float targetPos[3]		= GetEntityOrigin(victim);

		entity					= CreateEntityByName("env_sprite");
		g_iSpriteEntRef[victim] = EntIndexToEntRef(entity);
		g_iOwner[entity]		= victim;		// this tells that this env_sprite is bound to this CI.
		g_iRelation[entity]		= attacker;		// this tells that this env_sprite is created by the attacker
		DispatchKeyValue(entity, "targetname", targetname);
		DispatchKeyValue(entity, "spawnflags", "1");
		DispatchKeyValueVector(entity, "origin", targetPos);

		// Hooking the entity transmission. For those undesired clients, we wont let the sprite show to them.
		SDKHook(entity, SDKHook_SetTransmit, OnSetTransmit);
	}

	//if (g_bHideSprite[attacker])
		//AcceptEntityInput(entity, "HideSprite");

	DispatchKeyValue(entity, "model", g_sCustomModelVMT);
	DispatchKeyValue(entity, "rendercolor", "255 255 255");	   // since we dont have colored shileds, we can use the same color for both
	DispatchKeyValue(entity, "renderamt", "0");				   // If renderamt goes before rendercolor, it doesn't render
	DispatchKeyValue(entity, "renderfx", "6");				   // 6: Fast Fade Away (decreases alpha by -4 per frame/(in all games since L4D) Fades out over 1 s)
	DispatchKeyValue(entity, "scale", g_sSpriteScale);
	DispatchKeyValue(entity, "fademindist", g_sFadeDistance);
	DispatchSpawn(entity);

	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", victim);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", victim);
	AcceptEntityInput(entity, "ShowSprite");

	int entityFrame = INVALID_ENT_REFERENCE;

	if (g_iSpriteFrameEntRef[victim] != INVALID_ENT_REFERENCE)
		entityFrame = EntRefToEntIndex(g_iSpriteFrameEntRef[victim]);

	// animated sprite. it changes sprite texture per frame.
	if (entityFrame == INVALID_ENT_REFERENCE)
	{
		entityFrame					 = CreateEntityByName("env_texturetoggle");
		g_iSpriteFrameEntRef[victim] = EntIndexToEntRef(entityFrame);
		DispatchKeyValue(entityFrame, "targetname", targetname);
		DispatchKeyValue(entityFrame, "target", targetname);
		DispatchSpawn(entityFrame);

		SetVariantString("!activator");
		AcceptEntityInput(entityFrame, "SetParent", entity);
	}

	int	 frame = RoundFloat(damage);

	char input[38];
	FormatEx(input, sizeof(input), "OnUser1 !self:SetTextureIndex:%i:0:1", frame);
	SetVariantString(input);
	AcceptEntityInput(entityFrame, "AddOutput");
	AcceptEntityInput(entityFrame, "FireUser1");
}

Action OnSetTransmit(int client, int entity)
{
	// bots are not interested with the sprite !
	if (IsFakeClient(client))
		return Plugin_Handled;

	// if the target client of transmission is not the attacker, block the transmission to this client.
	if (client != g_iRelation[entity])
		return Plugin_Handled;

	// if the attacker choose to hide the sprite, then do nothing.
	if (g_bHideSprite[client])
		return Plugin_Handled;

	return Plugin_Continue;
}