local M = {}

--- Prepends given string to the each line in the table.
-- @param lines table: A table of the strings. Each item represents line of the document.
-- @param prefix string: A string that prepended to each item in the table.
function M.prefix_with(lines, prefix)
    for i, line in ipairs(lines) do
        lines[i] = prefix .. line
    end
end

function M.buf_get_first_n_chars_from_line(buffer, line, n)
    local l = vim.api.nvim_buf_get_lines(buffer, line, line + 1, true)[1]
    return string.sub(l, 1, n)
end

return M;
