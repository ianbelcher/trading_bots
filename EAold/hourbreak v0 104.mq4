//+------------------------------------------------------------------+
//|                                            hour break v0 104.mq4 |
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

#define PROGRAM_VERSION "hour break v0 104"

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
extern double  GLOBAL_riskpertradepercentage = 0.001;          //The percentage of the account to risk per trade.
extern int     GLOBAL_pausetime              = 1000;           //In milliseconds. Time to wait before polling server after bad response.
extern bool    GLOBAL_sendnotifications      = true;           //Whether to send notifications or not.

extern string  SET_CURRENCY                  = "EURUSD";
extern double  SET_DISTANCE                  = 0.00025;

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

v0 104
Have updated VPS to a two install setup, one for Live the other for Demo. 
Currently recording SPREAD and STOPLEVEL for the EURUSD pair to give a better idea for how SPREAD moves in relation to high/low/pp etc.
Looking to remove the Currency class and have Currencies and distances set manually by the user.

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
   log("GLOBAL_runcron: "+GLOBAL_runcron);
   log("GLOBAL_riskpertradepercentage: "+GLOBAL_riskpertradepercentage);
   log("GLOBAL_sendnotifications: "+GLOBAL_sendnotifications);
   log("SET_CURRENCY: "+SET_CURRENCY);
   log("SET_DISTANCE: "+SET_DISTANCE);

   GLOBAL_timeframe              = HOUR;              //In Minutes. The timeframe to cycle orders.
   GLOBAL_cronincrement          = 15;                //In Minutes. What time frame to run the smallest cron task
   GLOBAL_refreshrate            = 1;                 //In Seconds. How often to refresh rates
   
   account_init();  
   cron_init();

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
      account_updatestops();
      cron_update();
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

int      TESTING_VAR_bar;
double   TESTING_VAR_testvar1;
double   TESTING_VAR_testvar2;

double   TESTING_VAR_tp;
double   TESTING_VAR_sl;
double   TESTING_VAR_prize;

double   TESTING_VAR_highpoint;
double   TESTING_VAR_highhit;
double   TESTING_VAR_hightppoint;
double   TESTING_VAR_hightphit;
double   TESTING_VAR_highslpoint;
double   TESTING_VAR_highslhit;
double   TESTING_VAR_highmaxpriorsl;
double   TESTING_VAR_highwinner;
double   TESTING_VAR_lowpoint;
double   TESTING_VAR_lowhit;
double   TESTING_VAR_lowtppoint;
double   TESTING_VAR_lowtphit;
double   TESTING_VAR_lowslpoint;
double   TESTING_VAR_lowslhit;
double   TESTING_VAR_lowmaxpriorsl;
double   TESTING_VAR_lowwinner;

int      TESTING_TIMEFRAME = HOUR;
int      TESTING_MINITIMEFRAME = 1;
double   TESTING_DISTANCE = 0.00060;
double   TESTING_SPREAD = 0.00013;

void testing_logarray(int FUNCGET_instance = 1){
   function_start("testing_logarray", true);
   if(
      TimeHour(iTime(SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar)) >= 8 &&
      TimeHour(iTime(SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar)) <= 20 
   ){
      log(
      humandate(iTime(SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar))+";"+
      iTime(SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar)+";"+
      SET_CURRENCY+";"+
      TESTING_VAR_testvar1+";"+
      //"=SUMIF(R1C6:R50000C6,RC6,R1C20:R50000C20)"+";"+
      TESTING_VAR_testvar2+";"+
      //"=SUMIF(R1C6:R50000C6,RC6,R1C28:R50000C28)"+";"+
        
      TESTING_VAR_tp+";"+
      TESTING_VAR_sl+";"+
      TESTING_VAR_prize+";"+
             
      TESTING_VAR_highpoint+";"+
      //humandate(TESTING_VAR_highhit)+";"+
      TESTING_VAR_highhit+";"+
      TESTING_VAR_hightppoint+";"+
      //humandate(TESTING_VAR_hightphit)+";"+
      TESTING_VAR_hightphit+";"+
      TESTING_VAR_highslpoint+";"+
      //humandate(TESTING_VAR_highslhit)+";"+
      TESTING_VAR_highslhit+";"+
      TESTING_VAR_highmaxpriorsl+";"+
      testing_removezero(TESTING_VAR_highwinner)+";"+
      
      TESTING_VAR_lowpoint+";"+
      humandate(TESTING_VAR_lowhit)+";"+
      //TESTING_VAR_lowhit+";"+
      TESTING_VAR_lowtppoint+";"+
      humandate(TESTING_VAR_lowtphit)+";"+
      TESTING_VAR_lowslpoint+";"+
      humandate(TESTING_VAR_lowslhit)+";"+
      TESTING_VAR_lowmaxpriorsl+";"+
      testing_removezero(TESTING_VAR_lowwinner)+";"+
      "=IF(RC5<>R[-1]C5,SUMIF(R1C5:R50000C5,RC5,R1C19:R50000C19)+SUMIF(R1C5:R50000C5,RC5,R1C27:R50000C27),\"\")"+";"+
      "=IF(RC[-1]<>\"\",R[-1]C+R[-1]C*RC[-1]*0.01,R[-1]C)"+";"+
      "=MAX(R[-1]C,RC[-1])"+";"+
      "=RC[-2]/RC[-1]"+";"+
      "");
      
      if(SET_CURRENCY == Symbol()){
         ObjectCreate("hline-"+FUNCGET_instance+"entry", OBJ_RECTANGLE, 0, 
            iTime(Symbol(),TESTING_TIMEFRAME, TESTING_VAR_bar - 1), 
            TESTING_VAR_highpoint, 
            iTime(Symbol(),TESTING_TIMEFRAME, TESTING_VAR_bar), 
            TESTING_VAR_lowpoint
         );
         ObjectSet("hline-"+FUNCGET_instance+"entry", OBJPROP_COLOR, Yellow);
         ObjectSet("hline-"+FUNCGET_instance+"entry", OBJPROP_STYLE, 0);
         ObjectSet("hline-"+FUNCGET_instance+"entry", OBJPROP_WIDTH, 1);
         ObjectSet("hline-"+FUNCGET_instance+"entry", OBJPROP_BACK, 0);
      
         ObjectCreate("hline-"+FUNCGET_instance+"sl", OBJ_RECTANGLE, 0, 
            iTime(Symbol(),TESTING_TIMEFRAME, TESTING_VAR_bar - 1), 
            TESTING_VAR_highslpoint, 
            iTime(Symbol(),TESTING_TIMEFRAME, TESTING_VAR_bar), 
            TESTING_VAR_lowslpoint
         );
         ObjectSet("hline-"+FUNCGET_instance+"sl", OBJPROP_COLOR, Red);
         ObjectSet("hline-"+FUNCGET_instance+"sl", OBJPROP_STYLE, 0);
         ObjectSet("hline-"+FUNCGET_instance+"sl", OBJPROP_WIDTH, 1);
         ObjectSet("hline-"+FUNCGET_instance+"sl", OBJPROP_BACK, 0);
         
         ObjectCreate("hline-"+FUNCGET_instance+"tp", OBJ_RECTANGLE, 0, 
            iTime(Symbol(),TESTING_TIMEFRAME, TESTING_VAR_bar - 1), 
            TESTING_VAR_hightppoint, 
            iTime(Symbol(),TESTING_TIMEFRAME, TESTING_VAR_bar), 
            TESTING_VAR_lowtppoint
         );
         ObjectSet("hline-"+FUNCGET_instance+"tp", OBJPROP_COLOR, Green);
         ObjectSet("hline-"+FUNCGET_instance+"tp", OBJPROP_STYLE, 0);
         ObjectSet("hline-"+FUNCGET_instance+"tp", OBJPROP_WIDTH, 1);
         ObjectSet("hline-"+FUNCGET_instance+"tp", OBJPROP_BACK, 0);
         
         ObjectCreate("heading-"+FUNCGET_instance+"high", OBJ_TEXT, 0, iTime(Symbol(),TESTING_TIMEFRAME, TESTING_VAR_bar), TESTING_VAR_highpoint);
         ObjectSetText("heading-"+FUNCGET_instance+"high", "               "+TESTING_VAR_highwinner, 9, "Courier New", White);
         ObjectCreate("heading-"+FUNCGET_instance+"low", OBJ_TEXT, 0, iTime(Symbol(),TESTING_TIMEFRAME, TESTING_VAR_bar), TESTING_VAR_lowpoint);
         ObjectSetText("heading-"+FUNCGET_instance+"low", "               "+TESTING_VAR_lowwinner, 9, "Courier New", White);
      }
   }
   function_end();
}

void testing_cleararray(){
   function_start("testing_cleararray", true);
   TESTING_VAR_bar = 0;
   TESTING_VAR_testvar1 = 0;
   TESTING_VAR_testvar2 = 0;
   
   TESTING_VAR_tp = 0;
   TESTING_VAR_sl = 0;
   TESTING_VAR_prize = 0;
   
   TESTING_VAR_highpoint = 0;
   TESTING_VAR_highhit = 0;
   TESTING_VAR_hightppoint = 0;
   TESTING_VAR_hightphit = 0;
   TESTING_VAR_highslpoint = 0;
   TESTING_VAR_highslhit = 0;
   TESTING_VAR_highmaxpriorsl = 0;
   TESTING_VAR_highwinner = 0;
   
   TESTING_VAR_lowpoint = 0;
   TESTING_VAR_lowhit = 0;
   TESTING_VAR_lowtppoint = 0;
   TESTING_VAR_lowtphit = 0;
   TESTING_VAR_lowslpoint = 0;
   TESTING_VAR_lowslhit = 0;
   TESTING_VAR_lowmaxpriorsl = 0;
   TESTING_VAR_lowwinner = 0;         
   function_end();
}

void testing_runtests(){
   function_start("testing_runtests", true);
    
   //Returns the volitility report and shuts down the EA.
      GLOBAL_runcron = false;
      log("GLOBAL_runcron set to false. *** EA will not perform cron tasks***");
      log(";;;;;T;S;P;HP;HPH;HTP;HTPH;HSL;HSLH;MH;;LP;LPH;LTP;LTPH;LSL;LSLH;MH;;;Running Balance;Average Return;DD;Max Profit");
      log(";;;;;;;;;;;;;;;=SUM(R[1]C:R[50000]C);;;;;;;;=SUM(R[1]C:R[50000]C);=SUM(R[1]C:R[50000]C);1000;=AVERAGE(R[1]C19:R[50000]C19,R[1]C27:R[50000]C27);=MIN(R[1]C:R[50000]C);=MAX(R[1]C[-3]:R[50000]C[-3])");
      ObjectsDeleteAll();
      for(int a=1; a<960; a++){ //120 is a week, 960 8 week and extent of data
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
       
   TESTING_VAR_bar = FUNCGET_bar;
       
   TESTING_VAR_sl = (-1.0) * (TESTING_DISTANCE + TESTING_SPREAD);
   TESTING_VAR_tp = (20.0) * MathAbs(TESTING_VAR_sl);

   if(TESTING_VAR_sl != 0){
      TESTING_VAR_prize = MathAbs(TESTING_VAR_tp) / MathAbs(TESTING_VAR_sl);
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
 
   
   TESTING_VAR_highpoint = getinfo(2, SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar + 1); // +  TESTING_DISTANCE; 
   TESTING_VAR_hightppoint = TESTING_VAR_highpoint + TESTING_VAR_tp;
   TESTING_VAR_highslpoint = TESTING_VAR_highpoint + TESTING_VAR_sl;  

   TESTING_VAR_lowpoint = getinfo(3, SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar + 1);// - TESTING_DISTANCE;
   TESTING_VAR_lowtppoint = TESTING_VAR_lowpoint - TESTING_VAR_tp;
   TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint - TESTING_VAR_sl;
         
   FUNCVAR_minibar = iBarShift(SET_CURRENCY, TESTING_MINITIMEFRAME, getinfo(5, SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar));
   TESTING_VAR_highhit = 0;
   TESTING_VAR_hightphit = 1000000000000000;
   TESTING_VAR_highslhit = 1000000000000000;
   FUNCVAR_counter = 0;
   FUNCVAR_loss = -1;
   
   if(FUNCVAR_minibar > 0){
      //Find where entry would be made
      while(FUNCVAR_minibar - FUNCVAR_counter > 0 && FUNCVAR_counter < (TESTING_TIMEFRAME / TESTING_MINITIMEFRAME) - 1 && TESTING_VAR_highhit == 0){
         if(
            TESTING_VAR_highpoint <= getinfo(2, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_SPREAD &&
            TESTING_VAR_highpoint >= getinfo(3, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_SPREAD
         ){
            TESTING_VAR_highhit = iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter);
         }
         FUNCVAR_counter++;
      }
            
      //Check that entry was somewhat clean, else stop out the entry
      if(
         1==2 &&
         (
            getinfo(4, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter + 1) < TESTING_VAR_highpoint || //if close is lower than entry
            getinfo(4, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter + 1) < getinfo(1, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter + 1) //if close is lower than open
         )
         && 
         TESTING_VAR_highhit > 0
      ){
         TESTING_VAR_highslhit = iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter);
      }
      
      while(
         FUNCVAR_minibar - FUNCVAR_counter > 0 && 
         FUNCVAR_counter < (TESTING_TIMEFRAME / TESTING_MINITIMEFRAME) * 40 && 
         TESTING_VAR_highhit > 0 && //
         TimeDayOfWeek(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter)) >= TimeDayOfWeek(iTime(SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar)) //Finish searching at end of week
      ){
         if(
            TESTING_VAR_hightppoint <= getinfo(2, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter)
         ){
            TESTING_VAR_hightphit = MathMin(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_hightphit);
         }
   
         if(
            TESTING_VAR_highslpoint >= getinfo(3, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter)
         ){
            TESTING_VAR_highslhit = MathMin(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_highslhit);
         }
         if(TESTING_VAR_hightphit == 1000000000000000 && TESTING_VAR_highslhit == 1000000000000000){
            TESTING_VAR_highmaxpriorsl = MathMax(TESTING_VAR_highmaxpriorsl, (getinfo(2, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_VAR_highpoint - TESTING_SPREAD)/MathAbs(TESTING_VAR_sl));
            if(TESTING_VAR_highmaxpriorsl > 15){
               TESTING_VAR_highslpoint = TESTING_VAR_highpoint + MathAbs(TESTING_VAR_sl)*5;
               FUNCVAR_loss = 5;
            }else if(TESTING_VAR_highmaxpriorsl > 10){
               TESTING_VAR_highslpoint = TESTING_VAR_highpoint + MathAbs(TESTING_VAR_sl)*2.5;
               FUNCVAR_loss = 2.5;
            }else if(TESTING_VAR_highmaxpriorsl > 2){
               TESTING_VAR_highslpoint = TESTING_VAR_highpoint + MathAbs(TESTING_VAR_sl);
               FUNCVAR_loss = 1;
            }else if(TESTING_VAR_highmaxpriorsl > 0){
               TESTING_VAR_highslpoint = TESTING_VAR_highpoint;
               FUNCVAR_loss = 0;
            }
         }
         FUNCVAR_counter++;
      }
   }

   if(TESTING_VAR_hightphit < TESTING_VAR_highslhit && TESTING_VAR_highhit > 0){
      TESTING_VAR_highwinner = TESTING_VAR_prize;
   }else if(TESTING_VAR_hightphit > TESTING_VAR_highslhit && TESTING_VAR_highhit > 0){
      TESTING_VAR_highwinner = FUNCVAR_loss;
   }else if(TESTING_VAR_highhit > 0){
      TESTING_VAR_highwinner = 0;
   }

   FUNCVAR_minibar = iBarShift(SET_CURRENCY, TESTING_MINITIMEFRAME, getinfo(5, SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar));
   TESTING_VAR_lowhit = 0;
   TESTING_VAR_lowtphit = 1000000000000000;
   TESTING_VAR_lowslhit = 1000000000000000;
   FUNCVAR_counter = 0;
   FUNCVAR_loss = -1;
   
   /*
   
   // Sell situ
   
   if(FUNCVAR_minibar > 0){
      //Find where entry would be made
      while(FUNCVAR_minibar - FUNCVAR_counter > 0 && FUNCVAR_counter < (TESTING_TIMEFRAME / TESTING_MINITIMEFRAME) - 1 && TESTING_VAR_lowhit == 0){
         if(
            TESTING_VAR_lowpoint <= getinfo(2, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) &&
            TESTING_VAR_lowpoint >= getinfo(3, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter)
         ){
            TESTING_VAR_lowhit = iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter);
         }
         FUNCVAR_counter++;
      }

      //Check that entry was somewhat clean, else stop out the entry
      if(
         (
            getinfo(4, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter + 1) > TESTING_VAR_lowpoint || //if close is higher than entry
            getinfo(4, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter + 1) > getinfo(1, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter + 1) //if close is higher than open
         )
         && 
         TESTING_VAR_lowhit > 0
      ){
         TESTING_VAR_lowslhit = iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter);
      }

      while(
         FUNCVAR_minibar - FUNCVAR_counter > 0 && 
         FUNCVAR_counter < (TESTING_TIMEFRAME / TESTING_MINITIMEFRAME) * 40 && 
         TESTING_VAR_lowhit > 0 &&
         TimeDayOfWeek(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter)) >= TimeDayOfWeek(iTime(SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar)) //Finish searching at end of week              
      ){
         if(
            TESTING_VAR_lowtppoint >= getinfo(3, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_SPREAD
         ){
            TESTING_VAR_lowtphit = MathMin(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_lowtphit);
         }
   
         if(
            TESTING_VAR_lowslpoint <= getinfo(2, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_SPREAD
         ){
            TESTING_VAR_lowslhit = MathMin(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_lowslhit);
         }
         if(TESTING_VAR_lowtphit == 1000000000000000 && TESTING_VAR_lowslhit == 1000000000000000){
            TESTING_VAR_lowmaxpriorsl = MathMax(TESTING_VAR_lowmaxpriorsl, (TESTING_VAR_lowpoint - getinfo(3, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_SPREAD)/MathAbs(TESTING_VAR_sl));
            if(TESTING_VAR_lowmaxpriorsl > 15){
               TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint - MathAbs(TESTING_VAR_sl)*5;
               FUNCVAR_loss = 5;
            }else if(TESTING_VAR_lowmaxpriorsl > 10){
               TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint - MathAbs(TESTING_VAR_sl)*2.5;
               FUNCVAR_loss = 2.5;
            }else if(TESTING_VAR_lowmaxpriorsl > 5){
               TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint - MathAbs(TESTING_VAR_sl);
               FUNCVAR_loss = 1;
            }else if(TESTING_VAR_lowmaxpriorsl > 0){
               TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint;
               FUNCVAR_loss = 0;
            }
         }
         FUNCVAR_counter++;
      }
   }

   // Buy situ   
   
   if(FUNCVAR_minibar > 0){
      //Find where entry would be made
      while(FUNCVAR_minibar - FUNCVAR_counter > 0 && FUNCVAR_counter < (TESTING_TIMEFRAME / TESTING_MINITIMEFRAME) - 1 && TESTING_VAR_lowhit == 0){
         if(
            TESTING_VAR_lowpoint <= getinfo(2, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_SPREAD &&
            TESTING_VAR_lowpoint >= getinfo(3, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_SPREAD
         ){
            TESTING_VAR_lowhit = iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter);
         }
         FUNCVAR_counter++;
      }
      
      FUNCVAR_counter--; //Take the counter back one to check the entry bar
      
      while(
         FUNCVAR_minibar - FUNCVAR_counter > 0 && 
         FUNCVAR_counter < (TESTING_TIMEFRAME / TESTING_MINITIMEFRAME) * 40 && 
         TESTING_VAR_lowhit > 0 &&
         TimeDayOfWeek(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter)) >= TimeDayOfWeek(iTime(SET_CURRENCY, TESTING_TIMEFRAME, TESTING_VAR_bar)) //Finish searching at end of week              
      ){
         if(
            TESTING_VAR_lowtppoint <= getinfo(2, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) + TESTING_SPREAD
         ){
            TESTING_VAR_lowtphit = MathMin(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_lowtphit);
         }
   
         if(
            TESTING_VAR_lowslpoint >= getinfo(3, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_SPREAD
         ){
            TESTING_VAR_lowslhit = MathMin(iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter), TESTING_VAR_lowslhit);
         }
         if(TESTING_VAR_lowtphit == 1000000000000000 && TESTING_VAR_lowslhit == 1000000000000000 && TESTING_VAR_lowhit != iTime(SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter)){ // Don't check the first bar
            TESTING_VAR_lowmaxpriorsl = MathMax(TESTING_VAR_lowmaxpriorsl, (getinfo(2, SET_CURRENCY, TESTING_MINITIMEFRAME, FUNCVAR_minibar - FUNCVAR_counter) - TESTING_VAR_lowpoint - TESTING_SPREAD)/MathAbs(TESTING_VAR_sl));
            if(TESTING_VAR_lowmaxpriorsl > 15){
               TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint + MathAbs(TESTING_VAR_sl)*5;
               FUNCVAR_loss = 5;
            }else if(TESTING_VAR_lowmaxpriorsl > 10){
               TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint + MathAbs(TESTING_VAR_sl)*2.5;
               FUNCVAR_loss = 2.5;
            }else if(TESTING_VAR_lowmaxpriorsl > 5){
               TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint + MathAbs(TESTING_VAR_sl);
               FUNCVAR_loss = 1;
            }else if(TESTING_VAR_lowmaxpriorsl > 0){
               TESTING_VAR_lowslpoint = TESTING_VAR_lowpoint;
               FUNCVAR_loss = 0;
            }
         }
         FUNCVAR_counter++;
      }
   }
   */

   if(TESTING_VAR_lowtphit < TESTING_VAR_lowslhit && TESTING_VAR_lowhit > 0){
      TESTING_VAR_lowwinner = TESTING_VAR_prize;
   }else if(TESTING_VAR_lowtphit > TESTING_VAR_lowslhit && TESTING_VAR_lowhit > 0){
      TESTING_VAR_lowwinner = FUNCVAR_loss;
   }else if(TESTING_VAR_lowhit > 0){
      TESTING_VAR_lowwinner = 0;
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
                
      FUNCVAR_symbol = SET_CURRENCY;
      FUNCVAR_target = SET_DISTANCE;  
      FUNCVAR_volume = account_getlotsize(FUNCVAR_target, FUNCVAR_symbol);
      FUNCVAR_slippage = 2;
     
      FUNCVAR_attempt = 1;
      FUNCVAR_ticket = -1;
   
   while(FUNCVAR_ticket < 0 && FUNCVAR_attempt < 6 && FUNCVAR_volume > 0){
      FUNCVAR_price = getinfo(2, FUNCVAR_symbol, GLOBAL_timeframe, 1) + FUNCVAR_target * 1/3;
      FUNCVAR_sl = FUNCVAR_price - FUNCVAR_target;
      FUNCVAR_tp = FUNCVAR_price + (FUNCVAR_target * 20);
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
      //FUNCVAR_sl = FUNCVAR_price + FUNCVAR_target;
      //FUNCVAR_tp = FUNCVAR_price - (FUNCVAR_target * 20);
      FUNCVAR_sl = FUNCVAR_price - FUNCVAR_target;
      FUNCVAR_tp = FUNCVAR_price + (FUNCVAR_target * 20);
      FUNCVAR_comment = FUNCVAR_target;
      FUNCVAR_time = iTime(FUNCVAR_symbol, GLOBAL_timeframe, 0) + GLOBAL_timeframe * 60;
      //FUNCVAR_ticket = OrderSend(FUNCVAR_symbol, OP_SELLSTOP, FUNCVAR_volume, FUNCVAR_price, FUNCVAR_slippage, FUNCVAR_sl, FUNCVAR_tp, FUNCVAR_comment, 0, FUNCVAR_time);
      FUNCVAR_ticket = OrderSend(FUNCVAR_symbol, OP_BUYLIMIT, FUNCVAR_volume, FUNCVAR_price, FUNCVAR_slippage, FUNCVAR_sl, FUNCVAR_tp, FUNCVAR_comment, 0, FUNCVAR_time);
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

