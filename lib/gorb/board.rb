require 'gorb/stone'

class Board

  attr_accessor :groups, :turn
  attr_reader :black, :white, :handicap, :komi

  # Initialize a new Board instance. Requires two Player objects and a
  # handicap as arguments. The handicap should be an integer from 0 to 9.
  def initialize(black=nil, white=nil, handicap=0, komi=6.5)
    @black = black ||= Player.new("Black")
    @white = white ||= Player.new("White")
    @komi = komi
    @groups = []
    @hashes = []
    @turn = black

    raise ArgumentError, "Incorrect handicap" if handicap < 0 or handicap > 9
    @handicap = handicap
    @komi = 0.5 if handicap > 0
    @turn = white if handicap > 1

    handicap_stones = %w{Q16 D4 Q4 D16 K10 D10 Q10 K16 K4}
    case @handicap
    when 2..5, 7, 9
      handicap_stones[0..(@handicap-1)].each {|s| self.add_stone(s, :black)}
    when 6, 8
      handicap_stones[0..@handicap].each {|s| self.add_stone(s, :black)}
      self.remove_stone("K10")
    end
  end

  # Add a Stone to the board if the move is legal. This function will also
  # keep track of the turn. You can force the color with additional color
  # argument -- in this case the turn is not changing.
  def add_stone(point, color=nil)
    # Guess the color based on turn, unless color was forced.
    unless color
      if @turn == black
        color = :black
      else
        color = :white
      end
      advance = true
    end

    # Check the legality of the move and play it if legal.
    raise ArgumentError, "Illegal move" unless legal?(point, color)
    stone = Stone.new(self, point, color)
    resolve!(stone)

    # If the color was not explicitly set, advance the turn.
    turn_over if advance
    return stone
  end

  def remove_stone(point)
    stone = self.search(point).first
    raise ArgumentError, "No such stone" unless stone
    stone.group.delete(stone)
    stone.board.groups.delete(stone.group) if stone.group.size == 0
  end

  # Search the Board for stones in given points.
  def search(points)
    stones = []
    @groups.each do |group|
      group.each do |stone|
        stones << stone if points.include? stone.point
      end
    end
    return stones
  end

  def stone_at?(point)
    @groups.any? {|group| group.include? point}
  end

  def stones_at?(points)
    points.all? {|point| self.stone_at? point}
  end

  # Recalculate all liberties. Removes dead groups from the table.
  def resolve!(added_stone)
    @groups.each do |group|
      group.liberties! if not group.include? added_stone
    end
    # The group of last added stone is checked after others to make kills by
    # 'suicide' (filling dame) work.
    added_stone.group.liberties!
  end

  # Generate a hash of a board situation. Used to enforce ko rule.
  def generate_hash
    @groups.flatten.inject([]) {|hash, stone| hash << stone.to_s}.sort.hash
  end

  def legal?(point, color)
    # Check if the point if already occupied.
    return false if self.stone_at? point

    # The method for checking legality requires placing a test stone to the
    # point and seeing what happens. This is done by doing a deep copy of the
    # board and playing the move there.
    dummy_board = Marshal.load(Marshal.dump(self))

    # Check for suicide.
    stone = Stone.new(dummy_board, point, color)
    legal = true
    if stone.group.liberties == 0
      # Normally suicide is not ok...
      legal = false
      # ...but killing with 'suicide' (filling dame) is ok.
      opposing = dummy_board.search(stone.neighbors)
      opposing.each do |opp_stone|
        if opp_stone.color != color and opp_stone.group.liberties == 0
          legal = true
        end
      end
    end

    # Check for ko.
    dummy_board.resolve!(stone)
    legal = false if @hashes.include? dummy_board.generate_hash
    return legal
  end

  def turn_over
    if @turn == @black
      @turn = @white
    else
      @turn = @black
    end
    @hashes << generate_hash
  end

end