Pod::Spec.new do |spec|
  spec.name         		 = 'YLSwipeLockPattern'
  spec.version      		 = '1.0.0'
  spec.requires_arc 		 = true
  spec.ios.deployment_target 	 = '7.0'
  spec.license      		 = { :type => 'MIT' }
  spec.homepage     		 = 'https://github.com/itomych/YLSwipeLockView.git'
  spec.authors     		 = { 'Xiao Yulong' => 'https://github.com/XiaoYulong/YLSwipeLockView.git' }
  spec.summary      		 = 'ARC LockPattern for iOS and OS X.'
  spec.source       		 = { :git => 'https://github.com/itomych/YLSwipeLockView.git', :branch => 'dev' }
  spec.source_files 		 = 'YLSwipeLockView/*.(m,h)'
end