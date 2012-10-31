int start(){ 
   double price = Bid;
   double distance = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
   if(distance == 0){
      distance = MathAbs((Ask - Bid) * 4);
   }
   string name_pp = Symbol()+"_PP";
   string name_sl = Symbol()+"_SL";
   string name_tp = Symbol()+"_TP";
   
   if(ObjectFind(name_pp) == -1){
      ObjectCreate(name_pp, OBJ_HLINE, 0, TimeCurrent(), price);
   }else{
      ObjectSet(name_pp, OBJPROP_PRICE1, price);
   }
   ObjectSet(name_pp, OBJPROP_STYLE, STYLE_DASH);
   ObjectSet(name_pp, OBJPROP_COLOR, DodgerBlue);
   
   if(ObjectFind(name_sl) == -1){
      ObjectCreate(name_sl, OBJ_HLINE, 0, TimeCurrent(), price - distance);
   }else{
      ObjectSet(name_sl, OBJPROP_PRICE1, price - distance);
   }
   ObjectSet(name_sl, OBJPROP_STYLE, STYLE_DASH);
   ObjectSet(name_sl, OBJPROP_COLOR, Red);
   
   if(ObjectFind(name_tp) == -1){
      ObjectCreate(name_tp, OBJ_HLINE, 0, TimeCurrent(), price + distance);
   }else{
      ObjectSet(name_tp, OBJPROP_PRICE1, price + distance);
   }
   ObjectSet(name_tp, OBJPROP_STYLE, STYLE_DASH);
   ObjectSet(name_tp, OBJPROP_COLOR, Green);
      
   return;
}