# Uncomment this line to define a global platform for your project
platform :macos, '10.12'

# 切换数据源
source 'https://github.com/CocoaPods/Specs.git'

target 'ShadowsocksX-NG-R' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ShadowsocksX-NG
  pod 'GCDWebServer', '~> 3.5.4'

  target 'ShadowsocksX-NGTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'proxy_conf_helper' do
  pod 'BRLOptionParser', '~> 0.3.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5.0'
    end
  end
end
