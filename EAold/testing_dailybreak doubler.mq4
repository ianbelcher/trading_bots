//+------------------------------------------------------------------+
//|                                            testing_withtrend.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

double 
   FUNCVAR_lossfactor = 1,
   FUNCVAR_risk = 0.01,
   FUNCVAR_riskinit = 0.01,
   FUNCVAR_balance
   ;

int
   FUNCVAR_ticket,
   FUNCVAR_currentbar,
   FUNCVAR_riskfactor
   ;
   
string
   FUNCVAR_current
   ;

int init(){

   FUNCVAR_balance = AccountBalance();

}

int start(){
   

   
   if(
      FUNCVAR_currentbar != Time[0]
   ){ 
      order_closeout();
      
      if(AccountBalance() > FUNCVAR_balance){
         FUNCVAR_risk = FUNCVAR_risk * 10;
         FUNCVAR_riskfactor++;
         if(FUNCVAR_riskfactor>6){
            FUNCVAR_risk = FUNCVAR_riskinit; 
            FUNCVAR_riskfactor = 1;
         }
         FUNCVAR_balance = AccountBalance();
      }else if(AccountBalance() < FUNCVAR_balance){
         FUNCVAR_risk = FUNCVAR_riskinit; 
         FUNCVAR_riskfactor = 1;
         FUNCVAR_balance = AccountBalance();
      }
      
      FUNCVAR_currentbar = Time[0];
      
      double FUNCVAR_distance = (MarketInfo(Symbol(), MODE_STOPLEVEL)) * Point;
      
      double FUNCVAR_lots = MathMax(order_getlotsize(FUNCVAR_distance, Symbol(), FUNCVAR_risk), MarketInfo(Symbol(), MODE_MINLOT));
      
      FUNCVAR_ticket = OrderSend(Symbol(), OP_BUYSTOP, FUNCVAR_lots, High[1], 2, High[1] - (FUNCVAR_distance), High[1] + FUNCVAR_distance * FUNCVAR_lossfactor);
      
      //FUNCVAR_ticket = OrderSend(Symbol(), OP_SELLSTOP, FUNCVAR_lots, Low[1], 2, Low[1] + (FUNCVAR_distance ), Low[1] - FUNCVAR_distance* FUNCVAR_lossfactor);
   
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
         //FUNCVAR_ticket = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 200);
      }else if(OrderType() == OP_BUY){
         //FUNCVAR_ticket = OrderClose(OrderTicket(),OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 200);
      }else{
         OrderDelete(OrderTicket(), CLR_NONE);
      }
   }
}