//+------------------------------------------------------------------+
//|                                          Oil_Scalper_Pro.mq4     |
//|                    Universal Crude Oil Scalping System            |
//|        Brent | WTI | Natural Gas  —  Any Broker Symbol           |
//+------------------------------------------------------------------+
#property copyright "Professional Oil Trading Systems"
#property version   "1.00"
#property strict
#property description "Universal Oil Scalper: auto-detects Brent, WTI, Natural Gas"
#property description "M5 scalping | Fast EMA | Stoch | BB Mean-Reversion | Breakout"
#property description "Tight ATR stops | Partial close | Strict spread guard"

//=== STRATEGY SELECTION ===
input string ___STRATEGY___          = "========== SCALPING STRATEGIES ==========";
input bool   EnableFastEMAScalp      = true;  // 3/8 EMA cross + M15 trend filter
input bool   EnableMomentumScalp     = true;  // RSI(7) cross 50 + fast MACD flip
input bool   EnableStochScalp        = true;  // Stochastic reversal at extremes
input bool   EnableBBMeanReversion   = true;  // BB touch + rejection candle
input bool   EnableBreakoutScalp     = true;  // M5 bar high/low breakout

//=== TIMEFRAMES ===
input string          ___TF___         = "========== TIMEFRAMES ==========";
input ENUM_TIMEFRAMES ScalpTimeframe   = PERIOD_M5;   // Entry signals
input ENUM_TIMEFRAMES TrendTimeframe   = PERIOD_M30;  // Trend bias filter
input ENUM_TIMEFRAMES HTFTimeframe     = PERIOD_H1;   // Higher-level bias

//=== FAST EMA SETTINGS ===
input string ___EMA___               = "========== FAST EMAs ==========";
input int    EMA_Fast                = 3;
input int    EMA_Mid                 = 8;
input int    EMA_Slow                = 21;
input int    EMA_Trend               = 50;   // Trend filter on ScalpTF
input ENUM_MA_METHOD   MA_Method     = MODE_EMA;
input ENUM_APPLIED_PRICE MA_Price    = PRICE_CLOSE;

//=== RSI ===
input string ___RSI___               = "========== RSI ==========";
input int    RSI_Period              = 7;    // Fast RSI for scalping
input double RSI_Bull                = 52.0; // Must be above for longs
input double RSI_Bear                = 48.0; // Must be below for shorts
input double RSI_OB                  = 75.0;
input double RSI_OS                  = 25.0;

//=== MACD ===
input string ___MACD___              = "========== MACD ==========";
input int    MACD_Fast               = 5;
input int    MACD_Slow               = 13;
input int    MACD_Sig                = 3;

//=== STOCHASTIC ===
input string ___STOCH___             = "========== STOCHASTIC ==========";
input int    Stoch_K                 = 5;
input int    Stoch_D                 = 3;
input int    Stoch_Slow              = 3;
input double Stoch_OB                = 80.0;
input double Stoch_OS                = 20.0;
input double Stoch_MidOB             = 65.0; // Soft overbought for momentum filter
input double Stoch_MidOS             = 35.0; // Soft oversold  for momentum filter

//=== BOLLINGER BANDS ===
input string ___BB___                = "========== BOLLINGER BANDS ==========";
input int    BB_Period               = 20;
input double BB_Dev                  = 2.0;
input double BB_TouchBuffer          = 0.15; // Fraction of ATR price must be within BB edge

//=== ATR ===
input string ___ATR___               = "========== ATR ==========";
input int    ATR_Period              = 7;    // Shorter period for scalping
input double ATR_SL_Mult             = 0.9;  // Stop loss = 0.9x ATR (tight)
input double ATR_TP1_Mult            = 0.8;  // TP1 = 0.8x ATR (fast partial close)
input double ATR_TP2_Mult            = 1.6;  // TP2 = full close target
input double ATR_Min_Mult            = 0.4;  // Skip if ATR < 0.4x 30-bar avg (dead)
input double ATR_Max_Mult            = 2.8;  // Skip if ATR > 2.8x 30-bar avg (spike)

//=== RISK MANAGEMENT ===
input string ___RISK___              = "========== RISK MANAGEMENT ==========";
input double RiskPercent             = 0.5;  // Low risk per scalp
input double MaxLotSize              = 3.0;
input double MinLotSize              = 0.01;
input bool   UsePartialClose         = true;
input double PartialClosePct         = 60.0; // Close 60% at TP1 (take fast profit)
input bool   UseBreakEven            = true;
input double BreakEvenBuffer_ATR     = 0.05; // BE buffer = 0.05x ATR
input bool   UseTrailingStop         = true;
input double TrailATR_Mult           = 0.5;  // Trail = 0.5x ATR (tight scalp trail)
input double TrailActivate_ATR_Mult  = 0.7;  // Activate trail after 0.7x ATR profit

//=== DAILY & SESSION LIMITS ===
input string ___LIMITS___            = "========== LIMITS ==========";
input double MaxDailyLossPct         = 2.0;
input double MaxDailyProfitPct       = 4.0;
input int    MaxTradesPerDay         = 25;
input int    MaxTradesPerHour        = 5;
input int    MaxOpenPositions        = 2;    // Allow 2 concurrent scalps
input double MaxDrawdownPct          = 10.0;

//=== SESSION FILTER ===
input string ___SESSIONS___          = "========== SCALPING SESSIONS ==========";
// For oil scalping: London open and NY overlap are the ONLY sessions worth trading
input bool   TradeLondonOpen         = true;  // 07:00-09:00 GMT (oil price discovery)
input bool   TradeLondonCore         = true;  // 09:00-13:00 GMT
input bool   TradeNYOverlap          = true;  // 13:00-17:00 GMT (peak oil liquidity)
input bool   TradeNYSession          = false; // 17:00-21:00 GMT (thinner, riskier)
input bool   TradeAsian              = false; // 00:00-07:00 GMT (avoid for oil scalping)
input int    SessionGMTOffset        = 0;
input bool   SkipFriday1700          = true;
input bool   SkipMonday0500          = true;
input bool   SkipWeekend             = true;

//=== NEWS FILTER ===
input string ___NEWS___              = "========== NEWS FILTER ==========";
input bool   UseNewsFilter           = true;
input int    NewsMinBefore           = 45;  // Wider buffer for scalping
input int    NewsMinAfter            = 45;
input bool   FilterEIA               = true;
input bool   FilterAPI               = true;
input bool   FilterNFP               = true;
input bool   FilterFOMC              = true;

//=== SPREAD & EXECUTION ===
input string ___EXEC___              = "========== EXECUTION ==========";
input double MaxSpreadPoints         = 20.0; // Critical for scalping — tight cap
input int    MaxSlippage             = 10;   // Tight slippage for scalping
input bool   RequireBarClose         = false; // Scalping works tick-by-tick
input int    MinBarsSinceLastTrade   = 2;    // Bars to wait before next scalp

//=== POSITION ===
input string ___POSITION___          = "========== POSITION ==========";
input int    MagicNumber             = 303500;
input string TradeComment            = "OilScalp";

//=== SYMBOL ===
input string ___SYMBOL___            = "========== SYMBOL (blank = auto-detect) ==========";
input string ForceSymbol             = "";
input bool   ScanAllOilSymbols       = true;

//=== DISPLAY ===
input string ___DISPLAY___           = "========== DASHBOARD ==========";
input bool   ShowDashboard           = true;
input color  BullColor               = clrDodgerBlue;
input color  BearColor               = clrOrangeRed;
input color  NeutralColor            = clrGray;

//+------------------------------------------------------------------+
//| Oil type constants                                                |
//+------------------------------------------------------------------+
#define OIL_UNKNOWN  0
#define OIL_BRENT    1
#define OIL_WTI      2
#define OIL_NATGAS   3

//+------------------------------------------------------------------+
//| Known symbol patterns (same comprehensive list as swing EA)      |
//+------------------------------------------------------------------+
string BRENT_PATTERNS[] = {
   "BRENT","BCO","LCO","LCOIL","BRN","BRNO",
   "UKOIL","OILUK","UKCRUDE",
   "XBRENT","XBRO","XBRUSD","XBRO_USD",
   "OIL"
};
string WTI_PATTERNS[] = {
   "WTI","CRUDE","NYMEXOIL","CL",
   "USOIL","OILUS","USCRUDE","USOILCFD",
   "XTIUSD","XTI","XWTI","XWTIUSD",
   "WTIOIL"
};
string NATGAS_PATTERNS[] = {
   "NATGAS","NATURALGAS","NGAS","GAS",
   "XNGUSD","XNG","NG"
};
string SUFFIXES[] = {
   "",".raw",".ecn",".pro",".c","#","+","m","_SB",".SB",
   "USD","_USD",".USD"
};

//+------------------------------------------------------------------+
//| Global state                                                      |
//+------------------------------------------------------------------+
datetime g_LastBarTime        = 0;
datetime g_LastTradeBarTime   = 0;
datetime g_DayStartTime       = 0;
int      g_HourTradeCount     = 0;
int      g_CurrentHour        = -1;
double   g_DayStartBalance    = 0;
double   g_DayStartEquity     = 0;
int      g_TradesToday        = 0;
double   g_PeakEquity         = 0;
bool     g_DailyLimitHit      = false;
bool     g_DDHaltActive       = false;

string   g_WorkSymbol         = "";
int      g_OilType            = OIL_UNKNOWN;
string   g_OilTypeName        = "Unknown";
int      g_Digits             = 2;
double   g_TickSize           = 0.01;
double   g_EffSpreadMax       = 20.0;

// Cached indicators
double   g_EMA_Fast           = 0;
double   g_EMA_Mid            = 0;
double   g_EMA_Slow           = 0;
double   g_EMA_Trend          = 0;
double   g_TrendEMA_Trend     = 0; // EMA_Trend on TrendTimeframe
double   g_ATR                = 0;
double   g_ATR_Avg            = 0;
double   g_RSI                = 0;
double   g_MACD_Hist          = 0;
double   g_MACD_HistPrev      = 0;
double   g_Stoch_Main         = 0;
double   g_Stoch_Sig          = 0;
double   g_Stoch_MainPrev     = 0;
double   g_BB_Upper           = 0;
double   g_BB_Lower           = 0;
double   g_BB_Mid             = 0;
double   g_BB_Width           = 0;

int      g_Signal             = 0;
int      g_TrendBias          = 0;

//+------------------------------------------------------------------+
//| Symbol detection helpers (identical engine to swing EA)          |
//+------------------------------------------------------------------+
bool IsSymbolValid(string sym)
{
   if(StringLen(sym) == 0) return false;
   double bid = MarketInfo(sym, MODE_BID);
   double ask = MarketInfo(sym, MODE_ASK);
   double ts  = MarketInfo(sym, MODE_TICKSIZE);
   return (bid > 0 && ask >= bid && ts > 0);
}

string ToUpper(string s) { string r = s; StringToUpper(r); return r; }

int ClassifyPattern(string upper)
{
   int i;
   for(i = 0; i < ArraySize(BRENT_PATTERNS); i++)
      if(StringFind(upper, BRENT_PATTERNS[i]) >= 0) return OIL_BRENT;
   for(i = 0; i < ArraySize(WTI_PATTERNS); i++)
      if(StringFind(upper, WTI_PATTERNS[i]) >= 0) return OIL_WTI;
   for(i = 0; i < ArraySize(NATGAS_PATTERNS); i++)
      if(StringFind(upper, NATGAS_PATTERNS[i]) >= 0) return OIL_NATGAS;
   return OIL_UNKNOWN;
}

string TryWithSuffixes(string base)
{
   for(int i = 0; i < ArraySize(SUFFIXES); i++)
   {
      string c = base + SUFFIXES[i];
      if(IsSymbolValid(c)) return c;
   }
   return "";
}

string ScanList(string &list[], int &outType)
{
   for(int p = 0; p < ArraySize(list); p++)
   {
      string f = TryWithSuffixes(list[p]);
      if(StringLen(f) > 0) { outType = ClassifyPattern(ToUpper(f)); return f; }
   }
   outType = OIL_UNKNOWN; return "";
}

bool DetectOilSymbol()
{
   if(StringLen(ForceSymbol) > 0)
   {
      if(!IsSymbolValid(ForceSymbol))
      { Print("ForceSymbol '", ForceSymbol, "' invalid."); return false; }
      g_WorkSymbol = ForceSymbol;
      g_OilType    = ClassifyPattern(ToUpper(ForceSymbol));
      return true;
   }

   string chart = Symbol();
   if(IsSymbolValid(chart))
   {
      int t = ClassifyPattern(ToUpper(chart));
      if(t != OIL_UNKNOWN) { g_WorkSymbol = chart; g_OilType = t; return true; }
   }

   if(!ScanAllOilSymbols)
   { Print("Chart symbol not oil. Set ForceSymbol or enable ScanAllOilSymbols."); return false; }

   int ft = OIL_UNKNOWN;
   string f = "";
   f = ScanList(BRENT_PATTERNS, ft); if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_BRENT;return true;}
   f = ScanList(WTI_PATTERNS,   ft); if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_WTI;  return true;}
   f = ScanList(NATGAS_PATTERNS,ft); if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_NATGAS;return true;}

   Print("No oil symbol found. Add to Market Watch or set ForceSymbol.");
   return false;
}

void ApplyOilDefaults()
{
   switch(g_OilType)
   {
      case OIL_BRENT:  g_OilTypeName="Brent Crude (ICE)"; g_EffSpreadMax=MaxSpreadPoints;       break;
      case OIL_WTI:    g_OilTypeName="WTI Crude (NYMEX)"; g_EffSpreadMax=MaxSpreadPoints;       break;
      case OIL_NATGAS: g_OilTypeName="Natural Gas";        g_EffSpreadMax=MaxSpreadPoints*0.4;   break;
      default:         g_OilTypeName="Oil (Unknown)";      g_EffSpreadMax=MaxSpreadPoints;       break;
   }
}

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!DetectOilSymbol()) return INIT_FAILED;
   ApplyOilDefaults();

   g_Digits   = (int)MarketInfo(g_WorkSymbol, MODE_DIGITS);
   g_TickSize = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);

   g_PeakEquity      = AccountEquity();
   g_DayStartBalance = AccountBalance();
   g_DayStartEquity  = AccountEquity();
   g_DayStartTime    = TimeCurrent();

   Print("=================================================");
   Print(" Oil Scalper Pro v1.00 — READY");
   Print(" Oil Type  : ", g_OilTypeName);
   Print(" Symbol    : ", g_WorkSymbol);
   Print(" ScalpTF   : M", ScalpTimeframe);
   Print(" TrendTF   : M", TrendTimeframe);
   Print(" MaxSpread : ", g_EffSpreadMax, " pts");
   Print("=================================================");

   if(ShowDashboard) DrawDashboard("Initializing...", NeutralColor);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "OSP_");
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   ManageOpenPositions();

   if(RequireBarClose)
   {
      datetime bt = iTime(g_WorkSymbol, ScalpTimeframe, 0);
      if(bt == g_LastBarTime) return;
      g_LastBarTime = bt;
   }

   CheckDailyReset();

   if(g_DailyLimitHit || g_DDHaltActive)
   {
      if(ShowDashboard) DrawDashboard("DAILY LIMIT — HALTED", BearColor);
      return;
   }

   if(!CheckDrawdown())                              return;
   if(CountOpenPositions() >= MaxOpenPositions)      return;
   if(!IsAllowedSession())                           return;
   if(!CheckSpread())                                return;
   if(UseNewsFilter && IsNewsTime())                 return;
   if(!CheckHourlyLimit())                           return;
   if(!CheckBarsSinceLastTrade())                    return;

   LoadIndicators();
   if(!CheckVolatility())                            return;

   g_Signal = GenerateSignal();

   if(g_Signal != 0)
      ExecuteEntry(g_Signal);

   if(ShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Load indicators (M5 + M30 trend)                                 |
//+------------------------------------------------------------------+
void LoadIndicators()
{
   // Scalp timeframe
   g_EMA_Fast  = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Fast,  0, MA_Method, MA_Price, 1);
   g_EMA_Mid   = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Mid,   0, MA_Method, MA_Price, 1);
   g_EMA_Slow  = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Slow,  0, MA_Method, MA_Price, 1);
   g_EMA_Trend = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Trend, 0, MA_Method, MA_Price, 1);

   // Trend timeframe bias EMA
   g_TrendEMA_Trend = iMA(g_WorkSymbol, TrendTimeframe, EMA_Trend, 0, MA_Method, MA_Price, 1);

   // ATR
   g_ATR = iATR(g_WorkSymbol, ScalpTimeframe, ATR_Period, 1);
   double atrSum = 0;
   for(int i = 1; i <= 30; i++) atrSum += iATR(g_WorkSymbol, ScalpTimeframe, ATR_Period, i);
   g_ATR_Avg = atrSum / 30.0;

   // RSI
   g_RSI = iRSI(g_WorkSymbol, ScalpTimeframe, RSI_Period, MA_Price, 1);

   // MACD
   double macdMain  = iMACD(g_WorkSymbol, ScalpTimeframe, MACD_Fast, MACD_Slow, MACD_Sig, MA_Price, MODE_MAIN,   1);
   double macdSig   = iMACD(g_WorkSymbol, ScalpTimeframe, MACD_Fast, MACD_Slow, MACD_Sig, MA_Price, MODE_SIGNAL, 1);
   double macdMain2 = iMACD(g_WorkSymbol, ScalpTimeframe, MACD_Fast, MACD_Slow, MACD_Sig, MA_Price, MODE_MAIN,   2);
   double macdSig2  = iMACD(g_WorkSymbol, ScalpTimeframe, MACD_Fast, MACD_Slow, MACD_Sig, MA_Price, MODE_SIGNAL, 2);
   g_MACD_Hist     = macdMain  - macdSig;
   g_MACD_HistPrev = macdMain2 - macdSig2;

   // Stochastic
   g_Stoch_Main     = iStochastic(g_WorkSymbol, ScalpTimeframe, Stoch_K, Stoch_D, Stoch_Slow, MODE_SMA, 0, MODE_MAIN,   1);
   g_Stoch_Sig      = iStochastic(g_WorkSymbol, ScalpTimeframe, Stoch_K, Stoch_D, Stoch_Slow, MODE_SMA, 0, MODE_SIGNAL, 1);
   g_Stoch_MainPrev = iStochastic(g_WorkSymbol, ScalpTimeframe, Stoch_K, Stoch_D, Stoch_Slow, MODE_SMA, 0, MODE_MAIN,   2);

   // Bollinger Bands
   g_BB_Upper = iBands(g_WorkSymbol, ScalpTimeframe, BB_Period, BB_Dev, 0, MA_Price, MODE_UPPER, 1);
   g_BB_Lower = iBands(g_WorkSymbol, ScalpTimeframe, BB_Period, BB_Dev, 0, MA_Price, MODE_LOWER, 1);
   g_BB_Mid   = iBands(g_WorkSymbol, ScalpTimeframe, BB_Period, BB_Dev, 0, MA_Price, MODE_MAIN,  1);
   g_BB_Width = g_BB_Upper - g_BB_Lower;

   // Trend bias from higher TF
   double closeTrend = iClose(g_WorkSymbol, TrendTimeframe, 1);
   double closeScalp = iClose(g_WorkSymbol, ScalpTimeframe, 1);
   double trendFastEMA = iMA(g_WorkSymbol, TrendTimeframe, EMA_Fast, 0, MA_Method, MA_Price, 1);

   if(closeTrend > g_TrendEMA_Trend && trendFastEMA > g_TrendEMA_Trend)
      g_TrendBias = 1;
   else if(closeTrend < g_TrendEMA_Trend && trendFastEMA < g_TrendEMA_Trend)
      g_TrendBias = -1;
   else
      g_TrendBias = 0;
}

//+------------------------------------------------------------------+
//| Generate scalping signal                                         |
//+------------------------------------------------------------------+
int GenerateSignal()
{
   double close1 = iClose(g_WorkSymbol, ScalpTimeframe, 1);
   double close2 = iClose(g_WorkSymbol, ScalpTimeframe, 2);
   double high1  = iHigh (g_WorkSymbol, ScalpTimeframe, 1);
   double low1   = iLow  (g_WorkSymbol, ScalpTimeframe, 1);
   double high2  = iHigh (g_WorkSymbol, ScalpTimeframe, 2);
   double low2   = iLow  (g_WorkSymbol, ScalpTimeframe, 2);

   double fastPrev = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Fast, 0, MA_Method, MA_Price, 2);
   double midPrev  = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Mid,  0, MA_Method, MA_Price, 2);

   int signal = 0;

   // ------------------------------------------------------------------
   // STRATEGY 1: FAST EMA CROSSOVER
   // 3 EMA crosses 8 EMA, price above/below 21 EMA, M30 trend aligned
   // ------------------------------------------------------------------
   if(EnableFastEMAScalp && signal == 0)
   {
      bool crossUp   = (fastPrev <= midPrev) && (g_EMA_Fast > g_EMA_Mid);
      bool crossDown = (fastPrev >= midPrev) && (g_EMA_Fast < g_EMA_Mid);

      bool aboveSlow = (close1 > g_EMA_Slow);
      bool belowSlow = (close1 < g_EMA_Slow);

      if(crossUp   && aboveSlow && g_RSI > RSI_Bull && g_RSI < RSI_OB &&
         (!g_TrendBias || g_TrendBias == 1))
         signal = 1;

      if(crossDown && belowSlow && g_RSI < RSI_Bear && g_RSI > RSI_OS &&
         (!g_TrendBias || g_TrendBias == -1))
         signal = -1;
   }

   // ------------------------------------------------------------------
   // STRATEGY 2: RSI 50 CROSS + MACD HISTOGRAM FLIP
   // RSI crosses 50 while MACD histogram changes sign
   // ------------------------------------------------------------------
   if(EnableMomentumScalp && signal == 0)
   {
      double rsiPrev = iRSI(g_WorkSymbol, ScalpTimeframe, RSI_Period, MA_Price, 2);

      bool rsiBull = (rsiPrev < 50.0) && (g_RSI >= 50.0) && g_RSI < RSI_OB;
      bool rsiBear = (rsiPrev > 50.0) && (g_RSI <= 50.0) && g_RSI > RSI_OS;
      bool macdFlipBull = (g_MACD_HistPrev < 0) && (g_MACD_Hist > 0);
      bool macdFlipBear = (g_MACD_HistPrev > 0) && (g_MACD_Hist < 0);

      if(rsiBull && macdFlipBull && close1 > g_EMA_Slow &&
         (!g_TrendBias || g_TrendBias == 1))
         signal = 1;

      if(rsiBear && macdFlipBear && close1 < g_EMA_Slow &&
         (!g_TrendBias || g_TrendBias == -1))
         signal = -1;
   }

   // ------------------------------------------------------------------
   // STRATEGY 3: STOCHASTIC REVERSAL
   // Stoch crosses out of OS/OB zone — strongest mean-reversion scalp
   // ------------------------------------------------------------------
   if(EnableStochScalp && signal == 0)
   {
      bool stochCrossUpFromOS   = (g_Stoch_MainPrev < Stoch_OS) && (g_Stoch_Main >= Stoch_OS) &&
                                  (g_Stoch_Main > g_Stoch_Sig);
      bool stochCrossDownFromOB = (g_Stoch_MainPrev > Stoch_OB) && (g_Stoch_Main <= Stoch_OB) &&
                                  (g_Stoch_Main < g_Stoch_Sig);

      if(stochCrossUpFromOS   && g_RSI > RSI_OS && g_MACD_Hist > g_MACD_HistPrev)
         signal = 1;

      if(stochCrossDownFromOB && g_RSI < RSI_OB && g_MACD_Hist < g_MACD_HistPrev)
         signal = -1;
   }

   // ------------------------------------------------------------------
   // STRATEGY 4: BOLLINGER BAND TOUCH + REJECTION (mean reversion)
   // Price touches the outer BB and the candle body rejects it
   // ------------------------------------------------------------------
   if(EnableBBMeanReversion && signal == 0)
   {
      double buffer = g_ATR * BB_TouchBuffer;

      // Bullish: price touched lower BB and closed back above it (pin bar / hammer)
      bool touchedLower = (low1 <= g_BB_Lower + buffer);
      bool rejectedUp   = (close1 > g_BB_Lower) && (close1 > iOpen(g_WorkSymbol, ScalpTimeframe, 1));

      // Bearish: price touched upper BB and closed back below it
      bool touchedUpper = (high1 >= g_BB_Upper - buffer);
      bool rejectedDown = (close1 < g_BB_Upper) && (close1 < iOpen(g_WorkSymbol, ScalpTimeframe, 1));

      // Only mean-revert when stoch is at extreme and trend is not strongly opposing
      if(touchedLower && rejectedUp  && g_Stoch_Main < Stoch_MidOS &&
         g_RSI > RSI_OS && g_TrendBias != -1)
         signal = 1;

      if(touchedUpper && rejectedDown && g_Stoch_Main > Stoch_MidOB &&
         g_RSI < RSI_OB && g_TrendBias != 1)
         signal = -1;
   }

   // ------------------------------------------------------------------
   // STRATEGY 5: M5 BAR HIGH/LOW BREAKOUT
   // Current bar breaks above/below the previous bar's high/low with
   // momentum confirmation — catches impulsive scalp moves
   // ------------------------------------------------------------------
   if(EnableBreakoutScalp && signal == 0)
   {
      double curClose = iClose(g_WorkSymbol, ScalpTimeframe, 0); // Live close
      double ask      = MarketInfo(g_WorkSymbol, MODE_ASK);
      double bid      = MarketInfo(g_WorkSymbol, MODE_BID);

      bool breakHigh = (ask > high2 + g_ATR * 0.1); // Small buffer above prev high
      bool breakLow  = (bid < low2  - g_ATR * 0.1);

      // Need EMA alignment and momentum for breakout validity
      if(breakHigh && g_EMA_Fast > g_EMA_Mid && g_EMA_Mid > g_EMA_Slow &&
         g_MACD_Hist > 0 && g_RSI > 50.0 && g_RSI < RSI_OB &&
         (!g_TrendBias || g_TrendBias == 1))
         signal = 1;

      if(breakLow  && g_EMA_Fast < g_EMA_Mid && g_EMA_Mid < g_EMA_Slow &&
         g_MACD_Hist < 0 && g_RSI < 50.0 && g_RSI > RSI_OS &&
         (!g_TrendBias || g_TrendBias == -1))
         signal = -1;
   }

   // Hard block: never enter if stoch is at the extreme in the wrong direction
   if(signal ==  1 && g_Stoch_Main > Stoch_OB) signal = 0;
   if(signal == -1 && g_Stoch_Main < Stoch_OS)  signal = 0;

   return signal;
}

//+------------------------------------------------------------------+
//| Open entry order                                                  |
//+------------------------------------------------------------------+
void ExecuteEntry(int dir)
{
   double ask = MarketInfo(g_WorkSymbol, MODE_ASK);
   double bid = MarketInfo(g_WorkSymbol, MODE_BID);
   double atr = g_ATR;

   double entry, sl, tp1, tp2;

   if(dir == 1)
   {
      entry = ask;
      sl    = NormalizeDouble(ask - atr * ATR_SL_Mult,  g_Digits);
      tp1   = NormalizeDouble(ask + atr * ATR_TP1_Mult, g_Digits);
      tp2   = NormalizeDouble(ask + atr * ATR_TP2_Mult, g_Digits);
   }
   else
   {
      entry = bid;
      sl    = NormalizeDouble(bid + atr * ATR_SL_Mult,  g_Digits);
      tp1   = NormalizeDouble(bid - atr * ATR_TP1_Mult, g_Digits);
      tp2   = NormalizeDouble(bid - atr * ATR_TP2_Mult, g_Digits);
   }

   double minDist = MarketInfo(g_WorkSymbol, MODE_STOPLEVEL) * g_TickSize;
   if(MathAbs(entry - sl) < minDist)
      sl = (dir == 1) ? entry - minDist : entry + minDist;

   double lots = CalcLots(entry, sl);
   if(lots <= 0) return;

   string cmt = TradeComment + "|TP1=" + DoubleToStr(tp1, g_Digits);
   int    cmd = (dir == 1) ? OP_BUY : OP_SELL;
   double prc = (dir == 1) ? ask : bid;

   int ticket = OrderSend(g_WorkSymbol, cmd, lots, prc, MaxSlippage,
                          sl, tp2, cmt, MagicNumber, 0,
                          (dir == 1) ? BullColor : BearColor);

   if(ticket > 0)
   {
      g_TradesToday++;
      g_HourTradeCount++;
      g_LastTradeBarTime = iTime(g_WorkSymbol, ScalpTimeframe, 0);
      Print("Scalp opened | ", g_OilTypeName, " | #", ticket,
            " | ", (dir==1?"BUY":"SELL"),
            " | Lots:", lots, " | SL:", sl, " | TP2:", tp2,
            " | ATR:", DoubleToStr(atr, g_Digits));
   }
   else
   {
      int err = GetLastError();
      Print("OrderSend FAILED | Error:", err, " | ", ScalpErrDesc(err));
   }
}

//+------------------------------------------------------------------+
//| Dynamic lot sizing                                               |
//+------------------------------------------------------------------+
double CalcLots(double entry, double sl)
{
   double balance  = AccountBalance();
   double risk     = balance * RiskPercent / 100.0;
   double slDist   = MathAbs(entry - sl);
   if(slDist <= 0) return MinLotSize;

   double tv       = MarketInfo(g_WorkSymbol, MODE_TICKVALUE);
   double ts       = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);
   double step     = MarketInfo(g_WorkSymbol, MODE_LOTSTEP);
   double minLot   = MarketInfo(g_WorkSymbol, MODE_MINLOT);
   double maxLot   = MarketInfo(g_WorkSymbol, MODE_MAXLOT);

   if(tv <= 0 || ts <= 0) return minLot;

   double slVal = (slDist / ts) * tv;
   double raw   = risk / slVal;
   double lots  = MathFloor(raw / step) * step;

   lots = MathMax(lots, MathMax(minLot, MinLotSize));
   lots = MathMin(lots, MathMin(maxLot, MaxLotSize));
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Manage positions: partial close, break-even, tight trail        |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber)           continue;
      if(OrderSymbol() != g_WorkSymbol)               continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      double openPx  = OrderOpenPrice();
      double curSL   = OrderStopLoss();
      double curTP   = OrderTakeProfit();
      double ask     = MarketInfo(g_WorkSymbol, MODE_ASK);
      double bid     = MarketInfo(g_WorkSymbol, MODE_BID);
      double curPx   = (OrderType() == OP_BUY) ? bid : ask;
      double atr     = iATR(g_WorkSymbol, ScalpTimeframe, ATR_Period, 1);
      double ts      = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);
      double minSD   = MarketInfo(g_WorkSymbol, MODE_STOPLEVEL) * ts;
      double profPt  = (OrderType() == OP_BUY) ? (curPx - openPx) : (openPx - curPx);
      string cmt     = OrderComment();

      // Parse TP1
      double tp1 = 0;
      int p1 = StringFind(cmt, "TP1=");
      if(p1 >= 0) tp1 = StrToDouble(StringSubstr(cmt, p1 + 4));

      bool tp1Hit = (tp1 > 0) &&
                    ((OrderType() == OP_BUY  && curPx >= tp1) ||
                     (OrderType() == OP_SELL && curPx <= tp1));

      // --- PARTIAL CLOSE at TP1 ---
      if(UsePartialClose && tp1Hit && StringFind(cmt, "PC1") < 0)
      {
         double step    = MarketInfo(g_WorkSymbol, MODE_LOTSTEP);
         double minLot  = MarketInfo(g_WorkSymbol, MODE_MINLOT);
         double pLots   = NormalizeDouble(OrderLots() * PartialClosePct / 100.0, 2);
         pLots          = MathFloor(pLots / step) * step;
         if(pLots >= minLot && pLots < OrderLots())
            if(OrderClose(OrderTicket(), pLots, curPx, MaxSlippage, clrYellow))
               Print("Partial close TP1 | #", OrderTicket(), " | Lots:", pLots);
      }

      // --- BREAK-EVEN ---
      if(UseBreakEven && tp1Hit)
      {
         double beBuffer = atr * BreakEvenBuffer_ATR;
         double beSL;
         bool   doMod = false;
         if(OrderType() == OP_BUY)
         {
            beSL = NormalizeDouble(openPx + beBuffer, g_Digits);
            if(beSL > curSL + ts && beSL < curPx - minSD) doMod = true;
         }
         else
         {
            beSL = NormalizeDouble(openPx - beBuffer, g_Digits);
            if(beSL < curSL - ts && beSL > curPx + minSD) doMod = true;
         }
         if(doMod)
            if(OrderModify(OrderTicket(), openPx, beSL, curTP, 0, clrGold))
               Print("Break-even | #", OrderTicket(), " SL:", beSL);
      }

      // --- TIGHT TRAILING STOP ---
      if(UseTrailingStop && profPt >= atr * TrailActivate_ATR_Mult)
      {
         double trail = atr * TrailATR_Mult;
         double tSL;
         bool   doTrail = false;
         if(OrderType() == OP_BUY)
         {
            tSL = NormalizeDouble(curPx - trail, g_Digits);
            if(tSL > curSL + ts && tSL < curPx - minSD) doTrail = true;
         }
         else
         {
            tSL = NormalizeDouble(curPx + trail, g_Digits);
            if(tSL < curSL - ts && tSL > curPx + minSD) doTrail = true;
         }
         if(doTrail)
            if(OrderModify(OrderTicket(), openPx, tSL, curTP, 0, clrCyan))
               Print("Trail stop | #", OrderTicket(), " SL:", tSL);
      }
   }
}

//+------------------------------------------------------------------+
//| Session filter (oil scalping hours only)                        |
//+------------------------------------------------------------------+
bool IsAllowedSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int dow  = dt.day_of_week;
   int gmtH = (dt.hour - SessionGMTOffset + 24) % 24;

   if(SkipWeekend   && (dow == 0 || dow == 6))    return false;
   if(SkipMonday0500 && dow == 1 && gmtH < 5)     return false;
   if(SkipFriday1700 && dow == 5 && gmtH >= 17)   return false;

   if(TradeLondonOpen && gmtH >= 7  && gmtH < 9)  return true;
   if(TradeLondonCore && gmtH >= 9  && gmtH < 13) return true;
   if(TradeNYOverlap  && gmtH >= 13 && gmtH < 17) return true;
   if(TradeNYSession  && gmtH >= 17 && gmtH < 21) return true;
   if(TradeAsian      && gmtH >= 0  && gmtH < 7)  return true;
   return false;
}

//+------------------------------------------------------------------+
//| News filter                                                      |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int dow  = dt.day_of_week;
   int gmtH = (dt.hour - SessionGMTOffset + 24) % 24;
   int tot  = gmtH * 60 + dt.min;

   if(FilterEIA  && dow == 3) { int t=14*60+30; if(tot>=t-NewsMinBefore && tot<=t+NewsMinAfter) return true; }
   if(FilterAPI  && dow == 2) { int t=20*60+30; if(tot>=t-NewsMinBefore && tot<=t+NewsMinAfter) return true; }
   if(FilterFOMC && dow == 3) { int t=19*60+0;  if(tot>=t-NewsMinBefore && tot<=t+NewsMinAfter) return true; }
   if(FilterNFP  && dow == 5) { int t=13*60+30; if(tot>=t && tot<=t+60)                         return true; }
   return false;
}

//+------------------------------------------------------------------+
//| Spread check                                                     |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   return (MarketInfo(g_WorkSymbol, MODE_SPREAD) <= g_EffSpreadMax);
}

//+------------------------------------------------------------------+
//| Volatility guard                                                 |
//+------------------------------------------------------------------+
bool CheckVolatility()
{
   if(g_ATR <= 0 || g_ATR_Avg <= 0)                    return false;
   if(g_ATR < g_ATR_Avg * ATR_Min_Mult)                return false;
   if(g_ATR > g_ATR_Avg * ATR_Max_Mult)                return false;
   return true;
}

//+------------------------------------------------------------------+
//| Drawdown check                                                   |
//+------------------------------------------------------------------+
bool CheckDrawdown()
{
   double eq = AccountEquity();
   if(eq > g_PeakEquity) g_PeakEquity = eq;
   double dd = (g_PeakEquity > 0) ? (g_PeakEquity - eq) / g_PeakEquity * 100.0 : 0;
   if(dd >= MaxDrawdownPct)
   {
      if(!g_DDHaltActive) { Print("DRAWDOWN HALT: ", DoubleToStr(dd,2), "%"); g_DDHaltActive = true; }
      if(ShowDashboard) DrawDashboard("DD HALT: "+DoubleToStr(dd,1)+"%", BearColor);
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Hourly trade limit                                               |
//+------------------------------------------------------------------+
bool CheckHourlyLimit()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour != g_CurrentHour) { g_CurrentHour = dt.hour; g_HourTradeCount = 0; }
   return (g_HourTradeCount < MaxTradesPerHour);
}

//+------------------------------------------------------------------+
//| Bars since last trade guard (prevent back-to-back overtrading)  |
//+------------------------------------------------------------------+
bool CheckBarsSinceLastTrade()
{
   if(g_LastTradeBarTime == 0) return true;
   datetime cur = iTime(g_WorkSymbol, ScalpTimeframe, 0);
   int barsPassed = 0;
   for(int b = 0; b < MinBarsSinceLastTrade + 1; b++)
      if(iTime(g_WorkSymbol, ScalpTimeframe, b) <= g_LastTradeBarTime) { barsPassed = b; break; }
   return (barsPassed >= MinBarsSinceLastTrade);
}

//+------------------------------------------------------------------+
//| Daily reset                                                      |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   MqlDateTime now, start;
   TimeToStruct(TimeCurrent(),  now);
   TimeToStruct(g_DayStartTime, start);

   if(now.day != start.day || now.mon != start.mon)
   {
      g_DayStartTime    = TimeCurrent();
      g_DayStartBalance = AccountBalance();
      g_DayStartEquity  = AccountEquity();
      g_TradesToday     = 0;
      g_DailyLimitHit   = false;
      g_HourTradeCount  = 0;
      Print("Daily reset | Balance:", g_DayStartBalance);
   }

   if(g_TradesToday >= MaxTradesPerDay && !g_DailyLimitHit)
   { g_DailyLimitHit = true; Print("Daily trade limit: ", MaxTradesPerDay); return; }

   if(g_DayStartBalance > 0)
   {
      double pnl = (AccountEquity() - g_DayStartEquity) / g_DayStartBalance * 100.0;
      if(pnl <= -MaxDailyLossPct && !g_DailyLimitHit)
      { g_DailyLimitHit = true; Print("Daily LOSS limit: ", DoubleToStr(pnl,2), "%"); }
      if(pnl >= MaxDailyProfitPct && !g_DailyLimitHit)
      { g_DailyLimitHit = true; Print("Daily PROFIT target: ", DoubleToStr(pnl,2), "%"); }
   }
}

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
//| Dashboard                                                        |
//+------------------------------------------------------------------+
void DrawDashboard(string status, color clr)
{
   string tBias = (g_TrendBias == 1) ? "BULL" : (g_TrendBias == -1) ? "BEAR" : "FLAT";
   string sig   = (g_Signal == 1) ? "BUY" : (g_Signal == -1) ? "SELL" : "NONE";

   double eq  = AccountEquity();
   double bal = AccountBalance();
   double pnl = eq - g_DayStartEquity;
   double dd  = (g_PeakEquity > 0) ? (g_PeakEquity - eq) / g_PeakEquity * 100.0 : 0;

   string nl = "\n";
   string d  = nl;
   d += "=== OIL SCALPER PRO v1.00 ===" + nl;
   d += "Type    : " + g_OilTypeName + nl;
   d += "Symbol  : " + g_WorkSymbol  + nl;
   d += "Status  : " + status        + nl;
   d += "Trend   : " + tBias + " (" + IntegerToString(TrendTimeframe) + "m) | Signal: " + sig + nl;
   d += "ATR     : " + DoubleToStr(g_ATR,     g_Digits)
      + "  Avg: " + DoubleToStr(g_ATR_Avg, g_Digits) + nl;
   d += "RSI(7)  : " + DoubleToStr(g_RSI,        1) + nl;
   d += "Stoch   : " + DoubleToStr(g_Stoch_Main, 1)
      + " / " + DoubleToStr(g_Stoch_Sig,  1) + nl;
   d += "MACD H  : " + DoubleToStr(g_MACD_Hist, 5) + nl;
   d += "Balance : " + DoubleToStr(bal, 2)
      + "  Equity: " + DoubleToStr(eq, 2) + nl;
   d += "DayPnL  : " + DoubleToStr(pnl, 2)
      + "  DD: "    + DoubleToStr(dd,  2) + "%" + nl;
   d += "Trades  : " + IntegerToString(g_TradesToday) + "/" + IntegerToString(MaxTradesPerDay)
      + "  Hour: " + IntegerToString(g_HourTradeCount) + "/" + IntegerToString(MaxTradesPerHour) + nl;
   d += "Open Pos: " + IntegerToString(CountOpenPositions()) + "/" + IntegerToString(MaxOpenPositions) + nl;
   d += "Spread  : " + DoubleToStr(MarketInfo(g_WorkSymbol, MODE_SPREAD), 1)
      + " / max " + DoubleToStr(g_EffSpreadMax, 1) + nl;
   d += "Session : " + (IsAllowedSession() ? "ACTIVE" : "CLOSED") + nl;
   d += "News    : " + (UseNewsFilter && IsNewsTime() ? "BLOCKED" : "CLEAR") + nl;

   Comment(d);
}

void UpdateDashboard() { DrawDashboard("RUNNING", BullColor); }

string ScalpErrDesc(int code)
{
   switch(code)
   {
      case 129: return "Invalid price";
      case 130: return "Invalid stops";
      case 131: return "Invalid volume";
      case 132: return "Market closed";
      case 133: return "Trading disabled";
      case 134: return "Not enough money";
      case 135: return "Price changed";
      case 136: return "Off quotes";
      case 138: return "Requote";
      case 145: return "SL/TP too close";
      case 146: return "Trade context busy";
      default:  return "Error " + IntegerToString(code);
   }
}
//+------------------------------------------------------------------+
