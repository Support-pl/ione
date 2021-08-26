FROM ruby:2.5.5

ADD . /ione
WORKDIR /ione

RUN bundle install

ENTRYPOINT ["ruby", "/ione/ione_server.rb"]