use "ponytest"
use "../text-reader"

actor Main is TestList
	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		_LineReaderTests.make().tests(test)
		_ArraySearchTests.make().tests(test)
		_BufferElementTests.make().tests(test)


