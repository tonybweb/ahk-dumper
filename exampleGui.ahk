#Requires AutoHotkey v2.1-a
#Include ".\DumperGui.ahk"

dump.gui.addToSysTray().setHotkey("F1")

str := "string"
dump.gui(str)

ary := [1, 2, 3]
dump.gui(ary)

aryMap := Map("foo", "bar", "asdf", "jkl;")
dump.gui(aryMap)

i := 1234
dump.gui(i)

hex := 0xFF0000
dump.gui(hex)

obj := ary
obj.helloWorld := {
  foo: "bar",
  bar: [1, 2],
  baz: "asdf",
}
obj.objInObj := obj ;recursion protected
dump.gui(obj)