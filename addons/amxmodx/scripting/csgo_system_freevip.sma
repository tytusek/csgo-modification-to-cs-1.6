#include <amxmodx>
#include <csgo>
#include <ColorChat>
#include <reapi>

public plugin_init()
{
	register_plugin("[CSGO] System: Free VIP", "1.0.0", "TyTuS");
	RegisterHookChain(RG_CBasePlayer_Spawn, "Odrodzenie", true);
}

public Odrodzenie(id)
{
	if(!is_user_alive(id) || !csgo_get_user_loaded(id) || !csgo_get_user_allow(id))
		return PLUGIN_CONTINUE;

	if(csgo_get_user_time(id) > (5*60*60) && csgo_get_user_time(id) < (7*60*60))
	{
		set_user_flags(id, get_user_flags(id) | ADMIN_LEVEL_H);
		ColorChat(id,GREEN,"Dostales testowo VIPa oraz Premki na 2 Godziny Gry!")
	}
	return PLUGIN_CONTINUE;
}