
#include <stderror.mqh>
#include <stdlib.mqh>

int start(){ 
   double distance = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
   if(distance == 0){
      distance = MathAbs((Ask - Bid) * 2);
   }
   string name_pp = Symbol()+"_PP";
   string name_sl = Symbol()+"_SL";
   string name_tp = Symbol()+"_TP";
   int value_cmd = -1;
   int temp_error;
   
   double value_sl;
   if(ObjectFind(name_sl) != -1){
      value_sl =  NormalizeDouble(ObjectGet(name_sl, OBJPROP_PRICE1), MarketInfo(Symbol(), MODE_DIGITS));
   }else{
      value_sl = -1;
   }
  
   double value_tp;
   if(ObjectFind(name_tp) != -1){
      value_tp = NormalizeDouble(ObjectGet(name_tp, OBJPROP_PRICE1), MarketInfo(Symbol(), MODE_DIGITS));
   }else{
      value_tp = 0;
   }
   
   double value_pp;
   if(ObjectFind(name_pp) != -1){
      value_pp = NormalizeDouble(ObjectGet(name_pp, OBJPROP_PRICE1), MarketInfo(Symbol(), MODE_DIGITS));
      //Find BUYLIMIT etc based on positions
      if(value_pp > value_sl){ //Buy
         if(value_pp > Ask){
            value_cmd = 4; //BUYSTOP
         }else{
            value_cmd = 2; //BUYLIMIT
         }
      }else{ //Sell
         if(value_pp > Bid){
            value_cmd = 3; //SELLLIMIT
         }else{
            value_cmd = 5; //SELLSTOP
         }     
      }
   }else{
      if(value_tp > value_sl){ //Buy
         value_cmd = 0; //BUY
         value_pp = Ask;
      }else{ //Sell
         value_cmd = 1; //SELL
         value_pp = Bid;
      }
   }     
   
   double temp_ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   double temp_tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   if(temp_ticksize > 0 && temp_tickvalue > 0){
      double temp_targetinticks = MathAbs(value_pp - value_sl) / temp_ticksize;
      double value_volume = (0.01 * AccountBalance() / temp_targetinticks) / temp_tickvalue;
   }
   
   GetLastError();
   if(value_sl != -1){
      if(OrderSend(Symbol(), value_cmd, value_volume, value_pp, 10, value_sl, value_tp) == -1){
         temp_error = GetLastError();
         Alert("Error sending new order: " + temp_error+" "+ErrorDescription(temp_error));
         Alert(value_cmd+" "+value_pp+" "+value_sl+" "+value_tp);
      }else{
         ObjectDelete(name_pp);
         ObjectDelete(name_sl);
         ObjectDelete(name_tp);
      }
   }


   int value_numberoforders = OrdersTotal();
   for(int a=0; a < value_numberoforders; a++){
      
      OrderSelect(a, SELECT_BY_POS, MODE_TRADES);
      
      if(OrderSymbol() == Symbol()){
      
         name_pp = Symbol()+"_"+OrderTicket()+"_PP";
         name_sl = Symbol()+"_"+OrderTicket()+"_SL";
         name_tp = Symbol()+"_"+OrderTicket()+"_TP";
      
         if(ObjectFind(name_sl) != -1){
            value_sl = NormalizeDouble(ObjectGet(name_sl, OBJPROP_PRICE1), MarketInfo(Symbol(), MODE_DIGITS));
         }else{
            value_sl = OrderStopLoss();
         }
      
         if(ObjectFind(name_tp) != -1){
            value_tp = NormalizeDouble(ObjectGet(name_tp, OBJPROP_PRICE1), MarketInfo(Symbol(), MODE_DIGITS));
         }else{
            value_tp = OrderTakeProfit();
         }
      
         if(ObjectFind(name_pp) != -1){
            value_pp = NormalizeDouble(ObjectGet(name_pp, OBJPROP_PRICE1), MarketInfo(Symbol(), MODE_DIGITS));
         }else{
            value_pp = OrderOpenPrice();
         }
      
         if(OrderModify(OrderTicket(), value_pp, value_sl, value_tp, OrderExpiration()) == FALSE){
            temp_error = GetLastError();
            Alert("Error modifying "+OrderTicket()+": " + temp_error+" "+ErrorDescription(temp_error));
         }else{
            ObjectDelete(name_sl);
            ObjectDelete(name_tp);
            ObjectDelete(name_pp);
         }
      }
   }
   return;
}