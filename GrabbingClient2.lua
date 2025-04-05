local DragController = {}
DragController.__index = DragController


local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Camera = workspace.CurrentCamera
local ItemsController = require(script.Parent.Parent.Items.ItemsController)
local MouseController = require(script.Parent.Parent.Player.MouseController)
local GoodSignal = require(ReplicatedStorage.Shared.GoodSignal.GoodSignal)
local NPCController = require(StarterPlayer.StarterPlayerScripts.Modules.Game.NPC.NPCController)
local PlayerFunctions = require(ReplicatedStorage.Shared.Player.PlayerFunctions)


local GrabSpeed = 5
local Distance = 3
local MinDistance = 2
local MaxDistance = 7

function DragController:ClearHands()
	for _, Hand in self.Hands do
		Hand:Destroy()
	end
	
	self.Hands = {}
end

function DragController:SetUpDrag()
	RunService.RenderStepped:Connect(function(deltatime)
		if not ItemsController.Dragging then
			if self.Hands[1] then
				self:ClearHands()
			end
			return
		end
		
		if #self.Hands == 0 then
			self:CreateHand(1)
		end
		
		
		
		local ItemDragging = ItemsController.Dragging
		
		MouseController:SetIcon("Grab")

		local Offset = Distance 
		local GoalCFrame = Camera.CFrame + (Camera.CFrame.LookVector * Offset) 

	
		for _, Hand in self.Hands do
			Hand.CanCollide = false
			local Distance = (ItemDragging.PrimaryPart.Position - Camera.CFrame.Position).Magnitude	
			if Hand.Name == "Right Arm" then
				Hand.Size = Vector3.new(1, 1, 1)
				Hand.CFrame = self.Character.PrimaryPart.CFrame + self.Character.PrimaryPart.CFrame.RightVector + Vector3.new(0,-1,0)
				Hand.CFrame = CFrame.lookAt(Hand.Position, ItemDragging.PrimaryPart.Position) * CFrame.Angles(math.pi/2.25, 0.2, 00)
				Hand.Size = Vector3.new(1, Distance, 1)
			else
				Hand.Size = Vector3.new(.75, 1, .75)
				Hand.CFrame = self.Character.PrimaryPart.CFrame + (self.Character.PrimaryPart.CFrame.RightVector*-1 ) + Vector3.new(0,-1,0)
				Hand.CFrame = CFrame.lookAt(Hand.Position, ItemDragging.PrimaryPart.Position) * CFrame.Angles(math.pi/2.25, 0.2, 00)
				Hand.Size = Vector3.new(.75, Distance, .75)

			end
		end
	
		ItemDragging.PrimaryPart.AlignOri.CFrame = GoalCFrame
		ItemDragging.PrimaryPart.AlignPos.Position = GoalCFrame.Position
		--ItemDragging.PrimaryPart.Touched:Connect(function(Part)
		--	self:OnTouch(Part)
		--end)

	end)
end


local TouchDb = false

function DragController:OnTouch(Part : Instance)
	if TouchDb then
		return
	end
	
end

function DragController:CreateHand(HandAmount)
	self.Hands = {}
	
	if workspace.CurrentCamera:FindFirstChild("Arms") then
		workspace.CurrentCamera.Arms:Destroy()
	end
	
	
	local Character = self.Character
	
	local Hand = Character:WaitForChild("Left Arm")
	local Model = ReplicatedStorage.Assets.ScriptUsedItems.Arms:Clone()
	Model.Parent = workspace.CurrentCamera
	
	local Shirt = Character:FindFirstChild("Shirt"):Clone()
	
	if Shirt then
		Shirt.Parent = Model
	end
	
	for i = 1, HandAmount or 1 do
		local HandModel = i == 1 and Model["Right Arm"] or Model["Left Arm"]
		HandModel.CanCollide = false
		
		HandModel.Color = Character:FindFirstChild(HandModel.Name).Color
		
		table.insert(self.Hands, HandModel)
	end

	if HandAmount == 1 then
		Model["Left Arm"].Transparency = 0
	end
	
end

function DragController.new()
	local self = setmetatable({}, DragController)
	
	self.Touched = GoodSignal.new()
	self.Hands = {}
	self.Character = PlayerFunctions:GetCharacter(game.Players.LocalPlayer)
	return self
end

function DragController:Initialize()
	local Data = DragController.new()
	
	local TouchedDebounce = false
	
	Data.Touched:Connect(function(Part)
		if TouchedDebounce then
			--return
		end
		
		TouchedDebounce = true
		
		
		task.delay(1, function()
			TouchedDebounce = false
		end)
	end)
	
	Data:SetUpDrag()
end

return DragController
