//
//  YLSwipeLockView.m
//  YLSwipeLockViewDemo
//
//  Created by 肖 玉龙 on 15/2/12.
//  Copyright (c) 2015年 Yulong Xiao. All rights reserved.
//

#import "YLSwipeLockView.h"
#import "YLSwipeLockNodeView.h"

bool YLLineIntersectsNode(CGPoint point1, CGPoint point2, CGPoint center, CGFloat radius) {
    CGFloat x1 = point1.x - center.x;
    CGFloat y1 = point1.y - center.y;
    CGFloat x2 = point2.x - center.x;
    CGFloat y2 = point2.y - center.y;
    
    CGFloat dx = x2 - x1;
    CGFloat dy = y2 - y1;
    
    CGFloat a = dx * dx + dy * dy;
    CGFloat b = 2 * (x1 * dx + y1 * dy);
    CGFloat c = x1 * x1 + y1 * y1 - radius * radius;
    
    if (-b < 0)
        return (c < 0);
    if (-b < (2 * a))
        return ((4 * a * c - b * b) < 0);
    return (a + b + c < 0);
}

@interface YLSwipeLockView(){
    NSArray *arrayObjSelect;
}
@property (nonatomic, strong) NSMutableArray *nodeArray;
@property (nonatomic, strong) NSMutableArray *selectedNodeArray;
@property (nonatomic, strong) CAShapeLayer *polygonalLineLayer;
@property (nonatomic, strong) UIBezierPath *polygonalLinePath;
@property (nonatomic, strong) NSMutableArray *pointArray;

@end

@implementation YLSwipeLockView
+(void)initialize{
    
    if (self != [YLSwipeLockView class]) {
        return;
    }
    YLSwipeLockView *appearance= [self appearance];
    
    appearance.lineColourNormal = [UIColor whiteColor];
    appearance.lineColourWarning = [UIColor redColor];
    appearance.lineWidth = 2.0f;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupView];
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

-(void)setupView{
    self.lineWidth = [[[self class]appearance]lineWidth];
    [self.layer addSublayer:self.polygonalLineLayer];
    
    _nodeArray = [NSMutableArray arrayWithCapacity:9];
    for (int i = 0; i < 9; ++i) {
        YLSwipeLockNodeView *nodeView = [YLSwipeLockNodeView new];
        [_nodeArray addObject:nodeView];
        nodeView.tag = i;
        [self addSubview:nodeView];
    }
    _selectedNodeArray = [NSMutableArray arrayWithCapacity:9];
    _pointArray = [NSMutableArray array];
    
    UIPanGestureRecognizer *panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:panRec];
    self.viewState = YLSwipeLockNodeViewStatusNormal;
    [self cleanNodes];
}

-(void)pan:(UIPanGestureRecognizer *)rec
{
    if (self.viewState == YLSwipeLockViewStateSelected) {
        return;
    }
    
    if  (rec.state == UIGestureRecognizerStateBegan){
        self.viewState = YLSwipeLockNodeViewStatusNormal;
    }
    CGPoint touchPoint = [rec locationInView:self];
    NSInteger index = [self indexForNodeAtPoint:touchPoint];
    
    
    if (index >= 0) {
        YLSwipeLockNodeView *node = self.nodeArray[index];
        
        if (![self addSelectedNode:node]) {
            [self addIntermediateNode];
            [self moveLineWithFingerPosition:touchPoint];
        }
    }else{
        [self moveLineWithFingerPosition:touchPoint];
        
    }
    
    if (rec.state == UIGestureRecognizerStateEnded) {
        
        [self removeLastFingerPosition];
        if([self.delegate respondsToSelector:@selector(swipeView:didEndSwipeWithPassword:)]){
            NSMutableString *password = [NSMutableString new];
            for(YLSwipeLockNodeView *nodeView in self.selectedNodeArray){
                NSString *index = [@(nodeView.tag) stringValue];
                [password appendString:index];
                
            }
            
            self.viewState = [self.delegate swipeView:self didEndSwipeWithPassword:password];
            
        }
        else{
            self.viewState = YLSwipeLockViewStateSelected;
        }
    }
    
}

-(void)addIntermediateNode {
    if (self.selectedNodeArray.count < 2) {
        return;
    }
    
    YLSwipeLockNodeView *previousNode = [self.selectedNodeArray objectAtIndex:self.selectedNodeArray.count-2];
    YLSwipeLockNodeView *lastNode = [self.selectedNodeArray lastObject];
    
    for (YLSwipeLockNodeView *node in self.nodeArray) {
        if ([self.selectedNodeArray containsObject:node]) {
            continue;
        }
        if (YLLineIntersectsNode(previousNode.center, lastNode.center, node.center, node.bounds.size.width / 2)) {
            node.nodeViewStatus = YLSwipeLockNodeViewStatusSelected;
            [self.selectedNodeArray insertObject:node atIndex:self.selectedNodeArray.count - 2];
            [self.pointArray insertObject:[NSValue valueWithCGPoint:node.center] atIndex:self.selectedNodeArray.count-2];
        }
    }
}

-(BOOL)addSelectedNode:(YLSwipeLockNodeView *)nodeView
{
    if (![self.selectedNodeArray containsObject:nodeView]) {
        nodeView.nodeViewStatus = YLSwipeLockNodeViewStatusSelected;
        [self.selectedNodeArray addObject:nodeView];
        [self addLineToNode:nodeView];
        
        return YES;
    }else{
        return NO;
    }
    
}

-(void)addLineToNodeTest:(YLSwipeLockNodeView *)nodeView
{
    if(self.selectedNodeArray.count == 1){
        CGPoint startPoint = nodeView.center;
        [self.polygonalLinePath moveToPoint:startPoint];
        [self.pointArray addObject:[NSValue valueWithCGPoint:startPoint]];
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
        
    }else{
        
        CGPoint middlePoint = nodeView.center;
        [self.pointArray addObject:[NSValue valueWithCGPoint:middlePoint]];
        
        [self.polygonalLinePath removeAllPoints];
        CGPoint startPoint = [self.pointArray[0] CGPointValue];
        [self.polygonalLinePath moveToPoint:startPoint];
        for (int i = 1; i < self.pointArray.count; ++i) {
            CGPoint middlePoint = [self.pointArray[i] CGPointValue];
            [self.polygonalLinePath addLineToPoint:middlePoint];
        }
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
        
    }
    
}

-(void)addLineToNode:(YLSwipeLockNodeView *)nodeView
{
    if(self.selectedNodeArray.count == 1){
        CGPoint startPoint = nodeView.center;
        [self.polygonalLinePath moveToPoint:startPoint];
        [self.pointArray addObject:[NSValue valueWithCGPoint:startPoint]];
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
        
    }else{
        
        [self.pointArray removeLastObject];
        CGPoint middlePoint = nodeView.center;
        [self.pointArray addObject:[NSValue valueWithCGPoint:middlePoint]];
        
        
        [self.polygonalLinePath removeAllPoints];
        CGPoint startPoint = [self.pointArray[0] CGPointValue];
        [self.polygonalLinePath moveToPoint:startPoint];
        
        for (int i = 1; i < self.pointArray.count; ++i) {
            CGPoint middlePoint = [self.pointArray[i] CGPointValue];
            [self.polygonalLinePath addLineToPoint:middlePoint];
        }
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
        
    }

}

-(void)moveLineWithFingerPosition:(CGPoint)touchPoint
{
  
    if (self.pointArray.count > 0) {
        if (self.pointArray.count > self.selectedNodeArray.count) {
            [self.pointArray removeLastObject];
        }
        [self.pointArray addObject:[NSValue valueWithCGPoint:touchPoint]];
        [self.polygonalLinePath removeAllPoints];
        CGPoint startPoint = [self.pointArray[0] CGPointValue];
        [self.polygonalLinePath moveToPoint:startPoint];
        
        for (int i = 1; i < self.pointArray.count; ++i) {
            CGPoint middlePoint = [self.pointArray[i] CGPointValue];
            [self.polygonalLinePath addLineToPoint:middlePoint];
        }
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
    
    }
}
-(void)removeLastFingerPosition
{
    if (self.pointArray.count > 0) {
        if (self.pointArray.count > self.selectedNodeArray.count) {
            [self.pointArray removeLastObject];
        }
        [self.polygonalLinePath removeAllPoints];
        CGPoint startPoint = [self.pointArray[0] CGPointValue];
        [self.polygonalLinePath moveToPoint:startPoint];
        
        for (int i = 1; i < self.pointArray.count; ++i) {
            CGPoint middlePoint = [self.pointArray[i] CGPointValue];
            [self.polygonalLinePath addLineToPoint:middlePoint];
        }
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
        
    }
}

-(void)moveLineForChangeOrientation{
    if (self.selectedNodeArray.count) {
        arrayObjSelect = nil;
        arrayObjSelect = [[NSArray alloc]initWithArray:self.selectedNodeArray];
    }
    [self cleanNodes];
    for (YLSwipeLockNodeView *nodeView in arrayObjSelect) {
        nodeView.nodeViewStatus = YLSwipeLockNodeViewStatusSelected;
        [self.selectedNodeArray addObject:nodeView];
        [self addLineToNodeTest:nodeView];
    }
}

-(void)layoutSubviews{
    

    self.polygonalLineLayer.frame = self.bounds;
 
    CAShapeLayer *maskLayer = [CAShapeLayer new];
    maskLayer.frame = self.bounds;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.bounds];
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    maskLayer.lineWidth = self.lineWidth;
    maskLayer.strokeColor = [UIColor blackColor].CGColor;
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    for (int i = 0; i < self.nodeArray.count; ++i) {
        YLSwipeLockNodeView *nodeView = _nodeArray[i];
        CGFloat min = self.bounds.size.width < self.bounds.size.height ? self.bounds.size.width : self.bounds.size.height;
        CGFloat width = min / 5;
        CGFloat height = min / 5;
        CGFloat offsetCentre = self.bounds.size.width < self.bounds.size.height ? 0 : (self.bounds.size.width -self.bounds.size.height)/2;
        int row = i % 3;
        int column = i / 3;
        CGRect frame = CGRectMake(row *(width * 2)+offsetCentre , column * (width *2), width, height);
        nodeView.frame = frame;
        [maskPath appendPath:[UIBezierPath bezierPathWithOvalInRect:frame]];
    }
    if ([self.selectedNodeArray count]) {
        arrayObjSelect = nil;
        arrayObjSelect = [[NSArray alloc]initWithArray:self.selectedNodeArray];
        
    }
    [self cleanNodes];
    
    maskLayer.path = maskPath.CGPath;
    self.polygonalLineLayer.mask = maskLayer;

}

-(NSInteger)indexForNodeAtPoint:(CGPoint)point
{
    for (int i = 0; i < self.nodeArray.count; ++i) {
        YLSwipeLockNodeView *node = self.nodeArray[i];
        CGPoint pointInNode = [node convertPoint:point fromView:self];
        if ([node pointInside:pointInNode withEvent:nil]) {
            NSLog(@"点中了第%d个~~", i);
            return i;
        }
    }
    return -1;
}

-(void)cleanNodes
{
    for (int i = 0; i < self.nodeArray.count; ++i) {
        YLSwipeLockNodeView *node = self.nodeArray[i];
        node.nodeViewStatus = YLSwipeLockNodeViewStatusNormal;
    }
    
    [self.selectedNodeArray removeAllObjects];
    [self.pointArray removeAllObjects];
    self.polygonalLinePath = [UIBezierPath new];
    self.polygonalLineLayer.strokeColor =  self.lineColourNormal.CGColor;
    self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
}

-(void)cleanNodesIfNeeded{
    if(self.viewState != YLSwipeLockNodeViewStatusNormal){
        [self cleanNodes];
    }
}

-(void)makeNodesToWarning
{
    for (int i = 0; i < self.selectedNodeArray.count; ++i) {
        YLSwipeLockNodeView *node = self.selectedNodeArray[i];
        node.nodeViewStatus = YLSwipeLockNodeViewStatusWarning;
    }
    self.polygonalLineLayer.strokeColor = self.lineColourWarning.CGColor;
}

-(CAShapeLayer *)polygonalLineLayer
{
    if (_polygonalLineLayer == nil) {
        _polygonalLineLayer = [[CAShapeLayer alloc] init];
        _polygonalLineLayer.lineWidth = self.lineWidth;
        _polygonalLineLayer.strokeColor = self.lineColourNormal.CGColor;
        _polygonalLineLayer.fillColor = [UIColor clearColor].CGColor;
    }
    return _polygonalLineLayer;
}

-(void)setViewState:(YLSwipeLockViewState)viewState
{
//    if(_viewState != viewState){
        _viewState = viewState;
        switch (_viewState){
            case YLSwipeLockViewStateNormal:
                [self cleanNodes];
                break;
            case YLSwipeLockViewStateWarning:
                [self makeNodesToWarning];
                [self performSelector:@selector(cleanNodesIfNeeded) withObject:nil afterDelay:1];
                break;
            case YLSwipeLockViewStateSelected:
            default:
                break;
        }
//    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
