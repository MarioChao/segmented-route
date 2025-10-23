--!strict

-- Route Segment Base
-- Abstract class for route segment objects.


---------- Imports ----------

local ControlPoint = require(script.Parent.Parent.ControlPoint)


---------- Module ----------

local RouteSegmentBase = {}
RouteSegmentBase.__index = RouteSegmentBase


---------- Module types ----------

type ClassData = {
	_class: string,
	controlPoints: {ControlPoint.ClassType},
}

export type ClassType = ClassData & typeof(RouteSegmentBase)


---------- Module fields ----------

--[[
Constructs a new <code>RouteSegmentBase</code> object.
This method should only be used for creating inherited class.
]]
function RouteSegmentBase.new(): ClassType
	local self = setmetatable({} :: any, RouteSegmentBase) :: ClassType
	self._class = "RouteSegmentBase"
	self.controlPoints = {}
	return self
end


----- Control point functions -----

--[[
Adds a new <code>ControlPoint</code> from a child <code>Attachment</code> of a <code>BasePart</code>.
]]
function RouteSegmentBase.addControlPointPart_getOrCreateAttachment(self: ClassType, part: BasePart, attachmentName: string)
	local attachment
	local foundAttachment = part:FindFirstChild(attachmentName)
	if typeof(part) == "Instance" and part:IsA("BasePart") then
		if foundAttachment and foundAttachment:IsA("Attachment") then
			attachment = foundAttachment
		else
			attachment = Instance.new("Attachment")
			attachment.Name = attachmentName
			attachment.Parent = part
		end
		table.insert(self.controlPoints, ControlPoint.new(attachment))
	else
		warn(`[RouteSegmentBase]: addControlPointPart_getOrCreateAttachment only accepts BasePart, got {part}!`)
	end
end

--[[
Adds a new <code>ControlPoint</code>.
]]
function RouteSegmentBase.addControlPoint(self: ClassType, controlPoint: ControlPoint.ClassType)
	table.insert(self.controlPoints, controlPoint)
end

--[[
Adds a new <code>ControlPoint</code> using the <code>ControlPoint.new()</code> constructor.
]]
function RouteSegmentBase.addControlPoint_data(self: ClassType, data: ControlPoint.ControlPointData)
	if ControlPoint.validateData(data, true) then
		table.insert(self.controlPoints, ControlPoint.new(data))
	end
end

--[[
Gets the position of a stored <code>ControlPoint</code> by its index.
]]
function RouteSegmentBase.getControlPointPositionByIndex(self: ClassType, controlPointIndex: number): Vector3
	local result
	if 1 <= controlPointIndex and controlPointIndex <= self:getControlPointCount() then
		result = self.controlPoints[controlPointIndex]:getPosition()
	else
		warn(`[RouteSegmentBase]: getControlPointPositionByIndex received a controlPointId ({controlPointIndex}) that's out of range!`)
	end
	return result
end

--[[
Gets the positions of the specified range of control points.
]]
function RouteSegmentBase.getControlPointPositions(self: ClassType, firstIndex: number?, lastIndex: number?): {Vector3}
	local result = {}
	local controlPointCount = self:getControlPointCount()
	local sanitizedFirstId
	local sanitizedLastId

	sanitizedFirstId = firstIndex or 1
	sanitizedFirstId = math.max(sanitizedFirstId, 1)
	sanitizedLastId = lastIndex or controlPointCount
	sanitizedLastId = math.min(sanitizedLastId, controlPointCount)

	for index = sanitizedFirstId, sanitizedLastId do
		table.insert(result, self.controlPoints[index]:getPosition())
	end
	return result
end

--[[
Gets the number of control points.
]]
function RouteSegmentBase.getControlPointCount(self: ClassType): number
	return #self.controlPoints
end

--[[
Clears the stored control points.
]]
function RouteSegmentBase.clearControlPoints(self: ClassType)
	table.clear(self.controlPoints)
end


----- Alpha functions -----

--[[
Gets the alpha range (as <code>NumberRange</code>) of the segment.
]]
function RouteSegmentBase.getAlphaRange(self: ClassType): NumberRange
	warn("[RouteSegmentBase]: Abstract unimplemented function: getAlphaRange!")
	return NumberRange.new(0)
end

--[[
Gets the alpha range (as <code>number</code>) of the segment.
]]
function RouteSegmentBase.getAlphaRange_scalar(self: ClassType): number
	local alphaRange = self:getAlphaRange()
	return alphaRange.Max - alphaRange.Min
end

--[[
Returns whether the given alpha is in the segment's domain.
]]
function RouteSegmentBase.containsAlpha(self: ClassType, alpha: number): boolean
    local alphaRange = self:getAlphaRange()
    return alphaRange.Min <= alpha and alpha <= alphaRange.Max
end

--[[
Returns the given alpha clamped to the segment's domain.
]]
function RouteSegmentBase.clampAlpha(self: ClassType, alpha: number): number
	local alphaRange = self:getAlphaRange()
	local result = math.clamp(alpha, alphaRange.Min, alphaRange.Max)
	return result
end


----- Position functions -----

--[[
Gets the position at the given alpha.
]]
function RouteSegmentBase.getPositionAtAlpha(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	warn("[RouteSegmentBase]: Abstract unimplemented function: getPositionAtAlpha!")
	return Vector3.zero
end


----- First derivative functions -----

--[[
Gets the value of the first derivative at the given alpha.
]]
function RouteSegmentBase.getFirstDerivativeAtAlpha(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	warn("[RouteSegmentBase]: Abstract unimplemented function: getFirstDerivativeAtAlpha!")
	return Vector3.zero
end

--[[
Gets the positively oriented unit tangent vector at the given alpha.
]]
function RouteSegmentBase.getPositiveDirectionAtAlpha(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	local firstDerivative = self:getFirstDerivativeAtAlpha(alpha, willClampAlpha)
	if firstDerivative ~= Vector3.zero then
		firstDerivative = firstDerivative and firstDerivative.Unit
	end
	return firstDerivative
end


----- Higher order derivative functions -----

--[[
Gets the value of the kth derivative at the given alpha.
]]
function RouteSegmentBase.getHigherOrderDerivativeAtAlpha(self: ClassType, kthDerivative: number, alpha: number, willClampAlpha: boolean?): Vector3
	warn("[RouteSegmentBase]: Abstract unimplemented function: getHigherOrderDerivativeAtAlpha!")
	return Vector3.zero
end


----- Cleanup functions -----

--[[
Cleans up the segment by clearing the stored control points.
]]
function RouteSegmentBase.cleanUp(self: ClassType)
	self:clearControlPoints()
end


---------- Return module ----------

table.freeze(RouteSegmentBase)
return RouteSegmentBase
