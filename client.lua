local config = {}
config.intensity = 4.0
config.timeUntilReload = 10.0
config.sprayRange = 3.0
config.sprayEffectTime = 10

local holdingpepperspray = false
local usingpepperspray = false
local peppersprayModel = "w_am_flare"
local animDict = "weapons@first_person@aim_rng@generic@projectile@shared@core"
local animName = "idlerng_med"
local particleDict = "scr_bike_business"
local particleName = "scr_bike_spraybottle_spray"
local actionTime = 8
local pepperspray_net = nil

---------------------------------------------------------------------------
-- Toggling pepperspray --
---------------------------------------------------------------------------
RegisterNetEvent("pepperspray:Togglepepperspray")
AddEventHandler("pepperspray:Togglepepperspray", function()
    if not holdingpepperspray then
        RequestModel(GetHashKey(peppersprayModel))
        while not HasModelLoaded(GetHashKey(peppersprayModel)) do
            Citizen.Wait(100)
        end

        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(100)
        end

        local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
        local peppersprayspawned = CreateObject(GetHashKey(peppersprayModel), plyCoords.x, plyCoords.y, plyCoords.z, 1, 1, 1)
        Citizen.Wait(1000)
        local netid = ObjToNet(peppersprayspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)
        AttachEntityToEntity(peppersprayspawned, GetPlayerPed(PlayerId()), GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422), 0.05, -0.05, 0.0, 260.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
        --TaskPlayAnim(GetPlayerPed(PlayerId()), 1.0, -1, -1, 50, 0, 0, 0, 0) -- 50 = 32 + 16 + 2
        TaskPlayAnim(GetPlayerPed(PlayerId()), animDict, animName, 1.0, -1, -1, 50, 0, 0, 0, 0)
        pepperspray_net = netid
        holdingpepperspray = true
    else
        ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
        DetachEntity(NetToObj(pepperspray_net), 1, 1)
        DeleteEntity(NetToObj(pepperspray_net))
        pepperspray_net = nil
        holdingpepperspray = false
        usingpepperspray = false
    end
end)

---------------------------------------------------------------------------
-- Start Particles --
---------------------------------------------------------------------------
RegisterNetEvent("pepperspray:StartParticles")
AddEventHandler("pepperspray:StartParticles", function(peppersprayid)
    local entity = NetToObj(peppersprayid)

    RequestNamedPtfxAsset(particleDict)
    while not HasNamedPtfxAssetLoaded(particleDict) do
        Citizen.Wait(100)
    end

    UseParticleFxAssetNextCall(particleDict)
    local particleEffect = StartParticleFxLoopedOnEntity(particleName, entity, 0.2, 0.002, 0.0, 0.0, -95.0, 180.0, config.intensity, false, false, false)
    SetTimeout(10000, function()
        usingpepperspray = false
    end)
end)

---------------------------------------------------------------------------
-- Stop Particles --
---------------------------------------------------------------------------
RegisterNetEvent("pepperspray:StopParticles")
AddEventHandler("pepperspray:StopParticles", function(peppersprayid)
    local entity = NetToObj(peppersprayid)
    RemoveParticleFxFromEntity(entity)
end)

---------------------------------------------------------------------------
-- Play Effect
---------------------------------------------------------------------------
local isSprayed = false

RegisterNetEvent("pepperspray:PlayerEffect")
AddEventHandler("pepperspray:PlayerEffect", function()
	if not isSprayed then
		SetTimecycleModifier("drunk")
		SetTimecycleModifierStrength(2.0)
		local ped = GetPlayerPed(PlayerId())
		local fallPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, -1.0, 0.0)
		SetPedToRagdollWithFall(ped, config.sprayEffectTime * 1000, config.sprayEffectTime * 1000, 1, -GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
		Citizen.Wait(config.sprayEffectTime * 1000)
		ClearTimecycleModifier()
	end
end)

---------------------------------------------------------------------------
-- Spraying Pepper Spray --
---------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        if holdingpepperspray then
            if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                TriggerEvent("pepperspray:Togglepepperspray")
            end
            for i=140, 143 do
                DisableControlAction(0, i, true)
            end
            if IsControlJustPressed(0, 24) and usingpepperspray == false then
                FireSpray()
            end
        else
            for i=140, 143 do
                EnableControlAction(0, i, true)
            end
        end
        Citizen.Wait(0)
    end
end)

function FireSpray()
    Citizen.CreateThread(function()
        usingpepperspray = true
        local time = config.timeUntilReload
        local count = time
		TriggerServerEvent("pepperspray:SyncStartParticles", pepperspray_net)
	
		local foundPed = FindPedInRaycast()
		if foundPed ~= 0 then
			if IsPedAPlayer(foundPed) then
				local playerid = GetPlayerFromPed(foundPed)
				if playerid ~= -1 then
					TriggerServerEvent("pepperspray:TriggerPlayerEffect", GetPlayerServerId(playerid))
				end
			else
				local fallPos = GetOffsetFromEntityInWorldCoords(foundPed, 0.0, -1.0, 0.0)
				SetPedToRagdollWithFall(foundPed, 7000, 7000, 1, -GetEntityForwardVector(foundPed), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
			end
		end

        while IsControlPressed(0, 24) and count > 0 do

            if not holdingpepperspray then
                usingpepperspray = false
                TriggerServerEvent("pepperspray:SyncStopParticles", pepperspray_net)
                return
            end
            
            Citizen.Wait(500)
            count = count - 0.5
        end
        TriggerServerEvent("pepperspray:SyncStopParticles", pepperspray_net)
        usingpepperspray = false
    end)
end

function FindPedInRaycast()
	local player = PlayerId()
	local plyPed = GetPlayerPed(player)
	local plyPos = GetEntityCoords(plyPed, false)
	local plyOffset = GetOffsetFromEntityInWorldCoords(plyPed, 0.0, config.sprayRange, 0.0)
	local rayHandle = StartShapeTestCapsule(plyPos.x, plyPos.y, plyPos.z, plyOffset.x, plyOffset.y, plyOffset.z, 1.0, 12, plyPed, 7)
	local _, _, _, _, ped = GetShapeTestResult(rayHandle)
	return ped
end

function GetPlayerFromPed(ped)
	for a = 0, 64 do
		if GetPlayerPed(a) == ped then
			return a
		end
	end
	return -1
end

function Notification(message)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(message)
	DrawNotification(0, 1)
end