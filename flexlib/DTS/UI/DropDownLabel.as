package DTS.UI
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;
	import mx.controls.List;
	import mx.core.Application;
	import mx.events.ListEvent;

	[Event(name="change", type="flash.events.Event")]
	public class DropDownLabel extends LabelInternational
	{
		private var _dataProvider:Object = null;
		private var _dropDownLocation:String = "bottom";
		private var _dropDownDistance:int = 0;
		private var _labelField:String = null;
		private var _selectedItem:Object = null;
		private var _rowCount:int = 5;

		public function DropDownLabel() {
			super();

			addEventListener(MouseEvent.MOUSE_OVER, function(event:MouseEvent):void {
				if (enabled) {
					setStyle("textDecoration", "underline");
				}
			});
			addEventListener(MouseEvent.MOUSE_OUT, function(event:MouseEvent):void {
				setStyle("textDecoration", undefined);
			});
			addEventListener(MouseEvent.CLICK, OnClick);
		}

		override public function set text(value:String):void {
			selectedItem = value;
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

		public function get labelField():String {
			return _labelField;
		}

		public function set labelField(value:String):void {
			_labelField = value;
			selectedItem = selectedItem;
		}

		public function get dataProvider():Object {
			return _dataProvider;
		}

		public function set dataProvider(value:Object):void {
			_dataProvider = value;
			var nSelectedItem:Object = selectedItem;
			if (_dataProvider != null) {
				if (_dataProvider is Array) {
					_dataProvider = new ArrayCollection(_dataProvider as Array);
				}
				if (_dataProvider is ArrayCollection) {
					var dp:ArrayCollection = _dataProvider as ArrayCollection;
					if (nSelectedItem == null && dp.length > 0) {
						nSelectedItem = dp[0];
					}
				}
			}
			selectedItem = nSelectedItem;
		}

		public function get selectedItem():Object {
			return _selectedItem;
		}

		public function set selectedItem(value:Object):void {
			_selectedItem = value;
			if (value != null) {
				if (dataProvider != null && dataProvider is ArrayCollection) {
					var dp:ArrayCollection = dataProvider as ArrayCollection;
					var idx:int = dp.getItemIndex(value);
					if (idx != -1) {
						_selectedItem = value;
						super.text = (_labelField == null) ? value.toString() : value[_labelField];
					}
				}
			}
			if (_selectedItem == null) {
				super.text = "";
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
			_selectedItem = index;
			if (index > -1) {
				if (dataProvider != null && dataProvider is ArrayCollection) {
					var dp:ArrayCollection = dataProvider as ArrayCollection;
					var value:Object = dp.getItemAt(index);
					if (value != null) {
						_selectedItem = value;
						super.text = (_labelField == null) ? value.toString() : value[_labelField];
					}
				}
			}
			if (_selectedItem == null) {
				super.text = "";
			}
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function get rowCount():int {
			return _rowCount;
		}

		public function set rowCount(value:int):void {
			_rowCount = value;
		}

		protected function OnClick(event:MouseEvent=null):void {
			if (enabled && dataProvider != null && dataProvider is ArrayCollection) {
				var dp:ArrayCollection = dataProvider as ArrayCollection;
				if (dp.length > 0) {
					var rect:Rectangle = getBounds(Application.application as DisplayObject);
					var paddingLeft:Number = Number(getStyle("paddingLeft"));
					var paddingRight:Number = Number(getStyle("paddingRight"));
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
					list.width = Math.max(maxTextWidth + 8 + ((dp.length > _rowCount) ? 16 : 0), rect.width + paddingLeft + paddingRight);
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
						popUpCanvas.Open(rect.left - paddingLeft, rect.bottom + _dropDownDistance, false);
					}
					else {
						popUpCanvas.Open(rect.left - paddingLeft, rect.top - list.height - _dropDownDistance, false);
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
