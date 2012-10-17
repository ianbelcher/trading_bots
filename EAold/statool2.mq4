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

/*
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
*/

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
   global_timeframe = DAY; //5 * MINUTE;
   global_lookback = 60 * (MONTH * 6);
   global_lookforward = 20;

   int 
      rep = 0,
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
            //for(rep=10;rep<100;rep=rep+10){
               out_movement(global_pair);
            //}
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

void out_movement(string pair = "NULL", int length_factor = 0){
   int
      a,
      funcvar_factor = 2, 
      funcvar_count,
      funcvar_barnumber = global_lookforward,
      funcvar_gradient,
      funcvar_file,
      funcvar_volume,
      funcvar_file_summary;

   double
      funcvar_periodhigh = 0,
      funcvar_periodlow = 0,
      funcvar_bounce = 0,
      funcvar_gain_long = 0,
      funcvar_trades_long = 0,
      funcvar_gain_short = 0,
      funcvar_trades_short = 0,
      funcvar_point = getinfo(501, pair, global_timeframe, funcvar_barnumber);
            
   string
      funcvar_functions,
      funcvar_stringtoadd,
      funcvar_filename = "movementtest.csv",
      funcvar_filename_summary = "movementtest_summary.csv";
      
   // -- Handle file --
   if(pair == "NULL"){
      string headerarray[50] = {
      "pair", "date", "open", "high", "low", "close", "volume", "spread", "length_factor",
      "long/short", 
      "Marobuzu",
      "Long Term Gradient",
      //"1 range", "5 range", "10 range", "15 range", "20 range", 
      "1 position", "1 close", "1 dd", 
      "2 position", "2 close", "2 dd", 
      "3 position", "3 close", "3 dd",
      "4 position", "4 close", "4 dd",
      "5 position", "5 close", "5 dd",
      "6 position", "6 close", "6 dd", 
      "7 position", "7 close", "7 dd", 
      "8 position", "8 close", "8 dd",
      "9 position", "9 close", "9 dd",
      "10 position", "10 close", "10 dd",
      "11 position", "11 close", "11 dd", 
      "12 position", "12 close", "12 dd", 
      "13 position", "13 close", "13 dd",
      "14 position", "14 close", "14 dd",
      "15 position", "15 close", "15 dd",
      "16 position", "16 close", "16 dd", 
      "17 position", "17 close", "17 dd", 
      "18 position", "18 close", "18 dd",
      "19 position", "19 close", "19 dd",
      "20 position", "20 close", "20 dd",
      "","gradient",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      "=SUM(R[1]C:R[20000]C) - SUMIF(R[1]C:R[20000]C,\"!\",R[1]C9:R[20000]C9)*5",
      };
      funcvar_file = openafile(funcvar_filename, headerarray);
      FileClose(funcvar_file);
      string headerarray2[6] = {"date", "pair", "length_factor", "gain_long", "trades_long", "gain_short", "trades_short", "total_gain", "total trades", "spread", "bounce", "volume"};
      funcvar_file_summary = openafile(funcvar_filename_summary, headerarray2);
      FileClose(funcvar_file_summary);
      return(0);
   }else{
      funcvar_file = openafile(funcvar_filename, dummy);
      funcvar_file_summary = openafile(funcvar_filename_summary, dummy);
   }
   
   if(length_factor == 0){
      length_factor = getinfo(500, pair, global_timeframe, funcvar_barnumber);
   }
   
   funcvar_bounce = 0;
   funcvar_periodhigh = 0;
   funcvar_periodlow = 200;
   funcvar_barnumber = global_lookforward + 5;
   funcvar_functions = "=IF(RC[-60]<-1500,\"!\",RC[-62]);"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-58]<-1500,\"!\",RC[-60]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-56]<-1500,\"!\",RC[-58]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-54]<-1500,\"!\",RC[-56]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-52]<-1500,\"!\",RC[-54]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-50]<-1500,\"!\",RC[-52]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-48]<-1500,\"!\",RC[-50]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-46]<-1500,\"!\",RC[-48]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-44]<-1500,\"!\",RC[-46]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-42]<-1500,\"!\",RC[-44]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-40]<-1500,\"!\",RC[-42]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-38]<-1500,\"!\",RC[-40]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-36]<-1500,\"!\",RC[-38]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-34]<-1500,\"!\",RC[-36]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-32]<-1500,\"!\",RC[-34]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-30]<-1500,\"!\",RC[-32]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-28]<-1500,\"!\",RC[-30]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-26]<-1500,\"!\",RC[-28]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-24]<-1500,\"!\",RC[-26]));"+
   "=IF(RC[-1]=\"!\", \"!\",IF(RC[-22]<-1500,\"!\",RC[-24]));";
   
   while(getinfo(5, pair, global_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback + global_lookforward)){
      funcvar_bounce = funcvar_bounce + getinfo(7, pair, global_timeframe, funcvar_barnumber);
      funcvar_periodhigh = MathMax(funcvar_periodhigh, getinfo(2, pair, global_timeframe, funcvar_barnumber));
      funcvar_periodlow = MathMin(funcvar_periodlow, getinfo(3, pair, global_timeframe, funcvar_barnumber));
      funcvar_volume = funcvar_volume + getinfo(6, pair, global_timeframe, funcvar_barnumber);
      funcvar_count++;
      
      funcvar_barnumber++;
   }
   funcvar_bounce = funcvar_bounce / (funcvar_periodhigh - funcvar_periodlow);
   
   funcvar_barnumber = global_lookforward + 5;
   while(getinfo(5, pair, global_timeframe, funcvar_barnumber) > (TimeCurrent() - global_lookback + global_lookforward)){
      funcvar_gradient = getinfo(300, pair, global_timeframe, funcvar_barnumber);
      if(funcvar_gradient > funcvar_factor * length_factor){
         funcvar_stringtoadd = "";
         for(a = 1 ; a <= global_lookforward; a=a+1){
            funcvar_stringtoadd = 
            funcvar_stringtoadd +
            (iClose(pair, global_timeframe, funcvar_barnumber - a)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - length_factor) +";"+
            iClose(pair, global_timeframe, funcvar_barnumber - a) +";"+
            (iLow(pair, global_timeframe, funcvar_barnumber - a)/ funcvar_point - iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - length_factor)+";";
         }
         FileWrite(funcvar_file, 
            pair, 
            getinfosummary(pair, global_timeframe, funcvar_barnumber),
            getinfo(500, pair, global_timeframe, funcvar_barnumber),
            length_factor,
            " 1", 
            getinfo(8, pair, global_timeframe, funcvar_barnumber),
            getinfo(301, pair, global_timeframe, funcvar_barnumber),
            //getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 1) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 1) / funcvar_point - length_factor,
            //getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 5) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 5) / funcvar_point - length_factor,
            //getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 10) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 10) / funcvar_point - length_factor,
            //getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 15) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 15) / funcvar_point - length_factor,
            //getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 20) / funcvar_point - getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 20) / funcvar_point - length_factor,
            funcvar_stringtoadd,     
            funcvar_gradient,
            funcvar_functions
         );
         funcvar_gain_long = funcvar_gain_long + 
                        iClose(pair, global_timeframe, funcvar_barnumber - 20) / funcvar_point
                        - iClose(pair, global_timeframe, funcvar_barnumber) / funcvar_point
                        - length_factor;
         funcvar_trades_long++;
      }
      if(funcvar_gradient < -1 * funcvar_factor * length_factor){
         funcvar_stringtoadd = "";
         for(a = 1 ; a <= global_lookforward; a=a+1){
            funcvar_stringtoadd = 
            funcvar_stringtoadd +
            (iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - length_factor - iClose(pair, global_timeframe, funcvar_barnumber- a) / funcvar_point) +";"+
            iClose(pair, global_timeframe, funcvar_barnumber - a) +";"+
            (iClose(pair, global_timeframe, funcvar_barnumber)/ funcvar_point - length_factor - iHigh(pair, global_timeframe, funcvar_barnumber - a) / funcvar_point)+ ";";
         }
         FileWrite(funcvar_file, 
            pair, 
            getinfosummary(pair, global_timeframe, funcvar_barnumber), 
            getinfo(500, pair, global_timeframe, funcvar_barnumber), 
            length_factor,
            "-1",
            getinfo(8, pair, global_timeframe, funcvar_barnumber),
            getinfo(301, pair, global_timeframe, funcvar_barnumber),
            //getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 1) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 1) / funcvar_point - length_factor, 
            //getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 5) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 5) / funcvar_point - length_factor, 
            //getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 10) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 10) / funcvar_point - length_factor,
            //getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 15) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 15) / funcvar_point - length_factor,
            //getmaxlowafterclose(pair, global_timeframe, funcvar_barnumber, 20) / funcvar_point - getmaxhighafterclose(pair, global_timeframe, funcvar_barnumber, 20) / funcvar_point - length_factor, 
            funcvar_stringtoadd,
            funcvar_gradient,
            funcvar_functions
         );
         funcvar_gain_short = funcvar_gain_short
                        + iClose(pair, global_timeframe, funcvar_barnumber) / funcvar_point
                        - length_factor
                        - iClose(pair, global_timeframe, funcvar_barnumber - 20) / funcvar_point;
         funcvar_trades_short++;
      }
      funcvar_barnumber++;
   }
   
   FileWrite(funcvar_file_summary, 
      humandate(TimeLocal()),
      pair,
      length_factor,
      funcvar_gain_long,
      funcvar_trades_long,
      funcvar_gain_short,
      funcvar_trades_short,
      funcvar_gain_long + funcvar_gain_short,
      funcvar_trades_long + funcvar_trades_short,
      getinfo(500, pair, global_timeframe, funcvar_barnumber),
      funcvar_bounce,
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
      case 301: // Long Term Gradient
         return(MathRound((iMA(pair, timeframe, 200, 0, MODE_EMA, PRICE_TYPICAL, barnumber) - iMA(pair, timeframe, 200, 0, MODE_EMA, PRICE_TYPICAL, barnumber + 1)) / MarketInfo(pair, MODE_POINT)) );
         break;
      case 500: // Spread
         return(MarketInfo(pair, MODE_SPREAD));
         break;
      case 501: // Point
         return(MarketInfo(pair, MODE_POINT));
         break;
      case 502: // Spread as double
         return(MarketInfo(pair, MODE_SPREAD)*MarketInfo(pair, MODE_POINT));
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