namespace :test do
  desc "Create test coverage report"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["test"].execute
  end
end
