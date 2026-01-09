#include "raylib.bi"
#include "rlgl.bi"

Declare Sub DrawSphereBasic(byval col as RayColor)

const screenWidth = 800
const screenHeight = 450

const sunRadius = 4.0f
const earthRadius = 0.6f
const earthOrbitRadius = 8.0f
const moonRadius = 0.16f
const moonOrbitRadius = 1.5f

InitWindow(screenWidth, screenHeight, "raylib [models] example - rlgl solar system")

dim camera as Camera
camera.position = type<Vector3>(16.0f, 16.0f, 16.0f)
camera.target = type<Vector3>(0.0f, 0.0f, 0.0f)
camera.up = type<Vector3>(0.0f, 1.0f, 0.0f)
camera.fovy = 45.0f
camera.projection = CAMERA_PERSPECTIVE

dim rotationSpeed as single = 0.2f
dim earthRotation as single = 0.0f
dim earthOrbitRotation as single = 0.0f
dim moonRotation as single = 0.0f
dim moonOrbitRotation as single = 0.0f

SetTargetFPS(60)

while isnot WindowShouldClose()
  UpdateCamera(@camera, CAMERA_ORBITAL)

  earthRotation += (5.0f * rotationSpeed)
  earthOrbitRotation += (365 / 360.0f * (5.0f * rotationSpeed) * rotationSpeed)
  moonRotation += (2.0f * rotationSpeed)
  moonOrbitRotation += (8.0f * rotationSpeed)

  BeginDrawing()
    ClearBackground(RAYWHITE)

    BeginMode3D(camera)
      rlPushMatrix()
        rlScalef(sunRadius, sunRadius, sunRadius)
        DrawSphereBasic(GOLD)
      rlPopMatrix()

      rlPushMatrix()
        rlRotatef(earthOrbitRotation, 0.0f, 1.0f, 0.0f)
        rlTranslatef(earthOrbitRadius, 0.0f, 0.0f)

        rlPushMatrix()
          rlRotatef(earthRotation, 0.25, 1.0, 0.0)
          rlScalef(earthRadius, earthRadius, earthRadius)
          DrawSphereBasic(BLUE)
        rlPopMatrix()

        rlRotatef(moonOrbitRotation, 0.0f, 1.0f, 0.0f)
        rlTranslatef(moonOrbitRadius, 0.0f, 0.0f)
        rlRotatef(moonRotation, 0.0f, 1.0f, 0.0f)
        rlScalef(moonRadius, moonRadius, moonRadius)
        DrawSphereBasic(LIGHTGRAY)
      rlPopMatrix()

      DrawCircle3D(type<Vector3>(0.0f, 0.0f, 0.0f), earthOrbitRadius, type<Vector3>(1, 0, 0), 90.0f, Fade(RED, 0.5f))
      DrawGrid(20, 1.0f)
    EndMode3D()

    DrawText("EARTH ORBITING AROUND THE SUN!", 400, 10, 20, MAROON)
    DrawFPS(10, 10)
  EndDrawing()
wend

CloseWindow()

Sub DrawSphereBasic(byval col as RayColor)
  dim rings as long = 16
  dim slices as long = 16

  rlCheckRenderBatchLimit((rings + 2) * slices * 6)

  rlBegin(RL_TRIANGLES)
    rlColor4ub(col.r, col.g, col.b, col.a)

    for i as integer = 0 to rings + 1
      for j as integer = 0 to slices - 1
        rlVertex3f(cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)) * sin(DEG2RAD * (j * 360.0f / slices)), _
                   sin(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)), _
                   cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)) * cos(DEG2RAD * (j * 360.0f / slices)))
        
        rlVertex3f(cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))) * sin(DEG2RAD * ((j + 1) * 360.0f / slices)), _
                   sin(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))), _
                   cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))) * cos(DEG2RAD * ((j + 1) * 360.0f / slices)))
        
        rlVertex3f(cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))) * sin(DEG2RAD * (j * 360.0f / slices)), _
                   sin(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))), _
                   cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))) * cos(DEG2RAD * (j * 360.0f / slices)))

        rlVertex3f(cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)) * sin(DEG2RAD * (j * 360.0f / slices)), _
                   sin(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)), _
                   cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)) * cos(DEG2RAD * (j * 360.0f / slices)))
        
        rlVertex3f(cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)) * sin(DEG2RAD * ((j + 1) * 360.0f / slices)), _
                   sin(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)), _
                   cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * i)) * cos(DEG2RAD * ((j + 1) * 360.0f / slices)))
        
        rlVertex3f(cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))) * sin(DEG2RAD * ((j + 1) * 360.0f / slices)), _
                   sin(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))), _
                   cos(DEG2RAD * (270 + (180.0f / (rings + 1)) * (i + 1))) * cos(DEG2RAD * ((j + 1) * 360.0f / slices)))
      next
    next
  rlEnd()
End Sub