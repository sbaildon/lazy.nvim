local M = {}

---@param spec LazySpec Should be a module name to load, or a plugin spec
---@param opts? LazyConfig
function M.setup(spec, opts)
  if not vim.go.loadplugins then
    return
  end
  local start = vim.loop.hrtime()

  -- load module cache before anything else
  require("lazy.core.module").setup()
  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")
  local Loader = require("lazy.core.loader")
  local Plugin = require("lazy.core.plugin")

  Util.track({ plugin = "lazy.nvim" }) -- setup start
  Util.track("module", vim.loop.hrtime() - start)

  -- load config
  Util.track("config")
  Config.setup(spec, opts)
  Util.track()

  -- load the plugins
  Plugin.load()

  -- setup loader and handlers
  Loader.setup()

  -- correct time delta and loaded
  local delta = vim.loop.hrtime() - start
  Util.track().time = delta -- end setup
  if Config.plugins["lazy.nvim"] then
    Config.plugins["lazy.nvim"]._.loaded = { time = delta, source = "init.lua" }
  end

  -- load plugins with lazy=false or Plugin.init
  Loader.init_plugins()

  -- all done!
  vim.cmd("do User LazyDone")
end

function M.stats()
  local ret = { count = 0, loaded = 0 }
  for _, plugin in pairs(require("lazy.core.config").plugins) do
    ret.count = ret.count + 1
    if plugin._.loaded then
      ret.loaded = ret.loaded + 1
    end
  end
  return ret
end

function M.bootstrap()
  local lazypath = vim.fn.stdpath("data") .. "/site/pack/lazy/opt/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "--single-branch",
      "https://github.com/folke/lazy.nvim.git",
      lazypath,
    })
    vim.opt.runtimepath:append(lazypath)
  end
end

return M
