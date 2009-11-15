class String
  def starts_with?(characters)
    self.match(/^#{characters}/) ? true : false
  end
end
