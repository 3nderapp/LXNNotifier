Pod::Spec.new do |s|
  s.name                  = 'LXNNotifier'
  s.version               = '1.0'
  s.summary               = 'This is the repository forLXNNotifier.'
  s.homepage         	  = "https://github.com/3nderapp/LXNNotifier"
  s.license          	  = 'MIT'
  s.author                = { 'Leszek Kaczor' => 'leszekducker@gmail.com' }
  s.source                = { :git => "https://github.com/3nderapp/LXNNotifier.git", :tag => s.version.to_s }
  s.source_files          = 'LXNNotifier/Notifier/*'
  s.requires_arc	  = true
  s.ios.deployment_target = '6.0'
end
