//+------------------------------------------------------------------+
//|                                            hour break v0 102.mq4 |
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

#define PROGRAM_VERSION "hour break v0 102"

#define MINUTE 1
#define HOUR 60
#define DAY 1440
#define WEEK 10080
#define MONTH 43800
#define YEAR 525600

extern bool    GLOBAL_runtests               = true;           //This fires the testing class which stops the EA after initialisation
extern bool    GLOBAL_debug                  = false;          //Increases the amount of data written to the log for debugging purposes.
extern bool    GLOBAL_resetfiles             = true;           //Deletes and resets output files. Only for development.
extern bool    GLOBAL_runcron                = true;           //This setting turns off the cron update tasks. (ONLY runs init tasks)
extern bool    GLOBAL_jumpstart              = false;          //This setting runs all cron tasks to begin with as opposed to waiting
extern double  GLOBAL_riskpertradepercentage = 0.005;          //The percentage of the account to risk per trade.
extern int     GLOBAL_pausetime              = 1000;           //In milliseconds. Time to wait before polling server after bad response.
extern bool    GLOBAL_sendnotifications      = false;          //Whether to send notifications or not.

extern bool    CURRENCY_USD                  = true;
extern bool    CURRENCY_CHF                  = false;
extern bool    CURRENCY_EUR                  = true;
extern bool    CURRENCY_GBP                  = false;
extern bool    CURRENCY_CAD                  = false;
extern bool    CURRENCY_JPY                  = false;
extern bool    CURRENCY_AUD                  = false;
extern bool    CURRENCY_NZD                  = false;
extern bool    CURRENCY_SGD                  = false;
extern bool    CURRENCY_HKD                  = false;
extern bool    CURRENCY_DKK                  = false;
extern bool    CURRENCY_NOK                  = false;
extern bool    CURRENCY_SEK                  = false;
extern bool    CURRENCY_TRY                  = false;
extern bool    CURRENCY_PLN                  = false;
extern bool    CURRENCY_MXN                  = false;
extern bool    CURRENCY_XAU                  = false;
extern bool    CURRENCY_XAG                  = false;
extern string  CURRENCY_skippairs            = ";AUDJPY;EURAUD;GBPAUD;GBPJPY;USDJPY;EURGBP"; //= "CHFSGD; EURSGD; EURDKK; EURNOK; EURSEK; USDTRY; EURTRY; GBPSGD; GBPSEK; GBPNOK; GBPDKK; GBPTRY; CADSGD; CADSEK; CADNOK; CADDKK; CADTRY; AUDSGD; NZDCHF; NZDSGD; NZDCAD; NOKJPY; HKDJPY; NOKSEK; SEKJPY";

/*
Entry Rules.

SL for both is MODE_STOPLEVEL or MODE_SPREAD x 3 if no MODE_STOPLEVEL
TP is SL x 20

BUY_STOP at the high of the previous hour + SL distance (looking for continuation)
BUY_LIMIT at the low of the previous hour - SL distance (looking for reversal)

Once trade profit reaches  1+ve SL value, SL is bought to equal entry giving a risk free trade.
Once trade profit reaches  5+ve SL value, SL is bought to 1.0+ve SL giving a 100% return on original risk.
Once trade profit reaches 10+ve SL value, SL is bought to 2.5+ve SL giving a 250% return on original risk.
Once trade profit reaches 15+ve SL value, SL is bought to 5.0+ve SL giving a 500% return on original risk.

Only trade between hours of 0800 and 2000 inclusive.

Close all positions before close of markets on a Friday to avoid Monday morning differential.

Appearing to work best with
AUDUSD
EURJPY
EURUSD
GBPUSD

Testing over last 4 months (20120606 to 20121002) with current spreads (which can throw everything out IMMENSELY!)

Straight    @ 2.00% risk per trade gives a 57% DD and 30x return
Straight    @ 1.00% risk per trade gives a 45% DD and 15x return

Compounding @ 1.00% risk per trade gives a 64% DD and 28,000x return
Compounding @ 1.00% risk per trade gives a 91% DD and 1,000,000,000x return with current spread x 1.5
Compounding @ 0.50% risk per trade gives a 40% DD and 437x return
Compounding @ 0.20% risk per trade gives a 18% DD and 14x return
Compounding @ 0.10% risk per trade gives a  8% DD and 4x return
Compounding @ 0.10% risk per trade gives a 18% DD and 18x return with current spread x 1.5

As can be seen, massive differences due to spreads and outcomes. What can be said is that the report always comes back positive.

Current issues which are/can/may effect performance of this strategy.

   Currently looking at 1 minute bars to decipher winners. There could be the case where many entries are stopped out as due to dynamic spreads, stops may be hit more often than is testable in MT
      Have added a system which tries to counteract this issue as best possible.
   Moving to a BUYSTOP and BUYLIMIT setup as currently SELLSTOPs on the prev low are losing pretty constantly.
   Need to add a routine for SendOrder so that it can handle errors or if the STOP/LIMIT is too close to the market. (These cases are good entries)
   
v0 103
Currently testing on a pro account while forward testing on a micro account. MODE_SPREAD mostly equals MODE_STOPLEVEL which is stopping out almost all trades. 
Moving to a x 3 setup for testing (should find a micro testing server later) and finding that EURUSD works on this setup. 
Going to forward test using MODE_SPREAD x 3 instead of MODE_STOPLEVEL with just EURUSD

*/

int         GLOBAL_timeframe;
int         GLOBAL_cronincrement;
int         GLOBAL_refreshrate;
double      GLOBAL_riskpertradeamount;

//+------------------------------------------------------------------+
//| initialization function                                          |
//+------------------------------------------------------------------+
int init(){  
   Alert(PROGRAM_VERSION + " started.");
   Alert("Initalising log");
   log(); //Initialise the log file so dependant functions can work  
   Alert("Starting init function processing");
   function_start("init", true);

   log(PROGRAM_VERSION + " started.");
   log("GLOBAL_pausetime: "+GLOBAL_pausetime);
   log("GLOBAL_debug: "+GLOBAL_debug);
   log("GLOBAL_resetfiles: "+GLOBAL_resetfiles);
   log("GLOBAL_runcron: "+GLOBAL_runcron);
   log("GLOBAL_jumpstart: "+GLOBAL_jumpstart);
   log("GLOBAL_riskpertradepercentage: "+GLOBAL_riskpertradepercentage);
   log("GLOBAL_sendnotifications: "+GLOBAL_sendnotifications);
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
     
   GLOBAL_timeframe              = HOUR;              //In Minutes. The timeframe to cycle orders.
   GLOBAL_cronincrement          = 15;                //In Minutes. What time frame to run the smallest cron task
   GLOBAL_refreshrate            = 1;                 //In Seconds. How often to refresh rates
   
   account_init();  
   cron_init();
   currency_init();

   if(GLOBAL_runtests == true){
      testing_runtests();
   }
   
   Alert("Initalised");
    
   function_end();
   return(0);
}

int deinit(){
   ObjectsDeleteAll();
   Alert("Uninitalised EA");
}

//+------------------------------------------------------------------+
//| start function                                                   |
//+------------------------------------------------------------------+
int start(){
   
   int FUNCVAR_time;

   if(GLOBAL_runcron == true){
      //while(1==1){
         //if(TimeCurrent() >= FUNCVAR_time + GLOBAL_refreshrate){
            //FUNCVAR_time = TimeCurrent();
            //RefreshRates();
            account_updatestops();
            cron_update();
         //}
      //}
   }
   return(0);
}


//+------------------------------------------------------------------+
//| CRON class                                                       |
//+------------------------------------------------------------------+

int         CRON_VAR_currentweek;
int         CRON_VAR_currentday;
int         CRON_VAR_currenthour;
int         CRON_VAR_currenttimeframe;
int         CRON_VAR_currentincrement;
int         CRON_VAR_weekcrontime;
int         CRON_VAR_daycrontime;
int         CRON_VAR_hourcrontime;
int         CRON_VAR_timeframecrontime;
int         CRON_VAR_incrementcrontime;
bool        CRON_VAR_weekended;
bool        CRON_VAR_dayended;
bool        CRON_VAR_hourended;
bool        CRON_VAR_timeframeended;
bool        CRON_VAR_incrementended;

void cron_init(){

   CRON_VAR_weekcrontime             = 1.0 * HOUR * 60;
   CRON_VAR_daycrontime              = 3.0 * MINUTE * 60;
   CRON_VAR_hourcrontime             = 2.0 * MINUTE * 60;
   CRON_VAR_timeframecrontime        = 1.0 * MINUTE * 60;
   CRON_VAR_incrementcrontime        = 0.2 * MINUTE * 60;
   
   if(GLOBAL_jumpstart == true){
      CRON_VAR_currentweek              = 0;
      CRON_VAR_currentday               = 0;
      CRON_VAR_currenthour              = 0;
      CRON_VAR_currenttimeframe         = 0;
      CRON_VAR_currentincrement         = 0;
      CRON_VAR_weekended                = FALSE;
      CRON_VAR_dayended                 = FALSE;
      CRON_VAR_hourended                = FALSE;
      CRON_VAR_timeframeended           = FALSE;
      CRON_VAR_incrementended           = FALSE;
   }else{
      CRON_VAR_currentweek              = iTime(Symbol(), PERIOD_W1, 0);
      CRON_VAR_currentday               = iTime(Symbol(), PERIOD_D1, 0);
      CRON_VAR_currenthour              = iTime(Symbol(), PERIOD_H1, 0);
      CRON_VAR_currenttimeframe         = iTime(Symbol(), GLOBAL_timeframe, 0);
      CRON_VAR_currentincrement         = iTime(Symbol(), GLOBAL_cronincrement, 0);
      CRON_VAR_weekended                = TRUE;
      CRON_VAR_dayended                 = TRUE;
      CRON_VAR_hourended                = TRUE;
      CRON_VAR_timeframeended           = TRUE;
      CRON_VAR_incrementended           = TRUE;
   }

}

void cron_update(){
   function_start("cron_update", true);
   
   //Week
   if(
      iTime(Symbol(), PERIOD_W1, 0) * 2 - iTime(Symbol(), PERIOD_W1, 1) - TimeCurrent() < CRON_VAR_weekcrontime &&
      CRON_VAR_weekended == FALSE
   ){
      cron_endweek();
   }
   
   if(CRON_VAR_currentweek != iTime(Symbol(), PERIOD_W1, 0)){
      if(CRON_VAR_weekcrontime == FALSE){
         cron_endweek();
      }
      cron_newweek();
      CRON_VAR_currentweek = iTime(Symbol(), PERIOD_W1, 0);
   }
   
   //Day
   if(
      iTime(Symbol(), PERIOD_D1, 0) * 2 - iTime(Symbol(), PERIOD_D1, 1) - TimeCurrent() < CRON_VAR_daycrontime &&
      CRON_VAR_dayended == FALSE
   ){
      cron_endday();
   }
   
   if(CRON_VAR_currentday != iTime(Symbol(), PERIOD_D1, 0)){
      if(CRON_VAR_dayended == FALSE){
         cron_endday();
      }
      cron_newday();
      CRON_VAR_currentday = iTime(Symbol(), PERIOD_D1, 0);
   }
   
   //Hour
   if(
      iTime(Symbol(), PERIOD_H1, 0) * 2 - iTime(Symbol(), PERIOD_H1, 1) - TimeCurrent() < CRON_VAR_hourcrontime &&
      CRON_VAR_hourended == FALSE
   ){
      cron_endhour();
   }
   
   if(CRON_VAR_currenthour != iTime(Symbol(), PERIOD_H1, 0)){
      if(CRON_VAR_hourended == FALSE){
         cron_endhour();
      }
      cron_newhour();
      CRON_VAR_currenthour = iTime(Symbol(), PERIOD_H1, 0);
   }
      
   //Timeframe
   if(
      iTime(Symbol(), GLOBAL_timeframe, 0) * 2 - iTime(Symbol(), GLOBAL_timeframe, 1) - TimeCurrent() < CRON_VAR_timeframeended &&
      CRON_VAR_timeframeended == FALSE
   ){
      cron_endtimeframe();
   }
   
   if(CRON_VAR_currenttimeframe != iTime(Symbol(), GLOBAL_timeframe, 0)){
      if(CRON_VAR_timeframeended == FALSE){
         cron_endtimeframe();
      }
      cron_newtimeframe();
      CRON_VAR_currenttimeframe = iTime(Symbol(), GLOBAL_timeframe, 0);
   }

   //Increment
   if(
      iTime(Symbol(), GLOBAL_cronincrement, 0) * 2 - iTime(Symbol(), GLOBAL_cronincrement, 1) - TimeCurrent() < CRON_VAR_incrementcrontime &&
      CRON_VAR_incrementended == FALSE
   ){
      cron_endincrement();
   }
   
   if(CRON_VAR_currentincrement != iTime(Symbol(), GLOBAL_cronincrement, 0)){
      if(CRON_VAR_incrementended == FALSE){
         cron_endincrement();
      }
      cron_newincrement();
      CRON_VAR_currentincrement = iTime(Symbol(), GLOBAL_cronincrement, 0);
   }

   function_end();
}


void cron_endweek(){
   function_start("cron_endweek", true);

   log("Ending Week");
   //v---------------------


   //^---------------------     
   CRON_VAR_weekended = TRUE;
   function_end();
}

void cron_newweek(){
   function_start("cron_newweek", true);
   
   log("Starting Week");
   //v---------------------
   
   
   //^---------------------
   CRON_VAR_weekended = FALSE;
   function_end();   
}

void cron_endday(){
   function_start("cron_endday", true);
   
   log("Ending Day");
   //v---------------------
   
   
   //^---------------------
   CRON_VAR_dayended = TRUE;
   function_end();
}

void cron_newday(){
   function_start("cron_newday", true);
   
   log("Starting Day");
   //v---------------------
   
   
   
   //^---------------------
   CRON_VAR_dayended = FALSE;
   function_end();
}

void cron_endhour(){
   function_start("cron_endhour", true);
   
   log("Ending Hour");
   //v---------------------
   
   
   
   //^---------------------
   CRON_VAR_hourended = TRUE;
   function_end();
}

void cron_newhour(){
   function_start("cron_newhour", true);

   log("Starting Hour");
   //v---------------------

   if(
      TimeHour(TimeCurrent()) >= 8 &&
      TimeHour(TimeCurrent()) <= 22
   ){
      account_createorders();
   }else{
      log("Skipping orders this hour");
   }
   account_update();
   
   //^---------------------
   CRON_VAR_hourended = FALSE;
   function_end();
}

void cron_endtimeframe(){
   function_start("cron_endtimeframe", true);
   
   log("Ending Timeframe");
   //v---------------------


   
   //^---------------------
   CRON_VAR_timeframeended = TRUE;
   function_end();
}

void cron_newtimeframe(){
   function_start("cron_newtimeframe", true);

   log("Starting Timeframe");
   //v---------------------


   
   //^---------------------
   CRON_VAR_timeframeended = FALSE;
   function_end();
}

void cron_endincrement(){
   function_start("cron_endincrement", true);
   
   log("Ending Increment");
   //v---------------------
   

   //^---------------------
   CRON_VAR_incrementended = TRUE;
   
   function_end();
}

void cron_newincrement(){
   function_start("cron_newincrement", true);
   
   log("Starting Increment");
   //v---------------------
   
   
   //^---------------------
   CRON_VAR_incrementended = FALSE;
   function_end();      
}




//+------------------------------------------------------------------+
//| function tracking class                                          |
//+------------------------------------------------------------------+

int         FUNCTION_functionnest;
string      FUNCTION_functionname[100];
bool        FUNCTION_tracer[100];

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
//| Currency class                                                   |
//+------------------------------------------------------------------+

int         CURRENCY_all_numberofpairs;
string      CURRENCY_all_entities[100];
string      CURRENCY_all_pairs[100];

int         CURRENCY_selected_numberofpairs;
string      CURRENCY_selected_entities[100];
string      CURRENCY_selected_pairs[100];

void currency_init(){
   function_start("currency_init", true);
   
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
   //log("=SUMIF(R68C7:R3000C7,R[-1]C,R68C28:R3000C28)&\" \"&SUMIF(R68C7:R3000C7,R[-1]C,R68C35:R3000C35)&\" \"&SUMIF(R68C7:R3000C7,R[-1]C,R68C28:R3000C28)+SUMIF(R68C7:R3000C7,R[-1]C,R68C35:R3000C35)");
   
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

//+------------------------------------------------------------------+
//| testing class                                                    |
//+------------------------------------------------------------------+

//vard - variable definitions

string   TESTING_VAR_pair[100];
int      TESTING_VAR_bar[100];
double   TESTING_VAR_testvar1[100];
double   TESTING_VAR_testvar2[100];
double   TESTING_VAR_spread[100];
double   TESTING_VAR_stoplossfactor[100];

double   TESTING_VAR_tp[100];
double   TESTING_VAR_sl[100];
double   TESTING_VAR_prize[100];
double   TESTING_VAR_ratio_spread[100];
double   TESTING_VAR_ratio_slfactor[100];

double   TESTING_VAR_highpoint[100];
double   TESTING_VAR_highhit[100];
double   TESTING_VAR_hightppoint[100];
double   TESTING_VAR_hightphit[100];
double   TESTING_VAR_highslpoint[100];
double   TESTING_VAR_highslhit[100];
double   TESTING_VAR_highmaxpriorsl[100];
double   TESTING_VAR_highwinner[100];
double   TESTING_VAR_lowpoint[100];
double   TESTING_VAR_lowhit[100];
double   TESTING_VAR_lowtppoint[100];
double   TESTING_VAR_lowtphit[100];
double   TESTING_VAR_lowslpoint[100];
double   TESTING_VAR_lowslhit[100];
double   TESTING_VAR_lowmaxpriorsl[100];
double   TESTING_VAR_lowwinner[100];

int      VOLCONST_vol_timeframe = HOUR;
int      VOLCONST_vol_minitimeframe = 1;
int      VOLCONST_vol_lookback = 5;
int      VOLCONST_vol_targetfactor = 10; //size of tp compared to sl
int      VOLCONST_vol_slfactor = 5; //size of sl compared to slratio
double   VOLCONST_vol_targetsize = 1; //percentage of the average break to aim for.
double   VOLCONST_vol_minsprdrto = 1;
double   VOLCONST_vol_minslrto = 1;

void testing_logarray(int FUNCGET_instance = 1){
   function_start("testing_logarray", true);
   for(int a=0;a<100;a++){
      if(
         StringLen(TESTING_VAR_pair[a]) > 2 &&
         TimeHour(iTime(TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a])) >= 8 &&
         TimeHour(iTime(TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a])) <= 20 
      ){
         log(
         humandate(iTime(TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a]))+";"+
         iTime(TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a])+";"+
         TESTING_VAR_pair[a]+";"+
         //TESTING_VAR_testvar1[a]+";"+
         "=SUMIF(R1C6:R50000C6,RC6,R1C23:R50000C23)"+";"+
         //TESTING_VAR_testvar2[a]+";"+
         "=SUMIF(R1C6:R50000C6,RC6,R1C31:R50000C31)"+";"+
         TESTING_VAR_spread[a]+";"+
         TESTING_VAR_stoplossfactor[a]+";"+
           
         TESTING_VAR_tp[a]+";"+
         TESTING_VAR_sl[a]+";"+
         TESTING_VAR_prize[a]+";"+
         TESTING_VAR_ratio_spread[a]+";"+
         TESTING_VAR_ratio_slfactor[a]+";"+
                
         TESTING_VAR_highpoint[a]+";"+
         humandate(TESTING_VAR_highhit[a])+";"+
         //TESTING_VAR_highhit[a]+";"+
         TESTING_VAR_hightppoint[a]+";"+
         humandate(TESTING_VAR_hightphit[a])+";"+
         TESTING_VAR_highslpoint[a]+";"+
         humandate(TESTING_VAR_highslhit[a])+";"+
         TESTING_VAR_highmaxpriorsl[a]+";"+
         testing_removezero(TESTING_VAR_highwinner[a])+";"+
         
         TESTING_VAR_lowpoint[a]+";"+
         humandate(TESTING_VAR_lowhit[a])+";"+
         //TESTING_VAR_lowhit[a]+";"+
         TESTING_VAR_lowtppoint[a]+";"+
         humandate(TESTING_VAR_lowtphit[a])+";"+
         TESTING_VAR_lowslpoint[a]+";"+
         humandate(TESTING_VAR_lowslhit[a])+";"+
         TESTING_VAR_lowmaxpriorsl[a]+";"+
         testing_removezero(TESTING_VAR_lowwinner[a])+";"+
         "=IF(RC5<>R[-1]C5,SUMIF(R1C5:R50000C5,RC5,R1C23:R50000C23)+SUMIF(R1C5:R50000C5,RC5,R1C31:R50000C31),\"\")"+";"+
         "=IF(RC[-1]<>\"\",R[-1]C+R[-1]C*RC[-1]*0.001,R[-1]C)"+";"+
         "=MAX(R[-1]C,RC[-1])"+";"+
         "=RC[-2]/RC[-1]"+";"+
         "");
         
         if(TESTING_VAR_pair[a] == Symbol()){
            ObjectCreate("hline-"+FUNCGET_instance+a+"entry", OBJ_RECTANGLE, 0, 
               iTime(Symbol(),VOLCONST_vol_timeframe, TESTING_VAR_bar[a] - 1), 
               TESTING_VAR_highpoint[a], 
               iTime(Symbol(),VOLCONST_vol_timeframe, TESTING_VAR_bar[a]), 
               TESTING_VAR_lowpoint[a]
            );
            ObjectSet("hline-"+FUNCGET_instance+a+"entry", OBJPROP_COLOR, Yellow);
            ObjectSet("hline-"+FUNCGET_instance+a+"entry", OBJPROP_STYLE, 0);
            ObjectSet("hline-"+FUNCGET_instance+a+"entry", OBJPROP_WIDTH, 1);
            ObjectSet("hline-"+FUNCGET_instance+a+"entry", OBJPROP_BACK, 0);
         
            ObjectCreate("hline-"+FUNCGET_instance+a+"sl", OBJ_RECTANGLE, 0, 
               iTime(Symbol(),VOLCONST_vol_timeframe, TESTING_VAR_bar[a] - 1), 
               TESTING_VAR_highslpoint[a], 
               iTime(Symbol(),VOLCONST_vol_timeframe, TESTING_VAR_bar[a]), 
               TESTING_VAR_lowslpoint[a]
            );
            ObjectSet("hline-"+FUNCGET_instance+a+"sl", OBJPROP_COLOR, Red);
            ObjectSet("hline-"+FUNCGET_instance+a+"sl", OBJPROP_STYLE, 0);
            ObjectSet("hline-"+FUNCGET_instance+a+"sl", OBJPROP_WIDTH, 1);
            ObjectSet("hline-"+FUNCGET_instance+a+"sl", OBJPROP_BACK, 0);
            
            ObjectCreate("hline-"+FUNCGET_instance+a+"tp", OBJ_RECTANGLE, 0, 
               iTime(Symbol(),VOLCONST_vol_timeframe, TESTING_VAR_bar[a] - 1), 
               TESTING_VAR_hightppoint[a], 
               iTime(Symbol(),VOLCONST_vol_timeframe, TESTING_VAR_bar[a]), 
               TESTING_VAR_lowtppoint[a]
            );
            ObjectSet("hline-"+FUNCGET_instance+a+"tp", OBJPROP_COLOR, Green);
            ObjectSet("hline-"+FUNCGET_instance+a+"tp", OBJPROP_STYLE, 0);
            ObjectSet("hline-"+FUNCGET_instance+a+"tp", OBJPROP_WIDTH, 1);
            ObjectSet("hline-"+FUNCGET_instance+a+"tp", OBJPROP_BACK, 0);
            
            ObjectCreate("heading-"+FUNCGET_instance+a+"high", OBJ_TEXT, 0, iTime(Symbol(),VOLCONST_vol_timeframe, TESTING_VAR_bar[a]), TESTING_VAR_highpoint[a]);
            ObjectSetText("heading-"+FUNCGET_instance+a+"high", "               "+TESTING_VAR_highwinner[a], 9, "Courier New", White);
            ObjectCreate("heading-"+FUNCGET_instance+a+"low", OBJ_TEXT, 0, iTime(Symbol(),VOLCONST_vol_timeframe, TESTING_VAR_bar[a]), TESTING_VAR_lowpoint[a]);
            ObjectSetText("heading-"+FUNCGET_instance+a+"low", "               "+TESTING_VAR_lowwinner[a], 9, "Courier New", White);
         }
      }
   }
   function_end();
}

void testing_cleararray(){
   function_start("testing_cleararray", true);
   for(int a=0;a<100;a++){
         TESTING_VAR_pair[a] = "";
         TESTING_VAR_bar[a] = 0;
         TESTING_VAR_testvar1[a] = 0;
         TESTING_VAR_testvar2[a] = 0;
         TESTING_VAR_spread[a] = 0;
         TESTING_VAR_stoplossfactor[a] = 0;
         
         TESTING_VAR_tp[a] = 0;
         TESTING_VAR_sl[a] = 0;
         TESTING_VAR_prize[a] = 0;
         TESTING_VAR_ratio_spread[a] = 0;
         TESTING_VAR_ratio_slfactor[a] = 0;
         
         TESTING_VAR_highpoint[a] = 0;
         TESTING_VAR_highhit[a] = 0;
         TESTING_VAR_hightppoint[a] = 0;
         TESTING_VAR_hightphit[a] = 0;
         TESTING_VAR_highslpoint[a] = 0;
         TESTING_VAR_highslhit[a] = 0;
         TESTING_VAR_highmaxpriorsl[a] = 0;
         TESTING_VAR_highwinner[a] = 0;
         
         TESTING_VAR_lowpoint[a] = 0;
         TESTING_VAR_lowhit[a] = 0;
         TESTING_VAR_lowtppoint[a] = 0;
         TESTING_VAR_lowtphit[a] = 0;
         TESTING_VAR_lowslpoint[a] = 0;
         TESTING_VAR_lowslhit[a] = 0;
         TESTING_VAR_lowmaxpriorsl[a] = 0;
         TESTING_VAR_lowwinner[a] = 0;         
   }
   function_end();
}

void testing_runtests(){
   function_start("testing_runtests", true);
    
   //Returns the volitility report and shuts down the EA.
      GLOBAL_runcron = false;
      log("GLOBAL_runcron set to false. *** EA will not perform cron tasks***");
      log(";;;;;Sprd;SLF;T;S;P;sprd;sl;HP;HPH;HTP;HTPH;HSL;HSLH;MH;=SUM(R[1]C:R[50000]C);LP;LPH;LTP;LTPH;LSL;LSLH;MH;=SUM(R[1]C:R[50000]C);=SUM(R[1]C:R[50000]C);1;=AVERAGE(R[1]C23:R[50000]C23,R[1]C31:R[50000]C31);=MIN(R[1]C:R[50000]C);=MAX(R[1]C[-3]:R[50000]C[-3])");
      ObjectsDeleteAll();
      for(int a=1; a<1500; a++){
         testing_createarray(a);
         testing_testarray();
         testing_logarray(a);
         testing_cleararray();
      }
      
   function_end();
}


void testing_createarray(int FUNCGET_bar = 1){
   function_start("testing_createarray", true);
   
   int
      FUNCVAR_currencycounter,
      FUNCVAR_barnumberloop
      ;
   
   for(FUNCVAR_currencycounter=0;FUNCVAR_currencycounter<CURRENCY_selected_numberofpairs;FUNCVAR_currencycounter++){

      TESTING_VAR_pair[FUNCVAR_currencycounter] = CURRENCY_selected_pairs[FUNCVAR_currencycounter];
      
      TESTING_VAR_bar[FUNCVAR_currencycounter] = FUNCGET_bar;
      
      TESTING_VAR_spread[FUNCVAR_currencycounter] = getinfo(502, TESTING_VAR_pair[FUNCVAR_currencycounter], VOLCONST_vol_timeframe, FUNCGET_bar + 1) * 3;
      //TESTING_VAR_spread[FUNCVAR_currencycounter] = 1.5 * getinfo(502, TESTING_VAR_pair[FUNCVAR_currencycounter], VOLCONST_vol_timeframe, FUNCGET_bar + 1);
      //TESTING_VAR_spread[FUNCVAR_currencycounter] = 0.00012;
      
      TESTING_VAR_stoplossfactor[FUNCVAR_currencycounter] = getinfo(503, TESTING_VAR_pair[FUNCVAR_currencycounter], VOLCONST_vol_timeframe, FUNCGET_bar + 1) * 3;
      if(TESTING_VAR_stoplossfactor[FUNCVAR_currencycounter] <= TESTING_VAR_spread[FUNCVAR_currencycounter]){
         TESTING_VAR_stoplossfactor[FUNCVAR_currencycounter] = TESTING_VAR_spread[FUNCVAR_currencycounter] * 3;
      }
         
      TESTING_VAR_sl[FUNCVAR_currencycounter] = (-1.0) * (TESTING_VAR_stoplossfactor[FUNCVAR_currencycounter]);
      TESTING_VAR_tp[FUNCVAR_currencycounter] = (20.0) * MathAbs(TESTING_VAR_sl[FUNCVAR_currencycounter]);

      if(TESTING_VAR_sl[FUNCVAR_currencycounter] != 0){
         TESTING_VAR_prize[FUNCVAR_currencycounter] = MathAbs(TESTING_VAR_tp[FUNCVAR_currencycounter]) / MathAbs(TESTING_VAR_sl[FUNCVAR_currencycounter]);
      }
      TESTING_VAR_ratio_spread[FUNCVAR_currencycounter] = MathAbs(TESTING_VAR_sl[FUNCVAR_currencycounter]) / TESTING_VAR_spread[FUNCVAR_currencycounter];
      TESTING_VAR_ratio_slfactor[FUNCVAR_currencycounter] = MathAbs(TESTING_VAR_sl[FUNCVAR_currencycounter]) / TESTING_VAR_stoplossfactor[FUNCVAR_currencycounter];
      
   }
      
   function_end();
}

void testing_testarray(){
   function_start("testing_testarray", true);
   
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
      if(StringLen(TESTING_VAR_pair[a]) > 2 ){
    
         TESTING_VAR_highpoint[a] = getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a] + 1) + MathAbs(TESTING_VAR_sl[a]) * 1/3; // 1 spread inside the bar seems best atm
         TESTING_VAR_hightppoint[a] = TESTING_VAR_highpoint[a] + TESTING_VAR_tp[a];
         TESTING_VAR_highslpoint[a] = TESTING_VAR_highpoint[a] + TESTING_VAR_sl[a];  

         TESTING_VAR_lowpoint[a] = getinfo(3, TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a] + 1) - MathAbs(TESTING_VAR_sl[a]) * 1/3; // 2 spreads outside the bar seems best atm
         TESTING_VAR_lowtppoint[a] = TESTING_VAR_lowpoint[a] + TESTING_VAR_tp[a];
         TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a] + TESTING_VAR_sl[a];
            
            FUNCVAR_minibar = iBarShift(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, getinfo(5, TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a]));
            TESTING_VAR_highhit[a] = 0;
            TESTING_VAR_hightphit[a] = 1000000000000000;
            TESTING_VAR_highslhit[a] = 1000000000000000;
            FUNCVAR_counter = 0;
            FUNCVAR_loss = -1;
            
            if(FUNCVAR_minibar > 0 && (TESTING_VAR_ratio_spread[a] >= VOLCONST_vol_minsprdrto && TESTING_VAR_ratio_slfactor[a] >= VOLCONST_vol_minslrto)){
               //Find where entry would be made
               while(FUNCVAR_minibar - FUNCVAR_counter > 0 && FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) - 1 && TESTING_VAR_highhit[a] == 0){
                  if(
                     TESTING_VAR_highpoint[a] <= getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_VAR_spread[a] &&
                     TESTING_VAR_highpoint[a] >= getinfo(3, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_VAR_spread[a]
                  ){
                     TESTING_VAR_highhit[a] = iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter);
                  }
                  FUNCVAR_counter++;
               }
               
               //Check that entry was somewhat clean, else stop out the entry
               if(
                  getinfo(4, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter + 1) < getinfo(1, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter + 1) &&
                  TESTING_VAR_highhit[a] > 0
               ){
                  TESTING_VAR_highslhit[a] = iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter);
               }
               
               while(
                  FUNCVAR_minibar - FUNCVAR_counter > 0 && 
                  FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) * 40 && 
                  TESTING_VAR_highhit[a] > 0 && //
                  TimeDayOfWeek(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)) >= TimeDayOfWeek(iTime(TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a])) //Finish searching at end of week
               ){
                  if(
                     TESTING_VAR_hightppoint[a] <= getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_VAR_spread[a]
                  ){
                     TESTING_VAR_hightphit[a] = MathMin(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_hightphit[a]);
                  }
            
                  if(
                     TESTING_VAR_highslpoint[a] >= getinfo(3, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_VAR_spread[a]
                  ){
                     TESTING_VAR_highslhit[a] = MathMin(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_highslhit[a]);
                  }
                  if(TESTING_VAR_hightphit[a] == 1000000000000000 && TESTING_VAR_highslhit[a] == 1000000000000000){
                     TESTING_VAR_highmaxpriorsl[a] = MathMax(TESTING_VAR_highmaxpriorsl[a], (getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_VAR_highpoint[a] - TESTING_VAR_spread[a])/MathAbs(TESTING_VAR_sl[a]));
                     if(TESTING_VAR_highmaxpriorsl[a] > 15){
                        TESTING_VAR_highslpoint[a] = TESTING_VAR_highpoint[a] + MathAbs(TESTING_VAR_sl[a])*5;
                        FUNCVAR_loss = 5;
                     }else if(TESTING_VAR_highmaxpriorsl[a] > 10){
                        TESTING_VAR_highslpoint[a] = TESTING_VAR_highpoint[a] + MathAbs(TESTING_VAR_sl[a])*2.5;
                        FUNCVAR_loss = 2.5;
                     }else if(TESTING_VAR_highmaxpriorsl[a] > 5){
                        TESTING_VAR_highslpoint[a] = TESTING_VAR_highpoint[a] + MathAbs(TESTING_VAR_sl[a]);
                        FUNCVAR_loss = 1;
                     }else if(TESTING_VAR_highmaxpriorsl[a] > 0){
                        TESTING_VAR_highslpoint[a] = TESTING_VAR_highpoint[a];
                        FUNCVAR_loss = 0;
                     }
                  }
                  FUNCVAR_counter++;
               }
            }
   
            if(TESTING_VAR_hightphit[a] < TESTING_VAR_highslhit[a] && TESTING_VAR_highhit[a] > 0){
               TESTING_VAR_highwinner[a] = TESTING_VAR_prize[a];
            }else if(TESTING_VAR_hightphit[a] > TESTING_VAR_highslhit[a] && TESTING_VAR_highhit[a] > 0){
               TESTING_VAR_highwinner[a] = FUNCVAR_loss;
            }else if(TESTING_VAR_highhit[a] > 0){
               TESTING_VAR_highwinner[a] = 0;
            }
   
            FUNCVAR_minibar = iBarShift(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, getinfo(5, TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a]));
            TESTING_VAR_lowhit[a] = 0;
            TESTING_VAR_lowtphit[a] = 1000000000000000;
            TESTING_VAR_lowslhit[a] = 1000000000000000;
            FUNCVAR_counter = 0;
            FUNCVAR_loss = -1;
            
            /* Original Sell Verison 
            if(FUNCVAR_minibar > 0 && (TESTING_VAR_ratio_spread[a] >= VOLCONST_vol_minsprdrto && TESTING_VAR_ratio_slfactor[a] >= VOLCONST_vol_minslrto)){
               //Find where entry would be made
               while(FUNCVAR_minibar - FUNCVAR_counter > 0 && FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) - 1 && TESTING_VAR_lowhit[a] == 0){
                  if(
                     TESTING_VAR_lowpoint[a] <= getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) &&
                     TESTING_VAR_lowpoint[a] >= getinfo(3, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)
                  ){
                     TESTING_VAR_lowhit[a] = iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter);
                  }
                  FUNCVAR_counter++;
               }
         
               while(
                  FUNCVAR_minibar - FUNCVAR_counter > 0 && 
                  FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) * 40 && 
                  TESTING_VAR_lowhit[a] > 0 &&
                  TimeDayOfWeek(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)) >= TimeDayOfWeek(iTime(TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a])) //Finish searching at end of week              
               ){
                  if(
                     TESTING_VAR_lowtppoint[a] >= getinfo(3, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_VAR_spread[a]
                  ){
                     TESTING_VAR_lowtphit[a] = MathMin(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_lowtphit[a]);
                  }
            
                  if(
                     TESTING_VAR_lowslpoint[a] <= getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_VAR_spread[a]
                  ){
                     TESTING_VAR_lowslhit[a] = MathMin(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_lowslhit[a]);
                  }
                  if(TESTING_VAR_lowtphit[a] == 1000000000000000 && TESTING_VAR_lowslhit[a] == 1000000000000000){
                     TESTING_VAR_lowmaxpriorsl[a] = MathMax(TESTING_VAR_lowmaxpriorsl[a], (TESTING_VAR_lowpoint[a] - getinfo(3, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_VAR_spread[a])/TESTING_VAR_sl[a]);
                     if(TESTING_VAR_lowmaxpriorsl[a] > 15){
                        TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a] - MathAbs(TESTING_VAR_sl[a])*5;
                        FUNCVAR_loss = 5;
                     }else if(TESTING_VAR_lowmaxpriorsl[a] > 10){
                        TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a] - MathAbs(TESTING_VAR_sl[a])*2.5;
                        FUNCVAR_loss = 2.5;
                     }else if(TESTING_VAR_lowmaxpriorsl[a] > 5){
                        TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a] - MathAbs(TESTING_VAR_sl[a]);
                        FUNCVAR_loss = 1;
                     }else if(TESTING_VAR_lowmaxpriorsl[a] > 0){
                        TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a];
                        FUNCVAR_loss = 0;
                     }
                  }
                  FUNCVAR_counter++;
               }
            }
            */
            
            if(FUNCVAR_minibar > 0 && (TESTING_VAR_ratio_spread[a] >= VOLCONST_vol_minsprdrto && TESTING_VAR_ratio_slfactor[a] >= VOLCONST_vol_minslrto)){
               //Find where entry would be made
               while(FUNCVAR_minibar - FUNCVAR_counter > 0 && FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) - 1 && TESTING_VAR_lowhit[a] == 0){
                  if(
                     TESTING_VAR_lowpoint[a] <= getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) &&
                     TESTING_VAR_lowpoint[a] >= getinfo(3, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)
                  ){
                     TESTING_VAR_lowhit[a] = iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter);
                  }
                  FUNCVAR_counter++;
               }
               
               FUNCVAR_counter--; //Take the counter back one to check the entry bar
               
               while(
                  FUNCVAR_minibar - FUNCVAR_counter > 0 && 
                  FUNCVAR_counter < (VOLCONST_vol_timeframe / VOLCONST_vol_minitimeframe) * 40 && 
                  TESTING_VAR_lowhit[a] > 0 &&
                  TimeDayOfWeek(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter)) >= TimeDayOfWeek(iTime(TESTING_VAR_pair[a], VOLCONST_vol_timeframe, TESTING_VAR_bar[a])) //Finish searching at end of week              
               ){
                  if(
                     TESTING_VAR_lowtppoint[a] <= getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_VAR_spread[a]
                  ){
                     TESTING_VAR_lowtphit[a] = MathMin(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_lowtphit[a]);
                  }
            
                  if(
                     TESTING_VAR_lowslpoint[a] >= getinfo(3, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_VAR_spread[a]
                  ){
                     TESTING_VAR_lowslhit[a] = MathMin(iTime(TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_lowslhit[a]);
                  }
                  if(TESTING_VAR_lowtphit[a] == 1000000000000000 && TESTING_VAR_lowslhit[a] == 1000000000000000){
                     TESTING_VAR_lowmaxpriorsl[a] = MathMax(TESTING_VAR_lowmaxpriorsl[a], (getinfo(2, TESTING_VAR_pair[a], VOLCONST_vol_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_VAR_lowpoint[a] - TESTING_VAR_spread[a])/TESTING_VAR_sl[a]);
                     if(TESTING_VAR_lowmaxpriorsl[a] > 15){
                        TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a] + MathAbs(TESTING_VAR_sl[a])*5;
                        FUNCVAR_loss = 5;
                     }else if(TESTING_VAR_lowmaxpriorsl[a] > 10){
                        TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a] + MathAbs(TESTING_VAR_sl[a])*2.5;
                        FUNCVAR_loss = 2.5;
                     }else if(TESTING_VAR_lowmaxpriorsl[a] > 5){
                        TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a] + MathAbs(TESTING_VAR_sl[a]);
                        FUNCVAR_loss = 1;
                     }else if(TESTING_VAR_lowmaxpriorsl[a] > 0){
                        TESTING_VAR_lowslpoint[a] = TESTING_VAR_lowpoint[a];
                        FUNCVAR_loss = 0;
                     }
                  }
                  FUNCVAR_counter++;
               }
            }
            
   
            if(TESTING_VAR_lowtphit[a] < TESTING_VAR_lowslhit[a] && TESTING_VAR_lowhit[a] > 0){
               TESTING_VAR_lowwinner[a] = TESTING_VAR_prize[a];
            }else if(TESTING_VAR_lowtphit[a] > TESTING_VAR_lowslhit[a] && TESTING_VAR_lowhit[a] > 0){
               TESTING_VAR_lowwinner[a] = FUNCVAR_loss;
            }else if(TESTING_VAR_lowhit[a] > 0){
               TESTING_VAR_lowwinner[a] = 0;
            }
         //}
      }
   }
      
   function_end();
}

string testing_removezero(double FUNCGET_number){
   if(FUNCGET_number != 0){
      return(FUNCGET_number);
   }else{
      return("");
   }
}

//+------------------------------------------------------------------+
//| END testing class                                                |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Account class                                                    |
//+------------------------------------------------------------------+

double      ACCOUNT_previousbalance;
double      ACCOUNT_initbalance;

void account_init(){
   function_start("account_init", true);
   
   GLOBAL_riskpertradeamount     = AccountBalance() * GLOBAL_riskpertradepercentage;
   ACCOUNT_initbalance           = AccountBalance();
   ACCOUNT_previousbalance       = AccountBalance();
   
   function_end();
}

void account_createorders(){
   function_start("account_createorders", true);
   
   int
      FUNCVAR_currencycounter,
      FUNCVAR_attempt,
      FUNCVAR_ticket,
      FUNCVAR_slippage,
      FUNCVAR_errornumber
      ;
      
   datetime
      FUNCVAR_time
      ;
   
   double
      FUNCVAR_price,
      FUNCVAR_sl,
      FUNCVAR_tp,
      FUNCVAR_target,
      FUNCVAR_volume
      ;
      
   string
      FUNCVAR_symbol,
      FUNCVAR_comment
      ;

   for(FUNCVAR_currencycounter=0;FUNCVAR_currencycounter<CURRENCY_selected_numberofpairs;FUNCVAR_currencycounter++){
                 
      FUNCVAR_symbol = CURRENCY_selected_pairs[FUNCVAR_currencycounter];
      //FUNCVAR_target = MarketInfo(FUNCVAR_symbol, MODE_STOPLEVEL) * MarketInfo(FUNCVAR_symbol, MODE_POINT);  
      FUNCVAR_target = MarketInfo(FUNCVAR_symbol, MODE_SPREAD) * MarketInfo(FUNCVAR_symbol, MODE_POINT) * 3;  
      FUNCVAR_volume = account_getlotsize(FUNCVAR_target, FUNCVAR_symbol);
      FUNCVAR_slippage = 2;
     
      FUNCVAR_attempt = 1;
      FUNCVAR_ticket = -1;
   
      while(FUNCVAR_ticket < 0 && FUNCVAR_attempt < 6 && FUNCVAR_volume > 0){
         FUNCVAR_price = getinfo(2, FUNCVAR_symbol, GLOBAL_timeframe, 1) + FUNCVAR_target * 1/3;
         FUNCVAR_sl = FUNCVAR_price - FUNCVAR_target;
         FUNCVAR_tp = FUNCVAR_price + (FUNCVAR_target * 1);
         FUNCVAR_comment = FUNCVAR_target;
         FUNCVAR_time = iTime(FUNCVAR_symbol, GLOBAL_timeframe, 0) + GLOBAL_timeframe * 60;
         FUNCVAR_ticket = OrderSend(FUNCVAR_symbol, OP_BUYSTOP, FUNCVAR_volume, FUNCVAR_price, FUNCVAR_slippage, FUNCVAR_sl, FUNCVAR_tp, FUNCVAR_comment, 0, FUNCVAR_time);
         if(FUNCVAR_ticket < 0){
            FUNCVAR_errornumber = GetLastError();
            log("Order failed attempt "+FUNCVAR_attempt+" with error #"+FUNCVAR_errornumber+" - "+ErrorDescription(FUNCVAR_errornumber));
            log("OP_BUYSTOP "+FUNCVAR_symbol+" "+FUNCVAR_volume+" "+FUNCVAR_price+" "+FUNCVAR_slippage+" "+FUNCVAR_sl+" "+FUNCVAR_tp+" "+FUNCVAR_comment+" "+FUNCVAR_time);
            Sleep(GLOBAL_pausetime);
            FUNCVAR_attempt++;
            RefreshRates();
         }
      }
      if(FUNCVAR_attempt == 6){
         log("Order unable to be opened.");
      }
      
      FUNCVAR_attempt = 1;
      FUNCVAR_ticket = -1;
      
      while(FUNCVAR_ticket < 0 && FUNCVAR_attempt < 6 && FUNCVAR_volume > 0){
         FUNCVAR_price = getinfo(3, FUNCVAR_symbol, GLOBAL_timeframe, 1) - FUNCVAR_target * 1/3;
         FUNCVAR_sl = FUNCVAR_price + FUNCVAR_target;
         FUNCVAR_tp = FUNCVAR_price - (FUNCVAR_target * 1);
         //FUNCVAR_sl = FUNCVAR_price - FUNCVAR_target;
         //FUNCVAR_tp = FUNCVAR_price + (FUNCVAR_target * 20);
         FUNCVAR_comment = FUNCVAR_target;
         FUNCVAR_time = iTime(FUNCVAR_symbol, GLOBAL_timeframe, 0) + GLOBAL_timeframe * 60;
         FUNCVAR_ticket = OrderSend(FUNCVAR_symbol, OP_SELLSTOP, FUNCVAR_volume, FUNCVAR_price, FUNCVAR_slippage, FUNCVAR_sl, FUNCVAR_tp, FUNCVAR_comment, 0, FUNCVAR_time);
         //FUNCVAR_ticket = OrderSend(FUNCVAR_symbol, OP_BUYLIMIT, FUNCVAR_volume, FUNCVAR_price, FUNCVAR_slippage, FUNCVAR_sl, FUNCVAR_tp, FUNCVAR_comment, 0, FUNCVAR_time);
         if(FUNCVAR_ticket < 0){
            FUNCVAR_errornumber = GetLastError();
            log("Order failed attempt "+FUNCVAR_attempt+" with error #"+FUNCVAR_errornumber+" - "+ErrorDescription(FUNCVAR_errornumber));
            log("OP_BUYLIMIT "+FUNCVAR_symbol+" "+FUNCVAR_volume+" "+FUNCVAR_price+" "+FUNCVAR_slippage+" "+FUNCVAR_sl+" "+FUNCVAR_tp+" "+FUNCVAR_comment+" "+FUNCVAR_time);
            Sleep(GLOBAL_pausetime);
            FUNCVAR_attempt++;
            RefreshRates();
         }
      }
      if(FUNCVAR_attempt == 6){
         log("Order unable to be opened.");
      }
      
   }
   function_end();
}

double account_getlotsize(double FUNCGET_target, string FUNCGET_currency){
   function_start("account_getlotsize", true);
   
   double
      FUNCVAR_targetinticks,
      FUNCVAR_tickvalue,
      FUNCVAR_ticksize,
      FUNCVAR_lots
      ;
   
   RefreshRates();
   FUNCVAR_ticksize = MarketInfo(FUNCGET_currency, MODE_TICKSIZE);
   FUNCVAR_tickvalue = MarketInfo(FUNCGET_currency, MODE_TICKVALUE);
   FUNCVAR_lots = 0;
   if(FUNCVAR_ticksize != 0 && FUNCVAR_tickvalue != 0){
      FUNCVAR_targetinticks = FUNCGET_target / FUNCVAR_ticksize;
      if(FUNCVAR_targetinticks != 0){
         FUNCVAR_lots = (GLOBAL_riskpertradeamount / FUNCVAR_targetinticks) / FUNCVAR_tickvalue;
      }
   }
   if(FUNCVAR_lots == 0){
      log("Error calculating lot size. Currency:"+FUNCGET_currency+" Target:"+FUNCGET_target+" Ticksize:"+FUNCVAR_ticksize+" Tickvalue:"+FUNCVAR_tickvalue);
      function_end();
      return(0);
   }
   
   function_end();
   return(FUNCVAR_lots);
}

void account_updatestops(){
   function_start("account_updatestops", true);
   
   int
      FUNCVAR_numberoforders,
      FUNCVAR_ticketnumber,
      FUNCVAR_count
      ;
      
   double
      FUNCVAR_target
      ;
   
   FUNCVAR_numberoforders = OrdersTotal();
   for(FUNCVAR_count=0; FUNCVAR_count < FUNCVAR_numberoforders; FUNCVAR_count++) {
      OrderSelect(FUNCVAR_count, SELECT_BY_POS, MODE_TRADES);

      FUNCVAR_target = StrToDouble(OrderComment());
   
      if(FUNCVAR_target > 0){
         if(OrderType() == OP_SELL){
            if(
               OrderOpenPrice() - MarketInfo(OrderSymbol(), MODE_ASK) > FUNCVAR_target * 15 &&
               OrderStopLoss() > OrderOpenPrice() - FUNCVAR_target * 3
            ){
               account_modifyorder(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - FUNCVAR_target * 3, OrderTakeProfit());
            }else if(
               OrderOpenPrice() - MarketInfo(OrderSymbol(), MODE_ASK) > FUNCVAR_target * 10 &&
               OrderStopLoss() > OrderOpenPrice() - FUNCVAR_target * 2
            ){
               account_modifyorder(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - FUNCVAR_target * 2, OrderTakeProfit());
            }else if(
               OrderOpenPrice() - MarketInfo(OrderSymbol(), MODE_ASK) > FUNCVAR_target * 5 &&
               OrderStopLoss() > OrderOpenPrice() - FUNCVAR_target * 1
            ){
               account_modifyorder(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - FUNCVAR_target * 1, OrderTakeProfit());
            }else if(
               OrderOpenPrice() - MarketInfo(OrderSymbol(), MODE_ASK) > FUNCVAR_target &&
               OrderStopLoss() > OrderOpenPrice() - FUNCVAR_target * 0
            ){       
               account_modifyorder(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - FUNCVAR_target * 0, OrderTakeProfit());
            }
         }else if(OrderType() == OP_BUY){
            if(
               MarketInfo(OrderSymbol(), MODE_BID) - OrderOpenPrice() > FUNCVAR_target * 15 &&
               OrderStopLoss() < OrderOpenPrice() + FUNCVAR_target * 3
            ){
               account_modifyorder(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + FUNCVAR_target * 3, OrderTakeProfit());
            }else if(
               MarketInfo(OrderSymbol(), MODE_BID) - OrderOpenPrice() > FUNCVAR_target * 10 &&
               OrderStopLoss() < OrderOpenPrice() + FUNCVAR_target * 2
            ){
               account_modifyorder(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + FUNCVAR_target * 2, OrderTakeProfit());
            }else if(
               MarketInfo(OrderSymbol(), MODE_BID) - OrderOpenPrice() > FUNCVAR_target * 5 &&
               OrderStopLoss() < OrderOpenPrice() + FUNCVAR_target * 1
            ){
               account_modifyorder(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + FUNCVAR_target * 1, OrderTakeProfit());
            }else if(
               MarketInfo(OrderSymbol(), MODE_BID) - OrderOpenPrice() > FUNCVAR_target &&
               OrderStopLoss() < OrderOpenPrice() + FUNCVAR_target * 0
            ){       
               account_modifyorder(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + FUNCVAR_target * 0, OrderTakeProfit());
            }
         }
      }
   }

   function_end();
}

void account_modifyorder(int FUNCGET_OrderTicket, double FUNCGET_OrderOpenPrice, double FUNCGET_SL, double FUNCGET_TP){
   function_start("account_modifyorder", true);
   
   int
      FUNCVAR_ticket,
      FUNCVAR_errornumber,
      FUNCVAR_attempt
      ;
   
   FUNCVAR_attempt = 1;
   
   while(FUNCVAR_ticket == FALSE && FUNCVAR_attempt < 6){
      FUNCVAR_ticket = OrderModify(FUNCGET_OrderTicket, FUNCGET_OrderOpenPrice, FUNCGET_SL, FUNCGET_TP, 0);
      if(FUNCVAR_ticket == FALSE){
         FUNCVAR_errornumber = GetLastError();
         log("Modify Order failed with error #"+FUNCVAR_errornumber+" - "+ErrorDescription(FUNCVAR_errornumber));
         log("Modify Order failed attempt "+FUNCVAR_attempt+": "+FUNCGET_OrderTicket+" "+FUNCGET_OrderOpenPrice+" "+FUNCGET_SL+" "+FUNCGET_TP);
         Sleep(GLOBAL_pausetime);
         FUNCVAR_attempt++;
         RefreshRates();
      }
   }
   if(FUNCVAR_attempt == 6){
      log("Order unable to be closed.");
   }else{
      log("Order "+FUNCGET_OrderTicket+" closed");
   }
   function_end();

}


void account_update(){
   function_start("account_update", true);
   
   double
      FUNCVAR_accountchange,
      FUNCVAR_initaccountchange,
      FUNCVAR_accountchangepercentage,
      FUNCVAR_initchangepercentage
      ;

   FUNCVAR_accountchange = AccountBalance() - ACCOUNT_previousbalance;
   if(ACCOUNT_previousbalance > 0){
      FUNCVAR_accountchangepercentage = ((AccountBalance() / ACCOUNT_previousbalance)-1)*100;
   }else{
      FUNCVAR_accountchangepercentage = 100;
   }
   FUNCVAR_initaccountchange = AccountBalance() - ACCOUNT_initbalance;
   if(ACCOUNT_initbalance > 0){
      FUNCVAR_initchangepercentage = ((AccountBalance() / ACCOUNT_initbalance)-1)*100;
   }else{
      FUNCVAR_initchangepercentage = 100;
   }
   if(GLOBAL_sendnotifications == true){
      //Add more information here as to winners vs losers.
      SendNotification("Pre:"+DoubleToStr(ACCOUNT_previousbalance, 2)+AccountCurrency()+" Post:"+DoubleToStr(AccountBalance(), 2)+AccountCurrency()+" Change:"+DoubleToStr(FUNCVAR_accountchange, 2)+" "+DoubleToStr(FUNCVAR_accountchangepercentage, 2)+"% or "+DoubleToStr(FUNCVAR_initaccountchange, 2)+" "+DoubleToStr(FUNCVAR_initchangepercentage, 2)+"% since init");
   }
   ACCOUNT_previousbalance = AccountBalance();
   GLOBAL_riskpertradeamount = AccountBalance() * GLOBAL_riskpertradepercentage;

   function_end();
}

