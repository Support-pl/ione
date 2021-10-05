FROM node:latest

ADD . /app
WORKDIR /app

RUN npm install
RUN npm install -g serve
RUN npm run build
RUN chmod +x command.sh

EXPOSE 5000
ENTRYPOINT [ "/app/command.sh" ]
