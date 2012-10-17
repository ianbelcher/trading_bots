//+------------------------------------------------------------------+
//|                                             currency tracker.mq4 |
//|                                       Copyright 2012 Ian Belcher |
//|                                             http://ianbelcher.me |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012 Ian Belcher"
#property link      "http://ianbelcher.me"

//+------------------------------------------------------------------+
//| start function                                                   |
//+------------------------------------------------------------------+
int start(){
   
   log(TimeCurrent()+";"+DoubleToStr(Bid, 5)+";"+DoubleToStr(MarketInfo(Symbol(), MODE_SPREAD), 0)+";"+DoubleToStr(MarketInfo(Symbol(), MODE_STOPLEVEL),0));
   
   return(0);
}

//+------------------------------------------------------------------+
//| record keeping functions                                         |
//+------------------------------------------------------------------+

void log(string FUNCGET_msg = "NULL"){
//Logging and function management in this function can create infinite loops if there are errors.
//Please refrain.
   int 
      FUNCVAR_logfile,
      FUNCVAR_counter
      ;
   string 
      FUNCVAR_functionnamelist
      ;
        
   FUNCVAR_logfile = FileOpen(Symbol()+".csv", FILE_CSV|FILE_WRITE|FILE_READ);
   if(FUNCVAR_logfile < 1){
     Alert(Symbol()+".csv file not found, the last error is ", GetLastError());
     FileClose(FUNCVAR_logfile);
     return(0);
   }
   FileSeek(FUNCVAR_logfile, 0, SEEK_END);
   FileWrite(FUNCVAR_logfile, FUNCGET_msg);
   FileClose(FUNCVAR_logfile);
}