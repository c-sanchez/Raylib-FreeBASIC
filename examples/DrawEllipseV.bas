#include "raylib.bi"

' Initialize window
InitWindow(800, 450, "raylib 6.0 - DrawEllipseV Example")

SetTargetFPS(60)

While Not WindowShouldClose()
  ' Get time for the pulsating animation
  Dim timePassed As Double = GetTime()
  
  ' Get current mouse position as Vector2
  Dim mousePos As Vector2 = GetMousePosition()
  
  ' Calculate dynamic horizontal and vertical radii using Sine/Cosine
  Dim radiusH As Single = 100.0f + CSng(Sin(timePassed * 2.0f)) * 50.0f
  Dim radiusV As Single = 80.0f + CSng(Cos(timePassed * 3.0f)) * 40.0f
  
  BeginDrawing()
    ClearBackground(RAYWHITE)
    
    DrawText("DrawEllipseV Example", 20, 20, 20, DARKGRAY)
    DrawText("Move the mouse to move the Vector2 center.", 20, 50, 20, GRAY)
    
    ' Draw the ellipse using the Vector2 position directly
    DrawEllipseV(mousePos, radiusH, radiusV, PURPLE)
    
    ' Draw ellipse outline
    DrawEllipseLinesV(mousePos, radiusH, radiusV, DARKPURPLE)
    
    ' Draw a tiny circle at the exact center to show the Vector2 origin
    DrawCircleV(mousePos, 3.0f, RED)
    
  EndDrawing()
Wend

CloseWindow()