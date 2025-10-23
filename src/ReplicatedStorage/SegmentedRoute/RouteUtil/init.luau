--!strict

-- Route Util
-- Utility modules to further supplement with <code>LinkedRoute</code> and <code>RouteSegmentBase</code>.


---------- Imports ----------

local LinkedRoute = require(script.Parent.LinkedRoute)


----- Sub-modules -----

local RouteReparam = require(script.RouteReparam)
local RouteVisualizer = require(script.RouteVisualizer)


---------- Types ----------

export type ColorRange = RouteVisualizer.ColorRange
export type PartVisualizerInfo_Input = RouteVisualizer.PartVisualizerInfo_Input


---------- Module ----------

local RouteUtil = {}


---------- Module fields ----------

----- Sub-modules -----

RouteUtil.Reparam = RouteReparam
RouteUtil.Visualizer = RouteVisualizer


----- Combination functions -----

--[[
Creates parts at equal distance steps on the route. An additional part will be created at the end of the route.<br>
If the route is modified after the function is called, destroy the returned <code>Folder</code> and call this function again to update the visualized route.

@return ((number, boolean) -> number) The reparameterization function to convert between alpha and distance.
@return (Instance) The <code>Folder</code> containing the created parts.
@return ({BasePart}) A table containing the created parts in sequential order.
]]

function RouteUtil.createParts_equalDistanceSteps(linkedRoute: LinkedRoute.ClassType, visualizerInfo_input: PartVisualizerInfo_Input, autoResizePartLength: boolean, deltaDistance: number)
    local reparameterization_function = RouteReparam.getRoute_reparameterization_function(linkedRoute)
    local partFolder, createdParts = RouteVisualizer.createParts_equalSteps(linkedRoute, visualizerInfo_input, autoResizePartLength, 0, deltaDistance, function(parameter: number)
        return reparameterization_function(parameter, true)
    end)
    return reparameterization_function, partFolder, createdParts
end


---------- Return module ----------

table.freeze(RouteUtil)
return RouteUtil
