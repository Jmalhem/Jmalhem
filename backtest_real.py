#!/usr/bin/env python3
"""
Oil EA Backtester — REAL Historical Data
Uses uploaded Brent OHLCV CSV files (MT4 export format).

Swing EA  : H1 entry + H4 trend bias  (Aug 2022 – Jun 2026, 4 years)
Scalper EA: M5 entry + M30 trend bias  (Sep 2025 – Jun 2026, ~9 months)

CSV format: DATE,TIME,OPEN,HIGH,LOW,CLOSE,VOLUME  (no header)
Date format: YYYY.MM.DD   Time format: HH:MM
"""

import math, statistics, csv, os
from datetime import datetime, timedelta

# ─────────────────────────────────────────────────────────────────────────────
# FILE PATHS
# ─────────────────────────────────────────────────────────────────────────────
DATA_DIR = "/root/.claude/uploads/4d54b556-e998-5518-a089-393bba423e3e"

def find_file(suffix):
    for fn in os.listdir(DATA_DIR):
        if fn.endswith(suffix + ".csv"):
            return os.path.join(DATA_DIR, fn)
    raise FileNotFoundError(f"No file matching *{suffix}.csv in {DATA_DIR}")

PATH_H4  = find_file("BRENTs240")
PATH_H1  = find_file("BRENTs60")
PATH_M15 = find_file("BRENTs15")
PATH_M5  = find_file("BRENTs5")

# ─────────────────────────────────────────────────────────────────────────────
# BACKTEST PARAMETERS
# ─────────────────────────────────────────────────────────────────────────────
INITIAL_BALANCE = 10_000.0
TICK_SIZE       = 0.01          # $0.01 per barrel
TICK_VALUE_STD  = 1.0           # $1 per pip per lot (100-barrel standard lot)
SPREAD_POINTS   = 3             # 3 pts = $0.03 typical Brent ECN spread
SLIPPAGE_PTS    = 1             # 1 pt slippage

# Swing EA
SW_RISK_PCT       = 1.0
SW_MAX_LOT        = 5.0;  SW_MIN_LOT  = 0.01
SW_ATR_SL         = 1.8;  SW_ATR_TP1  = 1.5;  SW_ATR_TP2  = 3.0
SW_PARTIAL_PCT    = 50.0
SW_TRAIL_MULT     = 1.0;  SW_TRAIL_ACT = 1.5
SW_MAX_TRADES_DAY = 6
SW_MAX_DD_PCT     = 15.0; SW_DAILY_LOSS = 3.0; SW_DAILY_PROF = 5.0
SW_EMA_FAST = 8;  SW_EMA_MED = 21; SW_EMA_SLOW = 50; SW_EMA_TREND = 200
SW_RSI_PER  = 14; SW_RSI_OB  = 70.0; SW_RSI_OS = 30.0
SW_RSI_BULL = 45.0; SW_RSI_BEAR = 55.0
SW_MACD_F = 12; SW_MACD_S = 26; SW_MACD_SIG = 9
SW_STOCH_K = 5; SW_STOCH_D = 3; SW_STOCH_SL = 3
SW_STOCH_OB = 80.0; SW_STOCH_OS = 20.0
SW_BB_PER = 20; SW_BB_DEV = 2.0
SW_ATR_PER = 14; SW_ATR_MIN = 0.3; SW_ATR_MAX = 3.5

# Scalper EA
SC_RISK_PCT       = 0.5
SC_MAX_LOT        = 3.0;  SC_MIN_LOT  = 0.01
SC_ATR_SL         = 0.9;  SC_ATR_TP1  = 0.8;  SC_ATR_TP2  = 1.6
SC_PARTIAL_PCT    = 60.0
SC_TRAIL_MULT     = 0.5;  SC_TRAIL_ACT = 0.7
SC_MAX_TRADES_DAY = 25;   SC_MAX_TRADES_HR = 5
SC_MAX_DD_PCT     = 10.0; SC_DAILY_LOSS = 2.0; SC_DAILY_PROF = 4.0
SC_MAX_SPREAD     = 20.0; SC_MIN_BARS   = 2
SC_EMA_FAST = 3;  SC_EMA_MID = 8; SC_EMA_SLOW = 21; SC_EMA_TREND = 50
SC_RSI_PER  = 7;  SC_RSI_OB  = 75.0; SC_RSI_OS = 25.0
SC_RSI_BULL = 52.0; SC_RSI_BEAR = 48.0
SC_MACD_F = 5; SC_MACD_S = 13; SC_MACD_SIG = 3
SC_STOCH_K = 5; SC_STOCH_D = 3; SC_STOCH_SL = 3
SC_STOCH_OB = 80.0; SC_STOCH_OS = 20.0
SC_STOCH_MOB = 65.0; SC_STOCH_MOS = 35.0
SC_BB_PER = 20; SC_BB_DEV = 2.0; SC_BB_TOUCH = 0.15
SC_ATR_PER = 7; SC_ATR_MIN = 0.4; SC_ATR_MAX = 2.8

# ─────────────────────────────────────────────────────────────────────────────
# DATA LOADER
# ─────────────────────────────────────────────────────────────────────────────
class Bar:
    __slots__ = ('dt','open','high','low','close','volume')
    def __init__(self, dt, o, h, l, c, v):
        self.dt=dt; self.open=o; self.high=h; self.low=l; self.close=c; self.volume=v

def load_csv(path):
    bars = []
    with open(path, newline='') as f:
        for row in csv.reader(f):
            if len(row) < 6: continue
            try:
                dt = datetime.strptime(row[0].strip() + ' ' + row[1].strip(), '%Y.%m.%d %H:%M')
                o, h, l, c = float(row[2]), float(row[3]), float(row[4]), float(row[5])
                v = int(float(row[6])) if len(row) > 6 else 0
                bars.append(Bar(dt, o, h, l, c, v))
            except Exception:
                continue
    bars.sort(key=lambda b: b.dt)
    return bars

def resample(bars, factor_minutes):
    """Aggregate lower-TF bars into higher-TF bars of factor_minutes width."""
    if not bars: return []
    out = []
    bucket = []
    bucket_start = None
    for b in bars:
        # Compute which bucket this bar belongs to
        mins = b.dt.hour * 60 + b.dt.minute
        slot = (mins // factor_minutes) * factor_minutes
        slot_dt = b.dt.replace(hour=slot // 60, minute=slot % 60, second=0)
        if bucket_start is None:
            bucket_start = slot_dt
        if slot_dt != bucket_start and bucket:
            o = bucket[0].open;  h = max(x.high for x in bucket)
            l = min(x.low  for x in bucket);  c = bucket[-1].close
            v = sum(x.volume for x in bucket)
            out.append(Bar(bucket_start, o, h, l, c, v))
            bucket = []; bucket_start = slot_dt
        bucket.append(b)
    if bucket:
        o = bucket[0].open;  h = max(x.high for x in bucket)
        l = min(x.low  for x in bucket);  c = bucket[-1].close
        v = sum(x.volume for x in bucket)
        out.append(Bar(bucket_start, o, h, l, c, v))
    return out

# ─────────────────────────────────────────────────────────────────────────────
# INDICATORS
# ─────────────────────────────────────────────────────────────────────────────
def ema(values, period):
    result = [None] * len(values)
    k = 2.0 / (period + 1)
    first_valid = next((i for i, v in enumerate(values) if v is not None), None)
    if first_valid is None or len(values) - first_valid < period:
        return result
    seed_end = first_valid + period
    seed = [values[i] for i in range(first_valid, seed_end) if values[i] is not None]
    if len(seed) < period: return result
    result[seed_end - 1] = sum(seed) / period
    for i in range(seed_end, len(values)):
        if values[i] is not None and result[i-1] is not None:
            result[i] = values[i] * k + result[i-1] * (1 - k)
    return result

def atr_series(highs, lows, closes, period):
    n = len(closes)
    tr = [None] * n
    for i in range(1, n):
        h, l, pc = highs[i], lows[i], closes[i-1]
        tr[i] = max(h - l, abs(h - pc), abs(l - pc))
    result = [None] * n
    seed = [tr[i] for i in range(1, period + 1) if tr[i] is not None]
    if len(seed) < period: return result
    result[period] = sum(seed) / period
    for i in range(period + 1, n):
        if tr[i] is not None and result[i-1] is not None:
            result[i] = (result[i-1] * (period - 1) + tr[i]) / period
    return result

def rsi_series(closes, period):
    n = len(closes)
    result = [None] * n
    if n < period + 1: return result
    gains, losses = [], []
    for i in range(1, period + 1):
        d = closes[i] - closes[i-1]
        gains.append(max(d, 0.0)); losses.append(max(-d, 0.0))
    avg_g = sum(gains) / period
    avg_l = sum(losses) / period
    result[period] = 100 - 100 / (1 + avg_g / avg_l) if avg_l > 0 else 100.0
    for i in range(period + 1, n):
        d = closes[i] - closes[i-1]
        avg_g = (avg_g * (period-1) + max(d,0.0)) / period
        avg_l = (avg_l * (period-1) + max(-d,0.0)) / period
        result[i] = 100 - 100 / (1 + avg_g / avg_l) if avg_l > 0 else 100.0
    return result

def macd_series(closes, fast, slow, sig):
    ef = ema(closes, fast); es = ema(closes, slow)
    line = [ef[i] - es[i] if ef[i] is not None and es[i] is not None
            else None for i in range(len(closes))]
    sig_line = ema(line, sig)
    hist = [line[i] - sig_line[i]
            if line[i] is not None and sig_line[i] is not None
            else None for i in range(len(closes))]
    return line, sig_line, hist

def stoch_series(highs, lows, closes, k_per, d_per, slowing):
    n = len(closes)
    raw_k = [None] * n
    for i in range(k_per - 1, n):
        lo = min(lows[i-k_per+1:i+1]); hi = max(highs[i-k_per+1:i+1])
        raw_k[i] = 100.0 * (closes[i] - lo) / (hi - lo) if hi != lo else 50.0
    sk = [None] * n
    for i in range(k_per + slowing - 2, n):
        w = [raw_k[j] for j in range(i-slowing+1, i+1) if raw_k[j] is not None]
        if len(w) == slowing: sk[i] = sum(w) / slowing
    sd = [None] * n
    for i in range(d_per - 1, n):
        w = [sk[j] for j in range(i-d_per+1, i+1) if sk[j] is not None]
        if len(w) == d_per: sd[i] = sum(w) / d_per
    return sk, sd

def bb_series(closes, period, dev):
    n = len(closes)
    upper = [None]*n; lower = [None]*n; mid = [None]*n
    for i in range(period-1, n):
        w = closes[i-period+1:i+1]
        m = sum(w) / period
        sd = math.sqrt(sum((x-m)**2 for x in w) / period)
        mid[i]=m; upper[i]=m+dev*sd; lower[i]=m-dev*sd
    return upper, lower, mid

def rolling_avg(vals, period):
    result = [None] * len(vals)
    for i in range(period-1, len(vals)):
        w = [vals[j] for j in range(i-period+1, i+1) if vals[j] is not None]
        if len(w) == period: result[i] = sum(w)/period
    return result

# ─────────────────────────────────────────────────────────────────────────────
# SESSION / NEWS HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def is_session(dt):
    dow  = dt.weekday()   # 0=Mon, 4=Fri, 5=Sat, 6=Sun
    h    = dt.hour
    if dow >= 5: return False
    if dow == 0 and h < 5: return False    # Monday gap
    if dow == 4 and h >= 17: return False  # Friday close
    return (7 <= h < 9) or (9 <= h < 13) or (13 <= h < 17)

def is_news(dt):
    dow = dt.weekday(); h = dt.hour; m = dt.minute; tot = h*60+m
    buf = 30
    if dow == 2:  # Wednesday: EIA 14:30, FOMC 19:00
        if 14*60+30-buf <= tot <= 14*60+30+buf: return True
        if 19*60-buf     <= tot <= 19*60+buf:   return True
    if dow == 1 and 20*60+30-buf <= tot <= 20*60+30+buf: return True  # API Tue
    if dow == 4 and 13*60+30     <= tot <= 14*60+30:     return True  # NFP Fri
    return False

# ─────────────────────────────────────────────────────────────────────────────
# POSITION
# ─────────────────────────────────────────────────────────────────────────────
_pid = [0]

class Position:
    def __init__(self, direction, entry, sl, tp1, tp2, lots, dt):
        _pid[0] += 1
        self.id=_pid[0]; self.dir=direction; self.entry=entry
        self.sl=sl; self.tp1=tp1; self.tp2=tp2; self.lots=lots; self.orig_lots=lots
        self.open_dt=dt; self.close_dt=None; self.close_px=None; self.pnl=0.0
        self.partial_done=False; self.be_done=False; self.status='open'
        self.close_reason=''

    def profit_pts(self, px): return (px - self.entry) * self.dir

    def close(self, px, dt, reason=''):
        self.close_px=px; self.close_dt=dt; self.status='closed'; self.close_reason=reason
        self.pnl = ((px - self.entry) * self.dir / TICK_SIZE) * TICK_VALUE_STD * self.lots
        return self.pnl

# ─────────────────────────────────────────────────────────────────────────────
# GENERIC POSITION MANAGER  (called every bar for both EAs)
# ─────────────────────────────────────────────────────────────────────────────
def manage_positions(open_pos, bar, atr_val,
                     use_partial, partial_pct, min_lot,
                     use_be, be_atr_buf,
                     use_trail, trail_atr, trail_act_atr,
                     digits, balance_ref, closed_trades):
    """Mutates open_pos and closed_trades in place. Returns balance delta."""
    delta = 0.0
    spread = SPREAD_POINTS * TICK_SIZE
    for pos in list(open_pos):
        bid = bar.close - spread / 2
        ask = bar.close + spread / 2
        cur_px = bid if pos.dir == 1 else ask

        # SL hit
        if pos.dir == 1 and bar.low <= pos.sl:
            sl_px = pos.sl - SLIPPAGE_PTS * TICK_SIZE
            delta += pos.close(sl_px, bar.dt, 'SL')
            open_pos.remove(pos); closed_trades.append(pos); continue
        if pos.dir == -1 and bar.high >= pos.sl:
            sl_px = pos.sl + SLIPPAGE_PTS * TICK_SIZE
            delta += pos.close(sl_px, bar.dt, 'SL')
            open_pos.remove(pos); closed_trades.append(pos); continue

        # TP2 hit
        if pos.dir == 1 and bar.high >= pos.tp2:
            delta += pos.close(pos.tp2, bar.dt, 'TP2')
            open_pos.remove(pos); closed_trades.append(pos); continue
        if pos.dir == -1 and bar.low <= pos.tp2:
            delta += pos.close(pos.tp2, bar.dt, 'TP2')
            open_pos.remove(pos); closed_trades.append(pos); continue

        # TP1 partial close
        tp1_hit = (pos.dir == 1 and bar.high >= pos.tp1) or \
                  (pos.dir == -1 and bar.low <= pos.tp1)
        if use_partial and tp1_hit and not pos.partial_done:
            close_lots = round(pos.lots * partial_pct / 100.0, 2)
            from math import floor
            step = 0.01
            close_lots = floor(close_lots / step) * step
            if close_lots >= min_lot and close_lots < pos.lots:
                diff = (pos.tp1 - pos.entry) * pos.dir
                pnl  = (diff / TICK_SIZE) * TICK_VALUE_STD * close_lots
                delta += pnl; pos.lots -= close_lots
            pos.partial_done = True

        # Break-even
        if use_be and tp1_hit and not pos.be_done and atr_val:
            buf = atr_val * be_atr_buf
            if pos.dir == 1:
                new_sl = round(pos.entry + buf, digits)
                if new_sl > pos.sl: pos.sl = new_sl
            else:
                new_sl = round(pos.entry - buf, digits)
                if new_sl < pos.sl: pos.sl = new_sl
            pos.be_done = True

        # Trailing stop
        if use_trail and atr_val:
            prof = pos.profit_pts(cur_px)
            if prof >= atr_val * trail_act_atr:
                trail_dist = atr_val * trail_atr
                if pos.dir == 1:
                    new_sl = round(cur_px - trail_dist, digits)
                    if new_sl > pos.sl: pos.sl = new_sl
                else:
                    new_sl = round(cur_px + trail_dist, digits)
                    if new_sl < pos.sl: pos.sl = new_sl

    return delta

def unrealised_pnl(open_pos, price):
    total = 0.0
    spread = SPREAD_POINTS * TICK_SIZE
    for pos in open_pos:
        cur_px = price - spread/2 if pos.dir == 1 else price + spread/2
        diff = (cur_px - pos.entry) * pos.dir
        total += (diff / TICK_SIZE) * TICK_VALUE_STD * pos.lots
    return total

def calc_lots(entry, sl, balance, risk_pct, min_lot, max_lot):
    sl_dist = abs(entry - sl)
    if sl_dist <= 0: return min_lot
    risk_amt = balance * risk_pct / 100.0
    sl_val   = (sl_dist / TICK_SIZE) * TICK_VALUE_STD
    if sl_val <= 0: return min_lot
    raw = risk_amt / sl_val
    from math import floor
    lots = floor(raw / 0.01) * 0.01
    return max(min_lot, min(max_lot, round(lots, 2)))

# ─────────────────────────────────────────────────────────────────────────────
# SWING EA BACKTEST  (H1 + H4)
# ─────────────────────────────────────────────────────────────────────────────
def backtest_swing(h1_bars, h4_bars):
    print(f"  H1 bars: {len(h1_bars):,}  ({h1_bars[0].dt.date()} → {h1_bars[-1].dt.date()})")
    print(f"  H4 bars: {len(h4_bars):,}")

    # Pre-compute H1 indicators
    closes = [b.close for b in h1_bars]
    highs  = [b.high  for b in h1_bars]
    lows   = [b.low   for b in h1_bars]

    ema_f  = ema(closes, SW_EMA_FAST)
    ema_m  = ema(closes, SW_EMA_MED)
    ema_s  = ema(closes, SW_EMA_SLOW)
    ema_t  = ema(closes, SW_EMA_TREND)
    atr_v  = atr_series(highs, lows, closes, SW_ATR_PER)
    atr_avg= rolling_avg(atr_v, 50)
    rsi_v  = rsi_series(closes, SW_RSI_PER)
    _, _, macd_h = macd_series(closes, SW_MACD_F, SW_MACD_S, SW_MACD_SIG)
    stk, std_v   = stoch_series(highs, lows, closes, SW_STOCH_K, SW_STOCH_D, SW_STOCH_SL)
    bb_up, bb_lo, _ = bb_series(closes, SW_BB_PER, SW_BB_DEV)

    # H4 trend lookup
    h4_closes = [b.close for b in h4_bars]
    h4_highs  = [b.high  for b in h4_bars]
    h4_lows   = [b.low   for b in h4_bars]
    h4_ef     = ema(h4_closes, SW_EMA_FAST)
    h4_et     = ema(h4_closes, SW_EMA_TREND)
    h4_times  = [b.dt for b in h4_bars]

    def h4_bias_at(dt):
        # Binary search: last H4 bar that has fully closed before dt
        lo_, hi_ = 0, len(h4_times)-1; res = -1
        while lo_ <= hi_:
            mid_ = (lo_+hi_)//2
            if h4_times[mid_] < dt: res=mid_; lo_=mid_+1
            else: hi_=mid_-1
        if res < 0 or h4_ef[res] is None or h4_et[res] is None: return 0
        if h4_closes[res] > h4_et[res] and h4_ef[res] > h4_et[res]: return  1
        if h4_closes[res] < h4_et[res] and h4_ef[res] < h4_et[res]: return -1
        return 0

    # ── Simulation state ──
    balance   = INITIAL_BALANCE
    peak_eq   = INITIAL_BALANCE
    max_dd    = 0.0
    open_pos  = []
    trades    = []
    equity_curve = []

    day_balance = INITIAL_BALANCE; day_equity = INITIAL_BALANCE
    day_trades  = 0; cur_day = None
    daily_halted = False; dd_halted = False

    WARMUP = max(SW_EMA_TREND, 50, SW_BB_PER) + 5

    for i in range(WARMUP, len(h1_bars)):
        bar = h1_bars[i]; dt = bar.dt

        # Daily reset
        d = dt.date()
        if d != cur_day:
            cur_day      = d
            day_balance  = balance
            day_equity   = balance + unrealised_pnl(open_pos, bar.close)
            day_trades   = 0
            daily_halted = False

        # Manage positions
        delta = manage_positions(
            open_pos, bar, atr_v[i],
            True,  SW_PARTIAL_PCT, SW_MIN_LOT,
            True,  0.1,
            True,  SW_TRAIL_MULT, SW_TRAIL_ACT,
            2, balance, trades)
        balance += delta

        # Equity & drawdown
        equity = balance + unrealised_pnl(open_pos, bar.close)
        if equity > peak_eq: peak_eq = equity
        dd = (peak_eq - equity) / peak_eq * 100.0 if peak_eq > 0 else 0
        if dd > max_dd: max_dd = dd
        dd_halted = (dd >= SW_MAX_DD_PCT)

        pnl_pct = (equity - day_equity) / day_balance * 100.0 if day_balance > 0 else 0
        if pnl_pct <= -SW_DAILY_LOSS: daily_halted = True
        if pnl_pct >= SW_DAILY_PROF:  daily_halted = True

        equity_curve.append((dt, round(equity, 2)))

        # Entry guards
        if daily_halted or dd_halted: continue
        if day_trades >= SW_MAX_TRADES_DAY: continue
        if len(open_pos) >= 1: continue
        if not is_session(dt): continue
        if is_news(dt): continue

        # Indicator availability
        needed = [ema_f[i], ema_m[i], ema_s[i], ema_t[i],
                  atr_v[i], atr_avg[i], rsi_v[i], macd_h[i], stk[i], bb_up[i]]
        if any(v is None for v in needed): continue
        if atr_v[i] < atr_avg[i] * SW_ATR_MIN: continue
        if atr_v[i] > atr_avg[i] * SW_ATR_MAX: continue

        h4b = h4_bias_at(dt)
        c1  = closes[i]; c2 = closes[i-1]
        ef1 = ema_f[i];  ef2 = ema_f[i-1]
        em1 = ema_m[i];  em2 = ema_m[i-1]
        es1 = ema_s[i]
        r1  = rsi_v[i]
        mh1 = macd_h[i]; mh2 = macd_h[i-1] if macd_h[i-1] is not None else mh1
        sk1 = stk[i];    sd1 = std_v[i] if std_v[i] is not None else sk1
        bbu = bb_up[i];  bbl = bb_lo[i]
        bbu2= bb_up[i-1] if bb_up[i-1] is not None else bbu
        bbl2= bb_lo[i-1] if bb_lo[i-1] is not None else bbl
        a   = atr_v[i]

        signal = 0

        # S1: EMA trend follow
        if h4b != 0:
            if ef2 <= em2 and ef1 > em1 and h4b == 1 and c1 > es1 and SW_RSI_BULL < r1 < SW_RSI_OB:
                signal = 1
            elif ef2 >= em2 and ef1 < em1 and h4b == -1 and c1 < es1 and SW_RSI_OS < r1 < SW_RSI_BEAR:
                signal = -1

        # S2: MACD momentum
        if signal == 0:
            if mh2 < 0 and mh1 > 0 and r1 > 50 and r1 < SW_RSI_OB and (not h4b or h4b == 1):
                signal = 1
            elif mh2 > 0 and mh1 < 0 and r1 < 50 and r1 > SW_RSI_OS and (not h4b or h4b == -1):
                signal = -1

        # S3: BB breakout
        if signal == 0:
            squeeze = (bbu - bbl) < a * SW_BB_DEV
            if not squeeze:
                if c1 > bbu and c2 <= bbu2 and mh1 > 0 and (not h4b or h4b == 1):  signal = 1
                if c1 < bbl and c2 >= bbl2 and mh1 < 0 and (not h4b or h4b == -1): signal = -1

        # S4: Pullback to EMA
        if signal == 0 and h4b != 0:
            if h4b == 1 and abs(c1-em1) < a*0.4 and c1 > es1 and sk1 < 40 and sk1 > sd1 and 40 < r1 < 65:
                signal = 1
            elif h4b == -1 and abs(c1-em1) < a*0.4 and c1 < es1 and sk1 > 60 and sk1 < sd1 and 35 < r1 < 60:
                signal = -1

        if signal == 1  and sk1 > SW_STOCH_OB: signal = 0
        if signal == -1 and sk1 < SW_STOCH_OS: signal = 0
        if signal == 0: continue

        spread = SPREAD_POINTS * TICK_SIZE
        entry  = (bar.close + spread/2) if signal == 1 else (bar.close - spread/2)
        sl     = entry - a * SW_ATR_SL  * signal
        tp1    = entry + a * SW_ATR_TP1 * signal
        tp2    = entry + a * SW_ATR_TP2 * signal

        min_dist = 0.05  # minimum SL distance ($0.05)
        if abs(entry - sl) < min_dist:
            sl = entry - min_dist * signal

        lots = calc_lots(entry, sl, balance, SW_RISK_PCT, SW_MIN_LOT, SW_MAX_LOT)
        pos  = Position(signal, entry, sl, tp1, tp2, lots, dt)
        open_pos.append(pos); day_trades += 1

    # Close remaining at end
    if h1_bars:
        lb = h1_bars[-1]
        for pos in list(open_pos):
            balance += pos.close(lb.close, lb.dt, 'EOT')
            trades.append(pos)

    return trades, equity_curve, balance, peak_eq, max_dd

# ─────────────────────────────────────────────────────────────────────────────
# SCALPER EA BACKTEST  (M5 + M30 resampled)
# ─────────────────────────────────────────────────────────────────────────────
def backtest_scalper(m5_bars, m30_bars):
    print(f"  M5  bars: {len(m5_bars):,}  ({m5_bars[0].dt.date()} → {m5_bars[-1].dt.date()})")
    print(f"  M30 bars (resampled): {len(m30_bars):,}")

    closes = [b.close for b in m5_bars]
    highs  = [b.high  for b in m5_bars]
    lows   = [b.low   for b in m5_bars]
    opens  = [b.open  for b in m5_bars]

    ef_v   = ema(closes, SC_EMA_FAST)
    em_v   = ema(closes, SC_EMA_MID)
    es_v   = ema(closes, SC_EMA_SLOW)
    et_v   = ema(closes, SC_EMA_TREND)
    atr_v  = atr_series(highs, lows, closes, SC_ATR_PER)
    atr_avg= rolling_avg(atr_v, 30)
    rsi_v  = rsi_series(closes, SC_RSI_PER)
    _, _, macd_h = macd_series(closes, SC_MACD_F, SC_MACD_S, SC_MACD_SIG)
    stk, std_v   = stoch_series(highs, lows, closes, SC_STOCH_K, SC_STOCH_D, SC_STOCH_SL)
    bb_up, bb_lo, _ = bb_series(closes, SC_BB_PER, SC_BB_DEV)

    # M30 trend bias
    c30 = [b.close for b in m30_bars]; h30 = [b.high for b in m30_bars]; l30 = [b.low for b in m30_bars]
    et30 = ema(c30, SC_EMA_TREND); ef30 = ema(c30, SC_EMA_FAST)
    t30_times = [b.dt for b in m30_bars]

    def m30_bias_at(dt):
        lo_, hi_ = 0, len(t30_times)-1; res = -1
        while lo_ <= hi_:
            mid_ = (lo_+hi_)//2
            if t30_times[mid_] < dt: res=mid_; lo_=mid_+1
            else: hi_=mid_-1
        if res < 0 or et30[res] is None or ef30[res] is None: return 0
        if c30[res] > et30[res] and ef30[res] > et30[res]: return  1
        if c30[res] < et30[res] and ef30[res] < et30[res]: return -1
        return 0

    balance   = INITIAL_BALANCE
    peak_eq   = INITIAL_BALANCE
    max_dd    = 0.0
    open_pos  = []
    trades    = []
    equity_curve = []

    day_balance = INITIAL_BALANCE; day_equity = INITIAL_BALANCE
    day_trades  = 0; cur_day = None
    hour_trades = 0; cur_hour = -1
    daily_halted = False; dd_halted = False
    last_trade_bar = -999

    WARMUP = max(SC_EMA_TREND, SC_BB_PER, SC_ATR_PER*5) + 5

    for i in range(WARMUP, len(m5_bars)):
        bar = m5_bars[i]; dt = bar.dt

        if dt.hour != cur_hour:
            cur_hour = dt.hour; hour_trades = 0

        d = dt.date()
        if d != cur_day:
            cur_day      = d
            day_balance  = balance
            day_equity   = balance + unrealised_pnl(open_pos, bar.close)
            day_trades   = 0; hour_trades = 0
            daily_halted = False

        # Manage positions
        delta = manage_positions(
            open_pos, bar, atr_v[i],
            True,  SC_PARTIAL_PCT, SC_MIN_LOT,
            True,  0.05,
            True,  SC_TRAIL_MULT, SC_TRAIL_ACT,
            2, balance, trades)
        balance += delta

        equity = balance + unrealised_pnl(open_pos, bar.close)
        if equity > peak_eq: peak_eq = equity
        dd = (peak_eq - equity) / peak_eq * 100.0 if peak_eq > 0 else 0
        if dd > max_dd: max_dd = dd
        dd_halted = (dd >= SC_MAX_DD_PCT)

        pnl_pct = (equity - day_equity) / day_balance * 100.0 if day_balance > 0 else 0
        if pnl_pct <= -SC_DAILY_LOSS: daily_halted = True
        if pnl_pct >= SC_DAILY_PROF:  daily_halted = True

        equity_curve.append((dt, round(equity, 2)))

        if daily_halted or dd_halted: continue
        if day_trades   >= SC_MAX_TRADES_DAY: continue
        if hour_trades  >= SC_MAX_TRADES_HR:  continue
        if len(open_pos) >= 2: continue
        if not is_session(dt): continue
        if is_news(dt): continue
        if (i - last_trade_bar) < SC_MIN_BARS: continue
        if SPREAD_POINTS > SC_MAX_SPREAD: continue

        needed = [ef_v[i], em_v[i], es_v[i], et_v[i],
                  atr_v[i], atr_avg[i], rsi_v[i], macd_h[i], stk[i], bb_up[i]]
        if any(v is None for v in needed): continue
        if atr_v[i] < atr_avg[i] * SC_ATR_MIN: continue
        if atr_v[i] > atr_avg[i] * SC_ATR_MAX: continue

        c1  = closes[i]; c2 = closes[i-1] if i > 0 else c1
        o1  = opens[i]
        h1_ = highs[i];  l1 = lows[i]
        h2  = highs[i-1] if i > 0 else h1_; l2 = lows[i-1] if i > 0 else l1
        ef1 = ef_v[i];   ef2 = ef_v[i-1] if i>0 else ef1
        em1 = em_v[i];   em2 = em_v[i-1] if i>0 else em1
        es1 = es_v[i]
        r1  = rsi_v[i];  r2  = rsi_v[i-1] if rsi_v[i-1] is not None else r1
        mh1 = macd_h[i]; mh2 = macd_h[i-1] if macd_h[i-1] is not None else mh1
        sk1 = stk[i];    sk2 = stk[i-1] if stk[i-1] is not None else sk1
        sd1 = std_v[i]   if std_v[i] is not None else sk1
        bbu = bb_up[i];  bbl = bb_lo[i]
        a   = atr_v[i]

        tb  = m30_bias_at(dt)
        signal = 0

        # S1: Fast EMA cross
        if ef2 <= em2 and ef1 > em1 and c1 > es1 and SC_RSI_BULL < r1 < SC_RSI_OB and (not tb or tb==1):
            signal = 1
        elif ef2 >= em2 and ef1 < em1 and c1 < es1 and SC_RSI_OS < r1 < SC_RSI_BEAR and (not tb or tb==-1):
            signal = -1

        # S2: RSI 50 cross + MACD flip
        if signal == 0:
            if r2 < 50 <= r1 and r1 < SC_RSI_OB and mh2 < 0 and mh1 > 0 and c1 > es1 and (not tb or tb==1):
                signal = 1
            elif r2 > 50 >= r1 and r1 > SC_RSI_OS and mh2 > 0 and mh1 < 0 and c1 < es1 and (not tb or tb==-1):
                signal = -1

        # S3: Stoch reversal
        if signal == 0:
            if sk2 < SC_STOCH_OS and sk1 >= SC_STOCH_OS and sk1 > sd1 and r1 > SC_RSI_OS and mh1 > mh2:
                signal = 1
            elif sk2 > SC_STOCH_OB and sk1 <= SC_STOCH_OB and sk1 < sd1 and r1 < SC_RSI_OB and mh1 < mh2:
                signal = -1

        # S4: BB mean reversion
        if signal == 0:
            buf = a * SC_BB_TOUCH
            if l1 <= bbl+buf and c1 > bbl and c1 > o1 and sk1 < SC_STOCH_MOS and r1 > SC_RSI_OS and tb != -1:
                signal = 1
            elif h1_ >= bbu-buf and c1 < bbu and c1 < o1 and sk1 > SC_STOCH_MOB and r1 < SC_RSI_OB and tb != 1:
                signal = -1

        # S5: Bar breakout
        if signal == 0:
            spread_val = SPREAD_POINTS * TICK_SIZE
            ask_live = bar.close + spread_val/2; bid_live = bar.close - spread_val/2
            buf = a * 0.1
            if ask_live > h2+buf and ef1 > em1 > es1 and mh1 > 0 and r1 > 50 and r1 < SC_RSI_OB and (not tb or tb==1):
                signal = 1
            elif bid_live < l2-buf and ef1 < em1 < es1 and mh1 < 0 and r1 < 50 and r1 > SC_RSI_OS and (not tb or tb==-1):
                signal = -1

        if signal == 1  and sk1 > SC_STOCH_OB: signal = 0
        if signal == -1 and sk1 < SC_STOCH_OS: signal = 0
        if signal == 0: continue

        spread_val = SPREAD_POINTS * TICK_SIZE
        entry = (bar.close + spread_val/2) if signal == 1 else (bar.close - spread_val/2)
        sl  = entry - a * SC_ATR_SL  * signal
        tp1 = entry + a * SC_ATR_TP1 * signal
        tp2 = entry + a * SC_ATR_TP2 * signal

        if abs(entry - sl) < 0.02:
            sl = entry - 0.02 * signal

        lots = calc_lots(entry, sl, balance, SC_RISK_PCT, SC_MIN_LOT, SC_MAX_LOT)
        pos  = Position(signal, entry, sl, tp1, tp2, lots, dt)
        open_pos.append(pos)
        day_trades += 1; hour_trades += 1; last_trade_bar = i

    if m5_bars:
        lb = m5_bars[-1]
        for pos in list(open_pos):
            balance += pos.close(lb.close, lb.dt, 'EOT')
            trades.append(pos)

    return trades, equity_curve, balance, peak_eq, max_dd

# ─────────────────────────────────────────────────────────────────────────────
# STATISTICS
# ─────────────────────────────────────────────────────────────────────────────
def compute_stats(trades, equity_curve, final_balance, peak_eq, max_dd, bars_per_day):
    if not trades: return {}
    pnls   = [t.pnl for t in trades]
    wins   = [p for p in pnls if p > 0]
    losses = [p for p in pnls if p < 0]

    gross_profit = sum(wins)   if wins   else 0
    gross_loss   = sum(losses) if losses else 0

    # Monthly breakdown
    monthly = {}
    for t in trades:
        if t.close_dt:
            key = t.close_dt.strftime('%Y-%m')
            monthly.setdefault(key, []).append(t.pnl)

    # Sharpe (annualised from daily equity returns)
    eq_vals = [v for _, v in equity_curve]
    daily_rets = []
    for j in range(bars_per_day, len(eq_vals), bars_per_day):
        prev = eq_vals[j-bars_per_day]
        if prev > 0:
            daily_rets.append((eq_vals[j] - prev) / prev)
    sharpe = 0.0
    if len(daily_rets) > 5:
        mu = statistics.mean(daily_rets)
        sd = statistics.stdev(daily_rets)
        sharpe = (mu / sd * math.sqrt(252)) if sd > 0 else 0

    # Max consecutive loss
    max_cw = max_cl = cw = cl = 0
    for p in pnls:
        if p > 0: cw+=1; cl=0
        else:     cl+=1; cw=0
        max_cw = max(max_cw, cw); max_cl = max(max_cl, cl)

    # Trade durations
    durs = [(t.close_dt - t.open_dt).total_seconds()/3600
            for t in trades if t.close_dt and t.open_dt]
    avg_dur = statistics.mean(durs) if durs else 0

    # Win by reason
    by_reason = {}
    for t in trades:
        r = t.close_reason
        by_reason.setdefault(r, []).append(t.pnl)

    return {
        'total_trades'    : len(trades),
        'wins'            : len(wins),
        'losses'          : len(losses),
        'win_rate'        : len(wins)/len(trades)*100,
        'gross_profit'    : gross_profit,
        'gross_loss'      : gross_loss,
        'net_pnl'         : sum(pnls),
        'net_return_pct'  : sum(pnls)/INITIAL_BALANCE*100,
        'profit_factor'   : abs(gross_profit/gross_loss) if gross_loss else float('inf'),
        'expectancy'      : statistics.mean(pnls),
        'avg_win'         : statistics.mean(wins)   if wins   else 0,
        'avg_loss'        : statistics.mean(losses) if losses else 0,
        'max_win'         : max(pnls),
        'max_loss'        : min(pnls),
        'max_dd'          : max_dd,
        'sharpe'          : sharpe,
        'avg_dur_hr'      : avg_dur,
        'max_cw'          : max_cw,
        'max_cl'          : max_cl,
        'final_balance'   : final_balance,
        'monthly'         : monthly,
        'by_reason'       : by_reason,
    }

# ─────────────────────────────────────────────────────────────────────────────
# ASCII EQUITY CURVE
# ─────────────────────────────────────────────────────────────────────────────
def ascii_equity(equity_curve, width=68, height=14):
    if len(equity_curve) < 2: return "  (no data)"
    vals = [v for _, v in equity_curve]
    step = max(1, len(vals)//width)
    sampled = vals[::step][:width]
    lo = min(sampled); hi = max(sampled)
    rng = hi - lo if hi != lo else 1
    rows = []
    for row in range(height, -1, -1):
        thresh = lo + rng * row / height
        line = ''.join('█' if v >= thresh else ' ' for v in sampled)
        rows.append(f"  ${thresh:>9,.0f} |{line}|")
    rows.append(f"            +{'-'*len(sampled)}+")
    return '\n'.join(rows)

# ─────────────────────────────────────────────────────────────────────────────
# REPORT
# ─────────────────────────────────────────────────────────────────────────────
def print_report(sw_trades, sw_stats, sw_eq, sc_trades, sc_stats, sc_eq, out):
    def p(s=''): out.append(s); print(s)

    p("=" * 78)
    p("  OIL EA BACKTEST — REAL BRENT HISTORICAL DATA")
    p("  Source: MT4 broker export (Brent crude oil)")
    p(f"  Initial balance: ${INITIAL_BALANCE:,.0f}  |  Spread: {SPREAD_POINTS} pts ($0.03/bbl)")
    p("=" * 78)

    for label, trades, stats, eq in [
        ("SWING EA — Brent Oil Trader Pro v4.00", sw_trades, sw_stats, sw_eq),
        ("SCALPER EA — Oil Scalper Pro v1.00",   sc_trades, sc_stats, sc_eq),
    ]:
        if not eq: p(f"\n  {label}: no data."); continue
        p(); p("─" * 78); p(f"  {label}"); p("─" * 78)
        if not stats: p("  No closed trades."); continue

        period_start = eq[0][0].strftime('%Y-%m-%d')
        period_end   = eq[-1][0].strftime('%Y-%m-%d')
        p(f"  Period          : {period_start} → {period_end}")
        p(f"  Final Balance   : ${stats['final_balance']:>10,.2f}")
        p(f"  Net P&L         : ${stats['net_pnl']:>+10,.2f}")
        p(f"  Total Return    : {stats['net_return_pct']:>+8.2f}%")
        p(f"  Max Drawdown    : {stats['max_dd']:>8.2f}%")
        p(f"  Sharpe Ratio    : {stats['sharpe']:>8.2f}")
        p()
        p(f"  Total Trades    : {stats['total_trades']:>5}")
        p(f"  Winning Trades  : {stats['wins']:>5}   ({stats['win_rate']:.1f}%)")
        p(f"  Losing Trades   : {stats['losses']:>5}   ({100-stats['win_rate']:.1f}%)")
        p(f"  Profit Factor   : {stats['profit_factor']:>8.2f}")
        p(f"  Expectancy/trade: ${stats['expectancy']:>+8.2f}")
        p()
        p(f"  Gross Profit    : ${stats['gross_profit']:>+10,.2f}")
        p(f"  Gross Loss      : ${stats['gross_loss']:>+10,.2f}")
        p(f"  Avg Win         : ${stats['avg_win']:>+8.2f}")
        p(f"  Avg Loss        : ${stats['avg_loss']:>+8.2f}")
        p(f"  Win/Loss Ratio  : {abs(stats['avg_win']/stats['avg_loss']) if stats['avg_loss'] else 0:>8.2f}x")
        p(f"  Largest Win     : ${stats['max_win']:>+8.2f}")
        p(f"  Largest Loss    : ${stats['max_loss']:>+8.2f}")
        p(f"  Max Consec Wins : {stats['max_cw']:>5}")
        p(f"  Max Consec Loss : {stats['max_cl']:>5}")
        p(f"  Avg Trade Dur   : {stats['avg_dur_hr']:>6.1f} hrs")
        p()

        # Exit reason breakdown
        p("  EXIT REASON BREAKDOWN:")
        for reason, pnls in sorted(stats['by_reason'].items()):
            w = sum(1 for x in pnls if x > 0)
            p(f"    {reason:<8}: {len(pnls):>4} trades | {w:>3} wins | "
              f"total ${sum(pnls):>+8.2f} | avg ${statistics.mean(pnls):>+7.2f}")

        p()
        # Monthly breakdown
        p("  MONTHLY P&L:")
        for month in sorted(stats['monthly'].keys()):
            pnls = stats['monthly'][month]
            total = sum(pnls); wins = sum(1 for x in pnls if x > 0)
            bar_len = min(int(abs(total)/10), 30)
            bar_chr = '█' * bar_len
            sign = '+' if total >= 0 else '-'
            p(f"    {month}: {len(pnls):>3} trades | {wins:>2}W/{len(pnls)-wins:>2}L | "
              f"${total:>+8.2f}  {bar_chr}")

        p()
        p("  EQUITY CURVE:")
        p(ascii_equity(eq))

        # Last 20 trades
        p()
        p("  LAST 20 CLOSED TRADES:")
        p(f"  {'#':>5}  {'Dir':>4}  {'Opened':>16}  {'Entry':>7}  {'SL':>7}  "
          f"{'TP2':>7}  {'Closed':>7}  {'P&L':>9}  Reason")
        p("  " + "-"*88)
        show = trades[-20:] if len(trades) >= 20 else trades
        for t in show:
            d   = "BUY" if t.dir == 1 else "SEL"
            od  = t.open_dt.strftime('%Y-%m-%d %H:%M') if t.open_dt else '—'
            cpx = f"${t.close_px:.2f}" if t.close_px else '—'
            p(f"  {t.id:>5}  {d:>4}  {od:>16}  "
              f"${t.entry:>6.2f}  ${t.sl:>6.2f}  ${t.tp2:>6.2f}  "
              f"{cpx:>7}  ${t.pnl:>+8.2f}  {t.close_reason}")

    # Side-by-side comparison
    p(); p("─" * 78); p("  SIDE-BY-SIDE COMPARISON"); p("─" * 78)
    sw, sc = sw_stats, sc_stats
    if sw and sc:
        fmt = "  {:<24} {:>20}  {:>20}"
        p(fmt.format("Metric", "Swing EA (H1, 4yr)", "Scalper (M5, 9mo)"))
        p("  " + "-"*66)
        def row(label, sw_val, sc_val):
            p(fmt.format(label, sw_val, sc_val))
        row("Period",
            f"{sw_eq[0][0].strftime('%b %Y')}–{sw_eq[-1][0].strftime('%b %Y')}",
            f"{sc_eq[0][0].strftime('%b %Y')}–{sc_eq[-1][0].strftime('%b %Y')}")
        row("Final Balance",   f"${sw['final_balance']:,.2f}", f"${sc['final_balance']:,.2f}")
        row("Net Return",      f"{sw['net_return_pct']:+.2f}%", f"{sc['net_return_pct']:+.2f}%")
        row("Max Drawdown",    f"{sw['max_dd']:.2f}%",       f"{sc['max_dd']:.2f}%")
        row("Sharpe Ratio",    f"{sw['sharpe']:.2f}",        f"{sc['sharpe']:.2f}")
        row("Total Trades",    str(sw['total_trades']),       str(sc['total_trades']))
        row("Win Rate",        f"{sw['win_rate']:.1f}%",     f"{sc['win_rate']:.1f}%")
        row("Profit Factor",   f"{sw['profit_factor']:.2f}", f"{sc['profit_factor']:.2f}")
        row("Expectancy/trade",f"${sw['expectancy']:+.2f}",  f"${sc['expectancy']:+.2f}")
        row("Avg Win",         f"${sw['avg_win']:+.2f}",     f"${sc['avg_win']:+.2f}")
        row("Avg Loss",        f"${sw['avg_loss']:+.2f}",    f"${sc['avg_loss']:+.2f}")
        row("Win/Loss Ratio",
            f"{abs(sw['avg_win']/sw['avg_loss']) if sw['avg_loss'] else 0:.2f}x",
            f"{abs(sc['avg_win']/sc['avg_loss']) if sc['avg_loss'] else 0:.2f}x")
        row("Max Consec Loss", str(sw['max_cl']),             str(sc['max_cl']))
        row("Avg Trade Dur",   f"{sw['avg_dur_hr']:.1f}h",   f"{sc['avg_dur_hr']:.1f}h")

    p(); p("=" * 78)

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
def main():
    print("Loading real Brent OHLCV data...")
    h1_bars  = load_csv(PATH_H1)
    h4_bars  = load_csv(PATH_H4)
    m5_bars  = load_csv(PATH_M5)
    m15_bars = load_csv(PATH_M15)

    # Resample M5 → M30 for scalper trend filter
    m30_bars = resample(m5_bars, 30)

    print(f"\nRunning Swing EA backtest (H1 + H4)...")
    sw_trades, sw_eq, sw_bal, sw_peak, sw_dd = backtest_swing(h1_bars, h4_bars)
    sw_stats = compute_stats(sw_trades, sw_eq, sw_bal, sw_peak, sw_dd, bars_per_day=10)
    print(f"  → {len(sw_trades)} trades")

    print(f"\nRunning Scalper EA backtest (M5 + M30)...")
    sc_trades, sc_eq, sc_bal, sc_peak, sc_dd = backtest_scalper(m5_bars, m30_bars)
    sc_stats = compute_stats(sc_trades, sc_eq, sc_bal, sc_peak, sc_dd, bars_per_day=120)
    print(f"  → {len(sc_trades)} trades")

    out_lines = []
    print("\n" + "="*78)
    print_report(sw_trades, sw_stats, sw_eq, sc_trades, sc_stats, sc_eq, out_lines)

    report_path = '/home/user/Jmalhem/backtest_real_report.txt'
    with open(report_path, 'w') as f:
        f.write('\n'.join(out_lines))
    print(f"\nReport saved: {report_path}")

    csv_path = '/home/user/Jmalhem/backtest_real_trades.csv'
    with open(csv_path, 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['EA','ID','Dir','Open_DT','Entry','SL','TP2',
                    'Close_DT','Close_Px','Lots','PnL','Reason'])
        for t in sw_trades:
            w.writerow(['Swing', t.id, 'BUY' if t.dir==1 else 'SELL',
                        t.open_dt, round(t.entry,2), round(t.sl,2), round(t.tp2,2),
                        t.close_dt, round(t.close_px,2) if t.close_px else '',
                        t.orig_lots, round(t.pnl,2), t.close_reason])
        for t in sc_trades:
            w.writerow(['Scalper', t.id, 'BUY' if t.dir==1 else 'SELL',
                        t.open_dt, round(t.entry,2), round(t.sl,2), round(t.tp2,2),
                        t.close_dt, round(t.close_px,2) if t.close_px else '',
                        t.orig_lots, round(t.pnl,2), t.close_reason])
    print(f"Trades CSV: {csv_path}")

if __name__ == '__main__':
    main()
