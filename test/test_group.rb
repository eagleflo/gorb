require 'test/unit'
require 'gorb'

class TestGroup < Test::Unit::TestCase

  def test_include
    board = Board.new
    stone = board.add_stone("K10")
    assert stone.group.include?("K10")
    assert !stone.group.include?("K9")
    board.add_stone("K9", :black)
    assert stone.group.include?("K9")
    board.add_stone("K11", :white)
    assert !stone.group.include?("K11")
  end

  def test_group_liberties
    # Normal liberties.
    board = Board.new
    stone = board.add_stone("K10", :black)
    board.add_stone("K9", :black)
    assert_equal 6, stone.group.liberties
    board.add_stone("K8", :white)
    assert_equal 5, stone.group.liberties

    # Side liberties.
    stone = board.add_stone("A10", :black)
    assert_equal 3, stone.group.liberties

    # Corner liberties.
    stone = board.add_stone("A1", :black)
    assert_equal 2, stone.group.liberties
    board.add_stone("A2", :white)
    assert_equal 1, stone.group.liberties
  end

  def test_group_liberties!
    board = Board.new
    stone = board.add_stone("K10", :black)
    board.add_stone("K9", :white)
    board.add_stone("K11", :white)
    board.add_stone("J10", :white)
    board.add_stone("L10", :white)
    # Board#add_stone implicitly calls liberties!.
    assert_equal 4, board.groups.size
  end

end