#ifndef LFX_TRADE_DATA_MANAGER_MQH
#define LFX_TRADE_DATA_MANAGER_MQH

#include <Trade\PositionInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>

class LFXTradeBase {
protected:
    string m_expertName;
    string m_symbol;
    ulong  m_magicNumber;
    CPositionInfo m_posInfo;

    bool IsRelevant(ulong ticket, bool isPosition = true) {
        if (isPosition) {
            if (!m_posInfo.SelectByTicket(ticket)) return false;
            if (m_posInfo.Symbol() != m_symbol) return false;
            if (m_magicNumber > 0 && m_posInfo.Magic() != m_magicNumber) return false;
        } else {
            if (!OrderSelect(ticket)) return false;
            if (OrderGetString(ORDER_SYMBOL) != m_symbol) return false;
            if (m_magicNumber > 0 && OrderGetInteger(ORDER_MAGIC) != m_magicNumber) return false;
        }
        return true;
    }

    void LogError(string method, string message) {
        Print(m_expertName, "> ", m_magicNumber, "> ", m_symbol, "> ", method, ": ", message);
    }

public:
    LFXTradeBase(string expertName, string symbol, ulong magicNumber) {
        m_expertName = expertName;
        m_symbol = symbol;
        m_magicNumber = magicNumber;
    }

    virtual ~LFXTradeBase() {}

    virtual double GetFloatingProfitLoss() {
        double profit = 0.0;
        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if (!IsRelevant(ticket)) continue;
            profit += m_posInfo.Profit() + m_posInfo.Swap();
        }
        return profit;
    }
};

class LFXTradeDataManager : public LFXTradeBase {
private:
    // CHistoryOrderInfo m_histInfo; // Removed - not needed with direct HistoryDealGetX calls

    void AggregatePositionData(ENUM_POSITION_TYPE type, double& totalVolume, double& totalProfit, int& positionCount,
                               double& lastOpenPrice, ulong& lastTicket, double& firstOpenPrice, 
                               datetime& latestOpenTime, datetime& earliestOpenTime) {
        totalVolume = 0.0; totalProfit = 0.0; positionCount = 0;
        lastOpenPrice = 0.0; lastTicket = 0; firstOpenPrice = 0.0;
        latestOpenTime = 0; earliestOpenTime = 0;

        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if (!IsRelevant(ticket)) continue;
            if (type != -1 && m_posInfo.PositionType() != type) continue;

            totalVolume += m_posInfo.Volume();
            totalProfit += m_posInfo.Profit() + m_posInfo.Swap();
            positionCount++;

            datetime openTime = (datetime)m_posInfo.Time();
            double openPrice = m_posInfo.PriceOpen();
            if (openTime > latestOpenTime) {
                latestOpenTime = openTime;
                lastOpenPrice = openPrice;
                lastTicket = ticket;
            }
            if (earliestOpenTime == 0 || openTime < earliestOpenTime) {
                earliestOpenTime = openTime;
                firstOpenPrice = openPrice;
            }
        }
    }

    double CalculateAverageOpenPrice(ENUM_POSITION_TYPE type) {
        double totalPriceVolume = 0.0, totalVolume = 0.0;
        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if (!IsRelevant(ticket)) continue;
            if (m_posInfo.PositionType() == type) {
                totalPriceVolume += m_posInfo.PriceOpen() * m_posInfo.Volume();
                totalVolume += m_posInfo.Volume();
            }
        }
        return totalVolume > 0 ? NormalizeDouble(totalPriceVolume / totalVolume, _Digits) : 0.0;
    }

public:
    LFXTradeDataManager(string expertName, string symbol, ulong magicNumber = 0) 
        : LFXTradeBase(expertName, symbol, magicNumber) {}

    double GetPositionLastOpenPrice(ENUM_POSITION_TYPE type) {
        double volume, profit, lastOpenPrice;
        int count;
        ulong lastTicket;
        double firstOpenPrice;
        datetime latestTime, earliestTime;
        AggregatePositionData(type, volume, profit, count, lastOpenPrice, lastTicket, firstOpenPrice, latestTime, earliestTime);
        return lastOpenPrice;
    }

    double GetPositionLastOpenPrice(ENUM_POSITION_TYPE type, ulong& ticket) {
        double volume, profit, lastOpenPrice;
        int count;
        double firstOpenPrice;
        datetime latestTime, earliestTime;
        AggregatePositionData(type, volume, profit, count, lastOpenPrice, ticket, firstOpenPrice, latestTime, earliestTime);
        return lastOpenPrice;
    }

    double GetPositionFirstOpenPrice(ENUM_POSITION_TYPE type) {
        double volume, profit, lastOpenPrice;
        int count;
        ulong lastTicket;
        double firstOpenPrice;
        datetime latestTime, earliestTime;
        AggregatePositionData(type, volume, profit, count, lastOpenPrice, lastTicket, firstOpenPrice, latestTime, earliestTime);
        return firstOpenPrice;
    }

    double GetTotalVolume(ENUM_POSITION_TYPE type = -1) {
        double volume, profit;
        int count;
        ulong lastTicket;
        double lastPrice, firstPrice;
        datetime latestTime, earliestTime;
        AggregatePositionData(type, volume, profit, count, lastPrice, lastTicket, firstPrice, latestTime, earliestTime);

        if (type == -1) {
            for (int i = OrdersTotal() - 1; i >= 0; i--) {
                ulong ticket = OrderGetTicket(i);
                if (!IsRelevant(ticket, false)) continue;
                volume += OrderGetDouble(ORDER_VOLUME_CURRENT);
            }
        }
        return volume;
    }

    double GetPositionAverageOpenPrice(ENUM_POSITION_TYPE type) {
        return CalculateAverageOpenPrice(type);
    }

    int GetPositionCount(ENUM_POSITION_TYPE type) {
        double volume, profit, lastPrice;
        int count;
        ulong lastTicket;
        double firstPrice;
        datetime latestTime, earliestTime;
        AggregatePositionData(type, volume, profit, count, lastPrice, lastTicket, firstPrice, latestTime, earliestTime);
        return count;
    }

    double GetDailyProfitLoss() {
        MqlDateTime today;
        TimeToStruct(TimeCurrent(), today);
        today.hour = 0;
        today.min = 0;
        today.sec = 0;
        datetime start = StructToTime(today);

        double historyProfit = 0.0;
        HistorySelect(start, TimeCurrent());
        uint totalDeals = HistoryDealsTotal();
        for (uint i = 0; i < totalDeals; i++) {
            ulong ticket = HistoryDealGetTicket(i);
            if (ticket == 0) continue; // Invalid ticket

            ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
            if (dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL) continue;
            if (HistoryDealGetString(ticket, DEAL_SYMBOL) != m_symbol) continue;
            if (m_magicNumber > 0 && HistoryDealGetInteger(ticket, DEAL_MAGIC) != m_magicNumber) continue;
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            if (dealTime >= start) {
                historyProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                                 HistoryDealGetDouble(ticket, DEAL_SWAP) +
                                 HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            }
        }
        return historyProfit + GetFloatingProfitLoss();
    }

    double CalculatePositionPotentialLoss(ENUM_POSITION_TYPE type, double stopLossPrice) {
        if (stopLossPrice <= 0) {
            LogError(__FUNCTION__, "Invalid stop-loss price: " + DoubleToString(stopLossPrice, 2));
            return 0.0;
        }

        double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
        if (tickSize == 0 || tickValue == 0) {
            LogError(__FUNCTION__, "Invalid tick size or value");
            return 0.0;
        }

        double totalLoss = 0.0;
        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if (!IsRelevant(ticket)) continue;
            if (m_posInfo.PositionType() != type) continue;

            double openPrice = m_posInfo.PriceOpen();
            double volume = m_posInfo.Volume();
            totalLoss += (type == POSITION_TYPE_BUY) ?
                         (openPrice - stopLossPrice) * volume * tickValue / tickSize :
                         (stopLossPrice - openPrice) * volume * tickValue / tickSize;
        }
        return totalLoss;
    }

    void GetPositionSummary(int& buyCount, double& buyProfitLoss, double& buyVolume,
                            int& sellCount, double& sellProfitLoss, double& sellVolume) {
        buyCount = 0; buyProfitLoss = 0.0; buyVolume = 0.0;
        sellCount = 0; sellProfitLoss = 0.0; sellVolume = 0.0;

        for (int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if (!IsRelevant(ticket)) continue;

            if (m_posInfo.PositionType() == POSITION_TYPE_BUY) {
                buyCount++;
                buyProfitLoss += m_posInfo.Profit() + m_posInfo.Swap();
                buyVolume += m_posInfo.Volume();
            } else if (m_posInfo.PositionType() == POSITION_TYPE_SELL) {
                sellCount++;
                sellProfitLoss += m_posInfo.Profit() + m_posInfo.Swap();
                sellVolume += m_posInfo.Volume();
            }
        }
    }

    virtual double GetFloatingProfitLoss() override {
        return LFXTradeBase::GetFloatingProfitLoss();
    }
};

#endif