local ds = require(game.ReplicatedStorage.Modules.DataService)
local data = ds:GetData()

local target = {
   "dragonfly",
   "raccoon",
   "discobee",
   "butterfly"
}

local f
for _,farm in workspace.Farm:GetChildren() do
    if farm.Important.Data.Owner.Value == game.Players.LocalPlayer.Name then
        f = farm
    end
end

local got

for i,v in data["SavedObjects"] do
    print(v.Data.EggName,v.Data.Type)
    if not v.Data.Type then continue end
    local lwr = string.lower(v.Data.Type):gsub("%s+", "")
    if not table.find(target,lwr) then continue end
    got = true
    for _,vv in f.Important.Objects_Physical:GetChildren() do
      if vv:GetAttribute("OBJECT_UUID") == i then
            vv.PetEgg.Transparency = 0
        end
    end
end

if not got then game:GetService("TeleportService"):Teleport(game.PlaceId) end
queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/Jakobb8/jak-rbx/main/rjtillpet.luau"))()')