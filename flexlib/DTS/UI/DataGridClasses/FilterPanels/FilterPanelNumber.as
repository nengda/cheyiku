package DTS.UI.DataGridClasses.FilterPanels
{
	import DTS.UI.TextInputAdvanced;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.events.FlexEvent;
	import mx.skins.ProgrammaticSkin;
	import mx.utils.StringUtil;
	
	public class FilterPanelNumber extends FilterPanelBase
	{
		protected var _dataField:String;
		protected var _filterValue1:Number = Number.NaN;
		protected var _filterValue2:Number = Number.NaN;

		protected var _hboxInput:HBox;
		protected var _btnOperator:Button;
		protected var _textInput:TextInputAdvanced;
		protected var _lblHint:Label;

		public function FilterPanelNumber(dataField:String, onFilterChanged:Function=null) {
			super();

			_dataField = dataField;

			setStyle("borderStyle", "solid");
			setStyle("borderThickness", 0);
			setStyle("dropShadowEnabled", true);
			setStyle("shadowDistance", 0);

			var vbox:VBox = new VBox();
			vbox.setStyle("backgroundColor", 0xb7babc);
			vbox.setStyle("verticalGap", 0);

			_hboxInput = new HBox();
			_hboxInput.height = 22;
			_hboxInput.setStyle("backgroundColor", 0xffffcc);
			_hboxInput.setStyle("paddingLeft", 2);
			_hboxInput.setStyle("paddingRight", 2);
			_hboxInput.setStyle("horizontalGap", 2);
			_hboxInput.setStyle("verticalAlign", "middle");

			_btnOperator = new Button();
			_btnOperator.height = 18;
			_btnOperator.label = ">";
			_btnOperator.setStyle("paddingLeft", 0);
			_btnOperator.setStyle("paddingRight", 0);
			_btnOperator.setStyle("paddingTop", 0);
			_btnOperator.setStyle("paddingBottom", 0);
			_btnOperator.setStyle("cornerRadius", 0);
			_btnOperator.setStyle("upSkin", mx.skins.ProgrammaticSkin);
			_btnOperator.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
				switch (_btnOperator.label) {
					case ">":
						_btnOperator.label = "<";
						break;
					case "<":
						_btnOperator.label = "Range:";
						_textInput.text = "";
						_textInput.width = 120;
						_lblHint.visible = true;
						_lblHint.includeInLayout = true;
						_hboxInput.setStyle("backgroundColor", 0xffffcc);
						break;
					case "Range:":
						_btnOperator.label = ">";
						_textInput.text = "";
						_textInput.width = 80;
						_lblHint.visible = false;
						_lblHint.includeInLayout = false;
						_hboxInput.setStyle("backgroundColor", 0xffffcc);
						break;
				}
				OnTextInputChanged();
			});
			_hboxInput.addChild(_btnOperator);

			_textInput = new TextInputAdvanced();
			_textInput.width = 80;
			_textInput.height = 18;
			_textInput.setStyle("textAlign", "right");
			_textInput.setStyle("focusThickness", 0);
			_textInput.setStyle("borderSkin", mx.skins.ProgrammaticSkin);
			_textInput.addEventListener("changeDelayed", OnTextInputChanged);
			_textInput.addEventListener(FlexEvent.ENTER, function(event:FlexEvent):void {
				OnTextInputChanged();
				Close();
			});
			_hboxInput.addChild(_textInput);

			_lblHint = new Label();
			_lblHint.percentWidth = 100;
			_lblHint.text = "Example: 1.23 - 7.89";
			_lblHint.visible = false;
			_lblHint.includeInLayout = false;
			_lblHint.setStyle("color", 0xeeeeee);
			_lblHint.setStyle("fontStyle", "italic");
			_lblHint.setStyle("textAlign", "right");
			_lblHint.setStyle("paddingTop", -1);
			_lblHint.setStyle("paddingBottom", -2);

			vbox.addChild(_hboxInput);
			vbox.addChild(_lblHint);
			addChild(vbox);

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
				var fieldValue:Number = Number(o[_dataField]);
				switch (_btnOperator.label) {
					case ">":
						if (fieldValue >= _filterValue1) {
							return true;
						}
						break;
					case "<":
						if (fieldValue <= _filterValue1) {
							return true;
						}
						break;
					case "Range:":
						if (fieldValue >= _filterValue1 && fieldValue <= _filterValue2) {
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
				values: [_filterValue1, _filterValue2]
			};
		}

		override public function set FilterValue(value:Object):void {
			if (value == null) {
				_textInput.text = "";
			}
			else {
				var op:String = value.operator;
				var values:Array = value.values as Array;
				switch (op) {
					case ">":
					case "<":
						_btnOperator.label = op;
						_textInput.text = values[0].toString();
						break;
					case "Range:":
						_btnOperator.label = op;
						_textInput.text = values[0].toString() + " - " + values[1].toString();
						break;
				}
			}
			OnTextInputChanged();
		}

		override public function get FilterEnabled():Boolean {
			return (!isNaN(_filterValue1));
		}

		private function OnTextInputChanged(event:Event=null):void {
			var inputValue:String = null;
			if (_textInput.text != null && _textInput.text.match(/^\s*$/) == null) {
				inputValue = StringUtil.trim(_textInput.text);
			}
			_filterValue1 = Number.NaN;
			_filterValue2 = Number.NaN;
			var backgroundColor:uint = 0xffffcc;
			if (inputValue != null) {
				switch (_btnOperator.label) {
					case ">":
					case "<":
						_filterValue1 = Number(inputValue);
						if (isNaN(_filterValue1)) {
							backgroundColor = 0xffdddd;
						}
						break;
					case "Range:":
						var tokens:Array = inputValue.split(/-/);
						if (tokens.length != 2) {
							backgroundColor = 0xffdddd;
						}
						else {
							var r1:Number = Number(tokens[0]);
							var r2:Number = Number(tokens[1]);
							if (isNaN(r1) || isNaN(r2)) {
								backgroundColor = 0xffdddd;
							}
							else {
								_filterValue1 = r1;
								_filterValue2 = r2;
							}
						}
						break;
				}
			}
			_hboxInput.setStyle("backgroundColor", backgroundColor);
			FilterChanged();
		}
	}
}