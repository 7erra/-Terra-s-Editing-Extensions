/*
	Author: Terra

	Description:
	Handles the UI events of the New Config Viewer

	Parameter(s):
		0 (Optional):
			STRING - Mode in which to execute
		1 (Optional):
			ARRAY - Arguments for the mode
	Returns:
	ANYTHING, depending on mode
*/

/*
	Variables (namespace) - explanation:
	"_cfgArray" (Display) - Path to config (not to actual config, that is selected in the listbox)
	"BIS_fnc_configviewer_path" (profileNamespace) - same as _cfgArray, shared with old config viewer
	"BIS_fnc_configviewer_selected" (profileNamespace) - Selected listbox entry, shared with old config viewer
	"TER_3den_RscConfigViewer73_script" (uiNamespace) - This script
	"TER_3den_RscColorPicker_loadColor" (uiNamespace) - Set on preview of a color from the properties listbox
	"prevSearch" (Config search editbox) - ctrlText of the control to prevent searching when no new character was entered
	"update" (Favorites listbox) - Prevent firing of EH when the same class is selected
	"BIS_fnc_configviewer_bookmarks" (profileNamespace) - Array of favourites, format: [[[path], selected], ...]
	"TER_3den_configViewer73_dbSettings" (profileNamespace) - Scripted database with settings
*/
#include "\a3\ui_f\hpp\definedikcodes.inc"
#include "ctrls.inc"
#define SELF (uiNamespace getVariable ["TER_3den_RscConfigViewer73_script",{}])
params [["_mode", "create"],["_this",[]]];

switch _mode do {
	case "create":{
		//--- DEFAULT ACTION
		//--- Create display
		_parentDisplay = param [0, findDisplay ([49, 313] select is3DEN)];
		_parentDisplay createDisplay "TER_3den_RscDisplayConfigViewer73";
	};
	case "onLoad":{
		params ["_display"];
		//--- Init function
		//if (isNil {uiNamespace getVariable "TER_3den_RscConfigViewer73_script"}) then {
			uiNamespace setVariable ["TER_3den_RscConfigViewer73_script", compile preprocessFileLineNumbers "\TER_Editing\gui\scripts\RscConfigViewer73.sqf"];
		//};
		//--- Load settings
		_dbSettings = +(profileNamespace getVariable ["TER_3den_configViewer73_dbSettings",[]]);
		//--- Initialize Display
		_display displayAddEventHandler ["Unload",{
			["onUnload",_this] call SELF;
		}];
		_display displayAddEventHandler ["KeyDown",{
			["displayKey",_this] call SELF;
		}];
		//--- Directory Listbox
		_btnDirectory = _display displayCtrl IDC_CONFIG_BTNDIRECTORY;
		_btnDirectory ctrlAddEventHandler ["ButtonClick",{
			["dirUp",_this] call SELF;
		}];
		//--- Search edit configs
		_edSearchConfigs = _display displayCtrl IDC_CONFIG_EDCONFIGSEARCH;
		_edSearchConfigs ctrlSetTooltip "Search for config classes \nSeperate search terms with spaces \nUse ""-"" to exclude terms";
		_search = [_dbSettings, ["searchConfigs"], ""] call BIS_fnc_dbValueReturn;
		_edSearchConfigs ctrlSetText _search;
		ctrlSetFocus _edSearchConfigs;
		private _prevSearch = ["translateSearch", [_search]] call SELF;
		_edSearchConfigs setVariable ["prevSearch",_prevSearch];
		_edSearchConfigs ctrlAddEventHandler ["KeyDown",{
			["keySearch",_this] spawn SELF;
		}];
		_btnEndConfigSearch = _display displayCtrl IDC_CONFIG_BTNENDCONFIGSEARCH;
		_btnEndConfigSearch ctrlAddEventHandler ["ButtonClick",{
			["endConfigSearch",_this] call SELF;
		}];
		//--- Listbox configs
		_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
		_lbConfigs ctrlAddEventHandler ["LBDblClick",{
			["configsDblClick",_this] call SELF;
		}];
		_lbConfigs ctrlAddEventHandler ["LBSelChanged",{
			["configChange",_this] call SELF;
		}];
		_lbConfigs ctrlAddEventHandler ["KeyDown",{
			["lbConfigsKey",_this] call SELF;
		}];
		//--- Favorite button
		_btnFavorite = _display displayCtrl IDC_CONFIG_BTNFAVOR;
		_btnFavorite ctrlAddEventHandler ["ButtonClick",{
			["toggleFavorite",_this] call SELF;
		}];
		//--- Favorite combo
		_lbFavorites = _display displayCtrl IDC_CONFIG_LBFAVORITES;
		["fillFavorites",[_display]] call SELF;
		_lbFavorites ctrlAddEventHandler ["LBSelChanged",{
			["changeFavorite",_this] call SELF;
		}];
		//--- View mode toolbox
		_settingViewMode = [_dbSettings, ["viewMode"], 0] call BIS_fnc_dbValueReturn;
		_toolViewMode = _display displayCtrl IDC_CONFIG_TOOLVIEW;
		_toolViewMode lbSetCurSel _settingViewMode;
		_toolViewMode ctrlAddEventHandler ["ToolBoxSelChanged",{
			["changeView",_this] call SELF;
		}];
		//--- Inheritance toolbox
		_settingInheritance = [_dbSettings, ["inheritance"], 0] call BIS_fnc_dbValueReturn;
		_toolInheritance = _display displayCtrl IDC_CONFIG_TOOLINHERITANCE;
		_toolInheritance lbSetCurSel _settingInheritance;
		_toolInheritance ctrlAddEventHandler ["ToolBoxSelChanged",{
			["changeInheritance",_this] call SELF;
		}];
		//--- Show classes toolbox
		_settingShowClasses = [_dbSettings, ["showClasses"], 1] call BIS_fnc_dbValueReturn;
		_toolShowClasses = _display displayCtrl IDC_CONFIG_TOOLSHOWCLASSES;
		_toolShowClasses lbSetCurSel _settingShowClasses;
		_toolShowClasses ctrlAddEventHandler ["ToolBoxSelChanged",{
			["changeShowClasses",_this] call SELF;
		}];
		//--- Property search
		_settingPropSearch = [_dbSettings, ["searchProperties"], ""] call BIS_fnc_dbValueReturn;
		_edPropertySearch = _display displayCtrl IDC_CONFIG_EDPROPERTYSEARCH;
		_edPropertySearch ctrlSetText _settingPropSearch;
		_edPropertySearch setVariable ["prevSearch", _settingPropSearch];
		_edPropertySearch ctrlAddEventHandler ["KeyDown",{
			["edPropSearchKeyDown",_this] spawn SELF;
		}];
		//--- Properties listbox
		_lbProperties = _display displayCtrl IDC_CONFIG_LBPROPERTIES;
		_lbProperties ctrlAddEventHandler ["LBSelChanged",{
			["changeProperty",_this] call SELF;
		}];
		_lbProperties ctrlAddEventHandler ["LBDblClick",{
			["doubleClickProperties", _this] call SELF;
		}];
		//--- Error message
		_stxtError = _display displayCtrl IDC_CONFIG_STXTERROR;
		_stxtError ctrlAddEventHandler ["KillFocus",{
			["errorHide",_this] call SELF;
		}];
		_stxtError ctrlAddEventHandler ["MouseButtonDown",{
			["errorHide",_this] call SELF;
		}];
		//--- Info box
		_btnInfoOpen = _display displayCtrl IDC_CONFIG_BTNOPENINFO;
		_btnInfoOpen ctrlAddEventHandler ["ButtonClick",{
			["openInfo",ctrlParent (_this#0)] call SELF;
		}];
		_grpInfo = _display displayCtrl IDC_CONFIG_GRPINFO;
		_btnInfoOk = _display displayCtrl IDC_CONFIG_BTNINFOOK;
		_btnInfoOk ctrlAddEventHandler ["ButtonClick",{
			["infoClose",[ctrlParentControlsGroup (_this#0)]] call SELF;
		}];
		_stxtInfo = _display displayCtrl IDC_CONFIG_STXTINFO;
		_stxtInfo ctrlSetStructuredText parseText call compile loadFile "\TER_Editing\gui\scripts\RscConfigViewer73\info.sqf";
		//--- Parents config combo
		_comboParents = _display displayCtrl IDC_CONFIG_COMBOPARENTS;
		_comboParents ctrlAddEventHandler ["LBSelChanged",{
			["gotoParent",_this] call SELF;
		}];
		//--- Preview group
		_grpPreview = _display displayCtrl IDC_CONFIG_GRPPREVIEW;
		_grpPicturePreview = _grpPreview controlsGroupCtrl IDC_CONFIG_GRPPICPREVIEW;
		_picPreview = _grpPreview controlsGroupCtrl IDC_CONFIG_PICPREVIEW;
		_picPreview setVariable ["startpos", ctrlPosition _picPreview];
		_sliderPicPreviewScale = _display displayCtrl IDC_CONFIG_SLIDERPREVIEWSCALE;
		_sliderPicPreviewScale sliderSetRange [0,1];
		_sliderPicPreviewScale sliderSetSpeed [0.01,0.01];
		_sliderPicPreviewScale ctrlAddEventHandler ["SliderPosChanged",{
			["previewPicScaleChange",_this] call SELF;
		}];
		_settingPreviewScale = [_dbSettings, ["picPreviewScale"], 1] call BIS_fnc_dbValueReturn;
		_sliderPicPreviewScale sliderSetPosition _settingPreviewScale;
		["previewPicScaleChange",[_sliderPicPreviewScale, _settingPreviewScale]] call SELF;
		_btnPreviewClose = _display displayCtrl IDC_CONFIG_BTNPREVIEWCLOSE;
		_btnPreviewClose ctrlAddEventHandler ["ButtonClick",{
			ctrlParentControlsGroup (_this#0) ctrlShow false;
		}];
		//--- History group
		_grpHistory = _display displayCtrl IDC_CONFIG_GRPHISTORY;
		_lbHistory = _display displayCtrl IDC_CONFIG_LBHISTORY;
		_lbHistory ctrlAddEventHandler ["LBDblClick",{
			["lbDoubleClickHistory", _this] call SELF;
		}];
		//--- Load previous config
		_cfgArray = +(profilenamespace getvariable ["BIS_fnc_configviewer_path",[]]);
		_cfgSelected = profilenamespace getvariable ["BIS_fnc_configviewer_selected",""];
		_display setVariable ["_cfgArray",_cfgArray];
		["updateClasses",[_display, _cfgSelected]] spawn SELF;
	};
	case "collectHistory":{
		params ["_cfgArray"];
		_history = uiNamespace getVariable ["TER_3den_configViewer73_history",[]];
		_cfgConfig = [_cfgArray] call BIS_fnc_configPath;
		if (!isClass _cfgConfig OR count _cfgArray == 0) exitWith {
			_history
		};
		_history pushBackUnique _cfgArray;
		uiNamespace setVariable ["TER_3den_configViewer73_history",_history];
		_history
	};
	case "openHistory":{
		params ["_display"];
		_history = +(uiNamespace getVariable ["TER_3den_configViewer73_history",[]]);
		_historyString = _history apply {[_x, "STRING"] call BIS_fnc_configPath};
		_lbHistory = _display displayCtrl IDC_CONFIG_LBHISTORY;
		{
			private _ind = _lbHistory lbAdd _x;
			_lbHistory lbSetData [_ind, str (_history select _forEachIndex)];
		} forEach _historyString;
	};
	case "lbDoubleClickHistory":{
		params ["_lbHistory","_ind"];
		_display = ctrlParent _lbHistory;
		private _cfgArray = _lbHistory lbData _ind;
		private _cfgArray = parseSimpleArray _cfgArray;
		private _selClass = _cfgArray deleteAt (count _cfgArray -1);
		["updateClasses",[_display, _selClass]] call SELF;
	};
	case "previewPicScaleChange":{
		params ["_sliderPicPreviewScale","_slPos"];
		_display = ctrlParent _sliderPicPreviewScale;
		_picPreview = _display displayCtrl IDC_CONFIG_PICPREVIEW;
		//--- Set scale of the picture
		_startPos = _picPreview getVariable "startpos";
		_startPos params ["","","_wPic","_hPic"];
		_wRel = _slPos * _wPic;
		_hRel = _slPos * _hPic;
		_picPreview ctrlSetPosition [
			1.3/2 * UI_GRID_W + _wPic/2 - _wRel/2,
			_hPic/2 - _hRel/2,
			_wRel,
			_hRel
		];
		_picPreview ctrlCommit 0;
	};
	case "findconfig":{
		//--- Called from the 3den context menu
		//--- modified version of a3\3den\functions\fn_3denentitiymenu.sqf
		_input = uinamespace getvariable ["bis_fnc_3DENEntityMenu_data",[]];
		_entity = _input param [1,objnull];
		switch (typename _entity) do {
			case (typename objnull): {
				with profileNamespace do 
				{
					BIS_fnc_configviewer_path = ['configfile','CfgVehicles'];
					BIS_fnc_configviewer_selected = (_entity get3DENAttribute "ItemClass") select 0;
				};
				[] call TER_fnc_configViewer73;
			};
			case (typename []): {
				scopename "findconfig_waypoint";
				_type = (_entity get3DENAttribute "ItemClass") select 0;
				{
					_category = configname  _x;
					{
						if (configname _x == _type) then {
							with profileNamespace do 
							{
								BIS_fnc_configviewer_path = ['configfile','CfgVehicles'];
								BIS_fnc_configviewer_selected = (_entity get3DENAttribute "ItemClass") select 0;
							};
							[] call TER_fnc_configViewer73;
							breakto "findconfig_waypoint";
						};
					} foreach (configproperties [_x,"isclass _x"]);
				} foreach (configproperties [configfile >> "cfgwaypoints","isclass _x"]);
			};
			case (typename ""): {
				[] call TER_fnc_configViewer73;

				_type = (_entity get3DENAttribute "markerType") select 0;
				if (_type == 0) then {
					with profileNamespace do 
					{
						BIS_fnc_configviewer_path = ['configfile','CfgVehicles'];
						BIS_fnc_configviewer_selected = (_entity get3DENAttribute "ItemClass") select 0;
					};
				} else {
					with profileNamespace do 
					{
						BIS_fnc_configviewer_path = ['configfile','CfgVehicles'];
						BIS_fnc_configviewer_selected = (_entity get3DENAttribute "ItemClass") select 0;
					};
				};
			};
		};
	};
	case "lbConfigsKey":{
		params ["_lbConfigs", "_key", "_shift", "_ctrl", "_alt"];
		if (_ctrl && _key == DIK_C) exitWith {
			private _selClass = _lbConfigs lbText lbCurSel _lbConfigs;
			copyToClipboard _selClass;
			_lbConfigs ctrlSetFade 0.8;
			_lbConfigs ctrlCommit 0;
			_lbConfigs ctrlSetFade 0;
			_lbConfigs ctrlCommit 0.5;
			true
		};
		false
	};
	case "openInfo":{
		params ["_display"];
		_grpInfo = _display displayCtrl IDC_CONFIG_GRPINFO;
		_btnInfoOk = _display displayCtrl IDC_CONFIG_BTNINFOOK;
		_grpInfo ctrlShow true;
		ctrlSetFocus _grpInfo;
	};
	case "infoClose":{
		params ["_grpInfo"];
		_grpInfo ctrlShow false;
	};
	case "displayKey":{
		params ["_display", "_key", "_shift", "_ctrl", "_alt"];
		_progLoading = _display displayCtrl IDC_CONFIG_PROGLOADING;
		_isLoading = progressPosition _progLoading != 1;
		if (_ctrl && _shift && _key == DIK_F) exitWith {
			ctrlSetFocus (_display displayCtrl IDC_CONFIG_EDPROPERTYSEARCH);
			true
		};
		if (_ctrl && _key == DIK_F && !_isLoading) exitWith {
			ctrlSetFocus (_display displayCtrl IDC_CONFIG_EDCONFIGSEARCH);
			true
		};
		if (_ctrl && _key == DIK_Q && !_isLoading) then {
			["dirUp",[_display displayCtrl IDC_CONFIG_BTNDIRECTORY]] call SELF;
			true
		};
		if (false && _ctrl && _key == DIK_C) exitWith {
			_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
			_selClass = _lbConfigs lbText lbCurSel _lbConfigs;
			copyToClipboard _selClass;
		};
		if (_ctrl && _key == DIK_H) exitWith {
			_grpHistory = _display displayCtrl IDC_CONFIG_GRPHISTORY;
			_grpHistory ctrlShow true;
			true
		};
		if (_key == DIK_ESCAPE) exitWith {
			_grpInfo = _display displayCtrl IDC_CONFIG_GRPINFO;
			if (ctrlShown _grpInfo) exitWith {
				_grpInfo ctrlShow false;
				true
			};
			_grpPreview = _display displayCtrl IDC_CONFIG_GRPPREVIEW;
			if (ctrlShown _grpPreview) exitWith {
				_grpPreview ctrlShow false;
				true
			};
			_grpHistory = _display displayCtrl IDC_CONFIG_GRPHISTORY;
			if (ctrlShown _grpHistory) exitWith {
				_grpHistory ctrlShow false;
				true
			};
			false
		};
		false
	};
	case "doubleClickProperties":{
		//--- Double click to preview entry
		params ["_lbProperties","_ind"];
		_display = ctrlParent _lbProperties;
		_data = _lbProperties lbData _ind;
		_cfgArray = +(_display getVariable ["_cfgArray",[]]);
		_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
		_selClass = _lbConfigs lbText lbCurSel _lbConfigs;
		_cfgArray append [_selClass];
		_cfgConfig = [_cfgArray] call BIS_fnc_configPath;
		_propCfg = _cfgConfig >> _data;
		if (isClass _propCfg) exitWith {
			//--- Load class
			(_display displayCtrl IDC_CONFIG_EDCONFIGSEARCH) ctrlSetText "";
			_display setVariable ["_cfgArray",_cfgArray];
			["updateClasses",[_display, _data]] call SELF;
		};
		_fncHideGrps = {
			[
				IDC_CONFIG_GRPPICPREVIEW,
				IDC_CONFIG_GRPCOLORPICKER
			] apply {
				private _ctrl = _this displayCtrl _x;
				_ctrl ctrlShow false;
			};
		};
		if (isArray _propCfg) exitWith {
			private _value = getArray _propCfg;
			if ({_x isEqualType 0} count _value in [3,4]) exitWith {
				//--- Color RGB or RGBA
				_grpColorPicker = _display displayCtrl IDC_CONFIG_GRPCOLORPICKER;
				["loadColor", [_grpColorPicker, _value]] call (uiNamespace getVariable ["TER_3den_RscColorPicker_script",{}]);
				_grpPreview = _display displayCtrl IDC_CONFIG_GRPPREVIEW;
				_grpPreview ctrlShow true;
				_display call _fncHideGrps;
				_grpColorPicker ctrlShow true;
				ctrlSetFocus _grpColorPicker;
				true
			};
			false
		};
		if (isText _propCfg) exitWith {
			private _value = getText _propCfg;
			if (_value select [count _value -4, 4] in [".jpg", ".paa"]) exitWith {
				//--- Texture
				_grpPreview = _display displayCtrl IDC_CONFIG_GRPPREVIEW;
				_grpPreview ctrlShow true;
				_display call _fncHideGrps;
				_picPreview = _display displayCtrl IDC_CONFIG_PICPREVIEW;
				_picPreview ctrlSetText _value;
				_grpPicturePreview = _display displayCtrl IDC_CONFIG_GRPPICPREVIEW;
				_grpPicturePreview ctrlShow true;
				ctrlSetFocus _grpPicturePreview;
				true
			};
			false
		};
		//--- No special config, display entry as text?
	};
	case "edPropSearchKeyDown":{
		//--- Key was pressed while search is focused
		params ["_edPropertySearch"];
		_filter = ctrlText _edPropertySearch;
		if (_filter == _edPropertySearch getVariable ["prevSearch",""]) exitWith {};
		_edPropertySearch setVariable ["prevSearch",_filter];
		_display = ctrlParent _edPropertySearch;
		_lbProperties = _display displayCtrl IDC_CONFIG_LBPROPERTIES;
		["updateProperties",[_display]] call SELF;
	};
	case "updateProperties":{
		params ["_display"];
		//--- LB view
		_lbProperties = _display displayCtrl IDC_CONFIG_LBPROPERTIES;
		_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
		_edPropertySearch = _display displayCtrl IDC_CONFIG_EDPROPERTYSEARCH;
		_toolInheritance = _display displayCtrl IDC_CONFIG_TOOLINHERITANCE;
		_toolShowClasses = _display displayCtrl IDC_CONFIG_TOOLSHOWCLASSES;
		private _ind = lbCurSel _lbConfigs;
		private _selConfig = _lbConfigs lbText _ind;
		if (_selConfig == "") exitWith {lbClear _lbProperties};
		private _cfgArray = _display getVariable ["_cfgArray",[]];
		private _newConfig = if (count _cfgArray == 0) then {
			call compile (_lbConfigs lbText _ind)
		} else {
			_cfgConfig = [_cfgArray] call BIS_fnc_configPath;
			_cfgName = _lbConfigs lbText _ind;
			_cfgConfig >> _cfgName
		};
		private _includeInherit = lbCurSel _toolInheritance == 0;
		private _condFilter = ["true","!isClass _x"] select (lbCurSel _toolShowClasses == 1);
		private _properties = configProperties[_newConfig, _condFilter, _includeInherit];
		private _filter = toLower ctrlText _edPropertySearch;
		private _propertyNames = _properties apply {configName _x};
		_propertyNames sort true;
		lbClear _lbProperties;
		{
			_alpha = 1;
			_c = 0.4;
			_cfgProp = _newConfig >> _x;
			_paramsLB = switch true do {
				case (isText _cfgProp): {[
					str getText _cfgProp, // value
					[1,_c,_c,_alpha] // color
				]};
				case (isNumber _cfgProp):{[
					getNumber _cfgProp,
					[_c,1,_c,_alpha]
				]};
				case (isArray _cfgProp):{
					//--- Arrays need some more love
					private _strArray = str getArray _cfgProp;
					[
					_strArray select [1, count _strArray -2],
					[_c,_c,1,_alpha],
					"%1[] = {%2};"
				]};
				case (isClass _cfgProp):{[
					_x,
					[1,_c,1,_alpha],
					"class %1 {...};"
				]};
			};
			private _entry = format[_paramsLB param [2, "%1 = %2;"], _x, _paramsLB#0];
			if (_filter in toLower _entry) then {
				private _ind = _lbProperties lbAdd _entry;
				_lbProperties lbSetColor [_ind, _paramsLB#1];
				_lbProperties lbSetData [_ind, _x];
			};
		} forEach _propertyNames;
		if (isNil {_lbProperties getVariable "loadedInd"}) then {
			private _dbSettings = profileNamespace getVariable ["TER_3den_configViewer73_dbSettings",[]];
			private _loadInd = [_dbSettings, ["selectedProperty"], -1] call BIS_fnc_dbValueReturn;
			_lbProperties lbSetCurSel _loadInd;
			_lbProperties setVariable ["loadedInd", true];
		};
		//lbSort _lbProperties;
	};
	case "changeProperty":{
		params ["_lbProperties","_ind"];
		_display = ctrlParent _lbProperties;
		["updateEdCfgPath",[_display]] call SELF;
		_edPropValue = _display displayCtrl IDC_CONFIG_EDPROPVALUE;
		_edPropValue ctrlSetText (_lbProperties lbText _ind);
	};
	case "changeShowClasses":{
		params ["_toolShowClasses","_ind"];
		_display = ctrlParent _toolShowClasses;
		["updateProperties",[_display]] call SELF;
	};
	case "changeInheritance":{
		params ["_toolInheritance","_ind"];
		_display = ctrlParent _toolInheritance;
		["updateProperties",[_display]] call SELF;
	};
	case "changeFavorite":{
		params ["_lbFavorites","_ind"];
		if (
			!isNil {_lbFavorites getVariable "update"} OR
			lbCurSel _lbFavorites == -1
		) exitWith {};
		_display = ctrlParent _lbFavorites;
		_edSearchConfigs = _display displayCtrl IDC_CONFIG_EDCONFIGSEARCH;
		//_edSearchConfigs ctrlSetText "";
		_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
		_cfgString = _lbFavorites lbText _ind;
		_cfgArray = [_cfgString, []] call BIS_fnc_configPath;
		if (!isClass ([_cfgArray] call BIS_fnc_configPath)) exitWith {
			["showError", [_display, "Favourite is not a class."]] call SELF;
		};
		_cfgSelected = _cfgArray deleteAt (count _cfgArray -1);
		_display setVariable ["_cfgArray",_cfgArray];
		["updateClasses",[_display, _cfgSelected]] spawn SELF;
	};
	case "errorHide":{
		params ["_stxtError"];
		_stxtError ctrlSetFade 1;
		_stxtError ctrlSetPositionH 0;
		_stxtError ctrlCommit 0;
	};
	case "toggleFavorite":{
		params ["_btnFavorite"];
		_display = ctrlParent _btnFavorite;
		_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
		_lbFavorites = _display displayCtrl IDC_CONFIG_LBFAVORITES;
		_iconPath = "\a3\ui_f\data\gui\rsc\rscdisplaymultiplayer\";
		_favIcon = _iconPath +"mp_serverlike_ca.paa";
		_normalIcon = _iconPath +"mp_serverempty_ca.paa";
		_cfgArray = +(_display getVariable ["_cfgArray",[]]);
		if (lbCurSel _lbConfigs > -1) then {
			_cfgArray pushBack (_lbConfigs lbText lbCurSel _lbConfigs);
		};
		_cfgString = [_cfgArray, "STRING"] call BIS_fnc_configPath;
		_currentFavorites = profileNamespace getVariable ["BIS_fnc_configviewer_bookmarks",[]];
		//[[["configfile","CfgWeapons"],["currentweapon vehicle cameraon"]],[["configfile","CfgMagazines","30Rnd_556x45_Stanag"],"30Rnd_556x45_Stanag"],[["configfile","CfgVehicles","B_Soldier_F"],"B_Soldier_F"],[["configfile","CfgVehicles","Land_Laptop_unfolded_F"],"Land_Laptop_unfolded_F"]]
		if (ctrlText _btnFavorite == _normalIcon) then {
			//--- Add to favorites
			_btnFavorite ctrlSetText _favIcon;
			_currentFavorites pushBack [_cfgArray, _cfgArray#((count _cfgArray) -1)];
			_lbFavorites setVariable ["update",false];
			private _ind = _lbFavorites lbAdd _cfgString;
			_lbFavorites lbSetCurSel _ind;
			_lbFavorites setVariable ["update",nil];
		} else {
			//--- Remove from favorites
			_btnFavorite ctrlSetText _normalIcon;
			_lbFavorites setVariable ["update",false];
			_currentFavorites deleteAt (lbCurSel _lbFavorites);
			lbClear _lbFavorites;
			_lbFavorites lbSetCurSel -1;
			["fillFavorites",[_display]] call SELF;
			_lbFavorites setVariable ["update",nil];
		};
		profileNamespace setVariable ["BIS_fnc_configviewer_bookmarks",_currentFavorites];
		saveProfileNamespace;
	};
	case "configChange":{
		//--- New config selected from list
		params ["_lbConfigs","_ind"];
		_display = ctrlParent _lbConfigs;
		_selectClass = _lbConfigs lbText _ind;
		_currentFavorites = +(profileNamespace getVariable ["BIS_fnc_configviewer_bookmarks",[]]);
		_currentFavorites = _currentFavorites apply {(_x#0) apply {toLower _x}};
		_cfgArray = +(_display getVariable ["_cfgArray",[]]);
		_cfgArray pushBack _selectClass;
		_cfgArray = _cfgArray apply {toLower _x};
		private _cfgConfig = [_cfgArray] call BIS_fnc_configPath;
		_lbFavorites = _display displayCtrl IDC_CONFIG_LBFAVORITES;
		_lbFavorites setVariable ["update",false];
		_favInd = _currentFavorites find _cfgArray;
		if (_favInd < 0) then {
			//--- Stupid workaround to select non existing favorite
			lbClear _lbFavorites;
			_lbFavorites lbSetCurSel _favInd;
			["fillFavorites",[_display]] call SELF;
		} else {
			_lbFavorites lbSetCurSel _favInd;
		};
		_lbFavorites setVariable ["update",nil];
		_favIcon = [
			"\a3\ui_f\data\gui\rsc\rscdisplaymultiplayer\mp_serverempty_ca.paa",
			"\a3\ui_f\data\gui\rsc\rscdisplaymultiplayer\mp_serverlike_ca.paa"
		] select (_cfgArray in _currentFavorites);
		_btnFavorite = _display displayCtrl IDC_CONFIG_BTNFAVOR;
		_btnFavorite ctrlSetText _favIcon;
		["updateEdCfgPath",[_display]] call SELF;
		_lbProperties = _display displayCtrl IDC_CONFIG_LBPROPERTIES;
		if (!isNil {_lbProperties getVariable "loadedInd"}) then {
			_lbProperties lbSetCurSel -1;
		};
		["updateProperties", [_display]] call SELF;
		//--- Update parents
		private _parents = [_cfgConfig >> _selectClass] call BIS_fnc_returnParents;
		_parents deleteAt 0;
		reverse _parents;
		_comboParents = _display displayCtrl IDC_CONFIG_COMBOPARENTS;
		lbClear _comboParents;
		_comboParents lbAdd format ["%1",count _parents];
		_comboParents lbSetCurSel 0;
		{
			private _ind = _comboParents lbAdd ([_x, "STRING"] call BIS_fnc_configPath);
			_comboParents lbSetData [_ind, str ([_x] call BIS_fnc_configPath)];
		} forEach _parents;
		//--- Save to history
		["collectHistory", [_cfgArray]] call SELF;
	};
	case "gotoParent":{
		params ["_comboParents","_ind"];
		_display = ctrlParent _comboParents;
		_cfgArray = _comboParents lbData _ind;
		if (_cfgArray == "") exitWith {};
		_cfgArray = parseSimpleArray _cfgArray;
		_selClass = _cfgArray deleteAt (count _cfgArray -1);
		_display setVariable ["_cfgArray", _cfgArray];
		["updateClasses",[_display, _selClass]] spawn SELF;
	};
	case "fillFavorites":{
		params ["_display"];
		_lbFavorites = _display displayCtrl IDC_CONFIG_LBFAVORITES;
		//_lbFavorites lbAdd "";
		lbClear _lbFavorites;
		_currentFavorites = +(profileNamespace getVariable ["BIS_fnc_configviewer_bookmarks",[]]);
		_currentFavorites apply {
			_path = _x#0;
			_strPath = [_path, "STRING"] call BIS_fnc_configPath;
			_ind = _lbFavorites lbAdd _strPath;
		};
	};
	case "endConfigSearch":{
		params ["_btnEndConfigSearch"];
		_display = ctrlParent _btnEndConfigSearch;
		_edSearchConfigs = _display displayCtrl IDC_CONFIG_EDCONFIGSEARCH;
		if (ctrlText _edSearchConfigs == "") exitWith {};
		_edSearchConfigs ctrlSetText "";
		["updateClasses",[_display]] spawn SELF;
	};
	case "updateClasses":{
		params ["_display",["_selectClass",""],["_allowLoading",true]];
		_progLoading = _display displayCtrl IDC_CONFIG_PROGLOADING;
		_stxtProgress = _display displayCtrl IDC_CONFIG_STXTPROGRESS;
		_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
		_edSearchConfigs = _display displayCtrl IDC_CONFIG_EDCONFIGSEARCH;
		//--- Variables
		_cfgArray = _display getVariable ["_cfgArray",[]];
		_cfgConfig = [_cfgArray] call BIS_fnc_configPath;
		_filter = tolower ctrlText _edSearchConfigs;
		if (
			_cfgArray isEqualTo (_display getVariable ["_cfgArray_old",-1]) &&
			_selectClass != ""
		) exitWith {
			//--- Same config path as previously
			for "_ind" from 0 to (lbSize _lbConfigs -1) do {
				if (_lbConfigs lbText _ind == _selectClass) exitWith {
					_lbConfigs lbSetCurSel _ind;
				};
			};
		};
		//--- TODO: Implement caching listboxes?
		_fncLoad = {
			params ["_display", "_enable"];
			{
				private _ctrl = _display displayCtrl _x;
				_ctrl ctrlEnable _enable;
			} forEach
			[
				IDC_CONFIG_BTNDIRECTORY,
				IDC_CONFIG_LBFAVORITES,
				IDC_CONFIG_COMBOPARENTS,
				IDC_CONFIG_LBCONFIGS
			];
		};
		private _dTime = diag_tickTime;
		if (_allowLoading) then {
			//--- Start loading screen
			_stxtProgress ctrlSetStructuredText parseText "WORKING...";
			[_display, false] call _fncLoad;
			_progLoading progressSetPosition 0;
		};
		_display setVariable ["_cfgArray_old", +_cfgArray];
		_cfgString = [_cfgArray, "STRING"] call BIS_fnc_configPath;
		private _classes = if (count _cfgArray == 0) then {
			//--- The most upper part of the cfg hirarchy
			["configFile","missionConfigFile","campaignConfigFile"];
		} else {
			_configFilter = ["translateSearch", [_filter]] call SELF;
			(configProperties [_cfgConfig, _configFilter, true]) apply {
				configName _x
			};
		};
		_classes sort true;
		private _countClasses = count _classes;
		lbClear _lbConfigs;
		private _foundInd = false;
		_exit = false;
		{
			if (
				isNull _display OR
				_filter != ctrlText _edSearchConfigs
			) exitWith {_exit = true};
			_ind = _lbConfigs lbAdd _x;
			_subPath = _cfgConfig >> _x;
			if (toLower (_lbConfigs lbText _ind) == toLower _selectClass) then {
				_lbConfigs lbSetCurSel _ind;
				_foundInd = true;
			};
			//--- Detect subclasses
			_hasSubclasses = false;
			_parents = [_subPath] call bis_fnc_returnparents;
			{
				for "_s" from 0 to (count _x - 1) do {
					if (isclass (_x select _s)) exitwith {_hasSubclasses = true;_s = count _x;};
				};
				if (_hasSubclasses) exitwith {};
			} foreach _parents;
			if (_hasSubclasses) then {
				_lbConfigs lbSetTextRight [_ind, "+"];
			};
			if (_allowLoading) then {
				_stxtProgress ctrlSetStructuredText parseText format ["(%1 / %2)",_forEachIndex +1, _countClasses];
				_progLoading progressSetPosition ((_forEachIndex +1)/_countClasses);
			};
		} forEach _classes;
		if (_exit) exitWith {};
		if (!_foundInd) then {_lbConfigs lbSetCurSel 0};
		//--- End loading screen
		if (_allowLoading) then {
			_plural = ["", "es"] select (_countClasses > 1);
			_stxtProgress ctrlSetStructuredText parseText format ["%1 class%2, %3 s", _countClasses, _plural, (diag_tickTime - _dTime) toFixed 3];
			[_display, true] call _fncLoad;
		};
		_btnDirectory = _display displayCtrl IDC_CONFIG_BTNDIRECTORY;
		if (count _cfgArray == 0) then {
			//--- The most upper part of the cfg hirarchy
			_btnDirectory ctrlSetText "(Default directory)";
			_btnDirectory ctrlEnable false;
		} else {
			_btnDirectory ctrlEnable true;
			_btnDirectory ctrlSetText format ["< %1", _cfgArray select (count _cfgArray -1)];
		};
	};
	case "translateSearch":{
		params ["_filter"];
		private _configFilter = "isClass _x";
		_filterArray = _filter splitString " ";
		_filterArray apply {
			_filterWOsymbol = _x select [1, count _x -1];
			_filterWOsymbolArray = toArray _filterWOsymbol;
			_addFilter = switch (_x select [0,1]) do {
				//--- Find special search symbols
				case "-":{
					//--- Exclude
					if (count _filterWOsymbol == 0) exitWith {""};
					format [" && !('%1' in toLower configName _x)", toLower _filterWOsymbol];
				};
				/* case "\":{
					//--- Property
					_tempAddFilter = _filterWOsymbol splitString "=";
					if (count _tempAddFilter < 2) exitWith {""};
					_tempAddFilter params ["_prop", "_value"];
					if ( // waiting for \prop="value"
						(_value select [0, 1] == """" && 
						_value select [count _value -1, 1] != """") OR // \prop="val <- still writing
						_value == """" // prop=" <- first and last char are "
					) exitWith {""};// Input is not copmleted
					_typeValue = typeName call compile _value;
					_typeValue = _typeValue call {
						if (_this == typeName 1) exitWith {"Number"};
						if (_this == typeName "") exitWith {"Text"};
						"Array"
					};
					// workaround for configproperties returning inherited classes AND properties
					// trying to get a property from a property spams the debug log
					format [
						" && if (isClass _x) then {get%1  (_x >> ""%2"") isEqualTo %3} else {false}", 
						_typeValue, 
						_prop, 
						_value
					];
				}; */
				default {
					format [" && '%1' in toLower configName _x", toLower _x];
				};
			};
			_configFilter = _configFilter + _addFilter;
		};
		_configFilter
	};
	case "configsDblClick":{
		params ["_lbConfigs","_ind"];
		_display = ctrlParent _lbConfigs;
		_entry = _lbConfigs lbText _ind;
		_cfgArray = _display getVariable ["_cfgArray",[]];
		_cfgConfig = if (count _cfgArray == 0) then {
			[[_entry]]
		} else {
			[_cfgArray +[_entry]]
		} call BIS_fnc_configPath;
		if (count configProperties [_cfgConfig, "isClass _x", true] == 0) exitWith {
			//--- Don't open configs without subclasses
			["showError",[_display, "The selected config has no sub classes."]] call SELF;
		};
		_edSearchConfigs = _display displayCtrl IDC_CONFIG_EDCONFIGSEARCH;
		_edSearchConfigs ctrlSetText "";
		_cfgArray pushBack _entry;
		_display setVariable ["_cfgArray", _cfgArray];
		["updateClasses",[_display]] spawn SELF;
	};
	case "showError":{
		params ["_display","_errorMessage"];
		_stxtError = _display displayCtrl IDC_CONFIG_STXTERROR;
		_errorMessage = "<t size='1.25'>ERROR</t><br/>" +_errorMessage;
		_stxtError ctrlSetFade 0;
		_stxtError ctrlSetStructuredText parseText _errorMessage;
		_stxtError ctrlSetPosition getMousePosition;
		_stxtError ctrlSetPositionH ctrlTextHeight _stxtError;
		_stxtError ctrlCommit 0;
		ctrlSetFocus _stxtError;
		_stxtError spawn {
			while {ctrlFade _this < 1 && !isNull _this} do {
				_this ctrlSetPosition getMousePosition;
				_this ctrlCommit 0;
				_frame = diag_frameNo;
				waitUntil {
					_frame != diag_frameNo && 
					!(ctrlPosition _this isEqualTo getMousePosition) ||
					isNull _this
				};
			};
		};
	};
	case "keySearch":{
		params ["_edSearchConfigs","_key"];
		//if !(_key in [DIK_NUMPADENTER, DIK_RETURN]) exitWith {};
		_filter = ctrlText _edSearchConfigs;
		_configFilter = ["translateSearch", [_filter]] call SELF;
		if (_configFilter == _edSearchConfigs getVariable ["prevSearch",""]) exitWith {false};
		_edSearchConfigs setVariable ["prevSearch", _configFilter];
		_display = ctrlParent _edSearchConfigs;
		//_edSearchConfigs ctrlEnable false;
		["updateClasses",[_display, nil, true]] call SELF;
		//_edSearchConfigs ctrlEnable true;
		//ctrlSetFocus _edSearchConfigs;
		false
	};
	case "dirUp":{
		params ["_btnDirectory"];
		private ["_display", "_edSearchConfigs","_cfgArray","_cfgClass"];
		_display = ctrlParent _btnDirectory;
		_edSearchConfigs = _display displayCtrl IDC_CONFIG_EDCONFIGSEARCH;
		_edSearchConfigs ctrlSetText "";
		_cfgArray = _display getVariable ["_cfgArray",[]];
		_cfgClass = _cfgArray deleteAt (count _cfgArray -1);
		//_display setVariable ["_cfgArray",_cfgArray];
		["updateClasses",[_display, _cfgClass]] spawn SELF;
	};
	case "updateEdCfgPath":{
		params ["_display"];
		_edCfgPath = _display displayCtrl IDC_CONFIG_EDCFGPATH;
		_cfgArray = +(_display getVariable ["_cfgArray",[]]);
		_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
		_class = _lbConfigs lbText lbCurSel _lbConfigs;
		if (_class != "") then {
			_cfgArray pushBack _class;
		};
		_lbProperties = _display displayCtrl IDC_CONFIG_LBPROPERTIES;
		_prop = _lbProperties lbData lbCurSel _lbProperties;
		if (_prop != "") then {
			_cfgArray pushBack _prop;
		};
		_cfgString = [_cfgArray, "STRING"] call BIS_fnc_configPath;
		_edCfgPath ctrlSetText _cfgString;
	};
	case "onUnload":{
		params ["_display", "_exitCode"];
		_lbConfigs = _display displayCtrl IDC_CONFIG_LBCONFIGS;
		_cfgArray = _display getVariable ["_cfgArray",[]];
		_cfgSelected = _lbConfigs lbText lbCurSel _lbConfigs;
		if (_cfgSelected == "" && count _cfgArray > 0) then {
			_cfgSelected = _cfgArray deleteAt (count _cfgArray -1);
		};
		profileNamespace setVariable ["BIS_fnc_configviewer_path",_cfgArray];
		profilenamespace setvariable ["BIS_fnc_configviewer_selected",_cfgSelected];
		//--- Save Settings
		_dbSettings = profileNamespace getVariable ["TER_3den_dbSettings",[]];
		//--- Config Search
		_edSearchConfigs = _display displayCtrl IDC_CONFIG_EDCONFIGSEARCH;
		[_dbSettings, ["searchConfigs"], ctrlText _edSearchConfigs] call BIS_fnc_dbValueSet;
		//--- View mode
		_toolViewMode = _display displayCtrl IDC_CONFIG_TOOLVIEW;
		[_dbSettings, ["viewMode"], lbCurSel _toolViewMode] call BIS_fnc_dbValueSet;
		//--- Inheritance
		_toolInheritance = _display displayCtrl IDC_CONFIG_TOOLINHERITANCE;
		[_dbSettings, ["inheritance"], lbCurSel _toolInheritance] call BIS_fnc_dbValueSet;
		//--- Show classes
		_toolShowClasses = _display displayCtrl IDC_CONFIG_TOOLSHOWCLASSES;
		[_dbSettings, ["showClasses"], lbCurSel _toolShowClasses] call BIS_fnc_dbValueSet;
		//--- Property search
		_edPropSearch = _display displayCtrl IDC_CONFIG_EDPROPERTYSEARCH;
		[_dbSettings, ["searchProperties"], ctrlText _edPropSearch] call BIS_fnc_dbValueSet;
		//--- Selected property index
		_lbProperties = _display displayCtrl IDC_CONFIG_LBPROPERTIES;
		[_dbSettings, ["selectedProperty"], lbCurSel _lbProperties] call BIS_fnc_dbValueSet;
		//--- Preview picture scale
		_sliderPicPreviewScale = _display displayCtrl IDC_CONFIG_SLIDERPREVIEWSCALE;
		[_dbSettings, ["picPreviewScale"], sliderPosition _sliderPicPreviewScale] call BIS_fnc_dbValueSet;

		profileNamespace setVariable ["TER_3den_configViewer73_dbSettings",_dbSettings];
		saveProfileNamespace;
	};
};
