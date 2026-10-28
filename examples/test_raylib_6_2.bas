#include once "raylib.bi"

InitWindow(800, 500, "Raylib 6.2 - Test de Nuevas Funciones")
SetTargetFPS(60)

Dim As Single circleThick = 2.0f
Dim As Single angle = 0.0f

Do Until WindowShouldClose()
  angle += 0.02f
  circleThick = 2.0f + Sin(GetTime() * 3.0f) * 4.0f

  BeginDrawing()
    ClearBackground(RAYWHITE)

    DrawText("Probando novedades de Raylib 6.2", 20, 20, 20, DARKGRAY)

    ' 1. Nueva funcion: DrawTriangleGradient (Degradado multicolor por vertice)
    DrawText("1. DrawTriangleGradient():", 40, 70, 16, BLACK)
    Dim As Vector2 v1 = Type<Vector2>(180 + Cos(angle) * 30.0f, 130 + Sin(angle) * 20.0f)
    Dim As Vector2 v2 = Type<Vector2>(80, 280)
    Dim As Vector2 v3 = Type<Vector2>(280, 280)
    
    DrawTriangleGradient(v1, v2, v3, RED, GREEN, BLUE)
    DrawTriangleLines(v1, v2, v3, DARKGRAY)

    ' 2. Nueva funcion: DrawCircleLinesEx (Circulo con grosor personalizado)
    DrawText("2. DrawCircleLinesEx():", 450, 70, 16, BLACK)
    Dim As Vector2 center = Type<Vector2>(580, 200)
    DrawCircleLinesEx(center, 70.0f, circleThick, MAROON)
    DrawCircleLinesEx(center, 40.0f, 2.0f, DARKBLUE)

    ' 3. Nuevas funciones de paths (IsPathDirectory / IsPathAbsolute)
    DrawText("3. Nuevos validadores de rutas:", 40, 340, 16, BLACK)
    
    Dim As String testPath1 = "C:\Windows"
    Dim As String testPath2 = "texturas/avatar.png"

    DrawText(TextFormat("Ruta '%s': Es Absoluta? %s", testPath1, IIf(IsPathAbsolute(testPath1), "SI", "NO")), 50, 375, 16, DARKGREEN)
    DrawText(TextFormat("Ruta '%s': Es Directorio? %s", testPath1, IIf(IsPathDirectory(testPath1), "SI", "NO")), 50, 400, 16, DARKGREEN)
    
    DrawText(TextFormat("Ruta '%s': Es Absoluta? %s", testPath2, IIf(IsPathAbsolute(testPath2), "SI", "NO")), 50, 435, 16, PURPLE)
    DrawText(TextFormat("Ruta '%s': Es Directorio? %s", testPath2, IIf(IsPathDirectory(testPath2), "SI", "NO")), 50, 460, 16, PURPLE)

  EndDrawing()
Loop

CloseWindow()