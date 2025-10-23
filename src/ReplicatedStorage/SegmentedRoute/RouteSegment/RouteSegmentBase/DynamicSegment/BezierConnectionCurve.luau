--!strict

-- Bezier Connection Curve
-- Dynamic bezier curve segment that joins two `RouteSegmentBase` segments with a given continuity.


---------- Imports ----------

local DynamicSegment = require(script.Parent)

local RouteSegmentBase = require(script.Parent.Parent)
local BezierCurve = require(script.Parent.Parent.BezierCurve)


---------- Module ----------

local BezierConnectionCurve = setmetatable({}, DynamicSegment)
BezierConnectionCurve.__index = BezierConnectionCurve


---------- Module types ----------

type ClassData = {
    _segment1: RouteSegmentBase.ClassType,
    _segment2: RouteSegmentBase.ClassType,
    continuity: number,

    _bezierCurve: BezierCurve.ClassType,
}

type InheritedType = DynamicSegment.ClassType
export type ClassType = InheritedType & ClassData & typeof(BezierConnectionCurve)


---------- Module fields ----------

--[[
Constructs a new <code>BezierConnectionCurve</code> object.
Continuity: https://en.wikipedia.org/wiki/Smoothness#Smoothness_of_curves_and_surfaces

@param continuity number A nonnegative number representing the smoothness of joined segments. Recommend values 1 to 3.
]]
function BezierConnectionCurve.new(segment1: RouteSegmentBase.ClassType, segment2: RouteSegmentBase.ClassType, continuity: number): ClassType
	local self = setmetatable(DynamicSegment.new() :: any, BezierConnectionCurve) :: ClassType
	self._class = "BezierConnectionCurve"
    self._segment1 = segment1
    self._segment2 = segment2
    self.continuity = continuity
    self:update()
	return self
end


----- Update functions -----

--[[
Updates the stored control points to smoothly connect the segments.
]]
function BezierConnectionCurve.updateControlPoints(self: ClassType)
    local segment1AlphaMax
    local segment2AlphaMin
    local temporaryBezierCurve
    local k = self.continuity

    segment1AlphaMax = self._segment1:getAlphaRange().Max
    segment2AlphaMin = self._segment2:getAlphaRange().Min

    -- Base case
    if k == 0 then
        temporaryBezierCurve = BezierCurve.new()
        temporaryBezierCurve:addControlPoint_data(self._segment1:getHigherOrderDerivativeAtAlpha(k, segment1AlphaMax))
        temporaryBezierCurve:addControlPoint_data(self._segment2:getHigherOrderDerivativeAtAlpha(k, segment2AlphaMin))
    elseif k == 1 then
        local pos1, pos2
        local deriv1, deriv2
        temporaryBezierCurve = BezierCurve.new()
        pos1 = self._segment1:getPositionAtAlpha(segment1AlphaMax)
        pos2 = self._segment2:getPositionAtAlpha(segment2AlphaMin)
        deriv1 = self._segment1:getFirstDerivativeAtAlpha(segment1AlphaMax)
        deriv2 = self._segment2:getFirstDerivativeAtAlpha(segment2AlphaMin)
        temporaryBezierCurve:addControlPoint_data(pos1)
        temporaryBezierCurve:addControlPoint_data(pos1 + deriv1 / 3) -- deriv1 = deltaPos * 3
        temporaryBezierCurve:addControlPoint_data(pos2 - deriv2 / 3) -- deriv2 = -deltaPos * 3
        temporaryBezierCurve:addControlPoint_data(pos2)
    end

    -- General case
    if k > 1 then
        -- Create two bezier curves (k = continuity)
        local firstCurve = BezierCurve.new()
        local secondCurve = BezierCurve.new()
        local controlPointCount = k + 1
        local tempK = k

        -- Initialize each curve with dummy control points
        for i = 1, controlPointCount do
            firstCurve:addControlPoint_data(Vector3.zero)
            secondCurve:addControlPoint_data(Vector3.zero)
        end

        -- Get antiderivative bezier curves until 1st derivative
        while tempK >= 1 do
            firstCurve = firstCurve:getAntiderivativeCurve(self._segment1:getHigherOrderDerivativeAtAlpha(tempK, segment1AlphaMax))
            secondCurve = secondCurve:getAntiderivativeCurve(-self._segment2:getHigherOrderDerivativeAtAlpha(tempK, segment2AlphaMin))
            tempK -= 1
        end

        -- Get antiderive bezier curves at position
        firstCurve = firstCurve:getAntiderivativeCurve(self._segment1:getPositionAtAlpha(segment1AlphaMax))
        secondCurve = secondCurve:getAntiderivativeCurve(self._segment2:getPositionAtAlpha(segment2AlphaMin))

        -- Connect the two bezier curves
        temporaryBezierCurve = BezierCurve.new()
        for index = 1, controlPointCount do
            temporaryBezierCurve:addControlPoint_data(firstCurve:getControlPointPositionByIndex(index))
        end
        for index = controlPointCount, 1, -1 do
            temporaryBezierCurve:addControlPoint_data(secondCurve:getControlPointPositionByIndex(index))
        end
    end


    -- Update segment states
    self.controlPoints = temporaryBezierCurve.controlPoints
    self._bezierCurve = temporaryBezierCurve
end


----- Alpha functions -----

--[[
Gets the alpha range (as <code>NumberRange</code>) of the segment.
]]
function BezierConnectionCurve.getAlphaRange(self: ClassType): NumberRange
	return self._bezierCurve:getAlphaRange()
end


----- Position functions -----

--[[
Gets the position at the given alpha.
]]
function BezierConnectionCurve._getPositionAlpha_dynamic(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
    return self._bezierCurve:getPositionAtAlpha(alpha, willClampAlpha)
end


----- First derivative functions -----

--[[
Gets the value of the first derivative at the given alpha.
]]
function BezierConnectionCurve._getFirstDerivativeAtAlpha_dynamic(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	return self._bezierCurve:getFirstDerivativeAtAlpha(alpha, willClampAlpha)
end

----- Higher order derivative functions -----

--[[
Gets the value of the kth derivative at the given alpha.
]]
function BezierConnectionCurve._getHigherOrderDerivativeAtAlpha_dynamic(self: ClassType, kthDerivative: number, alpha: number, willClampAlpha: boolean?): Vector3
	return self._bezierCurve:getHigherOrderDerivativeAtAlpha(kthDerivative, alpha, willClampAlpha)
end


---------- Return module ----------

table.freeze(BezierConnectionCurve)
return BezierConnectionCurve
