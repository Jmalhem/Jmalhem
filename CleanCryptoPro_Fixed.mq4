//+------------------------------------------------------------------+
//|                                     CleanCryptoPro_Fixed.mq4    |
//|                          Professional Crypto Trading - DEBUGGED |
//|                           All Bugs Fixed & Optimized Version    |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Systems"
#property version   "2.00"
#property strict

// === CRYPTO STRATEGY ===
input string ___STRATEGY___ = "=== CRYPTO STRATEGY ===";
input bool EnableVolatilityTrading = true;
input bool EnableMomentumTrading = true;
input bool EnableTrendFollowing = true;
input bool EnableMeanReversion = true;
input bool Enable24HourTrading = true;
input double BaseCryptoRisk = 3.0;
input double MaxCryptoRisk = 15.0;
input int MaxPositions = 2;

// === CRYPTO TYPE ===
input string ___CRYPTO_TYPE___ = "=== CRYPTO DETECTION ===";
input bool AutoDetectCrypto = true;
input double BitcoinMultiplier = 1.0;
input double EthereumMultiplier = 1.2;
input double AltcoinMultiplier = 0.8;
input double DeFiMultiplier = 0.6;

// === VOLATILITY MANAGEMENT ===
input string ___VOLATILITY___ = "=== VOLATILITY SETTINGS ===";
input double MaxVolatilityThreshold = 15.0;
input double MinVolatilityThreshold = 2.0;
input bool UseVolatilityBreakouts = true;
input double BreakoutMultiplier = 3.0;
input bool UseVolatilityScaling = true;

// === TECHNICAL INDICATORS ===
input string ___INDICATORS___ = "=== TECHNICAL INDICATORS ===";
input int FastMA = 12;
input int SlowMA = 26;
input int SignalMA = 9;
input int RSI_Period = 14;
input int RSI_OverboughtLevel = 70;
input int RSI_OversoldLevel = 30;
input int BB_Period = 20;
input double BB_Deviation = 2.0;
input int ATR_Period = 20;

// === RISK MANAGEMENT ===
input string ___RISK_MGMT___ = "=== RISK MANAGEMENT ===";
input bool UseATRStops = true;
input double ATR_StopMultiplier = 2.5;
input double ATR_TargetMultiplier = 5.0;
input bool UsePercentageStops = true;
input double PercentageStopLevel = 4.0;
input bool UseTrailingStops = true;
input double TrailingStopPercent = 6.0;
input bool UseBreakEven = true;
input double BreakEvenThreshold = 2.5;
input double PartialCloseDrawdown = 15.0;
input double FullCloseDrawdown = 25.0;

// === TIME FILTERS ===
input string ___TIME_FILTERS___ = "=== TIME MANAGEMENT ===";
input bool UseTimeFilters = false;
input bool AvoidMajorNews = true;
input int MagicNumber = 666000;

// === DASHBOARD ===
input string ___DASHBOARD___ = "=== DASHBOARD SETTINGS ===";
input bool ShowDashboard = true;
input int DashboardX = 20;
input int DashboardY = 30;
input color BitcoinColor = clrOrange;
input color EthereumColor = clrBlue;
input color AltcoinColor = clrPurple;
input color ProfitColor = clrLimeGreen;
input color LossColor = clrRed;

// === GLOBAL VARIABLES ===
datetime LastAnalysisTime = 0;
datetime LastDashboardUpdate = 0;
string CryptocurrencyName = "";
int CryptoType = 0;
double CryptoMultiplier = 1.0;

// Market analysis
double CurrentVolatility = 0;
double MomentumStrength = 0;
double TrendStrength = 0;
string MarketPhase = "";
double Fear_Greed_Index = 50;
bool VolatilityExpansion = false;
string VolatilityRegime = "";

// Performance tracking
double HourlyPnL = 0;
double DailyPnL = 0;
double MaxEquity = 0;
double CurrentDrawdown = 0;
int TotalTrades = 0;
int WinningTrades = 0;
int LosingTrades = 0;
double ProfitFactor = 0;
string CurrentSignal = "";
double TotalProfit = 0;
double TotalLoss = 0;

// Order modification tracking
datetime LastModificationTime[];
int LastModificationAttempt[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== CLEAN CRYPTO PRO EA V2.0 - FIXED & OPTIMIZED ===");

   // Auto-detect cryptocurrency
   if(AutoDetectCrypto)
      DetectCryptocurrency();

   // Initialize variables
   MaxEquity = AccountEquity();
   CurrentVolatility = 0;
   MomentumStrength = 0;
   TrendStrength = 0;
   MarketPhase = "UNKNOWN";
   VolatilityRegime = "NORMAL";

   // Initialize tracking arrays
   ArrayResize(LastModificationTime, 1000);
   ArrayResize(LastModificationAttempt, 1000);
   ArrayInitialize(LastModificationTime, 0);
   ArrayInitialize(LastModificationAttempt, 0);

   // Create dashboard
   if(ShowDashboard)
      CreateDashboard();

   // Set timer for 5-second updates
   EventSetTimer(5);

   Print("Detected Cryptocurrency: ", CryptocurrencyName);
   Print("Crypto Type: ", CryptoType);
   Print("Crypto Multiplier: ", CryptoMultiplier);
   Print("24/7 Trading: ", Enable24HourTrading ? "Enabled" : "Disabled");
   Print("Risk per Trade: ", BaseCryptoRisk, "% | Max Risk: ", MaxCryptoRisk, "%");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   if(ShowDashboard)
      DeleteDashboard();

   Print("=== CLEAN CRYPTO PRO EA DEINITIALIZED ===");
   Print("Cryptocurrency: ", CryptocurrencyName);
   Print("Total Trades: ", TotalTrades);
   Print("Winning Trades: ", WinningTrades);
   Print("Losing Trades: ", LosingTrades);
   if(TotalTrades > 0)
      Print("Win Rate: ", DoubleToStr((double)WinningTrades/TotalTrades*100, 1), "%");
   Print("Profit Factor: ", DoubleToStr(ProfitFactor, 2));
   Print("Final P&L: $", DoubleToStr(DailyPnL, 2));
   Print("Max Drawdown: ", DoubleToStr(CurrentDrawdown, 2), "%");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Process on new bar only
   if(Time[0] == LastAnalysisTime)
      return;
   LastAnalysisTime = Time[0];

   // Comprehensive crypto analysis
   AnalyzeCryptoMarket();

   // Risk validation
   if(!ValidateRiskLimits())
      return;

   // Manage existing positions
   ManagePositions();

   // Execute trading strategies
   ExecuteCryptoStrategies();

   // Update performance metrics
   UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Timer function - Dashboard updates only                         |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(ShowDashboard)
   {
      // Update dashboard every 5 seconds instead of every tick
      UpdateDashboard();
      LastDashboardUpdate = TimeCurrent();
   }

   // Update performance metrics
   UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Cryptocurrency detection - Improved                             |
//+------------------------------------------------------------------+
void DetectCryptocurrency()
{
   string symbol = Symbol();
   StringToUpper(symbol);

   // More robust detection with exact matching
   if(StringFind(symbol, "BTCUSD") >= 0 || StringFind(symbol, "XBTUSD") >= 0 ||
      StringFind(symbol, "BITCOIN") >= 0)
   {
      CryptocurrencyName = "BITCOIN";
      CryptoType = 1;
      CryptoMultiplier = BitcoinMultiplier;
   }
   else if(StringFind(symbol, "ETHUSD") >= 0 || StringFind(symbol, "ETHEREUM") >= 0)
   {
      CryptocurrencyName = "ETHEREUM";
      CryptoType = 2;
      CryptoMultiplier = EthereumMultiplier;
   }
   else if(StringFind(symbol, "ADAUSD") >= 0 || StringFind(symbol, "DOTUSD") >= 0 ||
           StringFind(symbol, "LINKUSD") >= 0 || StringFind(symbol, "XRPUSD") >= 0 ||
           StringFind(symbol, "SOLUSD") >= 0 || StringFind(symbol, "AVAXUSD") >= 0)
   {
      CryptocurrencyName = "ALTCOIN";
      CryptoType = 3;
      CryptoMultiplier = AltcoinMultiplier;
   }
   else if(StringFind(symbol, "UNIUSD") >= 0 || StringFind(symbol, "AAVEUSD") >= 0 ||
           StringFind(symbol, "COMPUSD") >= 0 || StringFind(symbol, "MKRUSD") >= 0)
   {
      CryptocurrencyName = "DEFI";
      CryptoType = 4;
      CryptoMultiplier = DeFiMultiplier;
   }
   else
   {
      CryptocurrencyName = "UNKNOWN_CRYPTO";
      CryptoType = 0;
      CryptoMultiplier = 1.0;
   }
}

//+------------------------------------------------------------------+
//| Crypto market analysis - Fixed                                  |
//+------------------------------------------------------------------+
void AnalyzeCryptoMarket()
{
   AnalyzeCryptoVolatility();
   AnalyzeMomentumAndTrend();
   DetermineMarketPhase();
   UpdateFearGreedIndex();
}

void AnalyzeCryptoVolatility()
{
   // Use completed bars only
   double atr = iATR(Symbol(), 0, ATR_Period, 1);
   double typicalPrice = (High[1] + Low[1] + Close[1]) / 3.0; // Fixed: Use typical price

   if(typicalPrice > 0)
      CurrentVolatility = (atr / typicalPrice) * 100.0;
   else
      CurrentVolatility = 0;

   // Determine volatility regime (don't overwrite MarketPhase here)
   if(CurrentVolatility > MaxVolatilityThreshold)
      VolatilityRegime = "EXTREME";
   else if(CurrentVolatility > MaxVolatilityThreshold * 0.7)
      VolatilityRegime = "HIGH";
   else if(CurrentVolatility < MinVolatilityThreshold)
      VolatilityRegime = "LOW";
   else
      VolatilityRegime = "NORMAL";

   // Check for volatility expansion using completed bars
   double currentRange = High[1] - Low[1];
   double avgRange = CalculateAverageRange(20);

   if(avgRange > 0 && currentRange > avgRange * 2.0)
      VolatilityExpansion = true;
   else
      VolatilityExpansion = false;
}

double CalculateAverageRange(int period)
{
   double avgRange = 0;
   for(int i = 1; i <= period; i++)
   {
      avgRange += High[i] - Low[i];
   }
   if(period > 0)
      return avgRange / period;
   return 0;
}

void AnalyzeMomentumAndTrend()
{
   // Multi-indicator momentum analysis - Fixed RSI scaling
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
   double macd_main = iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, 1);
   double macd_signal = iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_SIGNAL, 1);

   // Calculate momentum strength with balanced contributions
   MomentumStrength = 0;

   // RSI component - Fixed: Proper scaling
   if(rsi > 70)
      MomentumStrength += 0.5;
   else if(rsi < 30)
      MomentumStrength -= 0.5;
   else
      MomentumStrength += (rsi - 50) / 40.0; // Fixed: Changed from /100 to /40 for proper scaling

   // MACD component
   if(macd_main > macd_signal && macd_main > 0)
      MomentumStrength += 0.5;
   else if(macd_main < macd_signal && macd_main < 0)
      MomentumStrength -= 0.5;
   else if(macd_main > macd_signal)
      MomentumStrength += 0.25;
   else if(macd_main < macd_signal)
      MomentumStrength -= 0.25;

   MomentumStrength = MathMax(-1.0, MathMin(1.0, MomentumStrength));

   // Trend strength analysis with gradient measurement
   double ema_fast = iMA(Symbol(), 0, FastMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double ema_slow = iMA(Symbol(), 0, SlowMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double close = Close[1];

   // Calculate trend strength with price distance from EMAs
   double priceAboveFast = 0;
   double fastAboveSlow = 0;

   if(ema_fast != 0)
      priceAboveFast = (close - ema_fast) / ema_fast;
   if(ema_slow != 0)
      fastAboveSlow = (ema_fast - ema_slow) / ema_slow;

   TrendStrength = 0;

   if(close > ema_fast && ema_fast > ema_slow)
   {
      // Strong uptrend - measure strength by separation
      TrendStrength = 0.6 + MathMin(0.4, (priceAboveFast + fastAboveSlow) * 20);
   }
   else if(close < ema_fast && ema_fast < ema_slow)
   {
      // Strong downtrend
      TrendStrength = -0.6 + MathMax(-0.4, (priceAboveFast + fastAboveSlow) * 20);
   }
   else if(close > ema_slow)
   {
      TrendStrength = 0.3;
   }
   else if(close < ema_slow)
   {
      TrendStrength = -0.3;
   }

   TrendStrength = MathMax(-1.0, MathMin(1.0, TrendStrength));
}

void DetermineMarketPhase()
{
   // Combine volatility regime, momentum, and trend
   // Fixed: Don't overwrite VolatilityRegime, create comprehensive MarketPhase

   if(VolatilityRegime == "EXTREME")
   {
      if(MathAbs(MomentumStrength) > 0.6)
         MarketPhase = "VOLATILE_MOMENTUM";
      else
         MarketPhase = "VOLATILE_CHOPPY";
   }
   else if(MathAbs(TrendStrength) > 0.7 && MathAbs(MomentumStrength) > 0.5)
   {
      if(TrendStrength > 0)
         MarketPhase = "STRONG_UPTREND";
      else
         MarketPhase = "STRONG_DOWNTREND";
   }
   else if(MathAbs(MomentumStrength) > 0.6)
   {
      if(MomentumStrength > 0)
         MarketPhase = "BULLISH_MOMENTUM";
      else
         MarketPhase = "BEARISH_MOMENTUM";
   }
   else if(VolatilityRegime == "LOW")
   {
      MarketPhase = "ACCUMULATION";
   }
   else
   {
      MarketPhase = "RANGING";
   }
}

void UpdateFearGreedIndex()
{
   // Improved Fear & Greed calculation with normalized volatility impact
   double normalizedVolatility = MathMin(CurrentVolatility / MaxVolatilityThreshold, 1.0);

   Fear_Greed_Index = 50.0 + (MomentumStrength * 25.0) + (TrendStrength * 15.0)
                      - (normalizedVolatility * 10.0); // Fixed: Normalized volatility impact

   Fear_Greed_Index = MathMax(0, MathMin(100, Fear_Greed_Index));
}

//+------------------------------------------------------------------+
//| Risk validation - Enhanced with error handling                  |
//+------------------------------------------------------------------+
bool ValidateRiskLimits()
{
   // Update drawdown
   double currentEquity = AccountEquity();
   if(currentEquity > MaxEquity)
      MaxEquity = currentEquity;

   if(MaxEquity > 0)
      CurrentDrawdown = ((MaxEquity - currentEquity) / MaxEquity) * 100.0;
   else
      CurrentDrawdown = 0;

   // Partial closure at moderate drawdown
   if(CurrentDrawdown > PartialCloseDrawdown && CurrentDrawdown < FullCloseDrawdown)
   {
      Print("Partial drawdown protection triggered: ", CurrentDrawdown, "%");
      ClosePartialPositions("Partial drawdown protection");
      return false; // Don't open new positions
   }

   // Full closure at extreme drawdown
   if(CurrentDrawdown > FullCloseDrawdown)
   {
      Print("Full drawdown limit exceeded: ", CurrentDrawdown, "%");
      CloseAllPositions("Full drawdown protection");
      return false;
   }

   // Check maximum risk
   double currentRisk = CalculateCurrentRisk();
   if(currentRisk > MaxCryptoRisk)
   {
      Print("Maximum crypto risk exceeded: ", currentRisk, "%");
      return false;
   }

   // Maximum positions
   if(CountPositions() >= MaxPositions)
      return false;

   return true;
}

double CalculateCurrentRisk()
{
   double totalRisk = 0;
   double accountValue = AccountEquity();

   if(accountValue <= 0)
      return 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS))
         continue;

      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         double positionRisk = CalculatePositionRisk();
         totalRisk += positionRisk;
      }
   }

   return (totalRisk / accountValue) * 100.0;
}

double CalculatePositionRisk()
{
   double openPrice = OrderOpenPrice();
   double stopLoss = OrderStopLoss();
   double lots = OrderLots();

   if(stopLoss == 0)
   {
      // Estimate risk using percentage stop
      double riskPercent = UsePercentageStops ? PercentageStopLevel : 5.0;
      stopLoss = (OrderType() == OP_BUY) ?
                 openPrice * (1.0 - riskPercent/100.0) :
                 openPrice * (1.0 + riskPercent/100.0);
   }

   double riskPerUnit = MathAbs(openPrice - stopLoss);
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);

   // Fixed: Proper error handling
   if(tickValue > 0 && tickSize > 0)
      return lots * riskPerUnit * tickValue / tickSize;

   // Fallback calculation if MarketInfo fails
   return lots * riskPerUnit * 10; // Conservative estimate
}

//+------------------------------------------------------------------+
//| Strategy execution with priority system                         |
//+------------------------------------------------------------------+
void ExecuteCryptoStrategies()
{
   CurrentSignal = "NONE";

   // Strategy priority: Trend > Momentum > Volatility > Mean Reversion
   // Only execute highest priority strategy that matches

   if(EnableTrendFollowing && StringFind(MarketPhase, "TREND") >= 0)
   {
      ExecuteTrendStrategy();
      return; // Exit after executing highest priority
   }

   if(EnableMomentumTrading && StringFind(MarketPhase, "MOMENTUM") >= 0)
   {
      ExecuteMomentumStrategy();
      return;
   }

   if(EnableVolatilityTrading && StringFind(MarketPhase, "VOLATILE") >= 0)
   {
      ExecuteVolatilityStrategy();
      return;
   }

   if(EnableMeanReversion && MarketPhase == "RANGING")
   {
      ExecuteMeanReversionStrategy();
      return;
   }
}

void ExecuteVolatilityStrategy()
{
   if(VolatilityExpansion && MathAbs(MomentumStrength) > 0.4)
   {
      if(MomentumStrength > 0 && !HasLongPosition())
      {
         double lotSize = CalculateCryptoLotSize(0.8);
         if(lotSize > 0)
         {
            OpenCryptoPosition(OP_BUY, "Volatility Breakout", lotSize);
            CurrentSignal = "VOLATILITY_BUY";
         }
      }
      else if(MomentumStrength < 0 && !HasShortPosition())
      {
         double lotSize = CalculateCryptoLotSize(0.8);
         if(lotSize > 0)
         {
            OpenCryptoPosition(OP_SELL, "Volatility Breakdown", lotSize);
            CurrentSignal = "VOLATILITY_SELL";
         }
      }
   }
}

void ExecuteTrendStrategy()
{
   if(MathAbs(TrendStrength) > 0.7 && MathAbs(MomentumStrength) > 0.5)
   {
      if(TrendStrength > 0 && MomentumStrength > 0 && !HasLongPosition())
      {
         double lotSize = CalculateCryptoLotSize(1.0);
         if(lotSize > 0)
         {
            OpenCryptoPosition(OP_BUY, "Crypto Trend Bull", lotSize);
            CurrentSignal = "TREND_BUY";
         }
      }
      else if(TrendStrength < 0 && MomentumStrength < 0 && !HasShortPosition())
      {
         double lotSize = CalculateCryptoLotSize(1.0);
         if(lotSize > 0)
         {
            OpenCryptoPosition(OP_SELL, "Crypto Trend Bear", lotSize);
            CurrentSignal = "TREND_SELL";
         }
      }
   }
}

void ExecuteMeanReversionStrategy()
{
   double bb_upper = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 1);
   double bb_lower = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 1);
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
   double close = Close[1];

   // Fixed: Use strict inequality to avoid edge cases
   if(close < bb_lower && rsi < RSI_OversoldLevel && MomentumStrength > -0.8 && !HasLongPosition())
   {
      double lotSize = CalculateCryptoLotSize(0.7);
      if(lotSize > 0)
      {
         OpenCryptoPosition(OP_BUY, "Crypto Mean Rev Bull", lotSize);
         CurrentSignal = "MEAN_REV_BUY";
      }
   }

   if(close > bb_upper && rsi > RSI_OverboughtLevel && MomentumStrength < 0.8 && !HasShortPosition())
   {
      double lotSize = CalculateCryptoLotSize(0.7);
      if(lotSize > 0)
      {
         OpenCryptoPosition(OP_SELL, "Crypto Mean Rev Bear", lotSize);
         CurrentSignal = "MEAN_REV_SELL";
      }
   }
}

void ExecuteMomentumStrategy()
{
   if(MathAbs(MomentumStrength) > 0.6 && CurrentVolatility > MinVolatilityThreshold)
   {
      if(MomentumStrength > 0.6 && !HasLongPosition())
      {
         double lotSize = CalculateCryptoLotSize(1.0);
         if(lotSize > 0)
         {
            OpenCryptoPosition(OP_BUY, "Crypto Momentum", lotSize);
            CurrentSignal = "MOMENTUM_BUY";
         }
      }
      else if(MomentumStrength < -0.6 && !HasShortPosition())
      {
         double lotSize = CalculateCryptoLotSize(1.0);
         if(lotSize > 0)
         {
            OpenCryptoPosition(OP_SELL, "Crypto Momentum", lotSize);
            CurrentSignal = "MOMENTUM_SELL";
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Position management - Enhanced                                   |
//+------------------------------------------------------------------+
void OpenCryptoPosition(int orderType, string strategy, double lots)
{
   double price = (orderType == OP_BUY) ? Ask : Bid;
   double sl = CalculateCryptoStopLoss(orderType, price);
   double tp = CalculateCryptoTakeProfit(orderType, price);

   // Validate lot size
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   if(lots < minLot)
   {
      Print("Lot size too small: ", lots, " < ", minLot);
      return;
   }

   int ticket = OrderSend(Symbol(), orderType, lots, price, 10, sl, tp,
                         strategy + " - " + CryptocurrencyName, MagicNumber, 0,
                         (orderType == OP_BUY) ? ProfitColor : LossColor);

   if(ticket > 0)
   {
      TotalTrades++;
      Print("Crypto position opened: ", strategy, " | Crypto: ", CryptocurrencyName,
            " | Lot: ", lots, " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      int error = GetLastError();
      Print("Error opening crypto position: ", error, " - ", ErrorDescription(error));
   }
}

double CalculateCryptoLotSize(double strategyMultiplier)
{
   double baseLot = 0.01;
   double accountValue = AccountEquity();

   if(accountValue <= 0)
      return 0;

   double riskAmount = accountValue * (BaseCryptoRisk / 100.0);

   // Apply strategy multiplier
   riskAmount *= strategyMultiplier;

   // Apply crypto-specific multiplier
   riskAmount *= CryptoMultiplier;

   // Fixed: More reasonable volatility adjustment
   if(UseVolatilityScaling)
   {
      if(CurrentVolatility > 12.0)
         riskAmount *= 0.6; // Reduced but not too aggressive
      else if(CurrentVolatility > 8.0)
         riskAmount *= 0.75;
      else if(CurrentVolatility > 5.0)
         riskAmount *= 0.9;
      else if(CurrentVolatility < 2.5)
         riskAmount *= 1.2;
   }

   // Calculate lot size based on stop loss
   double stopDistance;
   if(UseATRStops)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, 1);
      stopDistance = atr * ATR_StopMultiplier;
   }
   else
   {
      double price = Close[1];
      stopDistance = price * (PercentageStopLevel / 100.0);
   }

   if(stopDistance > 0)
   {
      double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
      double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);

      if(tickValue > 0 && tickSize > 0)
      {
         baseLot = riskAmount / (stopDistance * tickValue / tickSize);
      }
      else
      {
         // Fallback if MarketInfo fails
         baseLot = riskAmount / (stopDistance * 10);
      }
   }

   // Ensure within limits
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);

   if(minLot <= 0) minLot = 0.01;
   if(maxLot <= 0) maxLot = 100;

   baseLot = MathMax(minLot, MathMin(maxLot, baseLot));

   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(lotStep > 0)
      baseLot = MathRound(baseLot / lotStep) * lotStep;

   return baseLot;
}

double CalculateCryptoStopLoss(int orderType, double price)
{
   double sl = 0;
   double atrSL = 0;
   double percentSL = 0;

   if(UseATRStops)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, 1);

      if(orderType == OP_BUY)
         atrSL = price - (atr * ATR_StopMultiplier);
      else
         atrSL = price + (atr * ATR_StopMultiplier);
   }

   if(UsePercentageStops)
   {
      if(orderType == OP_BUY)
         percentSL = price * (1.0 - PercentageStopLevel / 100.0);
      else
         percentSL = price * (1.0 + PercentageStopLevel / 100.0);
   }

   // Fixed: Use tighter stop for better protection
   if(UseATRStops && UsePercentageStops)
   {
      if(orderType == OP_BUY)
         sl = MathMax(atrSL, percentSL); // Tighter (higher) stop for BUY
      else
         sl = MathMin(atrSL, percentSL); // Tighter (lower) stop for SELL
   }
   else if(UseATRStops)
   {
      sl = atrSL;
   }
   else if(UsePercentageStops)
   {
      sl = percentSL;
   }

   return sl;
}

double CalculateCryptoTakeProfit(int orderType, double price)
{
   double tp = 0;

   // Fixed: Consistent 2:1 risk-reward ratio
   if(UseATRStops)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, 1);

      if(orderType == OP_BUY)
         tp = price + (atr * ATR_TargetMultiplier);
      else
         tp = price - (atr * ATR_TargetMultiplier);
   }
   else
   {
      // 2:1 risk-reward for percentage stops
      double rewardPercent = PercentageStopLevel * 2.0;

      if(orderType == OP_BUY)
         tp = price * (1.0 + rewardPercent / 100.0);
      else
         tp = price * (1.0 - rewardPercent / 100.0);
   }

   return tp;
}

void ManagePositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      int ticket = OrderTicket();

      // Throttle modifications - don't modify same order too frequently
      if(TimeCurrent() - GetLastModificationTime(ticket) < 60)
         continue;

      // Apply break-even first (highest priority)
      if(UseBreakEven)
      {
         if(ApplyCryptoBreakEven())
         {
            SetLastModificationTime(ticket);
            continue; // Don't apply trailing stop in same iteration
         }
      }

      // Apply trailing stops
      if(UseTrailingStops)
      {
         if(ApplyCryptoTrailingStop())
         {
            SetLastModificationTime(ticket);
         }
      }

      // Check for volatility exits
      CheckVolatilityExit();
   }
}

bool ApplyCryptoTrailingStop()
{
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double openPrice = OrderOpenPrice();
   double currentSL = OrderStopLoss();

   if(OrderType() == OP_BUY)
   {
      double profit = (currentPrice - openPrice) / openPrice * 100.0;
      if(profit > BreakEvenThreshold)
      {
         double newSL = currentPrice * (1.0 - TrailingStopPercent / 100.0);

         // Only move SL up, never down
         if(newSL > currentSL && newSL < currentPrice)
         {
            if(OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0))
            {
               Print("Trailing stop updated (BUY): ", newSL);
               return true;
            }
            else
            {
               Print("Failed to modify trailing stop: ", GetLastError());
            }
         }
      }
   }
   else // OP_SELL
   {
      double profit = (openPrice - currentPrice) / openPrice * 100.0;
      if(profit > BreakEvenThreshold)
      {
         double newSL = currentPrice * (1.0 + TrailingStopPercent / 100.0);

         // Fixed: Only move SL down (for SELL), never up
         // If no SL set yet, or new SL is better (lower)
         if((currentSL == 0 || newSL < currentSL) && newSL > currentPrice)
         {
            if(OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0))
            {
               Print("Trailing stop updated (SELL): ", newSL);
               return true;
            }
            else
            {
               Print("Failed to modify trailing stop: ", GetLastError());
            }
         }
      }
   }

   return false;
}

bool ApplyCryptoBreakEven()
{
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double openPrice = OrderOpenPrice();
   double currentSL = OrderStopLoss();

   if(OrderType() == OP_BUY)
   {
      double profit = (currentPrice - openPrice) / openPrice * 100.0;

      // Only move to breakeven if not already there
      if(profit > BreakEvenThreshold && currentSL < openPrice)
      {
         double newSL = openPrice * 1.002; // Small profit lock

         if(OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0))
         {
            Print("Break-even activated (BUY): ", newSL);
            return true;
         }
         else
         {
            Print("Failed to set break-even: ", GetLastError());
         }
      }
   }
   else // OP_SELL
   {
      double profit = (openPrice - currentPrice) / openPrice * 100.0;

      // Only move to breakeven if not already there
      if(profit > BreakEvenThreshold && (currentSL > openPrice || currentSL == 0))
      {
         double newSL = openPrice * 0.998; // Small profit lock

         if(OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0))
         {
            Print("Break-even activated (SELL): ", newSL);
            return true;
         }
         else
         {
            Print("Failed to set break-even: ", GetLastError());
         }
      }
   }

   return false;
}

void CheckVolatilityExit()
{
   // Exit if volatility becomes extreme
   if(CurrentVolatility > MaxVolatilityThreshold * 1.5)
   {
      double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;

      if(OrderClose(OrderTicket(), OrderLots(), closePrice, 10))
      {
         Print("Position closed due to extreme volatility: ", CurrentVolatility, "%");
      }
      else
      {
         Print("Failed to close position (volatility exit): ", GetLastError());
      }
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
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() &&
         OrderMagicNumber() == MagicNumber)
         count++;
   }
   return count;
}

bool HasLongPosition()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() &&
         OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY)
         return true;
   }
   return false;
}

bool HasShortPosition()
{
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() &&
         OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL)
         return true;
   }
   return false;
}

void CloseAllPositions(string reason)
{
   int attempts = 0;
   int maxAttempts = 3;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
      attempts = 0;

      while(attempts < maxAttempts)
      {
         if(OrderClose(OrderTicket(), OrderLots(), closePrice, 10))
         {
            Print("Position closed: ", reason);
            break;
         }
         else
         {
            attempts++;
            Print("Failed to close position (attempt ", attempts, "): ", GetLastError());
            Sleep(1000);
         }
      }
   }

   Print("All crypto positions closed: ", reason);
}

void ClosePartialPositions(string reason)
{
   // Close 50% of positions
   int totalPos = CountPositions();
   int toClose = (int)MathCeil(totalPos / 2.0);
   int closed = 0;

   for(int i = OrdersTotal() - 1; i >= 0 && closed < toClose; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS))
         continue;

      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;

      double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;

      if(OrderClose(OrderTicket(), OrderLots(), closePrice, 10))
      {
         closed++;
         Print("Partial position closed: ", reason);
      }
      else
      {
         Print("Failed to close partial position: ", GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
//| Performance tracking - Fixed                                     |
//+------------------------------------------------------------------+
void UpdatePerformanceMetrics()
{
   CalculateDailyPnL();
   CalculateProfitFactor();
}

void CalculateDailyPnL()
{
   HourlyPnL = 0;
   DailyPnL = 0;

   // Calculate from open positions
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS))
         continue;

      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         double pnl = OrderProfit() + OrderSwap() + OrderCommission();
         HourlyPnL += pnl;
         DailyPnL += pnl;
      }
   }

   // Fixed: Count winning trades only once from history
   int historyWins = 0;
   int historyLosses = 0;

   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;

      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         if(TimeDay(OrderCloseTime()) == Day())
         {
            double pnl = OrderProfit() + OrderSwap() + OrderCommission();
            DailyPnL += pnl;

            if(pnl > 0)
               historyWins++;
            else if(pnl < 0)
               historyLosses++;
         }
      }
   }

   // Update win/loss counts (these should be cumulative from history, not incremental)
   WinningTrades = historyWins;
   LosingTrades = historyLosses;
}

void CalculateProfitFactor()
{
   TotalProfit = 0;
   TotalLoss = 0;

   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;

      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         double pnl = OrderProfit() + OrderSwap() + OrderCommission();

         if(pnl > 0)
            TotalProfit += pnl;
         else if(pnl < 0)
            TotalLoss += MathAbs(pnl);
      }
   }

   ProfitFactor = (TotalLoss > 0) ? TotalProfit / TotalLoss : 0;
}

//+------------------------------------------------------------------+
//| Order modification tracking                                      |
//+------------------------------------------------------------------+
datetime GetLastModificationTime(int ticket)
{
   int index = ticket % 1000;
   return LastModificationTime[index];
}

void SetLastModificationTime(int ticket)
{
   int index = ticket % 1000;
   LastModificationTime[index] = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Dashboard functions                                              |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   ObjectCreate("Crypto_Dashboard_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_XDISTANCE, DashboardX);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_YDISTANCE, DashboardY);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_XSIZE, 420);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_YSIZE, 450);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_WIDTH, 2);

   CreateLabel("Crypto_Title", "CLEAN CRYPTO PRO V2.0", DashboardX + 10, DashboardY + 10, clrWhite, 16);
   CreateLabel("Crypto_Name", "", DashboardX + 10, DashboardY + 35, clrWhite, 12);
   CreateLabel("Crypto_Phase", "", DashboardX + 10, DashboardY + 60, clrWhite, 10);
   CreateLabel("Crypto_VolRegime", "", DashboardX + 10, DashboardY + 80, clrWhite, 9);
   CreateLabel("Crypto_Signal", "", DashboardX + 10, DashboardY + 100, clrWhite, 9);
   CreateLabel("Crypto_Balance", "", DashboardX + 10, DashboardY + 125, clrWhite, 9);
   CreateLabel("Crypto_Equity", "", DashboardX + 10, DashboardY + 145, clrWhite, 9);
   CreateLabel("Crypto_HourlyPL", "", DashboardX + 10, DashboardY + 165, clrWhite, 9);
   CreateLabel("Crypto_DailyPL", "", DashboardX + 10, DashboardY + 185, clrWhite, 9);
   CreateLabel("Crypto_Drawdown", "", DashboardX + 10, DashboardY + 205, clrWhite, 9);
   CreateLabel("Crypto_Volatility", "", DashboardX + 10, DashboardY + 230, clrWhite, 9);
   CreateLabel("Crypto_Momentum", "", DashboardX + 10, DashboardY + 250, clrWhite, 9);
   CreateLabel("Crypto_Trend", "", DashboardX + 10, DashboardY + 270, clrWhite, 9);
   CreateLabel("Crypto_FearGreed", "", DashboardX + 10, DashboardY + 290, clrWhite, 9);
   CreateLabel("Crypto_VolExpansion", "", DashboardX + 10, DashboardY + 310, clrWhite, 9);
   CreateLabel("Crypto_Positions", "", DashboardX + 10, DashboardY + 335, clrWhite, 9);
   CreateLabel("Crypto_Trades", "", DashboardX + 10, DashboardY + 355, clrWhite, 9);
   CreateLabel("Crypto_WinRate", "", DashboardX + 10, DashboardY + 375, clrWhite, 9);
   CreateLabel("Crypto_ProfitFactor", "", DashboardX + 10, DashboardY + 395, clrWhite, 9);
   CreateLabel("Crypto_Time", "", DashboardX + 10, DashboardY + 415, clrWhite, 9);
}

void CreateLabel(string name, string text, int x, int y, color clr, int size)
{
   ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(name, text, size, "Arial Bold", clr);
   ObjectSet(name, OBJPROP_XDISTANCE, x);
   ObjectSet(name, OBJPROP_YDISTANCE, y);
   ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void UpdateDashboard()
{
   if(!ShowDashboard) return;

   // Header information
   color cryptoColor = (CryptoType == 1) ? BitcoinColor :
                      (CryptoType == 2) ? EthereumColor : AltcoinColor;
   ObjectSetText("Crypto_Name", CryptocurrencyName + " (x" + DoubleToStr(CryptoMultiplier, 1) + ")",
                 12, "Arial Bold", cryptoColor);

   // Market phase
   color phaseColor = (StringFind(MarketPhase, "BULL") >= 0 || StringFind(MarketPhase, "UP") >= 0) ? ProfitColor :
                     (StringFind(MarketPhase, "BEAR") >= 0 || StringFind(MarketPhase, "DOWN") >= 0) ? LossColor : clrYellow;
   ObjectSetText("Crypto_Phase", "Phase: " + MarketPhase, 10, "Arial Bold", phaseColor);

   // Volatility regime
   color volRegimeColor = (VolatilityRegime == "EXTREME") ? LossColor :
                          (VolatilityRegime == "HIGH") ? clrOrange :
                          (VolatilityRegime == "LOW") ? ProfitColor : clrWhite;
   ObjectSetText("Crypto_VolRegime", "Vol Regime: " + VolatilityRegime, 9, "Arial", volRegimeColor);

   ObjectSetText("Crypto_Signal", "Signal: " + CurrentSignal, 9, "Arial", clrWhite);

   // Performance
   ObjectSetText("Crypto_Balance", "Balance: $" + DoubleToStr(AccountBalance(), 2), 9, "Arial", clrWhite);
   ObjectSetText("Crypto_Equity", "Equity: $" + DoubleToStr(AccountEquity(), 2), 9, "Arial", clrWhite);

   color hourlyColor = (HourlyPnL >= 0) ? ProfitColor : LossColor;
   ObjectSetText("Crypto_HourlyPL", "Hourly P&L: $" + DoubleToStr(HourlyPnL, 2), 9, "Arial Bold", hourlyColor);

   color dailyColor = (DailyPnL >= 0) ? ProfitColor : LossColor;
   ObjectSetText("Crypto_DailyPL", "Daily P&L: $" + DoubleToStr(DailyPnL, 2), 9, "Arial Bold", dailyColor);

   color ddColor = (CurrentDrawdown > 20) ? LossColor : (CurrentDrawdown > 10) ? clrYellow : ProfitColor;
   ObjectSetText("Crypto_Drawdown", "Drawdown: " + DoubleToStr(CurrentDrawdown, 1) + "%", 9, "Arial Bold", ddColor);

   // Technical analysis
   color volColor = (CurrentVolatility > 10) ? LossColor : (CurrentVolatility < 3) ? ProfitColor : clrYellow;
   ObjectSetText("Crypto_Volatility", "Volatility: " + DoubleToStr(CurrentVolatility, 2) + "%", 9, "Arial Bold", volColor);

   color momentumColor = (MomentumStrength > 0.3) ? ProfitColor : (MomentumStrength < -0.3) ? LossColor : clrWhite;
   ObjectSetText("Crypto_Momentum", "Momentum: " + DoubleToStr(MomentumStrength, 2), 9, "Arial Bold", momentumColor);

   color trendColor = (TrendStrength > 0.3) ? ProfitColor : (TrendStrength < -0.3) ? LossColor : clrWhite;
   ObjectSetText("Crypto_Trend", "Trend: " + DoubleToStr(TrendStrength, 2), 9, "Arial Bold", trendColor);

   color fearGreedColor = (Fear_Greed_Index > 70) ? clrOrange : (Fear_Greed_Index < 30) ? clrRed : clrWhite;
   string fearGreedText = (Fear_Greed_Index > 70) ? "GREED" : (Fear_Greed_Index < 30) ? "FEAR" : "NEUTRAL";
   ObjectSetText("Crypto_FearGreed", "Fear/Greed: " + fearGreedText + " (" + DoubleToStr(Fear_Greed_Index, 0) + ")",
                 9, "Arial Bold", fearGreedColor);

   color expColor = VolatilityExpansion ? clrYellow : clrGray;
   ObjectSetText("Crypto_VolExpansion", "Vol Expansion: " + (VolatilityExpansion ? "YES" : "NO"), 9, "Arial", expColor);

   // Trading info
   int openPositions = CountPositions();
   ObjectSetText("Crypto_Positions", "Open Positions: " + IntegerToString(openPositions) + "/" +
                 IntegerToString(MaxPositions), 9, "Arial", clrWhite);

   ObjectSetText("Crypto_Trades", "Total Trades: " + IntegerToString(TotalTrades), 9, "Arial", clrWhite);

   double winRate = 0;
   if(WinningTrades + LosingTrades > 0)
      winRate = (double)WinningTrades / (WinningTrades + LosingTrades) * 100.0;

   color winRateColor = (winRate > 60) ? ProfitColor : (winRate > 45) ? clrYellow : LossColor;
   ObjectSetText("Crypto_WinRate", "Win Rate: " + DoubleToStr(winRate, 1) + "% (W:" +
                 IntegerToString(WinningTrades) + " L:" + IntegerToString(LosingTrades) + ")",
                 9, "Arial", winRateColor);

   color pfColor = (ProfitFactor > 1.5) ? ProfitColor : (ProfitFactor > 1.0) ? clrYellow : LossColor;
   ObjectSetText("Crypto_ProfitFactor", "Profit Factor: " + DoubleToStr(ProfitFactor, 2), 9, "Arial", pfColor);

   ObjectSetText("Crypto_Time", "Time: " + TimeToString(TimeCurrent(), TIME_MINUTES), 9, "Arial", clrWhite);
}

void DeleteDashboard()
{
   ObjectDelete("Crypto_Dashboard_BG");
   ObjectDelete("Crypto_Title");
   ObjectDelete("Crypto_Name");
   ObjectDelete("Crypto_Phase");
   ObjectDelete("Crypto_VolRegime");
   ObjectDelete("Crypto_Signal");
   ObjectDelete("Crypto_Balance");
   ObjectDelete("Crypto_Equity");
   ObjectDelete("Crypto_HourlyPL");
   ObjectDelete("Crypto_DailyPL");
   ObjectDelete("Crypto_Drawdown");
   ObjectDelete("Crypto_Volatility");
   ObjectDelete("Crypto_Momentum");
   ObjectDelete("Crypto_Trend");
   ObjectDelete("Crypto_FearGreed");
   ObjectDelete("Crypto_VolExpansion");
   ObjectDelete("Crypto_Positions");
   ObjectDelete("Crypto_Trades");
   ObjectDelete("Crypto_WinRate");
   ObjectDelete("Crypto_ProfitFactor");
   ObjectDelete("Crypto_Time");
}

//+------------------------------------------------------------------+
//| Error description helper                                         |
//+------------------------------------------------------------------+
string ErrorDescription(int errorCode)
{
   string errorString;

   switch(errorCode)
   {
      case 0:    errorString = "No error";                             break;
      case 1:    errorString = "No error, but result is unknown";      break;
      case 2:    errorString = "Common error";                         break;
      case 3:    errorString = "Invalid trade parameters";             break;
      case 4:    errorString = "Trade server is busy";                 break;
      case 5:    errorString = "Old version of client terminal";       break;
      case 6:    errorString = "No connection";                        break;
      case 7:    errorString = "Not enough rights";                    break;
      case 8:    errorString = "Too frequent requests";                break;
      case 9:    errorString = "Malfunctional trade operation";        break;
      case 64:   errorString = "Account disabled";                     break;
      case 65:   errorString = "Invalid account";                      break;
      case 128:  errorString = "Trade timeout";                        break;
      case 129:  errorString = "Invalid price";                        break;
      case 130:  errorString = "Invalid stops";                        break;
      case 131:  errorString = "Invalid trade volume";                 break;
      case 132:  errorString = "Market is closed";                     break;
      case 133:  errorString = "Trade is disabled";                    break;
      case 134:  errorString = "Not enough money";                     break;
      case 135:  errorString = "Price changed";                        break;
      case 136:  errorString = "Off quotes";                           break;
      case 137:  errorString = "Broker is busy";                       break;
      case 138:  errorString = "Requote";                              break;
      case 139:  errorString = "Order is locked";                      break;
      case 140:  errorString = "Long positions only allowed";          break;
      case 141:  errorString = "Too many requests";                    break;
      case 145:  errorString = "Modification denied";                  break;
      case 146:  errorString = "Trade context is busy";                break;
      case 147:  errorString = "Expiration denied";                    break;
      case 148:  errorString = "Too many open orders";                 break;
      case 149:  errorString = "Hedge prohibited";                     break;
      case 150:  errorString = "Prohibited by FIFO";                   break;
      default:   errorString = "Unknown error";
   }

   return errorString;
}

//+------------------------------------------------------------------+
