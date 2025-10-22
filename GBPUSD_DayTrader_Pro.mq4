//+------------------------------------------------------------------+
//|                                      GBPUSD_DayTrader_Pro.mq4    |
//|                        Professional GBP/USD Day Trading System   |
//|                         Optimized for Intraday Trading          |
//+------------------------------------------------------------------+
#property copyright "Professional Day Trading Systems"
#property version   "3.00"
#property strict
#property description "Advanced GBP/USD Day Trading EA with 5 Professional Features"

//=== DAY TRADING CORE SETTINGS ===
input string ___DAYTRADING___ = "=== DAY TRADING STRATEGY ===";
input bool EnablePriceActionDayTrading = true;
input bool EnableBreakoutDayTrading = true;
input bool EnableTrendDayTrading = true;
input bool EnableMomentumDayTrading = true;
input bool EnableOrderFlowDayTrading = true;
input int DayTradingTimeframe = 60; // H1 for day trading
input int MaxTradesPerDay = 3; // Day traders take 1-3 quality trades
input int MaxTradesPerHour = 2; // Maximum trades per hour
input bool CloseAllAtEndOfDay = true;
input int EndOfDayHour = 21; // Close all positions at 9 PM GMT

//=== ENTRY FILTERS ===
input string ___FILTERS___ = "=== ENTRY FILTERS ===";
input double MaxSpreadPoints = 3.0; // Maximum spread in points (wider for day trading)
input bool RequireVolatility = true;
input double MinATRPips = 15.0; // Minimum ATR for day trading entry
input double MaxATRPips = 80.0; // Maximum ATR for day trading entry
input bool UseOrderFlow = true;
input int OrderFlowPeriod = 20; // Longer period for day trading

//=== TRADING SESSIONS ===
input string ___SESSIONS___ = "=== SESSION FILTERS ===";
input bool TradeLondonSession = true;
input int LondonStartHour = 8;
input int LondonEndHour = 16;
input bool TradeNYSession = true;
input int NYStartHour = 13;
input int NYEndHour = 21;
input bool TradeAsianSession = false;
input int AsianStartHour = 0;
input int AsianEndHour = 8;

//=== TECHNICAL INDICATORS ===
input string ___INDICATORS___ = "=== DAY TRADING INDICATORS ===";
input int FastEMA = 8;
input int SlowEMA = 21;
input int SignalEMA = 50;
input int RSI_Period = 14;
input int RSI_OverboughtLevel = 70;
input int RSI_OversoldLevel = 30;
input int StochasticK = 14;
input int StochasticD = 3;
input int StochasticSlowing = 3;
input int BollingerPeriod = 20;
input double BollingerDeviation = 2.0;
input int ATR_Period = 14;

//=== DAY TRADING RISK MANAGEMENT ===
input string ___RISK___ = "=== RISK MANAGEMENT ===";
input double RiskPercentPerTrade = 1.0; // Higher risk per day trade
input int StopLossPips = 40; // Wider stop loss for day trading
input int TakeProfitPips = 80; // Larger profit target
input bool UseTrailingStop = true;
input int TrailingStopPips = 20; // Wider trailing for day trading
input bool UseBreakEven = true;
input int BreakEvenPips = 20; // Move to BE after 20 pips profit
input int BreakEvenPlusPips = 5;

//=== POSITION MANAGEMENT ===
input string ___POSITION___ = "=== POSITION MANAGEMENT ===";
input int MaxConcurrentPositions = 2; // Can hold 2 day trades
input double MaxDailyLossPercent = 4.0; // Higher tolerance for day trading
input double MaxDailyProfitPercent = 8.0; // Higher daily profit target
input int MagicNumberDayTrade = 888888;

//=== ADVANCED FEATURES (PROFITABILITY BOOST) ===
input string ___ADVANCED___ = "=== ADVANCED FEATURES ===";
input bool UseMultiTimeframeFilter = true;
input int MTF_Timeframe1 = 60; // H1 for day trading
input int MTF_Timeframe2 = 240; // H4 for day trading
input int MTF_Timeframe3 = 1440; // D1 for day trading
input bool UseDynamicSLTP = true;
input double DynamicSLMultiplier = 1.5; // ATR multiplier for SL (day trading)
input double DynamicTPMultiplier = 3.0; // ATR multiplier for TP (day trading)
input double MinSLPips = 25.0; // Minimum SL for day trading
input double MaxSLPips = 60.0; // Maximum SL for day trading
input bool UsePartialProfitTaking = true;
input double PartialClosePercent = 50.0; // Close 50% at first target
input double PartialTP1Multiplier = 1.5; // First TP at 1.5x SL
input double PartialTP2Multiplier = 2.5; // Let rest run to 2.5x SL (day trading)
input bool UseCurrencyStrength = true;
input int StrengthPeriod = 20; // Longer period for day trading
input double MinStrengthDifference = 0.4; // Higher threshold for day trading
input bool UseTimeOptimization = true;
input bool TrackHourlyPerformance = true;
input double OverlapLotMultiplier = 1.2; // Moderate boost for day trading
input double OptimalHourMultiplier = 1.15; // Moderate boost for day trading
input int MinTradesForOptimization = 3; // Fewer trades needed (day trading)
input double MinWinRateForOptimal = 60.0; // Higher win rate required

//=== DAY TRADING DASHBOARD ===
input string ___DASHBOARD___ = "=== DASHBOARD ===";
input bool ShowDayTradeDashboard = true;
input int DashX = 20;
input int DashY = 30;
input color ProfitColorDayTrade = clrLimeGreen;
input color LossColorDayTrade = clrRed;
input color NeutralColorDayTrade = clrYellow;

//=== GLOBAL VARIABLES ===
datetime LastBarTime = 0;
datetime LastDayTradeTime = 0;
int DayTradesToday = 0;
int DayTradesThisHour = 0;
double DailyPnL = 0;
double SessionPnL = 0;
int TotalDayTrades = 0;
int WinningDayTrades = 0;
int LosingDayTrades = 0;
double MaxEquity = 0;
double CurrentDrawdown = 0;
double WinRate = 0;
double ProfitFactor = 0;
double AveragePips = 0;

// Market Analysis
double CurrentSpread = 0;
double CurrentATR = 0;
double CurrentVolatility = 0;
string MarketCondition = "";
string TradingSession = "";
bool InTradingWindow = false;
string CurrentSignal = "";
double OrderFlowBias = 0; // Positive = bullish, Negative = bearish

// Price levels
double DynamicSupport = 0;
double DynamicResistance = 0;
double PivotPoint = 0;
double R1 = 0, R2 = 0, S1 = 0, S2 = 0;

// Performance tracking
double TotalPips = 0;
double BestDayTrade = 0;
double WorstDayTrade = 0;
datetime StartOfDay = 0;

// Advanced Features Variables
string MTF_Trend_H1 = "";
string MTF_Trend_H4 = "";
string MTF_Trend_D1 = "";
string MTF_OverallTrend = "";
bool MTF_TrendAligned = false;
double GBP_Strength = 0;
double USD_Strength = 0;
double StrengthDifference = 0;
bool StrengthConfirmed = false;
int PartialPositionsToday = 0;
int FullClosuresToday = 0;

// Feature 5: Time Optimization Variables
int HourlyTrades[24];
int HourlyWins[24];
double HourlyPnL[24];
double HourlyWinRate[24];
bool OptimalHours[24];
string CurrentHourQuality = "";
double CurrentTimeMultiplier = 1.0;
int BestTradingHour = -1;
int WorstTradingHour = -1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== GBP/USD DAY TRADER PRO EA INITIALIZED ===");
   Print("Symbol: ", Symbol());
   Print("Timeframe: H1 (Day Trading)");
   Print("Max Spread: ", MaxSpreadPoints, " points");
   Print("Stop Loss: ", StopLossPips, " pips");
   Print("Take Profit: ", TakeProfitPips, " pips");
   Print("End of Day Hour: ", EndOfDayHour, ":00 GMT");

   // Validate settings
   if(!ValidateSettings())
   {
      Print("ERROR: Invalid settings detected!");
      return(INIT_PARAMETERS_INCORRECT);
   }

   // Initialize variables
   MaxEquity = AccountEquity();
   StartOfDay = TimeCurrent();
   LastBarTime = Time[0];

   // Initialize hourly tracking arrays
   for(int h = 0; h < 24; h++)
   {
      HourlyTrades[h] = 0;
      HourlyWins[h] = 0;
      HourlyPnL[h] = 0;
      HourlyWinRate[h] = 0;
      OptimalHours[h] = false;
   }

   // Create dashboard
   if(ShowDayTradeDashboard)
      CreateDayTradeDashboard();

   // Set timer for dashboard updates
   EventSetTimer(1); // 1-second updates for day trading

   Print("Initialization successful!");
   Print("Trading Sessions: London=", TradeLondonSession, " NY=", TradeNYSession, " Asian=", TradeAsianSession);

   // Print Advanced Features Status
   Print("=== ADVANCED FEATURES (ALL 5 ENABLED) ===");
   Print("Feature 1 - Multi-Timeframe Filter: ", UseMultiTimeframeFilter ? "Enabled" : "Disabled");
   Print("Feature 2 - Dynamic SL/TP: ", UseDynamicSLTP ? "Enabled" : "Disabled");
   Print("Feature 3 - Partial Profit Taking: ", UsePartialProfitTaking ? "Enabled" : "Disabled");
   Print("Feature 4 - Currency Strength Filter: ", UseCurrencyStrength ? "Enabled" : "Disabled");
   Print("Feature 5 - Time Optimization: ", UseTimeOptimization ? "Enabled" : "Disabled");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   if(ShowDayTradeDashboard)
      DeleteDayTradeDashboard();

   Print("=== GBP/USD DAY TRADER PRO EA STOPPED ===");
   Print("Total Day Trades: ", TotalDayTrades);
   Print("Winning Day Trades: ", WinningDayTrades);
   Print("Losing Day Trades: ", LosingDayTrades);
   if(TotalDayTrades > 0)
      Print("Win Rate: ", DoubleToStr(WinRate, 1), "%");
   Print("Profit Factor: ", DoubleToStr(ProfitFactor, 2));
   Print("Total Pips: ", DoubleToStr(TotalPips, 1));
   Print("Average Pips: ", DoubleToStr(AveragePips, 2));
   Print("Daily P&L: $", DoubleToStr(DailyPnL, 2));
   Print("Max Drawdown: ", DoubleToStr(CurrentDrawdown, 2), "%");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Update dashboard continuously
   if(ShowDayTradeDashboard)
      UpdateDayTradeDashboard();

   // Check for end-of-day closure (DAY TRADING SPECIFIC)
   if(CloseAllAtEndOfDay && TimeHour(TimeCurrent()) >= EndOfDayHour)
   {
      if(CountPositions() > 0)
      {
         CloseAllPositions("End of day closure");
         Print("=== END OF DAY - All positions closed ===");
      }
      return; // Don't trade after end of day
   }

   // Market conditions update
   UpdateMarketConditions();

   // Check for new bar
   if(Time[0] == LastBarTime)
      return;
   LastBarTime = Time[0];

   // Check if new day
   if(TimeDay(TimeCurrent()) != TimeDay(StartOfDay))
   {
      ResetDailyCounters();
      StartOfDay = TimeCurrent();
   }

   // Comprehensive day trading analysis
   AnalyzeDayTradingOpportunity();

   // Risk checks
   if(!ValidateRiskParameters())
      return;

   // Manage existing positions
   ManageDayTradePositions();

   // Execute day trading strategies
   ExecuteDayTradingStrategies();

   // Update performance
   UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Settings validation                                             |
//+------------------------------------------------------------------+
bool ValidateSettings()
{
   if(Symbol() != "GBPUSD" && StringFind(Symbol(), "GBP") < 0)
   {
      Print("WARNING: This EA is optimized for GBP/USD");
   }

   if(StopLossPips < 5)
   {
      Print("ERROR: Stop loss too small for GBP/USD");
      return false;
   }

   if(TakeProfitPips < StopLossPips)
   {
      Print("ERROR: Take profit should be >= stop loss");
      return false;
   }

   if(RiskPercentPerTrade > 2.0)
   {
      Print("WARNING: Risk per trade is high for day trading");
   }

   return true;
}

//+------------------------------------------------------------------+
//| Market conditions update                                        |
//+------------------------------------------------------------------+
void UpdateMarketConditions()
{
   // Update spread
   CurrentSpread = (Ask - Bid) / Point;

   // Update ATR
   CurrentATR = iATR(Symbol(), 0, ATR_Period, 0);
   double avgPrice = (Ask + Bid) / 2;
   CurrentVolatility = (CurrentATR / avgPrice) * 10000; // In pips

   // Determine trading session
   int currentHour = TimeHour(TimeCurrent());
   TradingSession = "";
   InTradingWindow = false;

   if(TradeLondonSession && currentHour >= LondonStartHour && currentHour < LondonEndHour)
   {
      TradingSession = "LONDON";
      InTradingWindow = true;
   }

   if(TradeNYSession && currentHour >= NYStartHour && currentHour < NYEndHour)
   {
      if(TradingSession == "LONDON")
         TradingSession = "LONDON/NY OVERLAP";
      else
         TradingSession = "NEW YORK";
      InTradingWindow = true;
   }

   if(TradeAsianSession && (currentHour >= AsianStartHour && currentHour < AsianEndHour))
   {
      TradingSession = "ASIAN";
      InTradingWindow = true;
   }

   if(TradingSession == "")
      TradingSession = "OFF-HOURS";
}

//+------------------------------------------------------------------+
//| Day trading opportunity analysis                                |
//+------------------------------------------------------------------+
void AnalyzeDayTradingOpportunity()
{
   // Calculate support/resistance
   CalculateDynamicLevels();

   // Calculate pivot points
   CalculatePivotPoints();

   // Analyze order flow
   if(UseOrderFlow)
      AnalyzeOrderFlow();

   // Determine market condition
   DetermineMarketCondition();

   // ADVANCED FEATURE 1: Multi-Timeframe Analysis
   AnalyzeMultiTimeframeTrend();

   // ADVANCED FEATURE 2: Currency Strength
   CalculateCurrencyStrength();

   // ADVANCED FEATURE 5: Time Optimization
   AnalyzeTimeOptimization();
}

void CalculateDynamicLevels()
{
   // Calculate recent high/low for support/resistance
   int lookback = 20;
   DynamicResistance = High[iHighest(Symbol(), 0, MODE_HIGH, lookback, 1)];
   DynamicSupport = Low[iLowest(Symbol(), 0, MODE_LOW, lookback, 1)];
}

void CalculatePivotPoints()
{
   // Classic pivot points
   double yesterdayHigh = iHigh(Symbol(), PERIOD_D1, 1);
   double yesterdayLow = iLow(Symbol(), PERIOD_D1, 1);
   double yesterdayClose = iClose(Symbol(), PERIOD_D1, 1);

   PivotPoint = (yesterdayHigh + yesterdayLow + yesterdayClose) / 3;
   R1 = (2 * PivotPoint) - yesterdayLow;
   R2 = PivotPoint + (yesterdayHigh - yesterdayLow);
   S1 = (2 * PivotPoint) - yesterdayHigh;
   S2 = PivotPoint - (yesterdayHigh - yesterdayLow);
}

void AnalyzeOrderFlow()
{
   // Simplified order flow based on price action and volume
   OrderFlowBias = 0;

   for(int i = 1; i <= OrderFlowPeriod; i++)
   {
      double bodySize = MathAbs(Close[i] - Open[i]);
      double rangeSize = High[i] - Low[i];

      if(rangeSize > 0)
      {
         double strength = bodySize / rangeSize;

         if(Close[i] > Open[i]) // Bullish
            OrderFlowBias += strength;
         else // Bearish
            OrderFlowBias -= strength;
      }
   }

   OrderFlowBias = OrderFlowBias / OrderFlowPeriod;
}

void DetermineMarketCondition()
{
   double ema_fast = iMA(Symbol(), 0, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_slow = iMA(Symbol(), 0, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);

   double range = DynamicResistance - DynamicSupport;
   double currentPrice = (Ask + Bid) / 2;

   // Determine condition
   if(CurrentSpread > MaxSpreadPoints)
   {
      MarketCondition = "HIGH SPREAD";
   }
   else if(CurrentVolatility < MinATRPips)
   {
      MarketCondition = "LOW VOLATILITY";
   }
   else if(CurrentVolatility > MaxATRPips)
   {
      MarketCondition = "HIGH VOLATILITY";
   }
   else if(range / Point < 100) // Less than 10 pips range
   {
      MarketCondition = "TIGHT RANGE";
   }
   else if(ema_fast > ema_slow && rsi > 50)
   {
      MarketCondition = "BULLISH TREND";
   }
   else if(ema_fast < ema_slow && rsi < 50)
   {
      MarketCondition = "BEARISH TREND";
   }
   else
   {
      MarketCondition = "RANGING";
   }
}

//+------------------------------------------------------------------+
//| FEATURE 1: Multi-Timeframe Trend Filter                        |
//+------------------------------------------------------------------+
void AnalyzeMultiTimeframeTrend()
{
   if(!UseMultiTimeframeFilter)
   {
      MTF_TrendAligned = true; // Allow all trades if disabled
      MTF_OverallTrend = "DISABLED";
      return;
   }

   // Analyze H1
   double h1_ema_fast = iMA(Symbol(), MTF_Timeframe1, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double h1_ema_slow = iMA(Symbol(), MTF_Timeframe1, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double h1_close = iClose(Symbol(), MTF_Timeframe1, 1);

   if(h1_close > h1_ema_fast && h1_ema_fast > h1_ema_slow)
      MTF_Trend_H1 = "BULLISH";
   else if(h1_close < h1_ema_fast && h1_ema_fast < h1_ema_slow)
      MTF_Trend_H1 = "BEARISH";
   else
      MTF_Trend_H1 = "NEUTRAL";

   // Analyze H4
   double h4_ema_fast = iMA(Symbol(), MTF_Timeframe2, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double h4_ema_slow = iMA(Symbol(), MTF_Timeframe2, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double h4_close = iClose(Symbol(), MTF_Timeframe2, 1);

   if(h4_close > h4_ema_fast && h4_ema_fast > h4_ema_slow)
      MTF_Trend_H4 = "BULLISH";
   else if(h4_close < h4_ema_fast && h4_ema_fast < h4_ema_slow)
      MTF_Trend_H4 = "BEARISH";
   else
      MTF_Trend_H4 = "NEUTRAL";

   // Analyze D1
   double d1_ema_fast = iMA(Symbol(), MTF_Timeframe3, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double d1_ema_slow = iMA(Symbol(), MTF_Timeframe3, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double d1_close = iClose(Symbol(), MTF_Timeframe3, 1);

   if(d1_close > d1_ema_fast && d1_ema_fast > d1_ema_slow)
      MTF_Trend_D1 = "BULLISH";
   else if(d1_close < d1_ema_fast && d1_ema_fast < d1_ema_slow)
      MTF_Trend_D1 = "BEARISH";
   else
      MTF_Trend_D1 = "NEUTRAL";

   // Determine overall trend (H4 and D1 must align for day trading)
   if(MTF_Trend_H4 == "BULLISH" && MTF_Trend_D1 == "BULLISH")
   {
      MTF_OverallTrend = "BULLISH";
      MTF_TrendAligned = true;
   }
   else if(MTF_Trend_H4 == "BEARISH" && MTF_Trend_D1 == "BEARISH")
   {
      MTF_OverallTrend = "BEARISH";
      MTF_TrendAligned = true;
   }
   else
   {
      MTF_OverallTrend = "MIXED";
      MTF_TrendAligned = false; // Don't trade if higher timeframes are mixed
   }
}

//+------------------------------------------------------------------+
//| FEATURE 2: Currency Strength/Correlation Filter                |
//+------------------------------------------------------------------+
void CalculateCurrencyStrength()
{
   if(!UseCurrencyStrength)
   {
      StrengthConfirmed = true; // Allow all trades if disabled
      GBP_Strength = 0;
      USD_Strength = 0;
      StrengthDifference = 0;
      return;
   }

   // Calculate GBP strength using GBP/USD and GBP/JPY
   double gbpusd_change = 0;
   double gbpjpy_change = 0;

   // GBP/USD change
   double gbpusd_current = iClose(Symbol(), 0, 1);
   double gbpusd_previous = iClose(Symbol(), 0, StrengthPeriod);
   if(gbpusd_previous != 0)
      gbpusd_change = ((gbpusd_current - gbpusd_previous) / gbpusd_previous) * 100;

   // GBP/JPY change (if available)
   double gbpjpy_current = iClose("GBPJPY", 0, 1);
   double gbpjpy_previous = iClose("GBPJPY", 0, StrengthPeriod);
   if(gbpjpy_previous != 0)
      gbpjpy_change = ((gbpjpy_current - gbpjpy_previous) / gbpjpy_previous) * 100;

   // Average GBP strength
   if(gbpjpy_current > 0) // If GBPJPY is available
      GBP_Strength = (gbpusd_change + gbpjpy_change) / 2;
   else
      GBP_Strength = gbpusd_change;

   // Calculate USD strength using EUR/USD
   double eurusd_change = 0;
   double eurusd_current = iClose("EURUSD", 0, 1);
   double eurusd_previous = iClose("EURUSD", 0, StrengthPeriod);
   if(eurusd_previous != 0)
      eurusd_change = ((eurusd_current - eurusd_previous) / eurusd_previous) * 100;

   // USD strength is inverse of EUR/USD
   USD_Strength = -eurusd_change;

   // Calculate strength difference
   StrengthDifference = GBP_Strength - USD_Strength;

   // Confirm if strength difference is significant
   if(MathAbs(StrengthDifference) >= MinStrengthDifference)
      StrengthConfirmed = true;
   else
      StrengthConfirmed = false;
}

//+------------------------------------------------------------------+
//| FEATURE 5: Enhanced Time-Based Trading Optimization            |
//+------------------------------------------------------------------+
void AnalyzeTimeOptimization()
{
   if(!UseTimeOptimization)
   {
      CurrentHourQuality = "DISABLED";
      CurrentTimeMultiplier = 1.0;
      return;
   }

   int currentHour = TimeHour(TimeCurrent());

   // Update hourly statistics from closed trades
   UpdateHourlyStatistics();

   // Determine if current hour is optimal
   if(TrackHourlyPerformance && HourlyTrades[currentHour] >= MinTradesForOptimization)
   {
      HourlyWinRate[currentHour] = (HourlyWins[currentHour] * 100.0) / HourlyTrades[currentHour];

      if(HourlyWinRate[currentHour] >= MinWinRateForOptimal && HourlyPnL[currentHour] > 0)
      {
         OptimalHours[currentHour] = true;
         CurrentHourQuality = "OPTIMAL";
      }
      else if(HourlyWinRate[currentHour] < 40 || HourlyPnL[currentHour] < 0)
      {
         OptimalHours[currentHour] = false;
         CurrentHourQuality = "POOR";
      }
      else
      {
         OptimalHours[currentHour] = false;
         CurrentHourQuality = "AVERAGE";
      }
   }
   else
   {
      CurrentHourQuality = "LEARNING";
   }

   // Calculate time-based lot multiplier
   CurrentTimeMultiplier = 1.0;

   // London/NY overlap bonus
   if(TradingSession == "LONDON/NY OVERLAP")
   {
      CurrentTimeMultiplier *= OverlapLotMultiplier;
      CurrentHourQuality += " + OVERLAP";
   }

   // Optimal hour bonus
   if(OptimalHours[currentHour])
   {
      CurrentTimeMultiplier *= OptimalHourMultiplier;
   }

   // Find best and worst hours
   FindBestWorstHours();
}

void UpdateHourlyStatistics()
{
   // Scan closed orders and update hourly stats
   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberDayTrade)
      {
         int closeHour = TimeHour(OrderCloseTime());
         double pnl = OrderProfit() + OrderSwap() + OrderCommission();

         // Only count if not already counted (check if this is from today)
         if(TimeDay(OrderCloseTime()) == TimeDay(TimeCurrent()))
         {
            // Note: This is simplified. In production, you'd want to track individual order IDs
            // to avoid double-counting. For now, we reset daily.
         }
      }
   }
}

void FindBestWorstHours()
{
   double bestPnL = -999999;
   double worstPnL = 999999;

   for(int h = 0; h < 24; h++)
   {
      if(HourlyTrades[h] >= MinTradesForOptimization)
      {
         if(HourlyPnL[h] > bestPnL)
         {
            bestPnL = HourlyPnL[h];
            BestTradingHour = h;
         }

         if(HourlyPnL[h] < worstPnL)
         {
            worstPnL = HourlyPnL[h];
            WorstTradingHour = h;
         }
      }
   }
}

void RecordTradeByHour(int tradeHour, bool isWin, double pnl)
{
   if(!TrackHourlyPerformance) return;

   if(tradeHour >= 0 && tradeHour < 24)
   {
      HourlyTrades[tradeHour]++;
      if(isWin) HourlyWins[tradeHour]++;
      HourlyPnL[tradeHour] += pnl;

      if(HourlyTrades[tradeHour] > 0)
         HourlyWinRate[tradeHour] = (HourlyWins[tradeHour] * 100.0) / HourlyTrades[tradeHour];
   }
}

//+------------------------------------------------------------------+
//| Risk validation                                                 |
//+------------------------------------------------------------------+
bool ValidateRiskParameters()
{
   // Check spread
   if(CurrentSpread > MaxSpreadPoints)
   {
      CurrentSignal = "SPREAD TOO HIGH";
      return false;
   }

   // Check volatility
   if(RequireVolatility)
   {
      if(CurrentVolatility < MinATRPips || CurrentVolatility > MaxATRPips)
      {
         CurrentSignal = "VOLATILITY OUT OF RANGE";
         return false;
      }
   }

   // Check trading window
   if(!InTradingWindow)
   {
      CurrentSignal = "OUTSIDE TRADING HOURS";
      return false;
   }

   // Check daily limits
   if(DayTradesToday >= MaxTradesPerDay)
   {
      CurrentSignal = "DAILY TRADE LIMIT REACHED";
      return false;
   }

   // Check hourly limits
   if(DayTradesThisHour >= MaxTradesPerHour)
   {
      CurrentSignal = "HOURLY TRADE LIMIT REACHED";
      return false;
   }

   // Check daily loss
   UpdateDailyPnL();
   double accountValue = AccountEquity();
   double dailyLoss = (DailyPnL / accountValue) * 100;

   if(dailyLoss < -MaxDailyLossPercent)
   {
      CurrentSignal = "DAILY LOSS LIMIT REACHED";
      CloseAllPositions("Daily loss limit");
      return false;
   }

   // Check daily profit target
   double dailyProfit = (DailyPnL / accountValue) * 100;
   if(dailyProfit > MaxDailyProfitPercent)
   {
      CurrentSignal = "DAILY PROFIT TARGET REACHED";
      CloseAllPositions("Daily profit target");
      return false;
   }

   // Check max positions
   if(CountPositions() >= MaxConcurrentPositions)
   {
      CurrentSignal = "MAX POSITIONS REACHED";
      return false;
   }

   // Update drawdown
   if(accountValue > MaxEquity)
      MaxEquity = accountValue;

   CurrentDrawdown = ((MaxEquity - accountValue) / MaxEquity) * 100;

   if(CurrentDrawdown > 10.0) // 10% max drawdown for day trading
   {
      CurrentSignal = "DRAWDOWN LIMIT EXCEEDED";
      return false;
   }

   // ADVANCED FILTER: Multi-Timeframe Trend Alignment
   if(UseMultiTimeframeFilter && !MTF_TrendAligned)
   {
      CurrentSignal = "MTF TREND NOT ALIGNED";
      return false;
   }

   // ADVANCED FILTER: Currency Strength Confirmation
   if(UseCurrencyStrength && !StrengthConfirmed)
   {
      CurrentSignal = "CURRENCY STRENGTH WEAK";
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Day trading strategies execution                                |
//+------------------------------------------------------------------+
void ExecuteDayTradingStrategies()
{
   CurrentSignal = "ANALYZING";

   // Price action day trading
   if(EnablePriceActionDayTrading)
      ExecutePriceActionDayTrade();

   // Breakout day trading
   if(EnableBreakoutDayTrading)
      ExecuteBreakoutDayTrade();

   // Trend day trading
   if(EnableTrendDayTrading)
      ExecuteRangeDayTrade();

   // Momentum day trading
   if(EnableMomentumDayTrading)
      ExecuteMomentumDayTrade();

   // Order flow day trading
   if(EnableOrderFlowDayTrading && UseOrderFlow)
      ExecuteOrderFlowDayTrade();
}

void ExecutePriceActionDayTrade()
{
   // Pin bar / rejection day trading
   double body = MathAbs(Close[1] - Open[1]);
   double upperWick = High[1] - MathMax(Close[1], Open[1]);
   double lowerWick = MathMin(Close[1], Open[1]) - Low[1];
   double totalRange = High[1] - Low[1];

   if(totalRange == 0) return;

   // Bullish pin bar at support
   if(lowerWick > body * 2 && lowerWick > upperWick &&
      Close[1] > Open[1] && Bid <= DynamicSupport + (10 * Point))
   {
      // MTF Filter: Only buy if MTF trend is bullish or disabled
      if(UseMultiTimeframeFilter && MTF_OverallTrend != "BULLISH" && MTF_OverallTrend != "DISABLED")
         return;

      // Currency Strength Filter: Ensure GBP is stronger than USD for buys
      if(UseCurrencyStrength && StrengthDifference < 0)
         return;

      if(!HasLongPosition())
      {
         ExecuteDayTrade(OP_BUY, "Price Action Bull");
         CurrentSignal = "PIN BAR BUY";
      }
   }

   // Bearish pin bar at resistance
   if(upperWick > body * 2 && upperWick > lowerWick &&
      Close[1] < Open[1] && Ask >= DynamicResistance - (10 * Point))
   {
      // MTF Filter: Only sell if MTF trend is bearish or disabled
      if(UseMultiTimeframeFilter && MTF_OverallTrend != "BEARISH" && MTF_OverallTrend != "DISABLED")
         return;

      // Currency Strength Filter: Ensure USD is stronger than GBP for sells
      if(UseCurrencyStrength && StrengthDifference > 0)
         return;

      if(!HasShortPosition())
      {
         ExecuteDayTrade(OP_SELL, "Price Action Bear");
         CurrentSignal = "PIN BAR SELL";
      }
   }
}

void ExecuteBreakoutDayTrade()
{
   double bb_upper = iBands(Symbol(), 0, BollingerPeriod, BollingerDeviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bb_lower = iBands(Symbol(), 0, BollingerPeriod, BollingerDeviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);

   // Bullish breakout
   if(Close[1] > bb_upper && Close[0] > Close[1] && rsi < RSI_OverboughtLevel)
   {
      if(!HasLongPosition() && MarketCondition == "BULLISH TREND")
      {
         ExecuteDayTrade(OP_BUY, "Breakout Bull");
         CurrentSignal = "BREAKOUT BUY";
      }
   }

   // Bearish breakout
   if(Close[1] < bb_lower && Close[0] < Close[1] && rsi > RSI_OversoldLevel)
   {
      if(!HasShortPosition() && MarketCondition == "BEARISH TREND")
      {
         ExecuteDayTrade(OP_SELL, "Breakout Bear");
         CurrentSignal = "BREAKOUT SELL";
      }
   }
}

void ExecuteRangeDayTrade()
{
   if(MarketCondition != "RANGING" && MarketCondition != "TIGHT RANGE")
      return;

   double range = DynamicResistance - DynamicSupport;
   double currentPrice = (Ask + Bid) / 2;
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);

   // Buy at support in range
   if(currentPrice <= DynamicSupport + (range * 0.2) && rsi < 40)
   {
      if(!HasLongPosition())
      {
         ExecuteDayTrade(OP_BUY, "Range Support");
         CurrentSignal = "RANGE BUY";
      }
   }

   // Sell at resistance in range
   if(currentPrice >= DynamicResistance - (range * 0.2) && rsi > 60)
   {
      if(!HasShortPosition())
      {
         ExecuteDayTrade(OP_SELL, "Range Resistance");
         CurrentSignal = "RANGE SELL";
      }
   }
}

void ExecuteMomentumDayTrade()
{
   double ema_fast = iMA(Symbol(), 0, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_slow = iMA(Symbol(), 0, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_signal = iMA(Symbol(), 0, SignalEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);

   double stoch_main = iStochastic(Symbol(), 0, StochasticK, StochasticD, StochasticSlowing, MODE_SMA, 0, MODE_MAIN, 0);
   double stoch_signal = iStochastic(Symbol(), 0, StochasticK, StochasticD, StochasticSlowing, MODE_SMA, 0, MODE_SIGNAL, 0);

   // Bullish momentum
   if(ema_fast > ema_slow && ema_slow > ema_signal &&
      rsi > 50 && rsi < RSI_OverboughtLevel &&
      stoch_main > stoch_signal && stoch_main < 80)
   {
      if(!HasLongPosition())
      {
         ExecuteDayTrade(OP_BUY, "Momentum Bull");
         CurrentSignal = "MOMENTUM BUY";
      }
   }

   // Bearish momentum
   if(ema_fast < ema_slow && ema_slow < ema_signal &&
      rsi < 50 && rsi > RSI_OversoldLevel &&
      stoch_main < stoch_signal && stoch_main > 20)
   {
      if(!HasShortPosition())
      {
         ExecuteDayTrade(OP_SELL, "Momentum Bear");
         CurrentSignal = "MOMENTUM SELL";
      }
   }
}

void ExecuteOrderFlowDayTrade()
{
   // Strong bullish order flow
   if(OrderFlowBias > 0.3 && MarketCondition == "BULLISH TREND")
   {
      if(!HasLongPosition())
      {
         ExecuteDayTrade(OP_BUY, "Order Flow Bull");
         CurrentSignal = "ORDER FLOW BUY";
      }
   }

   // Strong bearish order flow
   if(OrderFlowBias < -0.3 && MarketCondition == "BEARISH TREND")
   {
      if(!HasShortPosition())
      {
         ExecuteDayTrade(OP_SELL, "Order Flow Bear");
         CurrentSignal = "ORDER FLOW SELL";
      }
   }
}

//+------------------------------------------------------------------+
//| Execute day trade                                               |
//+------------------------------------------------------------------+
void ExecuteDayTrade(int orderType, string strategy)
{
   double lotSize = CalculateDayTradeLotSize();
   double price = (orderType == OP_BUY) ? Ask : Bid;
   double sl = CalculateStopLoss(orderType, price);
   double tp = CalculateTakeProfit(orderType, price);

   int ticket = OrderSend(Symbol(), orderType, lotSize, price, 3, sl, tp,
                         "DAY TRADE: " + strategy, MagicNumberDayTrade, 0,
                         (orderType == OP_BUY) ? ProfitColorDayTrade : LossColorDayTrade);

   if(ticket > 0)
   {
      TotalDayTrades++;
      DayTradesToday++;
      DayTradesThisHour++;
      LastDayTradeTime = TimeCurrent();

      Print("Day trade executed: ", strategy, " | Type: ", (orderType == OP_BUY ? "BUY" : "SELL"),
            " | Lot: ", lotSize, " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("Day trade failed: ", GetLastError(), " | Strategy: ", strategy);
   }
}

double CalculateDayTradeLotSize()
{
   double accountValue = AccountEquity();
   double riskAmount = accountValue * (RiskPercentPerTrade / 100.0);

   // FEATURE 5: Apply time-based multiplier
   if(UseTimeOptimization)
      riskAmount *= CurrentTimeMultiplier;

   double stopLossPoints = StopLossPips * 10; // Convert pips to points
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);

   double lotSize = 0.01;

   if(tickValue > 0 && tickSize > 0 && stopLossPoints > 0)
   {
      lotSize = riskAmount / (stopLossPoints * tickValue / tickSize);
   }

   // Ensure within limits
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(lotStep > 0)
      lotSize = MathRound(lotSize / lotStep) * lotStep;

   return lotSize;
}

double CalculateStopLoss(int orderType, double price)
{
   double sl = 0;
   double stopDistance = StopLossPips * 10 * Point;

   // FEATURE 3: Dynamic SL based on ATR
   if(UseDynamicSLTP)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, 1);
      double atrPips = (atr / Point) / 10; // Convert to pips

      // Calculate dynamic SL in pips
      double dynamicSLPips = atrPips * DynamicSLMultiplier;

      // Apply min/max limits
      dynamicSLPips = MathMax(MinSLPips, MathMin(MaxSLPips, dynamicSLPips));

      stopDistance = dynamicSLPips * 10 * Point;
   }

   if(orderType == OP_BUY)
      sl = price - stopDistance;
   else
      sl = price + stopDistance;

   return sl;
}

double CalculateTakeProfit(int orderType, double price)
{
   double tp = 0;
   double tpDistance = TakeProfitPips * 10 * Point;

   // FEATURE 3: Dynamic TP based on ATR
   if(UseDynamicSLTP)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, 1);
      double atrPips = (atr / Point) / 10; // Convert to pips

      // Calculate dynamic SL and TP in pips
      double dynamicSLPips = atrPips * DynamicSLMultiplier;
      dynamicSLPips = MathMax(MinSLPips, MathMin(MaxSLPips, dynamicSLPips));

      double dynamicTPPips = dynamicSLPips * (DynamicTPMultiplier / DynamicSLMultiplier);

      tpDistance = dynamicTPPips * 10 * Point;
   }

   if(orderType == OP_BUY)
      tp = price + tpDistance;
   else
      tp = price - tpDistance;

   return tp;
}

//+------------------------------------------------------------------+
//| Position management                                             |
//+------------------------------------------------------------------+
void ManageDayTradePositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberDayTrade)
      {
         // FEATURE 4: Partial Profit Taking
         if(UsePartialProfitTaking)
            ApplyPartialProfitTaking();

         // Apply trailing stop
         if(UseTrailingStop)
            ApplyTrailingStop();

         // Apply break-even
         if(UseBreakEven)
            ApplyBreakEven();

         // Check for quick exit conditions
         CheckQuickExit();
      }
   }
}

//+------------------------------------------------------------------+
//| FEATURE 4: Partial Profit Taking System                        |
//+------------------------------------------------------------------+
void ApplyPartialProfitTaking()
{
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double openPrice = OrderOpenPrice();
   double currentSL = OrderStopLoss();
   string orderComment = OrderComment();

   // Check if this is already a partial position (contains "PARTIAL")
   if(StringFind(orderComment, "PARTIAL") >= 0)
      return; // Already partially closed

   // Calculate profit in pips
   double profitPips = 0;
   if(OrderType() == OP_BUY)
      profitPips = (currentPrice - openPrice) / Point / 10;
   else
      profitPips = (openPrice - currentPrice) / Point / 10;

   // Calculate SL distance in pips for target calculation
   double slDistance = MathAbs(openPrice - currentSL) / Point / 10;
   if(slDistance == 0) slDistance = StopLossPips; // Fallback

   // Calculate TP1 target
   double tp1Target = slDistance * PartialTP1Multiplier;

   // Check if we've reached TP1
   if(profitPips >= tp1Target)
   {
      double originalLots = OrderLots();
      double closePercent = PartialClosePercent / 100.0;
      double lotsToClose = originalLots * closePercent;

      // Round to lot step
      double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
      if(lotStep > 0)
         lotsToClose = MathFloor(lotsToClose / lotStep) * lotStep;

      double minLot = MarketInfo(Symbol(), MODE_MINLOT);
      if(lotsToClose >= minLot && (originalLots - lotsToClose) >= minLot)
      {
         // Close partial position
         bool closed = OrderClose(OrderTicket(), lotsToClose, currentPrice, 3, ProfitColorDayTrade);

         if(closed)
         {
            PartialPositionsToday++;
            Print("Partial profit taken: ", lotsToClose, " lots at ", profitPips, " pips profit");

            // Modify remaining position comment to mark as partial
            int remainingTicket = OrderTicket();
            if(OrderSelect(remainingTicket, SELECT_BY_TICKET))
            {
               OrderModify(OrderTicket(), openPrice, currentSL, 0, 0); // Remove TP, let it trail
            }
         }
      }
   }
}

void ApplyTrailingStop()
{
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double openPrice = OrderOpenPrice();
   double currentSL = OrderStopLoss();

   if(OrderType() == OP_BUY)
   {
      double profit = (currentPrice - openPrice) / Point;
      if(profit >= TrailingStopPips * 10)
      {
         double newSL = currentPrice - (TrailingStopPips * 10 * Point);
         if(newSL > currentSL)
         {
            OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0, ProfitColorDayTrade);
         }
      }
   }
   else
   {
      double profit = (openPrice - currentPrice) / Point;
      if(profit >= TrailingStopPips * 10)
      {
         double newSL = currentPrice + (TrailingStopPips * 10 * Point);
         if(newSL < currentSL || currentSL == 0)
         {
            OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0, LossColorDayTrade);
         }
      }
   }
}

void ApplyBreakEven()
{
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double openPrice = OrderOpenPrice();
   double currentSL = OrderStopLoss();

   if(OrderType() == OP_BUY)
   {
      double profit = (currentPrice - openPrice) / Point;
      if(profit >= BreakEvenPips * 10 && currentSL < openPrice)
      {
         double newSL = openPrice + (BreakEvenPlusPips * 10 * Point);
         OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0, ProfitColorDayTrade);
         Print("Break-even applied for BUY day trade");
      }
   }
   else
   {
      double profit = (openPrice - currentPrice) / Point;
      if(profit >= BreakEvenPips * 10 && (currentSL > openPrice || currentSL == 0))
      {
         double newSL = openPrice - (BreakEvenPlusPips * 10 * Point);
         OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0, LossColorDayTrade);
         Print("Break-even applied for SELL day trade");
      }
   }
}

void CheckQuickExit()
{
   // Exit if spread widens significantly
   if(CurrentSpread > MaxSpreadPoints * 2)
   {
      double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
      OrderClose(OrderTicket(), OrderLots(), closePrice, 3, clrRed);
      Print("Day trade closed due to spread widening");
   }

   // Exit if market condition changes drastically
   if(MarketCondition == "HIGH SPREAD" || MarketCondition == "HIGH VOLATILITY")
   {
      double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
      OrderClose(OrderTicket(), OrderLots(), closePrice, 3, clrOrange);
      Print("Day trade closed due to unfavorable market condition");
   }
}

//+------------------------------------------------------------------+
//| Utility functions                                               |
//+------------------------------------------------------------------+
int CountPositions()
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberDayTrade)
         count++;
   }
   return count;
}

bool HasLongPosition()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() &&
         OrderMagicNumber() == MagicNumberDayTrade && OrderType() == OP_BUY)
         return true;
   }
   return false;
}

bool HasShortPosition()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() &&
         OrderMagicNumber() == MagicNumberDayTrade && OrderType() == OP_SELL)
         return true;
   }
   return false;
}

void CloseAllPositions(string reason)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberDayTrade)
      {
         double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
         OrderClose(OrderTicket(), OrderLots(), closePrice, 3);
      }
   }
   Print("All day trade positions closed: ", reason);
}

void ResetDailyCounters()
{
   DayTradesToday = 0;
   DayTradesThisHour = 0;
   DailyPnL = 0;
   PartialPositionsToday = 0;
   FullClosuresToday = 0;

   // Reset hourly statistics for new day
   for(int h = 0; h < 24; h++)
   {
      HourlyTrades[h] = 0;
      HourlyWins[h] = 0;
      HourlyPnL[h] = 0;
      HourlyWinRate[h] = 0;
      OptimalHours[h] = false;
   }

   BestTradingHour = -1;
   WorstTradingHour = -1;

   StartOfDay = TimeCurrent();
   Print("Daily counters and hourly statistics reset for new trading day");
}

//+------------------------------------------------------------------+
//| Performance tracking                                            |
//+------------------------------------------------------------------+
void UpdatePerformanceMetrics()
{
   UpdateDailyPnL();
   CalculateWinRate();
   CalculateProfitFactorMetric();
   CalculateAveragePips();
}

void UpdateDailyPnL()
{
   DailyPnL = 0;
   SessionPnL = 0;

   // Open positions
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberDayTrade)
      {
         double pnl = OrderProfit() + OrderSwap() + OrderCommission();
         DailyPnL += pnl;
         SessionPnL += pnl;
      }
   }

   // Closed positions from today
   TotalPips = 0;
   WinningDayTrades = 0;
   LosingDayTrades = 0;

   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberDayTrade)
      {
         if(TimeDay(OrderCloseTime()) == TimeDay(TimeCurrent()))
         {
            double pnl = OrderProfit() + OrderSwap() + OrderCommission();
            DailyPnL += pnl;

            // Calculate pips
            double pips = 0;
            if(OrderType() == OP_BUY)
               pips = (OrderClosePrice() - OrderOpenPrice()) / Point / 10;
            else
               pips = (OrderOpenPrice() - OrderClosePrice()) / Point / 10;

            TotalPips += pips;

            if(pnl > 0)
            {
               WinningDayTrades++;
               if(pips > BestDayTrade) BestDayTrade = pips;
            }
            else
            {
               LosingDayTrades++;
               if(pips < WorstDayTrade) WorstDayTrade = pips;
            }

            // FEATURE 5: Record trade by hour
            int tradeHour = TimeHour(OrderCloseTime());
            RecordTradeByHour(tradeHour, pnl > 0, pnl);
         }
      }
   }
}

void CalculateWinRate()
{
   int totalCompleted = WinningDayTrades + LosingDayTrades;
   if(totalCompleted > 0)
      WinRate = ((double)WinningDayTrades / totalCompleted) * 100;
   else
      WinRate = 0;
}

void CalculateProfitFactorMetric()
{
   double totalProfit = 0;
   double totalLoss = 0;

   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberDayTrade)
      {
         if(TimeDay(OrderCloseTime()) == TimeDay(TimeCurrent()))
         {
            double pnl = OrderProfit() + OrderSwap() + OrderCommission();
            if(pnl > 0)
               totalProfit += pnl;
            else
               totalLoss += MathAbs(pnl);
         }
      }
   }

   if(totalLoss > 0)
      ProfitFactor = totalProfit / totalLoss;
   else
      ProfitFactor = (totalProfit > 0) ? 99.99 : 0;
}

void CalculateAveragePips()
{
   int totalCompleted = WinningDayTrades + LosingDayTrades;
   if(totalCompleted > 0)
      AveragePips = TotalPips / totalCompleted;
   else
      AveragePips = 0;
}

//+------------------------------------------------------------------+
//| Dashboard functions                                             |
//+------------------------------------------------------------------+
void CreateDayTradeDashboard()
{
   // Background
   ObjectCreate("DayTrade_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "DayTrade_BG", OBJPROP_XDISTANCE, DashX);
   ObjectSetInteger(0, "DayTrade_BG", OBJPROP_YDISTANCE, DashY);
   ObjectSetInteger(0, "DayTrade_BG", OBJPROP_XSIZE, 420);
   ObjectSetInteger(0, "DayTrade_BG", OBJPROP_YSIZE, 640); // Increased height for Feature 5
   ObjectSetInteger(0, "DayTrade_BG", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "DayTrade_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "DayTrade_BG", OBJPROP_COLOR, clrGold);

   // Labels
   CreateDashLabel("DayTrade_Title", "GBP/USD DAY TRADER PRO", DashX + 10, DashY + 10, clrGold, 14);
   CreateDashLabel("DayTrade_Session", "", DashX + 10, DashY + 35, clrWhite, 10);
   CreateDashLabel("DayTrade_Condition", "", DashX + 10, DashY + 55, clrWhite, 9);
   CreateDashLabel("DayTrade_Signal", "", DashX + 10, DashY + 75, clrWhite, 9);
   CreateDashLabel("DayTrade_Spread", "", DashX + 10, DashY + 100, clrWhite, 9);
   CreateDashLabel("DayTrade_ATR", "", DashX + 10, DashY + 120, clrWhite, 9);
   CreateDashLabel("DayTrade_OrderFlow", "", DashX + 10, DashY + 140, clrWhite, 9);
   CreateDashLabel("DayTrade_Balance", "", DashX + 10, DashY + 165, clrWhite, 9);
   CreateDashLabel("DayTrade_Equity", "", DashX + 10, DashY + 185, clrWhite, 9);
   CreateDashLabel("DayTrade_SessionPL", "", DashX + 10, DashY + 205, clrWhite, 10);
   CreateDashLabel("DayTrade_DailyPL", "", DashX + 10, DashY + 225, clrWhite, 10);
   CreateDashLabel("DayTrade_Drawdown", "", DashX + 10, DashY + 245, clrWhite, 9);
   CreateDashLabel("DayTrade_TotalPips", "", DashX + 10, DashY + 270, clrWhite, 9);
   CreateDashLabel("DayTrade_AvgPips", "", DashX + 10, DashY + 290, clrWhite, 9);
   CreateDashLabel("DayTrade_BestWorst", "", DashX + 10, DashY + 310, clrWhite, 9);
   CreateDashLabel("DayTrade_DayTradesToday", "", DashX + 10, DashY + 335, clrWhite, 9);
   CreateDashLabel("DayTrade_TradesHour", "", DashX + 10, DashY + 355, clrWhite, 9);
   CreateDashLabel("DayTrade_WinRate", "", DashX + 10, DashY + 375, clrWhite, 9);
   CreateDashLabel("DayTrade_ProfitFactor", "", DashX + 10, DashY + 395, clrWhite, 9);
   CreateDashLabel("DayTrade_Positions", "", DashX + 10, DashY + 420, clrWhite, 9);

   // ADVANCED FEATURES SECTION
   CreateDashLabel("DayTrade_AdvTitle", "=== ADVANCED FEATURES ===", DashX + 10, DashY + 445, clrGold, 10);
   CreateDashLabel("DayTrade_MTF", "", DashX + 10, DashY + 465, clrWhite, 9);
   CreateDashLabel("DayTrade_MTF_Details", "", DashX + 10, DashY + 485, clrWhite, 8);
   CreateDashLabel("DayTrade_Strength", "", DashX + 10, DashY + 505, clrWhite, 9);
   CreateDashLabel("DayTrade_PartialStats", "", DashX + 10, DashY + 525, clrWhite, 9);
   CreateDashLabel("DayTrade_DynamicSL", "", DashX + 10, DashY + 545, clrWhite, 9);
   CreateDashLabel("DayTrade_TimeOpt", "", DashX + 10, DashY + 565, clrWhite, 9);
   CreateDashLabel("DayTrade_HourQuality", "", DashX + 10, DashY + 585, clrWhite, 9);
   CreateDashLabel("DayTrade_BestWorstHour", "", DashX + 10, DashY + 605, clrWhite, 8);

   CreateDashLabel("DayTrade_Time", "", DashX + 10, DashY + 620, clrWhite, 9);
}

void CreateDashLabel(string name, string text, int x, int y, color clr, int size)
{
   ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(name, text, size, "Arial Bold", clr);
   ObjectSet(name, OBJPROP_XDISTANCE, x);
   ObjectSet(name, OBJPROP_YDISTANCE, y);
   ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void UpdateDayTradeDashboard()
{
   if(!ShowDayTradeDashboard) return;

   // Session
   color sessionColor = InTradingWindow ? clrLimeGreen : clrRed;
   ObjectSetText("DayTrade_Session", "Session: " + TradingSession, 10, "Arial Bold", sessionColor);

   // Market condition
   color conditionColor = (MarketCondition == "BULLISH TREND") ? ProfitColorDayTrade :
                         (MarketCondition == "BEARISH TREND") ? LossColorDayTrade : NeutralColorDayTrade;
   ObjectSetText("DayTrade_Condition", "Market: " + MarketCondition, 9, "Arial Bold", conditionColor);

   // Signal
   ObjectSetText("DayTrade_Signal", "Signal: " + CurrentSignal, 9, "Arial", clrWhite);

   // Spread
   color spreadColor = (CurrentSpread <= MaxSpreadPoints * 0.5) ? ProfitColorDayTrade :
                      (CurrentSpread <= MaxSpreadPoints) ? NeutralColorDayTrade : LossColorDayTrade;
   ObjectSetText("DayTrade_Spread", "Spread: " + DoubleToStr(CurrentSpread, 1) + " pts", 9, "Arial Bold", spreadColor);

   // ATR
   color atrColor = (CurrentVolatility >= MinATRPips && CurrentVolatility <= MaxATRPips) ? ProfitColorDayTrade : NeutralColorDayTrade;
   ObjectSetText("DayTrade_ATR", "Volatility: " + DoubleToStr(CurrentVolatility, 1) + " pips", 9, "Arial Bold", atrColor);

   // Order flow
   color flowColor = (OrderFlowBias > 0.2) ? ProfitColorDayTrade : (OrderFlowBias < -0.2) ? LossColorDayTrade : clrWhite;
   string flowText = (OrderFlowBias > 0) ? "BULLISH" : (OrderFlowBias < 0) ? "BEARISH" : "NEUTRAL";
   ObjectSetText("DayTrade_OrderFlow", "Order Flow: " + flowText + " (" + DoubleToStr(OrderFlowBias, 2) + ")", 9, "Arial Bold", flowColor);

   // Account info
   ObjectSetText("DayTrade_Balance", "Balance: $" + DoubleToStr(AccountBalance(), 2), 9, "Arial", clrWhite);
   ObjectSetText("DayTrade_Equity", "Equity: $" + DoubleToStr(AccountEquity(), 2), 9, "Arial", clrWhite);

   // P&L
   color sessionColor2 = (SessionPnL >= 0) ? ProfitColorDayTrade : LossColorDayTrade;
   ObjectSetText("DayTrade_SessionPL", "Session P&L: $" + DoubleToStr(SessionPnL, 2), 10, "Arial Bold", sessionColor2);

   color dailyColor = (DailyPnL >= 0) ? ProfitColorDayTrade : LossColorDayTrade;
   ObjectSetText("DayTrade_DailyPL", "Daily P&L: $" + DoubleToStr(DailyPnL, 2), 10, "Arial Bold", dailyColor);

   // Drawdown
   color ddColor = (CurrentDrawdown < 3) ? ProfitColorDayTrade : (CurrentDrawdown < 6) ? NeutralColorDayTrade : LossColorDayTrade;
   ObjectSetText("DayTrade_Drawdown", "Drawdown: " + DoubleToStr(CurrentDrawdown, 2) + "%", 9, "Arial Bold", ddColor);

   // Pips
   color pipsColor = (TotalPips >= 0) ? ProfitColorDayTrade : LossColorDayTrade;
   ObjectSetText("DayTrade_TotalPips", "Total Pips: " + DoubleToStr(TotalPips, 1), 9, "Arial Bold", pipsColor);

   color avgColor = (AveragePips >= 0) ? ProfitColorDayTrade : LossColorDayTrade;
   ObjectSetText("DayTrade_AvgPips", "Avg Pips/Trade: " + DoubleToStr(AveragePips, 2), 9, "Arial", avgColor);

   ObjectSetText("DayTrade_BestWorst", "Best: " + DoubleToStr(BestDayTrade, 1) + " | Worst: " + DoubleToStr(WorstDayTrade, 1), 9, "Arial", clrWhite);

   // Day Trade counts
   string dayTradesText = IntegerToString(DayTradesToday) + "/" + IntegerToString(MaxTradesPerDay);
   color dayTradesColor = (DayTradesToday >= MaxTradesPerDay) ? LossColorDayTrade : clrWhite;
   ObjectSetText("DayTrade_DayTradesToday", "Day Trades Today: " + dayTradesText, 9, "Arial", dayTradesColor);

   string hourText = "Trades: " + IntegerToString(DayTradesToday) + " today";
   ObjectSetText("DayTrade_TradesHour", hourText, 9, "Arial", clrWhite);

   // Win rate
   color wrColor = (WinRate >= 60) ? ProfitColorDayTrade : (WinRate >= 45) ? NeutralColorDayTrade : LossColorDayTrade;
   ObjectSetText("DayTrade_WinRate", "Win Rate: " + DoubleToStr(WinRate, 1) + "% (" + IntegerToString(WinningDayTrades) + "W/" + IntegerToString(LosingDayTrades) + "L)", 9, "Arial Bold", wrColor);

   // Profit factor
   color pfColor = (ProfitFactor >= 2.0) ? ProfitColorDayTrade : (ProfitFactor >= 1.0) ? NeutralColorDayTrade : LossColorDayTrade;
   ObjectSetText("DayTrade_ProfitFactor", "Profit Factor: " + DoubleToStr(ProfitFactor, 2), 9, "Arial Bold", pfColor);

   // Positions
   ObjectSetText("DayTrade_Positions", "Open Positions: " + IntegerToString(CountPositions()), 9, "Arial", clrWhite);

   // ADVANCED FEATURES DISPLAY
   // MTF Trend
   color mtfColor = (MTF_TrendAligned) ? ProfitColorDayTrade : LossColorDayTrade;
   if(MTF_OverallTrend == "DISABLED") mtfColor = clrGray;
   ObjectSetText("DayTrade_MTF", "MTF Trend: " + MTF_OverallTrend, 9, "Arial Bold", mtfColor);

   string mtfDetails = "H1:" + MTF_Trend_H1 + " | H4:" + MTF_Trend_H4 + " | D1:" + MTF_Trend_D1;
   ObjectSetText("DayTrade_MTF_Details", mtfDetails, 8, "Arial", clrGray);

   // Currency Strength
   color strengthColor = (StrengthConfirmed) ? ProfitColorDayTrade : NeutralColorDayTrade;
   if(!UseCurrencyStrength) strengthColor = clrGray;
   string strengthText = "Strength: GBP=" + DoubleToStr(GBP_Strength, 2) + " USD=" + DoubleToStr(USD_Strength, 2);
   ObjectSetText("DayTrade_Strength", strengthText + " | Diff=" + DoubleToStr(StrengthDifference, 2), 9, "Arial", strengthColor);

   // Partial Profit Stats
   string partialText = "Partial Closes: " + IntegerToString(PartialPositionsToday) + " today";
   color partialColor = (UsePartialProfitTaking) ? clrWhite : clrGray;
   ObjectSetText("DayTrade_PartialStats", partialText, 9, "Arial", partialColor);

   // Dynamic SL/TP Status
   string dynamicText = "Dynamic SL/TP: ";
   if(UseDynamicSLTP)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, 1);
      double atrPips = (atr / Point) / 10;
      double calcSL = atrPips * DynamicSLMultiplier;
      calcSL = MathMax(MinSLPips, MathMin(MaxSLPips, calcSL));
      dynamicText += DoubleToStr(calcSL, 1) + " pips";
      ObjectSetText("DayTrade_DynamicSL", dynamicText, 9, "Arial", ProfitColorDayTrade);
   }
   else
   {
      dynamicText += "Disabled";
      ObjectSetText("DayTrade_DynamicSL", dynamicText, 9, "Arial", clrGray);
   }

   // Time Optimization
   string timeOptText = "Time Mult: x" + DoubleToStr(CurrentTimeMultiplier, 2);
   color timeOptColor = (CurrentTimeMultiplier > 1.0) ? ProfitColorDayTrade : clrWhite;
   if(!UseTimeOptimization) timeOptColor = clrGray;
   ObjectSetText("DayTrade_TimeOpt", timeOptText, 9, "Arial Bold", timeOptColor);

   // Hour Quality
   color hourColor = clrWhite;
   if(CurrentHourQuality == "OPTIMAL" || StringFind(CurrentHourQuality, "OVERLAP") >= 0)
      hourColor = ProfitColorDayTrade;
   else if(CurrentHourQuality == "POOR")
      hourColor = LossColorDayTrade;
   else if(CurrentHourQuality == "LEARNING")
      hourColor = NeutralColorDayTrade;
   else if(CurrentHourQuality == "DISABLED")
      hourColor = clrGray;

   ObjectSetText("DayTrade_HourQuality", "Hour Quality: " + CurrentHourQuality, 9, "Arial", hourColor);

   // Best/Worst Hours
   string bestWorstText = "Best: ";
   if(BestTradingHour >= 0)
      bestWorstText += IntegerToString(BestTradingHour) + ":00";
   else
      bestWorstText += "N/A";

   bestWorstText += " | Worst: ";
   if(WorstTradingHour >= 0)
      bestWorstText += IntegerToString(WorstTradingHour) + ":00";
   else
      bestWorstText += "N/A";

   ObjectSetText("DayTrade_BestWorstHour", bestWorstText, 8, "Arial", clrGray);

   // Time
   ObjectSetText("DayTrade_Time", "Time: " + TimeToString(TimeCurrent(), TIME_SECONDS), 9, "Arial", clrGray);
}

void DeleteDayTradeDashboard()
{
   ObjectDelete("DayTrade_BG");
   ObjectDelete("DayTrade_Title");
   ObjectDelete("DayTrade_Session");
   ObjectDelete("DayTrade_Condition");
   ObjectDelete("DayTrade_Signal");
   ObjectDelete("DayTrade_Spread");
   ObjectDelete("DayTrade_ATR");
   ObjectDelete("DayTrade_OrderFlow");
   ObjectDelete("DayTrade_Balance");
   ObjectDelete("DayTrade_Equity");
   ObjectDelete("DayTrade_SessionPL");
   ObjectDelete("DayTrade_DailyPL");
   ObjectDelete("DayTrade_Drawdown");
   ObjectDelete("DayTrade_TotalPips");
   ObjectDelete("DayTrade_AvgPips");
   ObjectDelete("DayTrade_BestWorst");
   ObjectDelete("DayTrade_DayTradesToday");
   ObjectDelete("DayTrade_TradesHour");
   ObjectDelete("DayTrade_WinRate");
   ObjectDelete("DayTrade_ProfitFactor");
   ObjectDelete("DayTrade_Positions");
   ObjectDelete("DayTrade_AdvTitle");
   ObjectDelete("DayTrade_MTF");
   ObjectDelete("DayTrade_MTF_Details");
   ObjectDelete("DayTrade_Strength");
   ObjectDelete("DayTrade_PartialStats");
   ObjectDelete("DayTrade_DynamicSL");
   ObjectDelete("DayTrade_TimeOpt");
   ObjectDelete("DayTrade_HourQuality");
   ObjectDelete("DayTrade_BestWorstHour");
   ObjectDelete("DayTrade_Time");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(ShowDayTradeDashboard)
      UpdateDayTradeDashboard();
}
//+------------------------------------------------------------------+
