FROM ruby:2.5.5-alpine

ADD . /ione
WORKDIR /ione

RUN apk update && apk add --virtual build-dependencies build-base
RUN apk add augeas-dev mariadb-dev postgresql-dev
RUN bundle install

ENTRYPOINT ["bundle", "exec", "rackup"]