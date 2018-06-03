return {
	createBinaryTree = function()
		return {
			TreeType = 0,
			Type = 0,
			Parent = nil,
			LChild = nil,
			rChild = nil,
			linkLeftChild = function(self, childTree)
				if (self.TreeType ~= 0) then return end
				self.LChild = childTree
				childTree.Parent = self
			end,
			linkRightChild = function(self, childTree)
				if (self.TreeType ~= 0) then return end
				self.RChild = childTree
				childTree.Parent = self
			end,
		}
	end,
	createTree = function()
		return {
			TreeType = 1,
			Type = 0,
			Parent = nil,
			Children = {},
			linkChild = function(self, childTree)
				if (self.TreeType ~= 1) then return end
				
				table.insert(self.Children, childTree)
			end,
		}
	end,
	getTopParent = function(tree)
		local p = tree
		
		while (p.Parent ~= nil) do 
			p = p.Parent
		end
		
		return p
	end
}
