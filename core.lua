local addonName, ns = ...

local N, C, M = {}, {}, {}

ns.N, ns.C, ns.M = N, C, M

_G[addonName] = {
	N, 	-- 1
	C, 	-- 2
	M, 	-- 3
	ns.OUF,	-- 4
}
local Tooltip = CreateFrame("Frame")
local Loading = CreateFrame("Frame")

local select = select
local format = string.format
local floor = floor
local upper = string.upper
local sub = sub
local gsub = gsub
local find = find

local UnitName = UnitName
local UnitLevel = UnitLevel
local UnitExists = UnitExists
local UnitCreatureType = UnitCreatureType
local GetQuestDifficultyColor = GetQuestDifficultyColor

C["Tooltips"] = {
	Enable = true,
	FontSize = 15, 
	Position = {"BOTTOMRIGHT", UIParent, 'BOTTOMRIGHT', -32, 16},
	AbbrevRealmNames = true,
	ShowPlayerTitles = true,
	ShowMouseoverTarget = true,
	BackdropColor = {0.08,0.08,0.1,1},	
	BorderColor = {0,0,0,0},
}

function Tooltip:Globals()
    GameTooltipStatusBar:ClearAllPoints()
    GameTooltipStatusBar:Hide()
end

function Tooltip:Skin()
	if self.IsEmbedded then return end --do nothing on embedded tooltips
	
	if (not self.IsSkinned) then
        self.Backdrop = CreateFrame('Frame', nil, self, 'BackdropTemplate')
		self.Backdrop:SetAllPoints()
		self.Backdrop:SetFrameLevel(self:GetFrameLevel())
		self.Backdrop:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1, bgFile ="Interface\\ChatFrame\\ChatFrameBackground"})
        self.Backdrop:SetBackdropColor(unpack(C.Tooltips.BackdropColor))
		self.Backdrop:SetBackdropBorderColor(unpack(C.Tooltips.BorderColor))

		if self.NineSlice then
			self.NineSlice:SetAlpha(0)
		end
		
		self.IsSkinned = true
	end
end

local function GetFormattedUnitType(unit)
    local creaturetype = UnitCreatureType(unit)
    if creaturetype then
        return creaturetype
    else
        return ""
    end
end

local function GetFormattedUnitClassification(unit)
    local class = UnitClassification(unit)
    if class == "worldboss" then
        return "|cffFF0000"..BOSS.."|r "
    elseif class == "rareelite" then
        return "|cffFF66CCRare|r |cffFFFF00"..ELITE.."|r "
    elseif class == "rare" then
        return "|cffFF66CCRare|r "
    elseif class == "elite" then
        return "|cffFFFF00"..ELITE.."|r "
    else
        return ""
    end
end

local function GetFormattedUnitLevel(unit)
    local diff = GetQuestDifficultyColor(UnitLevel(unit))
    if UnitLevel(unit) == -1 then
        return "|cffff0000??|r "
    elseif UnitLevel(unit) == 0 then
        return "? "
    else
        return format("|cff%02x%02x%02x%s|r ", diff.r*255, diff.g*255, diff.b*255, UnitLevel(unit))
    end
end

local function GetFormattedUnitClass(unit)
    local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
    if color then
		return format(" |cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, UnitClass(unit))
		--return (" "..UnitClass(unit))
    end
end

local function GetFormattedUnitString(unit)
    if UnitIsPlayer(unit) then
        if not UnitRace(unit) then
            return nil
        end
        return GetFormattedUnitLevel(unit)..UnitRace(unit)..GetFormattedUnitClass(unit)
    else
        return GetFormattedUnitLevel(unit)..GetFormattedUnitClassification(unit)..GetFormattedUnitType(unit)
    end
end

local function AddMouseoverTarget(self, unit)
    local unitTargetName = UnitName(unit.."target")
    local unitTargetClassColor = RAID_CLASS_COLORS[select(2, UnitClass(unit.."target"))] or { r = 1, g = 0, b = 1 }
    local unitTargetReactionColor = {
        r = select(1, GameTooltip_UnitColor(unit.."target")),
        g = select(2, GameTooltip_UnitColor(unit.."target")),
        b = select(3, GameTooltip_UnitColor(unit.."target"))
    }

    if UnitExists(unit.."target") then
        if UnitName("player") == unitTargetName then
            self:AddLine(format("|cffff00ff%s|r", upper(YOU)), 1, 1, 1)
        else
            if UnitIsPlayer(unit.."target") then
                self:AddLine(format("|cff%02x%02x%02x%s|r", unitTargetClassColor.r*255, unitTargetClassColor.g*255, unitTargetClassColor.b*255, unitTargetName:sub(1, 40)), 1, 1, 1)
            else
                self:AddLine(format("|cff%02x%02x%02x%s|r", unitTargetReactionColor.r*255, unitTargetReactionColor.g*255, unitTargetReactionColor.b*255, unitTargetName:sub(1, 40)), 1, 1, 1)
            end
        end
    end
end

-- >> move the GameTooltip
function Tooltip:SetTooltipDefaultAnchor(parent)
		self:SetOwner(parent, "ANCHOR_NONE")
		self:ClearAllPoints()
		self:SetPoint(unpack(C.Tooltips.Position))
end

function Tooltip:OnTooltipSetUnit()
    local _, unit = self:GetUnit()
	
    if UnitExists(unit) and UnitName(unit) ~= UNKNOWN then
        local name, realm = UnitName(unit)

            -- Player Titles

        if C.Tooltips.ShowPlayerTitles then
            if UnitPVPName(unit) then
                name = UnitPVPName(unit)
            end
        end

        GameTooltipTextLeft1:SetText(name)
	
		if UnitIsDeadOrGhost(unit) then
			GameTooltipTextLeft1:SetTextColor(0.5,0.5,0.5)
		end
            -- Color guildnames

        if GetGuildInfo(unit) then
            --if GetGuildInfo(unit) == GetGuildInfo("player") and IsInGuild("player") then
               GameTooltipTextLeft2:SetText("|cffFF66CC"..GameTooltipTextLeft2:GetText().."|r")
           -- end
        end

            -- Level

        for i = 2, GameTooltip:NumLines() do
            if _G["GameTooltipTextLeft"..i]:GetText():find("^"..TOOLTIP_UNIT_LEVEL:gsub("%%s", ".+")) then
                _G["GameTooltipTextLeft"..i]:SetText(GetFormattedUnitString(unit))
            end
        end

              -- Mouseover Target

        if C.Tooltips.ShowMouseoverTarget then
            AddMouseoverTarget(self, unit)
        end

            -- Away and DND

        if UnitIsAFK(unit) then
            self:AppendText("|cff00ff00 <"..CHAT_MSG_AFK..">|r")
        elseif UnitIsDND(unit) then
            self:AppendText("|cff00ff00 <"..DEFAULT_DND_MESSAGE..">|r")
        end

            -- Player realm names

        if realm and realm ~= "" then
            if C.Tooltips.AbbrevRealmNames then
                self:AppendText(" (*)")
            else
                self:AppendText(" - "..realm)
            end
        end
    end
end

function Tooltip:ResetBorderColor()
	if self ~= GameTooltip then
		return
	end

	if self.Backdrop then
		self.Backdrop:SetBackdropBorderColor(unpack(C.Tooltips.BorderColor))
    end
end

function Tooltip:AddHooks()
    --hooksecurefunc("GameTooltip_SetDefaultAnchor", self.SetTooltipDefaultAnchor)

    hooksecurefunc("GameTooltip_ClearMoney", self.ResetBorderColor)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, self.OnTooltipSetUnit)
end

function Tooltip:Enable()
    if not C.Tooltips.Enable then
        return
    end
    self:Globals()
    self:AddHooks()

    Tooltip.Skin(GameTooltip)
	Tooltip.Skin(ItemRefTooltip)
	Tooltip.Skin(EmbeddedItemTooltip)
	Tooltip.Skin(ShoppingTooltip1)
	Tooltip.Skin(ShoppingTooltip2)
end

function Loading:OnEvent(event)
    if (event=="PLAYER_LOGIN") then
		Tooltip:Enable()
    end
end

Loading:RegisterEvent("PLAYER_LOGIN")

Loading:SetScript("OnEvent", Loading.OnEvent)