-- hooks/post_install.lua
-- Performs additional setup after installation
-- Documentation: https://mise.jdx.dev/dev-tools/vfox.html

local function get_downloaded_filename(version)
    local os_name = RUNTIME.osType:lower()
    local arch = RUNTIME.archType

    -- v2.0.0 renamed the Windows asset: vibe-windows-x64.exe -> vibe-win32-x64.
    -- Unparseable versions fall through to the current (v2+) naming.
    local major = tonumber(version:match("^(%d+)"))
    local windows_asset = { os = "win32", arch = "x64", ext = "" }
    if major ~= nil and major < 2 then
        windows_asset = { os = "windows", arch = "x64", ext = ".exe" }
    end

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
            ["amd64"] = windows_asset,
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

-- Shell-escape a string to prevent command injection (Unix only: on Windows
-- we never shell out — see PostInstall)
local function shell_escape(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path

    -- Determine source and destination file names
    local os_name = RUNTIME.osType:lower()
    local isWindows = os_name == "windows"

    local srcFilename = get_downloaded_filename(sdkInfo.version)
    local destFilename = "vibe"
    if isWindows then
        destFilename = "vibe.exe"
    end

    -- The binary stays in the install root (no bin/ subdirectory): creating a
    -- directory would require os.execute, and mise passes os.execute strings
    -- to `cmd /C` as a single MSVC-escaped argument (\"), which cmd cannot
    -- parse — any quoted Windows command line breaks. os.rename needs no shell.
    local srcFile = path .. "/" .. srcFilename
    local destFile = path .. "/" .. destFilename

    local ok, renameErr = os.rename(srcFile, destFile)
    if not ok then
        error("Failed to rename vibe binary: " .. tostring(renameErr))
    end

    if not isWindows then
        local chmodResult = os.execute("chmod +x " .. shell_escape(destFile))
        if chmodResult ~= 0 then
            error("Failed to set executable permission on vibe")
        end

        -- Smoke test. Unix only: os.execute cannot safely quote Windows
        -- paths (see above), so Windows relies on CI's `mise exec` check.
        local testResult = os.execute(shell_escape(destFile) .. " --version > /dev/null 2>&1")
        if testResult ~= 0 then
            error("vibe installation verification failed")
        end
    end
end
