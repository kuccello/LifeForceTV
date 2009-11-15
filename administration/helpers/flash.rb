module LifeForceAdminHelpers
  module Flash
    def flash_message
      haml :'snippets/flash',:layout=>false
    end
  end
end
