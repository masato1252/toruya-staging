web: jemalloc.sh bundle exec puma -C config/puma.rb
worker:  bundle exec rake jobs:work
release: rake db:migrate
