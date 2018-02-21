#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define PLUGIN_NAME           "StackHealthShot"
#define PLUGIN_VERSION        "<TAG>"

#pragma semicolon 1
#pragma newdecls required


bool bUsing[MAXPLAYERS+1];
Handle hUseHS[MAXPLAYERS+1];
int iRealLife[MAXPLAYERS+1];

//#define DEBUG

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

	#if defined DEBUG
	RegConsoleCmd("sm_hs", Cmd_HS);
	#endif

	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))OnClientPutInServer(i);
}

#if defined DEBUG
public Action Cmd_HS(int client, int args)
{
	GivePlayerItem(client, "weapon_healthshot");
	return Plugin_Handled;
}
#endif

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (iRealLife[victim] > 100)
	{
		iRealLife[victim] -= RoundToNearest(damage);
		if (iRealLife[victim] - 50 <= 0)
		{
			damage *= 100;
			return Plugin_Continue;
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
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
	if (iRealLife[client] != 0)
	{
		SetEntityHealth(client, iRealLife[client] - 50);
		bUsing[client] = false;
		delete hUseHS[client];
		CreateTimer(0.2, Timer_UpdateRealLife, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_UpdateRealLife(Handle timer, any client)
{
	iRealLife[client] = 0;
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
		iRealLife[client] = iHealth + 50;

		if (iHealth >= 100)
			SetEntityHealth(client, 99);

		bUsing[client] = true;
		if (hUseHS[client] != null)
			delete hUseHS[client];

		DataPack data = new DataPack();
		data.WriteCell(GetClientUserId(client));
		data.WriteCell(iHealth);

		hUseHS[client] = CreateTimer(1.5, Timer_UsedHS, data);
	}
	return Plugin_Continue;
}

public Action Timer_UsedHS(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());

	if (!client)
	{
		bUsing[client] = false;
		iRealLife[client] = 0;
		return;
	}

	bUsing[client] = false;
	CreateTimer(0.2, Timer_UpdateLife, data);
	hUseHS[client] = null;
}

public Action Timer_UpdateLife(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int iHealth = data.ReadCell();

	if (!client)
	{
		iRealLife[client] = 0;
		return;
	}

	if (iHealth > 50)
	{
		SetEntityHealth(client, iHealth + 50);
	}
	RequestFrame(Frame_UpdateLife, client);
}

public void Frame_UpdateLife(int client)
{
	if (GetClientHealth(client) != iRealLife[client] && iRealLife[client] > 0)
	{
		SetEntityHealth(client, iRealLife[client]);
	}
	
	iRealLife[client] = 0;
}
stock int GetClientActiveWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

#if defined DEBUG
public void OnGameFrame()
{
	static bool bSet = false;
	if (!bSet)
	{
		SetHudTextParams(-1.0, -1.0, 0.1, 255, 50, 50, 255);
	}
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		ShowHudText(i, 1, "HP: %i		RHP: %i", GetClientHealth(i), iRealLife[i]);
	}
}
#endif