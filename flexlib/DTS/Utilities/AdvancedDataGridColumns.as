package DTS.Utilities
{
	import DTS.Logger.LogWindow;
	import DTS.UI.DataGridClasses.ItemRenderers.Label;
	
	import mx.controls.AdvancedDataGrid;
	import mx.controls.advancedDataGridClasses.AdvancedDataGridColumn;
	import mx.core.ClassFactory;
	import mx.formatters.DateFormatter;

	public class AdvancedDataGridColumns
	{
		public static function Create(dataGrid:AdvancedDataGrid, columns:Array, layoutMethod:String="auto"):Array {
			var dataGridColumns:Array = new Array();
			var c:Object = null;
			switch (layoutMethod) {
				case "auto":
					var remainingWidth:Number = dataGrid.getBounds(dataGrid.parent).width;
					var columnsWithoutWidth:int = 0;
					for each (c in columns) {
						if (c.hasOwnProperty("width")) {
							remainingWidth -= Number(c["width"]);
						}
						else {
							columnsWithoutWidth++;
						}
					}
					for each (c in columns) {
						if (!c.hasOwnProperty("width")) {
							c["width"] = int(remainingWidth / columnsWithoutWidth);
						}
					}
					break;
				case "none":
				default:
					break;
			}
			for each (c in columns) {
				dataGridColumns.push(CreateColumn(c));
			}
			dataGrid.columns = dataGridColumns;
			return dataGridColumns;
		}

		private static function CreateColumn(column:Object):AdvancedDataGridColumn {
			var c:AdvancedDataGridColumn = new AdvancedDataGridColumn();
			var classFactory:ClassFactory = null;
			if (column.hasOwnProperty("headerText")) {
				c.headerText = column["headerText"];
			}
			if (column.hasOwnProperty("dataField")) {
				c.dataField = column["dataField"];
			}
			if (column.hasOwnProperty("width")) {
				c.width = column["width"];
			}
			if (column.hasOwnProperty("minWidth")) {
				c.minWidth = column["minWidth"];
			}
			if (column.hasOwnProperty("resizable")) {
				c.resizable = column["resizable"];
			}
			if (column.hasOwnProperty("sortable")) {
				c.sortable = column["sortable"];
			}
			if (column.hasOwnProperty("sortDescending")) {
				c.sortDescending = column["sortDescending"];
			}
			if (column.hasOwnProperty("numeric") && column["numeric"] == true) {
				new NumericDataGridColumn(c, column);
			}
			if (column.hasOwnProperty("datetime") && column["datetime"] == true) {
				c.labelFunction = LabelDate;
			}
			if (column.hasOwnProperty("labelFunction")) {
				c.labelFunction = column["labelFunction"];
			}
			if (column.hasOwnProperty("sortCompareFunction")) {
				c.sortCompareFunction = column["sortCompareFunction"];
			}
			if (column.hasOwnProperty("itemRenderer")) {
				var itemRenderer:Object = column["itemRenderer"];
				classFactory = null;
				if (itemRenderer is String && (itemRenderer as String).toLowerCase() == "default") {
					// Use the default item renderer from Flex
				}
				else if (itemRenderer is Class) {
					classFactory = new ClassFactory(itemRenderer as Class);
				}
				else if (itemRenderer is ClassFactory) {
					classFactory = itemRenderer as ClassFactory;
				}
				else {
					classFactory = new ClassFactory(itemRenderer["rendererClass"] as Class);
					if (itemRenderer.hasOwnProperty("properties")) {
						classFactory.properties = itemRenderer["properties"];
					}
				}
				c.itemRenderer = classFactory;
			}
			else {
				c.itemRenderer = new ClassFactory(Label);
			}
			if (column.hasOwnProperty("headerRenderer")) {
				var headerRenderer:Object = column["headerRenderer"];
				classFactory = null;
				if (headerRenderer is Class) {
					classFactory = new ClassFactory(headerRenderer as Class);
				}
				else if (headerRenderer is ClassFactory) {
					classFactory = headerRenderer as ClassFactory;
				}
				else {
					classFactory = new ClassFactory(headerRenderer["rendererClass"] as Class);
					if (headerRenderer.hasOwnProperty("properties")) {
						classFactory.properties = headerRenderer["properties"];
					}
				}
				c.headerRenderer = classFactory;
			}
			return c;
		}

		private static function LabelDate(o:Object, c:AdvancedDataGridColumn):String {
			if (o != null) {
				return FormatDate(o[c.dataField]);
			}
			return "";
		}

		private static function FormatDate(o:Object):String {
			if (o == null) {
				return "";
			}
			var date:Date = null;
			if (o is Date) {
				date = o as Date;
			}
			else {
				date = DateParser.ParseYMDHMS(o.toString());
			}
			if (date != null) {
				return _dateFormatter.format(date);
			}
			return "";
		}

		private static var __dateFormatter:DateFormatter = null;
		private static function get _dateFormatter():DateFormatter {
			if (__dateFormatter == null) {
				__dateFormatter = new DateFormatter();
				__dateFormatter.formatString = "YYYY-MM-DD, JJ:NN";
			}
			return __dateFormatter;
		}
	}
}
