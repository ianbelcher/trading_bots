//+------------------------------------------------------------------+
//|                                        Signature System v0 7.mq4 |
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
#include <WinUser32.mqh>

//#define PROGRAM_VERSION "v0 1" //Original Development in UK
//Returned to Australia
//#define PROGRAM_VERSION "v0 2" 
//Orders being created and deleted. Checking for zero divide errors. Added External variables. Add function tracking for debugging.
//#define PROGRAM_VERSION "v0 3"
//Creation of trade tracking through Ticket number.
//#define PROGRAM_VERSION "v0 4"
//Reveloped the lookback section. Accounting for more data.
//#define PROGRAM_VERSION "v0 5"
//Major clean of code. Improved currency selection.
//#define PROGRAM_VERSION "v0 6" 
//Investigation of new data and simplification of testing reports.
#define PROGRAM_VERSION "v0 7"
//Introduction of WinUser32.mqh. Improvements to logging, notifications, investigation into Windows based check for EA running. 

#define MINUTE 1 
#define HOUR 60
#define DAY 1440
#define WEEK 10080
#define MONTH 43800
#define YEAR 525600

extern bool    GLOBAL_testing                = true;           //Makes the EA fire on increment, not timeframe. Resets log.
extern bool    GLOBAL_debug                  = false;          //Increases the amount of data written to the log for debugging purposes.
extern bool    GLOBAL_resetfiles             = false;          //Deletes and resets output files. Only for development.
extern int     GLOBAL_recentlookback         = 15000000;       //In Seconds. For the RECENT sub-signature, this is the lookback. 2.5M is about one month.
extern int     GLOBAL_goalminnumberofcases   = 6;              //There needs to be at least this many cases of a previous signature for it to be counted.
extern double  GLOBAL_goalminrating          = 0.3;            //The minimum expected ROI on a trade 
extern int     GLOBAL_goalspreadfactor       = 5;              //Minimum target needs to be this many times the spread to negate its effects.
extern double  GLOBAL_riskpertradepercentage = 0.01;           //The percentage of the account to risk per trade.
extern int     GLOBAL_pausetime              = 1000;           //In milliseconds. Time to wait before polling server after bad response.
extern bool    GLOBAL_sendnotifications      = false;          //Whether to send notifications or not.

extern bool    CURRENCY_USD                  = true;
extern bool    CURRENCY_CHF                  = true;
extern bool    CURRENCY_EUR                  = true;
extern bool    CURRENCY_GBP                  = true;
extern bool    CURRENCY_CAD                  = true;
extern bool    CURRENCY_JPY                  = true;
extern bool    CURRENCY_AUD                  = true;
extern bool    CURRENCY_NZD                  = true;
extern bool    CURRENCY_SGD                  = true;
extern bool    CURRENCY_HKD                  = true;
extern bool    CURRENCY_DKK                  = true;
extern bool    CURRENCY_NOK                  = true;
extern bool    CURRENCY_SEK                  = true;
extern bool    CURRENCY_TRY                  = true;
extern bool    CURRENCY_PLN                  = false; //= true;
extern bool    CURRENCY_MXN                  = false; //= true;
extern bool    CURRENCY_XAU                  = true;
extern bool    CURRENCY_XAG                  = true;
extern string  CURRENCY_skippairs            = "CHFSGD; EURSGD; EURDKK; EURNOK; EURSEK; USDTRY; EURTRY; GBPSGD; GBPSEK; GBPNOK; GBPDKK; GBPTRY; CADSGD; CADSEK; CADNOK; CADDKK; CADTRY; AUDSGD; NZDCHF; NZDSGD; NZDCAD; NOKJPY; HKDJPY; NOKSEK; SEKJPY";

//double GLOBAL_targetpercentages[7] = {0.764, 0.618, 0.50, 0.382, 0.33, 0.236, 0.15};
double GLOBAL_targetpercentages[13] = {0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25, 0.2};

int
   GLOBAL_timeframe,
   GLOBAL_minitimeframe,
   GLOBAL_currentnumberoforders,
   GLOBAL_cronincrement
   ;

double
   GLOBAL_riskpertradeamount
   ;

string
   GLOBAL_dumporderarray_file
   ;
   
bool
   GLOBAL_isdemo,
   GLOBAL_dumpsumarraytitles = false
   ; 

//v Account Variables
double
   ACCOUNT_previousbalance,
   ACCOUNT_closedordersprofit
   ;
int
   ACCOUNT_numberofclosedorders,
   ACCOUNT_totalnumberoforders
   ;
//^
   
//v Signature Variables
string
   SIGNATURE_SUM_order[100], //Buy or Sell
   SIGNATURE_SUM_pair[100],
   SIGNATURE_SUM_signature[100],

   SIGNATURE_signature[15]
   ;

int
   SIGNATURE_SUM_date,
   SIGNATURE_SUM_barnumber,
   SIGNATURE_SUM_recent_datemin[100],
   SIGNATURE_SUM_recent_datemax[100],
   SIGNATURE_SUM_recent_cases[100],
   SIGNATURE_SUM_recent_result[100],
   SIGNATURE_SUM_total_cases[100],
   SIGNATURE_SUM_total_result[100],
   SIGNATURE_SUM_noninverse_cases[100],
   SIGNATURE_SUM_noninverse_result[100],
   SIGNATURE_SUM_win[100],
      

   SIGNATURE_RECENT_datemin,
   SIGNATURE_RECENT_datemax,
   SIGNATURE_RECENT_cases[15], //Recent results
   SIGNATURE_RECENT_result[15],
   SIGNATURE_TOTAL_cases[15], //All results
   SIGNATURE_TOTAL_result[15],
   SIGNATURE_NONINVERSE_cases[15], //Without inverse results
   SIGNATURE_NONINVERSE_result[15]
   ;
   
double
   SIGNATURE_SUM_target[100], //The best target to choose
   SIGNATURE_SUM_targetdistance[100], //The best target to choose
   SIGNATURE_SUM_targetpositive[100],
   SIGNATURE_SUM_targetnegative[100],  
   SIGNATURE_SUM_recent_rating[100],
   SIGNATURE_SUM_total_rating[100],
   SIGNATURE_SUM_noninverse_rating[100]
   ;
//^

//v Orders Array
int
   ORDERS_ticket[100],
   ORDERS_choice[100]
   ;
double
   ORDERS_target[100],
   ORDERS_targetaccounttrisk,
   ORDERS_rating[100],
   ORDERS_return[100],
   ORDERS_cases[100],
   ORDERS_noninverse_rating[100],
   ORDERS_pair_rating[100],
   ORDERS_recent_rating[100]
   ;
string
   ORDERS_pair[100],
   ORDERS_order[100],
   ORDERS_signature[100]
   ;
//^

//v Time Array
int
   TIME_currentweek,
   TIME_currentday,
   TIME_currenthour,
   TIME_currentincrement,
   TIME_weekcrontime,
   TIME_daycrontime,
   TIME_hourcrontime,
   TIME_incrementcrontime
   ;

bool
   TIME_weekended,
   TIME_dayended,
   TIME_hourended,
   TIME_incrementended
   ;
//^

//v Function tracking array
int  
   FUNCTION_functionnest
   ;
string
   FUNCTION_functionname[500]
   ;  
bool
   FUNCTION_tracer[100]
   ;   
//^

//v Currency array
int
   CURRENCY_numberofpairs,
   CURRENCY_numberofallpairs,
   CURRENCY_allpairslookback[100]
   ;
string
   CURRENCY_usedentities[100],
   CURRENCY_allentities[100],
   CURRENCY_pairs[100],
   CURRENCY_allpairs[100]
   ;
//^

//+------------------------------------------------------------------+
//| initialization function                                          |
//+------------------------------------------------------------------+
int init(){  
   Alert("Signature System " + PROGRAM_VERSION + " started.");
   Alert("Initalising log");
   log(); //Initialise the log file so dependant functions can work  
   Alert("Starting init function processing");
   function_start("init", true);

   log("Signature System " + PROGRAM_VERSION + " started.");
   log("GLOBAL_testing: "+GLOBAL_testing);
   log("GLOBAL_pausetime: "+GLOBAL_pausetime);
   log("GLOBAL_goalminnumberofcases: "+GLOBAL_goalminnumberofcases);
   log("GLOBAL_goalminrating: "+GLOBAL_goalminrating);
   log("GLOBAL_goalspreadfactor: "+GLOBAL_goalspreadfactor);
   log("GLOBAL_riskpertradepercentage: "+GLOBAL_riskpertradepercentage);
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
     
   GLOBAL_timeframe              = DAY;            //In Minutes. The timeframe to look at for signatures.
   GLOBAL_minitimeframe          = HOUR;           //In Minutes. The timeframe for judging success of a signature, must be less than the main timeframe.
   GLOBAL_cronincrement          = MINUTE * 15;    //In Minutes. What time frame to run the smallest cron task
   
   GLOBAL_isdemo                 = IsDemo();
   GLOBAL_riskpertradeamount     = AccountBalance() * GLOBAL_riskpertradepercentage;
   GLOBAL_dumporderarray_file    = AccountNumber()+"-orders.csv";

   ACCOUNT_previousbalance       = AccountBalance();
   
   TIME_currentweek              = iTime(Symbol(), PERIOD_W1, 0);
   TIME_currentday               = iTime(Symbol(), PERIOD_D1, 0);
   TIME_currenthour              = iTime(Symbol(), PERIOD_H1, 0);
   TIME_currentincrement         = iTime(Symbol(), GLOBAL_cronincrement, 0);
   TIME_weekcrontime             = 10 * 60;
   TIME_daycrontime              = 5 * 60;
   TIME_hourcrontime             = 2 * 60;
   TIME_incrementcrontime        = 1;
   TIME_weekended                = FALSE;
   TIME_dayended                 = FALSE;
   TIME_hourended                = FALSE;
   TIME_incrementended           = FALSE;
   
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

//+------------------------------------------------------------------+
//| start function                                                   |
//+------------------------------------------------------------------+
int start(){

   cron_update();
  
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
   
   order_closeout();
   account_update();
   
   //^---------------------
   TIME_dayended = TRUE;
   function_end();
}

void cron_newday(){
   function_start("cron_newday", true);
   
   log("Starting Day");
   //v---------------------
   
   order_send();
   order_dumporderarray();
   
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

void cron_endincrement(){
   function_start("cron_endincrement", true);
   
   log("Ending Increment");
   //v---------------------
   
   if(GLOBAL_testing == true){
      order_closeout();
      account_update();
   }

   //^---------------------
   TIME_incrementended = TRUE;
   
   function_end();
}

void cron_newincrement(){
   function_start("cron_newincrement", true);
   
   log("Starting Increment");
   //v---------------------
   
   signature_clearsumarray();
   signature_createsumarray();
   order_createorderarray();
   updatedisplay(1);
   
   if(GLOBAL_testing == true){
      order_send();
      order_dumporderarray();
   }
   
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
      FUNCVAR_accountchangepercentage = ((AccountBalance() / ACCOUNT_previousbalance+0.0000000000001)-1)*100;
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

void updatedisplay(int FUNCGET_sumororder = 0){
   function_start("updatedisplay", true);

   int 
      FUNCVAR_counter
      ;
   string 
      FUNCVAR_text,
      FUNCVAR_aprepend,
      FUNCVAR_orderpropend
      ;
   
   ObjectsDeleteAll();
      
   switch(FUNCGET_sumororder){
      case 1:
         for(FUNCVAR_counter=0;FUNCVAR_counter<100;FUNCVAR_counter++){
            if(FUNCVAR_counter<10){
               FUNCVAR_aprepend = "0";
            }else{
               FUNCVAR_aprepend = "";
            }
            if(SIGNATURE_SUM_order[FUNCVAR_counter] == "OP_SELL"){
               FUNCVAR_orderpropend = "";
            }else{
               FUNCVAR_orderpropend = " ";
            }
      
            if(StringLen(SIGNATURE_SUM_order[FUNCVAR_counter]) > 1){
               FUNCVAR_text = 
                  FUNCVAR_aprepend+FUNCVAR_counter+ ") "+
                  SIGNATURE_SUM_pair[FUNCVAR_counter]+" "+
                  SIGNATURE_SUM_signature[FUNCVAR_counter]+" "+
                  StringSubstr(SIGNATURE_SUM_target[FUNCVAR_counter]+"     ",0,4)+" "+
                  StringSubstr(SIGNATURE_SUM_targetdistance[FUNCVAR_counter]+"     ",0,7)+" "+
                  StringSubstr(SIGNATURE_SUM_order[FUNCVAR_counter]+"     ",0,7)+" "+
                  StringSubstr(SIGNATURE_SUM_total_result[FUNCVAR_counter]+"     ",0,4)+" "+
                  StringSubstr(MathAbs(SIGNATURE_SUM_total_rating[FUNCVAR_counter])+"     ",0,6)+" "+
                  StringSubstr(SIGNATURE_SUM_total_result[FUNCVAR_counter]*MathAbs(SIGNATURE_SUM_total_rating[FUNCVAR_counter])+"     ",0,6);
            }else{
               FUNCVAR_text=" ";
            }
            ObjectCreate("heading", OBJ_LABEL, 0, 0, 0);
            ObjectSet("heading", OBJPROP_XDISTANCE, 20);
            ObjectSet("heading", OBJPROP_YDISTANCE, 5);
            ObjectSetText("heading", "    Pair   Sig      Aim  Dist    Order   Rslt Rtrn   Rating" , 9, "Courier New", Black);
           
            ObjectCreate("text"+FUNCVAR_counter, OBJ_LABEL, 0, 0, 0);
            ObjectSet("text"+FUNCVAR_counter, OBJPROP_XDISTANCE, 20);
            ObjectSet("text"+FUNCVAR_counter, OBJPROP_YDISTANCE, 15 + 10*FUNCVAR_counter);
            ObjectSet("text"+FUNCVAR_counter, OBJPROP_WIDTH, 400);
            ObjectSetText("text"+FUNCVAR_counter, FUNCVAR_text, 9, "Courier New", Black);
         }
         break;
      default:
         for(FUNCVAR_counter=0;FUNCVAR_counter<100;FUNCVAR_counter++){
            if(FUNCVAR_counter<10){
               FUNCVAR_aprepend = "0";
            }else{
               FUNCVAR_aprepend = "";
            }
            if(ORDERS_order[FUNCVAR_counter] == "OP_SELL"){
               FUNCVAR_orderpropend = "";
            }else{
               FUNCVAR_orderpropend = " ";
            }
      
            if(StringLen(ORDERS_order[FUNCVAR_counter]) > 1){
               FUNCVAR_text = 
                  FUNCVAR_aprepend+FUNCVAR_counter+ ") "+
                  ORDERS_pair[FUNCVAR_counter]+" "+
                  ORDERS_order[FUNCVAR_counter]+FUNCVAR_orderpropend+" "+
                  StringSubstr(ORDERS_target[FUNCVAR_counter]+" ", 0, 4)
                  ;
            }else{
               FUNCVAR_text = " ";
            }
            ObjectCreate("heading", OBJ_LABEL,0, 0, 0);
            ObjectSet("heading", OBJPROP_XDISTANCE, 20);
            ObjectSet("heading", OBJPROP_YDISTANCE, 5);
            ObjectSetText("heading", "    Pair   Order   Trgt" , 9, "Courier New", Black);
            
            ObjectCreate("text"+FUNCVAR_counter, OBJ_LABEL, 0, 0, 0);
            ObjectSet("text"+FUNCVAR_counter, OBJPROP_XDISTANCE, 20);
            ObjectSet("text"+FUNCVAR_counter, OBJPROP_YDISTANCE, 15 + 10*FUNCVAR_counter);
            ObjectSet("text"+FUNCVAR_counter, OBJPROP_WIDTH, 400);
            ObjectSetText("text"+FUNCVAR_counter, FUNCVAR_text, 9, "Courier New", Black);
         }
         break;
   }
   ObjectCreate("col2l1", OBJ_LABEL, 0, 0, 0);
   ObjectSet("col2l1", OBJPROP_XDISTANCE, 430);
   ObjectSet("col2l1", OBJPROP_YDISTANCE, 5);
   ObjectSetText("col2l1", " Time till new day: "+(iTime(Symbol(), PERIOD_D1, 0) + 60*60*24 - TimeCurrent())+" s / "+( (iTime(Symbol(), PERIOD_D1, 0) + 60*60*24 - TimeCurrent()) /60 )+" min / "+( (iTime(Symbol(), PERIOD_D1, 0) + 60*60*24 - TimeCurrent()) /60 /60 )+" hours" , 9, "Courier New", Gray);
   
   GetLastError(); //Clear error associated with objects as they are not important.

   function_end();
}


//+------------------------------------------------------------------+
//| order functions                                                  |
//+------------------------------------------------------------------+

void order_createorderarray(){
   function_start("order_createorderarray", true);

   int 
      FUNCVAR_sumindex
      ;
   double 
      FUNCVAR_sortablearray[100,3]
      ;
   
   for(int a=0;a<100;a++){
      ORDERS_target[a] = 0;
      ORDERS_pair[a] = "";
      ORDERS_order[a] = "";
      ORDERS_signature[a] = 0;
      ORDERS_rating[a] = 0;
      ORDERS_noninverse_rating[a] = 0;
      ORDERS_pair_rating[a] = 0;
      ORDERS_recent_rating[a] = 0;
      ORDERS_choice[a] = 0;
      ORDERS_ticket[a] = 0;
      FUNCVAR_sortablearray[a,0] = 0;
      FUNCVAR_sortablearray[a,1] = 0;
   }
   
   for(a=0;a<GLOBAL_currentnumberoforders;a++){
      FUNCVAR_sortablearray[a,0] = MathAbs(SIGNATURE_SUM_total_rating[a]);
      FUNCVAR_sortablearray[a,1] = a;
   }
   
   ArraySort(FUNCVAR_sortablearray, WHOLE_ARRAY, 0, MODE_DESCEND);
     
   for(a=0;a<GLOBAL_currentnumberoforders;a++){
      FUNCVAR_sumindex = FUNCVAR_sortablearray[a,1];
      log(FUNCVAR_sortablearray[a,0]+" "+FUNCVAR_sortablearray[a,1]+" "+SIGNATURE_SUM_pair[FUNCVAR_sumindex]);
      ORDERS_target[a] = SIGNATURE_SUM_target[FUNCVAR_sumindex];
      ORDERS_pair[a] = SIGNATURE_SUM_pair[FUNCVAR_sumindex];
      ORDERS_order[a] = SIGNATURE_SUM_order[FUNCVAR_sumindex];
      ORDERS_signature[a] = SIGNATURE_SUM_signature[FUNCVAR_sumindex];
      ORDERS_rating[a] = SIGNATURE_SUM_total_result[FUNCVAR_sumindex]; //Changing names between arrays
      ORDERS_cases[a] = SIGNATURE_SUM_total_cases[FUNCVAR_sumindex]; //Changing names between arrays. Probably should fix these...
      ORDERS_return[a] = SIGNATURE_SUM_total_rating[FUNCVAR_sumindex]; //Changing names between arrays
      ORDERS_noninverse_rating[a] = SIGNATURE_SUM_noninverse_rating[FUNCVAR_sumindex];
      ORDERS_recent_rating[a] = SIGNATURE_SUM_recent_rating[FUNCVAR_sumindex];
      ORDERS_choice[a] = a;
   }
   
   log("Created and sorted "+GLOBAL_currentnumberoforders+" orders");
   
   function_end();
}

void order_send(){
   function_start("order_send", true);
   
   int
      FUNCVAR_count,
      FUNCVAR_errornumber
      ;
   double 
      FUNCVAR_target
      ;

   //v Order Variables
   int
      FUNCVAR_magicnumber,
      FUNCVAR_slippage,
      FUNCVAR_cmd,
      FUNCVAR_ticket,
      FUNCVAR_attempt
      ;
   double
      FUNCVAR_volume,
      FUNCVAR_price,
      FUNCVAR_stoploss,
      FUNCVAR_takeprofit
      ;  
   string
      FUNCVAR_symbol,
      FUNCVAR_comment
      ;
   //^
   log("Opening Positions");
   
   ORDERS_targetaccounttrisk = GLOBAL_riskpertradeamount;
   
   for(FUNCVAR_count=0;FUNCVAR_count<GLOBAL_currentnumberoforders;FUNCVAR_count++){
      FUNCVAR_symbol = ORDERS_pair[FUNCVAR_count];
      if(GLOBAL_testing){
         FUNCVAR_target = MarketInfo(FUNCVAR_symbol, MODE_STOPLEVEL)*MarketInfo(FUNCVAR_symbol, MODE_POINT)*1.5;
      }else{
         FUNCVAR_target = ORDERS_target[FUNCVAR_count] * getinfo(7, FUNCVAR_symbol, GLOBAL_timeframe, 1);
      }
      FUNCVAR_volume = order_getlotsize(FUNCVAR_target, FUNCVAR_symbol);
      FUNCVAR_slippage = 2;
      FUNCVAR_comment = ORDERS_target[FUNCVAR_count];
      FUNCVAR_magicnumber = dateindex(iTime(ORDERS_pair[FUNCVAR_count], PERIOD_D1, 0)+60*60*24) + FUNCVAR_count;
     
      FUNCVAR_attempt = 1;
      FUNCVAR_ticket = -1;
      
      while(FUNCVAR_ticket < 0 && FUNCVAR_attempt < 6 && FUNCVAR_volume > 0){
         if(ORDERS_order[FUNCVAR_count] == "OP_SELL"){
            FUNCVAR_cmd = 1;
            FUNCVAR_price = MarketInfo(FUNCVAR_symbol, MODE_BID);
            FUNCVAR_stoploss = FUNCVAR_price + FUNCVAR_target;
            FUNCVAR_takeprofit = FUNCVAR_price - FUNCVAR_target;
         }else{
            FUNCVAR_cmd = 0;
            FUNCVAR_price = MarketInfo(FUNCVAR_symbol, MODE_ASK);
            FUNCVAR_stoploss = FUNCVAR_price - FUNCVAR_target;
            FUNCVAR_takeprofit = FUNCVAR_price + FUNCVAR_target;
         }
      
         FUNCVAR_ticket = OrderSend(FUNCVAR_symbol, FUNCVAR_cmd, FUNCVAR_volume, FUNCVAR_price, FUNCVAR_slippage, FUNCVAR_stoploss, FUNCVAR_takeprofit, FUNCVAR_comment, FUNCVAR_magicnumber);
         if(FUNCVAR_ticket < 0){
            FUNCVAR_errornumber = GetLastError();
            log("Order failed attempt "+FUNCVAR_attempt+": "+FUNCVAR_symbol+" "+FUNCVAR_cmd+" "+FUNCVAR_volume+" "+FUNCVAR_price+" "+FUNCVAR_slippage+" "+FUNCVAR_stoploss+" "+FUNCVAR_takeprofit+" "+FUNCVAR_comment+" "+FUNCVAR_magicnumber);
            log("Order failed with error #"+FUNCVAR_errornumber+" - "+ErrorDescription(FUNCVAR_errornumber));
            Sleep(GLOBAL_pausetime);
            FUNCVAR_attempt++;
            RefreshRates();
         }
      }
      if(FUNCVAR_attempt == 6){
         //TODO: This is a big issue, need to notify!
         log("Order unable to be opened.");
      }else{
         log("Ordered: "+FUNCVAR_symbol+" "+FUNCVAR_cmd+" "+FUNCVAR_volume+" "+FUNCVAR_price+" "+FUNCVAR_slippage+" "+FUNCVAR_stoploss+" "+FUNCVAR_takeprofit+" "+FUNCVAR_comment+" "+FUNCVAR_magicnumber);
         ORDERS_ticket[FUNCVAR_count] = FUNCVAR_ticket;
      }
   }
   ACCOUNT_totalnumberoforders = GLOBAL_currentnumberoforders;
   log("END Opening Positions");
   
   function_end();
}

double order_getlotsize(double FUNCGET_target, string FUNCGET_currency){
   function_start("order_getlotsize", true);
   
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
   if(FUNCVAR_ticksize > 0 && FUNCVAR_tickvalue > 0){
      FUNCVAR_targetinticks = FUNCGET_target / FUNCVAR_ticksize;
      FUNCVAR_lots = (GLOBAL_riskpertradeamount / FUNCVAR_targetinticks) / FUNCVAR_tickvalue;
   }
   if(FUNCVAR_lots == 0){
      log("Error calculating lot size. Currency:"+FUNCGET_currency+" Target:"+FUNCGET_target+" Ticksize:"+FUNCVAR_ticksize+" Tickvalue:"+FUNCVAR_tickvalue);
      function_end();
      return(0);
   }
   
   function_end();
   return(FUNCVAR_lots);
}

void order_closeout(){
   function_start("order_closeout", true);
   int
      FUNCVAR_count,
      FUNCVAR_attempt,
      FUNCVAR_errornumber,
      FUNCVAR_ticketnumber
      ;
   bool
      FUNCVAR_ticket
      ;
      
   log("Closing Positions");
   ACCOUNT_numberofclosedorders = OrdersTotal();
   ACCOUNT_closedordersprofit = 0;
   for(FUNCVAR_count=0; FUNCVAR_count < ACCOUNT_numberofclosedorders; FUNCVAR_count++) {
      OrderSelect(0, SELECT_BY_POS, MODE_TRADES);

      FUNCVAR_attempt = 1;
      FUNCVAR_ticket = FALSE;
      FUNCVAR_ticketnumber = OrderTicket();
      ACCOUNT_closedordersprofit = ACCOUNT_closedordersprofit + OrderProfit();
   
      while(FUNCVAR_ticket == FALSE && FUNCVAR_attempt < 6){
         if(OrderType() == OP_SELL){
            FUNCVAR_ticket = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 200);
         }else if(OrderType() == OP_BUY){
            FUNCVAR_ticket = OrderClose(OrderTicket(),OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 200);
         }
         if(FUNCVAR_ticket == FALSE){
            FUNCVAR_errornumber = GetLastError();
            log("Closing Order failed attempt "+FUNCVAR_attempt+": "+OrderTicket()+" "+OrderLots()+" "+MarketInfo(OrderSymbol(), MODE_ASK)+" "+"200");
            log("Closing Order failed with error #"+FUNCVAR_errornumber+" - "+ErrorDescription(FUNCVAR_errornumber));
            Sleep(GLOBAL_pausetime);
            FUNCVAR_attempt++;
            RefreshRates();
         }
      }
      if(FUNCVAR_attempt == 6){
         //TODO: This is a big issue, need to notify!
         log("Order unable to be closed.");
      }else{
         log("Order "+FUNCVAR_ticketnumber+" closed");
      }
    }
    log("END Closing Positions");

   function_end();
}

void order_dumporderarray(string FUNCGET_filename = "NULL"){
   function_start("order_dumporderarray", true);
   
   int
      FUNCVAR_file,
      FUNCVAR_counter
      ;

   string FUNCVAR_noheader[0];
   FUNCVAR_file = openafile(GLOBAL_dumporderarray_file, FUNCVAR_noheader);
   
   log("Dumping Current Order Array"); 
   for(FUNCVAR_counter=0; FUNCVAR_counter<100; FUNCVAR_counter++){
      if(ORDERS_ticket[FUNCVAR_counter] > 0){
         FileWrite(FUNCVAR_file,
            ORDERS_ticket[FUNCVAR_counter],
            ORDERS_pair[FUNCVAR_counter],
            ORDERS_target[FUNCVAR_counter],
            ORDERS_targetaccounttrisk,
            ORDERS_signature[FUNCVAR_counter],
            ORDERS_rating[FUNCVAR_counter],
            ORDERS_cases[FUNCVAR_counter],
            ORDERS_return[FUNCVAR_counter],
            ORDERS_noninverse_rating[FUNCVAR_counter],
            ORDERS_pair_rating[FUNCVAR_counter],
            ORDERS_recent_rating[FUNCVAR_counter],
            ORDERS_choice[FUNCVAR_counter],
            "");
      }
   }
      
   function_end();

}

//+------------------------------------------------------------------+
//| signature functions                                              |
//+------------------------------------------------------------------+
void signature_createsumarray(int FUNCGET_barnumber = 0){
   function_start("signature_createsumarray", true);
   
   int
      FUNCVAR_targetcounter,
      FUNCVAR_targetindex
      ;
   string
      FUNCVAR_signature,
      FUNCVAR_currentpair
      ;
   for(int a=0;a<CURRENCY_numberofpairs;a++){
      FUNCVAR_currentpair = CURRENCY_pairs[a];
      FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber + 1) + signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber);
      SIGNATURE_SUM_barnumber = FUNCGET_barnumber;
      SIGNATURE_SUM_date = iTime(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber);
      signature_setsignaturearray(FUNCVAR_signature, FUNCVAR_currentpair, FUNCGET_barnumber);
      FUNCVAR_targetindex = signature_testsignaturearray(FUNCVAR_currentpair);
      if(FUNCVAR_targetindex >= 0){
         signature_addsignaturetosum(FUNCVAR_targetindex, FUNCVAR_currentpair);
      }
   }
   
   function_end();
}

void signature_setsignaturearray(string FUNCGET_signature, string FUNCGET_pair, int FUNCGET_barnumber = 0){
   function_start("signature_setsignaturearray", true);
   
   int
      FUNCVAR_barnumberloop,
      FUNCVAR_positivehit,
      FUNCVAR_negativehit,
      FUNCVAR_targetcounter
      ;
   
   double
      FUNCVAR_positive,
      FUNCVAR_negative,
      FUNCVAR_closeout,
      FUNCVAR_return,
      FUNCVAR_pointtarget,
      FUNCVAR_ratingholder
      ;
      
   string
      FUNCVAR_currentpair,
      FUNCVAR_signature;
   
   for(int a=0;a<ArraySize(GLOBAL_targetpercentages);a++){
      SIGNATURE_signature[a] = "";
      SIGNATURE_RECENT_cases[a] = 0;
      SIGNATURE_RECENT_result[a] = 0;
      SIGNATURE_TOTAL_cases[a] = 0;
      SIGNATURE_TOTAL_result[a] = 0;
      SIGNATURE_NONINVERSE_cases[a] = 0;
      SIGNATURE_NONINVERSE_result[a] = 0;
   }


   SIGNATURE_RECENT_datemin = TimeCurrent();
   SIGNATURE_RECENT_datemax = 0;     
   for(a=0;a<CURRENCY_numberofpairs;a++){
      FUNCVAR_currentpair = CURRENCY_allpairs[a];
       for(FUNCVAR_barnumberloop=FUNCGET_barnumber + 2;FUNCVAR_barnumberloop < CURRENCY_allpairslookback[a]-2;FUNCVAR_barnumberloop++){ //Start looking at data 2 bars back from the bar we're looking at and 2 bars before the end of the data
         //v Construct the basic signature for this reference
         FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop + 1) + signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop);
         //^
         
         if(
            FUNCVAR_signature == FUNCGET_signature //||
            //signature_invert(FUNCVAR_signature) == FUNCGET_signature
         ){
            
            for(FUNCVAR_targetcounter=0;FUNCVAR_targetcounter < ArraySize(GLOBAL_targetpercentages); FUNCVAR_targetcounter++){
               
               FUNCVAR_pointtarget = getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop) * GLOBAL_targetpercentages[FUNCVAR_targetcounter];
               
               if(FUNCVAR_signature == FUNCGET_signature){
                  FUNCVAR_positive = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) + FUNCVAR_pointtarget;
                  FUNCVAR_negative = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - FUNCVAR_pointtarget;
                  FUNCVAR_positivehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumberloop - 1, FUNCVAR_positive );
                  FUNCVAR_negativehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumberloop - 1, FUNCVAR_negative );
               }else{ // Check the inverse
                  FUNCVAR_negative = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) + FUNCVAR_pointtarget;
                  FUNCVAR_positive = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - FUNCVAR_pointtarget;
                  FUNCVAR_negativehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumberloop - 1, FUNCVAR_negative );
                  FUNCVAR_positivehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumberloop - 1, FUNCVAR_positive );
               }
               
               FUNCVAR_return = signature_decipherwinner(FUNCVAR_positivehit, FUNCVAR_negativehit);
             
               SIGNATURE_signature[FUNCVAR_targetcounter] = FUNCGET_signature;
               
               //v Choose which sub-signatures to count this entry towards 
               if(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop) > getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber) - GLOBAL_recentlookback){
                  SIGNATURE_RECENT_cases[FUNCVAR_targetcounter]++;
                  SIGNATURE_RECENT_result[FUNCVAR_targetcounter] = SIGNATURE_RECENT_result[FUNCVAR_targetcounter] + FUNCVAR_return;
                  if(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop) < SIGNATURE_RECENT_datemin){
                     SIGNATURE_RECENT_datemin = getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop);
                  }
                  if(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop) > SIGNATURE_RECENT_datemax){
                     SIGNATURE_RECENT_datemax = getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop);
                  }
               }
               
               SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter]++;
               SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] = SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] + FUNCVAR_return;

               if(FUNCVAR_signature == FUNCGET_signature){
                  SIGNATURE_NONINVERSE_cases[FUNCVAR_targetcounter]++;
                  SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] = SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] + FUNCVAR_return;
               }
            
               //^ 
                              
            } //End For target loop
            
         } //End FUNCVAR_signature == FUNCGET_signature logic
                  
      } //For
   }
   
   function_end();
}


void signature_addsignaturetosum(int FUNCGET_target, string FUNCGET_pair){
   function_start("signature_addsignaturetosum", true);
   
   
   SIGNATURE_SUM_pair[GLOBAL_currentnumberoforders] = FUNCGET_pair;
   SIGNATURE_SUM_signature[GLOBAL_currentnumberoforders] = SIGNATURE_signature[FUNCGET_target];
   SIGNATURE_SUM_target[GLOBAL_currentnumberoforders] = GLOBAL_targetpercentages[FUNCGET_target];
   SIGNATURE_SUM_targetdistance[GLOBAL_currentnumberoforders] = getinfo(7, FUNCGET_pair, GLOBAL_timeframe, SIGNATURE_SUM_barnumber) * GLOBAL_targetpercentages[FUNCGET_target];

   if(SIGNATURE_RECENT_cases[FUNCGET_target] > 0){
      SIGNATURE_SUM_recent_rating[GLOBAL_currentnumberoforders] = (SIGNATURE_RECENT_result[FUNCGET_target]+0.0) / (SIGNATURE_RECENT_cases[FUNCGET_target]+0.0);
      SIGNATURE_SUM_recent_cases[GLOBAL_currentnumberoforders] = SIGNATURE_RECENT_cases[FUNCGET_target];
      SIGNATURE_SUM_recent_result[GLOBAL_currentnumberoforders] = MathAbs(SIGNATURE_RECENT_result[FUNCGET_target]);
      SIGNATURE_SUM_recent_datemin[GLOBAL_currentnumberoforders] = SIGNATURE_RECENT_datemin;
      SIGNATURE_SUM_recent_datemax[GLOBAL_currentnumberoforders] = SIGNATURE_RECENT_datemax;
   }
   
   if(SIGNATURE_TOTAL_cases[FUNCGET_target] > 0){
      SIGNATURE_SUM_total_rating[GLOBAL_currentnumberoforders] = (SIGNATURE_TOTAL_result[FUNCGET_target]+0.0) / (SIGNATURE_TOTAL_cases[FUNCGET_target]+0.0);
      SIGNATURE_SUM_total_cases[GLOBAL_currentnumberoforders] = SIGNATURE_TOTAL_cases[FUNCGET_target];
      SIGNATURE_SUM_total_result[GLOBAL_currentnumberoforders] = MathAbs(SIGNATURE_TOTAL_result[FUNCGET_target]);
   }
   
   if(SIGNATURE_NONINVERSE_cases[FUNCGET_target] > 0){
      SIGNATURE_SUM_noninverse_rating[GLOBAL_currentnumberoforders] = (SIGNATURE_NONINVERSE_result[FUNCGET_target]+0.0) / (SIGNATURE_NONINVERSE_cases[FUNCGET_target]+0.0);
      SIGNATURE_SUM_noninverse_cases[GLOBAL_currentnumberoforders] = SIGNATURE_NONINVERSE_cases[FUNCGET_target];
      SIGNATURE_SUM_noninverse_result[GLOBAL_currentnumberoforders] = MathAbs(SIGNATURE_NONINVERSE_result[FUNCGET_target]);
   }
   
   if(SIGNATURE_SUM_recent_rating[GLOBAL_currentnumberoforders] > 0){
      SIGNATURE_SUM_order[GLOBAL_currentnumberoforders] = "OP_BUY";
      GLOBAL_currentnumberoforders++;
   }else if(SIGNATURE_SUM_recent_rating[GLOBAL_currentnumberoforders] < 0){
      SIGNATURE_SUM_order[GLOBAL_currentnumberoforders] = "OP_SELL";
      GLOBAL_currentnumberoforders++;
   }else{
      SIGNATURE_SUM_order[GLOBAL_currentnumberoforders] = "";
   }
   
   function_end();
}


int signature_testsignaturearray(string FUNCGET_pair){
   function_start("signature_testsignaturearray", true);
   
   int
      FUNCVAR_targetcounter,
      FUNCVAR_besttarget = -1
      ;
   double
      FUNCVAR_bestrating = 0,
      FUNCVAR_currentrating = 0
      ;
   
   for(FUNCVAR_targetcounter=0;FUNCVAR_targetcounter < ArraySize(GLOBAL_targetpercentages); FUNCVAR_targetcounter++){
      if(SIGNATURE_RECENT_cases[FUNCVAR_targetcounter] != 0){
         FUNCVAR_currentrating = (SIGNATURE_RECENT_result[FUNCVAR_targetcounter]+0.0) / (SIGNATURE_RECENT_cases[FUNCVAR_targetcounter]+0.0);
      }else{
         FUNCVAR_currentrating = 0;
      }
        
      if( //Decide if signature can be added to sum array
         MathAbs(FUNCVAR_currentrating) > MathAbs(FUNCVAR_bestrating) && // Not >= as the larger the distance, the smaller the lot, the smaller the spread percentage and used margin
         MathAbs(FUNCVAR_currentrating) >= GLOBAL_goalminrating && 
         SIGNATURE_RECENT_cases[FUNCVAR_targetcounter] >= GLOBAL_goalminnumberofcases //&&
         //getinfo(7, FUNCGET_pair, GLOBAL_timeframe, SIGNATURE_SUM_barnumber) * GLOBAL_targetpercentages[FUNCVAR_targetcounter] > GLOBAL_goalspreadfactor * getinfo(502, FUNCGET_pair, GLOBAL_timeframe, 1)
      ){
         FUNCVAR_bestrating = FUNCVAR_currentrating;
         FUNCVAR_besttarget = FUNCVAR_targetcounter;
      }
   }
   
   function_end();
   return(FUNCVAR_besttarget);
}


void signature_createsumarrayresults(){
   function_start("signature_createsumarrayresults", true);
   
   int
      FUNCVAR_counter,
      FUNCVAR_barnumber,
      FUNCVAR_windirection
      ;
   double
      FUNCVAR_positive,
      FUNCVAR_negative,
      FUNCVAR_positivehit,
      FUNCVAR_negativehit,
      FUNCVAR_positivespreadmax,
      FUNCVAR_negativespreadmax
      ;
     
   for(FUNCVAR_counter=0; FUNCVAR_counter < GLOBAL_currentnumberoforders; FUNCVAR_counter++){
      FUNCVAR_barnumber = iBarShift(SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, SIGNATURE_SUM_date);
      if(SIGNATURE_SUM_order[FUNCVAR_counter] == "OP_BUY"){
         FUNCVAR_positive = getinfo(1, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber - 1) + SIGNATURE_SUM_targetdistance[FUNCVAR_counter];
         FUNCVAR_negative = getinfo(1, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber - 1) - (SIGNATURE_SUM_targetdistance[FUNCVAR_counter] + (getinfo(502, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber)) ); //incorporate spread to the negative target
      }else{
         FUNCVAR_positive = getinfo(1, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber - 1) + (SIGNATURE_SUM_targetdistance[FUNCVAR_counter] - (getinfo(502, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber)) ); //incorporate spread to the positive target
         FUNCVAR_negative = getinfo(1, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber - 1) - SIGNATURE_SUM_targetdistance[FUNCVAR_counter];      
      }
      FUNCVAR_positivehit = signature_getfirsthighinstance(SIGNATURE_SUM_pair[FUNCVAR_counter], FUNCVAR_barnumber - 1, FUNCVAR_positive );
      FUNCVAR_negativehit = signature_getfirstlowinstance(SIGNATURE_SUM_pair[FUNCVAR_counter], FUNCVAR_barnumber - 1, FUNCVAR_negative );
      FUNCVAR_windirection = signature_decipherwinner(FUNCVAR_positivehit, FUNCVAR_negativehit);
      
      SIGNATURE_SUM_targetpositive[FUNCVAR_counter] = FUNCVAR_positive;
      SIGNATURE_SUM_targetnegative[FUNCVAR_counter] = FUNCVAR_negative;
      if(
         (SIGNATURE_SUM_order[FUNCVAR_counter] == "OP_BUY" && FUNCVAR_windirection == 1) ||
         (SIGNATURE_SUM_order[FUNCVAR_counter] == "OP_SELL" && FUNCVAR_windirection == -1)
      ){
         SIGNATURE_SUM_win[FUNCVAR_counter] = 1;
      }else{
         SIGNATURE_SUM_win[FUNCVAR_counter] = -1;
      }
      if( FUNCVAR_windirection == 0){
         SIGNATURE_SUM_win[FUNCVAR_counter] = 0;
      }
   }
   
   function_end();
}

void signature_clearsumarray(){
   function_start("signature_clearsumarray", true);
   
   for(int a=0;a<100;a++){
      SIGNATURE_SUM_pair[a] = "";
      SIGNATURE_SUM_target[a] = 0;
      SIGNATURE_SUM_targetdistance[a] = 0;
      SIGNATURE_SUM_targetpositive[a] = 0;
      SIGNATURE_SUM_targetnegative[a] = 0;
      SIGNATURE_SUM_order[a] = "";
      SIGNATURE_SUM_recent_result[a] = 0;
      SIGNATURE_SUM_recent_rating[a] = 0;
      SIGNATURE_SUM_recent_cases[a] = 0;
      SIGNATURE_SUM_recent_datemin[a] = 0;
      SIGNATURE_SUM_recent_datemax[a] = 0;
      SIGNATURE_SUM_total_result[a] = 0;
      SIGNATURE_SUM_total_rating[a] = 0;
      SIGNATURE_SUM_total_cases[a] = 0;
      SIGNATURE_SUM_noninverse_result[a] = 0;
      SIGNATURE_SUM_noninverse_rating[a] = 0;
      SIGNATURE_SUM_noninverse_cases[a] = 0;
   }
   SIGNATURE_SUM_date = 0;
   GLOBAL_currentnumberoforders = 0;
   
   function_end();
}

void signature_dumpsumarray(){
   function_start("signature_dumpsumarray", true);
   
   int
      FUNCVAR_counter
      ;
        
   if(GLOBAL_dumpsumarraytitles == false){
      log(
         "Date"+";"+
         "Date"+";"+
         "TimeDayOfWeek"+";"+
         "SIGNATURE_SUM_pair"+";"+
         "getinfo(502)"+";"+
         "signature"+";"+
         "target"+";"+
         "targetdistance"+";"+
         "targetpositive"+";"+
         "targetnegative"+";"+
         "order"+";"+
         "recent_rating"+";"+
         "recent_result"+";"+
         "recent_cases"+";"+
         "datemin"+";"+
         "datemax"+";"+
         "total_result"+";"+
         "total_rating"+";"+
         "total_cases"+";"+
         "noninverse_result"+";"+
         "noninverse_rating"+";"+
         "noninverse_cases"+";"+
         "win"
      );
      GLOBAL_dumpsumarraytitles = true;
   }
   for(FUNCVAR_counter=0; FUNCVAR_counter < GLOBAL_currentnumberoforders; FUNCVAR_counter++){
      if(SIGNATURE_SUM_order[FUNCVAR_counter] != ""){
         log(
            humandate(SIGNATURE_SUM_date)+";"+
            SIGNATURE_SUM_date+";"+
            TimeDayOfWeek(SIGNATURE_SUM_date)+";"+
            SIGNATURE_SUM_pair[FUNCVAR_counter]+";"+
            getinfo(502, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, 1)*1.0+";"+
            SIGNATURE_SUM_signature[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_target[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_targetdistance[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_targetpositive[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_targetnegative[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_order[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_recent_rating[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_recent_result[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_recent_cases[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_recent_datemin[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_recent_datemax[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_total_rating[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_total_result[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_total_cases[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_noninverse_rating[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_noninverse_result[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_noninverse_cases[FUNCVAR_counter]+";"+
            SIGNATURE_SUM_win[FUNCVAR_counter]+";"+
         "");
      }
   }
      
   function_end();
}

string signature_getbarsignature(string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber){
   function_start("signature_getbarsignature");
   
   string 
      FUNCVAR_signature
      ;
   int
      FUNCVAR_passedint
      ;
   double
      FUNCVAR_range
      ;
   FUNCVAR_range = getinfo(7, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
   if(FUNCVAR_range > 0){
      FUNCVAR_passedint = MathFloor( 1 + ( ( getinfo(1, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) - getinfo(3, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) ) / FUNCVAR_range ) * 0.99999 / 20 * 100);
      FUNCVAR_signature = signature_getbarsignaturehelper(FUNCVAR_passedint);
      FUNCVAR_passedint = MathFloor( 1 + ( ( getinfo(4, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) - getinfo(3, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) ) / FUNCVAR_range ) * 0.99999 / 20 * 100);
      FUNCVAR_signature = FUNCVAR_signature + signature_getbarsignaturehelper(FUNCVAR_passedint);
   }else{
      log("No signature created due to 0 point range given");
   }
   if(StringLen(FUNCVAR_signature) != 4){
      log("Signature not correctly constructed: "+FUNCVAR_signature);
   }
   
   function_end();
   return(FUNCVAR_signature);

}

string signature_getbarsignaturehelper(int FUNCGET_passedint){
   function_start("signature_getbarsignaturehelper");
   
   switch(FUNCGET_passedint){
      case 1:
         function_end();
         return("1L");
         break;
      case 2:
         function_end();
         return("2L");
         break;
      case 3:
         function_end();
         return("3M");
         break;
      case 4:
         function_end();
         return("2H");
         break;
      case 5:
         function_end();
         return("1H");
         break;
      default:
         log("INCORRECT FUNCGET_passedint in function signature_getbarsignaturehelper given: "+FUNCGET_passedint+" ------------+");
   }
   
   function_end();
}

string signature_invert(string FUNCGET_signature){
   function_start("signature_invert");
   
   int 
      FUNCVAR_position
   ;
   FUNCVAR_position = 0;
   while(FUNCVAR_position > -1){
      FUNCVAR_position = StringFind(FUNCGET_signature, "L");
      if(FUNCVAR_position > -1){
         FUNCGET_signature = StringSetChar(FUNCGET_signature, FUNCVAR_position, 'T');
      }
   }
   FUNCVAR_position = 0;
   while(FUNCVAR_position > -1){
      FUNCVAR_position = StringFind(FUNCGET_signature, "H");
      if(FUNCVAR_position > -1){
         FUNCGET_signature = StringSetChar(FUNCGET_signature, FUNCVAR_position, 'L');
      }
   }
   FUNCVAR_position = 0;
   while(FUNCVAR_position > -1){
      FUNCVAR_position = StringFind(FUNCGET_signature, "T");
      if(FUNCVAR_position > -1){
         FUNCGET_signature = StringSetChar(FUNCGET_signature, FUNCVAR_position, 'H');
      }
   }
   
   function_end();
   return(FUNCGET_signature);
}

int signature_getfirsthighinstance(string FUNCGET_pair, int FUNCGET_barnumber, double FUNCGET_target){
   function_start("signature_getfirsthighinstance", true);
   
   int 
      FUNCVAR_counter,
      FUNCVAR_minibar = iBarShift(FUNCGET_pair, GLOBAL_minitimeframe, getinfo(5, FUNCGET_pair, GLOBAL_timeframe, FUNCGET_barnumber));
   
   if(FUNCVAR_minibar > 0){
      for(FUNCVAR_counter=0;FUNCVAR_counter < GLOBAL_timeframe / GLOBAL_minitimeframe - 1; FUNCVAR_counter++){
         if(FUNCVAR_minibar - FUNCVAR_counter >= 0){
            if(
               getinfo(2, FUNCGET_pair, GLOBAL_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) >= FUNCGET_target
            ){
               function_end();
               return(FUNCVAR_counter + 1);
            }
         }
      }
   }
   
   function_end();
   return(0);
}

int signature_getfirstlowinstance(string FUNCGET_pair, int FUNCGET_barnumber, double FUNCGET_target){
   function_start("signature_getfirstlowinstance", true);
   
   int 
      FUNCVAR_counter,
      FUNCVAR_minibar = iBarShift(FUNCGET_pair, GLOBAL_minitimeframe, getinfo(5, FUNCGET_pair, GLOBAL_timeframe, FUNCGET_barnumber))
      ;
      
   if(FUNCVAR_minibar > 0){
      for(FUNCVAR_counter=0;FUNCVAR_counter < GLOBAL_timeframe / GLOBAL_minitimeframe - 1; FUNCVAR_counter++){
         if(FUNCVAR_minibar - FUNCVAR_counter >= 0){
            if(
               getinfo(3, FUNCGET_pair, GLOBAL_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) <= FUNCGET_target
            ){
               function_end();
               return(FUNCVAR_counter + 1);
            }
         }
      }
   }
   
   function_end();
   return(0);
}

int signature_decipherwinner(int FUNCGET_positivehit, int FUNCGET_negativehit){
   function_start("signature_decipherwinner", true);
   
   if(
      (
      FUNCGET_negativehit > 0 && 
      FUNCGET_positivehit > 0 && 
      FUNCGET_positivehit < FUNCGET_negativehit 
      )||(
      FUNCGET_positivehit > 0 && 
      FUNCGET_negativehit == 0
      )
   ){
      function_end();
      return(1);
   }else if(
      (
      FUNCGET_negativehit > 0 && 
      FUNCGET_positivehit > 0 && 
      FUNCGET_negativehit < FUNCGET_positivehit
      )||(
      FUNCGET_negativehit > 0 &&
      FUNCGET_positivehit == 0
      )
   ){
      function_end();
      return(-1);
   }else{
      function_end();
      return(0);
   } 
   
   function_end();
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
      case 7: ///Range
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
      CURRENCY_usedentities[a] = " ";
      CURRENCY_allentities[a] = " ";
      CURRENCY_pairs[a] = " ";
      CURRENCY_allpairs[a] = " ";
   }
   CURRENCY_numberofpairs = 0;
   CURRENCY_numberofallpairs = 0;
   
   if(CURRENCY_USD){
      CURRENCY_usedentities[0] = "USD";
   }
   CURRENCY_allentities[0] = "USD";
   if(CURRENCY_CHF){
      CURRENCY_usedentities[1] = "CHF";
   }
   CURRENCY_allentities[1] = "CHF";
   if(CURRENCY_EUR){
      CURRENCY_usedentities[2] = "EUR";
   }
   CURRENCY_allentities[2] = "EUR";
   if(CURRENCY_GBP){
      CURRENCY_usedentities[3] = "GBP";
   }
   CURRENCY_allentities[3] = "GBP";
   if(CURRENCY_CAD){
      CURRENCY_usedentities[4] = "CAD";
   }
   CURRENCY_allentities[4] = "CAD";   
   if(CURRENCY_JPY){
      CURRENCY_usedentities[5] = "JPY";
   }
   CURRENCY_allentities[5] = "JPY";   
   if(CURRENCY_AUD){
      CURRENCY_usedentities[6] = "AUD";
   }
   CURRENCY_allentities[6] = "AUD";   
   if(CURRENCY_NZD){
      CURRENCY_usedentities[7] = "NZD";
   }
   CURRENCY_allentities[7] = "NZD";
   if(CURRENCY_SGD){
      CURRENCY_usedentities[8] = "SGD";
   } 
   CURRENCY_allentities[8] = "SGD";  
   if(CURRENCY_HKD){
      CURRENCY_usedentities[9] = "HKD";
   }
   CURRENCY_allentities[9] = "HKD";   
   if(CURRENCY_DKK){
      CURRENCY_usedentities[10] = "DKK";
   }
   CURRENCY_allentities[10] = "DKK";   
   if(CURRENCY_NOK){
      CURRENCY_usedentities[11] = "NOK";
   }
   CURRENCY_allentities[11] = "NOK";
   if(CURRENCY_SEK){
      CURRENCY_usedentities[12] = "SEK";
   }
   CURRENCY_allentities[12] = "SEK";   
   if(CURRENCY_TRY){
      CURRENCY_usedentities[13] = "TRY";
   }
   CURRENCY_allentities[13] = "TRY";   
   if(CURRENCY_PLN){
      CURRENCY_usedentities[14] = "PLN";
   }
   CURRENCY_allentities[14] = "PLN";   
   if(CURRENCY_MXN){
      CURRENCY_usedentities[15] = "MXN";
   }
   CURRENCY_allentities[15] = "MXN";
   if(CURRENCY_XAU){
      CURRENCY_usedentities[16] = "XAU";
   }
   CURRENCY_allentities[16] = "XAU";   
   if(CURRENCY_XAG){
      CURRENCY_usedentities[17] = "XAG";
   }
   CURRENCY_allentities[17] = "XAG";      
   
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < 100; FUNCVAR_basecurrency++){
      for(FUNCVAR_countercurrency = 0; FUNCVAR_countercurrency < 100; FUNCVAR_countercurrency++){
         FUNCVAR_currentpair = CURRENCY_allentities[FUNCVAR_basecurrency] + CURRENCY_allentities[FUNCVAR_countercurrency];
         if(
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1
         ){
            CURRENCY_allpairs[CURRENCY_numberofallpairs] = FUNCVAR_currentpair;
            CURRENCY_numberofallpairs++;
         }
         GetLastError();
      }
   }
   
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < 100; FUNCVAR_basecurrency++){
      for(FUNCVAR_countercurrency = 0; FUNCVAR_countercurrency < 100; FUNCVAR_countercurrency++){
         FUNCVAR_currentpair = CURRENCY_usedentities[FUNCVAR_basecurrency] + CURRENCY_usedentities[FUNCVAR_countercurrency];
         if(
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1 &&
            StringFind(CURRENCY_skippairs, FUNCVAR_currentpair) < 0
         ){
            CURRENCY_pairs[CURRENCY_numberofpairs] = FUNCVAR_currentpair;
            CURRENCY_numberofpairs++;
         }
         GetLastError();
      }
   }
   
   for(a=0; a < CURRENCY_numberofpairs; a++){
      if(StringLen(CURRENCY_pairs[a])>0){
         FUNCVAR_currencylist = FUNCVAR_currencylist+";"+CURRENCY_pairs[a];
      }
   }
   log("Found "+CURRENCY_numberofallpairs+" pairs and using "+CURRENCY_numberofpairs+": "+FUNCVAR_currencylist);
   
   function_end();
}


int init_getlookback(){
   function_start("getlookback", true);
   
   int
      FUNCVAR_barnumber,
      FUNCVAR_lookback,
      FUNCVAR_pairscount,
      FUNCVAR_newlookback
      ;
   string
      FUNCVAR_currentpair = "",
      FUNCVAR_pair
      ;
      
   log("Getting lookback for each pair"); 
   for(int a=0;a<CURRENCY_numberofallpairs;a++){
      FUNCVAR_currentpair = CURRENCY_allpairs[a];
      FUNCVAR_barnumber = 1;
      while(
         iTime(FUNCVAR_currentpair, GLOBAL_minitimeframe, FUNCVAR_barnumber) > 0
      ){
         FUNCVAR_barnumber++;
      }
      CURRENCY_allpairslookback[a] = iBarShift(FUNCVAR_currentpair, GLOBAL_timeframe, iTime(FUNCVAR_currentpair, GLOBAL_minitimeframe, FUNCVAR_barnumber - 1)) - 1; //Get equiv in the main timeframe then minus 1.
      log(FUNCVAR_currentpair+" back to barnumber "+CURRENCY_allpairslookback[a]+" dated: "+humandate(iTime(FUNCVAR_currentpair, GLOBAL_timeframe, CURRENCY_allpairslookback[a])));
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
      string FUNCVAR_ordersheaderarray[14] = {"Ticket", "Pair", "Target", "Target of Account", "Signature", "Rating", "Cases", "Return", "Non-Inverse Rating", "Pair Rating", "Recent Rating", "Choice"};
      FUNCVAR_file = openafile(GLOBAL_dumporderarray_file, FUNCVAR_ordersheaderarray);
      FileClose(FUNCVAR_file);
   }else{
      Alert("Will not reset "+GLOBAL_dumporderarray_file+" file automatically on live account. Please manually change this file.");
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
      
   if(GLOBAL_testing == true && FUNCGET_msg == "NULL"){
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
   FUNCVAR_return = TimeYear(FUNCGET_unixdate)+"-"+FUNCVAR_monthprepend+TimeMonth(FUNCGET_unixdate)+"-"+FUNCVAR_dayprepend+TimeDay(FUNCGET_unixdate)+"@"+FUNCVAR_hourprepend+TimeHour(FUNCGET_unixdate)+":"+FUNCVAR_minuteprepend+TimeMinute(FUNCGET_unixdate)+":"+FUNCVAR_secondsprepend+TimeSeconds(FUNCGET_unixdate);
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

int dateindex(int FUNCGET_unixdate){
   function_start("dateindex", true);
   
   int FUNCVAR_return = (TimeYear(FUNCGET_unixdate)-2000)*1000000+TimeMonth(FUNCGET_unixdate)*10000+TimeDay(FUNCGET_unixdate)*100;
   function_end();
   return(FUNCVAR_return);
}

string getinfosummarydate(string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber) {  
   function_start("getinfosummarydate", true);
   
   string FUNCVAR_return = humandate(iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
   function_end();
   return(FUNCVAR_return);
}

string getinfosummarybar(string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber) {
   function_start("getinfosummarybar", true);
   
   string FUNCVAR_return = iOpen(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber)+";"+iHigh(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber)+";"+iLow(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber)+";"+iClose(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
   function_end();
   return(FUNCVAR_return);
}


//+------------------------------------------------------------------+
//| testing and data functions                                       |
//+------------------------------------------------------------------+

void testing_runtests(){
   function_start("testing_runtests", true);
   
   //Gives each signature and its rating
      //testing_outputeachsignature();
   
   //Outputs every signature instance for testing purposes.
      //testing_outputsignaturedata();
     
   //Returns a report on the trades which would have been taken in the last number of days
      testing_outputdemonumberofdays(330,229);

   function_end();
}

void testing_outputdemonumberofdays(int FUNCGET_days = 1, int FUNCGET_startbar = 1){
   function_start("testing_outputdemonumberofdays", true);
   
   int
      FUNCVAR_startbar,
      FUNCVAR_counter,
      FUNCVAR_bar
      ;
    
   for(FUNCVAR_counter = 1; FUNCVAR_counter <= FUNCGET_days; FUNCVAR_counter++){
      FUNCVAR_bar = FUNCVAR_counter + FUNCGET_startbar;
      signature_clearsumarray();
      signature_createsumarray(FUNCVAR_bar);
      signature_createsumarrayresults();
      signature_dumpsumarray();
   }
   function_end();
}

void testing_outputeachsignature(string FUNCGET_command = "NULL"){
   function_start("testing_outputoverview", true);
   
   int
      FUNCVAR_file,
      FUNCVAR_targetcounter
      ;
   string
      FUNCVAR_signature
      ;
   
   log("testing_outputoverview;"+
      "FUNCVAR_signature;"+
      "SIGNATURE_TOTAL_cases[5];"+
      "SIGNATURE_TOTAL_result[5];"+
      "SIGNATURE_NONINVERSE_cases[5];"+
      "SIGNATURE_NONINVERSE_result[5];"+
      "SIGNATURE_PAIR_cases[5];"+
      "SIGNATURE_PAIR_result[5];"+
      "SIGNATURE_RECENT_cases[5];"+
      "SIGNATURE_RECENT_result[5];");     
   for(int a=1;a<6;a++){
      for(int b=1;b<6;b++){
         for(int c=1;c<6;c++){
            for(int d=1;d<6;d++){
               FUNCVAR_signature = ""+signature_getbarsignaturehelper(a)+signature_getbarsignaturehelper(b)+signature_getbarsignaturehelper(c)+signature_getbarsignaturehelper(d)+"";
               SIGNATURE_SUM_barnumber = 1;
               SIGNATURE_SUM_date = iTime(Symbol(), GLOBAL_timeframe, 1);
               signature_setsignaturearray(FUNCVAR_signature, "GBPUSD");
               log("testing_outputoverview;"+
               FUNCVAR_signature+";"+
               SIGNATURE_TOTAL_cases[5]+";"+
               SIGNATURE_TOTAL_result[5]+";"+
               SIGNATURE_NONINVERSE_cases[5]+";"+
               SIGNATURE_NONINVERSE_result[5]+";"+
               SIGNATURE_RECENT_cases[5]+";"+
               SIGNATURE_RECENT_result[5]); // Log the 5th target in the for this signature.
            }
         }
      }
   }
   
   function_end();
}

void testing_outputsignaturedata(){
   function_start("testing_outputsignaturedata", true);
   
   int
      FUNCVAR_barnumber = 1,
      FUNCVAR_positivehit,
      FUNCVAR_negativehit,
      FUNCVAR_targetcounter      
      ;
   
   double
      FUNCVAR_positive,
      FUNCVAR_negative,
      FUNCVAR_closeout,
      FUNCVAR_return,
      FUNCVAR_pointtarget,
      FUNCVAR_ratingholder,
      FUNCVAR_start
      ;
      
   string
      FUNCVAR_currentpair,
      FUNCVAR_signature;
        
   for(int a=0;a<CURRENCY_numberofpairs;a++){
      FUNCVAR_currentpair = CURRENCY_allpairs[a];
      for(FUNCVAR_targetcounter = 0; FUNCVAR_targetcounter < ArraySize(GLOBAL_targetpercentages);FUNCVAR_targetcounter++){
         for(FUNCVAR_barnumber=2;FUNCVAR_barnumber < CURRENCY_allpairslookback[a];FUNCVAR_barnumber++){        
            //v Construct the basic signature for this reference
            FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber + 1) + signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber);
            //^
         
            FUNCVAR_pointtarget = getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) * GLOBAL_targetpercentages[FUNCVAR_targetcounter];
            FUNCVAR_start = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber - 1);
            FUNCVAR_positive = FUNCVAR_start + FUNCVAR_pointtarget;
            FUNCVAR_negative = FUNCVAR_start - FUNCVAR_pointtarget;
            FUNCVAR_positivehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_positive );
            FUNCVAR_negativehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_negative );
         
            FUNCVAR_return = signature_decipherwinner(FUNCVAR_positivehit, FUNCVAR_negativehit);
            
            if(FUNCVAR_positivehit>0){
               FUNCVAR_positivehit = 24 - FUNCVAR_positivehit;
            }

            if(FUNCVAR_negativehit>0){
               FUNCVAR_negativehit = 24 - FUNCVAR_negativehit;
            }
                 
            log(
               "testing_outputsignaturedata;"+
               FUNCVAR_currentpair+";" +
               getinfosummarydate(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber)+";"+
               getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber)+";"+
               GLOBAL_targetpercentages[FUNCVAR_targetcounter]+";"+
               FUNCVAR_signature+";"+
               FUNCVAR_start+";"+
               FUNCVAR_positive+";"+
               FUNCVAR_positivehit+";"+
               FUNCVAR_negative+";"+
               FUNCVAR_negativehit+";"+
               FUNCVAR_return
            );
                
         }
      }
   }
   
   function_end();
}