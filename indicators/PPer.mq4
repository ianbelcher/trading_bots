//+------------------------------------------------------------------+
//|                                                    PP viewer.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_color1 Blue
#property indicator_color2 Yellow
#property indicator_color3 Yellow
#property indicator_color4 Red
#property indicator_color5 Red
#property indicator_color6 White
#property indicator_color7 White

extern int extern_timeframe   = 1440;  //In minutes, the chart to work off when calculating PP lines.

double 
   PP[],
   R1[],
   S1[],
   R2[],
   S2[],
   r5[],
   s5[]
   ;

int
   counted_bars
   ;

//+------------------------------------------------------------------+
//| initialization function                                          |
//+------------------------------------------------------------------+
int init(){
   
   SetIndexBuffer(0,PP);
   SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,1);
   SetIndexLabel (0,"PP");
   SetIndexBuffer(1,R1);
   SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,1);
   SetIndexLabel (1,"R1");
   SetIndexBuffer(2,S1);
   SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,1);
   SetIndexLabel (2,"S1");
   SetIndexBuffer(3,R2);
   SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,1);
   SetIndexLabel (3,"R2");
   SetIndexBuffer(4,S2);
   SetIndexStyle (4,DRAW_LINE,STYLE_SOLID,1);
   SetIndexLabel (4,"S2");
   SetIndexBuffer(5,r5);
   SetIndexStyle (5,DRAW_LINE,STYLE_DASH,0);
   SetIndexLabel (5,"r5");
   SetIndexBuffer(6,s5);
   SetIndexStyle (6,DRAW_LINE,STYLE_DASH,0);
   SetIndexLabel (6,"s5");
   
   return;                          
   
}

//+------------------------------------------------------------------+
//| start function                                                   |
//+------------------------------------------------------------------+
int start(){
   
   double
      var_high,
      var_low,
      var_close
      ;
   
   counted_bars=IndicatorCounted();
   int i=Bars-counted_bars-1;
   while(i>=0){
      var_high =  iHigh(Symbol(), extern_timeframe, iBarShift(Symbol(), extern_timeframe, Time[i]) + 1);
      var_low =   iLow(Symbol(), extern_timeframe, iBarShift(Symbol(), extern_timeframe, Time[i]) + 1);
      var_close = iClose(Symbol(), extern_timeframe, iBarShift(Symbol(), extern_timeframe, Time[i]) + 1);
      
      PP[i]=(var_high + var_low + var_close) / 3;
      R1[i]=(2 * PP[i]) - var_low;
      S1[i]=(2 * PP[i]) - var_high;
      r5[i]=(PP[i]+R1[i])/2;
      s5[i]=(PP[i]+S1[i])/2;
      R2[i]=PP[i] + (var_high - var_low);
      S2[i]=PP[i] - (var_high - var_low);             
      i--;  
   }
   
   return(0);
}

void updatedisplay(){
   
   int a, b, FUNCVAR_col, style;
   
   ObjectsDeleteAll();
   
   
   for(a=1;a<2;a++){
      for(b=1;b<24;b++){
         //var_high = iHigh(Symbol(), 1440, a + 1);
         //var_low = iLow(Symbol(), 1440, a + 1);
         //var_close = iClose(Symbol(), 1440, a + 1);
         
         
         //PP = (var_high + var_low + var_close) /3;
         
         //R1 = (2 x PP) - var_low;
         //S1 = (2 x PP) - var_high;
         
         //R2 = PP + (var_high - var_low);
         //S2 = PP - (var_high - var_low);

         //R3 = var_high + 2(PP - var_low);
         //S3 = var_low - 2(var_high - PP);
         
         /*
         ObjectCreate("hline-"+a+" "+b, OBJ_RECTANGLE, 0, 
         iTime(Symbol(),1440, a), 
         PP, 
         iTime(Symbol(),1440, a - 1), 
         PP + 0.0001);
         
         ObjectCreate("hline-"+a+" "+b+"R1", OBJ_RECTANGLE, 0, 
         iTime(Symbol(),1440, a), 
         PP * 2 - iHigh(Symbol(), 1440, a + 1), 
         iTime(Symbol(),1440, a - 1), 
         PP * 2 - iHigh(Symbol(), 1440, a + 1) + 0.0001);
         
         ObjectCreate("hline-"+a+" "+b+"S1", OBJ_RECTANGLE, 0, 
         iTime(Symbol(),1440, a), 
         PP * 2 - iLow(Symbol(), 1440, a + 1), 
         iTime(Symbol(),1440, a - 1), 
         PP * 2 - iLow(Symbol(), 1440, a + 1) + 0.0001);
         
         */
         
         ObjectCreate("hline-"+a+" "+b+"HL", OBJ_RECTANGLE, 0, 
         iTime(Symbol(),1440, a), 
         iHigh(Symbol(), 1440, a + 1)+ 0.0010 - MarketInfo(Symbol(), MODE_STOPLEVEL)*Point*1, 
         iTime(Symbol(),1440, a - 1), 
         iLow(Symbol(), 1440, a + 1)- 0.0010 + MarketInfo(Symbol(), MODE_STOPLEVEL)*Point*1);
         
         ObjectCreate("hline-"+a+" "+b+"HLentry", OBJ_RECTANGLE, 0, 
         iTime(Symbol(),1440, a), 
         iHigh(Symbol(), 1440, a + 1)+ 0.0010, //MarketInfo(Symbol(), MODE_STOPLEVEL)*Point*3, 
         iTime(Symbol(),1440, a - 1), 
         iLow(Symbol(), 1440, a + 1)- 0.0010); //MarketInfo(Symbol(), MODE_STOPLEVEL)*Point*3);
         
         ObjectCreate("hline-"+a+" "+b+"HLtarget", OBJ_RECTANGLE, 0, 
         iTime(Symbol(),1440, a), 
         iHigh(Symbol(), 1440, a + 1)+ 0.0010 + MarketInfo(Symbol(), MODE_STOPLEVEL)*Point*4, 
         iTime(Symbol(),1440, a - 1), 
         iLow(Symbol(), 1440, a + 1)- 0.0010 - MarketInfo(Symbol(), MODE_STOPLEVEL)*Point*4);
         
         ObjectSet("hline-"+a+" "+b, OBJPROP_COLOR, Green);
         ObjectSet("hline-"+a+" "+b, OBJPROP_WIDTH, 1);
         ObjectSet("hline-"+a+" "+b, OBJPROP_BACK, 0);
            
      }

   }     
   GetLastError(); // Clear error associated with objects as they are not important.
   
   return(0);
}