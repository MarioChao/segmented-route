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


----- Static functions -----

--[[
Evaluates a bezier curve at the given alpha using De Casteljau's algorithm.
https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm
]]
function BezierCurve._evaluateDeCasteljau(alpha: number, controlPointPositions: {Vector3}): Vector3
	local newControlPointPositions = {}
	local position1
	local position2
	local result

	if #controlPointPositions == 0 then
		warn(`[BezierCurve]: deCasteljau received empty control point positions!`)
	elseif #controlPointPositions == 1 then
		result = controlPointPositions[1]
	else
		position1 = controlPointPositions[1]
		for index = 1, #controlPointPositions - 1 do
			position2 = controlPointPositions[index + 1]
			table.insert(newControlPointPositions, position1:Lerp(position2, alpha))
			position1 = position2
		end
		result = BezierCurve._evaluateDeCasteljau(alpha, newControlPointPositions)
	end
	assert(result, "[BezierCurve]: deCasteljau failed to compute!")
	return result
end


----- Alpha functions -----

function BezierCurve.getAlphaRange(self: ClassType): NumberRange
	local result = NumberRange.new(0, 1)
	return result
end


----- Position functions -----

function BezierCurve.getPositionAtAlpha(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	local result
	if willClampAlpha then
		alpha = self:clampAlpha(alpha)
	end
	result = BezierCurve._evaluateDeCasteljau(alpha, self:getControlPointPositions())
	return result
end


----- Antiderivative functions -----

--[[
Gets the antiderivative bezier curve.
]]
function BezierCurve.getAntiderivativeCurve(self: ClassType, startAntiderivative: Vector3): ClassType
	local originalDegree
	local newBezierCurve
	local originalPosition
	local previousControlPointPosition
	local newControlPointPosition

	originalDegree = self:getControlPointCount() - 1
	newBezierCurve = BezierCurve.new()
	newBezierCurve:addControlPoint_data(startAntiderivative)
	previousControlPointPosition = startAntiderivative
	for id = 1, originalDegree + 1 do
		originalPosition = self:getControlPointPositionByIndex(id)
		-- From derivative: derivPosition = degree * (position2 - position1)
		-- Its equivalence: origPosition = (degree + 1) * (newAntiderivPosition - prevAntiderivPosition)
		-- Solved position: newAntiderivPosition = origPosition / (degree + 1) + prevAntiderivPosition
		newControlPointPosition = originalPosition / (originalDegree + 1) + previousControlPointPosition
		newBezierCurve:addControlPoint_data(newControlPointPosition)
		previousControlPointPosition = newControlPointPosition
	end

	return newBezierCurve
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

	newBezierCurve = BezierCurve.new()
	if degree > 0 then
		position1 = self:getControlPointPositionByIndex(1)
		for id = 1, degree do
			position2 = self:getControlPointPositionByIndex(id + 1)
			newControlPointPosition = degree * (position2 - position1)
			newBezierCurve:addControlPoint_data(newControlPointPosition)
			position1 = position2
		end
	end

	return newBezierCurve
end

--[[
Gets the value of the first derivative at the given alpha.
Formula: https://pages.mtu.edu/~shene/COURSES/cs3621/NOTES/spline/Bezier/bezier-der.html
]]
function BezierCurve._getFirstDerivativeAtAlpha_deCasteljau(self: ClassType, alpha: number): Vector3
	local degree
	local controlPointCount
	local position1
	local position2
	local result

	degree = self:getControlPointCount() - 1
	if degree <= 0 then
		result = Vector3.zero
	else
		controlPointCount = self:getControlPointCount()
		position1 = BezierCurve._evaluateDeCasteljau(alpha, self:getControlPointPositions(1, controlPointCount - 1))
		position2 = BezierCurve._evaluateDeCasteljau(alpha, self:getControlPointPositions(2, controlPointCount))
		if position1 and position2 then
			result = degree * (position2 - position1)
		end
	end

	assert(result, "[BezierCurve]: getFirstDerivativeCurve failed to compute!")
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
	local result
	if kthDerivative == 0 then
		result = self:getPositionAtAlpha(alpha, willClampAlpha)
	else
		result = self:getHigherOrderDerivativeCurve(kthDerivative - 1):getFirstDerivativeAtAlpha(alpha, willClampAlpha)
	end
	return result
end


---------- Return module ----------

table.freeze(BezierCurve)
return BezierCurve
