#Requires AutoHotkey v2

#Include "RichDumper.ahk"

OnError RichDumperLogError
RichDumperLogError(exception, mode) {
  return richDumper.captureError(exception, mode)
}
