namespace :db do
  namespace :remote do
    task :import do
      system("rm latest.dump")
      system("heroku pg:backups capture --app toruya-production")
      system("curl -o latest.dump `heroku pg:backups public-url --app toruya-production`")
      system("pg_restore --verbose --clean --no-acl --no-owner -h localhost -d kasaike_development latest.dump")
      Rake::Task["db:migrate"].invoke
    end
  end
end
