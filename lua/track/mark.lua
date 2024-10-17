local Mark = {}

-- % new %
function Mark:new(id, file_path, lnum, text)
	local instance = {
		_id = id,
		_text = text,
		_file_path = file_path,
		_lnum = lnum,
	}

	setmetatable(instance, { __index = Mark })

	return instance
end

-- % id %
function Mark:get_id()
	return self._id
end

-- % text %
function Mark:get_text()
	return self._text
end

function Mark:set_text(text)
	self._text = text
end

-- % lnum %
function Mark:get_lnum()
	return self._lnum
end

function Mark:set_lnum(lnum)
	self._lnum = lnum
end

-- % file_path %
function Mark:get_file_path()
	return self._file_path
end

function Mark:set_file_path(file_path)
	self._file_path = file_path
end

return Mark
