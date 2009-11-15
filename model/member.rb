require 'digest/sha1'

module Lifeforce
  class Member


    def password=(pass)
      self.md5_password = Member.encrypt("#{self.email}#{pass}")
    end

    def admin?
      self.is_admin.downcase == 'yes'
    end

    def token
      Member.encrypt("#{self.email}#{self.md5_password}")
    end

    def self.valid_token?(token)
      Lifeforce.root.member.each do |member|
        return true if member.token == token
      end
      false
    end

    def self.authenticate(email, pass)
      current_user = Member.find_by_email(email)
      return nil if current_user == nil
      return current_user if Member.encrypt("#{email}#{pass}") == current_user.md5_password
#      puts "#{__FILE__}:#{__LINE__} #{__method__} HERE -- did they match? #{Member.encrypt("#{email}#{pass}") == current_user.md5_password} (#{Member.encrypt("#{email}#{pass}")} == #{current_user.md5_password}"
      nil
    end

    def self.authenticate_as_admin(email, pass)
      m = Member.authenticate(email, pass)
#      puts "#{__FILE__}:#{__LINE__} #{__method__} Member authenticated: #{m.inspect} -- #{Lifeforce.root.pp_xml}"
      return m if m && m.admin?
      nil
    end

    def self.find_by_email(email)
      m = nil
      Lifeforce.root.member.each do |member|
#        puts "#{__FILE__}:#{__LINE__} #{__method__} MEMBER: #{member.pp_xml} \n\n#{email}\n\n was a match? #{member.email.downcase == email.downcase}"
        m = member if (member.email.downcase == email.downcase)
      end
      m
    end

    
    def self.create_default_administrator(email, password)
      Lifeforce.transaction do
        unless authenticate(email,password)
          default_admin =Lifeforce.root.new_member(Lifeforce.pid_from_string(encrypt(email)))
          default_admin.name = "Default Administrator"
          default_admin.handle = "Administrator"
          default_admin.email = email # always must be set first!!!
          default_admin.password = password # dont worry its encrypted -- see Member
          default_admin.last_login = Time.new.to_s
          default_admin.last_ip = "0.0.0.0"
          default_admin.status = "active"
          default_admin.is_admin = "yes"
        end
      end
    end

    protected
    def self.encrypt(pass)
      Digest::SHA1.hexdigest(pass)
    end

    def self.random_string(len)
      #generate a random password consisting of strings and digits
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      newpass = ""
      1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
      return newpass
    end
  end
end
