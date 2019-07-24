use "ponytest"
use "../text-reader"

actor Main is TestList
	new create(env: Env) =>
		PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		TestWrapper.tests(_TestLineReader, test)
		TestWrapper.tests(_TestBufferElement, test)
		TestWrapper.tests(_TestArraySearch, test)

trait TestWrapped
	fun all_tests(): Array[UnitTest iso]

actor TestWrapper
	fun tag tests(wrapped: TestWrapped val, test: PonyTest) =>
		let tests' = wrapped.all_tests()
		while tests'.size() > 0 do
			try test(tests'.pop()?) end
		end

// vi: sw=4 sts=4 ts=4 noet