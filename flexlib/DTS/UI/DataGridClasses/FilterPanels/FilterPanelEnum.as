package DTS.UI.DataGridClasses.FilterPanels
{
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.controls.CheckBox;
	import mx.events.FlexEvent;

	public class FilterPanelEnum extends FilterPanelBase
	{
		protected var _dataField:String;

		protected var _vbox:VBox;
		protected var _cbAll:CheckBox;
		protected var _allowedValues:Object;

		public function FilterPanelEnum(dataField:String, enums:Array, onFilterChanged:Function=null) {
			super();

			_dataField = dataField;

			setStyle("borderStyle", "solid");
			setStyle("borderThickness", 0);
			setStyle("dropShadowEnabled", true);
			setStyle("shadowDistance", 0);

			var vboxOutter:VBox = new VBox();
			vboxOutter.setStyle("verticalGap", 0);

			_vbox = new VBox();
			_vbox.setStyle("backgroundColor", 0xffffcc);
			_vbox.setStyle("verticalGap", 0);

			var canvas:Canvas = new Canvas();
			canvas.percentWidth = 100;
			canvas.setStyle("backgroundColor", 0xb7babc);

			_cbAll = new CheckBox();
			_cbAll.label = "全部";
			_cbAll.selected = true;
			_cbAll.setStyle("paddingLeft", 5);
			_cbAll.setStyle("paddingRight", 5);
			_cbAll.addEventListener(Event.CHANGE, function(event:Event):void {
				for each (var c:CheckBox in _vbox.getChildren()) {
					c.selected = _cbAll.selected;
				}
				OnSelectionChanged();
			});
			canvas.addChild(_cbAll);

			for each (var option:String in enums) {
				var cb:CheckBox = new CheckBox();
				cb.label = option;
				cb.selected = true;
				cb.setStyle("paddingLeft", 5);
				cb.setStyle("paddingRight", 5);
				cb.addEventListener(Event.CHANGE, OnSelectionChanged);
				_vbox.addChild(cb);
			}

			vboxOutter.addChild(_vbox);
			vboxOutter.addChild(canvas);
			addChild(vboxOutter);

			if (onFilterChanged != null) {
				addEventListener("FilterChanged", onFilterChanged);
			}
		}

		override public function Open(x:int, y:int, ensureVisible:Boolean=true):void {
			super.Open(x, y, ensureVisible);
		}

		override public function Filter(o:Object):Boolean {
			if (FilterEnabled) {
				var fieldValue:String = o[_dataField];
				if (fieldValue == null) {
					return false;
				}
				return _allowedValues.hasOwnProperty(fieldValue.toLowerCase());
			}
			return true;
		}

		override public function get FilterValue():Object {
			if (!FilterEnabled) {
				return null;
			}
			var value:Object = {};
			for each (var c:CheckBox in _vbox.getChildren()) {
				value[c.label] = c.selected;
			}
			return value;
		}

		override public function set FilterValue(value:Object):void {
			var c:CheckBox;
			if (value == null) {
				for each (c in _vbox.getChildren()) {
					c.selected = true;
				}
			}
			else {
				for each (c in _vbox.getChildren()) {
					if (value.hasOwnProperty(c.label)) {
						c.selected = value[c.label];
					}
				}
			}
			OnSelectionChanged();
		}

		override public function get FilterEnabled():Boolean {
			return !_cbAll.selected;
		}

		private function OnSelectionChanged(event:Event=null):void {
			var all:Boolean = true;
			_allowedValues = {};
			for each (var c:CheckBox in _vbox.getChildren()) {
				if (!c.selected) {
					all = false;
				}
				else {
					_allowedValues[c.label.toLowerCase()] = true;
				}
			}
			_cbAll.selected = all;
			FilterChanged();
			//Close();
		}
	}
}
