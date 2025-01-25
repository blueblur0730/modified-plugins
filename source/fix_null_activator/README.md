# [ANY] Fix Null Activator

### Introduction

- This plugin Fixes a crash caused by null activator when calling AcceptInput.
- Original Author: [GoD-Tony](https://forums.alliedmods.net/showthread.php?t=261173)
- [Previous Discussion](https://forums.alliedmods.net/showthread.php?t=261039)
- Currently supported games:
  - css
  - hl2dm
  - dods
  - tf2
  - l4d
  - l4d2
  - csgo

### How to use

- Open config file "fix_null_activator.cfg"
- The first sub-key should be an input's name like `Deactivate`, `TestActivator` etc. Go to the keys inside of it, the entity name is on the right of the key `entity_name`, fill in the entity you want to check. It would like this:

```
"Activators"
{
    // input name
    "Deactivate"
    {
        "entity_name"   "game_ui"
    }

    "TestActivator"
    {
        "entity_name"   "filter_activator_class"
        "entity_name"   "filter_activator_context"
        "entity_name"   "filter_activator_infected_class"
        "entity_name"   "filter_activator_mass_greater"
        "entity_name"   "filter_activator_model"
        "entity_name"   "filter_activator_name"
        "entity_name"   "filter_activator_team"
        "entity_name"   "filter_base"
        "entity_name"   "filter_damage_type"
        "entity_name"   "filter_enemy"
        "entity_name"   "filter_health"
        "entity_name"   "filter_melee_damage"
        "entity_name"   "filter_origin"
        "entity_name"   "filter_multi"
    }
}
```

- Every change applys on next map start.

### How dose this become a bug?

- When calling `CBaseEntity::AcceptInput`, there could be chance that the activator player was disconnected or the activator entity was destroyed, which will cause the activator pointer to be null to pass to `CBaseEntity::AcceptInput`.
`CBaseEntity::AcceptInput` dose not perform any check for the null activator pointer, so once this null pointer is passed to the target input function and this function try to access the pointer, the game crashes. This could be existed in any source games and any entity that is related to this logic such as `game_ui`, `filter_* entity`, etc.

- This plugin dynamic hooks the `CBaseEntity::AcceptInput` function with specific entity and checks if the activator pointer is null before calling the target input function. If the activator pointer is null, `CBaseEntity::AcceptInput` will be skipped and won't call the target input function.
