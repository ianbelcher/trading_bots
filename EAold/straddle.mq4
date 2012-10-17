//+------------------------------------------------------------------+
//|                                                      Stradle.mq4 |
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
   
   int a, b;
   double 
      size = 0.0008,
      timesec,
      open
      ;
   
   ObjectsDeleteAll();
   
   for(a=1;a<20;a++){
         timesec = iTime(Symbol(),1440, a)+10*60*60;
         open = iOpen(Symbol(), 60, iBarShift(Symbol(), 60, timesec));
         
         ObjectCreate("hline-"+a+" "+b+"HL", OBJ_RECTANGLE, 0, 
         timesec, 
         open + size, 
         timesec+24*60*60, 
         open - size
         );
         
            ObjectSet("hline-"+a+" "+b+"HL", OBJPROP_COLOR, Blue);
            ObjectSet("hline-"+a+" "+b+"HL", OBJPROP_STYLE, 0);
            ObjectSet("hline-"+a+" "+b+"HL", OBJPROP_WIDTH, 1);
            ObjectSet("hline-"+a+" "+b+"HL", OBJPROP_BACK, 0);
         
         ObjectCreate("hline-"+a+" "+b+"HLentry", OBJ_RECTANGLE, 0, 
         timesec, 
         open + size*3, 
         timesec+24*60*60, 
         open - size*3
         );
         
            ObjectSet("hline-"+a+" "+b+"HLentry", OBJPROP_COLOR, White);
            ObjectSet("hline-"+a+" "+b+"HLentry", OBJPROP_STYLE, 0);
            ObjectSet("hline-"+a+" "+b+"HLentry", OBJPROP_WIDTH, 1);
            ObjectSet("hline-"+a+" "+b+"HLentry", OBJPROP_BACK, 0);
   }     
   GetLastError(); // Clear error associated with objects as they are not important.
   
   return(0);
}