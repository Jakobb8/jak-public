local Library = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game.ReplicatedStorage
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local plr = game:GetService("Players").LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

local GuiController = require(ReplicatedStorage.Modules.GuiController)
local DataService = require(ReplicatedStorage.Modules.DataService)
local ByteNetRemotes = require(ReplicatedStorage.Modules.Remotes)

local GUIs = {
    seedShop = playerGui.Seed_Shop,
    gearShop = playerGui.Gear_Shop,
    eventShop = playerGui.EventShop_UI,
}

local seedData = require(ReplicatedStorage.Data.SeedData)
local gearData = require(ReplicatedStorage.Data.GearData)
local eventShopData = require(ReplicatedStorage.Data.EventShopData)
local petEggsModule = require(ReplicatedStorage.Data.PetRegistry.PetEggs)
local petEggData = require(ReplicatedStorage.Data.PetEggData)
local crateData = require(ReplicatedStorage.Data.CosmeticCrateRegistry.CosmeticCrates)
local events = ReplicatedStorage.GameEvents
local MutationHandler = require(ReplicatedStorage.Modules.MutationHandler)
local CalculatePlantValueModule = require(ReplicatedStorage.Modules.CalculatePlantValue)
local CraftingService = require(ReplicatedStorage.Modules.CraftingService.CraftingGlobalObjectService)
local CommaModule = require(ReplicatedStorage.Comma_Module)

local crops = {"Any"}
for i,_ in seedData do
    table.insert(crops,i)
end
table.sort(crops)
local cropVariants = {"Normal","Gold","Rainbow"}
local cropMutations = {}
for i,_ in MutationHandler:GetMutations() do
    table.insert(cropMutations,i)
end
table.sort(cropMutations)
local petEggs = {}
for i,_ in petEggsModule do
    table.insert(petEggs,i)
end
table.sort(petEggs)
local cosmeticCrates = {}
for i,_ in crateData do
    table.insert(cosmeticCrates,i)
end
table.sort(cosmeticCrates)

local Window = Library:CreateWindow{
    Title = "Jak's Grow a Garden Script",
    SubTitle = "by Jakobbb v1.1",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
}

local Tabs = {
    Garden = Window:AddTab{Title="Garden",Icon="phosphor-plant"},
    Shop = Window:AddTab{Title = "Shop", Icon = "phosphor-storefront"},
    Crafting = Window:AddTab{Title = "Crafting", Icon = "phosphor-pencil-ruler"},
    Event = Window:AddTab{Title = "Event", Icon = "phosphor-calendar-star"},
    Values = Window:AddTab{Title = "Values", Icon = "phosphor-chart-bar"},
    Pets = Window:AddTab{Title = "Pets", Icon = "phosphor-dog"},
    Cosmetics = Window:AddTab{Title = "Cosmetics", Icon = "phosphor-package"},
    Items = Window:AddTab{Title = "Items", Icon = "phosphor-backpack"},
    ui = Window:AddTab{Title = "GUIs", Icon = "phosphor-layout"},
    QOL = Window:AddTab{Title = "QOL", Icon = "phosphor-leaf"},
    vln = Window:AddTab{Title = "Vulns", Icon = "phosphor-bug"},
    Settings = Window:AddTab{Title = "Settings", Icon = "phosphor-gear"},
}

local root = Window.Root
local __runscript = true
root.AncestryChanged:Connect(function(_, parent)
    if not parent then
        __runscript = false
    end
end)
Window.Root.Active = true

local function toggleWindow()
    if Window.Root then
        Window:Minimize()
    end
end

local dragIcon = Instance.new("TextButton")
dragIcon.Font = Enum.Font.GothamBold
dragIcon.Text = "Toggle UI"
dragIcon.Size = UDim2.fromOffset(80, 80)
dragIcon.BackgroundColor3 = Color3.new(0,0,0)
dragIcon.TextColor3 = Color3.new(1,1,1)
dragIcon.Position = UDim2.new(0.75, 0, 0.5, 0)
dragIcon.AnchorPoint = Vector2.new(.5,0.5)
dragIcon.Active = true
dragIcon.TextSize = 12
dragIcon.Parent = Window.Root.Parent
Instance.new("UICorner",dragIcon).CornerRadius = UDim.new(1,0)
local st = Instance.new("UIStroke")
st.Thickness = 3
st.Color = Color3.new(1,1,1)
st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
st.Parent = dragIcon

local dragging
local dragStart
local startPosition
local debounce
local dragInput
local isDraggingSomething

dragIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = dragIcon.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false

                task.delay(0, function()
                    if debounce == true then return end
                    debounce = true
                    task.wait(.1)
                    debounce = false
                end)
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart

			if not isDraggingSomething then
				isDraggingSomething = true -- Prevent clicking while dragging
				TweenService:Create(dragIcon, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Position = UDim2.new(
						startPosition.X.Scale,
						startPosition.X.Offset + delta.X,
						startPosition.Y.Scale,
						startPosition.Y.Offset + delta.Y
					)
				}):Play()
			end

			isDraggingSomething = false -- Allow clicking after dragging
		end
	end)

dragIcon.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

dragIcon.MouseButton1Click:Connect(function()
	if not dragging and debounce == false then
		toggleWindow()
	end
end)

local function getRandomPositionFromPart(part)
	if not part then return nil end
	local size = part.Size
	local cf = part.CFrame
	local offset = Vector3.new(
		math.random() - 0.5,
		math.random() - 0.5,
		math.random() - 0.5
	) * size
	return cf.Position + cf:VectorToWorldSpace(offset)
end


local function getPlayerFarm()
    for _,farm in workspace.Farm:GetChildren() do
        local Owner = farm.Important.Data.Owner.Value
        if plr.Name == Owner then
            return farm
        end
    end
    return nil
end

local function getCharacter()
    return plr.Character or plr.CharacterAdded:Wait()
end

local function unequipAllTools()
    for _,tool in getCharacter():GetChildren() do
        if not tool:IsA("Tool") then continue end
        tool.Parent = plr.Backpack
    end
end

local function getGround()
    local char = getCharacter()
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local origin = char.HumanoidRootPart.Position
	local direction = Vector3.new(0, -100, 0)
	local raycastParams = RaycastParams.new()
    local farm = getPlayerFarm()
	raycastParams.FilterDescendantsInstances = {char,farm.Important}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(origin, direction, raycastParams)
	return result
end

local function isMaxEgg()
    local farm = getPlayerFarm()
    if not farm then return false end
    local objs = farm.Important.Objects_Physical
    local data = DataService:GetData()
    local extraEggSlots = data.PetsData.PurchasedEggSlots
    local eggSlots = extraEggSlots+3
    local eggs = 0
    for _,egg in objs:GetChildren() do
        if egg:GetAttribute("OBJECT_TYPE") ~= "PetEgg" then continue end
        eggs += 1
    end
    return eggs+1>eggSlots
end

local function getTool(toolName)
    if not toolName then return end
    for _,tool in plr.Backpack:GetChildren() do
        if string.find(tool.Name,toolName) then
            return tool
        end
    end
    for _,tool in getCharacter():GetChildren() do
        if string.find(tool.Name,toolName) then
            return tool
        end
    end
    return nil
end

local function equipTool(toolName)
    local tool = getTool(toolName)
    if not tool then return end
    tool.Parent = getCharacter()
end

local function calc(model)
            local met = setmetatable({}, {
                __index = function(_, key)
                    if key == "FindFirstChild" then
                        return function(_,childName)
                            if childName == "Item_String" then
                                return {Value = model.Name}
                            end
                            return model:FindFirstChild(childName)
                        end
                    elseif key == "GetAttribute" then
                        return function(_,attributeName)
                            return model:GetAttribute(attributeName)
                        end
                    end
                    local child = model:FindFirstChild(key)
                    if child then
                        return child
                    end
                    return model[key]
                end,
            })

            local plantValue = CalculatePlantValueModule(met)

            return plantValue
        end

local function checkIfFruitIsFavorited(fruit)
    return fruit:GetAttribute("Favorited") or fruit:GetAttribute("d")
end

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
    Title = "Open Event Shop",
    Description = "",
    Callback = function()
        GuiController:Toggle(GUIs.eventShop)
    end
}

local function filterShopList(list)
    local result = {}
    if not list then return result end
    for item,info in list do
        if info.StockChance<1 then continue end
        table.insert(result,item)
    end
    table.sort(result)
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
                    if seedStock[item].Stock < 1 then continue end
                    if DataService:GetData().Sheckles<seedData[item].Price then continue end
                    for _=0,seedStock[item].Stock do
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
                    if gearStock[item].Stock < 1 then continue end
                    if DataService:GetData().Sheckles<gearData[item].Price then continue end
                    for _=0,gearStock[item].Stock do
                        event:FireServer(item)
                        task.wait(.1)
                    end
                    task.wait(.5)
                end
            end
        end)
    end
})
Tabs.Shop:AddSection("Egg Shop")
local eggShopList = filterShopList(petEggData)
local slBuyEgg = Tabs.Shop:AddDropdown("abes",{
    Title = "Eggs",
    Multi = true,
    Values = eggShopList,
    Default = {}
})
local autoBuyEggs
autoBuyEggs = Tabs.Shop:AddToggle("abe",{
    Title = "Auto Buy Eggs",
    Description = "Buys eggs from the egg shop",
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while __runscript and task.wait(.5) and autoBuyEggs.Value do
                local eggStock = DataService:GetData().PetEggStock.Stocks
                local event = events.BuyPetEgg
                for item,val in slBuyEgg.Value do 
                    if not val then continue end
                    local stocks = {}
                    for i,s in eggStock do
                        if s.EggName == item then
                            stocks[i]=s
                        end
                    end
                    for i,stock in stocks do
                        if stock.Stock < 1 then continue end
                        if DataService:GetData().Sheckles<petEggData[stock.EggName].Price then continue end
                        for _=0,stock.Stock do
                            event:FireServer(i)
                            task.wait(.1)
                        end
                    end
                    task.wait(.5)
                end
            end
        end)
    end
})


-- Event
Tabs.Event:AddSection("Summer Harvest")

local autoSubmitSummerHarvest
autoSubmitSummerHarvest = Tabs.Event:AddToggle("assh",{
    Title = "Auto Submit Summer Harvest",
    Description = "Use with auto collect.",
    Callback = function(state)
        if not state then return end
        while autoSubmitSummerHarvest.Value and task.wait(10) and __runscript do
            events.SummerHarvestRemoteEvent:FireServer("SubmitAllPlants")
        end
    end
})

local eventShopList = filterShopList(eventShopData)
local slBuyHoneyShop = Tabs.Event:AddDropdown("absss",{
    Title = "Items",
    Multi = true,
    Values = eventShopList,
    Default = {}
})

local autoBuySummerShop
autoBuySummerShop = Tabs.Event:AddToggle("abss",{
    Title = "Auto Buy Summer Shop",
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while __runscript and task.wait(.5) and autoBuySummerShop.Value do
                local data = DataService:GetData()
                local honeyStock = data.EventShopStock.Stocks
                local event = events.BuyEventShopStock
                for item,val in slBuyHoneyShop.Value do 
                    
                    if not val then continue end
                    if not honeyStock[item] then continue end
                    if honeyStock[item].Stock < 1 then continue end
                    local itemData = eventShopData[item]
                    local cur = itemData.SpecialCurrencyType
                    local price = itemData.Price
                    local currentCur = data.SpecialCurrency[cur]
                    if currentCur<price then continue end
                    for _=0,honeyStock[item].Stock do
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
            pet.Parent = getCharacter()
        end
    end
})
Tabs.Items:AddSection("Seeds")
Tabs.Items:AddButton({
    Title = "Hold All Seeds",
    Callback = function()
        for _,seed in plr.Backpack:GetChildren() do
            if seed:GetAttribute("ItemType")~= "Seed" then continue end
            seed.Parent = getCharacter()
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
    Values = {"OFF","AND","OR","ONLY"},
    Description = [[OR Example: Collect all plants with Moonlit OR Bloodlit
AND Example: Collect all plants with Moonlit AND Bloodlit
ONLY Example: Collect all plants with Moonlit ONLY]]
})
local autoCollectToggle 
autoCollectToggle = Tabs.Garden:AddToggle("act",{
    Title = "Auto Collect",
    Defaut = false,
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            local function cPlant(plant)
                if plant:FindFirstChild("Grow") and plant.Grow.Age.Value < plant:GetAttribute("MaxAge") then return end
                local Variant = plant.Variant.Value
                local isVar = false
                for var,val in autoCollectVSel.Value do
                    if not val then continue end
                    if var == Variant then
                        isVar = true
                        break
                    end
                end
                if not isVar then return end
                local targets = {}
                for name,val in autoCollectFSel.Value do
                    if not val then continue end
                    table.insert(targets,name)
                end
                if not table.find(targets,plant.Name) and not table.find(targets,"Any") then return end
                local mode = autoCollectMode.Value
                local hasMut = mode ~= "OR"
                for mut,val in autoCollectMSel.Value do
                    if not val then continue end
                    if mode == "OFF" then continue end
                    if mode == "OR" then
                        if plant:GetAttribute(mut)==true then
                            hasMut = true
                            break
                        end
                    elseif mode == "AND" then
                        if not plant:GetAttribute(mut) then
                            hasMut = false
                            break
                        end
                    elseif mode == "ONLY" then
                        for _,m in cropMutations do
                            if not plant:GetAttribute(mut) then
                                hasMut = false
                                break
                            end
                            if mut == m then continue end
                            if plant:GetAttribute(m) == true then
                                hasMut = false
                                break
                            end
                        end
                    end
                end
                if not hasMut then return end
                task.wait(.025)
                ByteNetRemotes.Crops.Collect.send({plant})
            end 
                
            while task.wait(1) and __runscript and autoCollectToggle.Value do
                local farm = getPlayerFarm()
                for _,plant in farm.Important.Plants_Physical:GetChildren() do
                    if plant:FindFirstChild("Fruits") then 
                        for _,fruit in plant.Fruits:GetChildren() do
                            cPlant(fruit)
                        end
                    else
                        cPlant(plant)
                    end
                end
            end
        end)
    end
})

Tabs.Garden:AddSection("Favorite")
local autoFavoriteFSel = Tabs.Garden:AddDropdown("affs",{
    Title = "Fruit(s)",
    Default = {},
    Multi = true,
    Values = crops
})
local autoFavoriteVSel = Tabs.Garden:AddDropdown("afvs",{
    Title = "Variant(s)",
    Default = {},
    Multi = true,
    Values = cropVariants
})
local autoFavoriteMSel = Tabs.Garden:AddDropdown("afms",{
    Title = "Mutation(s)",
    Default = {},
    Multi = true,
    Values = cropMutations
})
local autoFavoriteFMode = Tabs.Garden:AddDropdown("affm",{
    Title = "Filter Mode",
    Default = 1,
    Multi = false,
    Values = {"OFF","AND","OR","ONLY"},
    Description = [[OR Example: Favorite all plants with Moonlit OR Bloodlit
AND Example: Favorite all plants with Moonlit AND Bloodlit
ONLY Example: Favorite all plants with Moonlit ONLY]]
})
local autoFavoriteMode = Tabs.Garden:AddDropdown("afm",{
    Title = "Favorite Mode",
    Default = 1,
    Multi = false,
    Values = {"Favorite","Unfavorite"}
})
local autoFavoriteFruit
autoFavoriteFruit = Tabs.Garden:AddToggle("aff",{
    Title = "Auto Favorite Fruit",
    Callback = function(state)
        if not state then return end
        local remote = events.FavoriteToolRemote
        local function fPlant(plant)
            if plant:FindFirstChild("Grow") and plant.Grow.Age.Value < plant:GetAttribute("MaxAge") then return end
            local fruits = autoFavoriteFSel.Value
            local variants = autoFavoriteVSel.Value
            local mutations = autoFavoriteMSel.Value
            local Variant = plant.Variant.Value
            local isVar = false
            for var,val in variants do
                if not val then continue end
                if var == Variant then
                    isVar = true
                    break
                end
            end
            if not isVar then return end
            local targets = {}
            for name,val in fruits do
                if not val then continue end
                table.insert(targets,name)
            end
            if not table.find(targets,plant.Name) and not table.find(targets,"Any") then return end
            local mode = autoFavoriteFMode.Value
            local hasMut = mode ~= "OR"
            for mut,val in mutations do
                if not val then continue end
                if mode == "OFF" then continue end
                if mode == "OR" then
                    if plant:GetAttribute(mut)==true then
                        hasMut = true
                        break
                    end
                elseif mode == "AND" then
                    if not plant:GetAttribute(mut) then
                        hasMut = false
                        break
                    end
                elseif mode == "ONLY" then
                    for _,m in cropMutations do
                        if not plant:GetAttribute(mut) then
                            hasMut = false
                            break
                        end
                        if mut == m then continue end
                        if plant:GetAttribute(m) == true then
                            hasMut = false
                            break
                        end
                    end
                end
            end
            if not hasMut then return end
            task.wait(.025)
            local tool = getTool("Favorite")
            if not tool then return end
            if not tool:IsDescendantOf(getCharacter()) then
                equipTool("Favorite")
            end
            local modeF = autoFavoriteMode.Value
            print(checkIfFruitIsFavorited(plant))
            if modeF == "Favorite" and not checkIfFruitIsFavorited(plant) then
                remote:InvokeServer(tool,plant,true)
            end
            if modeF == "Unfavorite" and checkIfFruitIsFavorited(plant) then
                remote:InvokeServer(tool,plant,false)
            end
        end 
        task.spawn(function()
            while task.wait(1) and __runscript and autoFavoriteFruit.Value do
                if not getTool("Favorite") then continue end
                local farm = getPlayerFarm()
                for _,plant in farm.Important.Plants_Physical:GetChildren() do
                    if plant:FindFirstChild("Fruits") then 
                        for _,fruit in plant.Fruits:GetChildren() do
                            fPlant(fruit)
                        end
                    else
                        fPlant(plant)
                    end
                end
            end
        end)
    end
})

Tabs.Garden:AddSection("Magnifying")
Tabs.Garden:AddButton{
    Title = "Magnify Garden",
    Callback = function()
        local farm = getPlayerFarm()
        local rem = events.MagnifyingGlassService_RE
        for _,plant in farm.Important.Plants_Physical:GetChildren() do
            if plant:FindFirstChild("Fruits") then
                for _,fruit in plant.Fruits:GetChildren() do
                    rem:FireServer("TryInspect",fruit)
                    task.wait()
                end
                task.wait()
            else
                rem:FireServer("TryInspect",plant)
                task.wait()
            end
        end
    end
}
Tabs.Garden:AddButton{
    Title = "Magnify All Garden",
    Callback = function()
        local rem = events.MagnifyingGlassService_RE
        for _,farm in workspace.Farm:GetChildren() do
            for _,plant in farm.Important.Plants_Physical:GetChildren() do
                if plant:FindFirstChild("Fruits") then
                    for _,fruit in plant.Fruits:GetChildren() do
                        task.wait()
                        if calc(fruit) < 1e8 then
                            continue
                        end
                        rem:FireServer("TryInspect",fruit)
                    end
                    task.wait()
                else
                    if calc(plant) < 1e8 then
                        continue
                    end
                    rem:FireServer("TryInspect",plant)
                    task.wait()
                end
            end
            task.wait()
        end
    end
}

Tabs.Garden:AddSection("Shovel")
local shovelSelP = Tabs.Garden:AddDropdown("ssP",{
    Title = "Plant(s)",
    Values = {}
})

Tabs.Garden:AddButton({
    Title = "Refresh Plants List",
    Callback = function()
        local plants = {}
        local farm = getPlayerFarm()
        for _,plant in farm.Important.Plants_Physical:GetChildren() do
            if plants[plant.Name] then
                plants[plant.Name] += 1
            else
                plants[plant.Name] = 1
            end
        end
        local plantsN = {}
        for n,v in plants do
            table.insert(plantsN,n.." x"..v)
        end
        shovelSelP:SetValues(plantsN)
    end
})

local shovelTill
shovelTill = Tabs.Garden:AddInput("sT",{
    Title = "Shovel Till",
    Description = "Shovels the selected plant until the garden only has the inputed number left",
    Default = 0,
    Callback = function(val)
        if not tonumber(val) then
            shovelTill:SetValue(0)
        end
    end
})

Tabs.Garden:AddButton({
    Title = "Shovel Plants",
    Callback = function()
        if not getTool("Trowel") then return end
        local plantN = shovelSelP.Value
        if not plantN then return end
        plantN = plantN:match("^(.-) x") or nil
        if not plantN then return end
        local farm = getPlayerFarm()
        local rem = events.Remove_Item
        equipTool("Shovel")
        for _,plant in farm.Important.Plants_Physical:GetChildren() do
            if plant.Name ~= plantN or not plant.PrimaryPart then continue end
            local plants = 0
            for _,plt in farm.Important.Plants_Physical:GetChildren() do
                if plt.Name ~= plantN or not plt.PrimaryPart then continue end
                plants += 1
            end
            if plants <= tonumber(shovelTill.Value) then return end
            task.wait()
            task.spawn(function()
                rem:FireServer(plant.PrimaryPart)
            end)
        end
    end
})

Tabs.Garden:AddSection("Trowel")

local trowelSelP = Tabs.Garden:AddDropdown("tsP",{
    Title = "Plant(s)",
    Values = {}
})
Tabs.Garden:AddButton({
    Title = "Refresh Plants List",
    Callback = function()
        local plants = {}
        local farm = getPlayerFarm()
        for _,plant in farm.Important.Plants_Physical:GetChildren() do
            if plants[plant.Name] then
                plants[plant.Name] += 1
            else
                plants[plant.Name] = 1
            end
        end
        local plantsN = {}
        for n,v in plants do
            table.insert(plantsN,n.." x"..v)
        end
        trowelSelP:SetValues(plantsN)
    end
})
Tabs.Garden:AddButton({
    Title = "Trowel Plants",
    Callback = function()
        if not getTool("Trowel") then return end
        local plantN = trowelSelP.Value
        if not plantN then return end
        plantN = plantN:match("^(.-) x") or nil
        if not plantN then return end
        local farm = getPlayerFarm()
        local rem = events.TrowelRemote
        local pos = getCharacter().PrimaryPart.CFrame
        equipTool("Trowel")
        for _,plant in farm.Important.Plants_Physical:GetChildren() do
            if plant.Name ~= plantN then continue end
            task.wait()
            task.spawn(function()
                rem:InvokeServer("Pickup",getTool("Trowel"),plant)
                rem:InvokeServer("Place",getTool("Trowel"),plant,pos)
            end)
        end
    end
})

Tabs.Garden:AddSection("Plant")
local autoPlantSeed 
autoPlantSeed = Tabs.Garden:AddToggle("aps",{
    Title = "Auto Plant Seed",
    Defaut = false,
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            task.wait(.5)
            while task.wait(.5) and __runscript and autoPlantSeed.Value do
                local char = getCharacter()
                local tool = char:FindFirstChildWhichIsA("Tool")
                if not tool then continue end
                if tool:GetAttribute("Seed") then continue end
                local seed = tool:GetAttribute("Seed")
                events.Plant_RE:FireServer(getGround().Position,seed)
            end
        end)
    end
})
local autoWateringCan
autoWateringCan = Tabs.Garden:AddToggle("awc",{
    Title = "Auto Watering Can",
    Callback = function(state)
        if not state then return end
        while task.wait(.1) and __runscript and autoWateringCan.Value do
            local char = getCharacter()
            local tool = char:FindFirstAncestorWhichIsA("Tool")
            if (not tool) or tool:GetAttribute("ITEM_TYPE") ~= "Watering Can" then
                unequipAllTools()
                for _,v in plr.Backpack:GetChildren() do
                    if v:GetAttribute("ITEM_TYPE") == "Watering Can" then
                        v.Parent = char
                    end
                end
            end
            events.Water_RE:FireServer(char.PrimaryPart.Position)
        end
    end
})

local antiAFK
antiAFK = Tabs.QOL:AddToggle("antf",{
    Title = "Anti-AFK",
    Default = true,
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while __runscript and task.wait(60) and antiAFK.Value do
                VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end
        end)
    end
})

-- QOL
Tabs.QOL:AddSection("Visuals")
Tabs.QOL:AddToggle("tTV",{
    Title = "Disable Camera",
    Callback = function(state)
        local cam = workspace.CurrentCamera
        if state then
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.new(Vector3.new(1000000,1000000,1000000))
        else
            cam.CameraType=Enum.CameraType.Custom
            cam.CameraSubject = getCharacter().Humanoid
        end
    end
})
Tabs.QOL:AddButton({
    Title = "Disable all lighting modifications",
    Description = "Must rejoin to revert",
    Callback = function()
        for _,v in game.Lighting:GetChildren() do
            v:Destroy()
        end
    end
})

Tabs.QOL:AddButton({
    Title = "Destroy other's garden",
    Description = "Must rejoin to revert",
    Callback = function()
        for _,garden in workspace.Farm:GetChildren() do
            if garden == getPlayerFarm() then continue end
            garden:Destroy()
        end
    end
})

Tabs.QOL:AddSection("Fruits")
local disableProx
local hoverInfo
hoverInfo = Tabs.QOL:AddToggle("hIT",{
    Title = "Hover Info",
    Description = "Shows fruit info when hovering. (Better with disable proximity prompts)",
    Callback = function(state)
        local mouse = plr:GetMouse()

        local lastInstance = nil
        local inputConnection = nil

        local phu = plr.PlayerGui.PlantHover_UI
        do
            local c = phu:FindFirstChild("FHINFO")
            if c then
                c:Destroy()
            end
        end
        task.wait(.1)

        local ui = phu.Frame:Clone()
        ui.Name = "FHINFO"
        ui.Parent = phu

        ui.PlantName.Size = UDim2.fromScale(10,0.75)
        ui.PlantInfo.Size = UDim2.fromScale(10,0.75)

        ui.Visible = true

        local function getMouseData()
            return mouse.Target, Vector2.new(mouse.X, mouse.Y)
        end

        local function getTouchData(touchPosition)
            local camera = workspace.CurrentCamera
            local viewportPoint = Vector2.new(touchPosition.X, touchPosition.Y)
            local ray = camera:ScreenPointToRay(viewportPoint.X, viewportPoint.Y)

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {plr.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude

            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

            if result then
                return result.Instance, touchPosition
            else
                return nil, touchPosition
            end
        end

        local function updatePlantInfoUI(hitInstance, screenPosition)
            local model = hitInstance
            while model and not model:IsA("Model") do
                model = model.Parent
            end

            if not model or model:FindFirstChild("Fruit_Spawn") or not model:GetAttribute("MaxAge") then
                ui.Show_Val.Value = false
                lastInstance = nil
                return
            end

            if model ~= lastInstance then
                local plantVariant = model.Variant
                if not plantVariant then return end
                plantVariant = plantVariant.Value
                local plantMutations = MutationHandler:GetMutationsAsString(model)..(plantVariant~="Normal" and ", "..plantVariant or "")
                plantMutations = (plantMutations=="" or plantMutations == " ") and "" or "["..plantMutations.."]"
                local plantWeight = model.Weight.Value
                if not plantMutations or not plantWeight then return end
                plantWeight = math.floor(plantWeight*100)/100
                ui.PlantName.Text = plantMutations.." "..model.Name.." ["..plantWeight.."]"

                local plantValue = calc(model) or 0
                local formattedValue = CommaModule.Comma(math.floor(plantValue)) or 0
                
                ui.PlantInfo.Text = formattedValue.." ¢"
            end

            ui.Position = UDim2.fromOffset(screenPosition.X, screenPosition.Y)
            ui.Show_Val.Value = true
            lastInstance = model
        end

        local function onInputMoved(input, gameProcessedEvent)
            if not hoverInfo.Value or not ui then
                inputConnection:Disconnect()
                return
            end
            if gameProcessedEvent then
                lastInstance = nil
                return
            end

            local hitInstance, screenPosition
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                hitInstance, screenPosition = getMouseData()
            elseif input.UserInputType == Enum.UserInputType.Touch then
                hitInstance, screenPosition = getTouchData(input.Position)
            else
                return
            end

            if hitInstance then
                updatePlantInfoUI(hitInstance, screenPosition)
            else
                ui.Show_Val.Value = false
                lastInstance = nil
            end
        end

        local function onInputEnded(input, gameProcessedEvent)
            if not hoverInfo.Value or gameProcessedEvent then
                ui.Show_Val.Value = false
                lastInstance = nil
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                ui.Show_Val.Value = false
                lastInstance = nil
            end
        end


        
        local function updateInputTracking()
            if inputConnection then
                inputConnection:Disconnect()
                inputConnection = nil
            end

            if hoverInfo.Value then
                if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
                    print("Touch tracking enabled (Mobile).")
                    inputConnection = UserInputService.InputChanged:Connect(onInputMoved)
                    UserInputService.InputEnded:Connect(onInputEnded)
                else
                    print("Mouse tracking enabled (PC/Desktop).")
                    inputConnection = UserInputService.InputChanged:Connect(onInputMoved)
                    UserInputService.InputEnded:Connect(onInputEnded)
                end
            end
        end

        updateInputTracking()
    end
})

disableProx = Tabs.QOL:AddToggle("dppT",{
    Title = "Disable Proximity Prompts",
    Callback = function(state)
        ProximityPromptService.Enabled = not state
    end
})

-- Pets
Tabs.Pets:AddSection("Eggs")
local selEggs = Tabs.Pets:AddDropdown("se",{
    Title = "Eggs",
    Multi = true,
    Default = {},
    Values = petEggs
})
local placeEggsRadius = Tabs.Pets:AddSlider("per",{
    Title = "Place Eggs Radius (studs)",
    Default = 10,
    Min = 0,
    Max = 100,
    Rounding = 1
})
local placeEggsMode = Tabs.Pets:AddDropdown("pem",{
    Title = "Place Egg Mode",
    Multi = false,
    Default = 1,
    Values = {"Radius", "Below Feet", "Random Position"}
})
local autoPlaceEggs
autoPlaceEggs = Tabs.Pets:AddToggle("ape",{
    Title = "Auto Place Eggs",
    Callback = function(state)
        if not state then return end
        while __runscript and task.wait(1) and autoPlaceEggs.Value do
            if isMaxEgg() then continue end
            local char = getCharacter()
            if char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool"):GetAttribute("ItemType")~="PetEgg" then continue end
            unequipAllTools()
            for eggName,statee in selEggs.Value do
                if not statee then continue end
                local egg
                for _,v in plr.Backpack:GetChildren() do
                    if string.find(v.Name,eggName) and v:GetAttribute("ItemType")=="PetEgg" then
                        egg = v
                        break
                    end
                end
                if not egg then continue end
                egg.Parent = char
                local mode = placeEggsMode.Value
                local event = events.PetEggService
                if mode=="Radius" then
                    local radius = placeEggsRadius.Value or 0
                    local raycastRes = getGround()
                    local ground = raycastRes.Instance
                    local pos = raycastRes.Position
                    if not ground:IsDescendantOf(getPlayerFarm()) then break end
                    event:FireServer("CreateEgg",pos+Vector3.new(math.random(-radius,radius),0,math.random(-radius,radius)))
                elseif mode == "Below Feet" then
                    local raycastRes = getGround()
                    local ground = raycastRes.Instance
                    local pos = raycastRes.Position
                    if not ground:IsDescendantOf(getPlayerFarm()) then break end
                    event:FireServer("CreateEgg",pos)
                elseif mode == "Random Position" then
                    local farm = getPlayerFarm()
                    local left = math.random(1,2)==2
                    local exp = farm.CurrentExpansion
                    local part
                    for _,p in exp[left and "Left" or "Right"]:GetChildren() do
                        if not p:IsA("BasePart") then continue end
                        if not part then
                            part = p
                            continue
                        end
                        if part.Mass < p.Mass then
                            part = p
                        end
                    end
                    local pos = getRandomPositionFromPart(part)
                    if not pos then continue end
                    event:FireServer("CreateEgg",pos+Vector3.new(0,part.Size.Y/2,0))
                end
            end
        end
    end
})

local autoHatchEgg 
autoHatchEgg = Tabs.Pets:AddToggle("ahe",{
    Title = "Auto Hatch Egg",
    Callback = function(state)
        if not state then return end
        while __runscript and task.wait(10) and autoHatchEgg.Value do
            local event = events.PetEggService
            local farm = getPlayerFarm()
            for _,egg in farm.Important.Objects_Physical:GetChildren() do
                if egg:GetAttribute("OBJECT_TYPE")~="PetEgg" then continue end
                if egg:GetAttribute("TimeToHatch")>0 then continue end
                event:FireServer("HatchPet",egg)
            end
        end
    end
})

-- Cosmetics
Tabs.Cosmetics:AddSection"Crates"
local slCrates = Tabs.Cosmetics:AddDropdown("apcs",{
    Title = "Crates",
    Default = {},
    Multi = true,
    Values = cosmeticCrates
})
local autoPlaceCrates
autoPlaceCrates = Tabs.Cosmetics:AddToggle("apc",{
    Title = "Auto Place Crates",
    Callback = function(state)
        if not state then return end
        while __runscript and task.wait(1) and autoPlaceCrates.Value do
            if isMaxEgg() then continue end
            local char = getCharacter()
            if char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool"):GetAttribute("ItemType")~="CosmeticCrate" then continue end
            unequipAllTools()
            for eggName,statee in slCrates.Value do
                if not statee then continue end
                local egg
                for _,v in plr.Backpack:GetChildren() do
                    if string.find(v.Name,eggName) and v:GetAttribute("ItemType")=="CosmeticCrate" then
                        egg = v
                        break
                    end
                end
                if not egg then continue end
                egg.Parent = char
                local mode = placeEggsMode.Value
                local event = events.CosmeticCrateService
                if mode=="Radius" then
                    local radius = placeEggsRadius.Value or 0
                    local raycastRes = getGround()
                    local ground = raycastRes.Instance
                    local pos = raycastRes.Position
                    if not ground:IsDescendantOf(getPlayerFarm()) then break end
                    event:FireServer("CrateCrate",pos+Vector3.new(math.random(-radius,radius),0,math.random(-radius,radius)))
                elseif mode == "Below Feet" then
                    local raycastRes = getGround()
                    local ground = raycastRes.Instance
                    local pos = raycastRes.Position
                    if not ground:IsDescendantOf(getPlayerFarm()) then break end
                    event:FireServer("CrateCrate",pos)
                elseif mode == "Random Position" then
                    local farm = getPlayerFarm()
                    local left = math.random(1,2)==2
                    local exp = farm.CurrentExpansion
                    local part
                    for _,p in exp[left and "Left" or "Right"]:GetChildren() do
                        if not p:IsA("BasePart") then continue end
                        if not part then
                            part = p
                            continue
                        end
                        if part.Mass < p.Mass then
                            part = p
                        end
                    end
                    local pos = getRandomPositionFromPart(part)
                    if not pos then continue end
                    event:FireServer("CrateCrate",pos)
                end
            end
        end
    end
})
local autoOpenCrates
autoOpenCrates = Tabs.Cosmetics:AddToggle("aoc",{
    Title = "Auto Open Crates",
    Callback = function(state)
        if not state then return end
        while __runscript and task.wait(10) and autoOpenCrates.Value do
            local data = DataService:GetData()
            local cosms = 0
            for _,_ in data.CosmeticData.Inventory do
                cosms+=1
            end
            if cosms+1>275 then continue end
            for _,crate in getPlayerFarm().Important.Objects_Physical:GetChildren() do
                if crate:GetAttribute("OBJECT_TYPE")~="CosmeticCrate" then continue end
                if crate:GetAttribute("TimeToOpen") > 0 then continue end
                events.CosmeticCrateService:FireServer("OpenCrate",crate)
            end
        end
    end
})

-- Values
local gardenValue = Tabs.Values:AddParagraph("gvP",{
    Title = "Garden Value:",
    Content = "0¢",
})

Tabs.Values:AddButton({
    Title = "Calculate Garden Value",
    Callback = function()
        local function calc(model)
            local proxyModel = {
                Item_String = {Value = model.Name}
            }

            setmetatable(proxyModel, {
                __index = function(_, key)
                    if key == "FindFirstChild" then
                        return function(_, childName)
                            if childName == "Item_String" then
                                return proxyModel.Item_String
                            end
                            return model:FindFirstChild(childName)
                        end
                    elseif key == "GetAttribute" then
                        return function(_, attributeName)
                            return model:GetAttribute(attributeName)
                        end
                    end
                    local child = model:FindFirstChild(key)
                    if child then
                        return child
                    end
                    return model[key]
                end,
            })

            local plantValue = CalculatePlantValueModule(proxyModel)
            return plantValue
        end

        local farmValue = 0
        local farm = getPlayerFarm()
        for _, plant in farm.Important.Plants_Physical:GetChildren() do
            local fruitsFolder = plant:FindFirstChild("Fruits")
            if fruitsFolder then
                for _, fruit in fruitsFolder:GetChildren() do
                    farmValue += calc(fruit)
                end
            else
                farmValue += calc(plant)
            end
        end

        gardenValue:SetValue(CommaModule.Comma(math.floor(farmValue)).."¢")
    end
})

local invValue = Tabs.Values:AddParagraph("ivP",{
    Title = "Inventory Value:",
    Content = "0¢",
})

Tabs.Values:AddButton({
    Title = "Calculate Inventory Value",
    Callback = function()
        unequipAllTools()
        local total = 0
        for _,fruit in plr.Backpack:GetChildren() do
            if fruit:GetAttribute("b") ~= "j" then continue end
            print(fruit,CalculatePlantValueModule(fruit))
            total += CalculatePlantValueModule(fruit)
        end
        print(total)
        invValue:SetValue(CommaModule.Comma(math.floor(total)).."¢")
    end
})

local fruitValue = Tabs.Values:AddParagraph("fvP",{
    Title = "Held Fruit Value:",
    Content = "0¢",
})

Tabs.Values:AddButton({
    Title = "Calculate Held Fruit Value",
    Callback = function()
        local fruit = getCharacter():FindFirstChildWhichIsA("Tool")
        if not fruit then return end
        if fruit:GetAttribute("b") ~= "j" then return end
        local fVal = CalculatePlantValueModule(fruit)
        fruitValue:SetValue(CommaModule.Comma(math.floor(fVal)).."¢")
    end
})

-- Crafting
local CraftingData = require(game.ReplicatedStorage.Data.CraftingData)
local CraftingTableDatas = CraftingData.CraftingRecipeRegistry.RecipiesSortedByMachineType
local NotificationService = require(game.ReplicatedStorage.Modules.Notification)
local InventoryEnums = require(game.ReplicatedStorage.Data.EnumRegistry.InventoryServiceEnums)
local ReversedItemEnums = require(game.ReplicatedStorage.Data.EnumRegistry.ReversedItemTypeEnums)
local PetService = require(game.ReplicatedStorage.Modules.PetServices.PetsService)
local CraftingRecipeRegistry = require(game.ReplicatedStorage.Data.CraftingData.CraftingRecipeRegistry)
local ItemRecipes = CraftingRecipeRegistry.ItemRecipes
local ItemTypeEnums = require(game.ReplicatedStorage.Data.EnumRegistry.ItemTypeEnums)
local LocalPlayer = game.Players.LocalPlayer

local function getSubmittedItems(machine)
	local machineData = CraftingService:GetIndividualCraftingMachineData(machine, machine:GetAttribute("CraftingObjectType"))
	if not (machineData and machineData.RecipeId) then return nil end
	local inputItems = machineData.InputItems
	if not inputItems then return nil end
	local submitted = {}
	for slot, _ in inputItems do
		submitted[tostring(slot)] = true
	end
	return submitted
end

local function getRequiredRecipeInputs(machine)
	local machineData = CraftingService:GetIndividualCraftingMachineData(machine, machine:GetAttribute("CraftingObjectType"))
	if not (machineData and machineData.RecipeId) then return nil end
	local recipe = ItemRecipes[machineData.RecipeId]
	if not recipe then return nil end
	return recipe.Inputs
end

local function getMissingRecipeInputs(machine)
	local submitted = getSubmittedItems(machine)
	local required = getRequiredRecipeInputs(machine)
	if not submitted or not required then return nil end
	local missing = {}
	for slot, data in required do
		if not submitted[slot] then
			missing[slot] = data
		end
	end
	return missing
end

local function inputItemToMachine(machine)
	CraftingService:GetCraftingObjectData(machine)
	local machineData = CraftingService:GetIndividualCraftingMachineData(machine, machine:GetAttribute("CraftingObjectType"))
	local recipe = machineData and machineData.RecipeId and ItemRecipes[machineData.RecipeId] or nil
	if not recipe then
		NotificationService:CreateNotification("No Crafting recipe has been selected")
		return
	end
	local submitted = getSubmittedItems(machine)
	if not submitted then return end
	local character = LocalPlayer.Character
	if not character then return end
	local tool = character:FindFirstChildWhichIsA("Tool")
	if not tool then
		NotificationService:CreateNotification("You are not holding an item!")
		return
	end
	if not character:FindFirstChildWhichIsA("Humanoid") then return end
	if tool:GetAttribute(InventoryEnums.Favorite) then
		NotificationService:CreateNotification("Cannot Submit a favorited item!")
		return
	end
	if tool:GetAttribute("Traded") then
		NotificationService:CreateNotification("This item is pending trade!")
		return
	end
	local itemType = ReversedItemEnums[tool:GetAttribute(InventoryEnums.ITEM_TYPE)] or tool:GetAttribute("ItemType")
	if not itemType then return end
	local itemName = tool:GetAttribute(InventoryEnums.ItemName)
	local petUUID = tool:GetAttribute("PET_UUID")
	local petData = petUUID and PetService:GetPlayerPetData(petUUID) or nil
	if itemType == ReversedItemEnums[ItemTypeEnums.PetEgg] then
		itemName = tool:GetAttribute(InventoryEnums.EggName)
	elseif itemType == ReversedItemEnums[ItemTypeEnums.CosmeticCrate] then
		itemName = tool:GetAttribute(InventoryEnums.CrateType)
	elseif petUUID and petData then
		itemName = petData.PetType
	elseif itemType == ReversedItemEnums[ItemTypeEnums.SprayBottle] then
		itemName = tool:GetAttribute(InventoryEnums.SprayType)
	elseif itemType == ReversedItemEnums[ItemTypeEnums["Seed Pack"]] then
		itemName = tool:GetAttribute(InventoryEnums.Type)
	elseif itemType == ReversedItemEnums[ItemTypeEnums["Harvest Tool"]] then
		itemName = ReversedItemEnums[tool:GetAttribute(InventoryEnums.ITEM_TYPE)]
	end
	local itemUUID = tool:GetAttribute(InventoryEnums.ITEM_UUID) or petUUID
	local foundSlot = nil
	for slot, data in recipe.Inputs do
		if not submitted[tostring(slot)] and data.ItemData.ItemName == itemName and data.ItemType == itemType then
			foundSlot = slot
			break
		end
	end
	if foundSlot then
		CraftingService:InputItem(machine, machine:GetAttribute("CraftingObjectType"), foundSlot, {
			ItemType = itemType,
			ItemData = {
				UUID = itemUUID
			}
		})
		game.ReplicatedStorage.GameEvents.PickupEvent:Fire("Craft_SubmitItem")
	else
		NotificationService:CreateNotification("That is not a required item for crafting")
	end
end


local function setRecipe(table, recipe)
   if not table or not recipe then return end
   local tables = workspace.CraftingTables
   if table == "Seed" then
      CraftingService:SetRecipe(tables.SeedEventCraftingWorkBench,"SeedEventWorkbench",recipe)
   end
   if table == "Gear" then
      CraftingService:SetRecipe(tables.EventCraftingWorkBench,"GearEventWorkbench",recipe)
   end
end

local gearRec = {}

for i,_ in CraftingTableDatas["GearEventWorkbench"] do
   table.insert(gearRec,i)
end

Tabs.Crafting:AddSection"Gear Crafting Table"
local GearRecipes
GearRecipes = Tabs.Crafting:AddDropdown("gl",{
   Title = "Gear Recipes",
   Values = gearRec,
   Multi = false
})

Tabs.Crafting:AddButton{
   Title = "Set Recipe",
   Callback = function()
      setRecipe("Gear",GearRecipes.Value)
   end
}

local autoCraftGear
autoCraftGear = Tabs.Crafting:AddToggle("acg", {
    Title = "Auto Craft Gear",
    Callback = function(state)
        if not state then return end
        while autoCraftGear.Value and __runscript and task.wait(10) do
            if not GearRecipes.Value then continue end
            local machine = workspace.CraftingTables.EventCraftingWorkBench
            local selectedRecipe = GearRecipes.Value
            local machineType = machine:GetAttribute("CraftingObjectType")
            local machineData = CraftingService:GetIndividualCraftingMachineData(machine, machineType)

            if not (machineData and machineData.RecipeId == selectedRecipe) then
                setRecipe("Gear", selectedRecipe)
                task.wait(0.1)
            end

            local missingInputs = getMissingRecipeInputs(machine)
            if not missingInputs then continue end

            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if not backpack then continue end

            local equipped = false

            for _, tool in ipairs(backpack:GetChildren()) do
                local itemType = ReversedItemEnums[tool:GetAttribute(InventoryEnums.ITEM_TYPE)] or tool:GetAttribute("ItemType")
                local itemName = tool:GetAttribute(InventoryEnums.ItemName)
                local petUUID = tool:GetAttribute("PET_UUID")
                local petData = petUUID and PetService:GetPlayerPetData(petUUID) or nil

                if itemType == ReversedItemEnums[ItemTypeEnums.PetEgg] then
                    itemName = tool:GetAttribute(InventoryEnums.EggName)
                elseif itemType == ReversedItemEnums[ItemTypeEnums.CosmeticCrate] then
                    itemName = tool:GetAttribute(InventoryEnums.CrateType)
                elseif petUUID and petData then
                    itemName = petData.PetType
                elseif itemType == ReversedItemEnums[ItemTypeEnums.SprayBottle] then
                    itemName = tool:GetAttribute(InventoryEnums.SprayType)
                elseif itemType == ReversedItemEnums[ItemTypeEnums["Seed Pack"]] then
                    itemName = tool:GetAttribute(InventoryEnums.Type)
                elseif itemType == ReversedItemEnums[ItemTypeEnums["Harvest Tool"]] then
                    itemName = ReversedItemEnums[tool:GetAttribute(InventoryEnums.ITEM_TYPE)]
                end

                for _, input in pairs(missingInputs) do
                    if input.ItemType == itemType and input.ItemData.ItemName == itemName then
                        unequipAllTools()
                        task.wait(0.1)
                        tool.Parent = LocalPlayer.Character
                        equipped = true
                        break
                    end
                end

                if equipped then break end
            end

            if equipped then
                inputItemToMachine(machine)
                task.wait(0.25)
                CraftingService:Craft(machine, machineType)
                task.wait(0.25)
            end
        end
    end
})




Tabs.Crafting:AddSection"Seed Crafting Table"

local seedRec = {}

for i,_ in CraftingTableDatas["SeedEventWorkbench"] do
   table.insert(seedRec,i)
end

local SeedRecipes
SeedRecipes = Tabs.Crafting:AddDropdown("sr",{
   Title = "Seed Recipes",
   Values = seedRec,
   Multi = false
})

Tabs.Crafting:AddButton{
    Title = "Set Recipe",
    Callback = function()
        setRecipe("Seed",SeedRecipes.Value)
    end
}

local autoCraftSeed
autoCraftSeed = Tabs.Crafting:AddToggle("acs", {
    Title = "Auto Craft Seed",
    Callback = function(state)
        if not state then return end
        while autoCraftSeed.Value and __runscript and task.wait(10) do
            task.wait(2)
            if not SeedRecipes.Value then continue end
            local machine = workspace.CraftingTables.SeedEventCraftingWorkBench
            local selectedRecipe = SeedRecipes.Value
            local machineType = machine:GetAttribute("CraftingObjectType")
            local machineData = CraftingService:GetIndividualCraftingMachineData(machine, machineType)

            if not (machineData and machineData.RecipeId == selectedRecipe) then
                setRecipe("Seed", selectedRecipe)
                task.wait(0.1)
            end

            local missingInputs = getMissingRecipeInputs(machine)
            if not missingInputs then continue end

            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if not backpack then continue end

            local equipped = false

            for _, tool in ipairs(backpack:GetChildren()) do
                local itemType = ReversedItemEnums[tool:GetAttribute(InventoryEnums.ITEM_TYPE)] or tool:GetAttribute("ItemType")
                local itemName = tool:GetAttribute(InventoryEnums.ItemName)
                local petUUID = tool:GetAttribute("PET_UUID")
                local petData = petUUID and PetService:GetPlayerPetData(petUUID) or nil

                if itemType == ReversedItemEnums[ItemTypeEnums.PetEgg] then
                    itemName = tool:GetAttribute(InventoryEnums.EggName)
                elseif itemType == ReversedItemEnums[ItemTypeEnums.CosmeticCrate] then
                    itemName = tool:GetAttribute(InventoryEnums.CrateType)
                elseif petUUID and petData then
                    itemName = petData.PetType
                elseif itemType == ReversedItemEnums[ItemTypeEnums.SprayBottle] then
                    itemName = tool:GetAttribute(InventoryEnums.SprayType)
                elseif itemType == ReversedItemEnums[ItemTypeEnums["Seed Pack"]] then
                    itemName = tool:GetAttribute(InventoryEnums.Type)
                elseif itemType == ReversedItemEnums[ItemTypeEnums["Harvest Tool"]] then
                    itemName = ReversedItemEnums[tool:GetAttribute(InventoryEnums.ITEM_TYPE)]
                end

                for _, input in pairs(missingInputs) do
                    if input.ItemType == itemType and input.ItemData.ItemName == itemName then
                        unequipAllTools()
                        task.wait(0.1)
                        tool.Parent = LocalPlayer.Character
                        equipped = true
                        break
                    end
                end

                if equipped then break end
            end

            if equipped then
                inputItemToMachine(machine)
                task.wait(0.25)
                CraftingService:Craft(machine, machineType)
                task.wait(0.25)
            end
        end
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
