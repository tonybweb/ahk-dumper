# Dumper
An AutoHotkey V2 variable dumping tool for debugging and development.

## Features
- nice indented formatting for object
- console output
- string output
- recursion protection
- dump and exit app support

## Examples
## Console Output
```
str := "foobar"
dump(str)

>
"foobar"
```
```
i := 1234
dump(i)

>
1234
```
```
ary := [1, 2, 3]
dump(ary)

>
{
  [1]: 1,
  [2]: 2,
  [3]: 3
}
```
```
obj := ary
obj.helloWorld := {
  foo: "bar",
  bar: [1, 2],
  baz: "asdf",
}
obj.objInObj := obj ;recursion protected
dump(obj)

>
{
  [1]: 1,
  [2]: 2,
  [3]: 3,
  helloWorld: {
    bar: {
      [1]: 1,
      [2]: 2
    },
    baz: "asdf",
    foo: "bar"
  },
  objInObj: *RECURSION PROTECTED*
}
```
### String Output
```
MsgBox(dumpToString(obj), "obj converted to string output")
```
![dumpToString Screenshot](dumpToString.png)
### Dump and Exit App
```
dumpAndExit("asdf")

>
asdf
```
### Multiple Variables at Once
```
dump(str, i, ary, obj)
```