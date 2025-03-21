#ifndef LFX_RISK_MANAGER_MQH
#define LFX_RISK_MANAGER_MQH

#include <Trade\Trade.mqh> // For CTrade class

// Constants
#define MAX_RETRIES 5           // Maximum retries for trade closure
#define RETRY_DELAY_MS 1000     // Delay between retries in milliseconds

// Enum for Prop Firm selection
enum PROP_FIRM {
   PROP_FIRM_FTMO = 0,        // FTMO
   PROP_FIRM_EQUITYEDGE = 1,  // EquityEdge
   PROP_FIRM_FUNDEDNEXT = 2   // FundedNext
};

// Enum for risk status
enum RISK_STATUS {
   RISK_STATUS_NONE = 0,                  // No risk condition breached
   RISK_STATUS_MAX_LOSS_PERCENT = 1,      // Maximum loss percent reached
   RISK_STATUS_MAX_DAILY_LOSS = 2,        // Maximum daily running loss reached
   RISK_STATUS_MAX_DAILY_LOSS_FOR_MAGIC = 4, // Maximum daily loss for magic reached
   RISK_STATUS_DAILY_PROFIT_TARGET = 8    // Daily profit target reached
};

/*
 * Class: LFXRiskManager
 * Author: Shomon Robie
 * Version: 1.0
 * Date: 2025-03-18
 * Description: Manages risk for the LakshmiFX Expert Advisor, enforcing maximum loss, daily loss, 
 *              and profit targets. Supports account-wide and magic-number-specific risk rules.
 *              Persists daily loss state across restarts using MT5 global variables.
 * Copyright: LakshmiFX 2025
 * License: Proprietary
 */
class LFXRiskManager {
private:
   string m_expertName;
   long m_magicNumber;
   long m_accountNumber;
   double m_maximumLossPercent;
   double m_maximumDailyRunningLoss;
   double m_maximumDailyRunningLossForMagic;
   double m_dailyProfitTarget;
   int m_eaRestartHour;
   double m_historyProfit;
   uint m_previousTotalDealsInHistory;
   datetime m_lastResetDate;
   string m_gvDailyLossReached;

   // Current risk status
   int m_riskStatus; // Bitwise combination of RISK_STATUS values

   double calculateRunningLoss(long targetMagic = 0) {
      MqlDateTime currentDay;
      datetime currentTime = TimeCurrent();
      if (!TimeToStruct(currentTime, currentDay)) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> TimeToStruct failed. Error: ", GetLastError());
         return -1.0;
      }
      currentDay.hour = 0; currentDay.min = 0; currentDay.sec = 0;
      datetime resetTimeToday = StructToTime(currentDay);

      if (resetTimeToday != m_lastResetDate) {
         m_historyProfit = 0.0;
         m_previousTotalDealsInHistory = 0;
         m_lastResetDate = resetTimeToday;
         GlobalVariableDel(m_gvDailyLossReached);
         m_riskStatus &= ~ (RISK_STATUS_MAX_DAILY_LOSS | RISK_STATUS_MAX_DAILY_LOSS_FOR_MAGIC | RISK_STATUS_DAILY_PROFIT_TARGET); // Reset daily flags
      }

      HistorySelect(resetTimeToday, currentTime);
      uint totalDealsInHistory = HistoryDealsTotal();
      if (m_previousTotalDealsInHistory != totalDealsInHistory) {
         m_historyProfit = 0.0;
         for (uint i = m_previousTotalDealsInHistory; i < totalDealsInHistory; i++) {
            ulong ticket = HistoryDealGetTicket(i);
            if (ticket > 0) {
               long dealMagic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
               ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
               datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
               if ((dealType == DEAL_TYPE_SELL || dealType == DEAL_TYPE_BUY) &&
                   dealTime >= resetTimeToday && dealTime <= currentTime &&
                   (targetMagic == 0 || dealMagic == targetMagic)) {
                  m_historyProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                                     HistoryDealGetDouble(ticket, DEAL_SWAP) +
                                     HistoryDealGetDouble(ticket, DEAL_COMMISSION);
               }
            }
         }
         m_previousTotalDealsInHistory = totalDealsInHistory;
      }

      double floatingProfit = 0.0;
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong posTicket = PositionGetTicket(i);
         if (PositionSelectByTicket(posTicket)) {
            long posMagic = PositionGetInteger(POSITION_MAGIC);
            if (targetMagic == 0 || posMagic == targetMagic) {
               floatingProfit += PositionGetDouble(POSITION_PROFIT) +
                                 PositionGetDouble(POSITION_SWAP);
            }
         }
      }

      return m_historyProfit + floatingProfit;
   }

   bool closeTrades(long targetMagic = 0) {
      CTrade trade;
      bool allClosed = false;

      for (int retry = 0; retry < MAX_RETRIES && !allClosed; retry++) {
         allClosed = true;
         for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if (PositionSelectByTicket(ticket)) {
               long posMagic = PositionGetInteger(POSITION_MAGIC);
               if (targetMagic == 0 || posMagic == targetMagic) {
                  if (!trade.PositionClose(ticket)) {
                     Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Failed to close trade #", ticket,
                           " (Magic: ", posMagic, "). Error: ", GetLastError());
                     allClosed = false;
                  }
               }
            }
         }
         if (!allClosed) {
            Sleep(RETRY_DELAY_MS);
            Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Retrying trade closure. Attempt ", retry + 1, " of ", MAX_RETRIES);
         }
      }

      if (!allClosed) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Some trades failed to close after ", MAX_RETRIES, " attempts!");
         return false;
      }
      return true;
   }

   bool isDailyTradingPaused() {
      if (!GlobalVariableCheck(m_gvDailyLossReached)) return false;

      MqlDateTime currentTime;
      TimeToStruct(TimeCurrent(), currentTime);
      return currentTime.hour < m_eaRestartHour;
   }

public:
   LFXRiskManager(string expertName, long magicNumber, double maximumLossPercent, double maximumDailyRunningLoss,
                        double maximumDailyRunningLossForMagic, double dailyProfitTarget, int eaRestartHour) {
      m_expertName = expertName;
      m_magicNumber = magicNumber;
      m_accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
      m_maximumLossPercent = maximumLossPercent;
      m_maximumDailyRunningLoss = maximumDailyRunningLoss;
      m_maximumDailyRunningLossForMagic = maximumDailyRunningLossForMagic;
      m_dailyProfitTarget = dailyProfitTarget;
      m_eaRestartHour = eaRestartHour;
      m_historyProfit = 0.0;
      m_previousTotalDealsInHistory = 0;
      m_lastResetDate = 0;
      m_gvDailyLossReached = "LakshmiFX_DailyLoss_" + IntegerToString(m_accountNumber);
      m_riskStatus = RISK_STATUS_NONE;
   }

   int checkRisk() {
      m_riskStatus = RISK_STATUS_NONE; // Reset status each tick

      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double dailyRunningLoss = calculateRunningLoss();
      double dailyRunningLossForMagic = calculateRunningLoss(m_magicNumber);
      double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double initialEquity = accountBalance + dailyRunningLoss - m_historyProfit;

      if (m_maximumLossPercent > 0 && equity < initialEquity * (1.0 - m_maximumLossPercent / 100.0)) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Maximum Loss (", m_maximumLossPercent, "%) reached! Equity: ", equity);
         m_riskStatus |= RISK_STATUS_MAX_LOSS_PERCENT;
         if (closeTrades()) {
            ExpertRemove();
         }
         return m_riskStatus;
      }

      if (m_dailyProfitTarget > 0 && dailyRunningLoss >= m_dailyProfitTarget) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Daily Profit Target (", m_dailyProfitTarget, ") reached! Profit: ", dailyRunningLoss);
         m_riskStatus |= RISK_STATUS_DAILY_PROFIT_TARGET;
         if (closeTrades()) {
            GlobalVariableSet(m_gvDailyLossReached, 1.0);
         }
         return m_riskStatus;
      }

      if (m_maximumDailyRunningLoss > 0 && dailyRunningLoss < -m_maximumDailyRunningLoss) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Maximum Daily Running Loss (", m_maximumDailyRunningLoss, ") reached! Loss: ", dailyRunningLoss);
         m_riskStatus |= RISK_STATUS_MAX_DAILY_LOSS;
         if (closeTrades()) {
            GlobalVariableSet(m_gvDailyLossReached, 1.0);
         }
         return m_riskStatus;
      }

      if (m_maximumDailyRunningLossForMagic > 0 && dailyRunningLossForMagic < -m_maximumDailyRunningLossForMagic) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Maximum Daily Running Loss for Magic (", m_maximumDailyRunningLossForMagic, ") reached! Loss: ", dailyRunningLossForMagic);
         m_riskStatus |= RISK_STATUS_MAX_DAILY_LOSS_FOR_MAGIC;
         closeTrades(m_magicNumber);
         return m_riskStatus;
      }

      if (isDailyTradingPaused()) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Trading paused until restart hour (", m_eaRestartHour, ")");
      }

      return m_riskStatus;
   }

   bool isRiskBreached() {
      return isDailyTradingPaused();
   }

   // Getter for risk status
   int getRiskStatus() const { return m_riskStatus; }
};

/*
 * Class: PropFirmRiskManager
 * Author: Shomon Robie
 * Version: 1.0
 * Date: 2025-03-18
 * Description: Manages prop firm-specific risk rules for the LakshmiFX EA, including daily loss 
 *              limits and trailing drawdowns tailored to firms like FTMO, EquityEdge, and FundedNext.
 * Copyright: LakshmiFX 2025
 * License: Proprietary
 */
class PropFirmRiskManager {
private:
   string m_expertName;
   long m_magicNumber;
   long m_accountNumber;
   PROP_FIRM m_propFirm;
   int m_challengeType;
   int m_serverTimezoneOffset;
   double m_dailyLossLimitPercent;
   double m_startingValue;
   double m_highestEquity;
   datetime m_lastResetDate;
   double m_historyProfit;
   uint m_previousTotalDealsInHistory;
   double m_maxTrailingDrawdownPercent;

   // Risk status for prop firm
   int m_riskStatus; // Bitwise combination of RISK_STATUS values (reusing same enum for simplicity)

   double calculateDailyLoss() {
      MqlDateTime currentDay;
      datetime currentTime = TimeCurrent();
      if (!TimeToStruct(currentTime, currentDay)) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> TimeToStruct failed. Error: ", GetLastError());
         return -1.0;
      }
      currentDay.hour = (m_propFirm == PROP_FIRM_EQUITYEDGE) ? 22 : 0;
      currentDay.min = 0; currentDay.sec = 0;
      datetime resetTimeToday = StructToTime(currentDay) + (m_propFirm == PROP_FIRM_FUNDEDNEXT ? m_serverTimezoneOffset : 0);
      if (m_propFirm == PROP_FIRM_EQUITYEDGE && currentTime < resetTimeToday) resetTimeToday -= 86400;

      if (resetTimeToday != m_lastResetDate) {
         if (m_propFirm == PROP_FIRM_EQUITYEDGE) m_startingValue = MathMax(AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoDouble(ACCOUNT_EQUITY));
         m_historyProfit = 0.0;
         m_previousTotalDealsInHistory = 0;
         m_lastResetDate = resetTimeToday;
         if (m_propFirm == PROP_FIRM_EQUITYEDGE) m_highestEquity = m_startingValue;
         m_riskStatus = RISK_STATUS_NONE; // Reset on new day
      }

      HistorySelect(resetTimeToday, currentTime);
      uint totalDealsInHistory = HistoryDealsTotal();
      if (m_previousTotalDealsInHistory != totalDealsInHistory) {
         m_historyProfit = 0.0;
         for (uint i = m_previousTotalDealsInHistory; i < totalDealsInHistory; i++) {
            ulong ticket = HistoryDealGetTicket(i);
            if (ticket > 0) {
               ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
               datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
               if ((dealType == DEAL_TYPE_SELL || dealType == DEAL_TYPE_BUY) &&
                   dealTime >= resetTimeToday && dealTime <= currentTime) {
                  m_historyProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                                     HistoryDealGetDouble(ticket, DEAL_SWAP) +
                                     HistoryDealGetDouble(ticket, DEAL_COMMISSION);
               }
            }
         }
         m_previousTotalDealsInHistory = totalDealsInHistory;
      }

      double floatingProfit = 0.0;
      for (int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong posTicket = PositionGetTicket(i);
         if (PositionSelectByTicket(posTicket)) {
            floatingProfit += PositionGetDouble(POSITION_PROFIT) +
                              PositionGetDouble(POSITION_SWAP);
         }
      }

      return m_historyProfit + floatingProfit;
   }

public:
   PropFirmRiskManager(string expertName, long magicNumber, PROP_FIRM propFirm, int challengeType, int serverTimezoneOffset) {
      m_expertName = expertName;
      m_magicNumber = magicNumber;
      m_accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
      m_propFirm = propFirm;
      m_challengeType = challengeType;
      m_serverTimezoneOffset = serverTimezoneOffset;
      switch (m_propFirm) {
         case PROP_FIRM_FTMO: m_dailyLossLimitPercent = 5.0; break;
         case PROP_FIRM_EQUITYEDGE: 
            m_dailyLossLimitPercent = 4.0; 
            m_maxTrailingDrawdownPercent = 6.0; 
            break;
         case PROP_FIRM_FUNDEDNEXT:
            switch (m_challengeType) {
               case 1: m_dailyLossLimitPercent = 3.0; break;
               case 2: m_dailyLossLimitPercent = 5.0; break;
               case 3: m_dailyLossLimitPercent = 4.0; break;
               default: m_dailyLossLimitPercent = 5.0; break;
            }
            break;
         default: m_dailyLossLimitPercent = 5.0; break;
      }
      m_startingValue = AccountInfoDouble(ACCOUNT_BALANCE);
      m_highestEquity = m_startingValue;
      m_historyProfit = 0.0;
      m_previousTotalDealsInHistory = 0;
      m_lastResetDate = 0;
      m_riskStatus = RISK_STATUS_NONE;
   }

   int checkRisk(double &currentValue, double &dailyLossLimit, double &trailingDrawdownLimit) {
      m_riskStatus = RISK_STATUS_NONE;

      double dailyLoss = calculateDailyLoss();
      if (dailyLoss == -1.0) {
         currentValue = -1.0;
         return m_riskStatus;
      }

      if (m_propFirm == PROP_FIRM_FUNDEDNEXT) {
         double baseDailyLossLimit = m_startingValue * m_dailyLossLimitPercent / 100.0;
         dailyLossLimit = baseDailyLossLimit + (m_historyProfit > 0 ? m_historyProfit : 0);
         currentValue = dailyLoss;
      } else {
         currentValue = m_startingValue + dailyLoss;
         dailyLossLimit = m_startingValue - (m_startingValue * m_dailyLossLimitPercent / 100.0);
      }
      trailingDrawdownLimit = (m_propFirm == PROP_FIRM_EQUITYEDGE) ?
         (m_highestEquity - (m_highestEquity * m_maxTrailingDrawdownPercent / 100.0)) : 0.0;

      if (m_propFirm == PROP_FIRM_EQUITYEDGE) m_highestEquity = MathMax(m_highestEquity, currentValue);

      Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Prop Firm: ", EnumToString(m_propFirm),
            " | Starting Value: ", m_startingValue, " | Daily Loss Limit: ",
            (m_propFirm == PROP_FIRM_FUNDEDNEXT ? -dailyLossLimit : dailyLossLimit), " | Trailing Drawdown Limit: ",
            trailingDrawdownLimit, " | Current Value: ", currentValue);

      if ((m_propFirm == PROP_FIRM_FUNDEDNEXT && currentValue < -dailyLossLimit) || 
          (m_propFirm != PROP_FIRM_FUNDEDNEXT && currentValue < dailyLossLimit)) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Daily Loss Limit breached!");
         m_riskStatus |= RISK_STATUS_MAX_DAILY_LOSS;
      }
      if (m_propFirm == PROP_FIRM_EQUITYEDGE && currentValue < trailingDrawdownLimit) {
         Print(m_expertName, "> ", m_magicNumber, "> ", _Symbol, "> Trailing Drawdown breached!");
         m_riskStatus |= RISK_STATUS_MAX_LOSS_PERCENT; // Using as a proxy for trailing drawdown
      }

      return m_riskStatus;
   }

   int getRiskStatus() const { return m_riskStatus; }
};

#endif