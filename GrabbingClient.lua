local ItemsController = {}
ItemsController.__index = ItemsController

local MaxReach = 10

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Network = require(script.Parent.Parent.Parent.Important.Network)
local PlayerFunctions = require(ReplicatedStorage.Shared.Player.PlayerFunctions)
local MouseController = require(script.Parent.Parent.Player.MouseController)

local Camera = workspace.CurrentCamera
local DragItemsFolder = workspace.Game.DragItems

ItemsController.ClosestObject = nil 
ItemsController.Dragging = nil :: Model  -- item dragging 

function ItemsController:SetUpDrag()
	UserInputService.InputBegan:Connect(function(input, gPE)
		if gPE then
			return
		end
		
		if input.KeyCode == Enum.KeyCode.E  then
			if ItemsController.ClosestObject and not ItemsController.Dragging  then
				local Result = Network:InvokeServer("Drag_" .. ItemsController.ClosestObject:FindFirstChild("ID").Value)

				if Result == "No" then
					return
				end
				
				ItemsController:SetUpItem(ItemsController.ClosestObject)
				
				if Result then
					ItemsController.Dragging = ItemsController.ClosestObject
				elseif ItemsController.Dragging == ItemsController.ClosestObject then
					ItemsController.Dragging = nil
					MouseController:SetIcon("Curser")
				end
			elseif ItemsController.Dragging then
				Network:InvokeServer("Drag_" .. ItemsController.Dragging:FindFirstChild("ID").Value)
				local ItemToClear = ItemsController.Dragging
				ItemsController.Dragging = nil
				MouseController:SetIcon("Curser")
				ItemsController:ClearItem(ItemToClear)
			end
			
			
		end
	end)
end

function ItemsController:ClearItem(Item)
	print(Item)
	if Item.PrimaryPart:FindFirstChild("AlignPos") then
		Item.PrimaryPart.AlignPos:Destroy()
		Item.PrimaryPart.APos1:Destroy()
	end

	if Item.PrimaryPart:FindFirstChild("AlignOri") then
		Item.PrimaryPart:FindFirstChild("AlignOri"):Destroy()
		Item.PrimaryPart:FindFirstChild("OPos1"):Destroy()
	end

	Item:SetAttribute("SetUp", false) 

end

function ItemsController:SetUpItem(Item: Model)
	
	if Item:GetAttribute("SetUp") == true then
		return
	end
	
	Item:SetAttribute("SetUp", true) 
	
	local AlignPos = Instance.new("AlignPosition", Item.PrimaryPart)
	AlignPos.Name = "AlignPos"
	AlignPos.MaxForce = 50000
	AlignPos.MaxVelocity= 650000
	AlignPos.Mode = "OneAttachment"
	AlignPos.Position = Item.PrimaryPart.Position
	AlignPos.Responsiveness = 75
	local P1 = Instance.new("Attachment", Item.PrimaryPart)
	P1.Name = "APos1"
	AlignPos.Attachment0 = P1

	local AlignOri = Instance.new("AlignOrientation", Item.PrimaryPart)
	AlignOri.Name = "AlignOri"
	AlignOri.Mode = "OneAttachment"
	AlignOri.MaxTorque = 15000
	AlignOri.MaxAngularVelocity = 100000
	AlignOri.Responsiveness = 50

	local O1 = Instance.new("Attachment", Item.PrimaryPart)
	O1.Name = "OPos1"
	AlignOri.Attachment0 = O1

end

function ItemsController:Initialize()
	
	for i, Item in workspace.Game.DragItems:GetChildren() do
		if Item:IsA("Model") then
			
			repeat wait()
				print(1)
			until Item.PrimaryPart ~= nil
			
			if script:FindFirstChild(Item.Name) then
				require(script[Item.Name])(Item)
			end
		end
	end
	
	workspace.Game.DragItems.ChildAdded:Connect(function(Item)
		
		if Item:IsA("Model") then
			if script:FindFirstChild(Item.Name) then
				repeat wait()
					print(2)
				until Item.PrimaryPart ~= nil
				
				require(script[Item.Name])(Item)
			end
		end
	end)
	
	ItemsController:SetUpDrag()
	
	task.spawn(function()
		while wait() do
			local Character = PlayerFunctions:GetCharacter(game.Players.LocalPlayer)
			-- debugging
			local Part = Instance.new("Part")
			Part.Anchored = true
			Part.Size = Vector3.new(.1,.1,MaxReach)
			Part.CFrame = Camera.CFrame + (Camera.CFrame.LookVector * (MaxReach/2))
			Part.Parent = workspace
			Part.Color = Color3.fromRGB(255,0,0)
			Part.Material = Enum.Material.SmoothPlastic
			Part.Transparency = 0.75
			Part.CanCollide = true 
			Part.CollisionGroup = "Ray"

			-- getting available "grab" parts
			local AvailableGrabs = {}
			
			for _, x in Part:GetTouchingParts() do
				if DragItemsFolder:IsAncestorOf(x) then
					table.insert(AvailableGrabs, x.Parent)
					Part.Color = Color3.fromRGB(66, 237, 26)
				end
			end
			
			-- finding the closest to the player 
			-- out of all of them
			local ClosestPart = nil
			local ClosestDistance = math.huge
			for _, FoundPart in pairs(AvailableGrabs) do
				if FoundPart:IsA("Model") then
					local Distance = (FoundPart.PrimaryPart.Position - Character.PrimaryPart.Position).Magnitude
					
					if not ClosestPart then
						ClosestPart = FoundPart
						ClosestDistance = Distance
						continue
					end	
					
					if Distance < ClosestDistance then
						ClosestPart = FoundPart
						ClosestDistance = Distance
					end
				end
			end

			-- checks if there was a previous closest object
			if ItemsController.ClosestObject then
				-- if there was and its different that the other "closest" 
				-- object then remove the highlight from that last part
				if ItemsController.ClosestObject ~= ClosestPart then
					-- removing highlight and setting curser back
					if ItemsController.ClosestObject:FindFirstChild("Highlight") then
						ItemsController.ClosestObject:FindFirstChild("Highlight"):Destroy()
						MouseController:SetIcon("Curser")
					end
					
			
					
				else -- the closest object was actually the same! (should happen a lot)
					if not ItemsController.ClosestObject:FindFirstChild("Highlight") then
						local Highlight = Instance.new("Highlight",ItemsController.ClosestObject)
						Highlight.FillTransparency = 1
					end
					
					-- setting the player curser
					MouseController:SetIcon("Pointer")

				end
			end
			
			ItemsController.ClosestObject = ClosestPart
			
			Part:Destroy()
			Part = nil
			AvailableGrabs = nil

		end
	end)
end

return ItemsController
