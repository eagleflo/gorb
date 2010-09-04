require 'test/unit'
require 'gorb'

class TestBoard < Test::Unit::TestCase

  def test_simple_initialize
    # Check that the defaults are sane: no handicap and no placed stones.
    board = Board.new
    assert_equal 0, board.handicap
    assert_equal 0, board.groups.size
    assert_equal "Black", board.black.to_str
    assert_equal "White", board.white.to_str
    assert_equal "Black", board.turn.to_str
    assert_equal 6.5, board.komi
    assert_equal "19x19", board.size

    # Make sure that handicap and players are read-only.
    assert_raise(NoMethodError) { board.handicap = 9 }
    assert_raise(NoMethodError) { board.black = Player.new }
  end

  def test_add_stone
    board = Board.new
    assert_equal 0, board.groups.size
    assert "Black", board.turn.to_str
    stone = board.add_stone("K10")
    assert_equal 1, board.groups.size
    assert board.groups.any? {|group| group.include? "K10"}
    assert_equal :black, stone.color
    assert_raise(ArgumentError) { board.add_stone("K10") }
    assert "white", board.turn.to_str
    stone = board.add_stone("K9")
    assert_equal :white, stone.color
    assert_equal 2, board.groups.size
  end

  def test_remove_stone
    board = Board.new
    board.add_stone("K10")
    assert_equal 1, board.groups.size
    board.remove_stone("K10")
    assert_equal 0, board.groups.size
    assert_raise(ArgumentError) { board.remove_stone("K10") }
  end

  def test_search
    board = Board.new
    assert_equal [], board.search("K10")
    assert_equal [], board.search(%w{K9 K10})
    board.add_stone("K10")
    assert_equal "K10", board.search("K10").first.to_s
    board.add_stone("K9")
    assert_equal 2, board.search(%w{K9 K10}).size
  end

  def test_stone_at?
    board = Board.new
    board.add_stone("K10", :black)
    board.add_stone("K11", :black)
    assert board.stone_at? "K10"
    assert board.stones_at? %w{K10 K11}
  end

  def test_legal?
    # Don't allow placing stones on occupied points.
    board = Board.new
    assert_equal true, board.legal?("K10", :black)
    board.add_stone("K10", :black)
    assert_equal false, board.legal?("K10", :white)
    assert_equal false, board.legal?("K10", :black)

    # Don't allow suicide...
    board = Board.new
    board.add_stone("A2", :white)
    board.add_stone("B2", :white)
    board.add_stone("B1", :white)
    assert !board.legal?("A1", :black)

    # ...unless it kills.
    board = Board.new
    board.add_stone("A3", :black)
    board.add_stone("B3", :black)
    board.add_stone("C3", :black)
    board.add_stone("C2", :black)
    board.add_stone("C1", :black)
    board.add_stone("A2", :white)
    board.add_stone("B2", :white)
    board.add_stone("B1", :white)
    assert board.legal?("A1", :black)

    # Make sure that joining your OWN stones together is still legal.
    board = Board.new
    board.add_stone("K9", :black)
    board.add_stone("K11", :black)
    board.add_stone("J10", :black)
    board.add_stone("L10", :black)
    assert board.legal?("K10", :black)
    assert !board.legal?("K10", :white)
  end

  def test_ko_enforcement
    board = Board.new
    board.add_stone("C1")
    board.add_stone("B1")
    board.add_stone("B2")
    board.add_stone("A2")
    assert board.legal?("A1", :black)
    stone = board.add_stone("A1")
    assert !board.legal?("B1", :white)
    assert_raise(ArgumentError) {board.add_stone("B1")}
    assert_equal 4, board.groups.size
    board.add_stone("A3")
    board.add_stone("B3")
    assert board.legal?("B1", :white)
    stone = board.add_stone("B1")
    assert_equal 4, board.groups.size
  end

  def test_turns
    board = Board.new
    assert "Black", board.turn.to_str
    board.add_stone("K10")
    assert "White", board.turn.to_str
  end

  def test_handicapped_initialize
    # Test each valid handicap.
    board = Board.new(nil, nil, 0)
    assert_equal 0, board.handicap
    assert_equal 0, board.groups.size
    assert_equal 6.5, board.komi
    assert_equal "Black", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 1)
    assert_equal 1, board.handicap
    assert_equal 0, board.groups.size
    assert_equal 0.5, board.komi
    assert_equal "Black", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 2)
    assert_equal 2, board.handicap
    assert_equal 2, board.groups.size
    assert board.stones_at?(%w{D4 Q16})
    assert_equal 0.5, board.komi
    assert_equal "White", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 3)
    assert_equal 3, board.handicap
    assert_equal 3, board.groups.size
    assert board.stones_at?(%w{D4 Q4 Q16})
    assert_equal 0.5, board.komi
    assert_equal "White", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 4)
    assert_equal 4, board.handicap
    assert_equal 4, board.groups.size
    assert board.stones_at?(%w{D4 D16 Q4 Q16})
    assert_equal 0.5, board.komi
    assert_equal "White", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 5)
    assert_equal 5, board.handicap
    assert_equal 5, board.groups.size
    assert board.stones_at?(%w{D4 D16 K10 Q4 Q16})
    assert_equal 0.5, board.komi
    assert_equal "White", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 6)
    assert_equal 6, board.handicap
    assert_equal 6, board.groups.size
    assert board.stones_at?(%w{D4 D10 D16 Q4 Q10 Q16})
    assert !board.stone_at?("K10")
    assert_equal 0.5, board.komi
    assert_equal "White", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 7)
    assert_equal 7, board.handicap
    assert_equal 7, board.groups.size
    assert board.stones_at?(%w{D4 D10 D16 K10 Q4 Q10 Q16})
    assert_equal 0.5, board.komi
    assert_equal "White", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 8)
    assert_equal 8, board.handicap
    assert_equal 8, board.groups.size
    assert board.stones_at?(%w{D4 D10 D16 Q4 Q10 Q16 K4 K16})
    assert !board.stone_at?("K10")
    assert_equal 0.5, board.komi
    assert_equal "White", board.turn.to_str
    assert_equal "19x19", board.size

    board = Board.new(nil, nil, 9)
    assert_equal 9, board.handicap
    assert_equal 9, board.groups.size
    assert board.stones_at?(%w{D16 K16 Q16 D10 K10 Q10 D4 K4 Q4})
    assert_equal 0.5, board.komi
    assert_equal "White", board.turn.to_str
    assert_equal "19x19", board.size

    # Test invalid handicaps.
    assert_raise(ArgumentError) { Board.new(nil, nil, -1) }
    assert_raise(ArgumentError) { Board.new(nil, nil, 10) }
  end

  def test_9x9_and_handicaps
     board = Board.new(nil, nil, 0, 6.5, "9x9")
     assert_equal 0, board.handicap
     assert_equal 0, board.groups.size
     assert_equal 6.5, board.komi
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 1, 0, "9x9")
     assert_equal 1, board.handicap
     assert_equal 0, board.groups.size
     assert_equal 0.5, board.komi
     assert_equal "Black", board.turn.to_str
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 2, 0, "9x9")
     assert_equal 2, board.handicap
     assert_equal 2, board.groups.size
     assert board.stones_at?(%w{G7 C3})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 3, 0, "9x9")
     assert_equal 3, board.handicap
     assert_equal 3, board.groups.size
     assert board.stones_at?(%w{G7 C3 G3})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 4, 0, "9x9")
     assert_equal 4, board.handicap
     assert_equal 4, board.groups.size
     assert board.stones_at?(%w{G7 C3 G3 C7})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 5, 0, "9x9")
     assert_equal 5, board.handicap
     assert_equal 5, board.groups.size
     assert board.stones_at?(%w{G7 C3 G3 C7 E5})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 6, 0, "9x9")
     assert_equal 6, board.handicap
     assert_equal 6, board.groups.size
     assert board.stones_at?(%w{G7 C3 G3 C7 C5 G5})
     assert !board.stone_at?("E5")
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 7, 0, "9x9")
     assert_equal 7, board.handicap
     assert_equal 7, board.groups.size
     assert board.stones_at?(%w{G7 C3 G3 C7 E5 C5 G5})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 8, 0, "9x9")
     assert_equal 8, board.handicap
     assert_equal 8, board.groups.size
     assert board.stones_at?(%w{G7 C3 G3 C7 C5 G5 E7 E3})
     assert !board.stone_at?("E5")
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "9x9", board.size

     board = Board.new(nil, nil, 9, 0, "9x9")
     assert_equal 9, board.handicap
     assert_equal 9, board.groups.size
     assert board.stones_at?(%w{G7 C3 G3 C7 E5 C5 G5 E7 E3})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "9x9", board.size
  end

  def test_13x13_and_handicaps
     board = Board.new(nil, nil, 0, 6.5, "13x13")
     assert_equal 0, board.handicap
     assert_equal 0, board.groups.size
     assert_equal 6.5, board.komi
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 1, 0, "13x13")
     assert_equal 1, board.handicap
     assert_equal 0, board.groups.size
     assert_equal 0.5, board.komi
     assert_equal "Black", board.turn.to_str
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 2, 0, "13x13")
     assert_equal 2, board.handicap
     assert_equal 2, board.groups.size
     assert board.stones_at?(%w{K10 D4})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 3, 0, "13x13")
     assert_equal 3, board.handicap
     assert_equal 3, board.groups.size
     assert board.stones_at?(%w{K10 D4 K4})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 4, 0, "13x13")
     assert_equal 4, board.handicap
     assert_equal 4, board.groups.size
     assert board.stones_at?(%w{K10 D4 K4 D10})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 5, 0, "13x13")
     assert_equal 5, board.handicap
     assert_equal 5, board.groups.size
     assert board.stones_at?(%w{K10 D4 K4 D10 G7})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 6, 0, "13x13")
     assert_equal 6, board.handicap
     assert_equal 6, board.groups.size
     assert board.stones_at?(%w{K10 D4 K4 D10 D7 K7})
     assert !board.stone_at?("G7")
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 7, 0, "13x13")
     assert_equal 7, board.handicap
     assert_equal 7, board.groups.size
     assert board.stones_at?(%w{K10 D4 K4 D10 G7 D7 K7})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 8, 0, "13x13")
     assert_equal 8, board.handicap
     assert_equal 8, board.groups.size
     assert board.stones_at?(%w{K10 D4 K4 D10 D7 K7 G10 G4})
     assert !board.stone_at?("G7")
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "13x13", board.size

     board = Board.new(nil, nil, 9, 0, "13x13")
     assert_equal 9, board.handicap
     assert_equal 9, board.groups.size
     assert board.stones_at?(%w{K10 D4 K4 D10 G7 D7 K7 G10 G4})
     assert_equal 0.5, board.komi
     assert_equal "White", board.turn.to_str
     assert_equal "13x13", board.size
  end

end
