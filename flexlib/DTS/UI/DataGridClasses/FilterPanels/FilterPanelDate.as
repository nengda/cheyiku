package DTS.UI.DataGridClasses.FilterPanels
{
	import DTS.UI.TextInputAdvanced;
	import DTS.Utilities.DateMath;
	import DTS.Utilities.DateParser;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.events.FlexEvent;
	import mx.formatters.DateFormatter;
	import mx.skins.ProgrammaticSkin;
	import mx.utils.StringUtil;
	
	public class FilterPanelDate extends FilterPanelBase
	{
		protected var _dataField:String;
		protected var _filterValue1:Date = null;
		protected var _filterValue2:Date = null;

		protected var _hboxInput:HBox;
		protected var _btnOperator:Button;
		protected var _textInput:TextInputAdvanced;
		protected var _lblHint:Label;

		public function FilterPanelDate(dataField:String, onFilterChanged:Function=null) {
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
			_btnOperator.label = "之后:";
			_btnOperator.setStyle("paddingLeft", 0);
			_btnOperator.setStyle("paddingRight", 0);
			_btnOperator.setStyle("paddingTop", 0);
			_btnOperator.setStyle("paddingBottom", 0);
			_btnOperator.setStyle("cornerRadius", 0);
			_btnOperator.setStyle("upSkin", mx.skins.ProgrammaticSkin);
			_btnOperator.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
				switch (_btnOperator.label) {
					case "之后:":
						_btnOperator.label = "之前:";
						break;
					case "之前:":
						_btnOperator.label = "之间:";
						_textInput.text = "";
						_textInput.width = 170;
						_lblHint.text = "格式: YYYY-MM-DD to YYYY-MM-DD";
						_hboxInput.setStyle("backgroundColor", 0xffffcc);
						break;
					case "之间:":
						_btnOperator.label = "之后:";
						_textInput.text = "";
						_textInput.width = 100;
						_lblHint.text = "格式: YYYY-MM-DD";
						_hboxInput.setStyle("backgroundColor", 0xffffcc);
						break;
				}
				OnTextInputChanged();
			});
			_hboxInput.addChild(_btnOperator);

			_textInput = new TextInputAdvanced();
			_textInput.width = 100;
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
			_lblHint.text = "格式: YYYY-MM-DD";
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
				var fieldValue:Object = o[_dataField];
				var date:Date = null;
				if (fieldValue is Date) {
					date = fieldValue as Date;
				}
				else {
					date = DateParser.ParseYMDHMS(fieldValue.toString());
				}
				if (date != null) {
					switch (_btnOperator.label) {
						case "之后:":
							if (date.getTime() >= _filterValue1.getTime()) {
								return true;
							}
							break;
						case "之前:":
							if (date.getTime() < _filterValue1.getTime()) {
								return true;
							}
							break;
						case "之间:":
							if (date.getTime() >= _filterValue1.getTime() && date.getTime() < DateMath.AddDays(_filterValue2, 1).getTime()) {
								return true;
							}
							break;
					}
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
					case "之后:":
					case "之前:":
						_btnOperator.label = op;
						_textInput.text = _dateFormatter.format(values[0]);
						break;
					case "之间:":
						_btnOperator.label = op;
						_textInput.text = _dateFormatter.format(values[0]) + " - " + _dateFormatter.format(values[1]);
						break;
				}
			}
			OnTextInputChanged();
		}

		override public function get FilterEnabled():Boolean {
			return (_filterValue1 != null);
		}

		private function OnTextInputChanged(event:Event=null):void {
			var inputValue:String = null;
			if (_textInput.text != null && _textInput.text.match(/^\s*$/) == null) {
				inputValue = StringUtil.trim(_textInput.text);
			}
			_filterValue1 = null;
			_filterValue2 = null;
			var backgroundColor:uint = 0xffffcc;
			if (inputValue != null) {
				switch (_btnOperator.label) {
					case "之后:":
					case "之前:":
						_filterValue1 = DateParser.ParseYMD(inputValue);
						if (_filterValue1 == null) {
							backgroundColor = 0xffdddd;
						}
						break;
					case "之间:":
						var tokens:Array = inputValue.split(/to/);
						if (tokens.length != 2) {
							backgroundColor = 0xffdddd;
						}
						else {
							var r1:Date = DateParser.ParseYMD(tokens[0]);
							var r2:Date = DateParser.ParseYMD(tokens[1]);
							if (r1 == null || r2 == null) {
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

		private static var __dateFormatter:DateFormatter = null;
		private static function get _dateFormatter():DateFormatter {
			if (__dateFormatter == null) {
				__dateFormatter = new DateFormatter();
				__dateFormatter.formatString = "YYYY-MM-DD";
			}
			return __dateFormatter;
		}
	}
}