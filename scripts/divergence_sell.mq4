
#include <stderror.mqh>
#include <stdlib.mqh>

int start(){ 
   double distance = (Ask - Bid) * 10;
   double value_sl = MarketInfo(Symbol(), MODE_BID) + distance;
   double value_tp = MarketInfo(Symbol(), MODE_BID) - distance;
   int value_cmd = 1;
   int temp_error;
     
   double temp_ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   double temp_tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   if(temp_ticksize > 0 && temp_tickvalue > 0){
      double temp_targetinticks = distance / temp_ticksize;
      double value_volume = (0.01 * AccountBalance() / temp_targetinticks) / temp_tickvalue;
   }
   
   GetLastError();
   if(value_sl > 0){
      if(OrderSend(Symbol(), value_cmd, value_volume, MarketInfo(Symbol(), MODE_BID), 20, value_sl, value_tp) == -1){
         temp_error = GetLastError();
         Alert("Error sending new order: " + temp_error+" "+ErrorDescription(temp_error));
         Alert(value_cmd+" "+value_sl+" "+value_tp);
      }
   }

   return;
}