require 'rubygems'
require 'xampl'
require File.join(File.dirname(__FILE__), "generated_model/LifeForce")

module Lifeforce

  STATUS_PENDING = "pending"
  STATUS_LIVE = "live"
  STATUS_DELETED = "deleted"

  Xampl.set_default_persister_kind(:tokyo_cabinet)
  Xampl.set_default_persister_format(:xml_format)

  def Lifeforce.persistence_type
    Xampl.default_persister_kind
  end

  def Lifeforce.root
    $root_requests = 0 unless $root_requests
    $new_root_counter = 0 unless $new_root_counter
    $root_requests += 1

    
    root = nil
    Lifeforce.transaction do
      root = Lifeforcetv[$TRANSACTION_CONTEXT]

      unless root

        root = Lifeforcetv.lookup($TRANSACTION_CONTEXT)

        unless root

          $new_root_counter += 1

          root = Lifeforcetv.new($TRANSACTION_CONTEXT) do | it |
            #it.setup_defaults
          end
        end
      end
    end
    root
  end

  def Lifeforce.transaction
    result = nil
    Xampl.transaction($TRANSACTION_CONTEXT) do
      result = yield
    end
    result
  end

  def Lifeforce.pid_from_string(string)
    string.downcase.gsub(/[ \/\\:\?'"%!@#\$\^&\*\(\)\+]/, '')
  end


end
