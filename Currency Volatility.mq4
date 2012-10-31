//+------------------------------------------------------------------+
//|                                          Currency Volatility.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

extern int GLOBAL_periodlong = 1;
extern int GLOBAL_timeframe = 1440;

string GLOBAL_entities[8] = {"USD", "EUR", "GBP", "CHF", "JPY", "CAD", "AUD", "NZD"}; //, "SGD", "DKK", "NOK", "SEK", "PLN", "MXN", "XAU", "XAG" };
string GLOBAL_pairs[64];
double GLOBAL_rating[64];
double GLOBAL_ratingholderincl[64];
double GLOBAL_ratingholderexcl[64];
double GLOBAL_movement[64];
double GLOBAL_CDe[64];

int 
      FUNCVAR_counter,
      FUNCVAR_basecurrency,
      FUNCVAR_basecurrency2,
      FUNCVAR_tradedcurrency,
      FUNCVAR_tradedcurrency2,
      FUNCVAR_barcounter,
      FUNCVAR_currenttime,
      a
      ;
string 
      FUNCVAR_base,
      FUNCVAR_base2,
      FUNCVAR_traded,
      FUNCVAR_traded2,
      FUNCVAR_text,
      FUNCVAR_aprepend,
      FUNCVAR_bprepend,
      FUNCVAR_cprepend,
      FUNCVAR_dprepend,
      FUNCVAR_orderpropend
      ;
   
double
      FUNCVAR_amount
      ;

int init(){
   
      log();
      ObjectCreate("heading", OBJ_LABEL, 0, 0, 0);
      ObjectSet("heading", OBJPROP_XDISTANCE, 20);
      ObjectSet("heading", OBJPROP_YDISTANCE, 30);
      ObjectSetText("heading", "    Pair    Value "+TimeCurrent() , 9, "Courier New", Black);   
      
      ObjectCreate("background", OBJ_RECTANGLE, 0, 0, 0, TimeCurrent()*2, 200);
      ObjectSet("background", OBJPROP_COLOR, White);
      
      for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_pairs);FUNCVAR_counter++){      
         ObjectCreate("text"+FUNCVAR_counter, OBJ_LABEL, 0, 0, 0);
         ObjectSet("text"+FUNCVAR_counter, OBJPROP_XDISTANCE, 20);
         ObjectSet("text"+FUNCVAR_counter, OBJPROP_YDISTANCE, 40 + 10*FUNCVAR_counter);
         ObjectSet("text"+FUNCVAR_counter, OBJPROP_WIDTH, 400);
      }
      
      for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_pairs);FUNCVAR_counter++){      
         ObjectCreate("textc2"+FUNCVAR_counter, OBJ_LABEL, 0, 0, 0);
         ObjectSet("textc2"+FUNCVAR_counter, OBJPROP_XDISTANCE, 400);
         ObjectSet("textc2"+FUNCVAR_counter, OBJPROP_YDISTANCE, 40 + 10*FUNCVAR_counter);
         ObjectSet("textc2"+FUNCVAR_counter, OBJPROP_WIDTH, 400);
      }    
   
}

int start(){

   if(FUNCVAR_currenttime + 5 < TimeCurrent()){
      FUNCVAR_currenttime = TimeCurrent();
      FUNCVAR_counter = 0;
      for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
         for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
            FUNCVAR_base = GLOBAL_entities[FUNCVAR_basecurrency];
            FUNCVAR_traded = GLOBAL_entities[FUNCVAR_tradedcurrency];
            if(
               MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TRADEALLOWED) == 1 &&
               MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_SPREAD) > 0 &&
               MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_POINT) > 0
            ){
               GLOBAL_pairs[FUNCVAR_counter] = FUNCVAR_base+FUNCVAR_traded;
               for(FUNCVAR_barcounter = 1; FUNCVAR_barcounter <= GLOBAL_periodlong; FUNCVAR_barcounter++){
                  GLOBAL_rating[FUNCVAR_counter] += iHigh(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, FUNCVAR_barcounter) - iLow(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, FUNCVAR_barcounter);
               }
               GLOBAL_rating[FUNCVAR_counter] = (GLOBAL_rating[FUNCVAR_counter] / GLOBAL_periodlong) / (MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_SPREAD) * MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_POINT));
               
               for(a=0;a<65;a++){ // Clear array before populating
                  GLOBAL_ratingholderincl[a] = 0;
                  GLOBAL_ratingholderexcl[a] = 0;
               }
                              
               for(FUNCVAR_basecurrency2 = 0; FUNCVAR_basecurrency2 < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency2++){
                  for(FUNCVAR_tradedcurrency2 = 0; FUNCVAR_tradedcurrency2 < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency2++){
                     FUNCVAR_base2 = GLOBAL_entities[FUNCVAR_basecurrency2];
                     FUNCVAR_traded2 = GLOBAL_entities[FUNCVAR_tradedcurrency2];
                     if(
                        MarketInfo(FUNCVAR_base2+FUNCVAR_traded2, MODE_TRADEALLOWED) == 1 &&
                        MarketInfo(FUNCVAR_base2+FUNCVAR_traded2, MODE_SPREAD) > 0 //&&
                        //FUNCVAR_base+FUNCVAR_traded != FUNCVAR_base2+FUNCVAR_traded2
                     ){
                        FUNCVAR_amount = iClose(FUNCVAR_base2+FUNCVAR_traded2, GLOBAL_timeframe, 0) - iOpen(FUNCVAR_base2+FUNCVAR_traded2, GLOBAL_timeframe, GLOBAL_periodlong - 1);                       
                        FUNCVAR_amount = FUNCVAR_amount / MarketInfo(FUNCVAR_base2+FUNCVAR_traded2, MODE_TICKSIZE); // Get size in Ticks
                        FUNCVAR_amount = FUNCVAR_amount * MarketInfo(FUNCVAR_base2+FUNCVAR_traded2, MODE_TICKVALUE); // Get size in account currency
                                                
                        GLOBAL_ratingholderincl[FUNCVAR_basecurrency2] = GLOBAL_ratingholderincl[FUNCVAR_basecurrency2]+FUNCVAR_amount;
                        GLOBAL_ratingholderincl[FUNCVAR_tradedcurrency2] = GLOBAL_ratingholderincl[FUNCVAR_tradedcurrency2]-FUNCVAR_amount;
                        
                        if(FUNCVAR_base+FUNCVAR_traded != FUNCVAR_base2+FUNCVAR_traded2){
                           GLOBAL_ratingholderexcl[FUNCVAR_basecurrency2] = GLOBAL_ratingholderexcl[FUNCVAR_basecurrency2]+FUNCVAR_amount;
                           GLOBAL_ratingholderexcl[FUNCVAR_tradedcurrency2] = GLOBAL_ratingholderexcl[FUNCVAR_tradedcurrency2]-FUNCVAR_amount;
                        }
                                 
                     }
                  }
               }
               GLOBAL_movement[FUNCVAR_counter] = iClose(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, 0) - iOpen(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, GLOBAL_periodlong - 1);                                     
               GLOBAL_movement[FUNCVAR_counter] = GLOBAL_movement[FUNCVAR_counter] / MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_POINT) / 100000; // Get size in Ticks
               //GLOBAL_movement[FUNCVAR_counter] = GLOBAL_movement[FUNCVAR_counter] * MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TICKVALUE); // Get size in account currency
               //GLOBAL_movement[FUNCVAR_counter] = GLOBAL_movement[FUNCVAR_counter] / 100;
               GLOBAL_CDe[FUNCVAR_counter] = (GLOBAL_ratingholderexcl[FUNCVAR_basecurrency] - GLOBAL_ratingholderexcl[FUNCVAR_tradedcurrency]) / 1000;
               
               FUNCVAR_counter++;
            }
         }
      }
      //for(a=0;a<64;a++){
      //   log(GLOBAL_pairs[a]+";"+GLOBAL_CDe[a]);
      //}         
      
      
   
      double sortarray[64,2];
      for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_pairs);FUNCVAR_counter++){
         sortarray[FUNCVAR_counter, 0] = MathAbs(GLOBAL_CDe[FUNCVAR_counter]);
         sortarray[FUNCVAR_counter, 1] = FUNCVAR_counter;
      }
      ArraySort(sortarray, WHOLE_ARRAY, 0, MODE_DESCEND);
      
      double sortarray2[8,2];
      for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_entities);FUNCVAR_counter++){
         sortarray2[FUNCVAR_counter, 0] = GLOBAL_ratingholderincl[FUNCVAR_counter];
         sortarray2[FUNCVAR_counter, 1] = FUNCVAR_counter;
      }
      ArraySort(sortarray2, WHOLE_ARRAY, 0, MODE_DESCEND);
        
      int index;
      for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_pairs);FUNCVAR_counter++){
         index = sortarray[FUNCVAR_counter, 1];
         if(FUNCVAR_counter<10){
            FUNCVAR_aprepend = "0";
         }else{
            FUNCVAR_aprepend = "";
         }
         if(GLOBAL_rating[index] < 10 && GLOBAL_rating[index] > 0 ){
            FUNCVAR_bprepend = " ";
         }else{
            FUNCVAR_bprepend = "";
         }
         if(GLOBAL_movement[index] < 10 && GLOBAL_movement[index] > 0 ){
            FUNCVAR_cprepend = " ";
         }else{
            FUNCVAR_cprepend = "";
         }
         if(GLOBAL_CDe[index] < 10 && GLOBAL_CDe[index] > 0 ){
            FUNCVAR_dprepend = " ";
         }else{
            FUNCVAR_dprepend = "";
         }
         
         if(StringLen(GLOBAL_pairs[index])>1){
            FUNCVAR_text = 
               FUNCVAR_aprepend+FUNCVAR_counter+ ") "+
               GLOBAL_pairs[index]+" "+
               FUNCVAR_bprepend+NormalizeDouble(GLOBAL_rating[index],2)+"   "+
               FUNCVAR_cprepend+GLOBAL_movement[index]+"   "+
               FUNCVAR_dprepend+GLOBAL_CDe[index]+"   "+
               ""+" "+
               "";
               //StringSubstr(SIGNATURE_SUM_target[FUNCVAR_counter]+"     ",0,4)+" "+  
         }else{
            FUNCVAR_text = " ";
         }
         GLOBAL_rating[index] = 0;
         ObjectSetText("text"+FUNCVAR_counter, FUNCVAR_text, 9, "Courier New", Black);
         
         FUNCVAR_text = " ";
         index = sortarray2[FUNCVAR_counter, 1];
         if(StringLen(GLOBAL_entities[FUNCVAR_counter])>1){
            FUNCVAR_text = 
               FUNCVAR_aprepend+FUNCVAR_counter+ ") "+
               GLOBAL_entities[index]+" "+
               GLOBAL_ratingholderincl[index]+" "+
               "";
               //StringSubstr(SIGNATURE_SUM_target[FUNCVAR_counter]+"     ",0,4)+" "+  
         }

         ObjectSetText("textc2"+FUNCVAR_counter, FUNCVAR_text, 9, "Courier New", Black);
         
      }
      ObjectSetText("heading", "    Pair    Value "+TimeCurrent() , 9, "Courier New", Black);   
      
      GetLastError(); //Clear error associated with objects as they are not important.
   }
    
   return(0);
}

void log(string FUNCGET_msg = "NULL"){
   int 
      FUNCVAR_logfile,
      FUNCVAR_counter
      ;
   string 
      FUNCVAR_functionnamelist
      ;
      
   if(FUNCGET_msg == "NULL"){
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
      FileWrite(FUNCVAR_logfile, TimeLocal(), GetLastError(), FUNCVAR_functionnamelist, FUNCGET_msg);
   }
   FileClose(FUNCVAR_logfile);
}