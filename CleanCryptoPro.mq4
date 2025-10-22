//+------------------------------------------------------------------+
//|                                        CleanCryptoPro.mq4       |
//|                                Professional Crypto Trading      |
//|                                     Clean & Error-Free Code     |
//+------------------------------------------------------------------+
#property copyright "Professional Trading Systems"
#property version   "1.00"
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
input double AltcoinMultiplier = 0.6;
input double DeFiMultiplier = 0.4;

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
input int RSI_OverboughtLevel = 80;
input int RSI_OversoldLevel = 20;
input int BB_Period = 20;
input double BB_Deviation = 2.5;
input int ATR_Period = 20;

// === RISK MANAGEMENT ===
input string ___RISK_MGMT___ = "=== RISK MANAGEMENT ===";
input bool UseATRStops = true;
input double ATR_StopMultiplier = 3.0;
input double ATR_TargetMultiplier = 6.0;
input bool UsePercentageStops = true;
input double PercentageStopLevel = 5.0;
input bool UseTrailingStops = true;
input double TrailingStopPercent = 8.0;
input bool UseBreakEven = true;
input double BreakEvenThreshold = 3.0;

// === TIME FILTERS ===
input string ___TIME_FILTERS___ = "=== TIME MANAGEMENT ===";
input bool UseTimeFilters = false; // Crypto trades 24/7
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

// Performance tracking
double HourlyPnL = 0;
double DailyPnL = 0;
double MaxEquity = 0;
double CurrentDrawdown = 0;
int TotalTrades = 0;
int WinningTrades = 0;
double ProfitFactor = 0;
string CurrentSignal = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== CLEAN CRYPTO PRO EA INITIALIZED ===");

   // Auto-detect cryptocurrency
   if(AutoDetectCrypto)
      DetectCryptocurrency();

   // Initialize variables
   MaxEquity = AccountEquity();
   CurrentVolatility = 0;
   MomentumStrength = 0;
   TrendStrength = 0;
   MarketPhase = "UNKNOWN";

   // Create dashboard
   if(ShowDashboard)
      CreateDashboard();

   // Set timer
   EventSetTimer(5); // 5-second updates for crypto

   Print("Detected Cryptocurrency: ", CryptocurrencyName);
   Print("Crypto Type: ", CryptoType);
   Print("Crypto Multiplier: ", CryptoMultiplier);
   Print("24/7 Trading: ", Enable24HourTrading ? "Enabled" : "Disabled");

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
   // Update dashboard
   if(ShowDashboard)
      UpdateDashboard();

   // High-frequency analysis for crypto volatility
   PerformHighFrequencyAnalysis();

   // Process on new bar
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

   // Update performance
   UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Cryptocurrency detection                                         |
//+------------------------------------------------------------------+
void DetectCryptocurrency()
{
   string symbol = Symbol();

   if(StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "BITCOIN") >= 0)
   {
      CryptocurrencyName = "BITCOIN";
      CryptoType = 1;
      CryptoMultiplier = BitcoinMultiplier;
   }
   else if(StringFind(symbol, "ETH") >= 0 || StringFind(symbol, "ETHEREUM") >= 0)
   {
      CryptocurrencyName = "ETHEREUM";
      CryptoType = 2;
      CryptoMultiplier = EthereumMultiplier;
   }
   else if(StringFind(symbol, "ADA") >= 0 || StringFind(symbol, "DOT") >= 0 ||
           StringFind(symbol, "LINK") >= 0 || StringFind(symbol, "XRP") >= 0)
   {
      CryptocurrencyName = "ALTCOIN";
      CryptoType = 3;
      CryptoMultiplier = AltcoinMultiplier;
   }
   else if(StringFind(symbol, "UNI") >= 0 || StringFind(symbol, "AAVE") >= 0 ||
           StringFind(symbol, "COMP") >= 0)
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
//| High-frequency analysis                                          |
//+------------------------------------------------------------------+
void PerformHighFrequencyAnalysis()
{
   // Real-time volatility monitoring
   double currentRange = High[0] - Low[0];
   double avgRange = CalculateAverageRange(20);

   if(currentRange > avgRange * 2)
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
   return avgRange / period;
}

//+------------------------------------------------------------------+
//| Crypto market analysis                                           |
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
   double atr = iATR(Symbol(), 0, ATR_Period, 1);
   double avgPrice = (High[1] + Low[1]) / 2;
   CurrentVolatility = (atr / avgPrice) * 100;

   // Determine volatility regime
   if(CurrentVolatility > MaxVolatilityThreshold)
      MarketPhase = "EXTREME_VOLATILITY";
   else if(CurrentVolatility > MaxVolatilityThreshold * 0.7)
      MarketPhase = "HIGH_VOLATILITY";
   else if(CurrentVolatility < MinVolatilityThreshold)
      MarketPhase = "LOW_VOLATILITY";
   else
      MarketPhase = "NORMAL_VOLATILITY";
}

void AnalyzeMomentumAndTrend()
{
   // Multi-indicator momentum analysis
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
   double macd_main = iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_MAIN, 1);
   double macd_signal = iMACD(Symbol(), 0, FastMA, SlowMA, SignalMA, PRICE_CLOSE, MODE_SIGNAL, 1);

   // Calculate momentum strength
   MomentumStrength = 0;

   // RSI component
   if(rsi > 70) MomentumStrength += 0.5;
   else if(rsi < 30) MomentumStrength -= 0.5;
   else MomentumStrength += (rsi - 50) / 100;

   // MACD component
   if(macd_main > macd_signal && macd_main > 0) MomentumStrength += 0.5;
   else if(macd_main < macd_signal && macd_main < 0) MomentumStrength -= 0.5;

   MomentumStrength = MathMax(-1.0, MathMin(1.0, MomentumStrength));

   // Trend strength analysis
   double ema_fast = iMA(Symbol(), 0, FastMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double ema_slow = iMA(Symbol(), 0, SlowMA, 0, MODE_EMA, PRICE_CLOSE, 1);
   double close = Close[1];

   TrendStrength = 0;

   if(close > ema_fast && ema_fast > ema_slow)
      TrendStrength = 1.0; // Strong uptrend
   else if(close < ema_fast && ema_fast < ema_slow)
      TrendStrength = -1.0; // Strong downtrend
   else if(close > ema_slow)
      TrendStrength = 0.5; // Weak uptrend
   else if(close < ema_slow)
      TrendStrength = -0.5; // Weak downtrend

   TrendStrength = MathMax(-1.0, MathMin(1.0, TrendStrength));
}

void DetermineMarketPhase()
{
   // Combine volatility, momentum, and trend
   if(CurrentVolatility > MaxVolatilityThreshold)
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
   else if(CurrentVolatility < MinVolatilityThreshold)
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
   // Simplified Fear & Greed calculation
   Fear_Greed_Index = 50 + (MomentumStrength * 25) + (TrendStrength * 15) - (CurrentVolatility * 2);
   Fear_Greed_Index = MathMax(0, MathMin(100, Fear_Greed_Index));
}

//+------------------------------------------------------------------+
//| Risk validation                                                  |
//+------------------------------------------------------------------+
bool ValidateRiskLimits()
{
   // Update drawdown
   double currentEquity = AccountEquity();
   if(currentEquity > MaxEquity)
      MaxEquity = currentEquity;

   CurrentDrawdown = ((MaxEquity - currentEquity) / MaxEquity) * 100;

   // Check crypto drawdown limit
   if(CurrentDrawdown > 25.0) // Crypto-specific limit
   {
      Print("Crypto drawdown limit exceeded: ", CurrentDrawdown, "%");
      CloseAllPositions("Drawdown protection");
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

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         double positionRisk = CalculatePositionRisk();
         totalRisk += positionRisk;
      }
   }

   return (totalRisk / accountValue) * 100;
}

double CalculatePositionRisk()
{
   double openPrice = OrderOpenPrice();
   double stopLoss = OrderStopLoss();
   double lots = OrderLots();

   if(stopLoss == 0)
   {
      // Use percentage stop if no stop loss set
      double riskPercent = UsePercentageStops ? PercentageStopLevel : 5.0;
      stopLoss = (OrderType() == OP_BUY) ? openPrice * (1 - riskPercent/100) : openPrice * (1 + riskPercent/100);
   }

   double riskPerUnit = MathAbs(openPrice - stopLoss);
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);

   if(tickValue > 0 && tickSize > 0)
      return lots * riskPerUnit * tickValue / tickSize;

   return 0;
}

//+------------------------------------------------------------------+
//| Strategy execution                                               |
//+------------------------------------------------------------------+
void ExecuteCryptoStrategies()
{
   CurrentSignal = "NONE";

   // Strategy selection based on market phase
   if(EnableVolatilityTrading && StringFind(MarketPhase, "VOLATILE") >= 0)
      ExecuteVolatilityStrategy();

   if(EnableTrendFollowing && StringFind(MarketPhase, "TREND") >= 0)
      ExecuteTrendStrategy();

   if(EnableMeanReversion && MarketPhase == "RANGING")
      ExecuteMeanReversionStrategy();

   if(EnableMomentumTrading && StringFind(MarketPhase, "MOMENTUM") >= 0)
      ExecuteMomentumStrategy();
}

void ExecuteVolatilityStrategy()
{
   if(VolatilityExpansion && MathAbs(MomentumStrength) > 0.4)
   {
      // Volatility breakout
      if(MomentumStrength > 0 && !HasLongPosition())
      {
         double lotSize = CalculateCryptoLotSize(0.8); // Reduced size for volatile conditions
         OpenCryptoPosition(OP_BUY, "Volatility Breakout", lotSize);
         CurrentSignal = "VOLATILITY_BUY";
      }
      else if(MomentumStrength < 0 && !HasShortPosition())
      {
         double lotSize = CalculateCryptoLotSize(0.8);
         OpenCryptoPosition(OP_SELL, "Volatility Breakdown", lotSize);
         CurrentSignal = "VOLATILITY_SELL";
      }
   }
}

void ExecuteTrendStrategy()
{
   if(MathAbs(TrendStrength) > 0.7 && MathAbs(MomentumStrength) > 0.5)
   {
      // Strong trend with momentum confirmation
      if(TrendStrength > 0 && MomentumStrength > 0 && !HasLongPosition())
      {
         double lotSize = CalculateCryptoLotSize(1.0);
         OpenCryptoPosition(OP_BUY, "Crypto Trend Bull", lotSize);
         CurrentSignal = "TREND_BUY";
      }
      else if(TrendStrength < 0 && MomentumStrength < 0 && !HasShortPosition())
      {
         double lotSize = CalculateCryptoLotSize(1.0);
         OpenCryptoPosition(OP_SELL, "Crypto Trend Bear", lotSize);
         CurrentSignal = "TREND_SELL";
      }
   }
}

void ExecuteMeanReversionStrategy()
{
   double bb_upper = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 1);
   double bb_lower = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 1);
   double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, 1);
   double close = Close[1];

   // Oversold mean reversion
   if(close <= bb_lower && rsi < RSI_OversoldLevel && MomentumStrength > -0.8 && !HasLongPosition())
   {
      double lotSize = CalculateCryptoLotSize(0.7);
      OpenCryptoPosition(OP_BUY, "Crypto Mean Rev Bull", lotSize);
      CurrentSignal = "MEAN_REV_BUY";
   }

   // Overbought mean reversion
   if(close >= bb_upper && rsi > RSI_OverboughtLevel && MomentumStrength < 0.8 && !HasShortPosition())
   {
      double lotSize = CalculateCryptoLotSize(0.7);
      OpenCryptoPosition(OP_SELL, "Crypto Mean Rev Bear", lotSize);
      CurrentSignal = "MEAN_REV_SELL";
   }
}

void ExecuteMomentumStrategy()
{
   if(MathAbs(MomentumStrength) > 0.6 && CurrentVolatility > MinVolatilityThreshold)
   {
      // Pure momentum play
      if(MomentumStrength > 0.6 && !HasLongPosition())
      {
         double lotSize = CalculateCryptoLotSize(1.1);
         OpenCryptoPosition(OP_BUY, "Crypto Momentum", lotSize);
         CurrentSignal = "MOMENTUM_BUY";
      }
      else if(MomentumStrength < -0.6 && !HasShortPosition())
      {
         double lotSize = CalculateCryptoLotSize(1.1);
         OpenCryptoPosition(OP_SELL, "Crypto Momentum", lotSize);
         CurrentSignal = "MOMENTUM_SELL";
      }
   }
}

//+------------------------------------------------------------------+
//| Position management                                              |
//+------------------------------------------------------------------+
void OpenCryptoPosition(int orderType, string strategy, double lots)
{
   double price = (orderType == OP_BUY) ? Ask : Bid;
   double sl = CalculateCryptoStopLoss(orderType, price);
   double tp = CalculateCryptoTakeProfit(orderType, price);

   int ticket = OrderSend(Symbol(), orderType, lots, price, 10, sl, tp, // Wider slippage for crypto
                         strategy + " - " + CryptocurrencyName, MagicNumber, 0,
                         (orderType == OP_BUY) ? ProfitColor : LossColor);

   if(ticket > 0)
   {
      TotalTrades++;
      Print("Crypto position opened: ", strategy, " Crypto: ", CryptocurrencyName, " Lot: ", lots);
   }
   else
   {
      Print("Error opening crypto position: ", GetLastError());
   }
}

double CalculateCryptoLotSize(double strategyMultiplier)
{
   double baseLot = 0.01;
   double accountValue = AccountEquity();
   double riskAmount = accountValue * (BaseCryptoRisk / 100.0);

   // Apply strategy multiplier
   riskAmount *= strategyMultiplier;

   // Apply crypto-specific multiplier
   riskAmount *= CryptoMultiplier;

   // Volatility adjustment
   if(UseVolatilityScaling)
   {
      if(CurrentVolatility > 10.0)
         riskAmount *= 0.4; // Significantly reduce size in extreme volatility
      else if(CurrentVolatility > 7.0)
         riskAmount *= 0.6;
      else if(CurrentVolatility > 5.0)
         riskAmount *= 0.8;
      else if(CurrentVolatility < 2.0)
         riskAmount *= 1.3; // Increase size in low volatility
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
      double price = (High[1] + Low[1]) / 2;
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
   }

   // Ensure within limits
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   baseLot = MathMax(minLot, MathMin(maxLot, baseLot));

   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(lotStep > 0)
      baseLot = MathRound(baseLot / lotStep) * lotStep;

   return baseLot;
}

double CalculateCryptoStopLoss(int orderType, double price)
{
   double sl = 0;

   if(UseATRStops)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, 1);

      if(orderType == OP_BUY)
         sl = price - (atr * ATR_StopMultiplier);
      else
         sl = price + (atr * ATR_StopMultiplier);
   }

   if(UsePercentageStops)
   {
      double percentSL;
      if(orderType == OP_BUY)
         percentSL = price * (1 - PercentageStopLevel / 100);
      else
         percentSL = price * (1 + PercentageStopLevel / 100);

      // Use the wider of ATR or percentage stop
      if(UseATRStops)
      {
         if(orderType == OP_BUY)
            sl = MathMin(sl, percentSL);
         else
            sl = MathMax(sl, percentSL);
      }
      else
      {
         sl = percentSL;
      }
   }

   return sl;
}

double CalculateCryptoTakeProfit(int orderType, double price)
{
   double tp = 0;

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
      // Use risk-reward ratio of 2:1 for percentage stops
      double riskPercent = PercentageStopLevel * 2;

      if(orderType == OP_BUY)
         tp = price * (1 + riskPercent / 100);
      else
         tp = price * (1 - riskPercent / 100);
   }

   return tp;
}

void ManagePositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         // Apply trailing stops
         if(UseTrailingStops)
            ApplyCryptoTrailingStop();

         // Apply break-even
         if(UseBreakEven)
            ApplyCryptoBreakEven();

         // Check for volatility exits
         CheckVolatilityExit();
      }
   }
}

void ApplyCryptoTrailingStop()
{
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double openPrice = OrderOpenPrice();

   if(OrderType() == OP_BUY)
   {
      double profit = (currentPrice - openPrice) / openPrice * 100;
      if(profit > BreakEvenThreshold)
      {
         double newSL = currentPrice * (1 - TrailingStopPercent / 100);
         if(newSL > OrderStopLoss())
         {
            OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0);
         }
      }
   }
   else
   {
      double profit = (openPrice - currentPrice) / openPrice * 100;
      if(profit > BreakEvenThreshold)
      {
         double newSL = currentPrice * (1 + TrailingStopPercent / 100);
         if(newSL < OrderStopLoss() || OrderStopLoss() == 0)
         {
            OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0);
         }
      }
   }
}

void ApplyCryptoBreakEven()
{
   double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
   double openPrice = OrderOpenPrice();

   if(OrderType() == OP_BUY)
   {
      double profit = (currentPrice - openPrice) / openPrice * 100;
      if(profit > BreakEvenThreshold && OrderStopLoss() < openPrice)
      {
         double newSL = openPrice * 1.005; // Small profit lock
         OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0);
      }
   }
   else
   {
      double profit = (openPrice - currentPrice) / openPrice * 100;
      if(profit > BreakEvenThreshold && (OrderStopLoss() > openPrice || OrderStopLoss() == 0))
      {
         double newSL = openPrice * 0.995; // Small profit lock
         OrderModify(OrderTicket(), openPrice, newSL, OrderTakeProfit(), 0);
      }
   }
}

void CheckVolatilityExit()
{
   // Exit if volatility becomes extreme
   if(CurrentVolatility > MaxVolatilityThreshold * 1.5)
   {
      double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
      OrderClose(OrderTicket(), OrderLots(), closePrice, 10);
      Print("Position closed due to extreme volatility: ", CurrentVolatility, "%");
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
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
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
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
         OrderClose(OrderTicket(), OrderLots(), closePrice, 10);
      }
   }
   Print("All crypto positions closed: ", reason);
}

void UpdatePerformanceMetrics()
{
   // Calculate daily P&L
   CalculateDailyPnL();

   // Calculate profit factor
   CalculateProfitFactor();
}

void CalculateDailyPnL()
{
   HourlyPnL = 0;
   DailyPnL = 0;

   // Calculate from open positions
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         double pnl = OrderProfit() + OrderSwap() + OrderCommission();
         HourlyPnL += pnl;
         DailyPnL += pnl;
      }
   }

   // Add closed positions from today
   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         if(TimeDay(OrderCloseTime()) == Day())
         {
            double pnl = OrderProfit() + OrderSwap() + OrderCommission();
            DailyPnL += pnl;
            if(pnl > 0) WinningTrades++;
         }
      }
   }
}

void CalculateProfitFactor()
{
   double totalProfit = 0;
   double totalLoss = 0;

   for(int i = 0; i < OrdersHistoryTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         double pnl = OrderProfit() + OrderSwap() + OrderCommission();
         if(pnl > 0)
            totalProfit += pnl;
         else
            totalLoss += MathAbs(pnl);
      }
   }

   ProfitFactor = (totalLoss > 0) ? totalProfit / totalLoss : 0;
}

//+------------------------------------------------------------------+
//| Dashboard functions                                              |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   ObjectCreate("Crypto_Dashboard_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_XDISTANCE, DashboardX);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_YDISTANCE, DashboardY);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_XSIZE, 400);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_YSIZE, 400);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "Crypto_Dashboard_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);

   CreateLabel("Crypto_Title", "CLEAN CRYPTO PRO", DashboardX + 10, DashboardY + 10, clrWhite, 16);
   CreateLabel("Crypto_Name", "", DashboardX + 10, DashboardY + 35, clrWhite, 12);
   CreateLabel("Crypto_Phase", "", DashboardX + 10, DashboardY + 60, clrWhite, 10);
   CreateLabel("Crypto_Signal", "", DashboardX + 10, DashboardY + 80, clrWhite, 9);
   CreateLabel("Crypto_Balance", "", DashboardX + 10, DashboardY + 105, clrWhite, 9);
   CreateLabel("Crypto_Equity", "", DashboardX + 10, DashboardY + 125, clrWhite, 9);
   CreateLabel("Crypto_HourlyPL", "", DashboardX + 10, DashboardY + 145, clrWhite, 9);
   CreateLabel("Crypto_DailyPL", "", DashboardX + 10, DashboardY + 165, clrWhite, 9);
   CreateLabel("Crypto_Drawdown", "", DashboardX + 10, DashboardY + 185, clrWhite, 9);
   CreateLabel("Crypto_Volatility", "", DashboardX + 10, DashboardY + 210, clrWhite, 9);
   CreateLabel("Crypto_Momentum", "", DashboardX + 10, DashboardY + 230, clrWhite, 9);
   CreateLabel("Crypto_Trend", "", DashboardX + 10, DashboardY + 250, clrWhite, 9);
   CreateLabel("Crypto_FearGreed", "", DashboardX + 10, DashboardY + 270, clrWhite, 9);
   CreateLabel("Crypto_VolExpansion", "", DashboardX + 10, DashboardY + 290, clrWhite, 9);
   CreateLabel("Crypto_Trades", "", DashboardX + 10, DashboardY + 315, clrWhite, 9);
   CreateLabel("Crypto_ProfitFactor", "", DashboardX + 10, DashboardY + 335, clrWhite, 9);
   CreateLabel("Crypto_Time", "", DashboardX + 10, DashboardY + 355, clrWhite, 9);
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
   ObjectSetText("Crypto_Name", CryptocurrencyName + " (x" + DoubleToStr(CryptoMultiplier, 1) + ")", 12, "Arial Bold", cryptoColor);

   // Market phase
   color phaseColor = (StringFind(MarketPhase, "BULL") >= 0 || StringFind(MarketPhase, "UP") >= 0) ? ProfitColor :
                     (StringFind(MarketPhase, "BEAR") >= 0 || StringFind(MarketPhase, "DOWN") >= 0) ? LossColor : clrYellow;
   ObjectSetText("Crypto_Phase", "Phase: " + MarketPhase, 10, "Arial Bold", phaseColor);

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

   color fearGreedColor = (Fear_Greed_Index > 70) ? ProfitColor : (Fear_Greed_Index < 30) ? LossColor : clrWhite;
   string fearGreedText = (Fear_Greed_Index > 70) ? "GREED" : (Fear_Greed_Index < 30) ? "FEAR" : "NEUTRAL";
   ObjectSetText("Crypto_FearGreed", "Fear/Greed: " + fearGreedText + " (" + DoubleToStr(Fear_Greed_Index, 0) + ")", 9, "Arial Bold", fearGreedColor);

   color expColor = VolatilityExpansion ? clrYellow : clrGray;
   ObjectSetText("Crypto_VolExpansion", "Vol Expansion: " + (VolatilityExpansion ? "YES" : "NO"), 9, "Arial", expColor);

   // Trading info
   ObjectSetText("Crypto_Trades", "Trades: " + IntegerToString(TotalTrades) + " | Wins: " + IntegerToString(WinningTrades), 9, "Arial", clrWhite);

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
   ObjectDelete("Crypto_Trades");
   ObjectDelete("Crypto_ProfitFactor");
   ObjectDelete("Crypto_Time");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(ShowDashboard)
      UpdateDashboard();
}

//+------------------------------------------------------------------+
