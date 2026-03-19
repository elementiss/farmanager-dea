# Lua Scripts for Far Manager

[![Github All Releases](https://img.shields.io/github/downloads/elementiss/farmanager-dea/total.svg)]()


[Русская версия README](readme.ru.md)

## SaveAndRun

SaveAndRun is a Lua script for Far Manager that executes commands based on the file extension of the edited file, as defined in a configuration file. It displays the command's output (stdout and stderr) in a menu, allowing navigation to error lines in the editor. Additionally, it supports file formatting with configurable tools.

[More...](./SaveAndRun/)

## EditorBackup

Script for Far Manager that creates backups of a file when saving it in the editor.
The backups are rotated so that the latest copy has the number 1, the second latest copy has the number 2, and so on.

You can set restrictions for which file types to create copies, the maximum number of file copies, and the folder for the copies.

[More...](./EditorBackup/)

## Highlight css colors

Script for Far Manager that hightlights #RRGGBB, #RRGGBBAA, rgb(), rgba() colors in the editor.

<img src="Highlight%20css%20colors/highlight-colors1.png" width="53%" alt="ex1"> <img src="Highlight%20css%20colors/highlight-colors2.png" width="13%" alt="ex1">

## Editor Stats

This script counts selected lines, characters, words, and bytes in the editor, displaying statistics for the current selection and line.

<img width="55%" alt="Editor Stats" src="https://github.com/user-attachments/assets/aeafd94d-558c-42f1-a6f8-a9e36e719f3a" />

`CtrlShiftS`
