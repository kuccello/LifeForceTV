module Gelding
  def self.mail(options)
    raise(ArgumentError, ":to is required") unless options[:to]

    to_addr, message = build_message(options)
    transport_via_sendmail(to_addr, message)
  end

  def self.build_message(options)
    header = []

    header << "From: #{ options[:from] }"
    to_addr = options[:to]
    header << "To: #{ to_addr }"
    header << "Subject: #{ options[:subject] }"
    header << ''
    header << ''

    message = "#{ header.join("\r\n") }#{ options[:body] }"
    return to_addr, message
  end

  def self.sendmail_binary
    @sendmail_binary ||= `which sendmail`.chomp
  end

  def self.transport_via_sendmail(to_addr, message)
    IO.popen('-', 'w+') do |pipe|
      if pipe then
        pipe.write(message)
      else
        exec(sendmail_binary, to_addr)
      end
    end
  end
end

