#include <sourcemod>
#include <sdktools>

#include <tf2_stocks>

#include <ripext>
#include <json>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = 
{
	name = "[TF2] Competitive Discord Mover", 
	author = "Lucas 'puntero' Maza", 
	description = "Moves users on Discord on corcondance with the teams they're in.", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/funkes"
};

ConVar  CV_RedChannel,
		CV_BluChannel,
		CV_DefaultChannel,
		CV_GuildID,
		CV_ServerIP,
		CV_APIName,
		CV_Cooldown;
		
bool b_OnCoolDown = false; 

public void OnPluginStart()
{
	CV_RedChannel     = CreateConVar("sm_dmover_redchannel",     "",      "Defines the RED channel ID to move RED players to.");
	CV_BluChannel     = CreateConVar("sm_dmover_bluchannel",     "",      "Defines the BLU channel ID to move BLU players to.");
	CV_DefaultChannel = CreateConVar("sm_dmover_defaultchannel", "",      "Defines the Default channel ID to move all players back to.");
	CV_GuildID 		  = CreateConVar("sm_dmover_guild",			 "",	  "ID of the Discord server where players are moved.");
	CV_Cooldown       = CreateConVar("sm_dmover_cooldown",       "8",     "Cooldown between attempts to move users again. ROOT bypasses this.");
	CV_ServerIP 	  = CreateConVar("sm_dmover_server",         "",  	  "Server hostname or IP to send the move request to.");
	CV_APIName 		  = CreateConVar("sm_dmover_server_api",     "mover", "API REST name to post the JSON to. Example: serverhostname.com/apiname");
	
	RegAdminCmd("sm_move", CMD_Move, ADMFLAG_GENERIC, "Moves users to their respective channels. Valid Arguments: 'teams' - 'default'");
	
	b_OnCoolDown = false;
}


public Action CMD_Move(int client, int args)
{
	if (args < 1) {
		ReplyToCommand(client, "[CM] Wrong command usage. Usage: sm_move [teams | default]");
		return Plugin_Handled;
	}
	
	if (b_OnCoolDown) {
		ReplyToCommand(client, "[CM] You must wait %.0f second(s) before attempting another move.", GetConVarFloat(CV_Cooldown));
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArgString(arg, sizeof(arg));
	
	if (!IsValidArgument(arg)) {
		ReplyToCommand(client, "[CM] Wrong argument passed. Usage: sm_move [teams | default]");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[CM] Moving players...");
	
	JSON_Array blues = new JSON_Array(),
			   reds  = new JSON_Array();
	
	for (int i = 1; i < MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			TFTeam team = TF2_GetClientTeam(i);
			
			char steamId[32];
			GetClientAuthId(i, AuthId_SteamID64, steamId, sizeof(steamId));
			
			if (team != TFTeam_Spectator || team != TFTeam_Unassigned)
				((team == TFTeam_Blue) ? blues.PushString(steamId) : reds.PushString(steamId));
		}
	}
	
	char Json[2048];
	/////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////
	
	JSON_Object main   = new JSON_Object();
	main.SetObject("red", reds);
	main.SetObject("blu", blues);
	
	char redId[32], bluId[32], defId[32], guildId[32];
	GetConVarString(CV_RedChannel, redId, sizeof(redId));
	GetConVarString(CV_BluChannel, bluId, sizeof(bluId));
	GetConVarString(CV_DefaultChannel, defId, sizeof(defId));
	GetConVarString(CV_GuildID, guildId, sizeof(guildId));
	
	main.SetString("channelBlu", bluId);
	main.SetString("channelRed", redId);
	main.SetString("channelDef", defId);
	main.SetString("action",     arg);
	main.SetString("guild", 	 guildId);
	
	main.Encode(Json, sizeof(Json), JSON_ENCODE_PRETTY);
	main.Cleanup();
	
	delete main;
	
	/////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////
	
	char ip[32];
	GetConVarString(CV_ServerIP, ip, sizeof(ip));
	
	HTTPClient http = new HTTPClient(ip);
	http.SetHeader("Accept", "application/json");
	http.SetHeader("Content-Type", "application/json");
	
	JSON obj = JSONObject.FromString(Json);
	
	char API[32];
	GetConVarString(CV_APIName, API, sizeof(API));
	
	http.Post(API, obj, OnSentJSON);
	
	delete http;
	
	/////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////
	
	b_OnCoolDown = true;
	CreateTimer(GetConVarFloat(CV_Cooldown), ResetCooldown);
	
	return Plugin_Handled;
}

public Action ResetCooldown(Handle timer)
{ b_OnCoolDown = false; }

void OnSentJSON(HTTPResponse response, any data)
{
	if (response.Status != HTTPStatus_OK || response.Data == null)
		PrintToChatAll("[CM] Failed to send data. ¿Is the server up?");
	
	return;
}

bool IsValidArgument(char[] buffer)
{
	return StrEqual(buffer, "teams", false) || StrEqual(buffer, "default", false);
}