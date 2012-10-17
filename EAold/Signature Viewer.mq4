//+------------------------------------------------------------------+
//|                                             Signature Viewer.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"


double GLOBAL_targetpercentages[7] = {0.764, 0.618, 0.50, 0.382, 0.33, 0.236, 0.15};
int GLOBAL_style[6] = {STYLE_SOLID, STYLE_DASH, STYLE_DOT, STYLE_DASHDOT, STYLE_DASHDOTDOT};
int GLOBAL_color[6] = {Red, Blue, Green, White, Red, Blue, Green, White, Red, Blue, Green, White};

//+------------------------------------------------------------------+
//| initialization function                                          |
//+------------------------------------------------------------------+
int init(){
   
   start();
   
   return(0);
}

//+------------------------------------------------------------------+
//| start function                                                   |
//+------------------------------------------------------------------+
int start(){
   
   updatedisplay();
   
   return(0);
}

void updatedisplay(){
   
   int a, b, FUNCVAR_col, style;
   
   ObjectsDeleteAll();
   
   for(a=0;a<20;a++){
   
      ObjectCreate("vline-"+a, OBJ_VLINE, 0, iTime(Symbol(),1440, a),0);
     
      for(b=0;b<ArraySize(GLOBAL_targetpercentages);b++){
         ObjectCreate("hline-"+a+" "+b, OBJ_RECTANGLE, 0, 
         iTime(Symbol(),1440, a)+(60*60), 
         iOpen(Symbol(), 1440, a) + (iHigh(Symbol(), 1440, a+1) - iLow(Symbol(), 1440, a+1)) * GLOBAL_targetpercentages[b], 
         iTime(Symbol(),1440, a)+(1380*60), 
         iOpen(Symbol(), 1440, a) - (iHigh(Symbol(), 1440, a+1) - iLow(Symbol(), 1440, a+1)) * GLOBAL_targetpercentages[b]);
         ObjectSet("hline-"+a+" "+b, OBJPROP_COLOR, GLOBAL_color[b]);
         style = MathMod(b, 5)+1;
         ObjectSet("hline-"+a+" "+b, OBJPROP_STYLE, GLOBAL_style[style]);
         ObjectSet("hline-"+a+" "+b, OBJPROP_WIDTH, 2);
         ObjectSet("hline-"+a+" "+b, OBJPROP_BACK, 0);
            
         ObjectCreate("heading-"+a+" "+b, OBJ_TEXT, 0, iTime(Symbol(),1440, a), iOpen(Symbol(), 1440, a) + (iHigh(Symbol(), 1440, a+1) - iLow(Symbol(), 1440, a+1)) * GLOBAL_targetpercentages[b]);
         ObjectSetText("heading-"+a+" "+b, "          "+StringSubstr(GLOBAL_targetpercentages[b]+" ",0,4) , 9, "Courier New", White);
         ObjectCreate("heading-"+a+" "+b+"lower", OBJ_TEXT, 0, iTime(Symbol(),1440, a), iOpen(Symbol(), 1440, a) - (iHigh(Symbol(), 1440, a+1) - iLow(Symbol(), 1440, a+1)) * GLOBAL_targetpercentages[b]);
         ObjectSetText("heading-"+a+" "+b+"lower", "          "+StringSubstr(GLOBAL_targetpercentages[b]+" ",0,4) , 9, "Courier New", White);
      }

   }     
   GetLastError(); // Clear error associated with objects as they are not important.
   
   return(0);
}