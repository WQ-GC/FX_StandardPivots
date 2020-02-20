#property strict

#property indicator_chart_window
#property indicator_buffers 11
#property indicator_color1  Gold
#property indicator_color2  Aqua
#property indicator_color3  Aqua
#property indicator_color4  Magenta
#property indicator_color5  Red
#property indicator_color6  Red
#property indicator_color7  Red
#property indicator_color8  White
#property indicator_color9  DodgerBlue
#property indicator_color10 DodgerBlue
#property indicator_color11 DodgerBlue

#define MAX_BUFFERS       11
#define FX_OPEN_HOUR      0
#define FX_OPEN_MIN       0
#define DECIMAL_DIGITS    5

enum PrevDayType{
  GET_PDH,
  GET_PDL,
  GET_PDC,
};

//Buffers
double Ind_OP[];
double Ind_PDH[];
double Ind_PDL[];
double Ind_PDC[];
double Ind_R3[];
double Ind_R2[];
double Ind_R1[];
double Ind_PP[];
double Ind_S1[];
double Ind_S2[];
double Ind_S3[];

struct FullPivotLevelsType{
  //Simple structure, no need to overload!
  double PDH;
  double PDL;
  double PDC;
};

FullPivotLevelsType prevPivotData;
FullPivotLevelsType nextPivotData;


int OnInit() {
  int totalBars = IndicatorCounted();
  //Print("Total handled bars after calculation ", IndicatorCounted());
  //Print("Total Bars in Chart: ", Bars);

  MapIndicatorBuffers();

  for(int i = 0; i < MAX_BUFFERS; i++) {
    SetIndexStyle(i,DRAW_LINE);
  }

  return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
  //Note: First run of OnCalculate() will compute indicator 
  //starting from 0 to end of database
  //limit == earlist candle in Chart
  static double currOP = 0;
  int limit = rates_total - prev_calculated; 
  //Print("limit: " + IntegerToString(limit));
  //Print("rates_total: " + IntegerToString(rates_total));
  //Print("prev_calculated: " + IntegerToString(prev_calculated));
  for(int i = 0; i < limit; i++)
  { 
    //Comment("i: " + IntegerToString(i) + 
    //        "\nlimit: " + IntegerToString(limit) +
    //        "\nrates_total: " + IntegerToString(rates_total) +
    //        "\nprev_calculated: " + IntegerToString(prev_calculated) + 
    //        "\nTime[" + IntegerToString(i) + "]: " + TimeToString(time[i]) +
    //        "\nTime[" + IntegerToString(0) + "]: " + TimeToString(time[0])
    //        );

    //Print("i: " + IntegerToString(i));
    //Print("rates_total: " + IntegerToString(rates_total));
    //Print("prev_calculated: " + IntegerToString(prev_calculated));
    //Print("limit: " + IntegerToString(limit));
    //Print("Time[" + IntegerToString(i) + "]: " + TimeToString(time[i]));
    //Print("Time[0]: " + TimeToString(time[0]));


/*
    if(((i == 0) || (i < (limit-1))) && (ComputeNewDay(i))){// && time[count] != lastNewDay) {
      //Print("Prev Day: " + TimeToStr(time[i+1]));  
      //Print(i + "   New Day:  " + TimeToStr(time[i]));      
      //Print("OP: " + DoubleToStr(open[i]) + "  - " + TimeToStr(time[i]));

      //currOP = open[i];//since today is New Day, the OP is this candle
      
      
    }
    else {
    }
*/    
    //For middle of the day, backtrack OP data
    currOP = GetOpenOP(time[i]);

    //pivotDate contains today's OP and Previous day's H,L,C
    GetPrevHLC(time[i], prevPivotData);



    //all buffers will be updated
    UpdateBuffers(i, prevPivotData, currOP);//display current buffers
  } 
 
  //return value of prev_calculated for next call 
  return(rates_total);
}

double GetOpenOP(datetime inTime) {
  MqlDateTime inTimeInfo;
  TimeToStruct(inTime, inTimeInfo);
  inTimeInfo.hour = FX_OPEN_HOUR;
  inTimeInfo.min = FX_OPEN_MIN;
  inTimeInfo.sec = 0;
  inTime = StructToTime(inTimeInfo);
  int OpenBarShift = iBarShift(Symbol(),PERIOD_CURRENT, inTime);

  return iOpen(Symbol(), PERIOD_CURRENT, OpenBarShift);
}

void GetPrevHLC(datetime inCurrTDate, FullPivotLevelsType& outPivotData) {
  //Get today's open bar
  datetime openTime = inCurrTDate;
  MqlDateTime openTimeInfo;
  TimeToStruct(openTime, openTimeInfo);
  openTimeInfo.hour = FX_OPEN_HOUR;
  openTimeInfo.min  = FX_OPEN_MIN;
  openTimeInfo.sec  = 0;
  openTime = StructToTime(openTimeInfo);
  
  //Get bar count for today
  int openBarShift = iBarShift(Symbol(),PERIOD_CURRENT, openTime);
  
  //Get prev bar count for prev day
  int prevBarShift = openBarShift + 1;
  
  if(prevBarShift > Bars-1) {
    outPivotData.PDH = 0;
    outPivotData.PDL = 0;
    outPivotData.PDC = 0;
    return;//no previous day
  }
  else {
    //Print("prevBarShift: " + IntegerToString(prevBarShift) + "   " + TimeToStr(Time[prevBarShift]));
    //Print("openBarShift: " + IntegerToString(openBarShift) + "   " + TimeToStr(Time[openBarShift]));
    //prevBarShift is the prev day's last candle
    outPivotData.PDH = GetPrevDay(prevBarShift, GET_PDH);
    outPivotData.PDL = GetPrevDay(prevBarShift, GET_PDL);
    outPivotData.PDC = GetPrevDay(prevBarShift, GET_PDC);
  }
}

double GetPrevDay(int inPrevBar, PrevDayType inPrevDay){
  if(inPrevDay == GET_PDC) {
    return NormalizeDouble(iClose(Symbol(), PERIOD_CURRENT, inPrevBar), DECIMAL_DIGITS);
  }
  
  else {
    datetime prevDayOpenTime = Time[inPrevBar];
    MqlDateTime prevDayOpenTimeInfo;
    TimeToStruct(prevDayOpenTime, prevDayOpenTimeInfo);
    prevDayOpenTimeInfo.hour = FX_OPEN_HOUR;
    prevDayOpenTimeInfo.min  = FX_OPEN_MIN;
    prevDayOpenTimeInfo.sec  = 0;
    prevDayOpenTime = StructToTime(prevDayOpenTimeInfo);
    //Print("prevDayOpenTime:  " + TimeToStr(prevDayOpenTime));
    
    //Search back till prev Day
    int barShift = inPrevBar;
    datetime tempTime = prevDayOpenTime;
    int tempBarShift = iBarShift(Symbol(),PERIOD_CURRENT, tempTime);
    double tempValue = 0;

    if(inPrevDay == GET_PDH) {
      double maxValue = NormalizeDouble(iHigh(Symbol(), PERIOD_CURRENT, tempBarShift), DECIMAL_DIGITS);

      while(tempTime <= Time[inPrevBar]) {
        tempBarShift = iBarShift(Symbol(),PERIOD_CURRENT, tempTime);
        //Search for HIGH
        tempValue = NormalizeDouble(iHigh(Symbol(), PERIOD_CURRENT, tempBarShift), DECIMAL_DIGITS);
  
        if(tempValue > maxValue) {
          maxValue = tempValue;
          barShift = tempBarShift;
        }
        tempTime += (Period()*60);
      }
      //Print("highBarShift: " + IntegerToString(barShift));
      //Print("outPivotData.PDH: " + DoubleToString(tempValue));
      return maxValue;
    }
    else {
      double minValue = NormalizeDouble(iLow(Symbol(), PERIOD_CURRENT, tempBarShift), DECIMAL_DIGITS);

      while(tempTime <= Time[inPrevBar]) {
        tempBarShift = iBarShift(Symbol(),PERIOD_CURRENT, tempTime);
        //Search for LOW
        tempValue = NormalizeDouble(iLow(Symbol(), PERIOD_CURRENT, tempBarShift), DECIMAL_DIGITS);

        if(tempValue < minValue) {
          minValue = tempValue;
          barShift = tempBarShift;
        }
        tempTime += (Period()*60);
      }
      //Print("LowBarShift: " + IntegerToString(barShift));
      //Print("outPivotData.PDH: " + DoubleToString(tempValue));
      return minValue;
    }
  }
}




//Precondition is that this function is a New Trading Day
datetime GetPrevTradingDay(int barCount) {
  datetime currDateTime = Time[barCount];
  datetime prevDateTime = Time[barCount+1];
  MqlDateTime prevDateInfo;
  MqlDateTime currDateInfo;

  TimeToStruct(prevDateTime, prevDateInfo);
  TimeToStruct(currDateTime, currDateInfo);

  //Print("  barCount: " + barCount);
  //Print("  Curr Day: " + currDateInfo.day + "/" + currDateInfo.mon + "/" + currDateInfo.year);
  //Print("  Prev Day: " + prevDateInfo.day + "/" + prevDateInfo.mon + "/" + prevDateInfo.year);

  return prevDateTime;
}


//returns status if New Day has occurred
bool ComputeNewDay(int barCount) {
  bool newDay = true;

  datetime openTDay   = Time[barCount];
  datetime prevCandle = Time[barCount+1];
  datetime currCandle = Time[barCount];

  MqlDateTime openTDayInfo;
  MqlDateTime prevTimeInfo;
  MqlDateTime currTimeInfo;
  
  TimeToStruct(openTDay,  openTDayInfo);

  //Assume currCandle is a new day (set to Start of Trading Day)
  openTDayInfo.hour = FX_OPEN_HOUR;
  openTDayInfo.min  = FX_OPEN_MIN;
  openTDayInfo.sec  = 0;

  openTDay = StructToTime(openTDayInfo);

  if(prevCandle < openTDay && openTDay <= currCandle ) {
    //Prev Candle time is not at start T Day
    newDay = true;
    //Print("New day (Start T time must be btw 2 candles)");
    //Print("New Day");
    //Print("  Prev : " + TimeToStr(Time[barCount+1]));    
    //Print("  Start: " + TimeToStr(openTDay));
    //Print("  Curr : " + TimeToStr(Time[barCount]));
  }
  else {
    newDay = false;
    //Print("  Same day");
    //Print("    Prev : " + TimeToStr(Time[barCount+1]));    
    //Print("    Start: " + TimeToStr(openTDay));
    //Print("    Curr : " + TimeToStr(Time[barCount]));
  } 
  return newDay;
}


void UpdateBuffers(int barCount, FullPivotLevelsType& inPivot, double inOP) {
  Ind_OP[barCount]  = inOP;
  Ind_PDH[barCount] = inPivot.PDH;
  Ind_PDL[barCount] = inPivot.PDL;
  Ind_PDC[barCount] = inPivot.PDC;
  
  //Standard Pivots
  Ind_PP[barCount] = (Ind_PDH[barCount] + Ind_PDL[barCount] + Ind_PDC[barCount]) / 3;
  Ind_R3[barCount] = Ind_PDH[barCount] + (2 * (Ind_PP[barCount] - Ind_PDL[barCount]));
  Ind_R2[barCount] = Ind_PP[barCount] + (Ind_PDH[barCount] - Ind_PDL[barCount]);
  Ind_R1[barCount] = (2 * Ind_PP[barCount]) - Ind_PDL[barCount];
  Ind_S1[barCount] = (2 * Ind_PP[barCount]) - Ind_PDH[barCount];
  Ind_S2[barCount] = Ind_PP[barCount] - (Ind_PDH[barCount] - Ind_PDL[barCount]);
  Ind_S3[barCount] = Ind_PDL[barCount] - (2 * (Ind_PDH[barCount] - Ind_PP[barCount]));  
}

void MapIndicatorBuffers() {
  IndicatorBuffers(MAX_BUFFERS);
  SetIndexBuffer(0, Ind_OP);        SetIndexLabel(0,"OP");
  SetIndexBuffer(1, Ind_PDH);       SetIndexLabel(1,"PDH");
  SetIndexBuffer(2, Ind_PDL);       SetIndexLabel(2,"PDL");
  SetIndexBuffer(3, Ind_PDC);       SetIndexLabel(3,"PDC");
  SetIndexBuffer(4, Ind_R3);        SetIndexLabel(4,"R3");
  SetIndexBuffer(5, Ind_R2);        SetIndexLabel(5,"R2");
  SetIndexBuffer(6, Ind_R1);        SetIndexLabel(6,"R1");
  SetIndexBuffer(7, Ind_PP);        SetIndexLabel(7,"PP");
  SetIndexBuffer(8, Ind_S1);        SetIndexLabel(8,"S1");
  SetIndexBuffer(9, Ind_S2);        SetIndexLabel(9,"S2");
  SetIndexBuffer(10,Ind_S3);        SetIndexLabel(10,"S3");
}