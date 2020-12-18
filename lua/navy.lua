local api = vim.api
local buf, win
local position = 0

local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function split(str)
  chunks = {}
  for substring in str:gmatch("%S+") do
    table.insert(chunks, substring)
  end

  return chunks
end


local function open_window()
  buf = api.nvim_create_buf(false, true)
  local border_buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'filetype', 'whid')

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

  api.nvim_win_set_option(win, 'cursorline', true) -- it highlight line with the cursor on it

  -- we can add title already here, because first line will never change
  api.nvim_buf_set_lines(buf, 0, -1, false, { center('What\'s running?'), '', ''})
  api.nvim_buf_add_highlight(buf, -1, 'NavyHeader', 0, 0, -1)
end

local function update_view(direction)
  api.nvim_buf_set_option(buf, 'modifiable', true)
  position = position + direction
  if position < 0 then position = 0 end

  local result = vim.fn.systemlist('navy ps')
  if #result == 0 then table.insert(result, '') end -- add  an empty line to preserve layout if there is no results
  for k,v in pairs(result) do
    result[k] = '  '..result[k]
  end

  api.nvim_buf_set_lines(buf, 1, 2, false, {center('Hello Sailor 🚢')})
  api.nvim_buf_set_lines(buf, 3, -1, false, result)

  api.nvim_buf_add_highlight(buf, -1, 'NavySubHeader', 1, 0, -1)
  api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function close_window()
  api.nvim_win_close(win, true)
end

local function launch()
  local str = api.nvim_get_current_line()
  close_window()
  local chunks = split(str)
  print(chunks[2])
  api.nvim_command("silent! ! navy launch "..chunks[2])
  print(chunks[2] .. " launched!")
end

local function copy_url()
  local str = api.nvim_get_current_line()
  close_window()
  local chunks = split(str)
  api.nvim_command("silent! ! echo " .. chunks[7] .. " | pbcopy")
  print(chunks[2] .. " url copied!")
end

local function stop_all()
  local str = api.nvim_get_current_line()
  close_window()
  api.nvim_command("silent! ! navy stop")
  -- Locks vim up - needs to be async
  -- print("Navy stopped")
end

local function stop_service()
  local str = api.nvim_get_current_line()
  close_window()
  local chunks = split(str)
  api.nvim_command("silent! ! navy stop  " .. chunks[2])
  -- Locks vim up - needs to be async
  -- print(chunks[2] .. " stopped")
end

local function start_service()
  local str = api.nvim_get_current_line()
  close_window()
  local chunks = split(str)
  api.nvim_command("silent! ! navy start  " .. chunks[2])
  -- Locks vim up - needs to be async
  -- print(chunks[2] .. " started")
end

local function move_cursor()
  local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, {new_pos, 0})
end

local function set_mappings()
  local mappings = {
    ['['] = 'update_view(-1)',
    [']'] = 'update_view(1)',
    q = 'close_window()',
    k = 'move_cursor()',
    l = 'launch()',
    c = 'copy_url()',
    s = 'start_service()',
    x = 'stop_service()',
    X = 'stop_all()'
  }

  for k,v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"navy".'..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end
  local other_chars = {
    'a', 'b', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 't', 'u', 'v', 'w', 'y', 'z'
  }
  for k,v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

local function navy()
  position = 0
  open_window()
  set_mappings()
  update_view(0)
  api.nvim_win_set_cursor(win, {4, 0})
end

return {
  navy = navy,
  update_view = update_view,
  open_file = open_file,
  move_cursor = move_cursor,
  close_window = close_window,
  launch = launch,
  copy_url = copy_url,
  stop_all = stop_all,
  stop_service = stop_service,
  start_service = start_service
}
