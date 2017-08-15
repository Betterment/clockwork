require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = false
end

if ENV['APPRAISAL_INITIALIZED'] || ENV['TRAVIS']
  task default: :test
else
  require 'appraisal'
  Appraisal::Task.new
  task default: :appraisal
end
