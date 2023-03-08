# syntax=docker/dockerfile:1

# ---------- build ----------
# Compiles native gems and precompiles assets, so none of the toolchain has to
# ship in the final image.
FROM ruby:3.1.3-slim AS build

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# SECRET_KEY_BASE is only needed to boot the app for `assets:precompile`; the
# real one comes from the environment at run time.
RUN SECRET_KEY_BASE=precompile-placeholder bundle exec rake assets:precompile && \
    rm -rf tmp/cache log/*

# ---------- runtime ----------
FROM ruby:3.1.3-slim AS runtime

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH=/usr/local/bundle \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    PORT=3000

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libpq5 postgresql-client tzdata && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid rails --create-home rails

WORKDIR /app

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build --chown=rails:rails /app /app

USER rails:rails

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS "http://127.0.0.1:${PORT}/up" || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
