//+------------------------------------------------------------------+
//|                                          Oil_Scalper_Pro.mq4     |
//|                    Universal Crude Oil Scalping System v2         |
//|        Brent | WTI | Natural Gas  —  Any Broker Symbol           |
//+------------------------------------------------------------------+
#property copyright "Professional Oil Trading Systems"
#property version   "2.00"
#property strict
#property description "Universal Oil Scalper v2: M15 entry | H1 trend bias"
#property description "EMA cross (5/13) + MACD histogram flip strategies"
#property description "ADX trending filter | Weekly DD cap | 2.5:1 RR"

//=== TIMEFRAMES ===
input string          ___TF___           = "========== TIMEFRAMES ==========";
input ENUM_TIMEFRAMES ScalpTimeframe     = PERIOD_M15;  // Entry signals
input ENUM_TIMEFRAMES TrendTimeframe     = PERIOD_H1;   // H1 trend bias

//=== EMA SETTINGS ===
input string ___EMA___                  = "========== EMAs ==========";
input int    EMA_Fast                   = 5;    // Fast EMA (crosses medium for entry)
input int    EMA_Med                    = 13;   // Medium EMA (cross target)
input int    EMA_Slow                   = 50;   // Slow EMA (trend gate on both TFs)

//=== ADX ===
input string ___ADX___                  = "========== ADX FILTER ==========";
input int    ADX_Period                 = 14;
input double ADX_MinTrend               = 18.0; // Skip if ADX < 18 (ranging/choppy)

//=== MACD ===
input string ___MACD___                 = "========== MACD ==========";
input int    MACD_Fast                  = 8;
input int    MACD_Slow                  = 17;
input int    MACD_Sig                   = 5;

//=== RSI ===
input string ___RSI___                  = "========== RSI ==========";
input int    RSI_Period                 = 14;
input double RSI_Bull                   = 45.0; // Long requires RSI > 45
input double RSI_Bear                   = 55.0; // Short requires RSI < 55
input double RSI_OB                     = 70.0;
input double RSI_OS                     = 30.0;

//=== ATR ===
input string ___ATR___                  = "========== ATR ==========";
input int    ATR_Period                 = 14;
input double ATR_SL_Mult               = 1.4;  // Stop loss = 1.4x ATR
input double ATR_TP_Mult               = 3.5;  // TP = 3.5x ATR → 2.5:1 RR
input double ATR_Trail_Mult            = 1.0;  // Trailing stop = 1.0x ATR
input double ATR_TrailActivate_Mult    = 2.0;  // Activate trailing after 2.0x ATR profit

//=== RISK MANAGEMENT ===
input string ___RISK___                 = "========== RISK MANAGEMENT ==========";
input double RiskPercent                = 0.8;  // Risk per trade (% of balance)
input double MaxLotSize                 = 5.0;
input double MinLotSize                 = 0.01;
input bool   UseTrailingStop            = true;

//=== WEEKLY DD CAP ===
input string ___WEEKLY___               = "========== WEEKLY DRAWDOWN CAP ==========";
input double WeeklyDDCapPct             = 6.0;  // Stop trading if weekly equity drops 6%
// Automatically resets each Monday — no permanent shutdown

//=== DAILY & HOURLY LIMITS ===
input string ___LIMITS___               = "========== TRADE LIMITS ==========";
input double MaxDailyLossPct            = 3.0;
input int    MaxTradesPerDay            = 5;
input int    MaxTradesPerHour           = 2;
input int    MaxOpenPositions           = 1;

//=== SESSION FILTER ===
input string ___SESSIONS___             = "========== SCALPING SESSIONS ==========";
input bool   TradeLondonOpen            = true;  // 07:00-09:00 GMT
input bool   TradeLondonCore            = true;  // 09:00-13:00 GMT
input bool   TradeNYOverlap             = true;  // 13:00-17:00 GMT
input bool   TradeNYSession             = false; // 17:00-21:00 GMT
input bool   TradeAsian                 = false; // 00:00-07:00 GMT
input int    SessionGMTOffset           = 0;
input bool   SkipFriday1700             = true;
input bool   SkipMonday0500             = true;
input bool   SkipWeekend               = true;

//=== NEWS FILTER ===
input string ___NEWS___                 = "========== NEWS FILTER ==========";
input bool   UseNewsFilter              = true;
input int    NewsMinBefore              = 45;
input int    NewsMinAfter               = 45;
input bool   FilterEIA                  = true;
input bool   FilterAPI                  = true;
input bool   FilterNFP                  = true;
input bool   FilterFOMC                 = true;

//=== SPREAD & EXECUTION ===
input string ___EXEC___                 = "========== EXECUTION ==========";
input double MaxSpreadPoints            = 25.0;
input int    MaxSlippage                = 10;
input int    MinBarsSinceLastTrade      = 3;    // Bars between scalp entries

//=== POSITION ===
input string ___POSITION___             = "========== POSITION ==========";
input int    MagicNumber                = 303600;
input string TradeComment               = "OilScalp2";

//=== SYMBOL ===
input string ___SYMBOL___               = "========== SYMBOL ==========";
input string ForceSymbol                = "";
input bool   ScanAllOilSymbols          = true;

//=== DISPLAY ===
input string ___DISPLAY___              = "========== DASHBOARD ==========";
input bool   ShowDashboard              = true;
input color  BullColor                  = clrDodgerBlue;
input color  BearColor                  = clrOrangeRed;
input color  NeutralColor               = clrGray;

//+------------------------------------------------------------------+
//| Oil type constants                                                |
//+------------------------------------------------------------------+
#define OIL_UNKNOWN  0
#define OIL_BRENT    1
#define OIL_WTI      2
#define OIL_NATGAS   3

//+------------------------------------------------------------------+
//| Known symbol patterns                                            |
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
bool     g_DailyLimitHit      = false;

// Weekly DD state
double   g_WeekBalance        = 0;
bool     g_WeekHalted         = false;
int      g_CurrentWeekYear    = -1;
int      g_CurrentWeekNum     = -1;

string   g_WorkSymbol         = "";
int      g_OilType            = OIL_UNKNOWN;
string   g_OilTypeName        = "Unknown";
int      g_Digits             = 2;
double   g_TickSize           = 0.01;
double   g_EffSpreadMax       = 25.0;

// Cached indicators (M15 scalp TF)
double   g_EMA_Fast           = 0;
double   g_EMA_Med            = 0;
double   g_EMA_Slow           = 0;
double   g_EMA_FastPrev       = 0;
double   g_EMA_MedPrev        = 0;
double   g_ATR                = 0;
double   g_RSI                = 0;
double   g_MACD_Hist          = 0;
double   g_MACD_HistPrev      = 0;
double   g_ADX                = 0;

// H1 trend context
int      g_H1Bias             = 0;  // 1=bull, -1=bear, 0=flat

int      g_Signal             = 0;

//+------------------------------------------------------------------+
//| Symbol detection helpers                                         |
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
   f = ScanList(BRENT_PATTERNS, ft); if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_BRENT; return true;}
   f = ScanList(WTI_PATTERNS,   ft); if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_WTI;   return true;}
   f = ScanList(NATGAS_PATTERNS,ft); if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_NATGAS; return true;}

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

   g_DayStartBalance = AccountBalance();
   g_DayStartEquity  = AccountEquity();
   g_DayStartTime    = TimeCurrent();

   // Initialize weekly DD tracking
   g_WeekBalance  = AccountBalance();
   g_WeekHalted   = false;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   g_CurrentWeekYear = dt.year;
   g_CurrentWeekNum  = GetWeekNumber(TimeCurrent());

   Print("=================================================");
   Print(" Oil Scalper Pro v2.00 — READY");
   Print(" Oil Type  : ", g_OilTypeName);
   Print(" Symbol    : ", g_WorkSymbol);
   Print(" ScalpTF   : M", ScalpTimeframe);
   Print(" TrendTF   : H", TrendTimeframe);
   Print(" EMA       : ", EMA_Fast, "/", EMA_Med, "/", EMA_Slow);
   Print(" ATR SL    : ", ATR_SL_Mult, "x | TP: ", ATR_TP_Mult, "x");
   Print(" Weekly DD : ", WeeklyDDCapPct, "% cap (resets Monday)");
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
//| Week number helper (ISO week)                                    |
//+------------------------------------------------------------------+
int GetWeekNumber(datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   // Simple week number: day-of-year / 7
   int doy = dt.day_of_year;
   return (doy / 7);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   ManageOpenPositions();

   // Bar-close mode — only fire on new M15 bar
   datetime bt = iTime(g_WorkSymbol, ScalpTimeframe, 0);
   if(bt == g_LastBarTime) return;
   g_LastBarTime = bt;

   CheckDailyReset();
   CheckWeeklyReset();

   if(g_DailyLimitHit)
   {
      if(ShowDashboard) DrawDashboard("DAILY LIMIT — HALTED", BearColor);
      return;
   }
   if(g_WeekHalted)
   {
      if(ShowDashboard) DrawDashboard("WEEKLY DD CAP — HALTED", BearColor);
      return;
   }

   if(CountOpenPositions() >= MaxOpenPositions) return;
   if(!IsAllowedSession())                       return;
   if(!CheckSpread())                             return;
   if(UseNewsFilter && IsNewsTime())              return;
   if(!CheckHourlyLimit())                        return;
   if(!CheckBarsSinceLastTrade())                 return;

   LoadIndicators();

   if(g_ADX < ADX_MinTrend) return;  // ADX filter: skip choppy/ranging markets
   if(g_H1Bias == 0)        return;  // No clear H1 trend

   g_Signal = GenerateSignal();

   if(g_Signal != 0)
      ExecuteEntry(g_Signal);

   if(ShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Load M15 indicators + H1 trend context                          |
//+------------------------------------------------------------------+
void LoadIndicators()
{
   // M15 scalp timeframe EMAs
   g_EMA_Fast     = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 1);
   g_EMA_Med      = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Med,  0, MODE_EMA, PRICE_CLOSE, 1);
   g_EMA_Slow     = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 1);
   g_EMA_FastPrev = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 2);
   g_EMA_MedPrev  = iMA(g_WorkSymbol, ScalpTimeframe, EMA_Med,  0, MODE_EMA, PRICE_CLOSE, 2);

   // ATR on M15
   g_ATR = iATR(g_WorkSymbol, ScalpTimeframe, ATR_Period, 1);

   // RSI on M15
   g_RSI = iRSI(g_WorkSymbol, ScalpTimeframe, RSI_Period, PRICE_CLOSE, 1);

   // MACD histogram on M15 (bars 1 and 2)
   double mMain1 = iMACD(g_WorkSymbol, ScalpTimeframe, MACD_Fast, MACD_Slow, MACD_Sig, PRICE_CLOSE, MODE_MAIN,   1);
   double mSig1  = iMACD(g_WorkSymbol, ScalpTimeframe, MACD_Fast, MACD_Slow, MACD_Sig, PRICE_CLOSE, MODE_SIGNAL, 1);
   double mMain2 = iMACD(g_WorkSymbol, ScalpTimeframe, MACD_Fast, MACD_Slow, MACD_Sig, PRICE_CLOSE, MODE_MAIN,   2);
   double mSig2  = iMACD(g_WorkSymbol, ScalpTimeframe, MACD_Fast, MACD_Slow, MACD_Sig, PRICE_CLOSE, MODE_SIGNAL, 2);
   g_MACD_Hist     = mMain1 - mSig1;
   g_MACD_HistPrev = mMain2 - mSig2;

   // ADX on M15
   g_ADX = iADX(g_WorkSymbol, ScalpTimeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, 1);

   // H1 trend bias: close > 50 EMA AND fast (5) EMA > 50 EMA
   double h1Close  = iClose(g_WorkSymbol, TrendTimeframe, 1);
   double h1Slow   = iMA(g_WorkSymbol, TrendTimeframe, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 1);
   double h1Fast   = iMA(g_WorkSymbol, TrendTimeframe, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 1);

   if(h1Close > h1Slow && h1Fast > h1Slow)
      g_H1Bias = 1;   // Bull
   else if(h1Close < h1Slow && h1Fast < h1Slow)
      g_H1Bias = -1;  // Bear
   else
      g_H1Bias = 0;
}

//+------------------------------------------------------------------+
//| Generate scalping signal (2 strategies)                         |
//+------------------------------------------------------------------+
int GenerateSignal()
{
   double c1  = iClose(g_WorkSymbol, ScalpTimeframe, 1);

   // ---------------------------------------------------------------
   // STRATEGY 1: EMA CROSS (5 EMA crosses 13 EMA)
   // H1 trend aligned | price above/below slow EMA | RSI zone
   // ---------------------------------------------------------------
   bool crossUp   = (g_EMA_FastPrev <= g_EMA_MedPrev) && (g_EMA_Fast > g_EMA_Med);
   bool crossDown = (g_EMA_FastPrev >= g_EMA_MedPrev) && (g_EMA_Fast < g_EMA_Med);

   if(crossUp && g_H1Bias == 1 && c1 > g_EMA_Slow &&
      g_RSI > RSI_Bull && g_RSI < RSI_OB)
      return 1;

   if(crossDown && g_H1Bias == -1 && c1 < g_EMA_Slow &&
      g_RSI < RSI_Bear && g_RSI > RSI_OS)
      return -1;

   // ---------------------------------------------------------------
   // STRATEGY 2: MACD HISTOGRAM FLIP
   // MACD changes sign (momentum shift) aligned with H1 trend
   // Price above medium and slow EMA | RSI zone
   // ---------------------------------------------------------------
   bool macdFlipBull = (g_MACD_HistPrev < 0) && (g_MACD_Hist > 0);
   bool macdFlipBear = (g_MACD_HistPrev > 0) && (g_MACD_Hist < 0);

   if(macdFlipBull && g_H1Bias == 1 &&
      c1 > g_EMA_Med && c1 > g_EMA_Slow &&
      g_RSI > RSI_Bull && g_RSI < RSI_OB)
      return 1;

   if(macdFlipBear && g_H1Bias == -1 &&
      c1 < g_EMA_Med && c1 < g_EMA_Slow &&
      g_RSI < RSI_Bear && g_RSI > RSI_OS)
      return -1;

   return 0;
}

//+------------------------------------------------------------------+
//| Open entry order                                                  |
//+------------------------------------------------------------------+
void ExecuteEntry(int dir)
{
   double ask = MarketInfo(g_WorkSymbol, MODE_ASK);
   double bid = MarketInfo(g_WorkSymbol, MODE_BID);
   double atr = g_ATR;

   double entry, sl, tp;

   if(dir == 1)
   {
      entry = ask;
      sl    = NormalizeDouble(ask - atr * ATR_SL_Mult, g_Digits);
      tp    = NormalizeDouble(ask + atr * ATR_TP_Mult, g_Digits);
   }
   else
   {
      entry = bid;
      sl    = NormalizeDouble(bid + atr * ATR_SL_Mult, g_Digits);
      tp    = NormalizeDouble(bid - atr * ATR_TP_Mult, g_Digits);
   }

   double minDist = MarketInfo(g_WorkSymbol, MODE_STOPLEVEL) * g_TickSize;
   if(MathAbs(entry - sl) < minDist)
      sl = (dir == 1) ? entry - minDist : entry + minDist;

   double lots = CalcLots(entry, sl);
   if(lots <= 0) return;

   int    cmd = (dir == 1) ? OP_BUY : OP_SELL;
   double prc = (dir == 1) ? ask : bid;

   int ticket = OrderSend(g_WorkSymbol, cmd, lots, prc, MaxSlippage,
                          sl, tp, TradeComment, MagicNumber, 0,
                          (dir == 1) ? BullColor : BearColor);

   if(ticket > 0)
   {
      g_TradesToday++;
      g_HourTradeCount++;
      g_LastTradeBarTime = iTime(g_WorkSymbol, ScalpTimeframe, 0);
      Print("Scalp opened | ", g_OilTypeName, " | #", ticket,
            " | ", (dir==1?"BUY":"SELL"),
            " | Lots:", lots,
            " | SL:", DoubleToStr(sl, g_Digits),
            " | TP:", DoubleToStr(tp, g_Digits),
            " | ATR:", DoubleToStr(atr, g_Digits));
   }
   else
   {
      int err = GetLastError();
      Print("OrderSend FAILED | Error:", err, " | ", ErrDesc(err));
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
//| Manage open positions: trailing stop only (no partial close)    |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber)           continue;
      if(OrderSymbol()      != g_WorkSymbol)          continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      double openPx = OrderOpenPrice();
      double curSL  = OrderStopLoss();
      double curTP  = OrderTakeProfit();
      double ask    = MarketInfo(g_WorkSymbol, MODE_ASK);
      double bid    = MarketInfo(g_WorkSymbol, MODE_BID);
      double curPx  = (OrderType() == OP_BUY) ? bid : ask;
      double atr    = iATR(g_WorkSymbol, ScalpTimeframe, ATR_Period, 1);
      double ts     = MarketInfo(g_WorkSymbol, MODE_TICKSIZE);
      double minSD  = MarketInfo(g_WorkSymbol, MODE_STOPLEVEL) * ts;
      double profPt = (OrderType() == OP_BUY) ? (curPx - openPx) : (openPx - curPx);

      if(!UseTrailingStop) continue;

      if(profPt >= atr * ATR_TrailActivate_Mult)
      {
         double trail = atr * ATR_Trail_Mult;
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
               Print("Trail stop | #", OrderTicket(), " SL:", DoubleToStr(tSL, g_Digits));
      }
   }
}

//+------------------------------------------------------------------+
//| Weekly DD cap — resets each Monday automatically                |
//+------------------------------------------------------------------+
void CheckWeeklyReset()
{
   int weekNum  = GetWeekNumber(TimeCurrent());
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int weekYear = dt.year;

   if(weekYear != g_CurrentWeekYear || weekNum != g_CurrentWeekNum)
   {
      g_CurrentWeekYear = weekYear;
      g_CurrentWeekNum  = weekNum;
      g_WeekBalance     = AccountBalance();
      g_WeekHalted      = false;
      Print("Weekly reset | Balance:", g_WeekBalance);
   }

   if(!g_WeekHalted && g_WeekBalance > 0)
   {
      double weekDD = (g_WeekBalance - AccountEquity()) / g_WeekBalance * 100.0;
      if(weekDD >= WeeklyDDCapPct)
      {
         g_WeekHalted = true;
         Print("WEEKLY DD CAP HIT: ", DoubleToStr(weekDD, 2), "% — halted until Monday");
      }
   }
}

//+------------------------------------------------------------------+
//| Session filter                                                   |
//+------------------------------------------------------------------+
bool IsAllowedSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int dow  = dt.day_of_week;
   int gmtH = (dt.hour - SessionGMTOffset + 24) % 24;

   if(SkipWeekend    && (dow == 0 || dow == 6))   return false;
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
//| Bars since last trade guard                                      |
//+------------------------------------------------------------------+
bool CheckBarsSinceLastTrade()
{
   if(g_LastTradeBarTime == 0) return true;
   for(int b = 0; b <= MinBarsSinceLastTrade; b++)
      if(iTime(g_WorkSymbol, ScalpTimeframe, b) == g_LastTradeBarTime)
         return (b >= MinBarsSinceLastTrade);
   return true;
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

   if(!g_DailyLimitHit)
   {
      if(g_TradesToday >= MaxTradesPerDay)
      { g_DailyLimitHit = true; Print("Daily trade limit: ", MaxTradesPerDay); return; }

      if(g_DayStartBalance > 0)
      {
         double pnl = (AccountEquity() - g_DayStartEquity) / g_DayStartBalance * 100.0;
         if(pnl <= -MaxDailyLossPct)
         { g_DailyLimitHit = true; Print("Daily LOSS limit: ", DoubleToStr(pnl,2), "%"); }
      }
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
   string h1b   = (g_H1Bias == 1) ? "BULL" : (g_H1Bias == -1) ? "BEAR" : "FLAT";
   string sig   = (g_Signal == 1) ? "BUY"  : (g_Signal == -1) ? "SELL" : "NONE";

   double eq  = AccountEquity();
   double bal = AccountBalance();
   double pnl = eq - g_DayStartEquity;
   double wdd = (g_WeekBalance > 0) ? (g_WeekBalance - eq) / g_WeekBalance * 100.0 : 0;

   string nl = "\n";
   string d  = nl;
   d += "=== OIL SCALPER PRO v2.00 ===" + nl;
   d += "Type    : " + g_OilTypeName + nl;
   d += "Symbol  : " + g_WorkSymbol  + nl;
   d += "Status  : " + status        + nl;
   d += "H1 Bias : " + h1b + " | ADX: " + DoubleToStr(g_ADX, 1)
      + " (min " + DoubleToStr(ADX_MinTrend, 1) + ")" + nl;
   d += "Signal  : " + sig + nl;
   d += "EMA F/M : " + DoubleToStr(g_EMA_Fast, g_Digits)
      + " / " + DoubleToStr(g_EMA_Med, g_Digits) + nl;
   d += "ATR     : " + DoubleToStr(g_ATR, g_Digits) + nl;
   d += "RSI(14) : " + DoubleToStr(g_RSI, 1) + nl;
   d += "MACD H  : " + DoubleToStr(g_MACD_Hist, 5) + nl;
   d += "Balance : " + DoubleToStr(bal, 2)
      + "  Equity: " + DoubleToStr(eq, 2) + nl;
   d += "DayPnL  : " + DoubleToStr(pnl, 2) + nl;
   d += "Week DD : " + DoubleToStr(wdd, 2) + "% / " + DoubleToStr(WeeklyDDCapPct, 1) + "% cap"
      + (g_WeekHalted ? " [HALTED]" : "") + nl;
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

string ErrDesc(int code)
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
