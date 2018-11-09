use "collections"




class BufferElement
	// the role of this class is to contain the array buffers and know where
	// the separators are and which bytes have been consumed.
	let _buffer: Array[U8] val
	let _offsets: Array[USize] val
	var _position: USize = 0 // current position
	var _current: USize = 0 // index into _offsets
	let _separator_length: USize

	new create(buffer: Array[U8] val, separator_length: USize, offsets: Array[USize] val) =>
		_buffer = buffer
		_offsets = offsets
		_separator_length = separator_length

	fun ref append_to(str: String iso): String iso^ =>
		"""
		returns the string that was appended to; true if we read to an end-of-line
		"""
		try
			str.append(_buffer, _position, _offsets(_current)?-_position)
			_position = _offsets(_current)? + _separator_length
			_current = _current + 1
		end
		str

	fun continuation(): Bool =>
		false
		// return true if we appended our remaining buffer without 
		// reaching a `separator`

	fun remaining(): USize =>
		"""
		number of bytes remaining to be read in the _buffer.
		"""
		if _buffer.size() > _position then
			(_buffer.size() - _position)
		else
			0
		end

class LineReader
	// The role of this class is to contain the external interface
	let _buffer: List[BufferElement] = List[BufferElement]()
	var _available: USize = 0
	var _lines: USize = 0
	let _separator: Array[U8] val = [0x13;0x10]

	fun ref apply(arr: Array[U8] val) =>
		_buffer.push(BufferElement.create(arr, _separator.size(), recover val Array[USize](0) end))
		_available = _available + arr.size()
		// 
		_lines = _lines + ArraySearch.count_needles(arr, _separator)

	fun box available(): USize => _available

	fun box has_line(): Bool => _lines > 0

	fun box line_count(): USize =>
		"""
		returns the number of complete lines that can be read from the buffer.
		"""
		_lines

	fun ref read_line(): String ? =>
		// I don't like that this function is partial, however,
		// the patterns of:
		// foo = bar(consume foo)
		// and
		// foo' = bar( consume foo); foo = consume foo'
		// are unhappy when they are in a try block or a loop.

		// peak at HEAD
		// copy from HEAD's buffer to the result
		// if HEAD.remaining == 0 then shift it off the front
		// did the copy produce a full line?
		//   return the result.
		// otherwise
		//   goto start

		var str: String iso = recover iso String() end
		var head = _buffer.head()?()?
		str = head.append_to(consume str)
		while head.continuation() do
			_buffer.shift()?
			head = _buffer.head()?()?
			str = head.append_to(consume str)
		end
		str

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
				@printf[None]("h: %x n: %x hi: %d ni: %d\n".cstring(), haystack(haystack_idx)?, needle(needle_idx)?, haystack_idx, needle_idx)
				if haystack(haystack_idx)? == needle(needle_idx)? then
					if (needle_idx+1) >= needle.size() then
						@printf[None]("found with hi: %d, ni: %d, ns: %d\n".cstring(), haystack_idx, needle_idx, needle.size())
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
		var count: USize = 0
		var haystack_idx: USize = 0
		while haystack_idx < haystack.size() do
			let found = ArraySearch.index_of(haystack, needle, haystack_idx)
			if found < haystack.size() then
				count = count + 1
			end
			haystack_idx = found + needle.size()
		end
		count

