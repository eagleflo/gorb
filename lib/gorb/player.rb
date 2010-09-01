class Player

  def initialize(name="Anonymous", rank=nil)
    @name = name
    @rank = rank
  end

  def to_str
    @name
  end

end
