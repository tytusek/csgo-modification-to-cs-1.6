#include <amxmodx>
#include <csgo>
#include <ColorChat>

public plugin_init()
{
  register_plugin("[CSGO] System: Player", "1.0", "TyTuS")
  register_clcmd("say", "cmd_Czat");
}

public cmd_Czat(id)
{
  new szZawartosc[128]; 
  read_args(szZawartosc, 127);
  remove_quotes(szZawartosc);
  if(!equal(szZawartosc, "/player", 7))
  return PLUGIN_CONTINUE;

  new iTarget = find_player("bhl", szZawartosc[8]);

  if(iTarget)
  {
    new name[30];
    get_user_name(iTarget, name, 29);
    new Data[1536],Len,tytul2[64];

    Len = formatex(Data[Len], 1536 - Len, "<html><head><style type=^"text/css^">#idtest{color:white; margin-left:35%; margin-top:0px;} </style></head><body bgcolor=black><div id=^"idtest^"><br>");
    Len += formatex(Data[Len], 1536 - Len,"<br><b>Monety:</b> %d", csgo_get_user_coin(iTarget));
    Len += formatex(Data[Len], 1536 - Len,"<br><b>Czas Online:</b> %d Godzin", floatround(float(csgo_get_user_time(iTarget)/3600),  floatround_round));
    Len += formatex(Data[Len], 1536 - Len,"<br><b>Zloty Medal: </b> %d", csgo_get_user_medal_gold(iTarget));
    Len += formatex(Data[Len], 1536 - Len,"<br><b>Srebrny Medal: </b> %d", csgo_get_user_medal_silver(iTarget));
    Len += formatex(Data[Len], 1536 - Len,"<br><b>Brazowy Medal: </b> %d", csgo_get_user_medal_brown(iTarget));
    Len += formatex(Data[Len], 1536 - Len,"<br><b>Zabojstwa:</b> %d | Smierci: %d", csgo_get_user_kills(iTarget), csgo_get_user_deads(iTarget));
    Len += formatex(Data[Len], 1536 - Len,"</div></body></html>");
    formatex(tytul2, 63, "Statystyki Gracza: %s", name);
    show_motd(id, Data, tytul2);
  }
  else
  {
    ColorChat(id, GREEN, "[CSGO]^x01 Nie znaleziono gracza, wpisz nick poprawniej");
  }
  return PLUGIN_CONTINUE;
}


	