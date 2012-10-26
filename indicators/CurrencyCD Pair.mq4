//+------------------------------------------------------------------+
//|                              Currency Convergence Divergence.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

extern int GLOBAL_period = 2;


string GLOBAL_entities[8] = {"USD", "EUR", "GBP", "CHF", "JPY", "CAD", "AUD", "NZD"}; //, "SGD", "DKK", "NOK", "SEK", "PLN", "MXN", "XAU", "XAG" };
double GLOBAL_ratings[8];

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Green
#property indicator_color2 Red


int GLOBAL_timeframe;

double 
   USD[],
   EUR[],
   GBP[],
   CHF[],
   JPY[],
   CAD[],
   AUD[],
   NZD[],
   base[],
   traded[],
   cd[]
   ;

int init(){
   GLOBAL_timeframe = Period();
   SetIndexBuffer(0,base);
   SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,1);
   SetIndexLabel (0,"base currency");
   ArraySetAsSeries(base, TRUE);
   
   SetIndexBuffer(1,traded);
   SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,1);
   SetIndexLabel (1,"traded currency");
   ArraySetAsSeries(traded, TRUE);

   //SetIndexBuffer(2,cd);
   //SetIndexStyle (2,DRAW_HISTOGRAM,STYLE_SOLID,1);
   //SetIndexLabel (2,"Convergence Divergence");
   //ArraySetAsSeries(cd, TRUE);

}

int start(){

   int 
      FUNCVAR_basecurrency,
      FUNCVAR_tradedcurrency,
      FUNCVAR_chartbasenumber,
      FUNCVAR_charttradednumber,
      counted_bars
      ;
      
   string
      FUNCVAR_base,
      FUNCVAR_chartbase,
      FUNCVAR_traded,
      FUNCVAR_charttraded,
      FUNCVAR_currency
      ;
   
   double
      FUNCVAR_amount,
      FUNCVAR_owncurrency
      ;

   counted_bars=IndicatorCounted();
   FUNCVAR_chartbase = StringSubstr(Symbol(),0,3);
   FUNCVAR_charttraded = StringSubstr(Symbol(), 3, 3);
   Comment(FUNCVAR_chartbase+" "+FUNCVAR_charttraded);
   int i=Bars-counted_bars-1;
   while(i>=0){
     
      for(FUNCVAR_basecurrency = 0; FUNCVAR_basecurrency < ArraySize(GLOBAL_entities); FUNCVAR_basecurrency++){
         for(FUNCVAR_tradedcurrency = 0; FUNCVAR_tradedcurrency < ArraySize(GLOBAL_entities); FUNCVAR_tradedcurrency++){
            FUNCVAR_base = GLOBAL_entities[FUNCVAR_basecurrency];
            FUNCVAR_traded = GLOBAL_entities[FUNCVAR_tradedcurrency];
            if(FUNCVAR_base==FUNCVAR_chartbase){
               FUNCVAR_chartbasenumber = FUNCVAR_basecurrency;
            }
            if(FUNCVAR_traded==FUNCVAR_charttraded){
               FUNCVAR_charttradednumber = FUNCVAR_tradedcurrency;
            }
            if(
               MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TRADEALLOWED) == 1 &&
               MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_SPREAD) > 0 &&
               !(FUNCVAR_base == FUNCVAR_chartbase &&
               FUNCVAR_traded == FUNCVAR_charttraded)
            ){
               //FUNCVAR_amount = iClose(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, iBarShift(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, iTime(FUNCVAR_base+FUNCVAR_traded, Period(),i))) - iOpen(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, iBarShift(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, iTime(FUNCVAR_base+FUNCVAR_traded, Period(),i)) + GLOBAL_period - 1);
               FUNCVAR_amount = iClose(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, i) - iOpen(FUNCVAR_base+FUNCVAR_traded, GLOBAL_timeframe, i + GLOBAL_period - 1);
               //FUNCVAR_amount = FUNCVAR_amount / MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_POINT); //Get size in Points
               FUNCVAR_amount = FUNCVAR_amount / MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TICKSIZE); // Get size in Ticks
               FUNCVAR_amount = FUNCVAR_amount * MarketInfo(FUNCVAR_base+FUNCVAR_traded, MODE_TICKVALUE); // Get size in account currency

               GLOBAL_ratings[FUNCVAR_basecurrency] = GLOBAL_ratings[FUNCVAR_basecurrency]+FUNCVAR_amount;
               GLOBAL_ratings[FUNCVAR_tradedcurrency] = GLOBAL_ratings[FUNCVAR_tradedcurrency]-FUNCVAR_amount;
            }
         }
      }
      
      base[i] = GLOBAL_ratings[FUNCVAR_chartbasenumber];
      traded[i] = GLOBAL_ratings[FUNCVAR_charttradednumber];
      //cd[i] = base[i] - traded[i] - base[i+1] - traded[i+1];
      for(int a=0; a<ArraySize(GLOBAL_entities); a++){
         GLOBAL_ratings[a] = 0;
      }
           
      i--;
      
   }
   
   return(0);

}