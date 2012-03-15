package DTS.Utilities
{	
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.controls.AdvancedDataGrid;
	
	public class AdvancedDataGridState
	{
		public static function Save(dataGrid:AdvancedDataGrid):Object {
			var expandedItems:Array = new Array();
			if (dataGrid.dataProvider != null) {
				var view:ICollectionView = ICollectionView(dataGrid.dataProvider);
				var cursor:IViewCursor = view.createCursor();
				while (!cursor.afterLast) {
					var item:Object = cursor.current;
					if (dataGrid.isItemOpen(item)) {
						expandedItems.push(item);
					}
					cursor.moveNext();
				}
			}
			return {
				"scrollPosition": dataGrid.verticalScrollPosition,
				"selectedItems": dataGrid.selectedItems,
				"expandedItems": expandedItems
			};
		}

		public static function Restore(dataGrid:AdvancedDataGrid, state:Object, compareItems:Function=null, onComplete:Function=null):void {
			if (compareItems == null) {
				compareItems = function(a:Object, b:Object):Boolean {
					return (a == b);
				};
			}
			if (dataGrid.dataProvider != null) {
				dataGrid.callLater(_Restore, [dataGrid, state, compareItems, onComplete]);
			}
		}

		private static function _Restore(dataGrid:AdvancedDataGrid, state:Object, compareItems:Function, onComplete:Function):void {
			var altered:Boolean = false;
			var expandedItems:Array = state.expandedItems as Array;
			var view:ICollectionView = ICollectionView(dataGrid.dataProvider);
			var cursor:IViewCursor = view.createCursor();
			while (!cursor.afterLast) {
				var item:Object = cursor.current;
				var isExpandedOriginally:Boolean = false;
				for each (var expanded:Object in expandedItems) {
					if (compareItems(expanded, item) == true) {
						isExpandedOriginally = true;
						break;
					}
				}
				if (dataGrid.isItemOpen(item) != isExpandedOriginally) {
					dataGrid.expandItem(item, isExpandedOriginally);
					altered = true;
				}
				cursor.moveNext();
			}
			if (altered) {
				dataGrid.callLater(_Restore, [dataGrid, state, compareItems, onComplete]);
			}
			else {
				var selectedItemsNew:Array = new Array();
				var selectedItems:Array = state.selectedItems as Array;
				if (selectedItems != null) {
					view = ICollectionView(dataGrid.dataProvider);
					cursor = view.createCursor();
					while (!cursor.afterLast) {
						var i:Object = cursor.current;
						for each (var selected:Object in selectedItems) {
							if (compareItems(selected, i) == true) {
								selectedItemsNew.push(i);
								break;
							}
						}
						cursor.moveNext();
					}
					dataGrid.selectedItems = selectedItemsNew;
					dataGrid.verticalScrollPosition = state.scrollPosition as int;
				}
				if (onComplete != null) {
					dataGrid.callLater(onComplete);
				}
			}
		}
	}
}
