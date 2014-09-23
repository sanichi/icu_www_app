FactoryGirl.define do
  factory :game do
    black     "Orr,M"
    date      "1998.07.12"
    eco       "B34"
    event     "Largs Weekender"
    moves     <<-EOM
1.e4 c5 2.Nf3 Nc6 3.d4 cxd4 4.Nxd4 g6 5.Nc3 Bg7 6.Be3 Nf6 7.f3 O-O 8.Bc4 Qb6
9.Qd3 Ne5 10.Qe2 Qxb2 11.Kd2 Qb4 12.Bd3 Nc6 13.Rab1 Qa5 14.Nb3 Qxc3+ 15.Kxc3
Nxe4+ 16.Kc4 Nd6+ 17.Kd5 Nb4+ 18.Kc5 Bc3 19.Bd4 b6# 0-1
EOM
    pgn
    result    "0-1"
    round     "4"
    white     "Lee,C"
    black_elo 2420

    factory :game_with_annotations do
      annotator "Orr,M"
      moves     <<-EOA
1.e4 c5 2.Nf3 Nc6 3.d4 cxd4 4.Nxd4 g6 5.Nc3 Bg7 6.Be3 Nf6 7.f3 O-O 8.Bc4 Qb6
{ This was my first outing with this opening and White has fallen into a small trap. }
9.Qd3 $2 { A panic reaction. } ( { The obvious move } 9.Bb3
{ to protect b2 has what looks like a problem after } 9...Nxe4
{ but in fact White need not be too afraid of this continuation because of }
10.Nd5 Qa5+ 11.c3 Nc5 12.Nxc6 dxc6 13.Nxe7+ Kh8 14.Nxc8 Raxc8
{ with equality. } ) 9...Ne5 10.Qe2 Qxb2 11.Kd2 Qb4 12.Bd3 Nc6 13.Rab1 Qa5
14.Nb3 ( 14.Rb5 { would have been better. } ) 14...Qxc3+ $3 ( 14...Nxe4+
15.Bxe4 Bxc3+ 16.Kd1 Qxa2 { would also win but not as beautifully. I spent
a long time checking the queen sacrifice to make sure it was correct but my
hand was still shaking and my heart pounding when I played it. }
) 15.Kxc3 Nxe4+ 16.Kc4 Nd6+ 17.Kd5 ( { If } 17.Kc5
{ makes the game finish even quicker after } 17...b6+ 18.Kd5 Nb4# ) 17...Nb4+
18.Kc5 Bc3 $3 { The key move, trapping the White king in the middle of the board.
White can do nothing to stop the Black b-pawn delivering checkmate. }
19.Bd4 b6# 0-1
EOA
    end

    factory :game_with_fen do
      fen   "r1b2rk1/pp1pppbp/2n2np1/q7/4P3/1NNBBP2/P1PKQ1PP/1R5R b - - 0 1"
      moves <<-EOA
1... Qxc3+ $3 2. Kxc3 Nxe4+ 3. Kc4 Nd6+ 4. Kd5 (4. Kc5 b6+ 5. Kd5 Nb4#) 4...
Nb4+ 5. Kc5 Bc3 $1 {and mate with b6 cannot be stopped} 6. Bd4 b6# 0-1
EOA
    end
  end
end
