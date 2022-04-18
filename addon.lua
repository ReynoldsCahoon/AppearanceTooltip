local db = {}

local tooltip = CreateFrame("Frame", "AppearanceTooltipTooltip", UIParent)
tooltip:SetClampedToScreen(true)
tooltip:SetFrameStrata("TOOLTIP")
tooltip:SetSize(300, 300)
tooltip:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
tooltip:SetBackdropColor(0.1, 0.1, .2, .99)
tooltip:Hide()

tooltip:SetScript("OnEvent", function(self, event, ...)
	if(event == "ADDON_LOADED")then
		ADDON_LOADED(self, event, ...)
	elseif (event == "PLAYER_LOGIN") then
		tooltip.model:SetUnit("player")
	end
end)
tooltip:RegisterEvent("ADDON_LOADED")
tooltip:RegisterEvent("PLAYER_LOGIN")


function ADDON_LOADED(addon, event, arg1)
    if arg1 ~= "AppearanceTooltip" then return end

    _G[arg1.."DB"] = setDefaults( {}, {
        modifier = false, -- or "Alt", "Ctrl", "Shift"
        rotate = true,
        spin = false,
        dressed = false, -- whether the model should be wearing your current outfit, or be naked
    })
    db = _G[arg1.."DB"]
	
    tooltip:UnregisterEvent("ADDON_LOADED")
end

tooltip.model = CreateFrame("DressUpModel", nil, tooltip)
tooltip.model:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 5, -5)
tooltip.model:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -5, 5)

tooltip.model:SetScript("OnShow", function(self)
    ResetModel(self)
end)

GameTooltip:HookScript("OnTooltipSetItem", function(self)
    ShowItem(select(2, self:GetItem()))
end)
GameTooltip:HookScript("OnHide", function()
    HideItem()
end)

----

local hider = CreateFrame("Frame")
hider:Hide()
hider:SetScript("OnUpdate", function(self)
    if (tooltip.owner and not (tooltip.owner:IsShown() and tooltip.owner:GetItem())) or not tooltip.owner then
        tooltip:Hide()
        tooltip.item = nil
    end
    self:Hide()
end)

local positioner = CreateFrame("Frame")
positioner:Hide()
positioner:SetScript("OnUpdate", function(self)
    local x, y = tooltip.owner:GetCenter()
    if x and y then
        tooltip:ClearAllPoints()
        local our_point, owner_point
        if y / GetScreenHeight() > 0.5 then
            our_point = "TOP"
            owner_point = "BOTTOM"
        else
            our_point = "BOTTOM"
            owner_point = "TOP"
        end
        if x / GetScreenWidth() > 0.5 and not ShoppingTooltip1:IsVisible() then
            our_point = our_point.."LEFT"
            owner_point = owner_point.."LEFT"
        else
            our_point = our_point.."RIGHT"
            owner_point = owner_point.."RIGHT"
        end
        tooltip:SetPoint(our_point, tooltip.owner, owner_point)
        self:Hide()
    end
end)

local spinner = CreateFrame("Frame", nil, tooltip);
spinner:Hide()
spinner:SetScript("OnUpdate", function(self, elapsed)
    tooltip.model:SetFacing(tooltip.model:GetFacing() + elapsed)
end)

----

function ShowItem(link)
    if not link then return end
    local id = tonumber(link:match("item:(%d+)"))
    if not id or id == 0 then return end

    local slot = select(9, GetItemInfo(id))
    if (not db.modifier or modifiers[db.modifier]()) and tooltip.item ~= id then
        tooltip.item = id

        if slot_facings[slot] and IsDressableItem(id) then
            tooltip.model:SetFacing(slot_facings[slot] - (db.rotate and 0.5 or 0))
			
            tooltip:Show()
            tooltip.owner = GameTooltip

            positioner:Show()
            if db.spin then
                spinner:Show()
            else
                spinner:Hide()
            end

            ResetModel(tooltip.model)
            tooltip.model:TryOn(link)
        else
            tooltip:Hide()
        end
    end
end

function HideItem()
    hider:Show()
end

function ResetModel(model)
    model:Dress()
    if not db.dressed then
        model:Undress()
    end
end

slot_facings = {
    INVTYPE_HEAD = 0,
    INVTYPE_SHOULDER = 0,
    INVTYPE_CLOAK = 3.4,
    INVTYPE_CHEST = 0,
    INVTYPE_ROBE = 0,
    INVTYPE_WRIST = 0,
    INVTYPE_2HWEAPON = 1.6,
    INVTYPE_WEAPON = 1.6,
    INVTYPE_WEAPONMAINHAND = 1.6,
    INVTYPE_WEAPONOFFHAND = -0.7,
    INVTYPE_SHIELD = -0.7,
    INVTYPE_HOLDABLE = -0.7,
    INVTYPE_RANGED = 1.6,
    INVTYPE_RANGEDRIGHT = 1.6,
    INVTYPE_THROWN = 1.6,
    INVTYPE_HAND = 0,
    INVTYPE_WAIST = 0,
    INVTYPE_LEGS = 0,
    INVTYPE_FEET = 0,
}

-- /script AppearanceTooltipTooltip.model:SetPosition(0,0,0)
-- x,y,z is effectively zoom, horizontal, vertical
slot_positions = {
    INVTYPE_2HWEAPON = {0.8, -0.3, 0},
    INVTYPE_WEAPON = {0.8, -0.3, 0},
    INVTYPE_WEAPONMAINHAND = {0.8, -0.3, 0},
    INVTYPE_WEAPONOFFHAND = {0.8, 0.3, 0},
    INVTYPE_SHIELD = {0.8, 0, 0},
    INVTYPE_HOLDABLE = {0.8, 0.3, 0},
    INVTYPE_RANGED = {0.8, -0.3, 0},
    INVTYPE_RANGEDRIGHT = {0.8, 0.3, 0},
    INVTYPE_THROWN = {0.8, -0.3, 0},
    [DEFAULT] = {0, 0, 0},
}

modifiers = {
    Shift = IsShiftKeyDown,
    Ctrl = IsControlKeyDown,
    Alt = IsAltKeyDown,
}

function setDefaults(options, defaults)
    setmetatable(options, { __index = function(t, k)
        if type(defaults[k]) == "table" then
            t[k] = setDefaults({}, defaults[k])
            return t[k]
        end
        return defaults[k]
    end, })
    return options
end
