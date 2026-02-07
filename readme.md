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

