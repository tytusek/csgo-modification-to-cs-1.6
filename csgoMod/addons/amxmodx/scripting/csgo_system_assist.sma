#include <amxmodx>
#include <reapi>
#include <csgo>

#define FRAG			// +1 frag

#if !defined MAX_PLAYERS
	const MAX_PLAYERS = 32;
#endif

#if !defined MAX_NAME_SIZE
	const MAX_NAME_SIZE = 32;
#endif
	
//                            who's             whom
new Float:g_playerDamage[MAX_PLAYERS + 1][MAX_PLAYERS + 1];
new HookChain:g_deathNoticePostHook;

new user_round_assist[33]=0;
new user_assist[33]=0;

public plugin_init() {
	register_plugin("KiLL Assist", "poka_4to_beta", "PRoSToTeM@ edit tytus"); // edited by neugomon

	register_plugin("Cod System: Assist", "1.0", "TyTuS")
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamage_Post", true);
	RegisterHookChain(RG_CSGameRules_DeathNotice, "OnDeathNotice", false);
	DisableHookChain((g_deathNoticePostHook = RegisterHookChain(RG_CSGameRules_DeathNotice, "OnDeathNotice_Post", true)));

}
public plugin_natives()
{
	register_native("get_user_assist", "get_user_assist", 1);
	register_native("get_user_round_assist", "get_user_round_assist", 1);
}
public get_user_assist(id)
        return user_assist[id];
public get_user_round_assist(id)
       return user_round_assist[id];

public client_connect(playerEntIndex)
	arrayset(_:g_playerDamage[playerEntIndex], 0, sizeof(g_playerDamage[]));

public OnPlayerSpawn_Post(playerEntIndex)
	for(new i = 1; i <= MAX_PLAYERS; i++){
		g_playerDamage[i][playerEntIndex] = 0.0;
		user_round_assist[i]=0;
	}

public OnPlayerTakeDamage_Post(playerEntIndex, inflictorEntIndex, attackerEntIndex, Float:damage, damageType)
{
	if(attackerEntIndex != playerEntIndex && is_user_connected(attackerEntIndex) && rg_is_player_can_takedamage(attackerEntIndex, playerEntIndex)) 
	    g_playerDamage[attackerEntIndex][playerEntIndex] += damage;
}

public OnDeathNotice(victimEntIndex, killerEntIndex, inflictorEntIndex)
{
	if(killerEntIndex != victimEntIndex && is_user_connected(killerEntIndex) && rg_is_player_can_takedamage(killerEntIndex, victimEntIndex))
	{
		new bestAttackerEntIndex = 0;
		for (new i = 1, Float:maxDamage; i <= MAX_PLAYERS; i++) {
			if (g_playerDamage[i][victimEntIndex] > maxDamage) {
				maxDamage = g_playerDamage[i][victimEntIndex];
				bestAttackerEntIndex = i;
			}
		}
		// Assistant must have more damage than killer
		if(bestAttackerEntIndex != killerEntIndex && is_user_connected(bestAttackerEntIndex) && rg_is_player_can_takedamage(bestAttackerEntIndex, victimEntIndex) && get_member(bestAttackerEntIndex, m_iTeam) != TEAM_SPECTATOR)
		{
			new name1[MAX_NAME_SIZE], name2[MAX_NAME_SIZE], name[MAX_NAME_SIZE];
			get_entvar(killerEntIndex, var_netname, name1, charsmax(name1));
			get_entvar(bestAttackerEntIndex, var_netname, name2, charsmax(name2));
			
		#if defined FRAG
			set_entvar(bestAttackerEntIndex, var_frags, Float:get_entvar(bestAttackerEntIndex, var_frags) + 1.0);
			user_assist[bestAttackerEntIndex]++;
			user_round_assist[bestAttackerEntIndex]++;
			csgo_set_user_assist(bestAttackerEntIndex, csgo_get_user_assist(bestAttackerEntIndex)+1);
		#endif
		
			// TODO: cut nicknames if big length (> 14) and add ...
			// TODO: UTF-8 cut correctly
			if(strlen(name1) + strlen(name2) > 28) {
				formatex(name, charsmax(name), "%.14s + %.14s", name1, name2);
			} else {
				formatex(name, charsmax(name), "%s + %s", name1, name2);
			}
		   
			message_begin(MSG_ALL, SVC_UPDATEUSERINFO);
			write_byte(killerEntIndex - 1);
			write_long(get_user_userid(killerEntIndex));
			write_char('\');
			write_char('n');
			write_char('a');
			write_char('m');
			write_char('e');
			write_char('\');
			write_string(name);
			for(new i = 0; i < 16; i++)
				write_byte(0);
			message_end();

			EnableHookChain(g_deathNoticePostHook);
		}
	}
}

public OnDeathNotice_Post(victimEntIndex, killerEntIndex, inflictorEntIndex)
{
	rh_update_user_info(killerEntIndex);
	DisableHookChain(g_deathNoticePostHook);
}