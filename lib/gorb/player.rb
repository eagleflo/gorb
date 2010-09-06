class Player

  attr_accessor :captured
  attr_reader :name, :rank

  def initialize(name="Anonymous", rank=nil)
    @name = name
    @rank = rank
    @captured = 0
  end

  def to_str
    @name
  end

end
