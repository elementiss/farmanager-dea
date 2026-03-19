# Lua-скрипты для Far Manager

[English version of README](readme.md)

## Highlight css colors

Скрипт для Far Manager, который подсвечивает цвета #RRGGBB, #RRGGBBAA, rgb(), rgba() в редакторе.

<img src="Highlight%20css%20colors/highlight-colors1.png" width="53%" alt="ex1"> <img src="Highlight%20css%20colors/highlight-colors2.png" width="13%" alt="ex1">

## Editor Stats

Этот скрипт подсчитывает строки, символы, слова и байты в редакторе, отображая статистику для текущего выделения и строки.

<img width="55%" alt="Editor Stats" src="https://github.com/user-attachments/assets/aeafd94d-558c-42f1-a6f8-a9e36e719f3a" />

`CtrlShiftS`


## SaveAndRun

SaveAndRun — это Lua-скрипт для Far Manager, который выполняет команды в зависимости от расширения редактируемого файла, указанного в конфигурационном файле. Он отображает вывод команды (stdout и stderr) в меню, позволяя переходить к строкам с ошибками в редакторе. Кроме того, поддерживает форматирование файлов с использованием настраиваемых инструментов.

[Подробнее...](./SaveAndRun/)

## EditorBackup

Скрипт для Far Manager, который создает резервные копии файла при сохранении файла в редакторе.
Выполняется ротация резервных копий таким образом, что последняя копия имеет номер 1, предпоследняя копия имеет номер 2 и т.д.

Можно задать ограничения, для каких типов файлов делать копии, максимальное количество копий файла, папку для копий.

[Подробнее...](./EditorBackup/)
