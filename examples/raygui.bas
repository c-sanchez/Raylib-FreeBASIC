#include once "raylib.bi"
#include once "raygui.bi"

' Inicialización
InitWindow(400, 200, "raygui - controls test suite")
SetTargetFPS(60)

Dim showMessageBox As Boolean = false

Do Until WindowShouldClose()
  ' Dibujar
  '----------------------------------------------------------------------------------
  BeginDrawing()
    
    ' Obtenemos el color de fondo del estilo por defecto
    ClearBackground(GetColor(GuiGetStyle(DEFAULT, BACKGROUND_COLOR)))

    ' Botón para mostrar el mensaje
    ' Usamos Type<Rectangle> para definir la estructura en la llamada
    If GuiButton(Type<Rectangle>(24, 24, 120, 30), "#191#Show Message") Then
      showMessageBox = true
    End If

    If showMessageBox Then
      Dim btnActive As Long = 0

      ' En raygui 5.0 se requiere el puntero @btnActive para devolver el botón seleccionado
      Dim result As Long = GuiMessageBox(Type<Rectangle>(85, 70, 250, 100), _
                                         "#191#Message Box", _
                                         "Hi! This is a message!", _
                                         "Nice;Cool", _
                                         @btnActive)

      ' Si result = 1 (RESULT_PRESSED) significa que se presionó un botón o se cerró
      If result = 1 Then showMessageBox = false
    End If

  EndDrawing()
Loop

CloseWindow()