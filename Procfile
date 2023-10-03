web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
release: bundle exec rake db:migrate
worker:  bundle exec rake jobs:work
recurring-tasks: ruby lib/daemons/recurring_tasks.rb start -- --no-monitor
