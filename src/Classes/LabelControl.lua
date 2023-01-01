-- Path of Building
--
-- Class: Label Control
-- Simple text label.
--
local LabelClass = newClass("LabelControl", "Control", function(self, anchor, x, y, width, height, label)
	self.Control(anchor, x, y, width, height)
	self.label = label
	self.width = function()
		return graphics:DrawStringWidth(self:GetProperty("height"), "VAR", self:GetProperty("label"))
	end
end)

function LabelClass:Draw()
	local x, y = self:GetPos()
	graphics:DrawString(x, y, "LEFT", self:GetProperty("height"), "VAR", self:GetProperty("label"))
end