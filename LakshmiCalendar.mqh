//+------------------------------------------------------------------+
//|                                              LakshmiCalendar.mqh |
//|                                     Copyright 2024, Shomon Robie |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Shomon Robie"
#property link      "https://www.mql5.com"
#property version   "1.00"
class LakshmiCalendar
  {
private:
      datetime date_from;
      datetime date_to;
      string symbol;
      long magic_number;
      int impact_type;
      
      struct AdjustedCalendarValue 
        { 
         ulong                               id;                    // value ID 
         ulong                               event_id;              // event ID 
         string                              event_name;            // Event Name
         datetime                            time;                  // event date and time 
         datetime                            period;                // event reporting period 
         int                                 revision;              // revision of the published indicator relative to the reporting period 
         double                              actual_value;          // actual value 
         double                              prev_value;            // previous value 
         double                              revised_prev_value;    // revised previous value 
         double                              forecast_value;        // forecast value 
         ENUM_CALENDAR_EVENT_IMPACT          impact_type;           // potential impact on the currency rate 
        }; 
public:
      
      
      // bool CheckForUpcomingEvent(string symbol, datetime start_time, datetime end_time);
            bool CheckForUpcomingEvent (string symbol,  long magic_number, int impact_type, datetime start_time, datetime end_time);
            LakshmiCalendar(string _symbol, long _magicNumber, int _impact_type, datetime _dateFrom, datetime _dateTo );
            string getEventName (long _eventid);
           ~LakshmiCalendar();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
LakshmiCalendar::LakshmiCalendar(string _symbol,  long _magic_number, int _impact_type, datetime _dateFrom, datetime _dateTo)
  {
      symbol = _symbol; 
      date_from = _dateFrom; 
      date_to = _dateTo; 
      magic_number = _magic_number;
      impact_type = _impact_type;
  }

LakshmiCalendar::~LakshmiCalendar()
  {
  }

bool LakshmiCalendar::CheckForUpcomingEvent (string _symbol, long _magic_number, int _impact_type, datetime _start_time, datetime _end_time){
   bool res = false;
   
   MqlCalendarValue calender_values[]; 
   if(CalendarValueHistory(calender_values, _start_time,_end_time,NULL,_symbol )) 
     { 
       res = true;
      PrintFormat(symbol , " >> ", _magic_number, " Received event values for symbol=%s: %d", 
                  symbol,ArraySize(calender_values));         
     } 
   else 
     { 
      PrintFormat("Error! Failed to receive events for symbol=%s",symbol ); 
      PrintFormat("Error code: %d",GetLastError()); 
      res = false;
      return(false);    
     }
     
   int total=ArraySize(calender_values);  
   AdjustedCalendarValue adj_cal_values[];    
   //ArrayResize(adj_cal_values, total);
   int x = 0;
   
   for (int i=0; i <= total-1; i++) {
      if ( calender_values[i].impact_type >=_impact_type) {    
            ArrayResize(adj_cal_values, x+1);      
            MqlCalendarEvent ev;
            
            adj_cal_values[x].id=calender_values[i].id; 
            adj_cal_values[x].event_id=calender_values[i].event_id; 
            
            if(CalendarEventById(adj_cal_values[x].event_id,ev)) {
            
               adj_cal_values[x].event_name= ev.name; 
            }
 
            adj_cal_values[x].time=calender_values[i].time; 
            adj_cal_values[x].period=calender_values[i].period; 
            adj_cal_values[x].revision=calender_values[i].revision; 
            adj_cal_values[x].impact_type=calender_values[i].impact_type; 
            //--- check and get values 
            if(calender_values[x].HasActualValue()) 
               adj_cal_values[x].actual_value=calender_values[i].GetActualValue(); 
            else 
               adj_cal_values[x].actual_value=double("nan"); 
        
            if(calender_values[x].HasPreviousValue()) 
               adj_cal_values[x].prev_value=calender_values[i].GetPreviousValue(); 
            else 
               adj_cal_values[x].prev_value=double("nan"); 
        
            if(calender_values[x].HasRevisedValue()) 
               adj_cal_values[x].revised_prev_value=calender_values[i].GetRevisedValue(); 
            else 
               adj_cal_values[x].revised_prev_value=double("nan"); 
        
            if(calender_values[x].HasForecastValue()) 
               adj_cal_values[x].forecast_value=calender_values[i].GetForecastValue(); 
            else 
               adj_cal_values[x].forecast_value=double("nan"); 
               x++;
            }
   } 
     
   return(res);  

}

string LakshmiCalendar::getEventName(long _eventid) {
    MqlCalendarEvent event;
    if(CalendarEventById(_eventid,event)) {
      return(event.name);
    } else {
      PrintFormat("Error! Failed to receive events for EventID=%i",_eventid ); 
      PrintFormat("Error code: %d",GetLastError());
      return(""); 
    }    
    
}