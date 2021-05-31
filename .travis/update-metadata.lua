#!/usr/bin/lua

-- This script inserts git metadata into LaTeX files before deployment.

local sha = io.popen('git log --pretty=format:"%H" -1'):read('*a')
local sha_short = io.popen('git log --pretty=format:"%h" -1'):read('*a')
local date = io.popen('git log --pretty=format:"%cs" -1'):read('*a')
--local version = io.open('VERSION', 'r'):read('*l')

local filename = arg[1]
local fh = io.open(filename, 'r')
local str = fh:read('*a')
fh:close()

str = str:gsub('\\ProvidesPackage{flare}%[[^%]]+%]',
               string.format(
                  '\\ProvidesPackage{flare}[%s Flare (git:%s) (AM)]',
                  date, sha_short))

local fh = io.open(filename, 'w')
fh:write(str)
fh:close()
