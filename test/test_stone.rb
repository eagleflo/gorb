require 'test/unit'
require 'gorb'

class TestStone < Test::Unit::TestCase

  def test_initialize
    board = Board.new
    stone = Stone.new(board, "K10", :black)
    assert board.stone_at? "K10"
    group = board.groups.first
    assert_equal 1, group.size
    stone = Stone.new(board, "K9", :black)
    assert_equal 1, board.groups.size
    assert_equal 2, group.size
    stone = Stone.new(board, "K11", :white)
    assert_equal 2, board.groups.size
    assert_equal 2, group.size
  end

  def test_neighbors
    board = Board.new
    stone = Stone.new(board, "K10", :black)
    assert_equal 4, stone.neighbors.size
    assert stone.neighbors.include? "K9"
    assert stone.neighbors.include? "K11"
    assert stone.neighbors.include? "J10"
    assert stone.neighbors.include? "L10"

    stone = Stone.new(board, "A1", :black)
    assert_equal 2, stone.neighbors.size
    assert stone.neighbors.include? "A2"
    assert stone.neighbors.include? "B1"
  end

  def test_stone_liberties
    board = Board.new
    stone = board.add_stone("K10", :black)
    assert_equal 4, stone.liberties.size
    board.add_stone("K9", :black)
    assert_equal 3, stone.liberties.size
  end

  def test_find_group_and_merge
    board = Board.new
    board.add_stone("K9", :black)
    board.add_stone("K11", :black)
    board.add_stone("J10", :black)
    board.add_stone("L10", :black)
    assert_equal 4, board.groups.size
    board.add_stone("K10", :black)
    assert_equal 1, board.groups.size
  end

end
