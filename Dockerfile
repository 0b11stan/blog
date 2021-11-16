FROM docker.io/debian AS build

WORKDIR /srv
RUN apt-get update && apt-get install -y pandoc make
COPY . .
RUN make www


FROM nginx

COPY --from=build /srv/www/ /usr/share/nginx/html
