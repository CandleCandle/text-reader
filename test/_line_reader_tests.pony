
// Q1:
// should read_line return the remaining bytes when has_line
// has returned false? - no, because then you can't distinguish
// between a partially provided line and end-of-stream
// hence providing read_remaining.

use "ponytest"
use "../text-reader"

primitive _TestLineReader is TestWrapped
	fun all_tests(): Array[UnitTest iso] =>
		[as UnitTest iso:

object iso is UnitTest
	fun name():String => "line-reader/initial"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		h.assert_eq[Bool](false, undertest.has_line())
		h.assert_eq[USize](0, undertest.available())
end

object iso is UnitTest
	fun name():String => "line-reader/apply-updates"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply([0x20;0x20;0xd;0xa])
		h.assert_eq[USize](4, undertest.available())
		h.assert_eq[USize](1, undertest.line_count())
		h.assert_eq[Bool](true, undertest.has_line())
end

object iso is UnitTest
	fun name():String => "line-reader/read-line-decrements"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply([0x20;0x20;0xd;0xa])
		let line: String = undertest.read_line()
		h.assert_eq[USize](0, undertest.available())
		h.assert_eq[String]("  ", line)
		h.assert_eq[Bool](false, undertest.has_line())
end
object iso is UnitTest
	fun name():String => "line-reader/trailing"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply([0x20;0xd;0xa;0x65])
		let line: String = undertest.read_line()
		h.assert_eq[USize](1, undertest.available())
		h.assert_eq[String](" ", line)
		h.assert_eq[Bool](false, undertest.has_line())
//		let line': String = undertest.read_remaining()
//		h.assert_eq[String]("A", line')
end

object iso is UnitTest
	fun name():String => "line-reader/split-separator"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply([0x20;0xd])
		undertest.apply([0xa;0x65])
		let line: String = undertest.read_line()
		h.assert_eq[String](" ", line)
//		let line': String = undertest.read_remaining()
//		h.assert_eq[String]("A", line')
end

object iso is UnitTest
	fun name():String => "line-reader/one-byte-at-a-time"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		for c in "One at a time.\r\n".array().values() do
			undertest.apply([c])
		end
		let line: String = undertest.read_line()
		h.assert_eq[String]("One at a time.", line)
end

object iso is UnitTest
	fun name():String => "line-reader/multiple-lines"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply("multiple\r\nlines\r\nin\r\none\r\ninput\r\n".array())
		let expected = ["multiple"; "lines"; "in"; "one"; "input"]
		for (i, e) in expected.pairs() do
			h.assert_eq[String](e, undertest.read_line(), "index: "+i.string()+" "+e)
		end
end

object iso is UnitTest
	fun name():String => "line-reader/multiple-inputs"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply("multiple ".array())
		undertest.apply("inputs ".array())
		undertest.apply("on ".array())
		undertest.apply("one ".array())
		undertest.apply("line\r\n".array())
		let line: String = undertest.read_line()
		h.assert_eq[String]("multiple inputs on one line", line)
end

object iso is UnitTest
	fun name():String => "line-reader/remaining-bytes"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply("lines\r\n".array())
		undertest.apply("with trailing bytes".array())
		h.assert_eq[String]("lines", undertest.read_line())
		let remaining: Array[ByteSeq] val = undertest.remaining()
		h.assert_eq[USize](1, remaining.size())
		try
			h.assert_array_eq[U8]("with trailing bytes".array(), remaining(0)?)
		end
end

object iso is UnitTest
	fun name():String => "line-reader/partial-remaining-bytes"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply("lines\r\nwith trailing bytes".array())
		h.assert_eq[String]("lines", undertest.read_line())
		let remaining: Array[ByteSeq] val = undertest.remaining()
		h.assert_eq[USize](1, remaining.size())
		try
			h.assert_array_eq[U8]("with trailing bytes".array(), remaining(0)?)
		end
end

object iso is UnitTest
	fun name():String => "line-reader/complete-example"
	fun apply(h: TestHelper) =>
		let undertest = LineReader
		undertest.apply("this is an\r\nexample ".array())
		undertest.apply("that\r\n".array())
		undertest.apply("should exibit ".array())
		undertest.apply("multiple\r\nedge\r".array())
		undertest.apply("\nca".array())
		undertest.apply("s".array())
		undertest.apply("e".array())
		undertest.apply("".array())
		undertest.apply("s".array())
		undertest.apply("\r".array())
		undertest.apply("\n".array())

		let expected = ["this is an"; "example that"; "should exibit multiple"; "edge"; "cases"]
		for (i, e) in expected.pairs() do
			h.assert_eq[String](e, undertest.read_line(), "index: "+i.string()+" "+e)
		end
end

]

// vi: sw=4 sts=4 ts=4 noet
