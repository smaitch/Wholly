--
--	Wholly Immersion Integration
--	Provides related quest information when using the Immersion addon
--

local Wholly = Wholly
local Grail = Grail

local ImmersionRelatedQuests = {}

local questEventFrame = CreateFrame("Frame")
questEventFrame:RegisterEvent("GOSSIP_CLOSED")
questEventFrame:RegisterEvent("QUEST_FINISHED")
questEventFrame:RegisterEvent("QUEST_GREETING")
questEventFrame:RegisterEvent("QUEST_DETAIL")

questEventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "GOSSIP_CLOSED" or event == "QUEST_FINISHED" then
		local relationshipsFrame = _G["ImmersionRelatedQuestsFrame"]
		if relationshipsFrame then
			relationshipsFrame:Hide()
		end
	else
		C_Timer.After(0.1, function()
			if ImmersionRelatedQuests.UpdateForCurrentQuest then
				ImmersionRelatedQuests.UpdateForCurrentQuest()
			end
		end)
	end
end)

Wholly._SetupImmersionIntegration = function(self)
	if not ImmersionFrame or not ImmersionFrame.TalkBox then
		return
	end
	self:_HookQuestFrameReferences()
	self:_SetupImmersionRelatedQuestsFrame()

	ImmersionFrame:HookScript("OnHide", function()
		local relationshipsFrame = _G["ImmersionRelatedQuestsFrame"]
		if relationshipsFrame then
			relationshipsFrame:Hide()
		end
	end)

	if ImmersionContentFrame and self._UpdateQuestInfoFrameVisibility then
		C_Timer.After(0.2, function()
			self:_UpdateQuestInfoFrameVisibility()
		end)
	end
end

Wholly._HookQuestFrameReferences = function(self)
	if not ImmersionFrame or not ImmersionFrame.TalkBox then
		return
	end

	local originalSetupQuestInfoFrame = self._SetupQuestInfoFrame

	self._SetupQuestInfoFrame = function(self)
		if nil == com_mithrandir_whollyQuestInfoFrame then
			local frame = CreateFrame("Frame", "com_mithrandir_whollyQuestInfoFrame", ImmersionFrame.TalkBox)
			frame:EnableMouse(true)
			frame:SetSize(60, 14)
			local xOffset, yOffset = -15, -35
			if Grail.existsClassic then
				xOffset, yOffset = -55, -55
			end
			frame:SetPoint("TOPRIGHT", ImmersionFrame.TalkBox, "TOPRIGHT", xOffset, yOffset)
			frame:SetScript("OnEnter", function(self) Wholly:QuestInfoEnter(self) end)
			frame:SetScript("OnLeave", function(self) Wholly.tooltip:Hide() end)
			local fontString = frame:CreateFontString("com_mithrandir_whollyQuestInfoFrameText", "BACKGROUND", "GameFontNormal")
			fontString:SetJustifyH("RIGHT")
			fontString:SetSize(60, 20)
			fontString:SetPoint("CENTER")
			fontString:SetText("None")
			self.configurationScript24()
		end
	end

	local originalPlayerLogin = self.eventDispatch.PLAYER_LOGIN
	if originalPlayerLogin then
		self.eventDispatch.PLAYER_LOGIN = function(selfEvent, frame, arg1)
			originalPlayerLogin(selfEvent, frame, arg1)
			if ImmersionFrame and ImmersionFrame.TalkBox then
				C_Timer.After(0.1, function()
					selfEvent:_RepositionFramesForImmersion()
				end)
			end
		end
	end
	if com_mithrandir_whollyQuestInfoFrame then
		local currentParent = com_mithrandir_whollyQuestInfoFrame:GetParent()
		if currentParent ~= ImmersionFrame.TalkBox then
			com_mithrandir_whollyQuestInfoFrame:SetParent(ImmersionFrame.TalkBox)
			com_mithrandir_whollyQuestInfoFrame:ClearAllPoints()
			com_mithrandir_whollyQuestInfoFrame:SetPoint("TOPRIGHT", ImmersionContentFrame, "TOPRIGHT", 0, 0)
		end
	end
	if ImmersionContentFrame then
		self:_SetupImmersionContentFrameHooks()
	end

	C_Timer.After(0.1, function()
		self:_RepositionFramesForImmersion()
	end)
end

Wholly._SetupImmersionContentFrameHooks = function(self)
	if not ImmersionContentFrame or not com_mithrandir_whollyQuestInfoFrame then
		return
	end

	local originalShow = ImmersionContentFrame.Show
	local originalHide = ImmersionContentFrame.Hide

	ImmersionContentFrame.Show = function(frame)if originalShow then
			originalShow(frame)
		else
			frame:Show()
		end
		self:_UpdateQuestInfoFrameVisibility()
	end

	ImmersionContentFrame.Hide = function(frame)
		if originalHide then
			originalHide(frame)
		else
			frame:Hide()
		end
		self:_UpdateQuestInfoFrameVisibility()
	end

	local originalSetShown = ImmersionContentFrame.SetShown
	ImmersionContentFrame.SetShown = function(frame, shown)
		if originalSetShown then
			originalSetShown(frame, shown)
		else
			if shown then
				frame:Show()
			else
				frame:Hide()
			end
		end
		self:_UpdateQuestInfoFrameVisibility()
	end
end

Wholly._UpdateQuestInfoFrameVisibility = function(self)
	if not com_mithrandir_whollyQuestInfoFrame or not ImmersionContentFrame then
		return
	end

	local shouldShow = not WhollyDatabase.hidesIDOnQuestPanel and ImmersionContentFrame:IsShown()

	if shouldShow then
		com_mithrandir_whollyQuestInfoFrame:Show()
	else
		com_mithrandir_whollyQuestInfoFrame:Hide()
	end
end

Wholly._RepositionFramesForImmersion = function(self)
	if not ImmersionFrame or not ImmersionFrame.TalkBox then
		return
	end

	if com_mithrandir_whollyQuestInfoBuggedFrame then
		com_mithrandir_whollyQuestInfoBuggedFrame:ClearAllPoints()
		if ImmersionContentFrame and ImmersionContentFrame.ObjectivesHeader then
			com_mithrandir_whollyQuestInfoBuggedFrame:SetPoint("LEFT", ImmersionContentFrame.ObjectivesHeader, "RIGHT", 0, 0)
		else
			com_mithrandir_whollyQuestInfoBuggedFrame:SetPoint("TOPLEFT", ImmersionFrame.TalkBox, "TOPLEFT", 100, -35)
		end
	end

	if com_mithrandir_whollyBreadcrumbFrame then
		com_mithrandir_whollyBreadcrumbFrame:ClearAllPoints()
		if Grail.existsClassic then
			com_mithrandir_whollyBreadcrumbFrame:SetPoint("TOPLEFT", ImmersionFrame.TalkBox, "BOTTOMLEFT", 16, 50)
		else
			com_mithrandir_whollyBreadcrumbFrame:SetPoint("TOPLEFT", ImmersionFrame.TalkBox, "BOTTOMLEFT", 16, -30)
		end
	end
end

Wholly._SetupImmersionRelatedQuestsFrame = function(self)
	if not ImmersionFrame then return end

	local frame = CreateFrame("Frame", "ImmersionRelatedQuestsFrame", ImmersionFrame.TalkBox)
	frame:SetSize(570, 155)
	frame:SetPoint("TOP", ImmersionFrame.TalkBox.Elements, "BOTTOM", 0, -8)
	frame:Hide()

	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(1)

	local bgFrame = CreateFrame("Frame", nil, frame)
	bgFrame:SetAllPoints(frame)
	bgFrame:SetFrameLevel(frame:GetFrameLevel())

	local bg = bgFrame:CreateTexture(nil, "BACKGROUND")
	bg:SetAtlas("TalkingHeads-TextBackground", true)
	bg:SetPoint("CENTER")
	bgFrame.Background = bg
	local content = CreateFrame("Frame", nil, frame)
	content:SetSize(506, 107)
	content:SetPoint("TOPLEFT", frame, "TOPLEFT", 32, -24)

	local title = content:CreateFontString(nil, "ARTWORK", "QuestTitleFont")
	title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	title:SetText(Wholly.s.RELATED_QUESTS)
	title:SetTextColor(1, 0.82, 0)
		title:EnableMouse(true)
	title:SetScript("OnEnter", function(self)
		Wholly.tooltip:SetOwner(self, "ANCHOR_TOP")
		Wholly.tooltip:SetText(Wholly.s.RELATED_QUESTS)
		Wholly.tooltip:AddLine(Wholly.s.RELATED_QUESTS_TOOLTIP, 0.7, 0.7, 0.7, true)
		Wholly.tooltip:Show()
	end)
	title:SetScript("OnLeave", function(self)
		Wholly.tooltip:Hide()
	end)
	frame.Title = title

	local attribution = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")	attribution:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 12)
	attribution:SetText(Wholly.s.WHOLLY_ATTRIBUTION)
	attribution:SetTextColor(0.5, 0.5, 0.5, 0.8)
	frame.Attribution = attribution

	if WhollyDatabase and WhollyDatabase.hidesImmersionAttribution ~= nil then
		if WhollyDatabase.hidesImmersionAttribution then
			attribution:Hide()
		else
			attribution:Show()
		end
	else
		attribution:Show()
	end

	local scrollFrame = CreateFrame("ScrollFrame", nil, content)
	scrollFrame:SetSize(506, 79)
	scrollFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetSize(506, 1)
	scrollFrame:SetScrollChild(scrollChild)

	frame.ScrollFrame = scrollFrame
	frame.ScrollChild = scrollChild
	frame.Content = content

	frame.FontStrings = {}
	frame.FontStringPool = {}
	frame.LastFontString = nil

	ImmersionRelatedQuests:SetupIntegrationHooks()

	return frame
end

ImmersionRelatedQuests.GetFontString = function(self, frame)
	if #frame.FontStringPool > 0 then
		return table.remove(frame.FontStringPool)
	end

	local fs = frame.ScrollChild:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med2")
	fs:SetJustifyH("LEFT")
	fs:SetWidth(506)
	fs:SetWordWrap(true)
	table.insert(frame.FontStrings, fs)
	return fs
end

ImmersionRelatedQuests.ReleaseFontString = function(self, frame, fontString)
	fontString:Hide()
	fontString:ClearAllPoints()
	fontString:SetText("")
	fontString:EnableMouse(false)
	fontString:SetScript("OnEnter", nil)
	fontString:SetScript("OnLeave", nil)

	if frame.LastFontString == fontString then
		frame.LastFontString = nil
	end

	table.insert(frame.FontStringPool, fontString)
end

ImmersionRelatedQuests.ClearContent = function(self, frame)
	for _, fs in ipairs(frame.FontStrings) do
		self:ReleaseFontString(frame, fs)
	end
	frame.LastFontString = nil
end

ImmersionRelatedQuests.AddLine = function(self, frame, text, color, indent, questId)
	local fs = self:GetFontString(frame)

	if fs == frame.LastFontString then
		frame.LastFontString = nil
	end

	fs:ClearAllPoints()

	local indentText = ""
	if indent and indent > 0 then
		indentText = string.rep("  ", indent)
	end

	local finalText = indentText .. (text or "")

	if color then
		if type(color) == "string" then
			finalText = "|c" .. color .. finalText .. "|r"
			fs:SetTextColor(1, 1, 1, 1)
		else
			fs:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
		end
	else
		fs:SetTextColor(1, 1, 1, 1)
	end

	fs:SetText(finalText)

	if questId and tonumber(questId) then
		fs:EnableMouse(true)
		fs:SetScript("OnEnter", function(self)
			Wholly.tooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			Wholly.briefQuestTooltip = true
			local dummyFrame = {
				statusCode = "P",
				GetAttribute = function() return nil end,
				SetAttribute = function() end
			}
			Wholly:_PopulateTooltipForQuest(dummyFrame, tonumber(questId))
			Wholly.briefQuestTooltip = false
			Wholly.tooltip:Show()
		end)
		fs:SetScript("OnLeave", function()
			Wholly.tooltip:Hide()
		end)
	else
		fs:EnableMouse(false)
		fs:SetScript("OnEnter", nil)
		fs:SetScript("OnLeave", nil)
	end

	local lastFS = frame.LastFontString
	if lastFS == fs then
		lastFS = nil
	end

	local yOffset = (lastFS and lastFS ~= fs) and -2 or 0
	fs:SetPoint("TOPLEFT", lastFS or frame.ScrollChild, lastFS and "BOTTOMLEFT" or "TOPLEFT", 0, yOffset)
	fs:Show()

	frame.LastFontString = fs
	return fs
end

ImmersionRelatedQuests.ProcessQuestList = function(self, frame, questList)
	if not questList then return false end

	local hasContent = false

	if type(questList) == "string" then
		if questList:find(",") then
			local questIds = { strsplit(",", questList) }
			for _, questIdStr in ipairs(questIds) do
				local questId = tonumber(questIdStr)
				if questId then
					hasContent = true
					self:AddEnhancedQuestLine(frame, questId)
				end
			end
		else
			local questId = tonumber(questList)
			if questId then
				hasContent = true
				self:AddEnhancedQuestLine(frame, questId)
			end
		end
	elseif type(questList) == "number" then
		hasContent = true
		self:AddEnhancedQuestLine(frame, questList)
	elseif type(questList) == "table" then
		if #questList > 0 then
			for _, questCode in ipairs(questList) do
				local questId = tonumber(questCode)
				if questId then
					hasContent = true
					self:AddEnhancedQuestLine(frame, questId)
				end
			end
		else
			local controlTable = {
				indentation = "  ",
				lastIndexUsed = 0,
				func = function(innerTable)
					local innorItem = innerTable.innorItem
					local code, subcode, numeric = Grail:CodeParts(innorItem)
					local classification = Grail:ClassificationOfQuestCode(innorItem, nil, WhollyDatabase.buggedQuestsConsideredUnobtainable)
					local statusColor = WhollyDatabase.color[classification] or "ffffff00"

					local displayText = Wholly:_PrettyQuestString({ innorItem, classification }) or tostring(innorItem)

					local questId = tonumber(innorItem)
					if questId then
						self:AddLine(frame, displayText, statusColor, 1, questId)
					else
						self:AddLine(frame, displayText, statusColor, 1)
					end
				end
			}
			Grail._ProcessCodeTable(questList, controlTable)
			hasContent = true
		end
	end

	return hasContent
end

ImmersionRelatedQuests.AddEnhancedQuestLine = function(self, frame, questId)
	local classification = Grail:ClassificationOfQuestCode(questId, nil, WhollyDatabase.buggedQuestsConsideredUnobtainable)
	local statusColor = WhollyDatabase.color[classification] or "ffffff00"

	local questString = Wholly:_PrettyQuestString({ questId, classification })

	local fs = self:GetFontString(frame)

	if fs == frame.LastFontString then
		frame.LastFontString = nil
	end
	fs:ClearAllPoints()

	if type(statusColor) == "string" then
		local r = tonumber(statusColor:sub(3, 4), 16) / 255
		local g = tonumber(statusColor:sub(5, 6), 16) / 255
		local b = tonumber(statusColor:sub(7, 8), 16) / 255
		fs:SetTextColor(r, g, b, 1)
	else
		fs:SetTextColor(1, 1, 1, 1)
	end

	fs:SetText("  " .. questString)

	local lastFS = frame.LastFontString
	if lastFS == fs then
		lastFS = nil
	end
	local yOffset = (lastFS and lastFS ~= fs) and -2 or 0
	fs:SetPoint("TOPLEFT", lastFS or frame.ScrollChild, lastFS and "BOTTOMLEFT" or "TOPLEFT", 0, yOffset)
	fs:Show()

	fs:EnableMouse(true)
	fs:SetScript("OnEnter", function(self)
		Wholly.tooltip:SetOwner(self, "ANCHOR_LEFT")
		Wholly.briefQuestTooltip = true
		local dummyFrame = {
			statusCode = "P",
			GetAttribute = function() return nil end,
			SetAttribute = function() end
		}
		Wholly:_PopulateTooltipForQuest(dummyFrame, questId)
		Wholly.briefQuestTooltip = false
		Wholly.tooltip:Show()
	end)
	fs:SetScript("OnLeave", function() Wholly.tooltip:Hide() end)

	frame.LastFontString = fs
	return fs
end

ImmersionRelatedQuests.AddRelatedQuestSection = function(self, frame, heading, questList, defaultColor)
	if not questList then return false end

	self:AddLine(frame, heading, "ffffd200")

	local hasContent = self:ProcessQuestList(frame, questList)

	return hasContent
end

ImmersionRelatedQuests.UpdateRelatedQuests = function(self, questId)
	local frame = _G["ImmersionRelatedQuestsFrame"]
	if not frame or not questId then
		if frame then frame:Hide() end
		return
	end

	if WhollyDatabase and WhollyDatabase.hidesImmersionRelatedQuests then
		frame:Hide()
		return
	end

	self:ClearContent(frame)
	local hasAnyContent = false
	local breadcrumbs = Grail:QuestBreadcrumbs(questId)
	if breadcrumbs then
		local hasContent = self:AddRelatedQuestSection(frame, Wholly.s.BREADCRUMB, breadcrumbs, "ff00ff00")
		hasAnyContent = hasAnyContent or hasContent
	end

	local prerequisites = Grail.DisplayableQuestPrerequisites and
		Grail:DisplayableQuestPrerequisites(questId, true) or
		Grail:QuestPrerequisites(questId, true)
	if prerequisites then
		local hasContent = self:AddRelatedQuestSection(frame, Wholly.s.PREREQUISITES, prerequisites, "ffff9900")
		hasAnyContent = hasAnyContent or hasContent
	end

	local breadcrumbsFor = Grail:QuestBreadcrumbsFor(questId)
	if breadcrumbsFor then
		local hasContent = self:AddRelatedQuestSection(frame, Wholly.s.IS_BREADCRUMB, breadcrumbsFor, "ff9900ff")
		hasAnyContent = hasAnyContent or hasContent
	end

	local invalidates = Grail:QuestInvalidates(questId)
	if invalidates then
		local hasContent = self:AddRelatedQuestSection(frame, Wholly.s.INVALIDATE, invalidates, "ffff0000")
		hasAnyContent = hasAnyContent or hasContent
	end

	local onAcceptCompletes = Grail:QuestOnAcceptCompletes(questId)
	if onAcceptCompletes then
		local hasContent = self:AddRelatedQuestSection(frame, Wholly.s.OAC, onAcceptCompletes, "ff00ffff")
		hasAnyContent = hasAnyContent or hasContent
	end

	local onCompletionCompletes = Grail:QuestOnCompletionCompletes(questId)	if onCompletionCompletes then
		local hasContent = self:AddRelatedQuestSection(frame, Wholly.s.OTC, onCompletionCompletes, "ff00ffff")
		hasAnyContent = hasAnyContent or hasContent
	end
	if hasAnyContent and not (WhollyDatabase and WhollyDatabase.hidesImmersionRelatedQuests) then
		local contentHeight = 0
		for _, fs in ipairs(frame.FontStrings) do
			if fs:IsShown() then
				contentHeight = contentHeight + 16
			end
		end

		contentHeight = math.max(contentHeight + 10, 20)
		frame.ScrollChild:SetHeight(contentHeight)

		local maxDisplayHeight = 100
		local actualHeight = math.min(contentHeight, maxDisplayHeight)
		frame.ScrollFrame:SetHeight(actualHeight)

		local totalFrameHeight = actualHeight + 80
		frame:SetHeight(totalFrameHeight)
		frame.Content:SetHeight(totalFrameHeight - 30)

		frame:Show()
	else
		frame:Hide()
	end
end

ImmersionRelatedQuests.SetupIntegrationHooks = function(self)
	local originalShowBreadcrumbInfo = Wholly.ShowBreadcrumbInfo
	Wholly.ShowBreadcrumbInfo = function(self)
		originalShowBreadcrumbInfo(self)
		local questId = self:_BreadcrumbQuestId()
		if questId then
			ImmersionRelatedQuests:UpdateRelatedQuests(questId)
		end
	end

	local originalBreadcrumbUpdate = Wholly.BreadcrumbUpdate
	Wholly.BreadcrumbUpdate = function(self, frame, shouldHide)
		originalBreadcrumbUpdate(self, frame, shouldHide)
		if not shouldHide then
			local questId = self:_BreadcrumbQuestId()
			if questId then
				ImmersionRelatedQuests:UpdateRelatedQuests(questId)
			end
		else
			local relationshipsFrame = _G["ImmersionRelatedQuestsFrame"]
			if relationshipsFrame then
				relationshipsFrame:Hide()
			end
		end
	end

	if ImmersionFrame and ImmersionFrame.TalkBox then
		local function UpdateForCurrentQuest()
			if not ImmersionFrame or not ImmersionFrame:IsShown() then
				local relationshipsFrame = _G["ImmersionRelatedQuestsFrame"]
				if relationshipsFrame then
					relationshipsFrame:Hide()
				end
				return
			end

			local questId = GetQuestID()
			if questId and questId > 0 then
				ImmersionRelatedQuests:UpdateRelatedQuests(questId)
			else
				local relationshipsFrame = _G["ImmersionRelatedQuestsFrame"]
				if relationshipsFrame then
					relationshipsFrame:Hide()
				end
			end
		end

		local originalBreadcrumbInfo = Wholly._GetBreadcrumbMessage
		Wholly._GetBreadcrumbMessage = function(self)
			local result = originalBreadcrumbInfo(self)
			UpdateForCurrentQuest()
			return result
		end

		ImmersionRelatedQuests.UpdateForCurrentQuest = UpdateForCurrentQuest
	end
end

_G.ImmersionRelatedQuests = ImmersionRelatedQuests
