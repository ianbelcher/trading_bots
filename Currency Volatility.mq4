//+------------------------------------------------------------------+
//|                                          Currency Volatility.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

extern int GLOBAL_period = 3;

string GLOBAL_entities[8] = {"USD", "CHF", "EUR", "GBP", "CAD", "JPY", "AUD", "NZD"}; //, "SGD", "DKK", "NOK", "SEK", "PLN", "MXN", "XAU", "XAG" };
string GLOBAL_pairs[64];
double GLOBAL_rating[64]; 

int 
      FUNCVAR_counter,
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency,
      FUNCVAR_barcounter,
      FUNCVAR_currenttime
      ;
   string 
      FUNCVAR_base,
      FUNCVAR_traded,
      FUNCVAR_text,
      FUNCVAR_aprepend,
      FUNCVAR_bprepend,
      FUNCVAR_orderpropend
      ;
   

int init(){
   
      ObjectCreate("heading", OBJ_LABEL, 0, 0, 0);
      ObjectSet("heading", OBJPROP_XDISTANCE, 20);
      ObjectSet("heading", OBJPROP_YDISTANCE, 5);
      ObjectSetText("heading", "    Pair    Value" , 9, "Courier New", Black);   
      
      for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_pairs);FUNCVAR_counter++){      
         ObjectCreate("text"+FUNCVAR_counter, OBJ_LABEL, 0, 0, 0);
         ObjectSet("text"+FUNCVAR_counter, OBJPROP_XDISTANCE, 20);
         ObjectSet("text"+FUNCVAR_counter, OBJPROP_YDISTANCE, 15 + 10*FUNCVAR_counter);
         ObjectSet("text"+FUNCVAR_counter, OBJPROP_WIDTH, 400);
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
               for(FUNCVAR_barcounter = 1; FUNCVAR_barcounter <= GLOBAL_period; FUNCVAR_barcounter++){
                  GLOBAL_rating[FUNCVAR_counter] += iHigh(FUNCVAR_base+FUNCVAR_traded, Period(), FUNCVAR_barcounter) - iLow(FUNCVAR_base+FUNCVAR_traded, Period(), FUNCVAR_barcounter);
               }
               GLOBAL_rating[FUNCVAR_counter] = (GLOBAL_rating[FUNCVAR_counter] / GLOBAL_period) / (MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_SPREAD) * MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_POINT));
               FUNCVAR_counter++;
            }
         }
      }
   
      double sortarray[64,2];
      for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_pairs);FUNCVAR_counter++){
         sortarray[FUNCVAR_counter, 0] = GLOBAL_rating[FUNCVAR_counter];
         sortarray[FUNCVAR_counter, 1] = FUNCVAR_counter;
      }
      ArraySort(sortarray, WHOLE_ARRAY, 0, MODE_DESCEND);
        
      int index;
      for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_pairs);FUNCVAR_counter++){
         index = sortarray[FUNCVAR_counter, 1];
         if(FUNCVAR_counter<10){
            FUNCVAR_aprepend = "0";
         }else{
            FUNCVAR_aprepend = "";
         }
         if(GLOBAL_rating[index] >= 0){
            FUNCVAR_bprepend = " ";
         }else{
            FUNCVAR_bprepend = "";
         }
         if(StringLen(GLOBAL_pairs[index])>1){
            FUNCVAR_text = 
               FUNCVAR_aprepend+FUNCVAR_counter+ ") "+
               GLOBAL_pairs[index]+" "+
               FUNCVAR_bprepend+NormalizeDouble(GLOBAL_rating[index],2)+" "+
               "";
               //StringSubstr(SIGNATURE_SUM_target[FUNCVAR_counter]+"     ",0,4)+" "+  
         }else{
            FUNCVAR_text = " ";
         }
         GLOBAL_rating[index] = 0;
         ObjectSetText("text"+FUNCVAR_counter, FUNCVAR_text, 9, "Courier New", Black);
      }
          
      GetLastError(); //Clear error associated with objects as they are not important.
   }
    
   return(0);
}