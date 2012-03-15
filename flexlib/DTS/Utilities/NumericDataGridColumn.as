package DTS.Utilities
{
	import mx.controls.advancedDataGridClasses.AdvancedDataGridColumn;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.formatters.NumberFormatter;
	import mx.utils.ObjectUtil;

	public class NumericDataGridColumn
	{
		private var _column:Object = null;
		private var _numberFormatter:NumberFormatter = new NumberFormatter();

		public function NumericDataGridColumn(column:Object, options:Object=null) {
			_column = column;
			if (_column is DataGridColumn) {
				DataGridColumn(_column).labelFunction = LabelFunction;
				DataGridColumn(_column).sortCompareFunction = SortFunction;
			}
			else if (column is AdvancedDataGridColumn) {
				AdvancedDataGridColumn(_column).labelFunction = LabelFunction;
				AdvancedDataGridColumn(_column).sortCompareFunction = SortFunction;
			}
			else {
				throw new Error("Unsupported column type");
			}
			if (options != null) {
				if (options.hasOwnProperty("decimalSeparatorFrom")) {
					_numberFormatter.decimalSeparatorFrom = options.decimalSeparatorFrom;
				}
				if (options.hasOwnProperty("decimalSeparatorTo")) {
					_numberFormatter.decimalSeparatorTo = options.decimalSeparatorTo;
				}
				if (options.hasOwnProperty("thousandsSeparatorFrom")) {
					_numberFormatter.thousandsSeparatorFrom = options.thousandsSeparatorFrom;
				}
				if (options.hasOwnProperty("thousandsSeparatorTo")) {
					_numberFormatter.thousandsSeparatorTo = options.thousandsSeparatorTo;
				}
				if (options.hasOwnProperty("precision") && options.precision != null && Number(options.precision) >= 0) {
					_numberFormatter.precision = Number(options.precision);
				}
			}
		}

		public function get Formatter():NumberFormatter {
			return _numberFormatter;
		}

		public function get Precision():int {
			return int(_numberFormatter.precision);
		}

		public function set Precision(value:int):void {
			_numberFormatter.precision = value;
		}

		private function LabelFunction(o:Object, c:Object):String {
			if (o != null) {
				var s:String = o[c.dataField];
				if (s != null && s.length > 0) {
					var number:Number = Number(s);
					return _numberFormatter.format(number);
				}
			}
			return "";
		}

		private function SortFunction(a:Object, b:Object):int {
			var valueA:Number = a[_column.dataField];
			var valueB:Number = b[_column.dataField];
			return ObjectUtil.numericCompare(valueA, valueB);
		}
	}
}