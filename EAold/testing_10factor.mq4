//+------------------------------------------------------------------+
//|                                            testing_withtrend.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

double 
   FUNCVAR_lossfactor = 10,
   FUNCVAR_startpercentage = 0.01,
   FUNCVAR_risk = 0.01,
   FUNCVAR_balance
   ;

int
   FUNCVAR_ticket,
   FUNCVAR_risknumber
   ;
   
string
   FUNCVAR_current
   ;

int init(){

   FUNCVAR_balance = AccountBalance();

}

int start(){
   

   
   if(
      OrdersTotal() == 0
   ){
   
      if(AccountBalance() > FUNCVAR_balance){
         //A higher account balance means the last trade won.
         //In this case, we'll reset the risk to inital
         FUNCVAR_risknumber = 0;
         FUNCVAR_risk = FUNCVAR_startpercentage;
         
      }else{
         //A lower account balance means the last trade lost.
         //In this case, we'll reverse the direction
         if(FUNCVAR_current == "SELL"){
            FUNCVAR_current = "BUY";
         }else{
            FUNCVAR_current = "SELL";
         }
         if(FUNCVAR_risknumber == 2){
            FUNCVAR_risknumber = 0;
         }
      }
   
      FUNCVAR_balance = AccountBalance();
            
      double FUNCVAR_distance = (MarketInfo(Symbol(), MODE_STOPLEVEL)) * Point;
      
      double FUNCVAR_lots = MathMax(order_getlotsize(FUNCVAR_distance, Symbol(), FUNCVAR_risk), MarketInfo(Symbol(), MODE_MINLOT));

      if(FUNCVAR_current == "SELL"){
         FUNCVAR_ticket = OrderSend(Symbol(), OP_BUY, FUNCVAR_lots, Ask, 2, Ask - (FUNCVAR_distance*2), Ask + (FUNCVAR_distance * FUNCVAR_lossfactor));
         FUNCVAR_current = "BUY";
      }else{
         FUNCVAR_ticket = OrderSend(Symbol(), OP_SELL, FUNCVAR_lots, Bid, 2, Bid + (FUNCVAR_distance*2), Bid - (FUNCVAR_distance * FUNCVAR_lossfactor));
         FUNCVAR_current = "SELL";
      }
         
      if(FUNCVAR_ticket > 0){
         FUNCVAR_risk = FUNCVAR_risk * FUNCVAR_lossfactor;
         FUNCVAR_risknumber++;
      }
   
   }
   
}


double order_getlotsize(double FUNCGET_target, string FUNCGET_currency, double FUNCGET_risk){
  
   double
      FUNCVAR_targetinticks,
      FUNCVAR_tickvalue,
      FUNCVAR_ticksize,
      FUNCVAR_lots
      ;
   
   RefreshRates();
   FUNCVAR_ticksize = MarketInfo(FUNCGET_currency, MODE_TICKSIZE);
   FUNCVAR_tickvalue = MarketInfo(FUNCGET_currency, MODE_TICKVALUE);
   FUNCVAR_lots = 0;
   if(FUNCVAR_ticksize > 0 && FUNCVAR_tickvalue > 0){
      FUNCVAR_targetinticks = FUNCGET_target / FUNCVAR_ticksize;
      FUNCVAR_lots = ((FUNCGET_risk*AccountBalance()) / FUNCVAR_targetinticks) / FUNCVAR_tickvalue;
   }
   
   return(FUNCVAR_lots);
}

void order_closeout(){

   int
      FUNCVAR_count,
      FUNCVAR_attempt,
      FUNCVAR_errornumber,
      FUNCVAR_ticketnumber
      ;
   bool
      FUNCVAR_ticket
      ;
      

   FUNCVAR_attempt = OrdersTotal();
   for(FUNCVAR_count=0; FUNCVAR_count < FUNCVAR_attempt; FUNCVAR_count++) {
      OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
      FUNCVAR_ticketnumber = OrderTicket();
      if(OrderType() == OP_SELL){
         FUNCVAR_ticket = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 200);
      }else if(OrderType() == OP_BUY){
         FUNCVAR_ticket = OrderClose(OrderTicket(),OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 200);
      }
   }
}