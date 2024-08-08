FROM docker.io/ruby
WORKDIR /srv/
COPY . .
RUN bundle install
