--!strict

-- Route Visualizer
-- Utility module for visualizing <code>LinkedRoute</code>.


---------- Imports ----------

local LinkedRoute = require(script.Parent.Parent.LinkedRoute)


---------- Types ----------

export type ColorRange = {Color3}


---------- Local functions ----------

----- Color functions -----

local colorizePart

colorizePart = function(part: BasePart, colorRange: ColorRange?, alpha: number)
    if colorRange then
        if #colorRange == 1 then
            part.Color = colorRange[1]
        elseif #colorRange == 2 then
            part.Color = colorRange[1]:Lerp(colorRange[2], alpha)
        end
    end
end


---------- Module ----------

local RouteVisualizer = {}


---------- Module fields ----------

----- Variables -----

RouteVisualizer.visualizerInstancesFolder = Instance.new("Folder")
RouteVisualizer.visualizerInstancesFolder.Name = "RouteVisualizerInstances"
RouteVisualizer.visualizerInstancesFolder.Parent = workspace


----- Visualization functions -----

--[[
Creates parts at equal parameter steps on the route. An additional part will be created at the end of the route.<br>
If the route is modified after the function is called, destroy the returned <code>Folder</code> and call this function again to update the visualized route.

@return (Instance) The <code>Folder</code> containing the created parts.
@return ({Part}) A table containing the created parts in sequential order.
]]
function RouteVisualizer.createParts_equalSteps(linkedRoute: LinkedRoute.ClassType, defaultPart: BasePart, autoResizePartLength: boolean, colorRange: ColorRange?, zeroAlphaParameter: number, deltaParameter: number, parameterToAlpha_function: ((parameter: number) -> number)?)
    local partsFolder
    local createdParts = {}
    local createdPartCount
    local alphaRange = linkedRoute:getAlphaRange()
    local alphaRange_scalar = linkedRoute:getAlphaRange_scalar()
    local parameter
    local alpha
    local newPart

    partsFolder = Instance.new("Folder")
    partsFolder.Name = "PartsFolder"
    createdPartCount = 0
    parameter = zeroAlphaParameter
    alpha = parameterToAlpha_function and parameterToAlpha_function(parameter) or parameter
    repeat
        -- Create part at alpha
        newPart = defaultPart:Clone()
        table.insert(createdParts, newPart)
        createdPartCount += 1
        colorizePart(newPart, colorRange, (alpha - alphaRange.Min) / alphaRange_scalar)
        newPart.CFrame = linkedRoute:getCFrameAtAlpha(alpha)
        newPart.Name = string.format("%5d", createdPartCount)

        -- Get next alpha
        parameter += deltaParameter
        alpha = parameterToAlpha_function and parameterToAlpha_function(parameter) or parameter
    until alpha > alphaRange.Max

    -- Case for last alpha 
    do
        -- Create part at alpha
        alpha = alphaRange.Max
        newPart = defaultPart:Clone()
        table.insert(createdParts, newPart)
        createdPartCount += 1
        colorizePart(newPart, colorRange, (alpha - alphaRange.Min) / alphaRange_scalar)
        newPart.CFrame = linkedRoute:getCFrameAtAlpha(alpha)
        newPart.Name = string.format("%.3f", alpha)
    end

    -- Resize parts for connection
    if autoResizePartLength then
        local currentPart
        local nextPart
        local partPositionDifferenceVector
        local partDistance
        local partMidPosition
        local lastPart

        -- Resize each part
        nextPart = createdParts[1]
        for partIndex = 1, createdPartCount - 1 do
            currentPart = nextPart
            nextPart = createdParts[partIndex + 1]

            -- Get info
            partPositionDifferenceVector = nextPart.Position - currentPart.Position
            partDistance = partPositionDifferenceVector.Magnitude
            partMidPosition = currentPart.Position + partPositionDifferenceVector / 2

            -- Modify part
            currentPart.Size = Vector3.new(currentPart.Size.X, currentPart.Size.Y, partDistance)
            currentPart.CFrame = CFrame.lookAlong(partMidPosition, partPositionDifferenceVector)
        end

        -- Remove last part
        lastPart = table.remove(createdParts)
        if lastPart then
            createdPartCount -= 1
            lastPart:Destroy()
        end
    end

    -- Parent parts to folder
    for _, part in createdParts do
        part.Parent = partsFolder
    end
    partsFolder.Parent = RouteVisualizer.visualizerInstancesFolder

    return partsFolder, createdParts
end


---------- Return module ----------

return RouteVisualizer
