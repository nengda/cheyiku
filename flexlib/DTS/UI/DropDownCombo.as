package DTS.UI
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.List;
	import mx.core.Application;
	import mx.events.ListEvent;

	[Event(name="change", type="flash.events.Event")]
	public class DropDownCombo extends Canvas
	{
		[Embed(source="DropDownLabelAssets/arrow_down.png")]
		private static const ICO_ARROW_DOWN:Class;

		[Embed(source="DropDownLabelAssets/arrow_down_disabled.png")]
		private static const ICO_ARROW_DOWN_DISABLED:Class;

		protected var _label:Label = null;
		protected var _button:Button = null;
		private var _dataProvider:Object = null;
		private var _labelPlacement:String = "left";
		private var _dropDownLocation:String = "bottom";
		private var _dropDownDistance:int = 0;
		private var _showButton:Boolean = true;
		private var _labelField:String = null;
		private var _selectedItem:Object = null;
		private var _rowCount:int = 5;

		public function DropDownCombo() {
			super();

			horizontalScrollPolicy = "off";
			verticalScrollPolicy = "off";

			_label = new Label();
			_label.x = 0;
			_label.y = 0;
			_label.text = label;
			addChild(_label);

			_button = new Button();
			_button.x = 0;
			_button.y = 0;
			_button.width = 17;
			_button.height = 18;
			_button.setStyle("paddingLeft", 0);
			_button.setStyle("paddingRight", 0);
			_button.setStyle("paddingTop", 0);
			_button.setStyle("paddingBottom", 0);
			_button.setStyle("icon", ICO_ARROW_DOWN);
			_button.setStyle("disabledIcon", ICO_ARROW_DOWN_DISABLED);
			addChild(_button);

			_label.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
				if (enabled) {
					_label.setStyle("textDecoration", "underline");
					_button.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
				}
			});
			_label.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
				_label.setStyle("textDecoration", undefined);
				_button.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			});
			_button.addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
				if (enabled) {
					_label.setStyle("textDecoration", "underline");
				}
			});
			_button.addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
				_label.setStyle("textDecoration", undefined);
			});
			addEventListener(MouseEvent.CLICK, OnClick);
		}

		override public function get enabled():Boolean {
			return _label.enabled;
		}

		override public function set enabled(value:Boolean):void {
			if (_label == null || _button == null) {
				callLater(function(v:Boolean):void {
					enabled = v;
				}, [value]);
				return;
			}
			_label.enabled = value;
			_button.enabled = value;
		}

		override public function get label():String {
			return _label.text;
		}

		override public function set label(value:String):void {
			_label.text = value;
			selectedItem = null;
			if (dataProvider != null && dataProvider is ArrayCollection) {
				for each (var i:Object in (dataProvider as ArrayCollection)) {
					var l:String = (_labelField == null) ? i.toString() : i[_labelField];
					if (l == value) {
						selectedItem = i;
						break;
					}
				}
			}
		}

		public function get labelPlacement():String {
			return _labelPlacement;
		}

		public function set labelPlacement(value:String):void {
			_labelPlacement = value;
			invalidateDisplayList();
		}

		public function get dropDownLocation():String {
			return _dropDownLocation;
		}

		public function set dropDownLocation(value:String):void {
			_dropDownLocation = value;
		}

		public function get dropDownDistance():int {
			return _dropDownDistance;
		}

		public function set dropDownDistance(value:int):void {
			_dropDownDistance = value;
		}

		public function set showButton(value:Boolean):void {
			_showButton = value;
			_button.visible = _showButton;
		}

		public function get showButton():Boolean {
			return _showButton;
		}

		public function get labelField():String {
			return _labelField;
		}

		public function set labelField(value:String):void {
			_labelField = value;
			selectedItem = selectedItem;
		}

		public function get paddingLeft():int {
			return int(_label.getStyle("paddingLeft"));
		}

		public function set paddingLeft(value:int):void {
			if (_label == null) {
				callLater(function(v:int):void {
					paddingLeft = v;
				}, [value]);
				return;
			}
			_label.setStyle("paddingLeft", value);
		}

		public function get paddingRight():int {
			return int(_label.getStyle("paddingRight"));
		}

		public function set paddingRight(value:int):void {
			if (_label == null) {
				callLater(function(v:int):void {
					paddingRight = v;
				}, [value]);
				return;
			}
			_label.setStyle("paddingRight", value);
		}

		public function get dataProvider():Object {
			return _dataProvider;
		}

		public function set dataProvider(value:Object):void {
			_dataProvider = value;
			selectedItem = null;
			if (_dataProvider != null) {
				if (_dataProvider is Array) {
					_dataProvider = new ArrayCollection(_dataProvider as Array);
				}
				if (_dataProvider is ArrayCollection) {
					var dp:ArrayCollection = _dataProvider as ArrayCollection;
					if (dp.length > 0) {
						selectedItem = dp[0];
					}
				}
			}
		}

		public function get selectedItem():Object {
			return _selectedItem;
		}

		public function set selectedItem(value:Object):void {
			_selectedItem = null;
			if (value != null) {
				if (dataProvider != null && dataProvider is ArrayCollection) {
					var dp:ArrayCollection = dataProvider as ArrayCollection;
					var idx:int = dp.getItemIndex(value);
					if (idx != -1) {
						_selectedItem = value;
						_label.text = (_labelField == null) ? value.toString() : value[_labelField];
					}
				}
			}
			if (_selectedItem == null) {
				_label.text = "";
			}
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function get selectedIndex():int {
			if (dataProvider != null && dataProvider is ArrayCollection) {
				var dp:ArrayCollection = dataProvider as ArrayCollection;
				return dp.getItemIndex(_selectedItem);
			}
			return -1;
		}

		public function set selectedIndex(index:int):void {
			_selectedItem = null;
			if (index > -1) {
				if (dataProvider != null && dataProvider is ArrayCollection) {
					var dp:ArrayCollection = dataProvider as ArrayCollection;
					var value:Object = dp.getItemAt(index);
					if (value != null) {
						_selectedItem = value;
						_label.text = (_labelField == null) ? value.toString() : value[_labelField];
					}
				}
			}
			if (_selectedItem == null) {
				_label.text = "";
			}
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function get rowCount():int {
			return _rowCount;
		}

		public function set rowCount(value:int):void {
			_rowCount = value;
		}

		override public function get measuredWidth():Number {
			return _label.measuredWidth + ((_showButton) ? _button.width + 5 : 0);
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (labelPlacement.toLowerCase() == "right") {
				_label.x = (_showButton) ? _button.width + 5 : 0;
				_label.width = unscaledWidth - ((_showButton) ? _button.width + 5 : 0);
				_button.x = 0;
			}
			else {
				_label.x = 0;
				_label.width = unscaledWidth - ((_showButton) ? _button.width + 5 : 0);
				_button.x = _label.width + 5;
			}
		}

		protected function OnClick(event:MouseEvent=null):void {
			if (enabled && dataProvider != null && dataProvider is ArrayCollection) {
				var dp:ArrayCollection = dataProvider as ArrayCollection;
				if (dp.length > 0) {
					var rect:Rectangle = getBounds(Application.application as DisplayObject);
					var popUpCanvas:PopUpCanvas = new PopUpCanvas();
					popUpCanvas.setStyle("dropShadowEnabled", true);
					popUpCanvas.setStyle("borderStyle", "solid");
					popUpCanvas.setStyle("borderThickness", 0);

					var item:Object;
					var textWidth:Number;
					var maxTextWidth:int = 0;
					if (_labelField == null){
						for each (item in dataProvider){
							textWidth = measureText(item.toString()).width;
							if (textWidth > maxTextWidth) {
								maxTextWidth = textWidth;
							}
						}
					} else {
						for each (item in dataProvider){
							textWidth = measureText(item[_labelField].toString()).width;
							if (textWidth > maxTextWidth) {
								maxTextWidth = textWidth;
							}
						}
					}

					var list:List = new List();
					list.width = Math.max(maxTextWidth + _button.width + 5, width);
					list.height = 22 * Math.min(dp.length, _rowCount);
					list.rowHeight = 22;
					list.horizontalScrollPolicy = "off";
					list.setStyle("borderStyle", "none");
					list.labelField = labelField;
					list.dataProvider = dataProvider;
					list.selectedItem = selectedItem;
					list.addEventListener(ListEvent.ITEM_CLICK, function(event:ListEvent):void {
						selectedItem = event.itemRenderer.data;
						popUpCanvas.Close();
					});
					popUpCanvas.addChild(list);
					if (_dropDownLocation.toLowerCase() != "top") {
						popUpCanvas.Open(rect.left, rect.bottom + _dropDownDistance, false);
					}
					else {
						popUpCanvas.Open(rect.left, rect.top - list.height - _dropDownDistance, false);
					}
					popUpCanvas.callLater(function():void {
						list.setFocus();
						try {
							list.scrollToIndex(dp.getItemIndex(selectedItem));
						}
						catch (error:Error) {}
					});
				}
			}
		}
	}
}
