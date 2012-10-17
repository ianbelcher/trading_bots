//+------------------------------------------------------------------+
//|                                                      statool.mq4 |
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


/*
string global_entities[8] = {
   "USD",
   "CHF",
   "EUR",
   "GBP",
   "CAD",
   "JPY",
   "AUD",
   "NZD"
};
*/

//------ Public Vars  --------

int
   global_timeframe,
   global_lookback,
   global_lookforward;

string
   global_pair,
   global_excludes[],
   dummy[0];


//----- Functions ---------
int init(){
   global_timeframe = 5 * MINUTE;
   global_lookback = 60 * (WEEK * 1);
   global_lookforward = 20;

   int 
      initvar_base,
      initvar_traded;
   Alert("statool started");
   log(); // init log function
   Alert("Getting Data");
   get_data();
   //out_bartypedata(); // init out_ideatester function
   out_movement();    
       
   for(initvar_base = 0; initvar_base < ArraySize(global_entities); initvar_base++){
      for(initvar_traded = 0; initvar_traded < ArraySize(global_entities); initvar_traded++){
         global_pair = global_entities[initvar_base] + global_entities[initvar_traded];
         if(
            global_entities[initvar_base] != global_entities[initvar_traded] &&
            //global_pair != global_entities[ArrayBsearch(global_excludes, global_pair)] &&
            MarketInfo(global_pair, MODE_TRADEALLOWED) == 1 
         ){
            log("Starting global_pair: "+global_pair);
            //out_bartypedata(global_pair);
            out_movement(global_pair);
         }else{
            GetLastError();
            //log("global_pair: "+global_pair+ " left. Trade allowed:"+MarketInfo(global_pair, MODE_TRADEALLOWED));
         }
      }
   }
   Alert("Finished");
   return(0);
}

int start() {
     return(0);
}



// --------------------------------------------------------------------------------------------
// --------------------------------------    Working Area   -----------------------------------
// --------------------------------------------------------------------------------------------

void out_movement(string pair = "NULL"){
   int
      funcvar_count,
      funcvar_barnumber = global_lookforward,
      funcvar_gradient,
      funcvar_file,
      funcvar_volume,
      funcvar_file_summary;

   double
      funcvar_periodhigh = 0,
      funcvar_periodlow = 0,
      funcvar_counter = 0,
      funcvar_gain = 0,
      funcvar_point = getinfo(501, pair, global_timeframe, funcvar_barnumber);
            
   string
      funcvar_filename = "movementtest.csv",
      funcvar_filename_summary = "movementtest_summary.csv";
      
   // -- Handle file --
   if(pair == "NULL"){
      string headerarray[50] = {
      "pair", "date", "open", "high", "low", "close", "volume", "spread", 
      "long/short", 
      "1 range", "2 range", "3 range", "4 range", "5 range", "10 range", "15 range", "20 range", "30 range", "40 range",
      "1 position", "1 close", "1 dd", 
      "2 position", "2 close", "2 dd", 
      "3 position", "3 close", "3 dd",
      "4 position", "4 close", "4 dd",
      "5 position", "5 close", "5 dd",
      "10 position", "10 close", "10 dd",
      "15 position", "15 close", "15 dd",
      "20 position", "20 close", "20 dd",
      "30 position", "30 close", "30 dd",
      "40 position", "40 close", "40 dd",
      "gradient"};
      funcvar_file = openafile(funcvar_filename, headerarray);
      FileClose(funcvar_file);
      string headerarray2[3] = {"pair", "gain", "spread", "bounce", "volume"};
      funcvar_file_summary = openafile(funcvar_filename_summary, headerarray2);
      FileClose(funcvar_file_summary);
      return(0);
   }else{
      funcvar_file = openafile(funcvar_filename, dummy);
      funcvar_file_summary = openafile(funcvar_filename_summary, dummy);
   }
   
   funcvar_counter = 0;
   funcvar_periodhigh = 0;
   funcvar_periodlow = 200;
   funcvar_barnumber=global_lookforward;
   while(global_lookforward > funcvar_barnumber){
      funcvar_counter = funcvar_counter + getinfo(7, pair, global_timeframe, funcvar_barnumber);
      funcvar_periodhigh = MathMax(funcvar_periodhigh, getinfo(2, pair, global_timeframe, funcvar_barnumber));
      funcvar_periodlow = MathMin(funcvar_periodlow, getinfo(3, pair, global_timeframe, funcvar_barnumber));
      funcvar_volume = funcvar_volume + getinfo(6, pair, global_timeframe, funcvar_barnumber);
      funcvar_count++;
      
      funcvar_barnumber++;
   }
   funcvar_counter = funcvar_counter / (funcvar_periodhigh - funcvar_periodlow);
   funcvar_barnumber=global_lookforward;
   while(getinfo(5, pair, global_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback + global_lookforward)){
      funcvar_gradient = getinfo(300, pair, global_timeframe, funcvar_barnumber);
      if(funcvar_gradient > 1 * getinfo(500, pair, global_timeframe, funcvar_barnumber)){
         FileWrite(funcvar_file, 
            pair, 
            getinfosummary(pair, global_timeframe, funcvar_barnumber),
            getinfo(500, pair, global_timeframe, funcvar_barnumber),
            " 1", 
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 1) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 1) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 2) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 2) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 3) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 3) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 4) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 4) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 5) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 5) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 10) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 10) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 15) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 15) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 20) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 20) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 30) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 30) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 40) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 40) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 1)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 1),
            iLow(pair, global_timeframe, funcvar_barnumber - 1),
            iClose(pair, global_timeframe, funcvar_barnumber - 2)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 2),
            iLow(pair, global_timeframe, funcvar_barnumber - 2),
            iClose(pair, global_timeframe, funcvar_barnumber - 3)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 3),
            iLow(pair, global_timeframe, funcvar_barnumber - 3),
            iClose(pair, global_timeframe, funcvar_barnumber - 4)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 4),
            iLow(pair, global_timeframe, funcvar_barnumber - 4),
            iClose(pair, global_timeframe, funcvar_barnumber - 5)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 5),
            iLow(pair, global_timeframe, funcvar_barnumber - 5),
            iClose(pair, global_timeframe, funcvar_barnumber - 10)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 10),
            iLow(pair, global_timeframe, funcvar_barnumber - 10),
            iClose(pair, global_timeframe, funcvar_barnumber - 15)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 15),
            iLow(pair, global_timeframe, funcvar_barnumber - 15),
            iClose(pair, global_timeframe, funcvar_barnumber - 20)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 20),
            iLow(pair, global_timeframe, funcvar_barnumber - 20),
            iClose(pair, global_timeframe, funcvar_barnumber - 30)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 30),
            iLow(pair, global_timeframe, funcvar_barnumber - 30),
            iClose(pair, global_timeframe, funcvar_barnumber - 40)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            iClose(pair, global_timeframe, funcvar_barnumber - 40),
            iLow(pair, global_timeframe, funcvar_barnumber - 40),
            funcvar_gradient
         );
         funcvar_gain = funcvar_gain + 
                        getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, global_lookforward) / funcvar_point -
                        getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, global_lookforward) / funcvar_point - 
                        getinfo(500, pair, global_timeframe, funcvar_barnumber);
      }
      if(funcvar_gradient < -1 * getinfo(500, pair, global_timeframe, funcvar_barnumber)){
         FileWrite(funcvar_file, 
            pair, 
            getinfosummary(pair, global_timeframe, funcvar_barnumber), 
            getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            "-1",
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 1) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 1) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 2) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 2) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 3) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 3) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 4) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 4) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 5) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 5) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 10) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 10) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 15) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 15) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber),
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 20) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 20) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 30) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 30) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 40) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 40) / funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 1) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 1),
            iHigh(pair, global_timeframe, funcvar_barnumber - 1),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 2) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 2),
            iHigh(pair, global_timeframe, funcvar_barnumber - 2),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 3) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 3),
            iHigh(pair, global_timeframe, funcvar_barnumber - 3),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 4) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 4),
            iHigh(pair, global_timeframe, funcvar_barnumber - 4),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 5) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 5),
            iHigh(pair, global_timeframe, funcvar_barnumber - 5),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 10) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 10),
            iHigh(pair, global_timeframe, funcvar_barnumber - 10),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 15) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 15),
            iHigh(pair, global_timeframe, funcvar_barnumber - 15),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 20) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 20),
            iHigh(pair, global_timeframe, funcvar_barnumber - 20),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 30) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 30),
            iHigh(pair, global_timeframe, funcvar_barnumber - 30),
            iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - getinfo(500, pair, global_timeframe, funcvar_barnumber) - iClose(pair, global_timeframe, funcvar_barnumber- 40) / funcvar_point,
            iClose(pair, global_timeframe, funcvar_barnumber - 40),
            iHigh(pair, global_timeframe, funcvar_barnumber - 40),
            funcvar_gradient
         );
         funcvar_gain = funcvar_gain + 
                        getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, global_lookforward) / funcvar_point -
                        getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, global_lookforward) / funcvar_point - 
                        getinfo(500, pair, global_timeframe, funcvar_barnumber);
      }
      funcvar_barnumber++;
   }
   
   
   
   FileWrite(funcvar_file_summary, 
      pair, 
      funcvar_gain,
      getinfo(500, pair, global_timeframe, funcvar_barnumber),
      funcvar_counter,
      funcvar_volume
      
   );
   FileClose(funcvar_file);
   FileClose(funcvar_file_summary);
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
      funcvar_snap = 10,
      funcvar_spreadfactor = 2; // Factor of the spread that the bar pattern must cover in order to be counted.
   double
      funcvar_checkvalue;
   if( // Three Inside Up
      getinfo(8, pair, timeframe, barnumber + 2) < -100 + funcvar_snap &&
      iClose(pair, timeframe, barnumber + 1) > getinfo(150, pair, timeframe, barnumber + 2) &&
      iLow(pair, timeframe, barnumber + 1) > iLow(pair, timeframe, barnumber + 2) &&
      iClose(pair, timeframe, barnumber) > iClose(pair, timeframe, barnumber + 2) &&
         MathMax(iHigh(pair, timeframe, barnumber + 2), MathMax(iHigh(pair, timeframe, barnumber + 1), iHigh(pair, timeframe, barnumber))) - 
         MathMin(iLow(pair, timeframe, barnumber + 2), MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber))) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("3;01;Three Inside Up");
   }else if( // Three Inside Down
      getinfo(8, pair, timeframe, barnumber + 2) > 100 - funcvar_snap &&
      iClose(pair, timeframe, barnumber + 1) < getinfo(150, pair, timeframe, barnumber + 2) &&
      iHigh(pair, timeframe, barnumber + 1) < iHigh(pair, timeframe, barnumber + 2) &&
      iClose(pair, timeframe, barnumber) < iClose(pair, timeframe, barnumber + 2) &&
         MathMax(iHigh(pair, timeframe, barnumber + 2), MathMax(iHigh(pair, timeframe, barnumber + 1),iHigh(pair, timeframe, barnumber))) - 
         MathMin(iLow(pair, timeframe, barnumber + 2), MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber))) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("3;-1;Three Inside Down");
   }else if( // Three White Soldiers
      getinfo(8, pair, timeframe, barnumber + 2) > 100 - funcvar_snap &&
      getinfo(8, pair, timeframe, barnumber + 1) > 100 - funcvar_snap &&
      getinfo(8, pair, timeframe, barnumber) > 100 - funcvar_snap &&
         MathMax(iHigh(pair, timeframe, barnumber + 2), MathMax(iHigh(pair, timeframe, barnumber + 1),iHigh(pair, timeframe, barnumber))) - 
         MathMin(iLow(pair, timeframe, barnumber + 2), MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber))) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("3;01;Three White Soldiers");
   }else if( // Three Black Crows
      getinfo(8, pair, timeframe, barnumber + 2) < -100 + funcvar_snap &&
      getinfo(8, pair, timeframe, barnumber + 1) < -100 + funcvar_snap &&
      getinfo(8, pair, timeframe, barnumber) < -100 + funcvar_snap &&
         MathMax(iHigh(pair, timeframe, barnumber + 2), MathMax(iHigh(pair, timeframe, barnumber + 1),iHigh(pair, timeframe, barnumber))) - 
         MathMin(iLow(pair, timeframe, barnumber + 2), MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber))) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("3;-;01;Three Black Crows");
   }else if( // Morning Star
      getinfo(8, pair, timeframe, barnumber + 2) < -100 + funcvar_snap &&
      getinfo(8, pair, timeframe, barnumber + 1) < funcvar_snap &&
      getinfo(8, pair, timeframe, barnumber + 1) > -funcvar_snap &&
      iClose(pair, timeframe, barnumber) > getinfo(150, pair, timeframe, barnumber + 2) &&
         MathMax(iHigh(pair, timeframe, barnumber + 2), MathMax(iHigh(pair, timeframe, barnumber + 1),iHigh(pair, timeframe, barnumber))) - 
         MathMin(iLow(pair, timeframe, barnumber + 2), MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber))) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("3;01;Morning Star");
   }else if( // Evening Star
      getinfo(8, pair, timeframe, barnumber + 2) > 100 - funcvar_snap &&
      getinfo(8, pair, timeframe, barnumber + 1) < funcvar_snap &&
      getinfo(8, pair, timeframe, barnumber + 1) > -funcvar_snap &&
      iClose(pair, timeframe, barnumber) < getinfo(150, pair, timeframe, barnumber + 2) &&
         MathMin(iHigh(pair, timeframe, barnumber + 2), MathMax(iHigh(pair, timeframe, barnumber + 1),iHigh(pair, timeframe, barnumber))) - 
         MathMin(iLow(pair, timeframe, barnumber + 2), MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber))) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("3;-1;Evening Star");
   }else if( // Tweezer Bottom
      getinfo(8, pair, timeframe, barnumber + 1) > -25 &&
      getinfo(8, pair, timeframe, barnumber + 1) < 0 &&
      getinfo(8, pair, timeframe, barnumber) < 25 &&
      getinfo(8, pair, timeframe, barnumber) > 0 &&
      iClose(pair, timeframe, barnumber + 1) > getinfo(150, pair, timeframe, barnumber + 1) &&
      iClose(pair, timeframe, barnumber) > getinfo(150, pair, timeframe, barnumber) &&
         MathMax(iHigh(pair, timeframe, barnumber + 1), iHigh(pair, timeframe, barnumber)) - 
         MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber)) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("2;01;Tweezer Bottom");
   }else if( // Tweezer Top
      getinfo(8, pair, timeframe, barnumber) > -25 &&
      getinfo(8, pair, timeframe, barnumber) < 0 &&
      getinfo(8, pair, timeframe, barnumber + 1) < 25 &&
      getinfo(8, pair, timeframe, barnumber + 1) > 0 &&
      iClose(pair, timeframe, barnumber + 1) < getinfo(150, pair, timeframe, barnumber + 1) &&
      iClose(pair, timeframe, barnumber) < getinfo(150, pair, timeframe, barnumber) &&
         MathMax(iHigh(pair, timeframe, barnumber + 1), iHigh(pair, timeframe, barnumber)) - 
         MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber)) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("2;-1;Tweezer Top");
   }else if( // Bullish/Long Engulfing
      getinfo(8, pair, timeframe, barnumber + 1) < -50 &&
      iClose(pair, timeframe, barnumber) > iHigh(pair, timeframe, barnumber + 1) &&
         MathMax(iHigh(pair, timeframe, barnumber + 1), iHigh(pair, timeframe, barnumber)) - 
         MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber)) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("2;01;Bullish/Long Engulfing");
   }else if( // Bearish/Short Engulfing
      getinfo(8, pair, timeframe, barnumber + 1) > 50 &&
      iClose(pair, timeframe, barnumber) < iLow(pair, timeframe, barnumber + 1) &&
         MathMax(iHigh(pair, timeframe, barnumber + 1), iHigh(pair, timeframe, barnumber)) - 
         MathMin(iLow(pair, timeframe, barnumber + 1), iLow(pair, timeframe, barnumber)) >
         getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("2;-1;Bearish/Short Engulfing");
   }else if( // Hammer
      getinfo(8, pair, timeframe, barnumber) < 25 &&
      getinfo(8, pair, timeframe, barnumber) > 0 &&
      iClose(pair, timeframe, barnumber) > getinfo(130, pair, timeframe, barnumber)  &&
         iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber) > getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("1;01;Hammer");
   }else if( // Hanging Man
      getinfo(8, pair, timeframe, barnumber) > -25 &&
      getinfo(8, pair, timeframe, barnumber) < 0 &&
      iClose(pair, timeframe, barnumber) < getinfo(170, pair, timeframe, barnumber)  &&
         iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber) > getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("1;-1;Hanging Man");
   }else if( // Inverted Hammer
      getinfo(8, pair, timeframe, barnumber) < 25 &&
      getinfo(8, pair, timeframe, barnumber) > 0 &&
      iClose(pair, timeframe, barnumber) < getinfo(170, pair, timeframe, barnumber) &&
         iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber) > getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("1;01;Inverted Hammer");
   }else if( // Shooting Star
      getinfo(8, pair, timeframe, barnumber) > -25 &&
      getinfo(8, pair, timeframe, barnumber) < 0 &&
      iClose(pair, timeframe, barnumber) > getinfo(130, pair, timeframe, barnumber) &&
         iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber) > getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("1;-1;Shooting Star");
   }else if( // Bullish Marubozu
      getinfo(8, pair, timeframe, barnumber) > 100 - funcvar_snap &&
         iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber) > getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("1;01;Bullish Marubozu");
   }else if( // Bearish Marubozu
      getinfo(8, pair, timeframe, barnumber) < -100 + funcvar_snap &&
         iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber) > getinfo(502, pair, timeframe, barnumber) * funcvar_spreadfactor 
   ){
      return("1;-1;Bearish Marubozu");
   }else{
      
      return("0;N;none");
   }
}

double getinfo(int what, string pair, int timeframe, int barnumber) {
   int 
      j = 0,
      funcvar_errornumber, 
      funcvar_done;
   double
      funcvar_checkvalue;
   
   if(what < 500){
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
            Sleep(20);
            GetLastError();
            funcvar_checkvalue = iTime(pair, timeframe, barnumber);
            funcvar_errornumber = GetLastError();
            log("Attempting to get "+pair+" "+timeframe+" "+barnumber+" and recieved "+funcvar_errornumber+": "+ErrorDescription(funcvar_errornumber));
            j++;
            if(j>6){
               log(pair+" unabled to be resolved. Data only available back to barnumber "+(barnumber-1)+" dated: "+humandate(iTime(pair, timeframe, barnumber-10)));
               global_lookback = TimeCurrent()-iTime(pair, timeframe, barnumber-1);
               return(0);
            }
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
      case 8: // Marubozu Ratiing
         return((iClose(pair, timeframe, barnumber)*1000 - iOpen(pair, timeframe, barnumber)*1000) / (iHigh(pair, timeframe, barnumber)*1000 - iLow(pair, timeframe, barnumber)*1000 + 0.01) * 100);
         break;
      case 110: // 10% of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.1);
         break;
      case 120: // 20% of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.2);
         break;
      case 130: // 30% of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.3);
         break;
      case 140: // 40% of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.4);
         break;
      case 150: // middle of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.5);
         break;
      case 160: // 60% of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.6);
         break;
      case 170: // 70% of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.7);
         break;
      case 180: // 80% of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.8);
         break;
      case 190: // 90% of range from high of bar
         return(iHigh(pair, timeframe, barnumber) - (iHigh(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber))*0.9);
         break;
      case 300: // Gradient
         return(MathRound((iMA(pair, timeframe, 20, 0, MODE_EMA, PRICE_TYPICAL, barnumber) - iMA(pair, timeframe, 20, 0, MODE_EMA, PRICE_TYPICAL, barnumber + 1)) / MarketInfo(pair, MODE_POINT)) );
         break;
      case 500: // Spread
         return(MarketInfo(pair, MODE_SPREAD)*2);
         break;
      case 501: // Point
         return(MarketInfo(pair, MODE_POINT));
         break;
      case 502: // Spread as double
         return(MarketInfo(pair, MODE_SPREAD)*2*MarketInfo(pair, MODE_POINT));
      default:
         log("***Improper Selection made in switch for function getinfo*** Looking for "+what);
         return(0);
         break;
   }
   return(false);
}

string getinfosummary(string pair, int timeframe, int barnumber) {
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
         Sleep(2000);
         GetLastError();
         funcvar_checkvalue = iTime(pair, timeframe, barnumber);
         funcvar_errornumber = GetLastError();
         log("Attempting to get "+pair+" "+timeframe+" "+barnumber+" and recieved "+funcvar_errornumber+": "+ErrorDescription(funcvar_errornumber));
         j++;
         if(j>6){
            log(pair+" unabled to be resolved. Data only available back to "+humandate(iTime(pair, timeframe, barnumber-1)) );
            global_lookback = TimeCurrent()-iTime(pair, timeframe, barnumber-1);
            return(0);
         }
      }
   }
  
   return(humandate(iTime(pair, timeframe, barnumber))+";"+iOpen(pair, timeframe, barnumber)+";"+iHigh(pair, timeframe, barnumber)+";"+iLow(pair, timeframe, barnumber)+";"+iClose(pair, timeframe, barnumber)+";"+iVolume(pair, timeframe, barnumber));
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
   FileWrite(funcvar_logfile, humandate(TimeLocal()), ErrorDescription(GetLastError()), msg);
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
      for(int a=0;a<ArraySize(headerarray);a++){
         funcvar_headerstring = funcvar_headerstring + headerarray[a] + ";";
      }
      GetLastError();
      FileWrite(funcvar_filenumber, funcvar_headerstring);
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

void get_data(){

   int 
      funcvar_base,
      funcvar_traded,
      funcvar_barnumber = 0;
   
   for(funcvar_base = 0; funcvar_base < ArraySize(global_entities); funcvar_base++){
      for(funcvar_traded = 0; funcvar_traded < ArraySize(global_entities); funcvar_traded++){
         global_pair = global_entities[funcvar_base] + global_entities[funcvar_traded];
         if(
            global_entities[funcvar_base] != global_entities[funcvar_traded] &&
            //global_pair != global_entities[ArrayBsearch(global_excludes, global_pair)] &&
            MarketInfo(global_pair, MODE_TRADEALLOWED) == 1 
         ){
            GetLastError();
            funcvar_barnumber = 1;
            log("Fetching: "+global_pair);
            while(getinfo(5, global_pair, global_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback)){
               funcvar_barnumber++;
            }
         }
      }
   }
   Alert("Got all available "+global_timeframe+" minute data back to "+humandate(TimeCurrent() - global_lookback) );
   return(0);
}

string humandate(int unixdate){
   string 
      minuteprepend = "",
      hourprepend = "",
      dayprepend = "",
      monthprepend = "";
   if(TimeHour(unixdate) < 10){
      hourprepend = "0";
   }
   if(TimeMinute(unixdate) < 10){
      minuteprepend = "0";
   }
   if(TimeDay(unixdate) < 10){
      dayprepend = "0";
   }
   if(TimeMonth(unixdate) < 10){
      monthprepend = "0";
   }
   return( TimeYear(unixdate)+"-"+monthprepend+TimeMonth(unixdate)+"-"+dayprepend+TimeDay(unixdate)+"@"+hourprepend+TimeHour(unixdate)+":"+minuteprepend+TimeMinute(unixdate) );
}


// --------------------------------------------------------------------------------------------
// -------------------------------------- Output Functions ------------------------------------
// --------------------------------------------------------------------------------------------

void out_bartypedata(string pair = "NULL"){
  
   int
      funcvar_file,
      funcvar_barnumber = global_lookforward + 1;

   double
      funcvar_spread = getinfo(500, pair, global_timeframe, funcvar_barnumber),
      funcvar_point = getinfo(501, pair, global_timeframe, funcvar_barnumber),
      funcvar_gradient = 0;

   string
      funcvar_bartype = "",
      funcvar_holdingvar = "",
      funcvar_filename = "bartypedata.csv";
        
   // -- Handle file --
   if(pair == "NULL"){
      string headerarray[15] = {"pair", "date", "open", "high", "low", "close", "volume", "bars in formation", "L/S?", "bartype", "spread", "Target", "failled", "gradient"};
      funcvar_file = openafile(funcvar_filename, headerarray);
      FileClose(funcvar_file);
      return(0);
   }else{
      funcvar_file = openafile(funcvar_filename, dummy);
   }
   
   while(getinfo(5, pair, global_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback + global_timeframe * 4)){
      funcvar_holdingvar = "";
      funcvar_bartype = getbartype(pair, global_timeframe, funcvar_barnumber); 
      funcvar_gradient = getinfo(300, pair, global_timeframe, funcvar_barnumber);
      if(StringSubstr(funcvar_bartype,0,1) == "2" || StringSubstr(funcvar_bartype,0,1) == "3"){
         if(StringSubstr(funcvar_bartype,2,2) == "01"){
            if(
               getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, global_lookforward) / funcvar_point < getinfo(500, pair, global_timeframe, funcvar_barnumber) * 2
            ){
               funcvar_holdingvar = "FAIL";
            }
            FileWrite(funcvar_file, 
               pair, 
               getinfosummary(pair, global_timeframe, funcvar_barnumber), 
               funcvar_bartype, 
               getinfo(500, pair, global_timeframe, funcvar_barnumber), 
               getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, global_lookforward) / funcvar_point,
               funcvar_holdingvar,
               funcvar_gradient
            );
         }
            
         if(StringSubstr(funcvar_bartype,2,2) == "-1"){
            if(
               getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, global_lookforward) / funcvar_point < getinfo(500, pair, global_timeframe, funcvar_barnumber) * 2
            ){
               funcvar_holdingvar = "FAIL";
            }
            FileWrite(funcvar_file, 
               pair, 
               getinfosummary(pair, global_timeframe, funcvar_barnumber), 
               funcvar_bartype, 
               getinfo(500, pair, global_timeframe, funcvar_barnumber), 
               getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, global_lookforward) / funcvar_point,
               funcvar_holdingvar,
               funcvar_gradient
            );
         }
      } 
      funcvar_barnumber++;
   }

   FileClose(funcvar_file);
   return(0);
}

double getmaxhighafterclose(string pair, int timeframe, int barnumber, int barsback){
   double maximumdistance = 0;
   for(int a=1;a<=barsback;a++){
      maximumdistance = MathMax(iHigh(pair, timeframe, barnumber - a) - iClose(pair, timeframe, barnumber), maximumdistance); 
   }
   return(maximumdistance);
}

double getmaxlowafterclose(string pair, int timeframe, int barnumber, int barsback){
   double maximumdistance = 0;
   for(int a=1;a<=barsback;a++){
      maximumdistance = MathMax(iClose(pair, timeframe, barnumber) - iLow(pair, timeframe, barnumber - a), maximumdistance); 
   }
   return(maximumdistance);
}