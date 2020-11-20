Pod::Spec.new do |spec|
  spec.name         = "LBImageClipController"
  spec.version      = "1.0.0"
  spec.summary      = "图片剪切/裁剪"
  spec.description  = "一个超轻量级的图片剪切/裁剪器，支持任意剪切/裁剪，集成方便。"
  spec.homepage     = "https://github.com/A1129434577/LBImageClipController"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "刘彬" => "1129434577@qq.com" }
  spec.platform     = :ios
  spec.ios.deployment_target = '8.0'
  spec.source       = { :git => 'https://github.com/A1129434577/LBImageClipController.git', :tag => spec.version.to_s }
  spec.resource     = "LBImageClipController/**/*.bundle"
  spec.source_files = "LBImageClipController/**/*.{h,m}"
  spec.requires_arc = true
end
