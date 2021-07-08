run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
    gem 'devise'
    gem 'autoprefixer-rails', '10.2.5'
    gem 'font-awesome-sass'
    gem 'simple_form'
    gem 'pundit'

  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY

  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'dotenv-rails'
  RUBY
end

inject_into_file 'Gemfile', after: 'group :development do' do
  <<-RUBY

  gem 'bullet'
  gem 'rack-mini-profiler'
  RUBY
end

# N+1 query (bullet)
########################################
inject_into_file 'config/environments/development.rb', before: '# Use an evented file watcher to asynchronously detect changes in source code,' do
  <<~RUBY

    # Bullet N+1 query
    config.after_initialize do
      Bullet.enable = true
      Bullet.rails_logger = true
    end

  RUBY
end

# Procfile
########################################
file 'Procfile', <<~YAML
  release: bundle exec rails db:migrate
  web: bundle exec puma -C config/puma.rb
YAML

gsub_file('Gemfile', /# gem 'redis'/, "gem 'redis'")

# Assets
########################################
run 'rm -rf app/assets/stylesheets'
run 'rm -rf vendor'
run 'curl -L https://github.com/lewagon/rails-stylesheets/archive/master.zip > stylesheets.zip'
run 'unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets'

# robots.txt
########################################
run 'rm -rf public/robots.txt'
file 'public/robots.txt', <<~TXT
  User-agent: *
  Disallow: /
TXT

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Dev production
########################################
gsub_file('config/environments/production.rb', 'config.assets.js_compressor = :uglifier', 'config.assets.js_compressor = Uglifier.new(harmony: true)')

# Flashes
########################################
file 'app/views/shared/_flashes.html.erb', <<~HTML
HTML
run 'rm app/views/shared/_flashes.html.erb'
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/html/_flashes.html.erb > app/views/shared/_flashes.html.erb'

# Navbar & footer
########################################
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/html/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb'
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/html/_footer_bertrand.html.erb > app/views/shared/_footer.html.erb'
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/css/_footer.scss > app/assets/stylesheets/components/_footer.scss'

inject_into_file 'app/assets/stylesheets/components/_index.scss', after: '@import "navbar";' do
  <<-CSS

  @import "footer";
  CSS
end

# CSS
########################################
inject_into_file 'app/assets/stylesheets/application.scss', after: '@import "pages/index";' do
  <<-CSS


  .hidden {
    display: none !important;
  }
  CSS
end

# LAYOUT
########################################
run 'rm app/views/layouts/application.html.erb'
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/html/application.html.erb > app/views/layouts/application.html.erb'

# README
########################################
markdown_file_content = <<-MARKDOWN
Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

environment generators

# FR language
########################################
inject_into_file 'config/application.rb', after: 'config.load_defaults 5.2' do
  <<~RUBY


    # Set the default local language
    config.i18n.default_locale = :fr

    # hearders for security
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'X-Download-Options' => 'noopen',
      'X-Permitted-Cross-Domain-Policies' => 'none',
      'Referrer-Policy' => 'strict-origin-when-cross-origin',
      'Access-Control-Allow-Origin' => '*'
    }
  RUBY
end

# Pundit install
########################################
generate('pundit:install')

# Pundit default policy
########################################
inject_into_file 'app/policies/application_policy.rb', before: 'class Scope' do
  <<~RUBY

    def user_loggedin?
      user != nil
    end

  RUBY
end

# Pundit page policy
########################################
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/ruby/page_policy.rb > app/policies/page_policy.rb'

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
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

  # Rspec install
  ########################################
  # generate('rspec:install')

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # Devise helpers methods
  ########################################
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/ruby/devise_helper.rb > app/helpers/devise_helper.rb'

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/ruby/application_controller.rb > app/controllers/application_controller.rb'

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  # generate('devise:views')
  # run 'rm app/views/devise'
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/devise > app/views/devise'

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/ruby/pages_controller.rb > app/controllers/pages_controller.rb'

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  ########################################
  run 'yarn add popper.js jquery bootstrap@4.6'
  append_file 'app/javascript/packs/application.js', <<~JS


    // External imports
    import "bootstrap";

    // Internal imports
    // import { initSelect2 } from '../components/init_select2';

    document.addEventListener('turbolinks:load', () => {
      // initSelect2();
    });
  JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
    <<~JS
      const webpack = require('webpack');
      // Preventing Babel from transpiling NodeModules packages
      environment.loaders.delete('nodeModules');
      // Bootstrap 4 has a dependency over jQuery & Popper.js:
      environment.plugins.prepend('Provide',
        new webpack.ProvidePlugin({
          $: 'jquery',
          jQuery: 'jquery',
          Popper: ['popper.js', 'default']
        })
      );
    JS
  end

  # Devise fr translation
  ########################################
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/yaml/devise.fr.yml > config/locales/devise.fr.yml'

  # Other fr translation
  ########################################
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/yaml/fr.yml > config/locales/fr.yml'

  # simple_form fr translation
  ########################################
  run 'rm config/locales/simple_form.en.yml'
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/yaml/simple_form.en.yml > config/locales/simple_form.en.yml'

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
  git commit: "-m 'Initial commit with devise template from https://github.com/lewagon/rails-templates'"
end
