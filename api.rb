run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
    gem 'bcrypt', '~> 3.1.7'
    gem 'rack-cors'
    gem 'jwt'

    # seeds
    gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'master'

  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY

  gem 'dotenv-rails'
  RUBY
end

# Procfile
########################################
file 'Procfile', <<~YAML
  release: bundle exec rails db:migrate
  web: bundle exec puma -C config/puma.rb
YAML

# robots.txt substitution
########################################
run 'rm -rf public/robots.txt'
file 'public/robots.txt', <<~TXT
  User-agent: *
  Disallow: /
TXT


########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  # Routes
  ########################################
  route "root to: 'pages#home'"

  # Git ignore
  ########################################
  append_file '.gitignore', <<~TXT
    # Ignore .env file containing credentials.
    .env*
    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Application controller substitution
  ########################################
  run 'rm app/controllers/application_controller.rb'
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/api/application_controller.rb > app/controllers/application_controller.rb'

  # cors.rb substitution
  ########################################
  run 'rm config/initializers/cors.rb'
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/api/cors.rb > config/initializers/cors.rb'

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Dotenv
  ########################################
  run 'touch .env'

  # Rubocop
  ########################################
  run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Fix puma config
  gsub_file('config/puma.rb', 'pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }', '# pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }')

  # Git
  ########################################
  git add: '.'
  git commit: "-m 'Initial commit with api template'"
end
