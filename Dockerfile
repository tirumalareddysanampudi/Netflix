FROM node:21.7.1-alpine3.19 
WORKDIR /app/
COPY ./package.json  ./
COPY ./yarn.lock  ./
RUN yarn install
COPY . .
ARG MY-NETFLIX
ENV VITE_APP_TMDB_V3_API_KEY=${MY-NETFLIX}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"
RUN yarn build

FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY --from=builder /app/dist .
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]
