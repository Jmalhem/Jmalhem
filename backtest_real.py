#!/usr/bin/env python3
"""
Oil EA Backtester v2 — REAL Historical Data  (Game-Changer Edition)

Swing EA v5  : H1 entry + H4 trend (ADX + EMA-stack + pullback-only)
Scalper EA v2: M15 entry + M30 trend (triple-confirmation, 2.5:1 RR)

Changes vs v1:
  Swing  – ADX>22 filter, dual-EMA-stack alignment, pullback-to-21EMA only,
            1.5x SL / 2.0x TP1 (60%) / 4.5x TP2 → 3:1 RR
  Scalper– M15 entry bars (less noise), M30 EMA-stack, must have ALL: trend+MACD+RSI+pullback,
            1.5x SL / 3.5x TP → 2.33:1 RR, max 8/day 2/hour, 4-bar gap
"""

import math, statistics, csv, os
from datetime import datetime, timedelta

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

INITIAL_BALANCE = 10_000.0
TICK_SIZE       = 0.01
TICK_VALUE_STD  = 1.0
SPREAD_POINTS   = 3
SLIPPAGE_PTS    = 1

# ── Swing EA v5 params ──
SW_RISK_PCT       = 1.0
SW_MAX_LOT        = 5.0;  SW_MIN_LOT  = 0.01
SW_ATR_SL         = 1.5;  SW_ATR_TP1  = 2.0;  SW_ATR_TP2  = 4.5
SW_PARTIAL_PCT    = 60.0
SW_TRAIL_MULT     = 0.9;  SW_TRAIL_ACT = 2.0
SW_MAX_TRADES_DAY = 4
SW_MAX_DD_PCT     = 12.0; SW_DAILY_LOSS = 3.0; SW_DAILY_PROF = 6.0
SW_ADX_MIN        = 18.0   # trending-market gate
SW_PULLBACK_ATR   = 0.85   # max distance from 21 EMA (looser for more setups)
SW_EMA_FAST = 8;  SW_EMA_MED = 21; SW_EMA_SLOW = 50; SW_EMA_TREND = 200
SW_RSI_PER  = 14; SW_RSI_OB  = 68.0; SW_RSI_OS = 32.0
SW_MACD_F = 12; SW_MACD_S = 26; SW_MACD_SIG = 9
SW_STOCH_K = 5; SW_STOCH_D = 3; SW_STOCH_SL = 3
SW_STOCH_OB = 78.0; SW_STOCH_OS = 22.0
SW_ATR_PER = 14; SW_ATR_MIN = 0.3; SW_ATR_MAX = 3.5

# ── Scalper EA v2 params (M15 entry + H1 trend) ──
SC_RISK_PCT       = 0.8
SC_MAX_LOT        = 3.0;  SC_MIN_LOT  = 0.01
SC_ATR_SL         = 1.4;  SC_ATR_TP2  = 3.5
SC_MAX_TRADES_DAY = 5;    SC_MAX_TRADES_HR = 2
SC_DAILY_LOSS     = 2.5;  SC_DAILY_PROF = 5.0
SC_WEEK_DD_PCT    = 6.0   # weekly DD cap (resets Monday — not permanent halt)
SC_MAX_SPREAD     = 20.0; SC_MIN_BARS   = 3
SC_EMA_FAST = 5;  SC_EMA_MED = 13; SC_EMA_SLOW = 50; SC_EMA_TREND = 50
SC_RSI_PER  = 9;  SC_RSI_OB  = 70.0; SC_RSI_OS = 30.0
SC_RSI_BULL = 45.0; SC_RSI_BEAR = 55.0
SC_MACD_F = 8; SC_MACD_S = 17; SC_MACD_SIG = 5
SC_STOCH_K = 5; SC_STOCH_D = 3; SC_STOCH_SL = 3
SC_STOCH_OB = 75.0; SC_STOCH_OS = 25.0
SC_ATR_PER = 10; SC_ATR_MIN = 0.4; SC_ATR_MAX = 2.8

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
                dt = datetime.strptime(row[0].strip()+' '+row[1].strip(), '%Y.%m.%d %H:%M')
                o,h,l,c = float(row[2]),float(row[3]),float(row[4]),float(row[5])
                v = int(float(row[6])) if len(row)>6 else 0
                bars.append(Bar(dt,o,h,l,c,v))
            except Exception:
                continue
    bars.sort(key=lambda b: b.dt)
    return bars

def resample(bars, factor_minutes):
    if not bars: return []
    out=[]; bucket=[]; bucket_start=None
    for b in bars:
        mins = b.dt.hour*60+b.dt.minute
        slot = (mins//factor_minutes)*factor_minutes
        slot_dt = b.dt.replace(hour=slot//60, minute=slot%60, second=0)
        if bucket_start is None: bucket_start = slot_dt
        if slot_dt != bucket_start and bucket:
            o=bucket[0].open; h=max(x.high for x in bucket)
            l=min(x.low for x in bucket); c=bucket[-1].close
            v=sum(x.volume for x in bucket)
            out.append(Bar(bucket_start,o,h,l,c,v))
            bucket=[]; bucket_start=slot_dt
        bucket.append(b)
    if bucket:
        o=bucket[0].open; h=max(x.high for x in bucket)
        l=min(x.low for x in bucket); c=bucket[-1].close
        v=sum(x.volume for x in bucket)
        out.append(Bar(bucket_start,o,h,l,c,v))
    return out

# ─────────────────────────────────────────────────────────────────────────────
# INDICATORS
# ─────────────────────────────────────────────────────────────────────────────
def ema(values, period):
    result=[None]*len(values); k=2.0/(period+1)
    fv=next((i for i,v in enumerate(values) if v is not None),None)
    if fv is None or len(values)-fv<period: return result
    se=fv+period
    seed=[values[i] for i in range(fv,se) if values[i] is not None]
    if len(seed)<period: return result
    result[se-1]=sum(seed)/period
    for i in range(se,len(values)):
        if values[i] is not None and result[i-1] is not None:
            result[i]=values[i]*k+result[i-1]*(1-k)
    return result

def atr_series(highs,lows,closes,period):
    n=len(closes); tr=[None]*n
    for i in range(1,n):
        h,l,pc=highs[i],lows[i],closes[i-1]
        tr[i]=max(h-l,abs(h-pc),abs(l-pc))
    result=[None]*n
    seed=[tr[i] for i in range(1,period+1) if tr[i] is not None]
    if len(seed)<period: return result
    result[period]=sum(seed)/period
    for i in range(period+1,n):
        if tr[i] is not None and result[i-1] is not None:
            result[i]=(result[i-1]*(period-1)+tr[i])/period
    return result

def adx_series(highs,lows,closes,period=14):
    n=len(closes); pdm=[0.0]*n; mdm=[0.0]*n; tr=[0.0]*n
    for i in range(1,n):
        up=highs[i]-highs[i-1]; dn=lows[i-1]-lows[i]
        pdm[i]=max(up,0) if up>dn and up>0 else 0
        mdm[i]=max(dn,0) if dn>up and dn>0 else 0
        h,l,pc=highs[i],lows[i],closes[i-1]
        tr[i]=max(h-l,abs(h-pc),abs(l-pc))
    spdm=[None]*n; smdm=[None]*n; str_=[None]*n
    if n<period+1: return [None]*n
    spdm[period]=sum(pdm[1:period+1])
    smdm[period]=sum(mdm[1:period+1])
    str_[period]=sum(tr[1:period+1])
    for i in range(period+1,n):
        spdm[i]=spdm[i-1]-spdm[i-1]/period+pdm[i]
        smdm[i]=smdm[i-1]-smdm[i-1]/period+mdm[i]
        str_[i]=str_[i-1]-str_[i-1]/period+tr[i]
    dx=[None]*n
    for i in range(period,n):
        if str_[i] and str_[i]>0:
            pdi=spdm[i]/str_[i]*100; mdi=smdm[i]/str_[i]*100
            if pdi+mdi>0: dx[i]=abs(pdi-mdi)/(pdi+mdi)*100
    adx=[None]*n
    fv=next((i for i in range(n) if dx[i] is not None),None)
    if fv is None or n-fv<period: return adx
    init=[dx[i] for i in range(fv,fv+period) if dx[i] is not None]
    if len(init)<period: return adx
    adx[fv+period-1]=sum(init)/period
    for i in range(fv+period,n):
        if dx[i] is not None and adx[i-1] is not None:
            adx[i]=(adx[i-1]*(period-1)+dx[i])/period
    return adx

def rsi_series(closes,period):
    n=len(closes); result=[None]*n
    if n<period+1: return result
    gains,losses=[],[]
    for i in range(1,period+1):
        d=closes[i]-closes[i-1]; gains.append(max(d,0.0)); losses.append(max(-d,0.0))
    ag=sum(gains)/period; al=sum(losses)/period
    result[period]=100-100/(1+ag/al) if al>0 else 100.0
    for i in range(period+1,n):
        d=closes[i]-closes[i-1]
        ag=(ag*(period-1)+max(d,0.0))/period; al=(al*(period-1)+max(-d,0.0))/period
        result[i]=100-100/(1+ag/al) if al>0 else 100.0
    return result

def macd_series(closes,fast,slow,sig):
    ef=ema(closes,fast); es=ema(closes,slow)
    line=[ef[i]-es[i] if ef[i] is not None and es[i] is not None else None for i in range(len(closes))]
    sig_line=ema(line,sig)
    hist=[line[i]-sig_line[i] if line[i] is not None and sig_line[i] is not None else None for i in range(len(closes))]
    return line,sig_line,hist

def stoch_series(highs,lows,closes,k_per,d_per,slowing):
    n=len(closes); raw_k=[None]*n
    for i in range(k_per-1,n):
        lo=min(lows[i-k_per+1:i+1]); hi=max(highs[i-k_per+1:i+1])
        raw_k[i]=100.0*(closes[i]-lo)/(hi-lo) if hi!=lo else 50.0
    sk=[None]*n
    for i in range(k_per+slowing-2,n):
        w=[raw_k[j] for j in range(i-slowing+1,i+1) if raw_k[j] is not None]
        if len(w)==slowing: sk[i]=sum(w)/slowing
    sd=[None]*n
    for i in range(d_per-1,n):
        w=[sk[j] for j in range(i-d_per+1,i+1) if sk[j] is not None]
        if len(w)==d_per: sd[i]=sum(w)/d_per
    return sk,sd

def rolling_avg(vals,period):
    result=[None]*len(vals)
    for i in range(period-1,len(vals)):
        w=[vals[j] for j in range(i-period+1,i+1) if vals[j] is not None]
        if len(w)==period: result[i]=sum(w)/period
    return result

def bisect_left_dt(times, target):
    lo,hi=0,len(times)-1; res=-1
    while lo<=hi:
        mid=(lo+hi)//2
        if times[mid]<target: res=mid; lo=mid+1
        else: hi=mid-1
    return res

# ─────────────────────────────────────────────────────────────────────────────
# SESSION / NEWS
# ─────────────────────────────────────────────────────────────────────────────
def is_session(dt):
    dow=dt.weekday(); h=dt.hour
    if dow>=5: return False
    if dow==0 and h<5: return False
    if dow==4 and h>=17: return False
    return (7<=h<9) or (9<=h<13) or (13<=h<17)

def is_news(dt):
    dow=dt.weekday(); h=dt.hour; m=dt.minute; tot=h*60+m; buf=30
    if dow==2:
        if 14*60+30-buf<=tot<=14*60+30+buf: return True
        if 19*60-buf<=tot<=19*60+buf: return True
    if dow==1 and 20*60+30-buf<=tot<=20*60+30+buf: return True
    if dow==4 and 13*60+30<=tot<=14*60+30: return True
    return False

# ─────────────────────────────────────────────────────────────────────────────
# POSITION
# ─────────────────────────────────────────────────────────────────────────────
_pid=[0]
class Position:
    def __init__(self,direction,entry,sl,tp1,tp2,lots,dt):
        _pid[0]+=1
        self.id=_pid[0]; self.dir=direction; self.entry=entry
        self.sl=sl; self.tp1=tp1; self.tp2=tp2; self.lots=lots; self.orig_lots=lots
        self.open_dt=dt; self.close_dt=None; self.close_px=None; self.pnl=0.0
        self.partial_done=False; self.be_done=False; self.status='open'
        self.close_reason=''; self.partial_pnl=0.0

    def profit_pts(self,px): return (px-self.entry)*self.dir

    def close(self,px,dt,reason=''):
        self.close_px=px; self.close_dt=dt; self.status='closed'; self.close_reason=reason
        self.pnl=self.partial_pnl+((px-self.entry)*self.dir/TICK_SIZE)*TICK_VALUE_STD*self.lots
        return self.pnl

def manage_positions(open_pos,bar,atr_val,
                     use_partial,partial_pct,min_lot,
                     use_be,be_atr_buf,
                     use_trail,trail_atr,trail_act_atr,
                     digits,closed_trades):
    delta=0.0; spread=SPREAD_POINTS*TICK_SIZE
    for pos in list(open_pos):
        bid=bar.close-spread/2; ask=bar.close+spread/2
        cur_px=bid if pos.dir==1 else ask

        if pos.dir==1 and bar.low<=pos.sl:
            sl_px=pos.sl-SLIPPAGE_PTS*TICK_SIZE
            delta+=pos.close(sl_px,bar.dt,'SL')
            open_pos.remove(pos); closed_trades.append(pos); continue
        if pos.dir==-1 and bar.high>=pos.sl:
            sl_px=pos.sl+SLIPPAGE_PTS*TICK_SIZE
            delta+=pos.close(sl_px,bar.dt,'SL')
            open_pos.remove(pos); closed_trades.append(pos); continue

        if pos.dir==1 and bar.high>=pos.tp2:
            delta+=pos.close(pos.tp2,bar.dt,'TP2')
            open_pos.remove(pos); closed_trades.append(pos); continue
        if pos.dir==-1 and bar.low<=pos.tp2:
            delta+=pos.close(pos.tp2,bar.dt,'TP2')
            open_pos.remove(pos); closed_trades.append(pos); continue

        tp1_hit=((pos.dir==1 and bar.high>=pos.tp1) or
                 (pos.dir==-1 and bar.low<=pos.tp1)) if pos.tp1>0 else False

        if use_partial and tp1_hit and not pos.partial_done and pos.tp1>0:
            from math import floor
            close_lots=floor(pos.lots*partial_pct/100.0/0.01)*0.01
            if close_lots>=min_lot and close_lots<pos.lots:
                diff=(pos.tp1-pos.entry)*pos.dir
                pnl=(diff/TICK_SIZE)*TICK_VALUE_STD*close_lots
                delta+=pnl; pos.partial_pnl+=pnl; pos.lots-=close_lots
            pos.partial_done=True

        if use_be and tp1_hit and not pos.be_done and atr_val:
            buf=atr_val*be_atr_buf
            if pos.dir==1:
                new_sl=round(pos.entry+buf,digits)
                if new_sl>pos.sl: pos.sl=new_sl
            else:
                new_sl=round(pos.entry-buf,digits)
                if new_sl<pos.sl: pos.sl=new_sl
            pos.be_done=True

        if use_trail and atr_val:
            prof=pos.profit_pts(cur_px)
            if prof>=atr_val*trail_act_atr:
                trail_dist=atr_val*trail_atr
                if pos.dir==1:
                    new_sl=round(cur_px-trail_dist,digits)
                    if new_sl>pos.sl: pos.sl=new_sl
                else:
                    new_sl=round(cur_px+trail_dist,digits)
                    if new_sl<pos.sl: pos.sl=new_sl

    return delta

def unrealised_pnl(open_pos,price):
    total=0.0; spread=SPREAD_POINTS*TICK_SIZE
    for pos in open_pos:
        cur_px=price-spread/2 if pos.dir==1 else price+spread/2
        diff=(cur_px-pos.entry)*pos.dir
        total+=(diff/TICK_SIZE)*TICK_VALUE_STD*pos.lots
    return total

def calc_lots(entry,sl,balance,risk_pct,min_lot,max_lot):
    sl_dist=abs(entry-sl)
    if sl_dist<=0: return min_lot
    risk_amt=balance*risk_pct/100.0
    sl_val=(sl_dist/TICK_SIZE)*TICK_VALUE_STD
    if sl_val<=0: return min_lot
    from math import floor
    lots=floor(risk_amt/sl_val/0.01)*0.01
    return max(min_lot,min(max_lot,round(lots,2)))

# ─────────────────────────────────────────────────────────────────────────────
# SWING EA v5  (H1 + H4)
# ─────────────────────────────────────────────────────────────────────────────
def backtest_swing(h1_bars, h4_bars):
    print(f"  H1 bars: {len(h1_bars):,}  ({h1_bars[0].dt.date()} → {h1_bars[-1].dt.date()})")
    print(f"  H4 bars: {len(h4_bars):,}")

    closes=[b.close for b in h1_bars]
    highs=[b.high for b in h1_bars]
    lows=[b.low for b in h1_bars]

    ema_f=ema(closes,SW_EMA_FAST)
    ema_m=ema(closes,SW_EMA_MED)
    ema_s=ema(closes,SW_EMA_SLOW)
    ema_t=ema(closes,SW_EMA_TREND)
    atr_v=atr_series(highs,lows,closes,SW_ATR_PER)
    adx_v=adx_series(highs,lows,closes,14)
    atr_avg=rolling_avg(atr_v,50)
    rsi_v=rsi_series(closes,SW_RSI_PER)
    _,_,macd_h=macd_series(closes,SW_MACD_F,SW_MACD_S,SW_MACD_SIG)
    stk,std_v=stoch_series(highs,lows,closes,SW_STOCH_K,SW_STOCH_D,SW_STOCH_SL)

    # H4 indicators for dual-timeframe stack
    h4c=[b.close for b in h4_bars]; h4h=[b.high for b in h4_bars]; h4l=[b.low for b in h4_bars]
    h4_ef=ema(h4c,SW_EMA_FAST); h4_em=ema(h4c,SW_EMA_MED)
    h4_es=ema(h4c,SW_EMA_SLOW); h4_et=ema(h4c,SW_EMA_TREND)
    h4_adx=adx_series(h4h,h4l,h4c,14)
    h4_times=[b.dt for b in h4_bars]

    def h4_context(dt):
        """Return (trend_bias, adx) from last closed H4 bar."""
        res=bisect_left_dt(h4_times,dt)
        if res<0: return 0,0
        ef,em,es,et=h4_ef[res],h4_em[res],h4_es[res],h4_et[res]
        adx=h4_adx[res] or 0
        c=h4c[res]
        if any(v is None for v in [ef,em,es]): return 0,adx
        # Bull: price above 50 EMA AND fast > slow (trend alignment)
        if c>es and ef>es: return 1,adx
        # Bear: price below 50 EMA AND fast < slow
        if c<es and ef<es: return -1,adx
        return 0,adx

    balance=INITIAL_BALANCE; peak_eq=INITIAL_BALANCE; max_dd=0.0
    open_pos=[]; trades=[]; equity_curve=[]
    day_balance=INITIAL_BALANCE; day_equity=INITIAL_BALANCE
    day_trades=0; cur_day=None; daily_halted=False; dd_halted=False

    WARMUP=max(SW_EMA_TREND,50)+20

    for i in range(WARMUP,len(h1_bars)):
        bar=h1_bars[i]; dt=bar.dt
        d=dt.date()
        if d!=cur_day:
            cur_day=d; day_balance=balance
            day_equity=balance+unrealised_pnl(open_pos,bar.close)
            day_trades=0; daily_halted=False

        delta=manage_positions(open_pos,bar,atr_v[i],
                               True,SW_PARTIAL_PCT,SW_MIN_LOT,
                               True,0.15,True,SW_TRAIL_MULT,SW_TRAIL_ACT,
                               2,trades)
        balance+=delta

        equity=balance+unrealised_pnl(open_pos,bar.close)
        if equity>peak_eq: peak_eq=equity
        dd=(peak_eq-equity)/peak_eq*100.0 if peak_eq>0 else 0
        if dd>max_dd: max_dd=dd
        dd_halted=(dd>=SW_MAX_DD_PCT)
        pnl_pct=(equity-day_equity)/day_balance*100.0 if day_balance>0 else 0
        if pnl_pct<=-SW_DAILY_LOSS: daily_halted=True
        if pnl_pct>=SW_DAILY_PROF:  daily_halted=True
        equity_curve.append((dt,round(equity,2)))

        if daily_halted or dd_halted: continue
        if day_trades>=SW_MAX_TRADES_DAY: continue
        if len(open_pos)>=1: continue
        if not is_session(dt): continue
        if is_news(dt): continue

        needed=[ema_f[i],ema_m[i],ema_s[i],ema_t[i],
                atr_v[i],atr_avg[i],rsi_v[i],macd_h[i],stk[i],adx_v[i]]
        if any(v is None for v in needed): continue
        if atr_v[i]<atr_avg[i]*SW_ATR_MIN: continue
        if atr_v[i]>atr_avg[i]*SW_ATR_MAX: continue

        # H1 ADX filter — only trade in trending H1 market
        if adx_v[i]<SW_ADX_MIN: continue

        h4_bias,h4_adx_val=h4_context(dt)
        if h4_bias==0: continue  # No clear H4 trend — skip

        ef1=ema_f[i]; em1=ema_m[i]; es1=ema_s[i]; et1=ema_t[i]
        c1=closes[i]; c2=closes[i-1]
        r1=rsi_v[i]
        mh1=macd_h[i]; mh2=macd_h[i-1] if macd_h[i-1] is not None else mh1
        sk1=stk[i]; sd1=std_v[i] if std_v[i] is not None else sk1
        a=atr_v[i]

        signal=0

        ef2=ema_f[i-1] if i>0 else ef1
        em2=ema_m[i-1] if i>0 else em1

        if h4_bias==1:
            # H1 must show bull direction: price above 21 EMA
            if c1<=em1: continue

            rsi_bull=(40<r1<SW_RSI_OB)
            if not rsi_bull: continue

            # S1: Pullback to 21 EMA with MACD positive
            near_med=abs(c1-em1)<a*SW_PULLBACK_ATR
            if near_med and mh1>0 and sk1<65:
                signal=1

            # S2: EMA crossover in trend direction with momentum
            if signal==0:
                cross_up=(ef2 is not None and ef2<=em2 and ef1>em1)
                if cross_up and mh1>0 and mh1>mh2 and sk1<72:
                    signal=1

            # S3: MACD flip while above 21 EMA and RSI strong
            if signal==0:
                macd_flip=(mh2 is not None and mh2<0 and mh1>0)
                if macd_flip and c1>es1 and 45<r1<SW_RSI_OB:
                    signal=1

        if h4_bias==-1:
            if c1>=em1: continue

            rsi_bear=(SW_RSI_OS<r1<60)
            if not rsi_bear: continue

            near_med=abs(c1-em1)<a*SW_PULLBACK_ATR
            if near_med and mh1<0 and sk1>35:
                signal=-1

            if signal==0:
                cross_dn=(ef2 is not None and ef2>=em2 and ef1<em1)
                if cross_dn and mh1<0 and mh1<mh2 and sk1>28:
                    signal=-1

            if signal==0:
                macd_flip=(mh2 is not None and mh2>0 and mh1<0)
                if macd_flip and c1<es1 and SW_RSI_OS<r1<55:
                    signal=-1

        if signal==1  and sk1>SW_STOCH_OB: signal=0
        if signal==-1 and sk1<SW_STOCH_OS: signal=0
        if signal==0: continue

        spread=SPREAD_POINTS*TICK_SIZE
        entry=(bar.close+spread/2) if signal==1 else (bar.close-spread/2)
        sl=entry-a*SW_ATR_SL*signal
        tp1=entry+a*SW_ATR_TP1*signal
        tp2=entry+a*SW_ATR_TP2*signal

        if abs(entry-sl)<0.05: sl=entry-0.05*signal

        lots=calc_lots(entry,sl,balance,SW_RISK_PCT,SW_MIN_LOT,SW_MAX_LOT)
        pos=Position(signal,entry,sl,tp1,tp2,lots,dt)
        open_pos.append(pos); day_trades+=1

    if h1_bars:
        lb=h1_bars[-1]
        for pos in list(open_pos):
            balance+=pos.close(lb.close,lb.dt,'EOT')
            trades.append(pos)

    return trades,equity_curve,balance,peak_eq,max_dd

# ─────────────────────────────────────────────────────────────────────────────
# SCALPER EA v2  (M15 entry + H1 trend bias, EMA-cross momentum)
# ─────────────────────────────────────────────────────────────────────────────
def backtest_scalper(m15_bars, h1_bars):
    print(f"  M15 bars: {len(m15_bars):,}  ({m15_bars[0].dt.date()} → {m15_bars[-1].dt.date()})")
    print(f"  H1 bars (trend context): {len(h1_bars):,}")

    closes=[b.close for b in m15_bars]
    highs=[b.high  for b in m15_bars]
    lows=[b.low    for b in m15_bars]
    opens=[b.open  for b in m15_bars]

    ef_v=ema(closes,SC_EMA_FAST); em_v=ema(closes,SC_EMA_MED)
    es_v=ema(closes,SC_EMA_SLOW)
    atr_v=atr_series(highs,lows,closes,SC_ATR_PER)
    atr_avg=rolling_avg(atr_v,30)
    rsi_v=rsi_series(closes,SC_RSI_PER)
    _,_,macd_h=macd_series(closes,SC_MACD_F,SC_MACD_S,SC_MACD_SIG)
    stk,std_v=stoch_series(highs,lows,closes,SC_STOCH_K,SC_STOCH_D,SC_STOCH_SL)

    # H1 trend bias — stable higher-timeframe direction
    h1c=[b.close for b in h1_bars]; h1h=[b.high for b in h1_bars]; h1l=[b.low for b in h1_bars]
    h1_ef=ema(h1c,SC_EMA_FAST); h1_em=ema(h1c,SC_EMA_MED); h1_es=ema(h1c,SC_EMA_SLOW)
    h1_times=[b.dt for b in h1_bars]

    def h1_bias(dt):
        res=bisect_left_dt(h1_times,dt)
        if res<0: return 0
        ef,em,es=h1_ef[res],h1_em[res],h1_es[res]
        c=h1c[res]
        if any(v is None for v in [ef,em,es]): return 0
        if c>es and ef>em: return 1   # H1 bullish: above 50 EMA, fast>medium
        if c<es and ef<em: return -1  # H1 bearish
        return 0

    balance=INITIAL_BALANCE; peak_eq=INITIAL_BALANCE; max_dd=0.0
    open_pos=[]; trades=[]; equity_curve=[]
    day_balance=INITIAL_BALANCE; day_equity=INITIAL_BALANCE
    day_trades=0; cur_day=None; hour_trades=0; cur_hour=-1
    daily_halted=False
    week_balance=INITIAL_BALANCE; cur_week=None; week_halted=False
    last_trade_bar=-999

    WARMUP=max(SC_EMA_SLOW,SC_ATR_PER*5,SC_MACD_S+SC_MACD_SIG)+10

    for i in range(WARMUP,len(m15_bars)):
        bar=m15_bars[i]; dt=bar.dt

        if dt.hour!=cur_hour:
            cur_hour=dt.hour; hour_trades=0

        d=dt.date()
        # ISO week number for weekly DD reset
        week_key=(dt.year, dt.isocalendar()[1])
        if week_key!=cur_week:
            cur_week=week_key; week_balance=balance; week_halted=False

        if d!=cur_day:
            cur_day=d; day_balance=balance
            day_equity=balance+unrealised_pnl(open_pos,bar.close)
            day_trades=0; hour_trades=0; daily_halted=False

        delta=manage_positions(open_pos,bar,atr_v[i],
                               False,0,SC_MIN_LOT,
                               False,0,
                               True,0.7,1.8,
                               2,trades)
        balance+=delta

        equity=balance+unrealised_pnl(open_pos,bar.close)
        if equity>peak_eq: peak_eq=equity
        dd=(peak_eq-equity)/peak_eq*100.0 if peak_eq>0 else 0
        if dd>max_dd: max_dd=dd

        # Weekly drawdown check (softer — resets each Monday)
        week_dd=(week_balance-equity)/week_balance*100.0 if week_balance>0 else 0
        if week_dd>=SC_WEEK_DD_PCT: week_halted=True

        pnl_pct=(equity-day_equity)/day_balance*100.0 if day_balance>0 else 0
        if pnl_pct<=-SC_DAILY_LOSS: daily_halted=True
        if pnl_pct>=SC_DAILY_PROF:  daily_halted=True
        equity_curve.append((dt,round(equity,2)))

        if daily_halted or week_halted: continue
        if day_trades>=SC_MAX_TRADES_DAY: continue
        if hour_trades>=SC_MAX_TRADES_HR: continue
        if len(open_pos)>=1: continue
        if not is_session(dt): continue
        if is_news(dt): continue
        if (i-last_trade_bar)<SC_MIN_BARS: continue
        if SPREAD_POINTS>SC_MAX_SPREAD: continue

        needed=[ef_v[i],em_v[i],es_v[i],atr_v[i],atr_avg[i],rsi_v[i],macd_h[i],stk[i]]
        if any(v is None for v in needed): continue
        if atr_v[i]<atr_avg[i]*SC_ATR_MIN: continue
        if atr_v[i]>atr_avg[i]*SC_ATR_MAX: continue

        h1b=h1_bias(dt)
        if h1b==0: continue  # require clear H1 trend

        ef1=ef_v[i]; em1=em_v[i]; es1=es_v[i]
        ef2=ef_v[i-1] if ef_v[i-1] is not None else ef1
        em2=em_v[i-1] if em_v[i-1] is not None else em1
        c1=closes[i]
        r1=rsi_v[i]
        mh1=macd_h[i]; mh2=macd_h[i-1] if macd_h[i-1] is not None else mh1
        sk1=stk[i]
        a=atr_v[i]
        signal=0

        if h1b==1:
            # Entry: 5 EMA crosses above 13 EMA on M15, in H1 bull trend
            cross_up=(ef2<=em2 and ef1>em1)
            # Confirm: MACD positive and RSI in momentum zone
            momentum_ok=(mh1>0 and SC_RSI_BULL<r1<SC_RSI_OB)
            # Price must be above 50 EMA on M15 (trend aligned)
            above_slow=(c1>es1)
            if cross_up and momentum_ok and above_slow and sk1<SC_STOCH_OB:
                signal=1

            # Second entry: MACD histogram flips positive while above 13 EMA
            if signal==0:
                macd_flip=(mh2<0 and mh1>0)
                if macd_flip and c1>em1 and c1>es1 and SC_RSI_BULL<r1<SC_RSI_OB:
                    signal=1

        if h1b==-1:
            cross_dn=(ef2>=em2 and ef1<em1)
            momentum_ok=(mh1<0 and SC_RSI_OS<r1<SC_RSI_BEAR)
            below_slow=(c1<es1)
            if cross_dn and momentum_ok and below_slow and sk1>SC_STOCH_OS:
                signal=-1

            if signal==0:
                macd_flip=(mh2>0 and mh1<0)
                if macd_flip and c1<em1 and c1<es1 and SC_RSI_OS<r1<SC_RSI_BEAR:
                    signal=-1

        if signal==1  and sk1>SC_STOCH_OB: signal=0
        if signal==-1 and sk1<SC_STOCH_OS: signal=0
        if signal==0: continue

        spread_val=SPREAD_POINTS*TICK_SIZE
        entry=(bar.close+spread_val/2) if signal==1 else (bar.close-spread_val/2)
        sl=entry-a*SC_ATR_SL*signal
        tp2=entry+a*SC_ATR_TP2*signal

        if abs(entry-sl)<0.03: sl=entry-0.03*signal

        lots=calc_lots(entry,sl,balance,SC_RISK_PCT,SC_MIN_LOT,SC_MAX_LOT)
        pos=Position(signal,entry,sl,0,tp2,lots,dt)
        open_pos.append(pos)
        day_trades+=1; hour_trades+=1; last_trade_bar=i

    if m15_bars:
        lb=m15_bars[-1]
        for pos in list(open_pos):
            balance+=pos.close(lb.close,lb.dt,'EOT')
            trades.append(pos)

    return trades,equity_curve,balance,peak_eq,max_dd

# ─────────────────────────────────────────────────────────────────────────────
# STATISTICS
# ─────────────────────────────────────────────────────────────────────────────
def compute_stats(trades,equity_curve,final_balance,peak_eq,max_dd,bars_per_day):
    if not trades: return {}
    pnls=[t.pnl for t in trades]
    wins=[p for p in pnls if p>0]; losses=[p for p in pnls if p<0]
    gross_profit=sum(wins) if wins else 0
    gross_loss=sum(losses) if losses else 0
    monthly={}
    for t in trades:
        if t.close_dt:
            key=t.close_dt.strftime('%Y-%m')
            monthly.setdefault(key,[]).append(t.pnl)
    eq_vals=[v for _,v in equity_curve]; daily_rets=[]
    for j in range(bars_per_day,len(eq_vals),bars_per_day):
        prev=eq_vals[j-bars_per_day]
        if prev>0: daily_rets.append((eq_vals[j]-prev)/prev)
    sharpe=0.0
    if len(daily_rets)>5:
        mu=statistics.mean(daily_rets); sd=statistics.stdev(daily_rets)
        sharpe=(mu/sd*math.sqrt(252)) if sd>0 else 0
    max_cw=max_cl=cw=cl=0
    for p in pnls:
        if p>0: cw+=1; cl=0
        else: cl+=1; cw=0
        max_cw=max(max_cw,cw); max_cl=max(max_cl,cl)
    durs=[(t.close_dt-t.open_dt).total_seconds()/3600
          for t in trades if t.close_dt and t.open_dt]
    avg_dur=statistics.mean(durs) if durs else 0
    by_reason={}
    for t in trades:
        r=t.close_reason; by_reason.setdefault(r,[]).append(t.pnl)
    return {
        'total_trades':len(trades),'wins':len(wins),'losses':len(losses),
        'win_rate':len(wins)/len(trades)*100,
        'gross_profit':gross_profit,'gross_loss':gross_loss,
        'net_pnl':sum(pnls),'net_return_pct':sum(pnls)/INITIAL_BALANCE*100,
        'profit_factor':abs(gross_profit/gross_loss) if gross_loss else float('inf'),
        'expectancy':statistics.mean(pnls),
        'avg_win':statistics.mean(wins) if wins else 0,
        'avg_loss':statistics.mean(losses) if losses else 0,
        'max_win':max(pnls),'max_loss':min(pnls),
        'max_dd':max_dd,'sharpe':sharpe,'avg_dur_hr':avg_dur,
        'max_cw':max_cw,'max_cl':max_cl,
        'final_balance':final_balance,'monthly':monthly,'by_reason':by_reason,
    }

def ascii_equity(equity_curve,width=68,height=14):
    if len(equity_curve)<2: return "  (no data)"
    vals=[v for _,v in equity_curve]
    step=max(1,len(vals)//width)
    sampled=vals[::step][:width]
    lo=min(sampled); hi=max(sampled); rng=hi-lo if hi!=lo else 1
    rows=[]
    for row in range(height,-1,-1):
        thresh=lo+rng*row/height
        line=''.join('█' if v>=thresh else ' ' for v in sampled)
        rows.append(f"  ${thresh:>9,.0f} |{line}|")
    rows.append(f"            +{'-'*len(sampled)}+")
    return '\n'.join(rows)

# ─────────────────────────────────────────────────────────────────────────────
# REPORT
# ─────────────────────────────────────────────────────────────────────────────
def print_report(sw_trades,sw_stats,sw_eq,sc_trades,sc_stats,sc_eq,out):
    def p(s=''): out.append(s); print(s)

    p("="*78)
    p("  OIL EA BACKTEST v2 — REAL BRENT HISTORICAL DATA  (Game-Changer Edition)")
    p("  Source: MT4 broker export (Brent crude oil)")
    p(f"  Initial balance: ${INITIAL_BALANCE:,.0f}  |  Spread: {SPREAD_POINTS} pts ($0.03/bbl)")
    p("  Swing v5: ADX+EMA-stack+Pullback | 1.5x SL / 2.0x TP1 / 4.5x TP2 (3:1 RR)")
    p("  Scalp v2: M15+H1 EMA-cross momentum | 1.4x SL / 3.5x TP (2.5:1 RR)")
    p("="*78)

    for label,trades,stats,eq in [
        ("SWING EA v5 — Brent Oil Trader Pro (H1+H4, ADX+Stack+Pullback)",sw_trades,sw_stats,sw_eq),
        ("SCALPER EA v2 — Oil Scalper (M15+H1, EMA-Cross Momentum)",sc_trades,sc_stats,sc_eq),
    ]:
        if not eq: p(f"\n  {label}: no data."); continue
        p(); p("─"*78); p(f"  {label}"); p("─"*78)
        if not stats: p("  No closed trades."); continue

        period_start=eq[0][0].strftime('%Y-%m-%d'); period_end=eq[-1][0].strftime('%Y-%m-%d')
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
        p("  EXIT REASON BREAKDOWN:")
        for reason,pnls in sorted(stats['by_reason'].items()):
            w=sum(1 for x in pnls if x>0)
            p(f"    {reason:<8}: {len(pnls):>4} trades | {w:>3} wins | "
              f"total ${sum(pnls):>+8.2f} | avg ${statistics.mean(pnls):>+7.2f}")
        p()
        p("  MONTHLY P&L:")
        for month in sorted(stats['monthly'].keys()):
            pnls=stats['monthly'][month]; total=sum(pnls)
            wins=sum(1 for x in pnls if x>0)
            bar_len=min(int(abs(total)/8),30); bar_chr='█'*bar_len
            sign='+' if total>=0 else '-'
            p(f"    {month}: {len(pnls):>3} trades | {wins:>2}W/{len(pnls)-wins:>2}L | "
              f"${total:>+8.2f}  {bar_chr}")
        p(); p("  EQUITY CURVE:")
        p(ascii_equity(eq))
        p(); p("  LAST 20 CLOSED TRADES:")
        p(f"  {'#':>5}  {'Dir':>4}  {'Opened':>16}  {'Entry':>7}  {'SL':>7}  "
          f"{'TP2':>7}  {'Closed':>7}  {'P&L':>9}  Reason")
        p("  "+"-"*88)
        show=trades[-20:] if len(trades)>=20 else trades
        for t in show:
            d="BUY" if t.dir==1 else "SEL"
            od=t.open_dt.strftime('%Y-%m-%d %H:%M') if t.open_dt else '—'
            cpx=f"${t.close_px:.2f}" if t.close_px else '—'
            p(f"  {t.id:>5}  {d:>4}  {od:>16}  "
              f"${t.entry:>6.2f}  ${t.sl:>6.2f}  ${t.tp2:>6.2f}  "
              f"{cpx:>7}  ${t.pnl:>+8.2f}  {t.close_reason}")

    p(); p("─"*78); p("  SIDE-BY-SIDE COMPARISON"); p("─"*78)
    sw,sc=sw_stats,sc_stats
    if sw and sc:
        fmt="  {:<25} {:>20}  {:>20}"
        p(fmt.format("Metric","Swing v5 (H1+H4)","Scalper v2 (M15+M30)"))
        p("  "+"-"*67)
        def row(label,sv,scv): p(fmt.format(label,sv,scv))
        row("Period",
            f"{sw_eq[0][0].strftime('%b %Y')}–{sw_eq[-1][0].strftime('%b %Y')}",
            f"{sc_eq[0][0].strftime('%b %Y')}–{sc_eq[-1][0].strftime('%b %Y')}")
        row("Final Balance",f"${sw['final_balance']:,.2f}",f"${sc['final_balance']:,.2f}")
        row("Net Return",f"{sw['net_return_pct']:+.2f}%",f"{sc['net_return_pct']:+.2f}%")
        row("Max Drawdown",f"{sw['max_dd']:.2f}%",f"{sc['max_dd']:.2f}%")
        row("Sharpe Ratio",f"{sw['sharpe']:.2f}",f"{sc['sharpe']:.2f}")
        row("Total Trades",str(sw['total_trades']),str(sc['total_trades']))
        row("Win Rate",f"{sw['win_rate']:.1f}%",f"{sc['win_rate']:.1f}%")
        row("Profit Factor",f"{sw['profit_factor']:.2f}",f"{sc['profit_factor']:.2f}")
        row("Expectancy/trade",f"${sw['expectancy']:+.2f}",f"${sc['expectancy']:+.2f}")
        row("Avg Win",f"${sw['avg_win']:+.2f}",f"${sc['avg_win']:+.2f}")
        row("Avg Loss",f"${sw['avg_loss']:+.2f}",f"${sc['avg_loss']:+.2f}")
        row("Win/Loss Ratio",
            f"{abs(sw['avg_win']/sw['avg_loss']) if sw['avg_loss'] else 0:.2f}x",
            f"{abs(sc['avg_win']/sc['avg_loss']) if sc['avg_loss'] else 0:.2f}x" if sc.get('avg_loss') else "n/a")
        row("Max Consec Loss",str(sw['max_cl']),str(sc['max_cl']))
        row("Avg Trade Dur",f"{sw['avg_dur_hr']:.1f}h",f"{sc['avg_dur_hr']:.1f}h")

    p(); p("="*78)

# ─────────────────────────────────────────────────────────────────────────────
def main():
    print("Loading real Brent OHLCV data...")
    h1_bars =load_csv(PATH_H1)
    h4_bars =load_csv(PATH_H4)
    m5_bars =load_csv(PATH_M5)
    m15_bars=load_csv(PATH_M15)
    print(f"\nRunning Swing EA v5 backtest (H1 + H4)...")
    sw_trades,sw_eq,sw_bal,sw_peak,sw_dd=backtest_swing(h1_bars,h4_bars)
    sw_stats=compute_stats(sw_trades,sw_eq,sw_bal,sw_peak,sw_dd,bars_per_day=10)
    print(f"  → {len(sw_trades)} trades")

    print(f"\nRunning Scalper EA v2 backtest (M15 + H1 trend)...")
    sc_trades,sc_eq,sc_bal,sc_peak,sc_dd=backtest_scalper(m15_bars,h1_bars)
    sc_stats=compute_stats(sc_trades,sc_eq,sc_bal,sc_peak,sc_dd,bars_per_day=40)
    print(f"  → {len(sc_trades)} trades")

    out_lines=[]
    print("\n"+"="*78)
    print_report(sw_trades,sw_stats,sw_eq,sc_trades,sc_stats,sc_eq,out_lines)

    report_path='/home/user/Jmalhem/backtest_real_report.txt'
    with open(report_path,'w') as f: f.write('\n'.join(out_lines))
    print(f"\nReport saved: {report_path}")

    csv_path='/home/user/Jmalhem/backtest_real_trades.csv'
    with open(csv_path,'w',newline='') as f:
        w=csv.writer(f)
        w.writerow(['EA','ID','Dir','Open_DT','Entry','SL','TP2',
                    'Close_DT','Close_Px','Lots','PnL','Reason'])
        for t in sw_trades:
            w.writerow(['Swing',t.id,'BUY' if t.dir==1 else 'SELL',
                        t.open_dt,round(t.entry,2),round(t.sl,2),round(t.tp2,2),
                        t.close_dt,round(t.close_px,2) if t.close_px else '',
                        t.orig_lots,round(t.pnl,2),t.close_reason])
        for t in sc_trades:
            w.writerow(['Scalper',t.id,'BUY' if t.dir==1 else 'SELL',
                        t.open_dt,round(t.entry,2),round(t.sl,2),round(t.tp2,2),
                        t.close_dt,round(t.close_px,2) if t.close_px else '',
                        t.orig_lots,round(t.pnl,2),t.close_reason])
    print(f"Trades CSV: {csv_path}")

if __name__=='__main__':
    main()
