local G = ...

local main_frame
local wxID_menu_show_dialog = G.ID("pkgman.menu_show_dialog")
local wxID_toolbar_show_dialog = G.ID("pkgman.toolbar_show_dialog")

local function pkg_path(name, state)
	local path = MergeFullPath(
    GetPathWithSep(ide.editorFilename), "packages/"..(name or ''))
	if name==nil or name=='' then return path end
	if state==nil then
		return path..iff(wx.wxFileExists(path..'.lua'), '.lua', '.lua.off')
	else
		return path..iff(state, '.lua', '.lua.off')
	end
end


local function DisablePackage(k)
	if not wx.wxFileExists(pkg_path(k, true)) then
		DisplayOutputLn("Disable package: "..k..'\tFail, file not found')
	else
		if not wx.wxFileExists(pkg_path(k, false)) then
			wx.wxRenameFile(pkg_path(k, true), pkg_path(k, false))
		else
			DisplayOutputLn("Disable package: "..k..'\tFail, file already exists')
		end
	end
end

local function EnablePackage(k)
	if not wx.wxFileExists(pkg_path(k, false)) then
		DisplayOutputLn("Enable package: "..k..'\tFail, file not found')
	else
		if not wx.wxFileExists(pkg_path(k, true)) then
			wx.wxRenameFile(pkg_path(k, false), pkg_path(k, true))
		else
			DisplayOutputLn("Enable package: "..k..'\tFail, file already exists')
		end
	end
end

local function CreateDialog(parent, this)
	UI = { this=this }



	UI.MyDialog1 = wx.wxDialog(parent or wx.NULL, wx.wxID_ANY, this.name, wx.wxDefaultPosition, wx.wxSize(600, 400), wx.wxDEFAULT_DIALOG_STYLE +		wx.wxRESIZE_BORDER + wx.wxSTAY_ON_TOP )
	UI.MyDialog1:SetSizeHints( wx.wxDefaultSize, wx.wxDefaultSize )

	UI.bSizer1 = wx.wxBoxSizer( wx.wxVERTICAL )

	UI.bSizer2 = wx.wxBoxSizer( wx.wxHORIZONTAL )

	UI.m_checkList1 = wx.wxListBox( UI.MyDialog1, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, {}, wx.wxLB_SORT )
	UI.bSizer2:Add( UI.m_checkList1, 1, wx.wxALL + wx.wxEXPAND, 5 )


	UI.m_notebook1 = wx.wxNotebook( UI.MyDialog1, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer2:Add( UI.m_notebook1, 1, wx.wxALL + wx.wxEXPAND, 5 )

	UI.m_textCtrl1 = wx.wxTextCtrl( UI.m_notebook1, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE + wx.wxTE_READONLY )
	UI.m_notebook1:AddPage(UI.m_textCtrl1, TR"About", False )

	UI.m_funcList = wx.wxListBox(UI.m_notebook1, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, {'ll;'}, wx.wxLB_SORT )
	UI.m_notebook1:AddPage(UI.m_funcList, TR"Events", False )


	UI.bSizer1:Add( UI.bSizer2, 1, wx.wxEXPAND, 5 )

	UI.bSizer3 = wx.wxBoxSizer( wx.wxHORIZONTAL )

	UI.Load = wx.wxButton( UI.MyDialog1, wx.wxID_ANY, TR"Load", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.Load, 1, wx.wxALL + wx.wxEXPAND, 5 )

	UI.UnLoad = wx.wxButton( UI.MyDialog1, wx.wxID_ANY, TR"UnLoad", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.UnLoad, 1, wx.wxALL + wx.wxEXPAND, 5 )

	UI.Disable = wx.wxButton( UI.MyDialog1, wx.wxID_ANY, TR"Disable", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.Disable, 1, wx.wxALL + wx.wxEXPAND, 5 )

	UI.Enable = wx.wxButton( UI.MyDialog1, wx.wxID_ANY, TR"Enable", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.Enable, 1, wx.wxALL + wx.wxEXPAND, 5 )

	UI.Reload = wx.wxButton( UI.MyDialog1, wx.wxID_ANY, TR"Reload", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.Reload, 1, wx.wxALL + wx.wxEXPAND, 5 )

	UI.Edit = wx.wxButton( UI.MyDialog1, wx.wxID_ANY, TR("&Edit"), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.Edit, 1, wx.wxALL + wx.wxEXPAND, 5 )

	UI.actUpdate = wx.wxButton( UI.MyDialog1, wx.wxID_ANY, TR"Refresh", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
	UI.bSizer3:Add( UI.actUpdate, 1, wx.wxALL + wx.wxEXPAND, 5 )

	UI.Edit:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		LoadFile(pkg_path(UI.m_checkList1:GetStringSelection()))

	end )

	UI.bSizer1:Add( UI.bSizer3, 0, wx.wxEXPAND, 5 )

	local function on_selected()
		local issel = UI.m_checkList1:GetSelection() ~= -1
		local name = UI.m_checkList1:GetStringSelection()
		local enabled = wx.wxFileExists(pkg_path(name, true))
		UI.m_funcList:Clear()
		UI.Reload:Enable( issel and ide.packages[name]~=nil and enabled )
		UI.Edit:Enable( issel )
		UI.Disable:Enable( issel and enabled )
		UI.Enable:Enable( issel and not enabled )
		UI.Load:Enable( issel and ide.packages[name]==nil and enabled )
		UI.UnLoad:Enable( issel and ide.packages[name]~=nil )
		local s = ''
		if issel then
			s = s .. 'Package '..name .. '\n\n'
			s = s .. 'path: \t' .. pkg_path(name) .. '\n'
			if ide.packages[name] then
				for k, v in pairs(ide.packages[name]) do
					if type(v)=='function' then
						UI.m_funcList:Append(k)
					elseif type(v)~='table' then
						s = s .. k .. ': \t'..tostring(v):gsub('\n', '\t\n') .. '\n'
					end
				end
			end
		end
		UI.m_textCtrl1:SetValue(s)
	end

	function UI:Update()
		self.m_checkList1:Clear()

		for k, v in pairs(ide.packages) do
			if v.name and v.description then
				self.m_checkList1:Append(k)
			end
		end

		local packages_dir = pkg_path(nil, nil)
		local fi = wx.wxFindFirstFile(packages_dir..'*.lua.off', wx.wxFILE)
		while fi and #fi>0 do
			self.m_checkList1:Append( fi:sub(#packages_dir+1, #fi-8))
		 	fi = wx.wxFindNextFile()
		end
		
--		local fi = wx.wxFindFirstFile(packages_dir..'*.lua', wx.wxFILE)
--		while fi and #fi>0 do
--			local name = fi:sub(#packages_dir+1, #fi-4)
--			if not ide.packages[name] or 1 then self.m_checkList1:Append( name ) end
--		 	fi = wx.wxFindNextFile()
--		end
		
		on_selected()
	end

	UI.actUpdate:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		UI:Update()
	end )

	UI.Reload:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		local fname = UI.m_checkList1:GetStringSelection()
		PackageUnRegister(fname)
		PackageRegister(fname)
		ide:GetMainFrame().uimgr:Update()
		on_selected()
	end )

	UI.UnLoad:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		local fname = UI.m_checkList1:GetStringSelection()
		PackageUnRegister(fname)
		ide:GetMainFrame().uimgr:Update()
		on_selected()
	end )

	UI.Load:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		local fname = UI.m_checkList1:GetStringSelection()
		PackageRegister(fname)
		ide:GetMainFrame().uimgr:Update()
		on_selected()
	end )

	UI.Disable:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		local fname = UI.m_checkList1:GetStringSelection()
		DisablePackage(fname)
		ide:GetMainFrame().uimgr:Update()
		on_selected()
	end )

	UI.Enable:Connect( wx.wxEVT_COMMAND_BUTTON_CLICKED, function(event)
		local fname = UI.m_checkList1:GetStringSelection()
		EnablePackage(fname)
		ide:GetMainFrame().uimgr:Update()
		on_selected()
	end )

	UI.m_checkList1:Connect( wx.wxEVT_COMMAND_LISTBOX_SELECTED, on_selected )
	UI.m_checkList1:Connect(wx.wxEVT_COMMAND_LISTBOX_DOUBLECLICKED,function(event)
		on_selected()
		local cmd_ev = wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED)
		if UI.Load:IsEnabled() then
			UI.Load:Command(cmd_ev)
		elseif UI.UnLoad:IsEnabled() then
			UI.UnLoad:Command(cmd_ev)
		elseif UI.Enable:IsEnabled() then
			UI.Enable:Command(cmd_ev)
			UI.Load:Command(cmd_ev)
		end
	end )

	local eventsArgs = setmetatable({
		onRegister =         function() return end,
		onUnRegister =       function() return end,
		onEditorLoad =       function() return ide:GetEditor() end,
		onEditorPreClose =   function() return ide:GetEditor() end,
		onEditorClose =      function() return ide:GetEditor() end,
		onEditorNew =        function() return ide:GetEditor() end,
		onEditorPreSave =    function() return ide:GetEditor(),
			ide:GetDocument(ide:GetEditor()):GetFilePath() end,
		onEditorSave =       function() return ide:GetEditor() end,
		onEditorFocusLost =  function() return ide:GetEditor() end,
		onEditorFocusSet =   function() return ide:GetEditor() end,
		onEditorAction =     function() return ide:GetEditor(),
			wx.wxCommandEvent() end,
		onEditorKeyDown =    function() return ide:GetEditor(),
			wx.wxKeyEvent(1) end,
		onEditorCharAdded =  function() return ide:GetEditor(),
			wxstc.wxStyledTextEvent() end,
		onEditorUserlistSelection = function() return ide:GetEditor(), event end,
		onEditorUpdateUI =   function() return ide:GetEditor(), event end,
		onEditorPainted =    function() return ide:GetEditor(), event end,
		onEditorCallTip =    function() return ide:GetEditor(), tip,
			value, eval end,
		onFiletreeActivate = function() return ide:GetProjectTree(),
			wx.wxTreeEvent(), ide:GetProjectTree():GetRootItem() end,
		onFiletreeLDown =    function() return ide:GetProjectTree(),
			wx.wxMouseEvent(), ide:GetProjectTree():GetRootItem() end,
		onFiletreeRDown =    function() return ide:GetProjectTree(),
			wx.wxMouseEvent(), ide:GetProjectTree():GetRootItem() end,
		onMenuEditor =       function() return menu, ide:GetEditor(),
			wx.wxMenuEvent() end,
		onMenuEditorTab =    function() return menu, ide:GetEditorNotebook(),
			wx.wxMenuEvent(), 1 end,--index
		onMenuOutput =       function() return menu, ide:GetEditor(),
			wx.wxMenuEvent() end,
		onMenuFiletree =     function() return menu, tree, wx.wxMenuEvent() end,
		onMenuOutline =      function() return menu, tree, wx.wxMenuEvent() end,
		onMenuWatch =        function() return menu, tree, wx.wxMenuEvent() end,
		onProjectPreLoad =   function() return ide:GetProject() end,
		onProjectLoad =      function() return ide:GetProject() end,
		onProjectClose =     function() return ide:GetProject() end,
		onInterpreterLoad =  function() return ide:GetInterpreter() end,
		onInterpreterClose = function() return ide:GetInterpreter() end,
		onIdle =             function() return event end,
		onIdleOnce =         function() return event end,
		onAppFocusLost =     function() return ide:GetApp() end,
		onAppFocusSet =      function() return ide:GetApp() end,
		onAppLoad =          function() return ide:GetApp() end,
		onAppClose =         function() return ide:GetApp() end,
	}, {
		__index =          	 function() return end,
	} )


	UI.m_funcList:Connect( wx.wxEVT_COMMAND_LISTBOX_DOUBLECLICKED, function(event)
		local pname = UI.m_checkList1:GetStringSelection()
		local fname = UI.m_funcList:GetStringSelection()
		if fname=='' or pname=='' then return end
		local pkg = ide.packages[pname]
		if type(pkg)=='table' then
			if type(pkg[fname])=='function' then
				local res, ret = pcall(pkg[fname], pkg, eventsArgs[fname]())
				DisplayOutputLn("Call "..pname..':'..fname..'() '..
					iff(res, '= ', 'failed: ')..tostring(ret))
				on_selected()
				ide:GetMainFrame().uimgr:Update()
			else
				DisplayOutputLn("Can't call "..pname..'<'..type(pkg)..">:"..
					fname'(). This is not a package.')
			end
		else
			DisplayOutputLn("Can't call "..pname..'<'..type(pkg)..">:"..
				fname..'<'..type(pkg[fname])..'>(). This is not a function')
		end
	end )

	UI.MyDialog1:Connect( wx.wxEVT_SHOW, function(event)
		if UI.MyDialog1:IsShown() then on_selected() end
	end )


	UI.MyDialog1:SetSizer( UI.bSizer1 )
	UI.MyDialog1:Layout()
	function UI:Show(state)	return self.MyDialog1:Show(state)	end
	function UI:IsShown()	return self.MyDialog1:IsShown()	end
	function UI:Update()
		self.m_checkList1:Clear()

		for k, v in pairs(ide.packages) do
			if v.name and v.description then
				self.m_checkList1:Append(k)
			end
		end

		local packages_dir = pkg_path(nil, nil)
		local fi = wx.wxFindFirstFile(packages_dir..'*.lua.off', wx.wxFILE)
		while fi and #fi>0 do
			self.m_checkList1:Append(fi:sub(#packages_dir+1, #fi-8))
		 	fi = wx.wxFindNextFile()
		end

		on_selected()
	end

	return UI--.MyDialog1
end


return {
  name = "Plugins manager",
  description = "Plugins manager tool",
  author = "rst256",
  version = 0.1,
  dependencies = 1.0,

	onRegister = function(self)
		main_frame = CreateDialog(ide:GetMainFrame(), self)
		main_frame:Update()

		ide:AddTool(TR(self.name), function()
			main_frame:Show(not main_frame:IsShown())
		end)

		ide:GetToolBar():AddTool(wxID_toolbar_show_dialog, TR(self.name),
			wx.wxArtProvider.GetBitmap(wx.wxART_REPORT_VIEW,
			wx.wxART_MENU, ide:GetToolBar():GetToolBitmapSize()))
		ide:GetMainFrame():Connect(wxID_toolbar_show_dialog,
			wx.wxEVT_COMMAND_MENU_SELECTED, function()
				main_frame:Show(not main_frame:IsShown())
		end)
		ide:GetToolBar():Realize()
	end,

	onAppLoad = function(self)
		main_frame:Update()

--		local pkg_list = {}

--		for k, v in pairs(ide.packages) do
--			if v.name and v.description and v~=self then
--				table.insert(pkg_list, k)
--			end
--		end

--		local packages_dir = pkg_path(nil, nil)
--		local fi = wx.wxFindFirstFile(packages_dir..'*.lua.off', wx.wxFILE)
--		while fi and #fi>0 do
--			table.insert(pkg_list, fi:sub(#packages_dir+1, #fi-8))
--		 	fi = wx.wxFindNextFile()
--		end



--		main_frame = CreateDialog(ide:GetMainFrame(), self.name, pkg_list)

--		ide:AddTool(TR(self.name), function()
--			main_frame:Show(not main_frame:IsShown())
--		end)

--		ide:GetToolBar():AddTool(wxID_toolbar_show_dialog, TR(self.name),
--			wx.wxArtProvider.GetBitmap(wx.wxART_REPORT_VIEW,
--			wx.wxART_MENU, ide:GetToolBar():GetToolBitmapSize()))
--		ide:GetMainFrame():Connect(wxID_toolbar_show_dialog,
--			wx.wxEVT_COMMAND_MENU_SELECTED, function()
--				main_frame:Show(not main_frame:IsShown())
--		end)
--		ide:GetToolBar():Realize()

  end,
--	PackageUnRegister'plugins'
  onUnRegister = function(self)
		if main_frame then main_frame:Show(false) end
		ide:GetToolBar():DeleteTool(wxID_toolbar_show_dialog)
    ide:GetToolBar():Realize()
		ide:RemoveTool(TR(self.name))
		ide:GetMainFrame().uimgr:Update()
  end,
}

