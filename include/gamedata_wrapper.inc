#if defined _gamedata_wrapper_
    #endinput
#endif
#define _gamedata_wrapper_

#include <sourcemod>

enum OperatingSystem
{
    OS_Unknown = -1,
    OS_Windows = 0,
    OS_Linux = 1
}

enum struct SDKCallParamsWrapper
{
    SDKType          type;
    SDKPassMethod    pass;
    int              decflags;
    int              encflags;
}

// credits to Forgetest.
methodmap GameDataWrapper < GameData
{
    public GameDataWrapper(const char[] file) {
        GameData gd = new GameData(file);
        if (!gd) SetFailState("[GameData] Missing gamedata of file \"%s\".", file);
        return view_as<GameDataWrapper>(gd);
    }

    property GameData Super {
        public get() { return view_as<GameData>(this); }
    }

    property OperatingSystem OS {
        public get() { return view_as<OperatingSystem>(this.Super.GetOffset("OS")); }
    }

    public int GetOffset(const char[] key) {
        int offset = this.Super.GetOffset(key);
        if (offset == -1) SetFailState("[GameData] Missing offset of section \"%s\".", key);
        return offset;
    }

    public void GetKeyValue(const char[] key, char[] buffer, int maxlen) {
        bool b = this.Super.GetKeyValue(key, buffer, maxlen);
        if (!b) SetFailState("[GameData] Missing key \"%s\" in gamedata file.", key);
    }

    public Address GetAddress(const char[] key) {
        Address ptr = this.Super.GetAddress(key);
        if (ptr == Address_Null) SetFailState("[GameData] Missing address of section \"%s\".", key);
        return ptr;
    }

    public Address GetMemSig(const char[] key) {
        Address ptr = this.Super.GetMemSig(key);
        if (ptr == Address_Null) SetFailState("[GameData] Missing signature memory of section \"%s\".", key);
        return ptr;
    }

#if defined _sdktools_included
    public Handle CreateSDKCallOrFail(
        SDKCallType type,
        SDKFuncConfSource src,
        const char[] name,
        const SDKCallParamsWrapper[] params = {},
        int numParams = 0,
        bool hasReturnValue = false,
        const SDKCallParamsWrapper ret = {})
    {
        static const char k_sSDKFuncConfSource[SDKFuncConfSource][] = { "Offsets", "Signatures", "Addresses" };
        Handle result;
        StartPrepSDKCall(type);
        if (!PrepSDKCall_SetFromConf(this, src, name))
            SetFailState("[SDKCall] Missing key \"%s\" from section \"%s\".", name, k_sSDKFuncConfSource[src]);

        for (int i = 0; i < numParams; ++i)
            PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);

        if (hasReturnValue)
            PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);

        if (!(result = EndPrepSDKCall()))
            SetFailState("[SDKCall] Failed to Prepare SDKCall for section \"%s\".", name);

        return result;
    }

    // use relative call address to setup call instead of setting from conf.
    public Handle CreateSDKCallOrFailEx(
        SDKCallType type,
        const char[] name,
        const SDKCallParamsWrapper[] params = {},
        int numParams = 0,
        bool hasReturnValue = false,
        const SDKCallParamsWrapper ret = {})
    {
        // first we check the address, if failed, do not start to prepare.
        Address pFunc = this.GetAddress(name);
        int offset = LoadFromAddress(pFunc, NumberType_Int32);
        pFunc += view_as<Address>(offset + 4);

        Handle result;
        StartPrepSDKCall(type);
        PrepSDKCall_SetAddress(pFunc);

        for (int i = 0; i < numParams; ++i)
            PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);

        if (hasReturnValue)
            PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);

        if (!(result = EndPrepSDKCall()))
            SetFailState("[SDKCall] Failed to Prepare SDKCall for section \"%s\".", name);

        return result;
    }
#endif

#if defined _dhooks_included
    public DynamicDetour CreateDetourOrFail(
            const char[] name,
            bool bNow = true,
            DHookCallback preHook = INVALID_FUNCTION,
            DHookCallback postHook = INVALID_FUNCTION) 
    {
        DynamicDetour hSetup = DynamicDetour.FromConf(this, name);

        if (!hSetup)
            SetFailState("[DHooks] Missing detour setup section \"%s\".", name);

        if (bNow)
        {
            if (preHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Pre, preHook))
                SetFailState("[DHooks] Failed to pre-detour of section \"%s\".", name);

            if (postHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Post, postHook))
                SetFailState("[DHooks] Failed to post-detour of section \"%s\".", name);
        }

        return hSetup;
    }

    public DynamicHook CreateDynamicHookOrFail(const char[] name)
    {
        DynamicHook hSetup = DynamicHook.FromConf(this, name);

        if (!hSetup)
            SetFailState("[DHooks] Missing dynamic hook setup section \"%s\".", name);
        return hSetup;
    }

    public DynamicHook CreateDynamicHookOrFailEx(
            const char[] name
            HookType type,
            int entity = -1,
            Address pAdr = Address_Null,
            DHookCallback preHook = INVALID_FUNCTION,
            DHookCallback postHook = INVALID_FUNCTION,
            DHookRemovalCB removalHook = INVALID_FUNCTION)
    {
        DynamicHook hSetup = DynamicHook.FromConf(this, name);

        if (!hSetup)
            SetFailState("[DHooks] Missing dynamic hook setup section \"%s\".", name);

        switch (type)
        {
            case HookType_Entity:
            {
                if (entity == -1) SetFailState("[DHooks] Invalid entity index for section \"%s\".", name);

                if (preHook != INVALID_FUNCTION && postHook != INVALID_FUNCTION)
                    SetFailState("[DHooks] Failed to create dynamic hook of an entity because no callback is specified for section \"%s\".", name);

                if (preHook != INVALID_FUNCTION && !hSetup.HookEntity(Hook_Pre, entity, preHook, removalHook))
                    SetFailState("[DHooks] Failed to pre-dhook section \"%s\".", name);

                if (postHook != INVALID_FUNCTION && !hSetup.HookEntity(Hook_Post, entity, postHook, removalHook))
                    SetFailState("[DHooks] Failed to post-dhook section \"%s\".", name);
            }
            
            case HookType_GameRules:
            {
                if (preHook != INVALID_FUNCTION && postHook != INVALID_FUNCTION)
                    SetFailState("[DHooks] Failed to create dynamic hook of a GameRules object because no callback is specified for section \"%s\".", name);

                if (preHook != INVALID_FUNCTION && !hSetup.HookGameRules(Hook_Pre, preHook, removalHook))
                    SetFailState("[DHooks] Failed to pre-dhook section \"%s\".", name);

                if (postHook != INVALID_FUNCTION && !hSetup.HookGameRules(Hook_Post, postHook, removalHook))
                    SetFailState("[DHooks] Failed to post-dhook section \"%s\".", name);
            }

            case HookType_Raw:
            {
                if (pAdr == Address_Null) SetFailState("Invalid address for section \"%s\".", name);
                
                if (preHook != INVALID_FUNCTION && postHook != INVALID_FUNCTION)
                    SetFailState("Failed to create dynamic hook of a GameRules object because no callback is specified for section \"%s\".", name);

                if (preHook != INVALID_FUNCTION && !hSetup.HookRaw(Hook_Pre, pAdr, preHook, removalHook))
                    SetFailState("Failed to pre-dhook section \"%s\".", name);

                if (postHook != INVALID_FUNCTION && !hSetup.HookRaw(Hook_Post, pAdr, postHook, removalHook))
                    SetFailState("Failed to post-dhook section \"%s\".", name);
            }
        }

        return hSetup;
    }
#endif

#if defined __sourcescramble_ext_included
    public MemoryPatch CreatePatchOrFail(const char[] name, bool enable = false) {
        MemoryPatch hPatch = MemoryPatch.CreateFromConf(this, name);
        if (!(enable ? hPatch.Enable() : hPatch.Validate()))
            SetFailState("[MemoryPatch] Failed to patch section \"%s\" through source scramble.", name);

        return hPatch;
    }
#endif

#if defined _midhook_included
    public MidHook CreateMidHookOrFail(const char[] name, MidHookCB callback, bool enable = true) {
        Address pAdr = this.GetAddress(name);
        MidHook hHook = new MidHook(pAdr, callback, enable);
        if (!hHook) SetFailState("[MidHooks] Failed to create Midhook for section \"%s\".", name);

        return hHook;
    }
#endif
}