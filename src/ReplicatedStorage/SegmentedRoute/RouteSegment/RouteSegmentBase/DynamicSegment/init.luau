--!strict

-- Dynamic Segment
-- Abstract class for dynamically updated route segments.


---------- Imports ----------

local RouteSegmentBase = require(script.Parent)


---------- Constants ----------

local Constants = {}

Constants.minUpdateTime = 0.0001


---------- Module ----------

local DynamicSegment = setmetatable({}, RouteSegmentBase)
DynamicSegment.__index = DynamicSegment


---------- Module types ----------

type ClassData = {
	_lastUpdateTime: number,
}

type InheritedType = RouteSegmentBase.ClassType
export type ClassType = InheritedType & ClassData & typeof(DynamicSegment)


---------- Module fields ----------

--[[
Constructs a new <code>DynamicSegment</code> object.
]]
function DynamicSegment.new(): ClassType
	local self = setmetatable(RouteSegmentBase.new() :: any, DynamicSegment) :: ClassType
	self._class = "DynamicSegment"
	self._lastUpdateTime = -1
	return self
end


----- Update functions -----

--[[
Updates the segment's data.
]]
function DynamicSegment.update(self: ClassType)
	if time() > self._lastUpdateTime + Constants.minUpdateTime then
		self:updateControlPoints()
		self._lastUpdateTime = time()
	end
end

--[[
Updates the stored control points.
]]
function DynamicSegment.updateControlPoints(self: ClassType)
end


----- Control point functions -----

function DynamicSegment.getControlPointPositionByIndex(self: ClassType, controlPointIndex: number): Vector3
    self:update()
	return RouteSegmentBase.getControlPointPositionByIndex(self, controlPointIndex)
end

function DynamicSegment.getControlPointCount(self: ClassType): number
    self:update()
	return #self.controlPoints
end


----- Position functions -----

--[[
Gets the position at the given alpha.
]]
function DynamicSegment._getPositionAlpha_dynamic(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
    warn(`[DynamicSegment]: Abstract unimplemented function: getPositionAlpha_dynamic!`)
    return Vector3.zero
end

--[[
Gets the position at the given alpha.
Don't override this function!
Instead, override <code>_getPositionAlpha_dynamic()</code>.
]]
function DynamicSegment.getPositionAtAlpha(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	self:update()
	return self:_getPositionAlpha_dynamic(alpha, willClampAlpha)
end


----- First derivative functions -----

--[[
Gets the value of the first derivative at the given alpha.
]]
function DynamicSegment._getFirstDerivativeAtAlpha_dynamic(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	warn(`[DynamicSegment]: Abstract unimplemented function: getFirstDerivativeAtAlpha_dynamic!`)
    return Vector3.zero
end
    
--[[
Gets the value of the first derivative at the given alpha.
Don't override this function!
Instead, override <code>_getFirstDerivativeAtAlpha_dynamic()</code>.
]]
function DynamicSegment.getFirstDerivativeAtAlpha(self: ClassType, alpha: number, willClampAlpha: boolean?): Vector3
	self:update()
	return self:_getFirstDerivativeAtAlpha_dynamic(alpha, willClampAlpha)
end


----- Higher order derivative functions -----

--[[
Gets the value of the kth derivative at the given alpha.
]]
function DynamicSegment._getHigherOrderDerivativeAtAlpha_dynamic(self: ClassType, kthDerivative: number, alpha: number, willClampAlpha: boolean?): Vector3
	warn("[DynamicSegment]: Abstract unimplemented function: getHigherOrderDerivativeAtAlpha_dynamic!")
	return Vector3.zero
end

--[[
Gets the value of the kth derivative at the given alpha.
Don't override this function!
Instead, override <code>_getHigherOrderDerivativeAtAlpha_dynamic()</code>.
]]
function DynamicSegment.getHigherOrderDerivativeAtAlpha(self: ClassType, kthDerivative: number, alpha: number, willClampAlpha: boolean?): Vector3
	self:update()
	return self:_getHigherOrderDerivativeAtAlpha_dynamic(kthDerivative, alpha, willClampAlpha)
end


---------- Return module ----------

table.freeze(DynamicSegment)
return DynamicSegment
