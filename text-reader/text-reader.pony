use "collections"
use "format"

class BufferElement
	// the role of this class is to contain the array buffers and know where
	// the separators are and which bytes have been consumed.
	let buffer: Array[U8] val
	var position: USize = 0 // current position in the buffer
	let _separators: Array[USize] val
	var separator_idx: USize // current position in the _separatoes array.
	let _uid: USize

	new create(uid: USize, buffer': Array[U8] val, separators': Array[USize] val) =>
		_uid = uid
		buffer = buffer'
		position = 0
		separator_idx = 0
		_separators = separators'

	fun box consumed(): Bool =>
		position >= buffer.size()

	fun box copy_to(): (USize, Bool) =>
		if separator_idx >= _separators.size() then
			(buffer.size(), false)
		else
			try (_separators(separator_idx)?, true) else (0, true) end
		end

	fun box string(): String iso^ =>
		let result: String iso = recover String end
		result.append("index = ")
		result.append(Format.int[USize](_uid where width=10, fmt=FormatHex, align=AlignRight))
		result.append(", size = ")
		result.append(Format.int[USize](buffer.size() where width=10, fmt=FormatHex, align=AlignRight))
		result.append(", position = ")
		result.append(Format.int[USize](position where width=10, fmt=FormatHex, align=AlignRight))
		result.append(", separator_idx = ")
		result.append(Format.int[USize](separator_idx where width=10, fmt=FormatHex, align=AlignRight))
		result.append(", separators = [")
		var first = true
		for sep in _separators.values() do
			if not first then result.append("; ") end
			result.append(Format.int[USize](sep where fmt=FormatHex))
			first = false
		end
		result.append("], [")
		first = true
		for b in buffer.values() do
			if not first then result.append(" ") end
			result.append(Format.int[U8](b where width=2, fmt=FormatHex, align=AlignRight, prec=2))
			first = false
		end
		result.append("]")
		result

class LineReader
	// The role of this class is to contain the external interface
	let _buffer: List[BufferElement] = List[BufferElement]()
	var _available: USize = 0
	var _lines: USize = 0
	let _separator: Array[U8] val = [0xd;0xa]
	var _uid: USize = 0

	fun ref apply(arr: Array[U8] val) =>
		// if there's the beginning of a separator at the end of this `arr` then add it as an additional separator
		// count the number of bytes of the separator that are in the previous `arr`, look for the remaining
		// parts of the separator at the beginning of this `arr`, if found, increment the `position` to point to
		// beyond the separator. This may cause the `arr` to be consumed. Only push it into `_buffer` if not consumed.

		var sep = ArraySearch.indexes_of(arr, _separator)

		(let trailing_position, let trailing_length) = ArraySearch.trailing_prefix(arr, _separator)
		if (trailing_length > 0) and (trailing_length < _separator.size()) then
			sep = recover val
				let sep' = sep.clone()
				sep'.>push(trailing_position)
			end
		end

		let seperator_count = sep.size()
		let element = BufferElement.create(_uid, arr, sep)

		(let leading_position, let leading_length) = ArraySearch.leading_suffix(arr, _separator)
		if (leading_length > 0) and (leading_length < _separator.size()) then
			element.position = leading_length
		end

		if not element.consumed() then
			_buffer.push(element)
			_uid = _uid + 1
			_available = _available + arr.size()
			_lines = _lines + seperator_count
		end

	fun box available(): USize => _available

	fun box has_line(): Bool => _lines > 0

	fun box line_count(): USize =>
		"""
		returns the number of complete lines that can be read from the buffer.
		"""
		_lines

	fun ref read_line(): String =>
		try
			let s: String iso = recover iso String.create() end // TODO pre-calculate the expected size of the string.
			var current: BufferElement = _buffer.head()?()?
			while not current.consumed() do
				(let copy_to, let line) = current.copy_to()

				s.append(current.buffer, current.position, copy_to-current.position)
				current.position = copy_to + _separator.size()
				current.separator_idx = current.separator_idx + 1
				if current.consumed() then
					_buffer.shift()?
					if _buffer.size() > 0 then
						current = _buffer.head()?()?
					end
				end
				if line then break end
			end
			_lines = _lines - 1
			_available = (_available - s.size()) - _separator.size()
			s
		else
			""
		end

	fun ref remaining(): Array[ByteSeq] val =>
		let size = _buffer.size()
		let result: Array[ByteSeq] iso = recover iso Array[ByteSeq](size) end
		for b in _buffer.values() do
			if b.position != 0 then
				result.push(recover val b.buffer.slice(b.position, b.buffer.size()) end)
			else
				result.push(b.buffer)
			end
		end
		_buffer.clear()
		_lines = 0
		_available = 0
		result

primitive ArraySearch
	// the role of this primitive is to encapsulate the array searching functions in a
	// easily testable way.

	fun index_of(haystack: Array[U8] val, needle: Array[U8] val, haystack_offset: USize = 0, needle_offset: USize = 0): USize =>
		"""
		returns the next index of the needle after offset.
		if needle does not exist then the result will be >= haystack.size()
		UB when haystack.size() == USize.max
		"""
		var haystack_idx: USize = haystack_offset
		var needle_idx: USize = needle_offset
		try
			while haystack_idx < haystack.size() do
				if haystack(haystack_idx)? == needle(needle_idx)? then
					if (needle_idx+1) >= needle.size() then
						return haystack_idx - (needle_idx - needle_offset)
					end
					needle_idx = needle_idx + 1
				else
					needle_idx = needle_offset // reset when not found
				end
				haystack_idx = haystack_idx + 1
			end
		end
		haystack_idx

	fun count_needles(haystack: Array[U8] val, needle: Array[U8] val): USize =>
		if haystack.size() < needle.size() then return 0 end
		indexes_of(haystack, needle).size()

	fun indexes_of(haystack: Array[U8] val, needle: Array[U8] val): Array[USize] val =>
		if haystack.size() < needle.size() then return [as USize: ] end
		let result: Array[USize] iso = recover Array[USize]() end
		var haystack_idx: USize = 0
		while haystack_idx < haystack.size() do
			let found = ArraySearch.index_of(haystack, needle, haystack_idx)
			if found < haystack.size() then
				result.push(found)
			end
			haystack_idx = found + needle.size()
		end
		result

	fun leading_suffix(haystack: Array[U8] val, needle: Array[U8] val): (USize, USize) =>
		"""
		returned tuple entries:
			1: position in the needle for starting the needle suffix
			2: length of the needle suffix found

		note: probably does not need to return a tuple as given the size of the needle, one of the entries can be calculated from the other.
		"""
		if (haystack.size() == 0) or (needle.size() == 0) then return (0, 0) end
		for (needle_idx, unused) in needle.pairs() do
			let suffix = recover val needle.slice(needle_idx, needle.size()) end
			let ret = index_of(haystack, suffix)
			if ret == 0 then
				return (needle_idx, suffix.size())
			end
		end
		(0, 0)

	fun trailing_prefix(haystack: Array[U8] val, needle: Array[U8] val): (USize, USize) =>
		"""
		returned tuple entries:
			1: position in the haystack for starting the needle prefix
			2: length of the needle found

		note: probably does not need to return a tuple as given the size of the needle and size of the haystack, one of the entries can be calculated from the other.
		"""
		if (haystack.size() == 0) or (needle.size() == 0) then return (0, 0) end
		for (needle_idx, unused) in needle.pairs() do
			let prefix = recover val needle.slice(0, needle.size()-needle_idx) end
			let ret = index_of(haystack, prefix, haystack.size()-prefix.size())
			var offset = haystack.size()-prefix.size()
			if offset >= haystack.size() then continue end // offset can be "-ive" when haystack.size() < needle.size() (note that given the numbers are all unsigned, offset will be very large, hence the >=)

			if ret == offset then
				return (offset, prefix.size())
			end
		end
		(0, 0)




