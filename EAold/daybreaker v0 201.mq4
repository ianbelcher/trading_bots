//+------------------------------------------------------------------+
//|                                            dayBreaker v0 200.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

//+------------------------------------------------------------------+
//| define GLOBAL vars                                               |
//+------------------------------------------------------------------+

#include <stderror.mqh>
#include <stdlib.mqh>

#define PROGRAM_VERSION "v0 200" // Stradle of full day using http://forex-strategies-revealed.com/advanced/midnight-setup/

#define MINUTE 1
#define HOUR 60
#define DAY 1440
#define WEEK 10080
#define MONTH 43800
#define YEAR 525600

extern bool    GLOBAL_debug                  = false;          //Increases the amount of data written to the log for debugging purposes.
extern bool    GLOBAL_resetfiles             = true;           //Deletes and resets output files. Only for development.
extern bool    GLOBAL_runcron                = true;           //This setting turns off the cron update tasks. (ONLY runs init tasks)
extern bool    GLOBAL_jumpstart              = false;          //This setting runs all cron tasks to begin with as opposed to waiting
extern int     GLOBAL_maxlookback            = 1300000;        //In seconds. This is the max overall lookback for all pairs. 2.6M is about one month.
extern double  GLOBAL_riskpertradepercentage = 0.01;           //The percentage of the account to risk per trade.
extern int     GLOBAL_pausetime              = 1000;           //In milliseconds. Time to wait before polling server after bad response.
extern bool    GLOBAL_sendnotifications      = false;          //Whether to send notifications or not.
extern double  GLOBAL_takeprofitfactor       = 1;              //The factor of size of the TP compared to the SL for a trade.

extern bool    CURRENCY_USD                  = true;
extern bool    CURRENCY_CHF                  = false;
extern bool    CURRENCY_EUR                  = true;
extern bool    CURRENCY_GBP                  = true;
extern bool    CURRENCY_CAD                  = false;
extern bool    CURRENCY_JPY                  = true;
extern bool    CURRENCY_AUD                  = true;
extern bool    CURRENCY_NZD                  = false;
extern bool    CURRENCY_SGD                  = false;
extern bool    CURRENCY_HKD                  = false;
extern bool    CURRENCY_DKK                  = false;
extern bool    CURRENCY_NOK                  = false;
extern bool    CURRENCY_SEK                  = false;
extern bool    CURRENCY_TRY                  = false;
extern bool    CURRENCY_PLN                  = false;
extern bool    CURRENCY_MXN                  = false;
extern bool    CURRENCY_XAU                  = true;
extern bool    CURRENCY_XAG                  = false;
extern string  CURRENCY_skippairs            = ";AUDJPY;EURAUD;GBPAUD;GBPJPY;USDJPY;EURGBP"; //= "CHFSGD; EURSGD; EURDKK; EURNOK; EURSEK; USDTRY; EURTRY; GBPSGD; GBPSEK; GBPNOK; GBPDKK; GBPTRY; CADSGD; CADSEK; CADNOK; CADDKK; CADTRY; AUDSGD; NZDCHF; NZDSGD; NZDCAD; NOKJPY; HKDJPY; NOKSEK; SEKJPY";

/*
Appearing to work best
AUDUSD
EURJPY
EURUSD
GBPUSD
XAUUSD
*/

int         GLOBAL_timeframe;
int         GLOBAL_cronincrement;
double      GLOBAL_riskpertradeamount;
string      GLOBAL_exportorderarray_file;
bool        GLOBAL_isdemo;

//vard - variable definitions

//v Account Variables

double      ACCOUNT_previousbalance;
double      ACCOUNT_closedordersprofit;
int         ACCOUNT_numberofclosedorders;
int         ACCOUNT_totalnumberoforders;

//v Time Array
  
int         TIME_currentweek;
int         TIME_currentday;
int         TIME_currenthour;
int         TIME_currenttimeframe;
int         TIME_currentincrement;
int         TIME_weekcrontime;
int         TIME_daycrontime;
int         TIME_hourcrontime;
int         TIME_timeframecrontime;
int         TIME_incrementcrontime;
bool        TIME_weekended;
bool        TIME_dayended;
bool        TIME_hourended;
bool        TIME_timeframeended;
bool        TIME_incrementended;

//v Function tracking array

int         FUNCTION_functionnest;
string      FUNCTION_functionname[100];
bool        FUNCTION_tracer[100];

//v Currency array

int         CURRENCY_all_numberofpairs;
int         CURRENCY_all_lookback[100];
string      CURRENCY_all_entities[100];
string      CURRENCY_all_pairs[100];

int         CURRENCY_selected_numberofpairs;
int         CURRENCY_selected_lookback[100];
string      CURRENCY_selected_entities[100];
string      CURRENCY_selected_pairs[100];

//+------------------------------------------------------------------+
//| initialization function                                          |
//+------------------------------------------------------------------+
int init(){  
   Alert("dayBreaker " + PROGRAM_VERSION + " started.");
   Alert("Initalising log");
   log(); //Initialise the log file so dependant functions can work  
   Alert("Starting init function processing");
   function_start("init", true);

   log("Signature System " + PROGRAM_VERSION + " started.");
   log("GLOBAL_pausetime: "+GLOBAL_pausetime);
   log("GLOBAL_riskpertradepercentage: "+GLOBAL_riskpertradepercentage);
   log("GLOBAL_debug: "+GLOBAL_debug);
   log("GLOBAL_resetfiles: "+GLOBAL_resetfiles);
   log("GLOBAL_runcron: "+GLOBAL_runcron);
   log("GLOBAL_jumpstart: "+GLOBAL_jumpstart);
   log("GLOBAL_maxlookback: "+GLOBAL_maxlookback);
   log("GLOBAL_riskpertradepercentage: "+GLOBAL_riskpertradepercentage);
   log("GLOBAL_pausetime: "+GLOBAL_pausetime);
   log("GLOBAL_sendnotifications: "+GLOBAL_sendnotifications);
   log("GLOBAL_takeprofitfactor: "+GLOBAL_takeprofitfactor);
   log("CURRENCY_USD :"+CURRENCY_USD);
   log("CURRENCY_CHF :"+CURRENCY_USD);
   log("CURRENCY_EUR :"+CURRENCY_EUR);
   log("CURRENCY_GBP :"+CURRENCY_GBP);
   log("CURRENCY_CAD :"+CURRENCY_CAD);
   log("CURRENCY_JPY :"+CURRENCY_JPY);
   log("CURRENCY_AUD :"+CURRENCY_AUD);
   log("CURRENCY_NZD :"+CURRENCY_NZD);
   log("CURRENCY_SGD :"+CURRENCY_SGD);
   log("CURRENCY_HKD :"+CURRENCY_HKD);
   log("CURRENCY_DKK :"+CURRENCY_DKK);
   log("CURRENCY_NOK :"+CURRENCY_NOK);
   log("CURRENCY_SEK :"+CURRENCY_SEK);
   log("CURRENCY_TRY :"+CURRENCY_TRY);
   log("CURRENCY_PLN :"+CURRENCY_PLN);
   log("CURRENCY_MXN :"+CURRENCY_MXN);
   log("CURRENCY_XAU :"+CURRENCY_XAU);
   log("CURRENCY_XAG :"+CURRENCY_XAG);
   log("CURRENCY_skippairs :"+CURRENCY_skippairs);
     
   GLOBAL_timeframe              = DAY;               //In Minutes. The timeframe to cycle orders.
   GLOBAL_cronincrement          = MINUTE * 5;        //In Minutes. What time frame to run the smallest cron task
  
   GLOBAL_isdemo                 = IsDemo();
   GLOBAL_riskpertradeamount     = AccountBalance() * GLOBAL_riskpertradepercentage;
   GLOBAL_exportorderarray_file  = AccountNumber()+"-orders.csv";

   ACCOUNT_previousbalance       = AccountBalance();
   
   TIME_weekcrontime             = 4 * 60;
   TIME_daycrontime              = 3 * 60;
   TIME_hourcrontime             = 2 * 60;
   TIME_timeframecrontime        = GLOBAL_timeframe / 240;
   TIME_incrementcrontime        = GLOBAL_cronincrement / 60;
   
   if(GLOBAL_jumpstart == true){
      TIME_currentweek              = 0;
      TIME_currentday               = 0;
      TIME_currenthour              = 0;
      TIME_currenttimeframe         = 0;
      TIME_currentincrement         = 0;
      TIME_weekended                = FALSE;
      TIME_dayended                 = FALSE;
      TIME_hourended                = FALSE;
      TIME_timeframeended           = FALSE;
      TIME_incrementended           = FALSE;
   }else{
      TIME_currentweek              = iTime(Symbol(), PERIOD_W1, 0);
      TIME_currentday               = iTime(Symbol(), PERIOD_D1, 0);
      TIME_currenthour              = iTime(Symbol(), PERIOD_H1, 0);
      TIME_currenttimeframe         = iTime(Symbol(), GLOBAL_timeframe, 0);
      TIME_currentincrement         = iTime(Symbol(), GLOBAL_cronincrement, 0);
      TIME_weekended                = TRUE;
      TIME_dayended                 = TRUE;
      TIME_hourended                = TRUE;
      TIME_timeframeended           = TRUE;
      TIME_incrementended           = TRUE;
   }
   
   init_populatecurrencyarray();
   init_getlookback();
   
   if(GLOBAL_resetfiles){
      init_resetfiles();
   }
     
   testing_runtests();
     
   Alert("Initalised");
    
   function_end();
   return(0);
}

int deinit(){

   Alert("Uninitalised EA");

}

//+------------------------------------------------------------------+
//| start function                                                   |
//+------------------------------------------------------------------+
int start(){

   if(GLOBAL_runcron == true){
      cron_update();
   }
  
   return(0);
}


//+------------------------------------------------------------------+
//| cron functions                                                   |
//+------------------------------------------------------------------+

void cron_update(){
   function_start("cron_update", true);
   
   //Week
   if(
      iTime(Symbol(), PERIOD_W1, 0) * 2 - iTime(Symbol(), PERIOD_W1, 1) - TimeCurrent() < TIME_weekcrontime &&
      TIME_weekended == FALSE
   ){
      cron_endweek();
   }
   
   if(TIME_currentweek != iTime(Symbol(), PERIOD_W1, 0)){
      if(TIME_weekended == FALSE){
         cron_endweek();
      }
      cron_newweek();
      TIME_currentweek = iTime(Symbol(), PERIOD_W1, 0);
   }
   
   //Day
   if(
      iTime(Symbol(), PERIOD_D1, 0) * 2 - iTime(Symbol(), PERIOD_D1, 1) - TimeCurrent() < TIME_daycrontime &&
      TIME_dayended == FALSE
   ){
      cron_endday();
   }
   
   if(TIME_currentday != iTime(Symbol(), PERIOD_D1, 0)){
      if(TIME_dayended == FALSE){
         cron_endday();
      }
      cron_newday();
      TIME_currentday = iTime(Symbol(), PERIOD_D1, 0);
   }
   
   //Hour
   if(
      iTime(Symbol(), PERIOD_H1, 0) * 2 - iTime(Symbol(), PERIOD_H1, 1) - TimeCurrent() < TIME_hourcrontime &&
      TIME_hourended == FALSE
   ){
      cron_endhour();
   }
   
   if(TIME_currenthour != iTime(Symbol(), PERIOD_H1, 0)){
      if(TIME_hourended == FALSE){
         cron_endhour();
      }
      cron_newhour();
      TIME_currenthour = iTime(Symbol(), PERIOD_H1, 0);
   }
      
   //Timeframe
   if(
      iTime(Symbol(), GLOBAL_timeframe, 0) * 2 - iTime(Symbol(), GLOBAL_timeframe, 1) - TimeCurrent() < TIME_timeframecrontime &&
      TIME_timeframeended == FALSE
   ){
      cron_endtimeframe();
   }
   
   if(TIME_currenttimeframe != iTime(Symbol(), GLOBAL_timeframe, 0)){
      if(TIME_timeframeended == FALSE){
         cron_endtimeframe();
      }
      cron_newtimeframe();
      TIME_currenttimeframe = iTime(Symbol(), GLOBAL_timeframe, 0);
   }

   //Increment
   if(
      iTime(Symbol(), GLOBAL_cronincrement, 0) * 2 - iTime(Symbol(), GLOBAL_cronincrement, 1) - TimeCurrent() < TIME_incrementcrontime &&
      TIME_incrementended == FALSE
   ){
      cron_endincrement();
   }
   
   if(TIME_currentincrement != iTime(Symbol(), GLOBAL_cronincrement, 0)){
      if(TIME_incrementended == FALSE){
         cron_endincrement();
      }
      cron_newincrement();
      TIME_currentincrement = iTime(Symbol(), GLOBAL_cronincrement, 0);
   }

   function_end();
}



void cron_endweek(){
   function_start("cron_endweek", true);

   log("Ending Week");
   //v---------------------


   //^---------------------     
   TIME_weekended = TRUE;
   function_end();
}

void cron_newweek(){
   function_start("cron_newweek", true);
   
   log("Starting Week");
   //v---------------------
   
   
   //^---------------------
   TIME_weekended = FALSE;
   function_end();   
}

void cron_endday(){
   function_start("cron_endday", true);
   
   log("Ending Day");
   //v---------------------
   
   
   //^---------------------
   TIME_dayended = TRUE;
   function_end();
}

void cron_newday(){
   function_start("cron_newday", true);
   
   log("Starting Day");
   //v---------------------
   
   
   
   //^---------------------
   TIME_dayended = FALSE;
   function_end();
}

void cron_endhour(){
   function_start("cron_endhour", true);
   
   log("Ending Hour");
   //v---------------------
   

   
   //^---------------------
   TIME_hourended = TRUE;
   function_end();
}

void cron_newhour(){
   function_start("cron_newhour", true);

   log("Starting Hour");
   //v---------------------


   
   //^---------------------
   TIME_hourended = FALSE;
   function_end();
}

void cron_endtimeframe(){
   function_start("cron_endtimeframe", true);
   
   log("Ending Timeframe");
   //v---------------------


   
   //^---------------------
   TIME_timeframeended = TRUE;
   function_end();
}

void cron_newtimeframe(){
   function_start("cron_newtimeframe", true);

   log("Starting Timeframe");
   //v---------------------


   
   //^---------------------
   TIME_timeframeended = FALSE;
   function_end();
}

void cron_endincrement(){
   function_start("cron_endincrement", true);
   
   log("Ending Increment");
   //v---------------------
   
   

   //^---------------------
   TIME_incrementended = TRUE;
   
   function_end();
}

void cron_newincrement(){
   function_start("cron_newincrement", true);
   
   log("Starting Increment");
   //v---------------------
   
   
   //^---------------------
   TIME_incrementended = FALSE;
   function_end();      
}

//+------------------------------------------------------------------+
//| function tracking                                                |
//+------------------------------------------------------------------+

void function_start(string FUNCGET_functionname, bool FUNCGET_tracer = false){
   FUNCTION_functionnest++;
   FUNCTION_functionname[FUNCTION_functionnest] = FUNCGET_functionname;
   FUNCTION_tracer[FUNCTION_functionnest] = FUNCGET_tracer;
   if(GLOBAL_debug == true && FUNCTION_tracer[FUNCTION_functionnest] == true){
      log("Function Start");
   }
}

void function_end(){
   if(GLOBAL_debug == true && FUNCTION_tracer[FUNCTION_functionnest] == true){
      log("Function End");
   }
   FUNCTION_functionname[FUNCTION_functionnest] = "";
   FUNCTION_functionnest--;
}

//+------------------------------------------------------------------+
//| Account functions                                                |
//+------------------------------------------------------------------+

void account_update(){
   function_start("account_update", true);
   
   double
      FUNCVAR_accountchange,
      FUNCVAR_accountchangepercentage
      ;

   FUNCVAR_accountchange = AccountBalance() - ACCOUNT_previousbalance;
   if(ACCOUNT_previousbalance > 0){
      FUNCVAR_accountchangepercentage = ((AccountBalance() / ACCOUNT_previousbalance)-1)*100;
   }else{
      FUNCVAR_accountchangepercentage = 100;
   }
   if(GLOBAL_sendnotifications == true){
      //Add more information here as to winners vs losers.
      SendNotification("Pre:"+DoubleToStr(ACCOUNT_previousbalance, 2)+AccountCurrency()+" Post:"+DoubleToStr(AccountBalance(), 2)+AccountCurrency()+" Change:"+DoubleToStr(FUNCVAR_accountchange, 2)+" "+DoubleToStr(FUNCVAR_accountchangepercentage, 2)+"% Closed:"+ACCOUNT_numberofclosedorders+" orders of "+ACCOUNT_totalnumberoforders+" for "+DoubleToStr(ACCOUNT_closedordersprofit, 2)+AccountCurrency());
   }
   ACCOUNT_previousbalance = AccountBalance();
   GLOBAL_riskpertradeamount = AccountBalance() * GLOBAL_riskpertradepercentage;

   function_end();
}

//+------------------------------------------------------------------+
//| frontend functions                                               |
//+------------------------------------------------------------------+





//+------------------------------------------------------------------+
//| information functions                                            |
//+------------------------------------------------------------------+

double getinfo(int FUNCGET_what, string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber) {
   function_start("getinfo");
   
   int 
      FUNCVAR_loopcount = 0,
      FUNCVAR_errornumber, 
      FUNCVAR_done,
      FUNCVAR_newlookback,
      FUNCVAR_checkvalue
      ;
   double
      FUNCVAR_high,
      FUNCVAR_low,
      FUNCVAR_return
      ;
   
   if(iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) == 0){
      log("Trying to get data beyond limit for "+FUNCGET_what+" "+FUNCGET_pair+" "+FUNCGET_timeframe+" "+FUNCGET_barnumber);
   }
       
   switch (FUNCGET_what){
      case 1: //Open
         FUNCVAR_return = iOpen(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
         function_end();
         return(FUNCVAR_return);
         break;
      case 2: //High
         FUNCVAR_return = iHigh(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
         function_end();
         return(FUNCVAR_return);
         break;
      case 3: //Low
         FUNCVAR_return = iLow(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
         function_end();
         return(FUNCVAR_return);
         break;
      case 4: //Close
         FUNCVAR_return = iClose(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
         function_end();
         return(FUNCVAR_return);
         break;
      case 5: //Time
         FUNCVAR_return = iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
         function_end();
         return(FUNCVAR_return);
         break;
      case 6: //Volume
         FUNCVAR_return = iVolume(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
         function_end();
         return(FUNCVAR_return);
         break;     
      case 7: //Range
         FUNCVAR_return = iHigh(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) - iLow(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
         function_end();
         return(FUNCVAR_return);
         break;
      case 500: //Spread
         FUNCVAR_return = MarketInfo(FUNCGET_pair, MODE_SPREAD);
         function_end();
         return(FUNCVAR_return);
         break;
      case 501: //Point
         FUNCVAR_return = MarketInfo(FUNCGET_pair, MODE_POINT);
         function_end();
         return(FUNCVAR_return);
         break;
      case 502: //Spread as double
         FUNCVAR_return = MarketInfo(FUNCGET_pair, MODE_SPREAD) * MarketInfo(FUNCGET_pair, MODE_POINT);
         function_end();
         return(FUNCVAR_return);
         break;
      case 503: //Minimum distance between market and SL point
         FUNCVAR_return = MarketInfo(FUNCGET_pair, MODE_STOPLEVEL) * MarketInfo(FUNCGET_pair, MODE_POINT);
         function_end();
         return(FUNCVAR_return);
         break;
      default:
         log("INCORRECT Selection made in switch for function getinfo*** Looking for " + FUNCGET_what);    
         function_end();
         return(0);
         break;
   }
   
   function_end();
   return(0);
}

//+------------------------------------------------------------------+
//| initialisation functions                                         |
//+------------------------------------------------------------------+

void init_populatecurrencyarray(){
   function_start("init_populatecurrencyarray", true);
   
   int
      FUNCVAR_basecurrency,
      FUNCVAR_countercurrency
      ;
   string
      FUNCVAR_currentpair = "",
      FUNCVAR_currencylist = ""
      ;
   
   for(int a=0;a<100;a++){
      CURRENCY_selected_entities[a] = " ";
      CURRENCY_all_entities[a] = " ";
      CURRENCY_selected_pairs[a] = " ";
      CURRENCY_all_pairs[a] = " ";
   }
   CURRENCY_selected_numberofpairs = 0;
   CURRENCY_all_numberofpairs = 0;
   
   if(CURRENCY_USD){
      CURRENCY_selected_entities[0] = "USD";
   }
   CURRENCY_all_entities[0] = "USD";
   if(CURRENCY_CHF){
      CURRENCY_selected_entities[1] = "CHF";
   }
   CURRENCY_all_entities[1] = "CHF";
   if(CURRENCY_EUR){
      CURRENCY_selected_entities[2] = "EUR";
   }
   CURRENCY_all_entities[2] = "EUR";
   if(CURRENCY_GBP){
      CURRENCY_selected_entities[3] = "GBP";
   }
   CURRENCY_all_entities[3] = "GBP";
   if(CURRENCY_CAD){
      CURRENCY_selected_entities[4] = "CAD";
   }
   CURRENCY_all_entities[4] = "CAD";   
   if(CURRENCY_JPY){
      CURRENCY_selected_entities[5] = "JPY";
   }
   CURRENCY_all_entities[5] = "JPY";   
   if(CURRENCY_AUD){
      CURRENCY_selected_entities[6] = "AUD";
   }
   CURRENCY_all_entities[6] = "AUD";   
   if(CURRENCY_NZD){
      CURRENCY_selected_entities[7] = "NZD";
   }
   CURRENCY_all_entities[7] = "NZD";
   if(CURRENCY_SGD){
      CURRENCY_selected_entities[8] = "SGD";
   } 
   CURRENCY_all_entities[8] = "SGD";  
   if(CURRENCY_HKD){
      CURRENCY_selected_entities[9] = "HKD";
   }
   CURRENCY_all_entities[9] = "HKD";   
   if(CURRENCY_DKK){
      CURRENCY_selected_entities[10] = "DKK";
   }
   CURRENCY_all_entities[10] = "DKK";   
   if(CURRENCY_NOK){
      CURRENCY_selected_entities[11] = "NOK";
   }
   CURRENCY_all_entities[11] = "NOK";
   if(CURRENCY_SEK){
      CURRENCY_selected_entities[12] = "SEK";
   }
   CURRENCY_all_entities[12] = "SEK";   
   if(CURRENCY_TRY){
      CURRENCY_selected_entities[13] = "TRY";
   }
   CURRENCY_all_entities[13] = "TRY";   
   if(CURRENCY_PLN){
      CURRENCY_selected_entities[14] = "PLN";
   }
   CURRENCY_all_entities[14] = "PLN";   
   if(CURRENCY_MXN){
      CURRENCY_selected_entities[15] = "MXN";
   }
   CURRENCY_all_entities[15] = "MXN";
   if(CURRENCY_XAU){
      CURRENCY_selected_entities[16] = "XAU";
   }
   CURRENCY_all_entities[16] = "XAU";   
   if(CURRENCY_XAG){
      CURRENCY_selected_entities[17] = "XAG";
   }
   CURRENCY_all_entities[17] = "XAG";      
   
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < 100; FUNCVAR_basecurrency++){
      for(FUNCVAR_countercurrency = 0; FUNCVAR_countercurrency < 100; FUNCVAR_countercurrency++){
         FUNCVAR_currentpair = CURRENCY_all_entities[FUNCVAR_basecurrency] + CURRENCY_all_entities[FUNCVAR_countercurrency];
         if(
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1
         ){
            CURRENCY_all_pairs[CURRENCY_all_numberofpairs] = FUNCVAR_currentpair;
            CURRENCY_all_numberofpairs++;
         }
         GetLastError();
      }
   }
   
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < 100; FUNCVAR_basecurrency++){
      for(FUNCVAR_countercurrency = 0; FUNCVAR_countercurrency < 100; FUNCVAR_countercurrency++){
         FUNCVAR_currentpair = CURRENCY_selected_entities[FUNCVAR_basecurrency] + CURRENCY_selected_entities[FUNCVAR_countercurrency];
         if(
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1 &&
            StringFind(CURRENCY_skippairs, FUNCVAR_currentpair) < 0
         ){
            CURRENCY_selected_pairs[CURRENCY_selected_numberofpairs] = FUNCVAR_currentpair;
            CURRENCY_selected_numberofpairs++;
         }
         GetLastError();
      }
   }
   
   for(a=0; a < CURRENCY_selected_numberofpairs; a++){
      if(StringLen(CURRENCY_selected_pairs[a])>0){
         FUNCVAR_currencylist = FUNCVAR_currencylist+";"+CURRENCY_selected_pairs[a];
      }
   }
   log("Found "+CURRENCY_all_numberofpairs+" pairs and using "+CURRENCY_selected_numberofpairs+": "+FUNCVAR_currencylist);
   log("=SUMIF(R68C7:R3000C7,R[-1]C,R68C28:R3000C28)&\" \"&SUMIF(R68C7:R3000C7,R[-1]C,R68C35:R3000C35)&\" \"&SUMIF(R68C7:R3000C7,R[-1]C,R68C28:R3000C28)+SUMIF(R68C7:R3000C7,R[-1]C,R68C35:R3000C35)");
   
   function_end();
}


int init_getlookback(){
   function_start("getlookback", true);
   
   int
      FUNCVAR_barnumber,
      FUNCVAR_lookback,
      FUNCVAR_pairscount,
      FUNCVAR_newlookback,
      FUNCVAR_counter
      ;
   string
      FUNCVAR_currentpair = "",
      FUNCVAR_pair
      ;
      
   log("Getting lookback for each pair"); 
   for(FUNCVAR_counter=0;FUNCVAR_counter<CURRENCY_all_numberofpairs;FUNCVAR_counter++){
      FUNCVAR_currentpair = CURRENCY_all_pairs[FUNCVAR_counter];
      FUNCVAR_barnumber = 1;
      while(
         iTime(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) > 0 &&
         iTime(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) > TimeCurrent() - GLOBAL_maxlookback
      ){
         FUNCVAR_barnumber++;
      }
      CURRENCY_all_lookback[FUNCVAR_counter] = FUNCVAR_barnumber - 1;
   }
   
   for(FUNCVAR_counter=0;FUNCVAR_counter<CURRENCY_selected_numberofpairs;FUNCVAR_counter++){
      FUNCVAR_currentpair = CURRENCY_selected_pairs[FUNCVAR_counter];
      FUNCVAR_barnumber = 1;
      while(
         iTime(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) > 0 &&
         iTime(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) > TimeCurrent() - GLOBAL_maxlookback
      ){
         FUNCVAR_barnumber++;
      }
      CURRENCY_selected_lookback[FUNCVAR_counter] = FUNCVAR_barnumber - 1;
      
      log(FUNCVAR_currentpair+" back to barnumber "+CURRENCY_selected_lookback[FUNCVAR_counter]+" dated: "+humandate(iTime(FUNCVAR_currentpair, GLOBAL_timeframe, CURRENCY_selected_lookback[FUNCVAR_counter])));
   }
   GetLastError();
   log("END Getting lookback"); 
   
   function_end();  
}

void init_resetfiles(){
   function_start("init_resetfiles", true);
   
   int
      FUNCVAR_file
      ;
   
   if(GLOBAL_isdemo == true){
      log("Initialising Orders File");
      string FUNCVAR_ordersheaderarray[1] = {"Orders"};
      FUNCVAR_file = openafile(GLOBAL_exportorderarray_file, FUNCVAR_ordersheaderarray);
      FileClose(FUNCVAR_file);
   }else{
      Alert("Will not reset "+GLOBAL_exportorderarray_file+" file automatically on live account. Please manually change this file.");
   }
   
   function_end();
}

//+------------------------------------------------------------------+
//| record keeping functions                                         |
//+------------------------------------------------------------------+

void log(string FUNCGET_msg = "NULL"){
//Logging and function management in this function can create infinite loops if there are errors.
//Please refrain.
   int 
      FUNCVAR_logfile,
      FUNCVAR_counter
      ;
   string 
      FUNCVAR_functionnamelist
      ;

   if(GLOBAL_resetfiles == true && FUNCGET_msg == "NULL"){
      FileDelete("log.csv");
      GetLastError();
   }
         
   FUNCVAR_logfile = FileOpen("log.csv", FILE_CSV|FILE_WRITE|FILE_READ);
   if(FUNCVAR_logfile < 1){
     Alert("log.csv file not found, the last error is ", ErrorDescription(GetLastError()));
     FileClose(FUNCVAR_logfile);
     return(0);
   }
   FileSeek(FUNCVAR_logfile, 0, SEEK_END);
   if(FUNCGET_msg != "NULL"){
      FUNCVAR_functionnamelist = "root";
      for(FUNCVAR_counter=1; FUNCVAR_counter<=FUNCTION_functionnest; FUNCVAR_counter++){
         FUNCVAR_functionnamelist= FUNCVAR_functionnamelist + "-" + FUNCTION_functionname[FUNCVAR_counter];
      }
      FileWrite(FUNCVAR_logfile, humandate(TimeLocal()), ErrorDescription(GetLastError()), FUNCVAR_functionnamelist, FUNCGET_msg);
   }
   FileClose(FUNCVAR_logfile);
}

string humandate(int FUNCGET_unixdate){ 
   string 
      FUNCVAR_secondsprepend = "",
      FUNCVAR_minuteprepend = "",
      FUNCVAR_hourprepend = "",
      FUNCVAR_dayprepend = "",
      FUNCVAR_monthprepend = "",
      FUNCVAR_return = ""
      ;
   if(FUNCGET_unixdate == 0 || FUNCGET_unixdate == 1000000000000000){
      return(" ");
   }
   if(TimeHour(FUNCGET_unixdate) < 10){
      FUNCVAR_hourprepend = "0";
   }
   if(TimeMinute(FUNCGET_unixdate) < 10){
      FUNCVAR_minuteprepend = "0";
   }
   if(TimeSeconds(FUNCGET_unixdate) < 10){
      FUNCVAR_secondsprepend = "0";
   }
   if(TimeDay(FUNCGET_unixdate) < 10){
      FUNCVAR_dayprepend = "0";
   }
   if(TimeMonth(FUNCGET_unixdate) < 10){
      FUNCVAR_monthprepend = "0";
   }
   FUNCVAR_return = TimeYear(FUNCGET_unixdate)+"-"+FUNCVAR_monthprepend+TimeMonth(FUNCGET_unixdate)+"-"+FUNCVAR_dayprepend+TimeDay(FUNCGET_unixdate)+" "+FUNCVAR_hourprepend+TimeHour(FUNCGET_unixdate)+":"+FUNCVAR_minuteprepend+TimeMinute(FUNCGET_unixdate)+":"+FUNCVAR_secondsprepend+TimeSeconds(FUNCGET_unixdate);
   return(FUNCVAR_return);
}

int openafile(string FUNCGET_filename, string FUNCGET_headerarray[]){
   function_start("openafile", true);
   
   string 
      FUNCVAR_headerstring
      ;
   int 
      FUNCVAR_filenumber,
      FUNCVAR_loopcount
      ;
      
   if(ArraySize(FUNCGET_headerarray) > 0){
      FileDelete(FUNCGET_filename);
      GetLastError();
      FUNCVAR_filenumber = FileOpen(FUNCGET_filename, FILE_CSV|FILE_WRITE|FILE_READ);
      if(FUNCVAR_filenumber < 1){
         Alert(FUNCGET_filename+" file not found, the last error is ", GetLastError());
         function_end();
         return(0);
      }
      for(FUNCVAR_loopcount = 0; FUNCVAR_loopcount <= ArraySize(FUNCGET_headerarray); FUNCVAR_loopcount++){
         FUNCVAR_headerstring = FUNCVAR_headerstring + FUNCGET_headerarray[FUNCVAR_loopcount] + ";";
      }
      GetLastError();
      FileWrite(FUNCVAR_filenumber, FUNCVAR_headerstring);
      log(FUNCGET_filename + " header written");
      function_end();
      return(FUNCVAR_filenumber);
   }else{
      GetLastError();
      FUNCVAR_filenumber = FileOpen(FUNCGET_filename, FILE_CSV|FILE_WRITE|FILE_READ);
      if(FUNCVAR_filenumber < 1){
         Alert(FUNCGET_filename+" file not found, the last error is ", GetLastError());
         function_end();
         return(0);
      }else{
         FileSeek(FUNCVAR_filenumber, 0, SEEK_END);
         function_end();
         return(FUNCVAR_filenumber);
      }
   }
   function_end();
   return(0);
}

string getinfosummarydate(string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber) {  
   function_start("getinfosummarydate", true);
   
   string FUNCVAR_return = humandate(iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
   function_end();
   return(FUNCVAR_return);
}

//+------------------------------------------------------------------+
//| testing and data functions                                       |
//+------------------------------------------------------------------+

void testing_runtests(){
   function_start("testing_runtests", true);
    
   //Returns a report on the trades which would have been taken in the last number of days
      //testing_demonumberofperiods();

   //Returns the volitility report and shuts down the EA.
      GLOBAL_runcron = false;
      log("GLOBAL_runcron set to false. *** EA will not perform cron tasks***");
      log(";;;;Sprd;SLF;TP;SL;Prize;sprdrto;slrto;HP;HHit;HTP;HTPHit;HSL;HSLHit;HH;HWin;LP;LHit;LTP;LTPHit;LSL;LSLHit;LH;LWin;;10000");
      ObjectsDeleteAll();
      for(int a=2; a<2000; a++){
         
         volatility_createvolarray(a);
         volatility_testvolarray();
         volatility_logvolarray(a);
         volatility_clearvolarray();
      }
      
   function_end();
}


//+------------------------------------------------------------------+
//| volatility class                                                 |
//+------------------------------------------------------------------+

//vard - variable definitions

string   VOL_vol_pair[100];
int      VOL_vol_bar[100];
double   VOL_vol_testvar[100];
double   VOL_vol_spread[100];
double   VOL_vol_stoplossfactor[100];

double   VOL_vol_tp[100];
double   VOL_vol_sl[100];
double   VOL_vol_prize[100];
double   VOL_vol_ratio_spread[100];
double   VOL_vol_ratio_slfactor[100];

double   VOL_vol_highpoint[100];
double   VOL_vol_highhit[100];
double   VOL_vol_hightppoint[100];
double   VOL_vol_hightphit[100];
double   VOL_vol_highslpoint[100];
double   VOL_vol_highslhit[100];
double   VOL_vol_highmaxpriorsl[100];
double   VOL_vol_highwinner[100];
double   VOL_vol_lowpoint[100];
double   VOL_vol_lowhit[100];
double   VOL_vol_lowtppoint[100];
double   VOL_vol_lowtphit[100];
double   VOL_vol_lowslpoint[100];
double   VOL_vol_lowslhit[100];
double   VOL_vol_lowmaxpriorsl[100];
double   VOL_vol_lowwinner[100];

int      VOLCONST_vol_timeframe = HOUR;
int      VOLCONST_vol_minitimeframe = 5;
int      VOLCONST_vol_lookback = 5;
int      VOLCONST_vol_targetfactor = 10; //size of tp compared to sl
int      VOLCONST_vol_slfactor = 5; //size of sl compared to slratio
double   VOLCONST_vol_targetsize = 1; //percentage of the average break to aim for.
double   VOLCONST_vol_minsprdrto = 1;
double   VOLCONST_vol_minslrto = 1;

void volatility_logvolarray(int FUNCGET_instance = 1){
   function_start("volatility_logvolarray", true);
   for(int a=0;a<100;a++){
      if(
         StringLen(VOL_vol_pair[a]) > 2 &&
         TimeHour(iTime(VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a])) >= 8 &&
         TimeHour(iTime(VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a])) <= 20 
      ){
         log(
         humandate(iTime(VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a]))+";"+
         iTime(VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a])+";"+
         VOL_vol_testvar[a]+";"+
         VOL_vol_pair[a]+";"+
         VOL_vol_spread[a]+";"+
         VOL_vol_stoplossfactor[a]+";"+
           
         VOL_vol_tp[a]+";"+
         VOL_vol_sl[a]+";"+
         VOL_vol_prize[a]+";"+
         VOL_vol_ratio_spread[a]+";"+
         VOL_vol_ratio_slfactor[a]+";"+
                
         VOL_vol_highpoint[a]+";"+
         humandate(VOL_vol_highhit[a])+";"+
         //VOL_vol_highhit[a]+";"+
         VOL_vol_hightppoint[a]+";"+
         humandate(VOL_vol_hightphit[a])+";"+
         VOL_vol_highslpoint[a]+";"+
         humandate(VOL_vol_highslhit[a])+";"+
         VOL_vol_highmaxpriorsl[a]+";"+
         volatility_removezero(VOL_vol_highwinner[a])+";"+
         
         VOL_vol_lowpoint[a]+";"+
         humandate(VOL_vol_lowhit[a])+";"+
         //VOL_vol_lowhit[a]+";"+
         VOL_vol_lowtppoint[a]+";"+
         humandate(VOL_vol_lowtphit[a])+";"+
         VOL_vol_lowslpoint[a]+";"+
         humandate(VOL_vol_lowslhit[a])+";"+
         VOL_vol_lowmaxpriorsl[a]+";"+
         volatility_removezero(VOL_vol_lowwinner[a])+";"+
         "=IF(RC5<>R[-1]C5,SUMIF(R41C5:R9971C5,RC5,R41C22:R9971C22)+SUMIF(R41C5:R9971C5,RC5,R41C30:R9971C30),\"\")"+";"+
         "=IF(RC[-1]<>\"\",R[-1]C+R40C*RC[-1]*0.01,R[-1]C)"+";"+
         "=MAX(R[-1]C,RC[-1])"+";"+
         "=RC[-2]/RC[-1]"+";"+
         "");
         
         if(VOL_vol_pair[a] == Symbol()){
            ObjectCreate("hline-"+FUNCGET_instance+a+"entry", OBJ_RECTANGLE, 0, 
               iTime(Symbol(),VOLCONST_vol_timeframe, VOL_vol_bar[a] - 1), 
               VOL_vol_highpoint[a], 
               iTime(Symbol(),VOLCONST_vol_timeframe, VOL_vol_bar[a]), 
               VOL_vol_lowpoint[a]
            );
            ObjectSet("hline-"+FUNCGET_instance+a+"entry", OBJPROP_COLOR, Blue);
            ObjectSet("hline-"+FUNCGET_instance+a+"entry", OBJPROP_STYLE, 0);
            ObjectSet("hline-"+FUNCGET_instance+a+"entry", OBJPROP_WIDTH, 2);
            ObjectSet("hline-"+FUNCGET_instance+a+"entry", OBJPROP_BACK, 0);
         
            ObjectCreate("hline-"+FUNCGET_instance+a+"sl", OBJ_RECTANGLE, 0, 
               iTime(Symbol(),VOLCONST_vol_timeframe, VOL_vol_bar[a] - 1), 
               VOL_vol_highslpoint[a], 
               iTime(Symbol(),VOLCONST_vol_timeframe, VOL_vol_bar[a]), 
               VOL_vol_lowslpoint[a]
            );
            ObjectSet("hline-"+FUNCGET_instance+a+"sl", OBJPROP_COLOR, Orange);
            ObjectSet("hline-"+FUNCGET_instance+a+"sl", OBJPROP_STYLE, 0);
            ObjectSet("hline-"+FUNCGET_instance+a+"sl", OBJPROP_WIDTH, 2);
            ObjectSet("hline-"+FUNCGET_instance+a+"sl", OBJPROP_BACK, 0);
            
            ObjectCreate("hline-"+FUNCGET_instance+a+"tp", OBJ_RECTANGLE, 0, 
               iTime(Symbol(),VOLCONST_vol_timeframe, VOL_vol_bar[a] - 1), 
               VOL_vol_hightppoint[a], 
               iTime(Symbol(),VOLCONST_vol_timeframe, VOL_vol_bar[a]), 
               VOL_vol_lowtppoint[a]
            );
            ObjectSet("hline-"+FUNCGET_instance+a+"tp", OBJPROP_COLOR, Red);
            ObjectSet("hline-"+FUNCGET_instance+a+"tp", OBJPROP_STYLE, 0);
            ObjectSet("hline-"+FUNCGET_instance+a+"tp", OBJPROP_WIDTH, 2);
            ObjectSet("hline-"+FUNCGET_instance+a+"tp", OBJPROP_BACK, 0);
            
            ObjectCreate("heading-"+FUNCGET_instance+a+"high", OBJ_TEXT, 0, iTime(Symbol(),VOLCONST_vol_timeframe, VOL_vol_bar[a]), VOL_vol_highpoint[a]);
            ObjectSetText("heading-"+FUNCGET_instance+a+"high", "               "+VOL_vol_highwinner[a], 9, "Courier New", White);
            ObjectCreate("heading-"+FUNCGET_instance+a+"low", OBJ_TEXT, 0, iTime(Symbol(),VOLCONST_vol_timeframe, VOL_vol_bar[a]), VOL_vol_lowpoint[a]);
            ObjectSetText("heading-"+FUNCGET_instance+a+"low", "               "+VOL_vol_lowwinner[a], 9, "Courier New", White);
         }
      }
   }
   function_end();
}

void volatility_clearvolarray(){
   function_start("volatility_clearvolarray", true);
   for(int a=0;a<100;a++){
         VOL_vol_pair[a] = "";
         VOL_vol_bar[a] = 0;
         VOL_vol_testvar[a] = 0;
         VOL_vol_spread[a] = 0;
         VOL_vol_stoplossfactor[a] = 0;
         
         VOL_vol_tp[a] = 0;
         VOL_vol_sl[a] = 0;
         VOL_vol_prize[a] = 0;
         VOL_vol_ratio_spread[a] = 0;
         VOL_vol_ratio_slfactor[a] = 0;
         
         VOL_vol_highpoint[a] = 0;
         VOL_vol_highhit[a] = 0;
         VOL_vol_hightppoint[a] = 0;
         VOL_vol_hightphit[a] = 0;
         VOL_vol_highslpoint[a] = 0;
         VOL_vol_highslhit[a] = 0;
         VOL_vol_highmaxpriorsl[a] = 0;
         VOL_vol_highwinner[a] = 0;
         
         VOL_vol_lowpoint[a] = 0;
         VOL_vol_lowhit[a] = 0;
         VOL_vol_lowtppoint[a] = 0;
         VOL_vol_lowtphit[a] = 0;
         VOL_vol_lowslpoint[a] = 0;
         VOL_vol_lowslhit[a] = 0;
         VOL_vol_lowmaxpriorsl[a] = 0;
         VOL_vol_lowwinner[a] = 0;         
   }
   function_end();
}

void volatility_createvolarray(int FUNCGET_bar = 1){
   function_start("volatility_createvolarray", true);
   
   int
      FUNCVAR_currencycounter,
      FUNCVAR_barnumberloop
      ;
   
   for(FUNCVAR_currencycounter=0;FUNCVAR_currencycounter<CURRENCY_selected_numberofpairs;FUNCVAR_currencycounter++){

      VOL_vol_pair[FUNCVAR_currencycounter] = CURRENCY_selected_pairs[FUNCVAR_currencycounter];
      
      VOL_vol_bar[FUNCVAR_currencycounter] = FUNCGET_bar;
      
      VOL_vol_spread[FUNCVAR_currencycounter] = getinfo(502, VOL_vol_pair[FUNCVAR_currencycounter], VOLCONST_vol_timeframe, FUNCGET_bar + 1);
      //VOL_vol_spread[FUNCVAR_currencycounter] = 1.5 * getinfo(502, VOL_vol_pair[FUNCVAR_currencycounter], VOLCONST_vol_timeframe, FUNCGET_bar + 1);
      //VOL_vol_spread[FUNCVAR_currencycounter] = 0.00012;
      
      VOL_vol_stoplossfactor[FUNCVAR_currencycounter] = getinfo(503, VOL_vol_pair[FUNCVAR_currencycounter], VOLCONST_vol_timeframe, FUNCGET_bar + 1);
      if(VOL_vol_stoplossfactor[FUNCVAR_currencycounter] <= VOL_vol_spread[FUNCVAR_currencycounter]){
         VOL_vol_stoplossfactor[FUNCVAR_currencycounter] = VOL_vol_spread[FUNCVAR_currencycounter] * 3;
      }

      VOL_vol_sl[FUNCVAR_currencycounter] = (-1.0) * (VOL_vol_stoplossfactor[FUNCVAR_currencycounter]);
      VOL_vol_tp[FUNCVAR_currencycounter] = (20.0) * MathAbs(VOL_vol_sl[FUNCVAR_currencycounter]);

      if(VOL_vol_sl[FUNCVAR_currencycounter] != 0){
         VOL_vol_prize[FUNCVAR_currencycounter] = MathAbs(VOL_vol_tp[FUNCVAR_currencycounter]) / MathAbs(VOL_vol_sl[FUNCVAR_currencycounter]);
      }
      VOL_vol_ratio_spread[FUNCVAR_currencycounter] = MathAbs(VOL_vol_sl[FUNCVAR_currencycounter]) / VOL_vol_spread[FUNCVAR_currencycounter];
      VOL_vol_ratio_slfactor[FUNCVAR_currencycounter] = MathAbs(VOL_vol_sl[FUNCVAR_currencycounter]) / VOL_vol_stoplossfactor[FUNCVAR_currencycounter];
      
   }
      
   function_end();
}

void volatility_testvolarray(){
   function_start("volatility_testvolarray", true);
   
   int
      FUNCVAR_currencycounter,
      FUNCVAR_targetscounter,
      FUNCVAR_spreadcounter,
      FUNCVAR_sidecounter,
      FUNCVAR_barnumberloop
      ;

   
   double
      FUNCVAR_entry,
      FUNCVAR_spread,
      FUNCVAR_distancefrombreak,
      FUNCVAR_target,      
      FUNCVAR_takeprofittarget,
      FUNCVAR_stoplosstarget,
      FUNCVAR_stopfactor,
      FUNCVAR_expectedreturn,
      FUNCVAR_loss
      ;
      
   int
      FUNCVAR_minibar,
      FUNCVAR_counter,
      FUNCVAR_entryhit,
      FUNCVAR_tphit,
      FUNCVAR_slhit,
      FUNCVAR_thisresult,
      FUNCVAR_winners,
      FUNCVAR_losers,
      FUNCVAR_cases
      ;
 
   for(int a=0;a<100;a++){
      if(StringLen(VOL_vol_pair[a]) > 2 ){
    
         VOL_vol_highpoint[a] = getinfo(2, VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a] + 1);
         VOL_vol_hightppoint[a] = VOL_vol_highpoint[a] + VOL_vol_tp[a];
         VOL_vol_highslpoint[a] = VOL_vol_highpoint[a] + VOL_vol_sl[a];  

         VOL_vol_lowpoint[a] = getinfo(3, VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a] + 1);
         VOL_vol_lowtppoint[a] = VOL_vol_lowpoint[a] - VOL_vol_tp[a];
         VOL_vol_lowslpoint[a] = VOL_vol_lowpoint[a] - VOL_vol_sl[a];
   
            FUNCVAR_minibar = iBarShift(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, getinfo(5, VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a]));
            VOL_vol_highhit[a] = 0;
            VOL_vol_hightphit[a] = 1000000000000000;
            VOL_vol_highslhit[a] = 1000000000000000;
            FUNCVAR_counter = 0;
            FUNCVAR_loss = -1;
            
            if(FUNCVAR_minibar > 0 && (VOL_vol_ratio_spread[a] >= VOLCONST_vol_minsprdrto && VOL_vol_ratio_slfactor[a] >= VOLCONST_vol_minslrto)){
               //Find where entry would be made
               while(FUNCVAR_minibar - FUNCVAR_counter > 0 && FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) - 1 && VOL_vol_highhit[a] == 0){
                  if(
                     VOL_vol_highpoint[a] <= getinfo(2, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) &&
                     VOL_vol_highpoint[a] >= getinfo(3, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)
                  ){
                     VOL_vol_highhit[a] = iTime(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter);
                  }
                  FUNCVAR_counter++;
               }
               
               
               
               while(
                  FUNCVAR_minibar - FUNCVAR_counter > 0 && 
                  FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) * 40 && 
                  VOL_vol_highhit[a] > 0 && //
                  TimeDayOfWeek(iTime(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)) >= TimeDayOfWeek(iTime(VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a])) //Finish searching at end of week
               ){
                  if(
                     VOL_vol_hightppoint[a] <= getinfo(2, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - VOL_vol_spread[a]
                  ){
                     VOL_vol_hightphit[a] = MathMin(iTime(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), VOL_vol_hightphit[a]);
                  }
            
                  if(
                     VOL_vol_highslpoint[a] >= getinfo(3, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) + VOL_vol_spread[a]
                  ){
                     VOL_vol_highslhit[a] = MathMin(iTime(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), VOL_vol_highslhit[a]);
                  }
                  if(VOL_vol_hightphit[a] == 1000000000000000 && VOL_vol_highslhit[a] == 1000000000000000){
                     VOL_vol_highmaxpriorsl[a] = MathMax(VOL_vol_highmaxpriorsl[a], (getinfo(2, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - VOL_vol_highpoint[a] - VOL_vol_spread[a])/MathAbs(VOL_vol_sl[a]));
                     if(VOL_vol_highmaxpriorsl[a] > 15){
                        VOL_vol_highslpoint[a] = VOL_vol_highpoint[a] + MathAbs(VOL_vol_sl[a])*5;
                        FUNCVAR_loss = 5;
                     }else if(VOL_vol_highmaxpriorsl[a] > 10){
                        VOL_vol_highslpoint[a] = VOL_vol_highpoint[a] + MathAbs(VOL_vol_sl[a])*2.5;
                        FUNCVAR_loss = 2.5;
                     }else if(VOL_vol_highmaxpriorsl[a] > 5){
                        VOL_vol_highslpoint[a] = VOL_vol_highpoint[a] + MathAbs(VOL_vol_sl[a]);
                        FUNCVAR_loss = 1;
                     }else if(VOL_vol_highmaxpriorsl[a] > 0){
                        VOL_vol_highslpoint[a] = VOL_vol_highpoint[a];
                        FUNCVAR_loss = 0;
                     }
                  }
                  FUNCVAR_counter++;
               }
            }
   
            if(VOL_vol_hightphit[a] < VOL_vol_highslhit[a] && VOL_vol_highhit[a] > 0){
               VOL_vol_highwinner[a] = VOL_vol_prize[a];
            }else if(VOL_vol_hightphit[a] > VOL_vol_highslhit[a] && VOL_vol_highhit[a] > 0){
               VOL_vol_highwinner[a] = FUNCVAR_loss;
            }else if(VOL_vol_highhit[a] > 0){
               VOL_vol_highwinner[a] = 0;
            }
   
            FUNCVAR_minibar = iBarShift(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, getinfo(5, VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a]));
            VOL_vol_lowhit[a] = 0;
            VOL_vol_lowtphit[a] = 1000000000000000;
            VOL_vol_lowslhit[a] = 1000000000000000;
            FUNCVAR_counter = 0;
            FUNCVAR_loss = -1;
            
            if(FUNCVAR_minibar > 0 && (VOL_vol_ratio_spread[a] >= VOLCONST_vol_minsprdrto && VOL_vol_ratio_slfactor[a] >= VOLCONST_vol_minslrto)){
               //Find where entry would be made
               while(FUNCVAR_minibar - FUNCVAR_counter > 0 && FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) - 1 && VOL_vol_lowhit[a] == 0){
                  if(
                     VOL_vol_lowpoint[a] <= getinfo(2, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) &&
                     VOL_vol_lowpoint[a] >= getinfo(3, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)
                  ){
                     VOL_vol_lowhit[a] = iTime(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter);
                  }
                  FUNCVAR_counter++;
               }
         
               while(
                  FUNCVAR_minibar - FUNCVAR_counter > 0 && 
                  FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) * 40 && 
                  VOL_vol_lowhit[a] > 0 &&
                  TimeDayOfWeek(iTime(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)) >= TimeDayOfWeek(iTime(VOL_vol_pair[a], VOLCONST_vol_timeframe, VOL_vol_bar[a])) //Finish searching at end of week              
               ){
                  if(
                     VOL_vol_lowtppoint[a] >= getinfo(3, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - VOL_vol_spread[a]
                  ){
                     VOL_vol_lowtphit[a] = MathMin(iTime(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), VOL_vol_lowtphit[a]);
                  }
            
                  if(
                     VOL_vol_lowslpoint[a] <= getinfo(2, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) + VOL_vol_spread[a]
                  ){
                     VOL_vol_lowslhit[a] = MathMin(iTime(VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), VOL_vol_lowslhit[a]);
                  }
                  if(VOL_vol_lowtphit[a] == 1000000000000000 && VOL_vol_lowslhit[a] == 1000000000000000){
                     VOL_vol_lowmaxpriorsl[a] = MathMax(VOL_vol_lowmaxpriorsl[a], (VOL_vol_lowpoint[a] - getinfo(2, VOL_vol_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - VOL_vol_spread[a])/VOL_vol_sl[a]);
                     if(VOL_vol_lowmaxpriorsl[a] > 15){
                        VOL_vol_lowslpoint[a] = VOL_vol_lowpoint[a] - MathAbs(VOL_vol_sl[a])*3;
                        FUNCVAR_loss = 3;
                     }else if(VOL_vol_lowmaxpriorsl[a] > 10){
                        VOL_vol_lowslpoint[a] = VOL_vol_lowpoint[a] - MathAbs(VOL_vol_sl[a])*2.5;
                        FUNCVAR_loss = 2.5;
                     }else if(VOL_vol_lowmaxpriorsl[a] > 5){
                        VOL_vol_lowslpoint[a] = VOL_vol_lowpoint[a] - MathAbs(VOL_vol_sl[a]);
                        FUNCVAR_loss = 1;
                     }else if(VOL_vol_lowmaxpriorsl[a] > 0){
                        VOL_vol_lowslpoint[a] = VOL_vol_lowpoint[a];
                        FUNCVAR_loss = 0;
                     }
                  }
                  FUNCVAR_counter++;
               }
            }
   
            if(VOL_vol_lowtphit[a] < VOL_vol_lowslhit[a] && VOL_vol_lowhit[a] > 0){
               VOL_vol_lowwinner[a] = VOL_vol_prize[a];
            }else if(VOL_vol_lowtphit[a] > VOL_vol_lowslhit[a] && VOL_vol_lowhit[a] > 0){
               VOL_vol_lowwinner[a] = FUNCVAR_loss;
            }else if(VOL_vol_lowhit[a] > 0){
               VOL_vol_lowwinner[a] = 0;
            }
         //}
      }
   }
      
   function_end();
}

string volatility_removezero(double FUNCGET_number){
   if(FUNCGET_number != 0){
      return(FUNCGET_number);
   }else{
      return("");
   }
}




//+------------------------------------------------------------------+
//| END volatility class                                             |
//+------------------------------------------------------------------+


