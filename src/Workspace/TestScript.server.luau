--!strict

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Imports ----------

local Modules = ReplicatedStorage.Modules
local SegmentedRoute = require(Modules.SegmentedRoute)
local LinkedRoute = SegmentedRoute.LinkedRoute
local RouteSegment = SegmentedRoute.RouteSegment
local RouteUtil = SegmentedRoute.RouteUtil


---------- Test functions ----------

----- Route segments -----

local testBezierCurveDerivatives
local testBezierCurve

testBezierCurveDerivatives = function(bezierCurve: SegmentedRoute.BezierCurve)
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


----- Route util -----

local travelAlongLinkedRoute
local visualizeDynamicRoute
local testLinkedRoute

travelAlongLinkedRoute = function(linkedRoute: SegmentedRoute.LinkedRoute, defaultPart: BasePart, speed: number)
    local routeStartTime = time()
    local routeElapsedTime
    local traversedDistance
    local routeAlpha
    local daTable = RouteUtil.Reparam.getRoute_distanceAlphaTable(linkedRoute)
    local reparameterization_function
    local routeLength
    local targetCFrame
    local newDefaultPart = defaultPart:Clone()
    newDefaultPart.Parent = workspace
    table.sort(daTable, function(a, b) return a.distance < b.distance end)
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
        newDefaultPart.CFrame = targetCFrame
        RunService.Heartbeat:Wait()
    end
end

visualizeDynamicRoute = function(linkedRoute: SegmentedRoute.LinkedRoute, useAlpha: boolean, defaultPart: BasePart, autoResizePartLength: boolean, colorRange: {Color3}, partCountLimit: number, minDeltaParameter: number)
    local reparameterization_function
    local partsFolder: Folder
    local oldPartsFolder: Folder
    local routeLength
    local alphaRange
    local partCountDeltaParameter
    local deltaParameter
    local newDefaultPart = defaultPart:Clone()
    while true do
        if useAlpha then
            -- Use alpha
            alphaRange = linkedRoute:getAlphaRange()
            partCountDeltaParameter = (alphaRange.Max - alphaRange.Min) / partCountLimit
            deltaParameter = math.max(minDeltaParameter, partCountDeltaParameter)
            partsFolder = RouteUtil.Visualizer.createParts_equalSteps(linkedRoute, newDefaultPart, autoResizePartLength, colorRange, alphaRange.Min, deltaParameter)
        else
            -- Use distance
            reparameterization_function = RouteUtil.Reparam.getRoute_reparameterization_function(linkedRoute)
            routeLength = reparameterization_function(linkedRoute:getAlphaRange().Max, false)
            partCountDeltaParameter = routeLength / partCountLimit
            deltaParameter = math.max(minDeltaParameter, partCountDeltaParameter)
            newDefaultPart.Size = Vector3.new(0.2, 0.2, deltaParameter * 0.4)
            reparameterization_function, partsFolder = RouteUtil.createParts_equalDistanceSteps(linkedRoute, newDefaultPart, autoResizePartLength, colorRange, deltaParameter)
        end
        RunService.Heartbeat:Wait()
        if oldPartsFolder then
            print(#oldPartsFolder:GetChildren())
            oldPartsFolder:Destroy()
        end
        oldPartsFolder = partsFolder
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
    -- task.defer(travelAlongLinkedRoute, linkedRoute, bulletPart, 32)
    -- task.defer(travelAlongLinkedRoute, linkedRoute, bulletPart, 8)
    colorRange1 = {BrickColor.new("Royal purple").Color, BrickColor.new("Pastel Blue").Color}
    colorRange2 = {BrickColor.new("Royal blue").Color, BrickColor.new("Medium blue").Color}
    visualizerPart = Instance.new("Part")
    visualizerPart.Material = Enum.Material.Neon
    -- visualizerPart.Transparency = 0.6
    visualizerPart.Locked = true
    visualizerPart.Size = Vector3.new(0.2, 0.2, 0.5)
    visualizerPart.Anchored = true
    -- visualizerPart.Size = Vector3.one * 0.5
    -- visualizerPart.Shape = Enum.PartType.Ball
    -- RouteUtil.Visualizer.createParts_equalSteps(linkedRoute, visualizerPart, colorRange1, 0, 0.03)
    task.defer(visualizeDynamicRoute, linkedRoute, true, visualizerPart, false, colorRange1, 2000, 0.025)
    -- RouteUtil.createParts_equalDistanceSteps(linkedRoute, visualizerPart, colorRange2, 1)
    -- task.defer(visualizeDynamicRoute, linkedRoute, false, visualizerPart, false, colorRange2, 2000, 1)
end


---------- Calling functions ----------

-- testBezierCurve()
testLinkedRoute()
