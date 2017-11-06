//+------------------------------------------------------------------+
//|                                                      Concave.mq5 |
//| Concave                                   Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#import "concave.dll"
int Create(int,double,int);
int Push(int,int,double,double,datetime,datetime);//
int Calculate(int); // 
void Destroy(int); // 
bool GetResults(int,int,int &x,double &y); // 
#import

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrOrangeRed
#property indicator_width1  2
#property indicator_type2   DRAW_SECTION
#property indicator_color2  clrOrangeRed
#property indicator_width2  2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpPeriod=200;           // Period
input double InpScale=0.1;         // Scale x 

input int InpK=5;           // K
double UPPER[];
double LOWER[];

int instance;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,UPPER,INDICATOR_DATA);
   SetIndexBuffer(1,LOWER,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);   
   instance=Create(InpPeriod,InpScale,InpK); //インスタンスを生成
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Destroy(instance); //インスタンスを破棄  
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])

  {

   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {
     
       
      datetime prev=(i>0) ? time[i-1]: 0;
      int n= Push(instance,i,high[i],low[i],time[i],prev);
      if(n == -1 )continue;
      if(n == -9999)
        {
         Print(i," ",time[i]);
         Print(n," ------------- Reset --------------- ",time[i]);
         Destroy(instance); //インスタンスを破棄
         instance=Create(InpPeriod,InpScale,InpK); //インスタンスを生成
         return 0;
        }

      if(i<=rates_total-2)continue;
      if(i<=InpPeriod)continue;
      int sz=Calculate(instance);
      if(sz>0)
        {
         int length= ArraySize(UPPER);
         
         ArrayFill(UPPER,0,length,EMPTY_VALUE);
         ArrayFill(LOWER,0,length,EMPTY_VALUE);
         for(int j=0;j<sz;j++)
           {           
            int x;
            double y;
            if(GetResults(instance,j,x,y))
              {
               int ii=i-(InpPeriod-x);
               if(high[ii]==y)
                 {
                  UPPER[ii]=y;
                 }
               else if(low[ii]==y)
                 {
                  LOWER[ii]=y;
                 }
               else
                 {
                 
                 if((high[ii]+low[ii])*0.5<y)
                    UPPER[ii]=y;             
                 else
                    LOWER[ii]=y;
                 
                 }
              }
           }
        }
     }

   return(rates_total);


  }
//+------------------------------------------------------------------+
