# Proyectos TDD - Desarrollo Movil Integral

| Carpeta | Proyecto | Pruebas |
|---|---|---|
| punto_venta_dolores | Punto de venta con SQLite | test/dominio_test.dart, test/datos_test.dart |
| tanda_dolorena | Ahorro rotativo vecinal | test/servicio_tanda_test.dart |
| nieves_2048 | Juego de fusion 2048 | test/motor_2048_test.dart, test/grid_test.dart, test/motor_juego_test.dart |

## Primera vez (una sola vez)
    cd proyectos_tdd
    powershell -ExecutionPolicy Bypass -File .\preparar.ps1

## Correr las pruebas de los 3
    powershell -ExecutionPolicy Bypass -File .\probar_todo.ps1

## Correr las pruebas de uno solo
    cd tanda_dolorena
    flutter test

## Ejecutar una app (entrar primero a su carpeta)
    cd nieves_2048
    flutter run -d windows

Cambia nieves_2048 por tanda_dolorena o punto_venta_dolores.
Para ver dispositivos disponibles: flutter devices
