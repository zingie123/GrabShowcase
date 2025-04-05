local ItemsServer = {}
ItemsServer.__index = ItemsServer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Network = require(game.ServerScriptService.Modules.Important.Network)
local Assets = ReplicatedStorage.Assets

local PlayersDragging = {}

function ItemsServer:GetItem(ItemName : string) : Model
	return Assets.Items:FindFirstChild(ItemName)
end

function ItemsServer:ToggleDrag(Player)
	if self.DraggedBy and self.DraggedBy ~= Player then
		warn("Player cannot interact with this")
		return "No"
	end
	
	if self.DraggedBy then
		PlayersDragging[Player] = nil
		self.DraggedBy = nil
		self.Model.PrimaryPart.Anchored = false
		
		task.spawn(function()
			local Count = 0
			
			repeat wait(.1)
				Count += .1
				print(Count)
			until Count > 5 or self.DraggedBy
			
			if Count > 5 then
				self.Model.PrimaryPart.Anchored = true
				self.Model:SetPrimaryPartCFrame(self.Spawn)
			else
				warn("Player picked it up!")
			end
		end)
		
		return false
	elseif not PlayersDragging[Player] then
		PlayersDragging[Player] = true
		self.DraggedBy = Player
		self.Model.PrimaryPart.Anchored = false
		self.Model.PrimaryPart:SetNetworkOwner(Player)
	else
		return false
	end
	
	
	return true
end

function ItemsServer:CreateItem(ItemName: string, Position : CFrame)
	local Item = ItemsServer:GetItem(ItemName)
	
	if not Item then
		return warn("Error: cannot create item! '" .. ItemName .. "' is not a valid item!")
	end
	
	local self = setmetatable({}, ItemsServer)
	self.Model = Item:Clone()
	self.DraggedBy = nil
	self.ID = HttpService:GenerateGUID(false)
	self.Spawn = Position

	-- setting up collision
	
	for _, Part in self.Model:GetDescendants() do
		if Part:IsA("BasePart") then
			Part.CollisionGroup = "Item"
			
			if Part ~= self.Model.PrimaryPart then
				local Weld = Instance.new("WeldConstraint")
				Weld.Part0 = self.Model.PrimaryPart
				Weld.Part1 = Part
				Weld.Parent = self.Model.PrimaryPart
			end
		end
	end
	
	-- setting up stuff for client
	local IDValue = Instance.new("StringValue", self.Model)
	IDValue.Name = "ID"
	IDValue.Value = self.ID
	
	
	Network:Bind("Drag_" .. self.ID, "Server", function(Player)
		return self:ToggleDrag(Player)
	end)
	

	self.Model.Parent = workspace.Game.DragItems
	self.Model.PrimaryPart:SetNetworkOwnershipAuto()
	self.Model.PrimaryPart.Anchored = true
	self.Model:SetPrimaryPartCFrame(Position)
end

function ItemsServer:Initialize()
	for _, Part in workspace.TestSpawns:GetChildren() do
		ItemsServer:CreateItem("X-Ray", Part.CFrame)
	end
	
end

return ItemsServer
