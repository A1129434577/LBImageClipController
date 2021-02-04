# LBImageClipController
一个超轻量级的图片剪切/裁剪器，支持任意剪切/裁剪，集成方便。
# 安装方式
```ruby
pod 'LBImageClipController'
```
# 使用
```Objc
LBImageClipController *imageClipController = [[LBImageClipController alloc] init];
imageClipController.image = [UIImage imageNamed:@"example.jpeg"];
[self presentViewController:imageClipController animated:YES completion:NULL];
imageClipController.imageClipFinishedHandle = ^(UIImage * _Nonnull image) {

};
```
![](https://github.com/A1129434577/LBImageClipController/blob/main/LBImageClipController.gif?raw=true)
