local GameObject = CS.UnityEngine.GameObject
local Time = CS.UnityEngine.Time
local Color = CS.UnityEngine.Color
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3

---@class WaitingPVP:CS.Akequ.Base.Room
WaitingPVP = {}

WaitingPVP.sent = false
WaitingPVP.time = 0
WaitingPVP.update_time = 1

function WaitingPVP:Init()
    if self.main.netEvent.isServer then
        CS.HookManager.Run("changeLockRoundState", true)
        CS.HookManager.Run("onLCZState", true)
        CS.Config.SetConfig("friendly_fire", true)

        local sm = GameObject.FindObjectOfType(typeof(CS.SupportManager))
        if sm ~= nil then 
            GameObject.Destroy(sm)                
        end
        self:ClearItemsOnMap()
        CS.HookManager.Add("onPlayerDeath", function(obj)
            local deathPly = obj[0]
            local killer = obj[1].killer

            if killer ~= nil then
                killer.health = killer.maxHealth
                killer:UpdateHealth()
            end
            if deathPly ~= nil then
                self.main:Invoke(function() deathPly:SetClass("PVPClass") end, 0.2)
            end
        end)
        CS.HookManager.Add("onPlayerCreated", function(obj)
            if GameObject.FindObjectsOfType(typeof(CS.Player)).Length > CS.Config.GetInt("start_default_round_minimum_players", 6) then
                GameObject.FindObjectOfType(typeof(CS.AdminPanel)):ShowAdminMessage("Нужное количество игроков достигнуто! Перезапуск раунда...", 3)
                self.main:Invoke(function() CS.HookManager.Run("RestartRoundAP") end, 2)
            end
        end)
    end
end

function WaitingPVP:Update()
    if self.main.netEvent.isServer then        
        self.update_time = self.update_time - Time.deltaTime
        if self.update_time <= 0 then
            self.update_time = 1
            self:PluginUpdate()
        end
    end
    if self.main.netEvent.isClient then
        if not self.sent then
            self.sent = true
            self.main:SendToServer("SetPlayer", CS.PlayerUtilities.GetLocalPlayer())
        end
    end
end

function WaitingPVP:PluginUpdate()
    self.time = self.time - 1
    if self.time <= 0 then
        self.time = 30
        self:GivePatrons()
        self:ClearItemsOnMap()
    end
end

function WaitingPVP:ClearItemsOnMap()
    local items = GameObject.FindObjectsOfType(typeof(CS.ItemPickup))
    for i = 0, items.Length - 1 do
        local item = items[i]
        if item ~= nil and item.gameObject ~= nil then
            GameObject.Destroy(item.gameObject)
        end
    end
end

function WaitingPVP:SetPlayer(player)
    if player ~= nil then
        player:SetClass("PVPClass")
        if GameObject.FindObjectsOfType(typeof(CS.Player)).Length < CS.Config.GetInt("start_default_round_minimum_players", 6) + 1 then
            GameObject.FindObjectOfType(typeof(CS.AdminPanel)):ShowAdminMessage("Ожидание нужного количества игроков для начала раунда (" .. CS.Config.GetInt("start_default_round_minimum_players", 6) + 1 .. ")", 5, player)
        end
    end
end

function WaitingPVP:GivePatrons()
    local players = GameObject.FindObjectsOfType(typeof(CS.Player))
    for i = 0, players.Length - 1 do
        local player = players[i]
        player:SetAvailAmmo("545x39", 120)
        player:SetAvailAmmo("556x45", 120)
        player:SetAvailAmmo("762x39", 120)
        player:SetAvailAmmo("9x19", 100)
    end
end

return WaitingPVP