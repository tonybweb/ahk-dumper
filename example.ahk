#Requires AutoHotkey v2.0

#Include ".\Dumper.ahk"

str := "string"
dump(str)

ary := [1, 2, 3]
dump(ary)

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

MsgBox(dumpToString(obj), "obj converted to string output")