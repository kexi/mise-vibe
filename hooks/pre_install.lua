-- hooks/pre_install.lua
-- Returns download information for a specific version
-- Documentation: https://mise.jdx.dev/dev-tools/vfox.html

local function get_platform(version)
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
    -- OS: darwin, linux, win32
    -- Arch: x64, arm64
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

    return platform
end

function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local platform = get_platform(version)

    -- Build asset name: vibe-{os}-{arch}{ext}
    local asset_name = "vibe-" .. platform.os .. "-" .. platform.arch .. platform.ext

    -- Build download URL
    local url = "https://github.com/kexi/vibe/releases/download/v" .. version .. "/" .. asset_name

    return {
        version = version,
        url = url,
    }
end
