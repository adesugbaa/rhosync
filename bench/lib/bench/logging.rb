module Bench
  module Logging
    def logger
      init_logger if Log4r::Logger['main'].nil?
      Log4r::Logger['main']
    end
    
    def log_prefix
      "[T:%03d|I:%03d]" % [@thread_id,@iteration]
    end

    protected
    def init_logger
      logger = Log4r::Logger.new('main')
      logger.outputters = Log4r::Outputter.stdout
    end
  end
end