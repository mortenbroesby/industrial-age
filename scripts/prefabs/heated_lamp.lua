require "prefabutil"

local assets = {
    Asset("ANIM", "anim/heated_lamp.zip"),
}

local function GetHeatFn(inst)
    if inst.disabled or not inst.running then 
        return 20
    else 
        return 60
    end
end

local function PushRemoveEnergy(inst)
    local x,y,z = inst:GetPosition():Get()
    local energycells = TheSim:FindEntities(x,y,z, inst.range, {"energycell"})
    local energycell = nil
    local cellfound = false
    if #energycells > 0 then
        for k,v in pairs(energycells) do 
            if v.empty then return end
            if not v.empty and not cellfound then
                inst.disabled = false
                cellfound = true
                inst.Light:Enable(true)
                energycell = v
                print("Asked for energy @: " .. tostring(energycell))
                energycell:PushEvent("depleteenergy", {energycell=energycell})
                return
            end
        end
    else
        cellfound = false
        inst.disabled = true
        inst.Light:Enable(false)
        print("No cells found")
    end
end

local function BurnEnergy(inst)
    inst:DoTaskInTime(1.5, function()
        BurnEnergy(inst)
    end)
    if inst.running then
        PushRemoveEnergy(inst)
    end
end

local function onturnon(inst)
    if not inst.disabled then
        inst.Light:Enable(true)
    end
    inst.running = true
end

local function onturnoff(inst)
    inst.Light:Enable(false)
    inst.running = false
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
    --inst.AnimState:PlayAnimation("hit")
end

local function onbuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    --inst.AnimState:PlayAnimation("place")
end

local function OnSave(inst, data)
    if inst.running then
        data.running = inst.running
    end
end

local function OnLoad(inst, data)
    if data and data.running then
        inst.running = data.running
    else
        inst.running = false
    end
    inst.AnimState:PlayAnimation("idle")
end

local function fn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
 
    MakeObstaclePhysics(inst, .6)
    MakeSnowCovered(inst, .01)

    local light = inst.entity:AddLight()
    inst.Light:Enable(false)
    inst.Light:SetRadius(5.7)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(.6)
    inst.Light:SetColour(255/255, 255/255, 255/255)

    inst.range = TUNING.HEATED_LAMP_RANGE

    anim:SetBank("heated_lamp")
    anim:SetBuild("heated_lamp")
    inst:AddTag("heatedlamp")
    inst:AddTag("structure")

    inst.running = true
    inst.disabled = true

    inst:AddComponent("inspectable")

    inst:AddComponent("heater")
    inst.components.heater.heatfn = GetHeatFn

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = onturnon
    inst.components.machine.turnofffn = onturnoff
    inst.components.machine.cooldowntime = 0
    inst.components.machine.ison = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:ListenForEvent("onbuilt", onbuilt)

    BurnEnergy(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    return inst
end

return Prefab( "common/objects/heated_lamp", fn, assets),
       MakePlacer("common/heated_lamp_placer", "heated_lamp", "heated_lamp", "idle")