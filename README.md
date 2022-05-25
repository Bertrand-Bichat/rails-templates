# Rails Templates

Quickly generate a rails app with the default [Wagon](https://www.lewagon.com) configuration
using [Rails Templates](http://guides.rubyonrails.org/rails_application_templates.html) +
some custom personal additions.


## Minimal

Get a minimal rails app ready to be deployed on Heroku (Procfile) with Bootstrap + Stimulus + Simple form +
debugging gems + N+1 queries gems + custom navbar + custom footer + custom layout +
YAML files for French translation of flashes +
robots.txt file configured to not index all the website

```bash
rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/Bertrand-Bichat/rails-templates/master/minimal.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```

## Devise

Same as minimal **plus** a Devise install with a generated `User` model +
Pundit authorization gem + all Devise views with French text and better CSS +
custom controllers (app. and pages) + custom seeds.

```bash
rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/Bertrand-Bichat/rails-templates/master/devise.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```

## API

Get an API rails backend ready to be deployed on Heroku (Procfile).

```bash
rails new \
  --database postgresql \
  --api \
  -m https://raw.githubusercontent.com/Bertrand-Bichat/rails-templates/master/api.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```
