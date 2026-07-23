# Multi-stage build for the landing-astro static site, served by nginx.
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Optional override for the requirements endpoint. Must be declared in this
# stage: ARGs are not inherited across FROM. Defaults to the URL compiled
# into src/pages/index.astro when left empty.
ARG PUBLIC_REQUIREMENTS_ENDPOINT=""
ENV PUBLIC_REQUIREMENTS_ENDPOINT=$PUBLIC_REQUIREMENTS_ENDPOINT
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
