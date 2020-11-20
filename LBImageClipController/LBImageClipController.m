//
//  LBImageClipController.m
//
//  Created by 刘彬 on 2016/5/8.
//  Copyright © 2016 刘彬. All rights reserved.
//

#import "LBImageClipController.h"
#import "LBImageZoomView.h"
#import "LBGridView.h"

#define KBottomMenuHeight 100  //底部菜单高度
#define KGridTopMargin 40  //顶部间距
#define KGridBottomMargin 20  //底部间距
#define KGridLRMargin 20   //左右边距
#define KActionButtonSize CGSizeMake(40, 30)

/// 视图转换为Image
@interface UIView (LBImageForImageClip)
/// 截取视图转Image
/// @param range 截图区域
- (UIImage *)lb_imageByViewInRect:(CGRect)range;
@end
@implementation UIView (LBImageForImageClip)

// View 转 Image
- (UIImage *)lb_imageByViewInRect:(CGRect)range{
    CGRect rect = self.bounds;
    /** 参数取整，否则可能会出现1像素偏差 */
    /** 有小数部分才调整差值 */
#define lfme_export_fixDecimal(d) ((fmod(d, (int)d)) > 0.59f ? ((int)(d+0.5)*1.f) : (((fmod(d, (int)d)) < 0.59f && (fmod(d, (int)d)) > 0.1f) ? ((int)(d)*1.f+0.5f) : (int)(d)*1.f))
    rect.origin.x = lfme_export_fixDecimal(rect.origin.x);
    rect.origin.y = lfme_export_fixDecimal(rect.origin.y);
    rect.size.width = lfme_export_fixDecimal(rect.size.width);
    rect.size.height = lfme_export_fixDecimal(rect.size.height);
#undef lfme_export_fixDecimal
    CGSize size = rect.size;
    //1.开启上下文
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //2.绘制图层
    [self.layer renderInContext:context];
    //3.从上下文中获取新图片
    UIImage *fullScreenImage = UIGraphicsGetImageFromCurrentImageContext();
    //4.关闭图形上下文
    UIGraphicsEndImageContext();
    if (CGRectEqualToRect(rect, range)) {
        return fullScreenImage;
    }
    //上面我们获得了一个全屏的截图，下边的方法是对这个图片进行裁剪。
    CGImageRef imageRef = fullScreenImage.CGImage;
    //注意：这里的宽/高 CGImageGetWidth(imageRef) 是图片的像素宽/高，所以计算截图区域时需要按比例来 * [UIScreen mainScreen].scale；
    range = CGRectMake(range.origin.x*[UIScreen mainScreen].scale, range.origin.y*[UIScreen mainScreen].scale, range.size.width*[UIScreen mainScreen].scale, range.size.height*[UIScreen mainScreen].scale);
    CGImageRef imageRefRect = CGImageCreateWithImageInRect(imageRef, range);
    UIImage *image =[[UIImage alloc] initWithCGImage:imageRefRect];
    CGImageRelease(imageRefRect);
    return image;
}

@end


@interface LBImageClipController ()<UIScrollViewDelegate, SLGridViewDelegate, LBImageZoomViewDelegate>

// 缩放视图
@property (nonatomic, strong) LBImageZoomView *zoomView;
//网格视图 裁剪框
@property (nonatomic, strong) LBGridView *gridView;

/// 原始位置区域
@property (nonatomic, assign) CGRect originalRect;
/// 最大裁剪区域
@property (nonatomic, assign) CGRect maxGridRect;

/// 裁剪区域
//@property (nonatomic, assign) CGRect clipRect;

/// 当前旋转角度
@property (nonatomic, assign) NSInteger rotateAngle;
/// 图像方向
@property (nonatomic, assign) UIImageOrientation imageOrientation;

@property (nonatomic, strong) UIButton *rotateBtn;  //旋转操作
@property (nonatomic, strong) UIButton *cancleClipBtn; //取消操作
@property (nonatomic, strong) UIButton *recoveryBtn; //还原
@property (nonatomic, strong) UIButton *doneClipBtn;  //保存操作
@end

@implementation LBImageClipController
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.autoDismiss = YES;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}
#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupUI];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)dealloc {
    NSLog(@"图片裁剪视图释放了");
}
#pragma mark - UI
- (void)setupUI {
    self.zoomView.image = self.image;
    self.maxGridRect = CGRectMake(KGridLRMargin, KGridTopMargin, CGRectGetWidth(self.view.frame) - KGridLRMargin * 2, CGRectGetHeight(self.view.frame) - KGridTopMargin - KGridBottomMargin- KBottomMenuHeight);
    
    CGSize newSize = CGSizeMake(CGRectGetWidth(self.view.frame) - 2 * KGridLRMargin, (CGRectGetWidth(self.view.frame) - 2 * KGridLRMargin)*self.image.size.height/self.image.size.width);
    if (newSize.height > CGRectGetHeight(self.maxGridRect)) {
        newSize = CGSizeMake(CGRectGetHeight(self.maxGridRect)*self.image.size.width/self.image.size.height, CGRectGetHeight(self.maxGridRect));
        self.zoomView.frame = (CGRect){(CGRectGetWidth(self.view.frame)-newSize.width)/2,KGridTopMargin,newSize};
    }else {
        self.zoomView.frame = (CGRect){(CGRectGetWidth(self.view.frame)-newSize.width)/2,(CGRectGetHeight(self.view.frame)-KBottomMenuHeight-newSize.height)/2.0,newSize};
    }
    
    [self.view addSubview:self.zoomView];
    self.zoomView.imageView.frame = self.zoomView.bounds;
    self.originalRect = self.zoomView.frame;
    self.gridView.gridRect = self.zoomView.frame;
    self.gridView.maxGridRect = self.maxGridRect;
    [self.view addSubview:self.gridView];
    
    [self.view addSubview:self.rotateBtn];
    [self.view addSubview:self.cancleClipBtn];
    [self.view addSubview:self.recoveryBtn];
    [self.view addSubview:self.doneClipBtn];
}

#pragma mark - Getter
- (LBImageZoomView *)zoomView {
    if (!_zoomView) {
        CGFloat zoomHeight = (CGRectGetWidth(self.view.frame)-KGridLRMargin*2)*self.image.size.height/self.image.size.width;
        _zoomView = [[LBImageZoomView alloc] initWithFrame:CGRectMake(KGridLRMargin, (CGRectGetHeight(self.view.frame)-KBottomMenuHeight-zoomHeight)/2.0, CGRectGetWidth(self.view.frame)-KGridLRMargin*2, zoomHeight)];
        _zoomView.backgroundColor = [UIColor blackColor];
        _zoomView.zoomViewDelegate = self;
    }
    return _zoomView;
}
- (LBGridView *)gridView {
    if (!_gridView) {
        _gridView = [[LBGridView alloc] initWithFrame:self.view.bounds];
        _gridView.delegate = self;
    }
    return _gridView;
}
- (UIButton *)cancleClipBtn {
    if (_cancleClipBtn == nil) {
        NSBundle *bundle = [self LBImageClipControllerBundle];
        UIImage *cancelImage = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"EditImageClipCancel@2x" ofType:@"png"]];
        _cancleClipBtn = [[UIButton alloc] initWithFrame:CGRectMake(30, CGRectGetHeight(self.view.frame) - KActionButtonSize.height - 20, KActionButtonSize.width, KActionButtonSize.height)];
        [_cancleClipBtn setImage:cancelImage forState:UIControlStateNormal];
        _cancleClipBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_cancleClipBtn addTarget:self action:@selector(cancleClipClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancleClipBtn;
}
- (UIButton *)doneClipBtn {
    if (_doneClipBtn == nil) {
        NSBundle *bundle = [self LBImageClipControllerBundle];
        UIImage *doneImage = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"EditImageClipDone@2x" ofType:@"png"]];
        _doneClipBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - CGRectGetMinX(self.cancleClipBtn.frame) - KActionButtonSize.width, CGRectGetMinY(self.cancleClipBtn.frame), KActionButtonSize.width, KActionButtonSize.height)];
        [_doneClipBtn setImage:doneImage forState:UIControlStateNormal];
        [_doneClipBtn addTarget:self action:@selector(doneClipClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneClipBtn;
}

- (UIButton *)rotateBtn {
    if (_rotateBtn == nil) {
        _rotateBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2-KActionButtonSize.width-15, CGRectGetMinY(self.cancleClipBtn.frame), KActionButtonSize.width, KActionButtonSize.height)];
        [_rotateBtn setTitle:@"旋转" forState:UIControlStateNormal];
        [_rotateBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _rotateBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [_rotateBtn addTarget:self action:@selector(rotateBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rotateBtn;
}

- (UIButton *)recoveryBtn {
    if (_recoveryBtn == nil) {
        _recoveryBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2+15, CGRectGetMinY(self.rotateBtn.frame), KActionButtonSize.width, KActionButtonSize.height)];
        [_recoveryBtn setTitle:@"还原" forState:UIControlStateNormal];
        [_recoveryBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _recoveryBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [_recoveryBtn addTarget:self action:@selector(recoveryClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recoveryBtn;
}

/// 返回图像方向
- (UIImageOrientation)imageOrientation {
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (_rotateAngle) {
        case 90:
        case -270:
            orientation = UIImageOrientationRight;
            break;
        case -90:
        case 270:
            orientation = UIImageOrientationLeft;
            break;
        case 180:
        case -180:
            orientation = UIImageOrientationDown;
            break;
        default:
            break;
    }
    _imageOrientation = orientation;
    return orientation;
}
#pragma mark - HelpMethods
- (NSBundle *)LBImageClipControllerBundle
{
    NSBundle *imageClipControllerBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"LBImageClipController" ofType:@"bundle"]];
    return imageClipControllerBundle;
}
// 放大zoomView区域到指定网格gridRect区域
- (void)zoomInToRect:(CGRect)gridRect{
    // 正在拖拽或减速
    if (self.zoomView.dragging || self.zoomView.decelerating) {
        return;
    }
    
    CGRect imageRect = [self.zoomView convertRect:self.zoomView.imageView.frame toView:self.view];
    //当网格往图片边缘(x/y轴方向)移动即将出图片边界时，调整self.zoomView.contentOffset和缩放zoomView大小，把网格外的图片区域逐步移到网格内
    if (!CGRectContainsRect(imageRect,gridRect)) {
        CGPoint contentOffset = self.zoomView.contentOffset;
        if (self.imageOrientation == UIImageOrientationRight) {
            if (CGRectGetMaxX(gridRect) > CGRectGetMaxX(imageRect)) contentOffset.y = 0;
            if (CGRectGetMinY(gridRect) < CGRectGetMinY(imageRect)) contentOffset.x = 0;
        }
        if (self.imageOrientation == UIImageOrientationLeft) {
            if (CGRectGetMinX(gridRect) < CGRectGetMinX(imageRect)) contentOffset.y = 0;
            if (CGRectGetMaxY(gridRect) > CGRectGetMaxY(imageRect)) contentOffset.x = 0;
        }
        if (self.imageOrientation == UIImageOrientationUp) {
            if (CGRectGetMinY(gridRect) < CGRectGetMinY(imageRect)) contentOffset.y = 0;
            if (CGRectGetMinX(gridRect) < CGRectGetMinX(imageRect)) contentOffset.x = 0;
        }
        if (self.imageOrientation == UIImageOrientationDown) {
            if (CGRectGetMaxY(gridRect) > CGRectGetMaxY(imageRect)) contentOffset.y = 0;
            if (CGRectGetMaxX(gridRect) > CGRectGetMaxX(imageRect)) contentOffset.x = 0;
        }
        self.zoomView.contentOffset = contentOffset;
        
        /** 取最大值缩放 */
        CGRect myFrame = self.zoomView.frame;
        myFrame.origin.x = MIN(myFrame.origin.x, gridRect.origin.x);
        myFrame.origin.y = MIN(myFrame.origin.y, gridRect.origin.y);
        myFrame.size.width = MAX(myFrame.size.width, gridRect.size.width);
        myFrame.size.height = MAX(myFrame.size.height, gridRect.size.height);
        self.zoomView.frame = myFrame;
        
        [self resetMinimumZoomScale];
        [self.zoomView setZoomScale:self.zoomView.zoomScale];
    }
}
//重置最小缩放系数  只要改变了zoomView大小就重置
- (void)resetMinimumZoomScale {
    CGRect rotateoriginalRect = CGRectApplyAffineTransform(self.originalRect, self.zoomView.transform);
    if (CGSizeEqualToSize(rotateoriginalRect.size, CGSizeZero)) {
        /** size为0时候不能继续，否则minimumZoomScale=+Inf，会无法缩放 */
        return;
    }
    //设置最小缩放系数
    CGFloat zoomScale = MAX(CGRectGetWidth(self.zoomView.frame) / CGRectGetWidth(rotateoriginalRect), CGRectGetHeight(self.zoomView.frame) / CGRectGetHeight(rotateoriginalRect));
    self.zoomView.minimumZoomScale = zoomScale;
}
//获取网格区域在图片上的相对位置
- (CGRect)rectOfGridOnImageByGridRect:(CGRect)cropRect {
    CGRect rect = [self.view convertRect:cropRect toView:self.zoomView.imageView];
    return rect;
}
//保存图片完成后调用的方法
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    if (error) {
        NSLog(@"保存图片出错%@", error.localizedDescription);
    } else {
        NSLog(@"保存图片成功");
    }
}
#pragma mark - EventsHandle
- (void)rotateBtnClicked:(id)sender {
    _rotateAngle = (_rotateAngle+=90)%360;
    CGFloat angleInRadians = 0.0f;
    switch (_rotateAngle) {
        case 90:    angleInRadians = M_PI_2;            break;
        case -90:   angleInRadians = -M_PI_2;           break;
        case 180:   angleInRadians = M_PI;              break;
        case -180:  angleInRadians = -M_PI;             break;
        case 270:   angleInRadians = (M_PI + M_PI_2);   break;
        case -270:  angleInRadians = -(M_PI + M_PI_2);  break;
        default:                                        break;
    }
    //旋转前获得网格框在图片上选择的区域
    CGRect gridRectOfImage = [self rectOfGridOnImageByGridRect:self.gridView.gridRect];
    
    /// 旋转变形
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
    self.zoomView.transform = transform;
    //transform后，bounds不会变，frame会变
    CGFloat width = CGRectGetWidth(self.zoomView.frame);
    CGFloat height = CGRectGetHeight(self.zoomView.frame);
    //计算旋转之后
    CGSize newSize = CGSizeMake(CGRectGetWidth(self.view.frame) - 2 * KGridLRMargin, (CGRectGetWidth(self.view.frame) - 2 * KGridLRMargin)*height/width);
    if (newSize.height > self.gridView.maxGridRect.size.height) {
        newSize = CGSizeMake(self.gridView.maxGridRect.size.height*width/height, self.gridView.maxGridRect.size.height);
        self.zoomView.frame = (CGRect){(CGRectGetWidth(self.view.frame)-newSize.width)/2,KGridTopMargin,newSize};
    }else {
        self.zoomView.frame = (CGRect){(CGRectGetWidth(self.view.frame)-newSize.width)/2,(CGRectGetHeight(self.view.frame)-KBottomMenuHeight-newSize.height)/2.0,newSize};
    }
    self.gridView.gridRect = self.zoomView.frame;
    
    //重置最小缩放系数
    [self resetMinimumZoomScale];
    CGFloat scale = MIN(CGRectGetWidth(self.zoomView.frame) / width, CGRectGetHeight(self.zoomView.frame) / height);
    [self.zoomView setZoomScale:self.zoomView.zoomScale * scale];
    // 调整contentOffset
    self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale, gridRectOfImage.origin.y*self.zoomView.zoomScale);
}
- (void)cancleClipClicked:(id)sender {
    if (self.autoDismiss) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
//还原
- (void)recoveryClicked:(id)sender {
    self.zoomView.minimumZoomScale = 1;
    self.zoomView.zoomScale = 1;
    self.zoomView.transform = CGAffineTransformIdentity;
    self.zoomView.frame = self.originalRect;
    self.gridView.gridRect = self.zoomView.frame;
    _rotateAngle = 0;
}
//完成编辑
- (void)doneClipClicked:(id)sender {
    if (self.autoDismiss) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    UIImage *clipImage = [self.zoomView.imageView lb_imageByViewInRect:[self rectOfGridOnImageByGridRect:_gridView.gridRect]];
    UIImage *roImage = [UIImage imageWithCGImage:clipImage.CGImage scale:[UIScreen mainScreen].scale orientation:self.imageOrientation];
    
    if (roImage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sl_ImageClippingComplete" object:nil userInfo:@{@"image" : roImage}];
        if (self.imageClipFinishedHandle) {
            self.imageClipFinishedHandle(roImage);
        }
    }
}

#pragma mark - SLGridViewDelegate
//开始调整
- (void)gridViewDidBeginResizing:(LBGridView *)gridView {
    CGPoint contentOffset = self.zoomView.contentOffset;
    if (self.zoomView.contentOffset.x < 0) contentOffset.x = 0;
    if (self.zoomView.contentOffset.y < 0) contentOffset.y = 0;
    [self.zoomView setContentOffset:contentOffset animated:NO];
}
//正在调整
- (void)gridViewDidResizing:(LBGridView *)gridView {
    //放大到 >= gridRect
    [self zoomInToRect:gridView.gridRect];
}
// 结束调整
- (void)gridViewDidEndResizing:(LBGridView *)gridView {
    CGRect gridRectOfImage = [self rectOfGridOnImageByGridRect:gridView.gridRect];
    //居中
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        CGSize newSize = CGSizeMake(CGRectGetWidth(self.view.frame) - 2 * KGridLRMargin, (CGRectGetWidth(self.view.frame) - 2 * KGridLRMargin)*gridView.gridRect.size.height/gridView.gridRect.size.width);
        if (newSize.height > self.gridView.maxGridRect.size.height) {
            newSize = CGSizeMake(self.gridView.maxGridRect.size.height*gridView.gridRect.size.width/gridView.gridRect.size.height, self.gridView.maxGridRect.size.height);
            self.zoomView.frame = (CGRect){(CGRectGetWidth(self.view.frame)-newSize.width)/2,KGridTopMargin,newSize};
        }else {
            self.zoomView.frame = (CGRect){(CGRectGetWidth(self.view.frame)-newSize.width)/2,(CGRectGetHeight(self.view.frame)-KBottomMenuHeight-newSize.height)/2.0,newSize};
        }
        //重置最小缩放系数
        [self resetMinimumZoomScale];
        [self.zoomView setZoomScale:self.zoomView.zoomScale];
        // 调整contentOffset
        CGFloat zoomScale = CGRectGetWidth(self.zoomView.frame)/gridView.gridRect.size.width;
        gridView.gridRect = self.zoomView.frame;
        [self.zoomView setZoomScale:self.zoomView.zoomScale * zoomScale];
        self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale, gridRectOfImage.origin.y*self.zoomView.zoomScale);
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - SLZoomViewDelegate
- (void)zoomViewDidBeginMoveImage:(LBImageZoomView *)zoomView {
    self.gridView.showMaskLayer = NO;
}
- (void)zoomViewDidEndMoveImage:(LBImageZoomView *)zoomView {
    self.gridView.showMaskLayer = YES;
}

@end



