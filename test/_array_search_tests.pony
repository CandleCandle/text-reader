use "ponytest"
use "../text-reader"

actor _ArraySearchTests is TestList
	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestOne)
		test(_TestTwo)
		test(_TestThree)
		test(_TestFour)
		test(_TestFive)
		test(_TestSix)
		test(_TestSeven)
		test(_TestEight)
		test(_TestNine)
		test(_TestTen)
		test(_TestFoundTrailingPrefix1)
		test(_TestFoundTrailingPrefix2)
		test(_TestFoundTrailingComplete)
		test(_TestNotFoundTrailing)
		test(_TestFoundSuffix1)
		test(_TestFoundSuffix2)
		test(_TestFoundCompleteSuffix)
		test(_TestNotFoundSuffix)

class iso _TestOne is UnitTest
	fun name():String => "array-search/index/basic"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.index_of(
				"search in here".array(),
				"arch".array()
			)
		h.assert_eq[USize](2, result)

class iso _TestSeven is UnitTest
	fun name():String => "array-search/index/prefix-first"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.index_of(
				"hear the hair here".array(),
				"here".array()
			)
		h.assert_eq[USize](14, result)

class iso _TestTwo is UnitTest
	fun name():String => "array-search/index/repeated"
	fun apply(h: TestHelper) =>
		let result1 = ArraySearch.index_of(
				"search in here".array(),
				"e".array()
			)
		h.assert_eq[USize](1, result1)
		let result2 = ArraySearch.index_of(
				"search in here".array(),
				"e".array()
				where haystack_offset = 2
			)
		h.assert_eq[USize](11, result2)

class iso _TestThree is UnitTest
	fun name():String => "array-search/index/first"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.index_of(
				"search in here".array(),
				"sea".array()
			)
		h.assert_eq[USize](0, result)

class iso _TestFour is UnitTest
	fun name():String => "array-search/index/not-found"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.index_of(
				"search in here".array(),
				"z".array()
			)
		h.assert_true(13 < result)

class iso _TestFive is UnitTest
	fun name():String => "array-search/index/not-found/prefix"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.index_of(
				"search in here".array(),
				"heretic".array()
			)
		h.assert_true(13 < result)

class iso _TestSix is UnitTest
	fun name():String => "array-search/index/not-found/suffix"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.index_of(
				"tic and you will find ...".array(),
				"heretic".array()
				where needle_offset = 4
			)
		h.assert_eq[USize](0, result)

class iso _TestEight is UnitTest
	fun name():String => "array-search/indexes/single"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.indexes_of(
				"search in here".array(),
				"a".array()
			)
		h.assert_array_eq[USize]([as USize: 2], result)

class iso _TestNine is UnitTest
	fun name():String => "array-search/indexes/multiple"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.indexes_of(
				"search in here".array(),
				"e".array()
			)
		h.assert_array_eq[USize]([as USize: 1; 11; 13], result)

class iso _TestTen is UnitTest
	fun name():String => "array-search/indexes/long"
	fun apply(h: TestHelper) =>
		let result = ArraySearch.indexes_of(
				"search in here".array(),
				"ea".array()
			)
		h.assert_array_eq[USize]([as USize: 1], result)

class iso _TestFoundTrailingPrefix1 is UnitTest
	fun name():String => "array-search/trailing/prefix/found/1"
	fun apply(h: TestHelper) =>
		(let location, let length) = ArraySearch.trailing_prefix(
				"search in here".array(),
				"rear".array()
				)
		h.assert_eq[USize](12, location)
		h.assert_eq[USize](2, length)

class iso _TestFoundTrailingPrefix2 is UnitTest
	fun name():String => "array-search/trailing/prefix/found/2"
	fun apply(h: TestHelper) =>
		(let location, let length) = ArraySearch.trailing_prefix(
				"a".array(),
				"at".array()
				)
		h.assert_eq[USize](0, location)
		h.assert_eq[USize](1, length)

class iso _TestFoundTrailingComplete is UnitTest
	fun name():String => "array-search/trailing/prefix/found/complete-match"
	fun apply(h: TestHelper) =>
		(let location, let length) = ArraySearch.trailing_prefix(
				"search in here".array(),
				"here".array()
				)
		h.assert_eq[USize](10, location)
		h.assert_eq[USize](4, length)

class iso _TestNotFoundTrailing is UnitTest
	fun name():String => "array-search/trailing/prefix/not-found"
	fun apply(h: TestHelper) =>
		(let location, let length) = ArraySearch.trailing_prefix(
				"search in here".array(),
				"no".array()
				)
		h.assert_eq[USize](0, location)
		h.assert_eq[USize](0, length)

class iso _TestFoundSuffix1 is UnitTest
	fun name():String => "array-search/leading/suffix/partial-found/1"
	fun apply(h: TestHelper) =>
		(let location, let length) = ArraySearch.leading_suffix(
				"search in here".array(),
				"noise".array()
				)
		h.assert_eq[USize](3, location)
		h.assert_eq[USize](2, length)

class iso _TestFoundSuffix2 is UnitTest
	fun name():String => "array-search/leading/suffix/partial-found/2"
	fun apply(h: TestHelper) =>
		(let location, let length) = ArraySearch.leading_suffix(
				"e".array(),
				"se".array()
				)
		h.assert_eq[USize](1, location)
		h.assert_eq[USize](1, length)

class iso _TestFoundCompleteSuffix is UnitTest
	fun name():String => "array-search/leading/suffix/complete-found"
	fun apply(h: TestHelper) =>
		(let location, let length) = ArraySearch.leading_suffix(
				"search in here".array(),
				"sea".array()
				)
		h.assert_eq[USize](0, location)
		h.assert_eq[USize](3, length)

class iso _TestNotFoundSuffix is UnitTest
	fun name():String => "array-search/leading/suffix/not-found"
	fun apply(h: TestHelper) =>
		(let location, let length) = ArraySearch.leading_suffix(
				"search in here".array(),
				"no".array()
				)
		h.assert_eq[USize](0, location)
		h.assert_eq[USize](0, length)


