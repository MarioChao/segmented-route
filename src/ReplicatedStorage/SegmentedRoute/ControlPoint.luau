--!strict

-- Control Point
-- Class for control point and positions.


---------- Types ----------

export type ControlPointData = Attachment | Vector3


---------- Module ----------

local ControlPoint = {}
ControlPoint.__index = ControlPoint


---------- Module types ----------

type ClassData = {
    data: ControlPointData
}

export type ClassType = ClassData & typeof(ControlPoint)


---------- Module fields ----------

--[[
Constructs a new <code>ControlPoint</code> object.
]]
function ControlPoint.new(data: ControlPointData): ClassType
    local self = setmetatable({} :: any, ControlPoint) :: ClassType
    self.data = data
    return self
end


----- Data validation functions -----

--[[
Validates if the given data can be used for a control point.

@return (boolean) Whether the data is valid.
]]
function ControlPoint.validateData(data: any, willPrintWarning: boolean?): boolean
    local result = false

    if typeof(data) == "Vector3" then
        result = true
    elseif typeof(data) == "Instance" then
        if data:IsA("Attachment") then
            result = true
        end
    end

    if not result and willPrintWarning then
        warn(`[ControlPoint]: validateData expects a Vector3 or Instance, got {data}!`)
    end

    return result
end


----- Position functions -----

--[[
Gets the position of the control point.
]]
function ControlPoint.getPosition(self: ClassType): Vector3
	local result
	if typeof(self.data) == "Vector3" then
		result = self.data
	elseif self.data:IsA("Attachment") then
		result = self.data.WorldPosition
	end
	return result
end


---------- Return module ----------

table.freeze(ControlPoint)
return ControlPoint
