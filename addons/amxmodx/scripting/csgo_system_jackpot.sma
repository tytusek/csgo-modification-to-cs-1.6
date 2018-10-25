#include <amxmodx>
#include <colorchat>
#include <csgo>

#define MIN_VALUE 50 // minimalna cena w loterii
#define MAX_VALUE 250 // maksymalna cena w loterii

new pula_gracza[33];
new maxplayers, nextlosowanie, maxpula;

public plugin_init()
{
	register_plugin("Losowanie", "1.0", "Linux`");
	register_clcmd("cena_puli", "LosPula_Wystawienie");	

	register_clcmd("say /jackpot", "LosMenu");
	register_clcmd("say_team /jackpot", "LosMenu");

	register_clcmd("say /pula", "PulaInfo");
	register_clcmd("say_team /pula", "PulaInfo");

	maxplayers = get_maxplayers();
	nextlosowanie = -1;
	maxpula = 0;
}
public client_authorized(id)
{
	pula_gracza[id] = 0;
}
public client_disconnect(id)
{
	if(pula_gracza[id])
	{
		maxpula -= pula_gracza[id];
		pula_gracza[id] = 0;
	}
}
public LosMenu(id)
{
	new opis[65];
	if(nextlosowanie >= 0)
		format(opis, charsmax(opis), "Pula Nagrod: %i Monet\r (Koniec puli za %i minut)", maxpula, nextlosowanie);
	else
		format(opis, charsmax(opis), "Pula Nagrod: %i Monet\r (Nikt nie gra, badz pierwszy!)", maxpula);

	new menu = menu_create(opis, "LosMenu_Handler");
	menu_additem(menu, "Dolacz do puli");
	menu_additem(menu, "Wyswietl graczy w puli");
	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}
public LosMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	switch(item)
	{
		case 0:
		{
			client_print(id, print_center, "Podaj Cene");
			client_cmd(id, "messagemode cena_puli");
		}
		case 1:
		{
			if(nextlosowanie >= 0)
			{
				new pula;
				new name[32], opis[65];
				new menu = menu_create("Lista graczy bioracych udzial w losowaniu:", "LosMenu_Handler2");
				for(new i = 1; i <= maxplayers; i ++)
				{
					if(!is_user_connected(i))
						continue;

					pula = pula_gracza[i];
					if(!pula)
						continue;

					get_user_name(i, name, charsmax(name));
					format(opis, charsmax(opis), "%s (%i Monet | Szansa na Win: %0.1f%%)", name, pula, float((pula*100)/maxpula));
					menu_additem(menu, opis);
				}

				menu_display(id, menu);
			}
			else
				client_print(id, print_chat, "[jackpot] Aktualnie nikt nie bierze udzialu w losowaniu, badz pierwszy!");
		}
	}
	return PLUGIN_CONTINUE;
}
public LosMenu_Handler2(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}

	LosMenu(id);
	return PLUGIN_CONTINUE;
}
public LosPula_Wystawienie(id)
{
	if(pula_gracza[id])
	{
		client_print(id, print_chat, "[jackpot] Aktualnie bierzesz juz udzial w losowaniu. Musisz zaczekac na jego koniec!");
		return PLUGIN_CONTINUE;
	}

	new arg[8];
	read_argv(1, arg, charsmax(arg));
	new cena = str_to_num(arg);
	new kasa = csgo_get_user_coin(id);

	if(kasa < MIN_VALUE)
	{
		LosMenu(id);
		client_print(id, print_chat, "[jackpot] Niepoprawna wartosc (MIN: %i, MAX. %i)", MIN_VALUE, (kasa > MAX_VALUE)? MAX_VALUE: kasa);
		return PLUGIN_CONTINUE;
	}
	if(cena > kasa)
	{
                LosMenu(id);
		client_print(id, print_chat, "Masz za malo");
		return PLUGIN_HANDLED;
	}
	if(cena < MIN_VALUE || cena > MAX_VALUE)
	{
		LosMenu(id);
		client_print(id, print_chat, "[jackpot] Niepoprawna wartosc (MIN: %i, MAX. %i)", MIN_VALUE, (kasa > MAX_VALUE)? MAX_VALUE: kasa);
		return PLUGIN_CONTINUE;
	}

	new time = get_timeleft()/60;
	if(time <= 6)
	{
		LosMenu(id);
		client_print(id, print_chat, "[jackpot] Mozliwosc dolaczenia do puli zostala zablokowana na 6 minut przed koncem mapy.");
		return PLUGIN_CONTINUE;
	}

	if(nextlosowanie == -1)
	{
		nextlosowanie = 5;
		set_task(60.0, "ZakonczLosowanie");
	}

	maxpula += cena;
	pula_gracza[id] = cena;
	csgo_set_user_coin(id, kasa-cena);

	new name[32];
	get_user_name(id, name, charsmax(name));
	ColorChat(0, GREEN, "[jackpot]^x01 Gracz^x03 %s^x01 wzial udzial w puli nagrod, dodajac^x03 %i Monety^x01.", name, cena);
	return PLUGIN_CONTINUE;
}
public PulaInfo(id)
{
	client_print(id, print_chat, "[jackpot] Aktualnie w puli nagrod znajduje sie: %i Monet", maxpula);
}
public ZakonczLosowanie()
{
	if(nextlosowanie > 0)
	{
		nextlosowanie --;
		set_task(60.0, "ZakonczLosowanie");
	}
	else if(maxpula)
	{
		new id_wygrywajacego = LosowanieGracza();
		if(is_user_connected(id_wygrywajacego))
		{
			new kasa = csgo_get_user_coin(id_wygrywajacego)+maxpula;
			if(kasa > 16000)
				kasa = 16000;

			new name[33];
			get_user_name(id_wygrywajacego, name, charsmax(name));
			csgo_set_user_coin(id_wygrywajacego, kasa);
			ColorChat(0, GREEN, "[jackpot]^x01 Gracz^x03 %s^x01 wygral ^x03 %i Monety^x01 w puli nagrod! Gratulujemy.", name, maxpula);
		}
		else
			ColorChat(0, GREEN, "[jackpot]^x01 Nikt nie wygral ^x03 %i Monet^x01 w puli nagrod! Moze nastepnym razem dopisze komus szczescie.", maxpula);

		maxpula = 0;
		nextlosowanie = -1;
	}
}
public LosowanieGracza()
{
	new wylosowany[33][2];
	new players, id_wylosowanego;

	for(new i = 1; i <= maxplayers; i ++)
	{
		if(!is_user_connected(i))
			continue;

		new pula = pula_gracza[i];
		if(!pula)
			continue;

		pula_gracza[i] = 0;
		wylosowany[players][0] = i;
		wylosowany[players][1] = pula/100;
		players ++;
	}
	if(players)
	{
		new ilosc_ponawianych_losowan = 64;
		for(new l = 1; l <= ilosc_ponawianych_losowan; l ++)
		{
			new id = random(players);
			if(random_num(1, 100) <= wylosowany[id][1])
			{
				id_wylosowanego = id;
				break;
			}
		}
	}

	return wylosowany[id_wylosowanego][0];
}