Pod::Spec.new do |s|
    s.name         = "LevelStorage"
    s.version      = "1.0.0"
    s.summary      = "storage"
    s.homepage     = ''
    s.license      = { :type => 'MIT' }
    s.author       = { 'jasenhuang' => 'jasenhuang@rdgz.org' }
    s.platform     = :ios, "8.0"
    s.ios.deployment_target = "8.0"
    s.source       = { :git => "http://git.code.oa.com/WeRead/LevelStorage.git" }
    s.source_files  = "LevelStorage/**/*.{h,m,mm}"
    s.public_header_files = "LevelStorage/LevelStorage.h"
    s.requires_arc = true
    s.libraries    = 'c++', 'z'
    s.dependency 'leveldb-library', '1.20'
end