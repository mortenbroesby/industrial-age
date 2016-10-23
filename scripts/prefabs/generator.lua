require "prefabutil"

local assets = {
    Asset("ANIM", "anim/generator.zip"),
}

local heats = { 70, 85, 100, 115 }
local function GetHeatFn(inst)
    return heats[inst.stored_section] or 20
end

local function PushGeneratedEnergy(inst)
    --print("Pushing energy")
    local x,y,z = inst:GetPosition():Get()
    local energycells = TheSim:FindEntities(x,y,z, inst.range, {"energycell"})
    local energycell = nil
    local cellfound = 0
    if #energycells > 0 then
        for k,v in pairs(energycells) do 
            if v.full then
                if cellfound > 0 then 
                    cellfound = cellfound - 1 
                end
            end
            if not v.full and cellfound < 2 then
                energycell = v
                cellfound = cellfound + 1
                --print("Sent energy to @: " .. tostring(energycell))
                energycell:PushEvent("fillenergy", {energycell=energycell})
            end
        end
    end
end

local function CheckSection(inst)
    print("Stored section: " .. tostring(inst.stored_section))
    if inst.stored_section == 0 then
        inst.efficiency = 0
        inst.AnimState:PlayAnimation("idle")
        --print("empty")
        inst.Light:Enable(false)
        inst.Light:SetRadius(0.5)
    elseif inst.stored_section == 1 then
        inst.efficiency = inst.multiplier * 1
        inst.AnimState:PlayAnimation("low")
        --print("low")
        inst.Light:SetRadius(0.5)
    elseif inst.stored_section == 2 then
        inst.efficiency = inst.multiplier * 2
        inst.AnimState:PlayAnimation("medium")
        --print("medium")
        inst.Light:SetRadius(3)
    elseif inst.stored_section == 3 then
        inst.efficiency = inst.multiplier * 3
        inst.AnimState:PlayAnimation("high")
        --print("high")
        inst.Light:SetRadius(5)
    elseif inst.stored_section == 4 then
        inst.efficiency = inst.multiplier * 4
        inst.AnimState:PlayAnimation("full")
        --print("full!")
        inst.Light:SetRadius(8)
    end
end

local function CalculateEnergy(inst)
    if not inst.task then
        inst.task = inst:DoPeriodicTask(5, CalculateEnergy, 1)
    end
    if inst.generating then
        inst.generate_value = inst.generate_value + inst.efficiency
        --print("Percentage to generate energy")
        --print(tostring(inst.generate_value))
        if inst.generate_value >= 100 then
            inst.generate_value = inst.generate_value - 100
            PushGeneratedEnergy(inst)
        end
    end
end

local function onextinguish(inst)
    if inst.components.fueled then
        inst.SoundEmitter:KillSound("idlesound")
        inst.generating = false
        inst.Light:Enable(false)
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end
       
local function onhit(inst, worker)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.AnimState:PlayAnimation("hit")
    inst:DoTaskInTime(1.8, function()
        CalculateEnergy(inst)
        CheckSection(inst)
    end)
end

local function onbuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.AnimState:PlayAnimation("place")
end

local function OnSave(inst, data)
    if inst.stored_section then
        data.stored_section = inst.stored_section
    end
end

local function OnLoad(inst, data)
    if data and data.stored_section then
        inst.stored_section = data.stored_section
        CheckSection(inst)
        CalculateEnergy(inst)
    else
        CalculateEnergy(inst)
        inst.AnimState:PlayAnimation("idle")
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
 
    MakeObstaclePhysics(inst, .7)
    MakeSnowCovered(inst, .01)

    local light = inst.entity:AddLight()
    inst.Light:Enable(false)
    inst.Light:SetRadius(5.7)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(.6)
    inst.Light:SetColour(255/255, 255/255, 255/255)

    inst.efficiency = TUNING.GENERATOR_EFFICIENCY
    inst.multiplier = TUNING.GENERATOR_EFFICIENCY_MULTIPLIER
    inst.range = TUNING.GENERATOR_RANGE
    inst.generating = false
    inst.generate_value = 0
    inst.stored_section = 0

    anim:SetBank("generator")
    anim:SetBuild("generator")
    inst:AddTag("generator")
    inst:AddTag("structure")

    inst:AddComponent("inspectable")
    inst:AddComponent("heater")
    inst.components.heater.heatfn = GetHeatFn

    inst:AddComponent("burnable")
    inst:ListenForEvent("onextinguish", onextinguish)

    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.GENERATOR_FUEL_MAX
    inst.components.fueled.accepting = true
    
    inst.components.fueled.rate = TUNING.GENERATOR_FUEL_RATE
    inst.components.fueled:SetSections(4)
    inst.components.fueled.ontakefuelfn = function() 
        CheckSection(inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") 
    end
       
    inst.components.fueled:SetUpdateFn( function()
        if inst.components.burnable and inst.components.fueled then
            CalculateEnergy(inst)
            inst.generating = true
            inst.Light:Enable(true)
        end
    end)

    inst.components.fueled:SetSectionCallback( function(section)
        inst.stored_section = section
        if section == 0 then
            inst.generating = false    
            inst.components.burnable:Extinguish()             
            --print("empty")
        else
            inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_idle_LP","idlesound")
            if not inst.components.burnable:IsBurning() then
                inst.components.burnable:Ignite()
            end
        end
    end)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(5)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.components.inspectable.getstatus = function(inst)
        local sec = inst.components.fueled:GetCurrentSection()
        if sec == 0 then 
            return "OUT"
        elseif sec <= 4 then
            local t = {"EMBERS","LOW","NORMAL","HIGH"}
            return t[sec]
        end
    end

    CalculateEnergy(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    return inst
end

return Prefab( "common/objects/generator", fn, assets),
       MakePlacer("common/generator_placer", "generator", "generator", "idle")