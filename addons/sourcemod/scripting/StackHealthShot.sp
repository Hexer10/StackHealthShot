#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <hexstocks>

#define PLUGIN_NAME           "StackHealthShot"
#define PLUGIN_VERSION        "1.0"

#pragma semicolon 1
#pragma newdecls required

bool bUsing[MAXPLAYERS+1];
Handle hUseHS[MAXPLAYERS+1];
int iRealLife[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "Hexah",
	description = "",
	version = PLUGIN_VERSION,
	url = "github.com/Hexer10/StackHealthShot"
};

public void OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	HookEvent("item_equip", Event_ItemEquip);
}

public void OnClientDisconnect_Post(int client)
{
	bUsing[client] = false;
	iRealLife[client] = 0;
	if (hUseHS[client] != null)
		delete hUseHS[client];
}

public Action Event_ItemEquip(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (hUseHS[client] != null)
	{
		SetEntityHealth(client, iRealLife[client]);
		bUsing[client] = false;
		delete hUseHS[client];
	}

}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	char sWeapon[64];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));
	if (StrEqual(sWeapon, "weapon_healthshot"))
	{
		if (bUsing[client])
			return Plugin_Continue;
		
		int iHealth = GetClientHealth(client);
		if (iHealth >= 100)
			SetEntityHealth(client, 99);

		ArrayList data = new ArrayList();
		data.Push(iHealth);
		data.Push(GetClientUserId(client));
		
		iRealLife[client] = iHealth;
		bUsing[client] = true;
		if (hUseHS[client] != null)
			delete hUseHS[client];

		hUseHS[client] = CreateTimer(1.5, Timer_UsedHS, data);
	}
	return Plugin_Continue;
}

public Action Timer_UsedHS(Handle timer, ArrayList data)
{
	int client = GetClientOfUserId(data.Get(1));
	if (!client)
	{
		bUsing[client] = false;
		return;
	}

	int iHealth = data.Get(0);
	if (!HasClientHS(client))
	{
		SetEntityHealth(client, iHealth);
		bUsing[client] = false;
		return;
	}

	bUsing[client] = false;
	CreateTimer(0.2, Timer_UpdateLife, data);
	hUseHS[client] = null;
}

public Action Timer_UpdateLife(Handle timer, ArrayList data)
{
	int client = GetClientOfUserId(data.Get(1));
	if (!client)
		return;
	int iHealth = data.Get(0);
	if (100 > iHealth > 50)
	{
		SetEntityHealth(client, iHealth + 50); //HP + 50 - 100
	}
	else if (iHealth >= 100)
	{
		SetEntityHealth(client, iHealth + 50);
	}
}

bool HasClientHS(int client)
{
	int weapon = GetPlayerActiveWeapon(client);
	
	if (weapon == -1)
		return false;
		
	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if (!StrEqual(sWeapon, "weapon_healthshot"))
	{
		return false;
	}
	return true;
}
