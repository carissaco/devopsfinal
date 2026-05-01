FROM node:20-alpine AS build
WORKDIR /app
ARG VITE_CATALOG_URL
ARG VITE_ORDERS_URL
ARG VITE_INVENTORY_URL
ENV VITE_CATALOG_URL=$VITE_CATALOG_URL
ENV VITE_ORDERS_URL=$VITE_ORDERS_URL
ENV VITE_INVENTORY_URL=$VITE_INVENTORY_URL
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
