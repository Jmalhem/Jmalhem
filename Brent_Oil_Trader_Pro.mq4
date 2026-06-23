//+------------------------------------------------------------------+
//|                                       Brent_Oil_Trader_Pro.mq4   |
//|                   Universal Crude Oil & Energy Trading System     |
//|        Brent | WTI | Natural Gas  —  Any Broker Symbol           |
//+------------------------------------------------------------------+
#property copyright "Professional Oil Trading Systems"
#property version   "4.00"
#property strict
#property description "Universal Oil EA: auto-detects Brent, WTI, Natural Gas"
#property description "Works with any broker symbol naming convention"
#property description "EMA Trend | MACD Momentum | BB Breakout | Pullback"

//=== STRATEGY SELECTION ===
input string ___STRATEGY___        = "========== STRATEGY ==========";
input bool   EnableTrendFollowing  = true;  // EMA crossover in HTF trend direction
input bool   EnableMomentumEntries = true;  // MACD histogram flip + RSI momentum
input bool   EnableBreakoutEntries = true;  // Bollinger Band squeeze breakout
input bool   EnablePullbackEntries = true;  // Pullback to medium EMA in trend

//=== TIMEFRAME SETTINGS ===
input string          ___TF___          = "========== TIMEFRAMES ==========";
input ENUM_TIMEFRAMES TrendTimeframe    = PERIOD_H4;  // Higher TF for trend direction
input ENUM_TIMEFRAMES EntryTimeframe    = PERIOD_H1;  // Entry signal timeframe
input ENUM_TIMEFRAMES FilterTimeframe   = PERIOD_M30; // Confirmation filter TF

//=== EMA SETTINGS ===
input string           ___EMA___         = "========== MOVING AVERAGES ==========";
input int              FastEMA_Period    = 8;
input int              MediumEMA_Period  = 21;
input int              SlowEMA_Period    = 50;
input int              TrendEMA_Period   = 200;
input ENUM_MA_METHOD   MA_Method         = MODE_EMA;
input ENUM_APPLIED_PRICE MA_Price        = PRICE_CLOSE;

//=== RSI SETTINGS ===
input string ___RSI___          = "========== RSI ==========";
input int    RSI_Period         = 14;
input double RSI_Overbought     = 70.0;
input double RSI_Oversold       = 30.0;
input double RSI_BullishMin     = 45.0;
input double RSI_BearishMax     = 55.0;

//=== MACD SETTINGS ===
input string ___MACD___         = "========== MACD ==========";
input int    MACD_FastEMA       = 12;
input int    MACD_SlowEMA       = 26;
input int    MACD_Signal        = 9;

//=== STOCHASTIC SETTINGS ===
input string ___STOCH___        = "========== STOCHASTIC ==========";
input int    Stoch_K            = 5;
input int    Stoch_D            = 3;
input int    Stoch_Slowing      = 3;
input double Stoch_Overbought   = 80.0;
input double Stoch_Oversold     = 20.0;

//=== BOLLINGER BANDS ===
input string ___BB___           = "========== BOLLINGER BANDS ==========";
input int    BB_Period          = 20;
input double BB_Deviation       = 2.0;
input double BB_SqueezeATRMult  = 0.8;

//=== ATR / VOLATILITY ===
input string ___ATR___              = "========== ATR / VOLATILITY ==========";
input int    ATR_Period             = 14;
input double ATR_SL_Multiplier      = 1.8;
input double ATR_TP1_Multiplier     = 1.5;
input double ATR_TP2_Multiplier     = 3.0;
input double ATR_TP3_Multiplier     = 5.0;
input double ATR_MinMultiplier      = 0.3;  // Skip if ATR < 0.3x 50-bar average
input double ATR_MaxMultiplier      = 3.5;  // Skip if ATR > 3.5x 50-bar average

//=== RISK MANAGEMENT ===
input string ___RISK___             = "========== RISK MANAGEMENT ==========";
input double RiskPercent            = 1.0;
input double MaxLotSize             = 5.0;
input double MinLotSize             = 0.01;
input bool   UsePartialClose        = true;
input double PartialClosePercent    = 50.0;
input bool   UseBreakEven           = true;
input bool   UseTrailingStop        = true;
input double TrailingATRMult        = 1.0;
input double TrailingActivateATRMult = 1.5;

//=== DAILY LIMITS ===
input string ___DAILY___            = "========== DAILY LIMITS ==========";
input double MaxDailyLossPercent    = 3.0;
input double MaxDailyProfitPercent  = 5.0;
input int    MaxTradesPerDay        = 6;
input double MaxDrawdownPercent     = 15.0;

//=== SESSION FILTER ===
input string ___SESSIONS___         = "========== OIL TRADING SESSIONS ==========";
input bool   TradeLondonOpen        = true;   // 07:00-09:00 GMT
input bool   TradeLondonCore        = true;   // 09:00-13:00 GMT
input bool   TradeNYOverlap         = true;   // 13:00-17:00 GMT (peak oil volume)
input bool   TradeNYSession         = false;  // 17:00-21:00 GMT
input bool   TradeAsian             = false;  // 00:00-07:00 GMT (low volume)
input int    SessionGMTOffset       = 0;      // Broker server GMT offset
input bool   SkipFriday1700         = true;
input bool   SkipMonday0000         = true;
input bool   SkipWeekend            = true;

//=== NEWS FILTER ===
input string ___NEWS___             = "========== NEWS FILTER ==========";
input bool   UseNewsFilter          = true;
input int    NewsBufferMinBefore    = 30;
input int    NewsBufferMinAfter     = 30;
input bool   FilterEIA              = true;   // EIA Wed 14:30 GMT
input bool   FilterAPI              = true;   // API Tue 20:30 GMT
input bool   FilterNFP              = true;   // NFP Fri 13:30 GMT
input bool   FilterFOMC             = true;   // FOMC Wed 19:00 GMT (every 6 weeks)

//=== EXECUTION ===
input string ___EXECUTION___        = "========== EXECUTION ==========";
input double MaxSpreadPoints        = 50.0;  // In broker points (auto-scaled per oil type)
input int    MaxSlippagePoints      = 30;
input bool   RequireBarClose        = true;

//=== POSITION ===
input string ___POSITION___         = "========== POSITION ==========";
input int    MagicNumber            = 202400;
input int    MaxOpenPositions       = 1;
input string TradeComment           = "OilPro";

//=== SYMBOL OVERRIDE ===
input string ___SYMBOL___           = "========== SYMBOL (leave blank = auto-detect) ==========";
input string ForceSymbol            = "";    // Override: e.g. "XTIUSD" or "UKOIL"
input bool   ScanAllOilSymbols      = true;  // Scan full list if chart symbol unknown

//=== DISPLAY ===
input string ___DISPLAY___          = "========== DASHBOARD ==========";
input bool   ShowDashboard          = true;
input color  DashBullColor          = clrDodgerBlue;
input color  DashBearColor          = clrOrangeRed;
input color  DashNeutralColor       = clrGray;

//+------------------------------------------------------------------+
//| Oil type constants                                                |
//+------------------------------------------------------------------+
#define OIL_UNKNOWN  0
#define OIL_BRENT    1
#define OIL_WTI      2
#define OIL_NATGAS   3

//+------------------------------------------------------------------+
//| Known oil symbol lists — every broker variant we know of         |
//+------------------------------------------------------------------+

// Brent Crude patterns (ICE/London)
string BRENT_PATTERNS[] = {
   "BRENT","BCO","LCO","LCOIL","BRN","BRNO",
   "UKOIL","OILUK","UKCRUDE",
   "XBRENT","XBRO","XBRUSD","XBRO_USD",
   "OIL"  // some brokers use generic OIL for Brent
};

// WTI Crude patterns (NYMEX)
string WTI_PATTERNS[] = {
   "WTI","CRUDE","NYMEXOIL","CL",
   "USOIL","OILUS","USCRUDE","USOILCFD",
   "XTIUSD","XTI","XWTI","XWTIUSD",
   "WTIOIL"
};

// Natural Gas patterns
string NATGAS_PATTERNS[] = {
   "NATGAS","NATURALGAS","NGAS","GAS",
   "XNGUSD","XNG","NG"
};

// Common broker suffixes to try alongside bare symbol name
string SUFFIXES[] = {
   "",".raw",".ecn",".pro",".c","#","+","m","_SB",".SB",
   "USD","_USD",".USD"
};

//+------------------------------------------------------------------+
//| Global state                                                      |
//+------------------------------------------------------------------+
datetime g_LastBarTime        = 0;
datetime g_DayStartTime       = 0;
double   g_DayStartBalance    = 0;
double   g_DayStartEquity     = 0;
int      g_TradesToday        = 0;
double   g_PeakEquity         = 0;
bool     g_DailyLimitHit      = false;
bool     g_DrawdownHaltActive = false;

string   g_WorkSymbol         = "";
int      g_OilType            = OIL_UNKNOWN;
string   g_OilTypeName        = "Unknown";
int      g_Digits             = 2;
double   g_TickSize           = 0.01;
double   g_EffectiveSpreadMax = 50.0; // Scaled by oil type in OnInit

// Cached indicator values
double   g_FastEMA_Entry  = 0;
double   g_MedEMA_Entry   = 0;
double   g_SlowEMA_Entry  = 0;
double   g_TrendEMA_Entry = 0;
double   g_FastEMA_Trend  = 0;
double   g_SlowEMA_Trend  = 0;
double   g_TrendEMA_Trend = 0;
double   g_ATR            = 0;
double   g_ATR_Avg        = 0;
double   g_RSI            = 0;
double   g_MACD_Main      = 0;
double   g_MACD_Signal_V  = 0;
double   g_MACD_Hist      = 0;
double   g_MACD_HistPrev  = 0;
double   g_Stoch_Main     = 0;
double   g_Stoch_Signal_V = 0;
double   g_BB_Upper       = 0;
double   g_BB_Lower       = 0;
double   g_BB_Middle      = 0;
double   g_BB_Width       = 0;

int      g_EntrySignal    = 0;

//+------------------------------------------------------------------+
//| Check if a symbol exists and has valid market data               |
//+------------------------------------------------------------------+
bool IsSymbolValid(string sym)
{
   if(StringLen(sym) == 0) return false;
   double bid = MarketInfo(sym, MODE_BID);
   double ask = MarketInfo(sym, MODE_ASK);
   double ts  = MarketInfo(sym, MODE_TICKSIZE);
   // Valid symbol: bid > 0, ask > bid, tick size positive
   return (bid > 0 && ask >= bid && ts > 0);
}

//+------------------------------------------------------------------+
//| Return oil type for a given pattern string                       |
//+------------------------------------------------------------------+
int ClassifyPattern(string upper)
{
   int i;
   // Brent
   for(i = 0; i < ArraySize(BRENT_PATTERNS); i++)
      if(StringFind(upper, BRENT_PATTERNS[i]) >= 0) return OIL_BRENT;
   // WTI
   for(i = 0; i < ArraySize(WTI_PATTERNS); i++)
      if(StringFind(upper, WTI_PATTERNS[i]) >= 0) return OIL_WTI;
   // Natural Gas
   for(i = 0; i < ArraySize(NATGAS_PATTERNS); i++)
      if(StringFind(upper, NATGAS_PATTERNS[i]) >= 0) return OIL_NATGAS;
   return OIL_UNKNOWN;
}

//+------------------------------------------------------------------+
//| Uppercase string helper                                          |
//+------------------------------------------------------------------+
string ToUpper(string s)
{
   string result = s;
   StringToUpper(result);
   return result;
}

//+------------------------------------------------------------------+
//| Try all suffixes for a base name; return first valid symbol      |
//+------------------------------------------------------------------+
string TrySymbolWithSuffixes(string base)
{
   for(int i = 0; i < ArraySize(SUFFIXES); i++)
   {
      string candidate = base + SUFFIXES[i];
      if(IsSymbolValid(candidate)) return candidate;
   }
   return "";
}

//+------------------------------------------------------------------+
//| Scan symbol list of patterns, return first tradeable match       |
//+------------------------------------------------------------------+
string ScanPatternList(string &patterns[], int &foundType)
{
   for(int p = 0; p < ArraySize(patterns); p++)
   {
      string found = TrySymbolWithSuffixes(patterns[p]);
      if(StringLen(found) > 0)
      {
         foundType = ClassifyPattern(ToUpper(found));
         return found;
      }
   }
   foundType = OIL_UNKNOWN;
   return "";
}

//+------------------------------------------------------------------+
//| Main symbol auto-detection logic                                 |
//+------------------------------------------------------------------+
bool DetectOilSymbol()
{
   // 1. Forced override
   if(StringLen(ForceSymbol) > 0)
   {
      if(!IsSymbolValid(ForceSymbol))
      {
         Print("ERROR: ForceSymbol '", ForceSymbol, "' not found or invalid.");
         return false;
      }
      g_WorkSymbol = ForceSymbol;
      g_OilType    = ClassifyPattern(ToUpper(ForceSymbol));
      Print("Symbol forced: ", g_WorkSymbol);
      return true;
   }

   // 2. Try chart symbol first
   string chartSym = Symbol();
   if(IsSymbolValid(chartSym))
   {
      int t = ClassifyPattern(ToUpper(chartSym));
      if(t != OIL_UNKNOWN)
      {
         g_WorkSymbol = chartSym;
         g_OilType    = t;
         Print("Chart symbol recognised as oil: ", g_WorkSymbol);
         return true;
      }
   }

   if(!ScanAllOilSymbols)
   {
      Print("Chart symbol '", chartSym, "' not recognised as oil. "
            "Enable ScanAllOilSymbols or set ForceSymbol.");
      return false;
   }

   // 3. Full scan: Brent first, then WTI, then NatGas
   int ft = OIL_UNKNOWN;
   string found = "";

   found = ScanPatternList(BRENT_PATTERNS, ft);
   if(StringLen(found) > 0) { g_WorkSymbol = found; g_OilType = OIL_BRENT; return true; }

   found = ScanPatternList(WTI_PATTERNS, ft);
   if(StringLen(found) > 0) { g_WorkSymbol = found; g_OilType = OIL_WTI; return true; }

   found = ScanPatternList(NATGAS_PATTERNS, ft);
   if(StringLen(found) > 0) { g_WorkSymbol = found; g_OilType = OIL_NATGAS; return true; }

   Print("ERROR: No recognised oil symbol found in this broker's market watch. "
         "Add the symbol to Market Watch or set ForceSymbol manually.");
   return false;
}

//+------------------------------------------------------------------+
//| Set oil-type-specific defaults                                   |
//+------------------------------------------------------------------+
void ApplyOilTypeDefaults()
{
   switch(g_OilType)
   {
      case OIL_BRENT:
         g_OilTypeName        = "Brent Crude (ICE)";
         g_EffectiveSpreadMax = MaxSpreadPoints; // Use user input as-is
         break;
      case OIL_WTI:
         g_OilTypeName        = "WTI Crude (NYMEX)";
         // WTI typically has slightly tighter spreads; keep user input
         g_EffectiveSpreadMax = MaxSpreadPoints;
         break;
      case OIL_NATGAS:
         g_OilTypeName        = "Natural Gas";
         // NatGas often quoted to 3-4 dp and has different spread scale
         g_EffectiveSpreadMax = MaxSpreadPoints * 0.5; // NatGas spreads are smaller
         break;
      default:
         g_OilTypeName        = "Oil (Unknown Type)";
         g_EffectiveSpreadMax = MaxSpreadPoints;
         break;
   }
}

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!DetectOilSymbol())
      return INIT_FAILED;

   ApplyOilTypeDefaults();

   g_Digits   = (int)MarketInfo(g_WorkSymbol, MODE_DIGITS);
   g_TickSize = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);

   g_PeakEquity      = AccountEquity();
   g_DayStartBalance = AccountBalance();
   g_DayStartEquity  = AccountEquity();
   g_DayStartTime    = TimeCurrent();

   Print("=================================================");
   Print(" Oil Trader Pro v4.00 — READY");
   Print(" Oil Type  : ", g_OilTypeName);
   Print(" Symbol    : ", g_WorkSymbol);
   Print(" Digits    : ", g_Digits, "  TickSize: ", g_TickSize);
   Print(" MaxSpread : ", g_EffectiveSpreadMax, " pts");
   Print("=================================================");

   if(ShowDashboard) DrawDashboard("Initializing...", DashNeutralColor);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "OPro_");
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Position management always runs (regardless of session/filters)
   ManageOpenPositions();

   // Bar-close entry gate
   if(RequireBarClose)
   {
      datetime barTime = iTime(g_WorkSymbol, EntryTimeframe, 0);
      if(barTime == g_LastBarTime) return;
      g_LastBarTime = barTime;
   }

   CheckDailyReset();

   if(g_DailyLimitHit || g_DrawdownHaltActive)
   {
      if(ShowDashboard) DrawDashboard("DAILY LIMIT — HALTED", DashBearColor);
      return;
   }

   if(!CheckDrawdown())    return;
   if(CountOpenPositions() >= MaxOpenPositions) return;
   if(!IsAllowedSession()) return;
   if(!CheckSpread())      return;
   if(UseNewsFilter && IsNewsTime()) return;

   LoadIndicators();

   if(!CheckVolatility())  return;

   g_EntrySignal = GenerateSignal();

   if(g_EntrySignal != 0)
      ExecuteEntry(g_EntrySignal);

   if(ShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Load all indicator values (called once per new bar)              |
//+------------------------------------------------------------------+
void LoadIndicators()
{
   g_FastEMA_Entry  = iMA(g_WorkSymbol, EntryTimeframe, FastEMA_Period,   0, MA_Method, MA_Price, 1);
   g_MedEMA_Entry   = iMA(g_WorkSymbol, EntryTimeframe, MediumEMA_Period, 0, MA_Method, MA_Price, 1);
   g_SlowEMA_Entry  = iMA(g_WorkSymbol, EntryTimeframe, SlowEMA_Period,   0, MA_Method, MA_Price, 1);
   g_TrendEMA_Entry = iMA(g_WorkSymbol, EntryTimeframe, TrendEMA_Period,  0, MA_Method, MA_Price, 1);

   g_FastEMA_Trend  = iMA(g_WorkSymbol, TrendTimeframe, FastEMA_Period,   0, MA_Method, MA_Price, 1);
   g_SlowEMA_Trend  = iMA(g_WorkSymbol, TrendTimeframe, SlowEMA_Period,   0, MA_Method, MA_Price, 1);
   g_TrendEMA_Trend = iMA(g_WorkSymbol, TrendTimeframe, TrendEMA_Period,  0, MA_Method, MA_Price, 1);

   g_ATR = iATR(g_WorkSymbol, EntryTimeframe, ATR_Period, 1);
   double atrSum = 0;
   for(int i = 1; i <= 50; i++) atrSum += iATR(g_WorkSymbol, EntryTimeframe, ATR_Period, i);
   g_ATR_Avg = atrSum / 50.0;

   g_RSI = iRSI(g_WorkSymbol, EntryTimeframe, RSI_Period, MA_Price, 1);

   g_MACD_Main     = iMACD(g_WorkSymbol, EntryTimeframe, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, MA_Price, MODE_MAIN,   1);
   g_MACD_Signal_V = iMACD(g_WorkSymbol, EntryTimeframe, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, MA_Price, MODE_SIGNAL, 1);
   g_MACD_Hist     = g_MACD_Main - g_MACD_Signal_V;
   g_MACD_HistPrev = iMACD(g_WorkSymbol, EntryTimeframe, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, MA_Price, MODE_MAIN,   2)
                   - iMACD(g_WorkSymbol, EntryTimeframe, MACD_FastEMA, MACD_SlowEMA, MACD_Signal, MA_Price, MODE_SIGNAL, 2);

   g_Stoch_Main     = iStochastic(g_WorkSymbol, EntryTimeframe, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN,   1);
   g_Stoch_Signal_V = iStochastic(g_WorkSymbol, EntryTimeframe, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, 1);

   g_BB_Upper  = iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_UPPER, 1);
   g_BB_Lower  = iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_LOWER, 1);
   g_BB_Middle = iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_MAIN,  1);
   g_BB_Width  = g_BB_Upper - g_BB_Lower;
}

//+------------------------------------------------------------------+
//| Consolidated entry signal generator                              |
//+------------------------------------------------------------------+
int GenerateSignal()
{
   double closeEntry = iClose(g_WorkSymbol, EntryTimeframe, 1);
   double prevClose  = iClose(g_WorkSymbol, EntryTimeframe, 2);
   double closeTrend = iClose(g_WorkSymbol, TrendTimeframe, 1);

   // Higher-timeframe trend bias
   int  trendBias  = 0;
   bool strongTrend = false;
   if(closeTrend > g_TrendEMA_Trend && g_FastEMA_Trend > g_SlowEMA_Trend)
   { trendBias = 1;  strongTrend = true; }
   else if(closeTrend < g_TrendEMA_Trend && g_FastEMA_Trend < g_SlowEMA_Trend)
   { trendBias = -1; strongTrend = true; }

   int signal = 0;

   // ------------------------------------------------------------------
   // STRATEGY 1: EMA TREND FOLLOWING
   // Fast EMA crosses Medium EMA aligned with HTF trend
   // ------------------------------------------------------------------
   if(EnableTrendFollowing && strongTrend && signal == 0)
   {
      double fastPrev = iMA(g_WorkSymbol, EntryTimeframe, FastEMA_Period,   0, MA_Method, MA_Price, 2);
      double medPrev  = iMA(g_WorkSymbol, EntryTimeframe, MediumEMA_Period, 0, MA_Method, MA_Price, 2);

      bool crossUp   = (fastPrev <= medPrev) && (g_FastEMA_Entry > g_MedEMA_Entry);
      bool crossDown = (fastPrev >= medPrev) && (g_FastEMA_Entry < g_MedEMA_Entry);

      if(crossUp   && trendBias == 1 && closeEntry > g_SlowEMA_Entry &&
         g_RSI > RSI_BullishMin && g_RSI < RSI_Overbought)
         signal = 1;

      if(crossDown && trendBias == -1 && closeEntry < g_SlowEMA_Entry &&
         g_RSI < RSI_BearishMax && g_RSI > RSI_Oversold)
         signal = -1;
   }

   // ------------------------------------------------------------------
   // STRATEGY 2: MACD MOMENTUM BREAKOUT
   // MACD histogram flips sign while RSI confirms direction
   // ------------------------------------------------------------------
   if(EnableMomentumEntries && signal == 0)
   {
      bool macdBull = (g_MACD_HistPrev < 0) && (g_MACD_Hist > 0);
      bool macdBear = (g_MACD_HistPrev > 0) && (g_MACD_Hist < 0);

      if(macdBull && g_RSI > 50.0 && g_RSI < RSI_Overbought &&
         (!strongTrend || trendBias == 1))
         signal = 1;

      if(macdBear && g_RSI < 50.0 && g_RSI > RSI_Oversold &&
         (!strongTrend || trendBias == -1))
         signal = -1;
   }

   // ------------------------------------------------------------------
   // STRATEGY 3: BOLLINGER BAND BREAKOUT AFTER SQUEEZE
   // Price closes outside the band following a bandwidth squeeze
   // ------------------------------------------------------------------
   if(EnableBreakoutEntries && signal == 0)
   {
      bool squeeze   = (g_BB_Width < g_ATR * BB_SqueezeATRMult * 2.0);
      double bbUpPrv = iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_UPPER, 2);
      double bbLoPrv = iBands(g_WorkSymbol, EntryTimeframe, BB_Period, BB_Deviation, 0, MA_Price, MODE_LOWER, 2);

      bool bullBreak = !squeeze && (closeEntry > g_BB_Upper) && (prevClose <= bbUpPrv);
      bool bearBreak = !squeeze && (closeEntry < g_BB_Lower) && (prevClose >= bbLoPrv);

      if(bullBreak && g_MACD_Hist > 0 && (!strongTrend || trendBias == 1))
         signal = 1;

      if(bearBreak && g_MACD_Hist < 0 && (!strongTrend || trendBias == -1))
         signal = -1;
   }

   // ------------------------------------------------------------------
   // STRATEGY 4: PULLBACK TO MEDIUM EMA
   // Best risk-reward: retrace to EMA within a strong trend
   // ------------------------------------------------------------------
   if(EnablePullbackEntries && strongTrend && signal == 0)
   {
      bool nearMed = (MathAbs(closeEntry - g_MedEMA_Entry) < g_ATR * 0.4);

      if(trendBias == 1 && nearMed && closeEntry > g_SlowEMA_Entry &&
         g_Stoch_Main < 40.0 && g_Stoch_Main > g_Stoch_Signal_V &&
         g_RSI > 40.0 && g_RSI < 65.0)
         signal = 1;

      if(trendBias == -1 && nearMed && closeEntry < g_SlowEMA_Entry &&
         g_Stoch_Main > 60.0 && g_Stoch_Main < g_Stoch_Signal_V &&
         g_RSI < 60.0 && g_RSI > 35.0)
         signal = -1;
   }

   // Stochastic extreme guard (never enter into an exhausted move)
   if(signal ==  1 && g_Stoch_Main > Stoch_Overbought) signal = 0;
   if(signal == -1 && g_Stoch_Main < Stoch_Oversold)   signal = 0;

   return signal;
}

//+------------------------------------------------------------------+
//| Open entry order with dynamic lot sizing                         |
//+------------------------------------------------------------------+
void ExecuteEntry(int direction)
{
   double ask = MarketInfo(g_WorkSymbol, MODE_ASK);
   double bid = MarketInfo(g_WorkSymbol, MODE_BID);
   double atr = g_ATR;

   double entry, sl, tp1, tp2, tp3;

   if(direction == 1)
   {
      entry = ask;
      sl    = NormalizeDouble(ask - atr * ATR_SL_Multiplier,  g_Digits);
      tp1   = NormalizeDouble(ask + atr * ATR_TP1_Multiplier, g_Digits);
      tp2   = NormalizeDouble(ask + atr * ATR_TP2_Multiplier, g_Digits);
      tp3   = NormalizeDouble(ask + atr * ATR_TP3_Multiplier, g_Digits);
   }
   else
   {
      entry = bid;
      sl    = NormalizeDouble(bid + atr * ATR_SL_Multiplier,  g_Digits);
      tp1   = NormalizeDouble(bid - atr * ATR_TP1_Multiplier, g_Digits);
      tp2   = NormalizeDouble(bid - atr * ATR_TP2_Multiplier, g_Digits);
      tp3   = NormalizeDouble(bid - atr * ATR_TP3_Multiplier, g_Digits);
   }

   // Ensure SL clears broker minimum stop distance
   double minDist = MarketInfo(g_WorkSymbol, MODE_STOPLEVEL) * g_TickSize;
   if(MathAbs(entry - sl) < minDist)
      sl = (direction == 1) ? entry - minDist : entry + minDist;

   double lots = CalculateLotSize(entry, sl);
   if(lots <= 0) return;

   string cmt = TradeComment + "|TP1=" + DoubleToStr(tp1, g_Digits)
              + "|TP2=" + DoubleToStr(tp2, g_Digits)
              + "|TP3=" + DoubleToStr(tp3, g_Digits);

   int cmd    = (direction == 1) ? OP_BUY : OP_SELL;
   double prc = (direction == 1) ? ask : bid;

   int ticket = OrderSend(g_WorkSymbol, cmd, lots, prc, MaxSlippagePoints,
                          sl, tp2, cmt, MagicNumber, 0,
                          (direction == 1) ? DashBullColor : DashBearColor);

   if(ticket > 0)
   {
      g_TradesToday++;
      Print("Trade opened | ", g_OilTypeName, " | Ticket:", ticket,
            " | ", (direction == 1 ? "BUY" : "SELL"),
            " | Lots:", lots, " | Entry:", entry,
            " | SL:", sl, " | TP2:", tp2, " | ATR:", atr);
   }
   else
   {
      int err = GetLastError();
      Print("OrderSend FAILED | Error:", err, " | ", OilErrorDesc(err));
   }
}

//+------------------------------------------------------------------+
//| Dynamic lot sizing — risk-based                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double entry, double sl)
{
   double balance   = AccountBalance();
   double riskAmt   = balance * RiskPercent / 100.0;
   double slDist    = MathAbs(entry - sl);
   if(slDist <= 0) return MinLotSize;

   double tickVal   = MarketInfo(g_WorkSymbol, MODE_TICKVALUE);
   double tickSz    = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);
   double lotStep   = MarketInfo(g_WorkSymbol, MODE_LOTSTEP);
   double minLot    = MarketInfo(g_WorkSymbol, MODE_MINLOT);
   double maxLot    = MarketInfo(g_WorkSymbol, MODE_MAXLOT);

   if(tickVal <= 0 || tickSz <= 0) return minLot;

   double slValPerLot = (slDist / tickSz) * tickVal;
   double raw         = riskAmt / slValPerLot;
   double lots        = MathFloor(raw / lotStep) * lotStep;

   lots = MathMax(lots, MathMax(minLot, MinLotSize));
   lots = MathMin(lots, MathMin(maxLot, MaxLotSize));
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Manage all open positions: partial close, break-even, trail      |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber)           continue;
      if(OrderSymbol() != g_WorkSymbol)               continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      double openPx   = OrderOpenPrice();
      double curSL    = OrderStopLoss();
      double curTP    = OrderTakeProfit();
      double ask      = MarketInfo(g_WorkSymbol, MODE_ASK);
      double bid      = MarketInfo(g_WorkSymbol, MODE_BID);
      double curPx    = (OrderType() == OP_BUY) ? bid : ask;
      double atr      = iATR(g_WorkSymbol, EntryTimeframe, ATR_Period, 1);
      double ts       = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);
      double minSD    = MarketInfo(g_WorkSymbol, MODE_STOPLEVEL) * ts;
      double profitPt = (OrderType() == OP_BUY) ? (curPx - openPx) : (openPx - curPx);
      string cmt      = OrderComment();

      // Parse TP1 from embedded comment
      double tp1 = 0;
      int p1     = StringFind(cmt, "TP1=");
      if(p1 >= 0)
      {
         string s = StringSubstr(cmt, p1 + 4);
         int pp   = StringFind(s, "|");
         if(pp > 0) s = StringSubstr(s, 0, pp);
         tp1 = StrToDouble(s);
      }

      bool tp1Hit = (tp1 > 0) &&
                    ((OrderType() == OP_BUY  && curPx >= tp1) ||
                     (OrderType() == OP_SELL && curPx <= tp1));

      // --- PARTIAL CLOSE at TP1 ---
      if(UsePartialClose && tp1Hit && StringFind(cmt, "PC1") < 0)
      {
         double lotStep    = MarketInfo(g_WorkSymbol, MODE_LOTSTEP);
         double minLot     = MarketInfo(g_WorkSymbol, MODE_MINLOT);
         double partLots   = NormalizeDouble(OrderLots() * PartialClosePercent / 100.0, 2);
         partLots          = MathFloor(partLots / lotStep) * lotStep;

         if(partLots >= minLot && partLots < OrderLots())
         {
            if(OrderClose(OrderTicket(), partLots, curPx, MaxSlippagePoints, clrYellow))
               Print("Partial TP1 close | Ticket:", OrderTicket(), " | Lots:", partLots);
         }
      }

      // --- BREAK-EVEN ---
      if(UseBreakEven && tp1Hit)
      {
         double beSL;
         bool   doModify = false;
         double beBuffer = atr * 0.1;

         if(OrderType() == OP_BUY)
         {
            beSL = NormalizeDouble(openPx + beBuffer, g_Digits);
            if(beSL > curSL + ts && beSL < curPx - minSD) doModify = true;
         }
         else
         {
            beSL = NormalizeDouble(openPx - beBuffer, g_Digits);
            if(beSL < curSL - ts && beSL > curPx + minSD) doModify = true;
         }

         if(doModify)
            if(OrderModify(OrderTicket(), openPx, beSL, curTP, 0, clrGold))
               Print("Break-even | Ticket:", OrderTicket(), " SL:", beSL);
      }

      // --- TRAILING STOP ---
      if(UseTrailingStop && profitPt >= atr * TrailingActivateATRMult)
      {
         double trailDist = atr * TrailingATRMult;
         double trailSL;
         bool   doTrail   = false;

         if(OrderType() == OP_BUY)
         {
            trailSL = NormalizeDouble(curPx - trailDist, g_Digits);
            if(trailSL > curSL + ts && trailSL < curPx - minSD) doTrail = true;
         }
         else
         {
            trailSL = NormalizeDouble(curPx + trailDist, g_Digits);
            if(trailSL < curSL - ts && trailSL > curPx + minSD) doTrail = true;
         }

         if(doTrail)
            if(OrderModify(OrderTicket(), openPx, trailSL, curTP, 0, clrCyan))
               Print("Trail stop | Ticket:", OrderTicket(), " SL:", trailSL);
      }
   }
}

//+------------------------------------------------------------------+
//| Session filter — oil-specific active hours (GMT)                 |
//+------------------------------------------------------------------+
bool IsAllowedSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int dow     = dt.day_of_week;
   int gmtH    = (dt.hour - SessionGMTOffset + 24) % 24;

   if(SkipWeekend   && (dow == 0 || dow == 6))          return false;
   if(SkipMonday0000 && dow == 1 && gmtH < 5)           return false;
   if(SkipFriday1700 && dow == 5 && gmtH >= 17)         return false;

   if(TradeLondonOpen && gmtH >= 7  && gmtH < 9)  return true;
   if(TradeLondonCore && gmtH >= 9  && gmtH < 13) return true;
   if(TradeNYOverlap  && gmtH >= 13 && gmtH < 17) return true;
   if(TradeNYSession  && gmtH >= 17 && gmtH < 21) return true;
   if(TradeAsian      && gmtH >= 0  && gmtH < 7)  return true;

   return false;
}

//+------------------------------------------------------------------+
//| News filter — oil-market-specific events                         |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int dow      = dt.day_of_week;
   int gmtH     = (dt.hour - SessionGMTOffset + 24) % 24;
   int totalMin = gmtH * 60 + dt.min;

   // EIA Petroleum Status Report — Wednesday 14:30 GMT
   if(FilterEIA && dow == 3)
   {
      int t = 14 * 60 + 30;
      if(totalMin >= t - NewsBufferMinBefore && totalMin <= t + NewsBufferMinAfter)
         return true;
   }

   // API Crude Oil Stock — Tuesday 20:30 GMT
   if(FilterAPI && dow == 2)
   {
      int t = 20 * 60 + 30;
      if(totalMin >= t - NewsBufferMinBefore && totalMin <= t + NewsBufferMinAfter)
         return true;
   }

   // US Non-Farm Payrolls — First Friday of month, 13:30 GMT
   if(FilterNFP && dow == 5)
   {
      int t = 13 * 60 + 30;
      if(totalMin >= t && totalMin <= t + 60) return true;
   }

   // FOMC Statement — Wednesday 19:00 GMT (approx every 6 weeks; broad filter)
   if(FilterFOMC && dow == 3)
   {
      int t = 19 * 60;
      if(totalMin >= t - NewsBufferMinBefore && totalMin <= t + NewsBufferMinAfter)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Spread check using oil-type-scaled threshold                     |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   return (MarketInfo(g_WorkSymbol, MODE_SPREAD) <= g_EffectiveSpreadMax);
}

//+------------------------------------------------------------------+
//| Volatility guard — skip dead or spike markets                    |
//+------------------------------------------------------------------+
bool CheckVolatility()
{
   if(g_ATR <= 0 || g_ATR_Avg <= 0)                    return false;
   if(g_ATR < g_ATR_Avg * ATR_MinMultiplier)            return false;
   if(g_ATR > g_ATR_Avg * ATR_MaxMultiplier)            return false;
   return true;
}

//+------------------------------------------------------------------+
//| Drawdown protection                                              |
//+------------------------------------------------------------------+
bool CheckDrawdown()
{
   double equity = AccountEquity();
   if(equity > g_PeakEquity) g_PeakEquity = equity;

   double ddPct = (g_PeakEquity > 0) ? (g_PeakEquity - equity) / g_PeakEquity * 100.0 : 0;

   if(ddPct >= MaxDrawdownPercent)
   {
      if(!g_DrawdownHaltActive)
      {
         Print("MAX DRAWDOWN HIT: ", DoubleToStr(ddPct, 2), "% — Halting trading");
         g_DrawdownHaltActive = true;
      }
      if(ShowDashboard) DrawDashboard("DRAWDOWN HALT: " + DoubleToStr(ddPct, 1) + "%", DashBearColor);
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Daily reset and P&L limits                                       |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   MqlDateTime dtNow, dtStart;
   TimeToStruct(TimeCurrent(),    dtNow);
   TimeToStruct(g_DayStartTime,   dtStart);

   if(dtNow.day != dtStart.day || dtNow.mon != dtStart.mon)
   {
      g_DayStartTime    = TimeCurrent();
      g_DayStartBalance = AccountBalance();
      g_DayStartEquity  = AccountEquity();
      g_TradesToday     = 0;
      g_DailyLimitHit   = false;
      Print("Daily reset | Balance:", g_DayStartBalance);
   }

   if(g_TradesToday >= MaxTradesPerDay && !g_DailyLimitHit)
   { g_DailyLimitHit = true; Print("Daily trade count reached: ", MaxTradesPerDay); return; }

   if(g_DayStartBalance > 0)
   {
      double pnlPct = (AccountEquity() - g_DayStartEquity) / g_DayStartBalance * 100.0;
      if(pnlPct <= -MaxDailyLossPercent && !g_DailyLimitHit)
      { g_DailyLimitHit = true; Print("Daily LOSS limit: ", DoubleToStr(pnlPct, 2), "%"); }
      if(pnlPct >= MaxDailyProfitPercent && !g_DailyLimitHit)
      { g_DailyLimitHit = true; Print("Daily PROFIT target: ", DoubleToStr(pnlPct, 2), "%"); }
   }
}

//+------------------------------------------------------------------+
//| Count this EA's open positions                                   |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int n = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() == MagicNumber && OrderSymbol() == g_WorkSymbol) n++;
   }
   return n;
}

//+------------------------------------------------------------------+
//| Dashboard (chart comment)                                        |
//+------------------------------------------------------------------+
void DrawDashboard(string status, color clr)
{
   string trendStr = "---";
   if(g_TrendEMA_Trend > 0)
   {
      double ct = iClose(g_WorkSymbol, TrendTimeframe, 1);
      trendStr = (ct > g_TrendEMA_Trend) ? "BULL" : (ct < g_TrendEMA_Trend) ? "BEAR" : "FLAT";
   }

   string sigStr = (g_EntrySignal ==  1) ? "BUY"  :
                   (g_EntrySignal == -1) ? "SELL" : "NONE";

   double equity  = AccountEquity();
   double balance = AccountBalance();
   double pnl     = equity - g_DayStartEquity;
   double dd      = (g_PeakEquity > 0) ? (g_PeakEquity - equity) / g_PeakEquity * 100.0 : 0;

   string nl = "\n";
   string d  = nl;
   d += "=== OIL TRADER PRO v4.00 ===" + nl;
   d += "Type   : " + g_OilTypeName + nl;
   d += "Symbol : " + g_WorkSymbol  + nl;
   d += "Status : " + status        + nl;
   d += "Trend  : " + trendStr + " | Signal: " + sigStr + nl;
   d += "ATR    : " + DoubleToStr(g_ATR,     g_Digits)
      + "  Avg: " + DoubleToStr(g_ATR_Avg, g_Digits) + nl;
   d += "RSI    : " + DoubleToStr(g_RSI, 1)
      + "  MACD: " + DoubleToStr(g_MACD_Hist, 5) + nl;
   d += "Stoch  : " + DoubleToStr(g_Stoch_Main, 1) + nl;
   d += "Balance: " + DoubleToStr(balance, 2)
      + "  Equity: " + DoubleToStr(equity, 2) + nl;
   d += "DayPnL : " + DoubleToStr(pnl, 2)
      + "  DD: "    + DoubleToStr(dd,  2) + "%" + nl;
   d += "Trades : " + IntegerToString(g_TradesToday) + "/" + IntegerToString(MaxTradesPerDay) + nl;
   d += "Pos    : " + IntegerToString(CountOpenPositions()) + "/" + IntegerToString(MaxOpenPositions) + nl;
   d += "Spread : " + DoubleToStr(MarketInfo(g_WorkSymbol, MODE_SPREAD), 1)
      + " / max " + DoubleToStr(g_EffectiveSpreadMax, 1) + nl;
   d += "Session: " + (IsAllowedSession() ? "ACTIVE" : "CLOSED") + nl;
   d += "News   : " + (UseNewsFilter && IsNewsTime() ? "BLOCKED" : "CLEAR") + nl;

   Comment(d);
}

void UpdateDashboard() { DrawDashboard("RUNNING", DashBullColor); }

//+------------------------------------------------------------------+
//| Error description                                                |
//+------------------------------------------------------------------+
string OilErrorDesc(int code)
{
   switch(code)
   {
      case 3:   return "Invalid trade params";
      case 4:   return "Trade server busy";
      case 6:   return "No connection";
      case 128: return "Trade timeout";
      case 129: return "Invalid price";
      case 130: return "Invalid stops";
      case 131: return "Invalid volume";
      case 132: return "Market closed";
      case 133: return "Trading disabled";
      case 134: return "Not enough money";
      case 135: return "Price changed";
      case 136: return "Off quotes";
      case 137: return "Broker busy";
      case 138: return "Requote";
      case 145: return "SL/TP too close";
      case 146: return "Trade context busy";
      case 148: return "Order limit reached";
      case 149: return "Hedging prohibited";
      case 150: return "FIFO violation";
      default:  return "Error " + IntegerToString(code);
   }
}
//+------------------------------------------------------------------+
