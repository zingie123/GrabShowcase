local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage.Assets
local ScriptedItems = Assets.ScriptUsedItems

local Player = Players.LocalPlayer

return function(Model: Model)
	print(Model)
	local SkeletonModels = {}
	
	local Camera = Instance.new("Camera", Model)
	Camera.FieldOfView = 25
	

	local XRay = script.SurfaceGui:Clone()
	XRay.Parent = Player.PlayerGui.XRay
	XRay.Name = "XRAY"
	XRay.Adornee =  Model:FindFirstChild("Screen", 3)
	
	XRay.Frame.ViewportFrame.CurrentCamera = Camera
	
	for i, NPC in workspace.NPCs:GetChildren() do
		if NPC:IsA("Model") then
			local Skeleton = ScriptedItems.Skeleton:Clone()
			table.insert(SkeletonModels, Skeleton)
			
			Skeleton.Parent = XRay.Frame.ViewportFrame.WorldModel
			Skeleton.TiedTo.Value = NPC
			
		end
	end
	
	workspace.NPCs.ChildAdded:Connect(function(NPC)
		if NPC:IsA("Model") then
			local Skeleton = ScriptedItems.Skeleton:Clone()
			table.insert(SkeletonModels, Skeleton)

			Skeleton.Parent = XRay.Frame.ViewportFrame.WorldModel
			Skeleton.TiedTo.Value = NPC

		end
	end)
	
	local Connection
	
	
	Connection = RunService.RenderStepped:Connect(function()
		if not Model or not Model.Parent then
			for _, x in SkeletonModels do
				x:Destroy()
			end

			SkeletonModels = nil
			Camera:Destroy()
			XRay:Destroy()
			Connection:Disconnect()
			return
		end
		Camera.CFrame =   Model.PrimaryPart.CFrame  
		Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Model.PrimaryPart.Position)
		
		for i, Skeleton in SkeletonModels do
			if not Skeleton.TiedTo.Value.Parent then
				Skeleton:Destroy()
				table.remove(SkeletonModels, i)
				break
			end
			
			Skeleton:SetPrimaryPartCFrame(Skeleton.TiedTo.Value.PrimaryPart.CFrame)
		end
	end)
end
