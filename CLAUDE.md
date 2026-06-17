# CLAUDE.md — Jmalhem Forex Expert Advisors

## Project Overview

This repository contains two professional-grade automated trading Expert Advisors (EAs) for the MetaTrader 4 (MT4) platform, written in MQL4. Both EAs are purpose-built for the **GBP/USD** currency pair.

| File | EA Name | Style | Timeframe | Frequency |
|------|---------|-------|-----------|-----------|
| `GBPUSD_DayTrader_Pro.mq4` | GBP/USD Day Trader Pro v3.00 | Day Trading | H1 | 1–3 trades/day |
| `GBPUSD_Scalper_Pro.mq4` | GBP/USD Scalper Pro v2.00 | Scalping | M1 | up to 30 trades/day |

---

## Repository Structure

```
Jmalhem/
├── GBPUSD_DayTrader_Pro.mq4    # Day trading EA (~1,752 lines)
├── GBPUSD_Scalper_Pro.mq4      # Scalping EA (~1,741 lines)
└── CLAUDE.md                   # This file
```

No build system, package manager, or CI/CD pipeline exists. MQL4 files are compiled directly by the MetaTrader 4 platform when loaded.

---

## Language and Platform

- **Language**: MQL4 (MetaQuotes Language 4) — proprietary C-like language for MT4
- **Platform**: MetaTrader 4
- **No external dependencies** — only built-in MQL4 standard library functions are used
- **Compilation**: Automatic when MT4 loads the EA; no manual compile step required
- **Deployment**: Copy `.mq4` file to `<MT4 install>/MQL4/Experts/`, then attach to a chart

---

## Code Structure (both files follow the same pattern)

Each EA file is organized into these top-to-bottom sections:

1. **File header** — copyright, version, description, `#property strict`
2. **Input parameters** — `~99` configurable parameters grouped by category with comment headers
3. **Global variables** — `~170` runtime tracking variables (P&L, win rates, drawdown, timers, etc.)
4. **Event handlers** — `OnInit()`, `OnDeinit()`, `OnTick()`, `OnTimer()`
5. **Core strategy functions** — entry logic per strategy type
6. **Indicator analysis** — EMA, RSI, Stochastic, Bollinger Bands, ATR calculations
7. **Position management** — stop loss, take profit, trailing, partial close logic
8. **Dashboard rendering** — real-time on-chart display via `ObjectCreate` / `ObjectSetText`
9. **Utility / helper functions** — validation, resets, logging

---

## Naming Conventions

| Category | Convention | Example |
|----------|-----------|---------|
| Global variables | `PascalCase` | `LastBarTime`, `DailyPnL`, `MaxEquity` |
| Functions | `PascalCase` | `OnInit()`, `ValidateSettings()`, `UpdateDashboard()` |
| Constants / Magic numbers | Named `input int` | `MagicNumberDayTrade = 888888` |
| Input parameters | Descriptive, grouped | `LondonStartHour`, `DayTradingTimeframe` |
| Section headers | Box-comment separators | `//+--- Section ---+` |

- Do **not** use Hungarian notation prefixes.
- Keep function names verb-noun (e.g. `CalculateATR`, `ManagePositions`, `DrawDashboard`).

---

## Trading Strategies

Both EAs implement five complementary strategies that can be individually enabled/disabled:

1. **Price Action** — candlestick pattern detection and key level reactions
2. **Breakout** — range breakouts with volatility confirmation
3. **Range** — mean-reversion within identified ranges
4. **Momentum** — trend-following with RSI/Stochastic confirmation
5. **Order Flow** — bias detection from recent price movement patterns

---

## Advanced Features (both EAs)

### 1. Multi-Timeframe Trend Filter
Requires higher-timeframe trend alignment before entry.
- Day Trader: H1/H4/D1 alignment
- Scalper: M15/H1/H4 alignment

### 2. Dynamic SL/TP Based on ATR Volatility
Adapts stop and target levels to current market volatility.
- Day Trader SL range: 25–60 pips; Scalper SL range: 6–15 pips
- Uses 1.5–3.0× ATR multipliers

### 3. Partial Profit Taking
- Closes 50% of position at first target (1.5× SL distance)
- Remaining 50% runs with trailing stop

### 4. Currency Strength Filter
Calculates relative GBP vs USD strength using GBP/USD and GBP/JPY to filter false signals.

### 5. Time-Based Trading Optimization
- Tracks win rate per hour across all 24 hours
- Labels hours: `OPTIMAL` (≥55% win rate) / `AVERAGE` / `POOR` / `LEARNING`
- Automatically increases lot size during best-performing hours
- Applies 1.3× lot multiplier during London/NY overlap

---

## Risk Management Parameters

| Parameter | Day Trader | Scalper |
|-----------|-----------|---------|
| Risk per trade | 1.0% | 0.5% |
| Max concurrent positions | 2 | 1 |
| Max trades/day | 3 | 30 |
| Max trades/hour | 2 | 5 |
| Max daily loss | 4% | 3% |
| Daily profit target | 8% | 5% |
| Max spread allowed | 3.0 pts | 2.0 pts |

---

## Technical Indicators Used

All indicators are MT4 built-in functions:

- `iMA()` — Exponential Moving Average (trend direction)
- `iRSI()` — Relative Strength Index (momentum)
- `iStochastic()` — Stochastic oscillator (momentum)
- `iBands()` — Bollinger Bands (volatility, S/R)
- `iATR()` — Average True Range (volatility measurement)

---

## Dashboard

Both EAs render a real-time on-chart dashboard using `ObjectCreate` / `ObjectSetText`. It displays:

- Current session, condition, and signal (BUY / SELL / NEUTRAL)
- Spread, ATR, and volatility
- Account: balance, equity, drawdown, daily P&L
- Trade stats: count, win rate, profit factor, pips
- Advanced feature status: MTF alignment, currency strength, hour quality, partial profit stats

**Color coding**: Lime = profit/bullish, Red = loss/bearish, Yellow = neutral, Gray = disabled.

---

## Development Workflow

### Making changes to an EA

1. Edit the `.mq4` file directly — there is no separate build step.
2. Open the file in MetaEditor (bundled with MT4) or any text editor.
3. MT4 will recompile on next load or when you press F7 in MetaEditor.
4. Test using MT4's built-in Strategy Tester (backtesting engine) before live use.

### Adding a new input parameter

- Add an `input <type> ParameterName = defaultValue; // category comment` line in the appropriate section.
- Keep parameters grouped under their category header comment.
- Update the `OnInit()` validation function if the parameter has constraints.

### Adding a new function

- Place it in the appropriate section (strategy, indicator, position management, etc.).
- Use the existing section-header comment style.
- Keep functions focused — one responsibility per function.

### Modifying risk logic

- All risk constants are exposed as `input` parameters; prefer changing defaults there.
- Hard limits (e.g. max trades/day) should be validated in `ValidateSettings()` and `OnTick()` guard clauses.

---

## What NOT to do

- Do not add external `#include` dependencies without confirming the library exists in the target MT4 installation.
- Do not change the `#property strict` pragma — it enforces type safety.
- Do not rename `OnInit`, `OnDeinit`, `OnTick`, or `OnTimer` — these are MT4 lifecycle hooks.
- Do not introduce `Sleep()` calls in `OnTick()` — it blocks the entire platform.
- Do not remove dashboard cleanup from `OnDeinit()` — orphaned chart objects persist across EA reloads.

---

## Testing

There is no automated test suite. Testing is done in MetaTrader 4:

1. **Strategy Tester** (backtesting): Tools → Strategy Tester, select the EA, date range, and symbol.
2. **Visual mode**: Watch the EA execute on historical data bar-by-bar.
3. **Optimization**: MT4 Strategy Tester can sweep input parameters.

When adding or modifying strategy logic, verify via backtest before committing.

---

## Commit Conventions

Commit messages in this repository follow this format:

```
<verb>: <short description>

<optional detail paragraph>
```

Common verbs: `Add`, `Fix`, `Update`, `Convert`, `Remove`, `Refactor`.

Examples from history:
- `Fix: 7 MQL4 compilation warnings (Hour() → TimeHour())`
- `Add: 4 advanced profitability features (multi-timeframe, dynamic SL/TP, partial profits, currency strength)`
- `Convert: Scalping EA → Day Trading EA`

---

## Key File Locations (when deployed in MT4)

| Purpose | Path |
|---------|------|
| EA source files | `<MT4>/MQL4/Experts/` |
| Compiled `.ex4` files | `<MT4>/MQL4/Experts/` (auto-generated) |
| Logs | `<MT4>/logs/` |
| Backtest reports | `<MT4>/tester/` |
