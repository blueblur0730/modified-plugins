#if defined _skill_detect_reporting_included
    #endinput
#endif
#define _skill_detect_reporting_included

static const char g_csSIClassName[][] = {
	"none",
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"witch",
	"tank"
};

// boomer pop
void HandlePop(int attacker, int victim, int shoveCount, float timeAlive)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepPop.BoolValue)
	{
		if (!IsValidClientInGame(attacker))
			return;

		(IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
		CPrintToChatAll("%t %t", "Tag+", "Popped", attacker, victim) :
		CPrintToChatAll("%t %t", "Tag+", "PoppedBot", attacker);
	}

	Call_StartForward(g_hForwardBoomerPop);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(shoveCount);
	Call_PushFloat(timeAlive);
	Call_Finish();
}

// charger level
void HandleLevel(int attacker, int victim)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepLevel.BoolValue)
	{
		if (!IsValidClientInGame(attacker))
			return;
		
		(IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
		CPrintToChatAll("%t %t", "Tag+++", "Leveled", attacker, victim) :
		CPrintToChatAll("%t %t", "Tag+++", "LeveledBot", attacker);
	}

	// call forward
	Call_StartForward(g_hForwardLevel);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}
// charger level hurt
void HandleLevelHurt(int attacker, int victim, int damage)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepHurtLevel.BoolValue)
	{
		if (!IsValidClientInGame(attacker))
			return;
		
		(IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
		CPrintToChatAll("%t %t", "Tag+++", "LeveledHurt", attacker, victim, damage) :
		CPrintToChatAll("%t %t", "Tag+++", "LeveledHurtBot", attacker, damage);
	}

	// call forward
	Call_StartForward(g_hForwardLevelHurt);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(damage);
	Call_Finish();
}

// deadstops
void HandleDeadstop(int attacker, int victim)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepDeadStop.BoolValue)
	{
		if (!IsValidClientInGame(attacker))
			return;

		(IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
		CPrintToChatAll("%t %t", "Tag+", "Deadstopped", attacker, victim) :
		CPrintToChatAll("%t %t", "Tag+", "DeadstoppedBot", attacker);
	}

	Call_StartForward(g_hForwardHunterDeadstop);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}

void HandleShove(int attacker, int victim, int zombieClass)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepShove.BoolValue)
	{
		if (!IsValidClientInGame(attacker))
			return;

		(IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
		CPrintToChatAll("%t %t", "Tag+", "Shoved", attacker, victim) :
		CPrintToChatAll("%t %t", "Tag+", "ShovedBot", attacker);
	}

	Call_StartForward(g_hForwardSIShove);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(zombieClass);
	Call_Finish();
}

// real skeet
void HandleSkeet(int attacker, int victim, bool bMelee = false, bool bSniper = false, bool bGL = false)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepSkeet.BoolValue)
	{
		if (attacker == -2)
		{
			// team skeet sets to -2
			(IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
			CPrintToChatAll("%t %t", "Tag+", "TeamSkeeted", victim) :
			CPrintToChatAll("%t %t", "Tag+", "TeamSkeetedBot");
		}
		else if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsFakeClient(i))
					continue;
				
				CPrintToChat(i, "%t %t", "Tag+", "Skeeted", attacker, (bMelee) ? Melee(i) : ((bSniper) ? Headshot(i) : ((bGL) ? Grenade(i) : "")), victim);
			}
		}
		else if (IsValidClientInGame(attacker))
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsFakeClient(i))
					continue;

				CPrintToChat(i, "%t %t", "Tag+", "SkeetedBot", attacker, (bMelee) ? Melee(i) : ((bSniper) ? Headshot(i) : ((bGL) ? Grenade(i) : "")));
			}
		}
	}

	// call forward
	Call_StartForward(g_hForwardSkeet);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(bMelee);
	Call_PushCell(bSniper);
	Call_PushCell(bGL);
	Call_Finish();
}

// hurt skeet / non-skeet
//  NOTE: bSniper not set yet, do this
void HandleNonSkeet(int attacker, int victim, int damage, bool bOverKill = false, bool bMelee = false, bool bSniper = false)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepHurtSkeet.BoolValue)
	{
		(IsValidClientInGame(victim)) ?
		CPrintToChatAll("%t %t", "Tag+", "HurtSkeet", victim, damage, (bOverKill) ? "Unchipped" : "") :
		CPrintToChatAll("%t %t", "Tag+", "HurtSkeetBot", damage, (bOverKill) ? "Unchipped" : "");

		for (int i = 1; i < MaxClients; i++)
		{
			static char buffer[64];
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;

			Format(buffer, sizeof(buffer), "%T", "Unchipped", i);
			IsValidClientInGame(victim) ?
			CPrintToChat(i, "%t %t", "Tag+", "HurtSkeet", victim, damage, (bOverKill) ? buffer : "") :
			CPrintToChat(i, "%t %t", "Tag+", "HurtSkeetBot", damage, (bOverKill) ? buffer : "");
		}

	}

	// call forward
	Call_StartForward(g_hForwardSkeetHurt);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(damage);
	Call_PushCell(bOverKill);
	Call_PushCell(bMelee);
	Call_PushCell(bSniper);
	Call_Finish();
}

// crown
void HandleCrown(int attacker)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepCrow.BoolValue)
	{
		(IsValidClientInGame(attacker)) ?
		CPrintToChatAll("%t %t", "Tag++", "CrownedWitch", attacker) :
		CPrintToChatAll("%t", "CrownedWitch2");
	}

	// call forward
	Call_StartForward(g_hForwardCrown);
	Call_PushCell(attacker);
	Call_Finish();
}
// drawcrown
void HandleDrawCrown(int attacker)
{
	if (g_hCvar_Report.BoolValue && g_hCvar_RepDrawCrow.BoolValue)
	{
		(IsValidClientInGame(attacker)) ?
		CPrintToChatAll("%t %t", "Tag++", "DrawCrowned", attacker) :
		CPrintToChatAll("%t %t", "DrawCrowned2");
	}

	// call forward
	Call_StartForward(g_hForwardDrawCrown);
	Call_PushCell(attacker);
	Call_Finish();
}

// smoker clears
void HandleTongueCut(int attacker, int victim)
{
	if (g_hCvar_Report.BoolValue && g_hCvar_RepTongueCut.BoolValue)
	{
		if (!IsValidClientInGame(victim))
			return;

		(IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
		CPrintToChatAll("%t %t", "Tag+++", "CutTongue", attacker, victim) :
		CPrintToChatAll("%t %t", "Tag+++", "CutTongueBot", attacker);
	}

	// call forward
	Call_StartForward(g_hForwardTongueCut);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}

void HandleSmokerSelfClear(int attacker, int victim, bool withShove = false)
{
	if (g_hCvar_Report.BoolValue && g_hCvar_RepSelfClear.BoolValue && (!withShove || g_hCvar_RepSelfClearShove.BoolValue))
	{
		if (!IsValidClientInGame(attacker))
			return;

		(IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
		CPrintToChatAll("%t %t", "Tag++", "SelfClearedTongue", attacker, victim, (withShove) ? "Shoving" : "none") :
		CPrintToChatAll("%t %t", "Tag++", "SelfClearedTongueBot", attacker, (withShove) ? "Shoving" : "none");
	}

	// call forward
	Call_StartForward(g_hForwardSmokerSelfClear);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(withShove);
	Call_Finish();
}

// rocks
void HandleRockEaten(int attacker, int victim)
{
	Call_StartForward(g_hForwardRockEaten);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}

void HandleRockSkeeted(int attacker, int victim)
{
	if (g_hCvar_Report.BoolValue && g_hCvar_RepRockSkeet.BoolValue)
	{
		if (!IsValidClientInGame(attacker))
			return;

		(g_hCvar_RepRockName.BoolValue && IsValidClientInGame(victim) && !IsFakeClient(victim)) ?
		CPrintToChatAll("%t %t", "Tag+", "SkeetedRock", attacker, victim) :
		CPrintToChatAll("%t %t", "Tag+", "SkeetedRockBot", attacker);
	}

	Call_StartForward(g_hForwardRockSkeeted);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}

// highpounces
void HandleHunterDP(int attacker, int victim, int actualDamage, float calculatedDamage, float height, bool playerIncapped = false)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepHunterDP.BoolValue && height >= g_hCvar_HunterDPThresh.FloatValue && !playerIncapped)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(attacker))
			CPrintToChatAll("%t %t", "Tag++", "HunterHP", attacker, victim, RoundFloat(calculatedDamage), RoundFloat(height));
		else if (IsValidClientInGame(victim))
			CPrintToChatAll("%t %t", "Tag++", "HunterHPBot", victim, RoundFloat(calculatedDamage), RoundFloat(height));
	}

	Call_StartForward(g_hForwardHunterDP);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(actualDamage);
	Call_PushFloat(calculatedDamage);
	Call_PushFloat(height);
	Call_PushCell((height >= g_hCvar_HunterDPThresh.FloatValue) ? 1 : 0);
	Call_PushCell((playerIncapped) ? 1 : 0);
	Call_Finish();
}
void HandleJockeyDP(int attacker, int victim, float height)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepJockeyDP.BoolValue && height >= g_hCvar_JockeyDPThresh.FloatValue)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(attacker))
			CPrintToChatAll("%t %t", "Tag+++", "JockeyHP", attacker, victim, RoundFloat(height));
		else if (IsValidClientInGame(victim))
			CPrintToChatAll("%t %t", "Tag+++", "JockeyHPBot", victim, RoundFloat(height));
	}

	Call_StartForward(g_hForwardJockeyDP);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushFloat(height);
	Call_PushCell((height >= g_hCvar_JockeyDPThresh.FloatValue) ? 1 : 0);
	Call_Finish();
}

// deathcharges
void HandleDeathCharge(int attacker, int victim, float height, float distance, bool bCarried = true)
{
	// report?
	if (g_hCvar_Report.BoolValue && g_hCvar_RepDeathCharge.BoolValue && height >= g_hCvar_DeathChargeHeight.FloatValue)
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;

			static char Buffer[64];
			Format(Buffer, sizeof(Buffer), "%t", "Bowling", i);
			if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(attacker))
				CPrintToChat(i, "%t %t", "Tag++++", "DeathCharged", attacker, victim, (bCarried) ? "" : Buffer, RoundFloat(height));
			else if (IsValidClientInGame(victim))
				CPrintToChat(i, "%t %t", "Tag++++", "DeathChargedBot", victim, (bCarried) ? "" : Buffer, RoundFloat(height));
		}

	}

	Call_StartForward(g_hForwardDeathCharge);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushFloat(height);
	Call_PushFloat(distance);
	Call_PushCell((bCarried) ? 1 : 0);
	Call_Finish();
}

// SI clears    (cleartimeA = pummel/pounce/ride/choke, cleartimeB = tongue drag, charger carry)
void HandleClear(int attacker, int victim, int pinVictim, int zombieClass, float clearTimeA, float clearTimeB, bool bWithShove = false)
{
	// sanity check:
	if (clearTimeA < 0 && clearTimeA != -1.0)
		clearTimeA = 0.0;

	if (clearTimeB < 0 && clearTimeB != -1.0)
		clearTimeB = 0.0;

	PrintDebug("Clear: %i freed %i from %i: time: %.2f / %.2f -- class: %s (with shove? %i)", attacker, pinVictim, victim, clearTimeA, clearTimeB, g_csSIClassName[zombieClass], bWithShove);

	if (g_hCvar_RepInstanClear.IntValue && attacker != pinVictim)
	{
		float fMinTime	 = g_hCvar_InstaTime.FloatValue;
		float fClearTime = clearTimeA;
		if (zombieClass == ZC_CHARGER || zombieClass == ZC_SMOKER) { fClearTime = clearTimeB; }

		if (fClearTime != -1.0 && fClearTime <= fMinTime)
		{
			if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			{
				if (IsValidClientInGame(pinVictim))
					CPrintToChatAll("%t %t", "Tag+", "SIClear", attacker, pinVictim, victim, g_csSIClassName[zombieClass], fClearTime);
				else
					CPrintToChatAll("%t %t", "Tag+", "SIClearTeammate", attacker, victim, g_csSIClassName[zombieClass], fClearTime);
			}
			else if (IsValidClientInGame(attacker))
			{
				if (IsValidClientInGame(pinVictim))
					CPrintToChatAll("%t %t", "Tag+", "SIClearBot", attacker, pinVictim, g_csSIClassName[zombieClass], fClearTime);
				else
					CPrintToChatAll("%t %t", "Tag+", "SIClearTeammateBot", attacker, g_csSIClassName[zombieClass], fClearTime);
			}
		}
	}

	Call_StartForward(g_hForwardClear);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(pinVictim);
	Call_PushCell(zombieClass);
	Call_PushFloat(clearTimeA);
	Call_PushFloat(clearTimeB);
	Call_PushCell((bWithShove) ? 1 : 0);
	Call_Finish();
}

// booms
void HandleVomitLanded(int attacker, int boomCount)
{
	Call_StartForward(g_hForwardVomitLanded);
	Call_PushCell(attacker);
	Call_PushCell(boomCount);
	Call_Finish();
}

// bhaps
void HandleBHopStreak(int survivor, int streak, float maxVelocity)
{
	if (g_hCvar_RepBhopStreak.BoolValue && IsValidClientInGame(survivor) && !IsFakeClient(survivor) && streak >= g_hCvar_BHopMinStreak.IntValue)
		CPrintToChat(survivor, "%t %t", "Tag+", "BunnyHop", streak, (streak > 1) ? PluralCount(survivor) : "", maxVelocity);

	Call_StartForward(g_hForwardBHopStreak);
	Call_PushCell(survivor);
	Call_PushCell(streak);
	Call_PushFloat(maxVelocity);
	Call_Finish();
}

// car alarms
void HandleCarAlarmTriggered(int survivor, int infected, CarAlarmReason_t reason)
{
	if (g_hCvar_RepCarAlarm.BoolValue && IsValidClientInGame(survivor) && !IsFakeClient(survivor))
	{
		if (reason == CALARM_HIT)
		{
			CPrintToChatAll("%t %t", "Tag+", "CalarmHit", survivor);
		}
		else if (reason == CALARM_TOUCHED)
		{
			// if a survivor touches an alarmed car, it might be due to a special infected...
			if (IsValidInfected(infected))
			{
				if (!IsFakeClient(infected))
				{
					CPrintToChatAll("%t %t", "Tag+", "CalarmTouched", infected, survivor);
				}
				else
				{
					switch (GetEntProp(infected, Prop_Send, "m_zombieClass"))
					{
						case ZC_SMOKER:
							CPrintToChatAll("%t %t", "Tag+", "CalarmTouchedHunter", survivor);

						case ZC_JOCKEY:
							CPrintToChatAll("%t %t", "Tag+", "CalarmTouchedJockey", survivor);

						case ZC_CHARGER:
							CPrintToChatAll("%t %t", "Tag+", survivor);

						default:
							CPrintToChatAll("%t %t", "Tag+", "CalarmTouchedInfected", survivor);
					}
				}
			}
			else
			{
				CPrintToChatAll("%t %t", "Tag+", "CalarmTouchedBot", survivor);
			}
		}
		else if (reason == CALARM_EXPLOSION)
		{
			CPrintToChatAll("%t %t", "Tag+", "CalarmExplosion", survivor);
		}
		else if (reason == CALARM_BOOMER)
		{
			if (IsValidInfected(infected) && !IsFakeClient(infected))
			{
				CPrintToChatAll("%t %t", "Tag+", "CalarmBoomer", survivor, infected);
			}
			else
			{
				CPrintToChatAll("%t %t", "Tag+", "CalarmBoomerBot", survivor);
			}
		}
		else
		{
			CPrintToChatAll("%t %t", "Tag+", "Calarm", survivor);
		}
	}

	Call_StartForward(g_hForwardAlarmTriggered);
	Call_PushCell(survivor);
	Call_PushCell(infected);
	Call_PushCell(reason);
	Call_Finish();
}

char[] Melee(int client)
{
	char sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%T", "Melee", client);
	return sBuffer;
}

char[] Headshot(int client)
{
	char sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%T", "HeadShot", client);
	return sBuffer;
}

char[] Grenade(int client)
{
	char sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%T", "Grenade", client);
	return sBuffer;
}

char[] PluralCount(int client)
{
	char sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%T", "PluralCount", client);
	return sBuffer;
}

