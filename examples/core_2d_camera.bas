#include "raylib.bi"

Const MAX_BUILDINGS = 100

Const screenWidth = 800
Const screenHeight = 450

InitWindow(screenWidth, screenHeight, "raylib [core] example - 2d camera")

Dim player As Rectangle = Type(400, 280, 40, 40)

Dim buildings(0 To MAX_BUILDINGS - 1) As Rectangle
Dim buildColors(0 To MAX_BUILDINGS - 1) As RayColor

Dim spacing As Integer = 0

For i As Integer = 0 To MAX_BUILDINGS - 1
  buildings(i).width = CSng(GetRandomValue(50, 200))
  buildings(i).height = CSng(GetRandomValue(100, 800))
  buildings(i).y = screenHeight - 130.0f - buildings(i).height
  buildings(i).x = -6000.0f + spacing

  spacing += CInt(buildings(i).width)

  buildColors(i) = Type<RayColor>(GetRandomValue(200, 240), GetRandomValue(200, 240), GetRandomValue(200, 250), 255)
Next

Dim camera As Camera2D
camera.target = Type<Vector2>(player.x + 20.0f, player.y + 20.0f)
camera.offset = Type<Vector2>(screenWidth / 2.0f, screenHeight / 2.0f)
camera.rotation = 0.0f
camera.zoom = 1.0f

SetTargetFPS(60)

Do While WindowShouldClose() = false

  If IsKeyDown(KEY_RIGHT) Then
    player.x += 2
  ElseIf IsKeyDown(KEY_LEFT) Then
    player.x -= 2
  End If

  camera.target = Type<Vector2>(player.x + 20, player.y + 20)

  If IsKeyDown(KEY_A) Then
    camera.rotation -= 1
  ElseIf IsKeyDown(KEY_S) Then
    camera.rotation += 1
  End If

  If camera.rotation > 40 Then
    camera.rotation = 40
  ElseIf camera.rotation < -40 Then
    camera.rotation = -40
  End If

  camera.zoom += (GetMouseWheelMove() * 0.05f)

  If camera.zoom > 3.0f Then
    camera.zoom = 3.0f
  ElseIf camera.zoom < 0.1f Then
    camera.zoom = 0.1f
  End If

  If IsKeyPressed(KEY_R) Then
    camera.zoom = 1.0f
    camera.rotation = 0.0f
  End If

  BeginDrawing()

    ClearBackground(RAYWHITE)

    BeginMode2D(camera)

      DrawRectangle(-6000, 320, 13000, 8000, DARKGRAY)

      For i As Integer = 0 To MAX_BUILDINGS - 1
        DrawRectangleRec(buildings(i), buildColors(i))
      Next

      DrawRectangleRec(player, RED)

      DrawLine(CInt(camera.target.x), -screenHeight * 10, CInt(camera.target.x), screenHeight * 10, GREEN)
      DrawLine(-screenWidth * 10, CInt(camera.target.y), screenWidth * 10, CInt(camera.target.y), GREEN)

    EndMode2D()

    DrawText("SCREEN AREA", 640, 10, 20, RED)

    DrawRectangle(0, 0, screenWidth, 5, RED)
    DrawRectangle(0, 5, 5, screenHeight - 10, RED)
    DrawRectangle(screenWidth - 5, 5, 5, screenHeight - 10, RED)
    DrawRectangle(0, screenHeight - 5, screenWidth, 5, RED)

    DrawRectangle(10, 10, 250, 113, Fade(SKYBLUE, 0.5f))
    DrawRectangleLines(10, 10, 250, 113, BLUE)

    DrawText("Free 2d camera controls:", 20, 20, 10, BLACK)
    DrawText("- Right/Left to move Offset", 40, 40, 10, DARKGRAY)
    DrawText("- Mouse Wheel to Zoom in-out", 40, 60, 10, DARKGRAY)
    DrawText("- A / S to Rotate", 40, 80, 10, DARKGRAY)
    DrawText("- R to reset Zoom and Rotation", 40, 100, 10, DARKGRAY)

  EndDrawing()

Loop

CloseWindow()