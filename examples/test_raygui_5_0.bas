#include once "raylib.bi"
#include once "raygui.bi"

InitWindow(700, 450, "Raygui 5.0 - Test de Nuevos Controles")
SetTargetFPS(60)

' Variables para el nuevo control GuiTabBar
Dim As Long activeTab = 0
Dim As Long tabScroll = 0
Dim As String tabsText = "General;Graficos;Sonido;Red"

' Variables para el nuevo control GuiValueBoxFloat
Dim As Single zoomValue = 1.25f
Dim As ZString * 32 textBuffer = "1.25"
Dim As Boolean editModeFloat = False

Do Until WindowShouldClose()
  BeginDrawing()
    ClearBackground(GetColor(GuiGetStyle(DEFAULT, BACKGROUND_COLOR)))

    DrawText("Novedades de Raygui 5.0", 24, 20, 20, DARKGRAY)

    ' 1. Nuevo control: GuiTabBar
    GuiLabel(Type<Rectangle>(24, 60, 200, 20), "1. Nuevo GuiTabBar():")
    
    Dim As Long tabResult = GuiTabBar(Type<Rectangle>(24, 85, 650, 32), tabsText, @tabScroll, @activeTab)
    
    If tabResult = RESULT_TAB_CLOSE Then
      DrawText("¡Peticion de cerrar pestana detectada!", 24, 125, 14, RED)
    Else
      DrawText(TextFormat("Pestana seleccionada: %i", activeTab), 24, 125, 14, DARKBLUE)
    End If

    ' 2. Nuevo control: GuiValueBoxFloat (Edicion de floats con teclado)
    GuiLabel(Type<Rectangle>(24, 170, 250, 20), "2. Nuevo GuiValueBoxFloat():")
    
    ' Movemos la caja a X = 130 para dar espacio a la etiqueta "Sensibilidad:" a su izquierda
    If GuiValueBoxFloat(Type<Rectangle>(130, 195, 90, 30), "Sensibilidad:", textBuffer, @zoomValue, editModeFloat) Then
      editModeFloat = Not editModeFloat
    End If

    DrawText(TextFormat("Valor Single en memoria: %.4f", zoomValue), 235, 202, 14, DARKGREEN)

    ' 3. Soporte de nuevos iconos (ID >= 220)
    GuiLabel(Type<Rectangle>(24, 260, 250, 20), "3. Nuevos Iconos integrados (Raygui 5.0):")

    GuiDrawIcon(ICON_WARNING, 40, 295, 2, RED)
    GuiLabel(Type<Rectangle>(75, 300, 100, 20), "ICON_WARNING")

    GuiDrawIcon(ICON_HOT, 200, 295, 2, ORANGE)
    GuiLabel(Type<Rectangle>(235, 300, 100, 20), "ICON_HOT")

    GuiDrawIcon(ICON_SPHERE, 340, 295, 2, BLUE)
    GuiLabel(Type<Rectangle>(375, 300, 100, 20), "ICON_SPHERE")

    GuiDrawIcon(ICON_CYLINDER, 480, 295, 2, DARKPURPLE)
    GuiLabel(Type<Rectangle>(515, 300, 100, 20), "ICON_CYLINDER")

    ' Barra de estado
    GuiStatusBar(Type<Rectangle>(0, 426, 700, 24), "Raygui 5.0 funcionando en FreeBASIC")

  EndDrawing()
Loop

CloseWindow()