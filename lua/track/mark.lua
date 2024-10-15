local Mark = {}

local id_count = 0

-- % new %
function Mark:new(file_path, lnum, text)
	id_count = id_count + 1

	local instance = {
		_id = id_count,
		_text = text,
		_file_path = file_path,
		_lnum = lnum,
	}

	setmetatable(instance, {
		__index = Mark,
	})

	return instance
end

-- % get_id %
function Mark:get_id()
	return self._id
end

-- % get_text %
function Mark:get_text()
	return self._text
end

-- % get_lnum %
function Mark:get_lnum()
	return self._lnum
end

-- % get_relative_file_path %
function Mark:get_relative_file_path(root_dir)
	if not root_dir then
		return self._file_path
	end

	local relative_file_path = string.match(self._file_path, "^" .. root_dir .. "/(.*)$")
	if not relative_file_path then
		error("invalid root directory path")
	end
	return relative_file_path
end

-- % set_text %
function Mark:set_text(text)
	self._text = text
end

return Mark
