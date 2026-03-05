#if defined _skill_detect_tracking_hunter_included
    #endinput
#endif
#define _skill_detect_tracking_hunter_included

Action HunterLungeAtVictim_OnShoved(any action, int actor, int entity, ActionDesiredResult result)
{
    //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnShoved called, entity: %d, actor: %d", entity, actor);
    HandleDeadstop(entity, actor);
    g_InfectedSkillCache[actor].ResetHunter();
    return Plugin_Continue;
}

// after takedamage hook.
Action HunterLungeAtVictim_OnInjured(any action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
    // already had a victim, not a skeet.
    if (g_InfectedSkillCache[actor].m_iSpecialVictim)
    {
        g_InfectedSkillCache[actor].ResetHunter();
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
        if (!g_SurvivorSkillCache[attacker].m_bShotCounted)
        {
            // count this shotgun pellet as once.
            g_InfectedSkillCache[actor].m_iShotsFired[attacker]++;
            //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnInjured: shotgun pellet, shots fired: %d", g_InfectedSkillCache[actor].m_iShotsFired[attacker]);
            g_SurvivorSkillCache[attacker].m_bShotCounted = true;
        }
    }
    else if (damagetype & DMG_BULLET)
    {
        // just count this into.
        g_InfectedSkillCache[actor].m_iShotsFired[attacker]++;
        //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnInjured: bullet, shots fired: %d", g_InfectedSkillCache[actor].m_iShotsFired[attacker]);
    }

    g_InfectedSkillCache[actor].m_iHunterShotDmg[attacker] += RoundToNearest(damage);
    g_InfectedSkillCache[actor].m_iHunterShotDmgTeam += RoundToNearest(damage);
    return Plugin_Continue;
}

Action HunterLungeAtVictim_OnKilled(any action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
    // already had a victim, not a skeet.
    if (g_InfectedSkillCache[actor].m_iSpecialVictim)
    {
        g_InfectedSkillCache[actor].ResetHunter();
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
    if (g_InfectedSkillCache[actor].m_iHunterShotDmgTeam > g_InfectedSkillCache[actor].m_iHunterShotDmg[attacker] && 
        g_InfectedSkillCache[actor].m_iHunterShotDmgTeam >= (L4D_HasPlayerControlledZombies() ? g_iPounceInterruptDefault : g_iPounceInterrupt))
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

    g_InfectedSkillCache[actor].ResetHunter();
    return Plugin_Continue;
}

Action HunterLungeAtVictim_OnStart(any action, int actor, any priorAction, ActionResult result)
{
    //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnStart called");
    g_InfectedSkillCache[actor].m_vecPouncePosition.GetClientAbsOrigin(actor);
    return Plugin_Continue;
}

Action HunterLungeAtVictim_OnEnd(any action, int actor, any priorAction, ActionResult result)
{
    //PrintToServer("[Skill Detect] HunterLungeAtVictim_OnEnd called");
    g_InfectedSkillCache[actor].ResetHunter();
    return Plugin_Continue;
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients)
        return;

    if (!IsClientInGame(client))
        return;

    int wepid = event.GetInt("weaponid");
    if (wepid == WEPID_SHOTGUN_CHROME || wepid == WEPID_SHOTGUN_SPAS || wepid == WEPID_AUTOSHOTGUN || wepid == WEPID_PUMPSHOTGUN)
    {
        g_SurvivorSkillCache[client].m_bShotCounted = false;
    }
}

void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    g_InfectedSkillCache[client].m_flPinTime[0] = GetGameTime();

    // clear hunter-hit stats (not skeeted)
    g_InfectedSkillCache[client].ResetHunter();

    // check if it was a DP
    // ignore if no real pounce start pos
    if (g_InfectedSkillCache[client].m_vecPouncePosition.IsZero())
        return;

    Vector endPos;
    endPos.GetClientAbsOrigin(client);
    float fHeight  = g_InfectedSkillCache[client].m_vecPouncePosition.z - endPos.z;

    // from pounceannounce:
    // distance supplied isn't the actual 2d vector distance needed for damage calculation. See more about it at
    // http://forums.alliedmods.net/showthread.php?t=93207

    float fMin = g_hCvar_MinPounceDistance.FloatValue;
    float fMax = g_hCvar_MaxPounceDistance.FloatValue;
    float fMaxDmg = g_hCvar_MaxPounceDamage.FloatValue;

    // calculate 2d distance between previous position and pounce position
    int distance = RoundToNearest(g_InfectedSkillCache[client].m_vecPouncePosition.Distance(endPos));

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

    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteCell(victim);
    pack.WriteFloat(fDamage);
    pack.WriteFloat(fHeight);
    CreateTimer(0.05, Timer_HunterDP, pack);
}

static void Timer_HunterDP(Handle timer, DataPack pack)
{
    pack.Reset();
    int client  = pack.ReadCell();
    int victim  = pack.ReadCell();
    float fDamage = pack.ReadFloat();
    float fHeight = pack.ReadFloat();
    delete pack;

    HandleHunterDP(client, victim, g_InfectedSkillCache[client].m_iPounceDamage, fDamage, fHeight);
}
