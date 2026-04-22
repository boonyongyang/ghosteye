#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ghosteye_frame_ffi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ghosteye_frame_ffi'
  s.version          = '0.0.1'
  s.summary          = 'Internal Ghosteye FFI plugin for camera frame preprocessing.'
  s.description      = <<-DESC
Internal Ghosteye plugin used by the app's frame preprocessing path for RGB
conversion experiments.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
