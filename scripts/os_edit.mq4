int start(){ 

   int value_numberoforders = OrdersTotal();

   string name_pp,name_sl,name_tp;

   for(int a=0; a < value_numberoforders; a++){
      
      OrderSelect(a, SELECT_BY_POS, MODE_TRADES);
      
      if(OrderSymbol() == Symbol() && (OrderType() == OP_BUY || OrderType() == OP_SELL)){
         
         name_sl = Symbol()+"_"+OrderTicket()+"_SL";
         name_tp = Symbol()+"_"+OrderTicket()+"_TP";
   
         if(ObjectFind(name_sl) == -1){
            ObjectCreate(name_sl, OBJ_HLINE, 0, TimeCurrent(), OrderStopLoss());
         }else{
            ObjectSet(name_sl, OBJPROP_PRICE1, OrderStopLoss());
         }
         ObjectSet(name_sl, OBJPROP_STYLE, STYLE_DASH);
         ObjectSet(name_sl, OBJPROP_COLOR, Red);
   
         if(ObjectFind(name_tp) == -1){
            ObjectCreate(name_tp, OBJ_HLINE, 0, TimeCurrent(), OrderTakeProfit());
         }else{
            ObjectSet(name_tp, OBJPROP_PRICE1, OrderTakeProfit());
         }
         ObjectSet(name_tp, OBJPROP_STYLE, STYLE_DASH);
         ObjectSet(name_tp, OBJPROP_COLOR, Green);
   
      }else{
   
         name_pp = Symbol()+"_"+OrderTicket()+"_PP";
         name_sl = Symbol()+"_"+OrderTicket()+"_SL";
         name_tp = Symbol()+"_"+OrderTicket()+"_TP";
   
         if(ObjectFind(name_pp) == -1){
            ObjectCreate(name_pp, OBJ_HLINE, 0, TimeCurrent(), OrderOpenPrice());
         }else{
            ObjectSet(name_pp, OBJPROP_PRICE1, OrderOpenPrice());
         }
         ObjectSet(name_pp, OBJPROP_STYLE, STYLE_DASH);
         ObjectSet(name_pp, OBJPROP_COLOR, Yellow);
   
         if(ObjectFind(name_sl) == -1){
            ObjectCreate(name_sl, OBJ_HLINE, 0, TimeCurrent(), OrderStopLoss());
         }else{
            ObjectSet(name_sl, OBJPROP_PRICE1, OrderStopLoss());
         }
         ObjectSet(name_sl, OBJPROP_STYLE, STYLE_DASH);
         ObjectSet(name_sl, OBJPROP_COLOR, Red);
   
         if(ObjectFind(name_tp) == -1){
            ObjectCreate(name_tp, OBJ_HLINE, 0, TimeCurrent(), OrderTakeProfit());
         }else{
            ObjectSet(name_tp, OBJPROP_PRICE1, OrderTakeProfit());
         }
         ObjectSet(name_tp, OBJPROP_STYLE, STYLE_DASH);
         ObjectSet(name_tp, OBJPROP_COLOR, Green);
      }
   }
      
   return;
}