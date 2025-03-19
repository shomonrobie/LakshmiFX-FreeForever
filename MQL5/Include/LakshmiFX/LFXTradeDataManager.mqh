// LFXTradeDataManager.mqh
// Version: 1.0.0
// Date: 2025-03-19
// Author: Shomon Robie
// License: MIT License
// Copyright (c) 2025 Shomon Robie
// Description: Manages trade data, including position counts and profit/loss calculations.

#ifndef LFX_TRADE_DATA_MANAGER_MQH
#define LFX_TRADE_DATA_MANAGER_MQH

class LFXTradeDataManager {
private:
   string m_ExpertName;
   string m_Symbol;
   long   m_MagicNumber;
   int    m_TotalBuyPositions;
   int    m_TotalSellPositions;

public:
   LFXTradeDataManager(string expertName, string symbol, long magicNumber) {
      m_ExpertName = expertName;
      m_Symbol = symbol;
      m_MagicNumber = magicNumber;
      m_TotalBuyPositions = 0;
      m_TotalSellPositions = 0;
   }

   void CalculateAllPositions() {
      m_TotalBuyPositions = 0;
      m_TotalSellPositions = 0;
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionGetSymbol(i) == m_Symbol && PositionGetInteger(POSITION_MAGIC) == m_MagicNumber) {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) m_TotalBuyPositions++;
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) m_TotalSellPositions++;
         }
      }
   }

   double GetDailyProfitLoss() {
      double profit = 0;
      datetime today = TimeCurrent() - (TimeCurrent() % 86400);
      for (int i = HistoryDealsTotal() - 1; i >= 0; i--) {
         ulong ticket = HistoryDealGetTicket(i);
         if (HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT &&
             HistoryDealGetString(ticket, DEAL_SYMBOL) == m_Symbol &&
             HistoryDealGetInteger(ticket, DEAL_MAGIC) == m_MagicNumber &&
             HistoryDealGetInteger(ticket, DEAL_TIME) >= today) {
            profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
         }
      }
      return profit;
   }

   double GetFloatingProfitLoss() {
      double profit = 0;
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         if (PositionGetSymbol(i) == m_Symbol && PositionGetInteger(POSITION_MAGIC) == m_MagicNumber) {
            profit += PositionGetDouble(POSITION_PROFIT);
         }
      }
      return profit;
   }

   int GetTotalBuyPositions() { return m_TotalBuyPositions; }
   int GetTotalSellPositions() { return m_TotalSellPositions; }
};

#endif
