program DelphiCraft;

{
   Delphi Tokyo conversion of Craft by Michael Fogleman
   https://www.michaelfogleman.com/projects/craft/

   (c)2017-2018 by Paul TOTH
   http://www.execute.fr
}

{$R *.res}

// https://github.com/neslib/DelphiGlfw

uses
  Neslib.glfw3 in '..\deps\Neslib.glfw3.pas',
  Execute.CrossGL in '..\lib\Execute.CrossGL.pas',
  Execute.SysUtils in '..\lib\Execute.SysUtils.pas',
  Execute.Inflate in '..\lib\Execute.Inflate.pas',
  Execute.PNGLoader in '..\lib\Execute.PNGLoader.pas',
  Execute.Textures in '..\lib\Execute.Textures.pas',
  Execute.SQLite3 in '..\lib\Execute.SQLite3.pas',
  MarcusGeelnard.TinyCThread in 'MarcusGeelnard.TinyCThread.pas',
  CaseyDuncan.noise in 'CaseyDuncan.noise.pas',
  Craft.Main in 'Craft.Main.pas',
  Craft.Util in 'Craft.Util.pas',
  Craft.Cube in 'Craft.Cube.pas',
  Craft.Matrix in 'Craft.Matrix.pas',
  Craft.Config in 'Craft.Config.pas',
  Craft.Map in 'Craft.Map.pas',
  Craft.Sign in 'Craft.Sign.pas',
  Craft.db in 'Craft.db.pas',
  Craft.Client in 'Craft.Client.pas',
  Craft.Item in 'Craft.Item.pas',
  Craft.Ring in 'Craft.Ring.pas',
  Craft.Render in 'Craft.Render.pas',
  Craft.Chunk in 'Craft.Chunk.pas',
  Craft.Player in 'Craft.Player.pas',
  Craft.Auth in 'Craft.Auth.pas';

begin // main
  main();
end.
