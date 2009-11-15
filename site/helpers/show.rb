helpers do

  #
  # show_highlight(show)
  # =======================================
  # description:
  # ----------------
  # renders an entry
  #
  # params:
  # ----------------
  # show - the show object to hightlight
  #
  # returns:
  # ----------------
  # html
  def show_highlight(show)
    haml :'snippets/showhighlight',:layout=>false,:locals=>{:show=>show}
  end

end
