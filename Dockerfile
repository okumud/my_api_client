ARG RUBY_VERSION=3.0

FROM ruby:${RUBY_VERSION}-slim

ARG ROOT_PATH=.
ARG APP_DIR=/opt/myapp
ARG USER_ID=10000
ARG GROUP_ID=10000
ARG USER_NAME=user

RUN set -x \
  && apt-get update -qq \
  && apt-get install -y --no-install-recommends \
       default-libmysqlclient-dev \
       build-essential \
       curl \
       gzip libc6 \
       git \
  && curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
  && apt-get install -y --no-install-recommends \
       nodejs \
  && npm install --global yarn

RUN set -x \
  && mkdir -p ${APP_DIR}/${ROOT_PATH} ${APP_DIR}/lib/my_api_client \
  && echo "#!/bin/sh" > /opt/entrypoint.sh \
  && echo "set -ex" >> /opt/entrypoint.sh \
  && echo "rm -f tmp/pids/server.pid" >> /opt/entrypoint.sh \
  && echo "bundle config set force_ruby_platform true" >> /opt/entrypoint.sh \
  && echo "bundle install" >> /opt/entrypoint.sh \
  && echo "exec \"\$@\"" >> /opt/entrypoint.sh \
  && chmod +x /opt/entrypoint.sh
COPY ${ROOT_PATH}/Gemfile ${ROOT_PATH}/Gemfile.lock ${APP_DIR}/${ROOT_PATH}
COPY my_api_client.gemspec ${APP_DIR}/
COPY lib/my_api_client/version.rb ${APP_DIR}/lib/my_api_client/
WORKDIR ${APP_DIR}/${ROOT_PATH}

ENTRYPOINT ["/opt/entrypoint.sh"]
EXPOSE 3000

CMD ["sh", "-c", "while true ; do sleep 1; done"]

RUN set -x \
 && useradd -u $USER_ID -o -m $USER_NAME \
 && groupmod -g $GROUP_ID $USER_NAME
# USER $USER_NAME
RUN set -x \
  && bundle config set force_ruby_platform true \
  && bundle install

#WORKDIR ${APP_DIR}
