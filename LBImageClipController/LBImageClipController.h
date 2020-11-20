//
//  LBImageClipController.h
//
//  Created by 刘彬 on 2016/5/8.
//  Copyright © 2016 刘彬. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LBImageClipController : UIViewController
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) BOOL autoDismiss;//点击取消或者剪切完成自动dismiss
@property (nonatomic, copy,nullable) void (^imageClipCanceledHandle)(void);
@property (nonatomic, copy,nullable) void (^imageClipFinishedHandle)(UIImage *image);
@end

NS_ASSUME_NONNULL_END
