FROM docker.io/debian AS build

WORKDIR /srv
RUN apt update && apt install -y pandoc
COPY . .
RUN ./build.sh


FROM nginx

COPY --from=build /srv/www/ /usr/share/nginx/html
