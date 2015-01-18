use gfx common util params

type sprite{Bank Name height/1 xy/[0 0]
            frames/0 faces/1 anims/[`|` [still 0]]
            auto_class/0}
  bank/Bank
  name/Name
  height/Height
  frames/Frames
  xy/Xy
  anims/Anims.tail{}{[?0 ?tail]}.table
  faces/Faces
  auto_class/Auto_class

init_frames S G =
| S.frames <= case S.frames
  [`*` W H] | map I (G.w*G.h)/(W*H): G.cut{I%(G.w/W)*W I/(G.w/W)*H W H}
  [@Fs] | map [X Y W H @Disp] Fs
          | R = @cut X Y W H G
          | R.hotspot <= Disp^($_ []=> [0 0])
          | R
  Else | [G]
| for F S.frames: !F.hotspot + S.xy

main.load_sprites =
| Folder = "[$data]/sprites/"
| $sprites <= @table: @join: map BankName Folder.folders
  | RootParams = t
  | ParamsFile = "[Folder][BankName].txt"
  | when ParamsFile.exists: load_params RootParams ParamsFile
  | BankFolder = "[Folder][BankName]/"
  | map Name BankFolder.urls.keep{is.[@_ png]}{?1}
    | Params = RootParams.deep_copy
    | ParamsFile = "[BankFolder][Name].txt"
    | when ParamsFile.exists: load_params Params ParamsFile
    | S = sprite BankName Name @Params.list.join
    | init_frames S gfx."[BankFolder][Name].png"
    //| when Name >< wizard: bad Params.anims
    | "[BankName]_[Name]",S

export sprite
