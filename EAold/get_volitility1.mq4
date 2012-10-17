//+------------------------------------------------------------------+
//|                                               get_volitility.mq4 |
//|                                                      Ian Belcher |
//|                                                    ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Ian Belcher"
#property link      "ianbelcher.me"

#include <stderror.mqh>
#include <stdlib.mqh>
#include <time.mqh>

string global_entities[18] = {
   "USD",
   "CHF",
   "EUR",
   "GBP",
   "CAD",
   "JPY",
   "AUD",
   "NZD",
   "SGD",
   "HKD",
   "DKK",
   "NOK",
   "SEK",
   "TKY",
   "PLN",
   "MXN",
   "XAU",
   "XAG"
};

//------ Public Vars  --------

int
   global_lookback;

string
   global_pair,
   global_excludes[1]= {"AAA"},
   dummy[0];


//----- Functions ---------
int init(){

   global_lookback = 60 * (MONTH * 1);

   int 
      initvar_base,
      initvar_traded;
   Alert("Get_volitility started");
   log(); // init log function
   get_data(5);
   out_bartypedata(); // init out_ideatester function
   
   /*      
   for(initvar_base = 0; initvar_base < ArraySize(global_entities); initvar_base++){
      for(initvar_traded = 0; initvar_traded < ArraySize(global_entities); initvar_traded++){
         global_pair = global_entities[initvar_base] + global_entities[initvar_traded];
         if(
            global_entities[initvar_base] != global_entities[initvar_traded] &&
            global_pair != global_entities[ArrayBsearch(global_excludes, global_pair)] &&
            MarketInfo(global_pair, MODE_TRADEALLOWED) == 1 
         ){
            log("Starting global_pair: "+global_pair);
            out_bartypedata(global_pair);
         }else{
            log("global_pair: "+global_pair+ " left. Trade allowed:"+MarketInfo(global_pair, MODE_TRADEALLOWED));
         }
      }
   }
   */
   Alert("Finished");
   return(0);
}

int start() {
     return(0);
}



// --------------------------------------------------------------------------------------------
// --------------------------------------    Working Area   -----------------------------------
// --------------------------------------------------------------------------------------------

void get_data(int timeframe){

   int 
      funcvar_base,
      funcvar_traded,
      funcvar_barnumber = 1;
   
   for(funcvar_base = 0; funcvar_base < ArraySize(global_entities); funcvar_base++){
      for(funcvar_traded = 0; funcvar_traded < ArraySize(global_entities); funcvar_traded++){
         global_pair = global_entities[funcvar_base] + global_entities[funcvar_traded];
         if(
            global_entities[funcvar_base] != global_entities[funcvar_traded] &&
            global_pair != global_entities[ArrayBsearch(global_excludes, global_pair)] &&
            MarketInfo(global_pair, MODE_TRADEALLOWED) == 1 
         ){
            GetLastError();
            funcvar_barnumber = 1;
            log("Starting global_pair: "+global_pair);
            while(getinfo(5, global_pair, timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback)){
               funcvar_barnumber++;
            }
         }
      }
   }
   Alert("Got data back to "+TimeYear(TimeCurrent() - global_lookback)+"-"+TimeMonth(TimeCurrent() - global_lookback)+"-"+TimeDay(TimeCurrent() - global_lookback)+"@"+TimeHour(TimeCurrent() - global_lookback)+":"+TimeMinute(TimeCurrent() - global_lookback));
   return(0);
}


void out_bartypedata(string pair = "NULL"){
  
   int
      funcvar_file,
      funcvar_timeframe = MINUTE*5,
      funcvar_barnumber = 1,
      funcvar_spread = MarketInfo(pair, MODE_SPREAD);
      
   double
      funcvar_gain = 0,
      funcvar_pointvalue = MarketInfo(pair, MODE_POINT);

   string
      funcvar_bartype = "",
      funcvar_filename = "bartypedata.csv";
        
   // -- Handle file --
   if(pair == "NULL"){
      string headerarray[4] = {"pair", "bartype", "gain", "spread"};
      funcvar_file = openafile(funcvar_filename, headerarray);
   }else{
      funcvar_file = openafile(funcvar_filename, dummy);
   }
   FileClose(funcvar_file);
   return(false);
   while(getinfo(5, pair, funcvar_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback)){
   
   // -- Code for this report --
      
      funcvar_bartype = getbartype(pair, funcvar_timeframe, funcvar_barnumber);
      FileWrite(funcvar_file, pair, funcvar_bartype, funcvar_gain, funcvar_spread*funcvar_pointvalue);
            
      funcvar_barnumber++;
   }

   FileClose(funcvar_file);
   return(0);
}


// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------



// --------------------------------------------------------------------------------------------
// -------------------------------------- Program Functions -----------------------------------
// --------------------------------------------------------------------------------------------

string getbartype(string pair, int timeframe, int barnumber) {
   int 
   temp;
   double
      funcvar_checkvalue;
   if( // Three Inside Up
      1==2
   ){
      return("TIU");
   }else if( // Three Inside Down
      1==2
   ){
      return("TID");
   }else if( // Three White Soldiers
      1==2
   ){
      return("TWS");
   }else if( // Three Black Crows
      1==2
   ){
      return("TBC");
   }else if( // Morning Star
      1==2
   ){
      return("TMS");
   }else if( // Evening Star
      1==2
   ){
      return("TES");
   }else if( // Tweezer Top
      1==2
   ){
      return("TT");
   }else if( // Tweezer Bottom
      1==2
   ){
      return("TB");
   }else if( // Bullish/Long Engulfing
      1==2
   ){
      return("LE");
   }else if( // Bearish/Short Engulfing
      1==2
   ){
      return("SE");
   }else if( // Hammer
      1==2
   ){
      return("HA");
   }else if( // Hanging Man
      1==2
   ){
      return("HM");
   }else if( // Inverted Hammer
      1==2
   ){
      return("IH");
   }else if( // Shooting Star
      1==2
   ){
      return("SS");
   }else if( // Bullish Marubozu
      1==2
   ){
      return("LM");
   }else if( // Bearish Marubozu
      1==2
   ){
      return("SM");
   
   }else{
      return("none");
   }
}

double getinfo(int what, string pair, int timeframe, int barnumber) {
   int 
      j = 0,
      funcvar_errornumber, 
      funcvar_done;
   double
      funcvar_checkvalue;
   
   GetLastError(); // Clear error buffer
   funcvar_errornumber = 0;
   funcvar_checkvalue = iTime(pair, timeframe, barnumber);
   funcvar_errornumber = GetLastError();
   funcvar_done = 0;
   while(funcvar_done != 1){
      if((funcvar_errornumber == false && funcvar_checkvalue > 0)){
         funcvar_done = 1;
         break;
      }else{
         Sleep(200);
         GetLastError();
         funcvar_checkvalue = iTime(pair, timeframe, barnumber);
         funcvar_errornumber = GetLastError();
         log("Attempting to get "+pair+" "+timeframe+" "+barnumber+" and recieved "+funcvar_errornumber+": "+ErrorDescription(funcvar_errornumber));
         j++;
         if(j>6){
            log(pair+" unabled to be resolved. Data only available back to "+TimeYear(iTime(pair, timeframe, barnumber-1))+"-"+TimeMonth(iTime(pair, timeframe, barnumber-1))+"-"+TimeDay(iTime(pair, timeframe, barnumber-1))+"@"+TimeHour(iTime(pair, timeframe, barnumber-1))+":"+TimeMinute(iTime(pair, timeframe, barnumber-1)));
            global_lookback = TimeCurrent()-iTime(pair, timeframe, barnumber-1);
            return(0);
         }
      }
   }
   switch (what){
      case 1: // Open
         return(iOpen(pair, timeframe, barnumber));
         break;
      case 2: // High
         return(iHigh(pair, timeframe, barnumber));
         break;
      case 3: // Low
         return(iLow(pair, timeframe, barnumber));
         break;
      case 4: // Close
         return(iClose(pair, timeframe, barnumber));
         break;
      case 5: // Time
         return(iTime(pair, timeframe, barnumber));
         break;
      case 6: // Volume
         return(iVolume(pair, timeframe, barnumber));
         break;     
      case 7: // Range
         return(iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber));
         break;   
      default:
         Alert("Improper Selection made in switch for function getinfo");
         break;
   }
   Alert("Error in getinfo function");
   return(false);
}

void log(string msg = "NULL"){
   int 
      funcvar_logfile;
   if(msg == "NULL"){
      FileDelete("log.csv");
      GetLastError();
   }
   funcvar_logfile = FileOpen("log.csv", FILE_CSV|FILE_WRITE|FILE_READ);
   if(funcvar_logfile < 1){
     Alert("log.csv file not found, the last error is ", GetLastError());
     FileClose(funcvar_logfile);
     return(0);
   }
   FileSeek(funcvar_logfile, 0, SEEK_END);
   FileWrite(funcvar_logfile, TimeLocal(), ErrorDescription(GetLastError()), msg);
   FileClose(funcvar_logfile);
}


int openafile(string filename, string headerarray[]){
   string 
      funcvar_headerstring;
   int 
      funcvar_filenumber;
      
   if(ArraySize(headerarray) > 0){
      FileDelete(filename);
      GetLastError();
      funcvar_filenumber = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_READ);
      if(funcvar_filenumber < 1){
         Alert(filename+" file not found, the last error is ", GetLastError());
         return(0);
      }
      Alert(ArraySize(headerarray));
      for(int a=1;a<ArraySize(headerarray);a++){
         funcvar_headerstring = funcvar_headerstring + headerarray[a] + ";";
      }
      GetLastError();
      FileWrite(funcvar_filenumber, funcvar_headerstring);
      Alert(GetLastError());
      log(filename + " header written");
      return(funcvar_filenumber);
   }else{
      GetLastError();
      funcvar_filenumber = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_READ);
      if(funcvar_filenumber < 1){
         Alert(filename+" file not found, the last error is ", GetLastError());
         return(0);
      }else{
         FileSeek(funcvar_filenumber, 0, SEEK_END);
         return(funcvar_filenumber);
      }
   }
   return(0);
}


// --------------------------------------------------------------------------------------------
// -------------------------------------- Output Functions ------------------------------------
// --------------------------------------------------------------------------------------------

void out_ideatester(string pair = "NULL"){
  
   int
      funcvar_file1,
      funcvar_file2,
      funcvar_timeframe = MINUTE*5,
      funcvar_barnumber = 1,
      funcvar_spread = MarketInfo(pair, MODE_SPREAD),
      funcvar_count = 0,
      funcvar_buy_winnercount = 0,
      funcvar_buy_lossercount = 0,
      funcvar_sell_winnercount = 0,
      funcvar_sell_lossercount = 0,
      funcvar_buy_count = 0,
      funcvar_sell_count = 0;
      
   double
      funcvar_gain = 0,
      funcvar_buy_pairgain = 0,
      funcvar_sell_pairgain = 0,
      funcvar_target = 4,
      funcvar_pointvalue = MarketInfo(pair, MODE_POINT);

   string
      funcvar_filename1 = "ideatester.csv",
      funcvar_filename2 = "ideatestersummary.csv",
      funcvar_winner = "";
   
   // -- Handle file --
   if(pair == "NULL"){
      FileDelete(funcvar_filename1);
      funcvar_file1 = openafile(funcvar_filename1, dummy);
      GetLastError();
      FileWrite(funcvar_file1, "pair", "time", "prev open", "prev high", "prev low", "prev close", "open", "high", "low", "close", "winner", "spread", "gain with spread accounted");
      log(funcvar_filename1 + " header written");
      FileClose(funcvar_file1);
      FileDelete(funcvar_filename2);
      funcvar_file2 = openafile(funcvar_filename2, dummy);
      GetLastError();
      FileWrite(funcvar_file2, "pair", "Buy Gain", "Buy Wins", "Buy Losses", "Sell Gain", "Sell Wins", "Sell Losses", "Total Trades");
      log(funcvar_filename2 + " header written");
      FileClose(funcvar_file2);
      return(false); 
   }else{
      funcvar_file1 = openafile(funcvar_filename1, dummy);
      funcvar_file2 = openafile(funcvar_filename2, dummy);
   }


   while(getinfo(5, pair, funcvar_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback)){
   
   // -- Code for this report --
      
      if(
         // Setup
         getinfo(2, pair, funcvar_timeframe, funcvar_barnumber) > getinfo(2, pair, funcvar_timeframe, funcvar_barnumber + 1) &&
         getinfo(7, pair, funcvar_timeframe, funcvar_barnumber + 1) > funcvar_spread*funcvar_pointvalue * 2 // Make sure previous bar was larger than x times spread
         //getinfo(4, pair, funcvar_timeframe, funcvar_barnumber + 1) > getinfo(3, pair, funcvar_timeframe, funcvar_barnumber + 1) + getinfo(7, pair, funcvar_timeframe, funcvar_barnumber + 1) * 0.75 // Close position on previous bar
      ){

            if(
               // Win Condition
               getinfo(2, pair, funcvar_timeframe, funcvar_barnumber) > getinfo(2, pair, funcvar_timeframe, funcvar_barnumber + 1) + funcvar_spread*funcvar_pointvalue*funcvar_target
            ){
               funcvar_gain = funcvar_spread*funcvar_pointvalue * funcvar_target - funcvar_spread*funcvar_pointvalue;
               funcvar_winner = "BW";
               funcvar_buy_winnercount++;
            }else{
               funcvar_gain = getinfo(4, pair, funcvar_timeframe, funcvar_barnumber) - getinfo(2, pair, funcvar_timeframe, funcvar_barnumber + 1) - funcvar_spread*funcvar_pointvalue;
               funcvar_winner = "BL";
               funcvar_buy_lossercount++;
            }
            
            funcvar_buy_count++;
            funcvar_buy_pairgain = funcvar_buy_pairgain + funcvar_gain;
            funcvar_count++;
            
            FileWrite(
               funcvar_file1, 
               pair,
               getinfo(5, pair, funcvar_timeframe, funcvar_barnumber), 
               getinfo(1, pair, funcvar_timeframe, funcvar_barnumber + 1),
               getinfo(2, pair, funcvar_timeframe, funcvar_barnumber + 1),               
               getinfo(3, pair, funcvar_timeframe, funcvar_barnumber + 1),
               getinfo(4, pair, funcvar_timeframe, funcvar_barnumber + 1),
               getinfo(1, pair, funcvar_timeframe, funcvar_barnumber),
               getinfo(2, pair, funcvar_timeframe, funcvar_barnumber),               
               getinfo(3, pair, funcvar_timeframe, funcvar_barnumber),
               getinfo(4, pair, funcvar_timeframe, funcvar_barnumber),
               funcvar_winner, funcvar_spread*funcvar_pointvalue, funcvar_gain);
         
      }else if(
         1==2 ){
      }

         
   // ---
   
   funcvar_barnumber++;
   }

   // -- Fix data and output --
   //Fix this up to show count and other added above to give a better idea for each currency as a whole.
   FileWrite(funcvar_file2, pair, funcvar_buy_pairgain/funcvar_pointvalue, funcvar_buy_winnercount, funcvar_buy_lossercount, funcvar_sell_pairgain/funcvar_pointvalue, funcvar_sell_winnercount, funcvar_sell_lossercount, funcvar_count);
   
   // --
   
   FileClose(funcvar_file1);
   FileClose(funcvar_file2);
   return(0);
}


void out_baroutput(string pair = "NULL"){
  
   int
      funcvar_file,
      funcvar_timeframe = MINUTE*5,
      funcvar_barnumber = 1,
      funcvar_spread = MarketInfo(pair, MODE_SPREAD),
      funcvar_instances = 0;
      
   double
      funcvar_gain = 0,
      funcvar_pointvalue = MarketInfo(pair, MODE_POINT);

   string
      funcvar_filename = "baroutput.csv";
   
   // -- Handle file --
   if(pair == "NULL"){
      FileDelete(funcvar_filename);
      funcvar_file = openafile(funcvar_filename, dummy);
      GetLastError();
      FileWrite(funcvar_file, "pair", "bar", "open", "high", "low", "close", "volume");
      log(funcvar_filename+ " header written");
      FileClose(funcvar_file);
      return(false); 
   }else{
      funcvar_file = openafile(funcvar_filename, dummy);
   }
   while(getinfo(5, pair, funcvar_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback)){
      FileWrite(funcvar_file, pair, funcvar_barnumber, getinfo(1, pair, funcvar_timeframe, funcvar_barnumber), getinfo(2, pair, funcvar_timeframe, funcvar_barnumber), getinfo(3, pair, funcvar_timeframe, funcvar_barnumber), getinfo(4, pair, funcvar_timeframe, funcvar_barnumber), getinfo(6, pair, funcvar_timeframe, funcvar_barnumber) );
      funcvar_barnumber++;
   }
   FileClose(funcvar_file);
   return(0);
}

void out_movementspread(string pair = "NULL"){
  
   int
      funcvar_barnumber = 1,
      funcvar_countedbar = 0,
      funcvar_missedbar = 0,
      funcvar_file,
      funcvar_timeframe = MINUTE*5,
      funcvar_spread = MarketInfo(pair, MODE_SPREAD);
      
   double
      funcvar_movement = 0,
      funcvar_barmovement = 0,
      funcvar_weeklyrange = 0,
      funcvar_movementperbar = 0,
      funcvar_pointvalue = MarketInfo(pair, MODE_POINT);

   string
      funcvar_filename = "movementspread.csv";
   
   // -- Handle file --
   if(pair == "NULL"){
      FileDelete(funcvar_filename);
      funcvar_file = openafile(funcvar_filename, dummy);
      GetLastError();
      FileWrite(funcvar_file, "pair", "MODE_SPREAD", "MODE_POINT", "Last Week Bar Range", "Total " + funcvar_timeframe + " min bar funcvar_movement", "Number of bars", "Number of counted bars", "Number of missed bars", "Average Bar length in points");
      log(funcvar_filename+ " header written");
      FileClose(funcvar_file);
      return(false); 
   }else{
      funcvar_file = openafile(funcvar_filename, dummy);
   }
   // --
      
   while(getinfo(5, pair, funcvar_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback)){ // Count all bars in the last week
   
   // -- Code for this report --
      
      funcvar_barmovement = getinfo(2, pair, funcvar_timeframe, funcvar_barnumber) - getinfo(3, pair, funcvar_timeframe, funcvar_barnumber);
      if(funcvar_barmovement > 0){
         funcvar_movement = funcvar_movement + funcvar_barmovement;
         funcvar_countedbar++;
      }else{
         funcvar_missedbar++;
      }
      funcvar_barnumber++;
   
   // --
   
   }

   // -- Fix data and output --

   if(funcvar_movement==0){
      log("Leaving "+pair+" due to zero funcvar_movement.");
      return(0);
   }
   if(funcvar_pointvalue==0){
      log("Leaving "+pair+" due to zero.");
      return(0);   
   }
   
  
   log("Attempting to calculate funcvar_movementperbar for "+pair+": "+funcvar_movement+"/"+funcvar_countedbar+"/"+funcvar_pointvalue);
   funcvar_movementperbar = (funcvar_movement/funcvar_countedbar) / funcvar_pointvalue;
   log("Move in points per bar: "+funcvar_movementperbar+" Attempting to calculate weekly range");
   funcvar_weeklyrange = getinfo(2, pair, 10080, 1)- getinfo(3, pair, 10080, 1);
   log("Weekly Range: "+funcvar_weeklyrange+" Attempting to write entry");
   FileWrite(funcvar_file, pair, funcvar_spread, funcvar_pointvalue, funcvar_weeklyrange, funcvar_movement, funcvar_barnumber, funcvar_countedbar, funcvar_missedbar, funcvar_movementperbar);
   // --
   
   FileClose(funcvar_file);
   return(0);
}




