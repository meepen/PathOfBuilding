-- Path of Building
--
-- Class: Timeless Jewel Socket Control
-- Specialized socket selection control for Timeless Jewel searches.
--

local m_min = math.min

local TimelessJewelSocketClass = newClass("TimelessJewelSocketControl", "DropDownControl", function(self, anchor, x, y, width, height, list, selFunc, build, socketViewer)
	self.DropDownControl(anchor, x, y, width, height, list, selFunc)
	self.build = build
	self.socketViewer = socketViewer
end)

function TimelessJewelSocketClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	self.DropDownControl:Draw(viewPort)
	self:DrawControls(viewPort)
	if self:IsMouseOver() and not noTooltip and not main.popups[2] then
		graphics:SetDrawLayer(nil, 15)
		local viewerY
		if self.DropDownControl.dropUp and self.DropDownControl.dropped then
			viewerY = y + 20
		else
			viewerY = m_min(y - 150 - 5, viewPort.y + viewPort.height - 154)
		end
		local viewerX = x + 215
		graphics:SetDrawColor(1, 1, 1)
		graphics:DrawImage(nil, viewerX, viewerY, 304, 304)
		local node = self.build.spec.nodes[self.DropDownControl.list[self.DropDownControl:GetHoverIndex()].id]
		self.socketViewer.zoom = 5
		local scale = self.build.spec.tree.size / 1500
		self.socketViewer.zoomX = -node.x / scale
		self.socketViewer.zoomY = -node.y / scale
		graphics:SetViewport(viewerX + 2, viewerY + 2, 300, 300)
		self.socketViewer:Draw(self.build, { x = 0, y = 0, width = 300, height = 300 }, { })
		graphics:SetDrawLayer(nil, 30)
		graphics:SetDrawColor(1, 1, 1, 0.2)
		graphics:DrawImage(nil, 149, 0, 2, 300)
		graphics:DrawImage(nil, 0, 149, 300, 2)
		graphics:SetViewport()
		graphics:SetDrawLayer(nil, 0)
	end
end