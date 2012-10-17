//+------------------------------------------------------------------+
//|                                          Currency Volatility.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

extern int GLOBAL_period = 15;

string GLOBAL_entities[8] = {"USD", "CHF", "EUR", "GBP", "CAD", "JPY", "AUD", "NZD"}; //, "SGD", "DKK", "NOK", "SEK", "PLN", "MXN", "XAU", "XAG" };
string GLOBAL_pairs[64];
double GLOBAL_rating[64]; 

int init(){
   
}

int start(){

   int 
      FUNCVAR_counter,
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency,
      FUNCVAR_barcounter
      ;
   string 
      FUNCVAR_base,
      FUNCVAR_traded,
      FUNCVAR_text,
      FUNCVAR_aprepend,
      FUNCVAR_orderpropend
      ;
   
   for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
      for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
         FUNCVAR_base = GLOBAL_entities[FUNCVAR_basecurrency];
         FUNCVAR_traded = GLOBAL_entities[FUNCVAR_tradedcurrency];
         if(
            MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TRADEALLOWED) == 1 &&
            MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_SPREAD) > 0
         ){
            GLOBAL_pairs[FUNCVAR_counter] = FUNCVAR_base+FUNCVAR_traded;
            for(FUNCVAR_barcounter = 1; FUNCVAR_barcounter <= GLOBAL_period; FUNCVAR_barcounter++){
               GLOBAL_rating[FUNCVAR_counter] += iClose(FUNCVAR_base+FUNCVAR_traded, Period(), FUNCVAR_barcounter) - iOpen(FUNCVAR_base+FUNCVAR_traded, Period(), FUNCVAR_barcounter);
            }
            GLOBAL_rating[FUNCVAR_counter] = GLOBAL_rating[FUNCVAR_counter] / MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_SPREAD);
            FUNCVAR_counter++;
         }
      }
   }
   
   ObjectsDeleteAll();
      
   for(FUNCVAR_counter=0;FUNCVAR_counter<ArraySize(GLOBAL_pairs);FUNCVAR_counter++){
      if(FUNCVAR_counter<10){
         FUNCVAR_aprepend = "0";
      }else{
         FUNCVAR_aprepend = "";
      }
      FUNCVAR_text = 
         FUNCVAR_aprepend+FUNCVAR_counter+ ") "+
         GLOBAL_pairs[FUNCVAR_counter]+" "+
         GLOBAL_rating[FUNCVAR_counter]+" "+
         "";
         //StringSubstr(SIGNATURE_SUM_target[FUNCVAR_counter]+"     ",0,4)+" "+
         
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
        
   ObjectCreate("col2l1", OBJ_LABEL, 0, 0, 0);
   ObjectSet("col2l1", OBJPROP_XDISTANCE, 430);
   ObjectSet("col2l1", OBJPROP_YDISTANCE, 5);
   
   GetLastError(); //Clear error associated with objects as they are not important.
 
   return(0);
}