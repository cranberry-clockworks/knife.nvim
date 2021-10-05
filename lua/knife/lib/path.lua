-- @class Path
--- Represents a path to the file.
-- @field directory string: A path to the directory contains the file. Could be nil if the path
-- specified for the file in the current working directory.
-- @field file string: A path to the file. Could be nil if the path is specified for the directory.
local Path = {}
local PathImpl = {
   __index = Path
}

-- @class
--- Represents a filename in the path.
-- @field name string: The filename without extension. Could be empty.
-- @field extension string: The extension of the file. Could be empty or nil if the extension is
-- not present.
local FileName = {}
local FileNameImpl = {
    __index = FileName
}

local separator = package.config:sub(1, 1)

--- Splits a string into two by given character
-- @param str string: The string to split.
-- @param char character: A character used to perform split.
-- @returns (string, string): A tuple of strings. If no split character was found (str, nil) is
-- returned. One of the two strings could be empty depending the case.
local function split(str, char)
    local i = #str
    for c in str:reverse():gmatch('.') do
        if (c == char) then
            return str:sub(1, i - 1), str:sub(i + 1, #str)
        end

        i = i - 1
    end

    return str, nil
end

function FileName.parse(filename)
    local name, extension = split(filename, '.')
    return setmetatable({
        name = name,
        extension = extension
    }, FileNameImpl)
end

--- Gets the name of the file with extension
-- @returns string: the filename with extension.
function FileName:fullname()
    if (self.extensions ~= nil) then
        return self.name .. '.' .. self.extensions
    end

    return self.name
end

function Path.parse(path)
    local dir, file = split(path, separator)

    if dir == nil or #dir == 0 then
        dir = nil
    end

    if (file ~= nil) then
        file = FileName.parse(file)
    end

    return setmetatable({
        directory = dir,
        file = file,
    }, PathImpl)
end

--- Returns full path to the file.
-- @returns string: The full path to the file.
function Path:to_string()
    dir = self.directory or ''
    if self.file ~= nil then
        return dir .. separator .. self.file:fullname()
    end

    return dir
end

return Path
