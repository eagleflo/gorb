require 'rake'
require 'rake/testtask'

task :default => [:test]

desc "Run tests"
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/test_*.rb'
  t.verbose = false
  t.warning = true
end
