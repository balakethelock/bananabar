local _G = _G or getfenv(0)

local GREEN = "|c000fb20a"
local LGREEN = "|c00c0ffc0"

local FORMAT_PRINT = LGREEN.."[|r"..GREEN.."BananaBar|r"..LGREEN.."] %s|r"

-- Bindings
BINDING_HEADER_BANANA_PLUGINNAME = "BananaBar Raid Symbols"
BINDING_NAME_BANANA_TARGET_SYMBOL1 = "Target "..RAID_TARGET_1
BINDING_NAME_BANANA_TARGET_SYMBOL2 = "Target "..RAID_TARGET_2
BINDING_NAME_BANANA_TARGET_SYMBOL3 = "Target "..RAID_TARGET_3
BINDING_NAME_BANANA_TARGET_SYMBOL4 = "Target "..RAID_TARGET_4
BINDING_NAME_BANANA_TARGET_SYMBOL5 = "Target "..RAID_TARGET_5
BINDING_NAME_BANANA_TARGET_SYMBOL6 = "Target "..RAID_TARGET_6
BINDING_NAME_BANANA_TARGET_SYMBOL7 = "Target "..RAID_TARGET_7
BINDING_NAME_BANANA_TARGET_SYMBOL8 = "Target "..RAID_TARGET_8
BINDING_NAME_BANANA_TARGET_SYMBOL9 = "Target Hunter's Mark"
BINDING_NAME_BANANA_CLEAR_ALL_SYMBOLS = "Clear all raid icons"
BINDING_NAME_BANANA_OPEN_CONFIG = "Open config"

local Checkboxes = {
	{ text = "Disable sound", var = "DISABLE_SOUND", frame = nil },
	{ text = "Disable error text", var = "DISABLE_ERROR_TEXT", frame = nil },
	{ text = "Hide button borders", var = "HIDE_BUTTON_FRAMES", frame = nil },
	{ text = "Show buttons in party", var = "SHOW_IN_PARTY", frame = nil },
	{ text = "Show buttons in raid", var = "SHOW_IN_RAID", frame = nil },
	{ text = "Show buttons out of group", var = "SHOW_OUT_OF_GROUP", frame = nil },
	{ text = "Hide unused buttons", var = "HIDE_UNUSED_BUTTONS", frame = nil },
	{ text = "Grey out dead targets", var = "GREY_OUT_DEATH", frame = nil },
	{ text = "Invert direction", var = "FLIP", frame = nil },
	{ text = "Detach hunter's mark", var = "DETACH", frame = nil },
}

local Layouts = {
	"1 line",
	"2 lines",
	"2 columns",
	"1 column",
	"Free moveable buttons"
}

-- Slash Commands
SLASH_BANANABAR1 = "/bananabar"
SLASH_BANANABAR2 = "/banana"
SLASH_BANANABAR3 = "/bbr"
SLASH_BANANABAR4 = "/bb"
SLASH_BANANATARGET1 = "/bbtarget"
SLASH_BANANATARGET2 = "/bananatarget"
SLASH_BANANATARGET3 = "/bananabartarget"
SLASH_BANANATARGET4 = "/bbrtarget"

local CLASS_COLORS = {
	["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, hex = "|cffc79c6e" },
	["MAGE"]    = { r = 0.41, g = 0.8,  b = 0.94, hex = "|cff69ccf0" },
	["ROGUE"]   = { r = 1.0,  g = 0.96, b = 0.41, hex = "|cfffff569" },
	["DRUID"]   = { r = 1.0,  g = 0.49, b = 0.04, hex = "|cffff7d0a" },
	["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45, hex = "|cffabd473" },
	["SHAMAN"]  = { r = 0.0,  g = 0.44, b = 0.87, hex = "|cff0070de" },
	["PRIEST"]  = { r = 1.0,  g = 1.0,  b = 1.0,  hex = "|cffffffff" },
	["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, hex = "|cff9482c9" },
	["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, hex = "|cfff58cba" },
};

local raidTargetIconTexCoords = {}
raidTargetIconTexCoords[1] = { ULx = 0, ULy = 0 }
raidTargetIconTexCoords[2] = { ULx = 0.25, ULy = 0 }
raidTargetIconTexCoords[3] = { ULx = 0.5, ULy = 0 }
raidTargetIconTexCoords[4] = { ULx = 0.75, ULy = 0 }
raidTargetIconTexCoords[5] = { ULx = 0, ULy = 0.25 }
raidTargetIconTexCoords[6] = { ULx = 0.25, ULy = 0.25 }
raidTargetIconTexCoords[7] = { ULx = 0.5, ULy = 0.25 }
raidTargetIconTexCoords[8] = { ULx = 0.75, ULy = 0.25 }

local huntersMark = "Interface\\Icons\\Ability_Hunter_SniperShot"
local markSpellIndex = nil
local superwow = type(SetAutoloot) == "function"
local shaguPlates = nil
local clearAttempts = 0
local updateInterval = 0.1
local timeLeft = 0
local IconsInfo = {}

local function Banana_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(format(FORMAT_PRINT, tostring(msg)))
end

local function Banana_Error(msg)
	if BANANA_CONFIG.DISABLE_ERROR_TEXT then return end
	DEFAULT_CHAT_FRAME:AddMessage(format(FORMAT_PRINT, tostring(msg)))
end

function Banana_OnLoad()
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("RAID_TARGET_UPDATE")
	local _, class = UnitClass("player")
	if class == "HUNTER" then
		this:RegisterEvent("SPELLS_CHANGED")
	end
	SlashCmdList["BANANABAR"] = Banana_Toggle
	SlashCmdList["BANANATARGET"] = function(arg)
		Banana_TargetCommand(arg)
	end
end

function Banana_OnEvent(event)
	if event == "VARIABLES_LOADED" then
		for i = 1, 9 do
			IconsInfo[i] = {}
			IconsInfo[i].MovingButton = 1
			IconsInfo[i].unitName = nil
			IconsInfo[i].symbol = nil
			IconsInfo[i].isDead = nil
			IconsInfo[i].isMyTarget = nil
			IconsInfo[i].numPlayersTargeting = 0
			IconsInfo[i].Players = {}
		end

		if not BANANA_CONFIG then
			BANANA_CONFIG = {}
			ShowUIPanel(BananaConfigFrame)
			Banana_Default()
		end
		
		for key, value in pairs(BANANA_CONFIG) do
			if value == 1 and key ~= "BUTTON_LAYOUT" then BANANA_CONFIG[key] = true end
			if value == 0 then BANANA_CONFIG[key] = false end
		end
		
		UIDropDownMenu_SetWidth(230, BananaConfigFrameComboBoxLayout)
		for i = 1, getn(Checkboxes) do
			local checkBox = CreateFrame("CheckButton", "BananaConfigFrameCheckBox"..i, BananaConfigFrame, "UICheckButtonTemplate")
			checkBox.Text = _G[checkBox:GetName().."Text"]
			if i == 1 then
				checkBox:SetPoint("TOPLEFT", BananaConfigFrameComboBoxLayout, "BOTTOMLEFT", 19, -15)
			else
				checkBox:SetPoint("TOPLEFT", "BananaConfigFrameCheckBox"..(i - 1), 0, -25)
			end
			checkBox.Text:SetText(Checkboxes[i].text)
			checkBox.var = Checkboxes[i].var
			checkBox:SetScript("OnClick", BananaConfig_CheckBox_OnClick)
			Checkboxes[i].frame = checkBox
		end
		Banana_UpdateScale()
		Banana_Layout()
		Banana_SetFramePositionAll()
		BananaConfig_Update()
		
		Banana_Print("Banana Raid Symbols loaded. Type /bb, /bbr, /banana or /bananabar to open config panel.")
		Banana_Print("Use Ctrl + RightClick to move buttons")
		Banana_Print("Use Alt + LeftClick to clear all existing symbols")
		return
	end
	if event == "RAID_TARGET_UPDATE" then
		Banana_Update()
		Banana_CtRaMainTankUpdate()
		timeLeft = updateInterval
		return
	end
	if event == "SPELLS_CHANGED" then
		local tex
		local i = 1
		repeat
			tex = GetSpellTexture(i, BOOKTYPE_SPELL)
			if tex == huntersMark then
				markSpellIndex = i
			end
			i = i + 1
		until not tex
		return
	end
end

function Banana_OnUpdate(elapsed)
	timeLeft = timeLeft - elapsed
	if timeLeft > 0 then return end
	timeLeft = updateInterval
	
	Banana_Update()
    Banana_CtRaMainTankUpdate()
	
	if clearAttempts > 0 then
		Banana_SetSymbol("player", 0)
		clearAttempts = clearAttempts - 1
	end
end

local function Banana_TexCoord(icon, index)
    if index == 9 then
        icon:SetTexture("Interface\\AddOns\\Bananabar\\Images\\HuntermarkArrow")
        icon:SetTexCoord(0, 1, 0, 1)
	else
		SetRaidTargetIconTexture(icon, index)
    end
end

function Banana_RaidTargetButtonOnLoad()
	local name = this:GetName()
	this.Icon = _G[name.."Icon"]
	this.Count = _G[name.."Count"]
	this.NormalTexture = _G[name.."NormalTexture"]
	Banana_TexCoord(this.Icon, this:GetID())
	this:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonDown", "MiddleButtonUp")
end

function Banana_ButtonOnClick(mouseButton)
	local index = this:GetID()
	if IsControlKeyDown() and mouseButton == "LeftButton" then
		if not BANANA_CONFIG.HIDE_UNUSED_BUTTONS then
			if not UnitExists("target") then
				Banana_TargetRaidSymbol(index)
				if not UnitExists("target") then
					Banana_Error("Not target selected.")
					Banana_PlayError()
					return
				end
			end
			if Banana_GetSymbol("target") == index then
				Banana_SetSymbol("target", 0)
				Banana_PlayRemove1()
			else
				Banana_SetSymbol("target", index)
			end
			Banana_Update()
		elseif UnitName("target") == nil or index == GetRaidTargetIndex("target") then
			Banana_TargetRaidSymbol(index)
			Banana_SetSymbol("target", 0)
			ClearTarget()
		else
			Banana_TargetRaidSymbol(index)
			Banana_SetSymbol("target", 0)
			TargetLastTarget()
		end
		return
	end
	if not IsControlKeyDown() and not IsAltKeyDown() and mouseButton == "LeftButton" then
		Banana_TargetRaidSymbol(index)
		return
	end
	if IsControlKeyDown() and mouseButton == "RightButton" then
		-- moving
		return
	end
	if IsAltKeyDown() and mouseButton == "LeftButton" then
		Banana_ClearAllSymbols()
		return
	end
	Banana_Print("Use Ctrl + RightClick to move buttons")
	Banana_Print("Use Alt + LeftClick to clear all existing symbols")
end

function Banana_ButtonOnMouseDown(mouseButton)
	if IsControlKeyDown() and mouseButton == "RightButton" then
		local index = this:GetID()
		local button = _G["RaidTargetFrame"..IconsInfo[index].MovingButton.."Button"]
		if button:IsMovable() then
			button:StartMoving()
		end
	end
end

function Banana_ButtonOnMouseUp()
	local index = this:GetID()
	local button = _G["RaidTargetFrame"..IconsInfo[index].MovingButton.."Button"]
	button:StopMovingOrSizing()
	button:SetUserPlaced(false)
	Banana_SaveFramePosistion(button)
end

function Banana_ButtonOnEnter(self)
	self = self or this
	if GetCVar("UberTooltips") == "1" then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	local info = IconsInfo[self:GetID()]
	if info and info.unitName then
		GameTooltip:AddLine(info.unitName)
		if info.numPlayersTargeting > 0 then
			GameTooltip:AddLine(format("Players targeting: %d", info.numPlayersTargeting), 0.5, 0.5, 0.5)
			GameTooltip:AddLine(table.concat(info.Players, "\n"))
		end
		GameTooltip:Show()
	else
		GameTooltip:SetText("Not used\n/bananabar to open config window\nCtrl+RightMouseButton to move buttons")
	end
end

function Banana_TargetRaidSymbol(index)
	local unit
	if superwow then
		unit = "mark"..index
		if UnitExists(unit) and Banana_GetSymbol(unit) == index then
			TargetUnit(unit)
			Banana_Update()
		end
		return
	end

	for i = 1, GetNumRaidMembers() do
		if Banana_TargetAttempt("raid"..i, index) then
			return
		end
	end
	for i = 1, GetNumPartyMembers() do
		if Banana_TargetAttempt("party"..i, index) then
			return
		end
	end
	if Banana_TargetAttempt("player", index) then
		return
	end
	if Banana_TargetAttemptNameplates(index) then
		return
	end
	
	Banana_PlayError()
	Banana_Error("Nothing to target")
	Banana_Update()
end

function Banana_TargetAttempt(unit, index)
	if not UnitExists(unit) then return false end
	
	if Banana_GetSymbol(unit) == index then
		TargetUnit(unit)
		Banana_Update()
		return true
	end

	local unitTarget = unit.."target"

	if not UnitExists(unitTarget) then return false end
	
	if Banana_GetSymbol(unitTarget) == index then
		TargetUnit(unitTarget)
		Banana_Error("Target: "..(UnitName(unitTarget) or "<Unknown>"))
		return true
	end
end

local function Banana_HideButton(frame)
	if not frame then return end
    
	if BananaConfigFrame:IsShown() then
        frame:Show()
        frame:SetAlpha(0.5)
	else
        frame:Hide()
        frame:SetAlpha(1)
    end
end

function Banana_Update()
	local numRaidMembers = GetNumRaidMembers()
	local numPartyMembers = GetNumPartyMembers()
	local inRaid = numRaidMembers > 0 and BANANA_CONFIG.SHOW_IN_RAID
	local inParty = numPartyMembers > 0 and BANANA_CONFIG.SHOW_IN_PARTY
	local isSolo = BANANA_CONFIG.SHOW_OUT_OF_GROUP
	
	if not (inParty or inRaid or isSolo) then
		for i = 1, 9 do
			Banana_HideButton(_G["RaidTargetFrame"..i.."Button"])
		end
		return
	end
	
	local prefix = inRaid and "raid" or "party"
	local limit = inRaid and numRaidMembers or (numPartyMembers + 1)
	
	for i = 1, 9 do
		local info = IconsInfo[i]
		info.numPlayersTargeting = 0
		info.unitName = nil
		info.symbol = nil
		info.isDead = nil
		info.isMyTarget = nil
		for k in pairs(info.Players) do info.Players[k] = nil end
	end

	for i = 1, limit do
		local unit = prefix..i
		if unit == "party"..limit then unit = "player" end

		if UnitExists(unit) then
			local symbol = Banana_GetSymbol(unit)
			if symbol then
				local info = IconsInfo[symbol]
				info.unitName = UnitName(unit)
				info.symbol = symbol
				info.isDead = UnitIsDead(unit)
				info.isMyTarget = UnitIsUnit(unit, "target")
			end

			local unitTarget = unit.."target"
		
			if UnitExists(unitTarget) then
				symbol = Banana_GetSymbol(unitTarget)
				if symbol then
					local info = IconsInfo[symbol]
					local _, englishClass = UnitClass(unit)
					local color = CLASS_COLORS[englishClass].hex
					info.symbol = symbol
					info.unitName = UnitName(unitTarget)
					info.numPlayersTargeting = info.numPlayersTargeting + 1
					info.Players[info.numPlayersTargeting] = color..UnitName(unit).."|r"
					info.isDead = UnitIsDead(unitTarget)
					info.isMyTarget = UnitIsUnit(unitTarget, "target")
				end
			end
		end
	end

	if superwow then
		for i = 1, 8 do
			local unit = "mark" .. i
			local info = IconsInfo[i]
			info.symbol = Banana_GetSymbol(unit)
			info.unitName = UnitExists(unit) and UnitName(unit)
			info.isDead = UnitIsDead(unit)
		end
	end
	
	for index = 1, 9 do
		local button = _G["RaidTargetFrame"..index.."Button"]
		local count = button.Count
		local info = IconsInfo[index]
		local numTargeting = info.numPlayersTargeting

		if info.unitName and numTargeting > 0 then
			count:SetText(numTargeting)
		else
			count:SetText("")
		end

		button:SetChecked(info.isMyTarget)

		if BANANA_CONFIG.HIDE_BUTTON_FRAMES then
			button.NormalTexture:Hide()
		else
			button.NormalTexture:Show()
		end
		
		if info.isDead and BANANA_CONFIG.GREY_OUT_DEATH then
			button:SetAlpha(0.5)
		else
			button:SetAlpha(1)
		end

		if info.unitName then
			if info.symbol then
				Banana_TexCoord(button.Icon, info.symbol)
				button:Show()
			else
				if BANANA_CONFIG.HIDE_UNUSED_BUTTONS then
					Banana_HideButton(button)
				else
					button:Show()
				end
			end
		else
			if BANANA_CONFIG.HIDE_UNUSED_BUTTONS then
				Banana_HideButton(button)
			else
				button:Show()
			end
		end
		if GameTooltip:IsOwned(button) then
			Banana_ButtonOnEnter(button)
		end
	end
end

function Banana_GetSymbol(unit)
    local result = GetRaidTargetIndex(unit)
    if not result then
		for i = 1, 16 do
			if UnitDebuff(unit, i) == huntersMark then
				result = 9
				break
			end
		end
    end
    return result
end

function Banana_SetSymbol(unit, index)
	if index <= 8 then
		if superwow and ((GetNumPartyMembers() + GetNumRaidMembers()) == 0) then
			SetRaidTarget(unit, index, 1)
		else
			SetRaidTarget(unit, index)
		end
		if index ~= 0 then
			Banana_PlaySetSymbol()
		end
	elseif index == 9 then
		if not markSpellIndex then
			Banana_Error("Hunter's Mark Spell not found")
			Banana_PlayError()
			return
		end
		CastSpell(markSpellIndex, BOOKTYPE_SPELL)
		Banana_PlaySetSymbol()
	end
end

function Banana_ClearAllSymbols()
	Banana_PlayRemoveAll()
	for i = 1, 8 do
		Banana_SetSymbol("player", i)
	end
	clearAttempts = 10
end

do
	local info = {}
	function Banana_ComboBoxLayout_Initialize()
		for key in pairs(info) do info[key] = nil end
		for i = 1, getn(Layouts) do
			info.text = Layouts[i]
			info.func = Banana_ComboBoxLayout_OnClick
			info.value = i
			info.checked = BANANA_CONFIG.BUTTON_LAYOUT == i
			UIDropDownMenu_AddButton(info)
		end
	end
end

function Banana_ComboBoxLayout_OnClick()
	local id = this:GetID()
	UIDropDownMenu_SetSelectedID(BananaConfigFrameComboBoxLayout, id)
	BANANA_CONFIG.BUTTON_LAYOUT = id
	Banana_Layout()
	BananaConfig_Update()
end

function BananaConfig_ValueChangedResize()
	if not BANANA_CONFIG then return end
	BANANA_CONFIG.BUTTON_SCALE = this:GetValue()
	BananaConfigFrameResizeSliderText:SetText("Buttons scale "..BANANA_CONFIG.BUTTON_SCALE.."%")
	Banana_UpdateScale()
end

function Banana_UpdateScale()
	local scale = BANANA_CONFIG.BUTTON_SCALE / 100
	for i = 1, 9 do
		local frame = _G["RaidTargetFrame"..i.."Button"]
		if frame:IsMovable() then
			frame:ClearAllPoints()
			Banana_SaveFramePosistion(frame)
			frame:SetScale(scale)
			Banana_SetFramePosition(frame)
		else
			frame:SetScale(scale)
		end
	end
end

function BananaConfig_CheckBox_OnClick()
	BANANA_CONFIG[this.var] = this:GetChecked() and true or false
	Banana_Update()
	Banana_Layout()
end

function Banana_Toggle()
	if BananaConfigFrame:IsShown() then
		HideUIPanel(BananaConfigFrame)
	else
		ShowUIPanel(BananaConfigFrame)
	end
end

function Banana_TargetCommand(arg)
	arg = tonumber(arg)
	if not arg or arg > 9 or arg < 1 then
		Banana_Error("/bananatarget number (Star is 1, skull is 8")
		return
	end
	Banana_TargetRaidSymbol(arg)
end

function Banana_Default()
	BANANA_CONFIG.BUTTON_SCALE = 100
	BANANA_CONFIG.BUTTON_LAYOUT = 1
	BANANA_CONFIG.SHOW_IN_PARTY = true
	BANANA_CONFIG.SHOW_IN_RAID = true
	BANANA_CONFIG.SHOW_OUT_OF_GROUP = true
	BANANA_CONFIG.HIDE_UNUSED_BUTTONS = false
	BANANA_CONFIG.HIDE_BUTTON_FRAMES = true
	BANANA_CONFIG.DISABLE_SOUND = true
	BANANA_CONFIG.DISABLE_ERROR_TEXT = true
	BANANA_CONFIG.GREY_OUT_DEATH = true
	BANANA_CONFIG.FLIP = false
	BANANA_CONFIG.DETACH = false

	Banana_UpdateScale()
	RaidTargetFrame1Button:ClearAllPoints()
	RaidTargetFrame2Button:ClearAllPoints()
	RaidTargetFrame3Button:ClearAllPoints()
	RaidTargetFrame4Button:ClearAllPoints()
	RaidTargetFrame5Button:ClearAllPoints()
	RaidTargetFrame6Button:ClearAllPoints()
	RaidTargetFrame7Button:ClearAllPoints()
	RaidTargetFrame8Button:ClearAllPoints()
	RaidTargetFrame9Button:ClearAllPoints()
	Banana_Layout()

	local starty = -GetScreenHeight() / 5
	local startx = GetScreenWidth() / 5
	local ofsx = -70
	local ofsy = 70

	BANANA_CONFIG.POS = {
		["RaidTargetFrame1Button"] = {
			["x"] = startx - (0 * ofsx),
			["y"] = starty - (0 * ofsy),
		},
		["RaidTargetFrame2Button"] = {
			["x"] = startx - (0 * ofsx),
			["y"] = starty - (1 * ofsy),
		},
		["RaidTargetFrame3Button"] = {
			["x"] = startx - (0 * ofsx),
			["y"] = starty - (2 * ofsy),
		},
		["RaidTargetFrame4Button"] = {
			["x"] = startx - (0 * ofsx),
			["y"] = starty - (3 * ofsy),
		},
		["RaidTargetFrame5Button"] = {
			["x"] = startx - (1 * ofsx),
			["y"] = starty - (0 * ofsy),
		},
		["RaidTargetFrame6Button"] = {
			["x"] = startx - (1 * ofsx),
			["y"] = starty - (1 * ofsy),
		},
		["RaidTargetFrame7Button"] = {
			["x"] = startx - (1 * ofsx),
			["y"] = starty - (2 * ofsy),
		},
		["RaidTargetFrame8Button"] = {
			["x"] = startx - (1 * ofsx),
			["y"] = starty - (3 * ofsy),
		},
		["RaidTargetFrame9Button"] = {
			["x"] = startx - (0.5 * ofsx),
			["y"] = starty - (4 * ofsy),
		},
	}
	Banana_SetFramePositionAll()
	BananaConfig_Update()
end

function Banana_CtRaMainTankUpdate()
	if not CT_RATarget then return end
	for i = 1, 10 do
		Banana_CtRaMainTankUpdateByIndex(i)
	end
end

function Banana_CtRaMainTankUpdateByIndex(mtindex)
    local ctraframe = "CT_RAMTGroupMember"..mtindex.."CastFrame"
    if not _G[ctraframe] then return end

    local frameName = "BananaMt"..mtindex
    local texName = "BananaMt"..mtindex.."Symbol"

    local frame = _G[frameName]
	if not frame then
		frame = CreateFrame("Frame", frameName, _G[ctraframe], "BananaMtSymbolTemplate")
		frame:SetFrameStrata("BACKGROUND")
        frame:SetPoint("RIGHT", ctraframe, "LEFT", 0, 0)
        frame:Hide()
    end
    frame:Hide()

    local tex = _G[texName]

    if CT_RATarget and CT_RATarget.MainTanks and CT_RATarget.MainTanks[mtindex] and CT_RATarget.MainTanks[mtindex][1] then
		if UnitExists("raid"..CT_RATarget.MainTanks[mtindex][1].."target") then
			local idx = Banana_GetSymbol("raid"..CT_RATarget.MainTanks[mtindex][1].."target")
			if idx then
				Banana_TexCoord(tex, idx)
				frame:Show()
				return
			end
		end
    end
end

function Banana_SaveFramePosistion(frame)
	if not frame then return end
	local left, top, scale = frame:GetLeft(), frame:GetTop(), frame:GetScale()
	local name = frame:GetName()
	if not (left and top and scale and name) then return end
	
	if not BANANA_CONFIG.POS then BANANA_CONFIG.POS = {} end
	if not BANANA_CONFIG.POS[name] then BANANA_CONFIG.POS[name] = {} end
	BANANA_CONFIG.POS[name].x = left * scale
	BANANA_CONFIG.POS[name].y = top * scale - GetScreenHeight()
end

function Banana_SetFramePosition(frame)
	if not (frame and frame:IsMovable() and BANANA_CONFIG.POS) then return end
	local framePos = BANANA_CONFIG.POS[frame:GetName()]
	if not framePos then return end
	
	local scale = frame:GetScale()
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", framePos.x / scale, framePos.y / scale)
end

function Banana_SetFramePositionAll()
	for i = 1, 9 do
		Banana_SetFramePosition(_G["RaidTargetFrame"..i.."Button"])
	end
end

function BananaConfig_Update()
	local scale = BANANA_CONFIG.BUTTON_SCALE
	BananaConfigFrameResizeSlider:SetValue(scale)
	BananaConfigFrameResizeSliderText:SetText("Buttons scale "..scale.."%")
	UIDropDownMenu_Initialize(BananaConfigFrameComboBoxLayout, Banana_ComboBoxLayout_Initialize)
    UIDropDownMenu_SetSelectedID(BananaConfigFrameComboBoxLayout, BANANA_CONFIG.BUTTON_LAYOUT)
	for i = 1, getn(Checkboxes) do
		if Checkboxes[i].frame then
			Checkboxes[i].frame:SetChecked(BANANA_CONFIG[Checkboxes[i].var])
		end
	end
end

function Banana_PlayError()
	if BANANA_CONFIG.DISABLE_SOUND then return end
	PlaySoundFile("Interface\\AddOns\\Bananabar\\Sound\\BananaNo.mp3")
end
function Banana_PlayRemove1()
	if BANANA_CONFIG.DISABLE_SOUND then return end
	PlaySoundFile("Interface\\AddOns\\Bananabar\\Sound\\BananaPlop1.mp3")
end

function Banana_PlayRemoveAll()
	if BANANA_CONFIG.DISABLE_SOUND then return end
	PlaySoundFile("Interface\\AddOns\\Bananabar\\Sound\\BananaPlop8.mp3")
end

function Banana_PlaySetSymbol()
	if BANANA_CONFIG.DISABLE_SOUND then return end
	PlaySoundFile("Interface\\AddOns\\Bananabar\\Sound\\BananaSetSymbol.mp3")
end

local function IsNameplate(frame)
	if frame:GetObjectType() ~= "Button" then return nil end
	if not frame:IsShown() then return nil end
	local child = frame:GetChildren()
	if not child then return nil end
	if not child:GetObjectType() == "StatusBar" then return nil end

	if frame:GetNumChildren() == 2 then
		if not shaguPlates then shaguPlates = true end
		return true
	end

	local region = frame:GetRegions()
	if not region then return nil end
	if not region:GetObjectType() == "Texture" then return nil end
	if not region:GetTexture() then return nil end

	return true
end

local numChildren = 0
local Frames
function Banana_TargetAttemptNameplates(index)
	if index == 9 then return nil end
	
	local button = raidTargetIconTexCoords[index]
	if not button then return nil end

	local bULx = button.ULx
	local bULy = button.ULy
	local numChildrenNew = WorldFrame:GetNumChildren()
	if numChildrenNew > numChildren then
		numChildren = numChildrenNew
		Frames = { WorldFrame:GetChildren() }
	end

	for _, nameplate in ipairs(Frames) do
		if IsNameplate(nameplate) then
			if shaguPlates then
				local baseplate, shaguplate = nameplate:GetChildren()
				if shaguplate.raidicon:IsShown() then
					local ULx,ULy = shaguplate.raidicon:GetTexCoord()
					if ULx == bULx and ULy == bULy then
						nameplate:Click()
						Banana_Update()
						return true
					end
				end
			else
				local _, _, _, _, _ , raidicon = nameplate:GetRegions()
				if raidicon:IsShown() and raidicon:GetObjectType() then
					if raidicon:GetTexture() then
						local ULx,ULy = raidicon:GetTexCoord()

						if ULx == bULx and ULy == bULy then
							nameplate:Click()
							Banana_Update()
							return true
						end
					end
				end
			end
		end
	end

	return nil
end


local function GetCheckBox(variable)
	for index, info in pairs(Checkboxes) do
		if info.var == variable then return info.frame end
	end
end

function Banana_Layout()
	local id = BANANA_CONFIG.BUTTON_LAYOUT
	local flipCheckBox = GetCheckBox("FLIP")
	local detachCheckBox = GetCheckBox("DETACH")
	
	if flipCheckBox and detachCheckBox then
		if id ~= 5 then
			flipCheckBox:Enable()
			flipCheckBox.Text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
			detachCheckBox:Enable()
			detachCheckBox.Text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		else
			flipCheckBox:Disable()
			flipCheckBox.Text:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			detachCheckBox:Disable()
			detachCheckBox.Text:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
		end
	end
	
	if id == 1 then
		local left, right = "LEFT", "RIGHT"
		local padding = 0
		if BANANA_CONFIG.FLIP then
			left, right = "RIGHT", "LEFT"
			padding = -padding
		end
		RaidTargetFrame1Button:SetMovable(true)
		RaidTargetFrame2Button:SetMovable(false)
		RaidTargetFrame3Button:SetMovable(false)
		RaidTargetFrame4Button:SetMovable(false)
		RaidTargetFrame5Button:SetMovable(false)
		RaidTargetFrame6Button:SetMovable(false)
		RaidTargetFrame7Button:SetMovable(false)
		RaidTargetFrame8Button:SetMovable(false)
		RaidTargetFrame9Button:SetMovable(true)
	
		RaidTargetFrame1Button:ClearAllPoints()
		RaidTargetFrame2Button:ClearAllPoints()
		RaidTargetFrame2Button:SetPoint(left, RaidTargetFrame1Button, right, padding, 0)
		RaidTargetFrame3Button:ClearAllPoints()
		RaidTargetFrame3Button:SetPoint(left, RaidTargetFrame2Button, right, padding, 0)
		RaidTargetFrame4Button:ClearAllPoints()
		RaidTargetFrame4Button:SetPoint(left, RaidTargetFrame3Button, right, padding, 0)
		RaidTargetFrame5Button:ClearAllPoints()
		RaidTargetFrame5Button:SetPoint(left, RaidTargetFrame4Button, right, padding, 0)
		RaidTargetFrame6Button:ClearAllPoints()
		RaidTargetFrame6Button:SetPoint(left, RaidTargetFrame5Button, right, padding, 0)
		RaidTargetFrame7Button:ClearAllPoints()
		RaidTargetFrame7Button:SetPoint(left, RaidTargetFrame6Button, right, padding, 0)
		RaidTargetFrame8Button:ClearAllPoints()
		RaidTargetFrame8Button:SetPoint(left, RaidTargetFrame7Button, right, padding, 0)
		RaidTargetFrame9Button:ClearAllPoints()
	
		IconsInfo[1].MovingButton = 1
		IconsInfo[2].MovingButton = 1
		IconsInfo[3].MovingButton = 1
		IconsInfo[4].MovingButton = 1
		IconsInfo[5].MovingButton = 1
		IconsInfo[6].MovingButton = 1
		IconsInfo[7].MovingButton = 1
		IconsInfo[8].MovingButton = 1
		IconsInfo[9].MovingButton = 9
	
		if not BANANA_CONFIG.DETACH then
			RaidTargetFrame9Button:SetMovable(false)
			RaidTargetFrame9Button:SetPoint(right, RaidTargetFrame1Button, left, -padding, 0)
			IconsInfo[9].MovingButton = 1
		end
	elseif id == 2 then
		local left, right = "LEFT", "RIGHT"
		local top, bottom = "TOP", "BOTTOM"
		local padding = 0
		if BANANA_CONFIG.FLIP then
			left, right = "RIGHT", "LEFT"
			top, bottom = "BOTTOM", "TOP"
			padding = -padding
		end
		RaidTargetFrame1Button:SetMovable(true)
		RaidTargetFrame2Button:SetMovable(false)
		RaidTargetFrame3Button:SetMovable(false)
		RaidTargetFrame4Button:SetMovable(false)
		RaidTargetFrame5Button:SetMovable(false)
		RaidTargetFrame6Button:SetMovable(false)
		RaidTargetFrame7Button:SetMovable(false)
		RaidTargetFrame8Button:SetMovable(false)
		RaidTargetFrame9Button:SetMovable(true)
	
		RaidTargetFrame1Button:ClearAllPoints()
		RaidTargetFrame2Button:ClearAllPoints()
		RaidTargetFrame2Button:SetPoint(left, RaidTargetFrame1Button, right, padding, 0)
		RaidTargetFrame3Button:ClearAllPoints()
		RaidTargetFrame3Button:SetPoint(left, RaidTargetFrame2Button, right, padding, 0)
		RaidTargetFrame4Button:ClearAllPoints()
		RaidTargetFrame4Button:SetPoint(left, RaidTargetFrame3Button, right, padding, 0)
		RaidTargetFrame5Button:ClearAllPoints()
		RaidTargetFrame5Button:SetPoint(top, RaidTargetFrame1Button, bottom, 0, -padding)
		RaidTargetFrame6Button:ClearAllPoints()
		RaidTargetFrame6Button:SetPoint(left, RaidTargetFrame5Button, right, padding, 0)
		RaidTargetFrame7Button:ClearAllPoints()
		RaidTargetFrame7Button:SetPoint(left, RaidTargetFrame6Button, right, padding, 0)
		RaidTargetFrame8Button:ClearAllPoints()
		RaidTargetFrame8Button:SetPoint(left, RaidTargetFrame7Button, right, padding, 0)
		RaidTargetFrame9Button:ClearAllPoints()
	
		IconsInfo[1].MovingButton = 1
		IconsInfo[2].MovingButton = 1
		IconsInfo[3].MovingButton = 1
		IconsInfo[4].MovingButton = 1
		IconsInfo[5].MovingButton = 1
		IconsInfo[6].MovingButton = 1
		IconsInfo[7].MovingButton = 1
		IconsInfo[8].MovingButton = 1
		IconsInfo[9].MovingButton = 9
	
		if not BANANA_CONFIG.DETACH then
			RaidTargetFrame9Button:SetMovable(false)
			RaidTargetFrame9Button:SetPoint(right, RaidTargetFrame1Button, left, -padding, 0)
			IconsInfo[9].MovingButton = 1
		end
	elseif id == 3 then
		local left, right = "LEFT", "RIGHT"
		local top, bottom = "TOP", "BOTTOM"
		local padding = 0
		if BANANA_CONFIG.FLIP then
			left, right = "RIGHT", "LEFT"
			top, bottom = "BOTTOM", "TOP"
			padding = -padding
		end
		RaidTargetFrame1Button:SetMovable(true)
		RaidTargetFrame2Button:SetMovable(false)
		RaidTargetFrame3Button:SetMovable(false)
		RaidTargetFrame4Button:SetMovable(false)
		RaidTargetFrame5Button:SetMovable(false)
		RaidTargetFrame6Button:SetMovable(false)
		RaidTargetFrame7Button:SetMovable(false)
		RaidTargetFrame8Button:SetMovable(false)
		RaidTargetFrame9Button:SetMovable(true)
	
		RaidTargetFrame1Button:ClearAllPoints()
		RaidTargetFrame2Button:ClearAllPoints()
		RaidTargetFrame2Button:SetPoint(left, RaidTargetFrame1Button, right, padding, 0)
		RaidTargetFrame3Button:ClearAllPoints()
		RaidTargetFrame3Button:SetPoint(top, RaidTargetFrame1Button, bottom, 0, -padding)
		RaidTargetFrame4Button:ClearAllPoints()
		RaidTargetFrame4Button:SetPoint(left, RaidTargetFrame3Button, right, padding, 0)
		RaidTargetFrame5Button:ClearAllPoints()
		RaidTargetFrame5Button:SetPoint(top, RaidTargetFrame3Button, bottom, 0, -padding)
		RaidTargetFrame6Button:ClearAllPoints()
		RaidTargetFrame6Button:SetPoint(left, RaidTargetFrame5Button, right, padding, 0)
		RaidTargetFrame7Button:ClearAllPoints()
		RaidTargetFrame7Button:SetPoint(top, RaidTargetFrame5Button, bottom, 0, -padding)
		RaidTargetFrame8Button:ClearAllPoints()
		RaidTargetFrame8Button:SetPoint(left, RaidTargetFrame7Button, right, padding, 0)
		RaidTargetFrame9Button:ClearAllPoints()
	
		IconsInfo[1].MovingButton = 1
		IconsInfo[2].MovingButton = 1
		IconsInfo[3].MovingButton = 1
		IconsInfo[4].MovingButton = 1
		IconsInfo[5].MovingButton = 1
		IconsInfo[6].MovingButton = 1
		IconsInfo[7].MovingButton = 1
		IconsInfo[8].MovingButton = 1
		IconsInfo[9].MovingButton = 9
	
		if not BANANA_CONFIG.DETACH then
			RaidTargetFrame9Button:SetMovable(false)
			RaidTargetFrame9Button:SetPoint(bottom, RaidTargetFrame1Button, top, 0, padding)
			IconsInfo[9].MovingButton = 1
		end
	elseif id == 4 then
		local top, bottom = "TOP", "BOTTOM"
		local padding = -0
		if BANANA_CONFIG.FLIP then
			top, bottom = "BOTTOM", "TOP"
			padding = -padding
		end
		RaidTargetFrame1Button:SetMovable(true)
		RaidTargetFrame2Button:SetMovable(false)
		RaidTargetFrame3Button:SetMovable(false)
		RaidTargetFrame4Button:SetMovable(false)
		RaidTargetFrame5Button:SetMovable(false)
		RaidTargetFrame6Button:SetMovable(false)
		RaidTargetFrame7Button:SetMovable(false)
		RaidTargetFrame8Button:SetMovable(false)
		RaidTargetFrame9Button:SetMovable(true)
	
		RaidTargetFrame1Button:ClearAllPoints()
		RaidTargetFrame2Button:ClearAllPoints()
		RaidTargetFrame2Button:SetPoint(top, RaidTargetFrame1Button, bottom, 0, padding)
		RaidTargetFrame3Button:ClearAllPoints()
		RaidTargetFrame3Button:SetPoint(top, RaidTargetFrame2Button, bottom, 0, padding)
		RaidTargetFrame4Button:ClearAllPoints()
		RaidTargetFrame4Button:SetPoint(top, RaidTargetFrame3Button, bottom, 0, padding)
		RaidTargetFrame5Button:ClearAllPoints()
		RaidTargetFrame5Button:SetPoint(top, RaidTargetFrame4Button, bottom, 0, padding)
		RaidTargetFrame6Button:ClearAllPoints()
		RaidTargetFrame6Button:SetPoint(top, RaidTargetFrame5Button, bottom, 0, padding)
		RaidTargetFrame7Button:ClearAllPoints()
		RaidTargetFrame7Button:SetPoint(top, RaidTargetFrame6Button, bottom, 0, padding)
		RaidTargetFrame8Button:ClearAllPoints()
		RaidTargetFrame8Button:SetPoint(top, RaidTargetFrame7Button, bottom, 0, padding)
		RaidTargetFrame9Button:ClearAllPoints()
	
		IconsInfo[1].MovingButton = 1
		IconsInfo[2].MovingButton = 1
		IconsInfo[3].MovingButton = 1
		IconsInfo[4].MovingButton = 1
		IconsInfo[5].MovingButton = 1
		IconsInfo[6].MovingButton = 1
		IconsInfo[7].MovingButton = 1
		IconsInfo[8].MovingButton = 1
		IconsInfo[9].MovingButton = 9
	
		if not BANANA_CONFIG.DETACH then
			RaidTargetFrame9Button:SetMovable(false)
			RaidTargetFrame9Button:SetPoint(bottom, RaidTargetFrame1Button, top, 0, -padding)
			IconsInfo[9].MovingButton = 1
		end
	elseif id == 5 then
		RaidTargetFrame1Button:SetMovable(true)
		RaidTargetFrame2Button:SetMovable(true)
		RaidTargetFrame3Button:SetMovable(true)
		RaidTargetFrame4Button:SetMovable(true)
		RaidTargetFrame5Button:SetMovable(true)
		RaidTargetFrame6Button:SetMovable(true)
		RaidTargetFrame7Button:SetMovable(true)
		RaidTargetFrame8Button:SetMovable(true)
		RaidTargetFrame9Button:SetMovable(true)
	
		RaidTargetFrame1Button:ClearAllPoints()
		RaidTargetFrame2Button:ClearAllPoints()
		RaidTargetFrame3Button:ClearAllPoints()
		RaidTargetFrame4Button:ClearAllPoints()
		RaidTargetFrame5Button:ClearAllPoints()
		RaidTargetFrame6Button:ClearAllPoints()
		RaidTargetFrame7Button:ClearAllPoints()
		RaidTargetFrame8Button:ClearAllPoints()
		RaidTargetFrame9Button:ClearAllPoints()
	
		IconsInfo[1].MovingButton = 1
		IconsInfo[2].MovingButton = 2
		IconsInfo[3].MovingButton = 3
		IconsInfo[4].MovingButton = 4
		IconsInfo[5].MovingButton = 5
		IconsInfo[6].MovingButton = 6
		IconsInfo[7].MovingButton = 7
		IconsInfo[8].MovingButton = 8
		IconsInfo[9].MovingButton = 9
	
		Banana_SetFramePositionAll()
	end
end
