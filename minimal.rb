run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
    gem 'autoprefixer-rails', '10.2.5'
    gem 'font-awesome-sass'
    gem 'simple_form'

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

# cache control expire
########################################
# inject_into_file 'config/environments/production.rb', before: '# Compress JavaScripts and CSS.' do
#   <<~RUBY

#     config.public_file_server.headers = {
#       'Cache-Control' => 'public, s-maxage=31536000, max-age=15552000',
#       'Expires' => "#{1.year.from_now.to_formatted_s(:rfc822)}"
#     }

#   RUBY
# end

# Procfile
########################################
file 'Procfile', <<~YAML
  release: bundle exec rails db:migrate
  web: bundle exec puma -C config/puma.rb
YAML

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

# Layout
########################################
if Rails.version < "6"
  scripts = <<~HTML
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
        <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  HTML
  gsub_file('app/views/layouts/application.html.erb', "<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>", scripts)
end

gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")

style = <<~HTML
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
HTML
gsub_file('app/views/layouts/application.html.erb', "<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>", style)

# Flashes
########################################
file 'app/views/shared/_flashes.html.erb', <<~HTML
  <% if notice %>
    <div class="alert alert-info alert-dismissible fade show m-1" role="status">
      <%= notice %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Fermer">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
  <% if alert %>
    <div class="alert alert-warning alert-dismissible fade show m-1" role="alert">
      <%= alert %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Fermer">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
HTML

# Navbar & footer
########################################
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/_navbar_wagon_without_login.html.erb > app/views/shared/_navbar.html.erb'
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/_footer_bertrand.html.erb > app/views/shared/_footer.html.erb'
run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/_footer.scss > app/assets/stylesheets/components/_footer.scss'

inject_into_file 'app/assets/stylesheets/components/_index.scss', after: '@import "navbar";' do
  <<-CSS

  @import "footer";
  CSS
end

inject_into_file 'app/assets/stylesheets/application.scss', after: '@import "pages/index";' do
  <<-CSS


  .hidden {
    display: none !important;
  }
  CSS
end

run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb', <<~HTML
  <!DOCTYPE html>
  <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

      <!-- Meta data -->
      <title>App name</title>
      <meta name="Language" content="fr" />
      <meta name="description" content="app description">

      <!-- csrf & csp -->
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>

      <!-- import CSS & JS files -->
      <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
      <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
      <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
    </head>

    <body>
      <!-- notices & alerts -->
      <%= render 'shared/flashes' %>

      <!-- navbar -->
      <%= render 'shared/navbar' %>

      <!-- main content -->
      <main role="main">
        <%= yield %>
      </main>

      <!-- footer -->
      <%= render 'shared/footer' %>

      <!-- noscript tag when JS brower is OFF -->
      <noscript>Votre navigateur web a bloqué le JavaScript. C'est important de le débloquer pour profiter de toutes les fonctionnallités de ce site web !</noscript>
    </body>
  </html>
HTML

# README
########################################
markdown_file_content = <<~MARKDOWN
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

  # Webpacker / Yarn
  ########################################
  run 'yarn add popper.js jquery bootstrap@4.6'
  append_file 'app/javascript/packs/application.js', <<~JS


    // ----------------------------------------------------
    // Note(lewagon): ABOVE IS RAILS DEFAULT CONFIGURATION
    // WRITE YOUR OWN JS STARTING FROM HERE 👇
    // ----------------------------------------------------

    // External imports
    import "bootstrap";

    // Internal imports, e.g:
    // import { initSelect2 } from '../components/init_select2';

    document.addEventListener('turbolinks:load', () => {
      // Call your functions here, e.g:
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

  # Other fr translation
  ########################################
  run 'curl -L https://github.com/Bertrand-Bichat/awesome-navbars/raw/master/templates/fr.yml > config/locales/fr.yml'

  # simple_form fr translation
  ########################################
  run 'rm config/locales/simple_form.en.yml'
  file 'config/locales/simple_form.en.yml', <<~YAML
    fr:
      simple_form:
        "yes": 'Oui'
        "no": 'Non'
        required:
          text: 'obligatoire'
          mark: '*'
          # You can uncomment the line below if you need to overwrite the whole required html.
          # When using html, text and mark won't be used.
          # html: '<abbr title="required">*</abbr>'
        error_notification:
          default_message: "Erreurs de saisie"
        # Examples
        # labels:
        #   defaults:
        #     password: 'Password'
        #   user:
        #     new:
        #       email: 'E-mail to sign in.'
        #     edit:
        #       email: 'E-mail.'
        # hints:
        #   defaults:
        #     username: 'User name to sign in.'
        #     password: 'No special characters, please.'
        # include_blanks:
        #   defaults:
        #     age: 'Rather not say'
        # prompts:
        #   defaults:
        #     age: 'Select your age'
  YAML

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
  git commit: "-m 'Initial commit with minimal template from https://github.com/lewagon/rails-templates'"
end
