FROM elixir:1.19.2-otp-28-slim AS build

WORKDIR /app

ENV MIX_ENV=prod

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force \
    && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY lib ./lib
RUN mix compile
RUN mix release

FROM debian:bookworm-slim AS app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates libstdc++6 openssl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    MIX_ENV=prod \
    PORT=8080

COPY --from=build /app/_build/prod/rel/rc_car_ws ./

EXPOSE 8080

CMD ["/app/bin/rc_car_ws", "start"]
