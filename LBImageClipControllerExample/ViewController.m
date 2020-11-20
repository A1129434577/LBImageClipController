//
//  ViewController.m
//  LBImageClipControllerExample
//
//  Created by 刘彬 on 2020/11/20.
//

#import "ViewController.h"
#import "LBImageClipController.h"
@interface ViewController ()
@property (nonatomic, strong) UIButton *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIButton *imageView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    imageView.center = self.view.center;
    imageView.backgroundColor = [UIColor lightGrayColor];
    [imageView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [imageView setTitle:@"开始剪切图片" forState:UIControlStateNormal];
    [imageView addTarget:self action:@selector(begainClip) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:imageView];
    _imageView = imageView;
}

-(void)begainClip{
    LBImageClipController *imageClipController = [[LBImageClipController alloc] init];
    imageClipController.image = [UIImage imageNamed:@"example.jpeg"];
    [self presentViewController:imageClipController animated:YES completion:NULL];
    imageClipController.imageClipFinishedHandle = ^(UIImage * _Nonnull image) {
        [self.imageView setBackgroundImage:image forState:UIControlStateNormal];
    };
}

@end
