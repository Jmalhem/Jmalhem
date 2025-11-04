# WAKA WAKA EA - REFACTORING GUIDE

## Version: 2.12 → 3.0 (Professional)
## Date: 2025
## Author: Refactored by Professional MQL4 Developer

---

## FUNCTION MAPPING (Obfuscated → Meaningful Names)

### Core Functions
| Original | New Name | Purpose |
|----------|----------|---------|
| `lizong_10` | `ConvertTimeframeToMinutes` | Converts enum timeframe to minutes |
| `lizong_11` | `GetErrorDescription` | Returns human-readable error message |
| `lizong_21` | `HasOpenPositions` | Checks if positions exist for symbol/level/direction |
| `lizong_22` | `GetAverageOpenPrice` | Calculates weighted average price |
| `lizong_23` | `GetWeightedTPPrice` | Calculates weighted take-profit price |
| `lizong_24` | `GetTotalLotSize` | Sums lot sizes for symbol/direction |
| `lizong_25` | `UpdateBuyOrders` | Manages buy order TP/SL updates |
| `lizong_26` | `UpdateSellOrders` | Manages sell order TP/SL updates |
| `lizong_27` | `InitializeSignalDatabase` | Loads hardcoded signal patterns |
| `lizong_28` | `CheckSignalPattern` | Validates trading signal against patterns |
| `lizong_29` | `CheckDrawdownLimits` | Monitors max drawdown violations |
| `lizong_30` | `ValidateOrderModification` | Checks if order modification is valid |
| `lizong_31` | `CreateTextLabel` | Creates chart text label |
| `lizong_32` | `AnalyzeMarketConditions` | Main market analysis per symbol |
| `lizong_33` | `ExecuteInitialTrades` | Opens initial grid positions |
| `lizong_34` | `CalculateInitialLotSize` | Computes initial position size |
| `lizong_35` | `ManageOpenPositions` | Main position management routine |
| `lizong_36` | `CalculateGridLotSize` | Computes lot size for grid levels |
| `lizong_37` | `ManageGridExpansion` | Opens additional grid levels |
| `lizong_38` | `UpdateBuyOrderTPSL` | Updates buy order take-profit/stop-loss |
| `lizong_39` | `UpdateSellOrderTPSL` | Updates sell order take-profit/stop-loss |
| `lizong_40` | `CalculateTakeProfit` | Computes take-profit price |
| `lizong_41` | `CalculateStopLoss` | Computes stop-loss price |
| `lizong_42` | `OpenBuyGridOrder` | Opens averaging buy order |
| `lizong_43` | `OpenSellGridOrder` | Opens averaging sell order |
| `lizong_44` | `TryCloseBuyOrder` | Attempts to close buy position |
| `lizong_45` | `TryCloseSellOrder` | Attempts to close sell position |
| `lizong_46` | `InitializeGUIPanel` | Creates trading panel interface |
| `lizong_47` | `ExecuteManualTrade` | Manual trade execution from GUI |
| `lizong_48` | `HandleButtonClick` | GUI button event handler |
| `lizong_49` | `UpdateGUIPanel` | Refreshes panel display |
| `lizong_50` | `CreateButton` | Creates GUI button object |

---

## GLOBAL VARIABLE MAPPING

### State Management
| Original | New Name | Type | Purpose |
|----------|----------|------|---------|
| `Global_1_st` | `g_LogoResourcePath` | string | Path to EA logo |
| `Global_2_st` | `g_Version` | string | EA version |
| `Global_3_lo` | `g_AccountNumber` | long | Account login |
| `Global_4_st` | `g_AccountName` | string | Account holder name |
| `Global_5_in` | `g_TickCounter` | int | Tick counter for logic |
| `Global_7_da` | `g_LastProcessTime` | datetime | Last processing timestamp |
| `Global_10_a_167` | `g_GUICanvas` | CCanvasX | GUI canvas object |
| `Global_11_bo` | `g_UseSignalDatabase` | bool | Enable signal pattern filter |
| `Global_12_in` | `g_SignalDatabaseSize` | int | Number of signal patterns |
| `Global_13_bo` | `g_UseTradeHistory` | bool | Track trade history |
| `Global_14_in` | `g_MaxHistorySize` | int | Max history records |
| `Global_15_a_169_ko[]` | `g_TradeHistory[]` | CutTrade[] | Trade history array |
| `Global_16_in` | `g_HistoryIndex` | int | Current history index |
| `Global_17_lo_ko[]` | `g_SignalPatterns[]` | long[] | Signal pattern IDs |
| `Global_18_do_ko[]` | `g_SignalPrices[]` | double[] | Signal price levels |
| `Global_19_in` | `g_SignalIndex` | int | Current signal index |
| `Global_20_in` | `g_UnusedVariable` | int | Appears unused |
| `Global_21_in` | `g_BasePeriodMinutes` | int | Base timeframe (M15) |
| `Global_22_a_168_ko[]` | `g_SymbolData[]` | SymbolInfo[] | Per-symbol data array |
| `Global_23_sh` | `g_CommaSeparator` | ushort | Comma character |
| `Global_24_in` | `g_MagicNumberBase` | int | Base magic number (84570) |
| `Global_25_do` | `g_ZeroThreshold` | double | Epsilon for comparisons |
| `Global_26_in` | `g_LastUpdateMinute` | int | Last GUI update minute |
| `Global_27_lo` | `g_LastTimerUpdate` | long | Last timer update |
| `Global_28_in` | `g_CurrentHour` | int | Current broker hour |
| `Global_29_bo` | `g_ForceCloseMode` | bool | Emergency close flag |
| `Global_30_in` | `g_TradingBlockedHours` | int | Hours blocked after DD |
| `Global_31_bo` | `g_PermanentBlock` | bool | Permanent trading block |
| `Global_32_in` | `g_PreviousHour` | int | Previous hour tracker |
| `Global_33_lo` | `g_LastWarningTime` | long | Last warning timestamp |
| `Global_34_lo` | `g_LastMarginWarning` | long | Last margin warning |
| `Global_35_bo` | `g_SymbolError` | bool | Symbol initialization error |
| `Global_36_st` | `g_SelectedSymbol` | string | GUI selected symbol |
| `Global_37_bo` | `g_AllowNewGrids` | bool | Allow new grids flag |
| `Global_38_do` | `g_InitialBalance` | double | Initial balance snapshot |
| `Global_39_bo` | `g_UseGridSizeOptimization` | bool | Optimize grid sizing |
| `Global_40_in` | `g_UnusedCounter` | int | Appears unused |

---

## CLASS STRUCTURE IMPROVEMENTS

### Original SymbolInformation Class
```mql4
class SymbolInformation {
public:
    string  st_1;          // Symbol name
    datetime da_2;         // Last tick time
    datetime da_3;         // Last OPO check time
    int    in_4;          // Tick counter
    bool   bo_5;          // Allow buy signals
    bool   bo_6;          // Allow sell signals
    // ... etc (28 poorly named members)
};
```

### Refactored SymbolData Class
```mql4
class SymbolData {
private:
    // Core identification
    string   m_Symbol;

    // Timing
    datetime m_LastTickTime;
    datetime m_LastOPOCheckTime;
    int      m_TickCounter;

    // Trading permissions
    bool     m_AllowBuySignals;
    bool     m_AllowSellSignals;
    bool     m_AllowNewBuyGrid;
    bool     m_AllowNewSellGrid;
    bool     m_RequireWeeklyReset;

    // Market data cache
    double   m_LastClosePrice;
    double   m_BBRangeSize;
    double   m_SmartDistanceMultiplier;

    // Grid state
    int      m_LastProcessedBar;
    int      m_CurrentGridBar;
    long     m_PatternID;
    double   m_PatternPrice;
    double   m_TotalLotMultiplier;

    // TP/SL tracking
    double   m_CachedBuyAvgPrice;
    double   m_CachedSellAvgPrice;
    double   m_TargetBuyTP;
    double   m_TargetSellTP;

    // Timestamps
    datetime m_LastBuyGridTime;
    datetime m_LastSellGridTime;
    int      m_CurrentDayOfWeek;

public:
    // Constructor/Destructor
    SymbolData();
    ~SymbolData();

    // Initialization
    void Initialize(string symbol);
    void Reset();

    // State management
    void UpdateTickData(datetime time);
    void UpdatePermissions();
    void CacheMarketData();

    // Getters/Setters
    string GetSymbol() const { return m_Symbol; }
    bool CanBuy() const { return m_AllowBuySignals; }
    bool CanSell() const { return m_AllowSellSignals; }
    // ... etc
};
```

---

## CRITICAL BUGS TO FIX

### Bug #1: Type Declaration Error
**Location**: Multiple functions
**Issue**: Integer variables declared as int but suffixed with `_do` (double)
```mql4
// WRONG
int Local_15_do;
int Local_25_do;

// CORRECT
int Local_15_in;
int Local_25_in;
```

### Bug #2: Infinite Loop
**Location**: OnInit(), lizong_36()
**Issue**: Loop iterator never changes
```mql4
// WRONG
for (tmp_in_7=MaximumTrades - 1; tmp_in_6 <= tmp_in_7; tmp_in_7=MaximumTrades - 1)

// CORRECT
for (int i = 1; i <= MaximumTrades - 1; i++)
```

### Bug #3: OnInit() Always Fails in Testing
**Location**: OnInit() line 483
**Issue**: Anti-debugging check breaks backtesting
```mql4
// WRONG - Always fails because arithmetic check is pointless
if ((Local_2_in + Local_3_in + ... != 45 || ...))
    return(32767);

// CORRECT - Remove entirely or make conditional
#ifdef DEBUG_MODE
if ((Local_2_in + Local_3_in + ... != 45 || ...))
    return(INIT_FAILED);
#endif
```

### Bug #4: Resource Handle Leak
**Location**: CCanvasX_12()
**Issue**: File handle closed multiple times without opening
```mql4
// WRONG
Local_5_in = -1;
if (Local_5_in != -1) FileClose(Local_5_in);  // Never opened!

// CORRECT
// Remove dead code entirely
```

### Bug #5: OrderSelect() Error Handling
**Location**: Multiple locations
**Issue**: Continues after OrderSelect() fails
```mql4
// WRONG
if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
    Print("Error");
    Local_2_bo = true;  // But continues anyway!
}

// CORRECT
if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
    Print("Error: ", GetErrorDescription(GetLastError()));
    continue;  // Skip this iteration
}
```

---

## PERFORMANCE OPTIMIZATIONS

### 1. Cache Indicator Values
**Before**:
```mql4
// Recalculates on every tick
double bb_upper = iBands(...) + iStdDev(...) * 2.0;
```

**After**:
```mql4
// Calculate once per bar
if (Time[0] != m_LastBarTime) {
    m_CachedBBUpper = iBands(...) + iStdDev(...) * 2.0;
    m_LastBarTime = Time[0];
}
```

### 2. Reduce OrderSelect() Calls
**Before**: 3-5 loops through all orders
**After**: Single pass with order info caching

### 3. Optimize String Operations
**Before**:
```mql4
string msg = TradeComment + " " + Para_0_st;  // Concatenation in loop
```

**After**:
```mql4
static string msg;
StringFormat(msg, "%s %s", TradeComment, Para_0_st);
```

---

## RECOMMENDED FEATURES TO ADD

1. **Trade Journal Export** - CSV/JSON export of all trades
2. **Equity Curve Tracking** - Real-time equity monitoring
3. **Multi-Timeframe Confirmation** - Add HTF filter
4. **News Filter Integration** - Avoid trading during news
5. **Telegram Notifications** - Send alerts via Telegram
6. **Adaptive Grid Sizing** - Adjust based on volatility
7. **Correlation Filter** - Avoid correlated pairs simultaneously
8. **Recovery Mode** - Special logic when in drawdown
9. **Trailing Stop** - Move SL to breakeven after X pips
10. **Session-Based Trading** - Trade only specific sessions

---

## REFACTORING STEPS

1. ✅ Create this documentation
2. ⏳ Rename all global variables
3. ⏳ Rename all functions
4. ⏳ Fix all bugs
5. ⏳ Refactor classes
6. ⏳ Add comprehensive comments
7. ⏳ Optimize performance
8. ⏳ Add new features
9. ⏳ Create unit tests
10. ⏳ Final review and testing

---

## TESTING PLAN

### Phase 1: Compile Testing
- Ensure refactored code compiles without errors
- Verify all function signatures match

### Phase 2: Logic Validation
- Compare behavior with original on tick-by-tick data
- Verify magic number generation
- Confirm TP/SL calculations

### Phase 3: Backtest Comparison
- Run identical backtests on both versions
- Compare results (should be identical)

### Phase 4: Live Testing
- Demo account testing for 2 weeks minimum
- Monitor for memory leaks, crashes
- Verify all features work correctly

---

## NOTES

- Original code appears to be decompiled/obfuscated
- Signal database (lizong_27) contains 600+ hardcoded patterns - likely proprietary
- Some features (CutTrade) appear incomplete/unused
- Code suggests commercial product with anti-reverse-engineering measures

