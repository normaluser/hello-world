{ Copyright (C) 2021 Parallel Realities }

PROGRAM ttf;

{$COPERATORS OFF}
USES CRT, SDL2, {SDL2_image,} SDL2_ttf;

CONST SCREEN_WIDTH        = 1280;      { size of the grafic window }
      SCREEN_HEIGHT       = 720;       { size of the grafic window }
      MAX_Filename_LENGTH = 256;
      FONT_SIZE           = 48;
      FONT_TEXTURE_SIZE   = 512;
      NUM_GLYPHS          = 128;
      FONT_MAX            = 2;

TYPE                                   { "T" short for "TYPE" }
     TApp        = RECORD
                     Window   : PSDL_Window;
                     Renderer : PSDL_Renderer;
                   end;
     FontName    = (FONT_ENTER_COMMAND, FONT_LINUX);

VAR app          : TApp;
    ttf_Font     : Array[0..FONT_MAX] of PTTF_Font;
    glyphs       : Array[0..FONT_MAX,0..NUM_GLYPHS] of TSDL_RECT;
    fontTextures : Array[0..FONT_MAX] of PSDL_Texture;
    gTicks       : UInt32;
    gRemainder   : Double;
    Event        : PSDL_EVENT;
    exitLoop     : BOOLEAN;
    textAngle    : Integer;
    surface1     : PSDL_Surface;
    numLogicCall : integer;


// *****************   UTIL   *****************

procedure errorMessage(Message : PChar);
begin
  SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR,'Error Box',Message,NIL);
  HALT(1);
end;

// *****************   DRAW   *****************

function toTexture(surface : PSDL_Surface; destroySurface : Byte) : PSDL_Texture;
begin
  toTexture := SDL_CreateTextureFromSurface(app.Renderer, surface);
  if (destroySurface <> 0) then
    SDL_FreeSurface(surface);
end;

function getTextTexture(text : PChar; typ : integer) : PSDL_Texture;
var white : TSDL_Color;
begin
  white.g := 255; white.b := 255; white.r := 255; white.a := 255;
  surface1 := TTF_RenderUTF8_Blended(ttf_font[typ], text, white);

  //convert SDL_Surface to SDL_Texture
  getTextTexture := toTexture(surface1, 1);
end;

procedure drawText(text : pchar; x, y, r, g, b, fontType : integer);
var i, character : integer;
    glyph, dest : PSDL_Rect;

begin
  SDL_SetTextureColorMod(fontTextures[fontType], r, g, b);
  i := 0;
  character := text[i+1];

	while (character)
	{
		glyph = &glyphs[fontType][character];

		dest.x = x;
		dest.y = y;
		dest.w = glyph->w;
		dest.h = glyph->h;

		SDL_RenderCopy(app.renderer, fontTextures[fontType], glyph, &dest);

		x += glyph->w;

		character = text[i++];
	}
end;

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
  SDL_SetRenderDrawColor(app.Renderer, 0, 0, 0, 255);
  //SDL_SetRenderDrawColor(app.Renderer, 6, 96, 96, 255);
  SDL_RenderClear(app.Renderer);
end;

procedure presentScene;
begin
  SDL_RenderPresent(app.Renderer);
end;

procedure initFont(fontType : FontName; filename : string);
begin
  SDL_Surface *surface, *text;
  SDL_Rect dest;
  int i;
	char c[2];
	SDL_Rect *g;

	memset(&glyphs[fontType], 0, sizeof(SDL_Rect) * NUM_GLYPHS);

	fonts[fontType] = TTF_OpenFont(filename, FONT_SIZE);

	surface = SDL_CreateRGBSurface(0, FONT_TEXTURE_SIZE, FONT_TEXTURE_SIZE, 32, 0, 0, 0, 0xff);

	SDL_SetColorKey(surface, SDL_TRUE, SDL_MapRGBA(surface->format, 0, 0, 0, 0));

	dest.x = dest.y = 0;

	for (i = ' ' ; i <= 'z' ; i++)
	{
		c[0] = i;
		c[1] = 0;

		text = TTF_RenderUTF8_Blended(fonts[fontType], c, white);

		TTF_SizeText(fonts[fontType], c, &dest.w, &dest.h);

		if (dest.x + dest.w >= FONT_TEXTURE_SIZE)
		{
			dest.x = 0;

			dest.y += dest.h + 1;

			if (dest.y + dest.h >= FONT_TEXTURE_SIZE)
			{
				SDL_LogMessage(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_CRITICAL, "Out of glyph space in %dx%d font atlas texture map.", FONT_TEXTURE_SIZE, FONT_TEXTURE_SIZE);
				exit(1);
			}
		}

		SDL_BlitSurface(text, NULL, surface, &dest);

		g = &glyphs[fontType][i];

		g->x = dest.x;
		g->y = dest.y;
		g->w = dest.w;
		g->h = dest.h;

		SDL_FreeSurface(text);

		dest.x += dest.w;
	}

	fontTextures[fontType] = toTexture(surface, 1);
end;

procedure initFonts;
var err : PChar;
begin
  initFont(FONT_ENTER_COMMAND, 'fonts/EnterCommand.ttf');
  initFont(FONT_LINUX, 'fonts/LinLibertine_DR.ttf');
end;

function toTexture(surface : PSDL_Surface; destroySurface : Byte) : PSDL_Texture;
begin
  toTexture := SDL_CreateTextureFromSurface(app.Renderer, surface);
  if (destroySurface <> 0) then
    SDL_FreeSurface(surface);
end;

function getTextTexture(text : PChar) : PSDL_Texture;
var white : TSDL_Color;
    i     : byte;
begin
  white.g := 255; white.b := 255; white.r := 255; white.a := 255;
  surface1 := TTF_RenderUTF8_Blended(ttf_Font[i], text, white);

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
  //SDL_DestroyTexture (helloWorld);
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
  INC(numLogicCall);
end;

procedure drawStatText;
begin
  char stat[32];
  sprintf(stat, "Logic calls: %d", numLogicCalls);
  drawText(stat, 50, 550, 128, 128, 128, FONT_ENTER_COMMAND);
  sprintf(stat, "Running: %d seconds", SDL_GetTicks() / 1000);
  drawText(stat, 50, 600, 128, 128, 128, FONT_ENTER_COMMAND);
end;

procedure drawNormalText;
begin
  drawText('A line of normal text!', 50, 50, 255, 255, 255, FONT_ENTER_COMMAND);
end;

procedure drawScaledText;
begin
  blitScaled(helloWorld, 50, 125, 500, 40);
end;

procedure drawColouredText;
begin
  drawText("A line of red coloured text.", 50, 150, 255, 0, 0, FONT_LINUX);
  drawText("A line of green coloured text.", 50, 250, 0, 255, 0, FONT_ENTER_COMMAND);
  drawText("A line of light blue coloured text.", 50, 350, 128, 192, 255, FONT_LINUX);
  drawText("A really long line of text that is too wide for the screen and can't be read properly.", 50, 450, 255, 255, 255, FONT_LINUX);
end;

procedure draw;
begin
  drawNormalText;
  drawColouredText;
  drawStatText;
end;

procedure initDemo;
begin
  numLogicCall := 0;
//  logic;
//  draw;
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
