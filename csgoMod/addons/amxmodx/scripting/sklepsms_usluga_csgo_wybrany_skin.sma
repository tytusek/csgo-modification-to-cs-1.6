#include <amxmodx>
#include <shop_sms>
#include <csgo>
#include <ColorChat>

new idbroni[33]=0;
new const WEAPONS[][] = 
{
	{0, "Skin do Wszystkich Broni"},
	{28, "Skin do AK47"},
	{22, "Skin do M4A1"},
	{18, "Skin do AWP"},
	{15, "Skin do FAMAS"},
	{14, "Skin do GALI"},
	{16, "Skin do USP"},
	{17, "Skin do GLOCK18"},
	{26, "Skin do DEAGLE"},
	{11, "Skin do FiveSeven"},
	{3, "Skin do Scout"},
	{5, "Skin do XM1014"},
	{7, "Skin do MAC10"},
	{19, "Skin do MP5"},
	{20, "Skin do M249"},
	{21, "Skin do M3"},
	{30, "Skin do P90"}
};


new const service_id[MAX_ID] = "csgo_wybrany_s";
#define PLUGIN "Sklep-SMS: Usluga CSGO wybrany skin"
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

public ss_service_chosen(id)
{
	if(!csgo_get_user_allow(id)) 
        {
                ColorChat(id, GREEN,"zrob konto ---- /konto");
		return SS_STOP;
	}
        menuChoseWeapon(id);
	return SS_STOP;
}      
public menuChoseWeapon(id)
{
	new string[128], menu = menu_create("\d Wybierz Bron (Skina)", "menuChoseWeaponHandle");
	for(new i=0; i<sizeof(WEAPONS); i++)
	{
		formatex(string, 127, "%s", WEAPONS[i][1]);
		menu_additem(menu, string);
	}
	menu_display(id, menu);
}

public menuChoseWeaponHandle(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new nameSkin[33], string[33], szText[128], menu = menu_create("Wybierz Skina: ", "menuCheckSkinHandle");

	for(new i = 1; i < csgo_get_skin_count(); i++)
	{
		csgo_get_skin_name(i, nameSkin, 32);
		if(WEAPONS[item-1][0]==0)
		{
			formatex(string, 32, "%d %d", i, csgo_get_skin_weaponid(i));

			if(csgo_get_user_skin(id, i)>0)
			{
				formatex(szText, 127, "%s\w | (sztuk:\d %d\w)", nameSkin, csgo_get_user_skin(id, i));
			}
			else formatex(szText, 127, "\d%s\r (Brak)", nameSkin);

			menu_additem(menu, szText, string);
		}
		else if(csgo_get_skin_weaponid(i)==WEAPONS[item-1][0])
		{
			formatex(string, 32, "%d %d", i, csgo_get_skin_weaponid(i));

			if(csgo_get_user_skin(id, i)>0)
			{
				formatex(szText, 127, "%s\w | (sztuk:\d %d\w)", nameSkin, csgo_get_user_skin(id, i));
			}
			else formatex(szText, 127, "\d%s\r (Brak)", nameSkin);

			menu_additem(menu, szText, string);
		}
	}
	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}

public menuCheckSkinHandle(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new access, callback, Data2[4][33], id_skina[33];
	menu_item_getinfo(menu, item, access, Data2[0], 32, Data2[1], 32, callback);
	
	parse(Data2[0], id_skina, 32);
	idbroni[id] = str_to_num(id_skina);

        new nazwa[33];
        csgo_get_skin_name(idbroni[id], nazwa, charsmax(nazwa));
        ColorChat(id, GREEN,"[Sklep-sms]^x03 Wybrales do kupienia^x04 %s,^x03 po wyslaniu sms i wpisaniu dostaniesz skina", nazwa);

	ss_show_sms_info(id);
	return PLUGIN_CONTINUE;
}

public ss_service_bought(id,amount) 
{
        csgo_set_user_skin(id, idbroni[id], csgo_get_user_skin(id, idbroni[id])+1);
        new nazwa[33];
        csgo_get_skin_name(idbroni[id], nazwa, charsmax(nazwa));
        ColorChat(id, GREEN,"[Sklep-sms]^x03 Kupiles^x04 %s", nazwa);
}

public native_filter(const native_name[], index, trap) 
{
	if(trap == 0) {
		register_plugin(PLUGIN, VERSION, AUTHOR); // Rejestrujemy plugin, aby nie bylo na liscie unknown
		pause_plugin();
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
