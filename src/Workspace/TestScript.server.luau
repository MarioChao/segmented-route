--!strict

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Imports ----------

local LinkedRoute = require(ReplicatedStorage.SegmentedRoute.LinkedRoute)
local RouteSegment = require(ReplicatedStorage.SegmentedRoute.RouteSegment)
local RouteUtil = require(ReplicatedStorage.SegmentedRoute.RouteUtil)


---------- Test functions ----------

local testBezierCurveDerivatives
local testBezierCurve
local travelAlongLinkedRoute
local testLinkedRoute

testBezierCurveDerivatives = function(bezierCurve: RouteSegment.BezierCurve)
    local bezierCurve_firstDerivative
    local bezierCurve_secondDerivative
    local bezierCurve_thirdDerivative
    bezierCurve_firstDerivative = bezierCurve:getFirstDerivativeCurve()
    bezierCurve_secondDerivative = bezierCurve:getHigherOrderDerivativeCurve(2)
    bezierCurve_thirdDerivative = bezierCurve:getHigherOrderDerivativeCurve(3)

    do
        print("[Test]: First derivative test")
        local val1 = bezierCurve:getFirstDerivativeAtAlpha(1.5)
        local val2 = bezierCurve:_getFirstDerivativeAtAlpha_deCasteljau(1.5)
        local val3 = bezierCurve_firstDerivative:getPositionAtAlpha(1.5)
        local val4 = bezierCurve_firstDerivative:_getPositionAtAlpha_deCasteljau(1.5, 1, #bezierCurve_firstDerivative.controlPoints)
        assert(val1 and val2 and val3 and val4)
        assert(val1:FuzzyEq(val2))
        assert(val1:FuzzyEq(val3))
        assert(val1:FuzzyEq(val4))
        print("[Test]: First derivative passed")
        print("First derivative positive direction", bezierCurve_firstDerivative:getPositiveDirectionAtAlpha(1.5))
    end
    do
        print("[Test]: Second derivative test")
        local val1 = bezierCurve_firstDerivative:getFirstDerivativeAtAlpha(1.5)
        local val2 = bezierCurve_secondDerivative:getPositionAtAlpha(1.5)
        assert(val1 and val2)
        assert(val1:FuzzyEq(val2))
        print("[Test]: Second derivative passed")
        print("Second derivative positive direction", bezierCurve_secondDerivative:getPositiveDirectionAtAlpha(1.5))
    end
    do
        print("[Test]: Third derivative test")
        local val1 = bezierCurve_secondDerivative:getFirstDerivativeAtAlpha(1.5)
        local val2 = bezierCurve_thirdDerivative:getPositionAtAlpha(1.5)
        assert(val1 and val2)
        assert(val1:FuzzyEq(val2))
        print("[Test]: Third derivative passed")
    end
    do
        local pcallSuccess, pcallResult
        pcallSuccess, pcallResult = pcall(function()
            print("Third derivative positive direction", bezierCurve_thirdDerivative:getPositiveDirectionAtAlpha(1.5))
        end)
        print(pcallSuccess, pcallResult)
        pcallSuccess, pcallResult = pcall(function()
            print("Fourth derivative", bezierCurve_thirdDerivative:getFirstDerivativeAtAlpha(1.5))
        end)
        print(pcallSuccess, pcallResult)
        pcallSuccess, pcallResult = pcall(function()
            print("Fourth derivative", bezierCurve:getHigherOrderDerivativeCurve(4):getPositionAtAlpha(1.5))
        end)
        print(pcallSuccess, pcallResult)
        pcallSuccess, pcallResult = pcall(function()
            print("Fourth derivative", bezierCurve:getHigherOrderDerivativeAtAlpha(4, 1.5))
        end)
        print(pcallSuccess, pcallResult)
    end
end

testBezierCurve = function()
    local controlPointParts = workspace.ControlPoints:GetChildren() :: {BasePart}
    local bezierCurve = RouteSegment.BezierCurve.new()

    table.sort(controlPointParts, function(a, b) return a.Name < b.Name end)
    for i = 1, 4 do
        bezierCurve:addControlPointPart_getOrCreateAttachment(controlPointParts[i], "ControlPointAttachment")
    end

    testBezierCurveDerivatives(bezierCurve)
end

travelAlongLinkedRoute = function(linkedRoute: LinkedRoute.ClassType, part: BasePart, speed: number)
    local routeStartTime = time()
    local routeElapsedTime
    local traversedDistance
    local routeAlpha
    local daTable = RouteUtil.Reparam.getRoute_distanceAlphaTable(linkedRoute)
    local reparameterization_function
    local routeLength
    local targetCFrame
    table.sort(daTable, function(a, b) return a.distance < b.distance end)
    print(`Route length: {routeLength} studs`)
    print(daTable)
    while true do
        -- Reparameterize
        reparameterization_function = RouteUtil.Reparam.getRoute_reparameterization_function(linkedRoute)
        routeLength = reparameterization_function(linkedRoute:getAlphaRange().Max, false)
        -- Get route alpha at time
        routeElapsedTime = time() - routeStartTime
        traversedDistance = routeElapsedTime * speed
        traversedDistance %= routeLength
        routeAlpha = reparameterization_function(traversedDistance, true)
        -- Set part CFrame
        targetCFrame = linkedRoute:getCFrameAtAlpha(routeAlpha)
        part.CFrame = targetCFrame
        RunService.Heartbeat:Wait()
    end
end

testLinkedRoute = function()
    local controlPointParts = workspace.ControlPoints:GetChildren() :: {BasePart}
    local curves = {}
    local curve
    local linkedRoute = LinkedRoute.new()
    local bulletPart
    local colorRange1
    local colorRange2
    local visualizerPart

    table.sort(controlPointParts, function(a, b) return a.Name < b.Name end)
    for i = 1, 5 do
        curve = RouteSegment.BezierCurve.new()
        table.insert(curves, curve)
        for j = (i - 1) * 3, i * 3 do
            curve:addControlPointPart_getOrCreateAttachment(controlPointParts[j % 5 + 1], "ControlPointAttachment")
        end
    end

    for _, tempCurve in curves do
        linkedRoute:addSegment(tempCurve)
    end

    bulletPart = Instance.new("Part")
    bulletPart.Size = Vector3.new(2, 2, 5)
    bulletPart.Color = BrickColor.new("Pink").Color
    bulletPart.Transparency = 0.6
    bulletPart.Anchored = true
    bulletPart.Parent = workspace
    task.defer(travelAlongLinkedRoute, linkedRoute, bulletPart, 32)
    colorRange1 = {BrickColor.new("Royal purple").Color, BrickColor.new("Pastel Blue").Color}
    colorRange2 = {BrickColor.new("Royal blue").Color, BrickColor.new("Medium blue").Color}
    visualizerPart = Instance.new("Part")
    visualizerPart.Size = Vector3.new(0.2, 0.2, 0.5)
    visualizerPart.Material = Enum.Material.Neon
    visualizerPart.Transparency = 0.6
    visualizerPart.Anchored = true
    -- visualizerPart.Size = Vector3.one * 0.5
    -- visualizerPart.Shape = Enum.PartType.Ball
    -- RouteUtil.Visualizer.createParts_equalSteps(linkedRoute, visualizerPart, colorRange1, 0, 0.03)
    task.defer(function()
        local reparameterization_function
        local partsFolder: Folder
        local oldPartsFolder: Folder
        local routeLength
        local partsLimit = 2000
        local minDeltaDistance
        local deltaDistance
        while true do
            reparameterization_function = RouteUtil.Reparam.getRoute_reparameterization_function(linkedRoute)
            routeLength = reparameterization_function(linkedRoute:getAlphaRange().Max, false)
            minDeltaDistance = routeLength / partsLimit
            deltaDistance = math.max(1, minDeltaDistance)
            visualizerPart.Size = Vector3.new(0.2, 0.2, deltaDistance * 0.5)
            reparameterization_function, partsFolder = RouteUtil.createParts_equalDistanceSteps(linkedRoute, visualizerPart, colorRange2, deltaDistance)
            RunService.Heartbeat:Wait()
            if oldPartsFolder then
                print(#oldPartsFolder:GetChildren())
                oldPartsFolder:Destroy()
            end
            oldPartsFolder = partsFolder
        end
    end)
end


---------- Calling functions ----------

-- testBezierCurve()
testLinkedRoute()
