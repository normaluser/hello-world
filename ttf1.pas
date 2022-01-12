{ Copyright (C) 2021 Parallel Realities }

PROGRAM ttf;

{$COPERATORS OFF}
USES CRT, SDL2, {SDL2_image,} SDL2_ttf;

CONST SCREEN_WIDTH        = 1280;      { size of the grafic window }
      SCREEN_HEIGHT       = 720;       { size of the grafic window }
      MAX_Filename_LENGTH = 256;
      FONT_SIZE           = 48;

TYPE                                   { "T" short for "TYPE" }
     TApp        = RECORD
                     Window   : PSDL_Window;
                     Renderer : PSDL_Renderer;
                   end;

VAR app          : TApp;
    ttfFont      : PTTF_Font;
    helloWorld   : PSDL_Texture;
    gTicks       : UInt32;
    gRemainder   : Double;
    Event        : PSDL_EVENT;
    exitLoop     : BOOLEAN;
    textAngle    : Integer;
    surface1     : PSDL_Surface;

// *****************   UTIL   *****************

procedure errorMessage(Message : PChar);
begin
  SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR,'Error Box',Message,NIL);
  HALT(1);
end;

// *****************   DRAW   *****************

procedure blit(Texture : PSDL_Texture; x, y, center : Integer);
VAR dest : TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  SDL_QueryTexture(Texture, NIL, NIL, @dest.w, @dest.h);
  if (center <> 0) then
  begin
    dest.x := dest.x - (dest.w DIV 2);
    dest.y := dest.y - (dest.h DIV 2);
  end;
  SDL_RenderCopy(app.Renderer, Texture, NIL, @dest);
end;

procedure blitScaled(Texture : PSDL_Texture; x, y, w, h : Integer);
VAR dest : TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  dest.w := w;
  dest.h := h;
  SDL_RenderCopy(app.Renderer, Texture, NIL, @dest);
end;

procedure blitRotated(Texture : PSDL_Texture; x, y, angle : Integer);
VAR dest : TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  SDL_QueryTexture(Texture, NIL, NIL, @dest.w, @dest.h);

  dest.x := dest.x - (dest.w DIV 2);
  dest.y := dest.y - (dest.h DIV 2);
  SDL_RenderCopyEx(app.Renderer, Texture, NIL, @dest, angle, NIL, SDL_FLIP_NONE);
end;

procedure prepareScene;
begin
  //SDL_SetRenderDrawColor(app.Renderer, 0, 0, 0, 255);
  SDL_SetRenderDrawColor(app.Renderer, 6, 96, 96, 255);
  SDL_RenderClear(app.Renderer);
end;

procedure presentScene;
begin
  SDL_RenderPresent(app.Renderer);
end;

procedure initFonts;
var err : PChar;
begin
  ttfFont := TTF_OpenFont('font/EnterCommand.ttf', FONT_SIZE);
  if ttfFont = NIL then errorMessage(TTF_GetError());
end;

function toTexture(surface : PSDL_Surface; destroySurface : Byte) : PSDL_Texture;
begin
  toTexture := SDL_CreateTextureFromSurface(app.Renderer, surface);
  if (destroySurface <> 0) then
    SDL_FreeSurface(surface);
end;

function getTextTexture(text : PChar) : PSDL_Texture;
var white : TSDL_Color;
begin
  white.g := 255; white.b := 255; white.r := 255; white.a := 255;
  surface1 := TTF_RenderUTF8_Blended(ttfFont, text, white);

  //convert SDL_Surface to SDL_Texture
  getTextTexture := toTexture(surface1, 1);
end;

// ***************   INIT SDL   ***************

procedure initSDL;
VAR rendererFlags, windowFlags : Integer;
begin
  rendererFlags := SDL_RENDERER_PRESENTVSYNC OR SDL_RENDERER_ACCELERATED;
  windowFlags := 0;

  if SDL_Init(SDL_INIT_VIDEO) < 0 then
    errorMessage(SDL_GetError());

  app.Window := SDL_CreateWindow('SDL TTF 1', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, windowFlags);
  if app.Window = NIL then
    errorMessage(SDL_GetError());

  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'linear');
  app.Renderer := SDL_CreateRenderer(app.Window, -1, rendererFlags);
  if app.Renderer = NIL then
    errorMessage(SDL_GetError());

{  IMG_INIT(IMG_INIT_PNG OR IMG_INIT_JPG);   }

  if (TTF_Init) < 0 then
    errorMessage(TTF_GetError());

  SDL_ShowCursor(0);
end;

procedure initDemoSystem;
begin
  initFonts;
end;

procedure AtExit;
begin
  SDL_DestroyTexture (helloWorld);
  SDL_DestroyRenderer(app.Renderer);
  SDL_DestroyWindow  (app.Window);
  TTF_Quit;
  SDL_Quit;
  if Exitcode <> 0 then WriteLn(SDL_GetError());
end;

// *****************   Input  *****************

procedure doInput;
begin
  while SDL_PollEvent(Event) = 1 do
  begin
    CASE Event^.Type_ of

      SDL_QUITEV:          exitLoop := TRUE;        { close Window }
      SDL_MOUSEBUTTONDOWN: exitLoop := TRUE;        { if Mousebutton pressed }

    end;  { CASE Event }
  end;    { SDL_PollEvent }
end;

// *****************   DEMO   *****************

procedure logic;
begin
  INC(textAngle);
  if textAngle > 360 then textAngle := 0;
end;

procedure drawNormalText;
begin
  blit(helloWorld, 50, 50, 0);
end;

procedure drawScaledText;
begin
  blitScaled(helloWorld, 50, 125, 500, 40);
end;

procedure drawRotatedText;
begin
  blitRotated(helloWorld,  60, 300, 90);
  blitRotated(helloWorld, 150, 300, -90);
  blitRotated(helloWorld, 600, 300, textAngle);
end;

procedure drawColouredText;
begin
  SDL_SetTextureColorMod(helloWorld, 255, 0, 0);
  blit(helloWorld, 275, 200, 0);
  SDL_SetTextureColorMod(helloWorld, 0, 255, 0);
  blit(helloWorld, 275, 250, 0);
  SDL_SetTextureColorMod(helloWorld, 0, 0, 255);
  blit(helloWorld, 275, 300, 0);
  SDL_SetTextureColorMod(helloWorld, 255, 255, 255);
  SDL_SetTextureAlphaMod(helloWorld, 64);
  blit(helloWorld, 275, 350, 0);
  SDL_SetTextureAlphaMod(helloWorld, 255);
end;

procedure draw;
begin
  drawNormalText;
  drawScaledText;
  drawRotatedText;
  drawColouredText;
end;

procedure initDemo;
begin
  helloWorld := getTextTexture('Hello World!');
  textAngle := 0;
  logic;
  draw;
end;

procedure CapFrameRate(VAR remainder : double; VAR Ticks : UInt32);
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
  initSDL;
  initDemoSystem;
  initDemo;
  exitloop := false;
  GTicks := SDL_GetTicks;
  Gremainder := 0;

  AddExitProc(@AtExit);

  NEW(Event);

  while exitLoop = FALSE do
  begin
    prepareScene;
    doInput;
    logic;
    draw;
    presentScene;

    CapFrameRate(GRemainder, GTicks);
  end;

  DISPOSE(Event);
  AtExit;
end.
