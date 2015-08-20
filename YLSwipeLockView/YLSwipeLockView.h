//
//  YLSwipeLockView.h
//  YLSwipeLockViewDemo
//
//  Created by 肖 玉龙 on 15/2/12.
//  Copyright (c) 2015年 Yulong Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#define LIGHTBLUE [UIColor colorWithRed:0.101 green:0.777 blue:0.467 alpha:1]
#define LINEWidth 2.0f

typedef NS_ENUM(NSUInteger, YLSwipeLockViewState) {
    YLSwipeLockViewStateNormal,
    YLSwipeLockViewStateWarning,
    YLSwipeLockViewStateSelected
};
@protocol YLSwipeLockViewDelegate;

@interface YLSwipeLockView : UIView
@property (nonatomic, weak) id<YLSwipeLockViewDelegate> delegate;
@property (nonatomic) YLSwipeLockViewState viewState;
@property (nonatomic, strong) UIColor *lineColourNormal;
@property (nonatomic, strong) UIColor *lineColourWarning;
@property (nonatomic) CGFloat lineWidth;

-(void)moveLineForChangeOrientation;
@end


@protocol YLSwipeLockViewDelegate<NSObject>
@optional
-(YLSwipeLockViewState)swipeView:(YLSwipeLockView *)swipeView didEndSwipeWithPassword:(NSString *)password;
@end