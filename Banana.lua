local YELLOW = "|c00f7f26c"
local ORANGE = "|c00f69218"
local WHITE = "|c00e7e4d9"
local MAGENTA = "|c00cb32dd"
local GREEN = "|c000fb20a"
local LGREEN = "|c00c0ffc0"
local BLUE = "|c00007aff"
local LBLUE = "|c008cb0c5"
local RED = "|c00d7422e"

local FORMAT_PRINT = LGREEN.."["..GREEN.."BananaBar"..LGREEN.."] %s"..FONT_COLOR_CODE_CLOSE

-- Bindings
BINDING_HEADER_BANANA_PLUGINNAME = "BananaBar Raid Target Symbols"
BINDING_NAME_BANANA_TARGET_SYMBOL1 = "Target Symbol 1 ("..RAID_TARGET_1..")"
BINDING_NAME_BANANA_TARGET_SYMBOL2 = "Target Symbol 2 ("..RAID_TARGET_2..")"
BINDING_NAME_BANANA_TARGET_SYMBOL3 = "Target Symbol 3 ("..RAID_TARGET_3..")"
BINDING_NAME_BANANA_TARGET_SYMBOL4 = "Target Symbol 4 ("..RAID_TARGET_4..")"
BINDING_NAME_BANANA_TARGET_SYMBOL5 = "Target Symbol 5 ("..RAID_TARGET_5..")"
BINDING_NAME_BANANA_TARGET_SYMBOL6 = "Target Symbol 6 ("..RAID_TARGET_6..")"
BINDING_NAME_BANANA_TARGET_SYMBOL7 = "Target Symbol 7 ("..RAID_TARGET_7..")"
BINDING_NAME_BANANA_TARGET_SYMBOL8 = "Target Symbol 8 ("..RAID_TARGET_8..")"
BINDING_NAME_BANANA_TARGET_SYMBOL9 = "Target Symbol 9 (Huntersmark)"

-- Saved Variables
BANANA_CONFIG = {}
BANANA_CONFIG.HIDE_UNUSED_BUTTONS = 0
BANANA_CONFIG.BUTTON_LAYOUT = 1
BANANA_CONFIG.BUTTON_SCALE = 100
BANANA_CONFIG.HIDE_BUTTON_FRAMES = 0
BANANA_CONFIG.DISABLE_SOUND = 1
BANANA_CONFIG.DISABLE_ERROR_TEXT = 1
BANANA_CONFIG.GREY_OUT_DEATH = 1
BANANA_CONFIG.POS = {}
BANANA_CONFIG.SHOW_IN_RAID = 1
BANANA_CONFIG.SHOW_IN_PARTY = 1
BANANA_CONFIG.SHOW_OUT_OF_GROUP = 1
BANANA_CONFIG.SHOW_EXTRA_INFO = nil
BANANA_CONFIG.FLIP = 0
BANANA_CONFIG.DETACH = 0

-- Slash Commands
SLASH_BANANA1 = "/bananabar"
SLASH_BANANA2 = "/bb"
SLASH_BANANABAR1 = "/banana"
SLASH_BANANABAR2 = "/bbr"
SLASH_BANANATARGET1 = "/bbtarget"
SLASH_BANANATARGET2 = "/bananatarget"
SLASH_BANANATARGET3 = "/bananabartarget"
SLASH_BANANATARGET4 = "/bbrtarget"

local raidTargetIconTexCoords = {}
raidTargetIconTexCoords[1] = { ULx = 0, 	ULy = 0 	}
raidTargetIconTexCoords[2] = { ULx = 0.25,  ULy = 0 	}
raidTargetIconTexCoords[3] = { ULx = 0.5, 	ULy = 0 	}
raidTargetIconTexCoords[4] = { ULx = 0.75, 	ULy = 0 	}
raidTargetIconTexCoords[5] = { ULx = 0, 	ULy = 0.25 	}
raidTargetIconTexCoords[6] = { ULx = 0.25, 	ULy = 0.25 	}
raidTargetIconTexCoords[7] = { ULx = 0.5, 	ULy = 0.25 	}
raidTargetIconTexCoords[8] = { ULx = 0.75, 	ULy = 0.25 	}

local huntersMark = "Interface\\Icons\\Ability_Hunter_SniperShot"
local superwow = SetAutoloot and true or false
local shaguPlates = nil
local icons = {}

local function Banana_Print(msg)
	local strx = string.format(FORMAT_PRINT, tostring(msg))
	DEFAULT_CHAT_FRAME:AddMessage(strx)
end

local function Banana_Error(msg)
	if BANANA_CONFIG.DISABLE_ERROR_TEXT ~= 1 then
		local strx = string.format(FORMAT_PRINT, tostring(msg))
		DEFAULT_CHAT_FRAME:AddMessage(strx)
	end
end

local function InGroupOrRaid()
	return ((GetNumPartyMembers() + GetNumRaidMembers()) > 0)
end

function Banana_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	SlashCmdList["BANANA"] = Banana_Toggle
	SlashCmdList["BANANABAR"] = Banana_Toggle
	SlashCmdList["BANANATARGET"] = Banana_TargetCommand
end

function Banana_OnEvent()
	if ( event == "ADDON_LOADED" ) and arg1 == "bananabar" then
		this:UnregisterEvent("ADDON_LOADED")
		for i = 1, 9 do
			icons[i] = {}
			icons[i].FrameIcon = getglobal("RaidTargetFrame"..i.."ButtonIcon")
			icons[i].FrameButton = getglobal("RaidTargetFrame"..i.."Button")
			icons[i].FrameFlash = getglobal("RaidTargetFrame"..i.."ButtonFlash")
			icons[i].FrameHotKey = getglobal("RaidTargetFrame"..i.."ButtonHotKey")
			icons[i].FrameName = getglobal("RaidTargetFrame"..i.."ButtonName")
			icons[i].FrameCount = getglobal("RaidTargetFrame"..i.."ButtonCount")
			icons[i].FrameNormalTexture = getglobal("RaidTargetFrame"..i.."ButtonNormalTexture")
			icons[i].FrameMobName = getglobal("RaidTargetFrame"..i.."ButtonMobName")
			icons[i].FrameTargetSymbol = getglobal("RaidTargetFrame"..i.."ButtonTargetSymbol")
			icons[i].Count = 0
			icons[i].Target = nil
			icons[i].Info = nil
			icons[i].Debuff = nil
			icons[i].MovingButton = 1
			icons[i].IsDeath = nil
			icons[i].MyTarget = nil
			icons[i].Players = {}
			for j = 1, 40 do
				icons[i].Players[j] = { Name = "", Color = { r = .0, g = .0, b = .0 }}
			end
		end
		Banana_Print("Banana Raid Symbols loaded. Type /bb, /bbr, /banana or /bananabar to open config panel.")
		Banana_Print("Use Ctrl + RightClick to move buttons")
		Banana_Print("Use Alt + LeftClick to clear all existing symbols")

		if not BANANA_CONFIG.SHOW_EXTRA_INFO then
			UIDropDownMenu_Initialize(BananaConfigFrameComboBoxLayout, Banana_ComboBoxLayout_Initialize)
			Banana_Default()
			BananaConfigFrame:Show()
		else
			Banana_UpdateScale()
			Banana_Layout()
			Banana_ReloadFramePositions()
			UIDropDownMenu_Initialize(BananaConfigFrameComboBoxLayout, Banana_ComboBoxLayout_Initialize)
			Banana_UpdateDialogFromVariables()
		end
	end
end

local attempts = 0
function Banana_OnUpdate()
	if (this.tick or 0.1) > GetTime() then
		return
	else
		this.tick = GetTime() + 0.1
	end
	Banana_UpdateStatus()
    Banana_CtRaMainTankUpdate()
	if attempts > 0 then
		Banana_SetSymbol("player", 0)
		attempts = attempts - 1
	end
end

local function Banana_TexCoord(icon,index)
    if index == 9 then
        icon:SetTexture("Interface\\AddOns\\Bananabar\\Images\\HuntermarkArrow")
        icon:SetTexCoord(0, 1, 0, 1)
        return
    end
    local button = UnitPopupButtons["RAID_TARGET_"..index]
    local x1 = button.tCoordLeft
	local y1 = button.tCoordTop
	local x2 = button.tCoordRight
	local y2 = button.tCoordBottom

    icon:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcons")
	icon:SetTexCoord(x1, x2, y1, y2)
end

function Banana_RaidTargetButtonOnLoad()
	local index = this:GetID()
	local icon = getglobal(this:GetName().."Icon")
    Banana_TexCoord(icon,index)
end

function Banana_ButtonOnClick(mouseButton)
	local index = this:GetID()
	if (IsControlKeyDown()) and mouseButton == "LeftButton" then
		if BANANA_CONFIG.HIDE_UNUSED_BUTTONS ~= 1 then
			if not UnitExists("target") then
				Banana_TargetRaidSymbol(index)
				if not UnitExists("target") then
					Banana_Error("Not target selected.")
					Banana_PlayError()
					return
				end
			end
			
			local oldindex = (Banana_GetSymbol("target") or 0)
			if oldindex == index then
				Banana_SetSymbol("target", 0)
				Banana_PlayRemove1()
			else
				Banana_SetSymbol("target", index)
			end
			Banana_UpdateStatus()
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
	if (not IsControlKeyDown()) and (not IsAltKeyDown()) and mouseButton == "LeftButton" then
		Banana_TargetRaidSymbol(index)
		return
	end
	if (IsControlKeyDown()) and mouseButton == "RightButton" then
		--moving
		return
	end
	if (IsAltKeyDown()) and mouseButton == "LeftButton" then
		Banana_ClearAllSymbols()
		return
	end
	Banana_Print("Use Ctrl + RightClick to move buttons")
	Banana_Print("Use Alt + LeftClick to clear all existing symbols")
end

local movingButton = nil

function Banana_ButtonOnMouseDown(mouseButton)
	if IsControlKeyDown() and mouseButton == "RightButton" then
		local index = this:GetID()
		if not movingButton then
			if getglobal("RaidTargetFrame"..icons[index].MovingButton.."Button"):IsMovable() then
				movingButton = index
				getglobal("RaidTargetFrame"..icons[index].MovingButton.."Button"):StartMoving()
			end
		end
	end
	if (not IsControlKeyDown()) and mouseButton == "RightButton" then
		Banana_UpdateStatus()
	end
end

function Banana_ButtonOnMouseUp()
	if movingButton then
		getglobal("RaidTargetFrame"..icons[movingButton].MovingButton.."Button"):StopMovingOrSizing()
		getglobal("RaidTargetFrame"..icons[movingButton].MovingButton.."Button"):SetUserPlaced(false)
		Banana_SaveFramePos(getglobal("RaidTargetFrame"..icons[movingButton].MovingButton.."Button"))
		movingButton = nil
	end
end

function Banana_ButtonOnEnter()
	if ( GetCVar("UberTooltips") == "1" ) then
		GameTooltip_SetDefaultAnchor(GameTooltip, this)
	else
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	end
	local index = this:GetID()
	if (icons[index].Target) then
		GameTooltip:AddLine(icons[index].Target)
		if icons[index].Count > 0 then
			GameTooltip:AddLine(icons[index].Count.." Players",0.5,0.5,0.5)
			for player = 1,icons[index].Count,1 do
				if icons[index].Players[player].Name ~= "" then
					GameTooltip:AddLine(icons[index].Players[player].Name,icons[index].Players[player].Color.r,icons[index].Players[player].Color.g,icons[index].Players[player].Color.b)
				end
			end
		end
		GameTooltip:Show()
	else
		GameTooltip:SetText("Not used\n/bananabar to open config window\nCtrl+RightMouseButton to move buttons")
	end
end

function Banana_TargetRaidSymbol(index)
	if superwow then
		if Banana_TargetRaidSymbolUnit("mark"..index, index) then
			return
		end
	end
	for i = 1, 40 do
		if Banana_TargetRaidSymbolUnit("raid"..i, index) then
			return
		end
	end
	for i = 1, 4 do
		if Banana_TargetRaidSymbolUnit("party"..i, index) then
			return
		end
	end
	if Banana_TargetRaidSymbolUnit("player", index) then
		return
	end
	if Banana_ScanNameplates(index) then
		return
	end
	Banana_PlayError()
	Banana_Error("Nothing to target")
	Banana_UpdateStatus()
end

function Banana_TargetRaidSymbolUnit(unit, index)
	if UnitExists(unit) then
	    if ( Banana_GetSymbol(unit) == index ) then
			TargetUnit(unit)
			Banana_UpdateStatus()
			return 1
	    end

		if UnitExists(unit.."target") then
		    if ( Banana_GetSymbol(unit.."target") == index ) then
				TargetUnit(unit.."target")
				Banana_Error("Target: "..(UnitName(unit.."target") or "<Unknown>"))
				return 1
		    end
		end
	end
    return nil
end

local function Banana_Reset()
	for index = 1, 9 do
		icons[index].Count = 0
    	icons[index].Target = nil
    	icons[index].TargetSymbol = nil
		for k in pairs(icons[index].Players) do
			icons[index].Players[k].Name = ""
			icons[index].Players[k].Color.r = .0
			icons[index].Players[k].Color.g = .0
			icons[index].Players[k].Color.b = .0
		end
		icons[index].Debuff = nil
		icons[index].IsDeath = nil
		icons[index].MyTarget = nil
  	end
end

local function Banana_DebuffCheck(sUnitname, sBuffname)
	local iIterator = 1
	while (true) do
		local debuffTexture, debuffApplications, debuffDispelType = UnitDebuff(sUnitname, iIterator)
		if not debuffTexture then
			return ""
		end
		if debuffTexture == sBuffname then
			return sBuffname
		end
		iIterator = iIterator + 1
	end
end

local function Banana_HideButton(frame)
    if BananaConfigFrame:IsVisible() then
        frame:Show()
        frame:SetAlpha(0.16)
    else
        frame:Hide()
        frame:SetAlpha(1)
    end
end

function Banana_UpdateStatus()
	if GetNumRaidMembers() > 0 then
        if BANANA_CONFIG.SHOW_IN_RAID == 1 then
            Banana_Reset()
            Banana_ScanPlayers("raid", 40)
			Banana_ScanNpcs()
            Banana_UpdateButtons()
        else
            for index = 1, 9 do
                local button = getglobal("RaidTargetFrame"..index.."Button")
                Banana_HideButton(button)
            end
        end
	elseif GetNumPartyMembers() > 0 then
        if BANANA_CONFIG.SHOW_IN_PARTY == 1 then
            Banana_Reset()
            Banana_ScanPlayers("party", 5)
			Banana_ScanNpcs()
            Banana_UpdateButtons()
        else
            for index = 1, 9 do
                local button = getglobal("RaidTargetFrame"..index.."Button")
                Banana_HideButton(button)
            end
        end
	else
        if BANANA_CONFIG.SHOW_OUT_OF_GROUP == 1 then
            Banana_Reset()
            Banana_ScanPlayers("party", 5)
			Banana_ScanNpcs()
            Banana_UpdateButtons()
        else
            for index = 1, 9 do
                local button = getglobal("RaidTargetFrame"..index.."Button")
                Banana_HideButton(button)
            end
        end
	end
end

function Banana_ScanPlayers(prefix,count)
  	for i = 1, count do
        local loopmember = prefix..i
        if loopmember == "party5" then
            loopmember = "player"
        end
        if UnitExists(loopmember) then
			local loopmembersymbol = (Banana_GetSymbol(loopmember) or 0)
            if loopmembersymbol ~= 0 then
                Banana_UpdateTargetSymbol(loopmember,loopmembersymbol)
		    	icons[loopmembersymbol].Target = UnitName(loopmember)
				
                -- loopmember has aggro?
                if UnitIsUnit(loopmember,loopmember.."targettarget") then
					icons[loopmembersymbol].Aggro = true
				end
				Banana_UpdateStatusScanTarget(loopmember,i,loopmembersymbol)
            end

            local loopmembertarget = loopmember.."target"
     
            if UnitExists(loopmembertarget) then
                local symbol = (Banana_GetSymbol(loopmembertarget) or 0)
                if symbol ~= 0 then
                    local _, englishClass = UnitClass(loopmember)
                    Banana_UpdateTargetSymbol(loopmembertarget,symbol)
                    icons[symbol].Target = UnitName(loopmembertarget)
                    icons[symbol].Count = icons[symbol].Count + 1
                    icons[symbol].Players[icons[symbol].Count].Name = UnitName(loopmember)
                    icons[symbol].Players[icons[symbol].Count].Color.r = RAID_CLASS_COLORS[englishClass].r
                    icons[symbol].Players[icons[symbol].Count].Color.g = RAID_CLASS_COLORS[englishClass].g
                    icons[symbol].Players[icons[symbol].Count].Color.b = RAID_CLASS_COLORS[englishClass].b
					Banana_UpdateStatusScanTarget(loopmembertarget,i,symbol)
                end
            end
        end
    end
end

function Banana_ScanNpcs()
	if not superwow then
		return
	end
	for i = 1, 8 do
		local m = "mark" .. i
		if UnitExists(m) then
			icons[i].Target = UnitName(m)
		end
		if not icons[i].IsDeath then
			if UnitIsDead(m) then
				icons[i].IsDeath = 1
			else
				icons[i].IsDeath = 0
			end
		end
	end
end

function Banana_UpdateTargetSymbol(unit,symbol)
    local target = unit.."target"
    if not icons[symbol].TargetSymbol  then
        if not UnitExists(target) then
            icons[symbol].TargetSymbol = 0
        else
            local tts = Banana_GetSymbol(target) or 0
            icons[symbol].TargetSymbol = tts
        end
    end
end

function Banana_UpdateStatusScanTarget(targettype,i,index)
	if not icons[index].Debuff then
		icons[index].Debuff = Banana_DebuffCheck(targettype, "Interface\\Icons\\Spell_Shadow_GatherShadows")
	end

	if not icons[index].IsDeath then
		if UnitIsDead(targettype) then
			icons[index].IsDeath = 1
		else
			icons[index].IsDeath = 0
		end
	end

	if not icons[index].MyTarget then
		if UnitIsUnit(targettype, "target") then
			icons[index].MyTarget = 1
		else
			icons[index].MyTarget = 0
		end
	end
end

function Banana_UpdateButtons()
	for index = 1, 9 do
		local button = getglobal("RaidTargetFrame"..index.."Button")
		local flash = getglobal("RaidTargetFrame"..index.."ButtonFlash")
		local count = getglobal("RaidTargetFrame"..index.."ButtonCount")
		
		if ( icons[index].Target) then
			count:SetText(tostring(icons[index].Count))
			count:Show()
			button:Show()
			
			if icons[index].Debuff ~= "" then
				flash:ClearAllPoints()
				flash:SetPoint("TOPLEFT",button,"TOPLEFT")
				flash:SetWidth(18)
				flash:SetHeight(18)
				flash:SetTexture(icons[index].Debuff)
				flash:Show()
			else
				flash:Hide()
			end
		else
			flash:Hide()
			count:Hide()
		end
		if icons[index].MyTarget == 1 then
			icons[index].FrameButton:SetChecked(1)
		else
			icons[index].FrameButton:SetChecked(0)
		end

		if icons[index].IsDeath == 1 and BANANA_CONFIG.GREY_OUT_DEATH == 1 then
			icons[index].FrameButton:SetAlpha(0.33)
		else
			if BANANA_CONFIG.HIDE_UNUSED_BUTTONS == 1 and (not icons[index].Target) then
				Banana_HideButton(icons[index].FrameButton)
			else
				icons[index].FrameButton:SetAlpha(1)
				icons[index].FrameButton:Show()
			end
		end

		if BANANA_CONFIG.HIDE_BUTTON_FRAMES == 1 then
			icons[index].FrameNormalTexture:Hide()
		else
			icons[index].FrameNormalTexture:Show()
		end

		if icons[index].Target and BANANA_CONFIG.SHOW_EXTRA_INFO == 1 then
			icons[index].FrameMobName:SetText(icons[index].Target)
			icons[index].FrameMobName:Show()
			if icons[index].TargetSymbol and icons[index].TargetSymbol ~= 0 then        
				Banana_TexCoord(icons[index].FrameTargetSymbol,icons[index].TargetSymbol)    
				icons[index].FrameTargetSymbol:Show()
			else
				icons[index].FrameTargetSymbol:Hide()
			end
		else
			icons[index].FrameMobName:SetText()
			icons[index].FrameMobName:Hide()
			icons[index].FrameTargetSymbol:Hide()
		end
  	end
end

function Banana_ComboBoxLayout_Initialize()
	local info = {}

	info.text = BANANA_LAYOUT1
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 1
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)

	info.text = BANANA_LAYOUT2
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 2
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)

	info.text = BANANA_LAYOUT3
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 3
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)

	info.text = BANANA_LAYOUT4
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 4
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)

	info.text = BANANA_LAYOUT5
	info.func = Banana_ComboBoxLayout_OnClick
	info.value = 5
	info.checked = BANANA_CONFIG.BUTTON_LAYOUT == info.value
	UIDropDownMenu_AddButton(info)
end

function Banana_ComboBoxLayout_OnClick()
	UIDropDownMenu_SetSelectedID(BananaConfigFrameComboBoxLayout, this:GetID())
	if BANANA_CONFIG.BUTTON_LAYOUT ~= this:GetID() then
		BANANA_CONFIG.BUTTON_LAYOUT = this:GetID()
		Banana_Layout()
	end
end

function BananaConfig_ValueChangedResize()
	BANANA_CONFIG.BUTTON_SCALE = this:GetValue()
	Banana_UpdateScale()
end

function Banana_UpdateScale()
	Banana_UpdateFrameScale(RaidTargetFrame1Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame2Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame3Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame4Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame5Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame6Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame7Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame8Button, BANANA_CONFIG.BUTTON_SCALE / 100)
	Banana_UpdateFrameScale(RaidTargetFrame9Button, BANANA_CONFIG.BUTTON_SCALE / 100)
end

function Banana_UpdateFrameScale(frame,scale)
	if frame:IsMovable() then
		frame:ClearAllPoints()
		Banana_SaveFramePos(frame)
		frame:SetScale(scale)
		Banana_LoadFramePos(frame)
	else
		frame:SetScale(scale)
	end
end

function BananaConfig_ValueChangedShowInRaid()
	if this:GetChecked() then
		BANANA_CONFIG.SHOW_IN_RAID = 1
	else
		BANANA_CONFIG.SHOW_IN_RAID = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedShowInParty()
	if this:GetChecked() then
		BANANA_CONFIG.SHOW_IN_PARTY = 1
	else
		BANANA_CONFIG.SHOW_IN_PARTY = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedShowOutOfGroup()
	if this:GetChecked() then
		BANANA_CONFIG.SHOW_OUT_OF_GROUP = 1
	else
		BANANA_CONFIG.SHOW_OUT_OF_GROUP = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedHideButtonFrames()
	if this:GetChecked() then
		BANANA_CONFIG.HIDE_BUTTON_FRAMES = 1
	else
		BANANA_CONFIG.HIDE_BUTTON_FRAMES = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedDisableSound()
	if this:GetChecked() then
		BANANA_CONFIG.DISABLE_SOUND = 1
	else
		BANANA_CONFIG.DISABLE_SOUND = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedDisableErrorText()
	if this:GetChecked() then
		BANANA_CONFIG.DISABLE_ERROR_TEXT = 1
	else
		BANANA_CONFIG.DISABLE_ERROR_TEXT = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedGreyOutDeath()
	if this:GetChecked() then
		BANANA_CONFIG.GREY_OUT_DEATH = 1
	else
		BANANA_CONFIG.GREY_OUT_DEATH = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedShowExtraInfo()
	if this:GetChecked() then
		BANANA_CONFIG.SHOW_EXTRA_INFO = 1
	else
		BANANA_CONFIG.SHOW_EXTRA_INFO = 0
	end
	Banana_UpdateStatus()
end

function BananaConfig_ValueChangedHideUnused()
	if this:GetChecked() then
		BANANA_CONFIG.HIDE_UNUSED_BUTTONS = 1
	else
		BANANA_CONFIG.HIDE_UNUSED_BUTTONS = 0
	end
	Banana_UpdateStatus()
end

function Banana_Toggle()
	if BananaConfigFrame:IsVisible() then
		BananaConfigFrame:Hide()
	else
		BananaConfigFrame:Show()
	end
end

function Banana_TargetCommand(arg)
	arg = tonumber(arg)
	if arg == nil or arg == "" or arg > 9 or arg < 1 then
		Banana_Error("/bananatarget number (Star is 1, skull is 8")
		return
	end
	Banana_TargetRaidSymbol(arg)
end

function Banana_Default()
	BANANA_CONFIG.SHOW_IN_RAID = 1
	BANANA_CONFIG.SHOW_IN_PARTY = 1
	BANANA_CONFIG.SHOW_OUT_OF_GROUP = 1
	BANANA_CONFIG.HIDE_UNUSED_BUTTONS = 0
	BANANA_CONFIG.BUTTON_LAYOUT = 3
	BANANA_CONFIG.BUTTON_SCALE = 100
	BANANA_CONFIG.HIDE_BUTTON_FRAMES = 1
	BANANA_CONFIG.DISABLE_SOUND = 1
	BANANA_CONFIG.DISABLE_ERROR_TEXT = 1
	BANANA_CONFIG.GREY_OUT_DEATH = 1
	BANANA_CONFIG.SHOW_EXTRA_INFO = 0
	BANANA_CONFIG.FLIP = 0
	BANANA_CONFIG.DETACH = 0
	Banana_UpdateDialogFromVariables()

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
	Banana_ReloadFramePositions()
end

function Banana_CtRaMainTankUpdate()
    Banana_CtRaMainTankUpdateByIndex(1)
    Banana_CtRaMainTankUpdateByIndex(2)
    Banana_CtRaMainTankUpdateByIndex(3)
    Banana_CtRaMainTankUpdateByIndex(4)
    Banana_CtRaMainTankUpdateByIndex(5)
    Banana_CtRaMainTankUpdateByIndex(6)
    Banana_CtRaMainTankUpdateByIndex(7)
    Banana_CtRaMainTankUpdateByIndex(8)
    Banana_CtRaMainTankUpdateByIndex(9)
    Banana_CtRaMainTankUpdateByIndex(10)
end

function Banana_CtRaMainTankUpdateByIndex(mtindex)
    local ctraframe = "CT_RAMTGroupMember"..mtindex.."CastFrame"
    if getglobal(ctraframe) == nil then
        return
    end

    local frameName = "BananaMt"..mtindex
    local texName = "BananaMt"..mtindex.."Symbol"

    local f
	if getglobal(frameName) == nil then
		f = CreateFrame("Frame", frameName, getglobal(ctraframe), "BananaMtSymbolTemplate")
		f:SetFrameStrata("BACKGROUND")
        f:SetPoint("RIGHT", ctraframe, "LEFT", 0, 0)
        f:Hide()
    else
        f = getglobal(frameName)
    end

    local tex = getglobal(texName)

    if CT_RATarget then
        if CT_RATarget.MainTanks then
            if CT_RATarget.MainTanks[mtindex] then
                if CT_RATarget.MainTanks[mtindex][1] then
                    if UnitExists("raid"..CT_RATarget.MainTanks[mtindex][1].."target") then
                        local idx = (Banana_GetSymbol("raid"..CT_RATarget.MainTanks[mtindex][1].."target") or 0)
                        if idx ~= 0 then
                            Banana_TexCoord(tex,idx)
                            f:Show()
                            return
                        end
                    end
                end
            end
        end
    end
    f:Hide()
end

function Banana_ClearAllSymbols()
    Banana_PlayRemoveAll()
	for i = 1, 8 do
    	Banana_SetSymbol("player", i)
	end
	attempts = 10
end

function Banana_SaveFramePos(frame)
	if frame then
		if frame:GetLeft() and frame:GetBottom() then
			local framePos = {}
			framePos.x = frame:GetLeft() * frame:GetScale()
			framePos.y = frame:GetTop() * frame:GetScale() - GetScreenHeight()
			if not BANANA_CONFIG.POS then
				BANANA_CONFIG.POS = {}
			end
			BANANA_CONFIG.POS[frame:GetName()] = framePos
		end
	end
end

function Banana_LoadFramePos(frame)
	if frame then
		if frame:IsMovable() then
			if BANANA_CONFIG.POS then
				local framePos = BANANA_CONFIG.POS[frame:GetName()]
				if framePos then
					frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", framePos.x / frame:GetScale(), framePos.y / frame:GetScale())
				end
			end
		end
	end
end

function Banana_ReloadFramePositions()
	Banana_LoadFramePos(RaidTargetFrame1Button)
	Banana_LoadFramePos(RaidTargetFrame2Button)
	Banana_LoadFramePos(RaidTargetFrame3Button)
	Banana_LoadFramePos(RaidTargetFrame4Button)
	Banana_LoadFramePos(RaidTargetFrame5Button)
	Banana_LoadFramePos(RaidTargetFrame6Button)
	Banana_LoadFramePos(RaidTargetFrame7Button)
	Banana_LoadFramePos(RaidTargetFrame8Button)
	Banana_LoadFramePos(RaidTargetFrame9Button)
end

local movingConfig = false
function Banana_HeaderMouseDown()
	if not movingConfig then
		movingConfig = true
		BananaConfigFrame:StartMoving()
	end
end

function Banana_HeaderMouseUp()
	if movingConfig then
		movingConfig = false
		BananaConfigFrame:StopMovingOrSizing()
	end
end

function Banana_UpdateDialogFromVariables()
    UIDropDownMenu_SetSelectedID(BananaConfigFrameComboBoxLayout, BANANA_CONFIG.BUTTON_LAYOUT)
    BananaConfigFrameCheckButtonShowInRaid:SetChecked(BANANA_CONFIG.SHOW_IN_RAID == 1)
    BananaConfigFrameCheckButtonShowInParty:SetChecked(BANANA_CONFIG.SHOW_IN_PARTY == 1)
    BananaConfigFrameCheckButtonShowOutOfGroup:SetChecked(BANANA_CONFIG.SHOW_OUT_OF_GROUP == 1)
    BananaConfigFrameCheckButtonHideUnused:SetChecked(BANANA_CONFIG.HIDE_UNUSED_BUTTONS == 1)
	BananaConfigFrameCheckButtonHideButtonFrames:SetChecked(BANANA_CONFIG.HIDE_BUTTON_FRAMES == 1)
	BananaConfigFrameCheckButtonDisableSound:SetChecked(BANANA_CONFIG.DISABLE_SOUND == 1)
	BananaConfigFrameCheckButtonDisableErrorText:SetChecked(BANANA_CONFIG.DISABLE_ERROR_TEXT == 1)
	BananaConfigFrameCheckButtonGreyOutDeath:SetChecked(BANANA_CONFIG.GREY_OUT_DEATH == 1)
    BananaConfigFrameCheckButtonShowExtraInfo:SetChecked(BANANA_CONFIG.SHOW_EXTRA_INFO == 1)
	BananaConfigFrameResizeSlider:SetValue(BANANA_CONFIG.BUTTON_SCALE)
end

function Banana_PlayError()
	if BANANA_CONFIG.DISABLE_SOUND ~= 1 then
    	PlaySoundFile("Interface\\AddOns\\Bananabar\\Sound\\BananaNo.mp3")
	end
end
function Banana_PlayRemove1()
	if BANANA_CONFIG.DISABLE_SOUND ~= 1 then
    	PlaySoundFile("Interface\\AddOns\\Bananabar\\Sound\\BananaPlop1.mp3")
	end
end

function Banana_PlayRemoveAll()
	if BANANA_CONFIG.DISABLE_SOUND ~= 1 then
    	PlaySoundFile("Interface\\AddOns\\Bananabar\\Sound\\BananaPlop8.mp3")
	end
end

function Banana_PlaySetSymbol()
	if BANANA_CONFIG.DISABLE_SOUND ~= 1 then
    	PlaySoundFile("Interface\\AddOns\\Bananabar\\Sound\\BananaSetSymbol.mp3")
	end
end

function Banana_GetSymbol(unit)
    local result = GetRaidTargetIndex(unit)
    if (not result) or (result == 0) then
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
		if superwow and not InGroupOrRaid() then
			SetRaidTarget(unit, index, 1)
		else
			SetRaidTarget(unit, index)
		end
		if index ~= 0 then
			Banana_PlaySetSymbol()
		end
	elseif index == 9 then
		local spell = nil
		local searchid = 1
		local tex
		repeat
			tex = GetSpellTexture(searchid, BOOKTYPE_SPELL)
			if tex == huntersMark then
				spell, _ = GetSpellName(searchid, BOOKTYPE_SPELL)
			end
			searchid = searchid + 1
		until spell ~= nil or tex == nil

		if spell == nil then
			Banana_Error("Huntersmark Spell not found")
			Banana_PlayError()
			return
		end
		CastSpellByName(spell)
		Banana_PlaySetSymbol()
	end
end

function Banana_IsNameplate(frame)
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

function Banana_ScanNameplates(index)
	if index == 9 then return nil end
	local button = raidTargetIconTexCoords[index]
	if not button then return nil end

	local bULx = button.ULx
	local bULy = button.ULy
	local frames = { WorldFrame:GetChildren() }

	for _, nameplate in ipairs(frames) do
    	if Banana_IsNameplate(nameplate) then
			if shaguPlates then
				local baseplate, shaguplate = nameplate:GetChildren()
				if shaguplate.raidicon:IsShown() then
					local ULx,ULy = shaguplate.raidicon:GetTexCoord()
					if ULx == bULx and ULy == bULy then
						nameplate:Click()
						Banana_UpdateStatus()
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
							Banana_UpdateStatus()
							return true
						end
					end
				end
			end
		end
	end

	return nil
end

function Banana_Layout()
	if BANANA_CONFIG.BUTTON_LAYOUT ~= 5 then
		BananaConfigFrameFlip:Enable()
		BananaConfigFrameDetach:Enable()
		BananaConfigFrameFlipText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		BananaConfigFrameDetachText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	else
		BananaConfigFrameFlip:Disable()
		BananaConfigFrameDetach:Disable()
		BananaConfigFrameFlipText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
		BananaConfigFrameDetachText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
	end
	if BANANA_CONFIG.BUTTON_LAYOUT == 1 then
		Banana_Layout1()
		return
	end
	if BANANA_CONFIG.BUTTON_LAYOUT == 2 then
		Banana_Layout2()
		return
	end
	if BANANA_CONFIG.BUTTON_LAYOUT == 3 then
		Banana_Layout3()
		return
	end
	if BANANA_CONFIG.BUTTON_LAYOUT == 4 then
		Banana_Layout4()
		return
	end
	Banana_Layout5()
end

function Banana_Layout1()
	local left, right = "LEFT", "RIGHT"
	local padding = 4
	if BANANA_CONFIG.FLIP == 1 then
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

	icons[1].MovingButton = 1
	icons[2].MovingButton = 1
	icons[3].MovingButton = 1
	icons[4].MovingButton = 1
	icons[5].MovingButton = 1
	icons[6].MovingButton = 1
	icons[7].MovingButton = 1
	icons[8].MovingButton = 1
	icons[9].MovingButton = 9

	if BANANA_CONFIG.DETACH ~= 1 then
		RaidTargetFrame9Button:SetMovable(false)
		RaidTargetFrame9Button:SetPoint(right, RaidTargetFrame1Button, left, -padding, 0)
		icons[9].MovingButton = 1
	end
end

function Banana_Layout2()
	local left, right = "LEFT", "RIGHT"
	local top, bottom = "TOP", "BOTTOM"
	local padding = 4
	if BANANA_CONFIG.FLIP == 1 then
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

	icons[1].MovingButton = 1
	icons[2].MovingButton = 1
	icons[3].MovingButton = 1
	icons[4].MovingButton = 1
	icons[5].MovingButton = 1
	icons[6].MovingButton = 1
	icons[7].MovingButton = 1
	icons[8].MovingButton = 1
	icons[9].MovingButton = 9

	if BANANA_CONFIG.DETACH ~= 1 then
		RaidTargetFrame9Button:SetMovable(false)
		RaidTargetFrame9Button:SetPoint(right, RaidTargetFrame1Button, left, -padding, 0)
		icons[9].MovingButton = 1
	end
end

function Banana_Layout3()
	local left, right = "LEFT", "RIGHT"
	local top, bottom = "TOP", "BOTTOM"
	local padding = 4
	if BANANA_CONFIG.FLIP == 1 then
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

	icons[1].MovingButton = 1
	icons[2].MovingButton = 1
	icons[3].MovingButton = 1
	icons[4].MovingButton = 1
	icons[5].MovingButton = 1
	icons[6].MovingButton = 1
	icons[7].MovingButton = 1
	icons[8].MovingButton = 1
	icons[9].MovingButton = 9

	if BANANA_CONFIG.DETACH ~= 1 then
		RaidTargetFrame9Button:SetMovable(false)
		RaidTargetFrame9Button:SetPoint(bottom, RaidTargetFrame1Button, top, 0, padding)
		icons[9].MovingButton = 1
	end
end

function Banana_Layout4()
	local top, bottom = "TOP", "BOTTOM"
	local padding = -4
	if BANANA_CONFIG.FLIP == 1 then
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

	icons[1].MovingButton = 1
	icons[2].MovingButton = 1
	icons[3].MovingButton = 1
	icons[4].MovingButton = 1
	icons[5].MovingButton = 1
	icons[6].MovingButton = 1
	icons[7].MovingButton = 1
	icons[8].MovingButton = 1
	icons[9].MovingButton = 9

	if BANANA_CONFIG.DETACH ~= 1 then
		RaidTargetFrame9Button:SetMovable(false)
		RaidTargetFrame9Button:SetPoint(bottom, RaidTargetFrame1Button, top, 0, -padding)
		icons[9].MovingButton = 1
	end
end

function Banana_Layout5()
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

	icons[1].MovingButton = 1
	icons[2].MovingButton = 2
	icons[3].MovingButton = 3
	icons[4].MovingButton = 4
	icons[5].MovingButton = 5
	icons[6].MovingButton = 6
	icons[7].MovingButton = 7
	icons[8].MovingButton = 8
	icons[9].MovingButton = 9

	Banana_ReloadFramePositions()
end

function BananaConfig_FlipToggle()
	if BANANA_CONFIG.FLIP ~= 1 then
		BANANA_CONFIG.FLIP = 1
	else
		BANANA_CONFIG.FLIP = 0
	end
	Banana_Layout()
end

function BananaConfig_DetachToggle()
	if BANANA_CONFIG.DETACH ~= 1 then
		BANANA_CONFIG.DETACH = 1
	else
		BANANA_CONFIG.DETACH = 0
	end
	Banana_Layout()
end