FROM node:latest AS builder
ADD . /app
WORKDIR /app

RUN npm install
RUN npm run build

# final
FROM alpine:3.13.2
RUN apk add thttpd
RUN adduser -D static
WORKDIR /home/static

COPY --from=builder /app/dist .
COPY --from=builder /app/command.sh .

RUN chmod +x command.sh
RUN chmod ugo+w config.js

USER static
ENTRYPOINT ["sh", "command.sh" ]
