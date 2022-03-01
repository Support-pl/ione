FROM ruby:2.6-alpine

ADD . /ione
WORKDIR /ione

RUN apk update && apk add --virtual build-dependencies build-base
RUN apk add augeas-dev mariadb-dev postgresql-dev
RUN bundle install

EXPOSE 8009

ENTRYPOINT ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "8009"]
