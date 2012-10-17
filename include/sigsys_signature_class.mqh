
string      SIGNATURE_signature[15];
int         SIGNATURE_RECENT_datemin;
int         SIGNATURE_RECENT_datemax;
int         SIGNATURE_RECENT_cases[15]; //Recent results
int         SIGNATURE_RECENT_result[15];
int         SIGNATURE_TOTAL_cases[15]; //All results
int         SIGNATURE_TOTAL_result[15];
int         SIGNATURE_NONINVERSE_cases[15]; //Without inverse results
int         SIGNATURE_NONINVERSE_result[15];

void signature_cleararray(){

   SIGNATURE_RECENT_datemin = 0;
   SIGNATURE_RECENT_datemax = 0;

   for(int a=0;a<ArraySize(GLOBAL_targetpercentages);a++){
      SIGNATURE_signature[a] = "";     
      SIGNATURE_RECENT_cases[a] = 0;
      SIGNATURE_RECENT_result[a] = 0;
      SIGNATURE_TOTAL_cases[a] = 0;
      SIGNATURE_TOTAL_result[a] = 0;
      SIGNATURE_NONINVERSE_cases[a] = 0;
      SIGNATURE_NONINVERSE_result[a] = 0;
   }
}

//^


