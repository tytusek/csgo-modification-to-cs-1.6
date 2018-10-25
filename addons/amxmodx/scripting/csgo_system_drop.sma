#include <amxmodx>
#include <reapi>
#include <ColorChat>
#include <csgo>
#include <dhudmessage>

new bool:next_round_set=false;
new bool:giving_award=false;
new bool:oneTimeOnRound[33]=false;

native is_vote_will_in_next_round()

public plugin_init() 
{
	register_plugin("[CSGO] System: Drop", "1.0", "TyTuS")
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", true);
	register_event("HLTV", "PoczatekRundy", "a", "1=0", "2=0");
	register_logevent("Koniec_Rundy", 2, "1=Round_End");
}

public PoczatekRundy()	
{
	if(next_round_set && !giving_award)
	{
		losowanie();
		przyznanie_doswiadczenia();
	}
		
	for(new id=1;id<=MAX_CLIENTS;id++)
	{
		if(is_user_connected(id) && !is_user_hltv(id) && !is_user_bot(id))
		{
			oneTimeOnRound[id]=false;
			if(get_entvar(id, var_weapons) & (1 << CSW_C4))
			{ 
				set_dhudmessage(255, 0, 255, -1.0, 0.15, 0, 10.0, 10.0);
				show_dhudmessage(id, "Posiadasz Bombe!^n jesli nie wykonujesz celi mapy. Wyrzuc!");
			}  
		}	
	}
}
public Koniec_Rundy()
{
	if(is_vote_will_in_next_round())
		next_round_set=true;
}

public przyznanie_doswiadczenia()
{
	new all_player=0;

	for(new id=1;id<=MAX_CLIENTS;id++)
	{
		if(is_user_connected(id) && !is_user_hltv(id) && !is_user_bot(id))
		{
			if(get_member(id, m_iTeam)==3)
				continue;

			all_player++;
		}
	}

	if(all_player<5)
		return PLUGIN_CONTINUE;

	new monety[3];

	monety[0]=10;
	monety[1]=15;
	monety[2]=20;

	new players[32], num;
	get_players(players, num, "h");
	new tempfrags, id;
	new swapfrags, swapid;
	new starfrags[3]; //0 - 3 miejsce / 1 - 2 miejsce / 2 - 1 miejsce
	new starid[3];

	for (new i = 0; i < num; i++)
	{
		id = players[i];
		tempfrags = get_user_frags(id);

		if ( tempfrags > starfrags[0] )
		{
			starfrags[0] = tempfrags;
			starid[0] = id;
			csgo_set_user_medal_brown(starid[0], csgo_get_user_medal_brown(starid[0])+1);
			csgo_set_user_coin(starid[0], csgo_get_user_coin(starid[0])+monety[0]);

			if ( tempfrags > starfrags[1] )
			{
				swapfrags = starfrags[1];
				swapid = starid[1];
				starfrags[1] = tempfrags;
				starid[1] = id;
				starfrags[0] = swapfrags;
				starid[0] = swapid;

				csgo_set_user_medal_silver(starid[1], csgo_get_user_medal_silver(starid[1])+1);
				csgo_set_user_coin(starid[1], csgo_get_user_coin(starid[1])+monety[1]);

				if ( tempfrags > starfrags[2] )
				{
					swapfrags = starfrags[2];
					swapid = starid[2];
					starfrags[2] = tempfrags;
					starid[2] = id;
					starfrags[1] = swapfrags;
					starid[1] = swapid;
	
					csgo_set_user_medal_gold(starid[2], csgo_get_user_medal_silver(starid[2])+1);
					csgo_set_user_coin(starid[2], csgo_get_user_coin(starid[2])+monety[2]);
				}
			}
		}
	}
	new winner = starid[2];
	if (!winner)
		return PLUGIN_CONTINUE;

	new name2[20], name1[20], name0[20];	
	get_user_name(starid[2], name2, charsmax(name2));	
	get_user_name(starid[1], name1, charsmax(name1));
	get_user_name(starid[0], name0, charsmax(name0));

	ColorChat(0, GREEN,"~~~~ Najlepsi byczusie na tej mapie to: ");
	ColorChat(0, GREEN,"Zloty Medal: ^x03 %s^x04 | fragi:^x03 %i^x04 | +monet:^x03 %d", name2, starfrags[2], monety[2]);
	ColorChat(0, GREEN,"Srebrny Medal: ^x03 %s^x04 | fragi:^x03 %i^x04 | +monet:^x03 %d", name1, starfrags[1], monety[1]);
	ColorChat(0, GREEN,"Brazowy Medal: ^x03 %s^x04 | fragi:^x03 %i^x04 | +monet:^x03 %d", name0, starfrags[0], monety[0]);
	giving_award=true;
	return PLUGIN_CONTINUE;
}


public CBasePlayer_Killed(ofiara, zabojca)
{ 
	if(!is_user_connected(zabojca) || zabojca<1 || zabojca>32 || ofiara<1 || ofiara>32|| zabojca==ofiara || get_playersnum() < 3 )
		return HC_CONTINUE;

	new imiezabojcy[32], imieofiary[32], ip_ofiara[33], ip_attacker[33];
	static maxdrop[33]=0;
	get_user_name(zabojca, imiezabojcy, 31); 
	get_user_name(ofiara, imieofiary, 31);

	get_user_ip(ofiara, ip_ofiara, 32, 1);
	get_user_ip(zabojca, ip_attacker, 32, 1);

	if(equal(ip_ofiara, ip_attacker))
		return HC_CONTINUE;	

	if(get_user_flags(zabojca) & ADMIN_LEVEL_H)
		csgo_set_user_coin(zabojca, csgo_get_user_coin(zabojca)+2);
	else
		csgo_set_user_coin(zabojca, csgo_get_user_coin(zabojca)+1);

	if(1>=random_num(1, 100) && !oneTimeOnRound[zabojca] && csgo_get_user_kills(zabojca)>100 && maxdrop[zabojca]<4)
	{
		giveKey(zabojca);
		maxdrop[zabojca]++;
	}
	else if(3>=random_num(1, 100) && !oneTimeOnRound[zabojca])
	{
		giveKey(zabojca);
		maxdrop[zabojca]++;
	}

	if(2 >= random_num(1, 100) && get_user_flags(zabojca) & ADMIN_LEVEL_H && csgo_get_user_kills(zabojca)>100 && maxdrop[zabojca]<4)
	{
		giveKey(zabojca);
		maxdrop[zabojca]++;
	}
	else if(6 >= random_num(1, 100) && get_user_flags(zabojca) & ADMIN_LEVEL_H && maxdrop[zabojca]<4)
	{
		giveKey(zabojca);
		maxdrop[zabojca]++;
	}
	return HC_CONTINUE;
}
public giveKey(zabojca)
{
	csgo_set_user_key(zabojca, csgo_get_user_key(zabojca)+1);
	ColorChat(zabojca, GREEN, "[CS:GO]^x01 Zdobyles^x04 Klucz^x01, wpisz^x04 /menu^x01 i otworz skrzynie!");
	oneTimeOnRound[zabojca]=true;
	return HC_CONTINUE;
}

public losowanie() 
{
	new ile, ilu_graczy=0,ilu_mozna=0, ilu_losowac = 1, jest, bool:wylosowany[33]=false;

	for(new i=1;i<33;i++)
	{
		if(is_user_connected(i))
		ilu_graczy++;
	}

	if(ilu_graczy<6)
	{
		ColorChat(0, TEAM_COLOR, "[CS:GO]^x01 Losowanie Skrzyn sie nie odbylo z powodu:^x04 Zbyt malej ilosci graczy");
		return PLUGIN_HANDLED;
	}

	for(new id=1;id<33;id++)
	{
		if(is_user_connected(id) && !is_user_hltv(id) && get_user_time(id,1)>300 && csgo_get_user_allow(id) && get_user_team(id)!=3)
		ilu_mozna++;
	}

	if(ilu_graczy>8)  ilu_losowac=2;
	if(ilu_graczy>14) ilu_losowac=3;
	if(ilu_graczy>20) ilu_losowac=5;
	if(ilu_graczy>25) ilu_losowac=6;

	if(ilu_mozna<=ilu_losowac)
	ilu_losowac=ilu_mozna;

	log_to_file("csgo_losuj_skrzynie.log", "ilu_losowac?: %d | ilu_moznaa?: %d", ilu_losowac, ilu_mozna);

	while(jest<ilu_losowac)
	{ 
		ile++;                       
		new id=random_num(1,32);
		if(is_user_connected(id) && !is_user_hltv(id) && get_user_team(id)!=3 && get_user_time(id,1)>300 && csgo_get_user_allow(id) && !wylosowany[id] && csgo_get_user_kills(id)>4)
		{
			wylosowany[id] = true;
			new name[33];
			get_user_name(id, name, 32);
			ColorChat(0, TEAM_COLOR, "[CS:GO]^x01 Gracz^x04 %s^x01 dostal Skrzynke!", name);
			log_to_file("csgo_losuj_skrzynie.log", "[CS:GO] Gracz %s dostal Skrzynke!", name);
			csgo_set_user_chest(id, csgo_get_user_chest(id)+1);
			jest++;
		}
	}
	log_to_file("csgo_losuj_skrzynie.log", "losowano az %d razy", ile);
	return PLUGIN_CONTINUE;
}