require 'test/unit'
require 'gorb'

class TestGroup < Test::Unit::TestCase

  def test_color
    board = Board.new
    board.add_stone("K10")
    assert_equal :black, board.groups.first.color
  end

  def test_merge
    board = Board.new
    board.add_stone("A12", :white)
    board.add_stone("C12", :white)
    assert_equal 2, board.groups.size
    board.add_stone("A11", :white)
    board.add_stone("B11", :white)
    board.add_stone("C11", :white)
    assert_equal 1, board.groups.size
    board.add_stone("A10", :white)
    assert_equal 1, board.groups.size
    assert board.stone_at?("A10")
    board.add_stone("C10", :white)
    board.add_stone("D10", :white)
    assert_equal 1, board.groups.size
    assert board.stone_at?("A10")
  end

  def test_merge_m17
    diagram = <<-END
       A B C D E F G H J K L M N
    19 . . . . . . X O O O O O .
    18 . . . . X X X X O X X O .
    17 . . . . X X X O O X X O .
    16 . X X X O X O O X X X X O
    15 X X O O O X O O O X O O .
    14 O O . O . O X O X X O . .
    13 O O O O . O X X . X X O .
    END
    board = Board.new
    board.read(diagram)
    assert_equal 10, board.groups.size
    assert board.stone_at?("M17")
  end

  def test_merge_a10
    diagram = <<-END
       A B C D 
    19 . . . . 
    18 . . . . 
    17 . . . . 
    16 . X X X 
    15 X X O O 
    14 O O . O 
    13 O O O O 
    12 X O X O 
    11 X X X O 
    10 X O X X 
     9 . . . . 
    END
    board = Board.new
    board.read(diagram)
    assert_equal 4, board.groups.size
    assert board.stone_at?("A10")
  end

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