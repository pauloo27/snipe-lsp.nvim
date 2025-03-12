local M = {}

--- add an escape keymap to the menu
--- @param menu table snipe menu instance
--- @return nil
M.add_close_keymap = function(menu)
	menu:add_new_buffer_callback(function(m)
		vim.keymap.set("n", "<esc>", function()
			m:close()
		end, { nowait = true, buffer = m.buf })
	end)
end

return M
