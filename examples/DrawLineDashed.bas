#include "raylib.bi"

' Initialize window
InitWindow(800, 450, "raylib 6.0 - DrawLineDashed Example")

' Define the center of the screen using the Vector2 structure
Dim centerPos As Vector2 = Type<Vector2>(400.0f, 225.0f)

SetTargetFPS(60)

While Not WindowShouldClose()
  ' Get current mouse position
  Dim mousePos As Vector2 = GetMousePosition()
  
  BeginDrawing()
    ClearBackground(RAYWHITE)
    
    DrawText("DrawLineDashed Example", 20, 20, 20, DARKGRAY)
    DrawText("Comparing different dash and space sizes:", 50, 70, 10, GRAY)
    
    ' 1. Dash size: 10, Space size: 10
    DrawText("Dash: 10, Space: 10", 50, 100, 10, DARKGRAY)
    DrawLineDashed(Type<Vector2>(200.0f, 105.0f), Type<Vector2>(750.0f, 105.0f), 10, 10, BLUE)
    
    ' 2. Dash size: 20, Space size: 5
    DrawText("Dash: 20, Space: 5", 50, 150, 10, DARKGRAY)
    DrawLineDashed(Type<Vector2>(200.0f, 155.0f), Type<Vector2>(750.0f, 155.0f), 20, 5, GREEN)
    
    ' 3. Dash size: 5, Space size: 15
    DrawText("Dash: 5, Space: 15", 50, 200, 10, DARKGRAY)
    DrawLineDashed(Type<Vector2>(200.0f, 205.0f), Type<Vector2>(750.0f, 205.0f), 5, 15, RED)
    
    ' 4. Dynamic dashed line targeting the mouse
    DrawText("Dynamic dashed line (Center to Mouse):", 50, 270, 20, DARKGRAY)
    DrawLineDashed(centerPos, mousePos, 15, 10, MAROON)
    
    ' Draw a small circle at the mouse tip for aesthetics
    DrawCircleV(mousePos, 4.0f, MAROON)
    
  EndDrawing()
Wend

CloseWindow()