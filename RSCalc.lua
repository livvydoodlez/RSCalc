-- Set GoalXP_DB to itself and check its value
GoalXP_DB = GoalXP_DB


-- Define colors using hex values
local brownHex = "4a402b"  -- Dark brown color
local lightBrownHex = "a18a5c"  -- Light brown color
local menuBackgroundHex = "5e4e39" -- Solid background color for dropdown menu
local frameBackgroundHex = "332c1e" -- Solid background color for the main UI

-- Function to convert hex color to RGB
function HexToRGB(hex)
    local r = tonumber("0x" .. hex:sub(1, 2)) / 255
    local g = tonumber("0x" .. hex:sub(3, 4)) / 255
    local b = tonumber("0x" .. hex:sub(5, 6)) / 255
    return r, g, b
end

-- Register the /rscalc command
SLASH_RSCALC1 = "/rscalc"
SlashCmdList["RSCALC"] = function()
    if not RSCalcUI then
        CreateRSCalcUI()
    end
    RSCalcUI:Show()
end


local FactionData = {
    ["Agility"] = 1185,
    ["Cooking"] = 1179,
    ["Construction"] = 1186,
    ["Crafting"] = 1180,
    ["Dungeoneering"] = 1190,
    ["Fishing"] = 1175,
    ["Firemaking"] = 1187,
    ["Fletching"] = 1181,
    ["Herblore"] = 1182,
    ["Hunting"] = 1176,
    ["Magic"] = 1169,
    ["Mining"] = 1177,
    ["Prayer"] = 1170,
    ["Runecrafting"] = 1183,
    ["Slayer"] = 1188,
    ["Smithing"] = 1184,
    ["Thieving"] = 1189,
    ["Woodcutting"] = 1178,
    ["Farming"] = 1173,
}

local CURRENTXP = 0
local CURRENTLEVEL = 0
GOALXP = 0

local function GetSkillXP(skillID)
    local name, desc, standingID, barMin, barMax, barValue, _, _, _, isHeader, _, _, _, factionID = GetFactionInfoByID(skillID)
    return (barValue - barMax)  -- Adjusted to reflect the actual skill progress
end

local function UpdateSkillLevel(skillID)
    CURRENTXP = GetSkillXP(skillID)

    -- Find the current level by comparing CURRENTXP with GoalXP_DB
    CURRENTLEVEL = 1  -- Start at level 1
    for level, xp in ipairs(GoalXP_DB.goalXPperLevel) do
        if CURRENTXP < xp then
            CURRENTLEVEL = level - 1  -- We haven't reached this level yet
            break
        end
    end

    -- Ensure CURRENTLEVEL doesn't exceed maximum (usually 99 for many games)
    if CURRENTLEVEL > 99 then
        CURRENTLEVEL = 99
    end

    -- Debug output to check the current level
    print("Current Level set to:", CURRENTLEVEL)  -- Debug output
end




-- Function to create the UI frame
function CreateRSCalcUI()
    -- Create the main frame
    local frame = CreateFrame("Frame", "RSCalcUI", UIParent, "BasicFrameTemplate")
    frame:SetSize(300, 200)  -- Width and height of the frame
    frame:SetPoint("CENTER")  -- Center the frame on the screen
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Add a title to the frame
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
    title:SetText("RS XP Calculator")

    -- Add a solid background color to the frame
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints(true)
    frame.bg:SetColorTexture(HexToRGB(frameBackgroundHex))  -- Solid background color

    -- Create a custom dropdown button
    local dropdownButton = CreateFrame("Button", "CustomSkillDropdownButton", frame)
    dropdownButton:SetSize(300, 30)  -- Width and height of the button
    dropdownButton:SetPoint("TOP", frame, "TOP", 0, -30)  -- Position the button

    -- Set the background texture for the dropdown button
    dropdownButton.bg = dropdownButton:CreateTexture(nil, "BACKGROUND")
    dropdownButton.bg:SetAllPoints(dropdownButton)
    dropdownButton.bg:SetColorTexture(HexToRGB(brownHex))  -- Brown background

    -- Set the border texture for the dropdown button
    dropdownButton.border = dropdownButton:CreateTexture(nil, "BORDER")
    dropdownButton.border:SetAllPoints(dropdownButton)
    dropdownButton.border:SetColorTexture(HexToRGB(lightBrownHex))  -- Light brown border

    -- Create the arrow texture
    local arrowTexture = dropdownButton:CreateTexture(nil, "ARTWORK")
    arrowTexture:SetSize(12, 12)  -- Size of the arrow
    arrowTexture:SetPoint("RIGHT", dropdownButton, "RIGHT", -5, 0)  -- Position to the right
    arrowTexture:SetTexture("Interface\\Buttons\\UI-ScrollBar-DownButton-Up")  -- Arrow texture
    arrowTexture:SetTexCoord(0.25, 0.75, 0.25, 0.75)  -- Crop the arrow texture

    -- Set the button text
    dropdownButton.text = dropdownButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownButton.text:SetPoint("CENTER", dropdownButton, "CENTER", 0, 0)  -- Center the text
    dropdownButton.text:SetText("SELECT SKILL V")

    -- Create a frame for the dropdown options
    local dropdownMenu = CreateFrame("Frame", "CustomSkillDropdownMenu", frame)
    dropdownMenu:SetSize(100, 400)  -- Width and height of the dropdown
    dropdownMenu:SetPoint("TOP", dropdownButton, "BOTTOM", 95, 0)  -- Position it below the button
    dropdownMenu:SetFrameStrata("DIALOG")  -- Ensure it appears above the main frame

    -- Set a solid background color for the dropdown menu
    dropdownMenu.bg = dropdownMenu:CreateTexture(nil, "BACKGROUND")
    dropdownMenu.bg:SetAllPoints(dropdownMenu)
    dropdownMenu.bg:SetColorTexture(HexToRGB(menuBackgroundHex))  -- Solid background color

    dropdownMenu:Hide()  -- Initially hidden

    -- Create a list of skills for the dropdown
    local skills = {}
    for skill in pairs(FactionData) do
        table.insert(skills, skill)
    end
    
    table.sort(skills)
    
    local selectedSkill = skills[1]  -- Default selected skill

    -- Create a table-like layout for skill information
    local skillInfoRow1 = CreateFrame("Frame", nil, frame)
    skillInfoRow1:SetSize(280, 20)  -- Width of the row
    skillInfoRow1:SetPoint("TOP", dropdownButton, "BOTTOM", 0, -10)  -- Position it below the dropdown button

    local skillLevelText = skillInfoRow1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    skillLevelText:SetPoint("LEFT", skillInfoRow1, "LEFT", 0, 0)  -- Align the skill level text to the left
    skillLevelText:SetText(selectedSkill .. " Level: 1")  -- Placeholder for level

    local spacer1 = skillInfoRow1:CreateTexture(nil, "OVERLAY")
    spacer1:SetSize(50, 20)  -- Width of the spacer
    spacer1:SetPoint("LEFT", skillLevelText, "RIGHT", 10, 0)  -- Position it to the right of the level text

    local goalLabel = skillInfoRow1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goalLabel:SetPoint("LEFT", spacer1, "RIGHT", 0, 0)
    goalLabel:SetText("Goal: ")

     -- Create an input box for the desired goal
    local goalInputBox = CreateFrame("EditBox", "GoalInputBox", skillInfoRow1, "InputBoxTemplate")
    goalInputBox:SetSize(30, 20)  -- Width and height of the input box (space for 2 digits)
    goalInputBox:SetPoint("LEFT", goalLabel, "RIGHT", 10, 0)  -- Position next to the label
    goalInputBox:SetAutoFocus(false)  -- Do not auto-focus when created
    goalInputBox:SetText("")  -- No placeholder text
    goalInputBox:SetTextColor(1, 1, 1)  -- White text color
    goalInputBox:SetBackdropColor(0, 0, 0, 1)  -- Solid black background for the input box
    goalInputBox:SetBackdropBorderColor(1, 1, 1, 1)  -- White border color

    -- Create another row for experience
    local skillInfoRow2 = CreateFrame("Frame", nil, frame)
    skillInfoRow2:SetSize(280, 20)  -- Width of the row
    skillInfoRow2:SetPoint("TOP", skillInfoRow1, "BOTTOM", 0, 0)  -- Position it below the first row
    
    -- Create another row for experience
    local skillInfoRow3 = CreateFrame("Frame", nil, frame)
    skillInfoRow3:SetSize(280, 20)  -- Width of the row
    skillInfoRow3:SetPoint("TOP", skillInfoRow2, "BOTTOM", 0, 0)  -- Position it below the first row
    
    -- Create another row for experience
    local skillInfoRow4 = CreateFrame("Frame", nil, frame)
    skillInfoRow4:SetSize(280, 20)  -- Width of the row
    skillInfoRow4:SetPoint("TOP", skillInfoRow3, "BOTTOM", 0, 0)  -- Position it below the first row
    

    local experienceText = skillInfoRow2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    experienceText:SetPoint("LEFT", skillInfoRow2, "LEFT", 0, 0)  -- Align the experience text to the left
    experienceText:SetText(selectedSkill .. " XP: 0")  -- Placeholder for experience
    
    local goalExp = skillInfoRow2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goalExp:SetPoint("LEFT", skillInfoRow4, "LEFT", 0, 0)  -- Align the experience text to the left
    goalExp:SetText("Goal XP: 0")  -- Placeholder for experience
    
    
    
        -- Define the info box
    local infoBox = CreateFrame("Frame", "InfoBox", UIParent)
    infoBox:SetSize(150, 200)  -- Width and height of the info box
    infoBox:SetPoint("LEFT", frame, "RIGHT", 10, 0)  -- Position it to the right of the main frame
    infoBox:Hide()  -- Initially hidden

    -- Set a solid background color for the info box
    infoBox.bg = infoBox:CreateTexture(nil, "BACKGROUND")
    infoBox.bg:SetAllPoints(true)
    infoBox.bg:SetColorTexture(HexToRGB(menuBackgroundHex))  -- Set background color to menuBackgroundHex

    -- Add a rounded border to the info box
    local borderTexture = infoBox:CreateTexture(nil, "BORDER")
    borderTexture:SetTexture(0, 0, 0, 0.7)  -- Black color with some transparency
    borderTexture:SetPoint("TOPLEFT", infoBox, -2, 2)
    borderTexture:SetPoint("BOTTOMRIGHT", infoBox, 2, -2)

    -- Add a title for the info box
    local infoBoxTitle = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoBoxTitle:SetPoint("TOP", infoBox, "TOP", 0, -5)  -- Position at the top of the box
    infoBoxTitle:SetText("Additional Info")  -- Title text
    infoBoxTitle:SetTextColor(1, 0.8, 0.2)  -- Gold color for title

    -- Create a scrollbar for the info box content (optional)
    local scrollFrame = CreateFrame("ScrollFrame", nil, infoBox, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(140, 160)  -- Set the size of the scrollable area
    scrollFrame:SetPoint("TOPLEFT", infoBox, "TOPLEFT", 5, -30)  -- Position it inside the info box

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(140, 200)  -- Make sure the content is larger than the scroll frame

    -- Add the content string to the content frame
    local contentText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    contentText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)  -- Align to top left
    contentText:SetText("SCROLL ITEMS.")  -- Placeholder text
    contentText:SetJustifyH("LEFT")  -- Align text to the left

    -- Add the content frame to the scroll frame
    scrollFrame:SetScrollChild(content)

    -- Create the Extend Info button
    local extendInfoButton = CreateFrame("Button", "ExtendInfoButton", frame, "UIPanelButtonTemplate")
    extendInfoButton:SetSize(100, 30)  -- Width and height of the button
    extendInfoButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)  -- Position it at the bottom center
    extendInfoButton:SetText("Extend Info")  -- Initial button text
  

local Prayer = {
    Bones = {
        { Name = "Bones", ItemID = 4359, Experience = 4.5, Tab = 1 },
        { Name = "Wolf bones", ItemID = 4359, Experience = 4.5, Tab = 1 },
        { Name = "Burnt bones", ItemID = 4359, Experience = 4.5, Tab = 1 },
        { Name = "Monkey bones", ItemID = 4359, Experience = 5, Tab = 1 },
        { Name = "Bat bones", ItemID = 4359, Experience = 5.3, Tab = 1 },
        { Name = "Jogre bones", ItemID = 4359, Experience = 15, Tab = 1 },
        { Name = "Big bones", ItemID = 4359, Experience = 15, Tab = 1 },
        { Name = "Zogre bones", ItemID = 4359, Experience = 22.5, Tab = 1 },
        { Name = "Shaikahan bones", ItemID = 4359, Experience = 25, Tab = 1 },
        { Name = "Babydragon bones", ItemID = 4359, Experience = 30, Tab = 1 },
        { Name = "Ourg bones", ItemID = 4359, Experience = 140, Tab = 1 },
        { Name = "Wyvern bones", ItemID = 4359, Experience = 72, Tab = 1 },
        { Name = "Dragon bones", ItemID = 4359, Experience = 72, Tab = 1 },
        { Name = "Fayrg bones", ItemID = 4359, Experience = 84, Tab = 1 },
        { Name = "Lava dragon bones", ItemID = 4359, Experience = 85, Tab = 1 },
        { Name = "Raurg bones", ItemID = 4359, Experience = 96, Tab = 1 },
        { Name = "Dagannoth bones", ItemID = 4359, Experience = 125, Tab = 1 },
        { Name = "Wyrm bones", ItemID = 4359, Experience = 50, Tab = 1 },
        { Name = "Drake bones", ItemID = 4359, Experience = 80, Tab = 1 },
        { Name = "Hydra bones", ItemID = 4359, Experience = 110, Tab = 1 },
        { Name = "Wyrmling bones", ItemID = 4359, Experience = 21, Tab = 1 },
        { Name = "Superior dragon bones", ItemID = 4359, Experience = 150, Tab = 1 }
    },
    Ensouled = {  -- Corrected key name
        { Name = "Ensouled goblin head", ItemID = 4359, Experience = 130, Tab = 2 },
        { Name = "Ensouled monkey head", ItemID = 4359, Experience = 182, Tab = 2 },
        { Name = "Ensouled imp head", ItemID = 4359, Experience = 286, Tab = 2 },
        { Name = "Ensouled minotaur head", ItemID = 4359, Experience = 364, Tab = 2 },
        { Name = "Ensouled scorpion head", ItemID = 4359, Experience = 454, Tab = 2 },
        { Name = "Ensouled bear head", ItemID = 4359, Experience = 480, Tab = 2 },
        { Name = "Ensouled unicorn head", ItemID = 4359, Experience = 494, Tab = 2 },
        { Name = "Ensouled dog head", ItemID = 4359, Experience = 520, Tab = 2 },
        { Name = "Ensouled chaos druid head", ItemID = 4359, Experience = 584, Tab = 2 },
        { Name = "Ensouled giant head", ItemID = 4359, Experience = 650, Tab = 2 },
        { Name = "Ensouled ogre head", ItemID = 4359, Experience = 716, Tab = 2 },
        { Name = "Ensouled elf head", ItemID = 4359, Experience = 754, Tab = 2 },
        { Name = "Ensouled troll head", ItemID = 4359, Experience = 780, Tab = 2 },
        { Name = "Ensouled horror head", ItemID = 4359, Experience = 832, Tab = 2 },
        { Name = "Ensouled kalphite head", ItemID = 4359, Experience = 884, Tab = 2 },
        { Name = "Ensouled dagannoth head", ItemID = 4359, Experience = 936, Tab = 2 },
        { Name = "Ensouled bloodveld head", ItemID = 4359, Experience = 1040, Tab = 2 },
        { Name = "Ensouled tzhaar head", ItemID = 4359, Experience = 1104, Tab = 2 },
        { Name = "Ensouled demon head", ItemID = 4359, Experience = 1170, Tab = 2 },
        { Name = "Ensouled aviansie head", ItemID = 4359, Experience = 1234, Tab = 2 },
        { Name = "Ensouled abyssal head", ItemID = 4359, Experience = 1300, Tab = 2 },
        { Name = "Ensouled dragon head", ItemID = 4359, Experience = 1560, Tab = 2 },
        { Name = "Ensouled hellhound head", ItemID = 4359, Experience = 1200, Tab = 2 }
    },
    Offerings = {  -- Corrected key name
        { Name = "Fiendish ashes", ItemID = 4359, Experience = 10, Tab = 3 },
        { Name = "Vile ashes", ItemID = 4359, Experience = 25, Tab = 3 },
        { Name = "Malicious ashes", ItemID = 4359, Experience = 65, Tab = 3 },
        { Name = "Abyssal ashes", ItemID = 4359, Experience = 85, Tab = 3 },
        { Name = "Infernal ashes", ItemID = 4359, Experience = 110, Tab = 3 }
    },
    Pyre = {  -- Corrected key name
        { Name = "Loar remains", ItemID = 4359, Experience = 33, Tab = 4 },
        { Name = "Phrin remains", ItemID = 4359, Experience = 46.5, Tab = 4 },
        { Name = "Riyl remains", ItemID = 4359, Experience = 59.5, Tab = 4 },
        { Name = "Asyn remains", ItemID = 4359, Experience = 82.5, Tab = 4 },
        { Name = "Fiyr remains", ItemID = 4359, Experience = 84, Tab = 4 },
        { Name = "Urium remains", ItemID = 4359, Experience = 120.5, Tab = 4 }
    },
    Teomat = {  -- Corrected key name
        { Name = "Blessed bone shards", ItemID = 4359, Experience = 5, Tab = 5 },
        { Name = "Blessed bone shards (sunfire wine)", ItemID = 4359, Experience = 6, Tab = 5 }
    }
}  

    
local Fishing = {
    Fish = {
        { Name = "Raw shrimps", ItemID = 4359, Experience = 10, Tab = 1 },
        { Name = "Raw sardine", ItemID = 4359, Experience = 20, Tab = 1 },
        { Name = "Raw herring", ItemID = 4359, Experience = 30, Tab = 1 },
        { Name = "Raw anchovies", ItemID = 4359, Experience = 40, Tab = 1 },
        { Name = "Raw mackerel", ItemID = 4359, Experience = 20, Tab = 1 },
        { Name = "Raw trout", ItemID = 4359, Experience = 50, Tab = 1 },
        { Name = "Raw cod", ItemID = 4359, Experience = 45, Tab = 1 },
        { Name = "Raw pike", ItemID = 4359, Experience = 60, Tab = 1 },
        { Name = "Raw slimy eel", ItemID = 4359, Experience = 65, Tab = 1 },
        { Name = "Raw salmon", ItemID = 4359, Experience = 70, Tab = 1 },
        { Name = "Raw tuna", ItemID = 4359, Experience = 80, Tab = 1 },
        { Name = "Raw rainbow fish", ItemID = 4359, Experience = 80, Tab = 1 },
        { Name = "Raw cave eel", ItemID = 4359, Experience = 80, Tab = 1 },
        { Name = "Raw lobster", ItemID = 4359, Experience = 90, Tab = 1 },
        { Name = "Raw bass", ItemID = 4359, Experience = 100, Tab = 1 },
        { Name = "Leaping trout", ItemID = 4359, Experience = 50, Tab = 1 },
        { Name = "Raw swordfish", ItemID = 4359, Experience = 100, Tab = 1 },
        { Name = "Raw lava eel", ItemID = 4359, Experience = 60, Tab = 1 },
        { Name = "Leaping salmon", ItemID = 4359, Experience = 70, Tab = 1 },
        { Name = "Raw monkfish", ItemID = 4359, Experience = 120, Tab = 1 },
        { Name = "Raw karambwan", ItemID = 4359, Experience = 50, Tab = 1 },
        { Name = "Leaping sturgeon", ItemID = 4359, Experience = 80, Tab = 1 },
        { Name = "Raw shark", ItemID = 4359, Experience = 110, Tab = 1 },
        { Name = "Raw sea turtle", ItemID = 4359, Experience = 38, Tab = 1 },
        { Name = "Infernal eel", ItemID = 4359, Experience = 95, Tab = 1 },
        { Name = "Raw manta ray", ItemID = 4359, Experience = 46, Tab = 1 },
        { Name = "Raw anglerfish", ItemID = 4359, Experience = 120, Tab = 1 },
        { Name = "Minnow", ItemID = 4359, Experience = 26.1, Tab = 1 },
        { Name = "Raw dark crab", ItemID = 4359, Experience = 130, Tab = 1 },
        { Name = "Sacred eel", ItemID = 4359, Experience = 105, Tab = 1 }
    },
    ["Ang.Bonus"] = {  -- Corrected key name
        { Name = "Raw shrimps", ItemID = 4359, Experience = 10.25, Tab = 2 },
        { Name = "Raw sardine", ItemID = 4359, Experience = 20.5, Tab = 2 },
        { Name = "Raw herring", ItemID = 4359, Experience = 30.75, Tab = 2 },
        { Name = "Raw anchovies", ItemID = 4359, Experience = 41, Tab = 2 },
        { Name = "Raw mackerel", ItemID = 4359, Experience = 20.5, Tab = 2 },
        { Name = "Raw trout", ItemID = 4359, Experience = 51.25, Tab = 2 },
        { Name = "Raw cod", ItemID = 4359, Experience = 46.12, Tab = 2 },
        { Name = "Raw pike", ItemID = 4359, Experience = 61.5, Tab = 2 },
        { Name = "Raw slimy eel", ItemID = 4359, Experience = 66.63, Tab = 2 },
        { Name = "Raw salmon", ItemID = 4359, Experience = 71.75, Tab = 2 },
        { Name = "Raw tuna", ItemID = 4359, Experience = 82, Tab = 2 },
        { Name = "Raw rainbow fish", ItemID = 4359, Experience = 82, Tab = 2 },
        { Name = "Raw cave eel", ItemID = 4359, Experience = 82, Tab = 2 },
        { Name = "Raw lobster", ItemID = 4359, Experience = 92.25, Tab = 2 },
        { Name = "Raw bass", ItemID = 4359, Experience = 102.5, Tab = 2 },
        { Name = "Leaping trout", ItemID = 4359, Experience = 51.25, Tab = 2 },
        { Name = "Raw swordfish", ItemID = 4359, Experience = 102.5, Tab = 2 },
        { Name = "Raw lava eel", ItemID = 4359, Experience = 61.5, Tab = 2 },
        { Name = "Leaping salmon", ItemID = 4359, Experience = 71.75, Tab = 2 },
        { Name = "Raw monkfish", ItemID = 4359, Experience = 123, Tab = 2 },
        { Name = "Raw karambwan", ItemID = 4359, Experience = 51.25, Tab = 2 },
        { Name = "Leaping sturgeon", ItemID = 4359, Experience = 82, Tab = 2 },
        { Name = "Raw shark", ItemID = 4359, Experience = 112.75, Tab = 2 },
        { Name = "Raw sea turtle", ItemID = 4359, Experience = 38.95, Tab = 2 },
        { Name = "Infernal eel", ItemID = 4359, Experience = 97.37, Tab = 2 },
        { Name = "Raw manta ray", ItemID = 4359, Experience = 47.15, Tab = 2 },
        { Name = "Raw anglerfish", ItemID = 4359, Experience = 123, Tab = 2 },
        { Name = "Minnow", ItemID = 4359, Experience = 26.75, Tab = 2 },
        { Name = "Raw dark crab", ItemID = 4359, Experience = 133.25, Tab = 2 },
        { Name = "Sacred eel", ItemID = 4359, Experience = 107.62, Tab = 2 }
    }
}
    
    
local Smithing = {
    Bronze = {
        { Name = "Bronze Bar", ItemID = 90153, Experience = 6.2, Tab = 1},
        { Name = "Bronze Axe", ItemID = 90009, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Dagger", ItemID = 90162, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Mace", ItemID = 90163, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Med Helm", ItemID = 90043, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Bolts (unf)", ItemID = 90164, Experience = 12.5, Tab = 1 },   
        { Name = "Bronze Nails", ItemID = 90043, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Sword", ItemID = 90165, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Dart Tips", ItemID = 90166, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Arrowtips", ItemID = 90179, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Scimitar", ItemID = 90033, Experience = 25, Tab = 1 },
        { Name = "Bronze Javelin Heads", ItemID = 4359, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Longsword", ItemID = 90236, Experience = 25, Tab = 1 },
        { Name = "Bronze Limbs", ItemID = 90396, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Knife", ItemID = 90169, Experience = 12.5, Tab = 1 },
        { Name = "Bronze Full Helm", ItemID = 90168, Experience = 25, Tab = 1 },
        { Name = "Bronze Sq Shield", ItemID = 90046, Experience = 25, Tab = 1 },
        { Name = "Bronze Warhammer", ItemID = 90170, Experience = 37.5, Tab = 1 },
        { Name = "Bronze Battleaxe", ItemID = 90171, Experience = 37.5, Tab = 1 },
        { Name = "Bronze Chainbody", ItemID = 90172, Experience = 37.5, Tab = 1 },
        { Name = "Bronze Kiteshield", ItemID = 90173, Experience = 37.5, Tab = 1 },
        { Name = "Bronze Claws", ItemID = 90174, Experience = 25, Tab = 1 },
        { Name = "Bronze Platelegs", ItemID = 90176, Experience = 37.5, Tab = 1 },
        { Name = "Bronze Plateskirt", ItemID = 90177, Experience = 37.5, Tab = 1 },
        { Name = "Bronze Platebody", ItemID = 90178, Experience = 62.5, Tab = 1 }
    },
    Iron = {
        { Name = "Iron Bar", ItemID = 90155, Experience = 12.5, Tab = 2 },
        { Name = "Iron Dagger", ItemID = 90086, Experience = 25, Tab = 2  },
        { Name = "Iron Axe", ItemID = 90011, Experience = 25, Tab = 2  },
        { Name = "Iron Spit", ItemID = 4359, Experience = 25, Tab = 2  },
        { Name = "Iron Mace", ItemID = 90181, Experience = 25, Tab = 2  },
        { Name = "Iron Med Helm", ItemID = 90182, Experience = 25, Tab = 2  },
        { Name = "Iron Nails", ItemID = 90185, Experience = 25, Tab = 2  },
        { Name = "Iron Dart Tip", ItemID = 90202, Experience = 25, Tab = 2  },
        { Name = "Iron Sword", ItemID = 90184, Experience = 25, Tab = 2  },
        { Name = "Iron Arrowtips", ItemID = 90199, Experience = 25, Tab = 2  },
        { Name = "Iron Scimitar", ItemID = 90186, Experience = 50, Tab = 2  },
        { Name = "Iron Longsword", ItemID = 90188, Experience = 50, Tab = 2  },
        { Name = "Iron Javelin Heads", ItemID = 4359, Experience = 25, Tab = 2  },
        { Name = "Iron Full Helm", ItemID = 90189, Experience = 50, Tab = 2  },
        { Name = "Iron Knife", ItemID = 90190, Experience = 25, Tab = 2  },
        { Name = "Iron Limbs", ItemID = 90397, Experience = 25, Tab = 2  },
        { Name = "Iron Sq Shield", ItemID = 90191, Experience = 50, Tab = 2  },
        { Name = "Iron Warhammer", ItemID = 90192, Experience = 75, Tab = 2  },
        { Name = "Iron Battleaxe", ItemID = 90085, Experience = 75, Tab = 2  },
        { Name = "Oil Lantern Frame", ItemID = 4359, Experience = 25, Tab = 2  },
        { Name = "Iron Chainbody", ItemID = 90193, Experience = 75, Tab = 2  },
        { Name = "Iron Kiteshield", ItemID = 90194, Experience = 75, Tab = 2  },
        { Name = "Iron Claws", ItemID = 90195, Experience = 50, Tab = 2  },
        { Name = "Iron Plateskirt", ItemID = 90196, Experience = 75, Tab = 2  },
        { Name = "Iron Platelegs", ItemID = 90197, Experience = 75, Tab = 2  },
        { Name = "Iron Platebody", ItemID = 90198, Experience = 125, Tab = 2  }
    },
    Steel = {
        { Name = "Steel Bar", ItemID = 90154, Experience = 17.5, Tab = 3 },
        { Name = "Steel Dagger", ItemID = 90267, Experience = 37.5, Tab = 3 },
        { Name = "Steel Axe", ItemID = 90012, Experience = 37.5, Tab = 3 },
        { Name = "Steel Mace", ItemID = 90268, Experience = 37.5, Tab = 3 },
        { Name = "Steel Med Helm", ItemID = 90269, Experience = 37.5, Tab = 3 },
        { Name = "Steel Bolts(Unf)", ItemID = 90270, Experience = 37.5, Tab = 3 },
        { Name = "Steel Dart Tip", ItemID = 90288, Experience = 37.5, Tab = 3 },
        { Name = "Steel Sword", ItemID = 90271, Experience = 37.5, Tab = 3 },
        { Name = "Cannonball (x4)", ItemID = 4359, Experience = 25.6, Tab = 3 },
        { Name = "Steel Scimitar", ItemID = 90272, Experience = 37.5, Tab = 3 },
        { Name = "Steel Arrowtips", ItemID = 90285, Experience = 37.5, Tab = 3 },
        { Name = "Steel Limbs", ItemID = 90398, Experience = 37.5, Tab = 3 },
        { Name = "Steel Studs", ItemID = 90399, Experience = 37.5, Tab = 3 },
        { Name = "Steel Longsword", ItemID = 90274, Experience = 75, Tab = 3 },
        { Name = "Steel Javelin Heads", ItemID = 4359, Experience = 37.5, Tab = 3 },
        { Name = "Steel Knife", ItemID = 4359, Experience = 37.5, Tab = 3 },
        { Name = "Steel Full Helm", ItemID = 90275, Experience = 75, Tab = 3 },
        { Name = "Steel Sq Shield", ItemID = 90277, Experience = 75, Tab = 3 },
        { Name = "Steel Warhammer", ItemID = 90278, Experience = 112.5, Tab = 3 },
        { Name = "Steel Battleaxe", ItemID = 90266, Experience = 112.5, Tab = 3 },
        { Name = "Steel Chainbody", ItemID = 90279, Experience = 112.5, Tab = 3 },
        { Name = "Steel Kiteshield", ItemID = 90280, Experience = 112.5, Tab = 3 },
        { Name = "Steel Claws", ItemID = 90281, Experience = 75, Tab = 3 },
        { Name = "Steel 2h Sword", ItemID = 90286, Experience = 112.5, Tab = 3 },
        { Name = "Steel Platelegs", ItemID = 90283, Experience = 112.5, Tab = 3 },
        { Name = "Steel Plateskirt", ItemID = 90282, Experience = 112.5, Tab = 3 },
        { Name = "Steel Platebody", ItemID = 90284, Experience = 187.5, Tab = 3 },
        { Name = "Bullseye Lantern (Unf)", ItemID = 4359, Experience = 37.5, Tab = 3 },
    },
    Gold = {
        { Name = "Gold bar (Goldsmith gauntlets)", ItemID = 90160, Experience = 56.2, Tab = 4 },
        { Name = "Gold bar", ItemID = 90160, Experience = 22.5, Tab = 4 },
    }
}
    

local function formatWithCommas(number)
    local formatted = tostring(math.abs(number))  -- Convert to positive number as a string
    local isNegative = number < 0                 -- Check if the original number is negative

    if #formatted <= 3 then
        -- Return as-is if the number has three or fewer digits
        return (isNegative and "-" or "") .. formatted
    end

    -- Insert commas every three digits from the right
    local result = ""
    local length = #formatted

    for i = length, 1, -1 do
        local posFromEnd = length - i + 1
        result = formatted:sub(i, i) .. result
        if posFromEnd % 3 == 0 and i > 1 then
            result = "," .. result
        end
    end

    return (isNegative and "-" or "") .. result
end
    
    
-- Store dynamically created tabs for easy management
local tabs = {}

local function updateItemList(groupItems)
    -- Clear previous item lines
    local itemLines = {}

    -- Calculate required XP for each item in the selected group
    local requiredXP = GOALXP - CURRENTXP

    for _, item in ipairs(groupItems) do
        local itemIcon = GetItemIcon(item.ItemID)
        local itemsNeeded = math.ceil(requiredXP / item.Experience)  -- Calculate items needed
        local itemsNeededFormatted = formatWithCommas(itemsNeeded) -- Format items needed with commas
        local displayLine = itemIcon and string.format("|T%s:16:16|t %s\nReq: %s", itemIcon, item.Name, itemsNeededFormatted)
                             or string.format("%s\nReq: %s", item.Name, itemsNeededFormatted)

        table.insert(itemLines, displayLine)
        table.insert(itemLines, "")  -- Add blank line for spacing
    end

    -- Update contentText with the new item lines
    contentText:SetText(table.concat(itemLines, "\n"))
end

-- Function to create tabs based on the groups in the selected skill
local function createTabsForGroups(skillData)
    -- Clear existing tabs if any
    for _, tab in ipairs(tabs) do
        tab:Hide()
    end
    wipe(tabs)

    -- Positioning for the tabs
    local xOffset = -300

    -- Table to hold tab items based on their specified Tab value
    local tabGroups = {}

    -- Collect items based on their Tab value
    for groupName, groupItems in pairs(skillData) do
        for _, item in ipairs(groupItems) do
            local tabIndex = item.Tab  -- Get the specified tab number from the item
            if not tabGroups[tabIndex] then
                tabGroups[tabIndex] = { Name = groupName, Items = groupItems }  -- Initialize the group in tabGroups
            end
        end
    end

    -- Create the tabs in order based on the Tab values
    for i = 1, #tabGroups do
        if tabGroups[i] then
            local tabButton = CreateFrame("Button", nil, InfoBox, "UIPanelButtonTemplate")
            tabButton:SetSize(60, 20)
            tabButton:SetText(tabGroups[i].Name)
            tabButton:SetPoint("BOTTOMLEFT", InfoBox, "BOTTOMLEFT", xOffset, -30)
            xOffset = xOffset + 65

            -- Add tab button to the tabs table for future reference
            table.insert(tabs, tabButton)

            -- OnClick event for each tab to update the item list according to the selected group
            tabButton:SetScript("OnClick", function()
                print("Clicked tab for group:", tabGroups[i].Name)  -- Debug output
                updateItemList(tabGroups[i].Items)  -- Update the item list with the correct group
            end)
        end
    end

    -- Automatically load the first tab's content if any tabs exist
    if #tabs > 0 then
        tabs[1]:Click()  -- Load the content of the first tab
    end
end

-- Your original onSkillSelected function with tab system integrated
local function onSkillSelected(selectedSkill)
    -- Update the title based on the selected skill
    infoBoxTitle:SetText("Additional Info: " .. selectedSkill)

    -- Clear previous content
    contentText:SetText("")

    -- Get the corresponding skill ID and update XP/level
    local skillID = FactionData[selectedSkill]
    UpdateSkillLevel(skillID)

    -- Add tabs and item list for specific groups if the skill is "Smithing"
    if selectedSkill == "Smithing" then
        -- Assuming Smithing data is globally accessible, as you had it set up
        local skillData = Smithing

        -- Create tabs for each group in Smithing
        createTabsForGroups(skillData)

        -- Auto-load the first group's items (or the first group) by default
        if skillData.Bronze then
            updateItemList(skillData.Bronze)
        end
    elseif selectedSkill == "Fishing" then
            
                -- Assuming Smithing data is globally accessible, as you had it set up
        local skillData = Fishing

        -- Create tabs for each group in Smithing
        createTabsForGroups(skillData)

        -- Auto-load the first group's items (or the first group) by default
        if skillData.Fish then
            updateItemList(skillData.Fish)
        end
    elseif selectedSkill == "Prayer" then
            
                -- Assuming Smithing data is globally accessible, as you had it set up
        local skillData = Prayer

        -- Create tabs for each group in Smithing
        createTabsForGroups(skillData)

        -- Auto-load the first group's items (or the first group) by default
        if skillData.Bones then
            updateItemList(skillData.Bones)
        end
    end
end

    
    
    
    
    
    
goalInputBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    local newText = text:gsub("[^0-9]", "")  -- Remove any non-numeric characters

    if newText ~= text then
        self:SetText(newText)  -- Update the text to only include numbers
        self:SetCursorPosition(#newText)  -- Reset the cursor position
    end

    if #newText > 2 then
        newText = newText:sub(1, 2)  -- Limit the input to 2 digits
        self:SetText(newText)  -- Set the text to the first 2 characters
        self:SetCursorPosition(#newText)  -- Move the cursor to the end of the text
    end

    -- Calculate the goal level based on the input
    local goalLevel = tonumber(newText)  -- Convert input to number

    -- Check if the goal level is valid and set GOALXP
    if goalLevel and goalLevel > 0 then
        if goalLevel <= #GoalXP_DB.goalXPperLevel then
            GOALXP = GoalXP_DB.goalXPperLevel[goalLevel]  -- Get the goal XP from the table
            goalExp:SetText("Goal XP: " .. (GOALXP - CURRENTXP))  -- Update the goal experience display
        else
            GOALXP = 0  -- If the input exceeds available levels, reset GOALXP
            goalExp:SetText("Goal XP: 0")  -- Update display accordingly
        end
    else
        GOALXP = 0  -- Reset GOALXP if the input is invalid
        goalExp:SetText("Goal XP: 0")  -- Default text if the input is invalid
    end

    -- Update the skill level and experience displays
    skillLevelText:SetText(selectedSkill .. " Level: " .. CURRENTLEVEL)  -- Update level text
    experienceText:SetText(selectedSkill .. " XP: " .. CURRENTXP)  -- Update experience text

    -- Debugging statements
    print("Current selectedSkill:", selectedSkill)  -- Check the value of selectedSkill

    -- Call onSkillSelected with the current selectedSkill
    if selectedSkill then
        onSkillSelected(selectedSkill)  -- Ensure this is called correctly
    else
        print("Warning: selectedSkill is nil")  -- Warning if selectedSkill is nil
    end
end)

    
    
    
    
    
    
    
    
    
    
    
    

-- Update the button's functionality to toggle the info box
extendInfoButton:SetScript("OnClick", function()
    if infoBox:IsShown() then
        infoBox:Hide()  -- Hide the info box
        extendInfoButton:SetText("Extend Info")  -- Change button text back
    else
        infoBox:Show()  -- Show the info box
        extendInfoButton:SetText("Hide Info")  -- Change button text to Hide Info
    end
end)


    
    

local function UpdateDropdownMenu()
    -- Show the dropdown menu first
    dropdownMenu:Show()
    print("Dropdown menu is shown.")

    -- Clear previous buttons
    for _, child in ipairs({dropdownMenu:GetChildren()}) do
        child:Hide()
    end

    -- Loop through skills to create buttons
    for i, skill in ipairs(skills) do
        local optionButton = CreateFrame("Button", nil, dropdownMenu)
        optionButton:SetSize(280, 20)
        optionButton:SetPoint("TOP", dropdownMenu, "TOP", 0, -((i - 1) * 20))
        optionButton:SetNormalFontObject("GameFontNormal")

        optionButton:SetText(skill)
        optionButton:SetNormalTexture("")  -- Clear default texture

        -- Set OnClick event to select skill and hide the menu
        optionButton:SetScript("OnClick", function()
            selectedSkill = skill

            -- Debugging the skill selection
            print("Skill selected: " .. selectedSkill)

            -- Ensure UpdateSkillLevel executes correctly
            UpdateSkillLevel(FactionData[selectedSkill])  -- Update level and XP for the selected skill

            -- Update UI elements with the new skill information
            skillLevelText:SetText(selectedSkill .. " Level: " .. CURRENTLEVEL)  -- Update level text
            experienceText:SetText(selectedSkill .. " XP: " .. CURRENTXP)  -- Update experience text
            dropdownButton.text:SetText(skill)  -- Update dropdown button to show selected skill
            onSkillSelected(selectedSkill)

            -- Hide the dropdown menu
            dropdownMenu:Hide()  -- Ensure this line is reached
        end)
        optionButton:Show()
    end
end

-- Show/hide dropdown menu on dropdownButton click
dropdownButton:SetScript("OnClick", function()
    print("Dropdown button clicked.")
    if dropdownMenu:IsShown() then
        print("Hiding dropdown menu.")
        dropdownMenu:Hide()
    else
        print("Showing dropdown menu.")
        UpdateDropdownMenu()  
    end
end)
    
    
    
frame:SetScript("OnHide", function()
    if infoBox and infoBox:IsShown() then
        infoBox:Hide()  -- Hide the info box when the main frame is closed
    end
end)
    
    

    RSCalcUI = frame
end

