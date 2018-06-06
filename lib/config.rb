
require 'dotenv/load'


Config = Struct.new(:account, :password, :host, :port).new(
  ENV['SYNO_USERNAME'],
  ENV['SYNO_PASSWORD'],
  ENV['SYNO_HOST'],
  ENV['SYNO_PORT'].to_i || 5000
)
