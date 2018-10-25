#include <amxmodx>
#include <csgo>
#include <ColorChat>
#include <reapi>

public plugin_init()
{
	register_plugin("[CSGO] System: Account", "1.1.0", "TyTuS");
	register_clcmd("say", "blockCMD");
	register_clcmd("say_team", "blockCMD");
	register_clcmd("say /konto", "menuAccount");
	register_concmd("getpassword", "enterPassword");
	register_concmd("register", "registerUser");

	RegisterHookChain(RG_CBasePlayer_Spawn, "Odrodzenie", true);
}

public blockCMD(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	if(!csgo_get_user_allow(id))
	{
		ColorChat(id, RED, "Zrob konto, aby moc pisac z innymi!");
		menuAccount(id);
		return PLUGIN_HANDLED;	
	}
	return PLUGIN_CONTINUE;	
}

public Odrodzenie(id)
{
	if(!csgo_get_user_loaded(id) || csgo_get_user_allow(id))
		return PLUGIN_CONTINUE;

	if(csgo_get_user_register(id))
	{
		if(get_user_time(id,1)>120)
		{
			new name[33];
			get_user_name(id, name, 32);
			log_to_file("bad_password.log","%s Nie wpisal hasla w ciagu 2 minut", name);
			server_cmd("kick #%d ^"Zostales wyrzucony za nie wpisanie hasla w ciagu 2 minut!^"", get_user_userid(id));
			return PLUGIN_CONTINUE;
		}
		ColorChat(id, RED, "Wpisz haslo, aby korzystac z konta");
		cmdExecute(id, "messagemode getpassword");
		return PLUGIN_CONTINUE;
	}
	else
	{
		menuAccount(id);
	}
	return PLUGIN_CONTINUE;
}
public menuAccount(id)
{
	if(!csgo_get_user_loaded(id))
	{
		ColorChat(id, RED,"Poczekaj, az zaladuje Ci sie konto!");
		return PLUGIN_CONTINUE;
	}
	new titleMenu[64], registerMenu[64], loginMenu[64], showPasswordMenu[64], name[33], menu;
	get_user_name(id, name, charsmax(name));

	formatex(titleMenu, charsmax(titleMenu), "Witaj\y %s", name);
	formatex(registerMenu, charsmax(registerMenu), "%s", csgo_get_user_register(id) ? "\dZarejestruj sie!" : "Zarejestruj sie!");
	formatex(loginMenu, charsmax(loginMenu), "%s", csgo_get_user_allow(id) ? "\dZaloguj sie!" : "Zaloguj sie!"); 
	formatex(showPasswordMenu, charsmax(showPasswordMenu), "%s", csgo_get_user_allow(id) ? "Pokaz moje haslo" : "\dPokaz moje haslo"); 

	menu=menu_create(titleMenu, "menuAccountHandler");
	menu_additem(menu, registerMenu);
	menu_additem(menu, loginMenu);
	menu_additem(menu, showPasswordMenu);
	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}

public menuAccountHandler(id, menu, item)
{
	if(item++ == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	switch(item)
	{
		case 1:
		{
			if(csgo_get_user_register(id))
			{
				ColorChat(id, NORMAL, "Jestes juz zarejestrowany");
				return PLUGIN_CONTINUE;
			}

			cmdExecute(id, "messagemode register");
		} 
		case 2:
		{
			if(csgo_get_user_allow(id))
			{
				ColorChat(id, NORMAL, "Jestes juz zalogowany");
				return PLUGIN_CONTINUE;
			}
			cmdExecute(id, "messagemode getpassword");
		} 
		case 3:
		{
			if(!csgo_get_user_allow(id))
			{
				ColorChat(id, NORMAL, "Musisz sie zalogowac!");
				return PLUGIN_CONTINUE;
			}
			new haslo[33]=0;
			csgo_get_user_password(id, haslo, charsmax(haslo));
			ColorChat(id, NORMAL,"Twoje haslo to^x04 %s", haslo);
		}
	}
	return PLUGIN_CONTINUE;
}

public registerUser(id)
{
	if(csgo_get_user_register(id) || !csgo_get_user_loaded(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE;

	new Data[32]=0, name[33];
	read_args(Data, charsmax(Data));
	get_user_name(id, name, charsmax(name));
	remove_quotes(Data);

	if(strlen(Data) < 5)
	{
		ColorChat(id, RED, "twoje haslo jest za krotkie minimum 6 znakow");
		cmdExecute(id, "messagemode register");
		return PLUGIN_CONTINUE;
	}

	if(equali(Data, "123456"))
	{
		ColorChat(id, RED, "twoje haslo jest zbyt proste");
		cmdExecute(id, "messagemode register");
		return PLUGIN_CONTINUE;
	}

	if(equali(Data, name))
	{
		ColorChat(id, RED, "twoje haslo, nie moze byc jak twoj nick!");
		cmdExecute(id, "messagemode register");
		return PLUGIN_CONTINUE;
	}

	cmdExecute(id, "setinfo _csgomod ^"%s^"", Data)
	ColorChat(id,GREEN,"^x01 Zrobiles nowe konto, twoje haslo od teraz to^x04 %s", Data);
	ColorChat(id,GREEN,"^x01 Zrobiles nowe konto, twoje haslo od teraz to^x04 %s", Data);
	csgo_set_user_password(id, Data)

	return PLUGIN_CONTINUE;
}

public enterPassword(id)
{
	if(!csgo_get_user_loaded(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE

	new Data[32]=0, haslo[33]=0, name[33]=0;
	static bad_password[33];

	read_args(Data, charsmax(Data));
	get_user_name(id, name, charsmax(name));
	csgo_get_user_password(id, haslo, charsmax(haslo));
	remove_quotes(Data);
	
	if(equali(Data,haslo))
	{
		csgo_set_user_allow(id, true);
		ColorChat(id,GREEN,"Wpisales poprawnie haslo, mozesz normalnie korzystac z tego konta!");
		cmdExecute(id, "setinfo _csgomod ^"%s^"", Data);
		return PLUGIN_CONTINUE;
	}
	else
	{
		bad_password[id]++;

		if(bad_password[id]>=3)
		{
			log_to_file("bad_password.log","%s wpisal zle haslo 3 razy", name);
			server_cmd("kick #%d ^"Zostales wyrzucony za 3 blednych prob wpisania hasla!^"", get_user_userid(id));
			return PLUGIN_CONTINUE;
		}
		ColorChat(id,RED,"Wprowadziles bledne haslo!");
		cmdExecute(id, "messagemode getpassword");
	} 
	return PLUGIN_CONTINUE;
}

stock cmdExecute( id , const szText[] , any:... ) 
{
    #pragma unused szText
    if ( id == 0 || is_user_connected( id ) ) {
    	new szMessage[ 256 ];
    	format_args( szMessage ,charsmax( szMessage ) , 1 );
        message_begin( id == 0 ? MSG_ALL : MSG_ONE, 51, _, id );
        write_byte( strlen( szMessage ) + 2 );
        write_byte( 10 );
        write_string( szMessage );
        message_end();
    }
}