#include <amxmodx>
#include <sqlx>
#include <reapi>
#include <codmod>
#include <ColorChat>

#if !defined MAX_PLAYERS
	const MAX_PLAYERS = 32;
#endif
#if !defined MAX_NAME_LENGTH
	const MAX_NAME_LENGTH = 32;
#endif
const MAX_AUTHID_LENGTH = 25;
const MAX_CLAN_LENGTH = 24;
const MIN_CLAN_LENGTH = 3;
const MIN_CLAN_PAIDCOINS = 100;

const MAX_CLAN_EXP = 2;
const MAX_CLAN_INTELLIGENCE = 2;
const MAX_CLAN_HEALTH = 2;
const MAX_CLAN_STAMINA = 2;
const MAX_CLAN_CONDITION = 2;
const MAX_CLAN_DMG = 2;
const MAX_CLAN_COIN = 2;

new const CLAN_STATS_COUNTER[] = { 1, 2, -1}

#if AMXX_VERSION_NUM < 183
	#define replace_string replace_all
#endif

enum _:ClanData {
	bool:oneTime, 
	bool:connect,
	bool:loaded,
	cid,
	uid, 
	clanName[MAX_CLAN_LENGTH],
	level, 
	points,
	coins,
	users,
	permission,
	paid
};

enum _:PlayerSkill
{
	unorder_points,
	exp,
	intelligence,
	health,
	stamina,
	condition,
	dmg,
	coin
};

enum CVARS{ 
	host, 
	user, 
	pass, 
	db, 
	costcreate,
	minlvlcreate,
	costchangename,
	maxlvlclan,
	costnextlvl,
	skillexp,
	skilldmg,
	skillhp,
	skillint,
	skillstamina,
	skillcondition,
	skillcoin
};

enum _:{ 
	CheckNameClan,
	Create,
	Create2,
	Top10,
	Checkmy,
	AddUser,
	UpdateUser,
	DeleteClan,
	DeleteUser,
	LeaveClan,
	UpdateName,
	ChangeName,
	UserOfClan,
	UpdateClan,
	UpdateOwner,
	UpdateDeputy,
	UpdateDeputy2
};

new Handle:g_hSqlTuple, 
	g_Data[3], 
	szQuery[1024];

new g_arrClanData[MAX_PLAYERS + 1][ClanData];
new g_PlayerClanSkill[MAX_PLAYERS + 1][PlayerSkill];

new g_pCvars[CVARS];
new gData[2048], len;
new g_DealingStats[33];
new bool:g_SkillReset[33];

public plugin_init(){

	/*
          1.0.0 first version

	*/

	register_plugin("Cod System: Clan", "1.0.0", "TyTuS");

	register_clcmd("nameclan", "CreateClan");
	register_clcmd("newnameclan", "ChangeNameClan");
	register_clcmd("paidcoins", "PaidCoinsClan");
	register_clcmd("say /klan", "MenuMainClan");

	g_pCvars[host] = register_cvar("clan_sql_host", 	"127.0.0.1");
	g_pCvars[user] = register_cvar("clan_sql_user", 	"root",	    FCVAR_PROTECTED);
	g_pCvars[pass] = register_cvar("clan_sql_pass", 	"password", FCVAR_PROTECTED);
	g_pCvars[db]   = register_cvar("clan_sql_db",   	"database");

	g_pCvars[costcreate]	 = 	register_cvar("clan_cost_create",   	"1000");  
	g_pCvars[costchangename]  = 	register_cvar("clan_cost_change_name",  "500"); 
	g_pCvars[minlvlcreate]	 = 	register_cvar("clan_minlvl_create",   	"100");
	g_pCvars[maxlvlclan]	 = 	register_cvar("clan_maxlvl_clan",   	"10");
	g_pCvars[costnextlvl]	 = 	register_cvar("clan_cost_nextlvl",   	"150");

	g_pCvars[skillexp]		 = 	register_cvar("clan_skill_exp",   		"100");
	g_pCvars[skillhp]		 = 	register_cvar("clan_skill_hp",   		"10");
	g_pCvars[skillint]		 = 	register_cvar("clan_skill_int",   		"10");
	g_pCvars[skillstamina]	 = 	register_cvar("clan_skill_stamina",   	"20");
	g_pCvars[skillcondition]	 = 	register_cvar("clan_skill_condition",   "15");
	g_pCvars[skillcoin]		 = 	register_cvar("clan_skill_coin",  		"4");
	g_pCvars[skilldmg]		 = 	register_cvar("clan_skill_dmg",   		"4");


	RegisterHookChain(RG_CBasePlayer_TakeDamage, "HookChain_Player_TakeDamage");
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", true);

	LoadCvars();
}

public plugin_natives(){
	register_native("cod_get_user_clan_name", "GetUserClanName", 1);
}

public GetUserClanName(id, Return[], len){
	if(is_user_connected(id)){
		param_convert(2);
		copy(Return, len, g_arrClanData[id][clanName]);
	}
}

public plugin_end(){
	SQL_FreeHandle(g_hSqlTuple);
}

public client_putinserver(id){
	ResetData(id)
	CheckMyClan(id);
}	

public CheckMyClan(id){
	if(!is_user_connected(id) || g_arrClanData[id][loaded] || g_arrClanData[id][connect])
		return;

	new szName[MAX_NAME_LENGTH]; 
	get_user_name(id, szName, charsmax(szName));
	mysql_escape_string(szName, charsmax(szName));
	g_arrClanData[id][connect]=true;

	formatex(szQuery, charsmax(szQuery), 
		"SELECT `cod_clans_system`.`cid`, `cod_clans_system`.`clan_name`, `cod_clans_system`.`clan_points`, `cod_clans_system`.`clan_level`, `cod_clans_system`.`clan_skills`, `cod_clans_system`.`clan_coins`, `cod_clans_system`.`clan_users`, \
		 	`cod_clans_users`.`permission_lvl`, `cod_clans_users`.`paid_coins`, `cod_clans_users`.`uid` FROM `cod_clans_system`, `cod_clans_users` \
				WHERE `cod_clans_system`.cid = `cod_clans_users`.cid AND `cod_clans_users`.`user_name` ='%s'", szName);

	g_Data[0] = Checkmy;
	g_Data[1] = id;
	SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
}
ResetData(id){
	g_arrClanData[id][oneTime] = false;
	g_arrClanData[id][connect] = false;
	g_arrClanData[id][loaded] = false;
	g_arrClanData[id][cid] = 0;
	g_arrClanData[id][uid] = 0;
	g_arrClanData[id][clanName] = "Brak";
	g_arrClanData[id][level] = 1;
	g_arrClanData[id][points] = 0;

	g_arrClanData[id][coins] = 0;
	g_arrClanData[id][users] = 0;
	g_arrClanData[id][permission] = 0;
	g_arrClanData[id][paid] = 0;
	g_SkillReset[id] = false;
	g_DealingStats[id] = 0;

	ResetClanSkills(id);
}

public MenuMainClan(id){
	if(!g_arrClanData[id][loaded] || !g_arrClanData[id][connect]){
		client_print(id, print_center, "Poczekaj az zaladuja sie klany");
		return;
	}
	new title[64]

	if(g_arrClanData[id][cid]<=0){
		formatex(title, charsmax(title), "System Klanow by TyTuS");
		new nameMenu[64], menu = menu_create(title, "MenuMainClanHandler");
		formatex(nameMenu, charsmax(nameMenu), "Stworz Klan \d(\y %d\r lvl i\y %d\r Monet\d )", get_pcvar_num(g_pCvars[minlvlcreate]), get_pcvar_num(g_pCvars[costcreate]));
		menu_additem(menu, nameMenu);
		menu_additem(menu, "Top10 Klanow");
		menu_display(id, menu);
	}
	else{
		formatex(title, charsmax(title), "Klan:\r %s\w [ \d%d \y/\d %d lvl\w ]", g_arrClanData[id][clanName], g_arrClanData[id][level], get_pcvar_num(g_pCvars[maxlvlclan]));
		new textMenu[64], menu = menu_create(title, "MenuMainClanHandler2");
		formatex(textMenu, charsmax(textMenu), "Dodaj Czlonkow [\r%d\y /\r %d\w]", g_arrClanData[id][users], 5 + g_arrClanData[id][level]);
		menu_additem(menu, textMenu);
		menu_additem(menu, "Klanowicze");
		menu_additem(menu, "Top10 Klanow");
		formatex(textMenu, charsmax(textMenu), "Zmien Nazwe \d(\y %d\r Monet\d )", get_pcvar_num(g_pCvars[costchangename]));
		menu_additem(menu, textMenu);

		formatex(textMenu, charsmax(textMenu), "Wplac Monety! \d( next lvl >\r %d\d Monet )",
			 g_arrClanData[id][level] == get_pcvar_num(g_pCvars[maxlvlclan]) ? 0 : (GetNextLvl(g_arrClanData[id][level])-g_arrClanData[id][coins]));

		menu_additem(menu, textMenu); 
		menu_additem(menu, "Skille Klanu");  
		menu_additem(menu, "Opusc/Usun Klan");
		menu_display(id, menu);
	}
}

public MenuMainClanHandler(id, menu, item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	switch(item){
		case 0: cmdExecute(id, "messagemode nameclan");
		case 1: Top10ClanMotd(id);
	}
	return PLUGIN_CONTINUE;
}

public MenuMainClanHandler2(id, menu, item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	switch(item){
		case 0: {	
			if(5 + g_arrClanData[id][level]==g_arrClanData[id][users]){
				ColorChat(id, RED, "Klan posiada maksymalna ilosc czlonkow!");
				MenuMainClan(id);
				return PLUGIN_CONTINUE;
			}
			if(g_arrClanData[id][permission]==0){
				ColorChat(id, RED, "Zapraszac nowe osoby do klanu moze Wlasciciel lub Zastepce");
				MenuMainClan(id);
				return PLUGIN_CONTINUE;
			}
			new menu = menu_create("Wybierz gracza:", "AddPlayerHandler");
			new szName[32], szTempid[10], menuText[64];

			for(new i=0; i<=MAX_PLAYERS; i++){
				if(!is_user_connected(i))
					continue;

				get_user_name(i, szName, charsmax(szName));
				formatex(menuText, charsmax(menuText), "%s [\r%s\w]", szName, g_arrClanData[i][clanName])
				num_to_str(i, szTempid, charsmax(szTempid));
				menu_additem(menu, menuText, szTempid);
			}
			menu_display(id, menu, 0);
		}
		case 1: {	
			formatex(szQuery, charsmax(szQuery), 
				"SELECT `uid`, `user_name`, `permission_lvl`, `paid_coins` \
				FROM `cod_clans_users` WHERE `cid` = '%d'", g_arrClanData[id][cid], g_arrClanData[id][cid], g_arrClanData[id][cid], g_arrClanData[id][cid]);

			g_Data[0] = UserOfClan;
			g_Data[1] = id;
			SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
		}
		case 2: Top10ClanMotd(id);
		case 3: {
			if(g_arrClanData[id][permission]<2 || cod_get_user_coins(id)<=get_pcvar_num(g_pCvars[costchangename])){
				ColorChat(id, RED, "Masz za malo monet, lub nie jestes Wlascicielem!");
				MenuMainClan(id);
				return PLUGIN_CONTINUE;
			}
			cmdExecute(id, "messagemode newnameclan");
		}
		case 4:{
			if(g_arrClanData[id][level]>=get_pcvar_num(g_pCvars[maxlvlclan])){
				client_print(id, print_center, "Twoj Klan juz ma maksymalny Lvl!");
				return PLUGIN_CONTINUE;
			}
			cmdExecute(id, "messagemode paidcoins"); 
		}
		case 5: SetClanSkills(id);
		case 6:{ 
			new menu = menu_create("Czy aby na pewno chcesz opuscic klan?", "LeaveClanHandler");
			menu_additem(menu, "Tak");
			menu_additem(menu, "Nie, jednak zostaje");
			menu_display(id, menu);
		}	
	}
	return PLUGIN_CONTINUE;
}
public Top10ClanMotd(id){
	if(!is_user_connected(id) || !g_arrClanData[id][loaded])
		return;

	formatex(szQuery, charsmax(szQuery), 
		"SELECT `clan_name`, `clan_level`, `clan_points`, `clan_coins`, `owner_name` FROM `cod_clans_system` ORDER BY (`clan_points`) DESC LIMIT 10");

	g_Data[0] = Top10;
	g_Data[1] = id;
	SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
}
public AddPlayerHandler(id, menu, item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new data[6], szName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);

	new tempid = str_to_num(data);
	if(g_arrClanData[tempid][cid]>=1 || !is_user_connected(tempid)){
		ColorChat(id, RED, "Ten Gracz juz ma Klan!");
		return PLUGIN_CONTINUE;
	}
	if(!is_user_connected(tempid) || !g_arrClanData[tempid][loaded]){
		ColorChat(id, RED, "Musi sie klan zaladowac temu graczowi");
		return PLUGIN_CONTINUE;
	}
	new name[33], title[40], tempname[33], userID, idString[4];
	get_user_name(tempid, tempname, 32);
	get_user_name(id, name, 32);
	userID = id;
	num_to_str(userID, idString, charsmax(idString));
	formatex(title, charsmax(title), "Chcesz dolaczyc do klanu:\r %s\w?", g_arrClanData[id][clanName]);
	new menu = menu_create(title, "AddPlayerJoinHandler");
	menu_additem(menu, "Dolaczam!", idString);
	menu_additem(menu, "Nie dzieki", idString);
	menu_display(tempid, menu);
	return PLUGIN_CONTINUE;
}
public PaidCoinsClan(id){
	if(g_arrClanData[id][cid]<1)
		return PLUGIN_HANDLED;

	if(g_arrClanData[id][level]>=get_pcvar_num(g_pCvars[maxlvlclan])){
		client_print(id, print_center, "Twoj Klan juz ma maksymalny Lvl!");
		return PLUGIN_HANDLED;
	}

	new amount, getText[192]=0;
	read_argv(1, getText, charsmax(getText));
	amount = str_to_num(getText);

	if(amount<=MIN_CLAN_PAIDCOINS){
		client_print(id, print_center, "Minimum mozna [%d] monet wplacic", MIN_CLAN_PAIDCOINS);
		cmdExecute(id, "messagemode paidcoins");
		return PLUGIN_HANDLED;
	}
	else if(amount>cod_get_user_coins(id)){
		client_print(id, print_center, "Nie posiadasz tylu monet!");
		cmdExecute(id, "messagemode paidcoins");
		return PLUGIN_HANDLED;
	}
	else{
		new lvl = 1, coinsClan = 0;
		coinsClan = g_arrClanData[id][coins];

		g_arrClanData[id][paid]+=amount;
		coinsClan+=amount;

		cod_set_user_coins(id, cod_get_user_coins(id)-amount);
		
		while(coinsClan>=GetNextLvl(lvl)){
			lvl++;
		}
		if(lvl>=get_pcvar_num(g_pCvars[maxlvlclan]))
			lvl=get_pcvar_num(g_pCvars[maxlvlclan])

		if(g_arrClanData[id][level]!=lvl)
			ColorChat(0, NORMAL, "Klan^x04 %s^x01, Awansowal z^x04 %d^x01 lvl na^x04 %d^x01 lvl!", g_arrClanData[id][clanName], g_arrClanData[id][level], lvl);

		ColorChat(id, NORMAL, "^x04Wplaciles^x03 %d^x01 Monet, Obecny lvl to^x03 %d^x01, do nastepnego lvl potrzeba^x03 %d ^x01 Monet",
		 	amount, lvl, g_arrClanData[id][level] == get_pcvar_num(g_pCvars[maxlvlclan]) ? 0 : (GetNextLvl(lvl)-coinsClan));

		for(new i=0;i<=MAX_PLAYERS;i++){
			if(!is_user_connected(i)) continue;

			if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
				g_PlayerClanSkill[i][unorder_points]+=(lvl-g_arrClanData[i][level]);	
				g_arrClanData[i][level]=lvl; 
				g_arrClanData[i][coins]=coinsClan;
			}
		}
		formatex(szQuery, charsmax(szQuery), 
				"UPDATE `cod_clans_users`, `cod_clans_system` SET \
					`cod_clans_users`.`paid_coins` = '%d', `cod_clans_system`.`clan_level`= '%d', `cod_clans_system`.`clan_coins` = '%d', `cod_clans_system`.`clan_points` = `cod_clans_system`.`clan_points`+'%d', \
					 `cod_clans_system`.`clan_skills` = '#%d#%d#%d#%d#%d#%d#%d#%d#0#0' \
						WHERE `cod_clans_users`.`cid` = `cod_clans_system`.`cid` AND `uid` = '%d';",
				g_arrClanData[id][paid], g_arrClanData[id][level], g_arrClanData[id][coins], amount*2,
				g_PlayerClanSkill[id][unorder_points], g_PlayerClanSkill[id][exp], g_PlayerClanSkill[id][intelligence], g_PlayerClanSkill[id][health], g_PlayerClanSkill[id][stamina],
				g_PlayerClanSkill[id][condition], g_PlayerClanSkill[id][dmg], g_PlayerClanSkill[id][coin], g_arrClanData[id][uid]);

		g_Data[0] = UpdateClan;
		g_Data[1] = id;
		SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
	}
	return PLUGIN_HANDLED;	
}
public GetNextLvl(lvl){
	return get_pcvar_num(g_pCvars[costnextlvl])*(lvl*lvl);
}

public SetClanSkills(id){
	new menuText[128];

	formatex(menuText, charsmax(menuText), "Przydziel Punkty (%i):", g_PlayerClanSkill[id][unorder_points]);

	new menu = menu_create(menuText, "SetClanSkillsHandler");

	if(CLAN_STATS_COUNTER[g_DealingStats[id]] == -1)
		formatex(menuText, charsmax(menuText), "Ile dodawac: \rwszystko \d(Ile pkt dodac do statow)^n");
	else 
		formatex(menuText, charsmax(menuText), "Ile dodawac: \r%d \d(Ile pkt dodac do statow)^n", CLAN_STATS_COUNTER[g_DealingStats[id]]);
	menu_additem(menu, menuText);

	formatex(menuText, charsmax(menuText), "Exp: \r(%i/%i) - \d [ Zwieksza exp o\r %d\d za killa ]", g_PlayerClanSkill[id][exp], MAX_CLAN_EXP, g_PlayerClanSkill[id][exp]*get_pcvar_num(g_pCvars[skillexp]));
	menu_additem(menu, menuText);

	formatex(menuText, charsmax(menuText), "Inteligencja: \r(%i/%i) - \d [ Zwieksza intel o \r %d\d ]", g_PlayerClanSkill[id][intelligence], MAX_CLAN_INTELLIGENCE, g_PlayerClanSkill[id][intelligence]*10);
	menu_additem(menu, menuText);

	formatex(menuText, charsmax(menuText), "Zdrowie: \r(%i/%i) - \d [ Zwieksza HP o \r %d\d ]", g_PlayerClanSkill[id][health], MAX_CLAN_HEALTH, g_PlayerClanSkill[id][health]*10);
	menu_additem(menu, menuText);

	formatex(menuText, charsmax(menuText), "Wytrzymalosc: \r(%i/%i) - \d [ Zwieksza Wytrzy.. o \r %d\d ]", g_PlayerClanSkill[id][stamina], MAX_CLAN_STAMINA, g_PlayerClanSkill[id][stamina]*20);
	menu_additem(menu, menuText);

	formatex(menuText, charsmax(menuText), "Kondycja: \r(%i/%i) - \d [ Zwieksza Kondyc.. o \r %d\d ]", g_PlayerClanSkill[id][condition], MAX_CLAN_CONDITION, g_PlayerClanSkill[id][condition]*15);
	menu_additem(menu, menuText);

	formatex(menuText, charsmax(menuText), "Obrazenia: \r(%i/%i) - \d [ Zwieksza DMG o \r %d\d ]", g_PlayerClanSkill[id][dmg], MAX_CLAN_DMG, g_PlayerClanSkill[id][dmg]*get_pcvar_num(g_pCvars[skilldmg]));
	menu_additem(menu, menuText);

	formatex(menuText, charsmax(menuText), "Monety: \r(%i/%i) - \d [ Zwieksza Drop monety o \r %d\d Procent ]^n", g_PlayerClanSkill[id][coin], MAX_CLAN_COIN, g_PlayerClanSkill[id][coin]*25);
	menu_additem(menu, menuText);

	menu_additem(menu, "Zresetuj Statystyki!^n");
	menu_additem(menu, "Zapisz Skille!^n");
	menu_display(id, menu);
}
public ResetClanSkills(id){
	g_PlayerClanSkill[id][unorder_points]=(g_arrClanData[id][level]-1);
	g_PlayerClanSkill[id][exp]=0;
	g_PlayerClanSkill[id][intelligence]=0;
	g_PlayerClanSkill[id][health]=0;
	g_PlayerClanSkill[id][stamina]=0;
	g_PlayerClanSkill[id][condition]=0;
	g_PlayerClanSkill[id][dmg]=0;
	g_PlayerClanSkill[id][coin]=0;

	if(g_PlayerClanSkill[id][unorder_points]>0)
		SetClanSkills(id);
}

public AddPlayerJoinHandler(id, menu, item){
	return MenusHandler(id, menu, item, 1);
}

public UserOfClanHandler(id, menu, item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new _access, rsn[64], info[40], infoSecond[40], menuText[64], CallBack;
	new userid, nameUser[33], permis;
	menu_item_getinfo(menu, item, _access, info, charsmax(info), rsn, charsmax(rsn), CallBack);

	formatex(infoSecond, charsmax(infoSecond),"%s", info);
	replace_all(infoSecond, charsmax(infoSecond), "#", " ");

	new Data[2][10];
	parse(infoSecond,
		Data[0], charsmax(Data[]),
		nameUser, charsmax(nameUser),
		Data[1], charsmax(Data[]));

	userid = str_to_num(Data[0]);
	permis = str_to_num(Data[1]);

	if(g_arrClanData[id][uid] == userid){
		ColorChat(id, RED, "Samego siebie nie mozesz edytowac!")
		return PLUGIN_CONTINUE;
	}
	if(permis == 2 && g_arrClanData[id][permission]<2){
		ColorChat(id, RED, "Nie mozesz edytowac wlasciciela!")
		return PLUGIN_CONTINUE;	
	}
	if(permis == 2){
		formatex(menuText, charsmax(menuText), "Wybrales:\y %s \r*Wlasciciel", nameUser);
	}
	else if(permis == 1){
		formatex(menuText, charsmax(menuText), "Wybrales:\y %s \r*Zastepca", nameUser);
	} 
	else formatex(menuText, charsmax(menuText), "Wybrales:\y %s", nameUser);

	new cb = menu_makecallback("ActionClanUserHandler");
	new menu = menu_create(menuText, "ActionClanUser");
	menu_additem(menu, "Przekaz Wlasciciela", info, _, cb);
	menu_additem(menu, "Przekaz Zastepce", info, _, cb);
	menu_additem(menu, "Zdegraduj Zastepce", info, _, cb);
	menu_additem(menu, "Usun z klanu", info, _, cb);
	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}
public ActionClanUserHandler(id, menu, item){
	if(item == 0 && g_arrClanData[id][permission]<2)
		return ITEM_DISABLED;

	if(item == 1 && g_arrClanData[id][permission]<2)
		return ITEM_DISABLED;

	if(item == 2 && g_arrClanData[id][permission]<2)
		return ITEM_DISABLED;
		
	if(item == 3 && g_arrClanData[id][permission]<1)
		return ITEM_DISABLED;
	return ITEM_ENABLED;
}
public ActionClanUser(id, menu, item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	new _access, rsn[64], info[40], CallBack;
	new userid, nameUser[33], permis;
	menu_item_getinfo(menu, item, _access, info, charsmax(info), rsn, charsmax(rsn), CallBack);

	replace_all(info, charsmax(info), "#", " ");

	new Data[2][10];
	parse(info,
		Data[0], charsmax(Data[]),
		nameUser, charsmax(nameUser),
		Data[1], charsmax(Data[]));

	userid = str_to_num(Data[0]);
	permis = str_to_num(Data[1]);

	switch(item){
		case 0:{
			formatex(szQuery, charsmax(szQuery), 
				"UPDATE `cod_clans_system`, `cod_clans_users` SET `cod_clans_system`.`owner_name`='%s', `cod_clans_users`.`permission_lvl`='2' \
					WHERE `cod_clans_system`.`cid`=`cod_clans_users`.`cid` AND`cod_clans_users`.`uid` = '%d';",
						nameUser, userid);

			g_Data[0] = UpdateOwner;  
			g_Data[1] = id;
			g_Data[2] = userid;
			SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
		}
		case 1:{
			formatex(szQuery, charsmax(szQuery), 
				"UPDATE `cod_clans_system`, `cod_clans_users` SET `cod_clans_system`.`deputy_name`='%s', `cod_clans_users`.`permission_lvl`='1' \
					WHERE `cod_clans_system`.`cid`=`cod_clans_users`.`cid` AND`cod_clans_users`.`uid` = '%d';",
						nameUser, userid);

			g_Data[0] = UpdateDeputy;  
			g_Data[1] = id;
			g_Data[2] = userid;
			SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
		}
		case 2:{ // zdegradowanie zastepcy
			formatex(szQuery, charsmax(szQuery), 
				"UPDATE `cod_clans_system`, `cod_clans_users` SET `cod_clans_system`.`deputy_name`='Brak', `cod_clans_users`.`permission_lvl`='0' \
					WHERE `cod_clans_system`.`cid`=`cod_clans_users`.`cid` AND`cod_clans_users`.`uid` = '%d';",
						userid);

			g_Data[0] = UpdateDeputy2;  
			g_Data[1] = id;
			g_Data[2] = userid;
			SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
		}
		case 3:{
			if(permis == 1){
				formatex(szQuery, charsmax(szQuery), 
					"DELETE FROM `cod_clans_users` WHERE `uid` = '%d'; UPDATE `cod_clans_system` SET `deputy_name`='Brak', `clan_users`=`clan_users`-1 WHERE `cid` = '%d';",
						userid,  g_arrClanData[id][cid]);
			}
			else if(permis == 0){
				formatex(szQuery, charsmax(szQuery), 
					"DELETE FROM `cod_clans_users` WHERE `uid` = '%d'; UPDATE `cod_clans_system` SET `clan_users`=`clan_users`-1 WHERE `cid` = '%d';",
					userid,  g_arrClanData[id][cid]);
			}
			g_Data[0] = DeleteUser;  
			g_Data[1] = id;
			g_Data[2] = userid;
			SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
		}
	}
	return PLUGIN_CONTINUE;
}

public LeaveClanHandler(id, menu, item){
	return MenusHandler(id, menu, item, 2);
}

public SetClanSkillsHandler(id, menu, item){
	return MenusHandler(id, menu, item, 3);
}

MenusHandler(id, menu, item, mmenu){
	if(item != MENU_EXIT){
		new _access, rsn[64], info[40], CallBack;
		menu_item_getinfo(menu, item, _access, info, charsmax(info), rsn, charsmax(rsn), CallBack);
		new id2 = str_to_num(info);

		switch(mmenu){
			case 1:{
				if(item==1 || g_arrClanData[id][uid]>0 || g_arrClanData[id][cid]>0){
					return PLUGIN_CONTINUE;
				}

				// id2 to zapraszajacy
				// id to osoba zaproszona

				if(5 + g_arrClanData[id2][level]==g_arrClanData[id2][users]){
					ColorChat(id, RED, "Sorka, nie ma juz miejsca dla ciebie w klanie :/");
					return PLUGIN_CONTINUE;
				}
				new szName[MAX_NAME_LENGTH], szAuth[MAX_AUTHID_LENGTH];

				get_user_name(id, szName, charsmax(szName))
				get_user_authid(id, szAuth, charsmax(szAuth));
				mysql_escape_string(szName, charsmax(szName));

				formatex(szQuery, charsmax(szQuery), 
					"INSERT INTO `cod_clans_users` (`uid`, `user_name`, `user_steamid`, `permission_lvl`, `paid_coins`, `cid`) \
						VALUES ('NULL', '%s', '%s', '0', '0', '%d'); UPDATE `cod_clans_system` SET `clan_users` = `clan_users`+1 WHERE `cid`='%d'",
					szName, szAuth, g_arrClanData[id2][cid], g_arrClanData[id2][cid]);

				for(new i=0;i<=MAX_PLAYERS;i++){
					if(!is_user_connected(i))
						continue;

					if(g_arrClanData[i][cid] == g_arrClanData[id2][cid]){
						ColorChat(i, GREEN, "Powitajcie^x03 %s^x04 w Klanie!", szName);
						g_arrClanData[i][users]++;
					}
						
				}
				log_to_file("cod_clan_users.log","Gracz: %s | Dolaczyl do klanu: %s | cid: %d | uid: %d", szName, g_arrClanData[id2][clanName], g_arrClanData[id2][cid], g_arrClanData[id2][uid]);

				g_Data[0] = AddUser;
				g_Data[1] = id;
				SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
			}
			case 2:{
				if(item==1 || g_arrClanData[id][oneTime])
					return PLUGIN_CONTINUE;

				g_arrClanData[id][oneTime]=true;

				if(g_arrClanData[id][permission] == 2){
					formatex(szQuery, charsmax(szQuery), 
						"DELETE FROM `cod_clans_users` WHERE `cid` = '%d'; DELETE FROM `cod_clans_system` WHERE `cid` = '%d'", g_arrClanData[id][cid],  g_arrClanData[id][cid]);
				
					g_Data[0] = DeleteClan; 
					g_Data[1] = id;
					SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
				}
				else if(g_arrClanData[id][permission]<2){

					if(g_arrClanData[id][permission] == 1){
						formatex(szQuery, charsmax(szQuery), 
							"DELETE FROM `cod_clans_users` WHERE `uid` = '%d'; UPDATE `cod_clans_system` SET `deputy_name`='Brak', `clan_users`=`clan_users`-1 WHERE `cid` = '%d';",
							 g_arrClanData[id][uid],  g_arrClanData[id][cid]);
					}
					else if(g_arrClanData[id][permission]==0){
						formatex(szQuery, charsmax(szQuery), 
							"DELETE FROM `cod_clans_users` WHERE `uid` = '%d'; UPDATE `cod_clans_system` SET `clan_users`=`clan_users`-1 WHERE `cid` = '%d';",
							g_arrClanData[id][uid],  g_arrClanData[id][cid]);
					}
					g_Data[0] = LeaveClan;  
					g_Data[1] = id;
					SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
				}
			}
			case 3:{
				if(g_arrClanData[id][permission] == 0){
					ColorChat(id, RED, "Tylko Wlasciciel i Zastepce mozna rozdawac Skille")
					SetClanSkills(id);
					return PLUGIN_CONTINUE;
				}

				new ilosc;
				if(CLAN_STATS_COUNTER[g_DealingStats[id]] == -1)
					ilosc = g_PlayerClanSkill[id][unorder_points];
				else ilosc = (CLAN_STATS_COUNTER[g_DealingStats[id]] > g_PlayerClanSkill[id][unorder_points]) ? g_PlayerClanSkill[id][unorder_points] : CLAN_STATS_COUNTER[g_DealingStats[id]]

				switch(item){ 
					case 0: {
						if(g_DealingStats[id] < charsmax(CLAN_STATS_COUNTER))
							g_DealingStats[id]++;
						else 	g_DealingStats[id] = 0;
					}       
					case 1: {
						if(g_PlayerClanSkill[id][exp] < MAX_CLAN_EXP){
							if(ilosc > MAX_CLAN_EXP - g_PlayerClanSkill[id][exp])
								ilosc = MAX_CLAN_EXP - g_PlayerClanSkill[id][exp];
							
							for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									g_PlayerClanSkill[i][exp]+=ilosc;
									g_PlayerClanSkill[i][unorder_points]-=ilosc;
								}
							}
						}
						else 	client_print(id, print_chat, "Maxymalny poziom statystyki exp osiagniety");                       
					}
					case 2: {
						if(g_PlayerClanSkill[id][intelligence] < MAX_CLAN_INTELLIGENCE){
							if(ilosc > MAX_CLAN_INTELLIGENCE - g_PlayerClanSkill[id][intelligence])
								ilosc = MAX_CLAN_INTELLIGENCE - g_PlayerClanSkill[id][intelligence];
							
							for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									g_PlayerClanSkill[i][intelligence]+=ilosc;
									g_PlayerClanSkill[i][unorder_points]-=ilosc;
								}
							}
						}
						else 	client_print(id, print_chat, "Maxymalny poziom statystyki inteligencja osiagniety");                       
					}
					case 3: {
						if(g_PlayerClanSkill[id][health] < MAX_CLAN_HEALTH){
							if(ilosc > MAX_CLAN_HEALTH - g_PlayerClanSkill[id][health])
								ilosc = MAX_CLAN_HEALTH - g_PlayerClanSkill[id][health];
							
							for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									g_PlayerClanSkill[i][health]+=ilosc;
									g_PlayerClanSkill[i][unorder_points]-=ilosc;
								}
							}
						}
						else 	client_print(id, print_chat, "Maxymalny poziom statystyki zdrowie osiagniety");                       
					}
					case 4: {
						if(g_PlayerClanSkill[id][stamina] < MAX_CLAN_STAMINA){
							if(ilosc > MAX_CLAN_STAMINA - g_PlayerClanSkill[id][stamina])
								ilosc = MAX_CLAN_STAMINA - g_PlayerClanSkill[id][stamina];
							
							for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									g_PlayerClanSkill[i][stamina]+=ilosc;
									g_PlayerClanSkill[i][unorder_points]-=ilosc;
								}
							}
						}
						else 	client_print(id, print_chat, "Maxymalny poziom statystyki wytrzymalosc osiagniety");                       
					}
					case 5: {
						if(g_PlayerClanSkill[id][condition] < MAX_CLAN_CONDITION){
							if(ilosc > MAX_CLAN_CONDITION - g_PlayerClanSkill[id][condition])
								ilosc = MAX_CLAN_CONDITION - g_PlayerClanSkill[id][condition];
							
							for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									g_PlayerClanSkill[i][condition]+=ilosc;
									g_PlayerClanSkill[i][unorder_points]-=ilosc;
								}
							}
						}
						else 	client_print(id, print_chat, "Maxymalny poziom statystyki kondycji osiagniety");                       
					}
					case 6: {
						if(g_PlayerClanSkill[id][dmg] < MAX_CLAN_DMG){
							if(ilosc > MAX_CLAN_DMG - g_PlayerClanSkill[id][dmg])
								ilosc = MAX_CLAN_DMG - g_PlayerClanSkill[id][dmg];
							
							for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									g_PlayerClanSkill[i][dmg]+=ilosc;
									g_PlayerClanSkill[i][unorder_points]-=ilosc;
								}
							}
						}
						else 	client_print(id, print_chat, "Maxymalny poziom statystyki obrazen osiagniety");                       
					}
					case 7: {
						if(g_PlayerClanSkill[id][coin] < MAX_CLAN_COIN){
							if(ilosc > MAX_CLAN_COIN - g_PlayerClanSkill[id][coin])
								ilosc = MAX_CLAN_COIN - g_PlayerClanSkill[id][coin];
							
							for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									g_PlayerClanSkill[i][coin]+=ilosc;
									g_PlayerClanSkill[i][unorder_points]-=ilosc;
								}
							}
						}
						else 	client_print(id, print_chat, "Maxymalny poziom statystyki dodatkowych monet osiagniety");                       
					}
					case 8: {
							for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									client_print(i, print_chat, "Umiejetnosci klanu zostaly zresetowane.");
									cod_set_user_bonus_health(i, cod_get_user_health(i, 0, 0, 1)-g_PlayerClanSkill[i][health]*get_pcvar_num(g_pCvars[skillhp]));
									cod_set_user_bonus_stamina(i, cod_get_user_stamina(i, 0, 0, 1)-g_PlayerClanSkill[i][stamina]*get_pcvar_num(g_pCvars[skillstamina]));
									cod_set_user_bonus_trim(i, cod_get_user_trim(i, 0, 0, 1)-g_PlayerClanSkill[i][stamina]*get_pcvar_num(g_pCvars[skillcondition]));
									cod_set_user_bonus_intelligence(i, cod_get_user_intelligence(i, 0, 0, 1)-g_PlayerClanSkill[i][intelligence]*get_pcvar_num(g_pCvars[skillint]));
									g_SkillReset[i] = false;
									ResetClanSkills(i);
								}
							}
					}
					case 9:{
						if(g_SkillReset[id]){
							client_print(id, print_chat, "Nie mozesz drugi raz zapisac bez resetowanie statystyk")
							return PLUGIN_CONTINUE;

						}
						for(new i=0;i<=MAX_PLAYERS;i++){
								if(!is_user_connected(i))
									continue;

								if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
									cod_set_user_bonus_health(i, cod_get_user_health(i, 0, 0, 1)+g_PlayerClanSkill[i][health]*get_pcvar_num(g_pCvars[skillhp]));
									cod_set_user_bonus_stamina(i, cod_get_user_stamina(i, 0, 0, 1)+g_PlayerClanSkill[i][stamina]*get_pcvar_num(g_pCvars[skillstamina]));
									cod_set_user_bonus_trim(i, cod_get_user_trim(i, 0, 0, 1)+g_PlayerClanSkill[i][stamina]*get_pcvar_num(g_pCvars[skillcondition]));
									cod_set_user_bonus_intelligence(i, cod_get_user_intelligence(i, 0, 0, 1)+g_PlayerClanSkill[i][intelligence]*get_pcvar_num(g_pCvars[skillint]));
									g_SkillReset[i] = true;
								}
						}
						formatex(szQuery, charsmax(szQuery), 
							"UPDATE `cod_clans_system` SET `clan_skills` = '#%d#%d#%d#%d#%d#%d#%d#%d#0#0' WHERE `cid` = '%d'",
							g_PlayerClanSkill[id][unorder_points], g_PlayerClanSkill[id][exp], g_PlayerClanSkill[id][intelligence], g_PlayerClanSkill[id][health], g_PlayerClanSkill[id][stamina],
							g_PlayerClanSkill[id][condition], g_PlayerClanSkill[id][dmg], g_PlayerClanSkill[id][coin], g_arrClanData[id][cid]);

						g_Data[0] = UpdateClan;
						g_Data[1] = id;
						SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
					}
				}
				if(g_PlayerClanSkill[id][unorder_points]>0)
					SetClanSkills(id);
			}
		}
	}
	return PLUGIN_CONTINUE;
}
				
public CreateClan(id){
	if(cod_get_user_level(id)<=get_pcvar_num(g_pCvars[minlvlcreate]) || cod_get_user_coins(id)<=get_pcvar_num(g_pCvars[costcreate]) || g_arrClanData[id][cid]>=1){
		client_print(id, print_center, "Masz zbyt maly lvl lub brakuje Ci monet!");
		return PLUGIN_HANDLED;
	}
	read_argv(1, g_arrClanData[id][clanName], charsmax(g_arrClanData[][clanName]));
	
	if(strlen(g_arrClanData[id][clanName])>=MAX_CLAN_LENGTH){
		client_print(id, print_center, "Twoja nazwa klanu jest zbyt dluga [MAX: %d]", MAX_CLAN_LENGTH);
		cmdExecute(id, "messagemode nameclan");
		return PLUGIN_HANDLED;
	}
	else if(strlen(g_arrClanData[id][clanName])<=MIN_CLAN_LENGTH){
		client_print(id, print_center, "Twoja nazwa klanu jest zbyt krotka [MIN: %d]", MIN_CLAN_LENGTH);
		cmdExecute(id, "messagemode nameclan");
		return PLUGIN_HANDLED;
	}
	else{
		mysql_escape_string(g_arrClanData[id][clanName], charsmax(g_arrClanData[][clanName]));
		formatex(szQuery, charsmax(szQuery), 
			"SELECT * FROM `cod_clans_system` WHERE `clan_name`= '%s'", g_arrClanData[id][clanName]);

		g_Data[0] = CheckNameClan;
		g_Data[1] = id;
		SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
	}
	return PLUGIN_HANDLED;
}

public ChangeNameClan(id){
	if(g_arrClanData[id][permission]<2 || cod_get_user_coins(id)<=get_pcvar_num(g_pCvars[costchangename])){
		ColorChat(id, RED, "Masz za malo monet, lub nie jestes Wlascicielem!");
		MenuMainClan(id);
		return PLUGIN_CONTINUE;
	}
	read_argv(1, g_arrClanData[id][clanName], charsmax(g_arrClanData[][clanName]));
	
	if(strlen(g_arrClanData[id][clanName])>=MAX_CLAN_LENGTH){
		client_print(id, print_center, "Twoja nazwa klanu jest zbyt dluga [MAX: %d]", MAX_CLAN_LENGTH);
		cmdExecute(id, "messagemode newnameclan");
		return PLUGIN_HANDLED;
	}
	else if(strlen(g_arrClanData[id][clanName])<=MIN_CLAN_LENGTH){
		client_print(id, print_center, "Twoja nazwa klanu jest zbyt krotka [MIN: %d]", MIN_CLAN_LENGTH);
		cmdExecute(id, "messagemode newnameclan");
		return PLUGIN_HANDLED;
	}
	else{
		mysql_escape_string(g_arrClanData[id][clanName], charsmax(g_arrClanData[][clanName]));
		formatex(szQuery, charsmax(szQuery), 
			"SELECT * FROM `cod_clans_system` WHERE `clan_name`= '%s'", g_arrClanData[id][clanName]);

		g_Data[0] = ChangeName;
		g_Data[1] = id;
		SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
	}
	return PLUGIN_HANDLED;
}

public SQL_Handler(failstate, Handle:query, err[], errcode, dt[], datasize)
{
	switch(failstate){

		case TQUERY_CONNECT_FAILED, TQUERY_QUERY_FAILED:{
			new szPrefix[32];
			switch(dt[0]){

				case CheckNameClan: 	szPrefix = "Check Name Clan";
				case Create:			szPrefix = "Create Clan";
				case Create2:			szPrefix = "Create2 Clan";
				case Top10:			szPrefix = "Top10 Clan";
				case UserOfClan:		szPrefix = "UserOfClan Clan";
				case Checkmy:			szPrefix = "CheckMy Clan";
				case AddUser:			szPrefix = "AddUser Clan";
				case DeleteClan:		szPrefix = "Delete Clan";
				case LeaveClan:		szPrefix = "LeaveClan Clan";
				case DeleteUser:		szPrefix = "DeleteUser Clan";
				case ChangeName:		szPrefix = "ChangeName Clan";
				case UpdateName: 		szPrefix = "UpdateName Clan";
				case UpdateClan: 		szPrefix = "UpdateClan Clan";
				case UpdateDeputy: 		szPrefix = "UpdateDeputy Clan";
				case UpdateDeputy2: 		szPrefix = "UpdateDeputy Clan";
			}
		
			log_amx("[SQL ERROR #%d][%s] %s", errcode, szPrefix, err);
			return;
		}
	}

	new id = dt[1];
	new id2 = dt[2];

	switch(dt[0]){
		case CheckNameClan: {
			if(!SQL_NumResults(query)){

				new szName[MAX_NAME_LENGTH];
				get_user_name(id, szName, charsmax(szName));
				mysql_escape_string(szName, charsmax(szName));

				formatex(szQuery, charsmax(szQuery), 
					"INSERT INTO `cod_clans_system` \ 
     					(`cid`, `clan_name`, `clan_points`, `clan_level`, `clan_skills`, `clan_coins`, `clan_users`, `owner_name`, `deputy_name`) \ 
						VALUES ('NULL', '%s', '0', '1', '#0#0#0#0#0#0#0#0#0#0', '0', '1', '%s', 'brak')", g_arrClanData[id][clanName], szName);

				g_Data[0] = Create;
				g_Data[1] = id;
				SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
			}
			else client_print(id, print_center, "Taka nazwa klanu juz istnieje!");
		}
		case Create:{
			new szName[MAX_NAME_LENGTH], szAuth[MAX_AUTHID_LENGTH];

			get_user_name(id, szName, charsmax(szName));
			mysql_escape_string(szName, charsmax(szName));
			get_user_authid(id, szAuth, charsmax(szAuth));
			cod_set_user_coins(id, cod_get_user_coins(id)-get_pcvar_num(g_pCvars[costcreate]));

			g_arrClanData[id][cid] = SQL_GetInsertId(query);
			g_arrClanData[id][level] = 1;
			g_arrClanData[id][points] = 0;
			
			g_arrClanData[id][coins] = 0;
			g_arrClanData[id][users] = 1;
			g_arrClanData[id][permission] = 2;
			g_arrClanData[id][paid] = 0;

			ResetClanSkills(id);

			formatex(szQuery, charsmax(szQuery), 
				"INSERT INTO `cod_clans_users`(`uid`, `user_name`, `user_steamid`, `permission_lvl`, `paid_coins`, `cid`) \
				 VALUES ('NULL', '%s', '%s', '2', '0', '%d');", szName, szAuth, g_arrClanData[id][cid]);

			g_Data[0] = Create2;
			g_Data[1] = id;
			SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
		}
		case Create2:{
			g_arrClanData[id][uid] = SQL_GetInsertId(query);
			client_print(id, print_center, "Wszystko poszlo pomyslnie!");
		}
		case Top10:{

			len = formatex(gData, charsmax(gData), "<style>body{background:#000}tr{text-align:left} table{font-size:13px;color:#FFB000;padding:2px}");
			len += formatex(gData[len], charsmax(gData) - len, "h2{color:#FFF;font-family:Verdana}</style><body><table width=100%% border=0 align=center cellpadding=0 cellspacing=1>");
			len += formatex(gData[len], charsmax(gData) - len, "<tr><th>#<th><b>Nazwa</b><th>lvl<th>Punkty<th>Wplaconych Monet<th>Wlasciciel</tr>");
			new count=1;
			while(SQL_MoreResults(query)){
				new nameClan[33], nameOwner[33];
				SQL_ReadResult(query, 0, nameClan, charsmax(nameClan));
				SQL_ReadResult(query, 4, nameOwner, charsmax(nameOwner));
				len += formatex(gData[len], charsmax(gData) - len, "<tr><td>%d<td><b>%s</b><td>%d<td>%d<td>%d<td>%s</tr>",
				count, nameClan, SQL_ReadResult(query, 1), SQL_ReadResult(query, 2), SQL_ReadResult(query, 3), nameOwner);
				count++;
				SQL_NextRow(query)
			}
			show_motd(id, gData, "Top10 klanow");
		}
		case Checkmy:{
			if(SQL_NumResults(query)){
				g_arrClanData[id][cid] = SQL_ReadResult(query, 0);
				SQL_ReadResult(query, 1, g_arrClanData[id][clanName], charsmax(g_arrClanData[][clanName]));
				g_arrClanData[id][points] = SQL_ReadResult(query, 2);
				g_arrClanData[id][level] = SQL_ReadResult(query, 3);

				new skills[30];
				SQL_ReadResult(query, 4, skills, charsmax(skills));
				replace_all(skills, charsmax(skills), "#", " ");

				new Data[8][4];
				parse(skills,
					Data[0], charsmax(Data[]),
					Data[1], charsmax(Data[]),
					Data[2], charsmax(Data[]),
					Data[3], charsmax(Data[]),
					Data[4], charsmax(Data[]),
					Data[5], charsmax(Data[]),
					Data[6], charsmax(Data[]),
					Data[7], charsmax(Data[]))

				g_PlayerClanSkill[id][unorder_points] = str_to_num(Data[0]);
				g_PlayerClanSkill[id][exp] = str_to_num(Data[1]);
				g_PlayerClanSkill[id][intelligence] = str_to_num(Data[2]);
				g_PlayerClanSkill[id][health] = str_to_num(Data[3]);
				g_PlayerClanSkill[id][stamina] = str_to_num(Data[4]);
				g_PlayerClanSkill[id][condition] = str_to_num(Data[5]);
				g_PlayerClanSkill[id][dmg] = str_to_num(Data[6]);
				g_PlayerClanSkill[id][coin] = str_to_num(Data[7]);

				cod_set_user_bonus_health(id, cod_get_user_health(id, 0, 0, 1)+g_PlayerClanSkill[id][health]*get_pcvar_num(g_pCvars[skillhp]));
				cod_set_user_bonus_stamina(id, cod_get_user_stamina(id, 0, 0, 1)+g_PlayerClanSkill[id][stamina]*get_pcvar_num(g_pCvars[skillstamina]));
				cod_set_user_bonus_trim(id, cod_get_user_trim(id, 0, 0, 1)+g_PlayerClanSkill[id][stamina]*get_pcvar_num(g_pCvars[skillcondition]));
				cod_set_user_bonus_intelligence(id, cod_get_user_intelligence(id, 0, 0, 1)+g_PlayerClanSkill[id][intelligence]*get_pcvar_num(g_pCvars[skillint]));

				g_arrClanData[id][coins] = SQL_ReadResult(query, 5);
				g_arrClanData[id][users] = SQL_ReadResult(query, 6);
				g_arrClanData[id][permission] = SQL_ReadResult(query, 7);
				g_arrClanData[id][paid] = SQL_ReadResult(query, 8);
				g_arrClanData[id][uid] = SQL_ReadResult(query, 9);
			}
			g_arrClanData[id][loaded]=true;
		}
		case AddUser:{
			ResetData(id);
			CheckMyClan(id);
		}
		case UserOfClan:{
			if(SQL_NumResults(query))
			{
				new menuText[64], userInfo[40], szName[MAX_NAME_LENGTH], menu;
				menu = menu_create("Twoi Czlonkowie Klanu: ", "UserOfClanHandler");
				while(SQL_MoreResults(query))
				{
					SQL_ReadResult(query, 1, szName, charsmax(szName)); // name user of clan
					mysql_escape_string(szName, charsmax(szName));
					replace_all(szName, charsmax(szName), " ", "_");
					// SQL_ReadResult(query, 0); // uid user of clan
					// SQL_ReadResult(query, 2); // permission user of clan
					// SQL_ReadResult(query, 3); // paid coins user of clan
					formatex(userInfo, charsmax(userInfo), "#%d#%s#%d",
						 SQL_ReadResult(query, 0), szName, SQL_ReadResult(query, 2));
					// userInfo // uid, name user, permission

					if(SQL_ReadResult(query, 2) == 2){
						formatex(menuText, charsmax(menuText), "%s \r*Wlasciciel ->\y %d\d Monet", szName, SQL_ReadResult(query, 3));
					}
					else if(SQL_ReadResult(query, 2) == 1){
						formatex(menuText, charsmax(menuText), "%s \r*Zastepca ->\y %d\d Monet", szName, SQL_ReadResult(query, 3));
					} 
					else formatex(menuText, charsmax(menuText), "%s \d(Wplacil:\r %d\d Monet)", szName, SQL_ReadResult(query, 3));
					menu_additem(menu, menuText, userInfo);
					SQL_NextRow(query);
				}
				menu_display(id, menu, 0);
			}
		}
		case ChangeName:{
			if(!SQL_NumResults(query)){
				formatex(szQuery, charsmax(szQuery), 
					"UPDATE `cod_clans_system` SET `clan_name`='%s' WHERE `cid` = '%d'", g_arrClanData[id][clanName], g_arrClanData[id][cid]);

				g_Data[0] = UpdateName;
				g_Data[1] = id;
				SQL_ThreadQuery(g_hSqlTuple, "SQL_Handler", szQuery, g_Data, sizeof(g_Data));
			}
			else client_print(id, print_center, "Taka nazwa klanu juz istnieje!");
		}
		case UpdateName:{
			cod_set_user_coins(id, cod_get_user_coins(id)-get_pcvar_num(g_pCvars[costchangename]));
			client_print(id, print_center, "Pomyslnie zmieniles nazwe klanu!");
			for(new i=0;i<=MAX_PLAYERS;i++){
				if(!is_user_connected(i))
					continue;

				if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
					g_arrClanData[i][clanName]=g_arrClanData[id][clanName];
					ColorChat(id, GREEN, "Nowa nazwa klanu to:^x03 %s", g_arrClanData[id][clanName]);
				}
			}
		}
		case DeleteClan:{
			new szName[MAX_NAME_LENGTH];
			get_user_name(id, szName, charsmax(szName));
			ColorChat(id, NORMAL, "Usunales klan: %s", g_arrClanData[id][clanName])
			log_to_file("cod_clan_users.log","Gracz: %s | usunal klan: %s | cid: %d | uid: %d", szName, g_arrClanData[id][clanName],g_arrClanData[id][cid], g_arrClanData[id][uid])
			for(new i=0;i<=MAX_PLAYERS;i++){
				if(!is_user_connected(i) || i==id)
					continue;

				if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
					ResetData(i);
					CheckMyClan(i);
				}
			}
			ResetData(id);
			CheckMyClan(id);
		}
		case LeaveClan:{
			new szName[MAX_NAME_LENGTH];
			get_user_name(id, szName, charsmax(szName));
			ColorChat(id, NORMAL, "Opusciles klan: %s", g_arrClanData[id][clanName])
			log_to_file("cod_clan_users.log","Gracz: %s | Opuscil klan: %s | cid: %d | uid: %d", szName, g_arrClanData[id][clanName], g_arrClanData[id][cid], g_arrClanData[id][uid])

			for(new i=0;i<=MAX_PLAYERS;i++){
				if(!is_user_connected(i))
					continue;

				if(g_arrClanData[i][cid] == g_arrClanData[id][cid])
					g_arrClanData[i][users]--;
			}
			ResetData(id);
			CheckMyClan(id);
		}
		case DeleteUser:{
			// id =  id owner clan
			// id2 = uid player who been deleted from clan

			for(new i=0;i<=MAX_PLAYERS;i++){
				if(!is_user_connected(i))
					continue;

				if(g_arrClanData[i][cid] == g_arrClanData[id][cid]){
					g_arrClanData[i][users]--;
				}
				
				if(g_arrClanData[i][uid] == id2){
					ResetData(i);
					CheckMyClan(i);
				}
			}
		}
		case UpdateOwner:{
			for(new i=0;i<=MAX_PLAYERS;i++){
				if(!is_user_connected(i))
					continue;

				if(g_arrClanData[i][permission] == 2 && g_arrClanData[i][cid] == g_arrClanData[id][cid]){
					g_arrClanData[i][permission] = 0; // old owner 
				}
				if(g_arrClanData[i][uid] == id2){
					g_arrClanData[i][permission] = 2; // new owner
				}
			}
		}
		case UpdateDeputy:{
			for(new i=0;i<=MAX_PLAYERS;i++){
				if(!is_user_connected(i))
					continue;

				if(g_arrClanData[i][permission] == 1 && g_arrClanData[i][cid] == g_arrClanData[id][cid]){
					g_arrClanData[i][permission] = 0; // old deputy 
				}
				if(g_arrClanData[i][uid] == id2){
					g_arrClanData[i][permission] = 1; // new deputy
				}
			}			
		}
		case UpdateDeputy2:{
			for(new i=0;i<=MAX_PLAYERS;i++){
				if(!is_user_connected(i))
					continue;

				if(g_arrClanData[i][permission] == 1 && g_arrClanData[i][cid] == g_arrClanData[id][cid]){
					g_arrClanData[i][permission] = 0; // old deputy 
				}
			}			
		}
		case UpdateClan:{
			client_print(id, print_center, "Wszystko poszlo pomyslnie!");
		}
	}
}

public HookChain_Player_TakeDamage(const this, pevInflictor,const pevAttacker, Float:flDamage, bitsDamageType){
	if(!is_user_connected(pevAttacker) || pevAttacker<1 || pevAttacker>32 || this==pevAttacker || flDamage <1.0)
		return HC_CONTINUE;

	if(g_PlayerClanSkill[pevAttacker][dmg] > 0 && bitsDamageType & 1<<1)
		SetHookChainArg(4, ATYPE_FLOAT, flDamage+(g_PlayerClanSkill[pevAttacker][dmg]*get_pcvar_num(g_pCvars[skilldmg])));

	return HC_CONTINUE;
}

public CBasePlayer_Killed(victim, killer){ 
	if(!is_user_connected(killer) || killer<1 || killer>32 || victim<1 || victim>32|| killer==victim)
		return HC_CONTINUE;

	if(g_PlayerClanSkill[killer][coin] > 0){

		if(random_num(g_PlayerClanSkill[killer][coin], get_pcvar_num(g_pCvars[skillcoin])) == get_pcvar_num(g_pCvars[skillcoin]))				
			cod_set_user_coins(killer, cod_get_user_coins(killer)+1);
	}
	if(g_PlayerClanSkill[killer][exp] > 0){
		cod_set_user_xp(killer, cod_get_user_xp(killer)+g_PlayerClanSkill[killer][exp]*get_pcvar_num(g_pCvars[skillexp]));
	}
	return HC_CONTINUE;
}

LoadCvars(){
	new g_szConfigDir[64];
	get_localinfo("amxx_configsdir", g_szConfigDir, charsmax(g_szConfigDir));
	add(g_szConfigDir, charsmax(g_szConfigDir), "/CLAN");
	
	new szConfig[64]; 
	formatex(szConfig, charsmax(szConfig), "%s/clan_cvar.cfg", g_szConfigDir);
	server_cmd("exec %s", szConfig);
	server_exec();
	
	new szHost[64], szUser[64], szPass[64], szDB[64];
	get_pcvar_string(g_pCvars[host], szHost, charsmax(szHost));
	get_pcvar_string(g_pCvars[user], szUser, charsmax(szUser));
	get_pcvar_string(g_pCvars[pass], szPass, charsmax(szPass));
	get_pcvar_string(g_pCvars[db],   szDB,   charsmax(szDB));
	
	SQL_SetAffinity("mysql");
	g_hSqlTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDB, 1);
	
	new errcode, 
		errstr[128], 
		Handle:hTest = SQL_Connect(g_hSqlTuple, errcode, errstr, charsmax(errstr));
		
	if(hTest == Empty_Handle)
	{
		new szError[128];
		formatex(szError, charsmax(szError), "[SQL ERROR #%d] %s", errcode, errstr);
		set_fail_state(szError);
	}
	else
	{
		SQL_FreeHandle(hTest);
#if AMXX_VERSION_NUM >= 183
		SQL_SetCharset(g_hSqlTuple, "utf8");
#endif
	}
}

stock mysql_escape_string(output[], len){
	static const szReplaceIn[][] = { "\\", "\0", "\n", "\r", "\x1a", "'", "^"" };
	static const szReplaceOut[][] = { "\\\\", "\\0", "\\n", "\\r", "\Z", "\'", "\^"" };
	for(new i; i < sizeof szReplaceIn; i++)
		replace_string(output, len, szReplaceIn[i], szReplaceOut[i]);
}

stock cmdExecute(id, const szText[] , any:... ){
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