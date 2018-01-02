require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every(1.hour, 'Tokai') do
    TokaiLend.list
  end
end
