-- this was NOT made by me, it was taken from: https://raw.githubusercontent.com/cracker-monkey/moonlight/refs/heads/master/src/Pathfinding.lua

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
--

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Color3fromRGB = Color3.fromRGB
local Instancenew = Instance.new
local Vector2zero = Vector2.zero
local Vector3zero = Vector3.zero
local Vector2new = Vector2.new
local Vector3new = Vector3.new
local Drawingnew = Drawing.new
local mathcos = math.cos
local mathsin = math.sin
local Env = getgenv()
local Ignores = {  }

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Blacklist
RayParams.FilterDescendantsInstances = Ignores

local Tracers = {}

function New(Class, Properties)
    local Object = Drawingnew(Class)
    for Property, Value in next, Properties do
        Object[Property] = Value
    end
    return Object
end

function CreateDrawingTracer(Cfg)
    Cfg = {
        Positions = Cfg.Positions or {},
        Time = Cfg.Time or 5,
        Color = Cfg.Color or Color3fromRGB(255, 255, 255),
        Outline = Cfg.Outline or Color3fromRGB(0, 0, 0),
    }

    local Character = LocalPlayer.Character
    local HumanoidRootPart = Character.HumanoidRootPart;

    local Tracer = {
        ["Objects"] = {},
        ["StartTick"] = os.clock(),
    }

    for _,v in next, Cfg.Positions do
        local OutlineObject = New("Line", {
            Thickness = 3,
            Transparency = 1,
            --ZIndex = 1,
            Color = Color3fromRGB(0, 0, 0)
        })

        local Obj = New("Line", {
            Thickness = 1,
            Transparency = 1,
            --ZIndex = 2,
            Color = Color3fromRGB(255, 255, 255)
        })

        Tracer.Objects[_] = {
            ["OutlineObject"] = OutlineObject,
            ["Object"] = Obj,
        }
    end

    local Connection = RunService.Heartbeat:Connect(function()
        local ScreenSize = Camera.ViewportSize

        local Transparency = 1
        local OutlineTransparency = 1

        local Origin = HumanoidRootPart and HumanoidRootPart.Position or Camera.CFrame.p

        if os.clock() - Tracer.StartTick > Cfg.Time then
            Tracer:Remove()
            table.remove(Tracers, _)
        end

        for _,v in next, Cfg.Positions do
            local From = _ == 1 and v or Cfg.Positions[_ - 1] or Vector3zero
            local To = v or Vector3zero
        
            local DistanceFromTracer = ((v or Vector3zero) - Origin).Magnitude

            local Trans = Transparency
            local OutlineTrans = OutlineTransparency

            local Objects = Tracer.Objects[_]

            local Object = Objects.Object

            local FromScreen, FromOnScreen = Camera:WorldToViewportPoint(From)
            local ToScreen, ToOnScreen = Camera:WorldToViewportPoint(To)
            
            Object.Visible = ToOnScreen and FromOnScreen

            if Object.Visible then
                local FromVector2 = Vector2new(FromScreen.x, FromScreen.y)
                local ToVector2 = Vector2new(ToScreen.x, ToScreen.y)
                
                Object.From = FromVector2
                Object.To = ToVector2
                Object.Color = Cfg.Color
            end
        end
    end)
    Tracer.Connection = Connection

    function Tracer:Remove()
        for _,v in next, Tracer.Objects do
            v.Object:Remove()
        end

        Tracer.Connection:Disconnect()
    end

    Tracers[#Tracers + 1] = Tracer
end

local astar = {
    maxtime = getgenv().maxtime or 1, -- max time to find path
    interval = getgenv().interval or 5, -- distance between nodes
    maxoffset = 0, -- minimum distance to target to stop pathfinding
    ignorelist = Ignores, -- list of objects to ignore from raycast
    performance = false,
    ThreadAmount = 4, -- Number of threads to create
    visualise = true,
}

local nodemetatable = {__index = function(self, index)
    if not rawget(self, index) then
        rawset(self, index, setmetatable({}, {__index = function(self0, index0)
            if not rawget(self0, index0) then
                rawset(self0, index0, {})
            end

            return rawget(self0, index0)
        end}))
    end

    return rawget(self, index)
end}

local directions = {
    space = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 1, 0),
        Vector3.new(0, -1, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1)
    },
    diagonal = {
        Vector3.new(1, 0, 1),
        Vector3.new(1, 0, -1),
        Vector3.new(-1, 0, 1),
        Vector3.new(-1, 0, -1),
        Vector3.new(1, 1, 0),
        Vector3.new(1, -1, 0),
        Vector3.new(-1, 1, 0),
        Vector3.new(-1, -1, 0),
        Vector3.new(0, 1, 1),
        Vector3.new(0, -1, 1),
        Vector3.new(0, 1, -1),
        Vector3.new(0, -1, -1)
    },
    bodydiagonal = {
        Vector3.new(1, 1, 1),
        Vector3.new(1, -1, 1),
        Vector3.new(-1, 1, 1),
        Vector3.new(-1, -1, 1),
        Vector3.new(1, 1, -1),
        Vector3.new(1, -1, -1),
        Vector3.new(-1, 1, -1),
        Vector3.new(-1, -1, -1)
    }
}

local workspace = game:GetService("Workspace")
local parameters = RaycastParams.new()
local insert = table.insert

parameters.FilterType = Enum.RaycastFilterType.Blacklist

function astar:distance(origin, target)
    local ox, oy, oz = origin.X, origin.Y, origin.Z
    local tx, ty, tz = target.X, target.Y, target.Z
    return ((ox - tx) ^ 2 + (oy - ty) ^ 2 + (oz - tz) ^ 2) ^ 0.5
end

function astar:findpart(origin, target)
    return workspace:Raycast(origin, target - origin, parameters)
end

function astar:findpath(origin, target, interval, maxoffset)
    local types = {space = astar.interval, diagonal = 2 ^ 0.5 * astar.interval, bodydiagonal = 3 ^ 0.5 * astar.interval}
    local nodes = setmetatable({}, nodemetatable)
    local endtime = tick() + astar.maxtime
    local starttime = tick()
    local path, distance

    parameters.FilterDescendantsInstances = astar.ignorelist
    nodes[0][0][0] = {
        hcost = self:distance(origin, target),
        offset = Vector3.new(),
        scanned = false,
        position = origin,
        lastnode = nil,
        gcost = 0
    }
    nodes[0][0][0].fcost = nodes[0][0][0].hcost

    -- Create coroutines
    local coroutines = {}
    local currentThread = 1
    local maxThreads = astar.ThreadAmount
    for i = 1, maxThreads do
        coroutines[i] = coroutine.create(function()
            while tick() < endtime do
                local lowestcost, currentnode, x, y, z = math.huge

                for x1, x0 in next, nodes do
                    for y1, y0 in next, x0 do
                        for z1, randomnode in next, y0 do
                            if not randomnode.scanned and randomnode.fcost < lowestcost then
                                lowestcost = randomnode.fcost
                                currentnode = randomnode
                                x = x1; y = y1; z = z1
                            end
                        end
                    end
                end

                if currentnode then
                    if self:findpart(currentnode.position, target) and currentnode.hcost > maxoffset then
                        for offsettype, offsets in next, directions do
                            for _, offset in next, offsets do
                                offset = offset * types.space
                                local offsetnode = nodes[x + offset.X][y + offset.Y][z + offset.Z]
                                local position = currentnode.position + offset

                                if not self:findpart(currentnode.position, position) then
                                    if offsetnode then
                                        if offsetnode.gcost > currentnode.gcost + types[offsettype] then
                                            offsetnode.lastnode = currentnode
                                            offsetnode.gcost = currentnode.gcost + types[offsettype]
                                            offsetnode.fcost = offsetnode.gcost + offsetnode.hcost
                                        end
                                    else
                                        nodes[x + offset.X][y + offset.Y][z + offset.Z] = {
                                            offset = Vector3.new(x + offset.X, y + offset.Y, z + offset.Z),
                                            position = position,
                                            scanned = false,
                                            lastnode = currentnode,
                                            gcost = currentnode.gcost + types[offsettype]
                                        }

                                        local offsetnode = nodes[x + offset.X][y + offset.Y][z + offset.Z]
                                        offsetnode.hcost = self:distance(offsetnode.position, target)
                                        offsetnode.fcost = offsetnode.hcost + offsetnode.gcost
                                    end
                                end
                            end
                        end

                        currentnode.scanned = true
                    else
                        path = {}

                        while currentnode.lastnode do
                            insert(path, 1, currentnode.position)
                            currentnode = currentnode.lastnode
                        end

                        insert(path, 1, origin)
                        currentnode = nodes[x][y][z]

                        if astar.performance then
                            local direction = (target - currentnode.position).Unit * types.space
                            local lastgcost = self:distance(currentnode.position, target)
                            distance = currentnode.gcost + lastgcost

                            for i = 1, math.floor(lastgcost / types.space) do
                                insert(path, currentnode.position + direction * i)
                            end
                        else
                            local points = {origin}
                            insert(path, target)

                            for i = 3, #path do
                                if self:findpart(points[#points], path[i]) then
                                    insert(points, path[i - 1])
                                end
                            end

                            insert(points, target)

                            path = {}
                            distance = 0

                            for i = 2, #points do
                                local startpos = points[i - 1]
                                local endpos = points[i]
                                local direction = (endpos - startpos).Unit * interval
                                local pointdist = self:distance(startpos, endpos)
                                distance = distance + pointdist

                                for i = 1, math.floor(pointdist / interval) do
                                    insert(path, startpos + direction * i)
                                end

                                insert(path, endpos)
                            end
                        end

                        endtime = tick()
                        coroutine.yield() -- Yield the current coroutine
                    end
                else
                    endtime = tick()
                    coroutine.yield() -- Yield the current coroutine
                end
            end
        end)
    end

    -- Resume coroutines in a round-robin fashion
    while true do
        local status, result = coroutine.resume(coroutines[currentThread])
        if not status then
            error(result)
        end

        if coroutine.status(coroutines[currentThread]) == "dead" then
            break
        end

        currentThread = currentThread % maxThreads + 1
    end

    if (astar.visualise) then
        CreateDrawingTracer({
            Time = 10,
            Positions = path
        });
    end

    return path, distance, endtime - starttime
end

return astar;

--[[
local Character = LocalPlayer.Character;
local HumanoidRootPart = Character.HumanoidRootPart;

local Origin = HumanoidRootPart.Position;
local End = vector.create(-79.35540771484375, 3.932297945022583, -172.06381225585938);

local Path, Distance, Time = astar:findpath(Origin, End, astar.interval, astar.maxoffset);

print("----");
print(Path and #Path or 0, Distance, Time);

if Path then
    

    --for _,v in next, Path do
    --    HumanoidRootPart.CFrame = CFrame.new(v);
    --    task.wait(0.05);
    --end
else
    warn("No path found")
end
]]
