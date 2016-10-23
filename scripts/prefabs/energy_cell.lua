require "prefabutil"

local assets = {
    Asset("ANIM", "anim/energy_cell.zip"),
}

local function CheckEnergy(inst)
    --[[if not inst.task then
        inst.task = inst:DoPeriodicTask(1, CheckEnergy, 1)
    end]]
    inst:DoTaskInTime(1.0, function()
        CheckEnergy(inst)
    end)

    --print("Charge left:")
    --print(tostring(inst.chargeleft))
    --print("Empty? " .. tostring(inst.empty))

    if inst.chargeleft and inst.chargeleft > 0 then
        inst.empty = false
        inst.AnimState:PlayAnimation(tostring(inst.chargeleft))
    else 
        inst.empty = true
        inst.AnimState:PlayAnimation("idle")
    end
    if inst.chargeleft and inst.chargeleft > 0 then
        if inst.chargeleft <= 20 then
            inst.full = false
        elseif inst.chargeleft == 21 then
            inst.full = true
        end
    end

end

local function onfillenergy(inst)
    --print("Energy recieved")
    if inst.chargeleft and inst.chargeleft > 0 then
        if inst.chargeleft < TUNING.CELL_ENERGY_MAX then
            inst.chargeleft = inst.chargeleft + 1
        end
    else
        inst.chargeleft = 1
    end
    CheckEnergy(inst)
end

local function ondepleteenergy(inst)
    --print("Energy sent")
    if inst.chargeleft and inst.chargeleft > 0 then
        inst.depletion_value = inst.depletion_value + inst.depletion_multiplier
        --print("Percentage to remove energy")
        --print(tostring(inst.depletion_value))
        if inst.depletion_value >= 100 then
            inst.depletion_value = inst.depletion_value - 100
            inst.chargeleft = inst.chargeleft - 1
        end
    else
        inst.chargeleft = 0
    end
    CheckEnergy(inst)
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
    inst.chargeleft = TUNING.CELL_ENERGY_MAX -- REMOVE!
    inst:DoTaskInTime(2.5, function()
        CheckEnergy(inst)
    end)
end

local function onlightning(inst)
    print("Lightning hit")
    onhit(inst)
    inst.chargeleft = TUNING.CELL_ENERGY_MAX
end

local function onbuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.chargeleft = 0
    inst.empty = true
    inst.full = false
    inst.AnimState:PlayAnimation("place")
end

local function OnSave(inst, data)
    if inst.chargeleft then
        data.chargeleft = inst.chargeleft
    end
    if inst.depletion_value then
        data.depletion_value = inst.depletion_value
    end
end

local function OnLoad(inst, data)
    if data and data.chargeleft then
        inst.chargeleft = data.chargeleft
    end
    if data and data.depletion_value then
        inst.depletion_value = data.depletion_value
    end
    CheckEnergy(inst)
end

local function fn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetPriority(5)
    minimap:SetIcon("energy_cell/energy_cell.tex")
 
    MakeObstaclePhysics(inst, .6)
    MakeSnowCovered(inst, .01)

    inst.depletion_value = 0
    inst.depletion_multiplier = TUNING.CELL_DEPLETION_MULTIPLIER

    anim:SetBank("energy_cell")
    anim:SetBuild("energy_cell")

    inst:AddTag("structure")
    inst:AddTag("lightningrod")
    inst:AddTag("energycell")
    inst:AddTag("structure")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("lightningstrike", onlightning)
    inst:ListenForEvent("fillenergy", onfillenergy)
    inst:ListenForEvent("depleteenergy", ondepleteenergy)

    CheckEnergy(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    return inst
end

return Prefab( "common/objects/energy_cell", fn, assets),
       MakePlacer("common/energy_cell_placer", "energy_cell", "energy_cell", "idle")