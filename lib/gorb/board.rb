require 'gorb/stone'

class Board

  attr_accessor :groups, :turn
  attr_reader :black, :white, :handicap, :komi, :size, :letters, :dead_groups

  # Initialize a new Board instance. Requires two Player objects, a handicap,
  # a komi and a size as arguments. The handicap should be an integer from
  # 0 to 9. Komi can be negative. Size should be either 9x9, 13x13 or 19x19.
  def initialize(black=nil, white=nil, handicap=0, komi=6.5, size="19x19")
    @black = black ||= Player.new("Black")
    @white = white ||= Player.new("White")
    @komi = komi
    @size = size
    @groups = []
    @hashes = []
    @turn = black
    @dead_groups = []

    raise ArgumentError, "Incorrect handicap" if handicap < 0 or handicap > 9
    @handicap = handicap
    @komi = 0.5 if handicap > 0
    @turn = white if handicap > 1

    if size == "9x9"
      @letters = %w{A B C D E F G H J}
      handicap_stones = %w{G7 C3 G3 C7 E5 C5 G5 E7 E3}
    elsif size == "13x13"
      @letters = %w{A B C D E F G H J K L M N}
      handicap_stones = %w{K10 D4 K4 D10 G7 D7 K7 G10 G4}
    elsif size == "19x19"
      @letters = %w{A B C D E F G H J K L M N O P Q R S T}
      handicap_stones = %w{Q16 D4 Q4 D16 K10 D10 Q10 K16 K4}
    else
      raise ArgumentError, "Incorrect board size"
    end

    case @handicap
    when 2..5, 7, 9
      handicap_stones[0..(@handicap-1)].each {|s| self.add_stone(s, :black)}
    when 6, 8
      handicap_stones[0..@handicap].each {|s| self.add_stone(s, :black)}
      self.remove_stone(handicap_stones[4]) # Middle stone
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

  def legal?(point, color)
    # Check if the point is already occupied.
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

  # Recalculate all liberties. Removes dead groups from the table.
  def resolve!(added_stone)
    @groups.reject {|group| group.color == added_stone.color}.each do |group|
      libs = group.liberties!
      self.send(added_stone.color).captured += group.size if libs == 0
    end
  end

  # Search the Board for stones in given points.
  def search(points)
    if points.is_a?(String)
      points = [points]
    end
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

  # Return the neighboring points of the point.
  def neighbors(point)
    x, y = @letters.index(point.chars.first), point[1, 2].to_i
    neighbors = []
    unless y == 1
      neighbors << @letters[x] + (y - 1).to_s
    end
    unless y == self.size.split('x')[0].to_i
      neighbors << @letters[x] + (y + 1).to_s
    end
    unless @letters[x] == @letters.first
      neighbors << @letters[x-1] + y.to_s
    end
    unless @letters[x] == @letters.last
      neighbors << @letters[x+1] + y.to_s
    end
    return neighbors
  end

  # Generate a hash of a board situation. Used to enforce ko rule.
  def generate_hash
    @groups.flatten.inject([]) {|hash, stone| hash << stone.to_s}.sort.hash
  end

  # Pass the turn and generate a hash of the board situation for checking ko.
  def turn_over
    if @turn == @black
      @turn = @white
    else
      @turn = @black
    end
    @hashes << generate_hash
  end

  # Mark dead groups after the game has ended to ease the scoring.
  def mark_dead_group(stone)
    group = self.search(stone).first.group
    @dead_groups << group
  end

  # Count the score.
  def scoring
    white, black = 0, 0

    # Remove dead groups from board (or its clone).
    score_board = Marshal.load(Marshal.dump(self))
    score_board.dead_groups.each do |group|
      score_board.groups.delete(group)
      if group.first.color == :white
        black += group.size
      elsif group.first.color == :black
        white += group.size
      end
    end

    # Collect all empty points into a list.
    empty_points = []
    side = self.size.split('x')[0].to_i
    for i in (0..side-1)
      for j in (0..side-1)
        coords = @letters[i] + (side - j).to_s
        if not score_board.stone_at?(coords)
          empty_points << coords
        end
      end
    end

    # Flood fill and remove from list of empty points.
    areas = []
    until empty_points.empty?
      current_area = []
      first_point = empty_points.first
      remove_from_empty_points = Proc.new do |point|
        if empty_points.include? point
          current_area << empty_points.delete(point)
          for neighbor in self.neighbors(point)
            remove_from_empty_points.call(neighbor)
          end
        end
      end
      remove_from_empty_points.call(first_point)
      areas << current_area
    end

    # Check bordering stones or groups: if uniform, award points.
    areas.each do |area|
      colors = []
      area.each do |empty_point|
        self.neighbors(empty_point).each do |neighbor|
          stone = score_board.search(neighbor).first
          if stone
            colors << stone.color unless colors.include? stone.color
          end
        end
      end
      if colors == [:white]
        white += area.size
      elsif colors == [:black]
        black += area.size
      end
    end

    # Add captured stones to the total.
    white += score_board.white.captured
    black += score_board.black.captured

    # Add komi.
    white += self.komi

    {:white => white, :black => black}
  end

  # Read a board situation from a (possibly incomplete) diagram.
  def read(diagram)
    # Try to read captured pieces information from gnugo output.
    black_captured = /Black \(X\) has captured (\d) pieces/.match(diagram)
    white_captured = /White \(O\) has captured (\d) pieces/.match(diagram)

    if black_captured
      self.black.captured += black_captured.captures.first.to_i
    end
    if white_captured
      self.white.captured += white_captured.captures.first.to_i
    end

    diagram.gsub!(/Black.*/, '')
    diagram.gsub!(/White.*/, '')
    diagram.gsub!(/N O P/, '')
    diagram.gsub!(/[A-NP-WYZa-z0-9]/, '')
    diagram.gsub!(/[-| ():]/, '')
    diagram.strip().split("\n").each_with_index do |line, i|
      line.split("").each_with_index do |char, j|
        coords = @letters[j] + (self.size.split('x')[0].to_i-i).to_s
        if char == "X"
          self.add_stone(coords, :black)
        elsif char == "O"
          self.add_stone(coords, :white)
        end
      end
    end
  end

end
