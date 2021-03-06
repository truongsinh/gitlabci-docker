FROM tianon/debian

MAINTAINER Anastas Semenov <anapsix@random.io>

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes libxml2-dev libxslt-dev libreadline6-dev libc6-dev libssl-dev libyaml-dev libicu-dev zlib1g-dev libsqlite3-dev libmysqlclient-dev wget gcc build-essential make git sudo postfix cron ruby1.9.1 ruby1.9.1-dev rubygems-integration redis-server
RUN gem install bundle --no-ri --no-rdoc

RUN adduser --disabled-login --gecos 'GitLab CI' gitlab_ci

RUN cd /home/gitlab_ci; sudo -u gitlab_ci -H git clone -b 4-3-stable --depth 1 https://github.com/gitlabhq/gitlab-ci.git gitlab-ci
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H mkdir -p tmp/pids tmp/sockets log

# add and patch to support SQLITE3
ADD ./BUNDLER-adding-sqlite3-support.patch /home/gitlab_ci/gitlab-ci/BUNDLER-adding-sqlite3-support.patch
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H git am BUNDLER-adding-sqlite3-support.patch;

RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H bundle install --without development test postgres --deployment

# add and run gitlabci ctrl
ADD ./gitlab_ctrl.rb /home/gitlab_ci/gitlab-ci/gitlabci_ctrl.rb
RUN chmod +x /home/gitlab_ci/gitlab-ci/gitlabci_ctrl.rb

RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H ./gitlabci_ctrl.rb --puma --app GITLAB_URLS="https://dev.gitlab.org/"
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H bundle exec whenever -w RAILS_ENV=production

# cleanup, if needed
#RUN DEBIAN_FRONTEND=noninteractive apt-get remove --force-yes -y ruby1.9.1-dev
#RUN DEBIAN_FRONTEND=noninteractive apt-get autoremove --force-yes -y

EXPOSE 9000

WORKDIR /home/gitlab_ci/gitlab-ci
CMD /home/gitlab_ci/gitlab-ci/gitlabci_ctrl.rb --start
