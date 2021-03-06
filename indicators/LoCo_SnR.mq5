//+------------------------------------------------------------------+
//|                                                     LoCo_SnR.mq5 |
//| LoCo_SnR (Local Convex Hull SnR)          Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#import "loco_snr.dll"
int Create(double,double);
int Push(int,int,double,double,datetime,datetime);//
void Destroy(int); //
int GetShiftCount(int,int);
bool GetLast(int,int,int,int &x1,double &y1,bool &is_ex,int &x2,double &y2); // 
int PushTrend(int,const double x,const double y,int dir);//
void ClearTrend(int,int dir);//
bool GetTrend(int instance,double &x,double &a,double &b,double &r,int dir);//
#import

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  1

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDodgerBlue
#property indicator_width2  1

#property indicator_type3   DRAW_SECTION
#property indicator_color3  clrSilver
#property indicator_width3  1
#property indicator_style3  STYLE_DOT

#property indicator_type4   DRAW_SECTION
#property indicator_color4  clrSilver
#property indicator_width4  1
#property indicator_style4  STYLE_DOT



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double InpScale=0.1;         // Scale x 
input int InpArmCount=7;          // Arm Count 
input bool InpShowLoCo=true;         // Show Local Convex
input int InpThreshold=250;       //  Threshold(in points)
input int InpLookBack=400;    // LookBack
input int InpLineWidth=1;    // Line Width
input color InpColor=clrLightYellow;    // Line Color
double Threshold=InpThreshold*_Point;
double ArmSize=InpScale*InpArmCount;
int WinNo=ChartWindowFind();

double UPPER[];
double UPPER_TOP[];

double LOWER[];
double LOWER_BTM[];

int instance;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

struct PointType
  {
   int               x;
   double            y;

  };

double upper[][2];
double lower[][2];

PointType NullPoint;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

   ObjectDeleteByName("LoCoSnR");
   if(InpShowLoCo)
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_ARROW);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_ARROW);
      PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_SECTION);
      PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_SECTION);
     }
   else
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE);
     }
   SetIndexBuffer(0,UPPER_TOP,INDICATOR_DATA);
   SetIndexBuffer(1,LOWER_BTM,INDICATOR_DATA);
   SetIndexBuffer(2,UPPER,INDICATOR_DATA);
   SetIndexBuffer(3,LOWER,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   instance=Create(InpScale,ArmSize); //インスタンスを生成

   NullPoint.x=0;
   NullPoint.y=0;

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   Destroy(instance); //インスタンスを破棄  

   ObjectDeleteByName("LoCoSnR");
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
      UPPER_TOP[i]=EMPTY_VALUE;
      LOWER_BTM[i]=EMPTY_VALUE;
      UPPER[i]=EMPTY_VALUE;
      LOWER[i]=EMPTY_VALUE;

      if(i<rates_total-5000)
        {
         continue;
        }

      datetime prev=(i>0) ? time[i-1]: 0;
      int n=Push(instance,i,high[i],low[i],time[i],prev);
      if(n == 0 )continue;
      if(n<0)
        {
         ArrayResize(upper,0);
         ArrayResize(lower,0);
         Print(n," ------------- Reset --------------- ",time[i]);
         Destroy(instance); //インスタンスを破棄
         instance=Create(InpScale,ArmSize); //インスタンスを生成
         return 0;
        }
      //--------------------------------------------------
      // UPPER
      //--------------------------------------------------       
      PointType h1,h2,l1,l2;
      bool h1_top;
      bool l1_btm;

      int h_push_sz=GetShiftCount(instance,1);
      int l_push_sz=GetShiftCount(instance,-1);

      PointType new_up=NullPoint;
      PointType new_dn=NullPoint;
      double temp_h[][2];
      double temp_l[][2];
      ArrayResize(temp_h,0);
      ArrayResize(temp_l,0);
      if(h_push_sz>0)
        {
         for(int k=h_push_sz-1;k>=0;k--)
           {
            if(GetLast(instance,1,k,h1.x,h1.y,h1_top,h2.x,h2.y))
              {
               if(h1_top)
                 {
                  UPPER_TOP[h1.x]=h1.y;
                  PushPoint(temp_h,h1.x,h1.y);
                 }
               UPPER[h1.x]=h1.y;
              }
           }
        }
      if(l_push_sz>0)
        {
         for(int k=l_push_sz-1;k>=0;k--)
           {
            if(GetLast(instance,-1,k,l1.x,l1.y,l1_btm,l2.x,l2.y))
              {
               if(l1_btm)
                 {
                  LOWER_BTM[l1.x]=l1.y;
                  PushPoint(temp_l,l1.x,l1.y);
                 }
               LOWER[l1.x]=l1.y;
              }
           }
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(h_push_sz>0 || l_push_sz>0)
        {
         int h_sz=ArrayRange(temp_h,0);
         int l_sz=ArrayRange(temp_l,0);
         int h_idx=-1;
         int l_idx=-1;
         while(h_idx<h_sz && l_idx<l_sz)
           {

            int h_next=(h_idx+1<h_sz )?int(temp_h[h_idx+1][1]): -1;
            int l_next=(l_idx+1<l_sz )?int(temp_l[l_idx+1][1]): -1;
            bool is_h=false;
            bool is_l=false;
            if(h_next==-1 && l_next==-1) break;
            else if((h_next==-1 && l_next!=-1) || (l_next!=-1 && l_next<h_next)) is_l=true;
            else if((h_next!=-1 && l_next==-1) || (h_next!=-1 && h_next<l_next)) is_h=true;
            else if(h_next==l_next){ is_h=true;is_l=true;}
            else
              {
               Print("Error ");
              }
            if(is_h)
              {
               ++h_idx;
               PushPoint(upper,int(temp_h[h_idx][1]),temp_h[h_idx][0]);

              }
            if(is_l)
              {
               ++l_idx;
               PushPoint(lower,int(temp_l[l_idx][1]),temp_l[l_idx][0]);
              }
           }
        }
      if(i<rates_total-2)continue;
      int h_sz= ArrayRange(upper,0);
      int l_sz= ArrayRange(lower,0);
      int h_idx=h_sz-1;
      int l_idx=l_sz-1;
      int limit=fmax(0,i-InpLookBack);
      double hist_h[];
      double hist_l[];

      double group_h[][3];
      double group_l[][3];

      ArrayResize(hist_h,0);
      ArrayResize(hist_l,0);
      ArrayResize(group_h,0);
      ArrayResize(group_l,0);

      while(h_idx>0 && l_idx>0)
        {
         if(upper[h_idx][1]>limit)
           {
            PushHist(hist_h,upper[h_idx][0]);
            --h_idx;
           }
         if(lower[l_idx][1]>limit)
           {
            PushHist(hist_l,lower[l_idx][0]);
            --l_idx;
           }
         if(upper[h_idx][1]<=limit && lower[l_idx][1]<=limit) break;

        }

      ArraySort(hist_h);
      ArraySort(hist_l);
      h_sz=ArrayRange(hist_h,0);
      l_sz=ArrayRange(hist_l,0);

      if(h_sz<5 || h_sz<5)
        {
         ObjectDeleteByName("LoCoSnR");
         continue;
        }
      double hist_max=hist_h[h_sz-1];
      double hist_min=hist_l[0];

      double prev_h=hist_h[h_sz-1];
      double resi=hist_h[h_sz-1];
      double prev_l=hist_l[0];
      double supp=hist_l[0];
      int cnt=1;
      //Print("------------------ high -----------------");
      //for(int j=h_sz-1;j>=0;j--)
      //  {
         // Print(j,",",hist_h[j]);
      //  }
      //Print("------------------ low -----------------");
      //for(int j=l_sz-1;j>=0;j--)
      //  {
         //Print(j,",",hist_l[j]);
      //  }
      Print("Threshold:",Threshold);       
      Print("------------------ high -----------------");
      for(int j=h_sz-2;j>=0;j--)
        {
         Print(prev_h," - ",hist_h[j]," = ",prev_h-hist_h[j]);
         if((prev_h-hist_h[j])<=Threshold)
           {
            prev_h=hist_h[j];
            cnt++;
           }
         else
           {
            PushGroup(group_h,hist_h[j+1],resi,cnt);
            cnt=1;
            resi=hist_h[j];
            prev_h=hist_h[j];

           }
        }
      Print("------------------ low -----------------");

      cnt=1;
      for(int j=1;j<l_sz;j++)
        {
         if((hist_l[j]-prev_l)<=Threshold)
           {
            prev_l=hist_l[j];
            cnt++;
           }
         else
           {
            PushGroup(group_l,supp,hist_l[j-1],cnt);
            cnt=1;
            supp=hist_l[j];
            prev_l=hist_l[j];
           }
        }

/*
(high)
0:113.586	113.588	2
1:112.479	113.089	9
2:112.149	112.149	1
(low)		
0:111.055	111.055	1
1:111.373	111.404	2
2:111.734	111.772	2
3:111.988	111.988	1
4:112.28	112.362	2
5:112.79	112.79	1

*/
      int no=0;
      h_sz=ArrayRange(group_h,0);
      l_sz=ArrayRange(group_l,0);
      if(h_sz==0 && l_sz==0)
        {

         ObjectDeleteByName("LoCoSnR");
         ObjectCreate(WinNo,StringFormat("LoCoSnR_%d",1),OBJ_HLINE,0,0,hist_max);
         ObjectSetInteger(0,StringFormat("LoCoSnR_%d",1),OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0,StringFormat("LoCoSnR_%d",1),OBJPROP_WIDTH,InpLineWidth);
         ObjectCreate(WinNo,StringFormat("LoCoSnR_%d",2),OBJ_HLINE,0,0,hist_min);
         ObjectSetInteger(0,StringFormat("LoCoSnR_%d",2),OBJPROP_COLOR,clrDodgerBlue);
         ObjectSetInteger(0,StringFormat("LoCoSnR_%d",2),OBJPROP_WIDTH,InpLineWidth);
         ChartRedraw(WinNo);
         continue;
        }
      double arr_snr[];
          Print("------------------ high -----------------");
      l_idx=ArrayRange(group_l,0)-1;
      for(int j=0;j<h_sz;j++)
        {
         resi=group_h[j][1];
         l_idx=find_support(group_l,resi,l_idx);
         if(l_idx!=-1)
           {
            double lmin=group_l[l_idx][0];
            double lmax=group_l[l_idx][1];
            int lcnt=int(group_l[l_idx][2]);
            if(lmin<resi && resi<lmax && lcnt>2)
              {
               //ng ->skip
               continue;
              }
           }
         //ok ->push
         no++;
         ArrayResize(arr_snr,no);
         arr_snr[no-1]=resi;
        }
            Print("------------------ low -----------------");
      h_idx=ArrayRange(group_h,0)-1;

      for(int j=0;j<ArrayRange(group_l,0);j++)
        {
         supp = group_l[j][0];
         h_idx=find_resistance(group_h,supp,h_idx);
         if(h_idx!=-1)
           {

            double hmin=group_h[h_idx][0];
            double hmax=group_h[h_idx][1];
            int hcnt=int(group_h[h_idx][2]);
            if(hmin<supp && supp<hmax && hcnt>2)
              {
               //ng ->skip
               continue;
              }
           }

         //ok ->push
         no++;
         ArrayResize(arr_snr,no);
         arr_snr[no-1]=supp;

        }


      ObjectDeleteByName("LoCoSnR");


      if(no>0)
        {
         for(int j=0;j<no;++j)
           {
            if(hist_max==arr_snr[j] || arr_snr[j]==hist_min)continue;
            ObjectCreate(WinNo,StringFormat("LoCoSnR_%d",j+1),OBJ_HLINE,0,0,arr_snr[j]);
            ObjectSetInteger(0,StringFormat("LoCoSnR_%d",j+1),OBJPROP_COLOR,InpColor);
            ObjectSetInteger(0,StringFormat("LoCoSnR_%d",j+1),OBJPROP_WIDTH,InpLineWidth);
           }

        }
      no++;
      ObjectCreate(WinNo,StringFormat("LoCoSnR_%d",no),OBJ_HLINE,0,0,hist_max);
      ObjectSetInteger(0,StringFormat("LoCoSnR_%d",no),OBJPROP_COLOR,InpColor);
      ObjectSetInteger(0,StringFormat("LoCoSnR_%d",no),OBJPROP_WIDTH,InpLineWidth);
      no++;
      ObjectCreate(WinNo,StringFormat("LoCoSnR_%d",no),OBJ_HLINE,0,0,hist_min);
      ObjectSetInteger(0,StringFormat("LoCoSnR_%d",no),OBJPROP_COLOR,InpColor);
      ObjectSetInteger(0,StringFormat("LoCoSnR_%d",no),OBJPROP_WIDTH,InpLineWidth);
      ChartRedraw(WinNo);

     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int find_support(double &group[][3],const double resi,const int ifrom)
  {
   int sz=ArrayRange(group,0);
   if(sz==0) return -1;
   int ifm=fmin(sz-1,ifrom);
   for(int i=ifm; i>=0;--i)
     {
      if(group[i][0]<resi) return i;
     }
   return -1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int find_resistance(double &group[][3],const double supp,const int ifrom)
  {
   int sz=ArrayRange(group,0);
   if(sz==0) return -1;


   int ifm=fmin(sz-1,ifrom);
   for(int i=ifm; i>=0;--i)
     {
      if(group[i][1]>supp) return i;
     }
   return -1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int last_max(const double &arr[][2],const int period)
  {
   int sz=ArrayRange(arr,0);
   if(sz < period)return -1;
   return ArrayMaximum(arr,sz-(period),period);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int last_min(const double &arr[][2],const int period)
  {
   int sz=ArrayRange(arr,0);
   if(sz < period)return -1;
   return ArrayMinimum(arr,sz-(period),period);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int PushPoint(double &arr[][2],const int x,const double y)
  {
   int sz=ArrayRange(arr,0)+1;
   ArrayResize(arr,sz);
   arr[sz-1][1]=x;
   arr[sz-1][0]=y;

   return sz;
  }
//+------------------------------------------------------------------+

int PushHist(double &arr[],const double y)
  {
   int sz=ArrayRange(arr,0)+1;
   ArrayResize(arr,sz);
   arr[sz-1]=y;
   return sz;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int PushGroup(double &arr[][3],const double min,const double max,const int cnt)
  {
   int sz=ArrayRange(arr,0)+1;
   ArrayResize(arr,sz);
   arr[sz-1][0]=min;
   arr[sz-1][1]=max;
   arr[sz-1][2]=cnt;
   return sz;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByName(string prefix)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         ObjectDelete(0,objName);
        }
     }
  }
//+------------------------------------------------------------------+
