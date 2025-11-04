#include <Canvas\Canvas.mqh>
#property  copyright "Valeriia Mishchenko"
#property version    "2.12"
#property strict
#property description  "Waka Waka EA"

  enum LotSizingEnum      {LowRiskPreset = 5,//Low Risk Set 20% annual (0.25% load)
                   MidRiskPreset = 4,//Mid Risk Set 40% annual (0.5% load)
                   HighRiskPreset = 3,//Significant Risk Set 80% annual (1.0% load)
                   ExtremeRiskPreset = 7,//High Risk Set 120% annual (1.5% load)
                   LotsEquity = 2,//Dynamic Lot based on Equity
                   LotsBalance = 1,//Dynamic Lot based on Balance
                   LotsDepositLoad = 6,//Lots based on Deposit load
                   FixedLots = 0//Fixed Lot
                     };
  enum AllowBuySellEnum      {AllowSell2 = 2,//Sell only
                   AllowBuy1 = 1,//Buy only
                   AllowBuySell0 = 0//Buy and Sell
                     };
  enum eMaxDrawdownAction      {IgnoreNewUntilRestart = 3,//Prohibit opening new grids until restart
                   IgnoreNewSignals = 2,//Prohibit opening new grids
                   CloseStopTradingUntilRestart = 1,//Close trades & stop trading until restart
                   CloseStopTradingFor24h = 0//Close trades & stop trading for 24h
                     };
  enum eDrawdownCalculation      {ThisStrategy = 1,//This strategy
                   TheAccount = 0//The account
                     };


//------------------
class CCanvasX : public CCanvas  { public:
              //    CCanvasX(void);
                bool CCanvasX_12( string Para_0_st);
         };
   //  CCanvasX::CCanvasX(void){m_style=0xFFFFFFFF;m_style_idx=0;m_chart_id=0;m_objname=NULL;m_objtype=-1;m_rcname=NULL;m_width=0;m_height=0;m_format=0;m_fontname="arial";m_fontsize=-120;m_fontflags=0;m_fontangle=0;};
class SymbolInformation  { public:string  st_1; datetime  da_2; datetime  da_3; int  in_4; bool  bo_5; bool  bo_6; datetime  da_7; datetime  da_8; double  do_9; bool  bo_10; bool  bo_11; double  do_12; double  do_13; int  in_14; int  in_15; long  lo_16; double  do_17; bool  bo_18; bool  bo_19; bool  bo_20; int  in_21; double  do_22; double  do_23; double  do_24; double  do_25; double  do_26; datetime  da_27; datetime  da_28;
                void SymbolInformation_13();
                void SymbolInformation_14();
                void SymbolInformation_15();
                void ~SymbolInformation();
         };
class CutTrade  { public:long  lo_1; double  do_2; bool  bo_3;
                void CutTrade_17();
                void CutTrade_18();
                void CutTrade_19();
                void ~CutTrade();
         };
extern string MM_Setting="Select the risk settings"  ;   //------> MM & Risk settings <------
extern bool AllowOpeningNewGrid=true  ;    //Allow Opening a new Grid?
extern  LotSizingEnum  LotSizingMethod=5  ;    //Lot-sizing Method
extern double LotSizingValueFixed=0.01  ;    //Fixed Lot
extern double LotSizingValueDynamic=10000  ;    //Dynamic Lot (Balance/Equity based)
extern double LotSizingDepositLoadPercent=0.25  ;    //Deposit Load %
extern bool FixedInitialDeposit=false ;    //Fixed Initial Deposit? (Tester only)
extern double MaximumLot=100  ;    //Maximum Lot
extern bool AutoSplit=false ;    //Auto Split?
extern double MaximumSpread=10  ;    //Maximum Spread, in pips
extern int MaximumSlippage=10  ;    //Maximum Slippage for a non-ECN acc, in pips
extern int   MaximumSymbols=2  ;    //Maximum Symbols at a time
extern bool AllowHedging=true  ;    //Allow Hedging?
extern bool AllowTradingOnHolidays=false ;    //Allow Trading on Holidays?
extern  AllowBuySellEnum  AllowToBuySell=0  ;    //Allow to Buy/Sell
extern double MinimumFreeMargin=0  ;    //Minimum Free Margin % [0-disabled]
extern double MaximumDrawdown=100  ;    //Max Floating Drawdown %
extern double MaximumDrawdownMoney=0  ;    //Max Floating Drawdown in Money [0-disabled]
extern  eMaxDrawdownAction  MaximumDrawdownAction=0  ;    //Max Drawdown Action
extern  eDrawdownCalculation  DrawdownCalculation=1  ;    //Max Drawdown Calculation
extern string Strategy_Setting="Select the strategy settings and symbols used"  ;   //------> Strategy settings <------
extern string Symbols="AUDNZD,AUDCAD,NZDCAD"  ;   //Symbols separated by comma (custom if empty)
extern int   HourToStartTrading=0  ;    //Hour to Start Trading (broker\'s time)
extern int   HourToStopTrading=23  ;    //Hour to Stop Trading (broker\'s time)
extern int   BollingerBandsPeriod=35  ;    //Bollinger Bands Period
extern int   RSI_Period=20  ;    //RSI Period
extern int   RSI_Value=15  ;    //Maximum RSI Value
extern string Strategy_Setting_TP="Select TP settings"  ;   //------> TakeProfit settings <------
extern double InitialTP=10  ;    //TakeProfit for Initial Trade, in pips
extern bool WeightedTP=true  ;    //Weighted TakeProfit?
extern double GridTP=0  ;    //TakeProfit for Grid, in pips (can also be zero or negative)
extern int   BreakEvenAfterThisLevel=0  ;    //Break Even after this Level [0-disabled]
extern bool HideTP=false ;    //Hide TakeProfit?
extern bool Use_OPO_Method=false ;    //Use OPO method to handle TP
extern  ENUM_TIMEFRAMES  OPO_TimeFrame=15  ;    //TF for OPO method
extern bool SmartTP=false ;    //Smart TakeProfit?
extern bool DoNotAdjustTPUnlessNewGrid=false ;    //Do not adjust TP unless new grid level opened
extern string Strategy_Setting_SL="Select SL settings"  ;   //------> StopLoss settings <------
extern double GridSL=0  ;    //StopLoss for Grid, in pips (1000pips if zero)
extern bool HideSL=false ;    //Hide StopLoss?
extern string Grid_Setting="Adjust the grid distance and multipliers"  ;   //------> Grid settings <------
extern int   TradeDistance=35  ;    //Trade Distance
extern bool SmartDistance=true  ;    //Smart Distance?
extern double TradeMultiplier_2nd=1  ;    //2nd Trade Multiplier
extern double TradeMultiplier_3rd=2  ;    //3rd-5th Trade Multiplier
extern double TradeMultiplier_6th=1.5  ;    //6th- Trade Multiplier
extern int   MaximumTrades=9  ;    //Maximum Trades
extern int   GridLevelToStart=1  ;    //Grid Level to Start (1-initial trade)
extern bool KeepOriginalProfitLotSize=false ;    //Keep Original Profit Level & Lot Size
extern string Additional_Setting="Change the comment and UID if needed"  ;   //------> Additional settings <------
extern string TradeComment="Waka"  ;   //Trade Comment
extern int   UID=0  ;    //UID (0...9)
extern bool ShowPanel=true  ;    //ShowPanel
  string    Global_1_st = "::W2.12LD_bmp\\WakaWakaEA.bmp";
  string    Global_2_st = "2.12";
  long      Global_3_lo = 0;
  string    Global_4_st = "";
  int       Global_5_in = 0;
  //string    Global_6_st = "";
  datetime  Global_7_da = 0;
  int       Global_8_in = 0;
  CCanvasX  Global_10_a_167;
  bool      Global_11_bo = true;
  int       Global_12_in = 3000;
  bool      Global_13_bo = false;
  int       Global_14_in = 50000;
  CutTrade  Global_15_a_169_ko[];
  int       Global_16_in = -1;
  double     Global_17_lo_ko[];
  double    Global_18_do_ko[];
  int       Global_19_in = -1;
  int       Global_20_in = 0;
  int       Global_21_in = 15;
  SymbolInformation Global_22_a_168_ko[];
  ushort     Global_23_sh = 0;
  int       Global_24_in = 84570;
  double    Global_25_do = 0.0000001;
  int       Global_26_in = -1;
  long      Global_27_lo = 0;
  int       Global_28_in = 0;
  bool      Global_29_bo = false;
  int       Global_30_in = 0;
  bool      Global_31_bo = false;
  int       Global_32_in = -1;
  long      Global_33_lo = 0;
  long      Global_34_lo = 0;
  bool      Global_35_bo = false;
  string    Global_36_st = "Select pair";
  bool      Global_37_bo = true;
  double    Global_38_do = 0.0;
  bool      Global_39_bo = true;
  int       Global_40_in = 0;

 int OnInit()
 {
  //int       Local_1_in;
  int       Local_2_in;
  int       Local_3_in;
  int       Local_4_in;
  int       Local_5_in;
  int       Local_6_in;
  int       Local_7_in;
  int       Local_8_in;
  int       Local_9_in;
  int       Local_10_in;
  int       Local_11_in;
  int       Local_12_in;
  int       Local_13_in;
  int       Local_14_in;
  int       Local_15_in;
  int       Local_16_in;
  int       Local_17_in;
  int       Local_18_in;
  int       Local_19_in;
  int       Local_20_in;
  int       Local_21_in;
  //uchar     Local_22_uc;
  //uchar     Local_23_uc;
  //uchar     Local_24_uc;
  int       Local_25_in;
  int       Local_26_in;
  bool      Local_27_bo;
  string    symb[];
  int       Local_29_in;
  int       Local_30_in;
  double    Local_31_do;
  double    Local_32_do;
  int       Local_33_in;
  int       Local_34_in;
//----- -----
 string     tmp_st_1;
 string     tmp_st_2;
 string     tmp_st_3;
 double     tmp_do_4;
 double     tmp_do_5;
 int        tmp_in_6;
 int        tmp_in_7;
 double     tmp_do_8;
 string     tmp_st_9;
 double     tmp_do_10;
 double     tmp_do_11;
 int        tmp_in_12;
 int        tmp_in_13;
 double     tmp_do_14;
 int        tmp_in_15;

 Print(TradeComment + " " + "->",": Initializing...");
 Global_30_in = 0 ;
 Global_31_bo = false ;
 Local_2_in = 0 ;
 Local_3_in = 1 ;
 Local_4_in=1 + 1;
 Local_5_in=Local_4_in + 1;
 Local_6_in=Local_4_in + Local_4_in;
 Local_7_in=Local_5_in + Local_4_in;
 Local_8_in=Local_5_in + Local_5_in;
 Local_9_in=Local_6_in + Local_5_in;
 Local_10_in=Local_8_in + Local_4_in;
 Local_11_in=Local_8_in + Local_5_in;
 Local_12_in = 0 ;
 Local_13_in = 1 ;
 Local_14_in = Local_4_in ;
 Local_15_in = Local_5_in ;
 Local_16_in=Local_5_in + 1;
 Local_17_in=Local_6_in + 1;
 Local_18_in=Local_17_in + 1;
 Local_19_in=Local_4_in + Local_17_in;
 Local_20_in=Local_16_in + Local_16_in;
 Local_21_in=Local_20_in + 1;
 /*
 for (Local_22_uc = Local_19_in * Local_21_in + Local_4_in ; Local_22_uc < Local_21_in * Local_11_in + Local_21_in + Local_3_in ; Local_22_uc ++)
 {
   Global_6_st +=CharToString(Local_22_uc);
 }
 for (Local_23_uc = Local_8_in * Local_10_in ; Local_23_uc < Local_19_in * Local_10_in + Local_14_in ; Local_23_uc ++)
 {
   Global_6_st +=CharToString(Local_23_uc);
 }
 for (Local_24_uc = 97 ; Local_24_uc < 123 ; Local_24_uc ++)
 {
   Global_6_st +=CharToString(Local_24_uc);
 }
 Global_6_st +=CharToString(32); //" !,.:/--"
 Global_6_st +=CharToString(33);
 Global_6_st +=CharToString(44);
 Global_6_st +=CharToString(46);
 Global_6_st +=CharToString(58);
 Global_6_st +=CharToString(47);
 Global_6_st +=CharToString(45);
 Global_6_st +=CharToString(95);
 */
 Local_25_in = 1 ;
 Local_26_in = 0 ;
 Global_3_lo = AccountInfoInteger(ACCOUNT_LOGIN) ;
 Global_4_st = AccountInfoString(ACCOUNT_NAME) ;
 Sleep(500);
 if ( !(IsTesting()) )
 {
   EventSetTimer(5);
 }
 Global_27_lo = TimeCurrent() ;
 Global_29_bo = false ;
 Global_23_sh = StringGetCharacter(",",0) ;
 Global_16_in = -1 ;
 Local_27_bo = IsTesting() ;
 Local_29_in = StringSplit(Symbols,Global_23_sh,symb) ;
 if ( Local_29_in >  0 && !(Local_27_bo) )
 {
   ArrayResize(Global_22_a_168_ko,Local_29_in,0);
   for (Local_30_in = 0 ; Local_30_in < Local_29_in ; Local_30_in ++)
   {
     tmp_st_1 = StringTrimLeft(symb[Local_30_in]);
     tmp_st_2 = StringTrimRight(StringTrimLeft(symb[Local_30_in]));
     Global_22_a_168_ko[Local_30_in].st_1 = StringTrimRight(StringTrimLeft(symb[Local_30_in]));
     if ( Global_22_a_168_ko[Local_30_in].st_1 == "" )
     {
       Global_22_a_168_ko[Local_30_in].st_1 = "??????";
       Print(TradeComment + " " + Global_22_a_168_ko[Local_30_in].st_1,": List of Symbols is incorrect! Check it for extra commas!");
       Global_35_bo = true ;
     }
     Global_22_a_168_ko[Local_30_in].da_2 = 0;
     Global_22_a_168_ko[Local_30_in].in_4 = 0;
     Global_22_a_168_ko[Local_30_in].bo_5 = false;
     Global_22_a_168_ko[Local_30_in].bo_6 = false;
     Global_22_a_168_ko[Local_30_in].da_7 = 0;
     Global_22_a_168_ko[Local_30_in].da_8 = 0;
     Global_22_a_168_ko[Local_30_in].do_9 = 0.0;
     Global_22_a_168_ko[Local_30_in].bo_10 = false;
     Global_22_a_168_ko[Local_30_in].bo_11 = false;
     Global_22_a_168_ko[Local_30_in].do_12 = 1.0;
     Global_22_a_168_ko[Local_30_in].do_13 = 0.0;
     Global_22_a_168_ko[Local_30_in].in_14 = 0;
     Global_22_a_168_ko[Local_30_in].in_15 = 0;
     Global_22_a_168_ko[Local_30_in].lo_16 = 0;
     Global_22_a_168_ko[Local_30_in].do_17 = 0.0;
     Global_22_a_168_ko[Local_30_in].bo_18 = true;
     Global_22_a_168_ko[Local_30_in].bo_19 = true;
     Global_22_a_168_ko[Local_30_in].bo_20 = true;
     Global_22_a_168_ko[Local_30_in].in_21 = 0;
     tmp_st_3 = Global_22_a_168_ko[Local_30_in].st_1;
     tmp_do_4 = 0.1;
     tmp_do_5 = 0.1;
     tmp_in_6 = 1;
     for (tmp_in_7=MaximumTrades - 1 ; tmp_in_6 <= tmp_in_7 ; tmp_in_7=MaximumTrades - 1)
     {
       tmp_do_5 = tmp_do_5 + lizong_36(tmp_st_3,tmp_do_4,tmp_in_6,0.0);
       tmp_in_6=tmp_in_6 + 1;
     }
     if ( tmp_do_4>Global_25_do )
     {
       tmp_do_8 = tmp_do_5 / tmp_do_4;
     }
     else
     {
       tmp_do_8 = 0.0;
     }
     Global_22_a_168_ko[Local_30_in].do_22 = tmp_do_8;
     Global_22_a_168_ko[Local_30_in].do_23 = 0.0;
     Global_22_a_168_ko[Local_30_in].do_24 = 0.0;
     Global_22_a_168_ko[Local_30_in].do_25 = 0.0;
     Global_22_a_168_ko[Local_30_in].do_26 = 0.0;
   }
 }
 else
 {
   ArrayResize(Global_22_a_168_ko,1,0);
   Global_22_a_168_ko[0].st_1 = Symbol();
   Global_22_a_168_ko[0].da_2 = 0;
   Global_22_a_168_ko[0].in_4 = 0;
   Global_22_a_168_ko[0].bo_5 = false;
   Global_22_a_168_ko[0].bo_6 = false;
   Global_22_a_168_ko[0].da_7 = 0;
   Global_22_a_168_ko[0].da_8 = 0;
   Global_22_a_168_ko[0].do_9 = 0.0;
   Global_22_a_168_ko[0].bo_10 = false;
   Global_22_a_168_ko[0].bo_11 = false;
   Global_22_a_168_ko[0].do_12 = 1.0;
   Global_22_a_168_ko[0].do_13 = 0.0;
   Global_22_a_168_ko[0].in_14 = 0;
   Global_22_a_168_ko[0].in_15 = 0;
   Global_22_a_168_ko[0].lo_16 = 0;
   Global_22_a_168_ko[0].do_17 = 0.0;
   Global_22_a_168_ko[0].bo_18 = true;
   Global_22_a_168_ko[0].bo_19 = true;
   Global_22_a_168_ko[0].bo_20 = true;
   Global_22_a_168_ko[0].in_21 = 0;
   tmp_st_9 = Symbol();
   tmp_do_10 = 0.1;
   tmp_do_11 = 0.1;
   tmp_in_12 = 1;
   for (tmp_in_13=MaximumTrades - 1 ; tmp_in_12 <= tmp_in_13 ; tmp_in_13=MaximumTrades - 1)
   {
     tmp_do_11 = tmp_do_11 + lizong_36(tmp_st_9,tmp_do_10,tmp_in_12,0.0);
     tmp_in_12=tmp_in_12 + 1;
   }
   if ( tmp_do_10>Global_25_do )
   {
     tmp_do_14 = tmp_do_11 / tmp_do_10;
   }
   else
   {
     tmp_do_14 = 0.0;
   }
   Global_22_a_168_ko[0].do_22 = tmp_do_14;
   Global_22_a_168_ko[0].do_23 = 0.0;
   Global_22_a_168_ko[0].do_24 = 0.0;
   Global_22_a_168_ko[0].do_25 = 0.0;
   Global_22_a_168_ko[0].do_26 = 0.0;
 }
 if ( Global_13_bo )
 {
   ArrayResize(Global_15_a_169_ko,Global_14_in,0);
 }
 if ( !(IsOptimization()) )
 {
   ObjectsDeleteAll(0,-1);
   if ( ShowPanel )
   {
     lizong_46();
     lizong_49(true);
   }
   if ( IsVisualMode() )
   {
     if ( ObjectFind(0,"but_Buy") != -1 && ObjectGetInteger(0,"but_Buy",OBJPROP_STATE,0) != 0 )
     {
       lizong_48("but_Buy");
     }
     if ( ObjectFind(0,"but_Sell") != -1 && ObjectGetInteger(0,"but_Sell",OBJPROP_STATE,0) != 0 )
     {
       lizong_48("but_Sell");
     }
     if ( ObjectFind(0,"but_Pair") != -1 && ObjectGetInteger(0,"but_Pair",OBJPROP_STATE,0) != 0 )
     {
       lizong_48("but_Pair");
     }
     if ( ObjectFind(0,"but_Suspend") != -1 )
     {
       Global_37_bo=!(ObjectGetInteger(0,"but_Suspend",OBJPROP_STATE,0));
       if ( ObjectGetInteger(0,"but_Suspend",OBJPROP_STATE,0) == 0 )
       {
         ObjectSetInteger(0,"but_Suspend",OBJPROP_BGCOLOR,32768);
         ObjectSetString(0,"but_Suspend",OBJPROP_TEXT,"New grids allowed");
       }
       if ( !(Global_37_bo) )
       {
         ObjectSetInteger(0,"but_Suspend",OBJPROP_BGCOLOR,255);
         ObjectSetString(0,"but_Suspend",OBJPROP_TEXT,"New grids NOT allowed!");
         for (tmp_in_15 = 0 ; tmp_in_15 < ArraySize(Global_22_a_168_ko) ; tmp_in_15=tmp_in_15 + 1)
         {
           Global_22_a_168_ko[tmp_in_15].bo_5 = false;
           Global_22_a_168_ko[tmp_in_15].bo_6 = false;
         }
       }
       ChartRedraw(0);
     }
   }
   ChartRedraw(0);
 }
 if ( Global_11_bo )
 {
   ArrayResize(Global_17_lo_ko,Global_12_in,0);
   ArrayFill(Global_17_lo_ko,0,Global_12_in,0);
   ArrayResize(Global_18_do_ko,Global_12_in,0);
   if ( Global_12_in != 0 )
   {
     ArrayFill(Global_18_do_ko,0,Global_12_in,0.0);
   }
 }
 if ( Global_11_bo )
 {
   lizong_27();
 }
 if ( Global_11_bo )
 {
   Local_31_do = 0.0 ;
   Local_32_do = 0.0 ;
   for (Local_33_in = 0 ; Local_33_in < ArraySize(Global_18_do_ko) ; Local_33_in ++)
   {
     for (Local_34_in = 0 ; Local_34_in < ArraySize(Global_17_lo_ko) - Local_33_in - 1 ; Local_34_in ++)
     {
       if ( Global_18_do_ko[Local_34_in]>Global_18_do_ko[Local_34_in + 1] )
       {
         Local_31_do = Global_18_do_ko[Local_34_in] ;
         Local_32_do = Global_17_lo_ko[Local_34_in] ;
         Global_18_do_ko[Local_34_in] = Global_18_do_ko[Local_34_in + 1];
         Global_17_lo_ko[Local_34_in] = Global_17_lo_ko[Local_34_in + 1];
         Global_18_do_ko[Local_34_in + 1] = Local_31_do;
         Global_17_lo_ko[Local_34_in + 1] = Local_32_do;
       }
     }
   }
 }
 Global_38_do = AccountInfoDouble(ACCOUNT_BALANCE) ;
 if ( ( Local_2_in + Local_3_in + Local_4_in + Local_5_in + Local_6_in + Local_7_in + Local_8_in + Local_9_in + Local_10_in + Local_11_in != 45 || Local_12_in + Local_13_in + Local_14_in + Local_15_in + Local_16_in + Local_17_in + Local_18_in + Local_19_in + Local_20_in + Local_21_in != 45 ) )
 {
   return(32767);
 }
 return(0);
 }
//OnInit <<==--------   --------
 void OnTick()
 {
  int       Local_1_in;
//----- -----
 bool       tmp_bo_1;
 int        tmp_in_2;
 bool       tmp_bo_3;


//-------------------------

 for (Local_1_in = 0 ; Local_1_in < ArraySize(Global_22_a_168_ko) ; Local_1_in ++)
 {
   if ( iTime(Global_22_a_168_ko[Local_1_in].st_1,Global_21_in,0) <= Global_22_a_168_ko[Local_1_in].da_2 )
   {
     tmp_bo_1 = false;
   }
   else
   {
     Global_22_a_168_ko[Local_1_in].da_2 = iTime(Global_22_a_168_ko[Local_1_in].st_1,Global_21_in,0);
     tmp_bo_1 = true;
   }
   if ( tmp_bo_1 )
   {
     lizong_32(Local_1_in);
     if ( IsTradeAllowed() )
     {
       tmp_in_2 = TerminalInfoInteger(8);
       if ( tmp_in_2 != 0 )
       {
         tmp_in_2 = (int)AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
       }
       if ( tmp_in_2 != 0 )
       {
         tmp_in_2 = MQLInfoInteger(MQL_TRADE_ALLOWED);
       }
       if ( ( tmp_in_2 != 0 || IsTesting() || IsOptimization() ) )
       {
         lizong_37(Local_1_in);
         lizong_25(Local_1_in);
         lizong_26(Local_1_in);
       }
     }
   }
   if ( iTime(Global_22_a_168_ko[Local_1_in].st_1,OPO_TimeFrame,0) <= Global_22_a_168_ko[Local_1_in].da_3 )
   {
     tmp_bo_3 = false;
   }
   else
   {
     Global_22_a_168_ko[Local_1_in].da_3 = iTime(Global_22_a_168_ko[Local_1_in].st_1,OPO_TimeFrame,0);
     tmp_bo_3 = true;
   }
   if ( tmp_bo_3 )
   {
     Global_22_a_168_ko[Local_1_in].bo_11 = false;
   }
 }
 lizong_35();
 }
//OnTick <<==--------   --------
 void OnTimer()
 {
 int        tmp_in_1;

 if ( IsTesting() || IsOptimization() )   return;
 Global_27_lo = TimeCurrent() ;
 for (tmp_in_1 = 0 ; tmp_in_1 < ArraySize(Global_22_a_168_ko) ; tmp_in_1=tmp_in_1 + 1)
 {
   iTime(Global_22_a_168_ko[tmp_in_1].st_1,Global_21_in,0);
   iTime(Global_22_a_168_ko[tmp_in_1].st_1,OPO_TimeFrame,0);
 }
 if ( !(ShowPanel) )   return;
 lizong_49(false);
 }
//OnTimer <<==--------   --------
 void OnChartEvent( const int Para_0_in,const long & Para_1_lo,const double & Para_2_do,const string & Para_3_st)
 {
 if ( Para_0_in != 1 )   return;
 lizong_48(Para_3_st);
 }
//OnChartEvent <<==--------   --------
 void OnDeinit( const int Para_0_in)
 {
 string     tmp_st_1;

 EventKillTimer();
 tmp_st_1 = "";
 switch(Para_0_in)
 {
   case 6 :
   tmp_st_1 = "Account changed";
     break;
   case 3 :
   tmp_st_1 = "Symbol/timeframe changed";
     break;
   case 4 :
   tmp_st_1 = "Chart closed";
     break;
   case 5 :
   tmp_st_1 = "Input parameters changed";
     break;
   case 2 :
   tmp_st_1 = "Expert recompiled";
     break;
   case 1 :
   tmp_st_1 = "Expert removed from the chart";
     break;
   case 7 :
   tmp_st_1 = "New template applied to the chart";
     break;
   default :
   tmp_st_1 = "Expert stopped";
 }
 Print(tmp_st_1);
 if ( !(IsTesting()) && !(IsOptimization()) )
 {Global_10_a_167.Destroy();
 }
 if ( IsTesting() || IsOptimization() )   return;
 ObjectsDeleteAll(0,-1);
 }
//OnDeinit <<==--------   --------
 int lizong_10( int Para_0_in)
 {
  //int       Local_1_in;
//----- -----

 switch(Para_0_in)
 {
   case 0 :
   return(0);
   case 1 :
   return(1);
   case 5 :
   return(5);
   case 15 :
   return(15);
   case 30 :
   return(30);
   case 60 :
   return(60);
   case 240 :
   return(240);
   case 1440 :
   return(1440);
   case 10080 :
   return(10080);
   case 43200 :
   return(43200);
 }
 return(0);
 }
//lizong_10 <<==--------   --------
 string lizong_11( int Para_0_in)
 {
  int       Local_1_in = 0;
  string    Local_2_st;
//----- -----
 string     tmp_st_1;

 if ( Para_0_in == -1 )
 {
   Local_1_in = GetLastError() ;
 }
 else
 {
   Local_1_in = Para_0_in ;
 }
 Local_2_st = " Err.code=" + IntegerToString(Local_1_in,0,32) + ": " ;
 switch(Local_1_in)
 {
   case 0 :
   tmp_st_1 = Local_2_st + "No error returned";
   return(tmp_st_1);
   case 1 :
   tmp_st_1 = Local_2_st + "No error returned, but the result is unknown";
   return(tmp_st_1);
   case 2 :
   tmp_st_1 = Local_2_st + "Common error";
   return(tmp_st_1);
   case 3 :
   tmp_st_1 = Local_2_st + "Invalid trade parameters";
   return(tmp_st_1);
   case 4 :
   tmp_st_1 = Local_2_st + "Trade server is busy";
   return(tmp_st_1);
   case 5 :
   tmp_st_1 = Local_2_st + "Old version of the client terminal";
   return(tmp_st_1);
   case 6 :
   tmp_st_1 = Local_2_st + "No connection with trade server";
   return(tmp_st_1);
   case 7 :
   tmp_st_1 = Local_2_st + "Not enough rights";
   return(tmp_st_1);
   case 8 :
   tmp_st_1 = Local_2_st + "Too frequent requests";
   return(tmp_st_1);
   case 9 :
   tmp_st_1 = Local_2_st + "Malfunctional trade operation";
   return(tmp_st_1);
   case 64 :
   tmp_st_1 = Local_2_st + "Account disabled";
   return(tmp_st_1);
   case 65 :
   tmp_st_1 = Local_2_st + "Invalid account";
   return(tmp_st_1);
   case 128 :
   tmp_st_1 = Local_2_st + "Trade timeout";
   return(tmp_st_1);
   case 129 :
   tmp_st_1 = Local_2_st + "Invalid price";
   return(tmp_st_1);
   case 130 :
   tmp_st_1 = Local_2_st + "Invalid stops";
   return(tmp_st_1);
   case 131 :
   tmp_st_1 = Local_2_st + "Invalid trade volume";
   return(tmp_st_1);
   case 132 :
   tmp_st_1 = Local_2_st + "Market is closed";
   return(tmp_st_1);
   case 133 :
   tmp_st_1 = Local_2_st + "Trade is disabled";
   return(tmp_st_1);
   case 134 :
   tmp_st_1 = Local_2_st + "Not enough money";
   return(tmp_st_1);
   case 135 :
   tmp_st_1 = Local_2_st + "Price changed";
   return(tmp_st_1);
   case 136 :
   tmp_st_1 = Local_2_st + "Off quotes";
   return(tmp_st_1);
   case 137 :
   tmp_st_1 = Local_2_st + "Broker is busy";
   return(tmp_st_1);
   case 138 :
   tmp_st_1 = Local_2_st + "Requote";
   return(tmp_st_1);
   case 139 :
   tmp_st_1 = Local_2_st + "Order is locked";
   return(tmp_st_1);
   case 140 :
   tmp_st_1 = Local_2_st + "Buy orders only allowed";
   return(tmp_st_1);
   case 141 :
   tmp_st_1 = Local_2_st + "Too many requests";
   return(tmp_st_1);
   case 145 :
   tmp_st_1 = Local_2_st + "Modification denied because order is too close to market";
   return(tmp_st_1);
   case 146 :
   tmp_st_1 = Local_2_st + "Trade context is busy";
   return(tmp_st_1);
   case 147 :
   tmp_st_1 = Local_2_st + "Expirations are denied by broker";
   return(tmp_st_1);
   case 148 :
   tmp_st_1 = Local_2_st + "The amount of open and pending orders has reached the limit set by the broker";
   return(tmp_st_1);
   case 149 :
   tmp_st_1 = Local_2_st + "An attempt to open an order opposite to the existing one when hedging is disabled";
   return(tmp_st_1);
   case 150 :
   tmp_st_1 = Local_2_st + "An attempt to close an order contravening the FIFO rule";
   return(tmp_st_1);
   case 4000 :
   tmp_st_1 = Local_2_st + "No error returned";
   return(tmp_st_1);
   case 4001 :
   tmp_st_1 = Local_2_st + "Wrong function pointer";
   return(tmp_st_1);
   case 4002 :
   tmp_st_1 = Local_2_st + "Array index is out of range";
   return(tmp_st_1);
   case 4003 :
   tmp_st_1 = Local_2_st + "No memory for function call stack";
   return(tmp_st_1);
   case 4004 :
   tmp_st_1 = Local_2_st + "Recursive stack overflow";
   return(tmp_st_1);
   case 4005 :
   tmp_st_1 = Local_2_st + "Not enough stack for parameter";
   return(tmp_st_1);
   case 4006 :
   tmp_st_1 = Local_2_st + "No memory for parameter string";
   return(tmp_st_1);
   case 4007 :
   tmp_st_1 = Local_2_st + "No memory for temp string";
   return(tmp_st_1);
   case 4008 :
   tmp_st_1 = Local_2_st + "Not initialized string";
   return(tmp_st_1);
   case 4009 :
   tmp_st_1 = Local_2_st + "Not initialized string in array";
   return(tmp_st_1);
   case 4010 :
   tmp_st_1 = Local_2_st + "No memory for array string";
   return(tmp_st_1);
   case 4011 :
   tmp_st_1 = Local_2_st + "Too long string";
   return(tmp_st_1);
   case 4012 :
   tmp_st_1 = Local_2_st + "Remainder from zero divide";
   return(tmp_st_1);
   case 4013 :
   tmp_st_1 = Local_2_st + "Zero divide";
   return(tmp_st_1);
   case 4014 :
   tmp_st_1 = Local_2_st + "Unknown command";
   return(tmp_st_1);
   case 4015 :
   tmp_st_1 = Local_2_st + "Wrong jump (never generated error)";
   return(tmp_st_1);
   case 4016 :
   tmp_st_1 = Local_2_st + "Not initialized array";
   return(tmp_st_1);
   case 4017 :
   tmp_st_1 = Local_2_st + "DLL calls are not allowed";
   return(tmp_st_1);
   case 4018 :
   tmp_st_1 = Local_2_st + "Cannot load library";
   return(tmp_st_1);
   case 4019 :
   tmp_st_1 = Local_2_st + "Cannot call function";
   return(tmp_st_1);
   case 4020 :
   tmp_st_1 = Local_2_st + "Expert function calls are not allowed";
   return(tmp_st_1);
   case 4021 :
   tmp_st_1 = Local_2_st + "Not enough memory for temp string returned from function";
   return(tmp_st_1);
   case 4022 :
   tmp_st_1 = Local_2_st + " System is busy (never generated error)";
   return(tmp_st_1);
   case 4023 :
   tmp_st_1 = Local_2_st + "DLL-function call critical error";
   return(tmp_st_1);
   case 4024 :
   tmp_st_1 = Local_2_st + "Internal error";
   return(tmp_st_1);
   case 4025 :
   tmp_st_1 = Local_2_st + "Out of memory";
   return(tmp_st_1);
   case 4026 :
   tmp_st_1 = Local_2_st + "Invalid pointer";
   return(tmp_st_1);
   case 4027 :
   tmp_st_1 = Local_2_st + "Too many formatters in the format function";
   return(tmp_st_1);
   case 4028 :
   tmp_st_1 = Local_2_st + "Parameters count exceeds formatters count";
   return(tmp_st_1);
   case 4029 :
   tmp_st_1 = Local_2_st + "Invalid array";
   return(tmp_st_1);
   case 4030 :
   tmp_st_1 = Local_2_st + "No reply from chart";
   return(tmp_st_1);
   case 4050 :
   tmp_st_1 = Local_2_st + "Invalid function parameters count";
   return(tmp_st_1);
   case 4051 :
   tmp_st_1 = Local_2_st + "Invalid function parameter value";
   return(tmp_st_1);
   case 4052 :
   tmp_st_1 = Local_2_st + "String function internal error";
   return(tmp_st_1);
   case 4053 :
   tmp_st_1 = Local_2_st + "Some array error";
   return(tmp_st_1);
   case 4054 :
   tmp_st_1 = Local_2_st + "Incorrect series array using";
   return(tmp_st_1);
   case 4055 :
   tmp_st_1 = Local_2_st + "Custom indicator error";
   return(tmp_st_1);
   case 4056 :
   tmp_st_1 = Local_2_st + "Arrays are incompatible";
   return(tmp_st_1);
   case 4057 :
   tmp_st_1 = Local_2_st + "Global variables processing error";
   return(tmp_st_1);
   case 4058 :
   tmp_st_1 = Local_2_st + "Global variable not found";
   return(tmp_st_1);
   case 4059 :
   tmp_st_1 = Local_2_st + "Function is not allowed in testing mode";
   return(tmp_st_1);
   case 4060 :
   tmp_st_1 = Local_2_st + "Function is not allowed for call";
   return(tmp_st_1);
   case 4061 :
   tmp_st_1 = Local_2_st + "Send mail error";
   return(tmp_st_1);
   case 4062 :
   tmp_st_1 = Local_2_st + "String parameter expected";
   return(tmp_st_1);
   case 4063 :
   tmp_st_1 = Local_2_st + "Integer parameter expected";
   return(tmp_st_1);
   case 4064 :
   tmp_st_1 = Local_2_st + "Double parameter expected";
   return(tmp_st_1);
   case 4065 :
   tmp_st_1 = Local_2_st + "Array as parameter expected";
   return(tmp_st_1);
   case 4066 :
   tmp_st_1 = Local_2_st + "Requested history data is in updating state";
   return(tmp_st_1);
   case 4067 :
   tmp_st_1 = Local_2_st + "Internal trade error";
   return(tmp_st_1);
   case 4068 :
   tmp_st_1 = Local_2_st + "Resource not found";
   return(tmp_st_1);
   case 4069 :
   tmp_st_1 = Local_2_st + "Resource not supported";
   return(tmp_st_1);
   case 4070 :
   tmp_st_1 = Local_2_st + "Duplicate resource";
   return(tmp_st_1);
   case 4071 :
   tmp_st_1 = Local_2_st + "Custom indicator cannot initialize";
   return(tmp_st_1);
   case 4072 :
   tmp_st_1 = Local_2_st + "Cannot load custom indicator";
   return(tmp_st_1);
   case 4073 :
   tmp_st_1 = Local_2_st + "No history data";
   return(tmp_st_1);
   case 4074 :
   tmp_st_1 = Local_2_st + "No memory for history data";
   return(tmp_st_1);
   case 4075 :
   tmp_st_1 = Local_2_st + "Not enough memory for indicator calculation";
   return(tmp_st_1);
   case 4099 :
   tmp_st_1 = Local_2_st + "End of file";
   return(tmp_st_1);
   case 4100 :
   tmp_st_1 = Local_2_st + "Some file error";
   return(tmp_st_1);
   case 4101 :
   tmp_st_1 = Local_2_st + "Wrong file name";
   return(tmp_st_1);
   case 4102 :
   tmp_st_1 = Local_2_st + "Too many opened files";
   return(tmp_st_1);
   case 4103 :
   tmp_st_1 = Local_2_st + "Cannot open file";
   return(tmp_st_1);
   case 4104 :
   tmp_st_1 = Local_2_st + "Incompatible access to a file";
   return(tmp_st_1);
   case 4105 :
   tmp_st_1 = Local_2_st + "No order selected";
   return(tmp_st_1);
   case 4106 :
   tmp_st_1 = Local_2_st + "Unknown symbol";
   return(tmp_st_1);
   case 4107 :
   tmp_st_1 = Local_2_st + "Invalid price";
   return(tmp_st_1);
   case 4108 :
   tmp_st_1 = Local_2_st + "Invalid ticket";
   return(tmp_st_1);
   case 4109 :
   tmp_st_1 = Local_2_st + "Trade is not allowed. Enable checkbox \'Allow live trading\' in the Expert Advisor properties";
   return(tmp_st_1);
   case 4110 :
   tmp_st_1 = Local_2_st + "Longs are not allowed. Check the Expert Advisor properties";
   return(tmp_st_1);
   case 4111 :
   tmp_st_1 = Local_2_st + "Shorts are not allowed. Check the Expert Advisor properties";
   return(tmp_st_1);
   case 4112 :
   tmp_st_1 = Local_2_st + "Automated trading by Expert Advisors/Scripts disabled by trade server";
   return(tmp_st_1);
   case 4200 :
   tmp_st_1 = Local_2_st + "Object already exists";
   return(tmp_st_1);
   case 4201 :
   tmp_st_1 = Local_2_st + "Unknown object property";
   return(tmp_st_1);
   case 4202 :
   tmp_st_1 = Local_2_st + "Object does not exist";
   return(tmp_st_1);
   case 4203 :
   tmp_st_1 = Local_2_st + "Unknown object type";
   return(tmp_st_1);
   case 4204 :
   tmp_st_1 = Local_2_st + "No object name";
   return(tmp_st_1);
   case 4205 :
   tmp_st_1 = Local_2_st + "Object coordinates error";
   return(tmp_st_1);
   case 4206 :
   tmp_st_1 = Local_2_st + "No specified subwindow";
   return(tmp_st_1);
   case 4207 :
   tmp_st_1 = Local_2_st + "Graphical object error";
   return(tmp_st_1);
   case 4210 :
   tmp_st_1 = Local_2_st + "Unknown chart property";
   return(tmp_st_1);
   case 4211 :
   tmp_st_1 = Local_2_st + "Chart not found";
   return(tmp_st_1);
   case 4212 :
   tmp_st_1 = Local_2_st + "Chart subwindow not found";
   return(tmp_st_1);
   case 4213 :
   tmp_st_1 = Local_2_st + "Chart indicator not found";
   return(tmp_st_1);
   case 4220 :
   tmp_st_1 = Local_2_st + "Symbol select error";
   return(tmp_st_1);
   case 4250 :
   tmp_st_1 = Local_2_st + "Notification error";
   return(tmp_st_1);
   case 4251 :
   tmp_st_1 = Local_2_st + "Notification parameter error";
   return(tmp_st_1);
   case 4252 :
   tmp_st_1 = Local_2_st + "Notifications disabled";
   return(tmp_st_1);
   case 4253 :
   tmp_st_1 = Local_2_st + "Notification send too frequent";
   return(tmp_st_1);
   case 4260 :
   tmp_st_1 = Local_2_st + "FTP server is not specified";
   return(tmp_st_1);
   case 4261 :
   tmp_st_1 = Local_2_st + "FTP login is not specified";
   return(tmp_st_1);
   case 4262 :
   tmp_st_1 = Local_2_st + "FTP connection failed";
   return(tmp_st_1);
   case 4263 :
   tmp_st_1 = Local_2_st + "FTP connection closed";
   return(tmp_st_1);
   case 4264 :
   tmp_st_1 = Local_2_st + "FTP path not found on server";
   return(tmp_st_1);
   case 4265 :
   tmp_st_1 = Local_2_st + "File not found in the MQL4\\Files directory to send on FTP server";
   return(tmp_st_1);
   case 4266 :
   tmp_st_1 = Local_2_st + "Common error during FTP data transmission";
   return(tmp_st_1);
   case 5001 :
   tmp_st_1 = Local_2_st + "Too many opened files";
   return(tmp_st_1);
   case 5002 :
   tmp_st_1 = Local_2_st + "Wrong file name";
   return(tmp_st_1);
   case 5003 :
   tmp_st_1 = Local_2_st + "Too long file name";
   return(tmp_st_1);
   case 5004 :
   tmp_st_1 = Local_2_st + "Cannot open file";
   return(tmp_st_1);
   case 5005 :
   tmp_st_1 = Local_2_st + "Text file buffer allocation error";
   return(tmp_st_1);
   case 5006 :
   tmp_st_1 = Local_2_st + "Cannot delete file";
   return(tmp_st_1);
   case 5007 :
   tmp_st_1 = Local_2_st + "Invalid file handle (file closed or was not opened)";
   return(tmp_st_1);
   case 5008 :
   tmp_st_1 = Local_2_st + "Wrong file handle (handle index is out of handle table)";
   return(tmp_st_1);
   case 5009 :
   tmp_st_1 = Local_2_st + "File must be opened with FILE_WRITE flag";
   return(tmp_st_1);
   case 5010 :
   tmp_st_1 = Local_2_st + "File must be opened with FILE_READ flag";
   return(tmp_st_1);
   case 5011 :
   tmp_st_1 = Local_2_st + "File must be opened with FILE_BIN flag";
   return(tmp_st_1);
   case 5012 :
   tmp_st_1 = Local_2_st + "File must be opened with FILE_TXT flag";
   return(tmp_st_1);
   case 5013 :
   tmp_st_1 = Local_2_st + "File must be opened with FILE_TXT or FILE_CSV flag";
   return(tmp_st_1);
   case 5014 :
   tmp_st_1 = Local_2_st + "File must be opened with FILE_CSV flag";
   return(tmp_st_1);
   case 5015 :
   tmp_st_1 = Local_2_st + "File read error";
   return(tmp_st_1);
   case 5016 :
   tmp_st_1 = Local_2_st + "File write error";
   return(tmp_st_1);
   case 5017 :
   tmp_st_1 = Local_2_st + "String size must be specified for binary file";
   return(tmp_st_1);
   case 5018 :
   tmp_st_1 = Local_2_st + "Incompatible file (for string arrays-TXT, for others-BIN)";
   return(tmp_st_1);
   case 5019 :
   tmp_st_1 = Local_2_st + "File is directory not file";
   return(tmp_st_1);
   case 5020 :
   tmp_st_1 = Local_2_st + "File does not exist";
   return(tmp_st_1);
   case 5021 :
   tmp_st_1 = Local_2_st + "File cannot be rewritten";
   return(tmp_st_1);
   case 5022 :
   tmp_st_1 = Local_2_st + "Wrong directory name";
   return(tmp_st_1);
   case 5023 :
   tmp_st_1 = Local_2_st + "Directory does not exist";
   return(tmp_st_1);
   case 5024 :
   tmp_st_1 = Local_2_st + "Specified file is not directory";
   return(tmp_st_1);
   case 5025 :
   tmp_st_1 = Local_2_st + "Cannot delete directory";
   return(tmp_st_1);
   case 5026 :
   tmp_st_1 = Local_2_st + "Cannot clean directory";
   return(tmp_st_1);
   case 5027 :
   tmp_st_1 = Local_2_st + "Array resize error";
   return(tmp_st_1);
   case 5028 :
   tmp_st_1 = Local_2_st + "String resize error";
   return(tmp_st_1);
   case 5029 :
   tmp_st_1 = Local_2_st + "Structure contains strings or dynamic arrays";
   return(tmp_st_1);
   case 5200 :
   tmp_st_1 = Local_2_st + "Invalid URL";
   return(tmp_st_1);
   case 5201 :
   tmp_st_1 = Local_2_st + "Failed to connect to specified URL";
   return(tmp_st_1);
   case 5202 :
   tmp_st_1 = Local_2_st + "Timeout exceeded";
   return(tmp_st_1);
   case 5203 :
   tmp_st_1 = Local_2_st + "HTTP request failed";
   return(tmp_st_1);
 }
 tmp_st_1 = Local_2_st + "Unknown error number";
 return(tmp_st_1);
 }
//lizong_11 <<==--------   --------
 bool CCanvasX::CCanvasX_12( string Para_0_st)
 {
  //bool      Local_2_bo;
  int       Local_3_in;
  string    Local_4_st;
  int       Local_5_in;
  int       Local_6_in = 0;
  int       Local_7_in = 0;
  int       Local_8_in = 0;
  int       Local_9_in = 0;
  CFileBin  Local_10_a_162;
//----- -----

 Local_5_in = -1 ;
 Local_4_st = "" ;
 Local_3_in = 32 ;
 if ( !(ResourceReadImage(Para_0_st,m_pixels,m_width,m_height)) )
 {
    if ( Local_5_in != -1 )
   {
     FileClose(Local_5_in);
     Local_5_in = -1 ;
     Local_4_st = "" ;
     Local_3_in &=96;
   }
   ;
 }
// return(true);
 if ( Local_5_in != -1 )
 {
   FileClose(Local_5_in);
   Local_5_in = -1 ;
   Local_4_st = "" ;
   Local_3_in &=96;
 }
 return(true);
 }
//CCanvasX_12 <<==--------   --------
 void SymbolInformation::SymbolInformation_13()
 {
 }
//SymbolInformation_13 <<==--------   --------
 void SymbolInformation::SymbolInformation_14()
 {
 }
//SymbolInformation_14 <<==--------   --------
 void SymbolInformation::SymbolInformation_15()
 {
 SymbolInformation_13();
 SymbolInformation_14();
 }
//SymbolInformation_15 <<==--------   --------
 void SymbolInformation::~SymbolInformation()
 {
/*
*/
 }
//~SymbolInformation <<==--------   --------
 void CutTrade::CutTrade_17()
 {
 }
//CutTrade_17 <<==--------   --------
 void CutTrade::CutTrade_18()
 {
 }
//CutTrade_18 <<==--------   --------
 void CutTrade::CutTrade_19()
 {
 CutTrade_17();
 CutTrade_18();
 }
//CutTrade_19 <<==--------   --------
 void CutTrade::~CutTrade()
 {
/*
*/
 }
//~CutTrade <<==--------   --------
 bool lizong_21( string Para_0_st,int Para_1_in,int Para_2_in)
 {
  //bool      Local_1_bo;
  bool      Local_2_bo = false;
  int       Local_3_in;
  int       Local_4_in;
  int       Local_5_in;
  int       Local_6_in;
  int       Local_7_in;
  int       Local_8_in;
  int       Local_9_in;
  int       Local_10_in;
  int       Local_11_in;
  int       Local_12_in;
  int       Local_13_in;
  int       Local_14_in;
  string    Local_15_st;
  int       Local_16_in;
  int       Local_17_in;
//----- -----
 int        tmp_in_1;
 int        tmp_in_2;
 int        tmp_in_3;
 int        tmp_in_4;

 Local_3_in=Global_24_in + UID;
 Local_4_in=StringLen(IntegerToString(Local_3_in,0,32));
 Local_5_in=Local_3_in + int(MathPow(10.0,Local_4_in));
 Local_6_in=Local_3_in + int(MathPow(10.0,Local_4_in)) * 2;
 Local_7_in = -1 ;
 Local_8_in = -1 ;
 Local_9_in = -1 ;
 Local_10_in = -1 ;
 Local_11_in = -1 ;
 Local_12_in = -1 ;
 if ( Para_2_in == 1 )
 {
   Local_7_in = 0 ;
   Local_8_in = 0 ;
   if ( Para_1_in >= 0 )
   {
     Local_9_in=int(MathPow(10.0,StringLen(IntegerToString(Local_3_in,0,32))  + 2)) + Local_3_in * 100 + Para_1_in;
     Local_10_in = Local_9_in ;
   }
   else
   {
     Local_11_in = Local_5_in ;
     Local_12_in = Local_5_in ;
   }
 }
 if ( Para_2_in == -1 )
 {
   Local_7_in = 1 ;
   Local_8_in = 1 ;
   if ( Para_1_in >= 0 )
   {
     Local_9_in=(int(MathPow(10.0,StringLen(IntegerToString(Global_24_in + UID,0,32))  + 2))) * 2 + (Global_24_in + UID) * 100 + Para_1_in;
     Local_10_in = Local_9_in ;
   }
   else
   {
     Local_11_in = Local_6_in ;
     Local_12_in = Local_6_in ;
   }
 }
 if ( Para_2_in == 0 )
 {
   Local_7_in = 0 ;
   Local_8_in = 1 ;
   if ( Para_1_in >= 0 )
   {
     Local_9_in=int(MathPow(10.0,StringLen(IntegerToString(Global_24_in + UID,0,32))  + 2)) + (Global_24_in + UID) * 100 + Para_1_in;
     if ( Para_1_in <  0 )
     {
       tmp_in_1 = -1;
     }
     else
     {
       tmp_in_2 = Global_24_in + UID;
       tmp_in_3 = StringLen(IntegerToString(tmp_in_2,0,32)) ;
       tmp_in_4 = 0;
       if ( -1 == 1 )
       {
         tmp_in_4 = 1;
       }
       if ( -1 == -1 )
       {
         tmp_in_4 = 2;
       }
       tmp_in_1 = int(MathPow(10.0,tmp_in_3 + 2)) * tmp_in_4 + tmp_in_2 * 100 + Para_1_in;
     }
     Local_10_in = tmp_in_1 ;
   }
   else
   {
     Local_11_in = Local_5_in ;
     Local_12_in = Local_6_in ;
   }
 }
 for (Local_13_in = 0 ; Local_13_in < OrdersTotal() ; Local_13_in ++)
 {
   if ( OrderSelect(Local_13_in,0,0) )
   {
     Local_14_in = OrderType() ;
     Local_15_st = OrderSymbol() ;
     Local_16_in = OrderMagicNumber() ;
     Local_17_in=Local_16_in / 100;
     if ( Para_1_in >= 0 && Local_15_st == Para_0_st && ( ( Local_16_in == Local_9_in && Local_14_in == Local_7_in ) || (Local_16_in == Local_10_in && Local_14_in == Local_8_in) ) )
     {
       return(true);
     }
     if ( Para_1_in <  0 && Local_15_st == Para_0_st && ( ( Local_17_in == Local_11_in && Local_14_in == Local_7_in ) || (Local_17_in == Local_12_in && Local_14_in == Local_8_in) ) )
     {
       return(true);
     }
   }
   else
   {
     Print(TradeComment + " " + Para_0_st,": Failed to select an order! Error=",lizong_11(GetLastError()));
     Local_2_bo = true ;
   }
 }
 return(Local_2_bo);
 }
//lizong_21 <<==--------   --------