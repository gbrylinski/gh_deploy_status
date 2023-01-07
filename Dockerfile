FROM ruby:slim AS builder

RUN mkdir /app
WORKDIR /app
COPY notifier.rb .

CMD ["ruby", "/app/notifier.rb"]
