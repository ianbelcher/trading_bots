//+------------------------------------------------------------------+
//|                                             DeleteAllPending.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ | 
//|                                                
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"
#property show_confirm
int totalPendingOrders = 0;   // variable to count total pending Orders
 
//+------------------------------------------------------------------+
//| script "Delete All pending orders"                              |
//+------------------------------------------------------------------+
int start()
  {
   bool   isDeleted;       //To check order deleted is successful or not
   int    Order_Type, total;
//----
   total=OrdersTotal();    //getting total orders including open and pending
//----
//+------------------------------------------------------------------+
//| counting total pending orders                                    |
//+------------------------------------------------------------------+
   
   
   for(int a=0; a<total; a++)
     {
      if(OrderSelect(a,SELECT_BY_POS,MODE_TRADES))
        {
         Order_Type=OrderType();
         //---- pending orders only are considered
         if(Order_Type!=OP_BUY && Order_Type!=OP_SELL)
           {
            totalPendingOrders++;
            }
         }
   }
   
   //Displaying number or total pending orders
   Print("Total Pending Orders "+totalPendingOrders);
   
   
   //Selecting pending orders and deleting first order in the loop till last order
   for(int i=0; i<totalPendingOrders; i++)
     {
     for(int b=0; b<totalPendingOrders; b++)
      {
      if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
        {
         Order_Type=OrderType();
         //---- pending orders only are considered
         if(Order_Type!=OP_BUY && Order_Type!=OP_SELL)
           {
            //---- print selected order
            OrderPrint();
            //---- delete first pending order
            isDeleted=OrderDelete(OrderTicket());
            if(isDeleted!=TRUE) Print("LastError = ", GetLastError());
            break;
           }
        }
      else { Print( "Error when order select ", GetLastError()); break; }
     }
//----
   }
   return(0);
  }
//+------------------------------------------------------------------+*/