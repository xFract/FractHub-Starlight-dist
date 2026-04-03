local a=game:GetService"HttpService"
local b=game:GetService"Players"
local c=game:GetService"VirtualUser"
local d=game:GetService"TeleportService"
local e=game:GetService"Lighting"
local f=game:GetService"GuiService"
local g=game:GetService"MarketplaceService"

local h={}
h.__index=h

h.Folder="StarlightInterfaceManager"
h.Settings={
Theme="Starlight",
MenuKeybind="K",
AutoExecute=false,
AutoExecuteGist="https://gist.githubusercontent.com/xFract/56ca5d02d698ea6536e4d975c4cf3d1e/raw/script.lua",
AntiAFK=false,
PerformanceMode=false,
FPSCap=60,
AutoRejoin=false,
LowPlayerHop=false,
StaffDetector=false,
WebhookURL="",
}

h.AFKThread=nil
h.IsRejoining=false
h.IsHopping=false
h.AutoExecuteSource=nil
h.AutoExecuteBound=false
h.AutoRejoinBound=false
h.StaffDetectorBound=false
h.OriginalLighting=nil
h.PerformanceRestore={}

local function cloneTable(i)
local j={}
for k,l in pairs(i)do
j[k]=l
end
return j
end

function h.new()
local i=setmetatable({},h)
i.Folder=h.Folder
i.Settings=cloneTable(h.Settings)
i.PerformanceRestore={}
return i
end

function h.SetFolder(i,j)
i.Folder=j
i:BuildFolderTree()
end

function h.SetLibrary(i,j)
i.Library=j
end

function h.SetWindow(i,j)
i.Window=j
end

function h.Notify(i,j,k,l)
if not i.Library then
return
end

i.Library:Notification{
Title=j,
Content=k,
Icon=l,
Duration=6,
}
end

function h.BuildFolderTree(i)
if not makefolder or not isfolder then
return
end

local j={}
local k=i.Folder:split"/"
for l=1,#k do
j[#j+1]=table.concat(k,"/",1,l)
end

for l,m in ipairs(j)do
if m~=""and not isfolder(m)then
makefolder(m)
end
end
end

function h.SaveSettings(i)
if not writefile then
return false
end

i:BuildFolderTree()
writefile(i.Folder.."/options.json",a:JSONEncode(i.Settings))
return true
end

function h.BuildAutoExecuteSource(i)
local j=i.Settings.AutoExecuteGist
if not j or j==""then
i.AutoExecuteSource=nil
return
end

i.AutoExecuteSource=string.format(
"repeat task.wait() until game:IsLoaded(); loadstring(game:HttpGet(%q))()",
j
)
end

function h.LoadSettings(i)
i:BuildAutoExecuteSource()

if not isfile or not readfile then
return false
end

local j=i.Folder.."/options.json"
if not isfile(j)then
return false
end

local k,l=pcall(function()
return a:JSONDecode(readfile(j))
end)
if not k or type(l)~="table"then
return false
end

for m,n in pairs(l)do
i.Settings[m]=n
end

i:BuildAutoExecuteSource()
return true
end

function h.SetTheme(i,j)
if not i.Library or not i.Library.Themes[j]then
return false
end

i.Settings.Theme=j
i.Library:SetTheme(j)
i:SaveSettings()
return true
end

function h.SetMinimizeBind(i,j)
if not j or j==""or not Enum.KeyCode[j]then
return false
end

i.Settings.MenuKeybind=j
if i.Library then
i.Library.WindowKeybind=j
end
i:SaveSettings()
return true
end

function h.SetFPSCap(i,j)
i.Settings.FPSCap=j
if type(setfpscap)=="function"then
setfpscap(j)
end
end

function h.SetAntiAFK(i,j)
i.Settings.AntiAFK=j==true

if i.AFKThread then
task.cancel(i.AFKThread)
i.AFKThread=nil
end

if i.Settings.AntiAFK then
i.AFKThread=task.spawn(function()
while i.Settings.AntiAFK do
c:CaptureController()
c:ClickButton2(Vector2.new())
task.wait(60)
end
end)
end
end

function h.SetPerformanceMode(i,j)
i.Settings.PerformanceMode=j==true

if i.Settings.PerformanceMode then
if not i.OriginalLighting then
i.OriginalLighting={
GlobalShadows=e.GlobalShadows,
FogEnd=e.FogEnd,
ShadowSoftness=e.ShadowSoftness,
}
end

i.PerformanceRestore={}
task.spawn(function()
pcall(function()
e.GlobalShadows=false
e.FogEnd=9e9
e.ShadowSoftness=0
end)

pcall(function()
for k,l in ipairs(workspace:GetDescendants())do
if l:IsA"BasePart"then
i.PerformanceRestore[l]={
class="BasePart",
Material=l.Material,
}
l.Material=Enum.Material.SmoothPlastic
elseif l:IsA"Decal"or l:IsA"Texture"then
i.PerformanceRestore[l]={
class="TextureLike",
Transparency=l.Transparency,
}
l.Transparency=1
elseif l:IsA"ParticleEmitter"or l:IsA"Trail"then
i.PerformanceRestore[l]={
class="Fx",
Enabled=l.Enabled,
}
l.Enabled=false
end
end
end)
end)
return
end

if i.OriginalLighting then
pcall(function()
e.GlobalShadows=i.OriginalLighting.GlobalShadows
e.FogEnd=i.OriginalLighting.FogEnd
e.ShadowSoftness=i.OriginalLighting.ShadowSoftness
end)
end

pcall(function()
for k,l in pairs(i.PerformanceRestore)do
if k and k.Parent then
if l.class=="BasePart"then
k.Material=l.Material
elseif l.class=="TextureLike"then
k.Transparency=l.Transparency
elseif l.class=="Fx"then
k.Enabled=l.Enabled
end
end
end
end)

i.PerformanceRestore={}
end

function h.SendWebhook(i,j,k)
local l=i.Settings.WebhookURL
if not l or l==""then
return
end

task.spawn(function()
pcall(function()
local m=(syn and syn.request)or request or http_request or(http and http.request)
if not m then
return
end

m{
Url=l,
Method="POST",
Headers={["Content-Type"]="application/json"},
Body=a:JSONEncode{
embeds={{
title=j,
description=k,
color=4894207,
footer={text="Starlight InterfaceManager"},
timestamp=DateTime.now():ToIsoDate(),
}},
},
}
end)
end)
end

function h.ServerHop(i)
if i.IsHopping then
return
end
i.IsHopping=true

task.spawn(function()
local j=i.Settings.LowPlayerHop==true
local k,l=pcall(function()
local k=string.format(
"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
game.PlaceId
)
return a:JSONDecode(game:HttpGet(k))
end)

if not k or not l or not l.data then
pcall(function()
d:Teleport(game.PlaceId,b.LocalPlayer)
end)
i.IsHopping=false
return
end

local m=game.JobId
local n
for o,p in ipairs(l.data)do
if p.id~=m and p.playing and p.maxPlayers then
if not j or p.playing<(p.maxPlayers*0.3)then
n=p
break
end
end
end

pcall(function()
if n then
d:TeleportToPlaceInstance(game.PlaceId,n.id,b.LocalPlayer)
else
d:Teleport(game.PlaceId,b.LocalPlayer)
end
end)

task.wait(5)
i.IsHopping=false
end)
end

function h.IsStaff(i,j)
if not j or j==b.LocalPlayer then
return false
end

if game.CreatorType==Enum.CreatorType.User and j.UserId==game.CreatorId then
return true
end

if game.CreatorType==Enum.CreatorType.Group then
local k,l=pcall(function()
return j:GetRankInGroup(game.CreatorId)
end)
if k and l>=200 then
return true
end
end

local k,l=pcall(function()
return j.HasVerifiedBadge
end)
if k and l then
return true
end

return false
end

function h.BindAutoRejoin(i)
if i.AutoRejoinBound then
return
end
i.AutoRejoinBound=true

local function triggerRejoin()
if not i.Settings.AutoRejoin or i.IsRejoining then
return
end

i.IsRejoining=true
task.wait(3)
pcall(function()
if#game.JobId>0 then
d:TeleportToPlaceInstance(game.PlaceId,game.JobId,b.LocalPlayer)
else
d:Teleport(game.PlaceId,b.LocalPlayer)
end
end)
task.wait(5)
i.IsRejoining=false
end

pcall(function()
local j=game:GetService"CoreGui":FindFirstChild"RobloxPromptGui"
j=j and j:FindFirstChild"promptOverlay"
if j then
j.ChildAdded:Connect(function(k)
if k.Name=="ErrorPrompt"then
triggerRejoin()
end
end)
end
end)

pcall(function()
f.ErrorMessageChanged:Connect(function()
triggerRejoin()
end)
end)
end

function h.BindStaffDetector(i)
if i.StaffDetectorBound then
return
end
i.StaffDetectorBound=true

local function checkPlayer(j)
if not i.Settings.StaffDetector or not i:IsStaff(j)then
return
end

local k="Unknown"
pcall(function()
k=g:GetProductInfo(game.PlaceId).Name
end)

i:SendWebhook(
"Staff Detected",
string.format(
"**Player:** %s\n**UserId:** %d\n**Game:** %s (PlaceId: %d)\n**Action:** Auto Hop",
j.Name,
j.UserId,
k,
game.PlaceId
)
)

task.wait(1)
i:ServerHop()
end

b.PlayerAdded:Connect(checkPlayer)
task.spawn(function()
for j,k in ipairs(b:GetPlayers())do
checkPlayer(k)
end
end)
end

function h.BindTeleportAutoExecute(i)
if i.AutoExecuteBound or not i.AutoExecuteSource or not b.LocalPlayer then
return
end
i.AutoExecuteBound=true

local j=false
b.LocalPlayer.OnTeleport:Connect(function()
if j or not i.Settings.AutoExecute then
return
end

local k=(syn and syn.queue_on_teleport)or queue_on_teleport or(fluxus and fluxus.queue_on_teleport)
if k then
k(i.AutoExecuteSource)
j=true
end
end)
end

function h.ApplyLoadedSettings(i)
if i.Library and i.Settings.Theme and i.Library.Themes[i.Settings.Theme]then
pcall(function()
i.Library:SetTheme(i.Settings.Theme)
end)
end

if i.Library and i.Settings.MenuKeybind and Enum.KeyCode[i.Settings.MenuKeybind]then
i.Library.WindowKeybind=i.Settings.MenuKeybind
end

if i.Settings.AntiAFK then
i:SetAntiAFK(true)
end
if i.Settings.PerformanceMode then
i:SetPerformanceMode(true)
end
if type(setfpscap)=="function"then
i:SetFPSCap(i.Settings.FPSCap or 60)
end
end

function h.BuildInterfaceSection(i,j,k)
assert(i.Library,"Must set InterfaceManager.Library")
assert(i.Window,"Must set InterfaceManager.Window")

k=k or{}

i:LoadSettings()
i:BindTeleportAutoExecute()
i:BindAutoRejoin()
i:BindStaffDetector()
i:ApplyLoadedSettings()

local l=i.Settings
local m={}
for n in pairs(i.Library.Themes)do
table.insert(m,n)
end
table.sort(m)

local n=j:CreateGroupbox({
Name=k.AppearanceTitle or"Appearance",
Column=k.AppearanceColumn or 1,
},"__ifm_appearance")

n:CreateLabel({
Name="Theme",
},"__ifm_theme_label"):AddDropdown({
Options=m,
CurrentOption={l.Theme},
MultipleOptions=false,
Callback=function(o)
local p=o and o[1]
if p and i.Library.Themes[p]then
i:SetTheme(p)
end
end,
},"__ifm_theme_dropdown")

n:CreateBind({
Name="Menu Keybind",
CurrentValue=l.MenuKeybind,
ChangedCallback=function(o)
i:SetMinimizeBind(o)
end,
Callback=function()end,
},"__ifm_menu_keybind")

n:CreateParagraph({
Name="Theme Tools",
Content="Use the built-in Themes groupbox on this tab for acrylic, custom themes, and autoload.",
},"__ifm_theme_note")

local o=j:CreateGroupbox({
Name=k.UtilityTitle or"Utility",
Column=k.UtilityColumn or 1,
},"__ifm_utility")

o:CreateToggle({
Name="Auto Execute",
CurrentValue=l.AutoExecute,
Callback=function(p)
l.AutoExecute=p
i:SaveSettings()
end,
},"__ifm_auto_execute")

o:CreateInput({
Name="Auto Execute URL",
PlaceholderText=l.AutoExecuteGist,
CurrentValue=l.AutoExecuteGist,
Callback=function(p)
l.AutoExecuteGist=p
i:BuildAutoExecuteSource()
i:BindTeleportAutoExecute()
i:SaveSettings()
end,
},"__ifm_auto_execute_url")

o:CreateToggle({
Name="Anti AFK",
CurrentValue=l.AntiAFK,
Callback=function(p)
i:SetAntiAFK(p)
i:SaveSettings()
end,
},"__ifm_anti_afk")

o:CreateToggle({
Name="Performance Mode",
CurrentValue=l.PerformanceMode,
Callback=function(p)
i:SetPerformanceMode(p)
i:SaveSettings()
end,
},"__ifm_performance_mode")

o:CreateSlider({
Name="FPS Cap",
Range={15,240},
Increment=1,
CurrentValue=l.FPSCap or 60,
Callback=function(p)
i:SetFPSCap(p)
i:SaveSettings()
end,
},"__ifm_fps_cap")

local p=j:CreateGroupbox({
Name=k.ServerTitle or"Server & Safety",
Column=k.ServerColumn or 2,
},"__ifm_server")

p:CreateToggle({
Name="Auto Rejoin",
CurrentValue=l.AutoRejoin,
Callback=function(q)
l.AutoRejoin=q
i:SaveSettings()
end,
},"__ifm_auto_rejoin")

p:CreateToggle({
Name="Low Player Hop",
CurrentValue=l.LowPlayerHop,
Callback=function(q)
l.LowPlayerHop=q
i:SaveSettings()
end,
},"__ifm_low_player_hop")

p:CreateToggle({
Name="Staff Detector",
CurrentValue=l.StaffDetector,
Callback=function(q)
l.StaffDetector=q
i:SaveSettings()
end,
},"__ifm_staff_detector")

p:CreateInput({
Name="Discord Webhook URL",
PlaceholderText="https://discord.com/api/webhooks/...",
CurrentValue=l.WebhookURL,
Callback=function(q)
l.WebhookURL=q
i:SaveSettings()
end,
},"__ifm_webhook")

p:CreateButton({
Name="Server Hop",
Callback=function()
i:ServerHop()
end,
},"__ifm_server_hop")

local q=j:CreateGroupbox({
Name=k.PersistenceTitle or"Persistence",
Column=k.PersistenceColumn or 2,
},"__ifm_persistence")

q:CreateParagraph({
Name="Settings File",
Content=i.Folder.."/options.json",
},"__ifm_path")

q:CreateButton({
Name="Save Settings",
Callback=function()
if i:SaveSettings()then
i:Notify("Interface Manager","Settings saved.",6026568227)
end
end,
},"__ifm_save")

q:CreateButton({
Name="Reload Settings",
Callback=function()
i:LoadSettings()
i:ApplyLoadedSettings()
i:Notify("Interface Manager","Settings reloaded from disk.",6026568227)
end,
},"__ifm_reload")

return{
Appearance=n,
Utility=o,
Server=p,
Persistence=q,
}
end

return h