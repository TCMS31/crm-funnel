# frozen_string_literal: true

# One thread count drives both Puma and the ActiveRecord pool (database.yml), so
# a request thread never waits on a connection.
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

port ENV.fetch('PORT', 3000)

# Allow `bin/rails restart` to restart Puma.
plugin :tmp_restart

pidfile ENV['PIDFILE'] if ENV['PIDFILE']
