//+------------------------------------------------------------------+
//|                                       Brent_Oil_Trader_Pro.mq4   |
//|                    Professional Brent Crude Oil Trading System    |
//|              Multi-Strategy | ATR Risk Mgmt | Session Aware       |
//+------------------------------------------------------------------+
#property copyright "Professional Oil Trading Systems"
#property version   "3.00"
#property strict
#property description "Advanced Brent Crude Oil EA - EMA Trend + RSI/MACD Momentum"
#property description "ATR-based risk management | Session filter | Trailing stops"

//=== STRATEGY SELECTION ===
input string ___STRATEGY___ = "========== STRATEGY ==========";
input bool EnableTrendFollowing   = true;   // EMA trend-following entries
input bool EnableMomentumEntries  = true;   // RSI/MACD momentum breakouts
input bool EnableBreakoutEntries  = true;   // Bollinger Band squeeze breakouts
input bool EnablePullbackEntries  = true;   // Pullback-to-EMA entries in trend

//=== TIMEFRAME SETTINGS ===
input string ___TF___ = "========== TIMEFRAMES ==========";
input ENUM_TIMEFRAMES TrendTimeframe  = PERIOD_H4;  // Higher TF for trend direction
input ENUM_TIMEFRAMES EntryTimeframe  = PERIOD_H1;  // Entry signal timeframe
input ENUM_TIMEFRAMES FilterTimeframe = PERIOD_M30; // Confirmation/filter timeframe

//=== EMA SETTINGS ===
input string ___EMA___ = "========== MOVING AVERAGES ==========";
input int    FastEMA_Period   = 8;    // Fast EMA
input int    MediumEMA_Period = 21;   // Medium EMA
input int    SlowEMA_Period   = 50;   // Slow EMA (trend baseline)
input int    TrendEMA_Period  = 200;  // Long-term trend EMA
input ENUM_MA_METHOD   MA_Method  = MODE_EMA;
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE;

//=== RSI SETTINGS ===
input string ___RSI___ = "========== RSI SETTINGS ==========";
input int    RSI_Period       = 14;
input double RSI_Overbought   = 70.0;
input double RSI_Oversold     = 30.0;
input double RSI_BullishMin   = 45.0;  // RSI must be above this for longs
input double RSI_BearishMax   = 55.0;  // RSI must be below this for shorts

//=== MACD SETTINGS ===
input string ___MACD___ = "========== MACD SETTINGS ==========";
input int    MACD_FastEMA    = 12;
input int    MACD_SlowEMA    = 26;
input int    MACD_Signal     = 9;

//=== STOCHASTIC SETTINGS ===
input string ___STOCH___ = "========== STOCHASTIC ==========";
input int    Stoch_K          = 5;
input int    Stoch_D          = 3;
input int    Stoch_Slowing    = 3;
input double Stoch_Overbought = 80.0;
input double Stoch_Oversold   = 20.0;

//=== BOLLINGER BANDS ===
input string ___BB___ = "========== BOLLINGER BANDS ==========";
input int    BB_Period        = 20;
input double BB_Deviation     = 2.0;
input double BB_SqueezeATRMult = 0.8; // Squeeze if bandwidth < 0.8x ATR

//=== ATR SETTINGS ===
input string ___ATR___ = "========== ATR / VOLATILITY ==========";
input int    ATR_Period          = 14;
input double ATR_SL_Multiplier   = 1.8;  // Stop loss = 1.8x ATR
input double ATR_TP1_Multiplier  = 1.5;  // TP1 = 1.5x ATR (partial close)
input double ATR_TP2_Multiplier  = 3.0;  // TP2 = 3.0x ATR (full close)
input double ATR_TP3_Multiplier  = 5.0;  // TP3 = 5.0x ATR (runner)
input double ATR_MinMultiplier   = 0.3;  // Skip if ATR < 0.3x average ATR (dead market)
input double ATR_MaxMultiplier   = 3.5;  // Skip if ATR > 3.5x average ATR (flash crash)

//=== RISK MANAGEMENT ===
input string ___RISK___ = "========== RISK MANAGEMENT ==========";
input double RiskPercent         = 1.0;   // % of account to risk per trade
input double MaxLotSize          = 5.0;   // Hard cap on lot size
input double MinLotSize          = 0.01;  // Minimum lot size
input bool   UsePartialClose     = true;  // Close 50% at TP1
input double PartialClosePercent = 50.0;  // Percent to close at TP1
input bool   UseBreakEven        = true;  // Move SL to breakeven after TP1
input bool   UseTrailingStop     = true;  // ATR-based trailing stop
input double TrailingATRMult     = 1.0;   // Trail = 1.0x ATR behind price
input double TrailingActivateATRMult = 1.5; // Activate trailing after 1.5x ATR profit

//=== DAILY PROTECTION ===
input string ___DAILY___ = "========== DAILY LIMITS ==========";
input double MaxDailyLossPercent  = 3.0;  // Stop trading if daily loss > 3%
input double MaxDailyProfitPercent = 5.0; // Stop trading if daily profit > 5%
input int    MaxTradesPerDay      = 6;    // Maximum trades per day
input double MaxDrawdownPercent   = 15.0; // Halt if equity drawdown > 15%

//=== SESSION FILTER ===
input string ___SESSIONS___ = "========== OIL TRADING SESSIONS ==========";
input bool   TradeLondonOpen  = true;  // 07:00-09:00 GMT (high oil volatility)
input bool   TradeLondonCore  = true;  // 09:00-13:00 GMT
input bool   TradeNYOverlap   = true;  // 13:00-17:00 GMT (peak oil volume)
input bool   TradeNYSession   = false; // 17:00-21:00 GMT
input bool   TradeAsian       = false; // 00:00-07:00 GMT (low volume)
input int    SessionGMTOffset = 0;     // Your broker's GMT offset
input bool   SkipFriday1700   = true;  // Avoid Friday after 17:00 GMT
input bool   SkipMonday0000   = true;  // Avoid Monday before 05:00 GMT
input bool   SkipWeekend      = true;  // Always skip Saturday/Sunday

//=== NEWS FILTER ===
input string ___NEWS___ = "========== NEWS / HIGH-IMPACT FILTER ==========";
input bool   UseNewsFilter       = true;  // Avoid known oil news times
input int    NewsBufferMinBefore = 30;   // Minutes before known event
input int    NewsBufferMinAfter  = 30;   // Minutes after known event
// EIA Weekly Petroleum (Wednesday 14:30 GMT) and API (Tuesday ~20:30 GMT)
input bool   FilterEIA           = true;  // Filter EIA Wednesday 14:30 GMT
input bool   FilterOPEC          = true;  // Filter OPEC meetings (manually set via OPECDate)

//=== SPREAD & SLIPPAGE ===
input string ___EXECUTION___ = "========== EXECUTION ==========";
input double MaxSpreadPoints  = 50.0; // Max allowed spread in points (broker-specific)
input int    MaxSlippagePoints = 30;  // Max slippage in points
input bool   RequireBarClose  = true; // Wait for bar close before entry

//=== POSITION & MAGIC ===
input string ___POSITION___ = "========== POSITION ==========";
input int    MagicNumber         = 202400; // Unique EA identifier
input int    MaxOpenPositions    = 1;      // One position at a time
input string TradeComment        = "BrentOilPro";

//=== SYMBOL SETTINGS ===
input string ___SYMBOL___ = "========== SYMBOL SETTINGS ==========";
input string OilSymbol       = "";  // Leave blank to use chart symbol
input double ContractSize    = 0.0; // 0 = auto-detect from MarketInfo

//=== DISPLAY ===
input string ___DISPLAY___ = "========== DASHBOARD ==========";
input bool   ShowDashboard   = true;
input color  DashBullColor   = clrDodgerBlue;
input color  DashBearColor   = clrOrangeRed;
input color  DashNeutralColor = clrGray;
input int    DashX           = 15;
input int    DashY           = 30;
input int    DashFontSize    = 9;

//+------------------------------------------------------------------+
//| Global state variables                                            |
//+------------------------------------------------------------------+
datetime g_LastBarTime       = 0;
datetime g_DayStartTime      = 0;
double   g_DayStartBalance   = 0;
double   g_DayStartEquity    = 0;
int      g_TradesToday       = 0;
double   g_PeakEquity        = 0;
bool     g_DailyLimitHit     = false;
bool     g_DrawdownHaltActive = false;
string   g_WorkSymbol        = "";
double   g_PipValue          = 0;
double   g_TickSize          = 0;
int      g_Digits            = 0;

// Indicator buffers (cached per bar)
double   g_FastEMA_Entry     = 0;
double   g_MedEMA_Entry      = 0;
double   g_SlowEMA_Entry     = 0;
double   g_TrendEMA_Entry    = 0;
double   g_FastEMA_Trend     = 0;
double   g_SlowEMA_Trend     = 0;
double   g_TrendEMA_Trend    = 0;
double   g_ATR               = 0;
double   g_ATR_Avg           = 0;
double   g_RSI               = 0;
double   g_MACD_Main         = 0;
double   g_MACD_Signal       = 0;
double   g_MACD_Hist         = 0;
double   g_MACD_HistPrev     = 0;
double   g_Stoch_Main        = 0;
double   g_Stoch_Signal      = 0;
double   g_BB_Upper          = 0;
double   g_BB_Lower          = 0;
double   g_BB_Middle         = 0;
double   g_BB_Width          = 0;

// State tracking for signals
int      g_EntrySignal       = 0; // 1=buy, -1=sell, 0=none
double   g_SignalSL          = 0;
double   g_SignalTP1         = 0;
double   g_SignalTP2         = 0;
double   g_SignalTP3         = 0;
bool     g_TP1Hit            = false;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   g_WorkSymbol = (OilSymbol == "") ? Symbol() : OilSymbol;
   g_Digits     = (int)MarketInfo(g_WorkSymbol, MODE_DIGITS);
   g_TickSize   = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);

   if(ContractSize > 0)
      g_PipValue = ContractSize * g_TickSize;
   else
      g_PipValue = MarketInfo(g_WorkSymbol, MODE_TICKVALUE);

   g_PeakEquity      = AccountEquity();
   g_DayStartBalance = AccountBalance();
   g_DayStartEquity  = AccountEquity();
   g_DayStartTime    = TimeCurrent();

   Print("Brent Oil Trader Pro v3.00 | Symbol: ", g_WorkSymbol,
         " | Digits: ", g_Digits, " | TickSize: ", g_TickSize);

   if(ShowDashboard) DrawDashboard("Initializing...", DashNeutralColor);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "BOP_");
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Manage existing positions first (always runs regardless of filters)
   ManageOpenPositions();

   // Check if new bar
   if(RequireBarClose)
   {
      datetime currentBarTime = iTime(g_WorkSymbol, EntryTimeframe, 0);
      if(currentBarTime == g_LastBarTime) return;
      g_LastBarTime = currentBarTime;
   }

   // Reset daily stats at day start
   CheckDailyReset();

   // Hard stop: daily limits breached
   if(g_DailyLimitHit || g_DrawdownHaltActive)
   {
      if(ShowDashboard) DrawDashboard("DAILY LIMIT - TRADING HALTED", DashBearColor);
      return;
   }

   // Check drawdown
   if(!CheckDrawdown()) return;

   // Count open positions (this EA's)
   int openPos = CountOpenPositions();
   if(openPos >= MaxOpenPositions) return;

   // Session & time filter
   if(!IsAllowedSession()) return;

   // Spread check
   if(!CheckSpread()) return;

   // News filter
   if(UseNewsFilter && IsNewsTime()) return;

   // Load all indicators
   LoadIndicators();

   // Volatility sanity check
   if(!CheckVolatility()) return;

   // Generate trading signal
   g_EntrySignal = GenerateSignal();

   // Execute trade if signal present
   if(g_EntrySignal != 0)
   {
      ExecuteEntry(g_EntrySignal);
   }

   // Update dashboard
   if(ShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Load all indicator values for current bar                        |
//+------------------------------------------------------------------+
void LoadIndicators()
{
   // Entry timeframe EMAs
   g_FastEMA_Entry  = iMA(g_WorkSymbol, EntryTimeframe, FastEMA_Period,   0, MA_Method, MA_Price, 1);
   g_MedEMA_Entry   = iMA(g_WorkSymbol, EntryTimeframe, MediumEMA_Period, 0, MA_Method, MA_Price, 1);
   g_SlowEMA_Entry  = iMA(g_WorkSymbol, EntryTimeframe, SlowEMA_Period,   0, MA_Method, MA_Price, 1);
   g_TrendEMA_Entry = iMA(g_WorkSymbol, EntryTimeframe, TrendEMA_Period,  0, MA_Method, MA_Price, 1);

   // Trend timeframe EMAs
   g_FastEMA_Trend  = iMA(g_WorkSymbol, TrendTimeframe, FastEMA_Period,   0, MA_Method, MA_Price, 1);
   g_SlowEMA_Trend  = iMA(g_WorkSymbol, TrendTimeframe, SlowEMA_Period,   0, MA_Method, MA_Price, 1);
   g_TrendEMA_Trend = iMA(g_WorkSymbol, TrendTimeframe, TrendEMA_Period,  0, MA_Method, MA_Price, 1);

   // ATR (entry TF) - current and average
   g_ATR     = iATR(g_WorkSymbol, EntryTimeframe, ATR_Period, 1);
   double atrSum = 0;
   for(int i = 1; i <= 50; i++) atrSum += iATR(g_WorkSymbol, EntryTimeframe, ATR_Period, i);
   g_ATR_Avg = atrSum / 50.0;

   // RSI
   g_RSI = iRSI(g_WorkSymbol, EntryTimeframe, RSI_Period, MA_Price, 1);

   // MACD
   g_MACD_Main    = iMACD(g_WorkSymbol, EntryTimeframe, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, MA_Price, MODE_MAIN,   1);
   g_MACD_Signal  = iMACD(g_WorkSymbol, EntryTimeframe, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, MA_Price, MODE_SIGNAL, 1);
   g_MACD_Hist    = g_MACD_Main - g_MACD_Signal;
   g_MACD_HistPrev = iMACD(g_WorkSymbol, EntryTimeframe, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, MA_Price, MODE_MAIN, 2)
                   - iMACD(g_WorkSymbol, EntryTimeframe, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, MA_Price, MODE_SIGNAL, 2);

   // Stochastic
   g_Stoch_Main   = iStochastic(g_WorkSymbol, EntryTimeframe, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN,   1);
   g_Stoch_Signal = iStochastic(g_WorkSymbol, EntryTimeframe, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, 1);

   // Bollinger Bands
   g_BB_Upper  = iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_UPPER,  1);
   g_BB_Lower  = iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_LOWER,  1);
   g_BB_Middle = iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_MAIN,   1);
   g_BB_Width  = g_BB_Upper - g_BB_Lower;
}

//+------------------------------------------------------------------+
//| Generate consolidated entry signal                               |
//+------------------------------------------------------------------+
int GenerateSignal()
{
   double closeEntry = iClose(g_WorkSymbol, EntryTimeframe, 1);
   double prevClose  = iClose(g_WorkSymbol, EntryTimeframe, 2);

   // === HIGHER TIMEFRAME TREND BIAS ===
   int trendBias = 0;
   double closeTrend = iClose(g_WorkSymbol, TrendTimeframe, 1);

   if(closeTrend > g_TrendEMA_Trend && g_FastEMA_Trend > g_SlowEMA_Trend)
      trendBias =  1;  // Bullish trend
   else if(closeTrend < g_TrendEMA_Trend && g_FastEMA_Trend < g_SlowEMA_Trend)
      trendBias = -1;  // Bearish trend

   // No clear trend — only allow breakout and pullback strategies
   bool strongTrend = (trendBias != 0);

   int signal    = 0;
   double sl_atr = g_ATR * ATR_SL_Multiplier;

   // -----------------------------------------------------------------------
   // STRATEGY 1: EMA TREND FOLLOWING
   // Entry when fast EMA crosses medium EMA in direction of HTF trend
   // -----------------------------------------------------------------------
   if(EnableTrendFollowing && strongTrend)
   {
      double fastPrev = iMA(g_WorkSymbol, EntryTimeframe, FastEMA_Period,   0, MA_Method, MA_Price, 2);
      double medPrev  = iMA(g_WorkSymbol, EntryTimeframe, MediumEMA_Period, 0, MA_Method, MA_Price, 2);

      bool fastCrossedAboveMed = (fastPrev <= medPrev) && (g_FastEMA_Entry > g_MedEMA_Entry);
      bool fastCrossedBelowMed = (fastPrev >= medPrev) && (g_FastEMA_Entry < g_MedEMA_Entry);

      // Price must be on correct side of slow EMA for trend confirmation
      bool aboveSlowEMA = (closeEntry > g_SlowEMA_Entry);
      bool belowSlowEMA = (closeEntry < g_SlowEMA_Entry);

      if(fastCrossedAboveMed && trendBias == 1 && aboveSlowEMA &&
         g_RSI > RSI_BullishMin && g_RSI < RSI_Overbought)
      {
         signal =  1;
      }
      else if(fastCrossedBelowMed && trendBias == -1 && belowSlowEMA &&
              g_RSI < RSI_BearishMax && g_RSI > RSI_Oversold)
      {
         signal = -1;
      }
   }

   // -----------------------------------------------------------------------
   // STRATEGY 2: MOMENTUM BREAKOUT (MACD histogram flip + RSI momentum)
   // -----------------------------------------------------------------------
   if(signal == 0 && EnableMomentumEntries)
   {
      bool macdFlippedBull = (g_MACD_HistPrev < 0) && (g_MACD_Hist > 0);
      bool macdFlippedBear = (g_MACD_HistPrev > 0) && (g_MACD_Hist < 0);
      bool macdAboveZero   = (g_MACD_Main > 0 && g_MACD_Signal > 0);
      bool macdBelowZero   = (g_MACD_Main < 0 && g_MACD_Signal < 0);

      bool rsiMomentumBull = (g_RSI > 50.0 && g_RSI < RSI_Overbought);
      bool rsiMomentumBear = (g_RSI < 50.0 && g_RSI > RSI_Oversold);

      if(macdFlippedBull && rsiMomentumBull && (!strongTrend || trendBias == 1))
         signal =  1;
      else if(macdFlippedBear && rsiMomentumBear && (!strongTrend || trendBias == -1))
         signal = -1;
   }

   // -----------------------------------------------------------------------
   // STRATEGY 3: BOLLINGER BAND BREAKOUT (squeeze then expansion)
   // -----------------------------------------------------------------------
   if(signal == 0 && EnableBreakoutEntries)
   {
      bool bbSqueeze  = (g_BB_Width < g_ATR * BB_SqueezeATRMult * 2.0);
      bool bullBreak  = (!bbSqueeze) && (closeEntry > g_BB_Upper) &&
                        (prevClose <= iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_UPPER, 2));
      bool bearBreak  = (!bbSqueeze) && (closeEntry < g_BB_Lower) &&
                        (prevClose >= iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_LOWER, 2));

      // Only trade BB breakout in direction of H4 trend or if no trend is defined
      if(bullBreak && g_MACD_Hist > 0 && (!strongTrend || trendBias == 1))
         signal =  1;
      else if(bearBreak && g_MACD_Hist < 0 && (!strongTrend || trendBias == -1))
         signal = -1;
   }

   // -----------------------------------------------------------------------
   // STRATEGY 4: PULLBACK TO EMA IN TREND (best reward-to-risk)
   // Price pulls back to medium EMA in a strong trend
   // -----------------------------------------------------------------------
   if(signal == 0 && EnablePullbackEntries && strongTrend)
   {
      double priceToMedEMA = MathAbs(closeEntry - g_MedEMA_Entry);
      bool nearMedEMA      = (priceToMedEMA < g_ATR * 0.4); // Within 0.4 ATR of medium EMA

      double prevLow  = iLow (g_WorkSymbol, EntryTimeframe, 1);
      double prevHigh = iHigh(g_WorkSymbol, EntryTimeframe, 1);

      // Bullish pullback: uptrend, price dipped to medium EMA, stochastic oversold
      if(trendBias == 1 && nearMedEMA && closeEntry > g_SlowEMA_Entry &&
         g_Stoch_Main < 40.0 && g_Stoch_Main > g_Stoch_Signal &&
         g_RSI > 40.0 && g_RSI < 65.0)
      {
         signal =  1;
      }
      // Bearish pullback: downtrend, price rallied to medium EMA, stochastic overbought
      else if(trendBias == -1 && nearMedEMA && closeEntry < g_SlowEMA_Entry &&
              g_Stoch_Main > 60.0 && g_Stoch_Main < g_Stoch_Signal &&
              g_RSI < 60.0 && g_RSI > 35.0)
      {
         signal = -1;
      }
   }

   // -----------------------------------------------------------------------
   // FINAL FILTER: Stochastic extreme filter (avoid entering overbought/oversold)
   // -----------------------------------------------------------------------
   if(signal == 1  && g_Stoch_Main > Stoch_Overbought) signal = 0;
   if(signal == -1 && g_Stoch_Main < Stoch_Oversold)   signal = 0;

   return signal;
}

//+------------------------------------------------------------------+
//| Execute entry order with dynamic position sizing                 |
//+------------------------------------------------------------------+
void ExecuteEntry(int direction)
{
   double ask  = MarketInfo(g_WorkSymbol, MODE_ASK);
   double bid  = MarketInfo(g_WorkSymbol, MODE_BID);
   double atr  = g_ATR;

   double entryPrice, slPrice, tp1Price, tp2Price, tp3Price;

   if(direction == 1) // BUY
   {
      entryPrice = ask;
      slPrice    = NormalizeDouble(ask - atr * ATR_SL_Multiplier, g_Digits);
      tp1Price   = NormalizeDouble(ask + atr * ATR_TP1_Multiplier, g_Digits);
      tp2Price   = NormalizeDouble(ask + atr * ATR_TP2_Multiplier, g_Digits);
      tp3Price   = NormalizeDouble(ask + atr * ATR_TP3_Multiplier, g_Digits);
   }
   else // SELL
   {
      entryPrice = bid;
      slPrice    = NormalizeDouble(bid + atr * ATR_SL_Multiplier, g_Digits);
      tp1Price   = NormalizeDouble(bid - atr * ATR_TP1_Multiplier, g_Digits);
      tp2Price   = NormalizeDouble(bid - atr * ATR_TP2_Multiplier, g_Digits);
      tp3Price   = NormalizeDouble(bid - atr * ATR_TP3_Multiplier, g_Digits);
   }

   // Validate SL distance
   double minSL = MarketInfo(g_WorkSymbol, MODE_STOPLEVEL) * g_TickSize;
   if(MathAbs(entryPrice - slPrice) < minSL)
   {
      Print("SL too close to entry - adjusting to broker minimum");
      slPrice = (direction == 1) ? entryPrice - minSL : entryPrice + minSL;
   }

   // Calculate position size based on risk %
   double lots = CalculateLotSize(entryPrice, slPrice);
   if(lots <= 0) return;

   // Store TP levels in comment for position manager
   string comment = TradeComment + "|TP1=" + DoubleToStr(tp1Price, g_Digits)
                  + "|TP2=" + DoubleToStr(tp2Price, g_Digits)
                  + "|TP3=" + DoubleToStr(tp3Price, g_Digits);

   int cmd = (direction == 1) ? OP_BUY : OP_SELL;

   int ticket = OrderSend(
      g_WorkSymbol, cmd, lots,
      (direction == 1) ? ask : bid,
      MaxSlippagePoints, slPrice, tp2Price,
      comment, MagicNumber, 0,
      (direction == 1) ? DashBullColor : DashBearColor
   );

   if(ticket > 0)
   {
      g_TradesToday++;
      Print("Order opened: Ticket=", ticket, " Dir=", (direction == 1 ? "BUY" : "SELL"),
            " Lots=", lots, " Entry=", entryPrice, " SL=", slPrice,
            " TP2=", tp2Price, " ATR=", atr);
   }
   else
   {
      int err = GetLastError();
      Print("OrderSend failed: Error=", err, " | ", ErrorDescription(err));
   }
}

//+------------------------------------------------------------------+
//| Calculate position size based on account risk %                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double entryPrice, double slPrice)
{
   double accountBalance = AccountBalance();
   double riskAmount     = accountBalance * RiskPercent / 100.0;
   double slDistance     = MathAbs(entryPrice - slPrice);

   if(slDistance <= 0)
   {
      Print("Invalid SL distance in lot calculation");
      return MinLotSize;
   }

   double tickValue   = MarketInfo(g_WorkSymbol, MODE_TICKVALUE);
   double tickSize    = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);
   double lotStep     = MarketInfo(g_WorkSymbol, MODE_LOTSTEP);
   double minLot      = MarketInfo(g_WorkSymbol, MODE_MINLOT);
   double maxLot      = MarketInfo(g_WorkSymbol, MODE_MAXLOT);

   if(tickValue <= 0 || tickSize <= 0)
   {
      Print("Invalid tick data, using minimum lot");
      return minLot;
   }

   double slValuePerLot = (slDistance / tickSize) * tickValue;
   double rawLots       = riskAmount / slValuePerLot;

   // Normalize to lot step
   double lots = MathFloor(rawLots / lotStep) * lotStep;

   // Apply hard limits
   lots = MathMax(lots, MathMax(minLot, MinLotSize));
   lots = MathMin(lots, MathMin(maxLot, MaxLotSize));

   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Manage all open positions (trailing stop, break-even, partial)   |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != g_WorkSymbol) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      double currentSL   = OrderStopLoss();
      double currentTP   = OrderTakeProfit();
      double openPrice   = OrderOpenPrice();
      double ask         = MarketInfo(g_WorkSymbol, MODE_ASK);
      double bid         = MarketInfo(g_WorkSymbol, MODE_BID);
      double currentPrice = (OrderType() == OP_BUY) ? bid : ask;
      double atr         = iATR(g_WorkSymbol, EntryTimeframe, ATR_Period, 1);
      double tickSize    = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);
      double minStopDist = MarketInfo(g_WorkSymbol, MODE_STOPLEVEL) * tickSize;

      double profit_pts  = (OrderType() == OP_BUY) ?
                           (currentPrice - openPrice) :
                           (openPrice - currentPrice);

      // Parse TP1 from comment
      double tp1 = 0;
      string cmnt = OrderComment();
      int tp1Pos  = StringFind(cmnt, "TP1=");
      if(tp1Pos >= 0)
      {
         string tp1Str = StringSubstr(cmnt, tp1Pos + 4);
         int pipePos   = StringFind(tp1Str, "|");
         if(pipePos > 0) tp1Str = StringSubstr(tp1Str, 0, pipePos);
         tp1 = StrToDouble(tp1Str);
      }

      bool tp1Reached = false;
      if(tp1 > 0)
      {
         tp1Reached = (OrderType() == OP_BUY)  ? (currentPrice >= tp1) :
                      (OrderType() == OP_SELL) ? (currentPrice <= tp1) : false;
      }

      // --- PARTIAL CLOSE AT TP1 ---
      if(UsePartialClose && tp1Reached && OrderLots() > MinLotSize)
      {
         // Check if already partially closed (track via comment)
         if(StringFind(cmnt, "PC1") < 0)
         {
            double partialLots = NormalizeDouble(OrderLots() * PartialClosePercent / 100.0, 2);
            double lotStep = MarketInfo(g_WorkSymbol, MODE_LOTSTEP);
            partialLots = MathFloor(partialLots / lotStep) * lotStep;
            double minLot = MarketInfo(g_WorkSymbol, MODE_MINLOT);
            if(partialLots >= minLot && partialLots < OrderLots())
            {
               bool closed = OrderClose(OrderTicket(), partialLots,
                                        currentPrice, MaxSlippagePoints,
                                        clrYellow);
               if(closed)
                  Print("Partial close TP1: Ticket=", OrderTicket(), " Lots=", partialLots);
            }
         }
      }

      // --- BREAK-EVEN ---
      if(UseBreakEven && tp1Reached)
      {
         double bePlus = atr * 0.1; // Small buffer above break-even
         double newSL_BE;
         bool modifyBE = false;

         if(OrderType() == OP_BUY)
         {
            newSL_BE = NormalizeDouble(openPrice + bePlus, g_Digits);
            if(newSL_BE > currentSL + tickSize && newSL_BE < currentPrice - minStopDist)
               modifyBE = true;
         }
         else
         {
            newSL_BE = NormalizeDouble(openPrice - bePlus, g_Digits);
            if(newSL_BE < currentSL - tickSize && newSL_BE > currentPrice + minStopDist)
               modifyBE = true;
         }

         if(modifyBE)
         {
            if(OrderModify(OrderTicket(), openPrice, newSL_BE, currentTP, 0, clrGold))
               Print("Break-even set: Ticket=", OrderTicket(), " SL=", newSL_BE);
         }
      }

      // --- TRAILING STOP ---
      if(UseTrailingStop && profit_pts >= atr * TrailingActivateATRMult)
      {
         double trailDist = atr * TrailingATRMult;
         double newSL_Trail;
         bool modifyTrail = false;

         if(OrderType() == OP_BUY)
         {
            newSL_Trail = NormalizeDouble(currentPrice - trailDist, g_Digits);
            if(newSL_Trail > currentSL + tickSize && newSL_Trail < currentPrice - minStopDist)
               modifyTrail = true;
         }
         else
         {
            newSL_Trail = NormalizeDouble(currentPrice + trailDist, g_Digits);
            if(newSL_Trail < currentSL - tickSize && newSL_Trail > currentPrice + minStopDist)
               modifyTrail = true;
         }

         if(modifyTrail)
         {
            if(OrderModify(OrderTicket(), openPrice, newSL_Trail, currentTP, 0, clrCyan))
               Print("Trailing stop updated: Ticket=", OrderTicket(), " SL=", newSL_Trail);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Session filter — oil-specific trading hours                      |
//+------------------------------------------------------------------+
bool IsAllowedSession()
{
   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);

   int dow  = dt.day_of_week; // 0=Sun, 6=Sat
   int hour = dt.hour;
   int min  = dt.min;
   int gmtHour = (hour - SessionGMTOffset + 24) % 24;

   // Skip weekends
   if(SkipWeekend && (dow == 0 || dow == 6)) return false;

   // Skip Monday early hours (market gaps common in oil)
   if(SkipMonday0000 && dow == 1 && gmtHour < 5) return false;

   // Skip Friday evening (thin liquidity, gap risk)
   if(SkipFriday1700 && dow == 5 && gmtHour >= 17) return false;

   // Check allowed sessions
   bool inSession = false;

   // London Open: 07:00-09:00 GMT (best for oil price discovery)
   if(TradeLondonOpen && gmtHour >= 7 && gmtHour < 9)  inSession = true;
   // London Core: 09:00-13:00 GMT
   if(TradeLondonCore && gmtHour >= 9 && gmtHour < 13) inSession = true;
   // NY Overlap: 13:00-17:00 GMT (peak oil volume)
   if(TradeNYOverlap  && gmtHour >= 13 && gmtHour < 17) inSession = true;
   // NY Session: 17:00-21:00 GMT
   if(TradeNYSession  && gmtHour >= 17 && gmtHour < 21) inSession = true;
   // Asian Session: 00:00-07:00 GMT
   if(TradeAsian      && gmtHour >= 0 && gmtHour < 7)  inSession = true;

   return inSession;
}

//+------------------------------------------------------------------+
//| News time filter — EIA, API inventory reports                    |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);

   int dow     = dt.day_of_week;
   int hour    = dt.hour;
   int minute  = dt.min;
   int gmtH    = (hour - SessionGMTOffset + 24) % 24;
   int totalMin = gmtH * 60 + minute;

   // EIA Weekly Petroleum Status: Wednesday 14:30 GMT
   if(FilterEIA && dow == 3)
   {
      int eiaTime = 14 * 60 + 30;
      if(totalMin >= eiaTime - NewsBufferMinBefore &&
         totalMin <= eiaTime + NewsBufferMinAfter)
         return true;
   }

   // API Crude Inventory: Tuesday ~20:30 GMT
   if(dow == 2)
   {
      int apiTime = 20 * 60 + 30;
      if(totalMin >= apiTime - NewsBufferMinBefore &&
         totalMin <= apiTime + NewsBufferMinAfter)
         return true;
   }

   // US CPI / NFP / FOMC: Friday/first-Friday 13:30 GMT, generic high-impact hour
   // Fridays 13:30-14:30 GMT (NFP first Friday of month)
   if(dow == 5)
   {
      int nfpTime = 13 * 60 + 30;
      if(totalMin >= nfpTime && totalMin <= nfpTime + 60)
         return true; // Broad Friday US data filter
   }

   return false;
}

//+------------------------------------------------------------------+
//| Spread check                                                      |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   double spread = MarketInfo(g_WorkSymbol, MODE_SPREAD);
   if(spread > MaxSpreadPoints)
   {
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Volatility check                                                  |
//+------------------------------------------------------------------+
bool CheckVolatility()
{
   if(g_ATR <= 0 || g_ATR_Avg <= 0) return false;

   // Dead market — skip (ATR too low relative to average)
   if(g_ATR < g_ATR_Avg * ATR_MinMultiplier) return false;

   // Extreme volatility — skip (ATR too high, risk of spike)
   if(g_ATR > g_ATR_Avg * ATR_MaxMultiplier) return false;

   return true;
}

//+------------------------------------------------------------------+
//| Drawdown check                                                    |
//+------------------------------------------------------------------+
bool CheckDrawdown()
{
   double equity   = AccountEquity();
   double balance  = AccountBalance();

   if(equity > g_PeakEquity) g_PeakEquity = equity;

   double ddPct = (g_PeakEquity > 0) ? (g_PeakEquity - equity) / g_PeakEquity * 100.0 : 0;

   if(ddPct >= MaxDrawdownPercent)
   {
      if(!g_DrawdownHaltActive)
      {
         Print("MAX DRAWDOWN HIT: ", DoubleToStr(ddPct, 2), "% - Halting trading");
         g_DrawdownHaltActive = true;
      }
      if(ShowDashboard) DrawDashboard("DRAWDOWN HALT: " + DoubleToStr(ddPct, 1) + "%", DashBearColor);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check and reset daily statistics                                 |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   datetime serverTime = TimeCurrent();
   MqlDateTime dtNow, dtStart;
   TimeToStruct(serverTime, dtNow);
   TimeToStruct(g_DayStartTime, dtStart);

   if(dtNow.day != dtStart.day || dtNow.mon != dtStart.mon)
   {
      g_DayStartTime    = serverTime;
      g_DayStartBalance = AccountBalance();
      g_DayStartEquity  = AccountEquity();
      g_TradesToday     = 0;
      g_DailyLimitHit   = false;
      Print("Daily reset: Balance=", g_DayStartBalance, " Equity=", g_DayStartEquity);
   }

   // Check daily trade count
   if(g_TradesToday >= MaxTradesPerDay && !g_DailyLimitHit)
   {
      g_DailyLimitHit = true;
      Print("Daily trade limit reached: ", MaxTradesPerDay);
   }

   // Check daily P&L limits
   if(g_DayStartBalance > 0)
   {
      double equity    = AccountEquity();
      double pnlPct    = (equity - g_DayStartEquity) / g_DayStartBalance * 100.0;

      if(pnlPct <= -MaxDailyLossPercent && !g_DailyLimitHit)
      {
         g_DailyLimitHit = true;
         Print("Daily LOSS limit hit: ", DoubleToStr(pnlPct, 2), "%");
      }
      if(pnlPct >= MaxDailyProfitPercent && !g_DailyLimitHit)
      {
         g_DailyLimitHit = true;
         Print("Daily PROFIT target hit: ", DoubleToStr(pnlPct, 2), "%");
      }
   }
}

//+------------------------------------------------------------------+
//| Count open positions for this EA                                 |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() == MagicNumber && OrderSymbol() == g_WorkSymbol)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Dashboard drawing                                                 |
//+------------------------------------------------------------------+
void DrawDashboard(string statusMsg, color statusColor)
{
   // Simple comment-based dashboard
   string trend     = "";
   string signal    = "NONE";
   color  sigColor  = DashNeutralColor;

   if(g_TrendEMA_Trend > 0)
   {
      double closeTrend = iClose(g_WorkSymbol, TrendTimeframe, 1);
      if(closeTrend > g_TrendEMA_Trend) trend = "BULL";
      else if(closeTrend < g_TrendEMA_Trend) trend = "BEAR";
      else trend = "FLAT";
   }

   if(g_EntrySignal == 1)  { signal = "BUY";  sigColor = DashBullColor; }
   if(g_EntrySignal == -1) { signal = "SELL"; sigColor = DashBearColor; }

   double equity   = AccountEquity();
   double balance  = AccountBalance();
   double pnlDay   = equity - g_DayStartEquity;
   double ddPct    = (g_PeakEquity > 0) ? (g_PeakEquity - equity) / g_PeakEquity * 100.0 : 0;

   string dash = "\n";
   dash += "=== BRENT OIL TRADER PRO v3.00 ===\n";
   dash += "Symbol    : " + g_WorkSymbol + "\n";
   dash += "Status    : " + statusMsg + "\n";
   dash += "H4 Trend  : " + trend + " | Signal: " + signal + "\n";
   dash += "ATR       : " + DoubleToStr(g_ATR, g_Digits) + " (Avg: " + DoubleToStr(g_ATR_Avg, g_Digits) + ")\n";
   dash += "RSI       : " + DoubleToStr(g_RSI, 1) + " | MACD Hist: " + DoubleToStr(g_MACD_Hist, 5) + "\n";
   dash += "Balance   : " + DoubleToStr(balance, 2) + " | Equity: " + DoubleToStr(equity, 2) + "\n";
   dash += "Day P&L   : " + DoubleToStr(pnlDay, 2) + " | Drawdown: " + DoubleToStr(ddPct, 2) + "%\n";
   dash += "Trades    : " + IntegerToString(g_TradesToday) + "/" + IntegerToString(MaxTradesPerDay) + "\n";
   dash += "Open Pos  : " + IntegerToString(CountOpenPositions()) + "/" + IntegerToString(MaxOpenPositions) + "\n";
   dash += "Spread    : " + DoubleToStr(MarketInfo(g_WorkSymbol, MODE_SPREAD), 1) + " pts\n";
   dash += "Session   : " + (IsAllowedSession() ? "ACTIVE" : "CLOSED") + "\n";

   Comment(dash);
}

void UpdateDashboard()
{
   DrawDashboard("RUNNING", DashBullColor);
}

//+------------------------------------------------------------------+
//| Format error description                                         |
//+------------------------------------------------------------------+
string ErrorDescription(int errCode)
{
   switch(errCode)
   {
      case 1:   return "No error";
      case 2:   return "Common error";
      case 3:   return "Invalid trade parameters";
      case 4:   return "Trade server busy";
      case 5:   return "Old version";
      case 6:   return "No connection";
      case 7:   return "Not enough rights";
      case 8:   return "Too frequent requests";
      case 9:   return "Malfunctional trade operation";
      case 64:  return "Account disabled";
      case 65:  return "Invalid account";
      case 128: return "Trade timeout";
      case 129: return "Invalid price";
      case 130: return "Invalid stops";
      case 131: return "Invalid trade volume";
      case 132: return "Market is closed";
      case 133: return "Trade is disabled";
      case 134: return "Not enough money";
      case 135: return "Price changed";
      case 136: return "Off quotes";
      case 137: return "Broker is busy";
      case 138: return "Requote";
      case 139: return "Order is locked";
      case 140: return "Long positions only allowed";
      case 141: return "Too many requests";
      case 145: return "Modification denied (too close to market)";
      case 146: return "Trade context busy";
      case 147: return "Expirations are denied";
      case 148: return "Amount of open/pending orders reached limit";
      case 149: return "Hedging is prohibited";
      case 150: return "Prohibited by FIFO rules";
      default:  return "Unknown error: " + IntegerToString(errCode);
   }
}
//+------------------------------------------------------------------+
