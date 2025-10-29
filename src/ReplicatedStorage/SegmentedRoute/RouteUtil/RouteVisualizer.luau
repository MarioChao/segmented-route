--!strict

-- Route Visualizer
-- Utility module for visualizing <code>LinkedRoute</code>.


---------- Imports ----------

local LinkedRoute = require(script.Parent.Parent.LinkedRoute)


---------- Types ----------

export type ColorRange = {Color3}

export type PartVisualizerInfo_Input = {
    templatePart: BasePart?,
    colorRange: ColorRange?,
}?

type PartVisualizerInfo = {
    templatePart: BasePart,
    colorRange: ColorRange,
}

export type PartVisualizerParams_Input = {
    autoResizeLength: boolean?,
    createSpheres: boolean?,
}?

type PartVisualizerParams = {
    autoResizeLength: boolean,
    createSpheres: boolean,
}


---------- Constants ----------

local Constants = {}

Constants.defaultTemplatePart = Instance.new("Part")
Constants.defaultTemplatePart.Material = Enum.Material.Neon
Constants.defaultTemplatePart.Locked = true
Constants.defaultTemplatePart.Size = Vector3.new(0.5, 0.2, 0.2)
Constants.defaultTemplatePart.Anchored = true
Constants.defaultTemplatePart.Shape = Enum.PartType.Cylinder

Constants.defaultSpherePart = Instance.new("Part")
Constants.defaultSpherePart.Material = Enum.Material.Neon
Constants.defaultSpherePart.Locked = true
Constants.defaultSpherePart.Size = Vector3.new(0.2, 0.2, 0.2)
Constants.defaultSpherePart.Anchored = true
Constants.defaultSpherePart.Shape = Enum.PartType.Ball

Constants.defaultColorRange = {BrickColor.new("Royal blue").Color, BrickColor.new("Medium blue").Color}

Constants.defaultVisualizerParams = {
    autoResizeLength = false,
    createSpheres = false,
} :: PartVisualizerParams

Constants.connectedVisualizerParams = {
    autoResizeLength = true,
    createSpheres = true,
} :: PartVisualizerParams

Constants.rotateXToZOffsetCFrame = CFrame.fromRotationBetweenVectors(Vector3.xAxis, Vector3.zAxis)


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


----- Visualizer info & params functions -----

local getPartVisualizerInfo
local getPartVisualizerParams

getPartVisualizerInfo = function(visualizerInfo: PartVisualizerInfo_Input): PartVisualizerInfo
    local result = {} :: PartVisualizerInfo
    result.templatePart = visualizerInfo and visualizerInfo.templatePart or Constants.defaultTemplatePart
    result.colorRange = visualizerInfo and visualizerInfo.colorRange or Constants.defaultColorRange
    return result
end

getPartVisualizerParams = function(visualizerParams: PartVisualizerParams_Input): PartVisualizerParams
    local result = {} :: PartVisualizerParams
    result.autoResizeLength = visualizerParams and visualizerParams.autoResizeLength or Constants.defaultVisualizerParams.autoResizeLength
    result.createSpheres = visualizerParams and visualizerParams.createSpheres or Constants.defaultVisualizerParams.createSpheres
    return result
end


----- Sampling functions -----

local sampleAlphas

sampleAlphas = function(linkedRoute: LinkedRoute.ClassType, zeroAlphaParameter: number, deltaParameter: number, parameterToAlpha_function: ((parameter: number) -> number)?): {number}
    local result = {}
    local alphaRange = linkedRoute:getAlphaRange()
    local parameter
    local alpha
    
    parameter = zeroAlphaParameter
    alpha = parameterToAlpha_function and parameterToAlpha_function(parameter) or parameter
    repeat
        -- Store sampled alpha
        table.insert(result, alpha)

        -- Get next alpha
        parameter += deltaParameter
        alpha = parameterToAlpha_function and parameterToAlpha_function(parameter) or parameter
    until alpha > alphaRange.Max or alpha ~= alpha

    -- Case for last alpha 
    table.insert(result, alphaRange.Max)

    -- Return sampled alphas
    return result
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
@return ({BasePart}) A table containing the created parts in sequential order.
]]
function RouteVisualizer.createParts_equalSteps(linkedRoute: LinkedRoute.ClassType, visualizerInfo_input: PartVisualizerInfo_Input, visualizerParams_input: PartVisualizerParams_Input, zeroAlphaParameter: number, deltaParameter: number, parameterToAlpha_function: ((parameter: number) -> number)?)
    local visualizerInfo = getPartVisualizerInfo(visualizerInfo_input)
    local visualizerParams = getPartVisualizerParams(visualizerParams_input)
    local sampledAlphas = sampleAlphas(linkedRoute, zeroAlphaParameter, deltaParameter, parameterToAlpha_function)
    local partsFolder
    local createdParts = {}
    local createdPartCount
    local alphaRange = linkedRoute:getAlphaRange()
    local alphaRange_scalar = linkedRoute:getAlphaRange_scalar()
    local newPart

    -- Create parts folder
    partsFolder = Instance.new("Folder")
    partsFolder.Name = "PartsFolder"
    createdPartCount = 0

    if not visualizerParams.autoResizeLength then
        -- Create part at each alpha
        for _, alpha in sampledAlphas do
            newPart = visualizerInfo.templatePart:Clone()
            table.insert(createdParts, newPart)
            createdPartCount += 1
            colorizePart(newPart, visualizerInfo.colorRange, (alpha - alphaRange.Min) / alphaRange_scalar)
            newPart.CFrame = linkedRoute:getCFrameAtAlpha(alpha)
            newPart.Name = string.format("%5d", createdPartCount)
        end
    else
        -- Create resize parts to connect the sampled points
        local currentAlpha
        local currentPosition
        local nextAlpha
        local nextPosition
        local sphereSize
        local partPositionDifferenceVector
        local partDistance
        local partMidPosition

        -- Create parts at each alpha interval
        nextAlpha = sampledAlphas[1]
        nextPosition = linkedRoute:getPositionAtAlpha(nextAlpha)
        for alphaIndex = 1, #sampledAlphas - 1 do
            currentAlpha = nextAlpha
            currentPosition = nextPosition
            nextAlpha = sampledAlphas[alphaIndex + 1]
            nextPosition = linkedRoute:getPositionAtAlpha(nextAlpha)

            ----- Create front sphere -----

            -- Inspired by AAZier
            if visualizerParams.createSpheres then
                newPart = Constants.defaultSpherePart:Clone()
                table.insert(createdParts, newPart)
                createdPartCount += 1
                colorizePart(newPart, visualizerInfo.colorRange, (currentAlpha - alphaRange.Min) / alphaRange_scalar)
                sphereSize = math.min(visualizerInfo.templatePart.Size.Y, visualizerInfo.templatePart.Size.Z)
                newPart.Size = Vector3.one * sphereSize
                newPart.CFrame = linkedRoute:getCFrameAtAlpha(currentAlpha);
                (newPart :: Part).Shape = Enum.PartType.Ball
                newPart.Name = string.format("%5d", createdPartCount)
            end

            ----- Create resized part -----

            -- Create part
            newPart = visualizerInfo.templatePart:Clone()
            table.insert(createdParts, newPart)
            createdPartCount += 1
            colorizePart(newPart, visualizerInfo.colorRange, (currentAlpha - alphaRange.Min) / alphaRange_scalar)
            newPart.Name = string.format("%5d", createdPartCount)

            -- Get info
            partPositionDifferenceVector = nextPosition - currentPosition
            partDistance = partPositionDifferenceVector.Magnitude
            partMidPosition = currentPosition + partPositionDifferenceVector / 2

            -- Modify part
            newPart.Size = Vector3.new(partDistance, newPart.Size.Y, newPart.Size.Z)
            newPart.CFrame = CFrame.lookAlong(partMidPosition, partPositionDifferenceVector)
        end

        ----- Create last sphere -----

        -- Inspired by AAZier
        if visualizerParams.createSpheres then
            currentAlpha = nextAlpha
            newPart = Constants.defaultSpherePart:Clone()
            table.insert(createdParts, newPart)
            createdPartCount += 1
            colorizePart(newPart, visualizerInfo.colorRange, (currentAlpha - alphaRange.Min) / alphaRange_scalar)
            sphereSize = math.min(visualizerInfo.templatePart.Size.Y, visualizerInfo.templatePart.Size.Z)
            newPart.Size = Vector3.one * sphereSize
            newPart.CFrame = linkedRoute:getCFrameAtAlpha(currentAlpha);
            (newPart :: Part).Shape = Enum.PartType.Ball
            newPart.Name = string.format("%5d", createdPartCount)
        end
    end

    -- Parent parts to folder
    for _, part in createdParts do
        part.CFrame = part.CFrame:ToWorldSpace(Constants.rotateXToZOffsetCFrame)
        part.Parent = partsFolder
    end
    partsFolder.Parent = RouteVisualizer.visualizerInstancesFolder

    return partsFolder, createdParts
end

--[[
Creates parts connecting equal parameter steps on the route.<br>
Wrapper function for <code>RouteVisualizer.createParts_equalSteps()</code> with <code>autoResizeLength</code> and <code>createSpheres</code> set to <code>true</code>.<br>
If the route is modified after the function is called, destroy the returned <code>Folder</code> and call this function again to update the visualized route.

@return (Instance) The <code>Folder</code> containing the created parts.
@return ({BasePart}) A table containing the created parts in sequential order.
]]
function RouteVisualizer.createParts_connected_equalSteps(linkedRoute: LinkedRoute.ClassType, visualizerInfo_input: PartVisualizerInfo_Input, zeroAlphaParameter: number, deltaParameter: number, parameterToAlpha_function: ((parameter: number) -> number)?)
    return RouteVisualizer.createParts_equalSteps(linkedRoute, visualizerInfo_input, Constants.connectedVisualizerParams, zeroAlphaParameter, deltaParameter, parameterToAlpha_function)
end


---------- Return module ----------

table.freeze(RouteVisualizer)
return RouteVisualizer
