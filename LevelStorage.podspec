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
    s.public_header_files = "LevelStorage/LevelStorage.h",
                            "LevelStorage/LevelKV.h",
                            "LevelStorage/LevelDB.h",
                            "LevelStorage/LevelKV+JSON.h",
                            "LevelStorage/LevelMacro.h"
    s.compiler_flags = '-x objective-c++'
    s.requires_arc = true
    s.frameworks   = "Foundation"
    s.libraries    = 'c++', 'z'
    s.pod_target_xcconfig = {
        "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++17",
        "CLANG_CXX_LIBRARY" => "libc++",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF" => "NO",
      }
    s.dependency 'leveldb-library', '1.20'
end