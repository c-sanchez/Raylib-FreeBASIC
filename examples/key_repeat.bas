#include "raylib.bi"

InitWindow(800, 450, "Key Repeat Example - raylib 5.0+")

Dim counter As Integer = 0

SetTargetFPS(60)

While IsNot WindowShouldClose()
  If IsKeyPressedRepeat(KEY_SPACE) Then
    counter += 1
  End If
  
  BeginDrawing()
  ClearBackground(RAYWHITE)
  
  DrawText("Hold SPACE key to increment counter", 20, 20, 20, DARKGRAY)
  DrawText("(Detects key repeat like text input)", 20, 50, 20, LIGHTGRAY)
  DrawText(TextFormat("Counter: %d", counter), 20, 100, 30, MAROON)
  
  EndDrawing()
Wend

CloseWindow()