#!/usr/bin/env python3
"""
Oil EA Backtester  —  Pure Python stdlib, no dependencies
Backtests:
  1. Brent Oil Trader Pro v4.00  (H1 swing EA)
  2. Oil Scalper Pro v1.00       (M5 scalping EA)

Price data: Synthetic OHLCV via GBM + volatility clustering,
calibrated to real Brent crude historical parameters.
"""

import math, random, statistics, csv, os
from datetime import datetime, timedelta
from collections import defaultdict

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
SEED             = 42
START_PRICE      = 82.50      # USD — approximate 2023 Brent level
ANNUAL_VOL       = 0.285      # ~28.5% annualized (historical Brent)
ANNUAL_DRIFT     = 0.025      # slight positive drift
TRADING_DAYS     = 504        # 2 full years
HOURS_PER_DAY    = 10         # 07:00–17:00 GMT
INITIAL_BALANCE  = 10_000.0   # USD
TICK_SIZE        = 0.01
TICK_VALUE_STD   = 1.0        # $/pip per lot (100-barrel standard lot)
SPREAD_POINTS    = 3          # typical Brent ECN spread in broker points
SLIPPAGE_POINTS  = 1

# Swing EA params
SW_RISK_PCT       = 1.0
SW_MAX_LOT        = 5.0
SW_MIN_LOT        = 0.01
SW_ATR_SL         = 1.8
SW_ATR_TP1        = 1.5
SW_ATR_TP2        = 3.0
SW_PARTIAL_PCT    = 50.0
SW_TRAIL_MULT     = 1.0
SW_TRAIL_ACT_MULT = 1.5
SW_MAX_TRADES_DAY = 6
SW_MAX_DD_PCT     = 15.0
SW_DAILY_LOSS_PCT = 3.0
SW_DAILY_PROF_PCT = 5.0
# EMA periods
SW_EMA_FAST  = 8
SW_EMA_MED   = 21
SW_EMA_SLOW  = 50
SW_EMA_TREND = 200
# RSI
SW_RSI_PER  = 14
SW_RSI_OB   = 70.0
SW_RSI_OS   = 30.0
SW_RSI_BULL = 45.0
SW_RSI_BEAR = 55.0
# MACD
SW_MACD_F = 12; SW_MACD_S = 26; SW_MACD_SIG = 9
# Stoch
SW_STOCH_K = 5; SW_STOCH_D = 3; SW_STOCH_SL = 3
SW_STOCH_OB = 80.0; SW_STOCH_OS = 20.0
# BB
SW_BB_PER = 20; SW_BB_DEV = 2.0
# ATR
SW_ATR_PER = 14
SW_ATR_MIN_MULT = 0.3
SW_ATR_MAX_MULT = 3.5

# Scalper EA params
SC_RISK_PCT       = 0.5
SC_MAX_LOT        = 3.0
SC_MIN_LOT        = 0.01
SC_ATR_SL         = 0.9
SC_ATR_TP1        = 0.8
SC_ATR_TP2        = 1.6
SC_PARTIAL_PCT    = 60.0
SC_TRAIL_MULT     = 0.5
SC_TRAIL_ACT_MULT = 0.7
SC_MAX_TRADES_DAY = 25
SC_MAX_TRADES_HR  = 5
SC_MAX_DD_PCT     = 10.0
SC_DAILY_LOSS_PCT = 2.0
SC_DAILY_PROF_PCT = 4.0
SC_MAX_SPREAD     = 20.0
SC_MIN_BARS_SINCE = 2
# EMA
SC_EMA_FAST  = 3; SC_EMA_MID = 8; SC_EMA_SLOW = 21; SC_EMA_TREND = 50
# RSI
SC_RSI_PER = 7; SC_RSI_OB = 75.0; SC_RSI_OS = 25.0
SC_RSI_BULL = 52.0; SC_RSI_BEAR = 48.0
# MACD
SC_MACD_F = 5; SC_MACD_S = 13; SC_MACD_SIG = 3
# Stoch
SC_STOCH_K = 5; SC_STOCH_D = 3; SC_STOCH_SL = 3
SC_STOCH_OB = 80.0; SC_STOCH_OS = 20.0
SC_STOCH_MOB = 65.0; SC_STOCH_MOS = 35.0
# BB
SC_BB_PER = 20; SC_BB_DEV = 2.0; SC_BB_TOUCH = 0.15
# ATR
SC_ATR_PER = 7
SC_ATR_MIN_MULT = 0.4
SC_ATR_MAX_MULT = 2.8

# ─────────────────────────────────────────────────────────────────────────────
# INDICATOR ENGINE
# ─────────────────────────────────────────────────────────────────────────────

def ema(values, period):
    result = [None] * len(values)
    valid = [(i, v) for i, v in enumerate(values) if v is not None]
    if len(valid) < period:
        return result
    # find first index where we have 'period' consecutive valid values
    k = 2.0 / (period + 1)
    # seed from first run of valids
    first_idx = valid[0][0]
    seed_end = first_idx + period
    if seed_end > len(values):
        return result
    seed_vals = [values[i] for i in range(first_idx, seed_end)
                 if values[i] is not None]
    if len(seed_vals) < period:
        return result
    result[seed_end - 1] = sum(seed_vals) / period
    for i in range(seed_end, len(values)):
        if values[i] is not None and result[i-1] is not None:
            result[i] = values[i] * k + result[i-1] * (1 - k)
    return result

def atr(highs, lows, closes, period):
    n = len(closes)
    tr = [None] * n
    for i in range(1, n):
        h, l, pc = highs[i], lows[i], closes[i-1]
        tr[i] = max(h - l, abs(h - pc), abs(l - pc))
    result = [None] * n
    # seed
    seed_vals = [tr[i] for i in range(1, period+1) if tr[i] is not None]
    if len(seed_vals) < period:
        return result
    result[period] = sum(seed_vals) / period
    for i in range(period + 1, n):
        if tr[i] is not None and result[i-1] is not None:
            result[i] = (result[i-1] * (period - 1) + tr[i]) / period
    return result

def rsi(closes, period):
    n = len(closes)
    result = [None] * n
    if n < period + 1:
        return result
    gains, losses = [], []
    for i in range(1, period + 1):
        d = closes[i] - closes[i-1]
        gains.append(max(d, 0.0))
        losses.append(max(-d, 0.0))
    avg_g = sum(gains) / period
    avg_l = sum(losses) / period
    result[period] = 100 - (100 / (1 + avg_g / avg_l)) if avg_l > 0 else 100.0
    for i in range(period + 1, n):
        d = closes[i] - closes[i-1]
        avg_g = (avg_g * (period - 1) + max(d, 0.0)) / period
        avg_l = (avg_l * (period - 1) + max(-d, 0.0)) / period
        result[i] = 100 - (100 / (1 + avg_g / avg_l)) if avg_l > 0 else 100.0
    return result

def macd(closes, fast, slow, sig_period):
    ef = ema(closes, fast)
    es = ema(closes, slow)
    line = [ef[i] - es[i] if ef[i] is not None and es[i] is not None else None
            for i in range(len(closes))]
    sig_line = ema(line, sig_period)
    hist = [line[i] - sig_line[i]
            if line[i] is not None and sig_line[i] is not None else None
            for i in range(len(closes))]
    return line, sig_line, hist

def stochastic(highs, lows, closes, k_per, d_per, slowing):
    n = len(closes)
    raw_k = [None] * n
    for i in range(k_per - 1, n):
        lo = min(lows[i-k_per+1:i+1])
        hi = max(highs[i-k_per+1:i+1])
        raw_k[i] = 100.0 * (closes[i] - lo) / (hi - lo) if hi != lo else 50.0
    # Slow %K = slowing-period SMA of raw_k
    sk = [None] * n
    for i in range(k_per + slowing - 2, n):
        vals = [raw_k[j] for j in range(i-slowing+1, i+1) if raw_k[j] is not None]
        if len(vals) == slowing:
            sk[i] = sum(vals) / slowing
    # %D = d-period SMA of slow %K
    sd = [None] * n
    for i in range(d_per - 1, n):
        vals = [sk[j] for j in range(i-d_per+1, i+1) if sk[j] is not None]
        if len(vals) == d_per:
            sd[i] = sum(vals) / d_per
    return sk, sd

def bollinger(closes, period, dev):
    n = len(closes)
    upper = [None]*n; lower = [None]*n; mid = [None]*n
    for i in range(period - 1, n):
        w = closes[i-period+1:i+1]
        m = sum(w) / period
        sd = math.sqrt(sum((x-m)**2 for x in w) / period)
        mid[i] = m; upper[i] = m + dev*sd; lower[i] = m - dev*sd
    return upper, lower, mid

def rolling_avg(values, period):
    """Simple rolling average ignoring Nones."""
    result = [None] * len(values)
    for i in range(period - 1, len(values)):
        w = [values[j] for j in range(i-period+1, i+1) if values[j] is not None]
        if len(w) == period:
            result[i] = sum(w) / period
    return result

# ─────────────────────────────────────────────────────────────────────────────
# PRICE DATA GENERATOR
# ─────────────────────────────────────────────────────────────────────────────

class Bar:
    __slots__ = ('dt','open','high','low','close','volume')
    def __init__(self, dt, o, h, l, c, v):
        self.dt=dt; self.open=o; self.high=h; self.low=l; self.close=c; self.volume=v

def generate_bars(freq_minutes):
    """
    Generate OHLCV bars using GBM with volatility clustering (GARCH-like).
    freq_minutes: 5 for M5, 60 for H1.
    """
    rng = random.Random(SEED)
    bars_per_day = HOURS_PER_DAY * 60 // freq_minutes
    total_bars   = TRADING_DAYS * bars_per_day

    # per-bar parameters
    bars_per_year = 250 * bars_per_day
    bar_vol  = ANNUAL_VOL   / math.sqrt(bars_per_year)
    bar_drift = ANNUAL_DRIFT / bars_per_year

    price  = START_PRICE
    bars   = []
    vol    = bar_vol  # current volatility (GARCH state)
    vol_avg = bar_vol

    # Build trading calendar: skip weekends, build dates
    start_dt = datetime(2023, 1, 2, 7, 0)  # Monday 07:00 GMT
    cur_dt   = start_dt
    bar_count = 0

    while bar_count < total_bars:
        # Skip Saturday/Sunday
        if cur_dt.weekday() >= 5:
            cur_dt += timedelta(minutes=freq_minutes)
            continue
        # Skip outside 07:00–17:00
        if cur_dt.hour < 7 or cur_dt.hour >= 17:
            cur_dt += timedelta(minutes=freq_minutes)
            continue

        # GARCH-like vol update
        shock_mag = abs(rng.gauss(0, 1))
        vol = 0.85 * vol + 0.10 * vol_avg * shock_mag + 0.05 * vol_avg

        # Generate intra-bar moves
        sub_steps = max(1, freq_minutes)
        o = price
        cur = price
        hi  = price
        lo  = price
        for _ in range(sub_steps):
            ret  = bar_drift / sub_steps + vol / math.sqrt(sub_steps) * rng.gauss(0, 1)
            cur *= math.exp(ret)
            hi   = max(hi, cur)
            lo   = min(lo, cur)
        c = cur
        v = int(rng.uniform(500, 2000) * (vol / vol_avg))

        bars.append(Bar(cur_dt, round(o,2), round(hi,2), round(lo,2), round(c,2), v))
        price = c
        bar_count += 1
        cur_dt += timedelta(minutes=freq_minutes)

    return bars

def resample_to_higher(m5_bars, factor):
    """Resample M5 bars into higher TF (e.g. factor=6 → M30, factor=12 → H1)."""
    out = []
    i = 0
    while i + factor <= len(m5_bars):
        chunk = m5_bars[i:i+factor]
        o = chunk[0].open
        h = max(b.high  for b in chunk)
        l = min(b.low   for b in chunk)
        c = chunk[-1].close
        v = sum(b.volume for b in chunk)
        out.append(Bar(chunk[0].dt, o, h, l, c, v))
        i += factor
    return out

# ─────────────────────────────────────────────────────────────────────────────
# SESSION / NEWS HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def gmt_hour(dt):
    return dt.hour  # data is generated in GMT

def is_session(dt, ea='swing'):
    dow  = dt.weekday()  # 0=Mon,4=Fri,5=Sat,6=Sun
    gmth = gmt_hour(dt)
    if dow >= 5: return False              # weekend
    if dow == 0 and gmth < 5: return False # Monday gap
    if dow == 4 and gmth >= 17: return False # Friday close
    # London open 07-09, London core 09-13, NY overlap 13-17
    if 7  <= gmth < 9:  return True
    if 9  <= gmth < 13: return True
    if 13 <= gmth < 17: return True
    return False

def is_news(dt):
    dow  = dt.weekday()  # 0=Mon
    gmth = gmt_hour(dt)
    totm = gmth * 60 + dt.minute
    buf  = 30
    # EIA Wednesday 14:30
    if dow == 2:
        t = 14*60+30
        if t-buf <= totm <= t+buf: return True
        t2 = 19*60
        if t2-buf <= totm <= t2+buf: return True  # FOMC Wed
    # API Tuesday 20:30
    if dow == 1 and 20*60+30 - buf <= totm <= 20*60+30 + buf: return True
    # NFP Friday 13:30
    if dow == 4 and 13*60+30 <= totm <= 14*60+30: return True
    return False

# ─────────────────────────────────────────────────────────────────────────────
# POSITION TRACKER
# ─────────────────────────────────────────────────────────────────────────────

class Position:
    _id = 0
    def __init__(self, direction, entry, sl, tp1, tp2, lots, open_dt):
        Position._id += 1
        self.id       = Position._id
        self.dir      = direction   # 1=buy, -1=sell
        self.entry    = entry
        self.sl       = sl
        self.tp1      = tp1
        self.tp2      = tp2
        self.lots     = lots
        self.orig_lots = lots
        self.open_dt  = open_dt
        self.close_dt = None
        self.close_px = None
        self.pnl      = 0.0
        self.partial_done = False
        self.be_done      = False
        self.status   = 'open'   # 'open','closed'

    def current_profit_pts(self, price):
        return (price - self.entry) * self.dir

    def close(self, price, dt, reason=''):
        self.close_px = price
        self.close_dt = dt
        self.status   = 'closed'
        # PnL in USD: (price_diff / tick_size) * tick_value * lots
        diff = (price - self.entry) * self.dir
        self.pnl = (diff / TICK_SIZE) * TICK_VALUE_STD * self.lots
        return self.pnl

# ─────────────────────────────────────────────────────────────────────────────
# BACKTEST ENGINE  (generic — used by both EAs)
# ─────────────────────────────────────────────────────────────────────────────

class BacktestResult:
    def __init__(self, name):
        self.name    = name
        self.trades  = []         # closed Position objects
        self.equity_curve = []    # (datetime, equity)
        self.balance  = INITIAL_BALANCE
        self.equity   = INITIAL_BALANCE
        self.peak_eq  = INITIAL_BALANCE
        self.max_dd   = 0.0
        self.day_stats = {}       # date -> {pnl, trades}

# ─────────────────────────────────────────────────────────────────────────────
# SWING EA BACKTEST  (H1)
# ─────────────────────────────────────────────────────────────────────────────

def backtest_swing(h1_bars, h4_bars):
    """
    Simulate Brent Oil Trader Pro on H1.
    Uses H1 for entry signals, H4 for trend bias.
    Strategies: EMA crossover, MACD momentum, BB breakout, pullback.
    """
    # Pre-compute H1 indicators
    closes = [b.close for b in h1_bars]
    highs  = [b.high  for b in h1_bars]
    lows   = [b.low   for b in h1_bars]

    ema_f   = ema(closes, SW_EMA_FAST)
    ema_m   = ema(closes, SW_EMA_MED)
    ema_s   = ema(closes, SW_EMA_SLOW)
    ema_t   = ema(closes, SW_EMA_TREND)
    atr_v   = atr(highs, lows, closes, SW_ATR_PER)
    rsi_v   = rsi(closes, SW_RSI_PER)
    _, _, macd_h = macd(closes, SW_MACD_F, SW_MACD_S, SW_MACD_SIG)
    stoch_k, stoch_d_v = stochastic(highs, lows, closes, SW_STOCH_K, SW_STOCH_D, SW_STOCH_SL)
    bb_up, bb_lo, bb_mid = bollinger(closes, SW_BB_PER, SW_BB_DEV)

    # ATR average (50-bar)
    atr_avg = rolling_avg(atr_v, 50)

    # H4: trend bias — just use EMA_FAST and EMA_TREND on H4
    closes4 = [b.close for b in h4_bars]
    highs4  = [b.high  for b in h4_bars]
    lows4   = [b.low   for b in h4_bars]
    ema_f4  = ema(closes4, SW_EMA_FAST)
    ema_t4  = ema(closes4, SW_EMA_TREND)

    # Build H4 lookup by H1 index (nearest H4 bar that has closed)
    h4_by_dt = {}
    for b4 in h4_bars:
        h4_by_dt[b4.dt] = b4
    h4_times = sorted(h4_by_dt.keys())

    def get_h4_idx_for(dt):
        # find the most recent H4 bar that started <= dt
        lo, hi_ = 0, len(h4_times) - 1
        res = 0
        while lo <= hi_:
            mid_ = (lo + hi_) // 2
            if h4_times[mid_] <= dt:
                res = mid_; lo = mid_ + 1
            else:
                hi_ = mid_ - 1
        return res

    res = BacktestResult("Brent Oil Trader Pro v4.00 (H1 Swing)")
    balance  = INITIAL_BALANCE
    peak_eq  = INITIAL_BALANCE
    max_dd   = 0.0
    open_pos = []   # list of Position
    trades   = []
    equity_curve = []

    day_balance  = INITIAL_BALANCE
    day_equity   = INITIAL_BALANCE
    day_trades   = 0
    cur_day      = None
    daily_halted = False
    dd_halted    = False

    WARMUP = max(SW_EMA_TREND, SW_BB_PER, SW_ATR_PER * 4)

    for i in range(WARMUP, len(h1_bars)):
        bar = h1_bars[i]
        dt  = bar.dt

        # ── Daily reset ──
        d = dt.date()
        if d != cur_day:
            cur_day     = d
            day_balance = balance
            day_equity  = balance + sum(
                p.current_profit_pts(bar.close) * (1/TICK_SIZE) * TICK_VALUE_STD * p.lots
                for p in open_pos)
            day_trades  = 0
            daily_halted = False

        # ── Manage open positions ──
        equity = balance
        for pos in list(open_pos):
            bid = bar.close - SPREAD_POINTS * TICK_SIZE / 2
            ask = bar.close + SPREAD_POINTS * TICK_SIZE / 2
            cur_px = bid if pos.dir == 1 else ask

            # Check SL hit
            if pos.dir == 1 and bar.low <= pos.sl:
                pnl = pos.close(pos.sl - SLIPPAGE_POINTS*TICK_SIZE, dt, 'SL')
                balance += pnl; open_pos.remove(pos); trades.append(pos); continue
            if pos.dir == -1 and bar.high >= pos.sl:
                pnl = pos.close(pos.sl + SLIPPAGE_POINTS*TICK_SIZE, dt, 'SL')
                balance += pnl; open_pos.remove(pos); trades.append(pos); continue

            # Check TP2 hit
            if pos.dir == 1 and bar.high >= pos.tp2:
                pnl = pos.close(pos.tp2, dt, 'TP2')
                balance += pnl; open_pos.remove(pos); trades.append(pos); continue
            if pos.dir == -1 and bar.low <= pos.tp2:
                pnl = pos.close(pos.tp2, dt, 'TP2')
                balance += pnl; open_pos.remove(pos); trades.append(pos); continue

            # TP1 partial close (50%)
            tp1_hit = (pos.dir == 1 and bar.high >= pos.tp1) or \
                      (pos.dir == -1 and bar.low <= pos.tp1)
            if tp1_hit and not pos.partial_done:
                close_lots = round(pos.lots * SW_PARTIAL_PCT / 100.0, 2)
                if close_lots >= SW_MIN_LOT and close_lots < pos.lots:
                    diff = (pos.tp1 - pos.entry) * pos.dir
                    part_pnl = (diff / TICK_SIZE) * TICK_VALUE_STD * close_lots
                    balance += part_pnl
                    pos.lots -= close_lots
                pos.partial_done = True

            # Break-even
            if tp1_hit and not pos.be_done:
                be = pos.entry + 0.1 * (atr_v[i] or 0) * pos.dir
                if pos.dir == 1 and be > pos.sl:
                    pos.sl = be
                elif pos.dir == -1 and be < pos.sl:
                    pos.sl = be
                pos.be_done = True

            # Trailing stop
            prof = pos.current_profit_pts(cur_px)
            cur_atr = atr_v[i] or 0
            if cur_atr > 0 and prof >= cur_atr * SW_TRAIL_ACT_MULT:
                trail_dist = cur_atr * SW_TRAIL_MULT
                if pos.dir == 1:
                    new_sl = cur_px - trail_dist
                    if new_sl > pos.sl: pos.sl = new_sl
                else:
                    new_sl = cur_px + trail_dist
                    if new_sl < pos.sl: pos.sl = new_sl

            # Unrealised equity contribution
            diff = (cur_px - pos.entry) * pos.dir
            equity += (diff / TICK_SIZE) * TICK_VALUE_STD * pos.lots

        # ── Guards ──
        if equity > peak_eq: peak_eq = equity
        dd = (peak_eq - equity) / peak_eq * 100.0 if peak_eq > 0 else 0
        if dd > max_dd: max_dd = dd
        if dd >= SW_MAX_DD_PCT: dd_halted = True
        if dd < SW_MAX_DD_PCT: dd_halted = False  # auto-reset if recovered

        pnl_day_pct = (equity - day_equity) / day_balance * 100.0 if day_balance > 0 else 0
        if pnl_day_pct <= -SW_DAILY_LOSS_PCT: daily_halted = True
        if pnl_day_pct >= SW_DAILY_PROF_PCT: daily_halted = True

        equity_curve.append((dt, round(equity, 2)))

        # ── Skip entry if halted ──
        if daily_halted or dd_halted: continue
        if day_trades >= SW_MAX_TRADES_DAY: continue
        if len(open_pos) >= 1: continue
        if not is_session(dt): continue
        if is_news(dt): continue

        # ── Indicator availability check ──
        if any(v is None for v in [ema_f[i], ema_m[i], ema_s[i], ema_t[i],
                                    atr_v[i], atr_avg[i], rsi_v[i], macd_h[i],
                                    stoch_k[i], bb_up[i]]):
            continue

        # ── Volatility filter ──
        if atr_v[i] < atr_avg[i] * SW_ATR_MIN_MULT: continue
        if atr_v[i] > atr_avg[i] * SW_ATR_MAX_MULT: continue

        # ── H4 trend bias ──
        h4i = get_h4_idx_for(dt)
        h4_bias = 0
        if h4i > 0 and ema_f4[h4i] is not None and ema_t4[h4i] is not None:
            if closes4[h4i] > ema_t4[h4i] and ema_f4[h4i] > ema_t4[h4i]:
                h4_bias = 1
            elif closes4[h4i] < ema_t4[h4i] and ema_f4[h4i] < ema_t4[h4i]:
                h4_bias = -1

        c1 = closes[i];   c2 = closes[i-1]
        ef1 = ema_f[i];   ef2 = ema_f[i-1]
        em1 = ema_m[i];   em2 = ema_m[i-1]
        es1 = ema_s[i]
        rsi1 = rsi_v[i]
        mh1  = macd_h[i]; mh2 = macd_h[i-1] if i > 1 else 0
        sk1  = stoch_k[i]
        sd1  = stoch_d_v[i]
        bbu  = bb_up[i];  bbl = bb_lo[i]
        bbu2 = bb_up[i-1]; bbl2 = bb_lo[i-1]
        a    = atr_v[i]

        signal = 0

        # Strategy 1: EMA trend follow
        if h4_bias != 0:
            if ef2 <= em2 and ef1 > em1 and h4_bias == 1 and c1 > es1 \
               and SW_RSI_BULL < rsi1 < SW_RSI_OB:
                signal = 1
            elif ef2 >= em2 and ef1 < em1 and h4_bias == -1 and c1 < es1 \
               and SW_RSI_OS < rsi1 < SW_RSI_BEAR:
                signal = -1

        # Strategy 2: MACD momentum
        if signal == 0 and mh2 is not None:
            if mh2 < 0 and mh1 > 0 and rsi1 > 50 and rsi1 < SW_RSI_OB \
               and (not h4_bias or h4_bias == 1):
                signal = 1
            elif mh2 > 0 and mh1 < 0 and rsi1 < 50 and rsi1 > SW_RSI_OS \
               and (not h4_bias or h4_bias == -1):
                signal = -1

        # Strategy 3: BB breakout
        if signal == 0 and bbu2 is not None:
            bb_squeeze = (bbu - bbl) < a * SW_BB_DEV
            if not bb_squeeze:
                if c1 > bbu and c2 <= bbu2 and mh1 > 0 and (not h4_bias or h4_bias == 1):
                    signal = 1
                elif c1 < bbl and c2 >= bbl2 and mh1 < 0 and (not h4_bias or h4_bias == -1):
                    signal = -1

        # Strategy 4: Pullback to EMA
        if signal == 0 and h4_bias != 0:
            near_med = abs(c1 - em1) < a * 0.4
            if h4_bias == 1 and near_med and c1 > es1 and sk1 < 40 and sk1 > sd1 \
               and 40 < rsi1 < 65:
                signal = 1
            elif h4_bias == -1 and near_med and c1 < es1 and sk1 > 60 and sk1 < sd1 \
               and 35 < rsi1 < 60:
                signal = -1

        # Stoch extreme guard
        if signal == 1  and sk1 > SW_STOCH_OB: signal = 0
        if signal == -1 and sk1 < SW_STOCH_OS: signal = 0

        if signal == 0: continue

        # ── Build order ──
        ask_px = bar.close + SPREAD_POINTS * TICK_SIZE / 2
        bid_px = bar.close - SPREAD_POINTS * TICK_SIZE / 2
        entry = ask_px if signal == 1 else bid_px
        sl = entry - a * SW_ATR_SL * signal
        tp1 = entry + a * SW_ATR_TP1 * signal
        tp2 = entry + a * SW_ATR_TP2 * signal

        # Lot sizing
        sl_dist = abs(entry - sl)
        if sl_dist <= 0: continue
        risk_amt = balance * SW_RISK_PCT / 100.0
        sl_val   = (sl_dist / TICK_SIZE) * TICK_VALUE_STD
        raw_lots = risk_amt / sl_val if sl_val > 0 else SW_MIN_LOT
        lots = max(SW_MIN_LOT, min(SW_MAX_LOT, round(raw_lots, 2)))

        pos = Position(signal, entry, sl, tp1, tp2, lots, dt)
        open_pos.append(pos)
        day_trades += 1

    # Close any remaining open positions at last bar close
    last_bar = h1_bars[-1]
    for pos in list(open_pos):
        pnl = pos.close(last_bar.close, last_bar.dt, 'EOT')
        balance += pnl
        trades.append(pos)

    res.trades      = trades
    res.equity_curve = equity_curve
    res.balance     = balance
    res.equity      = balance
    res.peak_eq     = peak_eq
    res.max_dd      = max_dd
    return res

# ─────────────────────────────────────────────────────────────────────────────
# SCALPER EA BACKTEST  (M5)
# ─────────────────────────────────────────────────────────────────────────────

def backtest_scalper(m5_bars, m30_bars):
    """
    Simulate Oil Scalper Pro on M5.
    Strategies: Fast EMA, Momentum, Stoch reversal, BB mean-rev, Breakout.
    """
    closes = [b.close for b in m5_bars]
    highs  = [b.high  for b in m5_bars]
    lows   = [b.low   for b in m5_bars]
    opens  = [b.open  for b in m5_bars]

    ef = ema(closes, SC_EMA_FAST)
    em_ = ema(closes, SC_EMA_MID)
    es = ema(closes, SC_EMA_SLOW)
    et = ema(closes, SC_EMA_TREND)
    atr_v  = atr(highs, lows, closes, SC_ATR_PER)
    atr_avg = rolling_avg(atr_v, 30)
    rsi_v  = rsi(closes, SC_RSI_PER)
    _, _, macd_h_v = macd(closes, SC_MACD_F, SC_MACD_S, SC_MACD_SIG)
    sk, sd_v = stochastic(highs, lows, closes, SC_STOCH_K, SC_STOCH_D, SC_STOCH_SL)
    bb_up, bb_lo, bb_mid = bollinger(closes, SC_BB_PER, SC_BB_DEV)

    # M30 trend bias EMA
    closes30 = [b.close for b in m30_bars]
    highs30  = [b.high  for b in m30_bars]
    lows30   = [b.low   for b in m30_bars]
    et30  = ema(closes30, SC_EMA_TREND)
    ef30  = ema(closes30, SC_EMA_FAST)

    m30_times = [b.dt for b in m30_bars]

    def get_m30_bias(dt):
        # most recent M30 bar <= dt
        lo_, hi_ = 0, len(m30_times)-1; res = 0
        while lo_ <= hi_:
            mid_ = (lo_+hi_)//2
            if m30_times[mid_] <= dt: res=mid_; lo_=mid_+1
            else: hi_=mid_-1
        if et30[res] is None or ef30[res] is None: return 0
        if closes30[res] > et30[res] and ef30[res] > et30[res]: return 1
        if closes30[res] < et30[res] and ef30[res] < et30[res]: return -1
        return 0

    res = BacktestResult("Oil Scalper Pro v1.00 (M5 Scalper)")
    balance   = INITIAL_BALANCE
    peak_eq   = INITIAL_BALANCE
    max_dd    = 0.0
    open_pos  = []
    trades    = []
    equity_curve = []

    day_balance  = INITIAL_BALANCE
    day_equity   = INITIAL_BALANCE
    day_trades   = 0
    cur_day      = None
    daily_halted = False
    dd_halted    = False
    hour_trades  = 0
    cur_hour     = -1
    last_trade_bar = -999

    WARMUP = max(SC_EMA_TREND, SC_BB_PER, SC_ATR_PER * 5)

    for i in range(WARMUP, len(m5_bars)):
        bar = m5_bars[i]
        dt  = bar.dt

        # ── Hourly reset ──
        if dt.hour != cur_hour:
            cur_hour   = dt.hour
            hour_trades = 0

        # ── Daily reset ──
        d = dt.date()
        if d != cur_day:
            cur_day      = d
            day_balance  = balance
            day_equity   = balance
            day_trades   = 0
            hour_trades  = 0
            daily_halted = False

        # ── Manage open positions ──
        equity = balance
        for pos in list(open_pos):
            bid = bar.close - SPREAD_POINTS * TICK_SIZE / 2
            ask = bar.close + SPREAD_POINTS * TICK_SIZE / 2
            cur_px = bid if pos.dir == 1 else ask

            if pos.dir == 1 and bar.low <= pos.sl:
                pnl = pos.close(pos.sl - SLIPPAGE_POINTS*TICK_SIZE, dt, 'SL')
                balance += pnl; open_pos.remove(pos); trades.append(pos); continue
            if pos.dir == -1 and bar.high >= pos.sl:
                pnl = pos.close(pos.sl + SLIPPAGE_POINTS*TICK_SIZE, dt, 'SL')
                balance += pnl; open_pos.remove(pos); trades.append(pos); continue
            if pos.dir == 1 and bar.high >= pos.tp2:
                pnl = pos.close(pos.tp2, dt, 'TP2')
                balance += pnl; open_pos.remove(pos); trades.append(pos); continue
            if pos.dir == -1 and bar.low <= pos.tp2:
                pnl = pos.close(pos.tp2, dt, 'TP2')
                balance += pnl; open_pos.remove(pos); trades.append(pos); continue

            tp1_hit = (pos.dir == 1  and bar.high >= pos.tp1) or \
                      (pos.dir == -1 and bar.low  <= pos.tp1)
            if tp1_hit and not pos.partial_done:
                cl = round(pos.lots * SC_PARTIAL_PCT / 100.0, 2)
                if cl >= SC_MIN_LOT and cl < pos.lots:
                    diff = (pos.tp1 - pos.entry) * pos.dir
                    balance += (diff/TICK_SIZE) * TICK_VALUE_STD * cl
                    pos.lots -= cl
                pos.partial_done = True

            if tp1_hit and not pos.be_done:
                buf = (atr_v[i] or 0) * 0.05
                be = pos.entry + buf * pos.dir
                if pos.dir == 1 and be > pos.sl: pos.sl = be
                if pos.dir == -1 and be < pos.sl: pos.sl = be
                pos.be_done = True

            prof = pos.current_profit_pts(cur_px)
            ca = atr_v[i] or 0
            if ca > 0 and prof >= ca * SC_TRAIL_ACT_MULT:
                tr_dist = ca * SC_TRAIL_MULT
                if pos.dir == 1:
                    nsl = cur_px - tr_dist
                    if nsl > pos.sl: pos.sl = nsl
                else:
                    nsl = cur_px + tr_dist
                    if nsl < pos.sl: pos.sl = nsl

            diff = (cur_px - pos.entry) * pos.dir
            equity += (diff/TICK_SIZE) * TICK_VALUE_STD * pos.lots

        # ── Equity / drawdown tracking ──
        if equity > peak_eq: peak_eq = equity
        dd = (peak_eq - equity) / peak_eq * 100.0 if peak_eq > 0 else 0
        if dd > max_dd: max_dd = dd
        if dd >= SC_MAX_DD_PCT: dd_halted = True
        if dd < SC_MAX_DD_PCT: dd_halted = False

        pnl_day_pct = (equity - day_equity) / day_balance * 100.0 if day_balance > 0 else 0
        if pnl_day_pct <= -SC_DAILY_LOSS_PCT: daily_halted = True
        if pnl_day_pct >= SC_DAILY_PROF_PCT:  daily_halted = True

        equity_curve.append((dt, round(equity, 2)))

        if daily_halted or dd_halted: continue
        if day_trades >= SC_MAX_TRADES_DAY: continue
        if hour_trades >= SC_MAX_TRADES_HR: continue
        if len(open_pos) >= 2: continue
        if not is_session(dt): continue
        if is_news(dt): continue
        if (i - last_trade_bar) < SC_MIN_BARS_SINCE: continue

        # ── Spread check ──
        if SPREAD_POINTS > SC_MAX_SPREAD: continue

        # ── Indicator check ──
        if any(v is None for v in [ef[i], em_[i], es[i], et[i],
                                    atr_v[i], atr_avg[i], rsi_v[i],
                                    macd_h_v[i], sk[i], bb_up[i]]):
            continue
        if atr_v[i] < atr_avg[i] * SC_ATR_MIN_MULT: continue
        if atr_v[i] > atr_avg[i] * SC_ATR_MAX_MULT: continue

        c1 = closes[i]; c2 = closes[i-1] if i > 0 else c1
        o1 = opens[i]
        h1_ = highs[i]; l1 = lows[i]
        h2  = highs[i-1] if i > 0 else h1_
        l2  = lows[i-1]  if i > 0 else l1
        ef1 = ef[i]; ef2 = ef[i-1] if i>0 else ef[i]
        em1 = em_[i]; em2 = em_[i-1] if i>0 else em_[i]
        es1 = es[i]; et1 = et[i]
        rsi1 = rsi_v[i]; rsi2 = rsi_v[i-1] if i>0 else rsi1
        mh1  = macd_h_v[i]; mh2 = macd_h_v[i-1] if i>0 else mh1
        sk1  = sk[i]; sk2 = sk[i-1] if i>0 else sk1; sd1 = sd_v[i]
        bbu  = bb_up[i]; bbl = bb_lo[i]
        a    = atr_v[i]

        trend_bias = get_m30_bias(dt)
        signal = 0

        # Strat 1: Fast EMA cross
        if ef2 <= em2 and ef1 > em1 and c1 > es1 \
           and SC_RSI_BULL < rsi1 < SC_RSI_OB \
           and (not trend_bias or trend_bias == 1):
            signal = 1
        elif ef2 >= em2 and ef1 < em1 and c1 < es1 \
           and SC_RSI_OS < rsi1 < SC_RSI_BEAR \
           and (not trend_bias or trend_bias == -1):
            signal = -1

        # Strat 2: RSI 50 cross + MACD flip
        if signal == 0 and mh2 is not None:
            if rsi2 < 50 and rsi1 >= 50 and rsi1 < SC_RSI_OB \
               and mh2 < 0 and mh1 > 0 and c1 > es1 \
               and (not trend_bias or trend_bias == 1):
                signal = 1
            elif rsi2 > 50 and rsi1 <= 50 and rsi1 > SC_RSI_OS \
               and mh2 > 0 and mh1 < 0 and c1 < es1 \
               and (not trend_bias or trend_bias == -1):
                signal = -1

        # Strat 3: Stochastic reversal
        if signal == 0:
            if sk2 < SC_STOCH_OS and sk1 >= SC_STOCH_OS and sk1 > sd1 \
               and rsi1 > SC_RSI_OS and (mh1 or 0) > (mh2 or 0):
                signal = 1
            elif sk2 > SC_STOCH_OB and sk1 <= SC_STOCH_OB and sk1 < sd1 \
               and rsi1 < SC_RSI_OB and (mh1 or 0) < (mh2 or 0):
                signal = -1

        # Strat 4: BB mean reversion
        if signal == 0:
            buf = a * SC_BB_TOUCH
            touched_lo = l1 <= bbl + buf
            rejected_up = c1 > bbl and c1 > o1
            touched_hi = h1_ >= bbu - buf
            rejected_dn = c1 < bbu and c1 < o1
            if touched_lo and rejected_up and sk1 < SC_STOCH_MOS \
               and rsi1 > SC_RSI_OS and trend_bias != -1:
                signal = 1
            elif touched_hi and rejected_dn and sk1 > SC_STOCH_MOB \
               and rsi1 < SC_RSI_OB and trend_bias != 1:
                signal = -1

        # Strat 5: Bar high/low breakout
        if signal == 0:
            ask_live = bar.close + SPREAD_POINTS * TICK_SIZE / 2
            bid_live = bar.close - SPREAD_POINTS * TICK_SIZE / 2
            brk_buf = a * 0.1
            if ask_live > h2 + brk_buf and ef1 > em1 and em1 > es1 \
               and (mh1 or 0) > 0 and rsi1 > 50 and rsi1 < SC_RSI_OB \
               and (not trend_bias or trend_bias == 1):
                signal = 1
            elif bid_live < l2 - brk_buf and ef1 < em1 and em1 < es1 \
               and (mh1 or 0) < 0 and rsi1 < 50 and rsi1 > SC_RSI_OS \
               and (not trend_bias or trend_bias == -1):
                signal = -1

        if signal == 1 and sk1 > SC_STOCH_OB:  signal = 0
        if signal == -1 and sk1 < SC_STOCH_OS: signal = 0
        if signal == 0: continue

        ask_px = bar.close + SPREAD_POINTS * TICK_SIZE / 2
        bid_px = bar.close - SPREAD_POINTS * TICK_SIZE / 2
        entry = ask_px if signal == 1 else bid_px
        sl  = entry - a * SC_ATR_SL  * signal
        tp1 = entry + a * SC_ATR_TP1 * signal
        tp2 = entry + a * SC_ATR_TP2 * signal

        sl_dist = abs(entry - sl)
        if sl_dist <= 0: continue
        risk_amt = balance * SC_RISK_PCT / 100.0
        sl_val   = (sl_dist / TICK_SIZE) * TICK_VALUE_STD
        raw_lots = risk_amt / sl_val if sl_val > 0 else SC_MIN_LOT
        lots = max(SC_MIN_LOT, min(SC_MAX_LOT, round(raw_lots, 2)))

        pos = Position(signal, entry, sl, tp1, tp2, lots, dt)
        open_pos.append(pos)
        day_trades += 1
        hour_trades += 1
        last_trade_bar = i

    last_bar = m5_bars[-1]
    for pos in list(open_pos):
        pnl = pos.close(last_bar.close, last_bar.dt, 'EOT')
        balance += pnl
        trades.append(pos)

    res.trades       = trades
    res.equity_curve = equity_curve
    res.balance      = balance
    res.equity       = balance
    res.peak_eq      = peak_eq
    res.max_dd       = max_dd
    return res

# ─────────────────────────────────────────────────────────────────────────────
# STATS & REPORT
# ─────────────────────────────────────────────────────────────────────────────

def compute_stats(res):
    trades = res.trades
    if not trades:
        return {}
    pnls   = [t.pnl for t in trades]
    wins   = [p for p in pnls if p > 0]
    losses = [p for p in pnls if p < 0]

    total_pnl    = sum(pnls)
    win_rate     = len(wins) / len(trades) * 100 if trades else 0
    avg_win      = statistics.mean(wins)   if wins   else 0
    avg_loss     = statistics.mean(losses) if losses else 0
    profit_factor = abs(sum(wins) / sum(losses)) if losses and sum(losses) != 0 else float('inf')
    expectancy   = (win_rate/100 * avg_win) + ((1-win_rate/100) * avg_loss)
    max_win      = max(pnls)
    max_loss     = min(pnls)

    # Sharpe (annualised) — using equity curve daily returns
    eq_vals = [eq for _, eq in res.equity_curve]
    daily_rets = []
    step = 120  # ~120 M5 bars or ~10 H1 bars per trading day
    for j in range(step, len(eq_vals), step):
        r = (eq_vals[j] - eq_vals[j-step]) / eq_vals[j-step] if eq_vals[j-step] > 0 else 0
        daily_rets.append(r)
    sharpe = 0.0
    if len(daily_rets) > 1:
        mu  = statistics.mean(daily_rets)
        std = statistics.stdev(daily_rets)
        sharpe = (mu / std * math.sqrt(252)) if std > 0 else 0

    # Trade durations
    durations = []
    for t in trades:
        if t.close_dt and t.open_dt:
            dur = (t.close_dt - t.open_dt).total_seconds() / 3600
            durations.append(dur)
    avg_dur = statistics.mean(durations) if durations else 0

    # Consecutive stats
    max_consec_wins = max_consec_loss = cur_w = cur_l = 0
    for p in pnls:
        if p > 0: cur_w += 1; cur_l = 0
        else:     cur_l += 1; cur_w = 0
        max_consec_wins = max(max_consec_wins, cur_w)
        max_consec_loss = max(max_consec_loss, cur_l)

    return {
        'total_trades'     : len(trades),
        'winning_trades'   : len(wins),
        'losing_trades'    : len(losses),
        'win_rate'         : win_rate,
        'total_pnl'        : total_pnl,
        'total_return_pct' : total_pnl / INITIAL_BALANCE * 100,
        'avg_win'          : avg_win,
        'avg_loss'         : avg_loss,
        'profit_factor'    : profit_factor,
        'expectancy'       : expectancy,
        'max_win'          : max_win,
        'max_loss'         : max_loss,
        'max_drawdown_pct' : res.max_dd,
        'sharpe'           : sharpe,
        'avg_duration_hr'  : avg_dur,
        'max_consec_wins'  : max_consec_wins,
        'max_consec_loss'  : max_consec_loss,
    }

def ascii_equity(equity_curve, width=70, height=16, label=''):
    if len(equity_curve) < 2:
        return "  (no data)"
    vals = [v for _, v in equity_curve]
    # Downsample
    step = max(1, len(vals) // width)
    sampled = vals[::step][:width]
    lo = min(sampled); hi = max(sampled)
    rng = hi - lo if hi != lo else 1

    rows = []
    for row in range(height, -1, -1):
        threshold = lo + rng * row / height
        line = ''
        for v in sampled:
            if v >= threshold:
                line += '█'
            else:
                line += ' '
        rows.append(f"  ${threshold:>9.0f} |{line}|")

    rows.append(f"           +{'-'*len(sampled)}+")
    rows.append(f"            {label}")
    return '\n'.join(rows)

def print_report(sw_res, sw_stats, sc_res, sc_stats, out_lines):
    def p(s=''): out_lines.append(s)

    p("=" * 78)
    p("  OIL EA BACKTEST REPORT")
    p(f"  Data: Synthetic GBM, Brent calibrated  |  Period: 2 years (504 trading days)")
    p(f"  Start price: ${START_PRICE}  |  Annual vol: {ANNUAL_VOL*100:.1f}%  |  Account: ${INITIAL_BALANCE:,.0f}")
    p("=" * 78)

    for ea_name, res, stats in [
        ("SWING EA — Brent Oil Trader Pro v4.00 (H1)", sw_res, sw_stats),
        ("SCALPER EA — Oil Scalper Pro v1.00 (M5)",   sc_res, sc_stats),
    ]:
        p()
        p("─" * 78)
        p(f"  {ea_name}")
        p("─" * 78)
        if not stats:
            p("  No trades generated."); continue

        final_bal = INITIAL_BALANCE + stats['total_pnl']
        p(f"  Final Balance   : ${final_bal:>10,.2f}   (started ${INITIAL_BALANCE:,.2f})")
        p(f"  Net P&L         : ${stats['total_pnl']:>+10,.2f}")
        p(f"  Total Return    : {stats['total_return_pct']:>+8.2f}%")
        p(f"  Max Drawdown    : {stats['max_drawdown_pct']:>8.2f}%")
        p(f"  Sharpe Ratio    : {stats['sharpe']:>8.2f}")
        p()
        p(f"  Total Trades    : {stats['total_trades']:>6}")
        p(f"  Winning Trades  : {stats['winning_trades']:>6}  ({stats['win_rate']:.1f}%)")
        p(f"  Losing Trades   : {stats['losing_trades']:>6}  ({100-stats['win_rate']:.1f}%)")
        p(f"  Profit Factor   : {stats['profit_factor']:>8.2f}")
        p(f"  Expectancy      : ${stats['expectancy']:>+8.2f} / trade")
        p()
        p(f"  Avg Win         : ${stats['avg_win']:>+8.2f}")
        p(f"  Avg Loss        : ${stats['avg_loss']:>+8.2f}")
        p(f"  Largest Win     : ${stats['max_win']:>+8.2f}")
        p(f"  Largest Loss    : ${stats['max_loss']:>+8.2f}")
        p(f"  Max Consec Wins : {stats['max_consec_wins']:>6}")
        p(f"  Max Consec Loss : {stats['max_consec_loss']:>6}")
        p(f"  Avg Trade Dur   : {stats['avg_duration_hr']:>6.1f} hours")
        p()
        p("  EQUITY CURVE:")
        p(ascii_equity(res.equity_curve, label="Start → End (2 years)"))
        p()
        p("  LAST 15 CLOSED TRADES:")
        p(f"  {'#':>5}  {'Dir':>4}  {'Open Date':>16}  {'Entry':>7}  "
          f"{'SL':>7}  {'TP2':>7}  {'Close':>7}  {'P&L':>9}  Status")
        p("  " + "-"*85)
        for t in res.trades[-15:]:
            d = "BUY" if t.dir == 1 else "SEL"
            od = t.open_dt.strftime('%Y-%m-%d %H:%M') if t.open_dt else '—'
            cp = f"${t.close_px:.2f}" if t.close_px else '—'
            p(f"  {t.id:>5}  {d:>4}  {od:>16}  ${t.entry:>6.2f}  "
              f"${t.sl:>6.2f}  ${t.tp2:>6.2f}  {cp:>7}  ${t.pnl:>+8.2f}  {t.status}")

    p()
    p("─" * 78)
    p("  SIDE-BY-SIDE COMPARISON")
    p("─" * 78)
    sw, sc = sw_stats, sc_stats
    fmt = "  {:<22} {:>18}  {:>18}"
    p(fmt.format("Metric", "Swing EA (H1)", "Scalper (M5)"))
    p("  " + "-"*60)
    p(fmt.format("Total Return",
                  f"{sw['total_return_pct']:+.2f}%",
                  f"{sc['total_return_pct']:+.2f}%"))
    p(fmt.format("Sharpe Ratio",
                  f"{sw['sharpe']:.2f}",
                  f"{sc['sharpe']:.2f}"))
    p(fmt.format("Max Drawdown",
                  f"{sw['max_drawdown_pct']:.2f}%",
                  f"{sc['max_drawdown_pct']:.2f}%"))
    p(fmt.format("Win Rate",
                  f"{sw['win_rate']:.1f}%",
                  f"{sc['win_rate']:.1f}%"))
    p(fmt.format("Profit Factor",
                  f"{sw['profit_factor']:.2f}",
                  f"{sc['profit_factor']:.2f}"))
    p(fmt.format("Expectancy/trade",
                  f"${sw['expectancy']:+.2f}",
                  f"${sc['expectancy']:+.2f}"))
    p(fmt.format("Total Trades",
                  str(sw['total_trades']),
                  str(sc['total_trades'])))
    p(fmt.format("Avg Trade Duration",
                  f"{sw['avg_duration_hr']:.1f}h",
                  f"{sc['avg_duration_hr']:.1f}h"))
    p(fmt.format("Max Consec Loss",
                  str(sw['max_consec_loss']),
                  str(sc['max_consec_loss'])))
    p()
    p("  NOTE: Results use synthetic GBM price data. Actual live performance")
    p("  will differ. Always validate on a demo account before going live.")
    p("=" * 78)

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    print("Generating synthetic oil price data...")
    m5_bars  = generate_bars(5)
    print(f"  M5  bars: {len(m5_bars):,}")

    m30_bars = resample_to_higher(m5_bars, 6)
    h1_bars  = resample_to_higher(m5_bars, 12)
    h4_bars  = resample_to_higher(m5_bars, 48)
    print(f"  M30 bars: {len(m30_bars):,}")
    print(f"  H1  bars: {len(h1_bars):,}")
    print(f"  H4  bars: {len(h4_bars):,}")

    print("\nRunning Swing EA backtest (H1)...")
    sw_res   = backtest_swing(h1_bars, h4_bars)
    sw_stats = compute_stats(sw_res)
    print(f"  Done — {len(sw_res.trades)} trades")

    print("Running Scalper EA backtest (M5)...")
    sc_res   = backtest_scalper(m5_bars, m30_bars)
    sc_stats = compute_stats(sc_res)
    print(f"  Done — {len(sc_res.trades)} trades")

    out_lines = []
    print_report(sw_res, sw_stats, sc_res, sc_stats, out_lines)
    report_text = '\n'.join(out_lines)

    print('\n' + report_text)

    # Save report
    out_path = '/home/user/Jmalhem/backtest_report.txt'
    with open(out_path, 'w') as f:
        f.write(report_text)
    print(f"\nReport saved: {out_path}")

    # Save trade CSV
    csv_path = '/home/user/Jmalhem/backtest_trades.csv'
    with open(csv_path, 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['EA','Ticket','Dir','Open_DT','Entry','SL','TP2','Close_DT','Close_Px','PnL','Status'])
        for t in sw_res.trades:
            w.writerow(['Swing', t.id, 'BUY' if t.dir==1 else 'SELL',
                        t.open_dt, round(t.entry,2), round(t.sl,2), round(t.tp2,2),
                        t.close_dt, round(t.close_px,2) if t.close_px else '',
                        round(t.pnl,2), t.status])
        for t in sc_res.trades:
            w.writerow(['Scalper', t.id, 'BUY' if t.dir==1 else 'SELL',
                        t.open_dt, round(t.entry,2), round(t.sl,2), round(t.tp2,2),
                        t.close_dt, round(t.close_px,2) if t.close_px else '',
                        round(t.pnl,2), t.status])
    print(f"Trades CSV: {csv_path}")

if __name__ == '__main__':
    main()
