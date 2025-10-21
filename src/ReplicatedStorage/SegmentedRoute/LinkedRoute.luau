--!strict

-- Linked Route
-- Class for connecting segments into routes.
-- A route connects segments such that segment K can only traverse to segment K-1 and segment K+1.


---------- Imports ----------

local RouteSegment = require(script.Parent.RouteSegment)


---------- Module ----------

local LinkedRoute = {}
LinkedRoute.__index = LinkedRoute


---------- Module types ----------

type ClassData = {
    _routeSegments: {RouteSegment.RouteSegmentBase},
}

export type ClassType = ClassData & typeof(LinkedRoute)


---------- Module fields ----------

--[[
Constructs a <code>LinkedRoute</code> object.
]]
function LinkedRoute.new(): ClassType
    local self = setmetatable({} :: any, LinkedRoute) :: ClassType
    self._routeSegments = {}
    return self
end


----- Segment functions -----

--[[
Adds a <code>RouteSegmentBase</code> to the end of the route.
]]
function LinkedRoute.addSegment(self: ClassType, segment: RouteSegment.RouteSegmentBase)
    table.insert(self._routeSegments, segment)
end

--[[
Gets the number of segments.
]]
function LinkedRoute.getSegmentCount(self: ClassType): number
    return #self._routeSegments
end

--[[
Gets the stored <code>RouteSegmentBase</code> at the given index.
]]
function LinkedRoute.getSegmentByIndex(self: ClassType, segmentIndex: number): RouteSegment.RouteSegmentBase
    local segmentCount = self:getSegmentCount()
    local result
	if not (1 <= segmentIndex and segmentIndex <= segmentCount) then
        warn(`[LinkedRoute]: getSegmentByIndex received a segmentId ({segmentIndex}) that's out of range!`)
        segmentIndex = math.clamp(segmentIndex, 1, segmentCount)
    end
    result = self._routeSegments[segmentIndex]
    return result
end

--[[
Clears the stored route segments.
]]
function LinkedRoute.clearSegments(self: ClassType)
    table.clear(self._routeSegments)
end


----- Alpha functions -----

--[[
Gets the alpha range (as <code>number</code>) from the start of the route to the end of the given segment.
]]
function LinkedRoute.getPrefixTotalAlphaRangeBySegmentIndex(self: ClassType, segmentId: number): number
    local finalSegmentId = math.min(segmentId, self:getSegmentCount())
    local prefixTotalAlpha = 0
    for id = 1, finalSegmentId do
        prefixTotalAlpha += self._routeSegments[id]:getAlphaRange_scalar()
    end
    return prefixTotalAlpha
end

--[[
Gets the alpha range (as <code>NumberRange</code>) of the route.
]]
function LinkedRoute.getAlphaRange(self: ClassType): NumberRange
    local finalAlpha = self:getPrefixTotalAlphaRangeBySegmentIndex(self:getSegmentCount())
    return NumberRange.new(0, finalAlpha)
end

--[[
Gets the alpha range (as <code>number</code>) of the route.
]]
function LinkedRoute.getAlphaRange_scalar(self: ClassType): number
    local alphaRange = self:getAlphaRange()
    return alphaRange.Max - alphaRange.Min
end

--[[
Returns whether the given alpha is in the route's domain.
]]
function LinkedRoute.containsAlpha(self: ClassType, routeAlpha: number): boolean
    local alphaRange = self:getAlphaRange()
    return alphaRange.Min <= routeAlpha and routeAlpha <= alphaRange.Max
end

--[[
Returns the given alpha clamped to the route's domain.
]]
function LinkedRoute.clampAlpha(self: ClassType, routeAlpha: number): number
	local alphaRange = self:getAlphaRange()
	local result = math.clamp(routeAlpha, alphaRange.Min, alphaRange.Max)
	return result
end

--[[
Converts the given alpha to the index and the relative alpha on a segment.

@return (number) The segment's index.
@return (number) The relative alpha on the segment.
]]
function LinkedRoute.getSegmentAtAlpha(self: ClassType, routeAlpha: number, willClampAlpha: boolean?): (number, number)
    local alphaRange
    local segmentIndex
    local prefixTotalAlpha
    local nextPrefixTotalAlpha
    local segment
    local segmentCount = self:getSegmentCount()
    local segmentAlpha

    if willClampAlpha then
        alphaRange = self:getAlphaRange()
        routeAlpha = math.clamp(routeAlpha, alphaRange.Min, alphaRange.Max)
    end

    segmentIndex = 0
    nextPrefixTotalAlpha = 0
    repeat
        prefixTotalAlpha = nextPrefixTotalAlpha
        segmentIndex += 1
        segment = self:getSegmentByIndex(segmentIndex)
        nextPrefixTotalAlpha += segment:getAlphaRange_scalar()
    until segmentIndex >= segmentCount or nextPrefixTotalAlpha >= routeAlpha
    segmentAlpha = routeAlpha - prefixTotalAlpha

    return segmentIndex, segmentAlpha
end


----- Position & direction functions -----

--[[
Gets the position at the given alpha.
]]
function LinkedRoute.getPositionAtAlpha(self: ClassType, routeAlpha: number, willClampAlpha: boolean?): Vector3
    local segmentIndex
    local segmentAlpha
    segmentIndex, segmentAlpha = self:getSegmentAtAlpha(routeAlpha, willClampAlpha)
    return self:getSegmentByIndex(segmentIndex):getPositionAtAlpha(segmentAlpha)
end

--[[
Gets the positively oriented unit tangent vector to the route at the given alpha.
]]
function LinkedRoute.getPositiveDirectionAtAlpha(self: ClassType, routeAlpha: number, willClampAlpha: boolean?): Vector3
	local segmentIndex
    local segmentAlpha
    segmentIndex, segmentAlpha = self:getSegmentAtAlpha(routeAlpha, willClampAlpha)
    return self:getSegmentByIndex(segmentIndex):getPositiveDirectionAtAlpha(segmentAlpha)
end

--[[
Gets a <code>CFrame</code> positioned at the given alpha with <code>LookVector</code> directed along the unit tangent vector at the given alpha.
]]
function LinkedRoute.getCFrameAtAlpha(self: ClassType, routeAlpha: number, willClampAlpha: boolean?): CFrame
    local alphaRange
    if willClampAlpha then
        alphaRange = self:getAlphaRange()
        routeAlpha = math.clamp(routeAlpha, alphaRange.Min, alphaRange.Max)
    end
    return CFrame.lookAlong(self:getPositionAtAlpha(routeAlpha), self:getPositiveDirectionAtAlpha(routeAlpha))
end


----- Clean up functions -----

--[[
Cleans up the route by clearing the stored segments.
]]
function LinkedRoute.cleanUp(self: ClassType)
    self:clearSegments()
end


---------- Return module ----------

return LinkedRoute
