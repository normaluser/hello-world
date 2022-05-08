{**************************************************************************
Copyright (C) 2015-2018 Parallel Realities

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

***************************************************************************
converted from "C" to "Pascal" by Ulrich 2022
***************************************************************************
* Loadtiles: Eine for Schleife mit intToStr(i) zur Dateinamensbildung
* funktioniert irgendwie nicht... immer dieselbe Speicheradresse bei PChar?? ARRAY of PChar??
* noch nicht komplett fehlerbereinigt ?! NEW / Dispose kommt zu Null
***************************************************************************}

PROGRAM ppp02;

{$COPERATORS OFF} {$mode FPC} {$H+}
USES CRT, SDL2, SDL2_Image, SDL2_Mixer, Math, sysutils;

CONST SCREEN_WIDTH      = 1280;            { size of the grafic window }
      SCREEN_HEIGHT     = 720;             { size of the grafic window }
      MAX_Tiles         = 7;
      TILE_SIZE         = 64;
      MAP_WIDTH         = 40;
      MAP_HEIGHT        = 20;
      MAP_RENDER_WIDTH  = 20;
      MAP_RENDER_HEIGHT = 12;
      PLAYER_MOVE_SPEED = 12;
      MAX_NAME_LENGTH   = 32;
      MAX_FILENAME_LENGTH = 1024;
      MAX_KEYBOARD_KEYS = 350;
      MAX_SND_CHANNELS  = 16;

TYPE                                        { "T" short for "TYPE" }
     TDelegating = (Game);
     TDelegate   = RECORD
                     logic, draw : TDelegating;
                   end;
     PTextur     = ^TTexture;
     TTexture    = RECORD
                     name : PChar;
                     Texture : PSDL_Texture;
                     next : PTextur;
                   end;
     TApp        = RECORD
                     Window   : PSDL_Window;
                     Renderer : PSDL_Renderer;
                     keyboard : Array[0..MAX_KEYBOARD_KEYS] OF integer;
                     textureHead, textureTail : PTextur;
                     Delegate : TDelegate;
                   end;
     TStage      = RECORD
                     camera : TSDL_Point;
                     map : ARRAY[0..PRED(MAP_WIDTH),0..PRED(MAP_HEIGHT)] of integer;
                   end;

VAR app      : TApp;
    stage    : TStage;
    Event    : TSDL_EVENT;
    exitLoop : BOOLEAN;
    EMessage : PChar;
    gTicks   : UInt32;
    gRemainder : double;
    tiles    : ARRAY[1..MAX_Tiles] of PSDL_Texture;
    summ     : integer;

// *****************   UTIL   *****************

procedure errorMessage(Message : PChar);
begin
  SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR,'Error Box',Message,NIL);
  HALT(1);
end;

// ****************   CAMERA   ****************

procedure doCamera;
begin
  stage.camera.x := MIN(MAX(stage.camera.x, 0), (MAP_WIDTH * TILE_SIZE) - SCREEN_WIDTH);
  stage.camera.y := MIN(MAX(stage.camera.y, 0), (MAP_HEIGHT * TILE_SIZE) - SCREEN_HEIGHT);
end;

procedure doPlayer;
begin
  if (app.keyboard[SDL_SCANCODE_A] = 1) then
    stage.camera.x := stage.camera.x - PLAYER_MOVE_SPEED;

  if (app.keyboard[SDL_SCANCODE_D] = 1) then
    stage.camera.x := stage.camera.x + PLAYER_MOVE_SPEED;

  if (app.keyboard[SDL_SCANCODE_W] = 1) then
    stage.camera.y := stage.camera.y - PLAYER_MOVE_SPEED;

  if (app.keyboard[SDL_SCANCODE_S] = 1) then
    stage.camera.y := stage.camera.y + PLAYER_MOVE_SPEED;
end;

// *****************   DRAW   *****************

procedure blit(Texture : PSDL_Texture; x, y, center : integer);
VAR dest : TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  SDL_QueryTexture(Texture, NIL, NIL, @dest.w, @dest.h);

  if center <> 0 then
  begin
    dest.x := dest.w DIV 2;
    dest.y := dest.h DIV 2;
  end;

  SDL_RenderCopy(app.Renderer, Texture, NIL, @dest);
end;

procedure blitRect(Texture : PSDL_Texture; src : PSDL_Rect; x, y : integer); INLINE;
VAR dest : TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  dest.w := src^.w;
  dest.h := src^.h;
  SDL_RenderCopy(app.Renderer, Texture, src, @dest);
end;

// ****************   Texture   ***************

procedure addTextureToCache(LName : Pchar; LTexture : PSDL_Texture);
VAR cache : PTextur;
begin
  NEW(cache);
  INC(summ);
  app.textureTail^.next := cache;
  app.textureTail := cache;
  cache^.name := LName;
  cache^.Texture := LTexture;
  cache^.next := NIL;
end;

function getTexture(name : Pchar) : PSDL_Texture;
VAR tf : PTextur;
begin
  getTexture := NIL;
  tf := app.textureHead^.next;
  while (tf <> NIL) do
  begin
    if strcomp(tf^.name, name) = 0
      then getTexture := tf^.Texture;
    tf := tf^.next;
  end;
end;

function loadTexture(Pfad : Pchar) : PSDL_Texture;
VAR tg : PSDL_Texture;
begin
  tg := getTexture(Pfad);
  if tg = NIL then
  begin
    tg := IMG_LoadTexture(app.Renderer, Pfad);
    if tg = NIL then
      errorMessage(SDL_GetError());
    addTextureToCache(Pfad, tg);
  end;
  loadTexture := tg;
end;

{
procedure loadTiles;
VAR i : integer;
    filename, Nr, a, b : pchar;
begin
  a := 'gfx/tile';
  b := '.png';

  filename := StrAlloc(StrLen(a)+6);
  for i := 1 to MAX_TILES do
  begin
    Nr := Pchar(IntToStr(i));
    StrMove(filename,a,StrLen(a)+1);
    StrCat(filename,Nr);
    StrCat(filename,b);
    tiles[i] := loadTexture(filename);   // hat das mit dem Zeiger auf PChar zu tun?  IMMER die selbe Speicheradresse??
  end;
end;
}

procedure loadTiles;
begin
 //  Eine for Schleife mit intToStr(i) zur Dateinamensbildung funktioniert irgendwie nicht...
  tiles[1] := loadTexture('gfx/tile1.png');
  tiles[2] := loadTexture('gfx/tile2.png');
  tiles[3] := loadTexture('gfx/tile3.png');
  tiles[4] := loadTexture('gfx/tile4.png');
  tiles[5] := loadTexture('gfx/tile5.png');
  tiles[6] := loadTexture('gfx/tile6.png');
  tiles[7] := loadTexture('gfx/tile7.png');
end;

procedure initStageListenPointer;
begin
  NEW(app.textureHead);
  INC(summ);
  app.textureHead^.name := '';
  app.textureHead^.Texture := NIL;
  app.textureHead^.next := NIL;
  app.textureTail := app.textureHead;
end;

procedure prepareScene;
begin
  SDL_SetRenderDrawColor(app.Renderer, 0, 0, 0, 255);
  SDL_RenderClear(app.Renderer);
end;

procedure presentScene;
begin
  SDL_RenderPresent(app.Renderer);
end;
// *****************    MAP   *****************

procedure drawMap;
VAR a, b, x, y, n, x1, x2, y1, y2, mx, my : integer;
begin
  x1 := (stage.camera.x MOD TILE_SIZE) * (-1);
  if (x1 = 0) then a := 0
              else a := TILE_SIZE;
  x2 := x1 + a + MAP_RENDER_WIDTH * TILE_SIZE;

  y1 := (stage.camera.y MOD TILE_SIZE) * (-1);
  if (y1 = 0) then b := 0
              else b := TILE_SIZE;
  y2 := y1 + b + MAP_RENDER_HEIGHT * TILE_SIZE;

  mx := stage.camera.x DIV TILE_SIZE;
  my := stage.camera.y DIV TILE_SIZE;

  y := y1;
  while y <= y2 do
  begin
    x := x1;
    while x <= x2 do
    begin
      if ((mx >= 0) AND (my >= 0) AND (mx < MAP_WIDTH) AND (my < MAP_HEIGHT)) then
      begin
        n := stage.map[mx,my];
        if (n > 0) then
        begin
          blit(tiles[n], x, y, 0);
        end;
      end;
      INC(mx);
      INC(x, TILE_SIZE);
    end;
    mx := stage.camera.x DIV TILE_SIZE;
    INC(my);
    INC(y, TILE_SIZE);
  end;
end;

procedure loadMap(filename : String);
VAR i,x,y,le : integer;
    filein : text;
    line : string;
begin
  x:=0;
  assign (filein, filename);
  {$i-}; reset(filein); {$i+};
  if IOresult = 0 then
  begin
    for y := 0 to PRED(MAP_HEIGHT) do
    begin
      x:=0;
      readln(filein,line);
      line:=StringReplace(line, ' ','',[rfReplaceAll]);
      le:=length(line);

      for i:=1 to le do
      begin
        stage.map[x,y]:=ORD(line[i])-48;
        INC(x);
      end;
    end;
    close(filein);
  end;
end;

procedure initMap;
begin
  FillChar(stage.map, sizeof(stage.map), 0);
  loadTiles;
  loadMap('data/map01.dat');
end;

// *****************   Stage  *****************

procedure draw_Game;
begin
  SDL_SetRenderDrawColor(app.renderer, 128, 192, 255, 255);
  SDL_RenderFillRect(app.renderer, NIL);

  drawMap;
end;

procedure logic_Game;
begin
  app.delegate.logic := Game;
  doPlayer;
  doCamera;
end;

// ***************   INIT SDL   ***************

procedure initSDL;
VAR rendererFlags, windowFlags : integer;
begin
  rendererFlags := SDL_RENDERER_PRESENTVSYNC OR SDL_RENDERER_ACCELERATED;
  windowFlags := 0;
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
    errorMessage(SDL_GetError());

  app.Window := SDL_CreateWindow('Pete''s Pizza Party 2', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, windowFlags);
  if app.Window = NIL then
    errorMessage(SDL_GetError());

  if MIX_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024) < 0 then
    errorMessage(SDL_GetError());
  Mix_AllocateChannels(MAX_SND_CHANNELS);

  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'linear');
  app.Renderer := SDL_CreateRenderer(app.Window, -1, rendererFlags);
  if app.Renderer = NIL then
    errorMessage(SDL_GetError());

  IMG_INIT(IMG_INIT_PNG OR IMG_INIT_JPG);
  SDL_ShowCursor(0);
end;

procedure destroyTexture;
VAR tex : PTextur;
begin
  tex := app.textureHead^.next;
  while (tex <> NIL) do
  begin
    tex := app.textureHead^.next;
    app.textureHead^.next := tex^.next;
    DEC(summ); DISPOSE(tex);
    tex := tex^.next;
  end;
  DISPOSE(app.TextureHead);   DEC(Summ);
end;

procedure cleanUp;
begin
  destroyTexture;
  if ExitCode <> 0 then WriteLn('CleanUp complete!');
end;

procedure AtExit;
VAR i : byte;
begin
  for i := 1 to Max_Tiles do
    SDL_DestroyTexture (Tiles[i]);

  if ExitCode <> 0 then cleanUp;
  Mix_CloseAudio;
  SDL_DestroyRenderer(app.Renderer);
  SDL_DestroyWindow (app.Window);
  MIX_Quit;   { Quits the Music / Sound }
  IMG_Quit;   { Quits the SDL_Image }
  SDL_Quit;   { Quits the SDL }
  if Exitcode <> 0 then WriteLn(SDL_GetError());
  SDL_ShowCursor(1);
end;

// *****************   Input  *****************

procedure doInput;
begin
  while SDL_PollEvent(@Event) = 1 do
  begin
    CASE Event.Type_ of

      SDL_QUITEV:          exitLoop := TRUE;        { close Window }
      SDL_MOUSEBUTTONDOWN: exitLoop := TRUE;        { if Mousebutton pressed }

      SDL_KEYDOWN: begin
                     if ((Event.key._repeat = 0) AND (Event.key.keysym.scancode < MAX_KEYBOARD_KEYS)) then
                       app.keyboard[Event.key.keysym.scancode] := 1;
                     if (app.keyboard[SDL_ScanCode_ESCAPE]) = 1 then exitLoop := TRUE;
                   end;   { SDL_Keydown }

      SDL_KEYUP:   begin
                     if ((Event.key._repeat = 0) AND (Event.key.keysym.scancode < MAX_KEYBOARD_KEYS)) then
                       app.keyboard[Event.key.keysym.scancode] := 0;
                   end;   { SDL_Keyup }
    end;  { CASE Event }
  end;    { SDL_PollEvent }
end;

// *************   DELEGATE LOGIC   ***********

procedure delegate_logic(Wahl : TDelegating);
begin
  CASE Wahl of
  Game : begin
           logic_Game;
           draw_Game;
         end;
  end;
end;

// *************   CAPFRAMERATE   *************

procedure CapFrameRate(VAR remainder : double; VAR Ticks : UInt32); INLINE;
VAR wait, FrameTime : longint;
begin
  wait := 16 + TRUNC(remainder);
  remainder := remainder - TRUNC(remainder);
  frameTime := SDL_GetTicks - Ticks;
  DEC(wait, frameTime);
  if (wait < 1) then wait := 1;
  SDL_Delay(wait);
  remainder := remainder + 0.667;
  Ticks := SDL_GetTicks;
end;

// *****************   MAIN   *****************

begin
  CLRSCR;
  summ := 0;
  InitSDL;
  InitStageListenPointer;
  InitMap;
  AddExitProc(@AtExit);
  exitLoop := FALSE;

  while exitLoop = FALSE do
  begin
    prepareScene;
    doInput;
    delegate_logic(app.delegate.logic);
    presentScene;
    CapFrameRate(gRemainder, gTicks);
  end;

  cleanUp;
  AtExit;
  writeln; writeln(summ);
end.
