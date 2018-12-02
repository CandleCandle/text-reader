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

