#if defined _skill_detect_tracking_hunter_included
    #endinput
#endif
#define _skill_detect_tracking_hunter_included

enum struct HunterSkillCache_t
{
    // hunters: skeets/pounces
    int m_iTeamDamage;                        // counting shotgun blast damage for hunter, counting entire survivor team's damage
    int m_iShotsFired[L4D2_MAXPLAYERS + 1];   // how many shots the survivor has fired to skeet a hunter.
    int m_iDamage[L4D2_MAXPLAYERS + 1];       // counting shotgun blast damage for hunter / skeeter combo
    int m_iPounceDamage;                      // how much damage on last 'highpounce' done
    Vector m_vecPounceStartPos;               // position that a hunter pounced from
    IntervalTimer_t m_IncapStartTimer;          // timer for when a hunter started incap someone.

    void SortSkeetDmg(int iArr[L4D2_MAXPLAYERS + 1][3])
    {
        for (int i = 1; i < L4D2_MAXPLAYERS; i++)
        {
            iArr[i][0] = i;
            iArr[i][1] = this.m_iDamage[i];
            iArr[i][2] = this.m_iShotsFired[i];
        }

        // Bubble sort in descending order
        int n = L4D2_MAXPLAYERS;
        for (int i = 1; i <= n - 1; i++)
        {
            for (int j = 1; j <= n - i; j++)
            {
                if (iArr[j][1] < iArr[j + 1][1])
                {
                    // Swap the entire row
                    int temp0 = iArr[j][0];
                    int temp1 = iArr[j][1];
                    int temp2 = iArr[j][2];

                    iArr[j][0] = iArr[j + 1][0];
                    iArr[j][1] = iArr[j + 1][1];
                    iArr[j][2] = iArr[j + 1][2];

                    iArr[j + 1][0] = temp0;
                    iArr[j + 1][1] = temp1;
                    iArr[j + 1][2] = temp2;
                }
            }
        }
    }

    void ResetHunter()
    {
        this.m_iTeamDamage = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            this.m_iDamage[i] = 0;
            this.m_iShotsFired[i] = 0;
        }
    }
}
HunterSkillCache_t g_Hunter[L4D2_MAXPLAYERS + 1];

Action HunterLungeAtVictim_OnShoved(any action, int actor, int entity, ActionDesiredResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnShoved called, entity: %d, actor: %d", entity, actor);
    HandleDeadstop(entity, actor);
    g_Hunter[actor].ResetHunter();
    return Plugin_Continue;
}

// after takedamage hook.
Action HunterLungeAtVictim_OnInjured(any action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    // already had a victim, not a skeet.
    if (g_InfectedSkillCache[actor].m_iSpecialVictim)
    {
        g_Hunter[actor].ResetHunter();
        return Plugin_Continue;
    }

    int attacker = info.m_hAttacker;
    //int weapon = info.m_hWeapon;
    int damagetype = info.m_bitsDamageType;
    float damage = info.m_flDamage;
    //int health = GetEntProp(actor, Prop_Data, "m_iHealth");
    //int damagecustom = info.m_iDamageCustom;

    //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnInjured called: attacker: %d, actor: %d, weapon: %d, damage: %.02f, damage type: %d, damage custom: %d, health: %d", attacker, actor, weapon, damage, damagetype, damagecustom, health);

    if (damagetype & DMG_BUCKSHOT)
    {
        if (!g_Survivor[attacker].m_bShotCounted)
        {
            // count this shotgun pellet as once.
            g_Hunter[actor].m_iShotsFired[attacker]++;
            //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnInjured: shotgun pellet, shots fired: %d", g_InfectedSkillCache[actor].m_iShotsFired[attacker]);
            g_Survivor[attacker].m_bShotCounted = true;
        }
    }
    else if (damagetype & DMG_BULLET)
    {
        // just count this into.
        g_Hunter[actor].m_iShotsFired[attacker]++;
        //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnInjured: bullet, shots fired: %d", g_InfectedSkillCache[actor].m_iShotsFired[attacker]);
    }

    g_Hunter[actor].m_iDamage[attacker] += RoundToNearest(damage);
    g_Hunter[actor].m_iTeamDamage += RoundToNearest(damage);
    return Plugin_Continue;
}

Action HunterLungeAtVictim_OnKilled(any action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    // already had a victim, not a skeet.
    if (g_InfectedSkillCache[actor].m_iSpecialVictim)
    {
        g_Hunter[actor].ResetHunter();
        return Plugin_Continue;
    }

    int attacker = info.m_hAttacker;
    int weapon = info.m_hWeapon;
    int damagetype = info.m_bitsDamageType;
    //float damage = info.m_flDamage;

    //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnKilled called: attacker: %d, actor: %d, weapon: %d, damage: %.02f, damage type: %d", attacker, actor, weapon, damage, damagetype);

    if (!IsValidSurvivor(attacker))
        return Plugin_Continue;
    
    // skeet?
    if (g_Hunter[actor].m_iTeamDamage > g_Hunter[actor].m_iDamage[attacker] && 
        g_Hunter[actor].m_iTeamDamage >= (L4D_HasPlayerControlledZombies() ? g_iPounceInterruptDefault : g_iPounceInterrupt))
    {
        // team skeet
        HandleSkeet(attacker, actor, _, _, _, true);
    }
    else if ((damagetype & DMG_BULLET) || (damagetype & DMG_BUCKSHOT))
    {
        char weaponA[32];
        strWeaponType weaponTypeA;
        GetEdictClassname(weapon, weaponA, sizeof(weaponA));

        if (g_hMapWeapons.GetValue(weaponA, weaponTypeA) && (weaponTypeA == WPTYPE_SNIPER || weaponTypeA == WPTYPE_MAGNUM))
        {
            if (g_hCvar_AllowSniper.BoolValue)
                HandleSkeet(attacker, actor, false, true);
        }

        // single player skeet
        HandleSkeet(attacker, actor);
    }
    else if (damagetype & (DMG_BLAST | DMG_PLASMA))
    {
        // direct GL hit?
        /*
            direct hit is DMG_BLAST | DMG_PLASMA
            indirect hit is DMG_AIRBOAT
        */

        char weaponB[32];
        strWeaponType weaponTypeB;
        GetEdictClassname(weapon, weaponB, sizeof(weaponB));

        if (g_hMapWeapons.GetValue(weaponB, weaponTypeB) && weaponTypeB == WPTYPE_GL)
        {
            if (g_hCvar_AllowGLSkeet.BoolValue)
                HandleSkeet(attacker, actor, false, false, true);
        }
    }
    else if ((damagetype & DMG_SLASH) || (damagetype & DMG_CLUB))
    {
        // melee skeet
        if (g_hCvar_AllowMelee.BoolValue)
            HandleSkeet(attacker, actor, true);
    }

    g_Hunter[actor].ResetHunter();
    return Plugin_Continue;
}

Action HunterLungeAtVictim_OnStart(any action, int actor, any priorAction, ActionResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnStart called");
    g_Hunter[actor].m_vecPounceStartPos.GetClientAbsOrigin(actor);
    return Plugin_Continue;
}

Action HunterLungeAtVictim_OnEnd(any action, int actor, any priorAction, ActionResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnEnd called");
    g_Hunter[actor].ResetHunter();
    return Plugin_Continue;
}

void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    g_Hunter[client].m_IncapStartTimer.Start();

    // clear hunter-hit stats (not skeeted)
    g_Hunter[client].ResetHunter();

    // check if it was a DP
    // ignore if no real pounce start pos
    if (g_Hunter[client].m_vecPounceStartPos.IsZero())
        return;

    Vector endPos;
    endPos.GetClientAbsOrigin(client);
    float fHeight  = g_Hunter[client].m_vecPounceStartPos.z - endPos.z;

    // if it's not a highpounce, ignore
    if (fHeight < g_hCvar_HunterDPThresh.FloatValue)
        return;

    // from pounceannounce:
    // distance supplied isn't the actual 2d vector distance needed for damage calculation. See more about it at
    // http://forums.alliedmods.net/showthread.php?t=93207

    float fMin = g_hCvar_MinPounceDistance.FloatValue;
    float fMax = g_hCvar_MaxPounceDistance.FloatValue;
    float fMaxDmg = g_hCvar_MaxPounceDamage.FloatValue;

    // calculate 2d distance between previous position and pounce position
    int distance = RoundToNearest(g_Hunter[client].m_vecPounceStartPos.Distance(endPos));

    // get damage using hunter damage formula
    // check if this is accurate, seems to differ from actual damage done!
    float fDamage  = (((float(distance) - fMin) / (fMax - fMin)) * fMaxDmg) + 1.0;

    // apply bounds
    if (fDamage < 0.0)
    {
        fDamage = 0.0;
    }
    else if (fDamage > fMaxDmg + 1.0)
    {
        fDamage = fMaxDmg + 1.0;
    }

    bool bIncap = false;
    int health = GetEntProp(victim, Prop_Data, "m_iHealth");
    if (RoundToNearest(fDamage) > health)
    {
        bIncap = true;
    }

    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteCell(victim);
    pack.WriteFloat(fDamage);
    pack.WriteFloat(fHeight);
    pack.WriteCell(bIncap);
    CreateTimer(0.05, Timer_HunterDP, pack);
}

static void Timer_HunterDP(Handle timer, DataPack pack)
{
    pack.Reset();
    int client  = pack.ReadCell();
    int victim  = pack.ReadCell();
    float fDamage = pack.ReadFloat();
    float fHeight = pack.ReadFloat();
    bool bIncap = pack.ReadCell();
    delete pack;

    HandleHunterDP(client, victim, g_Hunter[client].m_iPounceDamage, fDamage, fHeight, bIncap);
}
