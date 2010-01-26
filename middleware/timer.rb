class CodeTimer

  def initialize(app)
    @app = app
  end

  def call(env)
    begin_time = Time.new.to_i
    result = @app.call(env)
    end_time = Time.new.to_i

    puts "#{__FILE__}:#{__LINE__} #{__method__} CALL TIME: #{(end_time - begin_time)}"
    result
  end

  def timed_call
    begin_time = Time.new.to_i
    result = yield
    end_time = Time.new.to_i
    puts "#{__FILE__}:#{__LINE__} #{__method__} CALL TIME: #{(end_time - begin_time)}"
    result
  end
end
