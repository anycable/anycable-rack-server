# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/anycable/test_*.rb',
                          'test/anycable/**/test_*.rb']
end
desc 'Run gem tests'

task default: :test
