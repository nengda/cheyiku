package DTS.UI
{
	import mx.containers.Panel;
	import mx.core.Application;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;

	public class DialogFixed extends Panel
	{
		private var _titleButtons:UIComponent = null;

		public function DialogFixed() {
			super();
			y = 10240;
		}

		public static function Open(className:Class, modal:Boolean=true, center:Boolean=true):Object {
			var app:Application = Application.application as Application;
			var dlg:IFlexDisplayObject = PopUpManager.createPopUp(app, className, modal);
			if (center) {
				PopUpManager.centerPopUp(dlg);
			}
			return dlg;
		}

		public function BringToFront():void {
			PopUpManager.bringToFront(this);
		}

		public function Close():void {
			callLater(function(dlg:IFlexDisplayObject):void {
				PopUpManager.removePopUp(dlg);
			}, [this]);
		}

		public function set TitleButtons(buttons:UIComponent):void {
			if (_titleButtons != null) {
				this.titleBar.removeChild(_titleButtons);
			}
			_titleButtons = buttons;
			var addTitleButtons:Function = function(dlg:DialogFixed):void {
				if (dlg.titleBar != null) {
					dlg.titleBar.addChild(_titleButtons);
				}
				else {
					callLater(addTitleButtons, [dlg]);
				}
			};
			addTitleButtons(this);
		}

		public function get TitleButtons():UIComponent {
			return _titleButtons;
		}

		override protected function layoutChrome(unscaledWidth:Number, unscaledHeight:Number):void {
        	super.layoutChrome(unscaledWidth, unscaledHeight);
        	if (_titleButtons != null) {
	        	_titleButtons.width = _titleButtons.measuredWidth;
	        	_titleButtons.height = _titleButtons.measuredHeight;
	        	_titleButtons.x = this.width - _titleButtons.width - 10;
	        	_titleButtons.y = 6;
        	}
        }
	}
}