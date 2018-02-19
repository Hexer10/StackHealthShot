#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define PLUGIN_NAME           "StackHealthShot"
#define PLUGIN_VERSION        "1.1"

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

		DataPack data = new DataPack();
		data.WriteCell(iHealth);
		data.WriteCell(GetClientUserId(client));
		
		iRealLife[client] = iHealth;
		bUsing[client] = true;
		if (hUseHS[client] != null)
			delete hUseHS[client];

		hUseHS[client] = CreateDataTimer(1.5, Timer_UsedHS, data);
	}
	return Plugin_Continue;
}

public Action Timer_UsedHS(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int iHealth = data.ReadCell();

	if (!client)
	{
		bUsing[client] = false;
		return;
	}

	if (!HasClientHS(client))
	{
		SetEntityHealth(client, iHealth);
		bUsing[client] = false;
		return;
	}

	bUsing[client] = false;
	CreateDataTimer(0.2, Timer_UpdateLife, data);
	hUseHS[client] = null;
}

public Action Timer_UpdateLife(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int iHealth = data.ReadCell();

	if (!client)
		return;

	if (iHealth > 50)
	{
		SetEntityHealth(client, iHealth + 50);
	}
}

stock bool HasClientHS(int client)
{
	int weapon = GetClientActiveWeapon(client);
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

stock int GetClientActiveWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}