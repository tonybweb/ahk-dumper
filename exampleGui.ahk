#Requires AutoHotkey v2.1-a
#Include "example.ahk"
#Include "RichDumper.ahk"

RichDumper.addToSysTray().setHotkey("F1")

dumpGui(obj)