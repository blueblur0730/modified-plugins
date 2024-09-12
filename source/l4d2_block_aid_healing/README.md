# [L4D2] Block Aid-Healing

### Introduction
 - This Plugin blocks annoying aid-healing from your lovely teammates under 3 circumstances:
    - When moving faster than a threshold speed set by cvar.
    - When on a ladder.
    - When their health is greater than a limit set by cvar.
 - [Alliedmodders Link](https://forums.alliedmods.net/showthread.php?p=2828031).

### Requirements
 - Left4Dhooks
 - colors.inc

### ConVars
```
// Plugin Version
l4d2_block_aid_healing_version

// Type of status for target to have aid-healing blocked.
// 0 = do nothing,
// 1 = walking (more spcifically, velocity is taken into account),
// 2 = on a ladder,
// 4 = decided by health.
// Add numbers together.
aid_healing_blocked_type 7

// Type of client NOT allowed to use aid-healing under the rules we set.
// 0 = no one,
// 1 = bots,
// 2 = players,
// 3 = all disabled.
aid_healing_allowed_client_type 3

// Max velocity magnitude for target who had reached to have aid-healing blocked (when walking).
aid_healing_vel_max 10.0

// Max health threshold for target who had reached to have aid-healing blocked (when decided by health).
aid_healing_health_threshold 40

// Print a message to the chat when a client trys aid-healing.
aid_healing_should_print_message 1
```

### Note
 - Translation is provided, currently: en, chi.
