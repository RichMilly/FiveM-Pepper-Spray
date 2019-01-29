RegisterCommand("pepperspray", function(source, args, raw)
    local src = source
    TriggerClientEvent("pepperspray:Togglepepperspray", src)
end)

RegisterServerEvent("pepperspray:SyncStartParticles")
AddEventHandler("pepperspray:SyncStartParticles", function(peppersprayid)
    TriggerClientEvent("pepperspray:StartParticles", -1, peppersprayid)
end)

RegisterServerEvent("pepperspray:SyncStopParticles")
AddEventHandler("pepperspray:SyncStopParticles", function(peppersprayid)
    TriggerClientEvent("pepperspray:StopParticles", -1, peppersprayid)
end)

RegisterServerEvent("pepperspray:TriggerPlayerEffect")
AddEventHandler("pepperspray:TriggerPlayerEffect", function(playerid)
	TriggerClientEvent("pepperspray:PlayerEffect", playerid)
end)