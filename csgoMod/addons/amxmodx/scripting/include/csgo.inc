#if defined _csgo_included
  #endinput
#endif
#define _csgo_included

/*------------------------------
Ustawia ilosc monet danemu graczowi
id = id gracza,
wartosc = ilosc monet
------------------------------*/
native csgo_set_user_coin(id, wartosc);

/*------------------------------
Zwraca ilosc monet danego gracza
------------------------------*/
native csgo_get_user_coin(id);

/*------------------------------
Ustawia ilosc kluczy danemu graczowi
id = id gracza,
wartosc = ilosc klczuy
------------------------------*/
native csgo_set_user_key(id, wartosc);

/*------------------------------
Zwraca ilosc kluczy danego gracza
------------------------------*/
native csgo_get_user_key(id);

/*------------------------------
Ustawia ilosc skrzyn danemu graczowi
id = id gracza,
wartosc = ilosc skrzyn
------------------------------*/
native csgo_set_user_chest(id, wartosc);

/*------------------------------
Zwraca ilosc skrzyn danego gracza
------------------------------*/
native csgo_get_user_chest(id);

/*------------------------------
Ustawia ilosc skinow, danemu graczowi, dla danego skina,
id = id gracza,
skin_id = id skina, 
wartosc = ile skinow ma ustawic.
------------------------------*/
native csgo_set_user_skin(id, skin_id, wartosc);

/*------------------------------
Zwraca ilosc skinow danego gracza, dla danego skina,
id = id gracza,
skin_id = id skina
------------------------------*/
native csgo_get_user_skin(id, skin_id);

/*------------------------------
Ustawia id_skin, dla danego skina,
id = id gracza,
weaponid = id miejsca broni w silniku // [ jeszcze do poprawki]
wartosc = id broni dla miejsca

// w silniku

public setUserHoldSkin(id, weaponid, wartosc)
{
	UsingW[weaponid][id]=wartosc;
}

//
------------------------------*/
native csgo_set_user_hold_skin(id, weaponid, wartosc);

/*------------------------------
Zwraca id skina, dla weaponid
id = id gracza,
weaponid = id miejsca broni w silniku // [ jeszcze do poprawki]

// w silniku

public getUserHoldSkin(id, weaponid)
  return UsingW[weaponid][id];

// 
------------------------------*/
native csgo_get_user_hold_skin(id, weaponid);

/*------------------------------
Ustawia ilosc zlotych medali danemu graczowi
id = id gracza,
wartosc = ilosc zlotych medali
------------------------------*/
native csgo_set_user_medal_gold(id, wartosc);

/*------------------------------
Zwraca ilosc zlotych medali danego gracza
------------------------------*/
native csgo_get_user_medal_gold(id);

/*------------------------------
Ustawia ilosc srebrnych medali danemu graczowi
id = id gracza,
wartosc = ilosc srebrnych medali
------------------------------*/
native csgo_set_user_medal_silver(id, wartosc);

/*------------------------------
Zwraca ilosc srebrnych medali danego gracza
------------------------------*/
native csgo_get_user_medal_silver(id);

/*------------------------------
Ustawia ilosc brazowych medali danemu graczowi
id = id gracza,
wartosc = ilosc brazowych medali
------------------------------*/
native csgo_set_user_medal_brown(id, wartosc);

/*------------------------------
Zwraca ilosc brazowych medali danego gracza
------------------------------*/
native csgo_get_user_medal_brown(id);

/*------------------------------
Ustawia ilosc asyst danemu graczowi
id = id gracza,
wartosc = ilosc asyst
------------------------------*/
native csgo_set_user_assist(id, wartosc);

/*------------------------------
Zwraca ilosc asyst danego gracza
------------------------------*/
native csgo_get_user_assist(id);

/*------------------------------
Zwraca ilosc zabojstw danego gracza
------------------------------*/
native csgo_get_user_kills(id);

/*------------------------------
Zwraca ilosc smierci danego gracza
------------------------------*/
native csgo_get_user_deads(id);

/*------------------------------
Zwraca czas przegray na serverze danego gracza
------------------------------*/
native csgo_get_user_time(id);

/*------------------------------
Zwraca ilosc skinow jakie istnieja na serverze
------------------------------*/
native csgo_get_skin_count();

/*------------------------------
Zwraca nazwe skina dla skin_id,
skin_id = id skina
------------------------------*/
native csgo_get_skin_name(skin_id, Return[], len);

/*------------------------------
Zwraca id broni, dla skin_id,
skin_id = id skina
------------------------------*/
native csgo_get_skin_weaponid(skin_id);

/*------------------------------
Zwraca czy wczytano dane danego gracza
------------------------------*/ 
native csgo_get_user_loaded(id);	

/*------------------------------
Ustawia pozwolenie graczowi do zapisywania danych
id = id gracza,
bool:wartosc = true - pozwala, false - nie pozwala
------------------------------*/
native csgo_set_user_allow(id, bool:wartosc);

/*------------------------------
Zwraca czy ma dostep do konta dany gracz
------------------------------*/ 
native csgo_get_user_allow(id);	 

/*------------------------------
Ustawia rejestracja graczowi
id = id gracza,
bool:wartosc = true - zarejestrowany, false - nie zarejestrowany
------------------------------*/
native csgo_set_user_register(id, bool:wartosc);

/*------------------------------
Zwraca czy czy dany gracz jest zarejestrowany
------------------------------*/ 
native csgo_get_user_register(id);

/*------------------------------
Zwraca haslo danego gracza,
id = id gracza
------------------------------*/
native csgo_get_user_password(id, Return[], len);

/*------------------------------
Ustawia haslo dla danego gracza
id = id gracza,
nazwa[] = jakie haslo
------------------------------*/
native csgo_set_user_password(id, const nazwa[]);

/*------------------------------
Zwraca pozycje ranku gracza - /rank,
id = id gracza.
------------------------------*/ 
native csgo_get_user_rank(id);

/*------------------------------
Zwraca ilosc osob w rankingu /rank
------------------------------*/ 
native csgo_get_max_rank();

/*------------------------------
Zwraca szanse na drop tego skina dla skin_id,
skin_id = id skina
------------------------------*/
native csgo_get_skin_drop();

/*------------------------------
Zwraca id klucza glownego w bazie danych dla id
id = id gracza
------------------------------*/

native csgo_get_user_player(id);
