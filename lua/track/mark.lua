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

-- % to_string %
function Mark:to_string()
	return vim.json.encode({
		id = self._id,
		text = self._text,
		file_path = self._file_path,
		lnum = self._lnum,
	})
end

-- % from_string %
-- TODO: from_string
function Mark:from_string(str)
	local data = vim.json.decode(str)
	return Mark:new(data.id, data.file_path, data.lnum, data.text)
end

return Mark
