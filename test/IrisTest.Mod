MODULE IrisTest;  (** IrisTest.Run: an Oberon picture stored as t.pic and opened again *)
IMPORT Files, Display, Pictures, out;

PROCEDURE Run*;
VAR P, Q: Pictures.Picture; F: Files.File; len: LONGINT; fails: INTEGER;
BEGIN
  fails := 0;
  NEW(P); Pictures.Create(P, 40, 30, 8);
  Pictures.ReplConst(P, 1, 0, 0, 40, 30, Display.replace); Pictures.ReplConst(P, 3, 10, 5, 20, 10, Display.replace);
  F := Files.New("t.pic"); Pictures.Store(P, F, 0, len); Files.Register(F);
  NEW(Q); Pictures.Open(Q, "t.pic", TRUE);
  IF (Q.width # 40) OR (Q.height # 30) THEN INC(fails); out.String("FAIL size"); out.Ln END;
  IF (Pictures.Get(Q, 15, 10) # 3) OR (Pictures.Get(Q, 2, 2) # 1) THEN INC(fails); out.String("FAIL colours"); out.Ln END;
  out.String("IrisTest: "); out.Int(fails, 0); out.String(" failed"); out.Ln
END Run;

END IrisTest.
