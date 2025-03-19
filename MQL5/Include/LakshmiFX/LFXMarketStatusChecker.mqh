// LFXMarketStatusChecker.mqh
// Version: 1.0.0
// Date: 2025-03-19
// Author: Shomon Robie
// License: MIT License
// Copyright (c) 2025 Shomon Robie
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is furnished
// to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

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
   string   m_ExpertName;
   long     m_MagicNumber;
   int      m_CheckIntervalMinutes;
   datetime m_LastNotificationTime;
   bool     m_IsMarketActive;
   string   m_Symbol;
   int      m_TickTimeoutSeconds;
   bool     m_InitialCheckDone;
   ENUM_TIMEFRAMES m_Timeframe;
   int      m_LastBarCount;

   void NotifyMarketStatus(bool isActive) {
      datetime currentTime = TimeCurrent();
      if (currentTime > m_LastNotificationTime + m_CheckIntervalMinutes * 60 || !m_InitialCheckDone) {
         string message = m_ExpertName + "> Magic: " + (string)m_MagicNumber + "> " + 
                          m_Symbol + " market is " + (isActive ? "open" : "closed") + " at " + 
                          TimeToString(currentTime, TIME_DATE|TIME_MINUTES);
         #ifdef __MQL5__
            SendNotification(message);
         #endif
         Alert(message);
         Print(message);
         m_LastNotificationTime = currentTime;
         m_InitialCheckDone = true;
      }
   }

public:
   LFXMarketStatusChecker(string expertName, long magicNumber, int checkIntervalMinutes, 
                          int tickTimeoutSeconds = 300, string symbol = NULL, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
      m_ExpertName = expertName;
      m_MagicNumber = magicNumber;
      m_CheckIntervalMinutes = (checkIntervalMinutes > 0) ? checkIntervalMinutes : 5;
      m_TickTimeoutSeconds = (tickTimeoutSeconds > 0) ? tickTimeoutSeconds : 300;
      m_LastNotificationTime = 0;
      m_IsMarketActive = false;
      m_Symbol = (symbol == NULL) ? _Symbol : symbol;
      m_Timeframe = timeframe;
      m_InitialCheckDone = false;
      m_LastBarCount = 0;
   }

   bool Init() {
      #ifdef __MQL5__
         if (!EventSetTimer(m_CheckIntervalMinutes * 60)) {
            Print(m_ExpertName, "> Magic: ", m_MagicNumber, "> Failed to set timer.");
            return false;
         }
      #else
         if (!EventSetTimer(m_CheckIntervalMinutes * 60)) {
            Print(m_ExpertName, "> Magic: ", m_MagicNumber, "> Failed to set timer.");
            return false;
         }
      #endif
      Print(m_ExpertName, "> Magic: ", m_MagicNumber, "> Initialized v1.0.0. Checking market status every ", 
            m_CheckIntervalMinutes, " minutes on ", m_Symbol);
      CheckMarketStatus(true);
      return true;
   }

   void Deinit() {
      EventKillTimer();
   }

   void CheckMarketStatus(bool forceNotify = false) {
      bool tradeModeOpen = SymbolInfoInteger(m_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL;
      bool tickRecent = false;
      #ifdef __MQL5__
         MqlTick tick;
         if (SymbolInfoTick(m_Symbol, tick)) {
            tickRecent = tick.time > TimeCurrent() - m_TickTimeoutSeconds;
         }
      #else
         datetime lastTickTime = (datetime)SymbolInfoInteger(m_Symbol, SYMBOL_TIME);
         tickRecent = lastTickTime > TimeCurrent() - m_TickTimeoutSeconds;
      #endif

      bool isActive = tradeModeOpen && tickRecent;
      if (isActive != m_IsMarketActive || forceNotify) {
         m_IsMarketActive = isActive;
         NotifyMarketStatus(isActive);
      }
   }

   bool IsMarketActive() {
      return m_IsMarketActive;
   }

   bool IsFirstBarClosed() {
      int currentBars = iBars(m_Symbol, m_Timeframe);
      if (currentBars != m_LastBarCount) {
         m_LastBarCount = currentBars;
         return m_LastBarCount > 1;
      }
      return m_LastBarCount > 1;
   }
};

#endif // LFX_MARKET_STATUS_CHECKER_MQH
