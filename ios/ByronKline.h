#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>

@interface ByronKline : RCTViewManager
@property (nonatomic, copy) NSString *selectedDuration; //add by Zaid
@property (nonatomic, assign) BOOL showKDJ;
@property (nonatomic, assign) BOOL showMACD;
@property (nonatomic, assign) BOOL showRSI;

@end
