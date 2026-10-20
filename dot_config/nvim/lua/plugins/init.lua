-- Collects every plugin file of lua/plugins/ and lua/themes/, installs them all
-- with a single vim.pack.add, then runs each file's config function.
--
-- A plugin file returns:
--   pack   = list of vim.pack specs ("owner/repo" is expanded to a GitHub url)
--   config = optional function run once the plugins are loaded

local config_dir = vim.fn.stdpath("config") .. "/lua/"

local specs = {}
local configs = {}

local function to_spec(spec)
  if type(spec) == "string" then
    spec = { src = spec }
  end
  if not spec.src:find("://") then
    spec.src = "https://github.com/" .. spec.src
  end
  return spec
end

for _, module in ipairs({ "plugins", "themes" }) do
  for _, file in ipairs(vim.fn.readdir(config_dir .. module)) do
    if file:match("%.lua$") and file ~= "init.lua" then
      local name = module .. "." .. file:gsub("%.lua$", "")
      local ok, plugin = pcall(require, name)
      if ok then
        for _, spec in ipairs(plugin.pack or {}) do
          table.insert(specs, to_spec(spec))
        end
        if plugin.config then
          table.insert(configs, { name = name, fn = plugin.config })
        end
      else
        vim.notify("Erreur en chargeant " .. name .. " :\n" .. plugin, vim.log.levels.ERROR)
      end
    end
  end
end

-- Build hooks (replaces lazy's `build`): set `data = { build = ... }` on a spec
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local data = ev.data
    local build = data.spec.data and data.spec.data.build
    if not build or (data.kind ~= "install" and data.kind ~= "update") then
      return
    end
    if build:sub(1, 1) == ":" then
      if not data.active then
        vim.cmd.packadd(data.spec.name)
      end
      vim.cmd(build:sub(2))
    else
      vim.system(vim.split(build, " "), { cwd = data.path }):wait()
    end
  end,
})

vim.pack.add(specs)

-- :PackUpdate pulls every plugin's git repo (confirm with :write, cancel with :quit)
vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update()
end, { desc = "Update all plugins with vim.pack" })

for _, config in ipairs(configs) do
  local ok, err = pcall(config.fn)
  if not ok then
    vim.notify("Erreur dans la config de " .. config.name .. " :\n" .. err, vim.log.levels.ERROR)
  end
end
