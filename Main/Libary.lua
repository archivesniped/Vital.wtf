if not memorystats then
	memorystats = {};
	memorystats.cache = function(v470)
	end;
	memorystats.restore = function(v471)
	end;
end
for v52, v53 in pairs({"Internal","HttpCache","Instances","Signals","Script","PhysicsCollision","PhysicsParts","GraphicsSolidModels","GraphicsMeshParts","GraphicsParticles","GraphicsParts","GraphicsSpatialHash","GraphicsTerrain","GraphicsTexture","GraphicsTextureCharacter","Sounds","StreamingSounds","TerrainVoxels","Gui","Animation","Navigation","GeometryCSG"}) do
	memorystats.cache(v53);
end
local v0 = cloneref(game:GetService("UserInputService"));
local v1 = cloneref(game:GetService("TextService"));
local v2 = cloneref(game:GetService("CoreGui"));
local v3 = cloneref(game:GetService("Teams"));
local v4 = cloneref(game:GetService("Players"));
local v5 = cloneref(game:GetService("RunService"));
local v6 = cloneref(game:GetService("TweenService"));
local v7 = v5.RenderStepped;
local v8 = v4.LocalPlayer;
local v9 = v8:GetMouse();
local v10 = Instance.new("ScreenGui");
v10.ZIndexBehavior = Enum.ZIndexBehavior.Global;
v10.Parent = v2;
local v14 = {};
local v15 = {};
getgenv().Toggles = v14;
getgenv().Options = v15;
local v18 = {Registry={},RegistryMap={},HudRegistry={},FontColor=Color3.fromRGB(255, 255, 255),MainColor=Color3.fromRGB(28, 28, 28),BackgroundColor=Color3.fromRGB(20, 20, 20),AccentColor=Color3.fromRGB(106, 90, 205),OutlineColor=Color3.fromRGB(50, 50, 50),RiskColor=Color3.fromRGB(255, 50, 50),Black=Color3.new(0, 0, 0),Font=Enum.Font.RobotoMono,OpenedFrames={},DependencyBoxes={},Signals={},ScreenGui=v10};
local v19 = 0;
local v20 = 0;
table.insert(v18.Signals, v7:Connect(function(v54)
	v19 = v19 + v54;
	if (v19 >= (1 / 60)) then
		v19 = 0;
		v20 = v20 + (1 / 400);
		if (v20 > 1) then
			v20 = 0;
		end
		v18.CurrentRainbowHue = v20;
		v18.CurrentRainbowColor = Color3.fromHSV(v20, 0.8, 1);
	end
end));
local function v21()
	local v55 = v4:GetPlayers();
	for v212 = 1, #v55 do
		v55[v212] = v55[v212].Name;
	end
	table.sort(v55, function(v215, v216)
		return v215 < v216;
	end);
	return v55;
end
local function v22()
	local v56 = v3:GetTeams();
	for v217 = 1, #v56 do
		v56[v217] = v56[v217].Name;
	end
	table.sort(v56, function(v220, v221)
		return v220 < v221;
	end);
	return v56;
end
v18.SafeCallback = function(v57, v58, ...)
	if not v58 then
		return;
	end
	if not v18.NotifyOnError then
		return v58(...);
	end
	local v59, v60 = pcall(v58, ...);
	if not v59 then
		local v474, v475 = v60:find(":%d+: ");
		if not v475 then
			return v18:Notify(v60);
		end
		return v18:Notify(v60:sub(v475 + 1), 3);
	end
end;
v18.AttemptSave = function(v61)
	if v18.SaveManager then
		v18.SaveManager:Save();
	end
end;
v18.Create = function(v62, v63, v64)
	local v65 = v63;
	if (type(v63) == "string") then
		v65 = Instance.new(v63);
	end
	for v222, v223 in next, v64 do
		v65[v222] = v223;
	end
	return v65;
end;
v18.ApplyTextStroke = function(v66, v67)
	v67.TextStrokeTransparency = 1;
	v18:Create("UIStroke", {Color=Color3.new(0, 0, 0),Thickness=1,LineJoinMode=Enum.LineJoinMode.Miter,Parent=v67});
end;
v18.CreateLabel = function(v69, v70, v71)
	local v72 = v18:Create("TextLabel", {BackgroundTransparency=1,Font=v18.Font,TextColor3=v18.FontColor,TextSize=16,TextStrokeTransparency=0});
	v18:ApplyTextStroke(v72);
	v18:AddToRegistry(v72, {TextColor3="FontColor"}, v71);
	return v18:Create(v72, v70);
end;
v18.MakeDraggable = function(v73, v74, v75)
	v74.Active = true;
	v74.InputBegan:Connect(function(v225)
		if (v225.UserInputType == Enum.UserInputType.MouseButton1) then
			local v751 = Vector2.new(v9.X - v74.AbsolutePosition.X, v9.Y - v74.AbsolutePosition.Y);
			if (v751.Y > (v75 or 40)) then
				return;
			end
			while v0:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				v74.Position = UDim2.new(0, (v9.X - v751.X) + (v74.Size.X.Offset * v74.AnchorPoint.X), 0, (v9.Y - v751.Y) + (v74.Size.Y.Offset * v74.AnchorPoint.Y));
				v7:Wait();
			end
		end
	end);
end;
v18.AddToolTip = function(v77, v78, v79)
	local v80, v81 = v18:GetTextBounds(v78, v18.Font, 14);
	local v82 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,Size=UDim2.fromOffset(v80 + 5, v81 + 4),ZIndex=100,Parent=v18.ScreenGui,Visible=false});
	local v83 = v18:CreateLabel({Position=UDim2.fromOffset(3, 1),Size=UDim2.fromOffset(v80, v81),TextSize=14,Text=v78,TextColor3=v18.FontColor,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=(v82.ZIndex + 1),Parent=v82});
	v18:AddToRegistry(v82, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
	v18:AddToRegistry(v83, {TextColor3="FontColor"});
	local v84 = false;
	v79.MouseEnter:Connect(function()
		if v18:MouseIsOverOpenedFrame() then
			return;
		end
		v84 = true;
		v82.Position = UDim2.fromOffset(v9.X + 15, v9.Y + 12);
		v82.Visible = true;
		while v84 do
			v5.Heartbeat:Wait();
			v82.Position = UDim2.fromOffset(v9.X + 15, v9.Y + 12);
		end
	end);
	v79.MouseLeave:Connect(function()
		v84 = false;
		v82.Visible = false;
	end);
end;
v18.OnHighlight = function(v85, v86, v87, v88, v89)
	v86.MouseEnter:Connect(function()
		local v229 = v18.RegistryMap[v87];
		for v477, v478 in next, v88 do
			v87[v477] = v18[v478] or v478;
			if (v229 and v229.Properties[v477]) then
				v229.Properties[v477] = v478;
			end
		end
	end);
	v86.MouseLeave:Connect(function()
		local v230 = v18.RegistryMap[v87];
		for v480, v481 in next, v89 do
			v87[v480] = v18[v481] or v481;
			if (v230 and v230.Properties[v480]) then
				v230.Properties[v480] = v481;
			end
		end
	end);
end;
v18.MouseIsOverOpenedFrame = function(v90)
	for v231, v232 in next, v18.OpenedFrames do
		local v233, v234 = v231.AbsolutePosition, v231.AbsoluteSize;
		if ((v9.X >= v233.X) and (v9.X <= (v233.X + v234.X)) and (v9.Y >= v233.Y) and (v9.Y <= (v233.Y + v234.Y))) then
			return true;
		end
	end
end;
v18.IsMouseOverFrame = function(v91, v92)
	local v93, v94 = v92.AbsolutePosition, v92.AbsoluteSize;
	if ((v9.X >= v93.X) and (v9.X <= (v93.X + v94.X)) and (v9.Y >= v93.Y) and (v9.Y <= (v93.Y + v94.Y))) then
		return true;
	end
end;
v18.UpdateDependencyBoxes = function(v95)
	for v235, v236 in next, v18.DependencyBoxes do
		v236:Update();
	end
end;
v18.MapValue = function(v96, v97, v98, v99, v100, v101)
	return ((1 - ((v97 - v98) / (v99 - v98))) * v100) + (((v97 - v98) / (v99 - v98)) * v101);
end;
v18.GetTextBounds = function(v102, v103, v104, v105, v106)
	local v107 = v1:GetTextSize(v103, v105, v104, v106 or Vector2.new(1920, 1080));
	return v107.X, v107.Y;
end;
v18.GetDarkerColor = function(v108, v109)
	local v110, v111, v112 = Color3.toHSV(v109);
	return Color3.fromHSV(v110, v111, v112 / 1.5);
end;
v18.AccentColorDark = v18:GetDarkerColor(v18.AccentColor);
v18.AddToRegistry = function(v113, v114, v115, v116)
	local v117 = #v18.Registry + 1;
	local v118 = {Instance=v114,Properties=v115,Idx=v117};
	table.insert(v18.Registry, v118);
	v18.RegistryMap[v114] = v118;
	if v116 then
		table.insert(v18.HudRegistry, v118);
	end
end;
v18.RemoveFromRegistry = function(v120, v121)
	local v122 = v18.RegistryMap[v121];
	if v122 then
		for v752 = #v18.Registry, 1, -1 do
			if (v18.Registry[v752] == v122) then
				table.remove(v18.Registry, v752);
			end
		end
		for v753 = #v18.HudRegistry, 1, -1 do
			if (v18.HudRegistry[v753] == v122) then
				table.remove(v18.HudRegistry, v753);
			end
		end
		v18.RegistryMap[v121] = nil;
	end
end;
v18.UpdateColorsUsingRegistry = function(v123)
	for v237, v238 in next, v18.Registry do
		for v484, v485 in next, v238.Properties do
			if (type(v485) == "string") then
				v238.Instance[v484] = v18[v485];
			elseif (type(v485) == "function") then
				v238.Instance[v484] = v485();
			end
		end
	end
end;
v18.GiveSignal = function(v124, v125)
	table.insert(v18.Signals, v125);
end;
v18.Unload = function(v126)
	for v239 = #v18.Signals, 1, -1 do
		local v240 = table.remove(v18.Signals, v239);
		v240:Disconnect();
	end
	if v18.OnUnload then
		v18.OnUnload();
	end
	v10:Destroy();
end;
v18.OnUnload = function(v127, v128)
	v18.OnUnload = v128;
end;
v18:GiveSignal(v10.DescendantRemoving:Connect(function(v130)
	if v18.RegistryMap[v130] then
		v18:RemoveFromRegistry(v130);
	end
end));
local v44 = {};
do
	local v131 = {};
	v131.AddColorPicker = function(v241, v242, v243)
		local v244 = v241.TextLabel;
		assert(v243.Default, "AddColorPicker: Missing default value.");
		local v245 = {Value=v243.Default,Transparency=(v243.Transparency or 0),Type="ColorPicker",Title=(((type(v243.Title) == "string") and v243.Title) or "Color picker"),Callback=(v243.Callback or function(v486)
		end)};
		v245.SetHSVFromRGB = function(v487, v488)
			local v489, v490, v491 = Color3.toHSV(v488);
			v245.Hue = v489;
			v245.Sat = v490;
			v245.Vib = v491;
		end;
		v245:SetHSVFromRGB(v245.Value);
		local v247 = v18:Create("Frame", {BackgroundColor3=v245.Value,BorderColor3=v18:GetDarkerColor(v245.Value),BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(0, 28, 0, 14),ZIndex=6,Parent=v244});
		local v248 = v18:Create("ImageLabel", {BorderSizePixel=0,Size=UDim2.new(0, 27, 0, 13),ZIndex=5,Image="http://www.roblox.com/asset/?id=12977615774",Visible=not not v243.Transparency,Parent=v247});
		local v249 = v18:Create("Frame", {Name="Color",BackgroundColor3=Color3.new(1, 1, 1),BorderColor3=Color3.new(0, 0, 0),Position=UDim2.fromOffset(v247.AbsolutePosition.X, v247.AbsolutePosition.Y + 18),Size=UDim2.fromOffset(230, (v243.Transparency and 271) or 253),Visible=false,ZIndex=15,Parent=v10});
		v247:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			v249.Position = UDim2.fromOffset(v247.AbsolutePosition.X, v247.AbsolutePosition.Y + 18);
		end);
		local v250 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=16,Parent=v249});
		local v251 = v18:Create("Frame", {BackgroundColor3=v18.AccentColor,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 2),ZIndex=17,Parent=v250});
		local v252 = v18:Create("Frame", {BorderColor3=Color3.new(0, 0, 0),Position=UDim2.new(0, 4, 0, 25),Size=UDim2.new(0, 200, 0, 200),ZIndex=17,Parent=v250});
		local v253 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=18,Parent=v252});
		local v254 = v18:Create("ImageLabel", {BorderSizePixel=0,Size=UDim2.new(1, 0, 1, 0),ZIndex=18,Image="rbxassetid://4155801252",Parent=v253});
		local v255 = v18:Create("ImageLabel", {AnchorPoint=Vector2.new(0.5, 0.5),Size=UDim2.new(0, 6, 0, 6),BackgroundTransparency=1,Image="http://www.roblox.com/asset/?id=9619665977",ImageColor3=Color3.new(0, 0, 0),ZIndex=19,Parent=v254});
		local v256 = v18:Create("ImageLabel", {Size=UDim2.new(0, v255.Size.X.Offset - 2, 0, v255.Size.Y.Offset - 2),Position=UDim2.new(0, 1, 0, 1),BackgroundTransparency=1,Image="http://www.roblox.com/asset/?id=9619665977",ZIndex=20,Parent=v255});
		local v257 = v18:Create("Frame", {BorderColor3=Color3.new(0, 0, 0),Position=UDim2.new(0, 208, 0, 25),Size=UDim2.new(0, 15, 0, 200),ZIndex=17,Parent=v250});
		local v258 = v18:Create("Frame", {BackgroundColor3=Color3.new(1, 1, 1),BorderSizePixel=0,Size=UDim2.new(1, 0, 1, 0),ZIndex=18,Parent=v257});
		local v259 = v18:Create("Frame", {BackgroundColor3=Color3.new(1, 1, 1),AnchorPoint=Vector2.new(0, 0.5),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(1, 0, 0, 1),ZIndex=18,Parent=v258});
		local v260 = v18:Create("Frame", {BorderColor3=Color3.new(0, 0, 0),Position=UDim2.fromOffset(4, 228),Size=UDim2.new(0.5, -6, 0, 20),ZIndex=18,Parent=v250});
		local v261 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=18,Parent=v260});
		v18:Create("UIGradient", {Color=ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))}),Rotation=90,Parent=v261});
		local v262 = v18:Create("TextBox", {BackgroundTransparency=1,Position=UDim2.new(0, 5, 0, 0),Size=UDim2.new(1, -5, 1, 0),Font=v18.Font,PlaceholderColor3=Color3.fromRGB(190, 190, 190),PlaceholderText="Hex color",Text="#FFFFFF",TextColor3=v18.FontColor,TextSize=14,TextStrokeTransparency=0,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=20,Parent=v261});
		v18:ApplyTextStroke(v262);
		local v263 = v18:Create(v260:Clone(), {Position=UDim2.new(0.5, 2, 0, 228),Size=UDim2.new(0.5, -6, 0, 20),Parent=v250});
		local v264 = v18:Create(v263.Frame:FindFirstChild("TextBox"), {Text="255, 255, 255",PlaceholderText="RGB color",TextColor3=v18.FontColor});
		local v265, v266, v267;
		if v243.Transparency then
			v265 = v18:Create("Frame", {BorderColor3=Color3.new(0, 0, 0),Position=UDim2.fromOffset(4, 251),Size=UDim2.new(1, -8, 0, 15),ZIndex=19,Parent=v250});
			v266 = v18:Create("Frame", {BackgroundColor3=v245.Value,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=19,Parent=v265});
			v18:AddToRegistry(v266, {BorderColor3="OutlineColor"});
			v18:Create("ImageLabel", {BackgroundTransparency=1,Size=UDim2.new(1, 0, 1, 0),Image="http://www.roblox.com/asset/?id=12978095818",ZIndex=20,Parent=v266});
			v267 = v18:Create("Frame", {BackgroundColor3=Color3.new(1, 1, 1),AnchorPoint=Vector2.new(0.5, 0),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(0, 1, 1, 0),ZIndex=21,Parent=v266});
		end
		local v268 = v18:CreateLabel({Size=UDim2.new(1, 0, 0, 14),Position=UDim2.fromOffset(5, 5),TextXAlignment=Enum.TextXAlignment.Left,TextSize=14,Text=v245.Title,TextWrapped=false,ZIndex=16,Parent=v250});
		local v269 = {};
		do
			v269.Options = {};
			v269.Container = v18:Create("Frame", {BorderColor3=Color3.new(),ZIndex=14,Visible=false,Parent=v10});
			v269.Inner = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.fromScale(1, 1),ZIndex=15,Parent=v269.Container});
			v18:Create("UIListLayout", {Name="Layout",FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v269.Inner});
			v18:Create("UIPadding", {Name="Padding",PaddingLeft=UDim.new(0, 4),Parent=v269.Inner});
			local function v499()
				v269.Container.Position = UDim2.fromOffset(v247.AbsolutePosition.X + v247.AbsoluteSize.X + 4, v247.AbsolutePosition.Y + 1);
			end
			local function v500()
				local v755 = 60;
				for v847, v848 in next, v269.Inner:GetChildren() do
					if v848:IsA("TextLabel") then
						v755 = math.max(v755, v848.TextBounds.X);
					end
				end
				v269.Container.Size = UDim2.fromOffset(v755 + 8, v269.Inner.Layout.AbsoluteContentSize.Y + 4);
			end
			v247:GetPropertyChangedSignal("AbsolutePosition"):Connect(v499);
			v269.Inner.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(v500);
			task.spawn(v499);
			task.spawn(v500);
			v18:AddToRegistry(v269.Inner, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
			v269.Show = function(v757)
				v757.Container.Visible = true;
			end;
			v269.Hide = function(v759)
				v759.Container.Visible = false;
			end;
			v269.AddOption = function(v761, v762, v763)
				if (type(v763) ~= "function") then
					function v763()
					end
				end
				local v764 = v18:CreateLabel({Active=false,Size=UDim2.new(1, 0, 0, 15),TextSize=13,Text=v762,ZIndex=16,Parent=v761.Inner,TextXAlignment=Enum.TextXAlignment.Left});
				v18:OnHighlight(v764, v764, {TextColor3="AccentColor"}, {TextColor3="FontColor"});
				v764.InputBegan:Connect(function(v849)
					if (v849.UserInputType ~= Enum.UserInputType.MouseButton1) then
						return;
					end
					v763();
				end);
			end;
			v269:AddOption("Copy color", function()
				v18.ColorClipboard = v245.Value;
				v18:Notify("Copied color!", 2);
			end);
			v269:AddOption("Paste color", function()
				if not v18.ColorClipboard then
					return v18:Notify("You have not copied a color!", 2);
				end
				v245:SetValueRGB(v18.ColorClipboard);
			end);
			v269:AddOption("Copy HEX", function()
				pcall(setclipboard, v245.Value:ToHex());
				v18:Notify("Copied hex code to clipboard!", 2);
			end);
			v269:AddOption("Copy RGB", function()
				pcall(setclipboard, table.concat({math.floor(v245.Value.R * 255),math.floor(v245.Value.G * 255),math.floor(v245.Value.B * 255)}, ", "));
				v18:Notify("Copied RGB values to clipboard!", 2);
			end);
		end
		v18:AddToRegistry(v250, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
		v18:AddToRegistry(v251, {BackgroundColor3="AccentColor"});
		v18:AddToRegistry(v253, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
		v18:AddToRegistry(v261, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
		v18:AddToRegistry(v263.Frame, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
		v18:AddToRegistry(v264, {TextColor3="FontColor"});
		v18:AddToRegistry(v262, {TextColor3="FontColor"});
		local v270 = {};
		for v504 = 0, 1, 0.1 do
			table.insert(v270, ColorSequenceKeypoint.new(v504, Color3.fromHSV(v504, 1, 1)));
		end
		local v271 = v18:Create("UIGradient", {Color=ColorSequence.new(v270),Rotation=90,Parent=v258});
		v262.FocusLost:Connect(function(v505)
			if v505 then
				local v850, v851 = pcall(Color3.fromHex, v262.Text);
				if (v850 and (typeof(v851) == "Color3")) then
					v245.Hue, v245.Sat, v245.Vib = Color3.toHSV(v851);
				end
			end
			v245:Display();
		end);
		v264.FocusLost:Connect(function(v506)
			if v506 then
				local v852, v853, v854 = v264.Text:match("(%d+),%s*(%d+),%s*(%d+)");
				if (v852 and v853 and v854) then
					v245.Hue, v245.Sat, v245.Vib = Color3.toHSV(Color3.fromRGB(v852, v853, v854));
				end
			end
			v245:Display();
		end);
		v245.Display = function(v507)
			v245.Value = Color3.fromHSV(v245.Hue, v245.Sat, v245.Vib);
			v254.BackgroundColor3 = Color3.fromHSV(v245.Hue, 1, 1);
			v18:Create(v247, {BackgroundColor3=v245.Value,BackgroundTransparency=v245.Transparency,BorderColor3=v18:GetDarkerColor(v245.Value)});
			if v266 then
				v266.BackgroundColor3 = v245.Value;
				v267.Position = UDim2.new(1 - v245.Transparency, 0, 0, 0);
			end
			v255.Position = UDim2.new(v245.Sat, 0, 1 - v245.Vib, 0);
			v259.Position = UDim2.new(0, 0, v245.Hue, 0);
			v262.Text = "#" .. v245.Value:ToHex();
			v264.Text = table.concat({math.floor(v245.Value.R * 255),math.floor(v245.Value.G * 255),math.floor(v245.Value.B * 255)}, ", ");
			v18:SafeCallback(v245.Callback, v245.Value);
			v18:SafeCallback(v245.Changed, v245.Value);
		end;
		v245.OnChanged = function(v514, v515)
			v245.Changed = v515;
			v515(v245.Value);
		end;
		v245.Show = function(v517)
			for v767, v768 in next, v18.OpenedFrames do
				if (v767.Name == "Color") then
					v767.Visible = false;
					v18.OpenedFrames[v767] = nil;
				end
			end
			v249.Visible = true;
			v18.OpenedFrames[v249] = true;
		end;
		v245.Hide = function(v520)
			v249.Visible = false;
			v18.OpenedFrames[v249] = nil;
		end;
		v245.SetValue = function(v523, v524, v525)
			local v526 = Color3.fromHSV(v524[1], v524[2], v524[3]);
			v245.Transparency = v525 or 0;
			v245:SetHSVFromRGB(v526);
			v245:Display();
		end;
		v245.SetValueRGB = function(v528, v529, v530)
			v245.Transparency = v530 or 0;
			v245:SetHSVFromRGB(v529);
			v245:Display();
		end;
		v254.InputBegan:Connect(function(v532)
			if (v532.UserInputType == Enum.UserInputType.MouseButton1) then
				while v0:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local v933 = v254.AbsolutePosition.X;
					local v934 = v933 + v254.AbsoluteSize.X;
					local v935 = math.clamp(v9.X, v933, v934);
					local v936 = v254.AbsolutePosition.Y;
					local v937 = v936 + v254.AbsoluteSize.Y;
					local v938 = math.clamp(v9.Y, v936, v937);
					v245.Sat = (v935 - v933) / (v934 - v933);
					v245.Vib = 1 - ((v938 - v936) / (v937 - v936));
					v245:Display();
					v7:Wait();
				end
				v18:AttemptSave();
			end
		end);
		v258.InputBegan:Connect(function(v533)
			if (v533.UserInputType == Enum.UserInputType.MouseButton1) then
				while v0:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local v941 = v258.AbsolutePosition.Y;
					local v942 = v941 + v258.AbsoluteSize.Y;
					local v943 = math.clamp(v9.Y, v941, v942);
					v245.Hue = (v943 - v941) / (v942 - v941);
					v245:Display();
					v7:Wait();
				end
				v18:AttemptSave();
			end
		end);
		v247.InputBegan:Connect(function(v534)
			if ((v534.UserInputType == Enum.UserInputType.MouseButton1) and not v18:MouseIsOverOpenedFrame()) then
				if v249.Visible then
					v245:Hide();
				else
					v269:Hide();
					v245:Show();
				end
			elseif ((v534.UserInputType == Enum.UserInputType.MouseButton2) and not v18:MouseIsOverOpenedFrame()) then
				v269:Show();
				v245:Hide();
			end
		end);
		if v266 then
			v266.InputBegan:Connect(function(v858)
				if (v858.UserInputType == Enum.UserInputType.MouseButton1) then
					while v0:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
						local v1019 = v266.AbsolutePosition.X;
						local v1020 = v1019 + v266.AbsoluteSize.X;
						local v1021 = math.clamp(v9.X, v1019, v1020);
						v245.Transparency = 1 - ((v1021 - v1019) / (v1020 - v1019));
						v245:Display();
						v7:Wait();
					end
					v18:AttemptSave();
				end
			end);
		end
		v18:GiveSignal(v0.InputBegan:Connect(function(v535)
			if (v535.UserInputType == Enum.UserInputType.MouseButton1) then
				local v859, v860 = v249.AbsolutePosition, v249.AbsoluteSize;
				if ((v9.X < v859.X) or (v9.X > (v859.X + v860.X)) or (v9.Y < ((v859.Y - 20) - 1)) or (v9.Y > (v859.Y + v860.Y))) then
					v245:Hide();
				end
				if not v18:IsMouseOverFrame(v269.Container) then
					v269:Hide();
				end
			end
			if ((v535.UserInputType == Enum.UserInputType.MouseButton2) and v269.Container.Visible) then
				if (not v18:IsMouseOverFrame(v269.Container) and not v18:IsMouseOverFrame(v247)) then
					v269:Hide();
				end
			end
		end));
		v245:Display();
		v245.DisplayFrame = v247;
		v15[v242] = v245;
		return v241;
	end;
	v131.AddKeyPicker = function(v280, v281, v282)
		local v283 = v280;
		local v284 = v280.TextLabel;
		local v285 = v280.Container;
		assert(v282.Default, "AddKeyPicker: Missing default value.");
		local v286 = {Value=v282.Default,Toggled=false,Mode=(v282.Mode or "Toggle"),Type="KeyPicker",Callback=(v282.Callback or function(v536)
		end),ChangedCallback=(v282.ChangedCallback or function(v537)
		end),SyncToggleState=(v282.SyncToggleState or false)};
		if v286.SyncToggleState then
			v282.Modes = {"Toggle"};
			v282.Mode = "Toggle";
		end
		local v287 = v18:Create("Frame", {BackgroundColor3=Color3.new(0, 0, 0),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(0, 28, 0, 15),ZIndex=6,Parent=v284});
		local v288 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=7,Parent=v287});
		v18:AddToRegistry(v288, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
		local v289 = v18:CreateLabel({Size=UDim2.new(1, 0, 1, 0),TextSize=13,Text=v282.Default,TextWrapped=true,ZIndex=8,Parent=v288});
		local v290 = v18:Create("Frame", {BorderColor3=Color3.new(0, 0, 0),Position=UDim2.fromOffset(v284.AbsolutePosition.X + v284.AbsoluteSize.X + 4, v284.AbsolutePosition.Y + 1),Size=UDim2.new(0, 60, 0, 45 + 2),Visible=false,ZIndex=14,Parent=v10});
		v284:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			v290.Position = UDim2.fromOffset(v284.AbsolutePosition.X + v284.AbsoluteSize.X + 4, v284.AbsolutePosition.Y + 1);
		end);
		local v291 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=15,Parent=v290});
		v18:AddToRegistry(v291, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
		v18:Create("UIListLayout", {FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v291});
		local v292 = v18:CreateLabel({TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1, 0, 0, 18),TextSize=13,Visible=false,ZIndex=110,Parent=v18.KeybindContainer}, true);
		local v293 = v282.Modes or {"Always","Toggle","Hold"};
		local v294 = {};
		for v539, v540 in next, v293 do
			local v541 = {};
			local v542 = v18:CreateLabel({Active=false,Size=UDim2.new(1, 0, 0, 15),TextSize=13,Text=v540,ZIndex=16,Parent=v291});
			v541.Select = function(v771)
				for v861, v862 in next, v294 do
					v862:Deselect();
				end
				v286.Mode = v540;
				v542.TextColor3 = v18.AccentColor;
				v18.RegistryMap[v542].Properties.TextColor3 = "AccentColor";
				v290.Visible = false;
			end;
			v541.Deselect = function(v777)
				v286.Mode = nil;
				v542.TextColor3 = v18.FontColor;
				v18.RegistryMap[v542].Properties.TextColor3 = "FontColor";
			end;
			v542.InputBegan:Connect(function(v782)
				if (v782.UserInputType == Enum.UserInputType.MouseButton1) then
					v541:Select();
					v18:AttemptSave();
				end
			end);
			if (v540 == v286.Mode) then
				v541:Select();
			end
			v294[v540] = v541;
		end
		v286.Update = function(v546)
			if v282.NoUI then
				return;
			end
			local v547 = v286:GetState();
			v292.Text = string.format("[%s] %s (%s)", v286.Value, v282.Text, v286.Mode);
			v292.Visible = true;
			v292.TextColor3 = (v547 and v18.AccentColor) or v18.FontColor;
			v18.RegistryMap[v292].Properties.TextColor3 = (v547 and "AccentColor") or "FontColor";
			local v552 = 0;
			local v553 = 0;
			for v783, v784 in next, v18.KeybindContainer:GetChildren() do
				if (v784:IsA("TextLabel") and v784.Visible) then
					v552 = v552 + 18;
					if (v784.TextBounds.X > v553) then
						v553 = v784.TextBounds.X;
					end
				end
			end
			v18.KeybindFrame.Size = UDim2.new(0, math.max(v553 + 10, 210), 0, v552 + 23);
		end;
		v286.GetState = function(v555)
			if (v286.Mode == "Always") then
				return true;
			elseif (v286.Mode == "Hold") then
				if (v286.Value == "None") then
					return false;
				end
				local v999 = v286.Value;
				if ((v999 == "MB1") or (v999 == "MB2")) then
					return ((v999 == "MB1") and v0:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) or ((v999 == "MB2") and v0:IsMouseButtonPressed(Enum.UserInputType.MouseButton2));
				else
					return v0:IsKeyDown(Enum.KeyCode[v286.Value]);
				end
			else
				return v286.Toggled;
			end
		end;
		v286.SetValue = function(v556, v557)
			local v558, v559 = v557[1], v557[2];
			v289.Text = v558;
			v286.Value = v558;
			v294[v559]:Select();
			v286:Update();
		end;
		v286.OnClick = function(v562, v563)
			v286.Clicked = v563;
		end;
		v286.OnChanged = function(v565, v566)
			v286.Changed = v566;
			v566(v286.Value);
		end;
		if v283.Addons then
			table.insert(v283.Addons, v286);
		end
		v286.DoClick = function(v568)
			if ((v283.Type == "Toggle") and v286.SyncToggleState) then
				v283:SetValue(not v283.Value);
			end
			v18:SafeCallback(v286.Callback, v286.Toggled);
			v18:SafeCallback(v286.Clicked, v286.Toggled);
		end;
		local v301 = false;
		v287.InputBegan:Connect(function(v569)
			if ((v569.UserInputType == Enum.UserInputType.MouseButton1) and not v18:MouseIsOverOpenedFrame()) then
				v301 = true;
				v289.Text = "";
				local v864;
				local v865 = "";
				task.spawn(function()
					while not v864 do
						if (v865 == "...") then
							v865 = "";
						end
						v865 = v865 .. ".";
						v289.Text = v865;
						wait(0.4);
					end
				end);
				wait(0.2);
				local v866;
				v866 = v0.InputBegan:Connect(function(v945)
					local v946;
					if (v945.UserInputType == Enum.UserInputType.Keyboard) then
						v946 = v945.KeyCode.Name;
					elseif (v945.UserInputType == Enum.UserInputType.MouseButton1) then
						v946 = "MB1";
					elseif (v945.UserInputType == Enum.UserInputType.MouseButton2) then
						v946 = "MB2";
					end
					v864 = true;
					v301 = false;
					v289.Text = v946;
					v286.Value = v946;
					v18:SafeCallback(v286.ChangedCallback, v945.KeyCode or v945.UserInputType);
					v18:SafeCallback(v286.Changed, v945.KeyCode or v945.UserInputType);
					v18:AttemptSave();
					v866:Disconnect();
				end);
			elseif ((v569.UserInputType == Enum.UserInputType.MouseButton2) and not v18:MouseIsOverOpenedFrame()) then
				v290.Visible = true;
			end
		end);
		v18:GiveSignal(v0.InputBegan:Connect(function(v570)
			if not v301 then
				if (v286.Mode == "Toggle") then
					local v1002 = v286.Value;
					if ((v1002 == "MB1") or (v1002 == "MB2")) then
						if (((v1002 == "MB1") and (v570.UserInputType == Enum.UserInputType.MouseButton1)) or ((v1002 == "MB2") and (v570.UserInputType == Enum.UserInputType.MouseButton2))) then
							v286.Toggled = not v286.Toggled;
							v286:DoClick();
						end
					elseif (v570.UserInputType == Enum.UserInputType.Keyboard) then
						if (v570.KeyCode.Name == v1002) then
							v286.Toggled = not v286.Toggled;
							v286:DoClick();
						end
					end
				end
				v286:Update();
			end
			if (v570.UserInputType == Enum.UserInputType.MouseButton1) then
				local v867, v868 = v290.AbsolutePosition, v290.AbsoluteSize;
				if ((v9.X < v867.X) or (v9.X > (v867.X + v868.X)) or (v9.Y < ((v867.Y - 20) - 1)) or (v9.Y > (v867.Y + v868.Y))) then
					v290.Visible = false;
				end
			end
		end));
		v18:GiveSignal(v0.InputEnded:Connect(function(v571)
			if not v301 then
				v286:Update();
			end
		end));
		v286:Update();
		v15[v281] = v286;
		return v280;
	end;
	v44.__index = v131;
	v44.__namecall = function(v303, v304, ...)
		return v131[v304](...);
	end;
end
local v45 = {};
do
	local v136 = {};
	v136.AddBlank = function(v305, v306)
		local v307 = v305;
		local v308 = v307.Container;
		v18:Create("Frame", {BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, v306),ZIndex=1,Parent=v308});
	end;
	v136.AddLabel = function(v309, v310, v311)
		local v312 = {};
		local v313 = v309;
		local v314 = v313.Container;
		local v315 = v18:CreateLabel({Size=UDim2.new(1, -4, 0, 15),TextSize=14,Text=v310,TextWrapped=(v311 or false),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=v314});
		if v311 then
			local v785 = select(2, v18:GetTextBounds(v310, v18.Font, 14, Vector2.new(v315.AbsoluteSize.X, math.huge)));
			v315.Size = UDim2.new(1, -4, 0, v785);
		else
			v18:Create("UIListLayout", {Padding=UDim.new(0, 4),FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v315});
		end
		v312.TextLabel = v315;
		v312.Container = v314;
		v312.SetText = function(v572, v573)
			v315.Text = v573;
			if v311 then
				local v869 = select(2, v18:GetTextBounds(v573, v18.Font, 14, Vector2.new(v315.AbsoluteSize.X, math.huge)));
				v315.Size = UDim2.new(1, -4, 0, v869);
			end
			v313:Resize();
		end;
		if not v311 then
			setmetatable(v312, v44);
		end
		v313:AddBlank(5);
		v313:Resize();
		return v312;
	end;
	v136.AddSpacer = function(v319, v320)
		local v321 = {};
		local v322 = v319;
		local v323 = v322.Container;
		local v324 = v18:Create("Frame", {Size=UDim2.new(1, -4, 0, v320 or 10),BackgroundTransparency=1,Parent=v323,ZIndex=5});
		v321.Frame = v324;
		v321.Container = v323;
		v321.SetHeight = function(v575, v576)
			v324.Size = UDim2.new(1, -4, 0, v576);
			v322:Resize();
		end;
		v322:AddBlank(5);
		v322:Resize();
		return v321;
	end;
	v136.AddButton = function(v328, ...)
		local v329 = {};
		local function v330(v578, v579, ...)
			local v580 = select(1, ...);
			if (type(v580) == "table") then
				v579.Text = v580.Text;
				v579.Func = v580.Func;
				v579.DoubleClick = v580.DoubleClick;
				v579.Tooltip = v580.Tooltip;
			else
				v579.Text = select(1, ...);
				v579.Func = select(2, ...);
			end
			assert(type(v579.Func) == "function", "AddButton: `Func` callback is missing.");
		end
		v330("Button", v329, ...);
		local v331 = v328;
		local v332 = v331.Container;
		local function v333(v581)
			local v582 = v18:Create("Frame", {BackgroundColor3=Color3.new(0, 0, 0),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(1, -4, 0, 20),ZIndex=5});
			local v583 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=6,Parent=v582});
			local v584 = v18:CreateLabel({Size=UDim2.new(1, 0, 1, 0),TextSize=14,Text=v581.Text,ZIndex=6,Parent=v583});
			v18:Create("UIGradient", {Color=ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))}),Rotation=90,Parent=v583});
			v18:AddToRegistry(v582, {BorderColor3="Black"});
			v18:AddToRegistry(v583, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
			v18:OnHighlight(v582, v582, {BorderColor3="AccentColor"}, {BorderColor3="Black"});
			return v582, v583, v584;
		end
		local function v334(v585)
			local function v586(v787, v788, v789)
				local v790 = Instance.new("BindableEvent");
				local v791 = v787:Once(function(...)
					if ((type(v789) == "function") and v789(...)) then
						v790:Fire(true);
					else
						v790:Fire(false);
					end
				end);
				task.delay(v788, function()
					v791:disconnect();
					v790:Fire(false);
				end);
				return v790.Event:Wait();
			end
			local function v587(v792)
				if v18:MouseIsOverOpenedFrame() then
					return false;
				end
				if (v792.UserInputType ~= Enum.UserInputType.MouseButton1) then
					return false;
				end
				return true;
			end
			v585.Outer.InputBegan:Connect(function(v793)
				if not v587(v793) then
					return;
				end
				if v585.Locked then
					return;
				end
				if v585.DoubleClick then
					v18:RemoveFromRegistry(v585.Label);
					v18:AddToRegistry(v585.Label, {TextColor3="AccentColor"});
					v585.Label.TextColor3 = v18.AccentColor;
					v585.Label.Text = "Are you sure?";
					v585.Locked = true;
					local v953 = v586(v585.Outer.InputBegan, 0.5, v587);
					v18:RemoveFromRegistry(v585.Label);
					v18:AddToRegistry(v585.Label, {TextColor3="FontColor"});
					v585.Label.TextColor3 = v18.FontColor;
					v585.Label.Text = v585.Text;
					task.defer(rawset, v585, "Locked", false);
					if v953 then
						v18:SafeCallback(v585.Func);
					end
					return;
				end
				v18:SafeCallback(v585.Func);
			end);
		end
		v329.Outer, v329.Inner, v329.Label = v333(v329);
		v329.Outer.Parent = v332;
		v334(v329);
		v329.AddTooltip = function(v588, v589)
			if (type(v589) == "string") then
				v18:AddToolTip(v589, v588.Outer);
			end
			return v588;
		end;
		v329.AddButton = function(v590, ...)
			local v591 = {};
			v330("SubButton", v591, ...);
			v590.Outer.Size = UDim2.new(0.5, -2, 0, 20);
			v591.Outer, v591.Inner, v591.Label = v333(v591);
			v591.Outer.Position = UDim2.new(1, 3, 0, 0);
			v591.Outer.Size = UDim2.fromOffset(v590.Outer.AbsoluteSize.X - 2, v590.Outer.AbsoluteSize.Y);
			v591.Outer.Parent = v590.Outer;
			v591.AddTooltip = function(v794, v795)
				if (type(v795) == "string") then
					v18:AddToolTip(v795, v794.Outer);
				end
				return v591;
			end;
			if (type(v591.Tooltip) == "string") then
				v591:AddTooltip(v591.Tooltip);
			end
			v334(v591);
			return v591;
		end;
		if (type(v329.Tooltip) == "string") then
			v329:AddTooltip(v329.Tooltip);
		end
		v331:AddBlank(5);
		v331:Resize();
		return v329;
	end;
	v136.AddDivider = function(v341)
		local v342 = v341;
		local v343 = v341.Container;
		local v344 = {Type="Divider"};
		v342:AddBlank(2);
		local v345 = v18:Create("Frame", {BackgroundColor3=Color3.new(0, 0, 0),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(1, -4, 0, 5),ZIndex=5,Parent=v343});
		local v346 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=6,Parent=v345});
		v18:AddToRegistry(v345, {BorderColor3="Black"});
		v18:AddToRegistry(v346, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
		v342:AddBlank(9);
		v342:Resize();
	end;
	v136.AddInput = function(v347, v348, v349)
		assert(v349.Text, "AddInput: Missing `Text` string.");
		local v350 = {Value=(v349.Default or ""),Numeric=(v349.Numeric or false),Finished=(v349.Finished or false),Type="Input",Callback=(v349.Callback or function(v601)
		end)};
		local v351 = v347;
		local v352 = v351.Container;
		local v353 = v18:CreateLabel({Size=UDim2.new(1, 0, 0, 15),TextSize=14,Text=v349.Text,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5,Parent=v352});
		v351:AddBlank(1);
		local v354 = v18:Create("Frame", {BackgroundColor3=Color3.new(0, 0, 0),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(1, -4, 0, 20),ZIndex=5,Parent=v352});
		local v355 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=6,Parent=v354});
		v18:AddToRegistry(v355, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
		v18:OnHighlight(v354, v354, {BorderColor3="AccentColor"}, {BorderColor3="Black"});
		if (type(v349.Tooltip) == "string") then
			v18:AddToolTip(v349.Tooltip, v354);
		end
		v18:Create("UIGradient", {Color=ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))}),Rotation=90,Parent=v355});
		local v352 = v18:Create("Frame", {BackgroundTransparency=1,ClipsDescendants=true,Position=UDim2.new(0, 5, 0, 0),Size=UDim2.new(1, -5, 1, 0),ZIndex=7,Parent=v355});
		local v356 = v18:Create("TextBox", {BackgroundTransparency=1,Position=UDim2.fromOffset(0, 0),Size=UDim2.fromScale(5, 1),Font=v18.Font,PlaceholderColor3=Color3.fromRGB(190, 190, 190),PlaceholderText=(v349.Placeholder or ""),Text=(v349.Default or ""),TextColor3=v18.FontColor,TextSize=14,TextStrokeTransparency=0,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=v352});
		v18:ApplyTextStroke(v356);
		v350.SetValue = function(v602, v603)
			if (v349.MaxLength and (#v603 > v349.MaxLength)) then
				v603 = v603:sub(1, v349.MaxLength);
			end
			if v350.Numeric then
				if (not tonumber(v603) and (v603:len() > 0)) then
					v603 = v350.Value;
				end
			end
			v350.Value = v603;
			v356.Text = v603;
			v18:SafeCallback(v350.Callback, v350.Value);
			v18:SafeCallback(v350.Changed, v350.Value);
		end;
		if v350.Finished then
			v356.FocusLost:Connect(function(v881)
				if not v881 then
					return;
				end
				v350:SetValue(v356.Text);
				v18:AttemptSave();
			end);
		else
			v356:GetPropertyChangedSignal("Text"):Connect(function()
				v350:SetValue(v356.Text);
				v18:AttemptSave();
			end);
		end
		local function v358()
			local v606 = 2;
			local v607 = v352.AbsoluteSize.X;
			if (not v356:IsFocused() or (v356.TextBounds.X <= (v607 - (2 * v606)))) then
				v356.Position = UDim2.new(0, v606, 0, 0);
			else
				local v883 = v356.CursorPosition;
				if (v883 ~= -1) then
					local v1005 = string.sub(v356.Text, 1, v883 - 1);
					local v1006 = v1:GetTextSize(v1005, v356.TextSize, v356.Font, Vector2.new(math.huge, math.huge)).X;
					local v1007 = v356.Position.X.Offset + v1006;
					if (v1007 < v606) then
						v356.Position = UDim2.fromOffset(v606 - v1006, 0);
					elseif (v1007 > ((v607 - v606) - 1)) then
						v356.Position = UDim2.fromOffset(((v607 - v1006) - v606) - 1, 0);
					end
				end
			end
		end
		task.spawn(v358);
		v356:GetPropertyChangedSignal("Text"):Connect(v358);
		v356:GetPropertyChangedSignal("CursorPosition"):Connect(v358);
		v356.FocusLost:Connect(v358);
		v356.Focused:Connect(v358);
		v18:AddToRegistry(v356, {TextColor3="FontColor"});
		v350.OnChanged = function(v608, v609)
			v350.Changed = v609;
			v609(v350.Value);
		end;
		v351:AddBlank(5);
		v351:Resize();
		v15[v348] = v350;
		return v350;
	end;
	v136.AddToggle = function(v361, v362, v363)
		assert(v363.Text, "AddInput: Missing `Text` string.");
		local v364 = {Value=(v363.Default or false),Type="Toggle",Callback=(v363.Callback or function(v611)
		end),Addons={},Risky=v363.Risky};
		local v365 = v361;
		local v366 = v365.Container;
		local v367 = v18:Create("Frame", {BackgroundColor3=Color3.new(0, 0, 0),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(0, 13, 0, 13),ZIndex=5,Parent=v366});
		v18:AddToRegistry(v367, {BorderColor3="Black"});
		local v368 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=6,Parent=v367});
		v18:AddToRegistry(v368, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
		local v369 = v18:CreateLabel({Size=UDim2.new(0, 216, 1, 0),Position=UDim2.new(1, 6, 0, 0),TextSize=14,Text=v363.Text,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6,Parent=v368});
		v18:Create("UIListLayout", {Padding=UDim.new(0, 4),FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v369});
		local v370 = v18:Create("Frame", {BackgroundTransparency=1,Size=UDim2.new(0, 170, 1, 0),ZIndex=8,Parent=v367});
		v18:OnHighlight(v370, v367, {BorderColor3="AccentColor"}, {BorderColor3="Black"});
		v364.UpdateColors = function(v612)
			v364:Display();
		end;
		if (type(v363.Tooltip) == "string") then
			v18:AddToolTip(v363.Tooltip, v370);
		end
		v364.Display = function(v613)
			v368.BackgroundColor3 = (v364.Value and v18.AccentColor) or v18.MainColor;
			v368.BorderColor3 = (v364.Value and v18.AccentColorDark) or v18.OutlineColor;
			v18.RegistryMap[v368].Properties.BackgroundColor3 = (v364.Value and "AccentColor") or "MainColor";
			v18.RegistryMap[v368].Properties.BorderColor3 = (v364.Value and "AccentColorDark") or "OutlineColor";
		end;
		v364.OnChanged = function(v618, v619)
			v364.Changed = v619;
			v619(v364.Value);
		end;
		v364.SetValue = function(v621, v622)
			v622 = not not v622;
			v364.Value = v622;
			v364:Display();
			for v796, v797 in next, v364.Addons do
				if ((v797.Type == "KeyPicker") and v797.SyncToggleState) then
					v797.Toggled = v622;
					v797:Update();
				end
			end
			v18:SafeCallback(v364.Callback, v364.Value);
			v18:SafeCallback(v364.Changed, v364.Value);
			v18:UpdateDependencyBoxes();
		end;
		v370.InputBegan:Connect(function(v624)
			if ((v624.UserInputType == Enum.UserInputType.MouseButton1) and not v18:MouseIsOverOpenedFrame()) then
				v364:SetValue(not v364.Value);
				v18:AttemptSave();
			end
		end);
		if v364.Risky then
			v18:RemoveFromRegistry(v369);
			v369.TextColor3 = v18.RiskColor;
			v18:AddToRegistry(v369, {TextColor3="RiskColor"});
		end
		v364:Display();
		v365:AddBlank(v363.BlankSize or (5 + 2));
		v365:Resize();
		v364.TextLabel = v369;
		v364.Container = v366;
		setmetatable(v364, v44);
		v14[v362] = v364;
		v18:UpdateDependencyBoxes();
		return v364;
	end;
	v136.AddSlider = function(v378, v379, v380)
		assert(v380.Default, "AddSlider: Missing default value.");
		assert(v380.Text, "AddSlider: Missing slider text.");
		assert(v380.Min, "AddSlider: Missing minimum value.");
		assert(v380.Max, "AddSlider: Missing maximum value.");
		assert(v380.Rounding, "AddSlider: Missing rounding value.");
		local v381 = {Value=v380.Default,Min=v380.Min,Max=v380.Max,Rounding=v380.Rounding,MaxSize=232,Type="Slider",Callback=(v380.Callback or function(v625)
		end)};
		local v382 = v378;
		local v383 = v382.Container;
		if not v380.Compact then
			v18:CreateLabel({Size=UDim2.new(1, 0, 0, 10),TextSize=14,Text=v380.Text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Bottom,ZIndex=5,Parent=v383});
			v382:AddBlank(3);
		end
		local v384 = v18:Create("Frame", {BackgroundColor3=Color3.new(0, 0, 0),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(1, -4, 0, 13),ZIndex=5,Parent=v383});
		v18:AddToRegistry(v384, {BorderColor3="Black"});
		local v385 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=6,Parent=v384});
		v18:AddToRegistry(v385, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
		local v386 = v18:Create("Frame", {BackgroundColor3=v18.AccentColor,BorderColor3=v18.AccentColorDark,Size=UDim2.new(0, 0, 1, 0),ZIndex=7,Parent=v385});
		v18:AddToRegistry(v386, {BackgroundColor3="AccentColor",BorderColor3="AccentColorDark"});
		local v387 = v18:Create("Frame", {BackgroundColor3=v18.AccentColor,BorderSizePixel=0,Position=UDim2.new(1, 0, 0, 0),Size=UDim2.new(0, 1, 1, 0),ZIndex=8,Parent=v386});
		v18:AddToRegistry(v387, {BackgroundColor3="AccentColor"});
		local v388 = v18:CreateLabel({Size=UDim2.new(1, 0, 1, 0),TextSize=14,Text="Infinite",ZIndex=9,Parent=v385});
		v18:OnHighlight(v384, v384, {BorderColor3="AccentColor"}, {BorderColor3="Black"});
		if (type(v380.Tooltip) == "string") then
			v18:AddToolTip(v380.Tooltip, v384);
		end
		v381.UpdateColors = function(v626)
			v386.BackgroundColor3 = v18.AccentColor;
			v386.BorderColor3 = v18.AccentColorDark;
		end;
		v381.Display = function(v631)
			local v632 = v380.Suffix or "";
			if v380.Compact then
				v388.Text = v380.Text .. ": " .. v381.Value .. v632;
			elseif v380.HideMax then
				v388.Text = string.format("%s", v381.Value .. v632);
			else
				v388.Text = string.format("%s/%s", v381.Value .. v632, v381.Max .. v632);
			end
			local v633 = math.ceil(v18:MapValue(v381.Value, v381.Min, v381.Max, 0, v381.MaxSize));
			v386.Size = UDim2.new(0, v633, 1, 0);
			v387.Visible = not ((v633 == v381.MaxSize) or (v633 == 0));
		end;
		v381.OnChanged = function(v636, v637)
			v381.Changed = v637;
			v637(v381.Value);
		end;
		local function v392(v639)
			if (v381.Rounding == 0) then
				return math.floor(v639);
			end
			return tonumber(string.format("%." .. v381.Rounding .. "f", v639));
		end
		v381.GetValueFromXOffset = function(v640, v641)
			return v392(v18:MapValue(v641, 0, v381.MaxSize, v381.Min, v381.Max));
		end;
		v381.SetValue = function(v642, v643)
			local v644 = tonumber(v643);
			if not v644 then
				return;
			end
			v644 = math.clamp(v644, v381.Min, v381.Max);
			v381.Value = v644;
			v381:Display();
			v18:SafeCallback(v381.Callback, v381.Value);
			v18:SafeCallback(v381.Changed, v381.Value);
		end;
		v385.InputBegan:Connect(function(v646)
			if ((v646.UserInputType == Enum.UserInputType.MouseButton1) and not v18:MouseIsOverOpenedFrame()) then
				local v885 = v9.X;
				local v886 = v386.Size.X.Offset;
				local v887 = v885 - (v386.AbsolutePosition.X + v886);
				while v0:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local v957 = v9.X;
					local v958 = math.clamp(v886 + (v957 - v885) + v887, 0, v381.MaxSize);
					local v959 = v381:GetValueFromXOffset(v958);
					local v960 = v381.Value;
					v381.Value = v959;
					v381:Display();
					if (v959 ~= v960) then
						v18:SafeCallback(v381.Callback, v381.Value);
						v18:SafeCallback(v381.Changed, v381.Value);
					end
					v7:Wait();
				end
				v18:AttemptSave();
			end
		end);
		v381:Display();
		v382:AddBlank(v380.BlankSize or 6);
		v382:Resize();
		v15[v379] = v381;
		return v381;
	end;
	v136.AddDropdown = function(v396, v397, v398)
		if (v398.SpecialType == "Player") then
			v398.Values = v21();
			v398.AllowNull = true;
		elseif (v398.SpecialType == "Team") then
			v398.Values = v22();
			v398.AllowNull = true;
		end
		assert(v398.Values, "AddDropdown: Missing dropdown value list.");
		assert(v398.AllowNull or v398.Default, "AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.");
		if not v398.Text then
			v398.Compact = true;
		end
		local v399 = {Values=v398.Values,Value=(v398.Multi and {}),Multi=v398.Multi,Type="Dropdown",SpecialType=v398.SpecialType,Callback=(v398.Callback or function(v647)
		end)};
		local v400 = v396;
		local v401 = v400.Container;
		local v402 = 0;
		if not v398.Compact then
			local v803 = v18:CreateLabel({Size=UDim2.new(1, 0, 0, 10),TextSize=14,Text=v398.Text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Bottom,ZIndex=5,Parent=v401});
			v400:AddBlank(3);
		end
		for v648, v649 in next, v401:GetChildren() do
			if not v649:IsA("UIListLayout") then
				v402 = v402 + v649.Size.Y.Offset;
			end
		end
		local v403 = v18:Create("Frame", {BackgroundColor3=Color3.new(0, 0, 0),BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(1, -4, 0, 20),ZIndex=5,Parent=v401});
		v18:AddToRegistry(v403, {BorderColor3="Black"});
		local v404 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=6,Parent=v403});
		v18:AddToRegistry(v404, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
		v18:Create("UIGradient", {Color=ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))}),Rotation=90,Parent=v404});
		local v405 = v18:Create("ImageLabel", {AnchorPoint=Vector2.new(0, 0.5),BackgroundTransparency=1,Position=UDim2.new(1, -16, 0.5, 0),Size=UDim2.new(0, 12, 0, 12),Image="http://www.roblox.com/asset/?id=6282522798",ZIndex=8,Parent=v404});
		local v406 = v18:CreateLabel({Position=UDim2.new(0, 5, 0, 0),Size=UDim2.new(1, -5, 1, 0),TextSize=14,Text="--",TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=7,Parent=v404});
		v18:OnHighlight(v403, v403, {BorderColor3="AccentColor"}, {BorderColor3="Black"});
		if (type(v398.Tooltip) == "string") then
			v18:AddToolTip(v398.Tooltip, v403);
		end
		local v407 = 8;
		local v408 = v18:Create("Frame", {BackgroundColor3=Color3.new(0, 0, 0),BorderColor3=Color3.new(0, 0, 0),ZIndex=20,Visible=false,Parent=v10});
		local function v409()
			v408.Position = UDim2.fromOffset(v403.AbsolutePosition.X, v403.AbsolutePosition.Y + v403.Size.Y.Offset + 1);
		end
		local function v410(v651)
			v408.Size = UDim2.fromOffset(v403.AbsoluteSize.X, v651 or ((v407 * 20) + 2));
		end
		v409();
		v410();
		v403:GetPropertyChangedSignal("AbsolutePosition"):Connect(v409);
		local v411 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,BorderSizePixel=0,Size=UDim2.new(1, 0, 1, 0),ZIndex=21,Parent=v408});
		v18:AddToRegistry(v411, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
		local v412 = v18:Create("ScrollingFrame", {BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 1, 0),ZIndex=21,Parent=v411,TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",ScrollBarThickness=3,ScrollBarImageColor3=v18.AccentColor});
		v18:AddToRegistry(v412, {ScrollBarImageColor3="AccentColor"});
		v18:Create("UIListLayout", {Padding=UDim.new(0, 0),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v412});
		v399.Display = function(v653)
			local v654 = v399.Values;
			local v655 = "";
			if v398.Multi then
				for v964, v965 in next, v654 do
					if v399.Value[v965] then
						v655 = v655 .. v965 .. ", ";
					end
				end
				v655 = v655:sub(1, #v655 - 2);
			else
				v655 = v399.Value or "";
			end
			v406.Text = ((v655 == "") and "--") or v655;
		end;
		v399.GetActiveValues = function(v657)
			if v398.Multi then
				local v888 = {};
				for v966, v967 in next, v399.Value do
					table.insert(v888, v966);
				end
				return v888;
			else
				return (v399.Value and 1) or 0;
			end
		end;
		v399.BuildDropdownList = function(v658)
			local v659 = v399.Values;
			local v660 = {};
			for v804, v805 in next, v412:GetChildren() do
				if not v805:IsA("UIListLayout") then
					v805:Destroy();
				end
			end
			local v661 = 0;
			for v806, v807 in next, v659 do
				local v808 = {};
				v661 = v661 + 1;
				local v809 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Middle,Size=UDim2.new(1, -1, 0, 20),ZIndex=23,Active=true,Parent=v412});
				v18:AddToRegistry(v809, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
				local v810 = v18:CreateLabel({Active=false,Size=UDim2.new(1, -6, 1, 0),Position=UDim2.new(0, 6, 0, 0),TextSize=14,Text=v807,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=25,Parent=v809});
				v18:OnHighlight(v809, v809, {BorderColor3="AccentColor",ZIndex=24}, {BorderColor3="OutlineColor",ZIndex=23});
				local v811;
				if v398.Multi then
					v811 = v399.Value[v807];
				else
					v811 = v399.Value == v807;
				end
				v808.UpdateButton = function(v889)
					if v398.Multi then
						v811 = v399.Value[v807];
					else
						v811 = v399.Value == v807;
					end
					v810.TextColor3 = (v811 and v18.AccentColor) or v18.FontColor;
					v18.RegistryMap[v810].Properties.TextColor3 = (v811 and "AccentColor") or "FontColor";
				end;
				v810.InputBegan:Connect(function(v892)
					if (v892.UserInputType == Enum.UserInputType.MouseButton1) then
						local v1011 = not v811;
						if ((v399:GetActiveValues() == 1) and not v1011 and not v398.AllowNull) then
						else
							if v398.Multi then
								v811 = v1011;
								if v811 then
									v399.Value[v807] = true;
								else
									v399.Value[v807] = nil;
								end
							else
								v811 = v1011;
								if v811 then
									v399.Value = v807;
								else
									v399.Value = nil;
								end
								for v1031, v1032 in next, v660 do
									v1032:UpdateButton();
								end
							end
							v808:UpdateButton();
							v399:Display();
							v18:SafeCallback(v399.Callback, v399.Value);
							v18:SafeCallback(v399.Changed, v399.Value);
							v18:AttemptSave();
						end
					end
				end);
				v808:UpdateButton();
				v399:Display();
				v660[v809] = v808;
			end
			v412.CanvasSize = UDim2.fromOffset(0, (v661 * 20) + 1);
			local v663 = math.clamp(v661 * 20, 0, v407 * 20) + 1;
			v410(v663);
		end;
		v399.SetValues = function(v664, v665)
			if v665 then
				v399.Values = v665;
			end
			v399:BuildDropdownList();
		end;
		v399.OpenDropdown = function(v666)
			v408.Visible = true;
			v18.OpenedFrames[v408] = true;
			v405.Rotation = 180;
		end;
		v399.CloseDropdown = function(v670)
			v408.Visible = false;
			v18.OpenedFrames[v408] = nil;
			v405.Rotation = 0;
		end;
		v399.OnChanged = function(v674, v675)
			v399.Changed = v675;
			v675(v399.Value);
		end;
		v399.SetValue = function(v677, v678)
			if v399.Multi then
				local v894 = {};
				for v969, v970 in next, v678 do
					if table.find(v399.Values, v969) then
						v894[v969] = true;
					end
				end
				v399.Value = v894;
			elseif not v678 then
				v399.Value = nil;
			elseif table.find(v399.Values, v678) then
				v399.Value = v678;
			end
			v399:BuildDropdownList();
			v18:SafeCallback(v399.Callback, v399.Value);
			v18:SafeCallback(v399.Changed, v399.Value);
		end;
		v403.InputBegan:Connect(function(v679)
			if ((v679.UserInputType == Enum.UserInputType.MouseButton1) and not v18:MouseIsOverOpenedFrame()) then
				if v408.Visible then
					v399:CloseDropdown();
				else
					v399:OpenDropdown();
				end
			end
		end);
		v0.InputBegan:Connect(function(v680)
			if (v680.UserInputType == Enum.UserInputType.MouseButton1) then
				local v896, v897 = v408.AbsolutePosition, v408.AbsoluteSize;
				if ((v9.X < v896.X) or (v9.X > (v896.X + v897.X)) or (v9.Y < ((v896.Y - 20) - 1)) or (v9.Y > (v896.Y + v897.Y))) then
					v399:CloseDropdown();
				end
			end
		end);
		v399:BuildDropdownList();
		v399:Display();
		local v421 = {};
		if (type(v398.Default) == "string") then
			local v814 = table.find(v399.Values, v398.Default);
			if v814 then
				table.insert(v421, v814);
			end
		elseif (type(v398.Default) == "table") then
			for v1013, v1014 in next, v398.Default do
				local v1015 = table.find(v399.Values, v1014);
				if v1015 then
					table.insert(v421, v1015);
				end
			end
		elseif ((type(v398.Default) == "number") and (v399.Values[v398.Default] ~= nil)) then
			table.insert(v421, v398.Default);
		end
		if next(v421) then
			for v898 = 1, #v421 do
				local v899 = v421[v898];
				if v398.Multi then
					v399.Value[v399.Values[v899]] = true;
				else
					v399.Value = v399.Values[v899];
				end
				if not v398.Multi then
					break;
				end
			end
			v399:BuildDropdownList();
			v399:Display();
		end
		v400:AddBlank(v398.BlankSize or 5);
		v400:Resize();
		v15[v397] = v399;
		return v399;
	end;
	v136.AddDependencyBox = function(v423)
		local v424 = {Dependencies={}};
		local v425 = v423;
		local v426 = v425.Container;
		local v427 = v18:Create("Frame", {BackgroundTransparency=1,Size=UDim2.new(1, 0, 0, 0),Visible=false,Parent=v426});
		local v428 = v18:Create("Frame", {BackgroundTransparency=1,Size=UDim2.new(1, 0, 1, 0),Visible=true,Parent=v427});
		local v429 = v18:Create("UIListLayout", {FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v428});
		v424.Resize = function(v681)
			v427.Size = UDim2.new(1, 0, 0, v429.AbsoluteContentSize.Y);
			v425:Resize();
		end;
		v429:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			v424:Resize();
		end);
		v427:GetPropertyChangedSignal("Visible"):Connect(function()
			v424:Resize();
		end);
		v424.Update = function(v683)
			for v815, v816 in next, v424.Dependencies do
				local v817 = v816[1];
				local v818 = v816[2];
				if ((v817.Type == "Toggle") and (v817.Value ~= v818)) then
					v427.Visible = false;
					v424:Resize();
					return;
				end
			end
			v427.Visible = true;
			v424:Resize();
		end;
		v424.SetupDependencies = function(v685, v686)
			for v819, v820 in next, v686 do
				assert(type(v820) == "table", "SetupDependencies: Dependency is not of type `table`.");
				assert(v820[1], "SetupDependencies: Dependency is missing element argument.");
				assert(v820[2] ~= nil, "SetupDependencies: Dependency is missing value argument.");
			end
			v424.Dependencies = v686;
			v424:Update();
		end;
		v424.Container = v428;
		setmetatable(v424, v45);
		table.insert(v18.DependencyBoxes, v424);
		return v424;
	end;
	v45.__index = v136;
	v45.__namecall = function(v434, v435, ...)
		return v136[v435](...);
	end;
end
do
	v18.NotificationArea = v18:Create("Frame", {BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 40),Size=UDim2.new(0, 300, 0, 200),ZIndex=100,Parent=v10});
	v18:Create("UIListLayout", {Padding=UDim.new(0, 4),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v18.NotificationArea});
	local v150 = v18:Create("Frame", {BorderColor3=Color3.new(0, 0, 0),Position=UDim2.new(0, 100, 0, -25),Size=UDim2.new(0, 213, 0, 20),ZIndex=200,Visible=false,Parent=v10});
	local v151 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.AccentColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=201,Parent=v150});
	v18:AddToRegistry(v151, {BorderColor3="AccentColor"});
	local v152 = v18:Create("Frame", {BackgroundColor3=Color3.new(1, 1, 1),BorderSizePixel=0,Position=UDim2.new(0, 1, 0, 1),Size=UDim2.new(1, -2, 1, -2),ZIndex=202,Parent=v151});
	local v153 = v18:Create("UIGradient", {Color=ColorSequence.new({ColorSequenceKeypoint.new(0, v18:GetDarkerColor(v18.MainColor)),ColorSequenceKeypoint.new(1, v18.MainColor)}),Rotation=-90,Parent=v152});
	v18:AddToRegistry(v153, {Color=function()
		return ColorSequence.new({ColorSequenceKeypoint.new(0, v18:GetDarkerColor(v18.MainColor)),ColorSequenceKeypoint.new(1, v18.MainColor)});
	end});
	local v154 = v18:CreateLabel({Position=UDim2.new(0, 5, 0, 0),Size=UDim2.new(1, -4, 1, 0),TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=203,Parent=v152});
	v18.Watermark = v150;
	v18.WatermarkText = v154;
	v18:MakeDraggable(v18.Watermark);
	local v157 = v18:Create("Frame", {AnchorPoint=Vector2.new(0, 0.5),BorderColor3=Color3.new(0, 0, 0),Position=UDim2.new(0, 10, 0.5, 0),Size=UDim2.new(0, 210, 0, 20),Visible=false,ZIndex=100,Parent=v10});
	local v158 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=101,Parent=v157});
	v18:AddToRegistry(v158, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"}, true);
	local v159 = v18:Create("Frame", {BackgroundColor3=v18.AccentColor,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 2),ZIndex=102,Parent=v158});
	v18:AddToRegistry(v159, {BackgroundColor3="AccentColor"}, true);
	local v160 = v18:CreateLabel({Size=UDim2.new(1, 0, 0, 20),Position=UDim2.fromOffset(5, 2),TextXAlignment=Enum.TextXAlignment.Left,Text="Keybinds",ZIndex=104,Parent=v158});
	local v161 = v18:Create("Frame", {BackgroundTransparency=1,Size=UDim2.new(1, 0, 1, -20),Position=UDim2.new(0, 0, 0, 20),ZIndex=1,Parent=v158});
	v18:Create("UIListLayout", {FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v161});
	v18:Create("UIPadding", {PaddingLeft=UDim.new(0, 5),Parent=v161});
	v18.KeybindFrame = v157;
	v18.KeybindContainer = v161;
	v18:MakeDraggable(v157);
end
v18.SetWatermarkVisibility = function(v164, v165)
	v18.Watermark.Visible = v165;
end;
v18.SetWatermark = function(v167, v168)
	local v169, v170 = v18:GetTextBounds(v168, v18.Font, 14);
	v18.Watermark.Size = UDim2.new(0, v169 + 15, 0, (v170 * 1.5) + 3);
	v18:SetWatermarkVisibility(true);
	v18.WatermarkText.Text = v168;
end;
v18.Notify = function(v173, v174, v175)
	local v176, v177 = v18:GetTextBounds(v174, v18.Font, 14);
	v177 = v177 + 7;
	local v178 = v18:Create("Frame", {BorderColor3=Color3.new(0, 0, 0),Position=UDim2.new(0, 100, 0, 10),Size=UDim2.new(0, 0, 0, v177),ClipsDescendants=true,ZIndex=100,Parent=v18.NotificationArea});
	local v179 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 1, 0),ZIndex=101,Parent=v178});
	v18:AddToRegistry(v179, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"}, true);
	local v180 = v18:Create("Frame", {BackgroundColor3=Color3.new(1, 1, 1),BorderSizePixel=0,Position=UDim2.new(0, 1, 0, 1),Size=UDim2.new(1, -2, 1, -2),ZIndex=102,Parent=v179});
	local v181 = v18:Create("UIGradient", {Color=ColorSequence.new({ColorSequenceKeypoint.new(0, v18:GetDarkerColor(v18.MainColor)),ColorSequenceKeypoint.new(1, v18.MainColor)}),Rotation=-90,Parent=v180});
	v18:AddToRegistry(v181, {Color=function()
		return ColorSequence.new({ColorSequenceKeypoint.new(0, v18:GetDarkerColor(v18.MainColor)),ColorSequenceKeypoint.new(1, v18.MainColor)});
	end});
	local v182 = v18:CreateLabel({Position=UDim2.new(0, 4, 0, 0),Size=UDim2.new(1, -4, 1, 0),Text=v174,TextXAlignment=Enum.TextXAlignment.Left,TextSize=14,ZIndex=103,Parent=v180});
	local v183 = v18:Create("Frame", {BackgroundColor3=v18.AccentColor,BorderSizePixel=0,Position=UDim2.new(0, -1, 0, -1),Size=UDim2.new(0, 3, 1, 2),ZIndex=104,Parent=v178});
	v18:AddToRegistry(v183, {BackgroundColor3="AccentColor"}, true);
	pcall(v178.TweenSize, v178, UDim2.new(0, v176 + 8 + 4, 0, v177), "Out", "Quad", 0.4, true);
	task.spawn(function()
		wait(v175 or 5);
		pcall(v178.TweenSize, v178, UDim2.new(0, 0, 0, v177), "Out", "Quad", 0.4, true);
		wait(0.4);
		v178:Destroy();
	end);
end;
v18.CreateWindow = function(v184, ...)
	local v185 = {...};
	local v186 = {AnchorPoint=Vector2.zero};
	if (type(...) == "table") then
		v186 = ...;
	else
		v186.Title = v185[1];
		v186.Version = v185[2];
		v186.AutoShow = v185[3] or false;
	end
	if (type(v186.Title) ~= "string") then
		v186.Title = "No title";
	end
	if (type(v186.Version) ~= "string") then
		v186.Version = "";
	end
	if (type(v186.MenuFadeTime) ~= "number") then
		v186.MenuFadeTime = 0.2;
	end
	if (typeof(v186.Position) ~= "UDim2") then
		v186.Position = UDim2.fromOffset(175, 50);
	end
	if (type(v186.Size) ~= "UDim2") then
		v186.Size = UDim2.fromOffset(550, 570);
	end
	if v186.Center then
		v186.AnchorPoint = Vector2.new(0.5, 0.5);
		v186.Position = UDim2.fromScale(0.5, 0.5);
	end
	local v187 = {Tabs={}};
	local v188 = v18:Create("Frame", {AnchorPoint=v186.AnchorPoint,BackgroundColor3=Color3.new(0, 0, 0),BorderSizePixel=0,Position=v186.Position,Size=v186.Size,Visible=false,ZIndex=1,Parent=v10});
	local v189 = UDim2.new(v186.Size.X.Scale, v186.Size.X.Offset + 57, v186.Size.Y.Scale, v186.Size.Y.Offset + 57);
	local v190 = v18:Create("ImageLabel", {AnchorPoint=v186.AnchorPoint,BackgroundTransparency=1,Position=v186.Position,Size=v189,Image="rbxassetid://6015897843",ImageColor3=v18.AccentColor,ImageTransparency=0,ZIndex=1,Parent=v188,BackgroundColor3=Color3.fromRGB(255, 255, 255),BorderColor3=Color3.fromRGB(0, 0, 0),BorderSizePixel=0});
	v18:MakeDraggable(v188, 25);
	local v191 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.AccentColor,BorderMode=Enum.BorderMode.Inset,Position=UDim2.new(0, 1, 0, 1),Size=UDim2.new(1, -2, 1, -2),ZIndex=1,Parent=v188});
	v18:AddToRegistry(v191, {BackgroundColor3="MainColor",BorderColor3="AccentColor"});
	v18:AddToRegistry(v190, {ImageColor3="AccentColor"});
	local v192 = v18:CreateLabel({Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 0, 25),Text=function()
		if (v186.Version and (v186.Version ~= "")) then
			return v186.Title .. " | v" .. v186.Version;
		else
			return v186.Title;
		end
	end(),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=1,Parent=v191,RichText=true});
	local v193 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,Position=UDim2.new(0, 8, 0, 25),Size=UDim2.new(1, -16, 1, -33),ZIndex=1,Parent=v191});
	v18:AddToRegistry(v193, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
	local v194 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=Color3.new(0, 0, 0),BorderMode=Enum.BorderMode.Inset,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 1, 0),ZIndex=1,Parent=v193});
	v18:AddToRegistry(v194, {BackgroundColor3="BackgroundColor"});
	local v195 = v18:Create("Frame", {BackgroundTransparency=1,Position=UDim2.new(0, 8, 0, 8),Size=UDim2.new(1, -16, 0, 40),ZIndex=1,Parent=v194});
	local v196 = v18:Create("UIListLayout", {Padding=UDim.new(0, 0),FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v195});
	local v197 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=v18.OutlineColor,Position=UDim2.new(0, 8, 0, 54),Size=UDim2.new(1, -16, 1, -60),ZIndex=2,Parent=v194});
	v18:AddToRegistry(v197, {BackgroundColor3="MainColor",BorderColor3="OutlineColor"});
	v187.SetWindowTitle = function(v436, v437)
		v192.Text = v437;
	end;
	local function v199()
		local v439 = #v187.Tabs;
		if (v439 == 0) then
			return;
		end
		local v440 = v195.AbsoluteSize.X;
		local v441 = 0 * (v439 - 1);
		local v442 = (v440 - v441) / v439;
		for v700, v701 in ipairs(v187.Tabs) do
			v701.Button.Size = UDim2.new(0, v442, 1, 0);
		end
	end
	v187.AddTab = function(v443, v444)
		local v445 = {Groupboxes={},Tabboxes={}};
		local v446 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,Size=UDim2.new(0, 100, 1, 0),LayoutOrder=(#v187.Tabs + 1),ZIndex=1,Parent=v195});
		v445.Button = v446;
		v18:AddToRegistry(v446, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
		local v448 = v18:CreateLabel({Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 1, 0),Text=v444,ZIndex=1,Parent=v446});
		local v449 = v18:Create("Frame", {Name="TabFrame",BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 0),Size=UDim2.new(1, 0, 1, 0),Visible=false,ZIndex=2,Parent=v197});
		local v450 = v18:Create("ScrollingFrame", {BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(0, 8 - 1, 0, 8 - 1),Size=UDim2.new(0.5, -12 + 2, 0, 507 + 2),CanvasSize=UDim2.new(0, 0, 0, 0),BottomImage="",TopImage="",ScrollBarThickness=0,ZIndex=2,Parent=v449});
		local v451 = v18:Create("ScrollingFrame", {BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(0.5, 4 + 1, 0, 8 - 1),Size=UDim2.new(0.5, -12 + 2, 0, 507 + 2),CanvasSize=UDim2.new(0, 0, 0, 0),BottomImage="",TopImage="",ScrollBarThickness=0,ZIndex=2,Parent=v449});
		v18:Create("UIListLayout", {Padding=UDim.new(0, 8),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center,Parent=v450});
		v18:Create("UIListLayout", {Padding=UDim.new(0, 8),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center,Parent=v451});
		for v703, v704 in next, {v450,v451} do
			v704:WaitForChild("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				v704.CanvasSize = UDim2.fromOffset(0, v704.UIListLayout.AbsoluteContentSize.Y);
			end);
		end
		v445.ShowTab = function(v705)
			for v822, v823 in next, v187.Tabs do
				v823:HideTab();
			end
			v446.BackgroundColor3 = v18.MainColor;
			v18.RegistryMap[v446].Properties.BackgroundColor3 = "MainColor";
			v449.Visible = true;
		end;
		v445.HideTab = function(v710)
			v446.BackgroundColor3 = v18.BackgroundColor;
			v18.RegistryMap[v446].Properties.BackgroundColor3 = "BackgroundColor";
			v449.Visible = false;
		end;
		v445.SetLayoutOrder = function(v715, v716)
			v446.LayoutOrder = v716;
			v196:ApplyLayout();
			v199();
		end;
		table.insert(v187.Tabs, v445);
		v199();
		v445.AddGroupbox = function(v718, v719)
			local v720 = {};
			local v721 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 0, 507 + 2),ZIndex=2,Parent=(((v719.Side == 1) and v450) or v451)});
			v18:AddToRegistry(v721, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
			local v722 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(1, -2, 1, -2),Position=UDim2.new(0, 1, 0, 1),ZIndex=4,Parent=v721});
			v18:AddToRegistry(v722, {BackgroundColor3="BackgroundColor"});
			local v723 = v18:Create("Frame", {BackgroundColor3=v18.AccentColor,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 2),ZIndex=5,Parent=v722});
			v18:AddToRegistry(v723, {BackgroundColor3="AccentColor"});
			local v724 = v18:CreateLabel({Size=UDim2.new(1, 0, 0, 18),Position=UDim2.new(0, 4, 0, 2),TextSize=14,Text=v719.Name,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=5,Parent=v722});
			local v725 = v18:Create("Frame", {BackgroundTransparency=1,Position=UDim2.new(0, 4, 0, 20),Size=UDim2.new(1, -4, 1, -20),ZIndex=1,Parent=v722});
			v18:Create("UIListLayout", {FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v725});
			v720.Resize = function(v824)
				local v825 = 0;
				for v900, v901 in next, v720.Container:GetChildren() do
					if (not v901:IsA("UIListLayout") and v901.Visible) then
						v825 = v825 + v901.Size.Y.Offset;
					end
				end
				v721.Size = UDim2.new(1, 0, 0, 20 + v825 + 2 + 2);
			end;
			v720.Container = v725;
			setmetatable(v720, v45);
			v720:AddBlank(3);
			v720:Resize();
			v445.Groupboxes[v719.Name] = v720;
			return v720;
		end;
		v445.AddLeftGroupbox = function(v729, v730)
			return v445:AddGroupbox({Side=1,Name=v730});
		end;
		v445.AddRightGroupbox = function(v731, v732)
			return v445:AddGroupbox({Side=2,Name=v732});
		end;
		v445.AddTabbox = function(v733, v734)
			local v735 = {Tabs={}};
			local v736 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=v18.OutlineColor,BorderMode=Enum.BorderMode.Inset,Size=UDim2.new(1, 0, 0, 0),ZIndex=2,Parent=(((v734.Side == 1) and v450) or v451)});
			v18:AddToRegistry(v736, {BackgroundColor3="BackgroundColor",BorderColor3="OutlineColor"});
			local v737 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(1, -2, 1, -2),Position=UDim2.new(0, 1, 0, 1),ZIndex=4,Parent=v736});
			v18:AddToRegistry(v737, {BackgroundColor3="BackgroundColor"});
			local v738 = v18:Create("Frame", {BackgroundColor3=v18.AccentColor,BorderSizePixel=0,Size=UDim2.new(1, 0, 0, 2),ZIndex=10,Parent=v737});
			v18:AddToRegistry(v738, {BackgroundColor3="AccentColor"});
			local v739 = v18:Create("Frame", {BackgroundTransparency=1,Position=UDim2.new(0, 0, 0, 1),Size=UDim2.new(1, 0, 0, 18),ZIndex=5,Parent=v737});
			v18:Create("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Left,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v739});
			v735.AddTab = function(v827, v828)
				local v829 = {};
				local v830 = v18:Create("Frame", {BackgroundColor3=v18.MainColor,BorderColor3=Color3.new(0, 0, 0),Size=UDim2.new(0.5, 0, 1, 0),ZIndex=6,Parent=v739});
				v18:AddToRegistry(v830, {BackgroundColor3="MainColor"});
				local v831 = v18:CreateLabel({Size=UDim2.new(1, 0, 1, 0),TextSize=14,Text=v828,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7,Parent=v830});
				local v832 = v18:Create("Frame", {BackgroundColor3=v18.BackgroundColor,BorderSizePixel=0,Position=UDim2.new(0, 0, 1, 0),Size=UDim2.new(1, 0, 0, 1),Visible=false,ZIndex=9,Parent=v830});
				v18:AddToRegistry(v832, {BackgroundColor3="BackgroundColor"});
				local v833 = v18:Create("Frame", {BackgroundTransparency=1,Position=UDim2.new(0, 4, 0, 20),Size=UDim2.new(1, -4, 1, -20),ZIndex=1,Visible=false,Parent=v737});
				v18:Create("UIListLayout", {FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Parent=v833});
				v829.Show = function(v902)
					for v972, v973 in next, v735.Tabs do
						v973:Hide();
					end
					v833.Visible = true;
					v832.Visible = true;
					v830.BackgroundColor3 = v18.BackgroundColor;
					v18.RegistryMap[v830].Properties.BackgroundColor3 = "BackgroundColor";
					v829:Resize();
				end;
				v829.Hide = function(v908)
					v833.Visible = false;
					v832.Visible = false;
					v830.BackgroundColor3 = v18.MainColor;
					v18.RegistryMap[v830].Properties.BackgroundColor3 = "MainColor";
				end;
				v829.Resize = function(v914)
					local v915 = 0;
					for v974, v975 in next, v735.Tabs do
						v915 = v915 + 1;
					end
					for v976, v977 in next, v739:GetChildren() do
						if not v977:IsA("UIListLayout") then
							v977.Size = UDim2.new(1 / v915, 0, 1, 0);
						end
					end
					if not v833.Visible then
						return;
					end
					local v916 = 0;
					for v978, v979 in next, v829.Container:GetChildren() do
						if (not v979:IsA("UIListLayout") and v979.Visible) then
							v916 = v916 + v979.Size.Y.Offset;
						end
					end
					v736.Size = UDim2.new(1, 0, 0, 20 + v916 + 2 + 2);
				end;
				v830.InputBegan:Connect(function(v918)
					if ((v918.UserInputType == Enum.UserInputType.MouseButton1) and not v18:MouseIsOverOpenedFrame()) then
						v829:Show();
						v829:Resize();
					end
				end);
				v829.Container = v833;
				v735.Tabs[v828] = v829;
				setmetatable(v829, v45);
				v829:AddBlank(3);
				v829:Resize();
				if (#v739:GetChildren() == 2) then
					v829:Show();
				end
				return v829;
			end;
			v445.Tabboxes[v734.Name or ""] = v735;
			return v735;
		end;
		v445.AddLeftTabbox = function(v742, v743)
			return v445:AddTabbox({Name=v743,Side=1});
		end;
		v445.AddRightTabbox = function(v744, v745)
			return v445:AddTabbox({Name=v745,Side=2});
		end;
		v446.InputBegan:Connect(function(v746)
			if (v746.UserInputType == Enum.UserInputType.MouseButton1) then
				v445:ShowTab();
			end
		end);
		if (#v197:GetChildren() == 1) then
			v445:ShowTab();
		end
		v187.Tabs[v444] = v445;
		return v445;
	end;
	local v201 = v18:Create("TextButton", {BackgroundTransparency=1,Size=UDim2.new(0, 0, 0, 0),Visible=true,Text="",Modal=false,Parent=v10});
	local v202 = {};
	local v203 = false;
	local v204 = false;
	v18.Toggle = function(v462)
		if v204 then
			return;
		end
		local v463 = v186.MenuFadeTime;
		v204 = true;
		v203 = not v203;
		v201.Modal = v203;
		if v203 then
			v188.Visible = true;
			task.spawn(function()
				local v919 = v0.MouseIconEnabled;
				local v920 = Drawing.new("Triangle");
				v920.Thickness = 1;
				v920.Filled = true;
				v920.Visible = true;
				local v924 = Drawing.new("Triangle");
				v924.Thickness = 1;
				v924.Filled = false;
				v924.Color = Color3.new(0, 0, 0);
				v924.Visible = true;
				while v203 and v10.Parent do
					v0.MouseIconEnabled = false;
					local v981 = v0:GetMouseLocation();
					v920.Color = v18.AccentColor;
					v920.PointA = Vector2.new(v981.X, v981.Y);
					v920.PointB = Vector2.new(v981.X + 16, v981.Y + 6);
					v920.PointC = Vector2.new(v981.X + 6, v981.Y + 16);
					v924.PointA = v920.PointA;
					v924.PointB = v920.PointB;
					v924.PointC = v920.PointC;
					v7:Wait();
				end
				v0.MouseIconEnabled = v919;
				v920:Remove();
				v924:Remove();
			end);
		end
		for v747, v748 in next, v188:GetDescendants() do
			local v749 = {};
			if v748:IsA("ImageLabel") then
				table.insert(v749, "ImageTransparency");
				table.insert(v749, "BackgroundTransparency");
			elseif (v748:IsA("TextLabel") or v748:IsA("TextBox")) then
				table.insert(v749, "TextTransparency");
			elseif (v748:IsA("Frame") or v748:IsA("ScrollingFrame")) then
				table.insert(v749, "BackgroundTransparency");
			elseif v748:IsA("UIStroke") then
				table.insert(v749, "Transparency");
			end
			local v750 = v202[v748];
			if not v750 then
				v750 = {};
				v202[v748] = v750;
			end
			for v840, v841 in next, v749 do
				if not v750[v841] then
					v750[v841] = v748[v841];
				end
				if (v750[v841] == 1) then
					continue;
				end
				v6:Create(v748, TweenInfo.new(v463, Enum.EasingStyle.Linear), {[v841]=((v203 and v750[v841]) or 1)}):Play();
			end
		end
		task.wait(v463);
		v188.Visible = v203;
		v204 = false;
	end;
	v18:GiveSignal(v0.InputBegan:Connect(function(v466, v467)
		if ((type(v18.ToggleKeybind) == "table") and (v18.ToggleKeybind.Type == "KeyPicker")) then
			if ((v466.UserInputType == Enum.UserInputType.Keyboard) and (v466.KeyCode.Name == v18.ToggleKeybind.Value)) then
				task.spawn(v18.Toggle);
			end
		elseif ((v466.KeyCode == Enum.KeyCode.RightControl) or ((v466.KeyCode == Enum.KeyCode.RightShift) and not v467)) then
			task.spawn(v18.Toggle);
		end
	end));
	if v186.AutoShow then
		task.spawn(v18.Toggle);
	end
	v187.Holder = v188;
	return v187;
end;
local function v50()
	local v207 = v21();
	for v468, v469 in next, v15 do
		if ((v469.Type == "Dropdown") and (v469.SpecialType == "Player")) then
			v469:SetValues(v207);
		end
	end
end
v4.PlayerAdded:Connect(v50);
v4.PlayerRemoving:Connect(v50);
getgenv().Library = v18;
for v208, v209 in pairs({"Internal","HttpCache","Instances","Signals","Script","PhysicsCollision","PhysicsParts","GraphicsSolidModels","GraphicsMeshParts","GraphicsParticles","GraphicsParts","GraphicsSpatialHash","GraphicsTerrain","GraphicsTexture","GraphicsTextureCharacter","Sounds","StreamingSounds","TerrainVoxels","Gui","Animation","Navigation","GeometryCSG"}) do
	memorystats.restore(v209);
end
return v18, v14, v15;
