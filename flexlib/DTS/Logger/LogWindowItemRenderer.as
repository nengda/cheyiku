package DTS.Logger
{
	import mx.containers.Canvas;
	import mx.core.UITextField;

	public class LogWindowItemRenderer extends Canvas
	{
		private var _control:UITextField = null;

		public function LogWindowItemRenderer() {
			super();
		}
		
		override protected function createChildren():void {
			super.createChildren();

			_control = new UITextField();
			this.addChild(_control);
			this.regenerateStyleCache(true);

			this.horizontalScrollPolicy = "auto";
			this.verticalScrollPolicy = "auto";
		}

		override public function set data(value:Object):void {
			super.data = value;
			if (value != null) {
				var s:String = value["message"].toString();
				_control.text = s;
				_control.x = 5;
				_control.y = 0;
				_control.selectable = true;
				_control.validateNow();
				_control.width = _control.measuredWidth;
				_control.height = _control.measuredHeight;
				if (this.width < _control.width + 5) {
					this.height = _control.height + 16;
				}
				else {
					this.height = _control.height;
				}
			}
			super.invalidateDisplayList();
		}
	}
}
