//
//  YLSwipeLockNodeView.m
//  YLSwipeLockViewDemo
//
//  Created by 肖 玉龙 on 15/2/12.
//  Copyright (c) 2015年 Yulong Xiao. All rights reserved.
//

#import "YLSwipeLockNodeView.h"
#import "YLSwipeLockView.h"

//#define LINEWidth 2.0f
@interface YLSwipeLockNodeView()
@property (nonatomic, strong)CAShapeLayer *outlineLayer;
@property (nonatomic, strong)CAShapeLayer *innerCircleLayer;
@end


@implementation YLSwipeLockNodeView

+(void)initialize{
    
    if (self != [YLSwipeLockNodeView class]) {
        return;
    }
    YLSwipeLockNodeView *appearance= [self appearance];
    
    appearance.nodeColourNormal  = [UIColor whiteColor];
    appearance.nodeColourSelect  = [UIColor whiteColor];
    appearance.nodeColourWarning = [UIColor redColor];
    appearance.lineWidthNode     = 2.0f;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.lineWidthNode = [[[self class]appearance]lineWidthNode];
        [self.layer addSublayer:self.outlineLayer];
        [self.layer addSublayer:self.innerCircleLayer];
        self.nodeViewStatus = YLSwipeLockNodeViewStatusNormal;
    }
    return self;
}

-(void)pan:(UIPanGestureRecognizer *)rec
{
    CGPoint point = [rec locationInView:self];
    NSLog(@"location in view:%f, %f", point.x, point.y);
    self.nodeViewStatus = YLSwipeLockNodeViewStatusSelected;
}

-(void)setNodeViewStatus:(YLSwipeLockNodeViewStatus)nodeViewStatus
{
    _nodeViewStatus = nodeViewStatus;
    switch (_nodeViewStatus) {
        case YLSwipeLockNodeViewStatusNormal:
            [self setStatusToNormal];
            break;
        case YLSwipeLockNodeViewStatusSelected:
            [self setStatusToSelected];
            break;
        case YLSwipeLockNodeViewStatusWarning:
            [self setStatusToWarning];
            break;
        default:
            break;
    }
}

-(void)setStatusToNormal
{
    self.outlineLayer.strokeColor = [UIColor clearColor].CGColor;
    self.innerCircleLayer.fillColor = self.nodeColourNormal.CGColor;
}

-(void)setStatusToSelected
{
    self.outlineLayer.strokeColor =self.nodeColourSelect.CGColor;
    self.innerCircleLayer.fillColor =  self.nodeColourSelect.CGColor;
}

-(void)setStatusToWarning
{
    self.outlineLayer.strokeColor = self.nodeColourWarning.CGColor;
    self.innerCircleLayer.fillColor = self.nodeColourWarning.CGColor;
    
}


-(void)layoutSubviews
{
    self.outlineLayer.frame = self.bounds;
    UIBezierPath *outlinePath = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    self.outlineLayer.path = outlinePath.CGPath;
    
    CGRect frame = self.bounds;
    CGFloat width = frame.size.width / 2;
    CGFloat widthOffset = width/2 ;
    self.innerCircleLayer.frame = CGRectMake(width-widthOffset, width-widthOffset, width, width);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithOvalInRect:self.innerCircleLayer.bounds];
    self.innerCircleLayer.path = innerPath.CGPath;

}

-(CAShapeLayer *)outlineLayer
{
    if (_outlineLayer == nil) {
        _outlineLayer = [[CAShapeLayer alloc] init];
        _outlineLayer.strokeColor =  self.nodeColourNormal.CGColor;
        NSLog(@"lineWidthNode = %f",self.lineWidthNode);
        _outlineLayer.lineWidth = self.lineWidthNode;
        _outlineLayer.fillColor  = [UIColor clearColor].CGColor;

    }
    return _outlineLayer;
}

-(CAShapeLayer *)innerCircleLayer
{
    if (_innerCircleLayer == nil) {
        _innerCircleLayer = [[CAShapeLayer alloc] init];
        _innerCircleLayer.strokeColor = [UIColor clearColor].CGColor;
         NSLog(@"lineWidthNode = %f",self.lineWidthNode);
        _innerCircleLayer.lineWidth = self.lineWidthNode;
        _innerCircleLayer.fillColor  =  self.nodeColourNormal.CGColor;

    }
    return _innerCircleLayer;
}

@end
