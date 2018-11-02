use "collections"


//class _LineBuffer
//	let _buffer: Array[U8] val
//	let _offsets: Array[USize] val
//	var _current: USize = 0

	// append_to(str: String iso): String iso
	// is_consumed(): Bool

//	fun remaining(): USize =>
//		"""
//		number of bytes remaining to be read in the _buffer.
//		"""
//		0

class LineReader
	let _buffer: List[Array[U8] val] = List[Array[U8] val]()
	var _available: USize = 0
	var _offset: USize = 0
	var _lines: USize = 0
	let _separator: Array[U8] val = [0x13;0x10]

	fun ref apply(arr: Array[U8] val) =>
		_buffer.push(arr)
		_available = _available + arr.size()
		_lines = _lines + _count_separators(arr, _separator)

	fun box available(): USize => _available

	fun box has_line(): Bool => _lines > 0

	fun box line_count(): USize => _lines

	fun ref read_line(): String =>
		try
			let current = _buffer.head()?.apply()?
			let next_index = _index_of(current, _separator, _offset)
			var str: String iso = recover iso String(42) end // TODO pre-calculate the size.
			if next_index < current.size() then
				@printf[None]("next: %d, current offset: %d\n".cstring(), next_index, _offset)
				str.append(current, _offset, next_index - _offset)
				_offset = next_index + _separator.size()
				if _offset > current.size() then _offset = 0 end
				_available = (_available - str.size()) - _separator.size()
				_lines = _lines - 1
			end
			consume str
		else
			""
		end

	fun tag _index_of(haystack: Array[U8] val, needle: Array[U8] val, offset: USize): USize =>
		"""
		returns the next index of the needle after offset.
		if needle does not exist then the result will be >= haystack.size()
		UB when haystack.size() == USize.max
		"""
		var haystack_idx: USize = offset
		var needle_idx: USize = 0
		try
			while haystack_idx < haystack.size() do
				@printf[None]("h: %x n: %x hi: %d ni: %d\n".cstring(), haystack(haystack_idx)?, needle(needle_idx)?, haystack_idx, needle_idx)
				if haystack(haystack_idx)? == needle(needle_idx)? then
					if (needle_idx+1) >= needle.size() then
						@printf[None]("found with hi: %d, ni: %d, ns: %d\n".cstring(), haystack_idx, needle_idx, needle.size())
						return haystack_idx - needle_idx
					end
					needle_idx = needle_idx + 1
				end
				haystack_idx = haystack_idx + 1
			end
		end
		haystack_idx

	fun tag _count_separators(haystack: Array[U8] val, needle: Array[U8] val): USize =>
		if haystack.size() < needle.size() then return 0 end
		var count: USize = 0
		var haystack_idx: USize = 0
		while haystack_idx < haystack.size() do
			let found = _index_of(haystack, needle, haystack_idx)
			if found < haystack.size() then
				count = count + 1
			end
			haystack_idx = found + needle.size()
		end
			/*
			var needle_idx: USize = 0
			while haystack_idx < haystack.size() do
				if haystack(haystack_idx)? == needle(needle_idx)? then
					needle_idx = needle_idx + 1
					if needle_idx >= needle.size() then
						count = count + 1
						needle_idx = 0
					end
				else
					needle_idx = 0
				end
				haystack_idx = haystack_idx + 1
			end
			*/
		count

