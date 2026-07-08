local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2
local TransitionManager = CS.TransitionManager
local UIManager = CS.UIManager
local PlayerUtilities = CS.PlayerUtilities
local ColorUtility = CS.UnityEngine.ColorUtility
local GameObject = CS.UnityEngine.GameObject
local Config = CS.Config
local Color = CS.UnityEngine.Color
local Time = CS.UnityEngine.Time

local time_to_teleport = 7

---@class PVPClass:CS.Akequ.Base.PlayerClass
PVPClass = {}

PVPClass.text = nil

function PVPClass:Init()
    self.main.player:InitHealth(CS.Config.GetInt("PVPclass_health", 100), Color(1, 0, 0, 1), "PVP class")
    self.main.player:SetHitbox(Vector3(0.8, 1.8, 0.8), Vector3.zero)
    if self.main.player.isLocalPlayer then
        self.main.player:PlayBellSound(1)
        UIManager.SetMobileButtons({ "Move", "Rotate", "Pause", "PlayerList", "Interact", "Jump", "Run",
            "Inventory", "Voice", "Crouch" })
        TransitionManager.ShowClass("#FF0000",
            "",
            "Класс для тренировки скила",
            "PVP", "SCPIcon")
        PlayerUtilities.SetVoiceChat(PlayerUtilities.CreateValueTuple("3D", true),
            PlayerUtilities.CreateValueTuple("Intercom", false))

        -- Spawning UI
        if GameObject.Find("InfoTextObject") == nil then
            CS.GameConsole.Log("Spawning text...")
            
            local base_ = GameObject.Find("Canvas")
            local victory_text_obj = GameObject("InfoTextObject")
            victory_text_obj.transform:SetParent(base_.transform, false)
            victory_text_obj.transform.localPosition = Vector3(0, 80, 0)
            local rtv = victory_text_obj:AddComponent(typeof(CS.UnityEngine.RectTransform))
            rtv.anchorMin = Vector2(0.5, 0)
            rtv.anchorMax = Vector2(0.5, 0)
            rtv.pivot = Vector2(0.5, 0)
            rtv.sizeDelta = Vector2(700, 60)
            self.text = victory_text_obj:AddComponent(typeof(CS.UnityEngine.UI.Text))
            self.text.font = CS.UnityEngine.Resources.GetBuiltinResource(typeof(CS.UnityEngine.Font), "Arial.ttf")
            self.text.text = "<size=22>Вы будете телепортированы через " .. time_to_teleport .. " секунд\nВозьмите в руки оружие, которым желаете сражаться</size>"
            self.text.fontStyle = CS.UnityEngine.FontStyle.Bold
            self.text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
            self.text.enabled = true
            self.text.raycastTarget = false
        else
            self.text = GameObject.Find("InfoTextObject"):GetComponent(typeof(CS.UnityEngine.UI.Text))
            self.text.enabled = true
        end

        self.main:Invoke(function()
        self.teleported = true
        self.text.enabled = false
        end, time_to_teleport)
    end

    if self.main.player.isServer then
        self.main.player.godMode = true
        
        self.main.player:GiveItem("AK12")
        self.main.player:GiveItem("ASVAL")
        self.main.player:GiveItem("G36C")
        self.main.player:GiveItem("CZ75B")
        self.main.player:GiveItem("M170")

        local netRooms = GameObject.FindObjectsOfType(typeof(CS.NetRoom))
        for i = 0, netRooms.Length-1 do
            local nroom = netRooms[i]
            if nroom.roomObj.name == "Map_EZ_GateB(Clone)" then
                self.main.player:Teleport(nroom.roomObj.transform.position + Vector3(0, 1.25, 0), nroom)
            end
        end

        self.main:Invoke(function()
            self.main:Invoke(function() self.main.player.godMode = false end, 2.5)

            local netRooms = {}
            local ciclNetRooms = GameObject.FindObjectsOfType(typeof(CS.NetRoom))
            for i = 0, ciclNetRooms.Length-1 do
                local nroom = ciclNetRooms[i]
                if nroom.roomObj.name == "Map_EZ_Endroom(Clone)" or nroom.roomObj.name == "Map_EZ_Lift(Clone)" or
                    nroom.roomObj.name == "Map_EZ_Toilets(Clone)" or nroom.roomObj.name == "Map_EZ_Intercom(Clone)" then
                    table.insert(netRooms, nroom)
                end
            end
            local netRoom = netRooms[math.random(1, #netRooms)]
            self.main.player:Teleport(netRoom.roomObj.transform.position + Vector3(0, 1.25, 0), netRoom)

            local current_item = self.main.player.currentItem
            
            local items = self.main.player.items
            for i = 0, items.Length - 1 do
                self.main.player:RemoveItemOnServer(items[i])
            end

            if current_item ~= nil then
                self.main.player:GiveItem(current_item:GetType().Name)
            else
                self.main.player:GiveItem("AK12")
            end
            self.main.player:GiveItem("FirstAid")
            self.main.player:GiveItem("FlashGrenade")

            self.main.player:SetAvailAmmo("545x39", 120)
            self.main.player:SetAvailAmmo("556x45", 120)
            self.main.player:SetAvailAmmo("762x39", 120)
            self.main.player:SetAvailAmmo("9x19", 100)
        end, time_to_teleport)
    end

    self.main.playerModel = self.main.player:SpawnHumanoidModel("ply_classD")
    self.main.playerModel.transform.localPosition = Vector3(0, -0.83, 0)
    PlayerUtilities.SpawnHitboxes(self.main.player, self.main.playerModel)

    self.main.player:SetSpeed(2.5, 5, 1.1)
    self.main.player:SetJumpPower(3.5)
end

function PVPClass:GetSpectatorBone()
    return "DeathCam"
end

function PVPClass:OnStop()
    if self.main.playerModel ~= nil then
        GameObject.Destroy(self.main.playerModel)
    end
end

function PVPClass:OnOpenInventory()
    return true
end

function PVPClass:GetName()
    return "PVP class"
end

function PVPClass:GetTeamID()
    return "None"
end

function PVPClass:GetClassColor()
    return "FF0000"
end

return PVPClass