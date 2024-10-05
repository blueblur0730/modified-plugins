#if defined _animating_libarary_
    #endinput
#endif
#define _animating_libarary_

/**
 * CBaseAnimating library for l4d2.
 * 
 * Every entity that has a model uses CBaseAnimating. Classes derived from CBaseAnimating can set a model and animate.
 * For most of their original functions, please see here:
 * https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/server/baseanimating.cpp
 * 
 * For documentations see here:
 * https://developer.valvesoftware.com/wiki/$bodygroup
*/

methodmap CBaseAnimating
{
    /**
     * Creates a new CBaseAnimating instance. Use this before use any of the functions below.
     * 
     * @param entity    The entity index of the instance.
     * 
     * @return          A CBaseAnimating pointer address.
     */
    public native CBaseAnimating(int entity);

    /**
     * Returns the group number of a speciifc group name.
     * 
     * @param name      The name of the bodygroup.
     * 
     * @return          The number of the specified group name. 
     *                  -1 on failure.
    */
    public native int FindBodyGroupByName(const char[] name);

    /**
     * Sets the value of a specific body group.
     * 
     * @note            From the SDK: "// SetBodygroup is not supported on pending dynamic models. Wait for it to load!"
     * @note            iValue is actually a boolean arugument. only 0(invisible) or 1(visible) is allowed.
     * 
     * @param iGroup    The group number to set. Starting from 0.
     * @param iValue    The value to set the group to.
     * 
     * @noreturn
    */
    public native void SetBodyGroup(int iGroup, int iValue);
}

public SharedPlugin __pl_animating_library = 
{
	name = "animating_library",
	file = "animating_library.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_animating_library_SetNTVOptional()
{
    MarkNativeAsOptional("CBaseAnimating.CBaseAnimating");
    MarkNativeAsOptional("CBaseAnimating.FindBodyGroupByName");
    MarkNativeAsOptional("CBaseAnimating.SetBodyGroup");
}
#endif