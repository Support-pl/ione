FROM node:latest

ADD . /app
WORKDIR /app

RUN npm install
RUN npm install -g serve
RUN chmod +x command.sh

ENTRYPOINT [ "/app/command.sh" ]