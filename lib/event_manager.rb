# frozen_string_literal: true

# Manages events and their handlers
class EventManager
  attr_reader :handlers

  def initialize(logger)
    @handlers = []
    @logger = logger
  end

  def subscribe(&handler)
    handlers << handler unless handlers.include?(handler)
  end

  def unsubscribe(&handler)
    handlers.delete(handler)
  end

  def broadcast(*args)
    handlers.map do |handler|
      handler.call(*args)
    rescue => err
      logger.error err
    end
  end

  private

  attr_reader :logger
end
