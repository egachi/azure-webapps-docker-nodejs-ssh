FROM node:lts-buster-slim
RUN mkdir /code
WORKDIR /code
ADD package.json /code/
RUN npm install
ADD . /code/

# ssh
ENV SSH_PASSWD "root:Docker!"
RUN apt-get update \
        && apt-get install -y --no-install-recommends apt-utils dialog openssh-server \
	&& echo "$SSH_PASSWD" | chpasswd 

COPY sshd_config /etc/ssh/
COPY init.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/init.sh

EXPOSE 3000 2222
ENTRYPOINT ["/usr/local/bin/init.sh"]



# we can also redue docker file size even for prebuild docker rocker nodejs images 
# reference code below 

#!/bin/bash


FROM node:17.9.0 AS base

WORKDIR /usr/src/app

COPY package*.json ./
    
RUN npm install

COPY . .

# for lint

FROM base as linter

WORKDIR /usr/src/app

RUN npm run lint

# for build

FROM linter as builder

WORKDIR /usr/src/app

RUN npm run build


# for production

FROM node:17.9.0-alpine3.15

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install --only=production

COPY --from=builder /usr/src/app/dist ./

EXPOSE 3000

ENTRYPOINT ["node","./app.js"]

# run dependecy builds 
