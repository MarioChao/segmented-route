--!strict

-- Route Segment
-- Package for route segment classes.


---------- Imports ----------

local RouteSegmentBase = require(script.RouteSegmentBase)
local BezierCurve = require(script.RouteSegmentBase.BezierCurve)


---------- Types ----------

export type RouteSegmentBase = RouteSegmentBase.ClassType
export type BezierCurve = BezierCurve.ClassType


---------- Module ----------

local RouteSegment = {}


---------- Module fields ----------

RouteSegment.RouteSegmentBase = RouteSegmentBase
RouteSegment.BezierCurve = BezierCurve


---------- Return module ----------

return RouteSegment
