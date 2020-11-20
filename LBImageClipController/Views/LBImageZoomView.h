//
//  LBImageZoomView.h
//
//  Created by 刘彬 on 2016/5/8.
//  Copyright © 2016 刘彬. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LBImageZoomViewDelegate;
/// 缩放视图 用于图片编辑
@interface LBImageZoomView : UIScrollView
@property (nonatomic, strong) UIImage *image;
//
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, weak) id<LBImageZoomViewDelegate> zoomViewDelegate;
@end

/// 缩放视图代理
@protocol LBImageZoomViewDelegate <NSObject>
@optional
/// 开始移动图像位置
- (void)zoomViewDidBeginMoveImage:(LBImageZoomView *)zoomView;
/// 结束移动图像
- (void)zoomViewDidEndMoveImage:(LBImageZoomView *)zoomView;
@end

NS_ASSUME_NONNULL_END
