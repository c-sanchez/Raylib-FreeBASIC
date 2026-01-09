#include "raylib.bi"

InitWindow(800, 450, "Circle-Line Collision - raylib 5.5+")

Dim circlePos As Vector2 = Type(400, 225)
Dim circleRadius As Single = 50.0f
Dim lineStart As Vector2 = Type(100, 100)
Dim lineEnd As Vector2 = Type(700, 350)

SetTargetFPS(60)

While IsNot WindowShouldClose()
  circlePos = GetMousePosition()
  
  Dim collision As Boolean = CheckCollisionCircleLine(circlePos, circleRadius, lineStart, lineEnd)
  
  BeginDrawing()
  ClearBackground(RAYWHITE)
  
  DrawText("Move mouse to test collision", 20, 20, 20, DARKGRAY)
  
  DrawLineEx(lineStart, lineEnd, 4.0f, BLUE)
  
  DrawCircleV(circlePos, circleRadius, IIf(collision, RED, GREEN))
  
  DrawText(IIf(collision, "COLLISION!", "No collision"), 20, 50, 20, IIf(collision, RED, GREEN))
  
  EndDrawing()
Wend

CloseWindow()