platform :ios, '15.0'
ENV['SWIFT_VERSION'] = '5.0'
use_frameworks!
inhibit_all_warnings!

target 'PHI372-DC' do
  # 网络
  pod 'AFNetworking'
  # 数据解析
  pod 'JSONModel'
  pod 'YYModel'
  # 布局
  pod 'Masonry'
  # 图片
  pod 'SDWebImage'
  pod 'YYWebImage', '~> 1.0.5'
  # UI / HUD
  pod 'SVProgressHUD'
  pod 'IQKeyboardManager', '~> 6.5.19'
  pod 'SDCycleScrollView', '~> 1.82'

  # 业务模块后续按需启用:
  # pod 'Adjust', '~> 5.4.6'
  # pod 'SystemServices'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5.0'
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 13.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end

  # AFNetworking 4.0.1 兼容 Xcode 26: 删除 private header import (仓库已停维护无 4.0.2)
  # struct sockaddr_in6 已在公共头 netinet/in.h 中, in6.h 是冗余的
  ['Pods/AFNetworking/AFNetworking/AFNetworkReachabilityManager.m',
   'Pods/AFNetworking/AFNetworking/AFHTTPSessionManager.m'].each do |rel|
    f = File.expand_path(rel, __dir__)
    next unless File.exist?(f)
    content = File.read(f)
    if content.include?('#import <netinet6/in6.h>')
      content.gsub!(/^#import <netinet6\/in6\.h>\s*\n/,
                    "// netinet6/in6.h 是 private header, Xcode 26 SDK 拒绝引用; struct sockaddr_in6 已在 netinet/in.h 公共头中\n")
      File.write(f, content)
      puts "[Podfile post_install] patched #{File.basename(f)} for Xcode 26 SDK"
    end
  end
end
