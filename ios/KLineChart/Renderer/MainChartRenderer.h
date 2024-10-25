//
//  MainChartRenderer.h
//  KLine-Chart-OC
//
//  Created by 何俊松 on 2020/3/10.
//  Copyright © 2020 hjs. All rights reserved.
//

#import "BaseChartRenderer.h"
#import "KLineState.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainChartRenderer : BaseChartRenderer

@property(nonatomic,assign) NSString* mainBackgroundColor;
@property(nonatomic, assign) BOOL showBOLL;
@property(nonatomic, assign) BOOL showBOLLText;

- (instancetype)initWithMaxValue:(CGFloat)maxValue
                        minValue:(CGFloat)minValue
                       chartRect:(CGRect)chartRect
                     candleWidth:(CGFloat)candleWidth
                      topPadding:(CGFloat)topPadding
                          isLine:(BOOL)isLine
                           state:(MainState)state;
@end

NS_ASSUME_NONNULL_END
