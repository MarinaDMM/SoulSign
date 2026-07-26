ENV['SHELL'] = '/bin/zsh'

platform :ios, '14.0'

target 'SoulSign' do
  use_frameworks!

  pod 'GoogleMaps'
  pod 'GooglePlaces'

  # Unit/integration tests @testable-import the app module, so they need the
  # same framework/module search paths (they don't re-link the pods).
  target 'SoulSignTests' do
    inherit! :search_paths
  end
end

# Ensure every Pods target (including the Pods_SoulSign umbrella framework)
# emits a dSYM in Release, so App Store Connect's symbol upload doesn't warn
# about a missing dSYM for Pods_SoulSign.framework.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
    end
  end
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
  end
end
