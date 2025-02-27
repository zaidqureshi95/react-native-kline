//
//  KLinePainterView.m
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//
#import "KLinePainterView.h"
#import "MainChartRenderer.h"
#import "VolChartRenderer.h"
#import "SecondaryChartRenderer.h"
#import "ChartStyle.h"
#import "NSString+Rect.h"
#import "KLineStateManager.h"

@interface KLinePainterView()
@property(nonatomic,assign) CGFloat displayHeight;
@property(nonatomic,strong) MainChartRenderer *mainRenderer;
@property(nonatomic,strong) VolChartRenderer *volRenderer;
@property(nonatomic,strong) SecondaryChartRenderer *seconderyRender;
@property(nonatomic,strong) SecondaryChartRenderer *tertiaryRenderer; // MACD Renderer
@property(nonatomic,strong) SecondaryChartRenderer *quaternaryRenderer; // RSI Renderer
@property(nonatomic,assign) CGRect mainRect;
@property(nonatomic,assign) CGRect volRect;
@property(nonatomic,assign) CGRect secondaryRect;
@property(nonatomic,assign) CGRect tertiaryRect; // MACD Rect
@property(nonatomic,assign) CGRect quaternaryRect; // RSI Rect
@property(nonatomic,assign) CGRect dateRect;
@property(nonatomic,assign) NSUInteger startIndex;
@property(nonatomic,assign) NSUInteger stopIndex;
@property(nonatomic,assign) NSUInteger mMainMaxIndex;
@property(nonatomic,assign) NSUInteger mMainMinIndex;

@property(nonatomic,assign) CGFloat mMainMaxValue;
@property(nonatomic,assign) CGFloat mMainMinValue;

@property(nonatomic,assign) CGFloat mVolMaxValue;
@property(nonatomic,assign) CGFloat mVolMinValue;

@property(nonatomic,assign) CGFloat mSecondaryMaxValue;
@property(nonatomic,assign) CGFloat mSecondaryMinValue;

@property(nonatomic,assign) CGFloat mTertiaryMaxValue; // MACD Max Value
@property(nonatomic,assign) CGFloat mTertiaryMinValue; // MACD Min Value

@property(nonatomic,assign) CGFloat mQuaternaryMaxValue; // RSI Max Value
@property(nonatomic,assign) CGFloat mQuaternaryMinValue; // RSI Min Value

@property(nonatomic,assign) CGFloat mMainHighMaxValue;
@property(nonatomic,assign) CGFloat mMainLowMinValue;
@property(nonatomic, assign) CGFloat mWRMaxValue; // WR Max Value
@property(nonatomic, assign) CGFloat mWRMinValue; // WR Min Value
@property(nonatomic,assign) CGFloat candleWidth;
//var fromat: String = "yyyy-MM-dd"
@property(nonatomic,copy) NSString *fromat;

@end

@implementation KLinePainterView

#define MAIN_CHART_HEIGHT 180.0
#define INDICATOR_HEIGHT  58.0

- (void)setDatas:(NSArray<KLineModel *> *)datas {
    _datas = datas;
    [self setNeedsDisplay];
}

-(void)setScrollX:(CGFloat)scrollX {
    _scrollX = scrollX;
    [self setNeedsDisplay];
}

-(void)setIsLine:(BOOL)isLine {
    _isLine = isLine;
    [self setNeedsDisplay];
}
- (void)setShowKDJ:(BOOL)showKDJ {
    _showKDJ = showKDJ;
    [self setNeedsDisplay];
}

- (void)setShowMACD:(BOOL)showMACD {
    _showMACD = showMACD;
    [self setNeedsDisplay];
}
- (void)setShowRSI:(BOOL)showRSI {
    _showRSI = showRSI;
    [self setNeedsDisplay];
}
-(void)setScaleX:(CGFloat)scaleX {
    _scaleX = scaleX;
    self.candleWidth = scaleX * ChartStyle_candleWidth;
    [self setNeedsDisplay];
}
- (void)setShowWR:(BOOL)showWR { // Add this method
    _showWR = showWR;
    [self setNeedsDisplay];
}
- (void)setIsLongPress:(BOOL)isLongPress {
    _isLongPress = isLongPress;
    [self setNeedsDisplay];
}

-(void)setMainState:(MainState)mainState {
    _mainState = mainState;
    [self setNeedsDisplay];
}

- (void)setSecondaryState:(SecondaryState)secondaryState {
    _secondaryState = secondaryState;
    [self setNeedsDisplay];
}

- (void)setVolState:(VolState)volState {
    _volState = volState;
    [self setNeedsDisplay];
}

- (void)setMainBackgroundColor:(NSString *)mainBackgroundColor {
    _mainBackgroundColor = mainBackgroundColor;
    self.mainRenderer.mainBackgroundColor = mainBackgroundColor;
    [self setNeedsDisplay];
}

- (void)setSelectedDuration:(NSString *)selectedDuration {
    _selectedDuration = selectedDuration;
    [self calculateFormats];
    [self setNeedsDisplay];
}

- (instancetype)initWithFrame:(CGRect)frame
                        datas:(NSArray<KLineModel *> *)datas
                      scrollX:(CGFloat)scrollX
                       isLine:(BOOL)isLine
                       scaleX:(CGFloat)scaleX
                  isLongPress:(BOOL)isLongPress
                    mainState:(MainState)mainState
               secondaryState:(SecondaryState)secondaryState
             selectedDuration:(NSString *)selectedDuration { // Implement this initializer
    self = [super initWithFrame:frame];
    if (self) {
        self.datas = datas;
        self.scrollX = scrollX;
        self.isLine = isLine;
        self.scaleX = scaleX;
        self.isLongPress = isLongPress;
        self.mainState = mainState;
        self.secondaryState = secondaryState;
        self.candleWidth = ChartStyle_candleWidth * self.scaleX;
        self.selectedDuration = selectedDuration; // Set the selected duration
    }
   
    return self;
}

- (void)calculateFormats {
    if (self.datas.count < 2) { return; }
    NSTimeInterval fristtime = 0;
    NSTimeInterval secondTime = 0;
    NSTimeInterval time = ABS(fristtime - secondTime);
    if ([self.selectedDuration isEqualToString:@"1D" ] || [self.selectedDuration isEqualToString:@"1Min"]|| [self.selectedDuration isEqualToString:@"5M"]|| [self.selectedDuration isEqualToString:@"10M"]|| [self.selectedDuration isEqualToString:@"30M"]|| [self.selectedDuration isEqualToString:@"1H"]) {
        self.fromat = @"HH:mm";
    } else if ([self.selectedDuration isEqualToString:@"5D"] || [self.selectedDuration isEqualToString:@"1M"] || [self.selectedDuration isEqualToString:@"3M"]) {
        self.fromat = @"MM-dd";
    } else {
        self.fromat = @"yyyy-MM";
    }
}
- (void)drawRect:(CGRect)rect {
    _displayHeight = rect.size.height - ChartStyle_topPadding - ChartStyle_bottomDateHigh;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if(context != NULL) {
        [self divisionRect];
        [self calculateValue];
        [self calculateFormats];
        [self initRenderer];
        [self drawBgColor:context rect:rect];
        [self drawGrid:context];
        if(self.datas.count == 0) { return; }
        [self drawChart:context];
        [self drawRightText:context];
        [self drawDate:context];
        [self drawMaxAndMin:context];
        
        // Always draw the tooltip instead of only on long press
        [self drawLongPressCrossLine:context];

        [self drawRealTimePrice:context];
    }
}

// - (void)drawRect:(CGRect)rect {
//     _displayHeight = rect.size.height - ChartStyle_topPadding - ChartStyle_bottomDateHigh;
    
//     CGContextRef context = UIGraphicsGetCurrentContext();
//     if(context != NULL) {
//         [self divisionRect];
//         [self calculateValue];
//         [self calculateFormats];
//         [self initRenderer];
//         [self drawBgColor:context rect:rect];
//         [self drawGrid:context];
//         if(self.datas.count == 0) { return; }
//         [self drawChart:context];
//         [self drawRightText:context];
//         [self drawDate:context];
//         [self drawMaxAndMin:context];
//         if(_isLongPress) {
//             [self drawLongPressCrossLine:context];
//         } else {
//             [self drawTopText:context curPoint:self.datas.firstObject];
//         }
//         [self drawRealTimePrice:context];
//     }
// }

-(void)divisionRect {
    CGFloat volHeight = (_volState != VolStateNONE) ? INDICATOR_HEIGHT : 0;
    CGFloat secondaryHeight = _showKDJ ? INDICATOR_HEIGHT : 0;
    CGFloat tertiaryHeight = _showMACD ? INDICATOR_HEIGHT : 0;
    CGFloat quaternaryHeight = _showRSI ? INDICATOR_HEIGHT : 0;
    CGFloat wrHeight = _showWR ? INDICATOR_HEIGHT : 0; // Add this line
    CGFloat dateHeight = ChartStyle_bottomDateHigh;

    self.mainRect = CGRectMake(0, ChartStyle_topPadding, self.frame.size.width, MAIN_CHART_HEIGHT);

    CGFloat currentY = CGRectGetMaxY(self.mainRect);

    if (_volState != VolStateNONE) {
        self.volRect = CGRectMake(0, currentY, self.frame.size.width, volHeight);
        currentY = CGRectGetMaxY(self.volRect);
    } else {
        self.volRect = CGRectZero;
    }

    if (_showKDJ) {
        self.secondaryRect = CGRectMake(0, currentY, self.frame.size.width, secondaryHeight);
        currentY = CGRectGetMaxY(self.secondaryRect);
    } else {
        self.secondaryRect = CGRectZero;
    }

    if (_showMACD) {
        self.tertiaryRect = CGRectMake(0, currentY, self.frame.size.width, tertiaryHeight);
        currentY = CGRectGetMaxY(self.tertiaryRect);
    } else {
        self.tertiaryRect = CGRectZero;
    }

    if (_showRSI) {
        self.quaternaryRect = CGRectMake(0, currentY, self.frame.size.width, quaternaryHeight);
        currentY = CGRectGetMaxY(self.quaternaryRect);
    } else {
        self.quaternaryRect = CGRectZero;
    }

    if (_showWR) { // Add this block
        self.wrRect = CGRectMake(0, currentY, self.frame.size.width, wrHeight);
        currentY = CGRectGetMaxY(self.wrRect);
    } else {
        self.wrRect = CGRectZero;
    }

    self.dateRect = CGRectMake(0, currentY, self.frame.size.width, dateHeight);
}
-(void)calculateValue {
    if(self.datas.count == 0) { return; }
    CGFloat itemWidth = _candleWidth + ChartStyle_canldeMargin;
    if(_scrollX <= 0) {
        self.startX = -_scrollX;
        self.startIndex = 0;
    } else {
        CGFloat start = _scrollX / itemWidth;
        CGFloat offsetX = 0;
        if(floor(start) == ceil(start)) {
            _startIndex = (NSUInteger)floor(start);
        } else {
            _startIndex = (NSUInteger)(floor(_scrollX / itemWidth));
            offsetX = (CGFloat)_startIndex * itemWidth - _scrollX;
        }
        self.startX = offsetX;
    }
    NSUInteger diffIndex = (NSUInteger)(ceil(self.frame.size.width - self.startX) / itemWidth);
    _stopIndex = MIN(_startIndex + diffIndex, self.datas.count - 1);
    _mMainMaxValue = -CGFLOAT_MAX;
    _mMainMinValue = CGFLOAT_MAX;
    _mMainHighMaxValue = -CGFLOAT_MAX;
    _mMainLowMinValue = CGFLOAT_MAX;
    _mVolMaxValue = -CGFLOAT_MAX;
    _mVolMinValue = CGFLOAT_MAX;
    _mSecondaryMaxValue = -CGFLOAT_MAX;
    _mSecondaryMinValue = CGFLOAT_MAX;
    _mTertiaryMaxValue = -CGFLOAT_MAX; // Initialize MACD max value
    _mTertiaryMinValue = CGFLOAT_MAX; // Initialize MACD min value
    _mQuaternaryMaxValue = -CGFLOAT_MAX; // Initialize RSI max value
    _mQuaternaryMinValue = CGFLOAT_MAX; // Initialize RSI min value
    _mWRMaxValue = -CGFLOAT_MAX; // Initialize WR max value
    _mWRMinValue = CGFLOAT_MAX; // Initialize WR min value
    for (NSUInteger index = _startIndex; index <= _stopIndex; index++) {
        KLineModel *item = self.datas[index];
        [self getMianMaxMinValue:item i:index];
        [self getVolMaxMinValue:item];
        [self getSecondaryMaxMinValue:item];
        [self getTertiaryMaxMinValue:item]; // Calculate MACD max and min values
        [self getQuaternaryMaxMinValue:item]; // Calculate RSI max and min values
        [self getWRMaxMinValue:item]; // Calculate WR max and min values
    }
}

-(void)getMianMaxMinValue:(KLineModel *)item i:(NSUInteger)i {
    if (_isLine == true) {
        _mMainMaxValue = MAX(_mMainMaxValue, item.close);
        _mMainMinValue = MIN(_mMainMinValue, item.close);
    } else {
        CGFloat maxPrice = item.high;
        CGFloat minPrice = item.low;
        if (_mainState == MainStateMA) {
            if(item.MA5Price != 0){
                maxPrice = MAX(maxPrice, item.MA5Price);
                minPrice = MIN(minPrice, item.MA5Price);
            }
            if(item.MA10Price != 0){
                maxPrice = MAX(maxPrice, item.MA10Price);
                minPrice = MIN(minPrice, item.MA10Price);
            }
            if(item.MA20Price != 0){
                maxPrice = MAX(maxPrice, item.MA20Price);
                minPrice = MIN(minPrice, item.MA20Price);
            }
            if(item.MA30Price != 0){
                maxPrice = MAX(maxPrice, item.MA30Price);
                minPrice = MIN(minPrice, item.MA30Price);
            }
        } else if (_mainState == MainStateBOLL) {
            if(item.up != 0){
                maxPrice = MAX(item.up, item.high);
            }
            if(item.dn != 0){
                minPrice = MIN(item.dn, item.low);
            }
        }
        _mMainMaxValue = MAX(_mMainMaxValue, maxPrice);
        _mMainMinValue = MIN(_mMainMinValue, minPrice);

        if (_mMainHighMaxValue < item.high) {
            _mMainHighMaxValue = item.high;
            _mMainMaxIndex = i;
        }
        if (_mMainLowMinValue > item.low) {
            _mMainLowMinValue = item.low;
            _mMainMinIndex = i;
        }
    }
}
-(void)getWRMaxMinValue:(KLineModel *)item {
    if (item.r != CGFLOAT_MAX) { // Exclude invalid WR values
        _mWRMaxValue = MAX(_mWRMaxValue, item.r);
        _mWRMinValue = MIN(_mWRMinValue, item.r);
    }
}

-(void)getVolMaxMinValue:(KLineModel *)item {
    _mVolMaxValue = MAX(_mVolMaxValue, MAX(item.vol, MAX(item.MA5Volume, item.MA10Volume)));
    _mVolMinValue = MIN(_mVolMinValue, MIN(item.vol, MIN(item.MA5Volume, item.MA10Volume)));
}

-(void)getSecondaryMaxMinValue:(KLineModel *)item {
    _mSecondaryMaxValue = MAX(_mSecondaryMaxValue, MAX(item.k, MAX(item.d, item.j)));
    _mSecondaryMinValue = MIN(_mSecondaryMinValue, MIN(item.k, MIN(item.d, item.j)));
}

-(void)getTertiaryMaxMinValue:(KLineModel *)item {
    _mTertiaryMaxValue = MAX(_mTertiaryMaxValue, MAX(item.macd, MAX(item.dif, item.dea)));
    _mTertiaryMinValue = MIN(_mTertiaryMinValue, MIN(item.macd, MIN(item.dif, item.dea)));
}

-(void)getQuaternaryMaxMinValue:(KLineModel *)item {
    _mQuaternaryMaxValue = MAX(_mQuaternaryMaxValue, item.rsi);
    _mQuaternaryMinValue = MIN(_mQuaternaryMinValue, item.rsi);
}
-(void)initRenderer {
    _mainRenderer = [[MainChartRenderer alloc] initWithMaxValue:_mMainMaxValue minValue:_mMainMinValue chartRect:_mainRect candleWidth:_candleWidth topPadding:ChartStyle_topPadding isLine:_isLine state:_mainState];
     _mainRenderer.showBOLL=self.showBOLL;
     _mainRenderer.showBOLLText=self.showBOLLText;
    if (_volState != VolStateNONE) {
        _volRenderer = [[VolChartRenderer alloc] initWithMaxValue:_mVolMaxValue minValue:_mVolMinValue chartRect:_volRect candleWidth:_candleWidth topPadding:ChartStyle_childPadding];
        _volRenderer.showVMA = self.showVMA;  // Add this line

    } else {
        _volRenderer = nil;
    }
    
    _seconderyRender = [[SecondaryChartRenderer alloc] initWithMaxValue:_mSecondaryMaxValue minValue:_mSecondaryMinValue chartRect:_secondaryRect candleWidth:_candleWidth topPadding:ChartStyle_childPadding state:SecondaryStateKDJ];
    
    _tertiaryRenderer = [[SecondaryChartRenderer alloc] initWithMaxValue:_mTertiaryMaxValue minValue:_mTertiaryMinValue chartRect:_tertiaryRect candleWidth:_candleWidth topPadding:ChartStyle_childPadding state:SecondaryStateMacd]; // MACD Renderer
    
    _quaternaryRenderer = [[SecondaryChartRenderer alloc] initWithMaxValue:_mQuaternaryMaxValue minValue:_mQuaternaryMinValue chartRect:_quaternaryRect candleWidth:_candleWidth topPadding:ChartStyle_childPadding state:SecondaryStateRSI]; // RSI Renderer

    _wrRenderer = [[SecondaryChartRenderer alloc] initWithMaxValue:_mWRMaxValue minValue:_mWRMinValue chartRect:_wrRect candleWidth:_candleWidth topPadding:ChartStyle_childPadding state:SecondaryStateWR]; // WR Renderer
}


-(void)drawBgColor:(CGContextRef)context rect:(CGRect)rect {
    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:_mainBackgroundColor].CGColor);
    CGContextFillRect(context, rect);
    [_mainRenderer drawBg:context bgColor:_mainBackgroundColor];
    if(_volRenderer != nil) {
        [_volRenderer drawBg:context bgColor:_mainBackgroundColor];
    }
    if(_seconderyRender != nil) {
        [_seconderyRender drawBg:context bgColor:_mainBackgroundColor];
    }
    if(_tertiaryRenderer != nil) {
        [_tertiaryRenderer drawBg:context bgColor:_mainBackgroundColor];
    }
    if(_quaternaryRenderer != nil) {
        [_quaternaryRenderer drawBg:context bgColor:_mainBackgroundColor];
    }
    if(_wrRenderer != nil) {
        [_wrRenderer drawBg:context bgColor:_mainBackgroundColor];
    }
}

-(void)drawGrid:(CGContextRef)context {
    [_mainRenderer drawGrid:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    if(_volRenderer != nil) {
        [_volRenderer drawGrid:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    if(_seconderyRender != nil) {
        [_seconderyRender drawGrid:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    if(_tertiaryRenderer != nil) {
        [_tertiaryRenderer drawGrid:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    if(_quaternaryRenderer != nil) {
        [_quaternaryRenderer drawGrid:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    if(_wrRenderer != nil) {
        [_wrRenderer drawGrid:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    CGContextSetLineWidth(context, 1);
    CGContextAddRect(context, self.bounds);
    CGContextDrawPath(context, kCGPathStroke);
}
-(void)drawChart:(CGContextRef)context {
    for (NSUInteger index = _startIndex; index <= _stopIndex; index++) {
        KLineModel *curPoint = self.datas[index];
        CGFloat itemWidth = _candleWidth + ChartStyle_canldeMargin;
        CGFloat curX = (CGFloat)(index - _startIndex) * itemWidth + _startX;
        CGFloat _curX = self.frame.size.width - curX - _candleWidth / 2;
        KLineModel *lastPoint;
        if (index != _startIndex) {
            lastPoint = self.datas[index - 1];
        }

        [_mainRenderer drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX];

        if (_volRenderer != nil) {
            [_volRenderer drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX];
        }

        if (_showKDJ) {
            [_seconderyRender drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX];
        }

        if (_showMACD) {
            [_tertiaryRenderer drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX];
        }
        if (_showRSI) {
            [_quaternaryRenderer drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX];
        }
        if (_showWR) {
            [_wrRenderer drawChart:context lastPoit:lastPoint curPoint:curPoint curX:_curX];
        }
    }
}

- (void)drawDate:(CGContextRef)context {
    CGFloat cloumSpace = self.frame.size.width / (CGFloat)ChartStyle_gridColumns;

    // Get current date and time in Saudi timezone
    NSDate *now = [NSDate date];
    NSTimeZone *saudiTimeZone = [NSTimeZone timeZoneWithName:@"Asia/Riyadh"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:saudiTimeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];

    // Get current components in Saudi timezone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:saudiTimeZone];
    NSDateComponents *currentComponents = [calendar components:(NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:now];

    NSInteger currentHour = currentComponents.hour;
    NSInteger currentMinute = currentComponents.minute;
    NSInteger currentWeekday = currentComponents.weekday;

    // Check if today is between Sunday (1) and Thursday (5)
    BOOL isWeekday = (currentWeekday >= 1 && currentWeekday <= 5);
    BOOL isMarketTime = (currentHour > 10 || (currentHour == 10 && currentMinute >= 0)) && 
                        (currentHour < 15 || (currentHour == 15 && currentMinute <= 20));

    // Determine when to show only "10:00" and "15:20" for 1D duration
    if ([self.selectedDuration isEqualToString:@"1D"] && isWeekday && isMarketTime) {
        CGFloat thresholdScale = [self calculateThresholdScaleFor1D];
        if (_scaleX <= fabs(thresholdScale) && self.datas.count <= 320) {
            NSString *saudiStartTime = @"10:00";
            NSString *saudiEndTime = @"15:20";

            // Define a date formatter for the Saudi time
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm"];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Riyadh"]];

            // Parse the Saudi times
            NSDate *startTimeDate = [dateFormatter dateFromString:saudiStartTime];
            NSDate *endTimeDate = [dateFormatter dateFromString:saudiEndTime];

            // Convert to local time zone
            [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
            NSString *localStartTime = [dateFormatter stringFromDate:startTimeDate];
            NSString *localEndTime = [dateFormatter stringFromDate:endTimeDate];

            // Display the local times
            CGRect startRect = [localStartTime getRectWithFontSize:ChartStyle_bottomDatefontSize];
            CGFloat y = CGRectGetMinY(self.dateRect) + (ChartStyle_bottomDateHigh - startRect.size.height) / 2;

            [self.mainRenderer drawText:localStartTime atPoint:CGPointMake(0, y) fontSize:ChartStyle_bottomDatefontSize textColor:ChartColors_bottomDateTextColor];

            CGRect endRect = [localEndTime getRectWithFontSize:ChartStyle_bottomDatefontSize];
            [self.mainRenderer drawText:localEndTime atPoint:CGPointMake(self.frame.size.width - endRect.size.width, y) fontSize:ChartStyle_bottomDatefontSize textColor:ChartColors_bottomDateTextColor];

            return;
        }
    }

    // Default behavior for other durations and when zoomed in
    for (int i = 0; i < ChartStyle_gridColumns; i++) {
        NSUInteger index = [self calculateIndexWithSelectX:cloumSpace * (CGFloat)i];
        if ([self outRangeIndex:index]) { continue; }
        KLineModel *data = self.datas[index];
        NSString *dataStr = [self calculateDateText:data.id];
        CGRect rect = [dataStr getRectWithFontSize:ChartStyle_bottomDatefontSize];
        CGFloat y = CGRectGetMinY(self.dateRect) + (ChartStyle_bottomDateHigh - rect.size.height) / 2;
        [self.mainRenderer drawText:dataStr atPoint:CGPointMake(cloumSpace * i - rect.size.width / 2, y) fontSize:ChartStyle_bottomDatefontSize textColor:ChartColors_bottomDateTextColor];
    }
}

- (CGFloat)calculateThresholdScaleFor1D {
    // Calculate the threshold scale for 1D based on the data count
    if (self.datas.count >= 360) {
        return -0.05;
    } else if (self.datas.count >= 350) {
        return -0.045;
    } else if (self.datas.count >= 330) {
        return -0.04;
    } else if (self.datas.count >= 300) {
        return -0.03;
    } else if (self.datas.count >= 280) {
        return -0.02;
    } else if (self.datas.count >= 250) {
        return -0.001;
    } else if (self.datas.count > 240) {
        return 0.01;
    } else if (self.datas.count > 230) {
        return 0.02;
    } else if (self.datas.count > 220) {
        return 0.03;
    } else if (self.datas.count > 210) {
        return 0.04;
    } else if (self.datas.count > 200) {
        return 0.05;
    } else if (self.datas.count > 190) {
        return 0.06;
    } else if (self.datas.count > 180) {
        return 0.07;
    } else if (self.datas.count > 170) {
        return 0.09;
    } else if (self.datas.count > 160) {
        return 0.1;
    } else if (self.datas.count > 150) {
        return 0.12;
    } else if (self.datas.count > 140) {
        return 0.15;
    } else if (self.datas.count > 130) {
        return 0.17;
    } else if (self.datas.count > 120) {
        return 0.2;
    } else if (self.datas.count > 110) {
        return 0.23;
    } else if (self.datas.count > 100) {
        return 0.26;
    } else if (self.datas.count > 90) {
        return 0.32;
    } else if (self.datas.count > 80) {
        return 0.38;
    } else if (self.datas.count > 70) {
        return 0.45;
    } else if (self.datas.count > 60) {
        return 0.54;
    } else if (self.datas.count > 50) {
        return 0.68;
    } else if (self.datas.count > 40) {
        return 0.92;
    } else if (self.datas.count > 30) {
        return 1.3;
    } else if (self.datas.count > 20) {
        return 2.0;
    } else {
        return 4.0;
    }
}
-(void)drawMaxAndMin:(CGContextRef)context {
    if(_isLine) { return; }
    NSNumber *fixedPrice = [KLineStateManager manager].pricePrecision;
    NSString *maxFixedPrice = [NSString stringWithFormat:@"%@%@f", @"——%.", fixedPrice];
    NSString *minFixedPrice = [NSString stringWithFormat:@"%@%@f", @"%.", fixedPrice];
    [minFixedPrice stringByAppendingString:@"——"];
    CGFloat itemWidth = self.candleWidth + ChartStyle_canldeMargin;
    CGFloat y1 = [self.mainRenderer getY:_mMainHighMaxValue];
    CGFloat x1 = self.frame.size.width - ((self.mMainMaxIndex - self.startIndex) * itemWidth + self.startX + self.candleWidth / 2);
    if(x1 < self.frame.size.width / 2) {
        NSString *text = [NSString stringWithFormat:maxFixedPrice,_mMainHighMaxValue];
        CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        [self.mainRenderer drawText:text atPoint:CGPointMake(x1, y1 - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:[UIColor whiteColor]];
    } else {
        NSString *text = [NSString stringWithFormat:minFixedPrice,_mMainHighMaxValue];
        CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        [self.mainRenderer drawText:text atPoint:CGPointMake(x1 - rect.size.width, y1 - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:[UIColor whiteColor]];
    }

    CGFloat y2 = [self.mainRenderer getY:_mMainLowMinValue];
    CGFloat x2 = self.frame.size.width - ((self.mMainMinIndex - self.startIndex) * itemWidth + self.startX + self.candleWidth / 2);
    if(x2 < self.frame.size.width / 2) {
        NSString *text = [NSString stringWithFormat:maxFixedPrice,_mMainLowMinValue];
        CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        [self.mainRenderer drawText:text atPoint:CGPointMake(x2, y2 - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:[UIColor whiteColor]];
    } else {
        NSString *text = [NSString stringWithFormat:minFixedPrice,_mMainLowMinValue];
        CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        [self.mainRenderer drawText:text atPoint:CGPointMake(x2 - rect.size.width, y2 - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:[UIColor whiteColor]];
    }
}

-(void)drawLongPressCrossLine:(CGContextRef)context {
    if(_isLongPress){
    NSUInteger index = [self calculateIndexWithSelectX:self.longPressX];
    if ([self outRangeIndex:index]) { return; }
    KLineModel *point = self.datas[index];
    CGFloat itemWidth = _candleWidth + ChartStyle_canldeMargin;
    CGFloat curX = self.frame.size.width - ((index - self.startIndex) * itemWidth + self.startX + self.candleWidth / 2);

    // Set color for vertical line to gray and reduce its width
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 0.5); // Reduced width
    CGContextMoveToPoint(context, curX, 0);
    CGContextAddLineToPoint(context, curX, self.frame.size.height);
    CGContextDrawPath(context, kCGPathStroke);

    CGFloat y = [self.mainRenderer getY:point.close];

    // Set color for horizontal line to gray
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 0.5);
    CGContextMoveToPoint(context, 0, y);
    CGContextAddLineToPoint(context, self.frame.size.width, y);
    CGContextDrawPath(context, kCGPathStroke);

    // Set color for dot at intersection to gray
    CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextAddArc(context, curX, y, 2, 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFill);

    // Draw text for the cross line
    [self drawLongPressCrossLineText:context curPoint:point curX:curX y:y];
    }else{
         NSUInteger index = [self calculateIndexWithSelectX:self.longPressX];
    if ([self outRangeIndex:index]) { return; }
    KLineModel *point = self.datas[index];
    CGFloat itemWidth = _candleWidth + ChartStyle_canldeMargin;
    CGFloat curX ;

 

    CGFloat y ;


    // Draw text for the cross line
    [self drawLongPressCrossLineText:context curPoint:point curX:curX y:y];
    }
    
}
-(void)drawLongPressCrossLineText:(CGContextRef)context curPoint:(KLineModel *)curPoint curX:(CGFloat)curX y:(CGFloat)y {
    if (_isLongPress) {
        // Price display
        NSNumber *fixedPrice = [KLineStateManager manager].pricePrecision;
        NSString *fixedPriceStr = [NSString stringWithFormat:@"%@%@f", @"%.", fixedPrice];
        NSString *text = [NSString stringWithFormat:fixedPriceStr, curPoint.close];
        CGRect rect = [text getRectWithFontSize:ChartStyle_defaultTextSize];
        CGFloat padding = 3;
        CGFloat textHeight = rect.size.height + padding * 2;
        CGFloat textWidth = rect.size.width;
        BOOL isLeft = false;

        if (curX > self.frame.size.width / 2) {
            isLeft = true;
            CGContextMoveToPoint(context, self.frame.size.width, y - textHeight / 2);
            CGContextAddLineToPoint(context, self.frame.size.width, y + textHeight / 2);
            CGContextAddLineToPoint(context, self.frame.size.width - textWidth, y + textHeight / 2);
            CGContextAddLineToPoint(context, self.frame.size.width - textWidth - 10, y);
            CGContextAddLineToPoint(context, self.frame.size.width - textWidth, y - textHeight / 2);
            CGContextAddLineToPoint(context, self.frame.size.width, y - textHeight / 2);
            CGContextSetLineWidth(context, 1);
            CGContextSetStrokeColorWithColor(context, ChartColors_markerBorderColor.CGColor);
            CGContextSetFillColorWithColor(context, ChartColors_markerBgColor.CGColor);
            CGContextDrawPath(context, kCGPathFillStroke);
            [self.mainRenderer drawText:text atPoint:CGPointMake(self.frame.size.width - textWidth - 2, y - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:[UIColor whiteColor]];
        } else {
            isLeft = false;
            CGContextMoveToPoint(context, 0, y - textHeight / 2);
            CGContextAddLineToPoint(context, 0, y + textHeight / 2);
            CGContextAddLineToPoint(context, textWidth, y + textHeight / 2);
            CGContextAddLineToPoint(context, textWidth + 10, y);
            CGContextAddLineToPoint(context, textWidth, y - textHeight / 2);
            CGContextAddLineToPoint(context, 0, y - textHeight / 2);
            CGContextSetLineWidth(context, 1);
            CGContextSetStrokeColorWithColor(context, ChartColors_markerBorderColor.CGColor);
            CGContextSetFillColorWithColor(context, ChartColors_markerBgColor.CGColor);
            CGContextDrawPath(context, kCGPathFillStroke);
            [self.mainRenderer drawText:text atPoint:CGPointMake(2, y - rect.size.height / 2) fontSize:ChartStyle_defaultTextSize textColor:[UIColor whiteColor]];
        }

        // Time display
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:curPoint.id];
        NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
        if ([@[@"1D", @"5D",@"1Min",@"5M",@"10M",@"30M",@"1H"] containsObject:self.selectedDuration]) {
            timeFormatter.dateFormat = @"HH:mm";
        } else if([@[@"1M", @"3M"] containsObject:self.selectedDuration]) {
            timeFormatter.dateFormat = @"MM-dd";
        } else {
            timeFormatter.dateFormat = @"yyyy-MM";
        }

        NSString *timeText = [timeFormatter stringFromDate:date];
        CGRect timeRect = [timeText getRectWithFontSize:ChartStyle_defaultTextSize];
        CGFloat datePadding = 3;

        CGFloat timeBoxX = curX - timeRect.size.width / 2 - datePadding;
        CGFloat timeBoxY = CGRectGetMinY(self.dateRect) - timeRect.size.height - datePadding * 2;

        if (timeBoxY < 0) {
            timeBoxY = 0;
        }

        CGContextSetLineWidth(context, 1);
        CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);

        CGContextMoveToPoint(context, timeBoxX, timeBoxY);

        CGRect timeArcRect = CGRectMake(timeBoxX, timeBoxY, timeRect.size.width + datePadding * 2, timeRect.size.height + datePadding * 2);
        CGFloat minX = CGRectGetMinX(timeArcRect);
        CGFloat midX = CGRectGetMidX(timeArcRect);
        CGFloat maxX = CGRectGetMaxX(timeArcRect);
        CGFloat minY = CGRectGetMinY(timeArcRect);
        CGFloat midY = CGRectGetMidY(timeArcRect);
        CGFloat maxY = CGRectGetMaxY(timeArcRect);

        CGContextMoveToPoint(context, minX, midY);
        CGContextAddArcToPoint(context, minX, minY, midX, minY, 5);
        CGContextAddArcToPoint(context, maxX, minY, maxX, midY, 5);
        CGContextAddArcToPoint(context, maxX, maxY, midX, maxY, 5);
        CGContextAddArcToPoint(context, minX, maxY, minX, midY, 5);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);

        [self.mainRenderer drawText:timeText atPoint:CGPointMake(timeBoxX + datePadding, timeBoxY + datePadding) fontSize:ChartStyle_defaultTextSize textColor:[UIColor whiteColor]];

        // Display additional info only on long press
        self.showInfoBlock(curPoint, isLeft);
    }
    
    // Always show the top text values
    [self drawTopText:context curPoint:curPoint];
}


-(void)drawTopText:(CGContextRef)context curPoint:(KLineModel *)curPoint {
    [_mainRenderer drawTopText:context curPoint:curPoint];

    if (_volRenderer != nil) {
        [_volRenderer drawTopText:context curPoint:curPoint];
    }

    if (_showKDJ) {
        [_seconderyRender drawTopText:context curPoint:curPoint];
    }

    if (_showMACD) {
        [_tertiaryRenderer drawTopText:context curPoint:curPoint];
    }
    if (_showRSI) {
        [_quaternaryRenderer drawTopText:context curPoint:curPoint];
    }
    if (_showWR) {
        [_wrRenderer drawTopText:context curPoint:curPoint];
    }
}
- (void)setShowVMA:(BOOL)showVMA {
    _showVMA = showVMA;
    [self setNeedsDisplay];
}
- (void)setShowBOLL:(BOOL)showBOLL {
    _showBOLL = showBOLL;
    [self setNeedsDisplay];
}
- (void)setShowBOLLText:(BOOL)showBOLLText {
    _showBOLLText = showBOLLText;
    [self setNeedsDisplay];
}
-(void)drawRightText:(CGContextRef)context {
    [_mainRenderer drawRightText:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    if (_volRenderer != nil) {
        [_volRenderer drawRightText:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    if (_seconderyRender != nil) {
        [_seconderyRender drawRightText:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    if (_tertiaryRenderer != nil) {
        [_tertiaryRenderer drawRightText:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    if (_quaternaryRenderer != nil) {
        [_quaternaryRenderer drawRightText:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
    if (_wrRenderer != nil) {
        [_wrRenderer drawRightText:context gridRows:ChartStyle_gridRows gridColums:ChartStyle_gridColumns];
    }
}

-(void)drawRealTimePrice:(CGContextRef)context {
    KLineModel *point = self.datas.firstObject;
    NSNumber *fixedPrice = [KLineStateManager manager].pricePrecision;
    NSString *fixedPriceStr = [NSString stringWithFormat:@"%@%@f", @"%.", fixedPrice];
    NSString *text = [NSString stringWithFormat:fixedPriceStr,point.close];
    CGFloat fontSize = 10;
    CGRect rect = [text getRectWithFontSize:fontSize];
    CGFloat y = [self.mainRenderer getY:point.close];
    if(point.close > self.mMainMaxValue) {
        y = [self.mainRenderer getY:self.mMainMaxValue];
    } else if (point.close < self.mMainMinValue) {
        y = [self.mainRenderer getY:self.mMainMinValue];
    }
    if((-_scrollX - rect.size.width) > 0) {
        CGContextSetStrokeColorWithColor(context, ChartColors_realTimeLongLineColor.CGColor);
        CGContextSetLineWidth(context, 0.5);
        CGFloat locations[] = {5,5};
        CGContextSetLineDash(context, 0, locations, 2);
        CGContextMoveToPoint(context,self.frame.size.width + _scrollX, y);
        CGContextAddLineToPoint(context, self.frame.size.width, y);
        CGContextDrawPath(context, kCGPathStroke);
        CGContextAddRect(context, CGRectMake(self.frame.size.width - rect.size.width, y - rect.size.height / 2, rect.size.width, rect.size.height));
        CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:_mainBackgroundColor].CGColor);
        CGContextDrawPath(context, kCGPathFill);
        [self.mainRenderer drawText:text atPoint:CGPointMake(self.frame.size.width - rect.size.width, y - rect.size.height / 2) fontSize:fontSize textColor:ChartColors_reightTextColor];
        if(_isLine) {
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextAddArc(context, self.frame.size.width + _scrollX - _candleWidth / 2, y, 2, 0, M_PI_2, true);
            CGContextDrawPath(context, kCGPathFill);
        }
    } else {
        CGContextSetStrokeColorWithColor(context, ChartColors_realTimeLongLineColor.CGColor);
        CGContextSetLineWidth(context, 0.5);
        CGFloat locations[] = {5,5};
        CGContextSetLineDash(context, 0, locations, 2);
        CGContextMoveToPoint(context,0, y);
        CGContextAddLineToPoint(context, self.frame.size.width, y);
        CGContextDrawPath(context, kCGPathStroke);

        CGFloat r = 8;
        CGFloat w = rect.size.width + 16;
        CGContextSetLineWidth(context, 0.5);
        CGFloat locations1[] = {};
        CGContextSetLineDash(context, 0, locations1, 0);
        CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:_mainBackgroundColor].CGColor);
        CGContextMoveToPoint(context,self.frame.size.width * 0.8, y - r);

        CGFloat curX = self.frame.size.width * 0.8;
        CGRect arcRect = CGRectMake(curX - w / 2, y - r, w, 2 * r);
        CGFloat minX = CGRectGetMinX(arcRect);
        CGFloat midX = CGRectGetMidX(arcRect);
        CGFloat maxX = CGRectGetMaxX(arcRect);

        CGFloat minY = CGRectGetMinY(arcRect);
        CGFloat midY = CGRectGetMidY(arcRect);
        CGFloat maxY = CGRectGetMaxY(arcRect);

        CGContextMoveToPoint(context,minX, midY);
        CGContextAddArcToPoint(context, minX, minY, midX, minY, r);
        CGContextAddArcToPoint(context, maxX, minY, maxX, midY, r);
        CGContextAddArcToPoint(context, maxX, maxY, midX, maxY, r);
        CGContextAddArcToPoint(context, minX, maxY, minX, midY, r);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);

        CGFloat startX = CGRectGetMaxX(arcRect) - 4;
        CGContextSetFillColorWithColor(context, ChartColors_reightTextColor.CGColor);
        CGContextMoveToPoint(context,startX, y);
        CGContextAddLineToPoint(context, startX - 3, y - 3);
        CGContextAddLineToPoint(context, startX - 3, y + 3);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFill);
        [self.mainRenderer drawText:text atPoint:CGPointMake(curX - rect.size.width / 2 - 4, y - rect.size.height / 2) fontSize:fontSize textColor:ChartColors_reightTextColor];
    }
}

-(NSUInteger)calculateIndexWithSelectX:(CGFloat)selectX {
    NSInteger index = (self.frame.size.width - _startX - selectX) / (_candleWidth + ChartStyle_canldeMargin) + _startIndex;
    return index;
}

-(BOOL)outRangeIndex:(NSUInteger)index {
    if(index < 0 || index >= self.datas.count) {
        return true;
    } else {
        return false;
    }
}

-(NSString *)calculateDateText:(NSTimeInterval)time {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    formater.dateFormat = self.fromat;
    return [formater stringFromDate:date];
}

@end
