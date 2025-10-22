//+------------------------------------------------------------------+
//|                                        GBPUSD_Scalper_Pro.mq4    |
//|                        Professional GBP/USD Scalping System      |
//|                         Optimized for High-Frequency Trading     |
//+------------------------------------------------------------------+
#property copyright "Professional Scalping Systems"
#property version   "2.00"
#property strict
#property description "Advanced GBP/USD Scalping EA with Multi-Strategy Approach"

//=== SCALPING CORE SETTINGS ===
input string ___SCALPING___ = "=== SCALPING STRATEGY ===";
input bool EnablePriceActionScalping = true;
input bool EnableBreakoutScalping = true;
input bool EnableRangeScalping = true;
input bool EnableMomentumScalping = true;
input bool EnableOrderFlowScalping = true;
input int ScalpingTimeframe = 1; // M1 for scalping
input int MaxScalpsPerHour = 5;
input int MaxScalpsPerDay = 30;

//=== ENTRY FILTERS ===
input string ___FILTERS___ = "=== ENTRY FILTERS ===";
input double MaxSpreadPoints = 2.0; // Maximum spread in points
input bool RequireVolatility = true;
input double MinATRPips = 5.0; // Minimum ATR for entry
input double MaxATRPips = 30.0; // Maximum ATR for entry
input bool UseOrderFlow = true;
input int OrderFlowPeriod = 10;
input bool AvoidHighImpactNews = true;
input int NewsAvoidanceMinutes = 30;

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
input string ___INDICATORS___ = "=== SCALPING INDICATORS ===";
input int FastEMA = 5;
input int SlowEMA = 13;
input int SignalEMA = 21;
input int RSI_Period = 9;
input int RSI_OverboughtLevel = 75;
input int RSI_OversoldLevel = 25;
input int StochasticK = 5;
input int StochasticD = 3;
input int StochasticSlowing = 3;
input int BollingerPeriod = 20;
input double BollingerDeviation = 2.0;
input int ATR_Period = 14;

//=== SCALPING RISK MANAGEMENT ===
input string ___RISK___ = "=== RISK MANAGEMENT ===";
input double RiskPercentPerTrade = 0.5; // Small risk per scalp
input double MinRewardRiskRatio = 1.5;
input double MaxRewardRiskRatio = 3.0;
input int StopLossPips = 8; // Tight stop loss for scalping
input int TakeProfitPips = 12; // Quick profit target
input bool UseTrailingStop = true;
input int TrailingStopPips = 5;
input int TrailingStepPips = 2;
input bool UseBreakEven = true;
input int BreakEvenPips = 5;
input int BreakEvenPlusPips = 1;

//=== POSITION MANAGEMENT ===
input string ___POSITION___ = "=== POSITION MANAGEMENT ===";
input int MaxConcurrentPositions = 1; // One scalp at a time
input bool AllowHedging = false;
input double MaxDailyLossPercent = 3.0;
input double MaxDailyProfitPercent = 5.0; // Take profit and stop for the day
input int MagicNumberScalp = 777777;

//=== SCALPING DASHBOARD ===
input string ___DASHBOARD___ = "=== DASHBOARD ===";
input bool ShowScalpDashboard = true;
input int DashX = 20;
input int DashY = 30;
input color ProfitColorScalp = clrLimeGreen;
input color LossColorScalp = clrRed;
input color NeutralColorScalp = clrYellow;

//=== GLOBAL VARIABLES ===
datetime LastBarTime = 0;
datetime LastScalpTime = 0;
int ScalpsThisHour = 0;
int ScalpsToday = 0;
double DailyPnL = 0;
double SessionPnL = 0;
int TotalScalps = 0;
int WinningScalps = 0;
int LosingScalps = 0;
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
double BestScalp = 0;
double WorstScalp = 0;
datetime StartOfDay = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== GBP/USD SCALPER PRO EA INITIALIZED ===");
   Print("Symbol: ", Symbol());
   Print("Timeframe: M", ScalpingTimeframe);
   Print("Max Spread: ", MaxSpreadPoints, " points");
   Print("Stop Loss: ", StopLossPips, " pips");
   Print("Take Profit: ", TakeProfitPips, " pips");

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

   // Create dashboard
   if(ShowScalpDashboard)
      CreateScalpDashboard();

   // Set timer for dashboard updates
   EventSetTimer(1); // 1-second updates for scalping

   Print("Initialization successful!");
   Print("Trading Sessions: London=", TradeLondonSession, " NY=", TradeNYSession, " Asian=", TradeAsianSession);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   if(ShowScalpDashboard)
      DeleteScalpDashboard();

   Print("=== GBP/USD SCALPER PRO EA STOPPED ===");
   Print("Total Scalps: ", TotalScalps);
   Print("Winning Scalps: ", WinningScalps);
   Print("Losing Scalps: ", LosingScalps);
   if(TotalScalps > 0)
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
   if(ShowScalpDashboard)
      UpdateScalpDashboard();

   // Quick scalping checks
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

   // Check if new hour
   if(TimeHour(TimeCurrent()) != TimeHour(LastScalpTime))
      ScalpsThisHour = 0;

   // Comprehensive analysis
   AnalyzeScalpingOpportunity();

   // Risk checks
   if(!ValidateRiskParameters())
      return;

   // Manage existing positions
   ManageScalpPositions();

   // Execute scalping strategies
   ExecuteScalpingStrategies();

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
      Print("WARNING: Risk per trade is high for scalping");
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
   int currentHour = Hour();
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
//| Scalping opportunity analysis                                   |
//+------------------------------------------------------------------+
void AnalyzeScalpingOpportunity()
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
   if(ScalpsToday >= MaxScalpsPerDay)
   {
      CurrentSignal = "DAILY SCALP LIMIT REACHED";
      return false;
   }

   // Check hourly limits
   if(ScalpsThisHour >= MaxScalpsPerHour)
   {
      CurrentSignal = "HOURLY SCALP LIMIT REACHED";
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

   if(CurrentDrawdown > 10.0) // 10% max drawdown for scalping
   {
      CurrentSignal = "DRAWDOWN LIMIT EXCEEDED";
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Scalping strategies execution                                   |
//+------------------------------------------------------------------+
void ExecuteScalpingStrategies()
{
   CurrentSignal = "ANALYZING";

   // Price action scalping
   if(EnablePriceActionScalping)
      ExecutePriceActionScalp();

   // Breakout scalping
   if(EnableBreakoutScalping)
      ExecuteBreakoutScalp();

   // Range scalping
   if(EnableRangeScalping)
      ExecuteRangeScalp();

   // Momentum scalping
   if(EnableMomentumScalping)
      ExecuteMomentumScalp();

   // Order flow scalping
   if(EnableOrderFlowScalping && UseOrderFlow)
      ExecuteOrderFlowScalp();
}

void ExecutePriceActionScalp()
{
   // Pin bar / rejection scalping
   double body = MathAbs(Close[1] - Open[1]);
   double upperWick = High[1] - MathMax(Close[1], Open[1]);
   double lowerWick = MathMin(Close[1], Open[1]) - Low[1];
   double totalRange = High[1] - Low[1];

   if(totalRange == 0) return;

   // Bullish pin bar at support
   if(lowerWick > body * 2 && lowerWick > upperWick &&
      Close[1] > Open[1] && Bid <= DynamicSupport + (10 * Point))
   {
      if(!HasLongPosition())
      {
         ExecuteScalp(OP_BUY, "Price Action Bull");
         CurrentSignal = "PIN BAR BUY";
      }
   }

   // Bearish pin bar at resistance
   if(upperWick > body * 2 && upperWick > lowerWick &&
      Close[1] < Open[1] && Ask >= DynamicResistance - (10 * Point))
   {
      if(!HasShortPosition())
      {
         ExecuteScalp(OP_SELL, "Price Action Bear");
         CurrentSignal = "PIN BAR SELL";
      }
   }
}

void ExecuteBreakoutScalp()
{
   double bb_upper = iBands(Symbol(), 0, BollingerPeriod, BollingerDeviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bb_lower = iBands(Symbol(), 0, BollingerPeriod, BollingerDeviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 0);

   // Bullish breakout
   if(Close[1] > bb_upper && Close[0] > Close[1] && rsi < RSI_OverboughtLevel)
   {
      if(!HasLongPosition() && MarketCondition == "BULLISH TREND")
      {
         ExecuteScalp(OP_BUY, "Breakout Bull");
         CurrentSignal = "BREAKOUT BUY";
      }
   }

   // Bearish breakout
   if(Close[1] < bb_lower && Close[0] < Close[1] && rsi > RSI_OversoldLevel)
   {
      if(!HasShortPosition() && MarketCondition == "BEARISH TREND")
      {
         ExecuteScalp(OP_SELL, "Breakout Bear");
         CurrentSignal = "BREAKOUT SELL";
      }
   }
}

void ExecuteRangeScalp()
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
         ExecuteScalp(OP_BUY, "Range Support");
         CurrentSignal = "RANGE BUY";
      }
   }

   // Sell at resistance in range
   if(currentPrice >= DynamicResistance - (range * 0.2) && rsi > 60)
   {
      if(!HasShortPosition())
      {
         ExecuteScalp(OP_SELL, "Range Resistance");
         CurrentSignal = "RANGE SELL";
      }
   }
}

void ExecuteMomentumScalp()
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
         ExecuteScalp(OP_BUY, "Momentum Bull");
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
         ExecuteScalp(OP_SELL, "Momentum Bear");
         CurrentSignal = "MOMENTUM SELL";
      }
   }
}

void ExecuteOrderFlowScalp()
{
   // Strong bullish order flow
   if(OrderFlowBias > 0.3 && MarketCondition == "BULLISH TREND")
   {
      if(!HasLongPosition())
      {
         ExecuteScalp(OP_BUY, "Order Flow Bull");
         CurrentSignal = "ORDER FLOW BUY";
      }
   }

   // Strong bearish order flow
   if(OrderFlowBias < -0.3 && MarketCondition == "BEARISH TREND")
   {
      if(!HasShortPosition())
      {
         ExecuteScalp(OP_SELL, "Order Flow Bear");
         CurrentSignal = "ORDER FLOW SELL";
      }
   }
}

//+------------------------------------------------------------------+
//| Execute scalp                                                   |
//+------------------------------------------------------------------+
void ExecuteScalp(int orderType, string strategy)
{
   double lotSize = CalculateScalpLotSize();
   double price = (orderType == OP_BUY) ? Ask : Bid;
   double sl = CalculateStopLoss(orderType, price);
   double tp = CalculateTakeProfit(orderType, price);

   int ticket = OrderSend(Symbol(), orderType, lotSize, price, 3, sl, tp,
                         "SCALP: " + strategy, MagicNumberScalp, 0,
                         (orderType == OP_BUY) ? ProfitColorScalp : LossColorScalp);

   if(ticket > 0)
   {
      TotalScalps++;
      ScalpsToday++;
      ScalpsThisHour++;
      LastScalpTime = TimeCurrent();

      Print("Scalp executed: ", strategy, " | Type: ", (orderType == OP_BUY ? "BUY" : "SELL"),
            " | Lot: ", lotSize, " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("Scalp failed: ", GetLastError(), " | Strategy: ", strategy);
   }
}

double CalculateScalpLotSize()
{
   double accountValue = AccountEquity();
   double riskAmount = accountValue * (RiskPercentPerTrade / 100.0);

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

   if(orderType == OP_BUY)
      tp = price + tpDistance;
   else
      tp = price - tpDistance;

   return tp;
}

//+------------------------------------------------------------------+
//| Position management                                             |
//+------------------------------------------------------------------+
void ManageScalpPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberScalp)
      {
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
            OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0, ProfitColorScalp);
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
            OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0, LossColorScalp);
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
         OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0, ProfitColorScalp);
         Print("Break-even applied for BUY scalp");
      }
   }
   else
   {
      double profit = (openPrice - currentPrice) / Point;
      if(profit >= BreakEvenPips * 10 && (currentSL > openPrice || currentSL == 0))
      {
         double newSL = openPrice - (BreakEvenPlusPips * 10 * Point);
         OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0, LossColorScalp);
         Print("Break-even applied for SELL scalp");
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
      Print("Scalp closed due to spread widening");
   }

   // Exit if market condition changes drastically
   if(MarketCondition == "HIGH SPREAD" || MarketCondition == "HIGH VOLATILITY")
   {
      double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
      OrderClose(OrderTicket(), OrderLots(), closePrice, 3, clrOrange);
      Print("Scalp closed due to unfavorable market condition");
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
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberScalp)
         count++;
   }
   return count;
}

bool HasLongPosition()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() &&
         OrderMagicNumber() == MagicNumberScalp && OrderType() == OP_BUY)
         return true;
   }
   return false;
}

bool HasShortPosition()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() &&
         OrderMagicNumber() == MagicNumberScalp && OrderType() == OP_SELL)
         return true;
   }
   return false;
}

void CloseAllPositions(string reason)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberScalp)
      {
         double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
         OrderClose(OrderTicket(), OrderLots(), closePrice, 3);
      }
   }
   Print("All scalp positions closed: ", reason);
}

void ResetDailyCounters()
{
   ScalpsToday = 0;
   DailyPnL = 0;
   StartOfDay = TimeCurrent();
   Print("Daily counters reset for new trading day");
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
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberScalp)
      {
         double pnl = OrderProfit() + OrderSwap() + OrderCommission();
         DailyPnL += pnl;
         SessionPnL += pnl;
      }
   }

   // Closed positions from today
   TotalPips = 0;
   WinningScalps = 0;
   LosingScalps = 0;

   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberScalp)
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
               WinningScalps++;
               if(pips > BestScalp) BestScalp = pips;
            }
            else
            {
               LosingScalps++;
               if(pips < WorstScalp) WorstScalp = pips;
            }
         }
      }
   }
}

void CalculateWinRate()
{
   int totalCompleted = WinningScalps + LosingScalps;
   if(totalCompleted > 0)
      WinRate = ((double)WinningScalps / totalCompleted) * 100;
   else
      WinRate = 0;
}

void CalculateProfitFactorMetric()
{
   double totalProfit = 0;
   double totalLoss = 0;

   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumberScalp)
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
   int totalCompleted = WinningScalps + LosingScalps;
   if(totalCompleted > 0)
      AveragePips = TotalPips / totalCompleted;
   else
      AveragePips = 0;
}

//+------------------------------------------------------------------+
//| Dashboard functions                                             |
//+------------------------------------------------------------------+
void CreateScalpDashboard()
{
   // Background
   ObjectCreate("Scalp_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "Scalp_BG", OBJPROP_XDISTANCE, DashX);
   ObjectSetInteger(0, "Scalp_BG", OBJPROP_YDISTANCE, DashY);
   ObjectSetInteger(0, "Scalp_BG", OBJPROP_XSIZE, 420);
   ObjectSetInteger(0, "Scalp_BG", OBJPROP_YSIZE, 480);
   ObjectSetInteger(0, "Scalp_BG", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "Scalp_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "Scalp_BG", OBJPROP_COLOR, clrGold);

   // Labels
   CreateDashLabel("Scalp_Title", "GBP/USD SCALPER PRO", DashX + 10, DashY + 10, clrGold, 14);
   CreateDashLabel("Scalp_Session", "", DashX + 10, DashY + 35, clrWhite, 10);
   CreateDashLabel("Scalp_Condition", "", DashX + 10, DashY + 55, clrWhite, 9);
   CreateDashLabel("Scalp_Signal", "", DashX + 10, DashY + 75, clrWhite, 9);
   CreateDashLabel("Scalp_Spread", "", DashX + 10, DashY + 100, clrWhite, 9);
   CreateDashLabel("Scalp_ATR", "", DashX + 10, DashY + 120, clrWhite, 9);
   CreateDashLabel("Scalp_OrderFlow", "", DashX + 10, DashY + 140, clrWhite, 9);
   CreateDashLabel("Scalp_Balance", "", DashX + 10, DashY + 165, clrWhite, 9);
   CreateDashLabel("Scalp_Equity", "", DashX + 10, DashY + 185, clrWhite, 9);
   CreateDashLabel("Scalp_SessionPL", "", DashX + 10, DashY + 205, clrWhite, 10);
   CreateDashLabel("Scalp_DailyPL", "", DashX + 10, DashY + 225, clrWhite, 10);
   CreateDashLabel("Scalp_Drawdown", "", DashX + 10, DashY + 245, clrWhite, 9);
   CreateDashLabel("Scalp_TotalPips", "", DashX + 10, DashY + 270, clrWhite, 9);
   CreateDashLabel("Scalp_AvgPips", "", DashX + 10, DashY + 290, clrWhite, 9);
   CreateDashLabel("Scalp_BestWorst", "", DashX + 10, DashY + 310, clrWhite, 9);
   CreateDashLabel("Scalp_ScalpsToday", "", DashX + 10, DashY + 335, clrWhite, 9);
   CreateDashLabel("Scalp_ScalpsHour", "", DashX + 10, DashY + 355, clrWhite, 9);
   CreateDashLabel("Scalp_WinRate", "", DashX + 10, DashY + 375, clrWhite, 9);
   CreateDashLabel("Scalp_ProfitFactor", "", DashX + 10, DashY + 395, clrWhite, 9);
   CreateDashLabel("Scalp_Positions", "", DashX + 10, DashY + 420, clrWhite, 9);
   CreateDashLabel("Scalp_Time", "", DashX + 10, DashY + 440, clrWhite, 9);
}

void CreateDashLabel(string name, string text, int x, int y, color clr, int size)
{
   ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(name, text, size, "Arial Bold", clr);
   ObjectSet(name, OBJPROP_XDISTANCE, x);
   ObjectSet(name, OBJPROP_YDISTANCE, y);
   ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void UpdateScalpDashboard()
{
   if(!ShowScalpDashboard) return;

   // Session
   color sessionColor = InTradingWindow ? clrLimeGreen : clrRed;
   ObjectSetText("Scalp_Session", "Session: " + TradingSession, 10, "Arial Bold", sessionColor);

   // Market condition
   color conditionColor = (MarketCondition == "BULLISH TREND") ? ProfitColorScalp :
                         (MarketCondition == "BEARISH TREND") ? LossColorScalp : NeutralColorScalp;
   ObjectSetText("Scalp_Condition", "Market: " + MarketCondition, 9, "Arial Bold", conditionColor);

   // Signal
   ObjectSetText("Scalp_Signal", "Signal: " + CurrentSignal, 9, "Arial", clrWhite);

   // Spread
   color spreadColor = (CurrentSpread <= MaxSpreadPoints * 0.5) ? ProfitColorScalp :
                      (CurrentSpread <= MaxSpreadPoints) ? NeutralColorScalp : LossColorScalp;
   ObjectSetText("Scalp_Spread", "Spread: " + DoubleToStr(CurrentSpread, 1) + " pts", 9, "Arial Bold", spreadColor);

   // ATR
   color atrColor = (CurrentVolatility >= MinATRPips && CurrentVolatility <= MaxATRPips) ? ProfitColorScalp : NeutralColorScalp;
   ObjectSetText("Scalp_ATR", "Volatility: " + DoubleToStr(CurrentVolatility, 1) + " pips", 9, "Arial Bold", atrColor);

   // Order flow
   color flowColor = (OrderFlowBias > 0.2) ? ProfitColorScalp : (OrderFlowBias < -0.2) ? LossColorScalp : clrWhite;
   string flowText = (OrderFlowBias > 0) ? "BULLISH" : (OrderFlowBias < 0) ? "BEARISH" : "NEUTRAL";
   ObjectSetText("Scalp_OrderFlow", "Order Flow: " + flowText + " (" + DoubleToStr(OrderFlowBias, 2) + ")", 9, "Arial Bold", flowColor);

   // Account info
   ObjectSetText("Scalp_Balance", "Balance: $" + DoubleToStr(AccountBalance(), 2), 9, "Arial", clrWhite);
   ObjectSetText("Scalp_Equity", "Equity: $" + DoubleToStr(AccountEquity(), 2), 9, "Arial", clrWhite);

   // P&L
   color sessionColor2 = (SessionPnL >= 0) ? ProfitColorScalp : LossColorScalp;
   ObjectSetText("Scalp_SessionPL", "Session P&L: $" + DoubleToStr(SessionPnL, 2), 10, "Arial Bold", sessionColor2);

   color dailyColor = (DailyPnL >= 0) ? ProfitColorScalp : LossColorScalp;
   ObjectSetText("Scalp_DailyPL", "Daily P&L: $" + DoubleToStr(DailyPnL, 2), 10, "Arial Bold", dailyColor);

   // Drawdown
   color ddColor = (CurrentDrawdown < 3) ? ProfitColorScalp : (CurrentDrawdown < 6) ? NeutralColorScalp : LossColorScalp;
   ObjectSetText("Scalp_Drawdown", "Drawdown: " + DoubleToStr(CurrentDrawdown, 2) + "%", 9, "Arial Bold", ddColor);

   // Pips
   color pipsColor = (TotalPips >= 0) ? ProfitColorScalp : LossColorScalp;
   ObjectSetText("Scalp_TotalPips", "Total Pips: " + DoubleToStr(TotalPips, 1), 9, "Arial Bold", pipsColor);

   color avgColor = (AveragePips >= 0) ? ProfitColorScalp : LossColorScalp;
   ObjectSetText("Scalp_AvgPips", "Avg Pips/Trade: " + DoubleToStr(AveragePips, 2), 9, "Arial", avgColor);

   ObjectSetText("Scalp_BestWorst", "Best: " + DoubleToStr(BestScalp, 1) + " | Worst: " + DoubleToStr(WorstScalp, 1), 9, "Arial", clrWhite);

   // Scalp counts
   string scalpsText = IntegerToString(ScalpsToday) + "/" + IntegerToString(MaxScalpsPerDay);
   color scalpsColor = (ScalpsToday >= MaxScalpsPerDay) ? LossColorScalp : clrWhite;
   ObjectSetText("Scalp_ScalpsToday", "Scalps Today: " + scalpsText, 9, "Arial", scalpsColor);

   string hourText = IntegerToString(ScalpsThisHour) + "/" + IntegerToString(MaxScalpsPerHour);
   ObjectSetText("Scalp_ScalpsHour", "Scalps This Hour: " + hourText, 9, "Arial", clrWhite);

   // Win rate
   color wrColor = (WinRate >= 60) ? ProfitColorScalp : (WinRate >= 45) ? NeutralColorScalp : LossColorScalp;
   ObjectSetText("Scalp_WinRate", "Win Rate: " + DoubleToStr(WinRate, 1) + "% (" + IntegerToString(WinningScalps) + "W/" + IntegerToString(LosingScalps) + "L)", 9, "Arial Bold", wrColor);

   // Profit factor
   color pfColor = (ProfitFactor >= 2.0) ? ProfitColorScalp : (ProfitFactor >= 1.0) ? NeutralColorScalp : LossColorScalp;
   ObjectSetText("Scalp_ProfitFactor", "Profit Factor: " + DoubleToStr(ProfitFactor, 2), 9, "Arial Bold", pfColor);

   // Positions
   ObjectSetText("Scalp_Positions", "Open Positions: " + IntegerToString(CountPositions()), 9, "Arial", clrWhite);

   // Time
   ObjectSetText("Scalp_Time", "Time: " + TimeToString(TimeCurrent(), TIME_SECONDS), 9, "Arial", clrGray);
}

void DeleteScalpDashboard()
{
   ObjectDelete("Scalp_BG");
   ObjectDelete("Scalp_Title");
   ObjectDelete("Scalp_Session");
   ObjectDelete("Scalp_Condition");
   ObjectDelete("Scalp_Signal");
   ObjectDelete("Scalp_Spread");
   ObjectDelete("Scalp_ATR");
   ObjectDelete("Scalp_OrderFlow");
   ObjectDelete("Scalp_Balance");
   ObjectDelete("Scalp_Equity");
   ObjectDelete("Scalp_SessionPL");
   ObjectDelete("Scalp_DailyPL");
   ObjectDelete("Scalp_Drawdown");
   ObjectDelete("Scalp_TotalPips");
   ObjectDelete("Scalp_AvgPips");
   ObjectDelete("Scalp_BestWorst");
   ObjectDelete("Scalp_ScalpsToday");
   ObjectDelete("Scalp_ScalpsHour");
   ObjectDelete("Scalp_WinRate");
   ObjectDelete("Scalp_ProfitFactor");
   ObjectDelete("Scalp_Positions");
   ObjectDelete("Scalp_Time");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(ShowScalpDashboard)
      UpdateScalpDashboard();
}
//+------------------------------------------------------------------+
