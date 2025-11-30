# Build stage
FROM hexpm/elixir:1.18.3-erlang-27.3.4-alpine-3.21.3 AS builder

RUN apk add --no-cache build-base git dos2unix

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY lib lib
COPY priv priv
COPY rel rel

RUN find rel -type f -name "*.eex" -exec dos2unix {} \;

RUN mix compile
RUN mix release

# Runtime stage
FROM hexpm/elixir:1.18.3-erlang-27.3.4-alpine-3.21.3 AS runner

RUN apk add --no-cache libstdc++ openssl ncurses-libs libgcc

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/lootify_bets ./
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh && \
    dos2unix ./entrypoint.sh 2>/dev/null || true && \
    adduser -D appuser && chown -R appuser /app

USER appuser

ENV HOME=/app

# EPMD + Erlang distribution ports
EXPOSE 4369 9000 9001 9002 9003 9004 9005 9006 9007 9008 9009 9010

ENTRYPOINT ["./entrypoint.sh"]
