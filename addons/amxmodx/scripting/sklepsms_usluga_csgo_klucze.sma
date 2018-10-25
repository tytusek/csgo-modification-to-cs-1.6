#include <amxmodx>
#include <shop_sms>
#include <csgo>
#include <ColorChat>


new const service_id[MAX_ID] = "csgo_klucze";
#define PLUGIN "Sklep-SMS: Usluga COD EXP"
#define AUTHOR "SeeK"

public plugin_natives() {
	set_native_filter("native_filter");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
}


public plugin_cfg() {
	ss_register_service(service_id)
}

public ss_service_chosen(id) {
	if( !csgo_get_user_allow(id) ) {
                ColorChat(id, GREEN,"zrob konto ---- /konto");
		return SS_STOP;
	}
	return SS_OK;
}

public ss_service_bought(id,amount) {
        csgo_set_user_key(id,csgo_get_user_key(id)+amount)	
}
// Zabezpieczenie, jezeli plugin jest odpalony na serwerze bez odpowiednich funkcji
public native_filter(const native_name[], index, trap) {
	if(trap == 0) {
		register_plugin(PLUGIN, VERSION, AUTHOR); // Rejestrujemy plugin, aby nie bylo na liscie unknown
		pause_plugin();
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}