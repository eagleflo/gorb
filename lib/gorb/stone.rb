require 'gorb/group'

class Stone

  attr_accessor :group
  attr_reader :board, :point, :color

  def initialize(board, point, color)
    @board = board
    @point = point
    @color = color

    if (@point[1, 2].to_i > @board.size.split('x')[0].to_i or
        not @board.letters.index(@point[0]))
      raise ArgumentError, "Invalid point"
    end

    @group = self.find_group
  end

  # Return the neighboring points of the Stone.
  def neighbors
    @board.neighbors(@point)
  end

  # Return the liberties of the Stone.
  def liberties
    liberties = neighbors
    stones = @board.search(neighbors)
    stones.each {|stone| liberties.delete(stone.point)}
    return liberties
  end

  # Find the Group of the Stone or create a new one. If this Stone connects
  # one or more groups, merge them together to a single Group.
  def find_group
    groups = []
    stones = @board.search(neighbors)
    stones.each do |stone|
      if stone.color == @color and not groups.include? stone.group
        groups << stone.group
      end
    end
    if groups.empty?
      return Group.new(@board, self)
    else
      group = groups.pop
      group.merge(groups)
      group << self
      return group
    end
  end

  def to_s
    @point
  end

end
