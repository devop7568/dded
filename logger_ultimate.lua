print("[made by cxyrocc on dc | enhanced edition]")

-- ═══════════════════════════════════════
-- 3X FASTER LOGGING: Buffer system
-- ═══════════════════════════════════════
local logBuffer = {}
local deobfBuffer = {}
task.spawn(function()
 while true do
  task.wait(0.5)
  if #logBuffer > 0 then
   appendfile('logged.txt', table.concat(logBuffer))
   logBuffer = {}
  end
  if #deobfBuffer > 0 then
   appendfile('deobf_strings.txt', table.concat(deobfBuffer))
   deobfBuffer = {}
  end
 end
end)

writefile('logged.txt','\nlocal Players = game:GetService("Players")\nlocal GameSettings = game:GetService("GameSettings")\nlocal LocalizationService = game:GetService("LocalizationService")\nlocal WebSocketService = game:GetService("WebSocketService")\nlocal WebSocketClient = game:GetService("WebSocketClient")\nlocal HttpService = game:GetService("HttpService")\nlocal UserInputService = game:GetService("UserInputService")\nlocal RunService = game:GetService("RunService")\nlocal TeleportService = game:GetService("TeleportService")\n')
writefile('deobf_strings.txt', '-- Deobfuscated strings captured at runtime\n')
writefile('loadstring_dumps.txt', '-- All loadstring inputs captured\n')
writefile('constants_dump.txt', '-- Extracted constants from closures\n')

-- ═══════════════════════════════════════
-- UI LIB DETECTION (expanded)
-- ═══════════════════════════════════════
local function isuilib()
 local a = debug.traceback()
 local b = a:lower():gsub('%s+','')
 return b:find('windui') or b:find('rayfield') or b:find('obsidian') or b:find('interface') or b:find('luna') or b:find('fluent') or b:find('drday') or b:find('orion') or b:find('kavo') or b:find('venyx') or b:find('wally') or b:find('linoria') or b:find('synapse') or b:find('coregui')
end

-- ═══════════════════════════════════════
-- FORMAT UTILITIES
-- ═══════════════════════════════════════
local function formatlog(text)
 if type(text) ~= 'string' then
  error('Bad agrument #1 to formatlog "string" expected, got: '..type(text))
  return
 end
 return text:gsub('table: ',''):gsub('function: ',''):gsub('Ugc','game'):gsub('\n',''):gsub('%s%s+',';'):gsub('""',''):gsub('Data Ping', 'DataPing'):gsub('Workspace','workspace'):gsub('game.Players','Players'):gsub('Teleport Service','TeleportService'):gsub('Run Service','RunService'):gsub('HttpGetAsync','HttpGet'):gsub('"',"'")
end

local function tblformat(tbl, depth)
 local depth = depth or 0
 local res = ''
 local first = true
 if depth > 5 then return 'too big to display' end
 if type(tbl) ~= 'table' then
  res = '"'..tostring(tbl)..'"'
  if res == '"nil"' then
   res = ''
  end
  return res
 end
 for i, v in pairs(tbl) do
  if not first then res = res .. ', ' end
  first = false
  if type(i) == 'string' then
   res = res .. '["' .. i .. '"] = '
  end
  if type(v) == 'table' then
   res = res .. '{' .. tblformat(v, depth + 1) .. '}'
  elseif type(v) == 'string' then
   res = res .. '"' .. tostring(v) .. '"'
  else
   res = res .. tostring(v)
  end
 end
 return res
end

local function deepcopy(tbl, depth)
 depth = depth or 0
 if depth > 4 then return nil end
 if type(tbl) ~= 'table' then return tbl end
 local copy = {}
 for k, v in pairs(tbl) do
  copy[k] = type(v) == 'table' and deepcopy(v, depth+1) or v
 end
 return copy
end

-- ═══════════════════════════════════════
-- DEDUP + LOGGING CORE
-- ═══════════════════════════════════════
local Track = {}
local kirked = {}
local function kirk(fem, boy)
 return fem .. ';' .. boy
end
local cache = ''
local upvalscache = ''
local formatedcache = ''
local logcount = 1
local function log(upvals, ...)
 upvals = upvals or 'nil'
 upvals = formatlog(tostring(upvals))
 if #upvals > 100 then
  local holder = #upvals
  upvals = upvals:sub(1,50) .. '... (' .. holder .. ' character remaining)'
 end
 local args = ...
 local formated = formatlog(tostring(args))
 local logged = formated
 if logged == cache then
  return
 end
 if formated == formatedcache and upvals == upvalscache then
  return
 end
 local charliekirk = kirk(logged, upvals)
 if kirked[charliekirk] then
  return
 end
 if upvals:find('Signal') then
  logged = formated .. ':Connect(function(...)end)'
 end
 if logged:find('game:HttpGet') then
  logged = 'loadstring('..formated..')()'
 end
 if logcount > 36000 then
  game:shutdown()
  return
 end
 if logged:find('IsA') then
  return
 end
 logcount += 1
 cache = logged
 upvalscache = upvals
 formatedcache = formated
 kirked[charliekirk] = true
 logBuffer[#logBuffer + 1] = logged .. '\n'
end

isfunctionhooked = nil
restorefunction = nil

-- ═══════════════════════════════════════
-- STRING DEOBFUSCATION ENGINE
-- Intercepts common obfuscation patterns
-- ═══════════════════════════════════════
local stringResults = {}
local stringResultCount = 0

local oldchar = clonefunction(string.char)
local oldconcat = clonefunction(table.concat)
local oldbyte = clonefunction(string.byte)
local oldsub = clonefunction(string.sub)
local oldrep = clonefunction(string.rep)
local oldreverse = clonefunction(string.reverse)
local oldgsub = clonefunction(string.gsub)
local oldformat = clonefunction(string.format)

-- Hook string.char — catches char-by-char string building
local charAccum = {}
local lastCharTime = 0
hookfunction(string.char, function(...)
 local result = oldchar(...)
 if checkcaller() and not isuilib() then
  local now = tick()
  if now - lastCharTime < 0.01 then
   charAccum[#charAccum + 1] = result
  else
   if #charAccum > 3 then
    local built = table.concat(charAccum)
    if #built > 4 and not stringResults[built] then
     stringResults[built] = true
     stringResultCount += 1
     deobfBuffer[#deobfBuffer + 1] = '[string.char build #'..stringResultCount..'] ' .. built .. '\n'
    end
   end
   charAccum = {result}
  end
  lastCharTime = now
 end
 return result
end)

-- Hook table.concat — catches table-based string assembly
hookfunction(table.concat, function(tbl, sep)
 local result = oldconcat(tbl, sep)
 if checkcaller() and not isuilib() then
  if type(tbl) == 'table' and #tbl > 5 then
   local allStrings = true
   for _, v in ipairs(tbl) do
    if type(v) ~= 'string' or #v > 4 then
     allStrings = false
     break
    end
   end
   if allStrings and #result > 8 and not stringResults[result] then
    stringResults[result] = true
    stringResultCount += 1
    deobfBuffer[#deobfBuffer + 1] = '[table.concat #'..stringResultCount..'] ' .. result .. '\n'
   end
  end
 end
 return result
end)

-- Hook string.gsub — catches XOR/substitution decryption
local gsubCallCount = 0
hookfunction(string.gsub, function(s, pattern, repl, ...)
 local result = oldgsub(s, pattern, repl, ...)
 if checkcaller() and not isuilib() then
  gsubCallCount += 1
  if type(s) == 'string' and #s > 20 and type(result) == 'string' and result ~= s then
   if not stringResults[result] and #result > 8 and not result:find('[%z%c]') then
    stringResults[result] = true
    stringResultCount += 1
    deobfBuffer[#deobfBuffer + 1] = '[gsub decode #'..stringResultCount..'] ' .. result:sub(1, 500) .. '\n'
   end
  end
 end
 return result
end)

-- ═══════════════════════════════════════
-- BIT/XOR DECRYPTION INTERCEPTION
-- Catches bit.bxor / bit32.bxor string decryption
-- ═══════════════════════════════════════
if bit and bit.bxor then
 local oldbxor = clonefunction(bit.bxor)
 local xorAccum = {}
 local lastXorTime = 0
 hookfunction(bit.bxor, function(a, b, ...)
  local result = oldbxor(a, b, ...)
  if checkcaller() and not isuilib() then
   local now = tick()
   if now - lastXorTime < 0.005 then
    if result >= 32 and result <= 126 then
     xorAccum[#xorAccum + 1] = string.char(result)
    end
   else
    if #xorAccum > 5 then
     local built = table.concat(xorAccum)
     if not stringResults[built] then
      stringResults[built] = true
      stringResultCount += 1
      deobfBuffer[#deobfBuffer + 1] = '[XOR decrypt #'..stringResultCount..'] ' .. built .. '\n'
     end
    end
    xorAccum = {}
    if result >= 32 and result <= 126 then
     xorAccum[#xorAccum + 1] = string.char(result)
    end
   end
   lastXorTime = now
  end
  return result
 end)
end

if bit32 and bit32.bxor then
 local oldbxor32 = clonefunction(bit32.bxor)
 local xorAccum32 = {}
 local lastXor32Time = 0
 hookfunction(bit32.bxor, function(a, b, ...)
  local result = oldbxor32(a, b, ...)
  if checkcaller() and not isuilib() then
   local now = tick()
   if now - lastXor32Time < 0.005 then
    if result >= 32 and result <= 126 then
     xorAccum32[#xorAccum32 + 1] = string.char(result)
    end
   else
    if #xorAccum32 > 5 then
     local built = table.concat(xorAccum32)
     if not stringResults[built] then
      stringResults[built] = true
      stringResultCount += 1
      deobfBuffer[#deobfBuffer + 1] = '[XOR32 decrypt #'..stringResultCount..'] ' .. built .. '\n'
     end
    end
    xorAccum32 = {}
    if result >= 32 and result <= 126 then
     xorAccum32[#xorAccum32 + 1] = string.char(result)
    end
   end
   lastXor32Time = now
  end
  return result
 end)
end

-- ═══════════════════════════════════════
-- CLOSURE ANALYSIS ENGINE
-- Extract upvalues + constants from any closure
-- ═══════════════════════════════════════
local analyzedClosures = {}

local function analyzeClosureDeep(func, label)
 if not func or type(func) ~= 'function' then return end
 if analyzedClosures[func] then return end
 analyzedClosures[func] = true

 local output = '\n-- [Closure: ' .. (label or tostring(func)) .. ']\n'
 local hasContent = false

 pcall(function()
  local constants = getconstants(func)
  if constants and #constants > 0 then
   output = output .. '-- Constants:\n'
   for i, c in ipairs(constants) do
    if type(c) == 'string' and #c > 3 and not c:find('^[%d%.]+$') then
     output = output .. '--   [' .. i .. '] = "' .. c:sub(1, 200) .. '"\n'
     hasContent = true
    end
   end
  end
 end)

 pcall(function()
  local upvalues = getupvalues(func)
  if upvalues then
   for i, v in pairs(upvalues) do
    if type(v) == 'string' and #v > 3 then
     output = output .. '--   upval[' .. i .. '] = "' .. v:sub(1, 200) .. '"\n'
     hasContent = true
    elseif type(v) == 'table' then
     output = output .. '--   upval[' .. i .. '] = {' .. tblformat(v) .. '}\n'
     hasContent = true
    elseif type(v) == 'function' then
     output = output .. '--   upval[' .. i .. '] = <function>\n'
     hasContent = true
    end
   end
  end
 end)

 pcall(function()
  local protos = getprotos(func)
  if protos then
   for i, proto in ipairs(protos) do
    analyzeClosureDeep(proto, (label or '') .. '.proto[' .. i .. ']')
   end
  end
 end)

 if hasContent then
  appendfile('constants_dump.txt', output)
 end
end

-- ═══════════════════════════════════════
-- GC SCANNER — periodic sweep for new closures
-- ═══════════════════════════════════════
local gcScanned = {}
local gcScanEnabled = true

task.spawn(function()
 task.wait(3)
 while gcScanEnabled do
  pcall(function()
   local gc = getgc(true)
   for _, obj in ipairs(gc) do
    if type(obj) == 'function' and islclosure(obj) and not gcScanned[obj] then
     gcScanned[obj] = true
     local info = getinfo(obj)
     if info and info.source and not info.source:find('CoreGui') and not info.source:find('RobloxGui') then
      analyzeClosureDeep(obj, info.source .. ':' .. (info.currentline or '?'))
     end
    end
   end
  end)
  task.wait(5)
 end
end)

-- ═══════════════════════════════════════
-- GLOBAL/ENV SCANS
-- ═══════════════════════════════════════
function GlobalScan()
 for i, v in pairs(_G) do
  log('_G Scan', '_G.'..i..' = '..tblformat(v))
 end
end

function GenvScan()
 for i, v in pairs(getgenv()) do
  log('getgenv Scan', 'getgenv().'..i..' = '..tblformat(v))
 end
end

function RegistryScan()
 local reg = debug.getregistry()
 for i, v in pairs(reg) do
  if type(v) == 'function' and islclosure(v) then
   analyzeClosureDeep(v, 'registry['..tostring(i)..']')
  end
 end
end

function ModuleScan()
 local modules = getloadedmodules()
 for _, mod in ipairs(modules) do
  pcall(function()
   local src = decompile(mod)
   if src and #src > 50 then
    writefile('module_dumps/' .. mod.Name:gsub('[/\\:]','_') .. '.lua', src)
    log('ModuleScan', 'Decompiled: ' .. mod:GetFullName())
   end
  end)
 end
end

function ScriptScan()
 local scripts = getrunningscripts()
 for _, scr in ipairs(scripts) do
  pcall(function()
   local src = decompile(scr)
   if src and #src > 50 then
    writefile('script_dumps/' .. scr.Name:gsub('[/\\:]','_') .. '.lua', src)
    log('ScriptScan', 'Decompiled: ' .. scr:GetFullName())
   end
  end)
 end
end

-- ═══════════════════════════════════════
-- ENHANCED LOADSTRING HOOK
-- Dumps + decompiles + analyzes
-- ═══════════════════════════════════════
local loadstringCount = 0
local oldl = clonefunction(loadstring)
hookfunction(loadstring, function(str, chunkname)
 if checkcaller() and not isuilib() then
  loadstringCount += 1
  local filename = 'ls_dump_' .. loadstringCount .. '.lua'
  writefile(filename, str)
  appendfile('loadstring_dumps.txt', '\n-- [Loadstring #'..loadstringCount..'] len='..#str..' chunk='..(chunkname or 'nil')..'\n')

  if #str < 50000 then
   appendfile('loadstring_dumps.txt', str:sub(1, 5000) .. '\n')
  end

  local result = oldl(str, chunkname)
  if result then
   task.defer(function()
    analyzeClosureDeep(result, 'loadstring#' .. loadstringCount)
   end)
  end
  log('loadstring#'..loadstringCount, 'loadstring([' .. #str .. ' chars], "' .. (chunkname or '') .. '")')
  return result
 end
 return oldl(str, chunkname)
end)

-- ═══════════════════════════════════════
-- SETFFLAG HOOK
-- ═══════════════════════════════════════
local oldsetfflag = clonefunction(setfflag)
setfflag = newcclosure(function(flag, state)
 local upvals = oldsetfflag(flag, state)
 log(upvals,'setfflag("'..flag..'", '..'"'..state..'")')
 return upvals
end)

-- ═══════════════════════════════════════
-- REQUEST HOOK (enhanced)
-- ═══════════════════════════════════════
if http and http.request then
 setreadonly(http, false)
 http.request = nil
 setreadonly(http, false)
end
local oldrequest = request
request = newcclosure(function(data)
 local upvals = oldrequest(data)
 local meow = data.Body
 if type(data.Body) == 'string' then
  if data.Body:sub(1,1) == '{' and data.Body:sub(-1) == '}' then
   meow = data.Body
  else
   meow = '"'..data.Body..'"'
  end
 elseif type(data.Body) == 'table' then
  meow = 'game:GetService("HttpService"):JSONEncode('..tblformat(data.Body)..')'
 else
  meow = tostring(data.Body)
 end
 local meowmeow = '{'
 local first = true
 if data.Headers then
  for i, v in pairs(data.Headers) do
   if not first then meowmeow = meowmeow .. ', ' end
   first = false
   meowmeow = meowmeow .. '["'..i..'"] = "'..v..'"'
  end
 end
 meowmeow = meowmeow .. '}'
 log(upvals, 'request({\n Url = "'..data.Url..'",\n Method = "'..data.Method..'",\n Body = '..meow..',\n Headers = '..meowmeow..'\n})')

 if upvals and type(upvals) == 'table' and upvals.Body then
  if type(upvals.Body) == 'string' and #upvals.Body > 20 then
   appendfile('logged.txt', '-- [Response Body] ' .. upvals.Body:sub(1, 1000) .. '\n')
  end
 end
 return upvals
end)

-- ═══════════════════════════════════════
-- WEBSOCKET HOOK
-- ═══════════════════════════════════════
local wss = game:GetService('WebSocketService')
local oldwsscc = clonefunction(wss.CreateClient)
hookfunction(game.WebSocketService.CreateClient, function(_, url)
 warn('WSS')
 if not url:lower():find'luarmor' then
  log('idk i found luarmor use this xd', 'WebsocketService:CreateClient("WebSocketService","'..url..'")')
 end
 return oldwsscc(_, url)
end)

-- ═══════════════════════════════════════
-- INSTANCE.NEW HOOK
-- ═══════════════════════════════════════
Instance = Instance or {}
local oldinstancenew = clonefunction(Instance.new)
setreadonly(Instance, false)
Instance.new = newcclosure(function(name, parent)
 if checkcaller() and not isuilib() then
  local upvals = oldinstancenew(name, parent)
  local a = debug.getinfo(2,'Sl')
  if a and a.source:find('@') then
   log(upvals, 'local a = Instance.new("'..name..'")')
  else
   local b = tostring(name)
   Track[upvals] = b
   log(upvals, 'local '..b..' = Instance.new("'..name..'")')
  end
  return upvals
 end
 return oldinstancenew(name, parent)
end)

-- ═══════════════════════════════════════
-- GETFENV / SETFENV HOOKS
-- Catches environment manipulation (VM obfuscators use this)
-- ═══════════════════════════════════════
local oldgetfenv = clonefunction(getfenv)
hookfunction(getfenv, function(level)
 local result = oldgetfenv(level)
 if checkcaller() and not isuilib() then
  log(result, 'getfenv(' .. tostring(level) .. ')')
 end
 return result
end)

local oldsetfenv = clonefunction(setfenv)
hookfunction(setfenv, function(func, env)
 if checkcaller() and not isuilib() then
  log(nil, 'setfenv(<func>, <env with ' .. tostring(#(env and env or {})) .. ' keys>)')
  if type(env) == 'table' then
   for k, v in pairs(env) do
    if type(v) == 'function' then
     task.defer(function()
      analyzeClosureDeep(v, 'setfenv_env.' .. tostring(k))
     end)
    end
   end
  end
 end
 return oldsetfenv(func, env)
end)

-- ═══════════════════════════════════════
-- REQUIRE HOOK — catches module loads
-- ═══════════════════════════════════════
local oldrequire = clonefunction(require)
hookfunction(require, function(module)
 local result = oldrequire(module)
 if checkcaller() and not isuilib() then
  local modname = 'unknown'
  pcall(function() modname = module:GetFullName() end)
  log(result, 'require(' .. modname .. ')')
  pcall(function()
   local src = decompile(module)
   if src and #src > 50 then
    writefile('require_dumps/' .. module.Name:gsub('[/\\:]','_') .. '.lua', src)
   end
  end)
 end
 return result
end)

-- ═══════════════════════════════════════
-- SPAWN / TASK HOOKS — catches deferred execution
-- ═══════════════════════════════════════
local oldspawn = clonefunction(spawn)
hookfunction(spawn, function(func)
 if checkcaller() and not isuilib() and type(func) == 'function' then
  log(nil, 'spawn(<function>)')
  task.defer(function() analyzeClosureDeep(func, 'spawn_target') end)
 end
 return oldspawn(func)
end)

local oldtaskspawn = clonefunction(task.spawn)
hookfunction(task.spawn, function(func, ...)
 if checkcaller() and not isuilib() and type(func) == 'function' then
  log(nil, 'task.spawn(<function>, ' .. tblformat({...}) .. ')')
  task.defer(function() analyzeClosureDeep(func, 'task.spawn_target') end)
 end
 return oldtaskspawn(func, ...)
end)

local oldtaskdefer = clonefunction(task.defer)
hookfunction(task.defer, function(func, ...)
 if checkcaller() and not isuilib() and type(func) == 'function' then
  log(nil, 'task.defer(<function>, ' .. tblformat({...}) .. ')')
  task.defer(function() analyzeClosureDeep(func, 'task.defer_target') end)
 end
 return oldtaskdefer(func, ...)
end)

-- ═══════════════════════════════════════
-- COROUTINE HOOKS — catches wrapped execution
-- ═══════════════════════════════════════
local oldcowrap = clonefunction(coroutine.wrap)
hookfunction(coroutine.wrap, function(func)
 if checkcaller() and not isuilib() and type(func) == 'function' then
  log(nil, 'coroutine.wrap(<function>)')
  task.defer(function() analyzeClosureDeep(func, 'coroutine.wrap_target') end)
 end
 return oldcowrap(func)
end)

local oldcocreate = clonefunction(coroutine.create)
hookfunction(coroutine.create, function(func)
 if checkcaller() and not isuilib() and type(func) == 'function' then
  log(nil, 'coroutine.create(<function>)')
  task.defer(function() analyzeClosureDeep(func, 'coroutine.create_target') end)
 end
 return oldcocreate(func)
end)

-- ═══════════════════════════════════════
-- HTTPGET / HTTPGETASYNC HOOK
-- ═══════════════════════════════════════
local oldHttpGet = clonefunction(game.HttpGet)
hookfunction(game.HttpGet, function(self, url, ...)
 local result = oldHttpGet(self, url, ...)
 if checkcaller() and not isuilib() then
  log(result, 'game:HttpGet("' .. tostring(url) .. '")')
  if type(result) == 'string' and #result > 50 then
   local fname = 'httpget_' .. tostring(tick():gsub('%.','')) .. '.lua'
   pcall(function() writefile(fname, result) end)
  end
 end
 return result
end)

-- ═══════════════════════════════════════
-- GETSCRIPTBYTECODE HOOK
-- ═══════════════════════════════════════
if getscriptbytecode then
 local oldgsb = clonefunction(getscriptbytecode)
 hookfunction(getscriptbytecode, function(scr)
  local result = oldgsb(scr)
  if checkcaller() and not isuilib() then
   local name = 'unknown'
   pcall(function() name = scr:GetFullName() end)
   log(nil, 'getscriptbytecode(' .. name .. ') [' .. #result .. ' bytes]')
  end
  return result
 end)
end

-- ═══════════════════════════════════════
-- DECOMPILE HOOK — log when scripts decompile themselves
-- ═══════════════════════════════════════
if decompile then
 local olddecompile = clonefunction(decompile)
 hookfunction(decompile, function(target)
  local result = olddecompile(target)
  if checkcaller() and not isuilib() then
   local name = 'unknown'
   pcall(function() name = target:GetFullName() end)
   log(nil, 'decompile(' .. name .. ') [' .. #(result or '') .. ' chars]')
  end
  return result
 end)
end

-- ═══════════════════════════════════════
-- METAMETHOD HOOKS (index, namecall, newindex)
-- ═══════════════════════════════════════
local mt = getrawmetatable(game)
local oldindex = clonefunction(mt.__index)
local oldnamecall = clonefunction(mt.__namecall)
local oldnewindex = clonefunction(mt.__newindex)

hookmetamethod(game,'__index',newcclosure(function(self, v, ...)
 if checkcaller() and not isuilib() then
  local upvals = oldindex(self, v, ...)
  local formated = tblformat(...)
  if v == 'Character' then
   log('LocalPlayer.Character', self:GetFullName()..'.'..v)
   return upvals
  end
  if v == 'GetService' then return upvals end
  if v == 'HttpGet' then return upvals end
  if v == 'JSONDecode' then return upvals end
  if v == 'CoreGui' then return upvals end
  if v == 'JSONEncode' then return upvals end
  if v == 'JobId' then log('game.JobId', self:GetFullName()..'.'..v) return upvals end
  if v == 'PlaceId' then log('game.PlaceId', self:GetFullName()..'.'..v) return upvals end
  if v == 'WaitForChild' then return upvals end
  if v == 'FindFirstChild' then return upvals end
  if v == 'DescendantRemoving' then return upvals end
  if tostring(upvals):find('function:') then
   log(upvals, self:GetFullName()..':'..v..'('..formated..')')
   return upvals
  end
  log(upvals, self:GetFullName()..'.'..v)
  return upvals
 end
 return oldindex(self, v, ...)
end))

hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
 if checkcaller() and not isuilib() and getnamecallmethod() ~= 'GetFullName' then
  local instance = tostring(self)
  if type(instance) == 'Instance' then
   instance = oldnamecall(instance, 'GetFullName')
  end
  local upvals = oldnamecall(self, ...)
  local args = {...}
  local formated = tblformat(args)
  if getnamecallmethod() == 'GetService' then
   log(upvals, 'game:GetService("'..args[1]..'")')
   return upvals
  end
  if getnamecallmethod() == 'WaitForChild' then
   log(upvals, instance..':WaitForChild("'..args[1]..'")')
   return upvals
  end
  if getnamecallmethod() == 'FindFirstChild' then
   log(upvals, instance..':FindFirstChild("'..args[1]..'")')
   return upvals
  end
  if getnamecallmethod() == 'HttpGet' then
   log(upvals, 'game:HttpGet("'..args[1]..'", true)')
   return upvals
  end
  if getnamecallmethod() == 'FireServer' then
   log(upvals, instance..':FireServer('..formated..')')
   return upvals
  end
  if getnamecallmethod() == 'InvokeServer' then
   log(upvals, instance..':InvokeServer('..formated..')')
   return upvals
  end
  if getnamecallmethod() == 'Connect' or getnamecallmethod() == 'connect' then
   if type(args[1]) == 'function' then
    task.defer(function() analyzeClosureDeep(args[1], instance..':Connect') end)
   end
  end
  log(upvals, instance..':'..getnamecallmethod()..'("'..formated..'")')
  return upvals
 end
 return oldnamecall(self, ...)
end))

hookmetamethod(game, '__newindex', newcclosure(function(self, i, v)
 if checkcaller() and not isuilib() then
  local upvals = oldnewindex(self, i, v)
  local a = Track[self]
  local b = tostring(i)
  local c = tostring(typeof(v)) or 'Unknown'
  local d = tostring(v)
  local prefix = a or 'a'
  if b then
   if c == 'Instance' then
    log(upvals, prefix..'.'..b..' = '..v:GetFullName())
   elseif c == 'number' then
    log(upvals, prefix..'.'..b..' = '..d)
   elseif c == 'string' then
    log(upvals, prefix..'.'..b..' = "'..d..'"')
   elseif c == 'boolean' then
    log(upvals, prefix..'.'..b..' = '..d)
   elseif c == 'Color3' then
    log(upvals, prefix..'.'..b..' = Color3.new('..d..')')
   elseif c == 'CFrame' then
    log(upvals, prefix..'.'..b..' = CFrame.new('..d..')')
   elseif c == 'Vector3' then
    log(upvals, prefix..'.'..b..' = Vector3.new('..d..')')
   elseif c == 'UDim2' then
    log(upvals, prefix..'.'..b..' = UDim2.new('..d:gsub('{',''):gsub('}','')..')')
   elseif c == 'Vector2' then
    log(upvals, prefix..'.'..b..' = Vector2.new('..d..')')
   elseif c == 'UDim' then
    log(upvals, prefix..'.'..b..' = UDim.new('..d..')')
   elseif c == 'EnumItem' then
    log(upvals, prefix..'.'..b..' = '..d)
   elseif c == 'ColorSequence' then
    log(upvals, prefix..'.'..b..' = ColorSequence.new('..d:gsub('%s+',',')..')')
   elseif c == 'function' then
    log(upvals, prefix..'.'..b..' = <function>')
    task.defer(function() analyzeClosureDeep(v, prefix..'.'..b) end)
   else
    log(upvals, prefix..'.'..b..' = '..'['..c..'] '..d)
   end
  end
  return upvals
 end
 return oldnewindex(self, i, v)
end))

-- ═══════════════════════════════════════
-- DESCENDANT CLEANUP
-- ═══════════════════════════════════════
game.DescendantRemoving:Connect(function(a)
 Track[a] = nil
end)

-- ═══════════════════════════════════════
-- PRINT / WARN / ERROR HOOKS
-- ═══════════════════════════════════════
local oldprint = print
print = newcclosure(function(...)
 if checkcaller() and not isuilib() then
  local args = {...}
  local formated = {}
  for i = 1, select('#', ...) do
   local v = args[i]
   if type(v) == 'table' then
    formated[i] = tblformat(v)
   else
    formated[i] = tostring(v)
   end
  end
  local upvals = oldprint(...)
  log(upvals, 'print("'.. table.concat(formated,'\t') ..'")')
  return upvals
 end
 return oldprint(...)
end)

local oldwarn = warn
warn = newcclosure(function(...)
 if checkcaller() and not isuilib() then
  local args = {...}
  local formated = {}
  for i = 1, select('#', ...) do
   formated[i] = tostring(args[i])
  end
  oldwarn(...)
  log(nil, 'warn("'.. table.concat(formated,'\t') ..'")')
  return
 end
 return oldwarn(...)
end)

local olderror = clonefunction(error)
hookfunction(error, function(msg, level)
 if checkcaller() and not isuilib() then
  log(nil, 'error("'.. tostring(msg) ..'")')
 end
 return olderror(msg, level)
end)

-- ═══════════════════════════════════════
-- RAWSET / RAWGET HOOKS — VM obfuscators use these heavily
-- ═══════════════════════════════════════
local oldrawset = clonefunction(rawset)
hookfunction(rawset, function(t, k, v)
 if checkcaller() and not isuilib() then
  if type(v) == 'function' then
   log(nil, 'rawset(<table>, "'..tostring(k)..'", <function>)')
   task.defer(function() analyzeClosureDeep(v, 'rawset.'..tostring(k)) end)
  elseif type(v) == 'string' and #v > 10 then
   log(nil, 'rawset(<table>, "'..tostring(k)..'", "'..v:sub(1,100)..'")')
  end
 end
 return oldrawset(t, k, v)
end)

-- ═══════════════════════════════════════
-- PCALL / XPCALL HOOKS — catches error-suppressed execution
-- ═══════════════════════════════════════
local oldpcall = clonefunction(pcall)
hookfunction(pcall, function(func, ...)
 if checkcaller() and not isuilib() and type(func) == 'function' then
  local info = getinfo(func)
  if info and info.source and not info.source:find('CoreGui') then
   log(nil, 'pcall(<' .. (info.source or 'unknown') .. ':' .. (info.currentline or '?') .. '>)')
  end
 end
 return oldpcall(func, ...)
end)

-- ═══════════════════════════════════════
-- VM PATTERN DETECTION
-- Detects Luraph/IronBrew/Synapse Xen patterns
-- ═══════════════════════════════════════
task.spawn(function()
 task.wait(2)
 pcall(function()
  local gc = getgc(true)
  for _, obj in ipairs(gc) do
   if type(obj) == 'table' and not gcScanned[obj] then
    local arrayLen = #obj
    if arrayLen > 100 then
     local allFuncs = true
     local sample = math.min(20, arrayLen)
     for i = 1, sample do
      if type(obj[i]) ~= 'function' then
       allFuncs = false
       break
      end
     end
     if allFuncs then
      appendfile('constants_dump.txt', '\n-- [VM OPCODE TABLE DETECTED] Size: ' .. arrayLen .. ' handlers\n')
      for i = 1, math.min(10, arrayLen) do
       pcall(function()
        local consts = getconstants(obj[i])
        if consts then
         appendfile('constants_dump.txt', '--   handler['..i..'] constants: ' .. tblformat(consts) .. '\n')
        end
       end)
      end
     end
    end
    if arrayLen > 500 then
     local allNumbers = true
     for i = 1, math.min(50, arrayLen) do
      if type(obj[i]) ~= 'number' then
       allNumbers = false
       break
      end
     end
     if allNumbers then
      appendfile('constants_dump.txt', '\n-- [VM BYTECODE ARRAY DETECTED] Size: ' .. arrayLen .. ' instructions\n')
      appendfile('constants_dump.txt', '--   First 20: ' .. tblformat({unpack(obj, 1, 20)}) .. '\n')
     end
    end
   end
  end
 end)
end)

-- ═══════════════════════════════════════
-- AUTO-DECOMPILE NEW SCRIPTS
-- ═══════════════════════════════════════
game.DescendantAdded:Connect(function(desc)
 if desc:IsA('LocalScript') or desc:IsA('ModuleScript') then
  task.defer(function()
   task.wait(0.5)
   pcall(function()
    local src = decompile(desc)
    if src and #src > 50 then
     local fname = 'auto_decompile/' .. desc:GetFullName():gsub('[/\\:%.%s]','_') .. '.lua'
     writefile(fname, '-- Auto-decompiled: ' .. desc:GetFullName() .. '\n' .. src)
     log(nil, '[AUTO-DECOMPILE] ' .. desc:GetFullName() .. ' (' .. #src .. ' chars)')
    end
   end)
  end)
 end
end)

-- ═══════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════
pcall(function() makefolder('module_dumps') end)
pcall(function() makefolder('script_dumps') end)
pcall(function() makefolder('require_dumps') end)
pcall(function() makefolder('auto_decompile') end)

print("[Logger] Enhanced edition loaded")
print("[Logger] Files: logged.txt, deobf_strings.txt, loadstring_dumps.txt, constants_dump.txt")
print("[Logger] Folders: module_dumps/, script_dumps/, require_dumps/, auto_decompile/")
print("[Logger] Commands: GlobalScan() | GenvScan() | RegistryScan() | ModuleScan() | ScriptScan()")
print("[Logger] Executing target loadstring...")

loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/387a5df3b561f6821c25654316d0e352.lua"))()
