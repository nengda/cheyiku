package DTS.UI.DataGridClasses.FilterPanels
{
	import DTS.UI.TextInputAdvanced;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.events.FlexEvent;
	import mx.skins.ProgrammaticSkin;
	import mx.utils.StringUtil;

	public class FilterPanelString extends FilterPanelBase
	{
		protected var _dataField:String;
		protected var _filterValue:String = null;

		protected var _hboxInput:HBox;
		protected var _btnOperator:Button;
		protected var _textInput:TextInputAdvanced;

		public function FilterPanelString(dataField:String, onFilterChanged:Function=null) {
			super();

			_dataField = dataField;

			width = 200;
			setStyle("borderStyle", "solid");
			setStyle("borderThickness", 0);
			setStyle("dropShadowEnabled", true);
			setStyle("shadowDistance", 0);

			_hboxInput = new HBox();
			_hboxInput.height = 22;
			_hboxInput.setStyle("left", 0);
			_hboxInput.setStyle("right", 0);
			_hboxInput.setStyle("backgroundColor", 0xffffcc);
			_hboxInput.setStyle("paddingLeft", 2);
			_hboxInput.setStyle("paddingRight", 2);
			_hboxInput.setStyle("horizontalGap", 2);
			_hboxInput.setStyle("verticalAlign", "middle");

			_btnOperator = new Button();
			_btnOperator.height = 18;
			_btnOperator.label = "包含:";
			_btnOperator.setStyle("paddingLeft", 0);
			_btnOperator.setStyle("paddingRight", 0);
			_btnOperator.setStyle("paddingTop", 0);
			_btnOperator.setStyle("paddingBottom", 0);
			_btnOperator.setStyle("cornerRadius", 0);
			_btnOperator.setStyle("upSkin", mx.skins.ProgrammaticSkin);
			_btnOperator.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
				switch (_btnOperator.label) {
					case "等于:":
						_btnOperator.label = "包含:";
						break;
					case "包含:":
						_btnOperator.label = "不包含:";
						break;
					case "不包含:":
						_btnOperator.label = "等于:";
						break;
				}
				OnTextInputChanged();
			});
			_hboxInput.addChild(_btnOperator);

			_textInput = new TextInputAdvanced();
			_textInput.percentWidth = 100;
			_textInput.height = 18;
			_textInput.setStyle("focusThickness", 0);
			_textInput.setStyle("borderSkin", mx.skins.ProgrammaticSkin);
			_textInput.addEventListener("changeDelayed", OnTextInputChanged);
			_textInput.addEventListener(FlexEvent.ENTER, function(event:FlexEvent):void {
				OnTextInputChanged();
				Close();
			});
			_hboxInput.addChild(_textInput);

			addChild(_hboxInput);

			if (onFilterChanged != null) {
				addEventListener("FilterChanged", onFilterChanged);
			}
		}

		override public function Open(x:int, y:int, ensureVisible:Boolean=true):void {
			super.Open(x, y, ensureVisible);
			callLater(function():void {
				_textInput.setFocus();
			});
		}

		override public function Filter(o:Object):Boolean {
			if (FilterEnabled) {
				var fieldValue:String = o[_dataField];
				if (fieldValue == null) {
					return false;
				}
				switch (_btnOperator.label) {
					case "等于:":
						if (fieldValue.toLowerCase() == _filterValue) {
							return true;
						}
						break;
					case "包含:":
						if (fieldValue.toLowerCase().indexOf(_filterValue) != -1) {
							return true;
						}
						break;
					case "不包含:":
						if (fieldValue.toLowerCase().indexOf(_filterValue) == -1) {
							return true;
						}
						break;
				}
				return false;
			}
			return true;
		}

		override public function get FilterValue():Object {
			if (!FilterEnabled) {
				return null;
			}
			return {
				operator: _btnOperator.label,
				value: _filterValue
			};
		}

		override public function set FilterValue(value:Object):void {
			if (value == null) {
				_textInput.text = "";
			}
			else {
				_btnOperator.label = value.operator;
				_textInput.text = value.value;
			}
			OnTextInputChanged();
		}

		override public function get FilterEnabled():Boolean {
			return (_filterValue != null);
		}

		private function OnTextInputChanged(event:Event=null):void {
			_filterValue = null;
			if (_textInput.text != null && _textInput.text.match(/^\s*$/) == null) {
				_filterValue = StringUtil.trim(_textInput.text).toLowerCase();
			}
			FilterChanged();
		}
	}
}