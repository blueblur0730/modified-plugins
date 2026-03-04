#if defined _skill_detect_tracking_caralarm_included
    #endinput
#endif
#define _skill_detect_tracking_caralarm_included

enum CarAlarmReason_t
{
    CALARM_UNKNOWN,
    CALARM_HIT,
    CALARM_TOUCHED,
    CALARM_EXPLOSION,
    CALARM_BOOMER
};

enum struct CarAlarmTrace_t
{
    CarAlarmReason_t m_eReason;   // reason for the alarm
    int m_iCarEntity;             // car entity index
    int m_iGlassEntity;           // glass entity index
    int m_iAttacker;              // who attacked the car
    int m_iBoomerInflictor;       // boomer who inflicted the explosion (if any)
}
ArrayList g_hArray_CarAlarmTrace;

void OnSpawn_CarAlarm(int entity)
{
    if (!IsValidEntity(entity))
        return;

    int index = g_hArray_CarAlarmTrace.FindValue(entity, CarAlarmTrace_t::m_iCarEntity);
    if (index == -1)
    {
        CarAlarmTrace_t carAlarmTrace;
        carAlarmTrace.m_iCarEntity = entity;
        g_hArray_CarAlarmTrace.PushArray(carAlarmTrace, sizeof(carAlarmTrace));
    }
}

void OnSpawn_CarAlarmGlass(int entity)
{
    if (!IsValidEntity(entity))
        return;

    // glass is parented to a car, link the two through the Map
    // find parent and save both
    int parentEntity = GetEntPropEnt(entity, Prop_Data, "m_pParent");
    if (!IsValidEntity(parentEntity))
        return;

    int index = g_hArray_CarAlarmTrace.FindValue(parentEntity, CarAlarmTrace_t::m_iCarEntity);
    if (index != -1)
    {
        CarAlarmTrace_t carAlarmTrace;
        g_hArray_CarAlarmTrace.GetArray(index, carAlarmTrace, sizeof(carAlarmTrace));
        carAlarmTrace.m_iGlassEntity = entity;
        g_hArray_CarAlarmTrace.SetArray(index, carAlarmTrace, sizeof(carAlarmTrace));
    }
    else
    {
        CarAlarmTrace_t carAlarmTrace;
        carAlarmTrace.m_iCarEntity = parentEntity;
        carAlarmTrace.m_iGlassEntity = entity;
        g_hArray_CarAlarmTrace.PushArray(carAlarmTrace, sizeof(carAlarmTrace));
    }
}

void OnTakeDamagePost_Car(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if (!IsValidSurvivor(attacker))
        return;
    /*
        boomer popped on alarmed car =
            DMG_BLAST_SURFACE| DMG_BLAST
        and inflictor is the boomer

        melee slash/club =
            DMG_SLOWBURN|DMG_PREVENT_PHYSICS_FORCE + DMG_CLUB or DMG_SLASH
        shove is without DMG_SLOWBURN
    */

    int index = g_hArray_CarAlarmTrace.FindValue(victim, CarAlarmTrace_t::m_iCarEntity);
    if (index != -1)
    {
        CarAlarmTrace_t carAlarmTrace;
        g_hArray_CarAlarmTrace.GetArray(index, carAlarmTrace, sizeof(carAlarmTrace));
        if (damagetype & DMG_BLAST)
        {
            if (IsValidInfected(inflictor) && GetEntProp(inflictor, Prop_Send, "m_zombieClass") == ZC_BOOMER)
            {
                carAlarmTrace.m_eReason = CALARM_BOOMER;
                carAlarmTrace.m_iBoomerInflictor = inflictor;
            }
            else
            {
                carAlarmTrace.m_eReason = CALARM_EXPLOSION;
            }
        }
        else if (damage == 0.0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH) && !(damagetype & DMG_SLOWBURN))
        {
            carAlarmTrace.m_eReason = CALARM_TOUCHED;
        }
        else
        {
            carAlarmTrace.m_eReason = CALARM_HIT;
        }

        carAlarmTrace.m_iAttacker = attacker;
        g_hArray_CarAlarmTrace.SetArray(index, carAlarmTrace, sizeof(carAlarmTrace));
        CheckAlarm(victim, false);
    }
}

void OnTouchPost_Car(int entity, int client)
{
    if (!IsValidSurvivor(client))
        return;
    int index = g_hArray_CarAlarmTrace.FindValue(entity, CarAlarmTrace_t::m_iCarEntity);
    if (index != -1)
    {
        CarAlarmTrace_t carAlarmTrace;
        g_hArray_CarAlarmTrace.GetArray(index, carAlarmTrace, sizeof(carAlarmTrace));

        carAlarmTrace.m_eReason = CALARM_TOUCHED;
        carAlarmTrace.m_iAttacker = client;
        g_hArray_CarAlarmTrace.SetArray(index, carAlarmTrace, sizeof(carAlarmTrace));
        CheckAlarm(entity, false);
    }
}

void OnTakeDamagePost_CarGlass(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    // check for either: boomer pop or survivor
    if (!IsValidSurvivor(attacker))
        return;

    int index = g_hArray_CarAlarmTrace.FindValue(victim, CarAlarmTrace_t::m_iGlassEntity);
    if (index != -1)
    {
        CarAlarmTrace_t carAlarmTrace;
        g_hArray_CarAlarmTrace.GetArray(index, carAlarmTrace, sizeof(carAlarmTrace));

        if (damagetype & DMG_BLAST)
        {
            if (IsValidInfected(inflictor) && GetEntProp(inflictor, Prop_Send, "m_zombieClass") == ZC_BOOMER)
            {
                carAlarmTrace.m_eReason = CALARM_BOOMER;
                carAlarmTrace.m_iBoomerInflictor = inflictor;
            }
            else
            {
                carAlarmTrace.m_eReason = CALARM_EXPLOSION;
            }
        }
        else if (damage == 0.0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH) && !(damagetype & DMG_SLOWBURN))
        {
            carAlarmTrace.m_eReason = CALARM_TOUCHED;
        }
        else
        {
            carAlarmTrace.m_eReason = CALARM_HIT;
        }

        carAlarmTrace.m_iAttacker = attacker;
        g_hArray_CarAlarmTrace.SetArray(index, carAlarmTrace, sizeof(carAlarmTrace));
        CheckAlarm(victim, true);
    }
}

void OnTouchPost_CarGlass(int entity, int client)
{
    if (!IsValidSurvivor(client))
        return;

    int index = g_hArray_CarAlarmTrace.FindValue(entity, CarAlarmTrace_t::m_iGlassEntity);
    if (index != -1)
    {
        CarAlarmTrace_t carAlarmTrace;
        g_hArray_CarAlarmTrace.GetArray(index, carAlarmTrace, sizeof(carAlarmTrace));

        carAlarmTrace.m_eReason = CALARM_TOUCHED;
        carAlarmTrace.m_iAttacker = client;
        g_hArray_CarAlarmTrace.SetArray(index, carAlarmTrace, sizeof(carAlarmTrace));

        CheckAlarm(entity, true);
    }
}

void CheckAlarm(int victim, bool bParent = false)
{
    int index = g_hArray_CarAlarmTrace.FindValue(victim, bParent ? CarAlarmTrace_t::m_iGlassEntity : CarAlarmTrace_t::m_iCarEntity);
    if (index != -1)
    {
        if (bParent)
        {
            SDKUnhook(victim, SDKHook_OnTakeDamagePost, OnTakeDamagePost_CarGlass);
            SDKUnhook(victim, SDKHook_TouchPost, OnTouchPost_CarGlass);
        }
        else
        {
            SDKUnhook(victim, SDKHook_OnTakeDamagePost, OnTakeDamagePost_Car);
            SDKUnhook(victim, SDKHook_TouchPost, OnTouchPost_Car);
        }

        // check for infected assistance
        int infected = 0;
        CarAlarmTrace_t carAlarmTrace;
        g_hArray_CarAlarmTrace.GetArray(index, carAlarmTrace, sizeof(carAlarmTrace));
        if (IsValidSurvivor(carAlarmTrace.m_iAttacker))
        {
            if (carAlarmTrace.m_eReason == CALARM_BOOMER)
            {
                infected = carAlarmTrace.m_iBoomerInflictor;
            }
            else
            {
                infected = L4D2_GetSpecialInfectedDominatingMe(carAlarmTrace.m_iAttacker);
            }
        }

        HandleCarAlarmTriggered(carAlarmTrace.m_iAttacker, infected, (IsValidClientInGame(carAlarmTrace.m_iAttacker)) ? carAlarmTrace.m_eReason : CALARM_UNKNOWN);
        g_hArray_CarAlarmTrace.Erase(index);
    }
}