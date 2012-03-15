package DTS.UI.DataGridClasses.ItemRenderers
{
	import DTS.Core.GenericEvent;

	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.controls.CheckBox;
	import mx.controls.dataGridClasses.DataGridListData;
	import mx.controls.listClasses.BaseListData;
	import mx.controls.listClasses.IDropInListItemRenderer;

	[Event(name="Changed", type="DTS.Core.GenericEvent")]
	public class CheckBox extends Canvas implements IDropInListItemRenderer
	{
		private var _initialized:Boolean = false;
		private var _checkBox:mx.controls.CheckBox = null;
		private var _listData:BaseListData;

		public function CheckBox() {
			super();
			_checkBox = new mx.controls.CheckBox();
		}

		override protected function createChildren():void {
			super.createChildren();
			if (!_initialized) {
				_checkBox = new mx.controls.CheckBox();
				_checkBox.visible = false;
				_checkBox.setStyle("horizontalCenter", 0);
				_checkBox.setStyle("verticalCenter", 0);
				_checkBox.addEventListener(Event.CHANGE, OnChange);
				addChild(_checkBox);
				_initialized = true;
			}
			data = data;
		}

		override public function set data(value:Object):void {
			super.data = value;
			if (value != null && listData != null && listData is DataGridListData) {
				var b:Boolean = value[DataGridListData(listData).dataField];
				_checkBox.selected = b;
				_checkBox.visible = true;
			}
			else {
				_checkBox.visible = false;
			}
		}

	    public function get listData():BaseListData {
	        return _listData;
	    }

	    public function set listData(value:BaseListData):void {
	        _listData = value;
	        data = data;
	    }

		private function OnChange(event:Event):void {
			data[DataGridListData(listData).dataField] = _checkBox.selected;
			dispatchEvent(new GenericEvent("Changed", this, true));
		}
	}
}
