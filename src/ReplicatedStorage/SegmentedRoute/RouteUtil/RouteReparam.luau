--!strict

-- Route Reparam
-- Utility module for reparameterization of <code>LinkedRoute</code> and <code>RouteSegmentBase</code>.
-- Supports reparameterization between alpha and distance (arc length).


---------- Services ----------

local RunService = game:GetService("RunService")


---------- Imports ----------

local LinkedRoute = require(script.Parent.Parent.LinkedRoute)
local RouteSegment = require(script.Parent.Parent.RouteSegment)


---------- Types  ----------

type RecursionEndSettings = {
    atLeastDelaAlpha_dontEnd: number,
    atMostDeltaStud_end: number,
    atMostDeltaAlpha_end: number,
}

type DistanceAlphaPair = {
    distance: number,
    alpha: number,
}


---------- Constants ----------

local Constants = {}
Constants.recursionCountForDelay = 1000


---------- Global variables ----------

local Globals = {}
Globals.recursionCount = 0


---------- Local functions ----------

----- Recursion functions -----

local incrementRecursion

incrementRecursion = function()
    Globals.recursionCount += 1
    if Globals.recursionCount >= Constants.recursionCountForDelay then
        Globals.recursionCount = 0
        RunService.Heartbeat:Wait()
    end
end


----- Reparameterization helper functions -----

local isSegmentSmallEnough
local getSegmentDistance_recursion
local getRoute_distanceAlphaTable_recursion
local isDistanceAlphaPairLessThanParameter

isSegmentSmallEnough = function(deltaStud: number, deltaAlpha: number, recursionEndSettings: RecursionEndSettings): boolean
    local result = false
    if deltaAlpha > recursionEndSettings.atLeastDelaAlpha_dontEnd then
        result = false
    elseif deltaStud < recursionEndSettings.atMostDeltaStud_end then
        result = true
    elseif deltaAlpha < recursionEndSettings.atMostDeltaAlpha_end then
        result = true
    end
    return result
end

getSegmentDistance_recursion = function(segment: RouteSegment.RouteSegmentBase, startAlpha: number, stopAlpha: number, recursionEndSettings: RecursionEndSettings): number
    incrementRecursion()
    local result = 0
    local startPosition = segment:getPositionAtAlpha(startAlpha)
    local stopPosition = segment:getPositionAtAlpha(stopAlpha)
    local deltaStud = (stopPosition - startPosition).Magnitude
    local deltaAlpha = stopAlpha - startAlpha
    local midAlpha
    if isSegmentSmallEnough(deltaStud, deltaAlpha, recursionEndSettings) then
        result += deltaStud
    else
        midAlpha = startAlpha + deltaAlpha / 2
        result += getSegmentDistance_recursion(segment, startAlpha, midAlpha, recursionEndSettings)
        result += getSegmentDistance_recursion(segment, midAlpha, stopAlpha, recursionEndSettings)
    end
    return result
end

getRoute_distanceAlphaTable_recursion = function(resultTable: {DistanceAlphaPair}, linkedRoute: LinkedRoute.ClassType, startAlpha: number, stopAlpha: number, startDistance: number, recursionEndSettings: RecursionEndSettings): number
    incrementRecursion()
    local currentDistance = startDistance
    local startPosition = linkedRoute:getPositionAtAlpha(startAlpha)
    local stopPosition = linkedRoute:getPositionAtAlpha(stopAlpha)
    local deltaStud = (stopPosition - startPosition).Magnitude
    local deltaAlpha = stopAlpha - startAlpha
    local midAlpha
    local isValidDeltaStud

    -- Validate delta stud
    isValidDeltaStud = true
    isValidDeltaStud = isValidDeltaStud and deltaStud == deltaStud
    isValidDeltaStud = isValidDeltaStud and math.abs(deltaStud) ~= math.huge
    if not isValidDeltaStud then
        deltaStud = 1
    end

    -- Recursive subdivision
    if isSegmentSmallEnough(deltaStud, deltaAlpha, recursionEndSettings) or deltaStud ~= deltaStud then
        currentDistance += deltaStud
        table.insert(resultTable, {
            distance = currentDistance,
            alpha = stopAlpha,
        })
    else
        midAlpha = startAlpha + deltaAlpha / 2
        currentDistance = getRoute_distanceAlphaTable_recursion(resultTable, linkedRoute, startAlpha, midAlpha, currentDistance, recursionEndSettings)
        currentDistance = getRoute_distanceAlphaTable_recursion(resultTable, linkedRoute, midAlpha, stopAlpha, currentDistance, recursionEndSettings)
    end
    return currentDistance
end

isDistanceAlphaPairLessThanParameter = function(distanceAlphaPair: DistanceAlphaPair, parameter: number, inputIsDistance: boolean)
    local result
    if parameter == parameter then
        if inputIsDistance then
            result = distanceAlphaPair.distance < parameter
        else
            result = distanceAlphaPair.alpha < parameter
        end
    end
    return result
end


---------- Module ----------

local RouteReparam = {}


---------- Module fields ----------

----- Variables -----

RouteReparam.recursionEndSettings = {
    atLeastDelaAlpha_dontEnd = 0.1,
    atMostDeltaStud_end = 1,
    atMostDeltaAlpha_end = 0.01, -- at most around 100 segments per bezier curve
} :: RecursionEndSettings


----- Reparameterization functions -----

--[[
Gets an estimated total travelled distance / arc length (in studs) from the start of the segment to alpha.
Uses recursive subdivision.<br>
For better performance with repeated use, consider using <code>RouteReparam.getRoute_reparameterization_function()</code>.
]]
function RouteReparam.getSegmentDistanceAtAlpha(segment: RouteSegment.RouteSegmentBase, alpha: number): number
    return getSegmentDistance_recursion(segment, segment:getAlphaRange().Min, alpha, RouteReparam.recursionEndSettings)
end

--[[
Gets an estimated total travelled distance / arc length (in studs) from the start of the route to alpha.
Uses recursive subdivision for each segment.<br>
For better performance with repeated use, consider using <code>RouteReparam.getRoute_reparameterization_function()</code>.
]]
function RouteReparam.getRouteDistanceAtAlpha(linkedRoute: LinkedRoute.ClassType, routeAlpha: number): number
	local result = 0
    local segmentIndex
    local segmentAlpha
    local segment
    segmentIndex, segmentAlpha = linkedRoute:getSegmentAtAlpha(routeAlpha)
    for index = 1, segmentIndex - 1 do
        segment = linkedRoute:getSegmentByIndex(index)
        result += segment and RouteReparam.getSegmentDistanceAtAlpha(segment, segment:getAlphaRange().Max) or 0
    end
    segment = linkedRoute:getSegmentByIndex(segmentIndex)
    result += segment and RouteReparam.getSegmentDistanceAtAlpha(segment, segmentAlpha) or 0
    return result
end

--[[
Gets a <code>table</code> of distance-alpha value pairs used to reparameterize the route.<br>
If the route is modified after the function is called, call this function again to get a new <code>table</code>.
]]
function RouteReparam.getRoute_distanceAlphaTable(linkedRoute: LinkedRoute.ClassType): {DistanceAlphaPair}
    local alphaRange = linkedRoute:getAlphaRange()
    local distanceAlphaTable = {}
    getRoute_distanceAlphaTable_recursion(distanceAlphaTable, linkedRoute, alphaRange.Min, alphaRange.Max, 0, RouteReparam.recursionEndSettings)
    -- The calculated table should be sorted by default
    -- table.sort(distanceAlphaTable, function(a, b) return a.alpha < b.alpha end)
    return distanceAlphaTable
end

--[[
Gets an estimated <code>function</code> that converts distance from the start of the route to alpha (or the other way around).<br>
If the route is modified after the function is called, call this function again to estimate a new <code>function</code>.<br>
The estimated <code>function</code> performs a binary search on the distance-alpha <code>table</code> then linearly interpolates between the two closest values.
]]
function RouteReparam.getRoute_reparameterization_function(linkedRoute: LinkedRoute.ClassType): (parameter: number, inputIsDistance: boolean, willClampParameter: boolean?) -> number
    local daTable = RouteReparam.getRoute_distanceAlphaTable(linkedRoute)
    local reparameterization_function

    reparameterization_function = function(parameter: number, inputIsDistance: boolean)
        local indexL = 1
        local indexR = #daTable
        local indexM
        local result
        while indexR - indexL > 1 do
            indexM = indexL + (indexR - indexL) // 2
            if isDistanceAlphaPairLessThanParameter(daTable[indexM], parameter, inputIsDistance) then
                indexL = indexM
            else
                indexR = indexM
            end
        end
        if inputIsDistance then
            result = math.map(parameter, daTable[indexL].distance, daTable[indexR].distance, daTable[indexL].alpha, daTable[indexR].alpha)
        else
            result = math.map(parameter, daTable[indexL].alpha, daTable[indexR].alpha, daTable[indexL].distance, daTable[indexR].distance)
        end
        if result ~= result then
            -- Debug purposes
            warn(`[RouteReparam]: reparameterization_function resulted in nan!`)
        end
        return result
    end
    return reparameterization_function
end


---------- Return module ----------

table.freeze(RouteReparam)
return RouteReparam
