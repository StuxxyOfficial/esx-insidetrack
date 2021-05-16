QBCore = nil
Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent("QBCore:GetObject", function(obj) QBCore = obj end)
    end
end)


local cooldown = 60
local tick = 0
local checkRaceStatus = false

Utils.InsideTrackActive = false

local function OpenInsideTrack()
    QBCore.Functions.TriggerCallback("insidetrack:server:getbalance", function(balance)
        Utils.PlayerBalance = balance
    end)

    if Utils.InsideTrackActive then
        return
    end

    Utils.InsideTrackActive = true

    -- Scaleform
    Utils.Scaleform = RequestScaleformMovie('HORSE_RACING_CONSOLE')

    while not HasScaleformMovieLoaded(Utils.Scaleform) do
        Wait(0)
    end

    DisplayHud(false)
    ExecuteCommand("togglehud")
    SetPlayerControl(PlayerId(), false, 0)
    ReleaseNamedRendertarget("casinoscreen_02")

    while not RequestScriptAudioBank('DLC_VINEWOOD/CASINO_GENERAL') do
        Wait(0)
    end

    Utils:ShowMainScreen()
    Utils:SetMainScreenCooldown(cooldown)

    -- Add horses
    Utils.AddHorses(Utils.Scaleform)

    Utils:DrawInsideTrack()
    Utils:HandleControls()
end

local function LeaveInsideTrack()
    Utils.InsideTrackActive = false

    DisplayHud(true)
    SetPlayerControl(PlayerId(), true, 0)
    SetScaleformMovieAsNoLongerNeeded(Utils.Scaleform)

    Utils.Scaleform = -1
end

function Utils:DrawInsideTrack()
    Citizen.CreateThread(function()
        while Utils.InsideTrackActive do
            Wait(0)

            local xMouse, yMouse = GetDisabledControlNormal(2, 239), GetDisabledControlNormal(2, 240)

            -- Fake cooldown
            tick = (tick + 10)

            if (tick == 1000) then
                if (cooldown == 1) then
                    cooldown = 60
                end
                
                cooldown = (cooldown - 1)
                tick = 0

                Utils:SetMainScreenCooldown(cooldown)
            end
            
            -- Mouse control
            BeginScaleformMovieMethod(Utils.Scaleform, 'SET_MOUSE_INPUT')
            ScaleformMovieMethodAddParamFloat(xMouse)
            ScaleformMovieMethodAddParamFloat(yMouse)
            EndScaleformMovieMethod()

            -- Draw
            DrawScaleformMovieFullscreen(Utils.Scaleform, 255, 255, 255, 255)
        end
    end)
end

function Utils:HandleControls()
    Citizen.CreateThread(function()
        while Utils.InsideTrackActive do
            Wait(0)

            if IsControlJustPressed(2, 194) then
                LeaveInsideTrack()

                Utils:HandleBigScreen()
            end

            if IsControlJustPressed(2, 177) then
                LeaveInsideTrack()

                Utils:HandleBigScreen()
            end

            -- Left click
            if IsControlJustPressed(2, 237) then
                local clickedButton = Utils:GetMouseClickedButton()

                if Utils.ChooseHorseVisible then
                    if (clickedButton ~= 12) and (clickedButton ~= -1) then
                        Utils.CurrentHorse = (clickedButton - 1)
                        Utils:ShowBetScreen(Utils.CurrentHorse)
                        Utils.ChooseHorseVisible = false
                    end
                end

                -- Rules button
                if (clickedButton == 15) then
                    Utils:ShowRules()
                end

                -- Close buttons
                if (clickedButton == 12) then
                    if Utils.ChooseHorseVisible then
                        Utils.ChooseHorseVisible = false
                    end
                    
                    if Utils.BetVisible then
                        Utils:ShowHorseSelection()
                        Utils.BetVisible = false
                        Utils.CurrentHorse = -1
                    else
                        Utils:ShowMainScreen()
                    end
                end

                -- Start bet
                if (clickedButton == 1) then
                    Utils:ShowHorseSelection()
                end

                -- Start race
                if (clickedButton == 10) then
                    PlaySoundFrontend(-1, 'race_loop', 'dlc_vw_casino_inside_track_betting_single_event_sounds')
                    TriggerServerEvent("insidetrack:server:placebet", Utils.CurrentBet)
                    Utils:StartRace()
                    checkRaceStatus = true
                end

                -- Change bet
                if (clickedButton == 8) then
                    if (Utils.CurrentBet < Utils.PlayerBalance) then
                        Utils.CurrentBet = (Utils.CurrentBet + 100)
                        Utils.CurrentGain = (Utils.CurrentBet * 2)
                        Utils:UpdateBetValues(Utils.CurrentHorse, Utils.CurrentBet, Utils.PlayerBalance, Utils.CurrentGain)
                    end
                end

                if (clickedButton == 9) then
                    if (Utils.CurrentBet > 100) then
                        Utils.CurrentBet = (Utils.CurrentBet - 100)
                        Utils.CurrentGain = (Utils.CurrentBet * 2)
                        Utils:UpdateBetValues(Utils.CurrentHorse, Utils.CurrentBet, Utils.PlayerBalance, Utils.CurrentGain)
                    end
                end

                if (clickedButton == 13) then
                    Utils:ShowMainScreen()
                end

                -- Check race
                while checkRaceStatus do
                    Wait(0)

                    local raceFinished = Utils:IsRaceFinished()

                    if (raceFinished) then
                        StopSound(0)

                        if (Utils.CurrentHorse == Utils.CurrentWinner) then
                            -- Here you can add money
                            -- Exemple
                            -- TriggerServerEvent('myCoolEventWhoAddMoney', Utils.CurrentGain)

                            TriggerServerEvent("insidetrack:server:winnings", Utils.CurrentGain)

                            -- Refresh player balance
                            Utils.PlayerBalance = (Utils.PlayerBalance + Utils.CurrentGain)
                            Utils:UpdateBetValues(Utils.CurrentHorse, Utils.CurrentBet, Utils.PlayerBalance, Utils.CurrentGain)
                        end

                        Utils:ShowResults()

                        Utils.CurrentHorse = -1
                        Utils.CurrentWinner = -1
                        Utils.HorsesPositions = {}

                        checkRaceStatus = false
                    end
                end
            end
        end
    end)
end

local insideMarker = false

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(insideTrackLocation - coords)

        if dist <= 4.0 then
            Citizen.Wait(0)
            DrawMarker(2, insideTrackLocation.x, insideTrackLocation.y, insideTrackLocation.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.2, 0.1, 255, 0, 0, 155, 0, 0, 0, 1, 0, 0, 0)
            if dist <= 1.0 and not insideTrackActive then
                QBCore.Functions.DrawText3D(insideTrackLocation.x, insideTrackLocation.y, insideTrackLocation.z + 0.3, "[~g~E~w~] Inside Track")
                insideMarker = true
            end
        else
            insideMarker = false
            Citizen.Wait(1000)
        end
    end
end)

RegisterCommand("+InsideTrack", function()
    if insideMarker then
        OpenInsideTrack()
    end
end, false)
RegisterCommand("-InsideTrack", function()
end,false)
TriggerEvent("chat:removeSuggestion", "/+InsideTrack")
TriggerEvent("chat:removeSuggestion", "/-InsideTrack")

RegisterKeyMapping("+InsideTrack", "Interact with inside track at the casino", "keyboard" ,"e")