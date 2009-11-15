require 'digest/md5'

module Lifeforce
  class Member


    def password=(pass)
      self.md5_password = Member.encrypt(pass+self.pid)
    end

    def admin?
      self.is_admin.downcase == 'yes'
    end

    def token
      encrypt("#{self.email}#{self.password}")
    end

    def self.valid_token?(token)
      Lifeforce.root.member.each do |member|
        return true if member.token == token
      end
      false
    end

    def self.authenticate(email, pass)
      current_user = Member.find_by_email(email)
      return nil if current_user.nil?
      return current_user if Member.encrypt(pass+email) == current_user.md5_password
      nil
    end

    def self.authenticate_as_admin(email, pass)
      m = Member.authenticate(email, pass)
      return m if m && m.admin?
      nil
    end

    def self.find_by_email(email)
      Lifeforce.root.member.each do |member|
        return member if member.email.downcase == email.downcase
      end
      nil
    end

    # TODO ----
    def self.create_default_administrator(email, password)
      puts "#{__FILE__}:#{__LINE__} #{__method__} TODO ____ create_default_admin"
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
