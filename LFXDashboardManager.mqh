#ifndef LFX_DASHBOARD_MANAGER_MQH
#define LFX_DASHBOARD_MANAGER_MQH

#define DASHBOARD_SIZE 16

// Layout constants
#define X_BG 5
#define Y_BG 20
#define X_FIRST_COLUMN 10
#define X_SECOND_COLUMN 160
#define TOTAL_COLUMN_WIDTH 240
#define HEADER_HEIGHT 40
#define FONT_SIZE 7
#define LINE_HEIGHT 13
#define FONT_NAME "Arial"
#define ANIMATION_X_OFFSET 220

#include <LakshmiFX\LFXStatusAnimation.mqh>

enum ENUM_TRADE_DIRECTION {
   BOTH_BUY_SELL, // Both buy & sell
   BUY_ONLY,      // Buy only
   SELL_ONLY      // Sell only
};

struct DashboardData {
   double eaVersion;             // Static
   long magicNumber;             // Static
   string currentDay;            // Static
   double spread;                // Real-time
   string marketCondition;       // Static
   double equity;                // Real-time
   double balance;               // Real-time
   double buyPL;                 // Real-time
   int buyPosTotal;              // Near real-time
   double sellPL;                // Real-time
   int sellPosTotal;             // Near real-time
   double runningPL;             // Real-time
   double bePrice;               // Static
   ENUM_TRADE_DIRECTION tradeDirection; // Static
   string maxLossStatus;         // Near real-time
   string profitTargetStatus;    // Near real-time
};

class LFXDashboardManager {
private:
   string m_propNames[DASHBOARD_SIZE];
   string m_propValues[DASHBOARD_SIZE];
   string m_propTexts[DASHBOARD_SIZE];
   int m_yPositions[DASHBOARD_SIZE];

   string m_eaName;
   bool m_displayDashboard;
   color m_titleColor, m_textColor, m_borderColor, m_bgColor, m_activeButtonColor;

   LFXStatusAnimation* m_animation;

   void createLabel(string name, string text, int x, int y, color clr) {
      if (ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) {
         ObjectSetString(0, name, OBJPROP_TEXT, text);
         ObjectSetString(0, name, OBJPROP_FONT, FONT_NAME);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FONT_SIZE);
         ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
         ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
      }
   }

   string getValueText(int index, DashboardData& data) {
      switch (index) {
         case 0: return DoubleToString(data.eaVersion, 2);
         case 1: return IntegerToString(data.magicNumber);
         case 2: return data.currentDay;
         case 3: return DoubleToString(data.spread, 1);
         case 4: return data.marketCondition;
         case 5: return DoubleToString(data.equity, 2);
         case 6: return DoubleToString(data.balance, 2);
         case 7: return DoubleToString(data.buyPL, 2);
         case 8: return IntegerToString(data.buyPosTotal);
         case 9: return DoubleToString(data.sellPL, 2);
         case 10: return IntegerToString(data.sellPosTotal);
         case 11: return DoubleToString(data.runningPL, 2);
         case 12: return DoubleToString(data.bePrice, 5);
         case 13: return EnumToString(data.tradeDirection);
         case 14: return data.maxLossStatus;
         case 15: return data.profitTargetStatus;
         default: return "";
      }
   }

   void renderAnimations(DashboardData& data) {
      int animY = m_yPositions[14]; // Next to maxLossStatus
      m_animation.ClearVisuals();

      if (data.maxLossStatus != "" || data.profitTargetStatus != "") {
         return; // Override if limits active
      }
      if (data.buyPosTotal + data.sellPosTotal == 0) {
         m_animation.DrawGrokThinking(ANCHOR_LEFT_UPPER, CORNER_LEFT_UPPER, ANIMATION_X_OFFSET, animY, 2, true, false);
      } else {
         m_animation.DrawThreeDots(ANCHOR_LEFT_UPPER, CORNER_LEFT_UPPER, ANIMATION_X_OFFSET, animY, 2);
      }
   }

public:
   LFXDashboardManager(string eaName, bool displayDashboard, color titleColor, 
                       color textColor, color borderColor, color bgColor, 
                       color activeButtonColor) {
      m_eaName = eaName;
      m_displayDashboard = displayDashboard;
      m_titleColor = titleColor;
      m_textColor = textColor;
      m_borderColor = borderColor;
      m_bgColor = bgColor;
      m_activeButtonColor = activeButtonColor;
      m_animation = new LFXStatusAnimation();

      string propNames[DASHBOARD_SIZE] = {
         "ea_version", "magic_number", "current_day", "spread", "market_condition",
         "equity", "balance", "buy_pl", "buy_pos_total", "sell_pl",
         "sell_pos_total", "running_pl", "be_price", "trade_direction",
         "maxLossStatus", "profitTargetStatus"
      };
      string propValues[DASHBOARD_SIZE] = {
         "value_ea_version", "value_magic_number", "value_current_day", "value_spread", 
         "value_market_condition", "value_equity", "value_balance", "value_buy_pl", 
         "value_buy_pos_total", "value_sell_pl", "value_sell_pos_total", "value_running_pl", 
         "value_be_price", "value_trade_direction", "value_maxLossStatus", "value_profitTargetStatus"
      };
      string propTexts[DASHBOARD_SIZE] = {
         "Version", "Magic #", "Current Day", "Spread", "Market Condition",
         "Equity", "Balance", "Buy Order PL", "Buy Pos Total", "Sell Order PL",
         "Sell Pos Total", "Running PL", "Lock Profit Price", "Trade Direction",
         "Max Loss: ", "Profit Target: "
      };
      ArrayCopy(m_propNames, propNames);
      ArrayCopy(m_propValues, propValues);
      ArrayCopy(m_propTexts, propTexts);
   }

   ~LFXDashboardManager() {
      delete m_animation;
      for (int i = 0; i < DASHBOARD_SIZE; i++) {
         ObjectDelete(0, m_propNames[i]);
         ObjectDelete(0, m_propValues[i]);
      }
   }

   void init(DashboardData& data) {
      if (!m_displayDashboard) return;
      for (int i = 0; i < DASHBOARD_SIZE; i++) {
         m_yPositions[i] = Y_BG + HEADER_HEIGHT + (i * LINE_HEIGHT);
         createLabel(m_propNames[i], m_propTexts[i], X_FIRST_COLUMN, m_yPositions[i], m_textColor);
         createLabel(m_propValues[i], getValueText(i, data), X_SECOND_COLUMN, m_yPositions[i], m_textColor);
      }
      renderAnimations(data);
      ChartRedraw();
   }

   void update(DashboardData& data) {
      if (!m_displayDashboard) return;
      for (int i = 0; i < DASHBOARD_SIZE; i++) {
         ObjectSetString(0, m_propValues[i], OBJPROP_TEXT, getValueText(i, data));
      }
      renderAnimations(data);
      ChartRedraw();
   }
};

#endif