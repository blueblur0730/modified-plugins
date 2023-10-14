

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "Raoul Duke",
	description = "Notifies players of major survival events 10 seconds before starting.",
	version = PLUGIN_VERSION,
	url = "www.isntreal.com"
};
public OnPluginStart() {
	// Cvars to turn on/off default startup and message type (hint or chat)
	autoStart = CreateConVar("survival_timer_auto", "1", "The Survival Event Timer is automatically on for players by default but can be manual.", FCVAR_PLUGIN);
	useHints = CreateConVar("survival_timer_hints", "1", "The Survival Event Timer displays hints by default but can display chat messages instead.", FCVAR_PLUGIN);
	RegConsoleCmd("sm_showtimer", cmd_TimerSwitch);
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("create_panic_event", event_TimerStart);
	HookEvent("tank_killed", event_TankKilled);
	HookEvent("round_end", event_TimerEnd);
	
	AutoExecConfig(true);
	// Apply default preferences
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i)){
			if(GetConVarBool(autoStart) == true){	
				timerDisabled[i] = false;
			}
			else{
				timerDisabled[i] = true;
			}
		}
	}
}
// Switch client settings and vocalize
public Action:cmd_TimerSwitch(client, args) {
	if(IsClientInGame(client) && !IsFakeClient(client)){
		if(timerDisabled[client] == false){
			timerDisabled[client] = true;		
			PrintToChat(client, "\x01[\x05SM\x01] \x05Survival Event Timer Disabled.");
			PrintToChat(client, "\x01[\x05SM\x01] \x05Type \x01!showtimer \x05to enable.");
		}
		else{
			timerDisabled[client] = false;
			PrintToChat(client, "\x01[\x05SM\x01] \x05Survival Event Timer Enabled.");
			PrintToChat(client, "\x01[\x05SM\x01] \x05Type \x01!showtimer \x05to disable.");
		}
	}
	return Plugin_Handled;
}
// Vocalize state and trigger on spawn
public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:mode[16];
	GetConVarString(FindConVar("mp_gamemode"), mode, sizeof(mode));
	if (StrEqual(mode, "survival") && timerDisabled[client] != true) {
		PrintToChat(client, "\x01[\x05SM\x01] \x05Survival Event Timer Enabled.");
		PrintToChat(client, "\x01[\x05SM\x01] \x05Type \x01!showtimer \x05to disable.");
	}
	else if(StrEqual(mode, "survival") && timerDisabled[client] != false) {
		PrintToChat(client, "\x01[\x05SM\x01] \x05Survival Event Timer Disabled.");
		PrintToChat(client, "\x01[\x05SM\x01] \x05Type \x01!showtimer \x05to enable.");
	}
	return Plugin_Handled;	
}
// Start timer with first panic event
public Action:event_TimerStart(Handle:event, const String:name[], bool:dontBroadcast){
	// Verify survival mode & first panic event
	new String:mode[16];
	GetConVarString(FindConVar("mp_gamemode"), mode, sizeof(mode));
	if (!StrEqual(mode, "survival") || timerOn == true) {
		return Plugin_Handled;
	}
	else {
		timerOn = true;
		Timers[1] = CreateTimer(30.0, WarnTank);
		Timers[2] = CreateTimer(45.0, WarnHorde);
		Timers[3] = CreateTimer(100.0, WarnHorde);
		Timers[4] = CreateTimer(105.0, WarnTank);
		Timers[5] = CreateTimer(159.0, WarnHorde);
		Timers[6] = CreateTimer(165.0, WarnTank);
		Timers[7] = CreateTimer(192.0, WarnHorde);
		Timers[8] = CreateTimer(247.0, WarnHorde);
		Timers[9] = CreateTimer(255.0, WarnTank);
		Timers[10] = CreateTimer(297.0, WarnHorde);
		Timers[11] = CreateTimer(315.0, WarnDoubleTank);
		Timers[12] = CreateTimer(370.0, WarnHorde);
		Timers[13] = CreateTimer(410.0, WarnTank);
		Timers[14] = CreateTimer(417.0, WarnHorde);
		Timers[15] = CreateTimer(451.0, WarnTank);
		Timers[16] = CreateTimer(460.0, WarnHorde);
		Timers[17] = CreateTimer(490.0, WarnTank);
		Timers[18] = CreateTimer(555.0, WarnHorde);
		Timers[19] = CreateTimer(590.0, WarnTank);
		Timers[20] = CreateTimer(622.0, WarnHorde);
		Timers[21] = CreateTimer(665.0, WarnHorde);
		Timers[22] = CreateTimer(671.0, WarnTank);
		Timers[23] = CreateTimer(741.0, WarnHorde);
		Timers[24] = CreateTimer(760.0, WarnDoubleTank);
		tellClients("\x01[\x05SM\x01] \x05Survival Event Timer Started");	
		return Plugin_Handled;
	}
}
// Stop timer on round end
public Action:event_TimerEnd(Handle:event, const String:name[], bool:dontBroadcast){
	if(timerOn == true){	
		for (new i = 1; i <= 24; i++){
			if(Timers[i] != INVALID_HANDLE){		
				KillTimer(Timers[i]);
				Timers[i] = INVALID_HANDLE;
			}
		}
		currentTimer = 1;	
		tellClients("\x01[\x05SM\x01] \x05Round Ended \x01-\x05 Timer Stopped");
		timerOn = false;
	}
	return Plugin_Handled;
}
// Vocalize tank death
public Action:event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast){
	if(timerOn == true){
		showEvent("\x05TANK is DEAD");
	}
	return Plugin_Handled;
	
}
// Vocalize tank event
public Action:WarnTank(Handle:timer){
	if(timerOn == true){
		showEvent("\x05TANK in 10s");
		Timers[currentTimer] = INVALID_HANDLE;
		currentTimer++;
	}
	return Plugin_Handled;		
}
// Vocalize double tank event
public Action:WarnDoubleTank(Handle:timer){
	if(timerOn == true){
		showEvent("\x05TWO TANKS in 10s");
		Timers[currentTimer] = INVALID_HANDLE;
		currentTimer++;
	}
	return Plugin_Handled;	
}
// Vocalize horde event
public Action:WarnHorde(Handle:timer){
	if(timerOn == true){
		showEvent("\x05HORDE in 10s");
		Timers[currentTimer] = INVALID_HANDLE;
		currentTimer++;
	}
	return Plugin_Handled;		
}
// Chat message to enabled clients
tellClients(String:message[]){
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && timerDisabled[i] == false){
			PrintToChat(i, message);	
		}
	}	
}
// Event message to enabled clients 
showEvent(String:hint[]){
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && timerDisabled[i] == false){
			if(GetConVarBool(useHints) == true){
				PrintHintText(i, hint);	
			}
			else {
				PrintToChat(i, hint);
			}
		}
	}
}