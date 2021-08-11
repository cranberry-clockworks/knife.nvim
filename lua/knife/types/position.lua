-- @class Position
--- Represents position in (0, 0) indexing.
-- @field row number: A row number starting from 0.
-- @field column number: A column number starting from 0.
local Position = {}
local PositionImpl = {__index = Position}

function Position.new(ts_row, ts_column)
    return setmetatable({
        row = ts_row,
        column = ts_column
    }, PositionImpl)
end

function Position.from_cursor(buffer)
    local utils = require('knife.utils')
    local window = utils.vim_buf_get_win(buffer)
    local vim_row, vim_column = unpack(vim.api.nvim_win_get_cursor(window))
    return Position.new(vim_row - 1, vim_column)
end

return Position
