#!/usr/bin/env bash

set -e

app_name="rails"
whoami
id
source ~/.rvm/scripts/rvm
[ -e ~/${app_name} ] || ln -sf /vagrant ~/${app_name}
rvm rvmrc warning ignore ~/${app_name}/.rvmrc
rvm rvmrc trust ~/${app_name}/.rvmrc
# TODO ramdisk
mkdir -p ~/${app_name}/log || true
cd ~/${app_name}
source .rvmrc
rvm info
function createdb_unless_exists()  {
  name=$1
  echo "creating database $name"
  if psql -lqt | cut -d \| -f 1 | grep -w $name; then
    echo "  already exists"
  else
    createdb --template=template0 -E UTF8 $name
  fi
}
createdb_unless_exists ${app_name}_development
createdb_unless_exists ${app_name}_test
createdb_unless_exists ${app_name}_production

[ -r config/database.yml ] && cp -nv config/database.yml{,.previous}
cat > config/database.yml <<-EOYAML
defaults: &defaults
  adapter: postgresql
  encoding: utf-8
  pool: 5
  template: template0

development:
  database: ${app_name}_development
  min_messages: notice
  <<: *defaults

test:
  database: ${app_name}_test
  <<: *defaults

production:
  database: ${app_name}_production
  <<: *defaults
EOYAML
#cp -nv config/application.yml{.example,}
#cp -nv config/features.yml{.example,}
#cp -nv config/sprite_factory.yml{.example,}
bundle install
bundle exec rake db:migrate --trace
bundle exec rake db:migrate RAILS_ENV=test --trace
