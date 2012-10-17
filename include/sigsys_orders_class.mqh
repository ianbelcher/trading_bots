
double      ORDERS_targetaccountrisk;
int         ORDERS_currentnumberoforders;
int         ORDERS_date;
int         ORDERS_barnumber;

string      ORDERS_pair[100];
string      ORDERS_signature[100];

double      ORDERS_target[100];
int         ORDERS_recent_rating[100];
double      ORDERS_recent_result[100];
int         ORDERS_recent_cases[100];
int         ORDERS_recent_datemin[100];
int         ORDERS_recent_datemax[100];
int         ORDERS_total_rating[100];
double      ORDERS_total_result[100];
int         ORDERS_total_cases[100];
int         ORDERS_noninverse_rating[100];
double      ORDERS_noninverse_result[100];
int         ORDERS_noninverse_cases[100];

int         ORDERS_ticket[100];
int         ORDERS_cmd[100];
double      ORDERS_price[100];
double      ORDERS_volume[100];
double      ORDERS_stoploss[100];
double      ORDERS_takeprofit[100];
string      ORDERS_comment[100];
string      ORDERS_magicnumber[100];
 

double      ORDERS_tested_targetdistance[100];
double      ORDERS_tested_targetpositive[100];
double      ORDERS_tested_targetnegative[100];
double      ORDERS_tested_riskratio[100];
double      ORDERS_tested_initialposition[100];
int         ORDERS_tested_win[100];

string order_arrayrecordastext(int FUNCGET_recordnumber){
   function_start("order_arrayrecordastext", true);

   string FUNCVAR_text = 
      ORDERS_targetaccountrisk+";"+
      ORDERS_currentnumberoforders+";"+
      ORDERS_date+";"+
      ORDERS_barnumber+";"+
      
      ORDERS_pair[FUNCGET_recordnumber]+";"+
      ORDERS_signature[FUNCGET_recordnumber]+";"+
      
      ORDERS_target[FUNCGET_recordnumber]+";"+
      ORDERS_recent_rating[FUNCGET_recordnumber]+";"+
      ORDERS_recent_result[FUNCGET_recordnumber]+";"+
      ORDERS_recent_cases[FUNCGET_recordnumber]+";"+
      ORDERS_recent_datemin[FUNCGET_recordnumber]+";"+
      ORDERS_recent_datemax[FUNCGET_recordnumber]+";"+
      ORDERS_total_rating[FUNCGET_recordnumber]+";"+
      ORDERS_total_result[FUNCGET_recordnumber]+";"+
      ORDERS_total_cases[FUNCGET_recordnumber]+";"+
      ORDERS_noninverse_rating[FUNCGET_recordnumber]+";"+
      ORDERS_noninverse_result[FUNCGET_recordnumber]+";"+
      ORDERS_noninverse_cases[FUNCGET_recordnumber]+";"+
      
      ORDERS_ticket[FUNCGET_recordnumber]+";"+
      ORDERS_cmd[FUNCGET_recordnumber]+";"+
      ORDERS_price[FUNCGET_recordnumber]+";"+
      ORDERS_volume[FUNCGET_recordnumber]+";"+
      ORDERS_stoploss[FUNCGET_recordnumber]+";"+
      ORDERS_takeprofit[FUNCGET_recordnumber]+";"+
      ORDERS_comment[FUNCGET_recordnumber]+";"+
      ORDERS_magicnumber[FUNCGET_recordnumber]+";"+
      
      ORDERS_tested_targetdistance[FUNCGET_recordnumber]+";"+
      ORDERS_tested_targetpositive[FUNCGET_recordnumber]+";"+
      ORDERS_tested_targetnegative[FUNCGET_recordnumber]+";"+
      ORDERS_tested_riskratio[FUNCGET_recordnumber]+";"+
      ORDERS_tested_initialposition[FUNCGET_recordnumber]+";"+
      ORDERS_tested_win[FUNCGET_recordnumber];
    
   function_end();
   return(FUNCVAR_text);
}
//^