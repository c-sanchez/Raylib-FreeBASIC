#include "raylib.bi"
#include "rlgl.bi"

Declare Sub DrawCubeTexture(ByVal texture As Texture2D, ByVal position As Vector3, ByVal w As Single, ByVal h As Single, ByVal l As Single, ByVal tint As RayColor)
Declare Sub DrawCubeTextureRec(ByVal texture As Texture2D, ByVal source As Rectangle, ByVal position As Vector3, ByVal w As Single, ByVal h As Single, ByVal l As Single, ByVal tint As RayColor)

Const screenWidth = 800
Const screenHeight = 450

InitWindow(screenWidth, screenHeight, "raylib [models] example - draw cube texture")

Dim camera As Camera3D
camera.position = Type<Vector3>(0.0f, 10.0f, 10.0f)
camera.target = Type<Vector3>(0.0f, 0.0f, 0.0f)
camera.up = Type<Vector3>(0.0f, 1.0f, 0.0f)
camera.fovy = 45.0f
camera.projection = CAMERA_PERSPECTIVE

Dim texture As Texture2D = LoadTexture("resources/cubicmap_atlas.png")

SetTargetFPS(60)

Do Until WindowShouldClose()
  BeginDrawing()

    ClearBackground(RAYWHITE)

    BeginMode3D(camera)

      DrawCubeTexture(texture, Type<Vector3>(-2.0f, 2.0f, 0.0f), 2.0f, 4.0f, 2.0f, WHITE)

      DrawCubeTextureRec(texture, _
        Type<Rectangle>(0.0f, texture.height/2.0f, texture.width/2.0f, texture.height/2.0f), _
        Type<Vector3>(2.0f, 1.0f, 0.0f), 2.0f, 2.0f, 2.0f, WHITE)

      DrawGrid(10, 1.0f)

    EndMode3D()

    DrawFPS(10, 10)

  EndDrawing()
Loop

UnloadTexture(texture)
CloseWindow()

Sub DrawCubeTexture(ByVal texture As Texture2D, ByVal position As Vector3, ByVal w As Single, ByVal h As Single, ByVal l As Single, ByVal tint As RayColor)
  Dim x As Single = position.x
  Dim y As Single = position.y
  Dim z As Single = position.z

  rlSetTexture(texture.id)

  rlBegin(RL_QUADS)
    rlColor4ub(tint.r, tint.g, tint.b, tint.a)

    rlNormal3f(0.0f, 0.0f, 1.0f)
    rlTexCoord2f(0.0f, 0.0f): rlVertex3f(x - w/2, y - h/2, z + l/2)
    rlTexCoord2f(1.0f, 0.0f): rlVertex3f(x + w/2, y - h/2, z + l/2)
    rlTexCoord2f(1.0f, 1.0f): rlVertex3f(x + w/2, y + h/2, z + l/2)
    rlTexCoord2f(0.0f, 1.0f): rlVertex3f(x - w/2, y + h/2, z + l/2)

    rlNormal3f(0.0f, 0.0f, -1.0f)
    rlTexCoord2f(1.0f, 0.0f): rlVertex3f(x - w/2, y - h/2, z - l/2)
    rlTexCoord2f(1.0f, 1.0f): rlVertex3f(x - w/2, y + h/2, z - l/2)
    rlTexCoord2f(0.0f, 1.0f): rlVertex3f(x + w/2, y + h/2, z - l/2)
    rlTexCoord2f(0.0f, 0.0f): rlVertex3f(x + w/2, y - h/2, z - l/2)

    rlNormal3f(0.0f, 1.0f, 0.0f)
    rlTexCoord2f(0.0f, 1.0f): rlVertex3f(x - w/2, y + h/2, z - l/2)
    rlTexCoord2f(0.0f, 0.0f): rlVertex3f(x - w/2, y + h/2, z + l/2)
    rlTexCoord2f(1.0f, 0.0f): rlVertex3f(x + w/2, y + h/2, z + l/2)
    rlTexCoord2f(1.0f, 1.0f): rlVertex3f(x + w/2, y + h/2, z - l/2)

    rlNormal3f(0.0f, -1.0f, 0.0f)
    rlTexCoord2f(1.0f, 1.0f): rlVertex3f(x - w/2, y - h/2, z - l/2)
    rlTexCoord2f(0.0f, 1.0f): rlVertex3f(x + w/2, y - h/2, z - l/2)
    rlTexCoord2f(0.0f, 0.0f): rlVertex3f(x + w/2, y - h/2, z + l/2)
    rlTexCoord2f(1.0f, 0.0f): rlVertex3f(x - w/2, y - h/2, z + l/2)

    rlNormal3f(1.0f, 0.0f, 0.0f)
    rlTexCoord2f(1.0f, 0.0f): rlVertex3f(x + w/2, y - h/2, z - l/2)
    rlTexCoord2f(1.0f, 1.0f): rlVertex3f(x + w/2, y + h/2, z - l/2)
    rlTexCoord2f(0.0f, 1.0f): rlVertex3f(x + w/2, y + h/2, z + l/2)
    rlTexCoord2f(0.0f, 0.0f): rlVertex3f(x + w/2, y - h/2, z + l/2)

    rlNormal3f(-1.0f, 0.0f, 0.0f)
    rlTexCoord2f(0.0f, 0.0f): rlVertex3f(x - w/2, y - h/2, z - l/2)
    rlTexCoord2f(1.0f, 0.0f): rlVertex3f(x - w/2, y - h/2, z + l/2)
    rlTexCoord2f(1.0f, 1.0f): rlVertex3f(x - w/2, y + h/2, z + l/2)
    rlTexCoord2f(0.0f, 1.0f): rlVertex3f(x - w/2, y + h/2, z - l/2)
  rlEnd()

  rlSetTexture(0)
End Sub

Sub DrawCubeTextureRec(ByVal texture As Texture2D, ByVal source As Rectangle, ByVal position As Vector3, ByVal w As Single, ByVal h As Single, ByVal l As Single, ByVal tint As RayColor)
  Dim x As Single = position.x
  Dim y As Single = position.y
  Dim z As Single = position.z
  Dim texWidth As Single = CSng(texture.width)
  Dim texHeight As Single = CSng(texture.height)

  rlSetTexture(texture.id)

  rlBegin(RL_QUADS)
    rlColor4ub(tint.r, tint.g, tint.b, tint.a)

    rlNormal3f(0.0f, 0.0f, 1.0f)
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x - w/2, y - h/2, z + l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x + w/2, y - h/2, z + l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight)
    rlVertex3f(x + w/2, y + h/2, z + l/2)
    rlTexCoord2f(source.x/texWidth, source.y/texHeight)
    rlVertex3f(x - w/2, y + h/2, z + l/2)

    rlNormal3f(0.0f, 0.0f, -1.0f)
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x - w/2, y - h/2, z - l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight)
    rlVertex3f(x - w/2, y + h/2, z - l/2)
    rlTexCoord2f(source.x/texWidth, source.y/texHeight)
    rlVertex3f(x + w/2, y + h/2, z - l/2)
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x + w/2, y - h/2, z - l/2)

    rlNormal3f(0.0f, 1.0f, 0.0f)
    rlTexCoord2f(source.x/texWidth, source.y/texHeight)
    rlVertex3f(x - w/2, y + h/2, z - l/2)
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x - w/2, y + h/2, z + l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x + w/2, y + h/2, z + l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight)
    rlVertex3f(x + w/2, y + h/2, z - l/2)

    rlNormal3f(0.0f, -1.0f, 0.0f)
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight)
    rlVertex3f(x - w/2, y - h/2, z - l/2)
    rlTexCoord2f(source.x/texWidth, source.y/texHeight)
    rlVertex3f(x + w/2, y - h/2, z - l/2)
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x + w/2, y - h/2, z + l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x - w/2, y - h/2, z + l/2)

    rlNormal3f(1.0f, 0.0f, 0.0f)
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x + w/2, y - h/2, z - l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight)
    rlVertex3f(x + w/2, y + h/2, z - l/2)
    rlTexCoord2f(source.x/texWidth, source.y/texHeight)
    rlVertex3f(x + w/2, y + h/2, z + l/2)
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x + w/2, y - h/2, z + l/2)

    rlNormal3f(-1.0f, 0.0f, 0.0f)
    rlTexCoord2f(source.x/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x - w/2, y - h/2, z - l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, (source.y + source.height)/texHeight)
    rlVertex3f(x - w/2, y - h/2, z + l/2)
    rlTexCoord2f((source.x + source.width)/texWidth, source.y/texHeight)
    rlVertex3f(x - w/2, y + h/2, z + l/2)
    rlTexCoord2f(source.x/texWidth, source.y/texHeight)
    rlVertex3f(x - w/2, y + h/2, z - l/2)

  rlEnd()

  rlSetTexture(0)
End Sub