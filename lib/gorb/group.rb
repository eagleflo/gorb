class Group < Array

  def initialize(board, stone)
    @board = board
    @board.groups << self
    self << stone
  end

  def merge(groups)
    groups.each do |group|
      group.each {|stone| self << stone}
      @board.groups.delete group
    end
  end

  def include?(point)
    self.any? {|stone| stone.point == point}
  end

  # Check the liberties of the Group.
  def liberties
    libs = []
    self.each do |stone|
      stone.liberties.each do |liberty|
        libs << liberty
      end
    end
    libs.uniq!
    return libs.size
  end

  # Destructive version of the former. Note that this will remove the Group
  # from the board if it has no liberties, so all the existing groups should
  # have their liberties checked before checking the liberties of a new group
  # in order to allow kills by filling dame.
  def liberties!
    libs = self.liberties
    @board.groups.delete(self) if libs == 0
    return libs
  end

end
