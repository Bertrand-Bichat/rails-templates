# Rails Templates

Quickly generate a rails app with the default [Wagon](https://www.lewagon.com) configuration
using [Rails Templates](http://guides.rubyonrails.org/rails_application_templates.html) +
some custom personal additions.


## Minimal

Get a minimal rails app ready to be deployed on Heroku with Bootstrap, Simple form and debugging gems.

```bash
rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/Bertrand-Bichat/rails-templates/master/minimal.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```

## Devise

Same as minimal **plus** a Devise install with a generated `User` model + Pundit authorization gem +
N+1 queries gems + Procfile ready to use for Heroku + robots.txt file configured to not index all
the website + YAML files for French translation of Devise and Simple Form flashes.

```bash
rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/Bertrand-Bichat/rails-templates/master/devise.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```
