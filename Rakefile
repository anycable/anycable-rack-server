# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"
require "rake/testtask"

RuboCop::RakeTask.new

Rake::TestTask.new do |t|
  t.test_files = FileList["test/anycable/test_*.rb",
    "test/anycable/**/test_*.rb"]
end

namespace :anyt do
  task :rack do
    sh 'anyt -c "puma test/support/rack/config.ru" --except features/server_restart'
  end

  task :rails do
    Dir.chdir(File.join(__dir__, "test/support/rails")) do
      sh "ANYCABLE_BROADCAST_ADAPTER=http ANYCABLE_HTTP_BROADCAST_SECRET=any_secret " \
         "ANYCABLE_HTTP_BROADCAST_URL=http://localhost:9292/_anycable_rack_broadcast " \
         "anyt -c \"puma config.ru\" --wait-command=5 --except features/server_restart"
    end
  end
end

task anyt: ["anyt:rack", "anyt:rails"]

task default: [:rubocop, :test, :anyt]
