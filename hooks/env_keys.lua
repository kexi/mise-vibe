-- hooks/env_keys.lua
-- Configures environment variables for the installed tool
-- Documentation: https://mise.jdx.dev/dev-tools/vfox.html

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    return {
        {
            key = "PATH",
            value = mainPath,
        },
        {
            -- Installs created by older plugin versions placed the binary in
            -- bin/; keep it on PATH so they stay usable
            key = "PATH",
            value = mainPath .. "/bin",
        },
    }
end
