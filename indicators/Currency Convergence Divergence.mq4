//+------------------------------------------------------------------+
//|                              Currency Convergence Divergence.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

extern int GLOBAL_period = 15;
extern int GLOBAL_timeframe = 60;

extern bool GLOBAL_USD = true;
extern bool GLOBAL_EUR = true;
extern bool GLOBAL_GBP = true;
extern bool GLOBAL_CHF = true;
extern bool GLOBAL_JPY = true;
extern bool GLOBAL_CAD = true;
extern bool GLOBAL_AUD = true;
extern bool GLOBAL_NZD = true;


string GLOBAL_entities[8] = {"USD", "EUR", "GBP", "CHF", "CAD", "JPY", "AUD", "NZD"}; //, "SGD", "DKK", "NOK", "SEK", "PLN", "MXN", "XAU", "XAG" };
double GLOBAL_ratings[8];

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_color1 RoyalBlue
#property indicator_color2 Blue
#property indicator_color3 Gray
#property indicator_color4 Chocolate
#property indicator_color5 Green
#property indicator_color6 Red
#property indicator_color7 Gold
#property indicator_color8 White


double 
   USD[],
   EUR[],
   GBP[],
   CHF[],
   CAD[],
   JPY[],
   AUD[],
   NZD[],
   TOTAL[]
   ;

int init(){
   
   if(GLOBAL_USD == true){
      SetIndexBuffer(0,USD);
      SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,1);
      SetIndexLabel (0,"USD");
      ArraySetAsSeries(USD, TRUE);
   }
   
   if(GLOBAL_EUR == true){
      SetIndexBuffer(1,EUR);
      SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,1);
      SetIndexLabel (1,"EUR");
      ArraySetAsSeries(EUR, TRUE);
   }
   if(GLOBAL_GBP == true){
      SetIndexBuffer(2,GBP);
      SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,1);
      SetIndexLabel (2,"GBP");
      ArraySetAsSeries(GBP, TRUE);
   }
   if(GLOBAL_CHF == true){
      SetIndexBuffer(3,CHF);
      SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,1);
      SetIndexLabel (3,"CHF");
      ArraySetAsSeries(CHF, TRUE);
   }
   if(GLOBAL_CAD == true){
      SetIndexBuffer(4,CAD);
      SetIndexStyle (4,DRAW_LINE,STYLE_SOLID,1);
      SetIndexLabel (4,"CAD");
      ArraySetAsSeries(CAD, TRUE);
   }
   if(GLOBAL_JPY == true){
      SetIndexBuffer(5,JPY);
      SetIndexStyle (5,DRAW_LINE,STYLE_SOLID,1);
      SetIndexLabel (5,"JPY");
      ArraySetAsSeries(JPY, TRUE);
   }
   if(GLOBAL_AUD == true){
      SetIndexBuffer(6,AUD);
      SetIndexStyle (6,DRAW_LINE,STYLE_SOLID,1);
      SetIndexLabel (6,"AUD");
      ArraySetAsSeries(AUD, TRUE);
   }
   if(GLOBAL_NZD == true){
      SetIndexBuffer(7,NZD);
      SetIndexStyle (7,DRAW_LINE,STYLE_SOLID,1);
      SetIndexLabel (7,"NZD");
      ArraySetAsSeries(NZD, TRUE);
   }
   
   SetLevelValue (0, 0);

}

int start(){

   int 
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency,
      counted_bars
      ;
      
   string
      FUNCVAR_base,
      FUNCVAR_traded,
      FUNCVAR_currency
      ;
   
   double
      FUNCVAR_amount,
      FUNCVAR_owncurrency
      ;

   counted_bars=IndicatorCounted();
   int i=Bars-counted_bars-1;
   while(i>=0){
     
      for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
         for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
            FUNCVAR_base = GLOBAL_entities[FUNCVAR_basecurrency];
            FUNCVAR_traded = GLOBAL_entities[FUNCVAR_tradedcurrency];
            if(
               MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TRADEALLOWED) == 1 &&
               MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_SPREAD) > 0
            ){
               FUNCVAR_amount = iClose(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, iBarShift(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, iTime(FUNCVAR_base+FUNCVAR_traded, Period(),i))) - iOpen(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, iBarShift(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, iTime(FUNCVAR_base+FUNCVAR_traded, Period(),i)) + GLOBAL_period - 1);
               //FUNCVAR_amount = FUNCVAR_amount / MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_POINT); //Get size in Points
               FUNCVAR_amount = FUNCVAR_amount / MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TICKSIZE); // Get size in Ticks
               FUNCVAR_amount = FUNCVAR_amount * MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TICKVALUE); // Get size in account currency

               GLOBAL_ratings[FUNCVAR_basecurrency] = GLOBAL_ratings[FUNCVAR_basecurrency]+FUNCVAR_amount;
               GLOBAL_ratings[FUNCVAR_tradedcurrency] = GLOBAL_ratings[FUNCVAR_tradedcurrency]-FUNCVAR_amount;
            }
         }
      }
      
      USD[i] = GLOBAL_ratings[0];
      CHF[i] = GLOBAL_ratings[1];
      EUR[i] = GLOBAL_ratings[2];
      GBP[i] = GLOBAL_ratings[3];
      JPY[i] = GLOBAL_ratings[4];
      CAD[i] = GLOBAL_ratings[5];
      AUD[i] = GLOBAL_ratings[6];
      NZD[i] = GLOBAL_ratings[7];
      
      for(int a=0; a<ArraySize(GLOBAL_entities); a++){
         GLOBAL_ratings[a] = 0;
      }
           
      i--;
      
   }
   
   return(0);

}