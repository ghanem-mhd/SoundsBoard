# Uncomment the next line to define a global platform for your project
platform :ios, '12.4'
use_frameworks!

def shared_pods
    pod 'SnapKit', '~> 5.0.0'
    pod 'SwiftySound'
    pod "WARangeSlider"
end

target 'SoundsBoard' do
  # Pods for SoundsBoard
  pod 'NVActivityIndicatorView'
  pod 'MultiSlider'
  pod 'AudioKit', '~> 4.0'
  shared_pods
end

target 'SBKit' do
    shared_pods
end

target 'SBWidget' do
    shared_pods
end

target 'SBShare' do
    shared_pods
    pod 'AudioKit', '~> 4.0'
end


