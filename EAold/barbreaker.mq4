//+------------------------------------------------------------------+
//|                                                   barbreaker.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

double   FUNCVAR_lossfactor = 4;
double   FUNCVAR_risk = 0.01;

int
   FUNCVAR_ticket,
   FUNCVAR_currentbar
   ;
   
string
   FUNCVAR_current
   ;

int start(){
   
   if(
      FUNCVAR_currentbar != Time[0]
   ){ 
      FUNCVAR_currentbar = Time[0];
      
      order_closeout();
      
      double FUNCVAR_distance = MathMax(MarketInfo(Symbol(), MODE_STOPLEVEL) * Point, Ask-Bid) * 3;
      
      double FUNCVAR_lots = order_getlotsize(FUNCVAR_distance, Symbol(), FUNCVAR_risk);
      
      double FUNCVAR_price = High[1] + (Ask-Bid) * 1;
      
      FUNCVAR_ticket = OrderSend(Symbol(), OP_BUYSTOP, FUNCVAR_lots, FUNCVAR_price, 2, FUNCVAR_price - (FUNCVAR_distance), FUNCVAR_price + FUNCVAR_distance * FUNCVAR_lossfactor);
      
      FUNCVAR_price = Low[1] - (Ask-Bid) * 1;
      
      FUNCVAR_ticket = OrderSend(Symbol(), OP_SELLSTOP, FUNCVAR_lots, FUNCVAR_price, 2, FUNCVAR_price + (FUNCVAR_distance), FUNCVAR_price - FUNCVAR_distance * FUNCVAR_lossfactor);
   
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
   FUNCVAR_ticketnumber = 0;
   for(FUNCVAR_count=0; FUNCVAR_count < FUNCVAR_attempt; FUNCVAR_count++) {
      OrderSelect(FUNCVAR_ticketnumber, SELECT_BY_POS, MODE_TRADES);
      
      if(OrderType() == OP_SELL){
         //FUNCVAR_ticket = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 200);
      }else if(OrderType() == OP_BUY){
         //FUNCVAR_ticket = OrderClose(OrderTicket(),OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 200);
      }else if(OrderSymbol() == Symbol()){
         Alert("Attempting to delete");
         while(OrderDelete(OrderTicket(), CLR_NONE) == FALSE){
            Sleep(1000);
            Alert("Not Deleted");
         }
      }else{
         FUNCVAR_ticketnumber++;
         Alert("Leaving "+OrderSymbol()+" "+FUNCVAR_ticketnumber+" "+OrderTicket());
      }
   }
}