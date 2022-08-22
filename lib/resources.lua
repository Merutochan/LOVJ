-- resources.lua
--
-- Generate and handle patch resources
--

resources = {}
-- subdivided in three sections:
resources.global = {}  -- shared globally: general option values, post-processing shaders, etc.
resources.parameters = {}  -- used as parameters bound to elements in patches
resources.graphics = {} -- filepaths or data bound to graphics resources / sprites etc.

resources.parameters.DEFAULT_SIZE = 128


-- global functions

--- @public rSet Setter for resource value by idx
function rSet(r, idx, v)
    r[idx].value = v
end

--- @public rSet Setter for resource value by idx
function rGet(r, idx)
    return r[idx].value
end

--- @public rSet Setter for resource name by idx
function rSetName(r, idx, n)
    r[idx].name = n
end

--- @public rSet Setter for resource name by idx
function rGetName(r, idx)
    return r[idx].name
end

-- Initialize parameters table
function resources.Init()
    for i=1, resources.parameters.DEFAULT_SIZE do
        local resource = {}
        resource.name = "resource" .. i
        resource.value = 0
        table.insert(resources.parameters, resource)
    end
end


function resources.Update(update_msg)
    for k, msg in pairs(update_msg) do
        local destination = msg[1] -- destination (osc)
        local content = msg[2] -- content of packet (osc)
        if true then end -- pass
    end
    return resources
end

return resources