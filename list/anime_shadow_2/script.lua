getgenv().config = {}

local bridge = replicated_storage.Remotes.Bridge
local client = require(player.PlayerScripts.Arise_Client)
local animation = require(player.PlayerScripts.Arise_Client.Scripts.UserInterface.Scripts.Star_Animation)
local attack = require(player.PlayerScripts.Arise_Client.Scripts.Shadows.Scripts.Attack)
local shadow_dropdown

local worlds = {}
local enemies = {}
local enemies_display = {" - | All"}
local selected_display = {}

local folder = "uzu script"
local game_name = "anime shadow 2"
local game_folder = ("%*/%*"):format(folder, game_name)
local config_file = ("%*/%* config.json"):format(game_folder, player.Name)

if not isfolder(folder) then makefolder(folder) end
if not isfolder(game_folder) then makefolder(game_folder) end

function save()
    writefile(config_file, http_service:JSONEncode(config))
end

function load()
    if not isfile(config_file) then return end
    getgenv().config = http_service:JSONDecode(readfile(config_file))
end

attack.Attack_Animation = function() return end

for i, v in getconstants(animation.Play) do
    if typeof(v) ~= "number" then continue end
    setconstant(animation.Play, i, 0)
end

for i, v in replicated_storage.Shared.Enemies:GetChildren() do
    local enemies_data = require(v)

    for i2, v2 in enemies_data do
        enemies[v2.Name] = i2
        table.insert(enemies_display, ("%* | %*"):format(v.Name, v2.Name))
    end
end

function shadow_rarity(shadow)
    for i, world in replicated_storage.Shared.Shadows:GetChildren() do
        for i2, v2 in require(world) do
            if i2 ~= shadow then continue end
            return v2.Rarity
        end
    end
    return nil
end

function get_shadows()
    local shadows = {}
    local display = {}

    for i, v in client.Data.Shadows do
        local name = ("%* | %* | %* | %*"):format(v.Name, v.Level, v.Shiny and "Shiny" or "Normal", i)
        table.insert(shadows, {id = i, name = v.Name, lvl = v.Level, shiny = v.Shiny, rarity = shadow_rarity(v.Name), locked = v.Locked})

        if table.find(display, name) then continue end
        table.insert(display, name)
    end
    table.sort(display)
    return {display, shadows}
end

function nearest_enemy()
    local dist = math.huge
    local near = nil
    local units = {}

    for i, v in config.selected_enemy do
        table.insert(units, enemies[v:split(" | ")[2]] or "All")
    end

    for i, v in workspace.Server.Enemies:GetChildren() do
        for i2, v2 in v:GetChildren() do
            local mag = player:GetAttribute("Mode") ~= "Trial" and (table.find(units, v2.Name) or table.find(units, "All")) and v2:GetAttribute("Health") > 0 and get_distance(v2.Position)
        
            if mag and mag < dist then
                dist = mag
                near = v2
            end
        end
    end

    for i, v in workspace.Server.Trial.Enemies:GetChildren() do
        local mag = v:GetAttribute("Health") > 0 and get_distance(v.Position)
        
        if mag and mag < dist then
            dist = mag
            near = v
        end
    end
    return near
end

function is_attacking(mob)
    for i, v in mob:WaitForChild("Folder"):GetChildren() do
        if not v.Name:match(player.Name) then continue end
        return true
    end
    return false
end

function auto_mob()
    while task.wait() and config.auto_mob do
        local mob = nearest_enemy()
        if not mob then continue end

        if config.can_teleport and get_distance(mob.Position) > 20 then
            if not mob:FindFirstAncestor("Trial") then
                client.Data.Map = mob.Parent.Name
            end
            teleport(mob.CFrame * CFrame.new(0, 5, 3))
        end

        if not is_attacking(mob) then
            bridge:FireServer("Shadows", "Attack", "Attack_All", mob:GetAttribute("Class"), mob)
            task.wait(.3)
        end

        bridge:FireServer("Shadows", "Attack", "Click")
    end
end

function auto_trial()
    while task.wait() and config.auto_trial do
        if replicated_storage.Gamemodes.Trial.Open.Value and player:GetAttribute("Mode") ~= "Trial" then
            bridge:FireServer("Gamemodes", "Trial", "Join")
            task.wait(1)
        end
    end
end

function auto_star()
    while task.wait() and config.auto_star do
        for i = 1, (config.open or 10) / 10 do
            bridge:FireServer("General", "Stars", "Multi")
        end
    end
end

function auto_fuse()
    while task.wait() and config.auto_fuse do
        local shadows = get_shadows()[2]
        local id = config.selected_shadow:split(" | ")[4]
        local ids = {}

        for i, v in shadows do
            if table.find(config.selected_rarity, v.rarity) and not v.locked then
                table.insert(ids, v.id)
            end
        end

        if #ids <= 0 then continue end
        bridge:FireServer("General", "Shadows", "Fuse", id, ids)
    end
end

table.sort(enemies_display)
load()

getgenv().library = get_github_file("library/obsidian.lua")
local window = library:CreateWindow({Title = "uzu01", Footer = "v1.0", ToggleKeybind = Enum.KeyCode.LeftControl, Center = true, ShowCustomCursor = false, AutoShow = true, NotifySide = "left"})

local main = window:AddTab("Main", "house")
local farming = main:AddLeftGroupbox("Farming")
local shadows = main:AddRightGroupbox("Shadow")

local misc = window:AddTab("Misc", "ellipsis")
local other = misc:AddLeftGroupbox("Other")

farming:AddToggle("", {Text = "Auto Mob", Default = config.auto_mob, Callback = function(v)
    config.auto_mob = v
    save()

    task.spawn(auto_mob)
end})

farming:AddToggle("", {Text = "Can Teleport", Default = config.can_teleport, Callback = function(v)
    config.can_teleport = v
    save()
end})

farming:AddDropdown("", {Text = "Enemy", Values = enemies_display, Default = config.selected_enemy, Multi = true, Callback = function(val)
    config.selected_enemy = {}
    selected_display = {}

    for i, v in pairs(val) do
        table.insert(config.selected_enemy, i)
    end
    save()
end})

farming:AddToggle("", {Text = "Auto Trial", Default = config.auto_trial, Callback = function(v)
    config.auto_trial = v
    save()

    task.spawn(auto_trial)
end})

shadows:AddToggle("", {Text = "Auto Hatch", Default = config.auto_star, Callback = function(v)
    config.auto_star = v
    save()

    task.spawn(auto_star)
end})

shadows:AddDropdown("", {Text = "Open", Values = {10, 50, 100, 200}, Default = config.open, Callback = function(val)
    config.open = val
    save()
end})

shadows:AddToggle("", {Text = "Auto Fuse", Default = config.auto_fuse, Callback = function(v)
    config.auto_fuse = v
    save()

    task.spawn(auto_fuse)
end})

shadow_dropdown = shadows:AddDropdown("", {Text = "Shadow", Values = get_shadows()[1], Default = config.selected_shadow, Callback = function(val)
    config.selected_shadow = val
    save()
end})

shadows:AddDropdown("", {Text = "Rarity", Values = {"Common", "Rare", "Epic", "Legendary", "Mythical"}, Default = config.selected_rarity, Multi = true, Callback = function(val)
    config.selected_rarity = {}

    for i, v in pairs(val) do
        table.insert(config.selected_rarity, i)
    end
    save()
end})

shadows:AddButton("", {Text = "Refresh Shadow", Func = function()
    shadow_dropdown:SetValues(get_shadows()[1])
end})

other:AddToggle("", {Text = "Afk Mode", Default = config.afk_mode, Callback = function(v)
    config.afk_mode = v
    save()

    afk_mode(v)
end})

other:AddToggle("", {Text = "Auto Rejoin", Default = config.auto_rejoin, Callback = function(v)
    config.auto_rejoin = v
    save()
end})

other:AddToggle("", {Text = "Auto Execute", Default = config.auto_execute, Callback = function(v)
    config.auto_execute = v
    save()
    if not v then return end
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/uzu02/refs/heads/main/init.lua"))()')
end})

other:AddToggle("", {Text = "Auto Hide UI", Default = config.auto_hide, Callback = function(v)
    config.auto_hide = v
    save()

    library:Toggle(not v)
    if not v then return end
    library:Notify({Title = "UI Hidden", Description = "Press Left Ctrl To Toggle", Time = 5})
end})

other:AddButton("", {Text = "Unload UI", Func = function()
    library:Unload()
end})

other:AddButton("", {Text = "Copy Discord Invite", Func = function()
    setclipboard("https://discord.com/invite/wEqc5Tvp8Z")
end})

for i, v in pairs(core_gui.RobloxPromptGui.promptOverlay:GetChildren()) do
    if v.Name == "ErrorPrompt" and config.auto_rejoin then
        player:Kick("Rejoining")
        teleport_service:Teleport(game.PlaceId, player)
    end
end

core_gui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(v)
    if v.Name == "ErrorPrompt" and config.auto_rejoin then
        player:Kick("Rejoining")
        teleport_service:Teleport(game.PlaceId, player)
    end
end)
