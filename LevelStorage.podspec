Pod::Spec.new do |s|
    s.name         = "LevelStorage"
    s.version      = "1.0.0"
    s.summary      = "storage"
    s.homepage     = 'https://github.com/jasenhuang'
    s.license      = { :type => 'MIT' }
    s.author       = { 'jasenhuang' => 'jasenhuang@rdgz.org' }
    s.platform     = :ios, "8.0"
    s.ios.deployment_target = "8.0"
    s.source       = { :git => "http://git.code.oa.com/WeRead/LevelStorage.git" }
    s.source_files  = "LevelStorage/*.{h,m,mm}", 
                      "LevelStorage/Coding/*.{h,m,mm}"
    s.requires_arc = true
    s.frameworks   = "Foundation"
    s.libraries    = 'c++', 'z'
    s.dependency 'leveldb-library', '1.20'
end