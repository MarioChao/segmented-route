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

----- Creating routes -----

local createCubicBezierLoop
local createCubicBezierSmoothLoop

createCubicBezierLoop = function()
    local controlPointParts = workspace.ControlPoints:GetChildren() :: {BasePart}
    local curves = {}
    local curve
    local linkedRoute = LinkedRoute.new()

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

    return linkedRoute
end

createCubicBezierSmoothLoop = function(continuity: number)
    local controlPointParts = workspace.ControlPoints:GetChildren() :: {BasePart}
    local curves = {}
    local curve
    local linkedRoute = LinkedRoute.new()

    table.sort(controlPointParts, function(a, b) return a.Name < b.Name end)
    for i = 1, 5 do
        curve = RouteSegment.BezierCurve.new()
        table.insert(curves, curve)
        for j = (i - 1) * 3, i * 3 do
            curve:addControlPointPart_getOrCreateAttachment(controlPointParts[j % 5 + 1], "ControlPointAttachment")
        end
    end

    for _, tempCurve in curves do
        linkedRoute:addConnectedSegment(tempCurve, continuity)
    end
    linkedRoute:connectLoop(continuity)

    return linkedRoute
end


----- Visualizing routes -----

local travelAlongLinkedRoute
local visualizeDynamicRoute

travelAlongLinkedRoute = function(linkedRoute: SegmentedRoute.LinkedRoute, defaultPart: BasePart, speed: number)
    local newDefaultPart
    local routePreviousTime = time()
    local routeNewTime
    local routeDeltaTime
    local deltaDistance
    local daTable = RouteUtil.Reparam.getRoute_distanceAlphaTable(linkedRoute)
    local reparameterization_function
    local routeAlpha
    local originalRouteDistance
    local targetRouteDistance
    local routeTotalLength
    local targetCFrame
    newDefaultPart = defaultPart:Clone()
    newDefaultPart.Parent = workspace
    table.sort(daTable, function(a, b) return a.distance < b.distance end)
    print(daTable)
    routeAlpha = 0
    while true do
        -- Reparameterize
        reparameterization_function = RouteUtil.Reparam.getRoute_reparameterization_function(linkedRoute)
        -- Get original route distance at alpha
        originalRouteDistance = reparameterization_function(routeAlpha, false, true)
        -- Get delta time & delta distance
        routeNewTime = time()
        routeDeltaTime = routeNewTime - routePreviousTime
        routePreviousTime = routeNewTime
        deltaDistance = routeDeltaTime * speed
        -- Get target route distance
        routeTotalLength = reparameterization_function(linkedRoute:getAlphaRange().Max, false)
        targetRouteDistance = (originalRouteDistance + deltaDistance) % routeTotalLength
        -- Convert to new alpha
        routeAlpha = reparameterization_function(targetRouteDistance, true)
        -- Set part CFrame
        targetCFrame = linkedRoute:getCFrameAtAlpha(routeAlpha)
        newDefaultPart.CFrame = targetCFrame
        RunService.Heartbeat:Wait()
    end
end

visualizeDynamicRoute = function(linkedRoute: SegmentedRoute.LinkedRoute, useAlpha: boolean, visualizerInfo, connected: boolean, partCountLimit: number, minDeltaParameter: number)
    local reparameterization_function
    local partsFolder: Folder
    local oldPartsFolder: Folder
    local partsTable: {BasePart}
    local oldPartsTable: {BasePart}
    local routeLength
    local alphaRange
    local partCountDeltaParameter
    local deltaParameter
    while true do
        if useAlpha then
            -- Use alpha
            alphaRange = linkedRoute:getAlphaRange()
            partCountDeltaParameter = (alphaRange.Max - alphaRange.Min) / partCountLimit
            deltaParameter = math.max(minDeltaParameter, partCountDeltaParameter)
            if connected then
                partsFolder, partsTable = RouteUtil.Visualizer.createParts_connected_equalSteps(linkedRoute, visualizerInfo, alphaRange.Min, deltaParameter)
            else
                partsFolder, partsTable = RouteUtil.Visualizer.createParts_equalSteps(linkedRoute, visualizerInfo, nil, alphaRange.Min, deltaParameter)
            end
        else
            -- Use distance
            reparameterization_function = RouteUtil.Reparam.getRoute_reparameterization_function(linkedRoute)
            routeLength = reparameterization_function(linkedRoute:getAlphaRange().Max, false)
            partCountDeltaParameter = routeLength / partCountLimit
            deltaParameter = math.max(minDeltaParameter, partCountDeltaParameter)
            if visualizerInfo and visualizerInfo.templatePart then
                visualizerInfo.templatePart.Size = Vector3.new(deltaParameter * 0.4, visualizerInfo.templatePart.Size.Y, visualizerInfo.templatePart.Size.Z)
            end
            if connected then
                reparameterization_function, partsFolder, partsTable = RouteUtil.createParts_connected_equalDistanceSteps(linkedRoute, visualizerInfo, deltaParameter)
            else
                reparameterization_function, partsFolder, partsTable = RouteUtil.createParts_equalDistanceSteps(linkedRoute, visualizerInfo, nil, deltaParameter)
            end
        end
        RunService.Heartbeat:Wait()
        -- Clear old parts
        if not oldPartsTable or #oldPartsTable ~= #partsTable then
            print(#partsTable)
        end
        if oldPartsFolder then
            oldPartsFolder:Destroy()
        end
        oldPartsFolder = partsFolder
        oldPartsTable = partsTable
    end
end


----- Route segments -----

local testBezierCurveDerivatives
local testBezierCurve
local testBezierConnectionCurve

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
        local val4 = bezierCurve._evaluateDeCasteljau(1.5, bezierCurve_firstDerivative:getControlPointPositions())
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
    local partsFolder

    table.sort(controlPointParts, function(a, b) return a.Name < b.Name end)
    for i = 1, 4 do
        bezierCurve:addControlPointPart_getOrCreateAttachment(controlPointParts[i], "ControlPointAttachment")
    end

    testBezierCurveDerivatives(bezierCurve)

    partsFolder = RouteUtil.Visualizer.createParts_equalSteps(LinkedRoute.fromSegments({bezierCurve}), nil, {}, 0, 0.05)
    task.wait(2)
    partsFolder:Destroy()
    task.wait(1)
end

testBezierConnectionCurve = function()
    local controlPointParts = workspace.ControlPoints:GetChildren() :: {BasePart}
    local curve1 = RouteSegment.BezierCurve.new()
    local curve2 = RouteSegment.BezierCurve.new()
    local bezierConnectionCurve
    local partsFolder

    RouteSegment.BezierCurve.new()

    table.sort(controlPointParts, function(a, b) return a.Name < b.Name end)
    for i = 1, 4 do
        curve1:addControlPointPart_getOrCreateAttachment(controlPointParts[i], "ControlPointAttachment")
    end
    for i = 4, 5 do
        curve2:addControlPointPart_getOrCreateAttachment(controlPointParts[i], "ControlPointAttachment")
    end
    bezierConnectionCurve = RouteSegment.BezierConnectionCurve.new(curve1, curve2, 3)
    -- bezierConnectionCurve:getPositionAtAlpha(0)
    -- RouteUtil.Visualizer.createParts_equalSteps(LinkedRoute.fromSegments({curve1, bezierConnectionCurve, curve2}), nil, false, 0, 0.05)
    -- RouteUtil.createParts_equalDistanceSteps(LinkedRoute.fromSegments({curve1, bezierConnectionCurve, curve2}), nil, false, 1)
    visualizeDynamicRoute(LinkedRoute.fromSegments({curve1, bezierConnectionCurve, curve2}), false, nil, true, 1000, 1)
    task.wait(2)
end


----- Route util -----

local testLinkedRoute

testLinkedRoute = function(linkedRoute: SegmentedRoute.LinkedRoute)
    local bulletPart
    local colorRange1
    local colorRange2
    local visualizerPart
    local visualizerInfo: SegmentedRoute.PartVisualizerInfo_Input

    bulletPart = Instance.new("Part")
    bulletPart.Size = Vector3.new(2, 2, 5)
    bulletPart.Color = BrickColor.new("Pink").Color
    bulletPart.Transparency = 0.6
    bulletPart.Anchored = true
    task.defer(travelAlongLinkedRoute, linkedRoute, bulletPart, 32)
    -- task.defer(travelAlongLinkedRoute, linkedRoute, bulletPart, 8)

    colorRange1 = {BrickColor.new("Royal purple").Color, BrickColor.new("Pastel Blue").Color}
    colorRange2 = {BrickColor.new("Royal blue").Color, BrickColor.new("Medium blue").Color}
    visualizerPart = Instance.new("Part")
    visualizerPart.Material = Enum.Material.Neon
    visualizerPart.Locked = true
    visualizerPart.Size = Vector3.new(0.5, 0.2, 0.2)
    visualizerPart.Anchored = true
    visualizerPart.Shape = Enum.PartType.Cylinder

    visualizerInfo = {
        colorRange = colorRange1,
        templatePart = visualizerPart :: BasePart,
    }
    -- RouteUtil.Visualizer.createParts_equalSteps(linkedRoute, visualizerInfo, false, 0, 0.03)
    -- task.defer(visualizeDynamicRoute, linkedRoute, true, visualizerPart, false, colorRange1, 2000, 0.025)

    visualizerInfo = {
        colorRange = colorRange2,
        templatePart = visualizerPart :: BasePart,
    }
    -- RouteUtil.createParts_equalDistanceSteps(linkedRoute, visualizerInfo, true, 1)
    task.defer(visualizeDynamicRoute, linkedRoute, false, visualizerInfo, true, 2000, 1)
end


----- General test -----

local generalTest

generalTest = function()
    local linkedRoute
    -- linkedRoute = createCubicBezierLoop()
    linkedRoute = createCubicBezierSmoothLoop(1)
    -- testBezierCurve()
    -- testBezierConnectionCurve()
    testLinkedRoute(linkedRoute)
end


---------- Calling functions ----------

generalTest()
