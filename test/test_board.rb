require 'test/unit'
require 'gorb'

class TestBoard < Test::Unit::TestCase

  def setup
    @board = Board.new
  end

  def test_simple_initialize
    # Check that the defaults are sane: no handicap and no placed stones.
    assert_equal 0, @board.handicap
    assert_equal 0, @board.groups.size
    assert_equal "Black", @board.black.to_str
    assert_equal "White", @board.white.to_str
    assert_equal "Black", @board.turn.to_str
    assert_equal 6.5, @board.komi
    assert_equal "19x19", @board.size
  end

  def test_handicap_and_players_read_only
    # Make sure that handicap and players are read-only.
    assert_raise(NoMethodError) { @board.handicap = 9 }
    assert_raise(NoMethodError) { @board.black = Player.new }
  end

  def test_add_stone
    stone = @board.add_stone("K10")
    assert_equal 1, @board.groups.size
    assert @board.groups.any? {|group| group.include? "K10"}
    assert_equal :black, stone.color
  end

  def test_add_second_stone
    # Test that the second stone has correct color and that a new Group was
    # made for it.
    @board.add_stone("K10")
    stone = @board.add_stone("K9")
    assert_equal :white, stone.color
    assert_equal 2, @board.groups.size
  end

  def test_capture
    # A simple single stone capture in corner.
    # | . . . .
    # | X . . .
    # | O . . .
    # | X O . .
    # ---------
    @board.add_stone("A1")
    @board.add_stone("A2")
    @board.add_stone("A3")
    @board.add_stone("B1")
    assert_equal 1, @board.white.captured

    # Capturing an entire group.
    # | . . . .
    # | X . . .
    # | O X . .
    # | O O X .
    # ---------
    @board.add_stone("B2")
    @board.add_stone("A1")
    @board.add_stone("C1")
    assert_equal 3, @board.black.captured
  end

  def test_remove_stone
    @board.add_stone("K10")
    assert_equal 1, @board.groups.size
    @board.remove_stone("K10")
    assert_equal 0, @board.groups.size
    assert_raise(ArgumentError) { @board.remove_stone("K10") }
  end

  def test_search
    assert_equal [], @board.search("K10")
    assert_equal [], @board.search(%w{K9 K10})
    @board.add_stone("K10")
    assert_equal "K10", @board.search("K10").first.to_s
    @board.add_stone("K9")
    assert_equal 2, @board.search(%w{K9 K10}).size
  end

  def test_stone_at?
    @board.add_stone("K10", :black)
    assert @board.stone_at? "K10"
  end

  def test_stones_at?
    @board.add_stone("K10", :black)
    @board.add_stone("K11", :black)
    assert @board.stones_at? %w{K10 K11}
  end

  def test_legal_occupied
    # Don't allow placing stones on occupied points.
    assert_equal true, @board.legal?("K10", :black)
    @board.add_stone("K10", :black)
    assert_equal false, @board.legal?("K10", :white)
    assert_equal false, @board.legal?("K10", :black)
    assert_raise(ArgumentError) { @board.add_stone("K10") }
  end

  def test_legal_suicide
    # Don't allow suicide...
    @board.add_stone("A2", :white)
    @board.add_stone("B2", :white)
    @board.add_stone("B1", :white)
    assert !@board.legal?("A1", :black)
  end

  def test_legal_kill
    # ...unless it kills.
    @board.add_stone("A3", :black)
    @board.add_stone("B3", :black)
    @board.add_stone("C3", :black)
    @board.add_stone("C2", :black)
    @board.add_stone("C1", :black)
    @board.add_stone("A2", :white)
    @board.add_stone("B2", :white)
    @board.add_stone("B1", :white)
    assert @board.legal?("A1", :black)
  end

  def test_legal_joining_own_stones
    # Make sure that joining your OWN stones together is still legal.
    @board.add_stone("K9", :black)
    @board.add_stone("K11", :black)
    @board.add_stone("J10", :black)
    @board.add_stone("L10", :black)
    assert @board.legal?("K10", :black)
    assert !@board.legal?("K10", :white)
  end

  def test_ko_enforcement
    # Contrived ko sequence.
    # | . . . .
    # | . . . .
    # | O X . .
    # | . O X .
    # ---------
    @board.add_stone("C1")
    @board.add_stone("B1")
    @board.add_stone("B2")
    @board.add_stone("A2")
    assert @board.legal?("A1", :black)
    stone = @board.add_stone("A1")

    # White can't answer directly back at B1 now.
    # | . . . .
    # | . . . .
    # | O X . .
    # | X . X .
    # ---------
    assert !@board.legal?("B1", :white)
    assert_raise(ArgumentError) {@board.add_stone("B1")}
    assert_equal 4, @board.groups.size

    # But after a round of moves has been played, B1 is legal again.
    # | . . . .
    # | O X . .
    # | O X . .
    # | . O X .
    # ---------
    @board.add_stone("A3")
    @board.add_stone("B3")
    assert @board.legal?("B1", :white)
    stone = @board.add_stone("B1")
    assert_equal 4, @board.groups.size
  end

  def test_turn
    # Turn should automatically flip flop after adding a stone.
    assert "Black", @board.turn.to_str
    @board.add_stone("K10")
    assert "White", @board.turn.to_str
    @board.add_stone("K9")
    assert "Black", @board.turn.to_str
  end

  def test_turn_manual
    # Turn should NOT advance if a stone is placed "manually", enforcing color.
    assert "Black", @board.turn.to_str
    @board.add_stone("K10", :black)
    assert "Black", @board.turn.to_str
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

  def test_invalid_handicaps
    assert_raise(ArgumentError) { Board.new(nil, nil, -1) }
    assert_raise(ArgumentError) { Board.new(nil, nil, 10) }
  end

  def test_read
    diagram = <<-END
    ---------------------
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    ---------------------
    END
    board = Board.new(nil, nil, 0, 0, "9x9")
    board.read(diagram)
    assert board.stone_at?("E1")
    assert board.stone_at?("F1")
    assert board.stone_at?("E2")
    assert board.stone_at?("F2")
    assert board.stone_at?("E3")
    assert board.stone_at?("F3")
    assert board.stone_at?("E4")
    assert board.stone_at?("F4")
    assert board.stone_at?("E5")
    assert board.stone_at?("F5")
    assert board.stone_at?("E6")
    assert board.stone_at?("F6")
    assert board.stone_at?("E7")
    assert board.stone_at?("F7")
    assert board.stone_at?("E8")
    assert board.stone_at?("F8")
    assert board.stone_at?("E9")
    assert board.stone_at?("F9")
  end

  def test_read_gnugo_output
    diagram = <<-END
       White (O) has captured 5 pieces
       Black (X) has captured 3 pieces

       A B C D E F G H J K L M N O P Q R S T        Last move: White S15
    19 . . . . . . X O O O O O . O X . . . . 19
    18 . . . . X X X X O X X O . O X X . . . 18
    17 . . . . X X X O O X X O . . O X X X X 17
    16 . X X X O X O O X X X X O O O X O X O 16
    15 X X O O O X O O O X O O . . . O O(O)O 15
    14 O O . O . O X O X X O . . . . . O O O 14
    13 O O O O . O X X . X X O . O . O . . O 13
    12 X O X O . O X . . X O . O X O O . O X 12
    11 X X X O O X O X . X O . O X X X O O X 11
    10 X O X X X X O X . X O O X . . X X X X 10
     9 . . . . . X O O X X O X X . . . . . .  9
     8 . . . . X X X O O X X . . . . . . . .  8
     7 . . . X O O O . O O X X . . . . X . .  7
     6 . . . X O . . . . . O O X X X . . . .  6
     5 . . . X O . . . . . . . O O O X X . X  5
     4 . . . X X O . . . O . . O . O O X X O  4
     3 . . . . X O . . . . . . . . . . O O O  3
     2 . . X . X O . . . . . . . . . . . . .  2
     1 . . . X O O . . . . . . . . . . . . .  1
       A B C D E F G H J K L M N O P Q R S T
    END
    @board.read(diagram)
    assert @board.white.captured == 5
    assert @board.black.captured == 3
    assert @board.stone_at?("G19")
    assert @board.stone_at?("H19")
    assert @board.stone_at?("J19")
    assert @board.stone_at?("K19")
    assert @board.stone_at?("L19")
    assert @board.stone_at?("M19")
    assert @board.stone_at?("O19")
    assert @board.stone_at?("P19")
    assert @board.stone_at?("E18")
    assert @board.stone_at?("F18")
    assert @board.stone_at?("G18")
    assert @board.stone_at?("H18")
    assert @board.stone_at?("J18")
    assert @board.stone_at?("K18")
    assert @board.stone_at?("L18")
    assert @board.stone_at?("M18")
    assert @board.stone_at?("O18")
    assert @board.stone_at?("P18")
    assert @board.stone_at?("Q18")
    assert @board.stone_at?("E17")
    assert @board.stone_at?("F17")
    assert @board.stone_at?("G17")
    assert @board.stone_at?("H17")
    assert @board.stone_at?("J17")
    assert @board.stone_at?("K17")
    assert @board.stone_at?("L17")
    assert @board.stone_at?("M17")
    assert @board.stone_at?("P17")
    assert @board.stone_at?("Q17")
    assert @board.stone_at?("R17")
    assert @board.stone_at?("S17")
    assert @board.stone_at?("T17")
    assert @board.stone_at?("B16")
    assert @board.stone_at?("C16")
    assert @board.stone_at?("D16")
    assert @board.stone_at?("E16")
    assert @board.stone_at?("F16")
    assert @board.stone_at?("G16")
    assert @board.stone_at?("H16")
    assert @board.stone_at?("J16")
    assert @board.stone_at?("K16")
    assert @board.stone_at?("L16")
    assert @board.stone_at?("M16")
    assert @board.stone_at?("N16")
    assert @board.stone_at?("O16")
    assert @board.stone_at?("P16")
    assert @board.stone_at?("Q16")
    assert @board.stone_at?("R16")
    assert @board.stone_at?("S16")
    assert @board.stone_at?("T16")
    assert @board.stone_at?("A15")
    assert @board.stone_at?("B15")
    assert @board.stone_at?("C15")
    assert @board.stone_at?("D15")
    assert @board.stone_at?("E15")
    assert @board.stone_at?("F15")
    assert @board.stone_at?("G15")
    assert @board.stone_at?("H15")
    assert @board.stone_at?("J15")
    assert @board.stone_at?("K15")
    assert @board.stone_at?("L15")
    assert @board.stone_at?("M15")
    assert @board.stone_at?("Q15")
    assert @board.stone_at?("R15")
    assert @board.stone_at?("S15")
    assert @board.stone_at?("T15")
    assert @board.stone_at?("A14")
    assert @board.stone_at?("B14")
    assert @board.stone_at?("D14")
    assert @board.stone_at?("F14")
    assert @board.stone_at?("G14")
    assert @board.stone_at?("H14")
    assert @board.stone_at?("J14")
    assert @board.stone_at?("K14")
    assert @board.stone_at?("L14")
    assert @board.stone_at?("R14")
    assert @board.stone_at?("S14")
    assert @board.stone_at?("T14")
    assert @board.stone_at?("A13")
    assert @board.stone_at?("B13")
    assert @board.stone_at?("C13")
    assert @board.stone_at?("D13")
    assert @board.stone_at?("F13")
    assert @board.stone_at?("G13")
    assert @board.stone_at?("H13")
    assert @board.stone_at?("K13")
    assert @board.stone_at?("L13")
    assert @board.stone_at?("M13")
    assert @board.stone_at?("O13")
    assert @board.stone_at?("Q13")
    assert @board.stone_at?("T13")
    assert @board.stone_at?("A12")
    assert @board.stone_at?("B12")
    assert @board.stone_at?("C12")
    assert @board.stone_at?("D12")
    assert @board.stone_at?("F12")
    assert @board.stone_at?("G12")
    assert @board.stone_at?("K12")
    assert @board.stone_at?("L12")
    assert @board.stone_at?("N12")
    assert @board.stone_at?("O12")
    assert @board.stone_at?("P12")
    assert @board.stone_at?("Q12")
    assert @board.stone_at?("S12")
    assert @board.stone_at?("T12")
    assert @board.stone_at?("A11")
    assert @board.stone_at?("B11")
    assert @board.stone_at?("C11")
    assert @board.stone_at?("D11")
    assert @board.stone_at?("E11")
    assert @board.stone_at?("F11")
    assert @board.stone_at?("G11")
    assert @board.stone_at?("H11")
    assert @board.stone_at?("K11")
    assert @board.stone_at?("L11")
    assert @board.stone_at?("N11")
    assert @board.stone_at?("O11")
    assert @board.stone_at?("P11")
    assert @board.stone_at?("Q11")
    assert @board.stone_at?("R11")
    assert @board.stone_at?("S11")
    assert @board.stone_at?("T11")
    assert @board.stone_at?("A10")
    assert @board.stone_at?("B10")
    assert @board.stone_at?("C10")
    assert @board.stone_at?("D10")
    assert @board.stone_at?("E10")
    assert @board.stone_at?("F10")
    assert @board.stone_at?("G10")
    assert @board.stone_at?("H10")
    assert @board.stone_at?("K10")
    assert @board.stone_at?("L10")
    assert @board.stone_at?("M10")
    assert @board.stone_at?("N10")
    assert @board.stone_at?("Q10")
    assert @board.stone_at?("R10")
    assert @board.stone_at?("S10")
    assert @board.stone_at?("T10")
    assert @board.stone_at?("F9")
    assert @board.stone_at?("G9")
    assert @board.stone_at?("H9")
    assert @board.stone_at?("J9")
    assert @board.stone_at?("K9")
    assert @board.stone_at?("L9")
    assert @board.stone_at?("M9")
    assert @board.stone_at?("N9")
    assert @board.stone_at?("E8")
    assert @board.stone_at?("F8")
    assert @board.stone_at?("G8")
    assert @board.stone_at?("H8")
    assert @board.stone_at?("J8")
    assert @board.stone_at?("K8")
    assert @board.stone_at?("L8")
    assert @board.stone_at?("D7")
    assert @board.stone_at?("E7")
    assert @board.stone_at?("F7")
    assert @board.stone_at?("G7")
    assert @board.stone_at?("J7")
    assert @board.stone_at?("K7")
    assert @board.stone_at?("L7")
    assert @board.stone_at?("M7")
    assert @board.stone_at?("R7")
    assert @board.stone_at?("D6")
    assert @board.stone_at?("E6")
    assert @board.stone_at?("L6")
    assert @board.stone_at?("M6")
    assert @board.stone_at?("N6")
    assert @board.stone_at?("O6")
    assert @board.stone_at?("P6")
    assert @board.stone_at?("D5")
    assert @board.stone_at?("E5")
    assert @board.stone_at?("N5")
    assert @board.stone_at?("O5")
    assert @board.stone_at?("P5")
    assert @board.stone_at?("Q5")
    assert @board.stone_at?("R5")
    assert @board.stone_at?("T5")
    assert @board.stone_at?("D4")
    assert @board.stone_at?("E4")
    assert @board.stone_at?("F4")
    assert @board.stone_at?("K4")
    assert @board.stone_at?("N4")
    assert @board.stone_at?("P4")
    assert @board.stone_at?("Q4")
    assert @board.stone_at?("R4")
    assert @board.stone_at?("S4")
    assert @board.stone_at?("T4")
    assert @board.stone_at?("E3")
    assert @board.stone_at?("F3")
    assert @board.stone_at?("R3")
    assert @board.stone_at?("S3")
    assert @board.stone_at?("T3")
    assert @board.stone_at?("C2")
    assert @board.stone_at?("E2")
    assert @board.stone_at?("F2")
    assert @board.stone_at?("D1")
    assert @board.stone_at?("E1")
    assert @board.stone_at?("F1")
  end

  def test_scoring
    # Easy, basic example.
    diagram = <<-END
    ---------------------
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    | . . . . X O . . . |
    ---------------------
    END
    board = Board.new(nil, nil, 0, 0, "9x9")
    board.read(diagram)
    scoring = board.scoring
    assert_equal 36, scoring[:black]
    assert_equal 27, scoring[:white]
  end

  def test_scoring_full
    # More complicated full board game.
    diagram = <<-END
       White (O) has captured 5 pieces
       Black (X) has captured 3 pieces

       A B C D E F G H J K L M N O P Q R S T        Last move: White S15
    19 . . . . . . X O O O O O . O X . . . . 19
    18 . . . . X X X X O X X O . O X X . . . 18
    17 . . . . X X X O O X X O . . O X X X X 17
    16 . X X X O X O O X X X X O O O X O X O 16
    15 X X O O O X O O O X O O . . . O O(O)O 15
    14 O O . O . O X O X X O . . . . . O O O 14
    13 O O O O . O X X . X X O . O . O . . O 13
    12 X O X O . O X . . X O . O X O O . O X 12
    11 X X X O O X O X . X O . O X X X O O X 11
    10 X O X X X X O X . X O O X . . X X X X 10
     9 . . . . . X O O X X O X X . . . . . .  9
     8 . . . . X X X O O X X . . . . . . . .  8
     7 . . . X O O O . O O X X . . . . X . .  7
     6 . . . X O . . . . . O O X X X . . . .  6
     5 . . . X O . . . . . . . O O O X X . X  5
     4 . . . X X O . . . O . . O . O O X X O  4
     3 . . . . X O . . . . . . . . . . O O O  3
     2 . . X . X O . . . . . . . . . . . . .  2
     1 . . . X O O . . . . . . . . . . . . .  1
       A B C D E F G H J K L M N O P Q R S T
    END
    @board.read(diagram)
    @board.mark_dead_group("B10")
    scoring = @board.scoring
    assert_equal 90, scoring[:black]
    assert_equal 89.5, scoring[:white]
  end

end
