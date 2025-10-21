--!strict

-- Bezier Curve
-- A bezier (bézier) curve is a parametric curve defined by a set of control points.
-- https://en.wikipedia.org/wiki/B%C3%A9zier_curve


---------- Imports ----------

local RouteSegmentBase = require(script.Parent)


---------- Module ----------

local BezierCurve = setmetatable({}, RouteSegmentBase)
BezierCurve.__index = BezierCurve


---------- Module types ----------

type ClassData = {}

type InheritedType = RouteSegmentBase.ClassType
export type ClassType = InheritedType & ClassData & typeof(BezierCurve)


---------- Module fields ----------

--[[
Constructs a new <code>BezierCurve</code> object.
]]
function BezierCurve.new(): ClassType
	local self = setmetatable(RouteSegmentBase.new() :: any, BezierCurve) :: ClassType
	self._class = "BezierCurve"
	return self
end


----- Alpha functions -----

function BezierCurve.getAlphaRange(self: ClassType): NumberRange
	local result = NumberRange.new(0, 1)
	return result
end


----- Position functions -----

--[[
Gets the position at the given alpha using De Casteljau's algorithm.
https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm
]]
function BezierCurve._getPositionAtAlpha_deCasteljau(self: ClassType, alpha: number, firstId: number, lastId: number): Vector3
	local lerp1
	local lerp2
	local result

	if not (firstId and lastId) then
		warn("[BezierCurve]: _getPositionAtAlpha_deCasteljau should have `firstId` and `lastId` provided!")
	end

	if firstId > lastId then
		warn(`[BezierCurve]: _getPositionAtAlpha_deCasteljau has invalid range ({firstId}, {lastId})!`)
	elseif firstId == lastId then
		result = self:getControlPointPositionByIndex(firstId)
	else
		lerp1 = self:_getPositionAtAlpha_deCasteljau(alpha, firstId, lastId - 1)
		lerp2 = self:_getPositionAtAlpha_deCasteljau(alpha, firstId + 1, lastId)
		if lerp1 and lerp2 then
			result = lerp1:Lerp(lerp2, alpha)
		end
	end
	assert(result, "[BezierCurve]: _getPositionAtAlpha_deCasteljau failed to compute!")
	return result
end

function BezierCurve.getPositionAtAlpha(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	local result
	if willClampAlpha then
		alpha = self:clampAlpha(alpha)
	end
	result = self:_getPositionAtAlpha_deCasteljau(alpha, 1, self:getControlPointCount())
	return result
end


----- First derivative functions -----

--[[
Gets the first derivative bezier curve.
Formula: https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Derivative
]]
function BezierCurve.getFirstDerivativeCurve(self: ClassType): ClassType
	local degree
	local newBezierCurve
	local position1
	local position2
	local newControlPointPosition

	degree = self:getControlPointCount() - 1
	if degree == 0 then
		warn("[BezierCurve]: getFirstDerivativeCurve is called on a zero degree bezier curve!")
	end

	newBezierCurve = BezierCurve.new()
	position1 = self:getControlPointPositionByIndex(1)
	for id = 1, degree do
		position2 = self:getControlPointPositionByIndex(id + 1)
		newControlPointPosition = degree * (position2 - position1)
		newBezierCurve:addControlPoint_data(newControlPointPosition)
		position1 = position2
	end

	return newBezierCurve
end

--[[
Gets the value of the first derivative at the given alpha.
Formula: https://pages.mtu.edu/~shene/COURSES/cs3621/NOTES/spline/Bezier/bezier-der.html
]]
function BezierCurve._getFirstDerivativeAtAlpha_deCasteljau(self: ClassType, alpha: number): Vector3
	local degree
	local position1
	local position2
	local result

	degree = self:getControlPointCount() - 1
	if degree == 0 then
		warn("[BezierCurve]: _getFirstDerivativeAtAlpha_deCasteljau is called on a zero degree bezier curve!")
	end

	position1 = self:_getPositionAtAlpha_deCasteljau(alpha, 1, degree)
	position2 = self:_getPositionAtAlpha_deCasteljau(alpha, 2, degree + 1)
	if position1 and position2 then
		result = degree * (position2 - position1)
	end
	assert(result, "[BezierCurve]: _getFirstDerivativeAtAlpha_deCasteljau failed to compute!")
	return result
end

function BezierCurve.getFirstDerivativeAtAlpha(self: ClassType, alpha: number, willClampAlpha: number?): Vector3
	local result
	if willClampAlpha then
		alpha = self:clampAlpha(alpha)
	end
	result = self:_getFirstDerivativeAtAlpha_deCasteljau(alpha)
	return result
end


----- Higher order derivative functions -----

--[[
Gets the kth derivative bezier curve.
]]
function BezierCurve.getHigherOrderDerivativeCurve(self: ClassType, kthDerivative: number): ClassType
	local derivativeBezierCurve = self
	for i = 1, kthDerivative do
		derivativeBezierCurve = derivativeBezierCurve:getFirstDerivativeCurve()
	end
	return derivativeBezierCurve
end

function BezierCurve.getHigherOrderDerivativeAtAlpha(self: ClassType, kthDerivative: number, alpha: number, willClampAlpha: boolean?): Vector3
	return self:getHigherOrderDerivativeCurve(kthDerivative):getPositionAtAlpha(alpha, willClampAlpha)
end


---------- Return module ----------

table.freeze(BezierCurve)
return BezierCurve
