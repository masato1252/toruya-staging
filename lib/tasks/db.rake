namespace :db do
  namespace :remote do
    task :import do
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      system("rm latest.dump")
      system("heroku pg:backups capture --app toruya-staging")
      system("curl -o latest.dump `heroku pg:backups public-url --app toruya-staging`")
      system("pg_restore --verbose --clean --no-acl --no-owner -h localhost -d kasaike_development latest.dump")
      Rake::Task["db:migrate"].invoke
    end
  end
end
