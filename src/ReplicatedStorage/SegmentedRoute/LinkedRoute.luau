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


----- Static functions -----

--[[
Constructs a <code>LinkedRoute</code> object from a table of segments.
]]
function LinkedRoute.fromSegments(segments: {RouteSegment.RouteSegmentBase}): ClassType
    local self = LinkedRoute.new()
    for _, segment in segments do
        self:addSegment(segment)
    end
    return self
end


----- Segment functions -----

--[[
Adds a <code>RouteSegmentBase</code> to the end of the route.<br>
To add a segment that connects to the previous segment, consider using <code>LinkedRoute.addConnectedSegment()</code>.
]]
function LinkedRoute.addSegment(self: ClassType, segment: RouteSegment.RouteSegmentBase)
    table.insert(self._routeSegments, segment)
end

--[[
Adds a <code>RouteSegmentBase</code> joined with the previous segment (if exists) through a <code>BezierConnectionCurve</code>.

@param continuity number A nonnegative number representing the smoothness of joined segments. Recommend values 1 to 3.
]]
function LinkedRoute.addConnectedSegment(self: ClassType, segment: RouteSegment.RouteSegmentBase, continuity: number)
    local segmentCount = self:getSegmentCount()
    local previousSegment
    if segmentCount > 0 then
        previousSegment = self._routeSegments[segmentCount]
        self:addSegment(RouteSegment.BezierConnectionCurve.new(previousSegment, segment, continuity))
    end
    self:addSegment(segment)
end

--[[
Adds a <code>BezierConnectionCurve</code> to join the last segment with the first segment.

@param continuity number A nonnegative number representing the smoothness of joined segments. Recommend values 1 to 3.
]]
function LinkedRoute.connectLoop(self: ClassType, continuity: number)
    local segmentCount = self:getSegmentCount()
    local firstSegment
    local lastSegment
    if segmentCount > 0 then
        firstSegment = self._routeSegments[1]
        lastSegment = self._routeSegments[segmentCount]
        self:addSegment(RouteSegment.BezierConnectionCurve.new(lastSegment, firstSegment, continuity))
    end
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
function LinkedRoute.getSegmentByIndex(self: ClassType, segmentIndex: number): RouteSegment.RouteSegmentBase?
    local segmentCount = self:getSegmentCount()
    local result
    if segmentCount == 0 then
        warn(`[LinkedRoute] no segments in the route!`)
	elseif not (1 <= segmentIndex and segmentIndex <= segmentCount) then
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
    local alphaReached

    if willClampAlpha then
        alphaRange = self:getAlphaRange()
        routeAlpha = math.clamp(routeAlpha, alphaRange.Min, alphaRange.Max)
    end

    segmentIndex = 1
    prefixTotalAlpha = 0
    nextPrefixTotalAlpha = 0
    alphaReached = false
    while segmentIndex < segmentCount and not alphaReached do
        segment = self:getSegmentByIndex(segmentIndex)
        nextPrefixTotalAlpha += segment and segment:getAlphaRange_scalar() or 0
        if nextPrefixTotalAlpha < routeAlpha then
            segmentIndex += 1
            prefixTotalAlpha = nextPrefixTotalAlpha
        else
            alphaReached = true
        end
    end
    segmentAlpha = routeAlpha - prefixTotalAlpha

    return segmentIndex, segmentAlpha
end


----- Position & direction functions -----

--[[
Gets the position at the given alpha.
For an empty route, this would return <code>Vector3.zero</code>.
]]
function LinkedRoute.getPositionAtAlpha(self: ClassType, routeAlpha: number, willClampAlpha: boolean?): Vector3
    local segmentIndex
    local segmentAlpha
    local segment
    local result
    segmentIndex, segmentAlpha = self:getSegmentAtAlpha(routeAlpha, willClampAlpha)
    segment = self:getSegmentByIndex(segmentIndex)
    result = segment and segment:getPositionAtAlpha(segmentAlpha) or Vector3.zero
    return result
end

--[[
Gets the positively oriented unit tangent vector to the route at the given alpha.
]]
function LinkedRoute.getPositiveDirectionAtAlpha(self: ClassType, routeAlpha: number, willClampAlpha: boolean?): Vector3
	local segmentIndex
    local segmentAlpha
    local segment
    local result
    segmentIndex, segmentAlpha = self:getSegmentAtAlpha(routeAlpha, willClampAlpha)
    segment = self:getSegmentByIndex(segmentIndex)
    result = segment and segment:getPositiveDirectionAtAlpha(segmentAlpha) or Vector3.zero
    return result
end

--[[
Gets a <code>CFrame</code> positioned at the given alpha with <code>LookVector</code> directed along the unit tangent vector at the given alpha.
]]
function LinkedRoute.getCFrameAtAlpha(self: ClassType, routeAlpha: number, willClampAlpha: boolean?): CFrame
    local alphaRange
    local direction
    if willClampAlpha then
        alphaRange = self:getAlphaRange()
        routeAlpha = math.clamp(routeAlpha, alphaRange.Min, alphaRange.Max)
    end
    direction = self:getPositiveDirectionAtAlpha(routeAlpha)
    if direction == Vector3.zero then
        direction = Vector3.zAxis
    end
    return CFrame.lookAlong(self:getPositionAtAlpha(routeAlpha), direction)
end


----- Clean up functions -----

--[[
Cleans up the route by clearing the stored segments.
]]
function LinkedRoute.cleanUp(self: ClassType)
    self:clearSegments()
end


---------- Return module ----------

table.freeze(LinkedRoute)
return LinkedRoute
