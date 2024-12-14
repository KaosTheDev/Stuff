-- >> ESP << --

local runService, players, camera = game:GetService("RunService"), game:GetService("Players"), workspace.CurrentCamera
local localPlayer, newVector2, settings = players.LocalPlayer, Vector2.new, Settings.ESP
local tan, rad, round = math.tan, math.rad, function(...) local a = {}; for i, v in next, table.pack(...) do a[i] = math.round(v); end return unpack(a); end
local wtvp = function(...) local a, b = camera.WorldToViewportPoint(camera, ...) return newVector2(a.X, a.Y), b, a.Z end
local espCache = {}

local function createEsp(player)
    if espCache[player] then return end
    local drawings = {
        box = Drawing.new("Square"),
        boxoutline = Drawing.new("Square"),
        healthBar = Drawing.new("Square")
    }

    drawings.box.Thickness, drawings.box.Filled, drawings.box.Color, drawings.box.Visible, drawings.box.ZIndex = 1, false, settings.defaultcolor, false, 2
    drawings.boxoutline.Thickness, drawings.boxoutline.Filled, drawings.boxoutline.Color, drawings.boxoutline.Visible, drawings.boxoutline.ZIndex = 3, false, Color3.new(), false, 1
    drawings.healthBar.Filled, drawings.healthBar.Color, drawings.healthBar.Visible, drawings.healthBar.ZIndex = true, Color3.fromRGB(0, 255, 0), false, 3

    espCache[player] = drawings
end

local function removeEsp(player)
    if espCache[player] then
        for _, drawing in next, espCache[player] do drawing:Remove() end
        espCache[player] = nil
    end
end

local function updateEsp(player, esp)
    local character = player.Character
    local hrp, humanoid = character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")

    if not hrp or not humanoid or humanoid.Health <= 0 then
        for _, d in next, esp do d.Visible = false end
        return
    end

    local pos, vis, depth = wtvp(hrp.Position)
    for _, d in next, esp do d.Visible = vis end
    if not vis then return end

    local minBound, maxBound = hrp.Position - Vector3.new(2, 4, 2), hrp.Position + Vector3.new(2, 6, 2)
    local scale = 1 / (depth * tan(rad(camera.FieldOfView / 2)) * 2) * 500
    local width, height = round((maxBound.X - minBound.X) * 2 * scale, (maxBound.Y - minBound.Y) * 1.5 * scale)
    local x, y = round(pos.X, pos.Y)

    esp.box.Size, esp.box.Position, esp.box.Color = newVector2(width, height), newVector2(x - width / 2, y - height / 2), settings.teamcolor and player.TeamColor.Color or settings.defaultcolor
    esp.boxoutline.Size, esp.boxoutline.Position = esp.box.Size, esp.box.Position

    if settings.healthbar then
        local healthHeight = height * (humanoid.Health / humanoid.MaxHealth)
        esp.healthBar.Size, esp.healthBar.Position = newVector2(1.5, healthHeight), newVector2(esp.box.Position.X - 2, esp.box.Position.Y + height / 2 - healthHeight / 2)
    end
end

local function handleCharacter(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid").Died:Connect(function()
            removeEsp(player)
        end)
        createEsp(player)
    end)
    if player.Character then
        createEsp(player)
    end
end

players.PlayerAdded:Connect(function(player)
    handleCharacter(player)
end)

players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
end)

for _, player in next, players:GetPlayers() do
    if player ~= localPlayer then
        handleCharacter(player)
    end
end

runService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value, function()
    if settings.enabled then
        for player, esp in next, espCache do
            if settings.teamcheck and player.Team == localPlayer.Team then continue end
            updateEsp(player, esp)
        end
    else
        for _, esp in next, espCache do for _, d in next, esp do d.Visible = false end end
    end
end)

