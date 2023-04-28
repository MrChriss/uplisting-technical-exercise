FROM ruby:3.2.2-bullseye

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV BUNDLER_VERSION=2.4.12
ENV APP_DIR=/usr/src/app
ARG bundle_install_args

RUN mkdir -p ${APP_DIR} && \
    echo "gem: --no-document" > /root/.gemrc

WORKDIR ${APP_DIR}

RUN apt-get update -qq && \
    apt-get install -qq --fix-missing --no-install-recommends -y && \
    apt-get autoremove -yq && rm -rf /var/lib/apt && rm -rf /var/cache/apt

COPY Gemfile Gemfile.lock ${APP_DIR}/

RUN gem install bundler -v ${BUNDLER_VERSION}

RUN bundle check || bundle install $bundle_install_args --jobs 10 --retry 5

COPY . ${APP_DIR}

CMD ["bundler", "exec", "rspec; standardrb; reek; rubocop"]
