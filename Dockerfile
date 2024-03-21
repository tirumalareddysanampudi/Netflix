FROM node:latest
WORKDIR /app
COPY package.json package-lock.json* ./
COPY package.json package-lock.json* ./
RUN npm install
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
