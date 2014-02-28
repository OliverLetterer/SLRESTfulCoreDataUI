task :test do
  exit system("xcodebuild -workspace SLRESTfulCoreDataUI.xcworkspace -scheme SLRESTfulCoreDataUI test -sdk iphonesimulator7.0 -destination platform='iOS Simulator,OS=7.0,name=iPhone Retina (4-inch)' | xcpretty -c; exit ${PIPESTATUS[0]}")
end

task :default => 'test'