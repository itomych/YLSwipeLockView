//
//  YLSwipeLockView.m
//  YLSwipeLockViewDemo
//
//  Created by 肖 玉龙 on 15/2/12.
//  Copyright (c) 2015年 Yulong Xiao. All rights reserved.
//

#import "YLSwipeLockView.h"
#import "YLSwipeLockNodeView.h"
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

-(void)addIntermediateNode{
    
    if (self.selectedNodeArray.count<2) {
        return;
    }
    YLSwipeLockNodeView *previousNode = [self.selectedNodeArray objectAtIndex:self.selectedNodeArray.count-2];
    YLSwipeLockNodeView *lastNode = [self.selectedNodeArray lastObject];
    
    if (previousNode.center.x != lastNode.center.x && previousNode.center.y != lastNode.center.y) {
        if ( fabs(lastNode.frame.origin.x-previousNode.frame.origin.x)  != fabs(lastNode.frame.origin.y-previousNode.frame.origin.y)) {
            NSLog(@"return %f = %f",lastNode.frame.origin.x-previousNode.frame.origin.x,self.frame.size.width/3);
            return;
        }
    }
  
    CGPoint newPointNode = CGPointMake(previousNode.center.x, previousNode.center.y);
    
    if (previousNode.center.x == lastNode.center.x ) {
        newPointNode.x = previousNode.center.x;
    }
    if (previousNode.center.y == lastNode.center.y ) {
        newPointNode.y = previousNode.center.y;
    }
    
    if (previousNode.center.x >lastNode.center.x) {
        newPointNode.x = self.frame.size.width/2 - previousNode.frame.size.height/2;
    }
    
    if (lastNode.center.x >previousNode.center.x) {
        newPointNode.x =   self.frame.size.width/2 - lastNode.frame.size.height/2;
    }
    
    if (previousNode.center.y >lastNode.center.y) {
        newPointNode.y =    [self returnWidthFrame]/2 - previousNode.frame.size.height/2;
    }
    
    if (lastNode.center.y >previousNode.center.y) {
        newPointNode.y =   [self returnWidthFrame]/2 - lastNode.frame.size.height/2;
    }

    NSInteger index = [self indexForNodeAtPoint:newPointNode];
    if (index>0 ) {
        YLSwipeLockNodeView *nodeNew = self.nodeArray[index];
        if (![self.selectedNodeArray containsObject:nodeNew]) {
            nodeNew.nodeViewStatus = YLSwipeLockNodeViewStatusSelected;
            newPointNode = nodeNew.center;
            [self.selectedNodeArray insertObject:nodeNew atIndex:self.selectedNodeArray.count-1];
            [self.pointArray insertObject:[NSValue valueWithCGPoint:newPointNode] atIndex:self.selectedNodeArray.count-2];
        }else{
        }
    }
}


-(CGFloat)returnWidthFrame{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        return self.frame.size.width;
    }
    else{
        return self.frame.size.height;
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
//            NSLog(@"middlePoint.x %f,middlePoint.y %f ",middlePoint.x, middlePoint.y);
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
//            NSLog(@"middlePoint.x %f,middlePoint.y %f ",middlePoint.x, middlePoint.y);
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
//            NSLog(@"middlePoint.x %f,middlePoint.y %f ",middlePoint.x, middlePoint.y);
            [self.polygonalLinePath addLineToPoint:middlePoint];
        }
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
    
    }
}
-(void)removeLastFingerPosition
{
    if (self.pointArray.count > 0) {
        if (self.pointArray.count > self.selectedNodeArray.count) {
            CGPoint poit = (CGPoint)[[self.pointArray lastObject] CGPointValue];
            NSLog(@"self.pointArray1 %f self.pointArray %f",poit.x,poit.y);
            [self.pointArray removeLastObject];
        }
        [self.polygonalLinePath removeAllPoints];
        CGPoint startPoint = [self.pointArray[0] CGPointValue];
        [self.polygonalLinePath moveToPoint:startPoint];
        
        for (int i = 1; i < self.pointArray.count; ++i) {
            CGPoint middlePoint = [self.pointArray[i] CGPointValue];
//            NSLog(@"middlePoint.x %f,middlePoint.y %f ",middlePoint.x, middlePoint.y);
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
