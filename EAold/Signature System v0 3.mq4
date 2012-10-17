//+------------------------------------------------------------------+
//|                                        Signature System v0 3.mq4 |
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

//#define PROGRAM_VERSION "v0 1" // Original Development in UK
//#define PROGRAM_VERSION "v0 2" // Returned to Australia
#define PROGRAM_VERSION "v0 3" // Orders being created and deleted. Creating more robust code, checking for zero divide errors.
//#define PROGRAM_VERSION "v0 4" // Creation of trade tracking through Ticket number.
//#define PROGRAM_VERSION "v0 5" // Improvements to logging, notifications, investigation into Windows based check for EA running.
//#define PROGRAM_VERSION "v0 6" // 

#define MINUTE 1 
#define HOUR 60
#define DAY 1440
#define WEEK 10080
#define MONTH 43800
#define YEAR 525600

extern bool    GLOBAL_testing                = false;          // Is the EA running in testing mode.
extern int     GLOBAL_pausetime              = 2000;           // In milliseconds. Time to wait when server needs time.
extern int     GLOBAL_goalminnumberofcases   = 6;              // There needs to be at least this many cases of a previous signature for it to be counted.
extern double  GLOBAL_goalminrating          = 0.34;           // 0.01 over 0.33 to clear 0.33 out which is a popular spot for lower cased signatures.
extern int     GLOBAL_goalspreadfactor       = 5;              // Minimum target needs to be this many times the spread to negate its effects.
extern double  GLOBAL_riskpertradepercentage = 0.01;           // The percentage of the account to risk per trade.
   
double GLOBAL_targetpercentages[7] = {0.764, 0.618, 0.50, 0.382, 0.33, 0.236, 0.15};

//string GLOBAL_entities[18] = {"USD", "CHF", "EUR", "GBP", "CAD", "JPY", "AUD", "NZD", "SGD", "HKD", "DKK", "NOK", "SEK", "TRY", "PLN", "MXN", "XAU", "XAG" };
string GLOBAL_entities[16] = {"USD", "CHF", "EUR", "GBP", "CAD", "JPY", "AUD", "NZD", "SGD", "DKK", "NOK", "SEK", "PLN", "MXN", "XAU", "XAG" };


int
   GLOBAL_timeframe,
   GLOBAL_minitimeframe,
   GLOBAL_lookback,
   GLOBAL_recentlookback,
   GLOBAL_currentnumberoforders,
   GLOBAL_cronincrement
   ;

double
   GLOBAL_riskpertradeamount
   ;

string
   GLOBAL_dumpsumarray_file
   ;  
   
//v Signature Variables
string
   SIGNATURE_SUM_order[100], // Buy or Sell
   SIGNATURE_SUM_pair[100],
   SIGNATURE_SUM_signature[100],
   SIGNATURE_TOTAL_signature[15]
   ;

int
   SIGNATURE_SUM_cases[100],
   SIGNATURE_SUM_result[100],
   SIGNATURE_SUM_date,
   SIGNATURE_SUM_barnumber,
   SIGNATURE_TOTAL_cases[15], // All results
   SIGNATURE_TOTAL_result[15],
   SIGNATURE_NONINVERSE_cases[15], // Without inverse results
   SIGNATURE_NONINVERSE_result[15],
   SIGNATURE_PAIR_cases[15], // Results only on this pair
   SIGNATURE_PAIR_result[15],
   SIGNATURE_RECENT_cases[15],
   SIGNATURE_RECENT_result[15]
   ;
   
double
   SIGNATURE_SUM_target[100], // The best target to choose
   SIGNATURE_SUM_targetdistance[100], // The best target to choose
   SIGNATURE_SUM_targetpositive[100],
   SIGNATURE_SUM_targetnegative[100],
   SIGNATURE_SUM_rating[100], // The comparitive rating for this signature
   SIGNATURE_SUM_noninverse_rating[100],
   SIGNATURE_SUM_pair_rating[100],
   SIGNATURE_SUM_recent_rating[100],
   SIGNATURE_SUM_score[100],
   SIGNATURE_SUM_totalscore,
   SIGNATURE_SUM_win[100]
   ;
//^

//v Orders Array
double
   ORDERS_target[100],
   ORDERS_lotshare[100];

string
   ORDERS_pair[100],
   ORDERS_order[100]
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

//v Trade Array
int
   TRADES_numberofclosedorders
   ;

//^

//+------------------------------------------------------------------+
//| initialization function                                          |
//+------------------------------------------------------------------+
int init(){
   
   Alert("Signature System " + PROGRAM_VERSION + " started.");
   Alert("GLOBAL_testing: "+GLOBAL_testing);
   Alert("GLOBAL_pausetime: "+GLOBAL_pausetime);
   Alert("GLOBAL_goalminnumberofcases: "+GLOBAL_goalminnumberofcases);
   Alert("GLOBAL_goalminrating: "+GLOBAL_goalminrating);
   Alert("GLOBAL_goalspreadfactor: "+GLOBAL_goalspreadfactor);
   Alert("GLOBAL_riskpertradepercentage: "+GLOBAL_riskpertradepercentage);
   Alert("Initalising");
   
   log(); // Initialise the log file
   
   GLOBAL_timeframe              = DAY;            // In Minutes. The timeframe to look at for signatures.
   GLOBAL_minitimeframe          = HOUR;           // In Minutes. The timeframe for judging success of a signature, must be less than the main timeframe.
   GLOBAL_lookback               = TimeCurrent();  // In Seconds. The dynamic time to look back at historic data.
   GLOBAL_recentlookback         = 60 * YEAR * 1;  // In Seconds. For the RECENT sub-signature, this is the lookback.
   GLOBAL_cronincrement          = 1;              // In Minutes. How often to run smallest cron task.
   GLOBAL_riskpertradeamount     = AccountBalance() * GLOBAL_riskpertradepercentage;

   TIME_currentweek              = iTime(Symbol(), PERIOD_W1, 0);
   TIME_currentday               = iTime(Symbol(), PERIOD_D1, 0);
   TIME_currenthour              = iTime(Symbol(), PERIOD_H1, 0);
   TIME_currentincrement         = iTime(Symbol(), GLOBAL_cronincrement, 0);
   TIME_weekcrontime             = 10 * 60;
   TIME_daycrontime              = 5 * 60;
   TIME_hourcrontime             = 2 * 60;
   TIME_incrementcrontime        = 3;
   TIME_weekended                = FALSE;
   TIME_dayended                 = FALSE;
   TIME_hourended                = FALSE;
   TIME_incrementended           = FALSE;

   getmaxlookback();
   
   testing_runtests();
     
   Alert("Initalised");
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

   if(iTime(Symbol(), PERIOD_W1, 0) * 2 - iTime(Symbol(), PERIOD_W1, 1) - TimeCurrent() < TIME_weekcrontime * 2 ){
      cron_endweek();
   }
   if(TIME_currentweek != iTime(Symbol(), PERIOD_W1, 0)){
      if(TIME_weekended == FALSE){
         cron_endweek();
      }
      cron_newweek();
      TIME_currentweek = iTime(Symbol(), PERIOD_W1, 0);
   }
   if(iTime(Symbol(), PERIOD_D1, 0) * 2 - iTime(Symbol(), PERIOD_D1, 1) - TimeCurrent() < TIME_daycrontime * 2 ){
      cron_endday();
   }
   if(TIME_currentday != iTime(Symbol(), PERIOD_D1, 0)){
      if(TIME_dayended == FALSE){
         cron_endday();
      }
      cron_newday();
      TIME_currentday = iTime(Symbol(), PERIOD_D1, 0);
   }
   if(iTime(Symbol(), PERIOD_H1, 0) * 2 - iTime(Symbol(), PERIOD_H1, 1) - TimeCurrent() < TIME_hourcrontime * 2 ){
      cron_endhour();
   }
   if(TIME_currenthour != iTime(Symbol(), PERIOD_H1, 0)){
      if(TIME_hourended == FALSE){
         cron_endhour();
      }
      cron_newhour();
      TIME_currenthour = iTime(Symbol(), PERIOD_H1, 0);
   }
   if(iTime(Symbol(), GLOBAL_cronincrement, 0) * 2 - iTime(Symbol(), GLOBAL_cronincrement, 1) - TimeCurrent() < TIME_incrementcrontime * 2 ){
      cron_endincrement();
   }
   if(TIME_currentincrement != iTime(Symbol(), GLOBAL_cronincrement, 0)){
      if(TIME_incrementended == FALSE){
         cron_endincrement();
      }
      cron_newincrement();
      TIME_currentincrement = iTime(Symbol(), GLOBAL_cronincrement, 0);
   }

}

void cron_endweek(){
   int
      FUNCVAR_processtime
      ;
   FUNCVAR_processtime = TimeCurrent();
   log("Ending Week");
     
   TIME_weekended = TRUE;
   TIME_weekcrontime = TimeCurrent() + 1 - FUNCVAR_processtime;
}

void cron_newweek(){
   log("Starting Week");
   
}

void cron_endday(){
   int
      FUNCVAR_processtime
      ;
   FUNCVAR_processtime = TimeCurrent();
   log("Ending Day");
   
   order_closeout();
   GLOBAL_riskpertradeamount = AccountBalance() * GLOBAL_riskpertradepercentage;
   
   TIME_dayended = TRUE;
   TIME_daycrontime = TimeCurrent() + 1 - FUNCVAR_processtime;
}

void cron_newday(){
   log("Starting Day");
   
   order_send();
}

void cron_endhour(){
   int
      FUNCVAR_processtime
      ;
   FUNCVAR_processtime = TimeCurrent();
   log("Ending Hour");
     
   TIME_hourended = TRUE;
   TIME_hourcrontime = TimeCurrent() + 1 - FUNCVAR_processtime;
}

void cron_newhour(){
   log("Starting Hour");

}

void cron_endincrement(){
   int
      FUNCVAR_processtime
      ;
   FUNCVAR_processtime = TimeCurrent();

   TIME_incrementended = TRUE;
   TIME_incrementcrontime = TimeCurrent() + 1 - FUNCVAR_processtime;
}

void cron_newincrement(){
      
      signature_clearsumarray();
      signature_createsumarray();
      order_createorderarray();
      updatedisplay(1);
      
      
}

//+------------------------------------------------------------------+
//| frontend functions                                               |
//+------------------------------------------------------------------+

void updatedisplay(int FUNCGET_sumororder = 0){
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
                  StringSubstr(SIGNATURE_SUM_result[FUNCVAR_counter]+"     ",0,4)+" "+
                  StringSubstr(MathAbs(SIGNATURE_SUM_rating[FUNCVAR_counter])+"     ",0,6)+" "+
                  StringSubstr(SIGNATURE_SUM_result[FUNCVAR_counter]*MathAbs(SIGNATURE_SUM_rating[FUNCVAR_counter])+"     ",0,6);
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
                  StringSubstr(ORDERS_target[FUNCVAR_counter]+" ", 0, 4)+" "+
                  ORDERS_lotshare[FUNCVAR_counter]
                  ;
            }else{
               FUNCVAR_text = " ";
            }
            ObjectCreate("heading", OBJ_LABEL,0, 0, 0);
            ObjectSet("heading", OBJPROP_XDISTANCE, 20);
            ObjectSet("heading", OBJPROP_YDISTANCE, 5);
            ObjectSetText("heading", "    Pair   Order   Trgt Lot%" , 9, "Courier New", Black);
            
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
   
   GetLastError(); // Clear error associated with objects as they are not important.
}


//+------------------------------------------------------------------+
//| order functions                                                  |
//+------------------------------------------------------------------+

void order_createorderarray(){
   int 
      FUNCVAR_introunder
      ;
   double 
      FUNCVAR_sortablearray[100,3]
      ;
   
   for(int a=0;a<GLOBAL_currentnumberoforders;a++){
      FUNCVAR_sortablearray[a,0] = SIGNATURE_SUM_score[a];
      FUNCVAR_sortablearray[a,1] = a;
      
      //Prep the array while we're here
      ORDERS_target[a] = 0;
      ORDERS_pair[a] = "";
      ORDERS_order[a] = "";
      ORDERS_lotshare[a] = 0;
      
   }
   
   ArraySort(FUNCVAR_sortablearray, WHOLE_ARRAY, 0, MODE_DESCEND);
   
   for(a=0;a<GLOBAL_currentnumberoforders;a++){
      FUNCVAR_introunder = FUNCVAR_sortablearray[a,1];
      ORDERS_target[a] = SIGNATURE_SUM_target[FUNCVAR_introunder];
      ORDERS_pair[a] = SIGNATURE_SUM_pair[FUNCVAR_introunder];
      ORDERS_order[a] = SIGNATURE_SUM_order[FUNCVAR_introunder];
      //ORDERS_lotshare[a] = SIGNATURE_SUM_score[FUNCVAR_introunder] / GLOBAL_currentnumberoforders; //SIGNATURE_SUM_totalscore;
   }
}

void order_send(){
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
   log("+--------------------- Opening Positions -------------------------+");
   
   for(FUNCVAR_count=0;FUNCVAR_count<GLOBAL_currentnumberoforders;FUNCVAR_count++){
      FUNCVAR_symbol = ORDERS_pair[FUNCVAR_count];
      FUNCVAR_target = ORDERS_target[FUNCVAR_count] * getinfo(7, FUNCVAR_symbol, GLOBAL_timeframe, 1);
      FUNCVAR_volume = order_getlotsize(FUNCVAR_target, FUNCVAR_symbol);
      FUNCVAR_slippage = 2;
      FUNCVAR_comment = "";
      FUNCVAR_magicnumber = dateindex(iTime(ORDERS_pair[FUNCVAR_count], PERIOD_D1, 0)+60*60*24) + FUNCVAR_count;
     
     
      FUNCVAR_attempt = 1;
      FUNCVAR_ticket = 0;
      
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
            Sleep(GLOBAL_pausetime*5);
            FUNCVAR_attempt++;
            RefreshRates();
         }
      }
      if(FUNCVAR_attempt == 6){
         // TODO: This is a big issue, need to notify!
         log("Order unable to be opened.");
      }else{
         log("Ordered: "+FUNCVAR_symbol+" "+FUNCVAR_cmd+" "+FUNCVAR_volume+" "+FUNCVAR_price+" "+FUNCVAR_slippage+" "+FUNCVAR_stoploss+" "+FUNCVAR_takeprofit+" "+FUNCVAR_comment+" "+FUNCVAR_magicnumber);
      }
   }
   log("+------------------- End Opening Positions -----------------------+");
   
}

double order_getlotsize(double FUNCGET_target, string FUNCGET_currency){
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
      return(0);
   }
   return(FUNCVAR_lots);
}

void order_closeout(){
   int
      FUNCVAR_count,
      FUNCVAR_attempt,
      FUNCVAR_errornumber,
      FUNCVAR_ticketnumber
      ;
   bool
      FUNCVAR_ticket
      ;
      
   log("+--------------------- Closing Positions -------------------------+");
   TRADES_numberofclosedorders = OrdersTotal();
   for(FUNCVAR_count=0; FUNCVAR_count < TRADES_numberofclosedorders; FUNCVAR_count++) {
      OrderSelect(0, SELECT_BY_POS, MODE_TRADES);

      FUNCVAR_attempt = 1;
      FUNCVAR_ticket = FALSE;
      FUNCVAR_ticketnumber = OrderTicket();

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
         // TODO: This is a big issue, need to notify!
         log("Order unable to be closed.");
      }else{
         log("Order "+FUNCVAR_ticketnumber+" closed");
      }
    }
    log("+------------------- END Closing Positions -----------------------+");
}

//+------------------------------------------------------------------+
//| signature functions                                              |
//+------------------------------------------------------------------+
void signature_createsumarray(int FUNCGET_barnumber = 0){
   int
      FUNCVAR_targetcounter,
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency
      ;
   string
      FUNCVAR_signature,
      FUNCVAR_currentpair
      ;

   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
      for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
         FUNCVAR_currentpair = GLOBAL_entities[FUNCVAR_basecurrency] + GLOBAL_entities[FUNCVAR_tradedcurrency];
         if(
            GLOBAL_entities[FUNCVAR_basecurrency] != GLOBAL_entities[FUNCVAR_tradedcurrency] &&
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1 
         ){
            FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber + 1) + signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber);
            SIGNATURE_SUM_barnumber = FUNCGET_barnumber;
            SIGNATURE_SUM_date = iTime(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber);
            signature_setdataarray(FUNCVAR_signature, FUNCVAR_currentpair);
            signature_addtosumarray(FUNCVAR_currentpair);
         } // If
      } // End for
   } // End for
}

void signature_setdataarray(string FUNCGET_signature, string FUNCGET_pair, int FUNCGET_barnumber = 0){
   int
      FUNCVAR_barnumber = 1,
      FUNCVAR_positivehit,
      FUNCVAR_negativehit,
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency,
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
      SIGNATURE_TOTAL_cases[a] = 0;
      SIGNATURE_TOTAL_result[a] = 0;
      SIGNATURE_TOTAL_signature[a] = "";
      SIGNATURE_NONINVERSE_cases[a] = 0;
      SIGNATURE_NONINVERSE_result[a] = 0;
      SIGNATURE_PAIR_cases[a] = 0;
      SIGNATURE_PAIR_result[a] = 0;
      SIGNATURE_RECENT_cases[a] = 0;
      SIGNATURE_RECENT_result[a] = 0;
   }
     
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
      for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
         FUNCVAR_currentpair = GLOBAL_entities[FUNCVAR_basecurrency] + GLOBAL_entities[FUNCVAR_tradedcurrency];
         if(
            GLOBAL_entities[FUNCVAR_basecurrency] != GLOBAL_entities[FUNCVAR_tradedcurrency] &&
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1 
         ){
            FUNCVAR_barnumber = FUNCGET_barnumber + 2; // Start looking at data 2 bars back from the bar we're looking at.
            while(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) > (TimeCurrent() - GLOBAL_lookback)){
               
               //v Construct the basic signature for this reference
               FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber + 1) + signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber);
               //^
               
               if(
                  FUNCVAR_signature == FUNCGET_signature ||
                  signature_invert(FUNCVAR_signature) == FUNCGET_signature
               ){
                  
                  for(FUNCVAR_targetcounter=0;FUNCVAR_targetcounter < ArraySize(GLOBAL_targetpercentages); FUNCVAR_targetcounter++){
                     
                     FUNCVAR_pointtarget = getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) * GLOBAL_targetpercentages[FUNCVAR_targetcounter];
                     
                     if(FUNCVAR_signature == FUNCGET_signature){
                        FUNCVAR_positive = getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) + FUNCVAR_pointtarget;
                        FUNCVAR_negative = getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) - FUNCVAR_pointtarget;
                        FUNCVAR_positivehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_positive );
                        FUNCVAR_negativehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_negative );
                     }else{
                        FUNCVAR_negative = getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) + FUNCVAR_pointtarget;
                        FUNCVAR_positive = getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) - FUNCVAR_pointtarget;
                        FUNCVAR_negativehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_negative );
                        FUNCVAR_positivehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_positive );
                     }
                     
                     FUNCVAR_return = signature_decipherwinner(FUNCVAR_positivehit, FUNCVAR_negativehit);
                   
                     //v Choose which sub-signatures to count this entry towards 
                     SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter]++;
                     SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] = SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] + FUNCVAR_return;
                     SIGNATURE_TOTAL_signature[FUNCVAR_targetcounter] = FUNCGET_signature;
                     
                     if(FUNCVAR_signature == FUNCGET_signature){
                        SIGNATURE_NONINVERSE_cases[FUNCVAR_targetcounter]++;
                        SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] = SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] + FUNCVAR_return;
                     }
                     
                     if(FUNCVAR_currentpair == FUNCGET_pair){
                        SIGNATURE_PAIR_cases[FUNCVAR_targetcounter]++;
                        SIGNATURE_PAIR_result[FUNCVAR_targetcounter] = SIGNATURE_PAIR_result[FUNCVAR_targetcounter] + FUNCVAR_return;
                     }
                     
                     if(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) > (TimeCurrent() - GLOBAL_recentlookback)){
                        SIGNATURE_RECENT_cases[FUNCVAR_targetcounter]++;
                        SIGNATURE_RECENT_result[FUNCVAR_targetcounter] = SIGNATURE_RECENT_result[FUNCVAR_targetcounter] + FUNCVAR_return;
                     }
                     //^ 
                                    
                  } // End For target loop
                  
               } // End FUNCVAR_signature == FUNCGET_signature logic
               
               FUNCVAR_barnumber++; // Check next bar
               
            } // While
         
         }else{
         GetLastError();
         } // If currency tradable
         
      } // For Traded Currency
   } // For Base Currency
   
   return(0);
}


void signature_addtosumarray(string FUNCGET_pair){
   int
      FUNCVAR_targetcounter
      ;
   double
      FUNCVAR_bestrating = 0,
      FUNCVAR_currentrating = 0,
      FUNCVAR_besttarget = 0
      ;
   
   for(FUNCVAR_targetcounter=0;FUNCVAR_targetcounter < ArraySize(GLOBAL_targetpercentages); FUNCVAR_targetcounter++){
      if(SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter] != 0){
         FUNCVAR_currentrating = ((SIGNATURE_TOTAL_result[FUNCVAR_targetcounter]+0.0) / (SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter]+0.0));
      }else{
         break;
      }   
      if( // Decide if signature can be added to order array
         MathAbs(FUNCVAR_currentrating) >= MathAbs(FUNCVAR_bestrating) &&
         MathAbs(FUNCVAR_currentrating) > GLOBAL_goalminrating &&
         SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter] >= GLOBAL_goalminnumberofcases &&
         getinfo(7, FUNCGET_pair, GLOBAL_timeframe, SIGNATURE_SUM_barnumber) * GLOBAL_targetpercentages[FUNCVAR_targetcounter] > GLOBAL_goalspreadfactor * getinfo(502, FUNCGET_pair, GLOBAL_timeframe, 1)
      ){
         FUNCVAR_bestrating = FUNCVAR_currentrating;
         SIGNATURE_SUM_pair[GLOBAL_currentnumberoforders] = FUNCGET_pair;
         SIGNATURE_SUM_signature[GLOBAL_currentnumberoforders] = SIGNATURE_TOTAL_signature[FUNCVAR_targetcounter];
         SIGNATURE_SUM_target[GLOBAL_currentnumberoforders] = GLOBAL_targetpercentages[FUNCVAR_targetcounter];
         SIGNATURE_SUM_targetdistance[GLOBAL_currentnumberoforders] = getinfo(7, FUNCGET_pair, GLOBAL_timeframe, SIGNATURE_SUM_barnumber) * GLOBAL_targetpercentages[FUNCVAR_targetcounter];
         SIGNATURE_SUM_rating[GLOBAL_currentnumberoforders] = FUNCVAR_bestrating;
         SIGNATURE_SUM_cases[GLOBAL_currentnumberoforders] = SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter];
         SIGNATURE_SUM_result[GLOBAL_currentnumberoforders] = MathAbs(SIGNATURE_TOTAL_result[FUNCVAR_targetcounter]);
         SIGNATURE_SUM_score[GLOBAL_currentnumberoforders] = MathAbs(SIGNATURE_SUM_result[GLOBAL_currentnumberoforders] * SIGNATURE_SUM_rating[GLOBAL_currentnumberoforders]);
         SIGNATURE_SUM_noninverse_rating[GLOBAL_currentnumberoforders] = ((SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter]+0.0) / (SIGNATURE_NONINVERSE_cases[FUNCVAR_targetcounter]+0.0000000000001));
         SIGNATURE_SUM_pair_rating[GLOBAL_currentnumberoforders] = ((SIGNATURE_PAIR_result[FUNCVAR_targetcounter]+0.0) / (SIGNATURE_PAIR_cases[FUNCVAR_targetcounter]+0.0000000000001));
         SIGNATURE_SUM_recent_rating[GLOBAL_currentnumberoforders] = ((SIGNATURE_RECENT_result[FUNCVAR_targetcounter]+0.0) / (SIGNATURE_RECENT_cases[FUNCVAR_targetcounter]+0.0000000000001));
      }
      
   }
   if(SIGNATURE_SUM_rating[GLOBAL_currentnumberoforders] > 0){
      SIGNATURE_SUM_order[GLOBAL_currentnumberoforders] = "OP_BUY";
      SIGNATURE_SUM_totalscore = SIGNATURE_SUM_totalscore + SIGNATURE_SUM_score[GLOBAL_currentnumberoforders];
      GLOBAL_currentnumberoforders++;
   }else if(SIGNATURE_SUM_rating[GLOBAL_currentnumberoforders] < 0){
      SIGNATURE_SUM_order[GLOBAL_currentnumberoforders] = "OP_SELL";
      SIGNATURE_SUM_totalscore = SIGNATURE_SUM_totalscore + SIGNATURE_SUM_score[GLOBAL_currentnumberoforders];
      GLOBAL_currentnumberoforders++;
   }else{
      SIGNATURE_SUM_order[GLOBAL_currentnumberoforders] = "";
   }
   
}


void signature_createsumarrayresults(){
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
         FUNCVAR_negative = getinfo(1, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber - 1) - (SIGNATURE_SUM_targetdistance[FUNCVAR_counter] + (getinfo(502, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber)) ); // incorporate spread to the negative target
      }else{
         FUNCVAR_positive = getinfo(1, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber - 1) + (SIGNATURE_SUM_targetdistance[FUNCVAR_counter] - (getinfo(502, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber)) ); // incorporate spread to the positive target
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
}



void signature_clearsumarray(){
   for(int a=0;a<100;a++){
      SIGNATURE_SUM_pair[a] = "";
      SIGNATURE_SUM_target[a] = 0;
      SIGNATURE_SUM_targetdistance[a] = 0;
      SIGNATURE_SUM_targetpositive[a] = 0;
      SIGNATURE_SUM_targetnegative[a] = 0;
      SIGNATURE_SUM_order[a] = "";
      SIGNATURE_SUM_rating[a] = 0;
      SIGNATURE_SUM_cases[a] = 0;
      SIGNATURE_SUM_result[a] = 0;
      SIGNATURE_SUM_score[a] = 0;
      SIGNATURE_SUM_noninverse_rating[a] = 0;
      SIGNATURE_SUM_pair_rating[a] = 0;
      SIGNATURE_SUM_recent_rating[a] = 0;
   }
   SIGNATURE_SUM_totalscore = 0;
   SIGNATURE_SUM_date = 0;
   GLOBAL_currentnumberoforders = 0;
}

void signature_dumpsumarray(string FUNCGET_filename = "NULL"){
   int
      FUNCVAR_file,
      FUNCVAR_counter
      ;
      
   log("+----------------------- Dumping Array ---------------------------+");   
   if(FUNCGET_filename != "NULL"){
      string FUNCVAR_headerarray[14] = {"Date", "Date", "Day", "Pair", "Spread", "Signature", "Target", "Target Distance", "Target Positive", "Target Negative", "Order", "Result", "Rating", "Cases", "NonInverse", "Pair", "Recent", "Win"};
      FUNCVAR_file = openafile(FUNCGET_filename, FUNCVAR_headerarray);
      GLOBAL_dumpsumarray_file = FUNCGET_filename;
      FileClose(FUNCVAR_file);
      return(0);
   }else{
      string FUNCVAR_noheader[0];
      FUNCVAR_file = openafile(GLOBAL_dumpsumarray_file, FUNCVAR_noheader);
   }
  
   for(FUNCVAR_counter=0; FUNCVAR_counter < GLOBAL_currentnumberoforders; FUNCVAR_counter++){
      if(SIGNATURE_SUM_order[FUNCVAR_counter] != ""){
         FileWrite(FUNCVAR_file,
            humandate(SIGNATURE_SUM_date),
            SIGNATURE_SUM_date,
            TimeDayOfWeek(SIGNATURE_SUM_date),
            SIGNATURE_SUM_pair[FUNCVAR_counter],
            getinfo(502, SIGNATURE_SUM_pair[FUNCVAR_counter], GLOBAL_timeframe, 1)*1.0,
            SIGNATURE_SUM_signature[FUNCVAR_counter],
            SIGNATURE_SUM_target[FUNCVAR_counter],
            SIGNATURE_SUM_targetdistance[FUNCVAR_counter],
            SIGNATURE_SUM_targetpositive[FUNCVAR_counter],
            SIGNATURE_SUM_targetnegative[FUNCVAR_counter],
            SIGNATURE_SUM_order[FUNCVAR_counter],
            SIGNATURE_SUM_result[FUNCVAR_counter],
            SIGNATURE_SUM_rating[FUNCVAR_counter],
            SIGNATURE_SUM_cases[FUNCVAR_counter],
            SIGNATURE_SUM_noninverse_rating[FUNCVAR_counter],
            SIGNATURE_SUM_pair_rating[FUNCVAR_counter],
            SIGNATURE_SUM_recent_rating[FUNCVAR_counter],
            SIGNATURE_SUM_win[FUNCVAR_counter],
         "");
      }
   }
   FileClose(FUNCVAR_file);
   log("+--------------------- End Dumping Array -------------------------+");
}

string signature_getbarsignature(string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber){

   string 
      FUNCVAR_signature;
   int
      FUNCVAR_passedint;
      
   FUNCVAR_passedint = MathFloor( 1 + ( ( getinfo(1, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) - getinfo(3, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) ) / getinfo(7, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) ) * 0.99999 / 20 * 100);
   FUNCVAR_signature = signature_getbarsignaturehelper(FUNCVAR_passedint);
   FUNCVAR_passedint = MathFloor( 1 + ( ( getinfo(4, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) - getinfo(3, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) ) / getinfo(7, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) ) * 0.99999 / 20 * 100);
   FUNCVAR_signature = FUNCVAR_signature + signature_getbarsignaturehelper(FUNCVAR_passedint);
   if(StringLen(FUNCVAR_signature) != 4){
      log("Signature not correctly constructed: "+FUNCVAR_signature);
   }
   return(FUNCVAR_signature);

}

string signature_getbarsignaturehelper(int FUNCGET_passedint){
   switch(FUNCGET_passedint){
      case 1:
         return("1L");
         break;
      case 2:
         return("2L");
         break;
      case 3:
         return("3M");
         break;
      case 4:
         return("2H");
         break;
      case 5:
         return("1H");
         break;
      default:
         log("***INCORRECT FUNCGET_passedint in function signature_getbarsignaturehelper given: "+FUNCGET_passedint+" ------------+");
   }
}

string signature_invert(string FUNCGET_signature){
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
   return(FUNCGET_signature);
}

int signature_getfirsthighinstance(string FUNCGET_pair, int FUNCGET_barnumber, double FUNCGET_target){
   int 
      FUNCVAR_counter,
      FUNCVAR_minibar = iBarShift(FUNCGET_pair, GLOBAL_minitimeframe, getinfo(5, FUNCGET_pair, GLOBAL_timeframe, FUNCGET_barnumber));
   if(FUNCVAR_minibar > 0){
      for(FUNCVAR_counter=0;FUNCVAR_counter < GLOBAL_timeframe / GLOBAL_minitimeframe - 1; FUNCVAR_counter++){
         if(
            getinfo(2, FUNCGET_pair, GLOBAL_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) >= FUNCGET_target
         ){
            return(FUNCVAR_counter + 1);
         }
      }
   }
   return(0);
}

int signature_getfirstlowinstance(string FUNCGET_pair, int FUNCGET_barnumber, double FUNCGET_target){
   int 
      FUNCVAR_counter,
      FUNCVAR_minibar = iBarShift(FUNCGET_pair, GLOBAL_minitimeframe, getinfo(5, FUNCGET_pair, GLOBAL_timeframe, FUNCGET_barnumber));
   if(FUNCVAR_minibar > 0){
      for(FUNCVAR_counter=0;FUNCVAR_counter < GLOBAL_timeframe / GLOBAL_minitimeframe - 1; FUNCVAR_counter++){
         if(
            getinfo(3, FUNCGET_pair, GLOBAL_minitimeframe, FUNCVAR_minibar - FUNCVAR_counter) <= FUNCGET_target
         ){
            return(FUNCVAR_counter + 1);
         }
      }
   }
   return(0);
}

int signature_decipherwinner(int FUNCGET_positivehit, int FUNCGET_negativehit){
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
      return(-1);
   }else{
      return(0);
   } 
}

//+------------------------------------------------------------------+
//| information functions                                            |
//+------------------------------------------------------------------+

double getinfo(int FUNCGET_what, string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber) {
   int 
      FUNCVAR_loopcount = 0,
      FUNCVAR_errornumber, 
      FUNCVAR_done,
      FUNCVAR_newlookback;
   double
      FUNCVAR_high,
      FUNCVAR_low,
      FUNCVAR_checkvalue;
   
   if(FUNCGET_what < 500){
      GetLastError(); // Clear error buffer
      FUNCVAR_errornumber = 0;
      FUNCVAR_checkvalue = iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
      FUNCVAR_errornumber = GetLastError();
      FUNCVAR_done = 0;
      while(FUNCVAR_done != 1){
         if((FUNCVAR_errornumber == false && FUNCVAR_checkvalue > 0)){
            FUNCVAR_done = 1;
            break;
         }else{
            Sleep(GLOBAL_pausetime);
            GetLastError();
            FUNCVAR_checkvalue = iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
            FUNCVAR_errornumber = GetLastError();
            log("function-getinfo: Attempting to get "+FUNCGET_pair+" "+FUNCGET_timeframe+" "+FUNCGET_barnumber+" and recieved "+FUNCVAR_errornumber+": "+ErrorDescription(FUNCVAR_errornumber));
            FUNCVAR_loopcount++;
            if(FUNCVAR_loopcount>3){
               log("function-getinfo: "+FUNCGET_pair+" unabled to be resolved. Data only available back to barnumber "+(FUNCGET_barnumber-1)+" dated: "+humandate(iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber-1)));
               FUNCVAR_newlookback = TimeCurrent() - iTime(FUNCGET_pair, GLOBAL_timeframe, iBarShift(FUNCGET_pair, GLOBAL_timeframe, iTime(FUNCGET_pair, GLOBAL_minitimeframe, FUNCGET_barnumber-1)) - 1);
               log("function-getinfo: GLOBAL_lookback changed from "+GLOBAL_lookback+" to "+FUNCVAR_newlookback+" dated:"+humandate(TimeCurrent()-FUNCVAR_newlookback));
               GLOBAL_lookback = FUNCVAR_newlookback;
               return(0);
            }
         }
      }
   }
   switch (FUNCGET_what){
      case 1: // Open
         return(iOpen(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
         break;
      case 2: // High
         return(iHigh(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
         break;
      case 3: // Low
         return(iLow(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
         break;
      case 4: // Close
         return(iClose(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
         break;
      case 5: // Time
         return(iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
         break;
      case 6: // Volume
         return(iVolume(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
         break;     
      case 7: // Range
         return(iHigh(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) - iLow(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
         break;
      case 500: // Spread
         return(MarketInfo(FUNCGET_pair, MODE_SPREAD));
         break;
      case 501: // Point
         return(MarketInfo(FUNCGET_pair, MODE_POINT));
         break;
      case 502: // Spread as double
         return(MarketInfo(FUNCGET_pair, MODE_SPREAD) * MarketInfo(FUNCGET_pair, MODE_POINT));
         break;
      default:
         log("***INCORRECT Selection made in switch for function getinfo*** Looking for " + FUNCGET_what);    
         return(0);
         break;
   }
   
   return(false);
}

int getmaxlookback(){
   int
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency,
      FUNCVAR_barnumber,
      FUNCVAR_lookback,
      FUNCVAR_pairscount
      ;
   string
      FUNCVAR_currentpair,
      FUNCVAR_pairs
      ;
      
   log("+-------------------- Getting Max Lookback -----------------------+"); 
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
      for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
         FUNCVAR_currentpair = GLOBAL_entities[FUNCVAR_basecurrency] + GLOBAL_entities[FUNCVAR_tradedcurrency];
         if(
            GLOBAL_entities[FUNCVAR_basecurrency] != GLOBAL_entities[FUNCVAR_tradedcurrency] &&
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1 
         ){
            FUNCVAR_barnumber = 1;
            while(getinfo(5, FUNCVAR_currentpair, GLOBAL_minitimeframe, FUNCVAR_barnumber) > (TimeCurrent() - GLOBAL_lookback)){
               FUNCVAR_barnumber++;
            }
            FUNCVAR_barnumber = 1;
            while(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) > (TimeCurrent() - GLOBAL_lookback)){
               FUNCVAR_barnumber++;
            }
            FUNCVAR_pairs = FUNCVAR_pairs + FUNCVAR_currentpair + " ";
            FUNCVAR_pairscount++;
         }
      }
   }
   GetLastError();
   log("Total Pairs: " + FUNCVAR_pairscount);
   log("Pairs: "+FUNCVAR_pairs);
   log("+------------------ END Getting Max Lookback ---------------------+");   
}


//+------------------------------------------------------------------+
//| record keeping functions                                         |
//+------------------------------------------------------------------+

void log(string FUNCGET_msg = "NULL"){
   int 
      FUNCVAR_logfile
      ;
   if(GLOBAL_testing == true && FUNCGET_msg == "NULL"){
      FileDelete("log.csv");
      GetLastError();
   }
   FUNCVAR_logfile = FileOpen("log.csv", FILE_CSV|FILE_WRITE|FILE_READ);
   if(FUNCVAR_logfile < 1){
     Alert("log.csv file not found, the last error is ", GetLastError());
     FileClose(FUNCVAR_logfile);
     return(0);
   }
   FileSeek(FUNCVAR_logfile, 0, SEEK_END);
   if(FUNCGET_msg != "NULL"){
      FileWrite(FUNCVAR_logfile, humandate(TimeLocal()), ErrorDescription(GetLastError()), FUNCGET_msg);
   }
   FileClose(FUNCVAR_logfile);
}

int openafile(string FUNCGET_filename, string FUNCGET_headerarray[]){
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
         return(0);
      }
      for(FUNCVAR_loopcount = 0; FUNCVAR_loopcount <= ArraySize(FUNCGET_headerarray); FUNCVAR_loopcount++){
         FUNCVAR_headerstring = FUNCVAR_headerstring + FUNCGET_headerarray[FUNCVAR_loopcount] + ";";
      }
      GetLastError();
      FileWrite(FUNCVAR_filenumber, FUNCVAR_headerstring);
      log(FUNCGET_filename + " header written");
      return(FUNCVAR_filenumber);
   }else{
      GetLastError();
      FUNCVAR_filenumber = FileOpen(FUNCGET_filename, FILE_CSV|FILE_WRITE|FILE_READ);
      if(FUNCVAR_filenumber < 1){
         Alert(FUNCGET_filename+" file not found, the last error is ", GetLastError());
         return(0);
      }else{
         FileSeek(FUNCVAR_filenumber, 0, SEEK_END);
         return(FUNCVAR_filenumber);
      }
   }
   return(0);
}

string humandate(int FUNCGET_unixdate){
   string 
      FUNCVAR_minuteprepend = "",
      FUNCVAR_hourprepend = "",
      FUNCVAR_dayprepend = "",
      FUNCVAR_monthprepend = "";
   if(TimeHour(FUNCGET_unixdate) < 10){
      FUNCVAR_hourprepend = "0";
   }
   if(TimeMinute(FUNCGET_unixdate) < 10){
      FUNCVAR_minuteprepend = "0";
   }
   if(TimeDay(FUNCGET_unixdate) < 10){
      FUNCVAR_dayprepend = "0";
   }
   if(TimeMonth(FUNCGET_unixdate) < 10){
      FUNCVAR_monthprepend = "0";
   }
   return( TimeYear(FUNCGET_unixdate)+"-"+FUNCVAR_monthprepend+TimeMonth(FUNCGET_unixdate)+"-"+FUNCVAR_dayprepend+TimeDay(FUNCGET_unixdate)+"@"+FUNCVAR_hourprepend+TimeHour(FUNCGET_unixdate)+":"+FUNCVAR_minuteprepend+TimeMinute(FUNCGET_unixdate) );
}

int dateindex(int FUNCGET_unixdate){
   return((TimeYear(FUNCGET_unixdate)-2000)*1000000+TimeMonth(FUNCGET_unixdate)*10000+TimeDay(FUNCGET_unixdate)*100);
}

string getinfosummarydate(string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber) {  
   return(humandate(iTime(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber)));
}

string getinfosummarybar(string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber) {
   return(iOpen(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber)+";"+iHigh(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber)+";"+iLow(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber)+";"+iClose(FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber));
}


//+------------------------------------------------------------------+
//| testing and data functions                                       |
//+------------------------------------------------------------------+

void testing_runtests(){

   // Testing, Investigation and Data Functions 
   // Gives an overview for the rating for each signature
      //testing_outputoverview("INIT");
      //testing_outputoverview();
   // Gives the currently available trades based on today's bar
      //testing_outputproposal("INIT");
      //testing_outputproposal();
   // Outputs every signature instance for testing purposes.
      //testing_outputsignaturedata();
   // Returns a report on the trades which would have been taken in the last number of days
      //signature_dumpsumarray("Weeksum.csv");
      //testing_outputdemonumberofdays(40);
}

void testing_outputdemonumberofdays(int FUNCGET_days = 1){
   int
      FUNCVAR_startbar,
      FUNCVAR_counter
      ;
    
   for(FUNCVAR_counter = 1; FUNCVAR_counter <= FUNCGET_days; FUNCVAR_counter++){
      signature_clearsumarray();
      signature_createsumarray(FUNCVAR_counter + 1);
      signature_createsumarrayresults();
      signature_dumpsumarray();
   }
}

void testing_outputproposal(string FUNCGET_command = "NULL"){
   int
      FUNCVAR_file,
      FUNCVAR_targetcounter,
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency
      ;
   string
      FUNCVAR_signature,
      FUNCVAR_currentpair
      ;
      
   if(FUNCGET_command != "NULL"){
      string FUNCVAR_headerarray[5] = {"Pair", "Spread", "Signature", "Target", "Target Distance", "Order", "Result", "Rating", "Cases", "NonInverse", "Pair", "Recent"};
      FUNCVAR_file = openafile("signature-proposal.csv", FUNCVAR_headerarray);
      FileClose(FUNCVAR_file);
      return(0);
   }else{
      string FUNCVAR_noheader[0];
      FUNCVAR_file = openafile("signature-proposal.csv", FUNCVAR_noheader);
   }
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
      for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
         FUNCVAR_currentpair = GLOBAL_entities[FUNCVAR_basecurrency] + GLOBAL_entities[FUNCVAR_tradedcurrency];
         if(
            GLOBAL_entities[FUNCVAR_basecurrency] != GLOBAL_entities[FUNCVAR_tradedcurrency] &&
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1 
         ){
            FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, 1) + signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, 0);
            signature_setdataarray(FUNCVAR_signature, FUNCVAR_currentpair);
            signature_addtosumarray(FUNCVAR_currentpair);
            //v Temporary export results   
            if(SIGNATURE_SUM_order[GLOBAL_currentnumberoforders] != ""){
               FileWrite(FUNCVAR_file,
                  FUNCVAR_currentpair,
                  getinfo(502, FUNCVAR_currentpair, GLOBAL_timeframe, 1),
                  FUNCVAR_signature,
                  SIGNATURE_SUM_target[GLOBAL_currentnumberoforders],
                  SIGNATURE_SUM_targetdistance[GLOBAL_currentnumberoforders],
                  SIGNATURE_SUM_order[GLOBAL_currentnumberoforders],
                  SIGNATURE_SUM_result[GLOBAL_currentnumberoforders],
                  SIGNATURE_SUM_rating[GLOBAL_currentnumberoforders],
                  SIGNATURE_SUM_cases[GLOBAL_currentnumberoforders],
                  SIGNATURE_SUM_noninverse_rating[GLOBAL_currentnumberoforders],
                  SIGNATURE_SUM_pair_rating[GLOBAL_currentnumberoforders],
                  SIGNATURE_SUM_recent_rating[GLOBAL_currentnumberoforders],
               "");
               GLOBAL_currentnumberoforders++;
            }
         } // If
      } // End for
   } // End for
   //^

   FileClose(FUNCVAR_file);
}


void testing_outputoverview(string FUNCGET_command = "NULL"){
   int
      FUNCVAR_file,
      FUNCVAR_targetcounter
      ;
   string
      FUNCVAR_signature
      ;
      
   if(FUNCGET_command != "NULL"){
      string FUNCVAR_headerarray[5] = {"Signature", "Target", "Target Distance", "Order", "Rating", "Cases", "NonInverse", "Pair", "Recent"};
      FUNCVAR_file = openafile("signature-overview.csv", FUNCVAR_headerarray);
      FileClose(FUNCVAR_file);
      return(0);
   }else{
      string FUNCVAR_noheader[0];
      FUNCVAR_file = openafile("signature-overview.csv", FUNCVAR_noheader);
   }
   
   for(int a=1;a<6;a++){
      for(int b=1;b<6;b++){
         for(int c=1;c<6;c++){
            for(int d=1;d<6;d++){
               FUNCVAR_signature = ""+signature_getbarsignaturehelper(a)+signature_getbarsignaturehelper(b)+signature_getbarsignaturehelper(c)+signature_getbarsignaturehelper(d)+"";
               signature_setdataarray(FUNCVAR_signature, "GBPUSD");
               signature_addtosumarray("GBPUSD");
               //v Temporary export results   
               FileWrite(FUNCVAR_file,
                  FUNCVAR_signature,
                  SIGNATURE_SUM_target, // The best target to choose
                  SIGNATURE_SUM_targetdistance, // The best target to choose
                  SIGNATURE_SUM_order, // Buy or Sell
                  SIGNATURE_SUM_rating, // The comparitive rating for this signature
                  SIGNATURE_SUM_cases,
                  SIGNATURE_SUM_noninverse_rating,
                  SIGNATURE_SUM_pair_rating,
                  SIGNATURE_SUM_recent_rating,
               "");
               //^
            }
         }
      }
   }
   FileClose(FUNCVAR_file);
}

void testing_outputsignaturedata(){
   int
      FUNCVAR_barnumber = 1,
      FUNCVAR_positivehit,
      FUNCVAR_negativehit,
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency,
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
      
   string FUNCVAR_headerarray[5] = {"Currency", "Date", "Signature", "Positive Target", "Positive Hit", "Negative Target", "Negative Hit", "Decision"};
   int FUNCVAR_file = openafile("signature-TEST-signaturedata.csv", FUNCVAR_headerarray);
   
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
      for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
         FUNCVAR_currentpair = GLOBAL_entities[FUNCVAR_basecurrency] + GLOBAL_entities[FUNCVAR_tradedcurrency];
         if(
            GLOBAL_entities[FUNCVAR_basecurrency] != GLOBAL_entities[FUNCVAR_tradedcurrency] &&
            MarketInfo(FUNCVAR_currentpair, MODE_TRADEALLOWED) == 1 
         ){
            FUNCVAR_barnumber = 2;
            while(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) > (TimeCurrent() - GLOBAL_lookback)){
               
               //v Construct the basic signature for this reference
               FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber + 1) + signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber);
               //^
               
               // Uses a target of 25% regardless   
               FUNCVAR_pointtarget = getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) * 0.25;
               FUNCVAR_positive = getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) + FUNCVAR_pointtarget;
               FUNCVAR_negative = getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) - FUNCVAR_pointtarget;
               FUNCVAR_positivehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_positive );
               FUNCVAR_negativehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_negative );
               
               FUNCVAR_return = signature_decipherwinner(FUNCVAR_positivehit, FUNCVAR_negativehit);
               
               FileWrite(FUNCVAR_file,
               FUNCVAR_currentpair,
               getinfosummarydate(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber),
               FUNCVAR_signature,
               FUNCVAR_positive,
               FUNCVAR_positivehit,
               FUNCVAR_negative,
               FUNCVAR_negativehit,
               FUNCVAR_return
               );
               
               FUNCVAR_barnumber++; // Check next bar
               
            } // While
         
         }else{
         GetLastError();
         } // If currency tradable
         
      } // For Traded Currency
   } // For Base Currency
   FileClose(FUNCVAR_file);
   return(0);
}