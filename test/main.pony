

use "ponytest"
use "../text-reader"

actor Main is TestList
	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestInitialState)
		test(_TestApplyUpdates)
		test(_TestReadDecrements)

class iso _TestInitialState is UnitTest
	fun name():String => "line-reader/initial"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		h.assert_eq[Bool](false, undertest.has_line())
		h.assert_eq[USize](0, undertest.available())

class iso _TestApplyUpdates is UnitTest
	fun name():String => "line-reader/apply-updates"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply([0x20;0x20;0x13;0x10])
		h.assert_eq[USize](4, undertest.available())
		h.assert_eq[USize](1, undertest.line_count())
		h.assert_eq[Bool](true, undertest.has_line())

class iso _TestReadDecrements is UnitTest
	fun name():String => "line-reader/read-line-decrements"
	fun apply(h: TestHelper) =>
	let undertest = LineReader
		undertest.apply([0x20;0x20;0x13;0x10])
		let line: String = undertest.read_line()
		h.assert_eq[USize](0, undertest.available())
		h.assert_eq[String]("  ", line)
		h.assert_eq[Bool](false, undertest.has_line())

/*


		undertest.apply([0x20;0x13;0x10])
		h.assert_eq[Bool](true, undertest.has_line())
		h.assert_eq[USize](3, undertest.available())
		undertest.apply([0x20])
		h.assert_eq[USize](4, undertest.available())
		h.assert_eq[Bool](true, undertest.has_line())
		let line: String = undertest.read_line()
		h.assert_eq[USize](0, undertest.available())
		h.assert_eq[String]("  ", line)
		h.assert_eq[Bool](false, undertest.has_line())

class iso _Test3 is UnitTest
	fun name():String => "3"
	fun apply(h: TestHelper) =>
	let undertest = LineReader
		undertest.apply([0x20;0x13])
		undertest.apply([0x10;0x20])

class iso _Test4 is UnitTest
	fun name():String => "4"
	fun apply(h: TestHelper) =>
	let undertest = LineReader
		undertest.apply([0x20])
		undertest.apply([0x13;0x10;0x20])

class iso _Test5 is UnitTest
	fun name():String => "5"
	fun apply(h: TestHelper) =>
	let undertest = LineReader
		undertest.apply([0x20;0x13;0x20;0x13;0x10])
		undertest.apply([0x20;0x10;0x13;0x20;0x13;0x10])
		undertest.apply([0x13;0x10;0x20;])
		undertest.apply([0x20;0x13;0x10;0x20;])











*/
