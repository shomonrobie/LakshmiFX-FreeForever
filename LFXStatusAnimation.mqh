#property copyright "Copyright 2024, SHOMON ROBIE."
#property link      "https://www.lakshmifx.com"
#property version   "2.00"
#property description "Free Forever!"
#property description "Written by Shomon Robie"

#ifndef LFX_STATUS_ANIMATION_MQH
#define LFX_STATUS_ANIMATION_MQH

// Define platform-specific constants
#ifdef __MQL5__
   #define CHART_ID 0
#else
   #define CHART_ID 0
#endif

// Class to manage LakshmiFX EA visual states
class LFXStatusAnimation
{
private:
   int m_consecutiveTicks;
   int m_animationStep;
   datetime m_lastUpdate;
   
   string m_grokThinkingName1, m_grokThinkingName2, m_grokThinkingName3;
   string m_threeDotsName1, m_threeDotsName2, m_threeDotsName3;
   int m_frame;

   void createLabel(long chartId, int subWindow, string name, string text, ENUM_ANCHOR_POINT anchor,
                    ENUM_BASE_CORNER corner, int x, int y, int zOrder, color clr);

public:
   LFXStatusAnimation() : m_consecutiveTicks(0), m_animationStep(0), m_lastUpdate(0) {}
   ~LFXStatusAnimation() { ClearVisuals(); }

   


   // Function 1: Dot-flashing animation for trade analysis with sequential blinking
   void DrawGrokThinking(ENUM_ANCHOR_POINT anchor, ENUM_BASE_CORNER corner, 
                         int xDistance, int yDistance, int zOrder = 3, 
                         bool checkingForBuy = false, bool checkingForSell = false)
   {
      if (TimeCurrent() - m_lastUpdate < 0.2) return;
      m_lastUpdate = TimeCurrent();
      
      ObjectDelete(CHART_ID, "FlashDot1");
      ObjectDelete(CHART_ID, "FlashDot2");
      ObjectDelete(CHART_ID, "FlashDot3");
      m_consecutiveTicks = 0;
      
      color redGradient[] = {clrRed, clrDarkRed, clrMaroon};
      color greenGradient[] = {clrLime, clrGreen, clrDarkGreen};
      
      color colors[3];
      if (checkingForBuy) {
         ArrayCopy(colors, greenGradient);
      } else if (checkingForSell) {
         ArrayCopy(colors, redGradient);
      } else {
         return;
      }
      
      string names[] = {"FlashDot1", "FlashDot2", "FlashDot3"};
      int xOffsets[] = {0, 15, 30};
      
      for (int i = 0; i < 3; i++) {
         string name = names[i];
         if (ObjectCreate(CHART_ID, name, OBJ_LABEL, 0, 0, 0)) {
            ObjectSetString(CHART_ID, name, OBJPROP_TEXT, "•");
            ObjectSetInteger(CHART_ID, name, OBJPROP_FONTSIZE, 12);
            ObjectSetInteger(CHART_ID, name, OBJPROP_ANCHOR, anchor);
            ObjectSetInteger(CHART_ID, name, OBJPROP_CORNER, corner);
            ObjectSetInteger(CHART_ID, name, OBJPROP_XDISTANCE, xDistance + xOffsets[i]);
            ObjectSetInteger(CHART_ID, name, OBJPROP_YDISTANCE, yDistance - 20);
            ObjectSetInteger(CHART_ID, name, OBJPROP_COLOR, colors[i]);
            ObjectSetInteger(CHART_ID, name, OBJPROP_ZORDER, zOrder);
         }
      }
      
      int blinkPhase = m_animationStep % 3;
      for (int i = 0; i < 3; i++) {
         bool isVisible = (i != blinkPhase);
         ObjectSetInteger(CHART_ID, names[i], OBJPROP_TIMEFRAMES, isVisible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
      }
      
      m_animationStep++;
      ChartRedraw();
   }

   // Function 2: Dot-flashing animation for monitoring mode with per-tick blinking
   void DrawThreeDots(ENUM_ANCHOR_POINT anchor, ENUM_BASE_CORNER corner, 
                      int xDistance, int yDistance, int zOrder = 3)
   {
      if (TimeCurrent() - m_lastUpdate < 0.2) return;
      m_lastUpdate = TimeCurrent();
      
      if (m_consecutiveTicks >= 3) {
         ObjectDelete(CHART_ID, "FlashDot1");
         ObjectDelete(CHART_ID, "FlashDot2");
         ObjectDelete(CHART_ID, "FlashDot3");
         m_consecutiveTicks = 0;
         m_animationStep = 0;
      }
      
      color colors[] = {clrDeepSkyBlue, clrMediumOrchid, clrLime};
      string names[] = {"FlashDot1", "FlashDot2", "FlashDot3"};
      int xOffsets[] = {0, 15, 30};
      
      if (m_consecutiveTicks < 3) {
         string name = names[m_consecutiveTicks];
         if (ObjectCreate(CHART_ID, name, OBJ_LABEL, 0, 0, 0)) {
            ObjectSetString(CHART_ID, name, OBJPROP_TEXT, "•");
            ObjectSetInteger(CHART_ID, name, OBJPROP_FONTSIZE, 12);
            ObjectSetInteger(CHART_ID, name, OBJPROP_ANCHOR, anchor);
            ObjectSetInteger(CHART_ID, name, OBJPROP_CORNER, corner);
            ObjectSetInteger(CHART_ID, name, OBJPROP_XDISTANCE, xDistance + xOffsets[m_consecutiveTicks]);
            ObjectSetInteger(CHART_ID, name, OBJPROP_YDISTANCE, yDistance - 20);
            ObjectSetInteger(CHART_ID, name, OBJPROP_COLOR, colors[m_consecutiveTicks]);
            ObjectSetInteger(CHART_ID, name, OBJPROP_ZORDER, zOrder);
         }
         m_consecutiveTicks++;
      }
      
      if (m_consecutiveTicks > 0) {
         int blinkIndex = m_consecutiveTicks - 1;
         string blinkName = names[blinkIndex];
         bool isVisible = (m_animationStep % 2 == 0);
         ObjectSetInteger(CHART_ID, blinkName, OBJPROP_TIMEFRAMES, isVisible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
         
         for (int i = 0; i < 3; i++) {
            if (i != blinkIndex && ObjectFind(CHART_ID, names[i]) >= 0) {
               ObjectSetInteger(CHART_ID, names[i], OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
            }
         }
      }
      
      m_animationStep++;
      ChartRedraw();
   }

   // Cleanup function to remove visual objects
   void ClearVisuals()
   {
      ObjectDelete(CHART_ID, "GrokThink1");
      ObjectDelete(CHART_ID, "FlashDot1");
      ObjectDelete(CHART_ID, "FlashDot2");
      ObjectDelete(CHART_ID, "FlashDot3");
   }
};

#endif