--!strict

-- Route Segment
-- Package for route segment classes.


---------- Imports ----------

local RouteSegmentBase = require(script.RouteSegmentBase)
local BezierCurve = require(script.RouteSegmentBase.BezierCurve)
local DynamicSegment = require(script.RouteSegmentBase.DynamicSegment)
local BezierConnectionCurve = require(script.RouteSegmentBase.DynamicSegment.BezierConnectionCurve)


---------- Types ----------

export type RouteSegmentBase = RouteSegmentBase.ClassType
export type BezierCurve = BezierCurve.ClassType
export type DynamicSegment = DynamicSegment.ClassType
export type BezierConnectionCurve = BezierConnectionCurve.ClassType


---------- Module ----------

local RouteSegment = {}


---------- Module fields ----------

----- Sub-modules -----

RouteSegment.RouteSegmentBase = RouteSegmentBase
RouteSegment.BezierCurve = BezierCurve
RouteSegment.DynamicSegment = DynamicSegment
RouteSegment.BezierConnectionCurve = BezierConnectionCurve


---------- Return module ----------

table.freeze(RouteSegment)
return RouteSegment
