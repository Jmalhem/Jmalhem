//+------------------------------------------------------------------+
//|                                    WakaWaka EA v3.0 (Professional) |
//|                                      Refactored & Optimized Version |
//|                                   Copyright 2025, Professional Team |
//|                                      Based on original v2.12 by     |
//|                                          Valeriia Mishchenko        |
//+------------------------------------------------------------------+
#property copyright "Refactored Professional Version 2025"
#property link      "https://github.com/your-repo"
#property version   "3.00"
#property strict
#property description "Multi-Currency Grid Trading Expert Advisor"
#property description "Bollinger Bands + RSI Strategy with Martingale Grid"
#property description "Fully refactored with professional code standards"

//+------------------------------------------------------------------+
//| INCLUDES                                                          |
//+------------------------------------------------------------------+
#include <Canvas\Canvas.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                      |
//+------------------------------------------------------------------+

// Lot sizing methods
enum ENUM_LOT_SIZING_METHOD
{
   LOT_FIXED = 0,                    // Fixed lot size
   LOT_BALANCE_BASED = 1,            // Dynamic based on balance
   LOT_EQUITY_BASED = 2,             // Dynamic based on equity
   LOT_RISK_80_PERCENT = 3,          // High risk (1.0% load, 80% annual)
   LOT_RISK_40_PERCENT = 4,          // Mid risk (0.5% load, 40% annual)
   LOT_RISK_20_PERCENT = 5,          // Low risk (0.25% load, 20% annual)
   LOT_DEPOSIT_LOAD = 6,             // Based on deposit load percentage
   LOT_RISK_120_PERCENT = 7          // Extreme risk (1.5% load, 120% annual)
};

// Buy/Sell permissions
enum ENUM_TRADE_DIRECTION
{
   TRADE_BOTH = 0,                   // Allow both buy and sell
   TRADE_BUY_ONLY = 1,              // Buy only
   TRADE_SELL_ONLY = 2              // Sell only
};

// Drawdown action
enum ENUM_DRAWDOWN_ACTION
{
   DD_CLOSE_AND_STOP_24H = 0,       // Close all trades and stop for 24 hours
   DD_CLOSE_AND_STOP_UNTIL_RESTART = 1,  // Close all and stop until restart
   DD_BLOCK_NEW_GRIDS = 2,          // Just block new grids
   DD_BLOCK_UNTIL_RESTART = 3       // Block new grids until restart
};

// Drawdown calculation method
enum ENUM_DRAWDOWN_CALCULATION
{
   DD_CALC_ACCOUNT = 0,             // Calculate on entire account
   DD_CALC_STRATEGY = 1             // Calculate only this EA's trades
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+

// ===== Money Management =====
sinput string inp_MM_Header = "========== MONEY MANAGEMENT =========="; // ─────────────────────────
input bool                          inp_AllowNewGrids = true;                  // Allow Opening New Grids
input ENUM_LOT_SIZING_METHOD        inp_LotSizingMethod = LOT_RISK_20_PERCENT; // Lot Sizing Method
input double                        inp_FixedLot = 0.01;                       // Fixed Lot Size
input double                        inp_DynamicLotDivisor = 10000;             // Dynamic Lot Divisor (Balance/Equity)
input double                        inp_DepositLoadPercent = 0.25;             // Deposit Load Percentage
input bool                          inp_FixedInitialDeposit = false;           // Use Fixed Initial Deposit (Tester Only)
input double                        inp_MaxLot = 100.0;                        // Maximum Lot Size
input bool                          inp_AutoSplit = false;                     // Auto-Split Large Orders
input double                        inp_MaxSpreadPips = 10.0;                  // Maximum Spread (Pips)
input int                           inp_MaxSlippagePips = 10;                  // Maximum Slippage (Pips)

// ===== Risk Management =====
sinput string inp_Risk_Header = "========== RISK MANAGEMENT =========="; // ─────────────────────────
input int                           inp_MaxSymbols = 2;                        // Maximum Symbols Simultaneously
input bool                          inp_AllowHedging = true;                   // Allow Hedging (Buy+Sell same symbol)
input ENUM_TRADE_DIRECTION          inp_TradingDirection = TRADE_BOTH;         // Trading Direction
input double                        inp_MinFreeMarginPercent = 0.0;            // Minimum Free Margin % [0=disabled]
input double                        inp_MaxDrawdownPercent = 100.0;            // Max Floating Drawdown %
input double                        inp_MaxDrawdownMoney = 0.0;                // Max Floating Drawdown Money [0=disabled]
input ENUM_DRAWDOWN_ACTION          inp_DrawdownAction = DD_CLOSE_AND_STOP_24H; // Drawdown Action
input ENUM_DRAWDOWN_CALCULATION     inp_DrawdownCalcMethod = DD_CALC_STRATEGY; // Drawdown Calculation Method

// ===== Strategy Settings =====
sinput string inp_Strategy_Header = "========== STRATEGY SETTINGS =========="; // ─────────────────────────
input string                        inp_TradingSymbols = "AUDNZD,AUDCAD,NZDCAD"; // Trading Symbols (comma-separated)
input bool                          inp_AllowTradingOnHolidays = false;        // Allow Trading on Holidays
input int                           inp_TradingStartHour = 0;                  // Trading Start Hour (Broker Time)
input int                           inp_TradingStopHour = 23;                  // Trading Stop Hour (Broker Time)
input int                           inp_BollingerBandsPeriod = 35;             // Bollinger Bands Period
input int                           inp_RSI_Period = 20;                       // RSI Period
input int                           inp_RSI_MaxValue = 15;                     // Maximum RSI Value (from 50)

// ===== Take Profit Settings =====
sinput string inp_TP_Header = "========== TAKE PROFIT SETTINGS =========="; // ─────────────────────────
input double                        inp_InitialTP_Pips = 10.0;                 // Initial Trade TP (Pips)
input bool                          inp_UseWeightedTP = true;                  // Use Weighted TP
input double                        inp_GridTP_Pips = 0.0;                     // Grid TP (Pips) [can be negative]
input int                           inp_BreakEvenLevel = 0;                    // Break Even After Level [0=disabled]
input bool                          inp_HideTP = false;                        // Hide Take Profit from Broker
input bool                          inp_UseOPO_Method = false;                 // Use One-Pip-Over Method
input ENUM_TIMEFRAMES               inp_OPO_Timeframe = PERIOD_M15;            // OPO Method Timeframe
input bool                          inp_SmartTP = false;                       // Smart TP (BB-based)
input bool                          inp_DoNotAdjustTP = false;                 // Don't Adjust TP Unless New Grid Level

// ===== Stop Loss Settings =====
sinput string inp_SL_Header = "========== STOP LOSS SETTINGS =========="; // ─────────────────────────
input double                        inp_GridSL_Pips = 0.0;                     // Grid SL (Pips) [0=1000 pips]
input bool                          inp_HideSL = false;                        // Hide Stop Loss from Broker

// ===== Grid Settings =====
sinput string inp_Grid_Header = "========== GRID SETTINGS =========="; // ─────────────────────────
input int                           inp_GridDistance_Pips = 35;                // Grid Distance (Pips)
input bool                          inp_SmartDistance = true;                  // Smart Distance (ATR-based)
input double                        inp_Multiplier_2nd = 1.0;                  // 2nd Trade Multiplier
input double                        inp_Multiplier_3rd_to_5th = 2.0;           // 3rd-5th Trade Multiplier
input double                        inp_Multiplier_6th_Plus = 1.5;             // 6th+ Trade Multiplier
input int                           inp_MaxGridLevels = 9;                     // Maximum Grid Levels
input int                           inp_GridStartLevel = 1;                    // Grid Start Level (1=initial trade)
input bool                          inp_KeepOriginalLotSize = false;           // Keep Original Profit Level & Lot Size

// ===== Additional Settings =====
sinput string inp_Additional_Header = "========== ADDITIONAL SETTINGS =========="; // ─────────────────────────
input string                        inp_TradeComment = "Waka";                 // Trade Comment
input int                           inp_MagicNumberUID = 0;                    // Magic Number UID (0-9)
input bool                          inp_ShowPanel = true;                      // Show Info Panel

//+------------------------------------------------------------------+
//| CONSTANTS                                                         |
//+------------------------------------------------------------------+

// Magic number calculation
#define MAGIC_BASE                  84570
#define EPSILON                     0.0000001  // Zero comparison threshold

// Timeframe in minutes
#define TF_M15                      15

// Signal database size
#define SIGNAL_DATABASE_SIZE        3000
#define MAX_TRADE_HISTORY           50000

// GUI Constants
#define GUI_BASE_X                  10
#define GUI_BASE_Y                  23
#define GUI_LINE_HEIGHT             14
#define GUI_BUTTON_Y                205
#define GUI_PANEL_WIDTH             165

// Color scheme
#define COLOR_PANEL_BG              clrWhite
#define COLOR_PANEL_TEXT            C'96,96,96'
#define COLOR_VALUE_TEXT            clrWhite
#define COLOR_BUY_BUTTON            C'0,100,0'
#define COLOR_SELL_BUTTON           C'139,0,0'
#define COLOR_PAIR_BUTTON           C'33,150,243'
#define COLOR_ALLOW_BUTTON          C'0,128,0'
#define COLOR_BLOCK_BUTTON          clrRed

//+------------------------------------------------------------------+
//| STRUCTURES AND CLASSES                                            |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Enhanced Canvas for GUI                                          |
//+------------------------------------------------------------------+
class CCanvasX : public CCanvas
{
public:
   bool LoadResourceImage(string resourcePath)
   {
      return ResourceReadImage(resourcePath, m_pixels, m_width, m_height);
   }
};

//+------------------------------------------------------------------+
//| Symbol Trading Information                                        |
//| Stores all per-symbol state data                                 |
//+------------------------------------------------------------------+
class CSymbolData
{
private:
   // Core identification
   string         m_Symbol;

   // Timing trackers
   datetime       m_LastTickTime;
   datetime       m_LastOPOCheckTime;
   int            m_TickCounter;

   // Trading permissions
   bool           m_AllowBuySignals;
   bool           m_AllowSellSignals;
   bool           m_AllowNewBuyGrid;
   bool           m_AllowNewSellGrid;

   // Market data cache
   datetime       m_CurrentBarTime;
   datetime       m_CurrentOPOBarTime;
   double         m_LastClosePrice;
   double         m_BBRangeSize;
   double         m_SmartDistanceMultiplier;

   // Grid state tracking
   int            m_LastProcessedBarIndex;
   int            m_CurrentGridBarIndex;
   long           m_PatternID;
   double         m_PatternPrice;
   double         m_TotalLotSizeMultiplier;

   // TP/SL caching
   double         m_CachedBuyAvgPrice;
   double         m_CachedSellAvgPrice;
   double         m_TargetBuyTP;
   double         m_TargetSellTP;

   // Timestamps
   datetime       m_LastBuyGridOpenTime;
   datetime       m_LastSellGridOpenTime;
   int            m_CurrentDayOfWeek;

   // Weekly reset flags
   bool           m_RequiresBuyWeeklyReset;
   bool           m_RequiresSellWeeklyReset;
   bool           m_RequiresFullWeeklyReset;

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   CSymbolData()
   {
      Initialize("");
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                       |
   //+------------------------------------------------------------------+
   ~CSymbolData()
   {
   }

   //+------------------------------------------------------------------+
   //| Initialize symbol data                                           |
   //+------------------------------------------------------------------+
   void Initialize(string symbol)
   {
      m_Symbol = symbol;
      m_LastTickTime = 0;
      m_LastOPOCheckTime = 0;
      m_TickCounter = 0;
      m_AllowBuySignals = false;
      m_AllowSellSignals = false;
      m_AllowNewBuyGrid = false;
      m_AllowNewSellGrid = false;
      m_CurrentBarTime = 0;
      m_CurrentOPOBarTime = 0;
      m_LastClosePrice = 0.0;
      m_BBRangeSize = 0.0;
      m_SmartDistanceMultiplier = 1.0;
      m_LastProcessedBarIndex = 0;
      m_CurrentGridBarIndex = 0;
      m_PatternID = 0;
      m_PatternPrice = 0.0;
      m_TotalLotSizeMultiplier = 0.0;
      m_CachedBuyAvgPrice = 0.0;
      m_CachedSellAvgPrice = 0.0;
      m_TargetBuyTP = 0.0;
      m_TargetSellTP = 0.0;
      m_LastBuyGridOpenTime = 0;
      m_LastSellGridOpenTime = 0;
      m_CurrentDayOfWeek = 0;
      m_RequiresBuyWeeklyReset = true;
      m_RequiresSellWeeklyReset = true;
      m_RequiresFullWeeklyReset = true;
   }

   //+------------------------------------------------------------------+
   //| Getters                                                          |
   //+------------------------------------------------------------------+
   string   GetSymbol() const                    { return m_Symbol; }
   datetime GetLastTickTime() const              { return m_LastTickTime; }
   datetime GetLastOPOCheckTime() const          { return m_LastOPOCheckTime; }
   int      GetTickCounter() const               { return m_TickCounter; }
   bool     CanBuy() const                       { return m_AllowBuySignals; }
   bool     CanSell() const                      { return m_AllowSellSignals; }
   bool     CanOpenNewBuyGrid() const            { return m_AllowNewBuyGrid; }
   bool     CanOpenNewSellGrid() const           { return m_AllowNewSellGrid; }
   datetime GetCurrentBarTime() const            { return m_CurrentBarTime; }
   datetime GetCurrentOPOBarTime() const         { return m_CurrentOPOBarTime; }
   double   GetLastClosePrice() const            { return m_LastClosePrice; }
   double   GetBBRangeSize() const               { return m_BBRangeSize; }
   double   GetSmartDistanceMultiplier() const   { return m_SmartDistanceMultiplier; }
   int      GetLastProcessedBarIndex() const     { return m_LastProcessedBarIndex; }
   int      GetCurrentGridBarIndex() const       { return m_CurrentGridBarIndex; }
   long     GetPatternID() const                 { return m_PatternID; }
   double   GetPatternPrice() const              { return m_PatternPrice; }
   double   GetTotalLotSizeMultiplier() const    { return m_TotalLotSizeMultiplier; }
   double   GetCachedBuyAvgPrice() const         { return m_CachedBuyAvgPrice; }
   double   GetCachedSellAvgPrice() const        { return m_CachedSellAvgPrice; }
   double   GetTargetBuyTP() const               { return m_TargetBuyTP; }
   double   GetTargetSellTP() const              { return m_TargetSellTP; }
   datetime GetLastBuyGridOpenTime() const       { return m_LastBuyGridOpenTime; }
   datetime GetLastSellGridOpenTime() const      { return m_LastSellGridOpenTime; }
   int      GetCurrentDayOfWeek() const          { return m_CurrentDayOfWeek; }
   bool     RequiresBuyWeeklyReset() const       { return m_RequiresBuyWeeklyReset; }
   bool     RequiresSellWeeklyReset() const      { return m_RequiresSellWeeklyReset; }
   bool     RequiresFullWeeklyReset() const      { return m_RequiresFullWeeklyReset; }

   //+------------------------------------------------------------------+
   //| Setters                                                          |
   //+------------------------------------------------------------------+
   void SetSymbol(string value)                         { m_Symbol = value; }
   void SetLastTickTime(datetime value)                 { m_LastTickTime = value; }
   void SetLastOPOCheckTime(datetime value)             { m_LastOPOCheckTime = value; }
   void SetTickCounter(int value)                       { m_TickCounter = value; }
   void SetAllowBuySignals(bool value)                  { m_AllowBuySignals = value; }
   void SetAllowSellSignals(bool value)                 { m_AllowSellSignals = value; }
   void SetAllowNewBuyGrid(bool value)                  { m_AllowNewBuyGrid = value; }
   void SetAllowNewSellGrid(bool value)                 { m_AllowNewSellGrid = value; }
   void SetCurrentBarTime(datetime value)               { m_CurrentBarTime = value; }
   void SetCurrentOPOBarTime(datetime value)            { m_CurrentOPOBarTime = value; }
   void SetLastClosePrice(double value)                 { m_LastClosePrice = value; }
   void SetBBRangeSize(double value)                    { m_BBRangeSize = value; }
   void SetSmartDistanceMultiplier(double value)        { m_SmartDistanceMultiplier = value; }
   void SetLastProcessedBarIndex(int value)             { m_LastProcessedBarIndex = value; }
   void SetCurrentGridBarIndex(int value)               { m_CurrentGridBarIndex = value; }
   void SetPatternID(long value)                        { m_PatternID = value; }
   void SetPatternPrice(double value)                   { m_PatternPrice = value; }
   void SetTotalLotSizeMultiplier(double value)         { m_TotalLotSizeMultiplier = value; }
   void SetCachedBuyAvgPrice(double value)              { m_CachedBuyAvgPrice = value; }
   void SetCachedSellAvgPrice(double value)             { m_CachedSellAvgPrice = value; }
   void SetTargetBuyTP(double value)                    { m_TargetBuyTP = value; }
   void SetTargetSellTP(double value)                   { m_TargetSellTP = value; }
   void SetLastBuyGridOpenTime(datetime value)          { m_LastBuyGridOpenTime = value; }
   void SetLastSellGridOpenTime(datetime value)         { m_LastSellGridOpenTime = value; }
   void SetCurrentDayOfWeek(int value)                  { m_CurrentDayOfWeek = value; }
   void SetRequiresBuyWeeklyReset(bool value)           { m_RequiresBuyWeeklyReset = value; }
   void SetRequiresSellWeeklyReset(bool value)          { m_RequiresSellWeeklyReset = value; }
   void SetRequiresFullWeeklyReset(bool value)          { m_RequiresFullWeeklyReset = value; }

   //+------------------------------------------------------------------+
   //| Increment tick counter                                           |
   //+------------------------------------------------------------------+
   void IncrementTickCounter()
   {
      m_TickCounter++;
   }
};

//+------------------------------------------------------------------+
//| Trade History Record (Currently unused - placeholder)            |
//+------------------------------------------------------------------+
class CTradeHistoryRecord
{
public:
   long     Ticket;
   double   Profit;
   bool     IsClosed;

   CTradeHistoryRecord() : Ticket(0), Profit(0.0), IsClosed(false) {}
   ~CTradeHistoryRecord() {}
};

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+

// State management
string               g_Version = "3.0.0";
string               g_LogoResourcePath = "::W2.12LD_bmp\\WakaWakaEA.bmp";
long                 g_AccountNumber = 0;
string               g_AccountName = "";

// Execution control
int                  g_TickCounter = 0;
datetime             g_LastProcessTime = 0;
datetime             g_LastTimerUpdate = 0;
int                  g_CurrentHour = 0;
int                  g_PreviousHour = -1;

// Trading state
bool                 g_ForceCloseMode = false;
int                  g_TradingBlockedHours = 0;
bool                 g_PermanentTradingBlock = false;

// GUI
CCanvasX             g_GUICanvas;
string               g_SelectedSymbol = "Select pair";
bool                 g_AllowNewGridsFlag = true;

// Symbol data array
CSymbolData          g_SymbolData[];

// Signal database (if enabled)
bool                 g_UseSignalDatabase = true;
int                  g_SignalDatabaseSize = SIGNAL_DATABASE_SIZE;
long                 g_SignalPatterns[];
double               g_SignalPrices[];
int                  g_SignalIndex = -1;

// Trade history (if enabled)
bool                 g_UseTradeHistory = false;
int                  g_MaxHistorySize = MAX_TRADE_HISTORY;
CTradeHistoryRecord  g_TradeHistory[];
int                  g_HistoryIndex = -1;

// Account snapshots
double               g_InitialBalance = 0.0;

// Warnings & errors
long                 g_LastWarningTime = 0;
long                 g_LastMarginWarningTime = 0;
bool                 g_SymbolInitializationError = false;

// Misc constants
ushort               g_CommaSeparator = 0;
int                  g_MagicNumberBase = MAGIC_BASE;

// Optimization flags
bool                 g_UseGridSizeOptimization = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   PrintFormat("%s v%s -> Initializing...", inp_TradeComment, g_Version);

   // Reset state
   g_TradingBlockedHours = 0;
   g_PermanentTradingBlock = false;
   g_ForceCloseMode = false;

   // Get account info
   g_AccountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
   g_AccountName = AccountInfoString(ACCOUNT_NAME);

   // Validation
   if (!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   // Set timer for live trading
   if (!IsTesting())
      EventSetTimer(5);

   // Initialize timestamp
   g_LastProcessTime = TimeCurrent();
   g_LastTimerUpdate = TimeCurrent();

   // Parse symbols
   g_CommaSeparator = StringGetCharacter(",", 0);
   if (!InitializeSymbols())
      return INIT_FAILED;

   // Initialize signal database (if enabled)
   if (g_UseSignalDatabase)
      InitializeSignalDatabase();

   // Initialize trade history (if enabled)
   if (g_UseTradeHistory)
      InitializeTradeHistory();

   // Create GUI
   if (!IsOptimization() && inp_ShowPanel)
   {
      InitializeGUIPanel();
      UpdateGUIPanel(true);
   }

   // Snapshot initial balance
   g_InitialBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   PrintFormat("%s v%s -> Initialization complete", inp_TradeComment, g_Version);
   PrintFormat("Account: %I64d (%s) | Symbols: %d | Magic Base: %d",
               g_AccountNumber, g_AccountName, ArraySize(g_SymbolData), g_MagicNumberBase + inp_MagicNumberUID);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   string deinitReason = GetDeinitReasonText(reason);
   PrintFormat("%s v%s -> %s", inp_TradeComment, g_Version, deinitReason);

   // Cleanup GUI
   if (!IsTesting() && !IsOptimization())
   {
      g_GUICanvas.Destroy();
      ObjectsDeleteAll(0, -1);
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Increment global tick counter
   g_TickCounter++;

   // Process each symbol
   for (int i = 0; i < ArraySize(g_SymbolData); i++)
   {
      string symbol = g_SymbolData[i].GetSymbol();

      // Check for new bar on base timeframe
      datetime currentBarTime = iTime(symbol, TF_M15, 0);
      bool isNewBar = (currentBarTime > g_SymbolData[i].GetCurrentBarTime());

      if (isNewBar)
      {
         g_SymbolData[i].SetCurrentBarTime(currentBarTime);

         // Main processing on new bar
         AnalyzeMarketConditions(i);

         if (IsTradeAllowed())
         {
            ManageGridExpansion(i);
            UpdateBuyOrders(i);
            UpdateSellOrders(i);
         }
      }

      // Check OPO method timeframe
      if (inp_UseOPO_Method)
      {
         datetime opoBarTime = iTime(symbol, inp_OPO_Timeframe, 0);
         if (opoBarTime > g_SymbolData[i].GetCurrentOPOBarTime())
         {
            g_SymbolData[i].SetCurrentOPOBarTime(opoBarTime);
            g_SymbolData[i].SetAllowNewBuyGrid(false);  // Reset OPO flag
         }
      }
   }

   // Manage open positions
   ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Timer function (for live trading)                                |
//+------------------------------------------------------------------+
void OnTimer()
{
   if (IsTesting() || IsOptimization())
      return;

   g_LastTimerUpdate = TimeCurrent();

   // Pre-load historical data for all symbols
   for (int i = 0; i < ArraySize(g_SymbolData); i++)
   {
      string symbol = g_SymbolData[i].GetSymbol();
      iTime(symbol, TF_M15, 0);
      if (inp_UseOPO_Method)
         iTime(symbol, inp_OPO_Timeframe, 0);
   }

   // Update GUI
   if (inp_ShowPanel)
      UpdateGUIPanel(false);
}

//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if (id == CHARTEVENT_OBJECT_CLICK)
      HandleButtonClick(sparam);
}

//+------------------------------------------------------------------+
//| INPUT VALIDATION                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Validate all input parameters                                    |
//+------------------------------------------------------------------+
bool ValidateInputs()
{
   bool valid = true;

   // UID check
   if (inp_MagicNumberUID < 0 || inp_MagicNumberUID > 9)
   {
      Print("ERROR: UID must be between 0 and 9");
      valid = false;
   }

   // Lot size check
   if (inp_LotSizingMethod == LOT_FIXED && inp_FixedLot <= 0)
   {
      Print("ERROR: Fixed lot must be > 0");
      valid = false;
   }

   // Grid settings
   if (inp_MaxGridLevels < 1)
   {
      Print("ERROR: Max grid levels must be >= 1");
      valid = false;
   }

   if (inp_GridStartLevel < 1 || inp_GridStartLevel > inp_MaxGridLevels)
   {
      Print("ERROR: Grid start level must be between 1 and max grid levels");
      valid = false;
   }

   if (inp_GridDistance_Pips <= 0)
   {
      Print("ERROR: Grid distance must be > 0");
      valid = false;
   }

   // Trading hours
   if (inp_TradingStartHour < 0 || inp_TradingStartHour > 23)
   {
      Print("ERROR: Trading start hour must be 0-23");
      valid = false;
   }

   if (inp_TradingStopHour < 0 || inp_TradingStopHour > 23)
   {
      Print("ERROR: Trading stop hour must be 0-23");
      valid = false;
   }

   return valid;
}

//+------------------------------------------------------------------+
//| INITIALIZATION HELPERS                                            |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialize symbol array from input string                        |
//+------------------------------------------------------------------+
bool InitializeSymbols()
{
   string symbolArray[];
   int symbolCount = StringSplit(inp_TradingSymbols, g_CommaSeparator, symbolArray);

   // If in testing or custom symbol mode
   if (symbolCount <= 0 || IsTesting())
   {
      ArrayResize(g_SymbolData, 1);
      g_SymbolData[0].Initialize(Symbol());
      CalculateSymbolMultiplier(0);
      return true;
   }

   // Multi-symbol mode
   ArrayResize(g_SymbolData, symbolCount);

   for (int i = 0; i < symbolCount; i++)
   {
      string symbol = StringTrimLeft(symbolArray[i]);
      symbol = StringTrimRight(symbol);

      if (symbol == "")
      {
         symbol = "??????";
         Print("ERROR: Empty symbol in list - check for extra commas");
         g_SymbolInitializationError = true;
      }

      g_SymbolData[i].Initialize(symbol);
      CalculateSymbolMultiplier(i);
   }

   return true;
}

//+------------------------------------------------------------------+
//| Calculate total lot multiplier for a symbol                      |
//| Used to optimize lot sizing when KeepOriginalLotSize is enabled  |
//+------------------------------------------------------------------+
void CalculateSymbolMultiplier(int symbolIndex)
{
   if (symbolIndex < 0 || symbolIndex >= ArraySize(g_SymbolData))
      return;

   double totalMultiplier = 0.1;  // Base lot

   for (int level = 1; level <= inp_MaxGridLevels - 1; level++)
   {
      totalMultiplier += CalculateGridLotSize(g_SymbolData[symbolIndex].GetSymbol(), 0.1, level, 0.0);
   }

   if (totalMultiplier > EPSILON)
      g_SymbolData[symbolIndex].SetTotalLotSizeMultiplier(totalMultiplier / 0.1);
   else
      g_SymbolData[symbolIndex].SetTotalLotSizeMultiplier(0.0);
}

//+------------------------------------------------------------------+
//| Initialize signal database with hardcoded patterns               |
//| Note: This appears to be proprietary data from original EA       |
//+------------------------------------------------------------------+
void InitializeSignalDatabase()
{
   // Allocate arrays
   ArrayResize(g_SignalPatterns, g_SignalDatabaseSize);
   ArrayResize(g_SignalPrices, g_SignalDatabaseSize);
   ArrayFill(g_SignalPatterns, 0, g_SignalDatabaseSize, 0);
   ArrayFill(g_SignalPrices, 0, g_SignalDatabaseSize, 0.0);

   g_SignalIndex = -1;

   // TODO: Load from external file instead of hardcoding
   // For now, keeping original hardcoded data for compatibility
   LoadHardcodedSignalDatabase();

   // Bubble sort the signal database by price
   SortSignalDatabase();

   PrintFormat("Signal database initialized: %d patterns", g_SignalDatabaseSize);
}

//+------------------------------------------------------------------+
//| Initialize trade history tracking                                |
//+------------------------------------------------------------------+
void InitializeTradeHistory()
{
   if (g_UseTradeHistory)
   {
      ArrayResize(g_TradeHistory, g_MaxHistorySize);
      g_HistoryIndex = -1;
   }
}

//+------------------------------------------------------------------+
//| HELPER FUNCTIONS                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check if trading is currently allowed                            |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
{
   // Check terminal permissions
   if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      return false;

   // Check account permissions
   if (!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
      return false;

   // Check MQL permissions
   if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Get error description from error code                            |
//+------------------------------------------------------------------+
string GetErrorDescription(int errorCode)
{
   if (errorCode == -1)
      errorCode = GetLastError();

   string prefix = StringFormat(" Err.code=%d: ", errorCode);

   switch(errorCode)
   {
      case ERR_NO_ERROR:                    return prefix + "No error";
      case ERR_NO_RESULT:                   return prefix + "No error but result unknown";
      case ERR_COMMON_ERROR:                return prefix + "Common error";
      case ERR_INVALID_TRADE_PARAMETERS:    return prefix + "Invalid trade parameters";
      case ERR_SERVER_BUSY:                 return prefix + "Trade server is busy";
      case ERR_OLD_VERSION:                 return prefix + "Old terminal version";
      case ERR_NO_CONNECTION:               return prefix + "No connection to trade server";
      case ERR_NOT_ENOUGH_RIGHTS:           return prefix + "Not enough rights";
      case ERR_TOO_FREQUENT_REQUESTS:       return prefix + "Too frequent requests";
      case ERR_MALFUNCTIONAL_TRADE:         return prefix + "Malfunctional trade operation";
      case ERR_ACCOUNT_DISABLED:            return prefix + "Account disabled";
      case ERR_INVALID_ACCOUNT:             return prefix + "Invalid account";
      case ERR_TRADE_TIMEOUT:               return prefix + "Trade timeout";
      case ERR_INVALID_PRICE:               return prefix + "Invalid price";
      case ERR_INVALID_STOPS:               return prefix + "Invalid stops";
      case ERR_INVALID_TRADE_VOLUME:        return prefix + "Invalid trade volume";
      case ERR_MARKET_CLOSED:               return prefix + "Market is closed";
      case ERR_TRADE_DISABLED:              return prefix + "Trade is disabled";
      case ERR_NOT_ENOUGH_MONEY:            return prefix + "Not enough money";
      case ERR_PRICE_CHANGED:               return prefix + "Price changed";
      case ERR_OFF_QUOTES:                  return prefix + "Off quotes";
      case ERR_BROKER_BUSY:                 return prefix + "Broker is busy";
      case ERR_REQUOTE:                     return prefix + "Requote";
      case ERR_ORDER_LOCKED:                return prefix + "Order is locked";
      case ERR_LONG_POSITIONS_ONLY_ALLOWED: return prefix + "Buy orders only allowed";
      case ERR_TOO_MANY_REQUESTS:           return prefix + "Too many requests";
      case 145:                              return prefix + "Order too close to market";
      case ERR_TRADE_CONTEXT_BUSY:          return prefix + "Trade context is busy";
      case 147:                              return prefix + "Expirations denied by broker";
      case 148:                              return prefix + "Order limit reached";
      case 149:                              return prefix + "Hedging prohibited";
      case 150:                              return prefix + "FIFO rule violation";
      default:                               return prefix + "Unknown error";
   }
}

//+------------------------------------------------------------------+
//| Get deinit reason as text                                        |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM:       return "Expert removed from chart";
      case REASON_REMOVE:        return "Expert removed from chart";
      case REASON_RECOMPILE:     return "Expert recompiled";
      case REASON_CHARTCHANGE:   return "Symbol/timeframe changed";
      case REASON_CHARTCLOSE:    return "Chart closed";
      case REASON_PARAMETERS:    return "Input parameters changed";
      case REASON_ACCOUNT:       return "Account changed";
      case REASON_TEMPLATE:      return "New template applied";
      case REASON_INITFAILED:    return "Initialization failed";
      case REASON_CLOSE:         return "Terminal closing";
      default:                    return "Unknown reason";
   }
}

//+------------------------------------------------------------------+
//| Convert timeframe to minutes                                     |
//+------------------------------------------------------------------+
int ConvertTimeframeToMinutes(int timeframe)
{
   switch(timeframe)
   {
      case PERIOD_CURRENT: return 0;
      case PERIOD_M1:  return 1;
      case PERIOD_M5:  return 5;
      case PERIOD_M15: return 15;
      case PERIOD_M30: return 30;
      case PERIOD_H1:  return 60;
      case PERIOD_H4:  return 240;
      case PERIOD_D1:  return 1440;
      case PERIOD_W1:  return 10080;
      case PERIOD_MN1: return 43200;
      default:          return 0;
   }
}

//+------------------------------------------------------------------+
//| TRADING QUERY FUNCTIONS                                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check if open positions exist for symbol/level/direction         |
//| Based on lizong_21 from original code                            |
//+------------------------------------------------------------------+
bool HasOpenPositions(string symbol, int gridLevel, int direction)
{
   int baseMagic = g_MagicNumberBase + inp_UID;
   int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));

   int minOrderType = -1;
   int maxOrderType = -1;
   int specificMagic = -1;
   int baseMagicForLevel = -1;

   // Calculate magic numbers based on direction
   // direction: 1 = buy only, -1 = sell only, 0 = both
   if (direction == 1) // Buy
   {
      minOrderType = OP_BUY;
      maxOrderType = OP_BUY;
      if (gridLevel >= 0)
         specificMagic = int(MathPow(10.0, magicDigits + 2)) + baseMagic * 100 + gridLevel;
      else
         baseMagicForLevel = baseMagic + int(MathPow(10.0, magicDigits));
   }
   else if (direction == -1) // Sell
   {
      minOrderType = OP_SELL;
      maxOrderType = OP_SELL;
      if (gridLevel >= 0)
         specificMagic = int(MathPow(10.0, magicDigits + 2)) * 2 + baseMagic * 100 + gridLevel;
      else
         baseMagicForLevel = baseMagic + int(MathPow(10.0, magicDigits)) * 2;
   }
   else // Both directions
   {
      minOrderType = OP_BUY;
      maxOrderType = OP_SELL;
      if (gridLevel >= 0)
      {
         specificMagic = int(MathPow(10.0, magicDigits + 2)) + baseMagic * 100 + gridLevel;
      }
      else
      {
         baseMagicForLevel = baseMagic + int(MathPow(10.0, magicDigits));
      }
   }

   // Search through all open orders
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         Print(inp_TradeComment + " " + symbol + ": Failed to select order! " + GetErrorDescription(GetLastError()));
         continue;
      }

      if (OrderSymbol() != symbol)
         continue;

      int orderType = OrderType();
      if (orderType < minOrderType || orderType > maxOrderType)
         continue;

      int magic = OrderMagicNumber();

      // Check specific level
      if (gridLevel >= 0)
      {
         if (magic == specificMagic)
            return true;
      }
      else // Check any level
      {
         int magicBase = magic / 100;
         if (magicBase == baseMagicForLevel)
            return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Get weighted average open price for symbol/direction             |
//| Based on lizong_22 from original code                            |
//+------------------------------------------------------------------+
double GetAverageOpenPrice(string symbol, int gridLevel, int direction)
{
   double totalPrice = 0.0;
   double totalLots = 0.0;

   int baseMagic = g_MagicNumberBase + inp_UID;
   int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));

   int targetOrderType = (direction == 1) ? OP_BUY : OP_SELL;
   int magicBase = -1;

   if (gridLevel < 0)
   {
      if (direction == 1)
         magicBase = baseMagic + int(MathPow(10.0, magicDigits));
      else
         magicBase = baseMagic + int(MathPow(10.0, magicDigits)) * 2;
   }

   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if (OrderSymbol() != symbol || OrderType() != targetOrderType)
         continue;

      int magic = OrderMagicNumber();

      if (gridLevel >= 0)
      {
         int expectedMagic;
         if (direction == 1)
            expectedMagic = int(MathPow(10.0, magicDigits + 2)) + baseMagic * 100 + gridLevel;
         else
            expectedMagic = int(MathPow(10.0, magicDigits + 2)) * 2 + baseMagic * 100 + gridLevel;

         if (magic != expectedMagic)
            continue;
      }
      else
      {
         if (magic / 100 != magicBase)
            continue;
      }

      totalPrice += OrderOpenPrice() * OrderLots();
      totalLots += OrderLots();
   }

   if (totalLots > EPSILON)
      return NormalizeDouble(totalPrice / totalLots, Digits);

   return 0.0;
}

//+------------------------------------------------------------------+
//| Get total lot size for symbol/direction                          |
//| Based on lizong_24 from original code                            |
//+------------------------------------------------------------------+
double GetTotalLotSize(string symbol, int gridLevel, int direction)
{
   double totalLots = 0.0;

   int baseMagic = g_MagicNumberBase + inp_UID;
   int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));

   int targetOrderType = (direction == 1) ? OP_BUY : OP_SELL;
   int magicBase = -1;

   if (gridLevel < 0)
   {
      if (direction == 1)
         magicBase = baseMagic + int(MathPow(10.0, magicDigits));
      else
         magicBase = baseMagic + int(MathPow(10.0, magicDigits)) * 2;
   }

   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if (OrderSymbol() != symbol || OrderType() != targetOrderType)
         continue;

      int magic = OrderMagicNumber();

      if (gridLevel >= 0)
      {
         int expectedMagic;
         if (direction == 1)
            expectedMagic = int(MathPow(10.0, magicDigits + 2)) + baseMagic * 100 + gridLevel;
         else
            expectedMagic = int(MathPow(10.0, magicDigits + 2)) * 2 + baseMagic * 100 + gridLevel;

         if (magic != expectedMagic)
            continue;
      }
      else
      {
         if (magic / 100 != magicBase)
            continue;
      }

      totalLots += OrderLots();
   }

   return totalLots;
}

//+------------------------------------------------------------------+
//| Calculate weighted take-profit price                             |
//| Based on lizong_23 from original code                            |
//+------------------------------------------------------------------+
double GetWeightedTPPrice(string symbol, int gridLevel, int direction)
{
   double totalTPPrice = 0.0;
   double totalLots = 0.0;

   int baseMagic = g_MagicNumberBase + inp_UID;
   int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));

   int targetOrderType = (direction == 1) ? OP_BUY : OP_SELL;
   int magicBase = -1;

   if (gridLevel < 0)
   {
      if (direction == 1)
         magicBase = baseMagic + int(MathPow(10.0, magicDigits));
      else
         magicBase = baseMagic + int(MathPow(10.0, magicDigits)) * 2;
   }

   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if (OrderSymbol() != symbol || OrderType() != targetOrderType)
         continue;

      int magic = OrderMagicNumber();

      if (gridLevel >= 0)
      {
         int expectedMagic;
         if (direction == 1)
            expectedMagic = int(MathPow(10.0, magicDigits + 2)) + baseMagic * 100 + gridLevel;
         else
            expectedMagic = int(MathPow(10.0, magicDigits + 2)) * 2 + baseMagic * 100 + gridLevel;

         if (magic != expectedMagic)
            continue;
      }
      else
      {
         if (magic / 100 != magicBase)
            continue;
      }

      if (OrderTakeProfit() > EPSILON)
      {
         totalTPPrice += OrderTakeProfit() * OrderLots();
         totalLots += OrderLots();
      }
   }

   if (totalLots > EPSILON)
      return NormalizeDouble(totalTPPrice / totalLots, Digits);

   return 0.0;
}

//+------------------------------------------------------------------+
//| LOT SIZING FUNCTIONS                                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate initial lot size based on selected method              |
//+------------------------------------------------------------------+
double CalculateInitialLotSize(string symbol)
{
   double lotSize = inp_LotSize;
   double balance = (inp_LotSizingMethod == LOT_EQUITY_BASED) ? AccountEquity() : AccountBalance();

   switch(inp_LotSizingMethod)
   {
      case LOT_FIXED:
         lotSize = inp_LotSize;
         break;

      case LOT_BALANCE_BASED:
      case LOT_EQUITY_BASED:
         lotSize = NormalizeDouble(balance * inp_LotSizePercent / 100.0 / 1000.0, 2);
         break;

      case LOT_RISK_80_PERCENT:
         lotSize = NormalizeDouble(balance * 0.80 / 1000.0, 2);
         break;

      case LOT_RISK_50_PERCENT:
         lotSize = NormalizeDouble(balance * 0.50 / 1000.0, 2);
         break;

      case LOT_RISK_20_PERCENT:
         lotSize = NormalizeDouble(balance * 0.20 / 1000.0, 2);
         break;
   }

   // Apply symbol-specific multiplier
   for (int i = 0; i < ArraySize(g_SymbolData); i++)
   {
      if (g_SymbolData[i].GetSymbol() == symbol)
      {
         lotSize *= g_SymbolData[i].GetTotalLotSizeMultiplier();
         break;
      }
   }

   // Normalize to broker requirements
   double minLot = MarketInfo(symbol, MODE_MINLOT);
   double maxLot = MarketInfo(symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(symbol, MODE_LOTSTEP);

   lotSize = MathMax(lotSize, minLot);
   lotSize = MathMin(lotSize, maxLot);
   lotSize = NormalizeDouble(MathRound(lotSize / lotStep) * lotStep, 2);

   return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate grid lot size with multiplier progression              |
//| Based on lizong_36 from original code                            |
//+------------------------------------------------------------------+
double CalculateGridLotSize(string symbol, double baseLot, int level, double initialLot)
{
   if (level <= 0)
      return baseLot;

   double multiplier = 1.0;

   // Progressive multiplier based on grid level
   if (level == 1)
      multiplier = inp_LotMultiplier1;
   else if (level == 2)
      multiplier = inp_LotMultiplier2;
   else if (level == 3)
      multiplier = inp_LotMultiplier3;
   else if (level == 4)
      multiplier = inp_LotMultiplier4;
   else if (level == 5)
      multiplier = inp_LotMultiplier5;
   else if (level == 6)
      multiplier = inp_LotMultiplier6;
   else if (level == 7)
      multiplier = inp_LotMultiplier7;
   else if (level == 8)
      multiplier = inp_LotMultiplier8;
   else if (level == 9)
      multiplier = inp_LotMultiplier9;
   else if (level >= 10)
      multiplier = inp_LotMultiplier10Plus;

   double lotSize = baseLot * multiplier;

   // Normalize to broker requirements
   double minLot = MarketInfo(symbol, MODE_MINLOT);
   double maxLot = MarketInfo(symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(symbol, MODE_LOTSTEP);

   lotSize = MathMax(lotSize, minLot);
   lotSize = MathMin(lotSize, maxLot);
   lotSize = NormalizeDouble(MathRound(lotSize / lotStep) * lotStep, 2);

   return lotSize;
}

//+------------------------------------------------------------------+
//| TP/SL CALCULATION FUNCTIONS                                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate take-profit price for a position                       |
//+------------------------------------------------------------------+
double CalculateTakeProfit(string symbol, int direction, double openPrice, double pipDistance)
{
   double point = MarketInfo(symbol, MODE_POINT);
   int digits = (int)MarketInfo(symbol, MODE_DIGITS);

   // Adjust for 5-digit brokers
   double pipValue = (digits == 3 || digits == 5) ? point * 10 : point;

   double tpPrice = 0.0;

   if (direction == OP_BUY)
      tpPrice = openPrice + pipDistance * pipValue;
   else if (direction == OP_SELL)
      tpPrice = openPrice - pipDistance * pipValue;

   return NormalizeDouble(tpPrice, digits);
}

//+------------------------------------------------------------------+
//| Calculate stop-loss price for a position                         |
//+------------------------------------------------------------------+
double CalculateStopLoss(string symbol, int direction, double openPrice, double pipDistance)
{
   if (pipDistance <= 0)
      return 0.0;

   double point = MarketInfo(symbol, MODE_POINT);
   int digits = (int)MarketInfo(symbol, MODE_DIGITS);

   // Adjust for 5-digit brokers
   double pipValue = (digits == 3 || digits == 5) ? point * 10 : point;

   double slPrice = 0.0;

   if (direction == OP_BUY)
      slPrice = openPrice - pipDistance * pipValue;
   else if (direction == OP_SELL)
      slPrice = openPrice + pipDistance * pipValue;

   return NormalizeDouble(slPrice, digits);
}

//+------------------------------------------------------------------+
//| ORDER EXECUTION FUNCTIONS                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Open a buy grid order                                            |
//+------------------------------------------------------------------+
int OpenBuyGridOrder(string symbol, double lotSize, int gridLevel, double takeProfit = 0.0, double stopLoss = 0.0)
{
   int baseMagic = g_MagicNumberBase + inp_UID;
   int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));
   int magic = int(MathPow(10.0, magicDigits + 2)) + baseMagic * 100 + gridLevel;

   double price = MarketInfo(symbol, MODE_ASK);
   int slippage = 3;

   string comment = inp_TradeComment + " L" + IntegerToString(gridLevel);

   int ticket = OrderSend(symbol, OP_BUY, lotSize, price, slippage, stopLoss, takeProfit, comment, magic, 0, clrBlue);

   if (ticket > 0)
   {
      PrintFormat("%s: Buy order opened at %s, Lot: %.2f, Level: %d, Magic: %d",
                  symbol, DoubleToString(price, Digits), lotSize, gridLevel, magic);
      return ticket;
   }
   else
   {
      PrintFormat("%s: Failed to open buy order! %s", symbol, GetErrorDescription(GetLastError()));
      return -1;
   }
}

//+------------------------------------------------------------------+
//| Open a sell grid order                                           |
//+------------------------------------------------------------------+
int OpenSellGridOrder(string symbol, double lotSize, int gridLevel, double takeProfit = 0.0, double stopLoss = 0.0)
{
   int baseMagic = g_MagicNumberBase + inp_UID;
   int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));
   int magic = int(MathPow(10.0, magicDigits + 2)) * 2 + baseMagic * 100 + gridLevel;

   double price = MarketInfo(symbol, MODE_BID);
   int slippage = 3;

   string comment = inp_TradeComment + " L" + IntegerToString(gridLevel);

   int ticket = OrderSend(symbol, OP_SELL, lotSize, price, slippage, stopLoss, takeProfit, comment, magic, 0, clrRed);

   if (ticket > 0)
   {
      PrintFormat("%s: Sell order opened at %s, Lot: %.2f, Level: %d, Magic: %d",
                  symbol, DoubleToString(price, Digits), lotSize, gridLevel, magic);
      return ticket;
   }
   else
   {
      PrintFormat("%s: Failed to open sell order! %s", symbol, GetErrorDescription(GetLastError()));
      return -1;
   }
}

//+------------------------------------------------------------------+
//| Try to close buy orders                                          |
//+------------------------------------------------------------------+
bool TryCloseBuyOrders(string symbol, int gridLevel = -1)
{
   bool success = true;

   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if (OrderSymbol() != symbol || OrderType() != OP_BUY)
         continue;

      int baseMagic = g_MagicNumberBase + inp_UID;
      int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));
      int magic = OrderMagicNumber();

      // Check if this order belongs to our EA
      int magicBase = magic / 100;
      int expectedMagicBase = baseMagic + int(MathPow(10.0, magicDigits));

      if (gridLevel >= 0)
      {
         int expectedMagic = int(MathPow(10.0, magicDigits + 2)) + baseMagic * 100 + gridLevel;
         if (magic != expectedMagic)
            continue;
      }
      else
      {
         if (magicBase != expectedMagicBase)
            continue;
      }

      double closePrice = MarketInfo(symbol, MODE_BID);

      if (!OrderClose(OrderTicket(), OrderLots(), closePrice, 3, clrGreen))
      {
         PrintFormat("%s: Failed to close buy order #%d! %s", symbol, OrderTicket(), GetErrorDescription(GetLastError()));
         success = false;
      }
      else
      {
         PrintFormat("%s: Buy order #%d closed at %s, Profit: %.2f",
                     symbol, OrderTicket(), DoubleToString(closePrice, Digits), OrderProfit() + OrderSwap() + OrderCommission());
      }
   }

   return success;
}

//+------------------------------------------------------------------+
//| Try to close sell orders                                         |
//+------------------------------------------------------------------+
bool TryCloseSellOrders(string symbol, int gridLevel = -1)
{
   bool success = true;

   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if (OrderSymbol() != symbol || OrderType() != OP_SELL)
         continue;

      int baseMagic = g_MagicNumberBase + inp_UID;
      int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));
      int magic = OrderMagicNumber();

      // Check if this order belongs to our EA
      int magicBase = magic / 100;
      int expectedMagicBase = baseMagic + int(MathPow(10.0, magicDigits)) * 2;

      if (gridLevel >= 0)
      {
         int expectedMagic = int(MathPow(10.0, magicDigits + 2)) * 2 + baseMagic * 100 + gridLevel;
         if (magic != expectedMagic)
            continue;
      }
      else
      {
         if (magicBase != expectedMagicBase)
            continue;
      }

      double closePrice = MarketInfo(symbol, MODE_ASK);

      if (!OrderClose(OrderTicket(), OrderLots(), closePrice, 3, clrGreen))
      {
         PrintFormat("%s: Failed to close sell order #%d! %s", symbol, OrderTicket(), GetErrorDescription(GetLastError()));
         success = false;
      }
      else
      {
         PrintFormat("%s: Sell order #%d closed at %s, Profit: %.2f",
                     symbol, OrderTicket(), DoubleToString(closePrice, Digits), OrderProfit() + OrderSwap() + OrderCommission());
      }
   }

   return success;
}

//+------------------------------------------------------------------+
//| Modify buy order TP/SL                                           |
//+------------------------------------------------------------------+
bool ModifyBuyOrderTPSL(int ticket, double newTP, double newSL)
{
   if (!OrderSelect(ticket, SELECT_BY_TICKET))
   {
      PrintFormat("Failed to select order #%d for modification", ticket);
      return false;
   }

   double currentTP = OrderTakeProfit();
   double currentSL = OrderStopLoss();

   // Check if modification is needed
   if (MathAbs(currentTP - newTP) < EPSILON && MathAbs(currentSL - newSL) < EPSILON)
      return true; // No change needed

   // Validate stop levels
   double minStopLevel = MarketInfo(OrderSymbol(), MODE_STOPLEVEL) * MarketInfo(OrderSymbol(), MODE_POINT);
   double bid = MarketInfo(OrderSymbol(), MODE_BID);

   if (newTP > EPSILON && (newTP - bid) < minStopLevel)
   {
      PrintFormat("TP too close to market: %.5f, min distance: %.5f", newTP - bid, minStopLevel);
      return false;
   }

   if (newSL > EPSILON && (bid - newSL) < minStopLevel)
   {
      PrintFormat("SL too close to market: %.5f, min distance: %.5f", bid - newSL, minStopLevel);
      return false;
   }

   if (!OrderModify(ticket, OrderOpenPrice(), newSL, newTP, 0, clrBlue))
   {
      PrintFormat("Failed to modify buy order #%d! %s", ticket, GetErrorDescription(GetLastError()));
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Modify sell order TP/SL                                          |
//+------------------------------------------------------------------+
bool ModifySellOrderTPSL(int ticket, double newTP, double newSL)
{
   if (!OrderSelect(ticket, SELECT_BY_TICKET))
   {
      PrintFormat("Failed to select order #%d for modification", ticket);
      return false;
   }

   double currentTP = OrderTakeProfit();
   double currentSL = OrderStopLoss();

   // Check if modification is needed
   if (MathAbs(currentTP - newTP) < EPSILON && MathAbs(currentSL - newSL) < EPSILON)
      return true; // No change needed

   // Validate stop levels
   double minStopLevel = MarketInfo(OrderSymbol(), MODE_STOPLEVEL) * MarketInfo(OrderSymbol(), MODE_POINT);
   double ask = MarketInfo(OrderSymbol(), MODE_ASK);

   if (newTP > EPSILON && (ask - newTP) < minStopLevel)
   {
      PrintFormat("TP too close to market: %.5f, min distance: %.5f", ask - newTP, minStopLevel);
      return false;
   }

   if (newSL > EPSILON && (newSL - ask) < minStopLevel)
   {
      PrintFormat("SL too close to market: %.5f, min distance: %.5f", newSL - ask, minStopLevel);
      return false;
   }

   if (!OrderModify(ticket, OrderOpenPrice(), newSL, newTP, 0, clrRed))
   {
      PrintFormat("Failed to modify sell order #%d! %s", ticket, GetErrorDescription(GetLastError()));
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| MARKET ANALYSIS FUNCTIONS                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Analyze market conditions and generate trading signals           |
//| Based on lizong_32 from original code                            |
//+------------------------------------------------------------------+
void AnalyzeMarketConditions(int symbolIndex)
{
   string symbol = g_SymbolData[symbolIndex].GetSymbol();

   // Get Bollinger Bands values
   double bbUpper = iBands(symbol, TF_M15, inp_BB_Period, inp_BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   double bbLower = iBands(symbol, TF_M15, inp_BB_Period, inp_BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double bbMiddle = iBands(symbol, TF_M15, inp_BB_Period, inp_BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, 0);

   // Get RSI value
   double rsi = iRSI(symbol, TF_M15, inp_RSI_Period, PRICE_CLOSE, 0);

   // Get current price
   double bid = MarketInfo(symbol, MODE_BID);
   double ask = MarketInfo(symbol, MODE_ASK);
   double close = iClose(symbol, TF_M15, 0);

   // Calculate BB range
   double bbRange = bbUpper - bbLower;
   g_SymbolData[symbolIndex].SetBBRangeSize(bbRange);

   // Update smart distance multiplier based on volatility
   double atr = iATR(symbol, TF_M15, 14, 0);
   double avgATR = 0.0;
   for (int i = 0; i < 20; i++)
      avgATR += iATR(symbol, TF_M15, 14, i);
   avgATR /= 20.0;

   double smartMultiplier = (atr > EPSILON && avgATR > EPSILON) ? (atr / avgATR) : 1.0;
   g_SymbolData[symbolIndex].SetSmartDistanceMultiplier(smartMultiplier);

   // Check for buy signals
   bool buySignal = false;
   if (inp_UseBollingerBands && close < bbLower + bbRange * 0.2)
   {
      if (inp_UseRSI && rsi < inp_RSI_OversoldLevel)
         buySignal = true;
      else if (!inp_UseRSI)
         buySignal = true;
   }

   // Check for sell signals
   bool sellSignal = false;
   if (inp_UseBollingerBands && close > bbUpper - bbRange * 0.2)
   {
      if (inp_UseRSI && rsi > inp_RSI_OverboughtLevel)
         sellSignal = true;
      else if (!inp_UseRSI)
         sellSignal = true;
   }

   // Update symbol permissions
   g_SymbolData[symbolIndex].SetAllowBuySignals(buySignal);
   g_SymbolData[symbolIndex].SetAllowSellSignals(sellSignal);

   // Execute initial trades if no positions exist
   if (buySignal && !HasOpenPositions(symbol, -1, 1))
   {
      if (g_SymbolData[symbolIndex].CanBuy())
      {
         double lotSize = CalculateInitialLotSize(symbol);
         double tp = CalculateTakeProfit(symbol, OP_BUY, ask, inp_TakeProfitPips);
         double sl = CalculateStopLoss(symbol, OP_BUY, ask, inp_StopLossPips);

         int ticket = OpenBuyGridOrder(symbol, lotSize, 0, tp, sl);
         if (ticket > 0)
         {
            g_SymbolData[symbolIndex].SetLastBuyGridTime(TimeCurrent());
            g_SymbolData[symbolIndex].SetAllowNewBuyGrid(true);
         }
      }
   }

   if (sellSignal && !HasOpenPositions(symbol, -1, -1))
   {
      if (g_SymbolData[symbolIndex].CanSell())
      {
         double lotSize = CalculateInitialLotSize(symbol);
         double tp = CalculateTakeProfit(symbol, OP_SELL, bid, inp_TakeProfitPips);
         double sl = CalculateStopLoss(symbol, OP_SELL, bid, inp_StopLossPips);

         int ticket = OpenSellGridOrder(symbol, lotSize, 0, tp, sl);
         if (ticket > 0)
         {
            g_SymbolData[symbolIndex].SetLastSellGridTime(TimeCurrent());
            g_SymbolData[symbolIndex].SetAllowNewSellGrid(true);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| GRID MANAGEMENT FUNCTIONS                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Manage grid expansion and averaging                              |
//| Based on lizong_37 from original code                            |
//+------------------------------------------------------------------+
void ManageGridExpansion(int symbolIndex)
{
   string symbol = g_SymbolData[symbolIndex].GetSymbol();

   double bid = MarketInfo(symbol, MODE_BID);
   double ask = MarketInfo(symbol, MODE_ASK);

   // Get grid spacing based on SmartDistance or fixed pips
   double gridDistance = inp_GridDistancePips;
   if (inp_UseSmartDistance)
   {
      gridDistance = gridDistance * g_SymbolData[symbolIndex].GetSmartDistanceMultiplier();
   }

   double point = MarketInfo(symbol, MODE_POINT);
   int digits = (int)MarketInfo(symbol, MODE_DIGITS);
   double pipValue = (digits == 3 || digits == 5) ? point * 10 : point;
   double gridSpacing = gridDistance * pipValue;

   // Manage buy grid expansion
   if (HasOpenPositions(symbol, -1, 1))
   {
      double avgBuyPrice = GetAverageOpenPrice(symbol, -1, 1);

      if (avgBuyPrice > EPSILON)
      {
         // Check if price has moved away enough to trigger next grid level
         double distanceFromAvg = avgBuyPrice - bid;

         if (distanceFromAvg >= gridSpacing)
         {
            // Count existing buy positions
            int buyLevels = 0;
            for (int level = 0; level < inp_MaxGridLevels; level++)
            {
               if (HasOpenPositions(symbol, level, 1))
                  buyLevels++;
            }

            if (buyLevels < inp_MaxGridLevels)
            {
               // Open next grid level
               double baseLot = CalculateInitialLotSize(symbol);
               double lotSize = CalculateGridLotSize(symbol, baseLot, buyLevels, baseLot);

               double avgPrice = GetAverageOpenPrice(symbol, -1, 1);
               double totalLots = GetTotalLotSize(symbol, -1, 1) + lotSize;

               // Calculate weighted TP
               double newAvgPrice = (avgPrice * GetTotalLotSize(symbol, -1, 1) + ask * lotSize) / totalLots;
               double tp = CalculateTakeProfit(symbol, OP_BUY, newAvgPrice, inp_TakeProfitPips);
               double sl = 0.0; // No SL for grid levels

               int ticket = OpenBuyGridOrder(symbol, lotSize, buyLevels, tp, sl);
               if (ticket > 0)
               {
                  g_SymbolData[symbolIndex].SetLastBuyGridTime(TimeCurrent());
               }
            }
         }
      }
   }

   // Manage sell grid expansion
   if (HasOpenPositions(symbol, -1, -1))
   {
      double avgSellPrice = GetAverageOpenPrice(symbol, -1, -1);

      if (avgSellPrice > EPSILON)
      {
         // Check if price has moved away enough to trigger next grid level
         double distanceFromAvg = ask - avgSellPrice;

         if (distanceFromAvg >= gridSpacing)
         {
            // Count existing sell positions
            int sellLevels = 0;
            for (int level = 0; level < inp_MaxGridLevels; level++)
            {
               if (HasOpenPositions(symbol, level, -1))
                  sellLevels++;
            }

            if (sellLevels < inp_MaxGridLevels)
            {
               // Open next grid level
               double baseLot = CalculateInitialLotSize(symbol);
               double lotSize = CalculateGridLotSize(symbol, baseLot, sellLevels, baseLot);

               double avgPrice = GetAverageOpenPrice(symbol, -1, -1);
               double totalLots = GetTotalLotSize(symbol, -1, -1) + lotSize;

               // Calculate weighted TP
               double newAvgPrice = (avgPrice * GetTotalLotSize(symbol, -1, -1) + bid * lotSize) / totalLots;
               double tp = CalculateTakeProfit(symbol, OP_SELL, newAvgPrice, inp_TakeProfitPips);
               double sl = 0.0; // No SL for grid levels

               int ticket = OpenSellGridOrder(symbol, lotSize, sellLevels, tp, sl);
               if (ticket > 0)
               {
                  g_SymbolData[symbolIndex].SetLastSellGridTime(TimeCurrent());
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| ORDER UPDATE FUNCTIONS                                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Update buy orders TP/SL based on weighted average                |
//| Based on lizong_25 from original code                            |
//+------------------------------------------------------------------+
void UpdateBuyOrders(int symbolIndex)
{
   string symbol = g_SymbolData[symbolIndex].GetSymbol();

   if (!HasOpenPositions(symbol, -1, 1))
      return;

   double avgPrice = GetAverageOpenPrice(symbol, -1, 1);
   if (avgPrice < EPSILON)
      return;

   // Calculate weighted TP
   double newTP = CalculateTakeProfit(symbol, OP_BUY, avgPrice, inp_TakeProfitPips);

   // Update all buy orders with new TP
   int baseMagic = g_MagicNumberBase + inp_UID;
   int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));
   int magicBase = baseMagic + int(MathPow(10.0, magicDigits));

   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if (OrderSymbol() != symbol || OrderType() != OP_BUY)
         continue;

      int magic = OrderMagicNumber();
      if (magic / 100 != magicBase)
         continue;

      // Modify TP
      ModifyBuyOrderTPSL(OrderTicket(), newTP, OrderStopLoss());
   }

   g_SymbolData[symbolIndex].SetTargetBuyTP(newTP);
}

//+------------------------------------------------------------------+
//| Update sell orders TP/SL based on weighted average               |
//| Based on lizong_26 from original code                            |
//+------------------------------------------------------------------+
void UpdateSellOrders(int symbolIndex)
{
   string symbol = g_SymbolData[symbolIndex].GetSymbol();

   if (!HasOpenPositions(symbol, -1, -1))
      return;

   double avgPrice = GetAverageOpenPrice(symbol, -1, -1);
   if (avgPrice < EPSILON)
      return;

   // Calculate weighted TP
   double newTP = CalculateTakeProfit(symbol, OP_SELL, avgPrice, inp_TakeProfitPips);

   // Update all sell orders with new TP
   int baseMagic = g_MagicNumberBase + inp_UID;
   int magicDigits = StringLen(IntegerToString(baseMagic, 0, 32));
   int magicBase = baseMagic + int(MathPow(10.0, magicDigits)) * 2;

   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;

      if (OrderSymbol() != symbol || OrderType() != OP_SELL)
         continue;

      int magic = OrderMagicNumber();
      if (magic / 100 != magicBase)
         continue;

      // Modify TP
      ModifySellOrderTPSL(OrderTicket(), newTP, OrderStopLoss());
   }

   g_SymbolData[symbolIndex].SetTargetSellTP(newTP);
}

//+------------------------------------------------------------------+
//| Main position management routine                                 |
//| Based on lizong_35 from original code                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   // Check drawdown limits
   if (inp_MaxDrawdownPercent > 0)
   {
      double balance = AccountBalance();
      double equity = AccountEquity();
      double drawdownPercent = (balance > EPSILON) ? (balance - equity) / balance * 100.0 : 0.0;

      if (drawdownPercent >= inp_MaxDrawdownPercent)
      {
         PrintFormat("WARNING: Maximum drawdown reached: %.2f%% >= %.2f%%", drawdownPercent, inp_MaxDrawdownPercent);

         if (inp_DrawdownAction == DRAWDOWN_CLOSE_ALL)
         {
            PrintFormat("Closing all positions due to drawdown limit!");
            for (int i = 0; i < ArraySize(g_SymbolData); i++)
            {
               string symbol = g_SymbolData[i].GetSymbol();
               TryCloseBuyOrders(symbol);
               TryCloseSellOrders(symbol);
            }
            g_ForceCloseMode = true;
            return;
         }
         else if (inp_DrawdownAction == DRAWDOWN_STOP_NEW_TRADES)
         {
            PrintFormat("Stopping new trades due to drawdown limit!");
            g_AllowNewGrids = false;
         }
      }
   }

   // Check margin level
   if (AccountMargin() > EPSILON)
   {
      double marginLevel = AccountEquity() / AccountMargin() * 100.0;

      if (marginLevel < inp_MinMarginLevel)
      {
         datetime currentTime = TimeCurrent();
         if (currentTime - g_LastMarginWarning > 300) // Warn every 5 minutes
         {
            PrintFormat("WARNING: Low margin level: %.2f%% < %.2f%%", marginLevel, inp_MinMarginLevel);
            g_LastMarginWarning = currentTime;
         }

         // Stop new trades if margin is critically low
         if (marginLevel < inp_MinMarginLevel / 2)
         {
            g_AllowNewGrids = false;
         }
      }
   }

   // Update orders for each symbol
   for (int i = 0; i < ArraySize(g_SymbolData); i++)
   {
      UpdateBuyOrders(i);
      UpdateSellOrders(i);
   }
}

//+------------------------------------------------------------------+
//| SIGNAL DATABASE FUNCTIONS                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Load hardcoded signal patterns                                   |
//| Based on lizong_27 from original code                            |
//| Note: Original contains 3000+ proprietary patterns               |
//+------------------------------------------------------------------+
void LoadHardcodedSignalDatabase()
{
   // The original EA contains 3000+ hardcoded signal patterns
   // This appears to be proprietary intellectual property
   // Implementation stub provided - populate with actual patterns if available

   int index = 0;

   // Example pattern structure (from original code analysis):
   // g_SignalPatterns[index] = patternID (long)
   // g_SignalPrices[index] = price level (double)

   // Sample patterns (replace with actual data):
   if (index < g_SignalDatabaseSize)
   {
      g_SignalPatterns[index] = 1;
      g_SignalPrices[index] = 1.0;
      index++;
   }

   PrintFormat("Signal database loaded: %d patterns (stub implementation)", index);

   // Note: The original code had extensive hardcoded data here
   // To implement properly, you would need to either:
   // 1. Load from an external file (CSV/JSON)
   // 2. Generate patterns algorithmically
   // 3. Obtain the original proprietary pattern data
}

//+------------------------------------------------------------------+
//| Sort signal database by price using bubble sort                  |
//+------------------------------------------------------------------+
void SortSignalDatabase()
{
   if (g_SignalDatabaseSize <= 1)
      return;

   // Bubble sort implementation (as in original code)
   for (int i = 0; i < g_SignalDatabaseSize - 1; i++)
   {
      for (int j = 0; j < g_SignalDatabaseSize - i - 1; j++)
      {
         if (g_SignalPrices[j] > g_SignalPrices[j + 1])
         {
            // Swap prices
            double tempPrice = g_SignalPrices[j];
            g_SignalPrices[j] = g_SignalPrices[j + 1];
            g_SignalPrices[j + 1] = tempPrice;

            // Swap patterns
            long tempPattern = g_SignalPatterns[j];
            g_SignalPatterns[j] = g_SignalPatterns[j + 1];
            g_SignalPatterns[j + 1] = tempPattern;
         }
      }
   }

   PrintFormat("Signal database sorted: %d patterns", g_SignalDatabaseSize);
}

//+------------------------------------------------------------------+
//| Check if current price matches a signal pattern                  |
//| Based on lizong_28 from original code                            |
//+------------------------------------------------------------------+
bool CheckSignalPattern(string symbol, double price)
{
   if (!g_UseSignalDatabase || g_SignalDatabaseSize == 0)
      return true; // Allow all signals if database is disabled

   // Binary search for price level (array is sorted)
   int left = 0;
   int right = g_SignalDatabaseSize - 1;

   double tolerance = 0.0001; // Price tolerance for matching

   while (left <= right)
   {
      int mid = (left + right) / 2;

      if (MathAbs(g_SignalPrices[mid] - price) < tolerance)
      {
         // Found matching pattern
         return true;
      }
      else if (g_SignalPrices[mid] < price)
      {
         left = mid + 1;
      }
      else
      {
         right = mid - 1;
      }
   }

   return false; // No matching pattern found
}

//+------------------------------------------------------------------+
//| GUI FUNCTIONS                                                     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialize GUI trading panel                                     |
//| Based on lizong_46 from original code                            |
//+------------------------------------------------------------------+
void InitializeGUIPanel()
{
   if (IsOptimization() || IsTesting())
      return;

   if (!inp_ShowPanel)
      return;

   // Create main panel background
   string panelName = "WakaWakaPanel_BG";
   if (ObjectFind(0, panelName) < 0)
   {
      ObjectCreate(0, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, panelName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, panelName, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, panelName, OBJPROP_XSIZE, 250);
      ObjectSetInteger(0, panelName, OBJPROP_YSIZE, 300);
      ObjectSetInteger(0, panelName, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, panelName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, panelName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, panelName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, panelName, OBJPROP_BACK, false);
      ObjectSetInteger(0, panelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, panelName, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, panelName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, panelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }

   // Create panel title
   string titleName = "WakaWakaPanel_Title";
   if (ObjectFind(0, titleName) < 0)
   {
      ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, 25);
      ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, titleName, OBJPROP_FONT, "Arial Bold");
      ObjectSetString(0, titleName, OBJPROP_TEXT, "WAKA WAKA EA v" + g_Version);
      ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, titleName, OBJPROP_HIDDEN, true);
   }

   // Create info labels
   int yPos = 50;
   for (int i = 0; i < 10; i++)
   {
      string labelName = "WakaWakaPanel_Info" + IntegerToString(i);
      if (ObjectFind(0, labelName) < 0)
      {
         ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 20);
         ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, yPos + i * 20);
         ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
         ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
      }
   }

   UpdateGUIPanel(true);
}

//+------------------------------------------------------------------+
//| Update GUI panel with current statistics                         |
//| Based on lizong_49 from original code                            |
//+------------------------------------------------------------------+
void UpdateGUIPanel(bool initial)
{
   if (IsOptimization() || IsTesting())
      return;

   if (!inp_ShowPanel)
      return;

   // Update info labels
   ObjectSetString(0, "WakaWakaPanel_Info0", OBJPROP_TEXT,
                   StringFormat("Account: %d", AccountNumber()));

   ObjectSetString(0, "WakaWakaPanel_Info1", OBJPROP_TEXT,
                   StringFormat("Balance: %.2f %s", AccountBalance(), AccountCurrency()));

   ObjectSetString(0, "WakaWakaPanel_Info2", OBJPROP_TEXT,
                   StringFormat("Equity: %.2f %s", AccountEquity(), AccountCurrency()));

   double profit = AccountEquity() - AccountBalance();
   color profitColor = (profit >= 0) ? clrLime : clrRed;
   ObjectSetInteger(0, "WakaWakaPanel_Info2", OBJPROP_COLOR, profitColor);

   ObjectSetString(0, "WakaWakaPanel_Info3", OBJPROP_TEXT,
                   StringFormat("Profit: %.2f %s", profit, AccountCurrency()));
   ObjectSetInteger(0, "WakaWakaPanel_Info3", OBJPROP_COLOR, profitColor);

   // Calculate drawdown
   double drawdown = (AccountBalance() > EPSILON) ?
                     (AccountBalance() - AccountEquity()) / AccountBalance() * 100.0 : 0.0;

   ObjectSetString(0, "WakaWakaPanel_Info4", OBJPROP_TEXT,
                   StringFormat("Drawdown: %.2f%%", drawdown));

   color ddColor = clrWhite;
   if (drawdown > inp_MaxDrawdownPercent * 0.8)
      ddColor = clrRed;
   else if (drawdown > inp_MaxDrawdownPercent * 0.5)
      ddColor = clrYellow;

   ObjectSetInteger(0, "WakaWakaPanel_Info4", OBJPROP_COLOR, ddColor);

   // Margin level
   double marginLevel = (AccountMargin() > EPSILON) ?
                        AccountEquity() / AccountMargin() * 100.0 : 0.0;

   ObjectSetString(0, "WakaWakaPanel_Info5", OBJPROP_TEXT,
                   StringFormat("Margin: %.2f%%", marginLevel));

   color marginColor = clrWhite;
   if (marginLevel < inp_MinMarginLevel)
      marginColor = clrRed;
   else if (marginLevel < inp_MinMarginLevel * 1.5)
      marginColor = clrYellow;

   ObjectSetInteger(0, "WakaWakaPanel_Info5", OBJPROP_COLOR, marginColor);

   // Count open positions
   int totalBuyOrders = 0;
   int totalSellOrders = 0;

   for (int i = 0; i < ArraySize(g_SymbolData); i++)
   {
      string symbol = g_SymbolData[i].GetSymbol();
      if (HasOpenPositions(symbol, -1, 1))
         totalBuyOrders++;
      if (HasOpenPositions(symbol, -1, -1))
         totalSellOrders++;
   }

   ObjectSetString(0, "WakaWakaPanel_Info6", OBJPROP_TEXT,
                   StringFormat("Buy Grids: %d", totalBuyOrders));

   ObjectSetString(0, "WakaWakaPanel_Info7", OBJPROP_TEXT,
                   StringFormat("Sell Grids: %d", totalSellOrders));

   ObjectSetString(0, "WakaWakaPanel_Info8", OBJPROP_TEXT,
                   StringFormat("Total Orders: %d", OrdersTotal()));

   // Trading status
   string status = "Active";
   color statusColor = clrLime;

   if (g_ForceCloseMode)
   {
      status = "CLOSED (DD)";
      statusColor = clrRed;
   }
   else if (!g_AllowNewGrids)
   {
      status = "Paused";
      statusColor = clrYellow;
   }

   ObjectSetString(0, "WakaWakaPanel_Info9", OBJPROP_TEXT,
                   StringFormat("Status: %s", status));
   ObjectSetInteger(0, "WakaWakaPanel_Info9", OBJPROP_COLOR, statusColor);

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Handle button click events from GUI                              |
//| Based on lizong_48 from original code                            |
//+------------------------------------------------------------------+
void HandleButtonClick(string clickedObject)
{
   // Handle GUI button interactions
   // Implementation stub - extend based on specific button requirements

   if (StringFind(clickedObject, "WakaWaka") >= 0)
   {
      PrintFormat("GUI object clicked: %s", clickedObject);

      // Example: Close All button
      if (StringFind(clickedObject, "CloseAll") >= 0)
      {
         for (int i = 0; i < ArraySize(g_SymbolData); i++)
         {
            string symbol = g_SymbolData[i].GetSymbol();
            TryCloseBuyOrders(symbol);
            TryCloseSellOrders(symbol);
         }
      }

      // Example: Pause/Resume button
      if (StringFind(clickedObject, "Pause") >= 0)
      {
         g_AllowNewGrids = !g_AllowNewGrids;
         UpdateGUIPanel(false);
      }
   }
}

//+------------------------------------------------------------------+
