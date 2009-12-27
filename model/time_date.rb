require 'date'
class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end
end

class Date
  def to_gm_time
    to_time(new_offset, :gm)
  end

  def to_local_time
    to_time(new_offset(DateTime.now.offset-offset), :local)
  end

  private
  def to_time(dest, method)
    #Convert a fraction of a day to a number of microseconds
    usec = (dest.sec_fraction * 60 * 60 * 24 * (10**6)).to_i
    Time.send(method, dest.year, dest.month, dest.day, dest.hour, dest.min,
              dest.sec, usec)
  end
end

module Lifeforce
  class HelperDate

    attr_accessor :year, :month, :day_of_week, :day_of_month, :timestamp

    def initialize(timestamp)
      t = Time.at(timestamp)

      @month = t.month
      @year = t.year
      @day_of_week = t.wday
      @day_of_month = t.day
      @timestamp = timestamp
    end

    def month_str
      case @month
        when 1
          'Jan'
        when 2
          'Feb'
        when 3
          'Mar'
        when 4
          'Apr'
        when 5
          'May'
        when 6
          'Jun'
        when 7
          'Jul'
        when 8
          'Aug'
        when 9
          'Sept'
        when 10
          'Oct'
        when 11
          'Nov'
        when 12
          'Dec'
      end
    end

    def day_of_week_str
      case @day_of_week
        when 1
          'Sun'
        when 2
          'Mon'
        when 3
          'Tues'
        when 4
          'Wed'
        when 5
          'Thurs'
        when 6
          'Fri'
        when 7
          'Sat'
      end
    end
  end
end
