FROM ruby:2.3
RUN mkdir /api_gateway
WORKDIR /api_gateway
ADD Gemfile /api_gateway/Gemfile
ADD Gemfile.lock /api_gateway/Gemfile.lock
RUN bundle install
ADD . /api_gateway
