MODULE Iris;  (** Iris, a picture viewer for the desktop of polpo *)

(* Iris.Open name   opens the picture file name in a viewer: Oberon pictures (.pic) and the
                    formats of the PictureConverters section of Oberon.Text (GIF, JPEG, BMP,
                    TGA, PCX, ICO, IFF, XPM, ... once their converter modules are installed)
   Iris.Open ^      the selected name
   Iris.Info        the name and size of the picture of the viewer (in its menu)

   The picture is shown from its top left corner; drag it with any mouse button to see the
   rest. System.Copy makes a second viewer of the same picture. *)

IMPORT Objects, Display, Input, Texts, Oberon, MenuViewers, TextFrames, Pictures, Out;

CONST
  menu = "System.Close System.Copy System.Grow Iris.Info";
  bg = Display.FG;  (* black around the picture *)

TYPE
  Frame = POINTER TO FrameDesc;
  FrameDesc = RECORD (Display.FrameDesc)
    pict: Pictures.Picture;
    name: ARRAY 128 OF CHAR;
    x0, y0: INTEGER  (* the picture pixel at the top left corner of the frame, counted from the
                        left and from the top *)
  END;

(* keep the offsets inside the picture, or at 0 when it fits *)
PROCEDURE Clamp(F: Frame);
BEGIN
  IF F.x0 > F.pict.width - F.W THEN F.x0 := F.pict.width - F.W END;
  IF F.y0 > F.pict.height - F.H THEN F.y0 := F.pict.height - F.H END;
  IF F.x0 < 0 THEN F.x0 := 0 END;
  IF F.y0 < 0 THEN F.y0 := 0 END
END Clamp;

PROCEDURE Restore(F: Frame);
VAR px, py: INTEGER;
BEGIN
  IF (F.W <= 0) OR (F.H <= 0) THEN RETURN END;
  Clamp(F);
  Display.SetClip(F.X, F.Y, F.W, F.H);
  Display.ReplConst(bg, F.X, F.Y, F.W, F.H, Display.replace);
  px := F.X - F.x0; py := F.Y + F.H - F.pict.height + F.y0;  (* the bottom left corner of the picture *)
  Pictures.DisplayBlock(F.pict, 0, 0, F.pict.width, F.pict.height, px, py, Display.replace);
  Display.ResetClip
END Restore;

(* drag the picture while a mouse button is pressed *)
PROCEDURE Pan(F: Frame; X, Y: INTEGER);
VAR keys: SET; x, y: INTEGER;
BEGIN
  Input.Mouse(keys, x, y);
  WHILE keys # {} DO
    IF (x # X) OR (y # Y) THEN
      F.x0 := F.x0 - (x - X); F.y0 := F.y0 + (y - Y); X := x; Y := y;
      Oberon.FadeCursor(Oberon.Mouse); Restore(F)
    END;
    Oberon.DrawCursor(Oberon.Mouse, Oberon.Arrow, x, y);
    Input.Mouse(keys, x, y)
  END
END Pan;

PROCEDURE Handle*(F: Objects.Object; VAR M: Objects.ObjMsg);
VAR F1: Frame;
BEGIN
  WITH F: Frame DO
    IF M IS Oberon.InputMsg THEN
      WITH M: Oberon.InputMsg DO
        IF M.id = Oberon.track THEN
          IF M.keys # {} THEN Pan(F, M.X, M.Y) END;
          Oberon.DrawCursor(Oberon.Mouse, Oberon.Arrow, M.X, M.Y);
          M.res := 0
        END
      END
    ELSIF M IS Display.ModifyMsg THEN
      WITH M: Display.ModifyMsg DO
        IF M.F = F THEN F.X := M.X; F.Y := M.Y; F.W := M.W; F.H := M.H; Restore(F) END
      END
    ELSIF M IS Display.DisplayMsg THEN
      WITH M: Display.DisplayMsg DO
        IF (M.F = F) OR (M.F = NIL) THEN Restore(F) END
      END
    ELSIF M IS Display.LocateMsg THEN
      WITH M: Display.LocateMsg DO
        IF (F.X <= M.X) & (M.X < F.X + F.W) & (F.Y <= M.Y) & (M.Y < F.Y + F.H) THEN M.loc := F; M.res := 0 END
      END
    ELSIF M IS Objects.CopyMsg THEN
      WITH M: Objects.CopyMsg DO NEW(F1); F1^ := F^; M.obj := F1 END
    END
  END
END Handle;

(* the name after the command, or the selected one for ^ *)
PROCEDURE GetName(VAR name: ARRAY OF CHAR): BOOLEAN;
VAR S: Texts.Scanner; text: Texts.Text; beg, end, time: LONGINT;
BEGIN
  Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
  IF (S.class = Texts.Char) & (S.c = "^") THEN
    Oberon.GetSelection(text, beg, end, time);
    IF time < 0 THEN RETURN FALSE END;
    Texts.OpenScanner(S, text, beg); Texts.Scan(S)
  END;
  IF (S.class = Texts.Name) OR (S.class = Texts.String) THEN COPY(S.s, name); RETURN TRUE END;
  RETURN FALSE
END GetName;

PROCEDURE Open*;
VAR name: ARRAY 128 OF CHAR; P: Pictures.Picture; F: Frame; mf: TextFrames.Frame; V: MenuViewers.Viewer; X, Y: INTEGER;
BEGIN
  IF ~GetName(name) THEN Out.String("usage: Iris.Open name"); Out.Ln; RETURN END;
  NEW(P); Pictures.Open(P, name, TRUE);
  IF (P.width <= 0) OR (P.height <= 0) THEN
    Out.String("Iris: cannot open "); Out.String(name);
    Out.String(" (not a picture, or no converter in PictureConverters of Oberon.Text)"); Out.Ln;
    RETURN
  END;
  NEW(F); F.handle := Handle; F.pict := P; COPY(name, F.name); F.x0 := 0; F.y0 := 0;
  IF Oberon.Par.vwr # NIL THEN X := Oberon.Par.vwr.X ELSE X := Oberon.Pointer.X END;  (* from a viewer, or not (InitCommands) *)
  Oberon.AllocateUserViewer(X, X, Y);
  mf := TextFrames.NewMenu(name, menu);
  V := MenuViewers.New(mf, F, TextFrames.menuH, X, Y)
END Open;

(** in the menu of an Iris viewer: its picture's name, size and depth *)
PROCEDURE Info*;
VAR F: Display.Frame;
BEGIN
  IF (Oberon.Par.vwr # NIL) & (Oberon.Par.vwr.dsc # NIL) THEN
    F := Oberon.Par.vwr.dsc.next;
    IF (F # NIL) & (F IS Frame) THEN
      WITH F: Frame DO
        Out.String(F.name); Out.String(": "); Out.Int(F.pict.width, 0); Out.String(" x "); Out.Int(F.pict.height, 0);
        Out.String(", "); Out.Int(F.pict.depth, 0); Out.String(" bits"); Out.Ln
      END
    END
  END
END Info;

END Iris.
