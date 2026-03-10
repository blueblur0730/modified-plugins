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
    if (g_hCvar_RepPop.BoolValue)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;

        CPrintToChatAll("%t %t", "Tag+", "Popped", attacker, victim);
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
    if (g_hCvar_RepLevel.BoolValue)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;
        
        CPrintToChatAll("%t %t", "Tag+++", "Leveled", attacker, victim);
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
    if (g_hCvar_RepHurtLevel.BoolValue)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;
        
        CPrintToChatAll("%t %t", "Tag+++", "LeveledHurt", attacker, victim, damage);
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
    if (g_hCvar_RepDeadStop.BoolValue)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;

        CPrintToChatAll("%t %t", "Tag+", "Deadstopped", attacker, victim);
    }

    Call_StartForward(g_hForwardHunterDeadstop);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_Finish();
}

void HandleShove(int attacker, int victim, int zombieClass)
{
    // report?
    if (g_hCvar_RepShove.BoolValue)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;

        CPrintToChatAll("%t %t", "Tag+", "Shoved", attacker, victim);
    }

    Call_StartForward(g_hForwardSIShove);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushCell(zombieClass);
    Call_Finish();
}

// real skeet
void HandleSkeet(int attacker, int victim, bool bMelee = false, bool bSniper = false, bool bGL = false, bool bTeamSkeeted = false)
{
    // report?
    if (g_hCvar_RepSkeet.BoolValue)
    {
        if (bTeamSkeeted)
        {
            char szBuffer[256], szTemp[128], sPlural[8];
            for (int i = 1; i < MaxClients; i++)
            {
                if (!IsClientInGame(i) || IsFakeClient(i))
                    continue;

                int iArr[L4D2_MAXPLAYERS + 1][3];
                g_Hunter[victim].SortSkeetDmg(iArr);

                int count = 0;
                for (int j = 1; j < L4D2_MAXPLAYERS; j++)
                {
                    int index = iArr[j][0];
                    int damage = iArr[j][1];
                    int shotsFired = iArr[j][2];

                    //PrintToServer("index: %d, damage: %d, shotsFired: %d", index, damage, shotsFired);
                    if (!IsValidEdict(index) || damage <= 0 || index == attacker)
                        continue;

                    count++;
                    if (count > 2)
                        break;
                    
                    count == 1 ?
                    Format(szTemp, sizeof(szTemp), "%T", "AssisterString", j, index, shotsFired, damage) :
                    Format(szTemp, sizeof(szTemp), ", %T", "AssisterString", j, index, shotsFired, damage);
                    StrCat(szBuffer, sizeof(szBuffer), szTemp);
                }

                Format(sPlural, sizeof(sPlural), "%T", "Plural", i);
                CPrintToChat(i, "%t %t", "Tag+", "TeamSkeeted", 
                            victim, attacker, 
                            g_Hunter[victim].m_iShotsFired[attacker],
                            g_Hunter[victim].m_iDamage[attacker], 
                            g_Hunter[victim].m_iShotsFired[attacker] > 1 ? sPlural : ""
                        );

                CPrintToChat(i, "%t %t", "Tag+", "Assisters", szBuffer);
            }
        }
        else if (bMelee)
        {
			CPrintToChatAll("%t %t", "Tag+++", "SkeetedMelee", attacker, victim);
        }
        else if (bSniper)
        {
            char sBuffer[8];
            for (int i = 1; i < MaxClients; i++)
            {
                if (!IsClientInGame(i) || IsFakeClient(i))
                    continue;
                
                Format(sBuffer, sizeof(sBuffer), "%T", "Plural", i);
                CPrintToChat(i, "%t %t", "Tag++", "SkeetedSniper", attacker, victim, g_Hunter[victim].m_iShotsFired[attacker], g_Hunter[victim].m_iShotsFired[attacker] > 1 ? sBuffer : "");
            }
        }
		else if (bGL)
		{
			CPrintToChatAll("%t %t", "Tag++++", "SkeetedGL", attacker, victim);
		}
		else
		{
            char sBuffer[8];
            for (int i = 1; i < MaxClients; i++)
            {
                if (!IsClientInGame(i) || IsFakeClient(i))
                    continue;

                Format(sBuffer, sizeof(sBuffer), "%T", "Plural", i);
                CPrintToChat(i, "%t %t", "Tag+", "Skeeted", attacker, victim, g_Hunter[victim].m_iShotsFired[attacker], g_Hunter[victim].m_iShotsFired[attacker] > 1 ? sBuffer : "");
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

void HandleJockeySkeet(int attacker, int victim, bool bMelee = false, bool bSniper = false, bool bGL = false, bool bTeamSkeeted = false)
{
    // report?
    if (g_hCvar_RepJockeySkeet.BoolValue)
    {
        if (bTeamSkeeted)
        {
            char szBuffer[256], szTemp[128], sPlural[8];
            for (int i = 1; i < MaxClients; i++)
            {
                if (!IsClientInGame(i) || IsFakeClient(i))
                    continue;

                int iArr[L4D2_MAXPLAYERS + 1][3];
                g_Jockey[victim].SortSkeetDmg(iArr);

                int count = 0;
                for (int j = 1; j < L4D2_MAXPLAYERS; j++)
                {
                    int index = iArr[j][0];
                    int damage = iArr[j][1];
                    int shotsFired = iArr[j][2];

                    //PrintToServer("index: %d, damage: %d, shotsFired: %d", index, damage, shotsFired);
                    if (!IsValidEdict(index) || damage <= 0 || index == attacker)
                        continue;

                    count++;
                    if (count > 2)
                        break;

                    count == 1 ?
                    Format(szTemp, sizeof(szTemp), "%T", "AssisterString", j, index, shotsFired, damage) :
                    Format(szTemp, sizeof(szTemp), ", %T", "AssisterString", j, index, shotsFired, damage);
                    StrCat(szBuffer, sizeof(szBuffer), szTemp);
                }

                Format(sPlural, sizeof(sPlural), "%T", "Plural", i);
                CPrintToChat(i, "%t %t", "Tag+", "TeamSkeeted", 
                            victim, attacker, 
                            g_Jockey[victim].m_iShotsFired[attacker],
                            g_Jockey[victim].m_iDamage[attacker], 
                            g_Jockey[victim].m_iShotsFired[attacker] > 1 ? sPlural : ""
                        );

                CPrintToChat(i, "%t %t", "Tag+", "Assisters", szBuffer);
            }
        }
        else if (bMelee)
        {
			CPrintToChatAll("%t %t", "Tag+++", "SkeetedMelee", attacker, victim);
        }
        else if (bSniper)
        {
            char sBuffer[8];
            for (int i = 1; i < MaxClients; i++)
            {
                if (!IsClientInGame(i) || IsFakeClient(i))
                    continue;

                Format(sBuffer, sizeof(sBuffer), "%T", "Plural", i);
                CPrintToChat(i, "%t %t", "Tag++", "SkeetedSniper", attacker, victim, g_Jockey[victim].m_iShotsFired[attacker], g_Jockey[victim].m_iShotsFired[attacker] > 1 ? sBuffer : "");
            }
        }
		else if (bGL)
		{
			CPrintToChatAll("%t %t", "Tag++++", "SkeetedGL", attacker, victim);
		}
		else
		{
            char sBuffer[8];
            for (int i = 1; i < MaxClients; i++)
            {
                if (!IsClientInGame(i) || IsFakeClient(i))
                    continue;
                
                Format(sBuffer, sizeof(sBuffer), "%T", "Plural", i);
                CPrintToChat(i, "%t %t", "Tag+", "Skeeted", attacker, victim, g_Jockey[victim].m_iShotsFired[attacker], g_Jockey[victim].m_iShotsFired[attacker] > 1 ? sBuffer : "");
            }
		}
    }

    // call forward
    Call_StartForward(g_hForwardJockeySkeet);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushCell(bMelee);
    Call_PushCell(bSniper);
    Call_PushCell(bGL);
    Call_Finish();
}

// crown
void HandleCrown(int attacker)
{
    // report?
    if (g_hCvar_RepCrow.BoolValue)
    {
        if (!IsValidClientInGame(attacker))
            return;

        CPrintToChatAll("%t %t", "Tag++", "CrownedWitch", attacker);
    }

    // call forward
    Call_StartForward(g_hForwardCrown);
    Call_PushCell(attacker);
    Call_Finish();
}
// drawcrown
void HandleDrawCrown(int attacker)
{
    if (g_hCvar_RepDrawCrow.BoolValue)
    {
        if (!IsValidClientInGame(attacker)) 
            return;

        CPrintToChatAll("%t %t", "Tag++", "DrawCrowned", attacker);
    }

    // call forward
    Call_StartForward(g_hForwardDrawCrown);
    Call_PushCell(attacker);
    Call_Finish();
}

// smoker clears
void HandleTongueCut(int attacker, int victim)
{
    if (g_hCvar_RepTongueCut.BoolValue)
    {
        if (!IsValidClientInGame(victim) || !IsValidClientInGame(attacker))
            return;

        CPrintToChatAll("%t %t", "Tag+++", "CutTongue", attacker, victim);
    }

    // call forward
    Call_StartForward(g_hForwardTongueCut);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_Finish();
}

void HandleSmokerSelfClear(int attacker, int victim, bool withShove = false)
{
    if (g_hCvar_RepSelfClear.BoolValue && (!withShove ||g_hCvar_RepSelfClearShove.BoolValue))
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;

        char sBuffer[32];
        for (int i = 1; i < MaxClients; i++)
        {
            if (!IsClientInGame(i) || IsFakeClient(i))
                continue;

            Format(sBuffer, sizeof(sBuffer), "%T", "Shoving", i);
            CPrintToChat(i, "%t %t", "Tag++", "SelfClearedTongue", attacker, victim, (withShove) ? sBuffer : "");
        }
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

void HandleRockSkeeted(int attacker, int victim, int damage)
{
    if (g_hCvar_RepRockSkeet.BoolValue)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;

        CPrintToChatAll("%t %t", "Tag+", "SkeetedRock", attacker, victim);

    }

    Call_StartForward(g_hForwardRockSkeeted);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushCell(damage);
    Call_Finish();
}

// highpounces
void HandleHunterDP(int attacker, int victim, int actualDamage, float calculatedDamage, float height, bool playerIncapped = false)
{
    // report?
    if (g_hCvar_RepHunterDP.BoolValue && !playerIncapped)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;

        CPrintToChatAll("%t %t", "Tag++", "HunterHP", attacker, victim, RoundFloat(calculatedDamage), RoundFloat(height));
    }

    Call_StartForward(g_hForwardHunterDP);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushCell(actualDamage);
    Call_PushFloat(calculatedDamage);
    Call_PushFloat(height);
    Call_PushCell(playerIncapped);
    Call_Finish();
}
void HandleJockeyDP(int attacker, int victim, float height)
{
    // report?
    if (g_hCvar_RepJockeyDP.BoolValue && height >= g_hCvar_JockeyDPThresh.FloatValue)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;

        CPrintToChatAll("%t %t", "Tag+++", "JockeyHP", attacker, victim, RoundFloat(height));
    }

    Call_StartForward(g_hForwardJockeyDP);
    Call_PushCell(victim);
    Call_PushCell(attacker);
    Call_PushFloat(height);
    Call_PushCell((height >= g_hCvar_JockeyDPThresh.FloatValue) ? 1 : 0);
    Call_Finish();
}

// deathcharges
void HandleDeathCharge(int attacker, int victim, float height, float distance, int assister = -1, bool bCarried = true)
{
    // report?
    if (g_hCvar_RepDeathCharge.BoolValue && height >= g_hCvar_DeathChargeHeight.FloatValue)
    {
        if (bCarried)
        {
            if (height < g_hCvar_DeathChargeHeight.FloatValue)
                return;
        }
        else
        {
            if (height < g_hCvar_DeathChargeHeightBlow.FloatValue)
                return;
        }

        char szBuffer[64], szAssister[64];
        for (int i = 1; i < MaxClients; i++)
        {
            if (!IsClientInGame(i) || IsFakeClient(i))
                continue;

            Format(szBuffer, sizeof(szBuffer), "%T", "Bowling", i);

            if (assister > 0)
                Format(szAssister, sizeof(szAssister), ", %T", "DeathChargeAssister", i, assister);
            
            CPrintToChat(i, "%t %t", "Tag++++", "DeathCharged", attacker, victim, (bCarried) ? "" : szBuffer, RoundFloat(height), assister > 0 ? szAssister : "");
        }

    }

    Call_StartForward(g_hForwardDeathCharge);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushFloat(height);
    Call_PushFloat(distance);
    Call_PushCell((bCarried) ? 1 : 0);
    Call_PushCell(assister);
    Call_Finish();
}

void HandleChargingSkeet(int attacker, int victim, float flTime, bool bTeamSkeeted = false)
{
    if (g_hCvar_RepChargingSkeet.BoolValue)
    {
        if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
            return;

        if (bTeamSkeeted)
        {
            for (int i = 1; i < MaxClients; i++)
            {
                if (!IsClientInGame(i) || IsFakeClient(i))
                    continue;

                if (!IsClientInGame(i) || IsFakeClient(i))
                    continue;

                int iArr[L4D2_MAXPLAYERS + 1][3];
                g_Charger[victim].SortSkeetDmg(iArr);

                int count = 0;
                char szBuffer[256];
                for (int j = 1; j < L4D2_MAXPLAYERS; j++)
                {
                    int index = iArr[j][0];
                    int damage = iArr[j][1];
                    int shotsFired = iArr[j][2];

                    //PrintToServer("index: %d, damage: %d, shotsFired: %d", index, damage, shotsFired);
                    if (!IsValidEdict(index) || damage <= 0 || index == attacker)
                        continue;

                    count++;
                    if (count > 2)
                        break;

                    char szTemp[128];
                    count == 1 ?
                    Format(szTemp, sizeof(szTemp), "%T", "AssisterString", j, index, shotsFired, damage) :
                    Format(szTemp, sizeof(szTemp), ", %T", "AssisterString", j, index, shotsFired, damage);
                    StrCat(szBuffer, sizeof(szBuffer), szTemp);
                }

                char sBuffer[8];
                Format(sBuffer, sizeof(sBuffer), "%T", "Plural", i);
                CPrintToChat(i, "%t %t", "Tag+", "TeamChargingSkeeted", 
                            victim, attacker, 
                            g_Charger[victim].m_iShotsFired[attacker],
                            g_Charger[victim].m_iDamage[attacker], 
                            flTime,
                            g_Charger[victim].m_iShotsFired[attacker] > 1 ? sBuffer : "");

                CPrintToChat(i, "%t %t", "Tag+", "Assisters", szBuffer);
            }
        }
        else
        {
            CPrintToChatAll("%t %t", "Tag+", "ChargingSkeeted", attacker, victim, flTime);
        }
    }

    // call forward
    Call_StartForward(g_hForwardChargingSkeet);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushFloat(flTime);
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

    if (g_hCvar_RepInstanClear.IntValue && attacker != pinVictim)
    {
        float fMinTime = g_hCvar_InstaTime.FloatValue;
        float fClearTime = clearTimeA;
        if (zombieClass == ZC_CHARGER || zombieClass == ZC_SMOKER) { fClearTime = clearTimeB; }

        if (fClearTime != -1.0 && fClearTime <= fMinTime)
        {
            if (!IsValidClientInGame(attacker) || !IsValidClientInGame(victim))
                return;
            
            if (IsValidClientInGame(pinVictim))
            {
                CPrintToChatAll("%t %t", "Tag+", "SIClear", attacker, pinVictim, victim, g_csSIClassName[zombieClass], fClearTime);
            }
            else
            {
                CPrintToChatAll("%t %t", "Tag+", "SIClearTeammate", attacker, victim, g_csSIClassName[zombieClass], fClearTime);
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
    if (g_hCvar_RepVomitLanded.BoolValue)
    {
        CPrintToChatAll("%t %t", "Tag+", "VomitLanded", attacker, boomCount);
    }

    Call_StartForward(g_hForwardVomitLanded);
    Call_PushCell(attacker);
    Call_PushCell(boomCount);
    Call_Finish();
}

// bhaps
void HandleBHopStreak(int survivor, int streak, float maxVelocity)
{
    if (g_hCvar_RepBhopStreak.BoolValue && IsValidClientInGame(survivor) && !IsFakeClient(survivor) && streak >= g_hCvar_BHopMinStreak.IntValue)
    {
        char sBuffer[64];
        Format(sBuffer, sizeof(sBuffer), "%T", "Plural", survivor);
        CPrintToChat(survivor, "%t %t", "Tag+", "BunnyHop", streak, (streak > 1) ? sBuffer : "", maxVelocity);
    }

    Call_StartForward(g_hForwardBHopStreak);
    Call_PushCell(survivor);
    Call_PushCell(streak);
    Call_PushFloat(maxVelocity);
    Call_Finish();
}

// car alarms
void HandleCarAlarmTriggered(int survivor, int infected, CarAlarmReason_t reason)
{
    if (g_hCvar_RepCarAlarm.BoolValue && IsValidClientInGame(survivor))
    {
        if (reason == CALARM_HIT)
        {
            CPrintToChatAll("%t %t", "Tag+", "CarAlarmHit", survivor);
        }
        else if (reason == CALARM_TOUCHED)
        {
            // if a survivor touches an alarmed car, it might be due to a special infected...
            if (IsValidInfected(infected))
            {
                CPrintToChatAll("%t %t", "Tag+", "CarAlarmTouched", infected, survivor);
            }
            else
            {
                CPrintToChatAll("%t %t", "Tag+", "CarAlarmTouchedSelf", survivor);
            }
        }
        else if (reason == CALARM_EXPLOSION)
        {
            CPrintToChatAll("%t %t", "Tag+", "CarAlarmExplosion", survivor);
        }
        else if (reason == CALARM_BOOMER)
        {
            if (IsValidInfected(infected))
            {
                CPrintToChatAll("%t %t", "Tag+", "CarAlarmBoomer", survivor, infected);
            }
        }
        else
        {
            CPrintToChatAll("%t %t", "Tag+", "CarAlarm", survivor);
        }
    }

    Call_StartForward(g_hForwardAlarmTriggered);
    Call_PushCell(survivor);
    Call_PushCell(infected);
    Call_PushCell(reason);
    Call_Finish();
}

void HandleMultiImpact(int attacker, int numImpacts)
{
    if (g_hCvar_RepNumImpacts.BoolValue)
    {
        char sTag[8];
        if (numImpacts == 1)
        {
            strcopy(sTag, sizeof(sTag), "Tag+");
        }
        else if (numImpacts == 2)
        {
            strcopy(sTag, sizeof(sTag), "Tag++");
        }
        else if (numImpacts == 3)
        {
            strcopy(sTag, sizeof(sTag), "Tag+++");
        }
        else if (numImpacts >= 4)
        {   
            strcopy(sTag, sizeof(sTag), "Tag++++");
        }   
        
        CPrintToChatAll("%t %t", sTag, "MultipleImpacts", attacker, numImpacts);
    }

    Call_StartForward(g_hForwardNumImpacts);
    Call_PushCell(attacker);
    Call_PushCell(numImpacts);
    Call_Finish();
}

void HandlePopStagger(int attacker, int victim, int count, int staggerSurvivor[L4D2_MAXPLAYERS + 1], bool isStaggering)
{
    if (g_hCvar_RepPopStagger.BoolValue)
    {
        char szBuffer[128];
        for (int i = 1; i < MaxClients; i++)
        {
            if (!IsClientInGame(i) || IsFakeClient(i))
                continue;

            Format(szBuffer, sizeof(szBuffer), "%T", "Staggered", i);
            CPrintToChat(i, "%t %t", "Tag+", "PopStagger", attacker, victim, count, isStaggering ? szBuffer : "");
        }
    }

    Call_StartForward(g_hForwardPopStagger);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushCell(count);
    Call_PushArray(staggerSurvivor, L4D2_MAXPLAYERS + 1);
    Call_Finish();
}