require 'test/unit'
require 'gorb'

class TestStone < Test::Unit::TestCase

  def setup
    @board = Board.new
  end

  def test_initialize
    stone = Stone.new(@board, "K10", :black)
    assert @board.stone_at? "K10"
    group = @board.groups.first
    assert_equal 1, group.size
    stone = Stone.new(@board, "K9", :black)
    assert_equal 1, @board.groups.size
    assert_equal 2, group.size
    stone = Stone.new(@board, "K11", :white)
    assert_equal 2, @board.groups.size
    assert_equal 2, group.size
    assert_nothing_raised { Stone.new(@board, "T19", :black) }
    assert_raise(ArgumentError) { Stone.new(@board, "T20", :black) }
  end

  def test_neighbors
    stone = Stone.new(@board, "K10", :black)
    assert_equal 4, stone.neighbors.size
    assert stone.neighbors.include? "K9"
    assert stone.neighbors.include? "K11"
    assert stone.neighbors.include? "J10"
    assert stone.neighbors.include? "L10"
  end

  def test_neighbors_bottom_right_corner
    stone = Stone.new(@board, "A1", :black)
    assert_equal 2, stone.neighbors.size
    assert stone.neighbors.include? "A2"
    assert stone.neighbors.include? "B1"
  end

  def test_neighbors_top_left_corner
    stone = Stone.new(@board, "T19", :black)
    assert_equal 2, stone.neighbors.size
    assert stone.neighbors.include? "T18"
    assert stone.neighbors.include? "S19"
  end

  def test_neighbors_right_side
    stone = Stone.new(@board, "A10", :black)
    assert_equal 3, stone.neighbors.size
    assert stone.neighbors.include? "A11"
    assert stone.neighbors.include? "B10"
    assert stone.neighbors.include? "A9"
  end

  def test_neighbors_left_side
    stone = Stone.new(@board, "T10", :black)
    assert_equal 3, stone.neighbors.size
    assert stone.neighbors.include? "T11"
    assert stone.neighbors.include? "S10"
    assert stone.neighbors.include? "T9"
  end

  def test_stone_liberties
    stone = @board.add_stone("K10", :black)
    assert_equal 4, stone.liberties.size
    @board.add_stone("K9", :black)
    assert_equal 3, stone.liberties.size
  end

  def test_find_group_and_merge
    @board.add_stone("K9", :black)
    @board.add_stone("K11", :black)
    @board.add_stone("J10", :black)
    @board.add_stone("L10", :black)
    assert_equal 4, @board.groups.size
    @board.add_stone("K10", :black)
    assert_equal 1, @board.groups.size
  end

  def test_smaller_boards
    board = Board.new(nil, nil, 9, 0, "9x9")
    assert_nothing_raised { Stone.new(board, "J9", :black) }
    assert_raise(ArgumentError) { Stone.new(board, "Q16", :black)}

    board = Board.new(nil, nil, 9, 0, "13x13")
    assert_nothing_raised { Stone.new(board, "N13", :black) }
    assert_raise(ArgumentError) { Stone.new(board, "Q16", :black)}
  end

end
