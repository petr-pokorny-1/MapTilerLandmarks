# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'Landmarks' do
  use_frameworks!

  # Pods for Landmarks
  pod 'Mapbox-iOS-SDK', '6.2.1'	

end

post_install do |pi|
  pi.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.2'
      end
  end
end
