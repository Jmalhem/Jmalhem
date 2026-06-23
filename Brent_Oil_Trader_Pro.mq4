//+------------------------------------------------------------------+
//|                                       Brent_Oil_Trader_Pro.mq4   |
//|           Universal Crude Oil & Energy Trading System v5.00      |
//|        Brent | WTI | Natural Gas  —  Any Broker Symbol           |
//|                                                                    |
//|  GAME-CHANGER EDITION  —  v5.00                                  |
//|  H4 trend + H1 ADX + pullback/cross/MACD-flip entries           |
//|  1.5× SL | 2.0× TP1 (60% close) | 4.5× TP2  →  3:1 RR         |
//+------------------------------------------------------------------+
#property copyright "Professional Oil Trading Systems"
#property version   "5.00"
#property strict
#property description "Oil Trader Pro v5: ADX trend filter + dual EMA-stack + pullback entries"
#property description "3:1 risk-reward | H4+H1 confirmation | Any broker symbol auto-detected"

//=== STRATEGY ===
input string ___STRATEGY___        = "========== STRATEGY ==========";
input bool   EnablePullbackEntry   = true;  // Price pulls back to 21 EMA in H4 trend
input bool   EnableEMACrossEntry   = true;  // 8 EMA crosses 21 EMA in trend direction
input bool   EnableMACDFlipEntry   = true;  // MACD histogram flips positive in trend
input double ADX_MinTrend          = 18.0;  // Minimum ADX(14) for trending market

//=== TIMEFRAMES ===
input string          ___TF___          = "========== TIMEFRAMES ==========";
input ENUM_TIMEFRAMES TrendTimeframe    = PERIOD_H4;
input ENUM_TIMEFRAMES EntryTimeframe    = PERIOD_H1;

//=== EMA ===
input string           ___EMA___        = "========== MOVING AVERAGES ==========";
input int              FastEMA_Period   = 8;
input int              MediumEMA_Period = 21;
input int              SlowEMA_Period   = 50;
input ENUM_MA_METHOD   MA_Method        = MODE_EMA;
input ENUM_APPLIED_PRICE MA_Price       = PRICE_CLOSE;

//=== RSI ===
input string ___RSI___      = "========== RSI ==========";
input int    RSI_Period     = 14;
input double RSI_Overbought = 68.0;
input double RSI_Oversold   = 32.0;
input double RSI_BullMin    = 40.0;  // RSI floor for longs
input double RSI_BearMax    = 60.0;  // RSI ceiling for shorts

//=== MACD ===
input string ___MACD___  = "========== MACD ==========";
input int    MACD_Fast   = 12;
input int    MACD_Slow   = 26;
input int    MACD_Signal = 9;

//=== STOCHASTIC ===
input string ___STOCH___      = "========== STOCHASTIC ==========";
input int    Stoch_K          = 5;
input int    Stoch_D          = 3;
input int    Stoch_Slowing    = 3;
input double Stoch_Overbought = 78.0;
input double Stoch_Oversold   = 22.0;

//=== ATR / STOPS ===
input string ___ATR___              = "========== ATR / STOPS ==========";
input int    ATR_Period             = 14;
input double ATR_SL_Mult            = 1.5;   // Stop loss  = 1.5 × ATR
input double ATR_TP1_Mult           = 2.0;   // TP1        = 2.0 × ATR (60% close)
input double ATR_TP2_Mult           = 4.5;   // TP2        = 4.5 × ATR  → 3:1 RR
input double ATR_Trail_Mult         = 0.9;   // Trailing stop distance
input double ATR_TrailActivate_Mult = 2.0;   // Activate trailing after 2× ATR profit
input double ATR_MinMultiplier      = 0.3;
input double ATR_MaxMultiplier      = 3.5;

//=== RISK ===
input string ___RISK___          = "========== RISK MANAGEMENT ==========";
input double RiskPercent         = 1.0;
input double MaxLotSize          = 5.0;
input double MinLotSize          = 0.01;
input bool   UsePartialClose     = true;
input double PartialClosePct     = 60.0;    // Close 60% at TP1
input bool   UseBreakEven        = true;
input double BE_ATR_Buffer       = 0.15;    // BE above entry = 0.15 × ATR
input bool   UseTrailingStop     = true;
input int    MaxTradesPerDay     = 4;

//=== DAILY LIMITS ===
input string ___DAILY___         = "========== DAILY LIMITS ==========";
input double MaxDailyLossPct     = 3.0;
input double MaxDailyProfitPct   = 6.0;
input double MaxDrawdownPct      = 12.0;

//=== SESSION ===
input string ___SESSIONS___      = "========== OIL TRADING SESSIONS ==========";
input bool   TradeLondonOpen     = true;   // 07:00-09:00 GMT
input bool   TradeLondonCore     = true;   // 09:00-13:00 GMT
input bool   TradeNYOverlap      = true;   // 13:00-17:00 GMT
input bool   TradeNYSession      = false;
input bool   TradeAsian          = false;
input int    SessionGMTOffset    = 0;
input bool   SkipFriday1700      = true;
input bool   SkipMonday0500      = true;
input bool   SkipWeekend         = true;

//=== NEWS ===
input string ___NEWS___          = "========== NEWS FILTER ==========";
input bool   UseNewsFilter       = true;
input int    NewsMinBefore       = 30;
input int    NewsMinAfter        = 30;
input bool   FilterEIA           = true;
input bool   FilterAPI           = true;
input bool   FilterNFP           = true;
input bool   FilterFOMC          = true;

//=== EXECUTION ===
input string ___EXEC___          = "========== EXECUTION ==========";
input double MaxSpreadPoints     = 50.0;
input int    MaxSlippagePoints   = 30;
input bool   RequireBarClose     = true;

//=== POSITION ===
input string ___POS___           = "========== POSITION ==========";
input int    MagicNumber         = 202500;
input string TradeComment        = "OilPro5";

//=== SYMBOL ===
input string ___SYMBOL___        = "========== SYMBOL (blank = auto) ==========";
input string ForceSymbol         = "";
input bool   ScanAllOilSymbols   = true;

//=== DISPLAY ===
input string ___DISPLAY___       = "========== DASHBOARD ==========";
input bool   ShowDashboard       = true;
input color  BullColor           = clrDodgerBlue;
input color  BearColor           = clrOrangeRed;
input color  NeutralColor        = clrGray;

//+------------------------------------------------------------------+
#define OIL_UNKNOWN  0
#define OIL_BRENT    1
#define OIL_WTI      2
#define OIL_NATGAS   3

string BRENT_PATTERNS[] = {
   "BRENT","BCO","LCO","LCOIL","BRN","BRNO",
   "UKOIL","OILUK","UKCRUDE",
   "XBRENT","XBRO","XBRUSD","XBRO_USD","OIL"
};
string WTI_PATTERNS[] = {
   "WTI","CRUDE","NYMEXOIL","CL",
   "USOIL","OILUS","USCRUDE","USOILCFD",
   "XTIUSD","XTI","XWTI","XWTIUSD","WTIOIL"
};
string NATGAS_PATTERNS[] = {
   "NATGAS","NATURALGAS","NGAS","GAS","XNGUSD","XNG","NG"
};
string SUFFIXES[] = {
   "",".raw",".ecn",".pro",".c","#","+","m","_SB",".SB","USD","_USD",".USD"
};

//+------------------------------------------------------------------+
// Global state
//+------------------------------------------------------------------+
datetime g_LastBarTime      = 0;
datetime g_DayStartTime     = 0;
double   g_DayStartBalance  = 0;
double   g_DayStartEquity   = 0;
int      g_TradesToday      = 0;
double   g_PeakEquity       = 0;
bool     g_DailyLimitHit    = false;
bool     g_DDHaltActive     = false;

string   g_WorkSymbol       = "";
int      g_OilType          = OIL_UNKNOWN;
string   g_OilTypeName      = "Unknown";
int      g_Digits           = 2;
double   g_TickSize         = 0.01;
double   g_SpreadMax        = 50.0;

double   g_ATR              = 0;
double   g_ATR_Avg          = 0;
double   g_RSI              = 0;
double   g_MACD_Hist        = 0;
double   g_MACD_HistPrev    = 0;
double   g_Stoch_Main       = 0;
double   g_Stoch_Sig        = 0;
double   g_ADX              = 0;
int      g_Signal           = 0;
int      g_H4Bias           = 0;

//+------------------------------------------------------------------+
// Symbol detection helpers
//+------------------------------------------------------------------+
bool IsSymbolValid(string sym)
{
   if(StringLen(sym)==0) return false;
   return (MarketInfo(sym,MODE_BID)>0 && MarketInfo(sym,MODE_TICKSIZE)>0);
}

string ToUpper(string s) { string r=s; StringToUpper(r); return r; }

int ClassifyPattern(string upper)
{
   int i;
   for(i=0;i<ArraySize(BRENT_PATTERNS);i++) if(StringFind(upper,BRENT_PATTERNS[i])>=0) return OIL_BRENT;
   for(i=0;i<ArraySize(WTI_PATTERNS);i++)   if(StringFind(upper,WTI_PATTERNS[i])>=0)   return OIL_WTI;
   for(i=0;i<ArraySize(NATGAS_PATTERNS);i++) if(StringFind(upper,NATGAS_PATTERNS[i])>=0) return OIL_NATGAS;
   return OIL_UNKNOWN;
}

string TryWithSuffixes(string base)
{
   for(int i=0;i<ArraySize(SUFFIXES);i++) {
      string c=base+SUFFIXES[i]; if(IsSymbolValid(c)) return c; }
   return "";
}

string ScanList(string &list[], int &outType)
{
   for(int p=0;p<ArraySize(list);p++) {
      string f=TryWithSuffixes(list[p]);
      if(StringLen(f)>0) { outType=ClassifyPattern(ToUpper(f)); return f; } }
   outType=OIL_UNKNOWN; return "";
}

bool DetectOilSymbol()
{
   if(StringLen(ForceSymbol)>0) {
      if(!IsSymbolValid(ForceSymbol)) { Print("ForceSymbol invalid"); return false; }
      g_WorkSymbol=ForceSymbol; g_OilType=ClassifyPattern(ToUpper(ForceSymbol)); return true; }
   string chart=Symbol();
   if(IsSymbolValid(chart)) {
      int t=ClassifyPattern(ToUpper(chart));
      if(t!=OIL_UNKNOWN) { g_WorkSymbol=chart; g_OilType=t; return true; } }
   if(!ScanAllOilSymbols) { Print("Chart symbol not oil."); return false; }
   int ft=OIL_UNKNOWN; string f="";
   f=ScanList(BRENT_PATTERNS,ft); if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_BRENT;return true;}
   f=ScanList(WTI_PATTERNS,ft);   if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_WTI;  return true;}
   f=ScanList(NATGAS_PATTERNS,ft);if(StringLen(f)>0){g_WorkSymbol=f;g_OilType=OIL_NATGAS;return true;}
   Print("No oil symbol found."); return false;
}

void ApplyOilDefaults()
{
   switch(g_OilType) {
      case OIL_BRENT:  g_OilTypeName="Brent Crude (ICE)"; g_SpreadMax=MaxSpreadPoints;       break;
      case OIL_WTI:    g_OilTypeName="WTI Crude (NYMEX)"; g_SpreadMax=MaxSpreadPoints;       break;
      case OIL_NATGAS: g_OilTypeName="Natural Gas";        g_SpreadMax=MaxSpreadPoints*0.5;   break;
      default:         g_OilTypeName="Oil (Unknown)";      g_SpreadMax=MaxSpreadPoints;       break; }
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(!DetectOilSymbol()) return INIT_FAILED;
   ApplyOilDefaults();
   g_Digits   = (int)MarketInfo(g_WorkSymbol,MODE_DIGITS);
   g_TickSize = MarketInfo(g_WorkSymbol,MODE_TICKSIZE);
   g_PeakEquity     = AccountEquity();
   g_DayStartBalance= AccountBalance();
   g_DayStartEquity = AccountEquity();
   g_DayStartTime   = TimeCurrent();
   Print("=================================================");
   Print(" Oil Trader Pro v5.00 — READY  (Game-Changer)");
   Print(" Oil Type : ", g_OilTypeName, "  Symbol: ", g_WorkSymbol);
   Print(" Strategy : H4 trend + H1 ADX(", ADX_MinTrend, ") + pullback entries");
   Print(" RR Ratio : 1:", ATR_TP2_Mult/ATR_SL_Mult, "  |  Risk: ", RiskPercent, "%");
   Print("=================================================");
   if(ShowDashboard) DrawDashboard("Initializing...", NeutralColor);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0,"OPro_"); Comment(""); }

//+------------------------------------------------------------------+
void OnTick()
{
   ManageOpenPositions();
   if(RequireBarClose) {
      datetime bt=iTime(g_WorkSymbol,EntryTimeframe,0);
      if(bt==g_LastBarTime) return; g_LastBarTime=bt; }
   CheckDailyReset();
   if(g_DailyLimitHit||g_DDHaltActive) {
      if(ShowDashboard) DrawDashboard("HALTED",BearColor); return; }
   if(!CheckDrawdown())                         return;
   if(CountOpenPositions()>=1)                  return;
   if(!IsAllowedSession())                      return;
   if(MarketInfo(g_WorkSymbol,MODE_SPREAD)>g_SpreadMax) return;
   if(UseNewsFilter && IsNewsTime())             return;
   if(g_TradesToday>=MaxTradesPerDay)           return;

   LoadIndicators();
   if(!CheckVolatility())                       return;
   g_Signal = GenerateSignal();
   if(g_Signal!=0) ExecuteEntry(g_Signal);
   if(ShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
void LoadIndicators()
{
   // H1 indicators
   g_ATR = iATR(g_WorkSymbol,EntryTimeframe,ATR_Period,1);
   double atrSum=0;
   for(int i=1;i<=50;i++) atrSum+=iATR(g_WorkSymbol,EntryTimeframe,ATR_Period,i);
   g_ATR_Avg = atrSum/50.0;

   g_RSI = iRSI(g_WorkSymbol,EntryTimeframe,RSI_Period,MA_Price,1);

   double mMain = iMACD(g_WorkSymbol,EntryTimeframe,MACD_Fast,MACD_Slow,MACD_Signal,MA_Price,MODE_MAIN,1);
   double mSig  = iMACD(g_WorkSymbol,EntryTimeframe,MACD_Fast,MACD_Slow,MACD_Signal,MA_Price,MODE_SIGNAL,1);
   double mMain2= iMACD(g_WorkSymbol,EntryTimeframe,MACD_Fast,MACD_Slow,MACD_Signal,MA_Price,MODE_MAIN,2);
   double mSig2 = iMACD(g_WorkSymbol,EntryTimeframe,MACD_Fast,MACD_Slow,MACD_Signal,MA_Price,MODE_SIGNAL,2);
   g_MACD_Hist     = mMain  - mSig;
   g_MACD_HistPrev = mMain2 - mSig2;

   g_Stoch_Main = iStochastic(g_WorkSymbol,EntryTimeframe,Stoch_K,Stoch_D,Stoch_Slowing,MODE_SMA,0,MODE_MAIN,1);
   g_Stoch_Sig  = iStochastic(g_WorkSymbol,EntryTimeframe,Stoch_K,Stoch_D,Stoch_Slowing,MODE_SMA,0,MODE_SIGNAL,1);

   // ADX (14) on H1
   g_ADX = iADX(g_WorkSymbol,EntryTimeframe,14,MA_Price,MODE_MAIN,1);

   // H4 trend bias: fast EMA vs slow EMA and price position
   double h4_fast = iMA(g_WorkSymbol,TrendTimeframe,FastEMA_Period,  0,MA_Method,MA_Price,1);
   double h4_slow = iMA(g_WorkSymbol,TrendTimeframe,SlowEMA_Period,  0,MA_Method,MA_Price,1);
   double h4_close= iClose(g_WorkSymbol,TrendTimeframe,1);
   if(h4_close>h4_slow && h4_fast>h4_slow)       g_H4Bias =  1;
   else if(h4_close<h4_slow && h4_fast<h4_slow)  g_H4Bias = -1;
   else                                           g_H4Bias =  0;
}

//+------------------------------------------------------------------+
int GenerateSignal()
{
   if(g_H4Bias==0) return 0;     // no clear H4 trend
   if(g_ADX<ADX_MinTrend) return 0;  // not trending enough on H1

   double ef1 = iMA(g_WorkSymbol,EntryTimeframe,FastEMA_Period,  0,MA_Method,MA_Price,1);
   double em1 = iMA(g_WorkSymbol,EntryTimeframe,MediumEMA_Period,0,MA_Method,MA_Price,1);
   double es1 = iMA(g_WorkSymbol,EntryTimeframe,SlowEMA_Period,  0,MA_Method,MA_Price,1);
   double ef2 = iMA(g_WorkSymbol,EntryTimeframe,FastEMA_Period,  0,MA_Method,MA_Price,2);
   double em2 = iMA(g_WorkSymbol,EntryTimeframe,MediumEMA_Period,0,MA_Method,MA_Price,2);
   double c1  = iClose(g_WorkSymbol,EntryTimeframe,1);

   int signal = 0;

   if(g_H4Bias==1)
   {
      if(c1<=em1) return 0;  // H1 price must be above 21 EMA
      if(g_RSI<RSI_BullMin || g_RSI>RSI_Overbought) return 0;

      // S1: pullback to 21 EMA with MACD positive
      if(EnablePullbackEntry && signal==0)
      {
         bool nearMed = (MathAbs(c1-em1) < g_ATR*0.85);
         if(nearMed && g_MACD_Hist>0 && g_Stoch_Main<65) signal=1;
      }
      // S2: 8 EMA crosses above 21 EMA
      if(EnableEMACrossEntry && signal==0)
      {
         bool crossUp = (ef2<=em2 && ef1>em1);
         if(crossUp && g_MACD_Hist>0 && g_MACD_Hist>g_MACD_HistPrev && g_Stoch_Main<72) signal=1;
      }
      // S3: MACD histogram flips positive while above 21 EMA
      if(EnableMACDFlipEntry && signal==0)
      {
         bool flip = (g_MACD_HistPrev<0 && g_MACD_Hist>0);
         if(flip && c1>es1 && g_RSI>45) signal=1;
      }
   }
   else if(g_H4Bias==-1)
   {
      if(c1>=em1) return 0;
      if(g_RSI>RSI_BearMax || g_RSI<RSI_Oversold) return 0;

      if(EnablePullbackEntry && signal==0)
      {
         bool nearMed = (MathAbs(c1-em1) < g_ATR*0.85);
         if(nearMed && g_MACD_Hist<0 && g_Stoch_Main>35) signal=-1;
      }
      if(EnableEMACrossEntry && signal==0)
      {
         bool crossDn = (ef2>=em2 && ef1<em1);
         if(crossDn && g_MACD_Hist<0 && g_MACD_Hist<g_MACD_HistPrev && g_Stoch_Main>28) signal=-1;
      }
      if(EnableMACDFlipEntry && signal==0)
      {
         bool flip = (g_MACD_HistPrev>0 && g_MACD_Hist<0);
         if(flip && c1<es1 && g_RSI<55) signal=-1;
      }
   }

   if(signal== 1 && g_Stoch_Main>Stoch_Overbought) signal=0;
   if(signal==-1 && g_Stoch_Main<Stoch_Oversold)   signal=0;
   return signal;
}

//+------------------------------------------------------------------+
void ExecuteEntry(int dir)
{
   double ask=MarketInfo(g_WorkSymbol,MODE_ASK); double bid=MarketInfo(g_WorkSymbol,MODE_BID);
   double atr=g_ATR; double entry,sl,tp1,tp2;

   if(dir==1)  { entry=ask; sl=NormalizeDouble(ask-atr*ATR_SL_Mult,g_Digits); tp1=NormalizeDouble(ask+atr*ATR_TP1_Mult,g_Digits); tp2=NormalizeDouble(ask+atr*ATR_TP2_Mult,g_Digits); }
   else        { entry=bid; sl=NormalizeDouble(bid+atr*ATR_SL_Mult,g_Digits); tp1=NormalizeDouble(bid-atr*ATR_TP1_Mult,g_Digits); tp2=NormalizeDouble(bid-atr*ATR_TP2_Mult,g_Digits); }

   double minD=MarketInfo(g_WorkSymbol,MODE_STOPLEVEL)*g_TickSize;
   if(MathAbs(entry-sl)<minD) sl=(dir==1)?entry-minD:entry+minD;

   double lots=CalcLots(entry,sl);
   if(lots<=0) return;

   string cmt=TradeComment+"|TP1="+DoubleToStr(tp1,g_Digits);
   int ticket=OrderSend(g_WorkSymbol,(dir==1)?OP_BUY:OP_SELL,lots,(dir==1)?ask:bid,
                        MaxSlippagePoints,sl,tp2,cmt,MagicNumber,0,
                        (dir==1)?BullColor:BearColor);
   if(ticket>0) {
      g_TradesToday++;
      Print("Trade | ",g_OilTypeName," | #",ticket," | ",(dir==1?"BUY":"SELL"),
            " | Lots:",lots," | SL:",sl," | TP1:",tp1," | TP2:",tp2," | ATR:",atr);
   } else Print("OrderSend FAILED | Error:",GetLastError());
}

double CalcLots(double entry, double sl)
{
   double bal=AccountBalance(); double risk=bal*RiskPercent/100.0;
   double slDist=MathAbs(entry-sl); if(slDist<=0) return MinLotSize;
   double tv=MarketInfo(g_WorkSymbol,MODE_TICKVALUE); double ts=MarketInfo(g_WorkSymbol,MODE_TICKSIZE);
   double step=MarketInfo(g_WorkSymbol,MODE_LOTSTEP); double minLot=MarketInfo(g_WorkSymbol,MODE_MINLOT);
   double maxLot=MarketInfo(g_WorkSymbol,MODE_MAXLOT);
   if(tv<=0||ts<=0) return minLot;
   double lots=MathFloor(risk/((slDist/ts)*tv)/step)*step;
   return MathMax(MathMax(minLot,MinLotSize),MathMin(MathMin(maxLot,MaxLotSize),NormalizeDouble(lots,2)));
}

//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderMagicNumber()!=MagicNumber) continue;
      if(OrderSymbol()!=g_WorkSymbol) continue;
      if(OrderType()!=OP_BUY && OrderType()!=OP_SELL) continue;

      double openPx=OrderOpenPrice(); double curSL=OrderStopLoss(); double curTP=OrderTakeProfit();
      double ask=MarketInfo(g_WorkSymbol,MODE_ASK); double bid=MarketInfo(g_WorkSymbol,MODE_BID);
      double curPx=(OrderType()==OP_BUY)?bid:ask;
      double atr=iATR(g_WorkSymbol,EntryTimeframe,ATR_Period,1);
      double ts=MarketInfo(g_WorkSymbol,MODE_TICKSIZE);
      double minSD=MarketInfo(g_WorkSymbol,MODE_STOPLEVEL)*ts;
      double profPt=(OrderType()==OP_BUY)?(curPx-openPx):(openPx-curPx);
      string cmt=OrderComment();

      // Parse TP1
      double tp1=0;
      int p1=StringFind(cmt,"TP1=");
      if(p1>=0) { string s=StringSubstr(cmt,p1+4); int pp=StringFind(s,"|"); if(pp>0) s=StringSubstr(s,0,pp); tp1=StrToDouble(s); }

      bool tp1Hit=(tp1>0)&&((OrderType()==OP_BUY&&curPx>=tp1)||(OrderType()==OP_SELL&&curPx<=tp1));

      // Partial close at TP1
      if(UsePartialClose && tp1Hit && StringFind(cmt,"PC1")<0)
      {
         double step=MarketInfo(g_WorkSymbol,MODE_LOTSTEP); double minLot=MarketInfo(g_WorkSymbol,MODE_MINLOT);
         double pLots=NormalizeDouble(OrderLots()*PartialClosePct/100.0,2);
         pLots=MathFloor(pLots/step)*step;
         if(pLots>=minLot && pLots<OrderLots())
            if(OrderClose(OrderTicket(),pLots,curPx,MaxSlippagePoints,clrYellow))
               Print("Partial close TP1 | #",OrderTicket()," | Lots:",pLots);
      }

      // Break-even
      if(UseBreakEven && tp1Hit)
      {
         double buf=atr*BE_ATR_Buffer; double beSL; bool doMod=false;
         if(OrderType()==OP_BUY)  { beSL=NormalizeDouble(openPx+buf,g_Digits); if(beSL>curSL+ts && beSL<curPx-minSD) doMod=true; }
         else                     { beSL=NormalizeDouble(openPx-buf,g_Digits); if(beSL<curSL-ts && beSL>curPx+minSD) doMod=true; }
         if(doMod) if(OrderModify(OrderTicket(),openPx,beSL,curTP,0,clrGold)) Print("BE | #",OrderTicket()," SL:",beSL);
      }

      // Trailing stop
      if(UseTrailingStop && profPt>=atr*ATR_TrailActivate_Mult)
      {
         double trail=atr*ATR_Trail_Mult; double tSL; bool doTrail=false;
         if(OrderType()==OP_BUY)  { tSL=NormalizeDouble(curPx-trail,g_Digits); if(tSL>curSL+ts && tSL<curPx-minSD) doTrail=true; }
         else                     { tSL=NormalizeDouble(curPx+trail,g_Digits); if(tSL<curSL-ts && tSL>curPx+minSD) doTrail=true; }
         if(doTrail) if(OrderModify(OrderTicket(),openPx,tSL,curTP,0,clrCyan)) Print("Trail | #",OrderTicket()," SL:",tSL);
      }
   }
}

//+------------------------------------------------------------------+
bool IsAllowedSession()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   int dow=dt.day_of_week; int gmtH=(dt.hour-SessionGMTOffset+24)%24;
   if(SkipWeekend  && (dow==0||dow==6)) return false;
   if(SkipMonday0500 && dow==1 && gmtH<5) return false;
   if(SkipFriday1700 && dow==5 && gmtH>=17) return false;
   if(TradeLondonOpen && gmtH>=7  && gmtH<9)  return true;
   if(TradeLondonCore && gmtH>=9  && gmtH<13) return true;
   if(TradeNYOverlap  && gmtH>=13 && gmtH<17) return true;
   if(TradeNYSession  && gmtH>=17 && gmtH<21) return true;
   if(TradeAsian      && gmtH>=0  && gmtH<7)  return true;
   return false;
}

bool IsNewsTime()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   int dow=dt.day_of_week; int gmtH=(dt.hour-SessionGMTOffset+24)%24; int tot=gmtH*60+dt.min;
   if(FilterEIA  && dow==3) { int t=14*60+30; if(tot>=t-NewsMinBefore && tot<=t+NewsMinAfter) return true; }
   if(FilterAPI  && dow==2) { int t=20*60+30; if(tot>=t-NewsMinBefore && tot<=t+NewsMinAfter) return true; }
   if(FilterFOMC && dow==3) { int t=19*60;    if(tot>=t-NewsMinBefore && tot<=t+NewsMinAfter) return true; }
   if(FilterNFP  && dow==5) { int t=13*60+30; if(tot>=t && tot<=t+60) return true; }
   return false;
}

bool CheckVolatility()
{
   if(g_ATR<=0||g_ATR_Avg<=0) return false;
   if(g_ATR<g_ATR_Avg*ATR_MinMultiplier) return false;
   if(g_ATR>g_ATR_Avg*ATR_MaxMultiplier) return false;
   return true;
}

bool CheckDrawdown()
{
   double eq=AccountEquity();
   if(eq>g_PeakEquity) g_PeakEquity=eq;
   double dd=(g_PeakEquity>0)?(g_PeakEquity-eq)/g_PeakEquity*100.0:0;
   if(dd>=MaxDrawdownPct) { if(!g_DDHaltActive){Print("DD HALT: ",DoubleToStr(dd,2),"%"); g_DDHaltActive=true;} return false; }
   return true;
}

void CheckDailyReset()
{
   MqlDateTime now,start; TimeToStruct(TimeCurrent(),now); TimeToStruct(g_DayStartTime,start);
   if(now.day!=start.day||now.mon!=start.mon) {
      g_DayStartTime=TimeCurrent(); g_DayStartBalance=AccountBalance(); g_DayStartEquity=AccountEquity();
      g_TradesToday=0; g_DailyLimitHit=false; Print("Daily reset | Balance:",g_DayStartBalance); }
   if(g_TradesToday>=MaxTradesPerDay && !g_DailyLimitHit) { g_DailyLimitHit=true; return; }
   if(g_DayStartBalance>0) {
      double pnl=(AccountEquity()-g_DayStartEquity)/g_DayStartBalance*100.0;
      if(pnl<=-MaxDailyLossPct && !g_DailyLimitHit) { g_DailyLimitHit=true; Print("Daily LOSS: ",DoubleToStr(pnl,2),"%"); }
      if(pnl>=MaxDailyProfitPct && !g_DailyLimitHit) { g_DailyLimitHit=true; Print("Daily PROFIT: ",DoubleToStr(pnl,2),"%"); } }
}

int CountOpenPositions()
{
   int n=0;
   for(int i=0;i<OrdersTotal();i++) {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderMagicNumber()==MagicNumber && OrderSymbol()==g_WorkSymbol) n++; }
   return n;
}

//+------------------------------------------------------------------+
void DrawDashboard(string status, color clr)
{
   string h4s=(g_H4Bias==1)?"H4:BULL":(g_H4Bias==-1)?"H4:BEAR":"H4:FLAT";
   string sig=(g_Signal==1)?"BUY":(g_Signal==-1)?"SELL":"NONE";
   double eq=AccountEquity(); double bal=AccountBalance();
   double pnl=eq-g_DayStartEquity;
   double dd=(g_PeakEquity>0)?(g_PeakEquity-eq)/g_PeakEquity*100.0:0;
   string nl="\n"; string d=nl;
   d+="=== OIL TRADER PRO v5.00 ===" +nl;
   d+="Type    : "+g_OilTypeName+nl;
   d+="Symbol  : "+g_WorkSymbol+nl;
   d+="Status  : "+status+nl;
   d+="Trend   : "+h4s+" | ADX:"+DoubleToStr(g_ADX,1)+" | Signal:"+sig+nl;
   d+="ATR     : "+DoubleToStr(g_ATR,g_Digits)+"  Avg:"+DoubleToStr(g_ATR_Avg,g_Digits)+nl;
   d+="RSI     : "+DoubleToStr(g_RSI,1)+"  MACD:"+DoubleToStr(g_MACD_Hist,5)+nl;
   d+="Stoch   : "+DoubleToStr(g_Stoch_Main,1)+nl;
   d+="Balance : "+DoubleToStr(bal,2)+"  Equity:"+DoubleToStr(eq,2)+nl;
   d+="DayPnL  : "+DoubleToStr(pnl,2)+"  DD:"+DoubleToStr(dd,2)+"%"+nl;
   d+="Trades  : "+IntegerToString(g_TradesToday)+"/"+IntegerToString(MaxTradesPerDay)+nl;
   d+="Spread  : "+DoubleToStr(MarketInfo(g_WorkSymbol,MODE_SPREAD),1)+" / max "+DoubleToStr(g_SpreadMax,1)+nl;
   d+="Session : "+(IsAllowedSession()?"ACTIVE":"CLOSED")+nl;
   d+="News    : "+(UseNewsFilter&&IsNewsTime()?"BLOCKED":"CLEAR")+nl;
   Comment(d);
}

void UpdateDashboard() { DrawDashboard("RUNNING",BullColor); }
//+------------------------------------------------------------------+
