getgenv().config = {}

local bridge = replicated_storage.Remotes.Bridge

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

for i, v in replicated_storage.Shared.Enemies:GetChildren() do
    local enemies_data = require(v)

    for i2, v2 in enemies_data do
        enemies[v2.Name] = i2
        table.insert(enemies_display, ("%* | %*"):format(v.Name, v2.Name))
    end
end

function nearest_enemy()
    local dist = math.huge
    local near = nil

    for i, v in workspace.Server.Enemies:GetChildren() do
        for i2, v2 in v:GetChildren() do
            local mag = (table.find(selected_display, v2.Name) or table.find(selected_display, "All")) and v2:GetAttribute("Health") > 0 and get_distance(v2.Position)
        
            if mag and mag < dist then
                dist = mag
                near = v2
            end
        end
    end
    return near
end

function is_attacking(mob)
    for i, v in mob.Folder:GetChildren() do
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
            teleport(mob.CFrame * CFrame.new(0, 5, 3))
        end

        if not is_attacking(mob) then
            bridge:FireServer("Shadows", "Attack", "Attack_All", "World", mob)
            task.wait(.3)
        end

        bridge:FireServer("Shadows", "Attack", "Click")
    end
end

function auto_star()
    while task.wait() and config.auto_star do
        bridge:FireServer("General", "Stars", "Multi")
    end
end

bridge:FireServer("General", "Shadows", "Unequip_All")
bridge:FireServer("General", "Shadows", "Equip_Best")
firesignal(replicated_storage.Remotes.U_Bridge.OnClientEvent, "UserInterface", "Notification", "Create", "Buggy Game", Color3.fromRGB(0, 255, 0))

table.sort(enemies_display)
load()

getgenv().library = get_github_file("library/obsidian.lua")
local window = library:CreateWindow({Title = "uzu01", Footer = "v1.0", ToggleKeybind = Enum.KeyCode.LeftControl, Center = true, ShowCustomCursor = false, AutoShow = true, NotifySide = "left"})

local main = window:AddTab("Main", "house")
local farming = main:AddLeftGroupbox("Farming")

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
        table.insert(selected_display, enemies[i:split(" | ")[2]] or "All")
    end
    save()
end})

farming:AddToggle("", {Text = "Auto Star", Default = config.auto_star, Callback = function(v)
    config.auto_star = v
    save()

    task.spawn(auto_star)
end})
