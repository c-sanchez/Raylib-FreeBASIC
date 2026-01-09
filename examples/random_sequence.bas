#include "raylib.bi"

InitWindow(800, 450, "Random Sequence Example - raylib 5.0+")

Dim As long ptr randomSequence = LoadRandomSequence(10, 1, 100)

SetTargetFPS(60)

While IsNot WindowShouldClose()
  BeginDrawing()
  ClearBackground(RAYWHITE)
  
  DrawText("Random Sequence (no duplicates):", 20, 20, 20, DARKGRAY)
  
  For i As Integer = 0 To 9
    DrawText(TextFormat("%d", randomSequence[i]), 20, 60 + i * 30, 20, MAROON)
  Next
  
  EndDrawing()
Wend

UnloadRandomSequence(randomSequence)

CloseWindow()