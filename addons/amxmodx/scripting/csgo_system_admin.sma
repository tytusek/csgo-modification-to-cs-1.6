#include <amxmodx>
#include <csgo>
#include <ColorChat>
#pragma compress 1
new opcja, wybrany;
new ilosc[33];

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

public plugin_init() 
{
	register_plugin("COD Admin Menu", "1.5", "TyTuS");
	register_clcmd("say /csgoadmin", "adminMenu", ADMIN_IMMUNITY);
	register_clcmd("ile","pobierz");
}
	
public adminMenu(id)
{
	if(!(get_user_flags(id) & ADMIN_IMMUNITY))
		return PLUGIN_HANDLED;

	new menu = menu_create("\wCSGO:MOD Admin Menu \d[TyTuS]", "adminMenuHandler");
	menu_additem(menu, "Dodaj \d[Skina]");//1
	menu_additem(menu, "Dodaj \d[Klucz]");//3
	menu_additem(menu, "Dodaj \d[Skrzynie]");//4
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}


public adminMenuHandler(id, menu, item)
{
	if(item++ ==MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	switch(item)
	{
		case 1:
		{
			Gracz(id);
			opcja = 1;
		}
		case 2:	
		{
			Gracz(id);
			opcja = 2;
		}
		case 3:	
		{
			Gracz(id);
			opcja = 3;
		}
	}
	return PLUGIN_CONTINUE;
}
public Gracz(id)
{
        if(!(get_user_flags(id) & ADMIN_IMMUNITY)){
	   ColorChat(id, RED, "Opcja tylko dla tytusa!");
	   return PLUGIN_CONTINUE;
	}
	new menu = menu_create("Wybierz gracza:", "wybierz_gracza_handler");
	new players[32], pnum, tempid;
	new szName[32], szTempid[10];
	get_players(players, pnum);

	for( new i; i<pnum; i++ )
	{
		tempid = players[i];
		get_user_name(tempid, szName, charsmax(szName));
		num_to_str(tempid, szTempid, charsmax(szTempid));
		menu_additem(menu, szName, szTempid, 0);
	}
	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}
public wybierz_gracza_handler(id, menu, item)
{
	if(item == MENU_EXIT )
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	new tempid = str_to_num(data);
	new name[33], tempname[33];
	get_user_name(tempid, tempname, 32);
	get_user_name(id, name, 32);
	
	if(!csgo_get_user_allow(tempid))
	{
		ColorChat(id,RED,"Ten gracz musi sie zalogowac na swoje konto!");
		return PLUGIN_CONTINUE;
	}
	wybrany = tempid;
	ColorChat(id,TEAM_COLOR, "[CS:GO]^x01 Wybrales^x04 %s", tempname);

	if(opcja == 1)
		menuChoseWeapon(id);
	else
		console_cmd(id, "messagemode ile");
	return PLUGIN_CONTINUE;
}

public pobierz(id)
{
	new text[192]
	read_argv(1,text,191)
	format(ilosc, charsmax(ilosc), "%s", text);
	dawaj(id)
}
	
public dawaj(id)
{
	if(opcja == 2)
	{
		new name[33];
		get_user_name(wybrany, name, 32);
		csgo_set_user_key(wybrany,csgo_get_user_key(wybrany)+str_to_num(ilosc));
		ColorChat(id,TEAM_COLOR, "[CS:GO]^x01 Dales Graczowi:^x04 %s^x01, Kluczy:^x03 %d", name, str_to_num(ilosc));
	}
	if(opcja == 3)
	{
		new name[33];
		get_user_name(wybrany, name, 32);
		csgo_set_user_chest(wybrany,csgo_get_user_chest(wybrany)+str_to_num(ilosc))
		ColorChat(id,TEAM_COLOR, "[CS:GO]^x01 Dales Graczowi:^x04 %s^x01, Skrzyn:^x03 %d", name, str_to_num(ilosc));
	}

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

			if(csgo_get_user_skin(wybrany, i)>0)
			{
				formatex(szText, 127, "%s\w | (sztuk:\d %d\w)", nameSkin, csgo_get_user_skin(wybrany, i));
			}
			else formatex(szText, 127, "\d%s\r (Brak)", nameSkin);

			menu_additem(menu, szText, string);
		}
		else if(csgo_get_skin_weaponid(i)==WEAPONS[item-1][0])
		{
			formatex(string, 32, "%d %d", i, csgo_get_skin_weaponid(i));

			if(csgo_get_user_skin(wybrany, i)>0)
			{
				formatex(szText, 127, "%s\w | (sztuk:\d %d\w)", nameSkin, csgo_get_user_skin(wybrany, i));
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
	new name[33],nazwa[32], access, callback, Data2[4][33], id_skina[33];
	menu_item_getinfo(menu, item, access, Data2[0], 32, Data2[1], 32, callback);
	parse(Data2[0], id_skina, 32);

	csgo_get_skin_name(str_to_num(id_skina), nazwa, charsmax(nazwa));
	get_user_name(wybrany, name, 32);

	csgo_set_user_skin(wybrany, str_to_num(id_skina), csgo_get_user_skin(id, str_to_num(id_skina))+1);
	ColorChat(id,TEAM_COLOR, "[CS:GO]^x01 dales:^x04 %s^x01, Graczowi:^x04 %s", nazwa, name);
	return PLUGIN_CONTINUE;
}