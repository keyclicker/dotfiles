Cpp_template = [[
#include <iostream>
#include <vector>

using namespace std;

int main() {
  ios::sync_with_stdio(0);
  cin.tie(0);

  size_t t;
  cin >> t;

  while (t--) {
    int n;
    cin >> n;

    for (size_t i = 0; i < n; ++i) {

    }
  }

  return 0;
}
]]

Gcc_prefix = "g++ -std=c++20 "

local M = {}

-- generate folder and file structure for codeforces contest
function M.generate()
  -- prompt confirmation
  local confirm = vim.fn.input "List problems letters separated by space: "

  -- split input into list, make letters uppercase and remove spaces
  local problems = vim.fn.split(vim.fn.toupper(confirm), " ")

  -- create files Task<X>.cpp, Task<X>.in and Task<X>.out
  -- for each problem in current directory
  for _, problem in ipairs(problems) do
    local task = "Task" .. problem
    local cpp_name = task .. ".cpp"
    local in_name = task .. ".in"
    local out_name = task .. ".out"

    -- create files and write only if they don't exist
    -- create cpp file
    local cpp_exists = vim.fn.filereadable(cpp_name)
    if cpp_exists == 0 then
      local cpp_file = io.open(cpp_name, "w")
      if cpp_file == nil then
        print("Error creating file " .. cpp_name)
      else
        cpp_file:write(Cpp_template)
        cpp_file:close()
      end
    end

    -- create in file
    local in_exists = vim.fn.filereadable(in_name)
    if in_exists == 0 then
      local in_file = io.open(in_name, "w")
      if in_file == nil then
        print("Error creating file " .. in_file)
      else
        in_file:write ""
        in_file:close()
      end
    end

    -- create out file
    local out_exists = vim.fn.filereadable(out_name)
    if out_exists == 0 then
      local out_file = io.open(out_name, "w")
      if out_file == nil then
        print("Error creating file " .. out_file)
      else
        out_file:write ""
        out_file:close()
      end
    end

    -- create build directory if it doesn't exist
    local build_exists = vim.fn.isdirectory "build"
    if build_exists == 0 then os.execute "mkdir build" end
  end
end

local enter = vim.api.nvim_replace_termcodes("<CR>", true, true, true)

local function open_term(cmd)
  vim.cmd "vsplit"
  vim.cmd "terminal"
  vim.fn.feedkeys "a"
  vim.fn.feedkeys(cmd .. enter)
end

-- rebuild and run the current file if it's a cpp file
-- redirect input from Task<X>.in and check if output matches Task<X>.out
-- show diff if output doesn't match
function M.run_file()
  print "Running file"
  -- get current buffer name
  local file = vim.fn.expand "%:t"

  -- check if file is a cpp file
  if string.sub(file, -4) == ".cpp" then
    -- get task name
    local task = string.sub(file, 1, -5)

    local in_exists = vim.fn.filereadable(task .. ".in")
    local out_exists = vim.fn.filereadable(task .. ".out")

    if in_exists == 1 and out_exists == 1 then
      -- compile file
      local compile = Gcc_prefix .. "-o ./build/" .. task .. " " .. file
      local compile_status = os.execute(compile)

      if compile_status ~= 0 then
        print "Compilation failed"
        return
      end

      local echoRun = "echo '\\nRunning " .. task .. ":'; "
      local runIn = "./build/" .. task .. " < " .. task .. ".in"
      local run = runIn .. "; "
      local echoCat = "echo '\\nCatting:'" .. task .. ".out; "
      local cat = "cat " .. task .. ".out; "
      local echoDiff = "echo '\\nDiffing:'; "
      local diff = "diff <(" .. runIn .. ") " .. task .. ".out; "

      open_term(echoRun .. run .. echoCat .. cat .. echoDiff .. diff)
    else
      print "In or out file doesn't exist"
    end
  end
end

-- run dap for current file if it's a cpp file
function M.debug_file()
  -- get current buffer name
  local file = vim.fn.expand "%:t"

  -- check if file is a cpp file
  if string.sub(file, -4) == ".cpp" then
    -- get task name
    local task = string.sub(file, 1, -5)

    -- compile file
    local compile = Gcc_prefix .. "-o ./build/" .. task .. " " .. file
    local compile_status = os.execute(compile)

    -- if compilation fails, print error and return
    if compile_status ~= 0 then
      print "Compilation failed"
      return
    end

    require("dap").run {
      type = "codelldb",
      name = task,
      request = "launch",
      program = "./build/" .. task,
      args = {},
      cwd = vim.fn.getcwd(),
      externalConsole = false,
      MIMode = "gdb",
      setupCommands = {
        {
          description = "Enable pretty-printing for gdb",
          text = "-enable-pretty-printing",
          ignoreFailures = true,
        },
      },
    }
  end
end

return M
