//+------------------------------------------------------------------+
//|                                            testing_withtrend.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

double 
   FUNCVAR_lossfactor = 10,
   FUNCVAR_startpercentage = 0.001,
   FUNCVAR_risk = 0.001,
   FUNCVAR_balance,
   FUNCVAR_ddbalance
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
   
      if(AccountBalance() >= FUNCVAR_ddbalance){
         FUNCVAR_risk = FUNCVAR_startpercentage;     
         FUNCVAR_ddbalance = AccountBalance();
      }else{
         if(AccountBalance() < FUNCVAR_balance){
            if(FUNCVAR_current == "SELL"){
               FUNCVAR_current = "BUY";
            }else{
               FUNCVAR_current = "SELL";
            }
            FUNCVAR_risk = FUNCVAR_risk * FUNCVAR_lossfactor;
            FUNCVAR_balance = AccountBalance();
         }else{
            FUNCVAR_balance = AccountBalance();
         }
      }
   
      
            
      double FUNCVAR_distance = 0.0005;
      
      double FUNCVAR_lots = MathMax(order_getlotsize(FUNCVAR_distance, Symbol(), FUNCVAR_risk), MarketInfo(Symbol(), MODE_MINLOT));

      if(FUNCVAR_current == "SELL"){
         FUNCVAR_ticket = OrderSend(Symbol(), OP_BUY, FUNCVAR_lots, Ask, 2, Ask - (FUNCVAR_distance * FUNCVAR_lossfactor), Ask + (FUNCVAR_distance));
      }else{
         FUNCVAR_ticket = OrderSend(Symbol(), OP_SELL, FUNCVAR_lots, Bid, 2, Bid + (FUNCVAR_distance * FUNCVAR_lossfactor), Bid - (FUNCVAR_distance));
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