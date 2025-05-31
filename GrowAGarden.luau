local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau", true))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local plr = game:GetService("Players").LocalPlayer

local GuiController = require(ReplicatedStorage.Modules.GuiController)
local DataService = require(ReplicatedStorage.Modules.DataService)

local GUIs = {
    seedShop = plr.PlayerGui.Seed_Shop,
    gearShop = plr.PlayerGui.Gear_Shop,
    eventShop = plr.PlayerGui.EventShop_UI,
    twilightShop = plr.PlayerGui.NightEventShop_UI,
    honeyShop = plr.PlayerGui.HoneyEventShop_UI
}

local seedData = require(ReplicatedStorage.Data.SeedData)
local gearData = require(ReplicatedStorage.Data.GearData)
local honeyShopData = require(ReplicatedStorage.Data.HoneyEventShopData)
local events = ReplicatedStorage.GameEvents
local MutationHandler = require(ReplicatedStorage.Modules.MutationHandler)

local crops = {"Any"}
for i,_ in seedData do
    table.insert(crops,i)
end
local cropVariants = {"Normal","Gold","Rainbow"}
local cropMutations = {}
for i,_ in MutationHandler:GetMutations() do
    table.insert(cropMutations,i)
end

local Window = Library:CreateWindow{
    Title = "Jak's Grow a Garden Script",
    SubTitle = "by Jakobbb",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
}

local root = Window.Root
local __runscript = true
root.AncestryChanged:Connect(function(child, parent)
    if not parent then
        __runscript = false
    end
end)
Window.Root.Active = true

local function getPlayerFarm()
    for _,farm in workspace.Farm:GetChildren() do
        local Owner = farm.Important.Data.Owner.Value
        if plr.Name == Owner then
            return farm
        end
    end
    return nil
end

local function checkIfMaxEgg()
    local farm = getPlayerFarm()
    if not farm then return false end
    local objs = farm.Important.Objects_Physical
    local data = DataService:GetDate()
    local extraEggSlots = data.PetData.PurchasedEggSlots
    local eggSlots = extraEggSlots+3
    local eggs = 0
    for _,egg in objs:GetChildren() do
        if egg:GetAttribute("OBJECT_TYPE") ~= "PetEgg" then continue end
        eggs += 1
    end
    if eggs+1>eggSlots then return false end
    return true
end

local Tabs = {
    Garden = Window:AddTab{Title="Garden",Icon="phosphor-plant"},
    Shop = Window:AddTab{Title = "Shop", Icon = "phosphor-storefront"},
    Pets = Window:AddTab{Title = "Pets", Icon = "phosphor-dog"},
    Items = Window:AddTab{Title = "Items", Icon = "phosphor-backpack"},
    ui = Window:AddTab{Title = "GUIs", Icon = "phosphor-layout"},
    Performance = Window:AddTab{Title = "Performance", Icon = "phosphor-gauge"},
    Misc = Window:AddTab{Title = "Misc", Icon = "phosphor-list"},
    vln = Window:AddTab{Title = "Vulns", Icon = "phosphor-bug"},
    Settings = Window:AddTab{Title = "Settings", Icon = "phosphor-gear"},
}

Tabs.ui:AddButton{
    Title = "Open Seed Shop",
    Description = "",
    Callback = function()
        GuiController:Toggle(GUIs.seedShop)
    end
}
Tabs.ui:AddButton{
    Title = "Open Gear Shop",
    Description = "",
    Callback = function()
        GuiController:Toggle(GUIs.gearShop)
    end
}
Tabs.ui:AddButton{
    Title = "Open Honey Shop",
    Description = "",
    Callback = function()
        GuiController:Toggle(GUIs.honeyShop)
    end
}
Tabs.ui:AddButton{
    Title = "Open Twilight Shop",
    Description = "",
    Callback = function()
        GuiController:Toggle(GUIs.twilightShop)
    end
}

local function filterShopList(list)
    local result = {}
    if not list then return result end
    for item,info in list do
        if info.StockChance<1 then continue end
        table.insert(result,item)
    end
    return result
end

-- Shop
Tabs.Shop:AddSection("Seed Shop")
local seedShopList = filterShopList(seedData)
local slBuySeed = Tabs.Shop:AddDropdown("abss",{
    Title = "Seeds",
    Multi = true,
    Values = seedShopList,
    Default = {}
})
local autoBuySeed
autoBuySeed = Tabs.Shop:AddToggle("abs",{
    Title = "Auto Buy Seed",
    Description = "Buys seeds from the seed shop",
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while __runscript and task.wait(.5) and autoBuySeed.Value do
                local seedStock = DataService:GetData().SeedStock.Stocks
                local event = events.BuySeedStock
                for item,val in slBuySeed.Value do 
                    
                    if not val then continue end
                    if not seedStock[item] then continue end
                    if DataService:GetData().Sheckles<seedData[item].Price then continue end
                    for i=0,seedStock[item].Stock do
                        event:FireServer(item)
                        task.wait(.1)
                    end
                    task.wait(.5)
                end
            end
        end)
    end
})

Tabs.Shop:AddSection("Gear Shop")
local gearShopList = filterShopList(gearData)
local slBuyGear = Tabs.Shop:AddDropdown("abgs",{
    Title = "Gears",
    Multi = true,
    Values = gearShopList,
    Default = {}
})
local autoBuyGear
autoBuyGear = Tabs.Shop:AddToggle("abg",{
    Title = "Auto Buy Gear",
    Description = "Buys gears from the gear shop",
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while __runscript and task.wait(.5) and autoBuyGear.Value do
                local gearStock = DataService:GetData().GearStock.Stocks
                local event = events.BuyGearStock
                for item,val in slBuyGear.Value do 
                    
                    if not val then continue end
                    if not gearStock[item] then continue end
                    if DataService:GetData().Sheckles<gearData[item].Price then continue end
                    for i=0,gearStock[item].Stock do
                        event:FireServer(item)
                        task.wait(.1)
                    end
                    task.wait(.5)
                end
            end
        end)
    end
})

Tabs.Shop:AddSection("Honey Shop")
local honeyShopList = filterShopList(honeyShopData)
local slBuyHoneyShop = Tabs.Shop:AddDropdown("abhss",{
    Title = "Items",
    Multi = true,
    Values = honeyShopList,
    Default = {}
})
local autoBuyHoneyShop
autoBuyHoneyShop = Tabs.Shop:AddToggle("abhs",{
    Title = "Auto Buy Honey Shop",
    Description = "Buys honey event items from the honey shop",
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while __runscript and task.wait(.5) and autoBuyHoneyShop.Value do
                local data = DataService:GetData()
                local honeyStock = data.EventShopStock.Stocks
                local event = events.BuyGearStock
                for item,val in slBuyHoneyShop.Value do 
                    
                    if not val then continue end
                    if not honeyStock[item] then continue end
                    local itemData = honeyShopData[item]
                    local cur = itemData.SpecialCurrencyType
                    local price = itemData.price
                    local currentCur = data.SpecialCurrency[cur]
                    if currentCur<price then continue end
                    for i=0,honeyStock[item].Stock do
                        event:FireServer(item)
                        task.wait(.1)
                    end
                    task.wait(.5)
                end
            end
        end)
    end
})

-- vlns
Tabs.vln:AddSection("USING ANY FEATURES FROM THIS TAB CAN GET YOU BANNED!!!")
Tabs.vln:AddSection("USING ANY FEATURES FROM THIS TAB CAN GET YOU BANNED!!!")
Tabs.vln:AddSection("USING ANY FEATURES FROM THIS TAB CAN GET YOU BANNED!!!")
Tabs.vln:AddSection("USING ANY FEATURES FROM THIS TAB CAN GET YOU BANNED!!!")

-- Items
Tabs.Items:AddSection("Pets")
Tabs.Items:AddButton({
    Title = "Hold All Pets",
    Callback = function()
        for _,pet in plr.Backpack:GetChildren() do
            if pet:GetAttribute("ItemType")~= "Pet" then continue end
            pet.Parent = plr.Character
        end
    end
})
Tabs.Items:AddSection("Seeds")
Tabs.Items:AddButton({
    Title = "Hold All Seeds",
    Callback = function()
        for _,seed in plr.Backpack:GetChildren() do
            if seed:GetAttribute("ItemType")~= "Seed" then continue end
            seed.Parent = plr.Character
        end
    end
})

-- Garden
Tabs.Garden:AddSection("Collect")
local autoCollectFSel = Tabs.Garden:AddDropdown("acfs",{
    Title = "Plant(s)",
    Default = {},
    Multi = true,
    Values = crops
})
local autoCollectVSel = Tabs.Garden:AddDropdown("acvs",{
    Title = "Variant(s)",
    Default = {},
    Multi = true,
    Values = cropVariants
})
local autoCollectMSel = Tabs.Garden:AddDropdown("acms",{
    Title = "Mutation(s)",
    Default = {},
    Multi = true,
    Values = cropMutations
})
local autoCollectMode = Tabs.Garden:AddDropdown("acm",{
    Title = "Filter Mode",
    Default = 1,
    Multi = false,
    Values = {"OFF","AND","OR"},
    Description = "OR Example: Collect all plants with Moonlit or Bloodlit\nAND Example: Collect all plants with Moonlit and Bloodlit"
})
local autoCollectToggle 
autoCollectToggle = Tabs.Garden:AddToggle("act",{
    Title = "Auto Collect",
    Defaut = false,
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while task.wait() and __runscript and autoCollectToggle.Value do
                local farm = getPlayerFarm()
                for _,plant in farm.Important.Plants_Physical:GetChildren() do
                    if not plant:FindFirstChild("Variant") then continue end
                    local Variant = plant.Variant.Value
                    local isVar = false
                    for var,val in autoCollectVSel.Value do
                        if not val then continue end
                        if var == Variant then
                            isVar = true
                            break
                        end
                    end
                    if not isVar then continue end
                    local targets = {}
                    for name,val in autoCollectFSel.Value do
                        if not val then continue end
                        table.insert(targets,name)
                    end
                    if not table.find(targets,plant.Name) and not table.find(targets,"Any") then continue end
                    local mode = autoCollectMode.Value
                    local hasMut = mode == "AND" or mode == "OFF"
                    for mut,val in autoCollectMSel.Value do
                        if not val then continue end
                        if mode == "OR" then
                            if plant:GetAttribute(mut)==true then
                                hasMut = true
                            end
                        elseif mode == "AND" then
                            if not plant:GetAttribute(mut) then
                                hasMut = false
                            end
                        end
                    end
                    if not hasMut then continue end
                    for _,v in plant:GetDescendants() do
                        if v:IsA("ProximityPrompt") then
                            fireproximityprompt(v)
                        end
                    end
                    task.wait(.1)
                end
            end
        end)
    end
})

Tabs.Garden:AddSection("Plant")
local autoCollectToggle 
autoCollectToggle = Tabs.Garden:AddToggle("aps",{
    Title = "Auto Plant Seed",
    Defaut = false,
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            task.wait(.5)
            while task.wait(.5) and __runscript and autoCollectToggle.Value do
                local char = plr.Character or plr.CharacterAdded:Wait()
                local tool = char:FindFirstChildWhichIsA("Tool")
                if not tool then continue end
                if tool:GetAttribute("ITEM_TYPE")~="Seed" then continue end
                local seed = tool:GetAttribute("ItemName")
                events.Plant_RE:FireServer(char.PrimaryPart.Position,seed)
            end
        end)
    end
})

-- Misc
local antiAFK
antiAFK = Tabs.Misc:AddToggle("antf",{
    Title = "Anti-AFK",
    Default = true,
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while __runscript and task.wait(1) and antiAFK.Value do
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end
        end)
    end
})


SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes{}

InterfaceManager:SetFolder("JakHub")
SaveManager:SetFolder("JakHub/Grow-A-Garden")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()