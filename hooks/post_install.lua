-- hooks/post_install.lua
-- Performs additional setup after installation
-- Documentation: https://mise.jdx.dev/dev-tools/vfox.html

local function get_downloaded_filename()
    local os_name = RUNTIME.osType:lower()
    local arch = RUNTIME.archType

    -- vibe asset naming: vibe-{os}-{arch}
    local platform_map = {
        ["darwin"] = {
            ["amd64"] = { os = "darwin", arch = "x64", ext = "" },
            ["arm64"] = { os = "darwin", arch = "arm64", ext = "" },
        },
        ["linux"] = {
            ["amd64"] = { os = "linux", arch = "x64", ext = "" },
            ["arm64"] = { os = "linux", arch = "arm64", ext = "" },
        },
        ["windows"] = {
            ["amd64"] = { os = "windows", arch = "x64", ext = ".exe" },
        },
    }

    local os_map = platform_map[os_name]
    if os_map == nil then
        error("Unsupported operating system: " .. os_name)
    end

    local platform = os_map[arch]
    if platform == nil then
        error("Unsupported architecture: " .. arch .. " on " .. os_name)
    end

    return "vibe-" .. platform.os .. "-" .. platform.arch .. platform.ext
end

-- Shell-escape a string to prevent command injection
-- Uses single quotes for Unix, double quotes for Windows
local function shell_escape(s, isWindows)
    if isWindows then
        -- Windows: use double quotes and escape internal double quotes
        return '"' .. s:gsub('"', '""') .. '"'
    else
        -- Unix: use single quotes and escape internal single quotes
        return "'" .. s:gsub("'", "'\\''") .. "'"
    end
end

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path

    -- Determine source and destination file names
    local os_name = RUNTIME.osType:lower()
    local isWindows = os_name == "windows"

    local srcFilename = get_downloaded_filename()
    local destFilename = "vibe"
    if isWindows then
        destFilename = "vibe.exe"
    end

    local binDir = path .. "/bin"
    local srcFile = path .. "/" .. srcFilename
    local destFile = binDir .. "/" .. destFilename

    -- Normalize paths for Windows (replace forward slashes with backslashes)
    if isWindows then
        binDir = binDir:gsub("/", "\\")
        srcFile = srcFile:gsub("/", "\\")
        destFile = destFile:gsub("/", "\\")
    end

    -- Create bin directory (platform-specific)
    local mkdirResult
    if isWindows then
        -- On Windows, create parent directories as needed
        mkdirResult = os.execute('cmd /c "if not exist ' .. shell_escape(binDir, isWindows) .. ' mkdir ' .. shell_escape(binDir, isWindows) .. '"')
    else
        mkdirResult = os.execute("mkdir -p " .. shell_escape(binDir, isWindows))
    end
    if mkdirResult ~= 0 then
        error("Failed to create bin directory")
    end

    -- Move binary to bin/ and rename (platform-specific)
    local mvResult
    if isWindows then
        mvResult = os.execute('cmd /c "move ' .. shell_escape(srcFile, isWindows) .. ' ' .. shell_escape(destFile, isWindows) .. '"')
    else
        mvResult = os.execute("mv " .. shell_escape(srcFile, isWindows) .. " " .. shell_escape(destFile, isWindows))
    end
    if mvResult ~= 0 then
        error("Failed to move vibe binary to bin/")
    end

    -- Set executable permission on Unix systems
    local isUnix = not isWindows
    if isUnix then
        local chmodResult = os.execute("chmod +x " .. shell_escape(destFile, isWindows))
        if chmodResult ~= 0 then
            error("Failed to set executable permission on vibe")
        end
    end

    -- Verify installation (platform-specific null device)
    local nullDevice = isWindows and "NUL" or "/dev/null"
    local testCmd
    if isWindows then
        testCmd = shell_escape(destFile, isWindows) .. " --version > " .. nullDevice .. " 2>&1"
    else
        testCmd = shell_escape(destFile, isWindows) .. " --version > " .. nullDevice .. " 2>&1"
    end
    local testResult = os.execute(testCmd)
    if testResult ~= 0 then
        error("vibe installation verification failed")
    end
end
