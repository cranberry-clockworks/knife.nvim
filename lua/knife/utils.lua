return {
    --- Searches a window handle by given buffer handle.
    -- @param buffer: A buffer handle.
    -- @returns number: A window handle.
    vim_buf_get_win = function (buffer)
        buffer = buffer or 0
        if buffer == 0 then
            return vim.api.nvim_get_current_win()
        end
        for _, window in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(window) == buffer then
                return window
            end
        end
        error(string.format("Can't find a window handle with buffer id: %d", buffer))
    end
}
