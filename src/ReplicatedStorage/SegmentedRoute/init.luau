--!strict

-- Segmented Route
-- Package of modules for managing segments and routes.


---------- Imports ----------

local ControlPoint = require(script.ControlPoint)
local RouteSegment = require(script.RouteSegment)
local LinkedRoute = require(script.LinkedRoute)
local RouteUtil = require(script.RouteUtil)


---------- Types ----------

export type ControlPoint = ControlPoint.ClassType

export type RouteSegmentBase = RouteSegment.RouteSegmentBase
export type BezierCurve = RouteSegment.BezierCurve

export type LinkedRoute = LinkedRoute.ClassType


---------- Module ----------

local SegmentedRoute = {}


---------- Module fields ----------

SegmentedRoute.ControlPoint = ControlPoint
SegmentedRoute.RouteSegment = RouteSegment
SegmentedRoute.LinkedRoute = LinkedRoute
SegmentedRoute.RouteUtil = RouteUtil


---------- Return module ----------

return SegmentedRoute
