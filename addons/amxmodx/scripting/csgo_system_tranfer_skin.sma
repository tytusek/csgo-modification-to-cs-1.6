#include <amxmodx>
#include <ColorChat>
#include <csgo>

new ilosc_monet[33], ilosc_kluczy[33], ilosc_skrzyn[33], playerChoseSkin[33][3], playerChoseSkinNumber[33], wybrany_gracz[33];
new bool:playerConfirmTransfer[33];

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
	register_plugin("[CSGO] System: Transfer Skin", "1.0", "TyTuS")
	register_clcmd("say /wymien", "tranferSkinMenu");
}
public plugin_natives()
{
	register_native("csgo_set_user_transfer_menu", "tranferSkinMenu", 1);
}

public client_putinserver(id)
	resetData(id);

public client_disconnect(id)
	resetData(id);

public resetData(id)
{
	wybrany_gracz[id]=0;

	for(new i=0; i<3; i++)
		playerChoseSkin[id][i]=0;

	ilosc_monet[id]=0;
	ilosc_skrzyn[id]=0;
	ilosc_kluczy[id]=0;
	playerChoseSkinNumber[id]=0;
	playerConfirmTransfer[id]=false;
}

public tranferSkinMenu(id)
{
	if(!csgo_get_user_allow(id))
	{
		client_print(id, 3, "Musisz posiadac /konto");
		return PLUGIN_CONTINUE;
	}
	// add function checking what player got a skin 

	new menu = menu_create("Ustal Swoja Oferte", "tranferSkinMenuHandler");
	new szSkin[128], szMonety[33], szKluczy[33], szSkrzyn[33],szGracz[128], skinName[20], skinName2[20], skinName3[20], name[33];

	get_user_name(wybrany_gracz[id], name, 32);
	csgo_get_skin_name(playerChoseSkin[id][0], skinName, charsmax(skinName));
	csgo_get_skin_name(playerChoseSkin[id][1], skinName2, charsmax(skinName2));
	csgo_get_skin_name(playerChoseSkin[id][2], skinName3, charsmax(skinName3));

	formatex(szSkin, charsmax(szSkin), "Twoj Skin:\y %s | %s | %s", playerChoseSkin[id][0] ? skinName : "Nacisnij 1 aby wybrac", playerChoseSkin[id][1] ? skinName2 : "Nacisnij 1 aby wybrac", playerChoseSkin[id][2] ? skinName3 : "Nacisnij 1 aby wybrac");  
	formatex(szMonety, charsmax(szMonety), "Twoje Monety: \y[%d]", ilosc_monet[id]);
	formatex(szKluczy, charsmax(szKluczy), "Twoje Klucze: \y[%d]", ilosc_kluczy[id]);
	formatex(szSkrzyn, charsmax(szSkrzyn), "Twoje Skrzynie: \y[%d]", ilosc_skrzyn[id]);
	formatex(szGracz, charsmax(szGracz), "Z kim sie wymieniasz?:\y %s", wybrany_gracz[id] ? name : "Nacisnij 5 aby wybrac");  

	menu_additem(menu, szSkin);
	menu_additem(menu, szMonety);
	menu_additem(menu, szKluczy);
	menu_additem(menu, szSkrzyn);
	menu_additem(menu, szGracz);
	menu_additem(menu, "Wymien Sie!");
	menu_additem(menu, "Usun oferte");
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);

	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}

public tranferSkinMenuHandler(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	if(item!=7 && playerConfirmTransfer[id])
	{
		ColorChat(id, RED, "Nie mozesz nic zmienic w wymianie gdy potwierdziles. Kliknij 7 (Usun oferte), aby odblokowac wymiane");
		tranferSkinMenu(id);
		return PLUGIN_CONTINUE;
	}
	switch(item)
	{
		case 1: setSlotSkin(id);
		case 2: pobierz_ilosc_monet(id);
		case 3: pobierz_ilosc_kluczy(id);
		case 4: pobierz_ilosc_skrzyn(id);
		case 5: wybierz_gracza(id);	
		case 6:
		{
			if(wybrany_gracz[wybrany_gracz[id]]==id)
				wymien_oferte(id);
			else
			  ColorChat(id, GREEN,"[CS:GO] Gracz, musi wybrac ciebie w swojej ofercie wymiany");		
		}		
		case 7:
		{
			ColorChat(id, GREEN,"[CS:GO] Usunales oferte wymiany");
			resetData(id);
		}	
	}
	return PLUGIN_CONTINUE;
}
public setSlotSkin(id)
{
	new menu = menu_create("Wybierz Skina: ", "setSlotSkinHandler");
	new szSkin[64], szSkin2[64], szSkin3[64], skinName[20], skinName2[20], skinName3[20];

	csgo_get_skin_name(playerChoseSkin[id][0], skinName, charsmax(skinName));
	csgo_get_skin_name(playerChoseSkin[id][1], skinName2, charsmax(skinName2));
	csgo_get_skin_name(playerChoseSkin[id][2], skinName3, charsmax(skinName3));

	formatex(szSkin, charsmax(szSkin), "Twoj Skin [ Slot 1 ] :\y %s", playerChoseSkin[id][0] ? skinName : "Nacisnij 1 aby wybrac");  
	formatex(szSkin2, charsmax(szSkin2), "Twoj Skin [ Slot 2 ] :\y %s", playerChoseSkin[id][1] ? skinName2 : "Nacisnij 2 aby wybrac");
	formatex(szSkin3, charsmax(szSkin3), "Twoj Skin [ Slot 3 ] :\y %s", playerChoseSkin[id][2] ? skinName3 : "Nacisnij 3 aby wybrac");
	menu_additem(menu, szSkin);
	menu_additem(menu, szSkin2);
	menu_additem(menu, szSkin3);
	menu_display(id, menu);
}
public setSlotSkinHandler(id, menu, item)
{
	if(item++==MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	switch(item)
	{
		case 1:
		{
			playerChoseSkinNumber[id]=0;
			menuChoseWeapon(id);
		}
		case 2:
		{
			playerChoseSkinNumber[id]=1;
			menuChoseWeapon(id);
		}
		case 3:
		{
			playerChoseSkinNumber[id]=2;
			menuChoseWeapon(id);
		}
	}
	return PLUGIN_CONTINUE;
}

public pobierz_ilosc_monet(id)
{
	new szMonety[64];
	new menu = menu_create("\rWybierz Ilosc Monet", "pobierz_ilosc_monet_Handle");
	new cb = menu_makecallback("pobierz_ilosc_monet_Cb");

	for(new i = 100; i <= 10000; i+=100)
	{ 
		format(szMonety, charsmax(szMonety), "Monet: \y[%d]", i);  
		menu_additem(menu, szMonety, "0", 0, cb);
	}
	menu_display(id, menu);
}

public pobierz_ilosc_monet_Cb(id, menu, item)
{
	item++;
	if(csgo_get_user_coin(id)<item*200)
		return ITEM_DISABLED;
	return ITEM_ENABLED;
}

public pobierz_ilosc_monet_Handle(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	ilosc_monet[id] = item*100;
	tranferSkinMenu(id);
	return PLUGIN_HANDLED;
}

public pobierz_ilosc_kluczy(id)
{
	new szKlucze[64];
	new menu = menu_create("\rWybierz Ilosc Kluczy", "pobierz_ilosc_kluczy_Handle");
	new cb = menu_makecallback("pobierz_ilosc_kluczy_Cb");

	for(new i = 1; i <= 50; i++)
	{ 
		format(szKlucze, charsmax(szKlucze), "Klucze: \y[%d]", i);  
		menu_additem(menu, szKlucze, "0", 0, cb);
	}
	menu_display(id, menu);
}

public pobierz_ilosc_kluczy_Cb(id, menu, item)
{
	item++;
	if(csgo_get_user_key(id)<item)
		return ITEM_DISABLED;
	return ITEM_ENABLED;
}

public pobierz_ilosc_kluczy_Handle(id, menu, item)
{
	if(item++==MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	ilosc_kluczy[id] = item;
	tranferSkinMenu(id);
	return PLUGIN_HANDLED;
}

public pobierz_ilosc_skrzyn(id)
{
	new szSkrzynie[64];
	new menu = menu_create("\rWybierz Ilosc Skrzyn", "pobierz_ilosc_skrzyn_Handle");
	new cb = menu_makecallback("pobierz_ilosc_skrzyn_Cb");

	for(new i = 1; i <= 50; i++)
	{ 
		format(szSkrzynie, charsmax(szSkrzynie), "Skrzynie: \y[%d]", i);  
		menu_additem(menu, szSkrzynie, "0", 0, cb);
	}
	menu_display(id, menu);
}

public pobierz_ilosc_skrzyn_Cb(id, menu, item)
{
	item++;
	if(csgo_get_user_chest(id)<item)
		return ITEM_DISABLED;
	return ITEM_ENABLED;
}

public pobierz_ilosc_skrzyn_Handle(id, menu, item)
{
	if(item++==MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	ilosc_skrzyn[id] = item;
	tranferSkinMenu(id);
	return PLUGIN_HANDLED;
}

public wymien_oferte(id)
{
	new name[25], nazwa_skina[25], nazwa_skina2[25], nazwa_skina3[25], nazwa_skina_gracza[25], nazwa_skina_gracza2[25], nazwa_skina_gracza3[25], szMojaOferta[250], szJegoOferta[250];

	get_user_name(wybrany_gracz[id], name, charsmax(name));
	csgo_get_skin_name(playerChoseSkin[id][0], nazwa_skina, charsmax(nazwa_skina));
	csgo_get_skin_name(playerChoseSkin[id][1], nazwa_skina2, charsmax(nazwa_skina2));
	csgo_get_skin_name(playerChoseSkin[id][2], nazwa_skina3, charsmax(nazwa_skina3));

	csgo_get_skin_name(playerChoseSkin[wybrany_gracz[id]][0], nazwa_skina_gracza, charsmax(nazwa_skina_gracza));
	csgo_get_skin_name(playerChoseSkin[wybrany_gracz[id]][1], nazwa_skina_gracza2, charsmax(nazwa_skina_gracza2));
	csgo_get_skin_name(playerChoseSkin[wybrany_gracz[id]][2], nazwa_skina_gracza3, charsmax(nazwa_skina_gracza3));

	formatex(szMojaOferta, charsmax(szMojaOferta), "\dMoja Oferta \rSkin[1]:\y %s ^n\rSkin[2]:\y %s ^n\rSkin[3]:\y %s ^n\rMonety: \y[%d] | \rKluczy: \y[%d] | \rSkrzyn: \y[%d]^n", playerChoseSkin[id][0] ? nazwa_skina : "Brak", playerChoseSkin[id][1] ? nazwa_skina2 : "Brak", playerChoseSkin[id][2] ? nazwa_skina3 : "Brak", ilosc_monet[id], ilosc_kluczy[id], ilosc_skrzyn[id]); 
	formatex(szJegoOferta, charsmax(szJegoOferta), "\dOferta:\y %s \rSkin[1]:\y %s ^n\rSkin[2]:\y %s ^n\rSkin[3]:\y %s ^n\rMonety: \y[%d] | \rKluczy: \y[%d] | \rSkrzyn: \y[%d]^n", name, playerChoseSkin[wybrany_gracz[id]][0] ? nazwa_skina_gracza : "Brak", playerChoseSkin[wybrany_gracz[id]][1] ? nazwa_skina_gracza2 : "Brak", playerChoseSkin[wybrany_gracz[id]][2] ? nazwa_skina_gracza3 : "Brak", ilosc_monet[wybrany_gracz[id]], ilosc_kluczy[wybrany_gracz[id]], ilosc_skrzyn[wybrany_gracz[id]]);  
	new menu = menu_create("Czy zgadzasz sie na wymiane?", "wymien_ofertehandler");
	menu_additem(menu, "Cofnij do swojej oferty^n");
	menu_additem(menu, szMojaOferta);
	menu_additem(menu, szJegoOferta);
	menu_additem(menu, "Potwierdzam!");
	menu_display(id, menu);
	
}

public wymien_ofertehandler(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	switch(item)
	{
		
		case 1: tranferSkinMenu(id);
		case 4:
		{
			new name[33], nazwa_skina[25], nazwa_skina2[25], nazwa_skina3[25], nazwa_skina_gracza[25], nazwa_skina_gracza2[25], nazwa_skina_gracza3[25], szMojaOferta[250], szJegoOferta[250];

			get_user_name(id, name, charsmax(name));
			csgo_get_skin_name(playerChoseSkin[id][0], nazwa_skina, charsmax(nazwa_skina));
			csgo_get_skin_name(playerChoseSkin[id][1], nazwa_skina2, charsmax(nazwa_skina2));
			csgo_get_skin_name(playerChoseSkin[id][2], nazwa_skina3, charsmax(nazwa_skina3));

			csgo_get_skin_name(playerChoseSkin[wybrany_gracz[id]][0], nazwa_skina_gracza, charsmax(nazwa_skina_gracza));
			csgo_get_skin_name(playerChoseSkin[wybrany_gracz[id]][1], nazwa_skina_gracza2, charsmax(nazwa_skina_gracza2));
			csgo_get_skin_name(playerChoseSkin[wybrany_gracz[id]][2], nazwa_skina_gracza3, charsmax(nazwa_skina_gracza3));

			formatex(szJegoOferta, charsmax(szJegoOferta), "\dOferta:\y %s \rSkin[1]:\y %s ^n\rSkin[2]:\y %s ^n\rSkin[3]:\y %s ^n\rMonety: \y[%d] | \rKluczy: \y[%d] | \rSkrzyn: \y[%d]^n", name, playerChoseSkin[id][0] ? nazwa_skina : "Brak", playerChoseSkin[id][1] ? nazwa_skina2 : "Brak", playerChoseSkin[id][2] ? nazwa_skina3 : "Brak", ilosc_monet[id], ilosc_kluczy[id], ilosc_skrzyn[id]); 
			formatex(szMojaOferta, charsmax(szMojaOferta), "\dMoja oferta \rSkin[1]:\y %s ^n\rSkin[2]:\y %s ^n\rSkin[3]:\y %s ^n\rMonety: \y[%d] | \rKluczy: \y[%d] | \rSkrzyn: \y[%d]^n", playerChoseSkin[wybrany_gracz[id]][0] ? nazwa_skina_gracza : "Brak", playerChoseSkin[wybrany_gracz[id]][1] ? nazwa_skina_gracza2 : "Brak", playerChoseSkin[wybrany_gracz[id]][2] ? nazwa_skina_gracza3 : "Brak", ilosc_monet[wybrany_gracz[id]], ilosc_kluczy[wybrany_gracz[id]], ilosc_skrzyn[wybrany_gracz[id]]); 
			new menu2 = menu_create("Oferta wymiany:", "menu_wymien");
			menu_additem(menu2, szMojaOferta);
			menu_additem(menu2, szJegoOferta);
			menu_additem(menu2, "\rAnuluj^n");
			menu_additem(menu2, "Potwierdz");
			menu_display(wybrany_gracz[id], menu2);
			playerConfirmTransfer[wybrany_gracz[id]]=true;
			playerConfirmTransfer[id]=true;
		}
	}
	return PLUGIN_CONTINUE;
}
public menu_wymien(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}

	switch(item)
	{
		case 3:
		{
			resetData(id);
			resetData(wybrany_gracz[id]);
			ColorChat(id, RED, "Gracz odrzucil oferte wymiany");
			ColorChat(wybrany_gracz[id], RED, "Gracz odrzucil oferte wymiany");
		}	
		case 4: transferItem(id, wybrany_gracz[id]);
	
	}
	return PLUGIN_CONTINUE;
}
public transferItem(id, id2)
{
	if(!is_user_connected(id2) || !is_user_connected(id) || !validOffer(id) || !validOffer(id2))
		return PLUGIN_CONTINUE;

	new name[25], name2[25], nazwa_skina[25], nazwa_skina2[25], nazwa_skina3[25], nazwa_skina_gracza[25], nazwa_skina_gracza2[25], nazwa_skina_gracza3[25];
	get_user_name(id, name, 32);
	get_user_name(id2, name2, 32);

	if(!playerConfirmTransfer[id])
	{
		resetData(id);
		ColorChat(id2, RED, "Wymiana sie nie odbyla, poniewaz %s zresetowal oferte", name);	
		return PLUGIN_CONTINUE;
	}
	if(!playerConfirmTransfer[id2])
	{
		resetData(id2);
		ColorChat(id, RED, "Wymiana sie nie odbyla, poniewaz %s zresetowal oferte", name2);	
		return PLUGIN_CONTINUE;
	}

	csgo_get_skin_name(playerChoseSkin[id][0], nazwa_skina, charsmax(nazwa_skina));
	csgo_get_skin_name(playerChoseSkin[id][1], nazwa_skina2, charsmax(nazwa_skina2));
	csgo_get_skin_name(playerChoseSkin[id][2], nazwa_skina3, charsmax(nazwa_skina3));
	csgo_get_skin_name(playerChoseSkin[id2][0], nazwa_skina_gracza, charsmax(nazwa_skina_gracza));
	csgo_get_skin_name(playerChoseSkin[id2][1], nazwa_skina_gracza2, charsmax(nazwa_skina_gracza2));
	csgo_get_skin_name(playerChoseSkin[id2][2], nazwa_skina_gracza3, charsmax(nazwa_skina_gracza3));

	for(new i=0; i<3;i++)
	{
		csgo_set_user_skin(id, playerChoseSkin[id2][i], csgo_get_user_skin(id, playerChoseSkin[id2][i])+1);
		csgo_set_user_skin(id, playerChoseSkin[id][i], csgo_get_user_skin(id, playerChoseSkin[id][i])-1);

		csgo_set_user_skin(id2, playerChoseSkin[id][i], csgo_get_user_skin(id2, playerChoseSkin[id][i])+1);
		csgo_set_user_skin(id2, playerChoseSkin[id2][i], csgo_get_user_skin(id2, playerChoseSkin[id2][i])-1);

		for(new k=0; k<sizeof(WEAPONS); k++)
		{
			if(csgo_get_skin_weaponid(playerChoseSkin[id][i])==WEAPONS[k][0])
			{
				csgo_set_user_hold_skin(id, k, 0);
			}

			if(csgo_get_skin_weaponid(playerChoseSkin[id2][i])==WEAPONS[k][0])
			{
				csgo_set_user_hold_skin(id2, k, 0);
			}
		}
	}
	csgo_set_user_coin(id, csgo_get_user_coin(id)+ilosc_monet[id2]);
	csgo_set_user_coin(id, csgo_get_user_coin(id)-ilosc_monet[id]);

	csgo_set_user_coin(id2, csgo_get_user_coin(id2)+ilosc_monet[id]);
	csgo_set_user_coin(id2, csgo_get_user_coin(id2)-ilosc_monet[id2]);

	csgo_set_user_key(id, csgo_get_user_key(id)+ilosc_kluczy[id2]);
	csgo_set_user_key(id, csgo_get_user_key(id)-ilosc_kluczy[id]);

	csgo_set_user_key(id2, csgo_get_user_key(id2)+ilosc_kluczy[id]);
	csgo_set_user_key(id2, csgo_get_user_key(id2)-ilosc_kluczy[id2]);

	csgo_set_user_chest(id, csgo_get_user_chest(id)+ilosc_skrzyn[id2]);
	csgo_set_user_chest(id, csgo_get_user_chest(id)-ilosc_skrzyn[id]);

	csgo_set_user_chest(id2, csgo_get_user_chest(id2)+ilosc_skrzyn[id]);
	csgo_set_user_chest(id2, csgo_get_user_chest(id2)-ilosc_skrzyn[id2]);

	log_to_file("csgo_wymiana.log", "Gracz %s dostal -> %s | %s | %s | Monet: %d | Kluczy: %d | Skrzyn: %d", name2, playerChoseSkin[id][0] ? nazwa_skina : "Brak", playerChoseSkin[id][1] ? nazwa_skina2 : "Brak", playerChoseSkin[id][2] ? nazwa_skina3 : "Brak", ilosc_monet[id], ilosc_kluczy[id], ilosc_skrzyn[id]);
	log_to_file("csgo_wymiana.log", "Gracz %s dostal -> %s | %s | %s | Monet: %d | Kluczy: %d | Skrzyn: %d", name, playerChoseSkin[id2][0] ? nazwa_skina_gracza : "Brak", playerChoseSkin[id2][1] ? nazwa_skina_gracza2 : "Brak", playerChoseSkin[id2][2] ? nazwa_skina_gracza3 : "Brak", ilosc_monet[id2], ilosc_kluczy[id2], ilosc_skrzyn[id2]);
	ColorChat(id, RED, "Gracz %s otrzymal: %s | %s | %s | Monet: %d | Kluczy: %d | Skrzyn: %d", name, playerChoseSkin[id2][0] ? nazwa_skina_gracza : "Brak", playerChoseSkin[id2][1] ? nazwa_skina_gracza2 : "Brak", playerChoseSkin[id2][2] ? nazwa_skina_gracza3 : "Brak", ilosc_monet[id2], ilosc_kluczy[id2], ilosc_skrzyn[id2]);
	ColorChat(id, RED, "Gracz %s otrzymal: %s | %s | %s | Monet: %d | Kluczy: %d | Skrzyn: %d", name2, playerChoseSkin[id][0] ? nazwa_skina : "Brak", playerChoseSkin[id][1] ? nazwa_skina2 : "Brak", playerChoseSkin[id][2] ? nazwa_skina3 : "Brak", ilosc_monet[id], ilosc_kluczy[id], ilosc_skrzyn[id]);
	resetData(id);
	resetData(id2);
	return PLUGIN_CONTINUE;
}

public validOffer(id)
{
	if(csgo_get_user_coin(id)>ilosc_monet[id] || csgo_get_user_key(id)>ilosc_kluczy[id] || csgo_get_user_chest(id)>ilosc_skrzyn[id])
	{
		return true;
	}

	if(playerChoseSkin[id][0]==0 && playerChoseSkin[id][1]==0 && playerChoseSkin[id][2]==0)
	{
		return true;
	}

	new countSkin=1;

	if(playerChoseSkin[id][0]==playerChoseSkin[id][1] && playerChoseSkin[id][0]!=0 || playerChoseSkin[id][0]==playerChoseSkin[id][2] && playerChoseSkin[id][0]!=0 || playerChoseSkin[id][2]==playerChoseSkin[id][1] && playerChoseSkin[id][0]!=0)
	{
		countSkin=2;
	}

	if(playerChoseSkin[id][0]==playerChoseSkin[id][1] && playerChoseSkin[id][1]==playerChoseSkin[id][2] && playerChoseSkin[id][0]!=0 && playerChoseSkin[id][2]!=0)
	{
		countSkin=3;
	}

	for(new i=0; i<3;i++)
	{
		if(playerChoseSkin[id][i]!=0 && csgo_get_user_skin(id, playerChoseSkin[id][i])>=countSkin)
		{
			return true;
		}
	}
	resetData(id);
	ColorChat(id,GREEN,"Miales wieksza oferte niz posiadasz w ekwipunku, sprobuj ponownie! 2");
	return false;
}

public wybierz_gracza(id)
{
	new menu = menu_create("Wybierz gracza:", "wybierz_gracza_handler");
	new players[32], pnum, tempid;
	new szName[32], szTempid[10];
	get_players(players, pnum);
	for(new i; i<pnum; i++)
	{
		tempid = players[i];
		get_user_name(tempid, szName, charsmax(szName));
		num_to_str(tempid, szTempid, charsmax(szTempid));
		menu_additem(menu, szName, szTempid, 0);
	}
	menu_display(id, menu, 0);
}

public wybierz_gracza_handler(id, menu, item)
{
	if(item == MENU_EXIT)
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

	if(tempid==id)
		return PLUGIN_CONTINUE;

	if(!csgo_get_user_allow(tempid))
	{
		ColorChat(id,GREEN,"ten gracz musi sie zalogowac");
		return PLUGIN_CONTINUE;
	}
	wybrany_gracz[id] = tempid;
	tranferSkinMenu(id);
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
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
	playerChoseSkin[id][playerChoseSkinNumber[id]] = str_to_num(id_skina);

	if(csgo_get_user_skin(id,playerChoseSkin[id][playerChoseSkinNumber[id]])<1)
	{
		ColorChat(id, RED,"Nie posiadasz tego skina, jesli chcesz mozesz go kupic^x04 -->^x03 /sklepsms")
		playerChoseSkin[id][playerChoseSkinNumber[id]]=0;
		tranferSkinMenu(id);
		return PLUGIN_CONTINUE;
	}

	if(playerChoseSkin[id][0]==playerChoseSkin[id][1] && playerChoseSkin[id][1]==playerChoseSkin[id][2] && playerChoseSkin[id][0]==playerChoseSkin[id][2] && playerChoseSkin[id][0]!=0 && csgo_get_user_skin(id, playerChoseSkin[id][playerChoseSkinNumber[id]])<3)
	{
		ColorChat(id, RED,"Za malo sztuk masz tego skina, jesli chcesz mozesz go kupic^x04 -->^x03 /sklepsms")
		playerChoseSkin[id][playerChoseSkinNumber[id]]=0;
		tranferSkinMenu(id);
		return PLUGIN_CONTINUE;
	}
 
	if((playerChoseSkin[id][0]==playerChoseSkin[id][1] && playerChoseSkin[id][0]!=0 && csgo_get_user_skin(id, playerChoseSkin[id][playerChoseSkinNumber[id]])<2) || (playerChoseSkin[id][1]==playerChoseSkin[id][2] && playerChoseSkin[id][1]!=0 && csgo_get_user_skin(id, playerChoseSkin[id][playerChoseSkinNumber[id]])<2) || (playerChoseSkin[id][0]==playerChoseSkin[id][2] && playerChoseSkin[id][2]!=0 && csgo_get_user_skin(id, playerChoseSkin[id][playerChoseSkinNumber[id]])<2))
	{
		ColorChat(id, RED,"Za malo sztuk masz tego skina, jesli chcesz mozesz go kupic^x04 -->^x03 /sklepsms")
		playerChoseSkin[id][playerChoseSkinNumber[id]]=0;
		tranferSkinMenu(id);
		return PLUGIN_CONTINUE;
	}
	tranferSkinMenu(id);
	return PLUGIN_CONTINUE;
}
//problem wyzej z tym 

