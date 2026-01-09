#include "raylib.bi"
#include "raymath.bi"
#include "rlgl.bi"

#define RLGL_SRC_ALPHA &h0302
#define RLGL_MIN &h8007
#define RLGL_MAX &h8008

const MAX_BOXES = 20
const MAX_SHADOWS = MAX_BOXES * 3
const MAX_LIGHTS = 16

type ShadowGeometry
  vertices(0 to 3) as Vector2
end type

type LightInfo
  active as boolean
  dirty as boolean
  valid as boolean

  position as Vector2
  mask as RenderTexture
  outerRadius as single
  bounds as Rectangle

  shadows(0 to MAX_SHADOWS - 1) as ShadowGeometry
  shadowCount as long
end type

dim shared lights(0 to MAX_LIGHTS - 1) as LightInfo

sub MoveLight(byval slot as long, byval x as single, byval y as single)
  lights(slot).dirty = true
  lights(slot).position.x = x
  lights(slot).position.y = y

  lights(slot).bounds.x = x - lights(slot).outerRadius
  lights(slot).bounds.y = y - lights(slot).outerRadius
end sub

sub ComputeShadowVolumeForEdge(byval slot as long, byval sp as Vector2, byval ep as Vector2)
  if lights(slot).shadowCount >= MAX_SHADOWS then exit sub

  dim extension as single = lights(slot).outerRadius * 2

  dim spVector as Vector2 = Vector2Normalize(Vector2Subtract(sp, lights(slot).position))
  dim spProjection as Vector2 = Vector2Add(sp, Vector2Scale(spVector, extension))

  dim epVector as Vector2 = Vector2Normalize(Vector2Subtract(ep, lights(slot).position))
  dim epProjection as Vector2 = Vector2Add(ep, Vector2Scale(epVector, extension))

  lights(slot).shadows(lights(slot).shadowCount).vertices(0) = sp
  lights(slot).shadows(lights(slot).shadowCount).vertices(1) = ep
  lights(slot).shadows(lights(slot).shadowCount).vertices(2) = epProjection
  lights(slot).shadows(lights(slot).shadowCount).vertices(3) = spProjection

  lights(slot).shadowCount += 1
end sub

sub DrawLightMask(byval slot as long)
  BeginTextureMode(lights(slot).mask)
    ClearBackground(WHITE)

    rlSetBlendFactors(RLGL_SRC_ALPHA, RLGL_SRC_ALPHA, RLGL_MIN)
    rlSetBlendMode(BLEND_CUSTOM)

    if lights(slot).valid then
      DrawCircleGradient(cint(lights(slot).position.x), cint(lights(slot).position.y), lights(slot).outerRadius, ColorAlpha(WHITE, 0), WHITE)
    end if

    rlDrawRenderBatchActive()

    rlSetBlendMode(BLEND_ALPHA)
    rlSetBlendFactors(RLGL_SRC_ALPHA, RLGL_SRC_ALPHA, RLGL_MAX)
    rlSetBlendMode(BLEND_CUSTOM)

    for i as integer = 0 to lights(slot).shadowCount - 1
      DrawTriangleFan(@lights(slot).shadows(i).vertices(0), 4, WHITE)
    next

    rlDrawRenderBatchActive()

    rlSetBlendMode(BLEND_ALPHA)
  EndTextureMode()
end sub

sub SetupLight(byval slot as long, byval x as single, byval y as single, byval radius as single)
  lights(slot).active = true
  lights(slot).valid = false
  lights(slot).mask = LoadRenderTexture(GetScreenWidth(), GetScreenHeight())
  lights(slot).outerRadius = radius

  lights(slot).bounds.width = radius * 2
  lights(slot).bounds.height = radius * 2

  MoveLight(slot, x, y)

  DrawLightMask(slot)
end sub

function UpdateLight(byval slot as long, byval boxes as Rectangle ptr, byval count as long) as boolean
  if (not lights(slot).active) or (not lights(slot).dirty) then return false

  lights(slot).dirty = false
  lights(slot).shadowCount = 0
  lights(slot).valid = false

  for i as integer = 0 to count - 1
    if CheckCollisionPointRec(lights(slot).position, boxes[i]) then return false

    if not CheckCollisionRecs(lights(slot).bounds, boxes[i]) then continue for

    dim sp as Vector2 = type<Vector2>(boxes[i].x, boxes[i].y)
    dim ep as Vector2 = type<Vector2>(boxes[i].x + boxes[i].width, boxes[i].y)

    if lights(slot).position.y > ep.y then ComputeShadowVolumeForEdge(slot, sp, ep)

    sp = ep
    ep.y += boxes[i].height
    if lights(slot).position.x < ep.x then ComputeShadowVolumeForEdge(slot, sp, ep)

    sp = ep
    ep.x -= boxes[i].width
    if lights(slot).position.y < ep.y then ComputeShadowVolumeForEdge(slot, sp, ep)

    sp = ep
    ep.y -= boxes[i].height
    if lights(slot).position.x > ep.x then ComputeShadowVolumeForEdge(slot, sp, ep)

    lights(slot).shadows(lights(slot).shadowCount).vertices(0) = type<Vector2>(boxes[i].x, boxes[i].y)
    lights(slot).shadows(lights(slot).shadowCount).vertices(1) = type<Vector2>(boxes[i].x, boxes[i].y + boxes[i].height)
    lights(slot).shadows(lights(slot).shadowCount).vertices(2) = type<Vector2>(boxes[i].x + boxes[i].width, boxes[i].y + boxes[i].height)
    lights(slot).shadows(lights(slot).shadowCount).vertices(3) = type<Vector2>(boxes[i].x + boxes[i].width, boxes[i].y)
    lights(slot).shadowCount += 1
  next

  lights(slot).valid = true

  DrawLightMask(slot)

  return true
end function

sub SetupBoxes(byval boxes as Rectangle ptr, byval count as long ptr)
  boxes[0] = type<Rectangle>(150, 80, 40, 40)
  boxes[1] = type<Rectangle>(1200, 700, 40, 40)
  boxes[2] = type<Rectangle>(200, 600, 40, 40)
  boxes[3] = type<Rectangle>(1000, 50, 40, 40)
  boxes[4] = type<Rectangle>(500, 350, 40, 40)

  for i as integer = 5 to MAX_BOXES - 1
    boxes[i] = type<Rectangle>(GetRandomValue(0, GetScreenWidth()), GetRandomValue(0, GetScreenHeight()), GetRandomValue(10, 100), GetRandomValue(10, 100))
  next

  *count = MAX_BOXES
end sub

const screenWidth = 800
const screenHeight = 450

InitWindow(screenWidth, screenHeight, "raylib [shapes] example - top down lights")

dim boxCount as long = 0
dim boxes(0 to MAX_BOXES - 1) as Rectangle
SetupBoxes(@boxes(0), @boxCount)

dim img as Image = GenImageChecked(64, 64, 32, 32, DARKBROWN, DARKGRAY)
dim backgroundTexture as Texture2D = LoadTextureFromImage(img)
UnloadImage(img)

dim lightMask as RenderTexture = LoadRenderTexture(GetScreenWidth(), GetScreenHeight())

SetupLight(0, 600, 400, 300)
dim nextLight as long = 1

dim showLines as boolean = false

SetTargetFPS(60)

while not WindowShouldClose()
  if IsMouseButtonDown(MOUSE_BUTTON_LEFT) then MoveLight(0, GetMousePosition().x, GetMousePosition().y)

  if IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) and (nextLight < MAX_LIGHTS) then
    SetupLight(nextLight, GetMousePosition().x, GetMousePosition().y, 200)
    nextLight += 1
  end if

  if IsKeyPressed(KEY_F1) then showLines = not showLines

  dim dirtyLights as boolean = false
  for i as integer = 0 to MAX_LIGHTS - 1
    if UpdateLight(i, @boxes(0), boxCount) then dirtyLights = true
  next

  if dirtyLights then
    BeginTextureMode(lightMask)
      ClearBackground(BLACK)

      rlSetBlendFactors(RLGL_SRC_ALPHA, RLGL_SRC_ALPHA, RLGL_MIN)
      rlSetBlendMode(BLEND_CUSTOM)

      for i as integer = 0 to MAX_LIGHTS - 1
        if lights(i).active then DrawTextureRec(lights(i).mask.texture, type<Rectangle>(0, 0, GetScreenWidth(), -GetScreenHeight()), Vector2Zero(), WHITE)
      next

      rlDrawRenderBatchActive()

      rlSetBlendMode(BLEND_ALPHA)
    EndTextureMode()
  end if

  BeginDrawing()
    ClearBackground(BLACK)

    DrawTextureRec(backgroundTexture, type<Rectangle>(0, 0, GetScreenWidth(), GetScreenHeight()), Vector2Zero(), WHITE)

    DrawTextureRec(lightMask.texture, type<Rectangle>(0, 0, GetScreenWidth(), -GetScreenHeight()), Vector2Zero(), ColorAlpha(WHITE, iif(showLines, 0.75f, 1.0f)))

    for i as integer = 0 to MAX_LIGHTS - 1
      if lights(i).active then DrawCircle(cint(lights(i).position.x), cint(lights(i).position.y), 10, iif(i = 0, YELLOW, WHITE))
    next

    if showLines then
      for s as integer = 0 to lights(0).shadowCount - 1
        DrawTriangleFan(@lights(0).shadows(s).vertices(0), 4, DARKPURPLE)
      next

      for b as integer = 0 to boxCount - 1
        if CheckCollisionRecs(boxes(b), lights(0).bounds) then DrawRectangleRec(boxes(b), PURPLE)
        DrawRectangleLines(cint(boxes(b).x), cint(boxes(b).y), cint(boxes(b).width), cint(boxes(b).height), DARKBLUE)
      next

      DrawText("(F1) Hide Shadow Volumes", 10, 50, 10, GREEN)
    else
      DrawText("(F1) Show Shadow Volumes", 10, 50, 10, GREEN)
    end if

    DrawFPS(screenWidth - 80, 10)
    DrawText("Drag to move light #1", 10, 10, 10, DARKGREEN)
    DrawText("Right click to add new light", 10, 30, 10, DARKGREEN)
  EndDrawing()
wend

UnloadTexture(backgroundTexture)
UnloadRenderTexture(lightMask)
for i as integer = 0 to MAX_LIGHTS - 1
  if lights(i).active then UnloadRenderTexture(lights(i).mask)
next

CloseWindow()