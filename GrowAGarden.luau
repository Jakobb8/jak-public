local Library = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local plr = game:GetService("Players").LocalPlayer

local GuiController = require(ReplicatedStorage.Modules.GuiController)
local DataService = require(ReplicatedStorage.Modules.DataService)
local ByteNetRemotes = require(ReplicatedStorage.Modules.Remotes)

local GUIs = {
    seedShop = plr.PlayerGui.Seed_Shop,
    gearShop = plr.PlayerGui.Gear_Shop,
    eventShop = plr.PlayerGui.EventShop_UI,
    honeyShop = plr.PlayerGui.HoneyEventShop_UI
}

local seedData = require(ReplicatedStorage.Data.SeedData)
local gearData = require(ReplicatedStorage.Data.GearData)
local honeyShopData = require(ReplicatedStorage.Data.HoneyEventShopData)
local petEggsModule = require(ReplicatedStorage.Data.PetRegistry.PetEggs)
local petEggData = require(ReplicatedStorage.Data.PetEggData)
local crateData = require(ReplicatedStorage.Data.CosmeticCrateRegistry.CosmeticCrates)
local events = ReplicatedStorage.GameEvents
local MutationHandler = require(ReplicatedStorage.Modules.MutationHandler)

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
dragIcon.Position = UDim2.new(0.75, 0, 0.5, 0)
dragIcon.AnchorPoint = Vector2.new(.5,0.5)
dragIcon.Active = true
dragIcon.Parent = Window.Root.Parent
dragIcon.TextSize = 12
Instance.new("UICorner",dragIcon).CornerRadius = UDim.new(1,0)
local st = Instance.new("UIStroke")
st.Thickness = 3
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

local function getGround(): RaycastResult?
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

local function isMaxEgg() : boolean
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
    if eggs+1>eggSlots then return true end
    return false
end

local function givePlantToCombpressor(type)
    --[[
    TYPE: {
        lightest: "l",
        heaviest: "w",
        closestTo10Kg: "c"
    }
    --]]
    local data = DataService:GetData()
    if data["HoneyMachine"].IsRunning then return end
    if data.HoneyMachine.HoneyStored>0 then
        events.HoneyMachineService_RE:FireServer("MachineInteract")
        task.wait()
    end
    local char = getCharacter()
    local rPlant
    local lWeight = math.huge
    local hWeight = 0
    local cDiff = math.huge
    for _,plant in plr.Backpack:GetChildren() do
        if plant:GetAttribute("ItemType")~="Holdable" then continue end
        if plant:GetAttribute("Pollinated")~=true then continue end
        local weight = plant.Weight.Value
        if type == "l" then
            if lWeight>weight then
                lWeight = weight
                rPlant = plant
            end
        elseif type == "h" then
            if hWeight<weight then
                hWeight = weight
                rPlant = plant
            end
        elseif type == "c" then
            local diff = math.abs((10-data["HoneyMachine"]["PlantWeight"])-weight)
            if diff < cDiff then
                cDiff = diff
                rPlant = plant
            end
        end
    end
    if not rPlant then return end
    unequipAllTools()
    rPlant.Parent = char
    events.HoneyMachineService_RE:FireServer("MachineInteract")
end

local Tabs = {
    Garden = Window:AddTab{Title="Garden",Icon="phosphor-plant"},
    Shop = Window:AddTab{Title = "Shop", Icon = "phosphor-storefront"},
    Event = Window:AddTab{Title = "Event", Icon = "phosphor-calendar-star"},
    Pets = Window:AddTab{Title = "Pets", Icon = "phosphor-dog"},
    Cosmetics = Window:AddTab{Title = "Cosmetics", Icon = "phosphor-package"},
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
Tabs.Event:AddSection("Honey Shop")
local honeyShopList = filterShopList(honeyShopData)
local slBuyHoneyShop = Tabs.Event:AddDropdown("abhss",{
    Title = "Items",
    Multi = true,
    Values = honeyShopList,
    Default = {}
})
local autoBuyHoneyShop
autoBuyHoneyShop = Tabs.Event:AddToggle("abhs",{
    Title = "Auto Buy Honey Shop",
    Description = "Buys honey event items from the honey shop",
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            while __runscript and task.wait(.5) and autoBuyHoneyShop.Value do
                local data = DataService:GetData()
                local honeyStock = data.EventShopStock.Stocks
                local event = events.BuyEventShopStock
                for item,val in slBuyHoneyShop.Value do 
                    
                    if not val then continue end
                    if not honeyStock[item] then continue end
                    if honeyStock[item].Stock < 1 then continue end
                    local itemData = honeyShopData[item]
                    local cur = itemData.SpecialCurrencyType
                    local price = itemData.Price
                    local currentCur = data.SpecialCurrency[cur]
                    if currentCur<price then continue end
                    for _=0,honeyStock[item].Stock do
                        event:FireServer(item)
                        print("Bought",item," once")
                        task.wait(.1)
                    end
                    task.wait(.5)
                end
            end
        end)
    end
})

local autoGiveToCombpressor
autoGiveToCombpressor = Tabs.Event:AddToggle("agtc",{
    Title = "Auto Give Plants & Collect Honey",
    Callback = function(state)
        if not state then return end
        while task.wait(1) and __runscript and autoGiveToCombpressor.Value do
            givePlantToCombpressor("c")
        end
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
    Description = "OR Example: Collect all plants with Moonlit or Bloodlit\nAND Example: Collect all plants with Moonlit and Bloodlit"
})
local autoCollectToggle 
autoCollectToggle = Tabs.Garden:AddToggle("act",{
    Title = "Auto Collect",
    Defaut = false,
    Callback = function(state)
        if not state then return end
        task.spawn(function()
            local function d(plant)
                if plant.Grow.Age.Value < plant:GetAttribute("MaxAge") then return end
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
                            if mut == m then continue end
                            if plant:GetAttribute(m) then
                                hasMut=false
                                break
                            end
                        end
                    end
                end
                if not hasMut then return end
                task.wait(.025)
                ByteNetRemotes.Crops.Collect.send({plant})
            end 
                
            while task.wait() and __runscript and autoCollectToggle.Value do
                local farm = getPlayerFarm()
                for _,plant in farm.Important.Plants_Physical:GetChildren() do
                    if plant:FindFirstChild("Fruits") then 
                        for _,fruit in plant.Fruits:GetChildren() do
                            d(fruit)
                        end
                    else
                        d(plant)
                    end
                end
            end
        end)
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
                if tool:GetAttribute("ITEM_TYPE")~="Seed" then continue end
                local seed = tool:GetAttribute("ItemName")
                events.Plant_RE:FireServer(char.PrimaryPart.Position,seed)
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

-- Misc
local antiAFK
antiAFK = Tabs.Misc:AddToggle("antf",{
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

-- Performance
Tabs.Performance:AddToggle("tTV",{
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
Tabs.Performance:AddButton({
    Title = "Disable all lighting modifications",
    Description = "Must rejoin to revert",
    Callback = function()
        for _,v in game.Lighting:GetChildren() do
            v:Destroy()
        end
    end
})

Tabs.Performance:AddButton({
    Title = "Destroy other's garden",
    Description = "Must rejoin to revert",
    Callback = function()
        for _,garden in workspace.Farm:GetChildren() do
            if garden == getPlayerFarm() then continue end
            garden:Destroy()
        end
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
                    event:FireServer("CreateEgg",pos)
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

InterfaceManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes{}

InterfaceManager:SetFolder("JakHub")
SaveManager:SetFolder("JakHub/Grow-A-Garden")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()