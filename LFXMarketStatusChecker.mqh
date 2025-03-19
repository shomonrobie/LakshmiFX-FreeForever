#ifndef LFX_MARKET_STATUS_CHECKER_MQH
#define LFX_MARKET_STATUS_CHECKER_MQH

#ifdef __MQL4__
   #include <WinUser32.mqh>
   #define uchar char
   #define StringGetCharacter StringGetChar
   #define CharArrayToString CharToStr
#endif

class LFXMarketStatusChecker {
private:
   string   m_expertName;
   long     m_magicNumber;
   int      m_checkIntervalMinutes;
   datetime m_lastNotificationTime;
   bool     m_isMarketActive;
   string   m_symbol;
   int      m_tickTimeoutSeconds;
   bool     m_initialCheckDone;
   ENUM_TIMEFRAMES m_timeframe;
   int      m_lastBarCount; // Added for bar tracking

   void NotifyMarketStatus(bool isActive) {
      datetime currentTime = TimeCurrent();
      if (currentTime > m_lastNotificationTime + m_checkIntervalMinutes * 60 || !m_initialCheckDone) {
         string message = m_expertName + "> Magic: " + (string)m_magicNumber + "> " + 
                          m_symbol + " market is " + (isActive ? "open" : "closed") + " at " + 
                          TimeToString(currentTime, TIME_DATE|TIME_MINUTES);
         #ifdef __MQL5__
            SendNotification(message);
         #endif
         Alert(message);
         Print(message);
         m_lastNotificationTime = currentTime;
         m_initialCheckDone = true;
      }
   }

public:
   LFXMarketStatusChecker(string expertName, long magicNumber, int checkIntervalMinutes, 
                          int tickTimeoutSeconds = 300, string symbol = NULL, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
      m_expertName = expertName;
      m_magicNumber = magicNumber;
      m_checkIntervalMinutes = (checkIntervalMinutes > 0) ? checkIntervalMinutes : 5;
      m_tickTimeoutSeconds = (tickTimeoutSeconds > 0) ? tickTimeoutSeconds : 300;
      m_lastNotificationTime = 0;
      m_isMarketActive = false;
      m_symbol = (symbol == NULL) ? _Symbol : symbol;
      m_timeframe = timeframe;
      m_initialCheckDone = false;
      m_lastBarCount = 0; // Initialize bar count
   }

   bool Init() {
      #ifdef __MQL5__
         if (!EventSetTimer(m_checkIntervalMinutes * 60)) {
            Print(m_expertName, "> Magic: ", m_magicNumber, "> Failed to set timer.");
            return false;
         }
      #else
         if (!EventSetTimer(m_checkIntervalMinutes * 60)) {
            Print(m_expertName, "> Magic: ", m_magicNumber, "> Failed to set timer.");
            return false;
         }
      #endif
      Print(m_expertName, "> Magic: ", m_magicNumber, "> Initialized. Checking market status every ", 
            m_checkIntervalMinutes, " minutes on ", m_symbol);
      CheckMarketStatus(true); // Initial check with notification
      return true;
   }

   void Deinit() {
      EventKillTimer();
   }

   void CheckMarketStatus(bool forceNotify = false) {
      bool tradeModeOpen = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL;
      bool tickRecent = false;
      #ifdef __MQL5__
         MqlTick tick;
         if (SymbolInfoTick(m_symbol, tick)) {
            tickRecent = tick.time > TimeCurrent() - m_tickTimeoutSeconds;
         }
      #else
         datetime lastTickTime = (datetime)SymbolInfoInteger(m_symbol, SYMBOL_TIME);
         tickRecent = lastTickTime > TimeCurrent() - m_tickTimeoutSeconds;
      #endif

      bool isActive = tradeModeOpen && tickRecent;
      if (isActive != m_isMarketActive || forceNotify) {
         m_isMarketActive = isActive;
         NotifyMarketStatus(isActive);
      }
   }

   bool IsMarketActive() {
      return m_isMarketActive;
   }

   // New method: Check if first bar has closed
   bool IsFirstBarClosed() {
      int currentBars = iBars(m_symbol, m_timeframe);
      if (currentBars != m_lastBarCount) {
         m_lastBarCount = currentBars;
         return m_lastBarCount > 1; // True if at least one bar has closed (second bar or later)
      }
      return m_lastBarCount > 1; // Maintain state between ticks
   }
};

#endif // LFX_MARKET_STATUS_CHECKER_MQH