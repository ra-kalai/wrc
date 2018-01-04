-- WRC ( Web Remote Control )
-- Copyright (c) 2017, Ralph Augé
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
-- 
-- 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-- 
-- 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-- 
-- 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
--

local utils    = require 'lem.utils'
local lfs      = require 'lem.lfs'
local io       = require 'lem.io'
local signal   = require 'lem.signal'
local hathaway = require 'lem.hathaway'
local ljsonp   = require 'ljsonp'

local urldecode =  hathaway.urldecode
local parseform = hathaway.parseform

function clean_path(path)
	return path:gsub('%-', '%%-'):gsub('%[', '%%['):gsub('%]', '%%]')
			:gsub('%*', '%%*'):gsub('%+', '%%+')
			:gsub('%(', '%%('):gsub('%)', '%%)')
end

local spawn = utils.spawn

hathaway = hathaway.import()

GET('/', function(req, res)
	res.status = 302
	res.headers['Location'] = '/browse'
end)

GET('/browse', function(req, res)
	res.headers['Content-Type'] = 'text/html'
	res.file = 'browse.html'
end)

GET('/browse.css', function(req, res)
	res.headers['Content-Type'] = 'text/css'
	res.file = 'browse.css'
end)

GET('/jquery.js', function(req, res)
	res.headers['Content-Type'] = 'text/javascript'
	res.file = 'jquery-3.2.1.min.js'
end)

GETM('/preview/(.*)$', function(req, res, path)
	res.headers['Content-Type'] = 'text/json'

  local info = {}
  local filetype = io.popen(string.format("file -b %q", path), "r"):read("*a")

  if filetype:match("PDF document") then
    local cmd = string.format("convert %q -resize '300x300^' -gravity center -crop 300x300+0+0 +repage jpeg:- | base64 -w0", path .. '[0]')
    local preview = io.popen(cmd, "r"):read("*a")
    if preview and #preview then
      info.preview = preview
    end
  end

  if filetype:match("text") then
    local f = io.open(path, "r")

    local ts = {}
    for i=1, 7 do
      local l = f:read("*l") 
      if l then
        ts[#ts + 1] =  l .. '\n'
      end
    end

    info.ts = table.concat(ts)
  end

  if filetype:match("JPEG") then
    local cmd = string.format("convert %q -resize '300x300^' -gravity center -crop 300x300+0+0 +repage jpeg:- | base64 -w0", path)
    local preview = io.popen(cmd, "r"):read("*a")
    if preview and #preview then
      info.preview = preview
    end
  end

  info.filetype = filetype

	res:add(ljsonp.stringify(info))
end)


local g_running_process = {}

GET('/process-list', function(req, res, path)
	res.headers['Content-Type'] = 'text/json'
	local ret = {}
	for pid, v in pairs(g_running_process) do
		ret[#ret+1] = {pid, v[2]}
	end
	res:add('["ok", ' .. ljsonp.stringify(ret) .. ']')
end)

GETM('/display/(.*)$', function(req, res, path)
	res.headers['Content-Type'] = 'text/json'

  local info = {}
  local filetype = io.popen(string.format("file -i %q", path), "r"):read("*a")

  local cmd = {}
  if filetype:match('image') then
    cmd[#cmd+1] = 'feh'
    cmd[#cmd+1] = path
  end
  if filetype:match('video') or filetype:match('audio') then
    cmd[#cmd+1] = 'mpv'
    cmd[#cmd+1] = path
  end
  if #cmd > 0 then
      local stream, pid
      local tid 
      tid = utils.spawn2(function ()
       local ret = io.spawnp(
          cmd, 
          {
             {fds={0}, kind='pty', name='stdin'},
             {fds={1}, kind='pty', name='stdout'},
             {fds={2}, kind='pty', name='stderr'},
          })
          pid = ret.pid
          stream = ret.stream
        --stream, pid = io.popen(cmd, "3s");

        g_running_process[pid] = {stream, cmd}

        local process_died = function () 
          g_running_process[pid] = nil
        end

        spawn(function ()
          while true do
            local buf, err = stream.stdout:read("*l")
            if err then
              return process_died()
             else
               print('stdout', buf)
            end
          end
        end)

        spawn(function ()
          while true do
            local buf, err = stream.stderr:read("*l")
            if err then
              return process_died()
             else
               print('stderr', buf)
            end
          end
        end)
      end)

    utils.waittid({tid})

    res:add(ljsonp.stringify({'ok', {pid=pid, cmd=cmd}}))
		return
  end

  res:add('[]')
end)

GETM('/write%-to%-stdin/([0-9]+)/(.*)$', function(req, res, pid, text)
	res.headers['Content-Type'] = 'text/json'
  local stream = g_running_process[tonumber(pid)]

  if stream then
    stream[1].stdin:write(text)
  end
  
  res:add('[]')
end)

GETM('/kill%-process/([0-9]+)/([0-9]+)$', function(req, res, signal_nu, pid)
	res.headers['Content-Type'] = 'text/json'
  signal.kill(tonumber(pid), tonumber(signal_nu))
	res:add('["ok"]')
end)

GETM('/is%-process%-alive/([0-9]+)$', function(req, res, pid)
	res.headers['Content-Type'] = 'text/json'
  if (g_running_process[tonumber(pid)]) then
	  res:add('["ok", "alive"]')
		return
  end
	res:add('["ok", "no-info"]')
end)

GETM('/browse/(.*)$', function(req, res, path)
	res.headers['Content-Type'] = 'text/json'
	if path:match('^~') then
		path = path:gsub('^~', os.getenv('SERVE_DIR'))
	end
	path = clean_path(path)
	path = path .. '/*'

	local folderview = lfs.glob(path, 'dlfs')
	table.sort(folderview, function (a, b) 
			if a[2].mode == b[2].mode then
				return a[1] < b[1]
			else
				return a[2].mode < b[2].mode
			end
	end)
	res:add(ljsonp.stringify(folderview))
end)

GET('/favicon.ico$', function(req, res, path)
  res:add('')
end)

local sock = io.tcp.listen('*', 8080)
Hathaway({socket=sock})
