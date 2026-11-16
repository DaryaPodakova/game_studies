@echo off
rem Запуск уровня. Нужен Godot 4.7.x.
rem Путь к Godot берётся из переменной окружения GODOT, иначе из PATH (команда godot).
if not defined GODOT set GODOT=godot
"%GODOT%" --path "%~dp0"
