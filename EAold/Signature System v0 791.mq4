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
//#define PROGRAM_VERSION "v0 76"
// Good working version
#define PROGRAM_VERSION "v0 791"
//Investigating a simple hourly spreadbet. 

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
extern bool    GLOBAL_runcron                = false;          //This setting turns off the cron update tasks. (ONLY runs init tasks)
extern int     GLOBAL_recentlookback         = 15000000;       //In Seconds. For the RECENT sub-signature, this is the lookback. 2.5M is about one month.
extern double  GLOBAL_stoplossfactor         = 0.5;            //The factor of size of the SL compared to the TP point for a trade.
extern int     GLOBAL_goalminnumberofcases   = 6;              //There needs to be at least this many cases of a previous signature for it to be counted.
extern double  GLOBAL_goalminrating          = 0.1;            //The minimum expected ROI on a trade 
extern int     GLOBAL_goalspreadfactor       = 2;              //Minimum target needs to be this many times the spread to negate its effects.
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
extern bool    CURRENCY_PLN                  = true;
extern bool    CURRENCY_MXN                  = true;
extern bool    CURRENCY_XAU                  = true;
extern bool    CURRENCY_XAG                  = true;
extern string  CURRENCY_skippairs            = ""; //= "CHFSGD; EURSGD; EURDKK; EURNOK; EURSEK; USDTRY; EURTRY; GBPSGD; GBPSEK; GBPNOK; GBPDKK; GBPTRY; CADSGD; CADSEK; CADNOK; CADDKK; CADTRY; AUDSGD; NZDCHF; NZDSGD; NZDCAD; NOKJPY; HKDJPY; NOKSEK; SEKJPY";

//double      GLOBAL_targetpercentages[7] = {0.764, 0.618, 0.50, 0.382, 0.33, 0.236, 0.15};
double      GLOBAL_targetpercentages[7] = {0.5, 0.45, 0.4, 0.35, 0.3, 0.25, 0.2};

int         GLOBAL_timeframe;
int         GLOBAL_minitimeframe;
int         GLOBAL_cronincrement;
double      GLOBAL_riskpertradeamount;
string      GLOBAL_exportorderarray_file;
bool        GLOBAL_isdemo;

//v Account Variables

double      ACCOUNT_previousbalance;
double      ACCOUNT_closedordersprofit;
int         ACCOUNT_numberofclosedorders;
int         ACCOUNT_totalnumberoforders;

//^

//v Time Array
  
int         TIME_currentweek;
int         TIME_currentday;
int         TIME_currenthour;
int         TIME_currentincrement;
int         TIME_weekcrontime;
int         TIME_daycrontime;
int         TIME_hourcrontime;
int         TIME_incrementcrontime;
bool        TIME_weekended;
bool        TIME_dayended;
bool        TIME_hourended;
bool        TIME_incrementended;

//^

//v Function tracking array

int         FUNCTION_functionnest;
string      FUNCTION_functionname[100];
bool        FUNCTION_tracer[100];

//^

//v Currency array

int         CURRENCY_all_numberofpairs;
int         CURRENCY_selected_numberofpairs;
int         CURRENCY_all_lookback[100];
int         CURRENCY_selected_lookback[100];
string      CURRENCY_all_entities[100];
string      CURRENCY_selected_entities[100];
string      CURRENCY_all_pairs[100];
string      CURRENCY_selected_pairs[100];

//^



//+------------------------------------------------------------------+
//| signature class                                                  |
//+------------------------------------------------------------------+

string      SIGNATURE_pair;
string      SIGNATURE_signature;
int         SIGNATURE_barnumber;
int         SIGNATURE_RECENT_datemin;
int         SIGNATURE_RECENT_datemax;
int         SIGNATURE_RECENT_cases[15]; //Recent results
int         SIGNATURE_RECENT_result[15];
int         SIGNATURE_TOTAL_cases[15]; //All results
int         SIGNATURE_TOTAL_result[15];
int         SIGNATURE_NONINVERSE_cases[15]; //Without inverse results
int         SIGNATURE_NONINVERSE_result[15];
int         SIGNATURE_PAIR_cases[15];
int         SIGNATURE_PAIR_result[15];
double      SIGNATURE_NEXTBAR_high[15];
double      SIGNATURE_NEXTBAR_low[15];
double      SIGNATURE_NEXTBAR_close[15];
double      SIGNATURE_NEXTBAR_closedigital[15];


void signature_cleararray(){

   SIGNATURE_pair = "";     
   SIGNATURE_signature = "";     
   SIGNATURE_barnumber = 0; 
   SIGNATURE_RECENT_datemin = 0;
   SIGNATURE_RECENT_datemax = 0;

   for(int FUNCVAR_targetcounter=0;FUNCVAR_targetcounter<ArraySize(GLOBAL_targetpercentages);FUNCVAR_targetcounter++){   
      SIGNATURE_RECENT_cases[FUNCVAR_targetcounter] = 0;
      SIGNATURE_RECENT_result[FUNCVAR_targetcounter] = 0;
      SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter] = 0;
      SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] = 0;
      SIGNATURE_NONINVERSE_cases[FUNCVAR_targetcounter] = 0;
      SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] = 0;
      SIGNATURE_PAIR_cases[FUNCVAR_targetcounter] = 0;
      SIGNATURE_PAIR_result[FUNCVAR_targetcounter] = 0;
      SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter] = 0;
      SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter] = 0;
      SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] = 0;
      SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] = 0;
   }
}

void signature_dumpsignaturearray(){
   function_start("signature_dumpsignaturearray", true);
   
   int
      FUNCVAR_targetcounter
      ;
        
   for(FUNCVAR_targetcounter=0;FUNCVAR_targetcounter < ArraySize(GLOBAL_targetpercentages); FUNCVAR_targetcounter++){      
      log(
         SIGNATURE_pair+";"+
         SIGNATURE_signature+";"+
         SIGNATURE_barnumber+";"+
         GLOBAL_targetpercentages[FUNCVAR_targetcounter]+";"+
         SIGNATURE_RECENT_datemin+";"+
         SIGNATURE_RECENT_datemax+";"+
         SIGNATURE_RECENT_cases[FUNCVAR_targetcounter]+";"+
         SIGNATURE_RECENT_result[FUNCVAR_targetcounter]+";"+
         SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter]+";"+
         SIGNATURE_TOTAL_result[FUNCVAR_targetcounter]+";"+
         SIGNATURE_NONINVERSE_cases[FUNCVAR_targetcounter]+";"+
         SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter]+";"+
         SIGNATURE_PAIR_cases[FUNCVAR_targetcounter]+";"+
         SIGNATURE_PAIR_result[FUNCVAR_targetcounter]+";"+
         SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter]+";"+
         SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter]+";"+
         SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter]+";"+
         SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter]
      );
   }
      
   function_end();
}


void signature_setsignaturearray(string FUNCGET_signature, string FUNCGET_pair, int FUNCGET_barnumber = 0){
   function_start("signature_setsignaturearray", true);
   
   int
      FUNCVAR_barnumberloop,
      FUNCVAR_positivehit,
      FUNCVAR_negativehit,
      FUNCVAR_targetcounter,
      FUNCVAR_currencycounter,
      FUNCVAR_closedigital
      ;
   
   double
      FUNCVAR_positive,
      FUNCVAR_negative,
      FUNCVAR_closeout,
      FUNCVAR_return,
      FUNCVAR_pointtarget,
      FUNCVAR_ratingholder,
      FUNCVAR_close
      ;
      
   string
      FUNCVAR_currentpair,
      FUNCVAR_signature;
   
   signature_cleararray();
   
   SIGNATURE_pair = FUNCGET_pair;
   SIGNATURE_signature = FUNCGET_signature;
   SIGNATURE_barnumber = FUNCGET_barnumber;
   
   SIGNATURE_RECENT_datemin = TimeCurrent();
   SIGNATURE_RECENT_datemax = 0;
       
   /*
   for(FUNCVAR_currencycounter=0;FUNCVAR_currencycounter<CURRENCY_selected_numberofpairs;FUNCVAR_currencycounter++){
      FUNCVAR_currentpair = CURRENCY_selected_pairs[FUNCVAR_currencycounter];
       for(FUNCVAR_barnumberloop=FUNCGET_barnumber + 2;FUNCVAR_barnumberloop < CURRENCY_selected_lookback[FUNCVAR_currencycounter]-2;FUNCVAR_barnumberloop++){ //Start looking at data 2 bars back from the bar we're looking at and 2 bars before the end of the data

         FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop);
         
         if(
            FUNCVAR_signature == FUNCGET_signature ||
            signature_invert(FUNCVAR_signature) == FUNCGET_signature
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
                  if(FUNCVAR_signature == FUNCGET_signature){
                     SIGNATURE_NONINVERSE_cases[FUNCVAR_targetcounter]++;
                     SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] = SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] + FUNCVAR_return;
                  }
                  
                  if(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop) < SIGNATURE_RECENT_datemin){
                     SIGNATURE_RECENT_datemin = getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop);
                  }
                  if(getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop) > SIGNATURE_RECENT_datemax){
                     SIGNATURE_RECENT_datemax = getinfo(5, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop);
                  }
                                 
               }
               
               //
               if(FUNCVAR_signature == FUNCGET_signature){
                  SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter]   + ( ( getinfo(2, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop ) );
                  SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter]     + ( ( getinfo(3, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop ) );
                  FUNCVAR_close = ( getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop );
                  FUNCVAR_closedigital = 0;
                  if(FUNCVAR_close > 0.15){FUNCVAR_closedigital = 1;}
                  if(FUNCVAR_close < -0.15){FUNCVAR_closedigital = -1;}
                  SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] + FUNCVAR_close;
                  SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] + FUNCVAR_closedigital;
               }else if(1==2){ // Switch inversion on/off for NEXTBAR stats
                  SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter]   + ( ( getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(3, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop ) );
                  SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter]     + ( ( getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(2, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop ) );
                  FUNCVAR_close = ( getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop );
                  FUNCVAR_closedigital = 0;
                  if(FUNCVAR_close > 0.15){FUNCVAR_closedigital = 1;}
                  if(FUNCVAR_close < -0.15){FUNCVAR_closedigital = -1;}
                  SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] + FUNCVAR_close;
                  SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] + FUNCVAR_closedigital;
               }
               
               SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter]++;
               SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] = SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] + FUNCVAR_return;

               if(FUNCVAR_currentpair == FUNCGET_pair){
                  SIGNATURE_PAIR_cases[FUNCVAR_targetcounter]++;
                  SIGNATURE_PAIR_result[FUNCVAR_targetcounter] = SIGNATURE_PAIR_result[FUNCVAR_targetcounter] + FUNCVAR_return;
               }
               
               //^ 
                              
            } //End For target loop           
            
         }//End FUNCVAR_signature == FUNCGET_signature logic                  
      } //For
   } // For  
   
   */
   
   int FUNCVAR_lookback = getpairlookback(FUNCGET_pair);
     
   for(FUNCVAR_barnumberloop=FUNCGET_barnumber + 2;FUNCVAR_barnumberloop < FUNCVAR_lookback - 2;FUNCVAR_barnumberloop++){ //Start looking at data 2 bars back from the bar we're looking at and 2 bars before the end of the data

      FUNCVAR_signature = signature_getbarsignature(FUNCGET_pair, GLOBAL_timeframe, FUNCVAR_barnumberloop);
      
      if(
         FUNCVAR_signature == FUNCGET_signature ||
         signature_invert(FUNCVAR_signature) == FUNCGET_signature
      ){
      
         for(FUNCVAR_targetcounter=0;FUNCVAR_targetcounter < ArraySize(GLOBAL_targetpercentages); FUNCVAR_targetcounter++){
         
            FUNCVAR_pointtarget = getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop) * GLOBAL_targetpercentages[FUNCVAR_targetcounter];
         
            if(FUNCVAR_signature == FUNCGET_signature){
               FUNCVAR_positive = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) + FUNCVAR_pointtarget;
               FUNCVAR_negative = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - FUNCVAR_pointtarget * GLOBAL_stoplossfactor;
               FUNCVAR_positivehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumberloop - 1, FUNCVAR_positive );
               FUNCVAR_negativehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumberloop - 1, FUNCVAR_negative );
            }else{ // Check the inverse
               FUNCVAR_negative = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) + FUNCVAR_pointtarget * GLOBAL_stoplossfactor;
               FUNCVAR_positive = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - FUNCVAR_pointtarget;
               FUNCVAR_negativehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumberloop - 1, FUNCVAR_negative );
               FUNCVAR_positivehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumberloop - 1, FUNCVAR_positive );
            }
         
            FUNCVAR_return = signature_decipherwinner(FUNCVAR_positivehit, FUNCVAR_negativehit);
               
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
         
            //
            if(FUNCVAR_signature == FUNCGET_signature){
               SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter]   + ( ( getinfo(2, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop ) );
               SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter]     + ( ( getinfo(3, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop ) );
               FUNCVAR_close = ( getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop );
               FUNCVAR_closedigital = 0;
               if(FUNCVAR_close > 0.15){FUNCVAR_closedigital = 1;}
               if(FUNCVAR_close < -0.15){FUNCVAR_closedigital = -1;}
               SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] + FUNCVAR_close;
               SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] + FUNCVAR_closedigital;
            }else if(1==1){ // Switch inversion on/off for NEXTBAR stats
               SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_high[FUNCVAR_targetcounter]   + ( ( getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(3, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop ) );
               SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_low[FUNCVAR_targetcounter]     + ( ( getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(2, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop ) );
               FUNCVAR_close = ( getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) - getinfo(4, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop - 1) ) / getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumberloop );
               FUNCVAR_closedigital = 0;
               if(FUNCVAR_close > 0.15){FUNCVAR_closedigital = 1;}
               if(FUNCVAR_close < -0.15){FUNCVAR_closedigital = -1;}
               SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_close[FUNCVAR_targetcounter] + FUNCVAR_close;
               SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] = SIGNATURE_NEXTBAR_closedigital[FUNCVAR_targetcounter] + FUNCVAR_closedigital;
            }
         
            SIGNATURE_TOTAL_cases[FUNCVAR_targetcounter]++;
            SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] = SIGNATURE_TOTAL_result[FUNCVAR_targetcounter] + FUNCVAR_return;

            if(FUNCVAR_signature == FUNCGET_signature){
               SIGNATURE_NONINVERSE_cases[FUNCVAR_targetcounter]++;
               SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] = SIGNATURE_NONINVERSE_result[FUNCVAR_targetcounter] + FUNCVAR_return;
            }
            
            SIGNATURE_PAIR_cases[FUNCVAR_targetcounter]++;
            SIGNATURE_PAIR_result[FUNCVAR_targetcounter] = SIGNATURE_PAIR_result[FUNCVAR_targetcounter] + FUNCVAR_return;
         
            //^ 
                        
         } //End For target loop           
      
      }//End FUNCVAR_signature == FUNCGET_signature logic                  
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
      if(SIGNATURE_PAIR_cases[FUNCVAR_targetcounter] != 0){
         FUNCVAR_currentrating = (SIGNATURE_PAIR_result[FUNCVAR_targetcounter]+0.0) / (SIGNATURE_PAIR_cases[FUNCVAR_targetcounter]+0.0);
      }else{
         FUNCVAR_currentrating = 0;
      }   
        
      if( //Decide if signature can be added to sum array
         MathAbs(FUNCVAR_currentrating) > MathAbs(FUNCVAR_bestrating) && // Not >= as the larger the distance, the smaller the lot, the smaller the spread percentage and used margin
         MathAbs(FUNCVAR_currentrating) >= GLOBAL_goalminrating && 
         SIGNATURE_PAIR_cases[FUNCVAR_targetcounter] >= GLOBAL_goalminnumberofcases &&
         getinfo(7, FUNCGET_pair, GLOBAL_timeframe, SIGNATURE_barnumber) * GLOBAL_targetpercentages[FUNCVAR_targetcounter] > GLOBAL_goalspreadfactor * getinfo(502, FUNCGET_pair, GLOBAL_timeframe, 1)
      ){
         FUNCVAR_bestrating = FUNCVAR_currentrating;
         FUNCVAR_besttarget = FUNCVAR_targetcounter;
      }
   }
   
   function_end();
   return(FUNCVAR_besttarget);
}

string signature_getbarsignature(string FUNCGET_pair, int FUNCGET_timeframe, int FUNCGET_barnumber){
   function_start("signature_getbarsignature");
   
   string 
      FUNCVAR_signature,
      FUNCVAR_trend
      ;
   int
      FUNCVAR_passedint
      ;
   double
      FUNCVAR_range,
      FUNCVAR_trendmovement,
      FUNCVAR_spread
      ;
   
   FUNCVAR_signature = "";
   
   FUNCVAR_range = getinfo(7, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber + 1);
   if(FUNCVAR_range > 0){
      FUNCVAR_passedint = MathFloor( 1 + ( ( getinfo(1, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber + 1) - getinfo(3, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber + 1) ) / FUNCVAR_range ) * 0.99999 / 20 * 100);
      FUNCVAR_signature = FUNCVAR_signature + signature_getbarsignaturehelper(FUNCVAR_passedint);
      FUNCVAR_passedint = MathFloor( 1 + ( ( getinfo(4, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber + 1) - getinfo(3, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber + 1) ) / FUNCVAR_range ) * 0.99999 / 20 * 100);
      FUNCVAR_signature = FUNCVAR_signature + signature_getbarsignaturehelper(FUNCVAR_passedint);
   }
   
   FUNCVAR_range = getinfo(7, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
   if(FUNCVAR_range > 0){
      FUNCVAR_passedint = MathFloor( 1 + ( ( getinfo(1, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) - getinfo(3, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) ) / FUNCVAR_range ) * 0.99999 / 20 * 100);
      FUNCVAR_signature = FUNCVAR_signature + signature_getbarsignaturehelper(FUNCVAR_passedint);
      FUNCVAR_passedint = MathFloor( 1 + ( ( getinfo(4, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) - getinfo(3, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber) ) / FUNCVAR_range ) * 0.99999 / 20 * 100);
      FUNCVAR_signature = FUNCVAR_signature + signature_getbarsignaturehelper(FUNCVAR_passedint);
   }
     
   /* New signature investigation
   FUNCVAR_spread = getinfo(502, FUNCGET_pair, FUNCGET_timeframe, FUNCGET_barnumber);
   
   if(FUNCVAR_spread > 0){
      FUNCVAR_trendmovement = (iMA(FUNCGET_pair, FUNCGET_timeframe, 10, 0, MODE_SMA, PRICE_TYPICAL, FUNCGET_barnumber) - iMA(FUNCGET_pair, FUNCGET_timeframe, 10, 0, MODE_SMA, PRICE_TYPICAL, FUNCGET_barnumber + 1) ) / (FUNCVAR_spread * 10);
   }
   
   FUNCVAR_trend = 0;
   if(FUNCVAR_trendmovement >= 6){FUNCVAR_trend = "5";}
   if(FUNCVAR_trendmovement < 6 && FUNCVAR_trendmovement >= 2){FUNCVAR_trend = "4";}
   if(FUNCVAR_trendmovement < 2 && FUNCVAR_trendmovement > -2){FUNCVAR_trend = "3";}
   if(FUNCVAR_trendmovement <= -2 && FUNCVAR_trendmovement > 6){FUNCVAR_trend = "2";}
   if(FUNCVAR_trendmovement <= -6){FUNCVAR_trend = "1";}
   
   FUNCVAR_signature = FUNCVAR_trend; //FUNCVAR_signature + FUNCVAR_trend;
   */
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
//| End signature class                                              |
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| orders class                                                     |
//+------------------------------------------------------------------+

double      ORDERS_targetaccountrisk;
int         ORDERS_currentnumberoforders;
int         ORDERS_date;
int         ORDERS_barnumber;

string      ORDERS_pair[100];
double      ORDERS_spread[100];
string      ORDERS_signature[100];

double      ORDERS_target[100];
double      ORDERS_recent_rating[100];
int         ORDERS_recent_result[100];
int         ORDERS_recent_cases[100];
int         ORDERS_recent_datemin[100];
int         ORDERS_recent_datemax[100];
double      ORDERS_total_rating[100];
int         ORDERS_total_result[100];
int         ORDERS_total_cases[100];
double      ORDERS_noninverse_rating[100];
int         ORDERS_noninverse_result[100];
int         ORDERS_noninverse_cases[100];
double      ORDERS_pair_rating[100];
int         ORDERS_pair_result[100];
int         ORDERS_pair_cases[100];
double      ORDERS_nextbar_high[100];
double      ORDERS_nextbar_low[100];
double      ORDERS_nextbar_close[100];
double      ORDERS_nextbar_closedigital[100];

int         ORDERS_ticket[100];
int         ORDERS_cmd[100];
double      ORDERS_price[100];
double      ORDERS_volume[100];
double      ORDERS_stoploss[100];
double      ORDERS_takeprofit[100];
string      ORDERS_comment[100];
string      ORDERS_magicnumber[100];
 

double      ORDERS_tested_targetdistance[100];
double      ORDERS_tested_targetpositive[100];
double      ORDERS_tested_targetnegative[100];
double      ORDERS_tested_riskratio[100];
double      ORDERS_tested_price[100];
double      ORDERS_tested_endprice[100];
double      ORDERS_tested_win[100];

string order_arrayrecordastext(int FUNCGET_recordnumber){
   function_start("order_arrayrecordastext", true);

   string FUNCVAR_text = 
      humandate(ORDERS_date)+";"+
      ORDERS_date+";"+
      ORDERS_barnumber+";"+
      
      ORDERS_pair[FUNCGET_recordnumber]+";"+
      ORDERS_spread[FUNCGET_recordnumber]+";"+
      ORDERS_signature[FUNCGET_recordnumber]+";"+
      
      ORDERS_target[FUNCGET_recordnumber]+";"+
      ORDERS_recent_rating[FUNCGET_recordnumber]+";"+
      ORDERS_recent_result[FUNCGET_recordnumber]+";"+
      ORDERS_recent_cases[FUNCGET_recordnumber]+";"+
      ORDERS_recent_datemin[FUNCGET_recordnumber]+";"+
      ORDERS_recent_datemax[FUNCGET_recordnumber]+";"+
      ORDERS_total_rating[FUNCGET_recordnumber]+";"+
      ORDERS_total_result[FUNCGET_recordnumber]+";"+
      ORDERS_total_cases[FUNCGET_recordnumber]+";"+
      ORDERS_noninverse_rating[FUNCGET_recordnumber]+";"+
      ORDERS_noninverse_result[FUNCGET_recordnumber]+";"+
      ORDERS_noninverse_cases[FUNCGET_recordnumber]+";"+
      ORDERS_pair_rating[FUNCGET_recordnumber]+";"+
      ORDERS_pair_result[FUNCGET_recordnumber]+";"+
      ORDERS_pair_cases[FUNCGET_recordnumber]+";"+
      ORDERS_nextbar_high[FUNCGET_recordnumber]+";"+
      ORDERS_nextbar_low[FUNCGET_recordnumber]+";"+
      ORDERS_nextbar_close[FUNCGET_recordnumber]+";"+
      ORDERS_nextbar_closedigital[FUNCGET_recordnumber]+";"+
      
      ORDERS_ticket[FUNCGET_recordnumber]+";"+
      ORDERS_cmd[FUNCGET_recordnumber]+";"+
      ORDERS_price[FUNCGET_recordnumber]+";"+
      ORDERS_volume[FUNCGET_recordnumber]+";"+
      ORDERS_stoploss[FUNCGET_recordnumber]+";"+
      ORDERS_takeprofit[FUNCGET_recordnumber]+";"+
      ORDERS_comment[FUNCGET_recordnumber]+";"+
      ORDERS_magicnumber[FUNCGET_recordnumber]+";"+
      
      ORDERS_tested_targetdistance[FUNCGET_recordnumber]+";"+
      ORDERS_tested_targetpositive[FUNCGET_recordnumber]+";"+
      ORDERS_tested_targetnegative[FUNCGET_recordnumber]+";"+
      ORDERS_tested_riskratio[FUNCGET_recordnumber]+";"+
      ORDERS_tested_price[FUNCGET_recordnumber]+";"+
      ORDERS_tested_endprice[FUNCGET_recordnumber]+";"+
      ORDERS_tested_win[FUNCGET_recordnumber]
      ;
    
   function_end();
   return(FUNCVAR_text);
}

void order_cleararray(){
   function_start("order_cleararray", true);
   
   ORDERS_date = 0;
   ORDERS_currentnumberoforders = 0;
   
   for(int FUNCVAR_counter=0;FUNCVAR_counter<100;FUNCVAR_counter++){

         ORDERS_targetaccountrisk = 0;
         ORDERS_currentnumberoforders = 0;
         ORDERS_date = 0;
         ORDERS_barnumber = 0;
      
         ORDERS_pair[FUNCVAR_counter] = "";
         ORDERS_spread [FUNCVAR_counter] = 0;
         ORDERS_signature[FUNCVAR_counter] = "";
      
         ORDERS_target[FUNCVAR_counter] = 0;
         ORDERS_recent_rating[FUNCVAR_counter] = 0;
         ORDERS_recent_result[FUNCVAR_counter] = 0;
         ORDERS_recent_cases[FUNCVAR_counter] = 0;
         ORDERS_recent_datemin[FUNCVAR_counter] = 0;
         ORDERS_recent_datemax[FUNCVAR_counter] = 0;
         ORDERS_total_rating[FUNCVAR_counter] = 0;
         ORDERS_total_result[FUNCVAR_counter] = 0;
         ORDERS_total_cases[FUNCVAR_counter] = 0;
         ORDERS_noninverse_rating[FUNCVAR_counter] = 0;
         ORDERS_noninverse_result[FUNCVAR_counter] = 0;
         ORDERS_noninverse_cases[FUNCVAR_counter] = 0;
         ORDERS_pair_rating[FUNCVAR_counter] = 0;
         ORDERS_pair_result[FUNCVAR_counter] = 0;
         ORDERS_pair_cases[FUNCVAR_counter] = 0;
         ORDERS_nextbar_high[FUNCVAR_counter] = 0;
         ORDERS_nextbar_low[FUNCVAR_counter] = 0;
         ORDERS_nextbar_close[FUNCVAR_counter] = 0;
         ORDERS_nextbar_closedigital[FUNCVAR_counter] = 0;
      
         ORDERS_ticket[FUNCVAR_counter] = 0;
         ORDERS_cmd[FUNCVAR_counter] = -1;
         ORDERS_price[FUNCVAR_counter] = 0;
         ORDERS_volume[FUNCVAR_counter] = 0;
         ORDERS_stoploss[FUNCVAR_counter] = 0;
         ORDERS_takeprofit[FUNCVAR_counter] = 0;
         ORDERS_comment[FUNCVAR_counter] = "";
         ORDERS_magicnumber[FUNCVAR_counter] = "";
      
         ORDERS_tested_targetdistance[FUNCVAR_counter] = 0;
         ORDERS_tested_targetpositive[FUNCVAR_counter] = 0;
         ORDERS_tested_targetnegative[FUNCVAR_counter] = 0;
         ORDERS_tested_riskratio[FUNCVAR_counter] = 0;
         ORDERS_tested_price[FUNCVAR_counter] = 0;
         ORDERS_tested_endprice[FUNCVAR_counter] = 0;
         ORDERS_tested_win[FUNCVAR_counter] = 0;
   }
   
   function_end();
}

void order_addsignaturetoorder(int FUNCGET_target){
   function_start("signature_addsignaturetoorder", true);
      
   ORDERS_pair[ORDERS_currentnumberoforders] = SIGNATURE_pair;
   ORDERS_spread[ORDERS_currentnumberoforders] = getinfo(502, SIGNATURE_pair, GLOBAL_timeframe, ORDERS_barnumber);
   ORDERS_signature[ORDERS_currentnumberoforders] = SIGNATURE_signature;
   ORDERS_target[ORDERS_currentnumberoforders] = GLOBAL_targetpercentages[FUNCGET_target];
   ORDERS_tested_targetdistance[ORDERS_currentnumberoforders] = getinfo(7, SIGNATURE_pair, GLOBAL_timeframe, ORDERS_barnumber) * GLOBAL_targetpercentages[FUNCGET_target];

   if(SIGNATURE_RECENT_cases[FUNCGET_target] > 0){
      ORDERS_recent_rating[ORDERS_currentnumberoforders] = (SIGNATURE_RECENT_result[FUNCGET_target]+0.0) / (SIGNATURE_RECENT_cases[FUNCGET_target]+0.0);
      ORDERS_recent_cases[ORDERS_currentnumberoforders] = SIGNATURE_RECENT_cases[FUNCGET_target];
      ORDERS_recent_result[ORDERS_currentnumberoforders] = MathAbs(SIGNATURE_RECENT_result[FUNCGET_target]);
      ORDERS_recent_datemin[ORDERS_currentnumberoforders] = SIGNATURE_RECENT_datemin;
      ORDERS_recent_datemax[ORDERS_currentnumberoforders] = SIGNATURE_RECENT_datemax;
   }
   
   if(SIGNATURE_TOTAL_cases[FUNCGET_target] > 0){
      ORDERS_total_rating[ORDERS_currentnumberoforders] = (SIGNATURE_TOTAL_result[FUNCGET_target]+0.0) / (SIGNATURE_TOTAL_cases[FUNCGET_target]+0.0);
      ORDERS_total_cases[ORDERS_currentnumberoforders] = SIGNATURE_TOTAL_cases[FUNCGET_target];
      ORDERS_total_result[ORDERS_currentnumberoforders] = MathAbs(SIGNATURE_TOTAL_result[FUNCGET_target]);
      
      ORDERS_nextbar_high[ORDERS_currentnumberoforders] = (SIGNATURE_NEXTBAR_high[FUNCGET_target]+0.0) / (SIGNATURE_TOTAL_cases[FUNCGET_target]+0.0);
      ORDERS_nextbar_low[ORDERS_currentnumberoforders] = (SIGNATURE_NEXTBAR_low[FUNCGET_target]+0.0) / (SIGNATURE_TOTAL_cases[FUNCGET_target]+0.0);
      ORDERS_nextbar_close[ORDERS_currentnumberoforders] = (SIGNATURE_NEXTBAR_close[FUNCGET_target]+0.0) / (SIGNATURE_TOTAL_cases[FUNCGET_target]+0.0);
      ORDERS_nextbar_closedigital[ORDERS_currentnumberoforders] = (SIGNATURE_NEXTBAR_closedigital[FUNCGET_target]+0.0) / (SIGNATURE_TOTAL_cases[FUNCGET_target]+0.0);
   }
   
   if(SIGNATURE_NONINVERSE_cases[FUNCGET_target] > 0){
      ORDERS_noninverse_rating[ORDERS_currentnumberoforders] = (SIGNATURE_NONINVERSE_result[FUNCGET_target]+0.0) / (SIGNATURE_NONINVERSE_cases[FUNCGET_target]+0.0);
      ORDERS_noninverse_cases[ORDERS_currentnumberoforders] = SIGNATURE_NONINVERSE_cases[FUNCGET_target];
      ORDERS_noninverse_result[ORDERS_currentnumberoforders] = MathAbs(SIGNATURE_NONINVERSE_result[FUNCGET_target]);
   }

   if(SIGNATURE_PAIR_cases[FUNCGET_target] > 0){
      ORDERS_pair_rating[ORDERS_currentnumberoforders] = (SIGNATURE_PAIR_result[FUNCGET_target]+0.0) / (SIGNATURE_PAIR_cases[FUNCGET_target]+0.0);
      ORDERS_pair_cases[ORDERS_currentnumberoforders] = SIGNATURE_PAIR_cases[FUNCGET_target];
      ORDERS_pair_result[ORDERS_currentnumberoforders] = MathAbs(SIGNATURE_PAIR_result[FUNCGET_target]);
   }
        
   if(ORDERS_pair_rating[ORDERS_currentnumberoforders] > 0){
      ORDERS_cmd[ORDERS_currentnumberoforders] = 0; // Buy
      ORDERS_currentnumberoforders++;
   }else if(ORDERS_pair_rating[ORDERS_currentnumberoforders] < 0){
      ORDERS_cmd[ORDERS_currentnumberoforders] = 1; // Sell
      ORDERS_currentnumberoforders++;
   }else{
      ORDERS_cmd[ORDERS_currentnumberoforders] = -1;
   }
   
   function_end();
}

void order_addresultstoorder(){
   function_start("order_addresultstoorder", true);
   
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
      FUNCVAR_closeoutvalue
      ;
     
   for(FUNCVAR_counter=0; FUNCVAR_counter < ORDERS_currentnumberoforders; FUNCVAR_counter++){
      if(ORDERS_cmd[FUNCVAR_counter] >=0){
         FUNCVAR_barnumber = iBarShift(ORDERS_pair[FUNCVAR_counter], GLOBAL_timeframe, ORDERS_date);
         ORDERS_tested_price[FUNCVAR_counter] = getinfo(1, ORDERS_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber - 1);
         ORDERS_tested_endprice[FUNCVAR_counter] = getinfo(4, ORDERS_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber - 1);
         
         if(ORDERS_cmd[FUNCVAR_counter] == 0){
            FUNCVAR_positive = ORDERS_tested_price[FUNCVAR_counter] + ORDERS_tested_targetdistance[FUNCVAR_counter];
            FUNCVAR_negative = ORDERS_tested_price[FUNCVAR_counter] - (ORDERS_tested_targetdistance[FUNCVAR_counter] * GLOBAL_stoplossfactor) + getinfo(502, ORDERS_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber); //incorporate spread to the negative target
            ORDERS_tested_riskratio[FUNCVAR_counter] = (FUNCVAR_positive-ORDERS_tested_price[FUNCVAR_counter]) / (ORDERS_tested_price[FUNCVAR_counter] - FUNCVAR_negative);
            FUNCVAR_closeoutvalue = (ORDERS_tested_endprice[FUNCVAR_counter] - ORDERS_tested_price[FUNCVAR_counter])/ORDERS_tested_targetdistance[FUNCVAR_counter];
         }else if(ORDERS_cmd[FUNCVAR_counter] == 1){
            FUNCVAR_positive = ORDERS_tested_price[FUNCVAR_counter] + (ORDERS_tested_targetdistance[FUNCVAR_counter] * GLOBAL_stoplossfactor) - getinfo(502, ORDERS_pair[FUNCVAR_counter], GLOBAL_timeframe, FUNCVAR_barnumber); //incorporate spread to the positive target
            FUNCVAR_negative = ORDERS_tested_price[FUNCVAR_counter] - ORDERS_tested_targetdistance[FUNCVAR_counter];
            ORDERS_tested_riskratio[FUNCVAR_counter] = (ORDERS_tested_price[FUNCVAR_counter] - FUNCVAR_negative) / (FUNCVAR_positive-ORDERS_tested_price[FUNCVAR_counter]);
            FUNCVAR_closeoutvalue = (ORDERS_tested_price[FUNCVAR_counter] - ORDERS_tested_endprice[FUNCVAR_counter])/ORDERS_tested_targetdistance[FUNCVAR_counter];
         }
      
         //if(ORDERS_tested_riskratio[FUNCVAR_counter] < 0.9 || ORDERS_tested_riskratio[FUNCVAR_counter] > 1.1){
         //   log(ORDERS_pair[FUNCVAR_counter]+" on "+ORDERS_date+" has risk ratio of "+ORDERS_tested_riskratio[FUNCVAR_counter]);
         //}
      
         FUNCVAR_positivehit = signature_getfirsthighinstance(ORDERS_pair[FUNCVAR_counter], FUNCVAR_barnumber - 1, FUNCVAR_positive );
         FUNCVAR_negativehit = signature_getfirstlowinstance(ORDERS_pair[FUNCVAR_counter], FUNCVAR_barnumber - 1, FUNCVAR_negative );
         FUNCVAR_windirection = signature_decipherwinner(FUNCVAR_positivehit, FUNCVAR_negativehit);
         
         ORDERS_tested_targetpositive[FUNCVAR_counter] = FUNCVAR_positive;
         ORDERS_tested_targetnegative[FUNCVAR_counter] = FUNCVAR_negative;
         if(
            (ORDERS_cmd[FUNCVAR_counter] == 0 && FUNCVAR_windirection == 1) ||
            (ORDERS_cmd[FUNCVAR_counter] == 1 && FUNCVAR_windirection == -1)
         ){
            ORDERS_tested_win[FUNCVAR_counter] = 1;
         }else{
            ORDERS_tested_win[FUNCVAR_counter] = -1 * GLOBAL_stoplossfactor;
         }
         if(FUNCVAR_windirection == 0){
            if(FUNCVAR_closeoutvalue < -1 * GLOBAL_stoplossfactor){
               FUNCVAR_closeoutvalue = GLOBAL_stoplossfactor * (-1);
            }
            if(FUNCVAR_closeoutvalue > 1){
               FUNCVAR_closeoutvalue = 1;
            }
            ORDERS_tested_win[FUNCVAR_counter] = FUNCVAR_closeoutvalue;
         }

      }else{
         ORDERS_tested_win[FUNCVAR_counter] = 0;
      }
   }
   
   function_end();
}


void order_createorderarray(int FUNCGET_barnumber = 0){
   function_start("signature_createorderarray", true);
   
   int
      FUNCVAR_targetcounter,
      FUNCVAR_targetindex
      ;
   string
      FUNCVAR_signature,
      FUNCVAR_currentpair
      ;
   for(int a=0;a<CURRENCY_selected_numberofpairs;a++){
      FUNCVAR_currentpair = CURRENCY_selected_pairs[a];
      FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber);
      ORDERS_barnumber = FUNCGET_barnumber;
      ORDERS_date = iTime(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCGET_barnumber);
      signature_cleararray();
      signature_setsignaturearray(FUNCVAR_signature, FUNCVAR_currentpair, FUNCGET_barnumber);
      //signature_dumpsignaturearray();
      FUNCVAR_targetindex = signature_testsignaturearray(FUNCVAR_currentpair);
      if(FUNCVAR_targetindex >= 0){
         order_addsignaturetoorder(FUNCVAR_targetindex);
      }
   }
 
   function_end();
}

void order_open(){
   function_start("order_open", true);
   
   int
      FUNCVAR_count,
      FUNCVAR_errornumber
      ;
   double 
      FUNCVAR_target
      ;

   //v Order Variables
   int
      FUNCVAR_cmd,
      FUNCVAR_ticket,
      FUNCVAR_attempt,
      FUNCVAR_slippage
      ;
   double
      FUNCVAR_price,
      FUNCVAR_stoploss,
      FUNCVAR_takeprofit
      ;  
   string
      FUNCVAR_symbol
      ;
   //^
   log("Opening Positions");
   
   for(FUNCVAR_count=0;FUNCVAR_count<ORDERS_currentnumberoforders;FUNCVAR_count++){
      if(ORDERS_cmd[FUNCVAR_count] >= 0){
         if(GLOBAL_testing){
            FUNCVAR_target = MarketInfo(FUNCVAR_symbol, MODE_STOPLEVEL)*MarketInfo(FUNCVAR_symbol, MODE_POINT) * 1.5;
         }else{
            FUNCVAR_target = ORDERS_target[FUNCVAR_count] * getinfo(7, FUNCVAR_symbol, GLOBAL_timeframe, 1);
         }
         ORDERS_volume[FUNCVAR_count] = order_getlotsize(FUNCVAR_target, FUNCVAR_symbol);
         FUNCVAR_slippage = 2;
         ORDERS_comment[FUNCVAR_count] = ORDERS_target[FUNCVAR_count];
         ORDERS_magicnumber[FUNCVAR_count] = dateindex(iTime(ORDERS_pair[FUNCVAR_count], PERIOD_D1, 0)+60*60*24) + FUNCVAR_count;
     
         FUNCVAR_attempt = 1;
         FUNCVAR_ticket = -1;
      
         while(FUNCVAR_ticket < 0 && FUNCVAR_attempt < 6 && ORDERS_volume[FUNCVAR_count] > 0){
            if(ORDERS_cmd[FUNCVAR_count] == 1){
               ORDERS_price[FUNCVAR_count] = MarketInfo(FUNCVAR_symbol, MODE_BID);
               ORDERS_stoploss[FUNCVAR_count] = FUNCVAR_price + FUNCVAR_target;
               ORDERS_takeprofit[FUNCVAR_count] = FUNCVAR_price - FUNCVAR_target;
            }else{
               ORDERS_price[FUNCVAR_count] = MarketInfo(FUNCVAR_symbol, MODE_ASK);
               ORDERS_stoploss[FUNCVAR_count] = FUNCVAR_price - FUNCVAR_target;
               ORDERS_takeprofit[FUNCVAR_count] = FUNCVAR_price + FUNCVAR_target;
            }
      
            FUNCVAR_ticket = OrderSend(ORDERS_pair[FUNCVAR_count], ORDERS_cmd[FUNCVAR_count], ORDERS_volume[FUNCVAR_count], ORDERS_price[FUNCVAR_count], FUNCVAR_slippage, ORDERS_stoploss[FUNCVAR_count], ORDERS_takeprofit[FUNCVAR_count], ORDERS_comment[FUNCVAR_count], ORDERS_magicnumber[FUNCVAR_count]);
            if(FUNCVAR_ticket < 0){
               FUNCVAR_errornumber = GetLastError();
               log("Order failed attempt "+FUNCVAR_attempt+" with error #"+FUNCVAR_errornumber+" - "+ErrorDescription(FUNCVAR_errornumber));
               log("Order info: "+order_arrayrecordastext(FUNCVAR_count));
               Sleep(GLOBAL_pausetime);
               FUNCVAR_attempt++;
               RefreshRates();
            }
         }
         if(FUNCVAR_attempt == 6){
            //TODO: This is a big issue, need to notify!
            log("Order unable to be opened.");
         }else{
            log("Ordered: "+order_arrayrecordastext(FUNCVAR_count));
            ORDERS_ticket[FUNCVAR_count] = FUNCVAR_ticket;
         }
      }
   }
   ACCOUNT_totalnumberoforders = ORDERS_currentnumberoforders;
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

void order_exportorderarray(){
   function_start("order_exportorderarray", true);
   
   int
      FUNCVAR_file,
      FUNCVAR_counter
      ;

   string FUNCVAR_noheader[0];
   FUNCVAR_file = openafile(GLOBAL_exportorderarray_file, FUNCVAR_noheader);
   
   log("Dumping Current Order Array"); 
   for(FUNCVAR_counter=0; FUNCVAR_counter<100; FUNCVAR_counter++){
      if(ORDERS_cmd[FUNCVAR_counter] >= 0){
         FileWrite(FUNCVAR_file, order_arrayrecordastext(FUNCVAR_counter));
      }
   }
   
   FileClose(FUNCVAR_file);   
   function_end();
}


//+------------------------------------------------------------------+
//| End Orders class                                                 |
//+------------------------------------------------------------------+





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
   GLOBAL_exportorderarray_file  = AccountNumber()+"-orders.csv";

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
   
   order_open();
   order_exportorderarray();
   
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
   
   order_createorderarray();
   updatedisplay(1);
   
   if(GLOBAL_testing == true){
      order_open();
      order_exportorderarray();
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
      
   //switch(FUNCGET_sumororder){
   //   default:
         for(FUNCVAR_counter=0;FUNCVAR_counter<100;FUNCVAR_counter++){
            if(FUNCVAR_counter<10){
               FUNCVAR_aprepend = "0";
            }else{
               FUNCVAR_aprepend = "";
            }
            if(ORDERS_cmd[FUNCVAR_counter] == 0){
               FUNCVAR_orderpropend = "";
            }else{
               FUNCVAR_orderpropend = " ";
            }
      
            if(ORDERS_cmd[FUNCVAR_counter] >= 0){
               FUNCVAR_text = 
                  FUNCVAR_aprepend+FUNCVAR_counter+ ") "+
                  ORDERS_pair[FUNCVAR_counter]+" "+
                  ORDERS_signature[FUNCVAR_counter]+" "+
                  StringSubstr(ORDERS_target[FUNCVAR_counter]+"     ",0,4)+" "+
                  StringSubstr(ORDERS_tested_targetdistance[FUNCVAR_counter]+"     ",0,7)+" "+
                  StringSubstr(ORDERS_cmd[FUNCVAR_counter]+"     ",0,7)+" "+
                  StringSubstr(ORDERS_total_result[FUNCVAR_counter]+"     ",0,4)+" "+
                  StringSubstr(MathAbs(ORDERS_total_rating[FUNCVAR_counter])+"     ",0,6)+" "+
                  StringSubstr(ORDERS_total_result[FUNCVAR_counter]*MathAbs(ORDERS_total_rating[FUNCVAR_counter])+"     ",0,6);
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
   //}

   ObjectCreate("col2l1", OBJ_LABEL, 0, 0, 0);
   ObjectSet("col2l1", OBJPROP_XDISTANCE, 430);
   ObjectSet("col2l1", OBJPROP_YDISTANCE, 5);
   ObjectSetText("col2l1", " Time till new day: "+(iTime(Symbol(), PERIOD_D1, 0) + 60*60*24 - TimeCurrent())+" s / "+( (iTime(Symbol(), PERIOD_D1, 0) + 60*60*24 - TimeCurrent()) /60 )+" min / "+( (iTime(Symbol(), PERIOD_D1, 0) + 60*60*24 - TimeCurrent()) /60 /60 )+" hours" , 9, "Courier New", Gray);
   
   GetLastError(); //Clear error associated with objects as they are not important.

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
         iTime(FUNCVAR_currentpair, GLOBAL_minitimeframe, FUNCVAR_barnumber) > 0
      ){
         FUNCVAR_barnumber++;
      }
      CURRENCY_all_lookback[FUNCVAR_counter] = iBarShift(FUNCVAR_currentpair, GLOBAL_timeframe, iTime(FUNCVAR_currentpair, GLOBAL_minitimeframe, FUNCVAR_barnumber - 1)) - 1; //Get equiv in the main timeframe then minus 1.
   }
   
   for(FUNCVAR_counter=0;FUNCVAR_counter<CURRENCY_selected_numberofpairs;FUNCVAR_counter++){
      FUNCVAR_currentpair = CURRENCY_selected_pairs[FUNCVAR_counter];
      FUNCVAR_barnumber = 1;
      while(
         iTime(FUNCVAR_currentpair, GLOBAL_minitimeframe, FUNCVAR_barnumber) > 0
      ){
         FUNCVAR_barnumber++;
      }
      CURRENCY_selected_lookback[FUNCVAR_counter] = iBarShift(FUNCVAR_currentpair, GLOBAL_timeframe, iTime(FUNCVAR_currentpair, GLOBAL_minitimeframe, FUNCVAR_barnumber - 1)) - 1; //Get equiv in the main timeframe then minus 1.
      log(FUNCVAR_currentpair+" back to barnumber "+CURRENCY_selected_lookback[FUNCVAR_counter]+" dated: "+humandate(iTime(FUNCVAR_currentpair, GLOBAL_timeframe, CURRENCY_selected_lookback[FUNCVAR_counter])));
   }
   GetLastError();
   log("END Getting lookback"); 
   
   function_end();  
}

int getpairlookback(string FUNCGET_pair){
   function_start("getpairlookback");
   
   int 
      FUNCVAR_counter
      ;
   
   for(FUNCVAR_counter = 0; FUNCVAR_counter < ArraySize(CURRENCY_selected_lookback); FUNCVAR_counter++){
         if(CURRENCY_selected_pairs[FUNCVAR_counter] == FUNCGET_pair){
            function_end();
            return(CURRENCY_selected_lookback[FUNCVAR_counter]);
         }
   }
   
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
      //testing_outputsignaturedata("AUDUSD");
     
   //Returns a report on the trades which would have been taken in the last number of days
      testing_outputdemonumberofdays(10);
      
   //Gives the current correlation of the market to predictibility of the the system
      //testing_getpaircorrelation("AUDUSD");

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
      signature_cleararray();
      order_cleararray();
      order_createorderarray(FUNCVAR_bar);
      order_addresultstoorder();
      order_exportorderarray();
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

void testing_outputsignaturedata(string FUNCGET_pair = " "){
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
      FUNCVAR_signature
      ;
        
   for(int a=0;a<CURRENCY_selected_numberofpairs;a++){
      for(FUNCVAR_targetcounter = 0; FUNCVAR_targetcounter < ArraySize(GLOBAL_targetpercentages);FUNCVAR_targetcounter++){
         for(FUNCVAR_barnumber=2;FUNCVAR_barnumber < CURRENCY_selected_lookback[a];FUNCVAR_barnumber++){        
            //v Construct the basic signature for this reference
            FUNCVAR_signature = signature_getbarsignature(FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber);
            //^
         
            FUNCVAR_pointtarget = getinfo(7, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber) * GLOBAL_targetpercentages[FUNCVAR_targetcounter];
            FUNCVAR_start = getinfo(1, FUNCVAR_currentpair, GLOBAL_timeframe, FUNCVAR_barnumber - 1);
            FUNCVAR_positive = FUNCVAR_start + FUNCVAR_pointtarget;
            FUNCVAR_negative = FUNCVAR_start - FUNCVAR_pointtarget;
            FUNCVAR_positivehit = signature_getfirsthighinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_positive );
            FUNCVAR_negativehit = signature_getfirstlowinstance(FUNCVAR_currentpair, FUNCVAR_barnumber - 1, FUNCVAR_negative );
         
            FUNCVAR_return = signature_decipherwinner(FUNCVAR_positivehit, FUNCVAR_negativehit);
                           
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

int testing_getpaircorrelation(string FUNCGET_pair, int FUNCGET_barnumber = 0){
   function_start("testing_getpaircorrelation");
   
   int 
      FUNCVAR_barcounter
   ;
   string
      FUNCVAR_signature
   ;
   
   for(FUNCVAR_barcounter=1;FUNCVAR_barcounter < 5;FUNCVAR_barcounter++){
      FUNCVAR_signature = signature_getbarsignature(FUNCGET_pair, GLOBAL_timeframe, FUNCGET_barnumber + FUNCVAR_barcounter);
      signature_setsignaturearray(FUNCVAR_signature, FUNCGET_pair);
      signature_dumpsignaturearray();
   }
   
   function_end();
   return(0);
}