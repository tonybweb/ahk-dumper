#Requires AutoHotkey v2.0
#Include ".\RichDumper.ahk"

str := "string"
dump(str)
OutputDebug(dumpString(str))

ary := [1, 2, 3]
dump(ary)

aryMap := Map("foo", "bar", "asdf", "jkl;")
dump(aryMap)

i := 1234
dump(i)

hex := 0xFF0000
dump(hex)

obj := ary
obj.helloWorld := {
  foo: "bar",
  bar: [1, 2],
  baz: "asdf",
}
obj.objInObj := obj ;recursion protected
dump(obj)

dumpMsgBox(obj)
dumpGui(obj)