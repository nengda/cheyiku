package
{
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;

	public class MenuItem
	{
		private var _label:String;
		private var _control:Canvas;
		private var _controlCreationMethod:Function;
		private var _selectable:Boolean;
		private var _children:ArrayCollection;

		public function MenuItem(label:String, controlCreationMethod:Function, selectable:Boolean=true, children:ArrayCollection=null) {
			_label = label;
			_control = null;
			_controlCreationMethod = controlCreationMethod;
			_selectable = selectable;
			_children = children;
		}

		public function get label():String {
			return _label;
		}

		public function get control():Canvas {
			if (_control == null) {
				_control = _controlCreationMethod();
			}
			return _control;
		}

		public function get selectable():Boolean {
			return _selectable;
		}

		public function get children():ArrayCollection {
			return _children;
		}
	}
}
