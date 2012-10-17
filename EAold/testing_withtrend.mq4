//+------------------------------------------------------------------+
//|                                            testing_withtrend.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"



double FUNCVAR_balance;

double FUNCVAR_initalrisk;

double FUNCVAR_risk;
double FUNCVAR_risknumber;

int FUNCVAR_bar;

string FUNCVAR_position;

string FUNCVAR_currenttrend = "~";
string FUNCVAR_previoustrend = "~";

double FUNCVAR_sum;

int init(){
   FUNCVAR_balance = AccountBalance();
   FUNCVAR_initalrisk = 100;
   FUNCVAR_risk = FUNCVAR_initalrisk; 
   FUNCVAR_risknumber = 1;
   FUNCVAR_currenttrend = "~";
   FUNCVAR_previoustrend = "~";
}

int start(){
   
   int a;
   int FUNCVAR_ticket = 0;
   string FUNCVAR_pair;
   
   if(
      iMA(Symbol(), Period(), 5, 0, MODE_EMA, PRICE_TYPICAL, 1) > iMA(Symbol(), Period(), 10, 0, MODE_EMA, PRICE_TYPICAL, 1) &&
      iMA(Symbol(), Period(), 5, 0, MODE_EMA, PRICE_TYPICAL, 2) < iMA(Symbol(), Period(), 10, 0, MODE_EMA, PRICE_TYPICAL, 2) &&
      iMA(Symbol(), Period(), 50, 0, MODE_EMA, PRICE_TYPICAL, 1) > iMA(Symbol(), Period(), 50, 0, MODE_EMA, PRICE_TYPICAL, 2)
   ){
      FUNCVAR_currenttrend = "up";
   }else if(
      iMA(Symbol(), Period(), 5, 0, MODE_EMA, PRICE_TYPICAL, 1) < iMA(Symbol(), Period(), 10, 0, MODE_EMA, PRICE_TYPICAL, 1) &&
      iMA(Symbol(), Period(), 5, 0, MODE_EMA, PRICE_TYPICAL, 2) > iMA(Symbol(), Period(), 10, 0, MODE_EMA, PRICE_TYPICAL, 2) &&
      iMA(Symbol(), Period(), 50, 0, MODE_EMA, PRICE_TYPICAL, 1) < iMA(Symbol(), Period(), 50, 0, MODE_EMA, PRICE_TYPICAL, 1)
   ){
      FUNCVAR_currenttrend = "down";
   }else{
      FUNCVAR_currenttrend = "~";
   }
   
   if(
      FUNCVAR_currenttrend != FUNCVAR_previoustrend
   ){
   
      if(AccountBalance() > FUNCVAR_balance){
         //A higher account balance means the last trade won.
         //In this case, we'll let the risk double as happened on the last trade.
      }else{
         //A lower account balance means the last trade lost.
         //In this case, we'll reset the risk. 
         //FUNCVAR_risknumber = 1;
         //FUNCVAR_risk = FUNCVAR_initalrisk;
      }
   
      FUNCVAR_balance = AccountBalance();
      
      for(a=1;a<=5; a++){
         FUNCVAR_sum = FUNCVAR_sum + iHigh(Symbol(), Period(), a) - iLow(Symbol(), Period(), a);
      }
      FUNCVAR_sum = FUNCVAR_sum / 5;
      
      double FUNCVAR_distance = FUNCVAR_sum * 2;
      double FUNCVAR_lots = MathMax(order_getlotsize(FUNCVAR_distance, Symbol(), FUNCVAR_initalrisk), MarketInfo(Symbol(), MODE_MINLOT));
      Alert(FUNCVAR_distance+" "+FUNCVAR_lots);
      if(
         FUNCVAR_currenttrend == "up"
      ){  
         FUNCVAR_ticket = OrderSend(Symbol(), OP_BUY, FUNCVAR_lots, Ask, 2, Ask - FUNCVAR_distance, Ask + FUNCVAR_distance);
      }else if(
         FUNCVAR_currenttrend == "down"
      ){
         FUNCVAR_ticket = OrderSend(Symbol(), OP_SELL, FUNCVAR_lots, Bid, 2 , Bid + FUNCVAR_distance, Bid - FUNCVAR_distance);
      }else{
         //order_closeout();
      }
   
      if(FUNCVAR_ticket > 0){
         //FUNCVAR_risk = FUNCVAR_risk * 2 + FUNCVAR_initalrisk;
         //FUNCVAR_risknumber++;
         //if(FUNCVAR_risknumber > 7){
         //   FUNCVAR_risk = FUNCVAR_initalrisk;
         //   FUNCVAR_risknumber = 0;
         //}
      }
      
      FUNCVAR_previoustrend = FUNCVAR_currenttrend;
   
   }else{
      //Do nothing as we're waiting for a cross over
   
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
      FUNCVAR_lots = ((FUNCGET_risk) / FUNCVAR_targetinticks) / FUNCVAR_tickvalue;
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