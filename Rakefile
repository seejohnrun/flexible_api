require 'spec/rake/spectask'
require 'lib/flexible_api/version'
 
task :build do
  system "gem build flexible_api.gemspec"
end

task :release => :build do
  # tag and push
  system "git tag v#{FlexibleApi::VERSION}"
  system "git push origin --tags"
  # push the gem
  system "gem push flexible_api-#{FlexibleApi::VERSION}.gem"
end
