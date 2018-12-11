use "ponytest"
use "../text-reader"

actor _BufferElementTests is TestList
	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestFullyConsumed)
//		test(_TestPartiallyConsumed)
//		test(_TestRepeatConsume)
//		test(_TestPartialContent)

class iso _TestFullyConsumed is UnitTest
	fun name(): String => "buffer-element/fully-consumed"
	fun apply(h: TestHelper) =>
		let undertest = BufferElement(0, "fully-consumed\r\n".array(), [as USize: 14])

		(let copy_to, let line) = undertest.copy_to()
		h.assert_eq[USize](14, copy_to)
		h.assert_eq[Bool](true, line)
		h.assert_eq[Bool](false, undertest.consumed())

//class iso _TestPartiallyConsumed is UnitTest
//	fun name():String => "buffer-element/partially-consumed"
//	fun apply(h: TestHelper) =>
//		let undertest = BufferElement("partially\r\nconsumed\r\n".array(), 2, [as USize: 9; 19])
//		h.assert_eq[USize](21, undertest.remaining())
//		var str: String iso = recover iso String() end
//		undertest.append_to(str)
//		h.assert_eq[String iso](recover iso String().>append("partially") end, str)
//		h.assert_eq[USize](10, undertest.remaining())
//
//class iso _TestRepeatConsume is UnitTest
//	fun name():String => "buffer-element/repeat-consume"
//	fun apply(h: TestHelper) =>
//		let undertest = BufferElement("partially\r\nconsumed\r\n".array(), 2, [as USize: 9; 19])
//
//		h.assert_eq[USize](21, undertest.remaining())
//		var str: String iso = recover iso String() end
//		undertest.append_to(str)
//		h.assert_eq[String iso](recover iso String().>append("partially") end, str)
//
//		h.assert_eq[USize](10, undertest.remaining())
//		var str': String iso = recover iso String() end
//		undertest.append_to(str)
//		h.assert_eq[String iso](recover iso String().>append("consumed") end, str')
//		h.assert_eq[USize](0, undertest.remaining())
//
//class iso _TestPartialContent is UnitTest
//	fun name():String => "buffer-element/partial-content"
//	fun apply(h: TestHelper) =>
//		let undertest = BufferElement("partial conte...".array(), 2, [as USize: ])
//		h.assert_eq[USize](14, undertest.remaining())
//		var str: String iso = recover iso String() end
//		undertest.append_to(str)
//		h.assert_eq[String iso](String().>append("partial conte..."), str)
//		h.assert_eq[USize](0, undertest.remaining())
//		h.assert_true(undertest.continuation())
//
