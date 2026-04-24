FROM node:24-alpine

# Update packages to fix known OS vulnerabilities (e.g., busybox, openssl)
RUN apk update && apk upgrade --no-cache

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD [ "npm", "start" ]