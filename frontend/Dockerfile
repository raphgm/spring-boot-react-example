# Use a Node base image to build the app
FROM node:16 AS build

# Set working directory
WORKDIR /app

# Install dependencies and build the app
COPY package.json package-lock.json ./
RUN npm install
COPY . ./
RUN npm run build

# Use a lighter image to serve the app
FROM nginx:alpine

# Copy the build folder to Nginx’s HTML folder
COPY --from=build /app/build /usr/share/nginx/html
#COPY --from=build /app/src/main/resources/static/built /usr/share/nginx/html


EXPOSE 80
