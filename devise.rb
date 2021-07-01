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
inject_into_file 'config/environments/development.rb', before: 'config.file_watcher' do
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
    <div class="alert alert-info alert-dismissible fade show m-1" role="alert">
      <%= notice %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
  <% if alert %>
    <div class="alert alert-warning alert-dismissible fade show m-1" role="alert">
      <%= alert %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
HTML

run 'curl -L https://github.com/lewagon/awesome-navbars/raw/master/templates/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb'

inject_into_file 'app/views/layouts/application.html.erb', after: '<body>' do
  <<-HTML

    <%= render 'shared/navbar' %>
    <%= render 'shared/flashes' %>
  HTML
end

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

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # Pundit install
  ########################################
  rails_command 'g pundit:install'

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
  file 'app/policies/page_policy.rb', <<~RUBY
    class PagePolicy < Struct.new(:user, :page)

      def home?
        true
      end

      def user_loggedin?
        user != nil
      end
    end
  RUBY

  # Devise helpers methods
  ########################################
  file 'app/helpers/devise_helper.rb', <<~RUBY
    module DeviseHelper
      # Devise form in other views
      def resource_name
        :user
      end

      def resource
        @resource ||= User.new
      end

      def resource_class
        User
      end

      def devise_mapping
        @devise_mapping ||= Devise.mappings[:user]
      end
    end
  RUBY

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<~RUBY
    class ApplicationController < ActionController::Base
      #{"protect_from_forgery with: :exception\n" if Rails.version < "5.2"}
      before_action :authenticate_user!
      # stock la page actuelle avant d'authentifier l'utilisateur afin de pouvoir revenir dessus après le login
      before_action :store_user_location!, if: :storable_location?
      before_action :configure_permitted_parameters, if: :devise_controller?

      include Pundit

      # Pundit: white-list approach.
      after_action :verify_authorized, except: [:index, :my_journeys_index], unless: :skip_pundit?
      after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?

      # Raise an alert if not authorized
      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

      # protected

      # def after_update_path_for(resource)
      #   stored_location_for(resource) || root_path
      # end

      # def update_resource(resource, params)
      #   resource.update_without_password(params)

      #   # Require current password if user is trying to change password.
      #   # return super if params["password"]&.present?

      #   # Allows user to update registration information without password.
      #   # resource.update_without_password(params.except("current_password"))
      # end

      private

      # def after_sign_in_path_for(resource)
      #   stored_location_for(resource) || root_path
      # end

      # def after_sign_up_path_for(resource)
      #   stored_location_for(resource) || root_path
      # end

      def user_not_authorized
        flash[:alert] = "Vous n'êtes pas autorisé à effectuer cette action."
        redirect_to(root_path)
      end

      # vérifie que la page peut être stocker pour ne pas tomber dans une boucle de redirection infinie
      def storable_location?
        request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
      end

      # stock la page pour que l'utilisateur soit redirigé après le login
      def store_user_location!
        # :user is the scope we are authenticating
        store_location_for(:user, request.fullpath)
      end

      def skip_pundit?
        devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
      end

      def default_url_options
       { host: ENV['DOMAIN'] || "localhost:3000" } #rajouter le nom de domaine en prod
      end

      # equivalent a user_params (qu'est-ce qu'on autorise a etre modifie)
      def configure_permitted_parameters
        # lors de la creation d'un nouveau compte
        devise_parameter_sanitizer.permit(:sign_up) do |user_params|
          user_params.permit(
            :email,
            :password,
            :password_confirmation
          )
        end

        # lors de la modification d'un compte deja existant
        devise_parameter_sanitizer.permit(:account_update) do |user_params|
          user_params.permit(
            :email,
            :password,
            :password_confirmation,
            :current_password
          )
        end
      end
    end
  RUBY

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  generate('devise:views')

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<~RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [:home]

      def home
        authorize :page, :home?
      end
    end
  RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

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

  # Dotenv
  ########################################
  run 'touch .env'

  # Rubocop
  ########################################
  run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Git
  ########################################
  git add: '.'
  git commit: "-m 'Initial commit with devise template from https://github.com/lewagon/rails-templates'"

  # Fix puma config
  gsub_file('config/puma.rb', 'pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }', '# pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }')
end
