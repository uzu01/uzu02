local g = getgenv()
local x = setmetatable({}, {__index = function(x, y) return game:GetService(y) end})

g.players = x.Players
g.core_gui = x.CoreGui
g.gui_service = x.GuiService
g.run_service = x.RunService
g.http_service = x.HttpService
g.virtual_user = x.VirtualUser
g.tween_service = x.TweenService
g.teleport_service = x.TeleportService
g.user_input_service = x.UserInputService
g.collection_service = x.CollectionService
g.replicated_storage = x.ReplicatedStorage
g.pathfinding_service = x.PathfindingService
g.virtual_input_manager = x.VirtualInputManager

g.player = g.players.LocalPlayer

g.get_character = function()
    return g.player.Character
end

g.get_humanoid = function()
    return g.get_character() and g.get_character():FindFirstChild("Humanoid")
end

g.get_humanoid_root_part = function()
    return g.get_character() and g.get_character():FindFirstChild("HumanoidRootPart")
end

g.teleport = function(cframe)
    return g.get_character() and g.get_character():PivotTo(cframe)
end

g.get_distance = function(position)
    return g.get_character() and g.player:DistanceFromCharacter(position) or math.huge
end

g.no_clip = function()
    local character = g.get_character()
    if not character then return end

    for _, v in character:GetDescendants() do
        if v:IsA("BasePart") and v.CanCollide then
            v.CanCollide = false
        end
    end
end

g.float = function(bool)
    local humanoid_root_part = g.get_humanoid_root_part()
    local humanoid = g.get_humanoid()
    local body_velocity = humanoid_root_part and humanoid_root_part:FindFirstChild("BodyVelocity")

    if not bool and body_velocity then
        humanoid.PlatformStand = false
        body_velocity:Destroy()
        return 
    end

    if not bool or not humanoid_root_part or not humanoid then return end
    if body_velocity then return end

    humanoid.PlatformStand = true
    local body_velocity_instance = Instance.new("BodyVelocity")
    body_velocity_instance.Parent = humanoid_root_part
    body_velocity_instance.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    body_velocity_instance.P = 1250
    body_velocity_instance.Velocity = Vector3.zero
end

g.tween = function(cframe, speed, wait)
    local humanoid_root_part = g.get_humanoid_root_part()
    if not humanoid_root_part then return end
    local time = (humanoid_root_part.CFrame.p - cframe.p).Magnitude / speed
    local tween = g.tween_service:Create(humanoid_root_part, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = cframe})
    tween:Play()

    if wait then
        task.wait(time)
    end
end

g.use_tool = function(name)
    local character = g.get_character()
    local humanoid = g.get_humanoid()
    if not humanoid then return end
    local tool = g.player.Backpack:FindFirstChild(name) or character:FindFirstChild(name)
    
    if tool then
        if not character:FindFirstChild(tool.Name) then
            humanoid:EquipTool(tool)
        end
        tool:Activate()
    end
end

g.move_to = function(position)
    return g.get_humanoid() and g.get_humanoid():MoveTo(Vector3.new(position))
end

g.dex = function()
    if g.dex_loaded then return end
    g.dex_loaded = true
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end

g.rejoin = function(place_id)
    g.teleport_service:Teleport(place_id or game.PlaceId)
end

g.face = function(position)
    local humanoid_root_part = g.get_humanoid_root_part()
    if not humanoid_root_part then return end
    humanoid_root_part.CFrame = CFrame.lookAt(humanoid_root_part.Position, position)
end

g.afk_mode = function(bool, fps)
    setfpscap(fps or 60)
    g.run_service:Set3dRenderingEnabled(not bool)

    if g.afk_screen_gui then g.afk_screen_gui:Destroy() end
    if g.afk_frame then g.afk_frame:Destroy() end

    g.afk_screen_gui = Instance.new("ScreenGui")
    g.afk_screen_gui.Parent = core_gui
    g.afk_screen_gui.IgnoreGuiInset = true

    g.afk_frame = Instance.new("Frame")
    g.afk_frame.Parent = g.afk_screen_gui
    g.afk_frame.Size = UDim2.new(1, 0, 1, 0)
    g.afk_frame.BackgroundColor3 = Color3.new(0, 0, 0)
    g.afk_frame.Visible = bool
end

g.rspy = function()
    loadstring(game:HttpGet("http://192.168.100.10:5500/util/remote_spy.lua"))()
end

g.send_webhook = function(url, text, ...)
    return request({Url = ("%*?wait=true"):format(url), Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game.HttpService:JSONEncode({embeds = {...}, content = text})})    
end

g.mouse1_click = function(x, y)
    g.virtual_input_manager:SendMouseButtonEvent(x or 0, y or 0, 0, true, game, false)
    task.wait()
    g.virtual_input_manager:SendMouseButtonEvent(x or 0, y or 0, 0, false, game, false)
end

g.fire_proximity_prompt = function(proximity_prompt)
    proximity_prompt.HoldDuration = 0
    proximity_prompt:InputHoldBegin()
    proximity_prompt:InputHoldEnd()
end

g.press_key = function(key)
    g.virtual_input_manager:SendKeyEvent(true, key, false, game) 
    g.virtual_input_manager:SendKeyEvent(false, key, false, game) 
end

g.navigation = function(ui)
    assert(ui, `{ui} is nil`)
    assert(ui:IsA("TextButton") or ui:IsA("ImageButton"), `{ui} is not a button`)

    g.gui_service.GuiNavigationEnabled = ui.Visible
    g.gui_service.SelectedObject = ui.Visible and ui or nil
    if not ui.Visible then return end 

    g.press_key("Return")
    task.wait(.1)
    g.gui_service.SelectedObject = nil
end

g.copy_pos = function()
    setclipboard(tostring(g.get_character():GetPivot().p))
end
