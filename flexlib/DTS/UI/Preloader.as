package DTS.UI
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	import mx.events.FlexEvent;
	import mx.preloaders.IPreloaderDisplay;

	public class Preloader extends Sprite implements IPreloaderDisplay
	{
		private var _stageHeight:Number = 0;
        private var _stageWidth:Number = 0;
        private var _bytesLoaded:uint = 0;
        private var _bytesExpected:uint = 1;

		public function Preloader() {
			super();
		}

		public function get backgroundAlpha():Number {
			return 0;
		}

		public function set backgroundAlpha(value:Number):void {
		}

		public function get backgroundColor():uint {
			return 0;
		}

		public function set backgroundColor(value:uint):void {
		}

		public function get backgroundImage():Object {
			return null;
		}

		public function set backgroundImage(value:Object):void {
		}

		public function get backgroundSize():String {
			return null;
		}

		public function set backgroundSize(value:String):void {
		}

		public function set preloader(obj:Sprite):void {
			obj.addEventListener(ProgressEvent.PROGRESS, ProgressHandler);
			obj.addEventListener(FlexEvent.INIT_COMPLETE, CompleteHandler);
		}

		public function get stageHeight():Number {
			return _stageHeight;
		}

		public function set stageHeight(value:Number):void {
			_stageHeight = value;
		}

		public function get stageWidth():Number {
			return _stageWidth;
		}

		public function set stageWidth(value:Number):void {
			_stageWidth = value;
		}

		public function initialize():void {
			Draw();
		}

		private function Draw():void {
			graphics.clear();
			graphics.beginFill(Colors.THEME_COLOR);
			graphics.drawRect(2, _stageHeight - 5, (_stageWidth - 4) * _bytesLoaded / _bytesExpected, 3);
			graphics.endFill();
		}

		private function ProgressHandler(event:ProgressEvent):void {
			_bytesLoaded = event.bytesLoaded;
			_bytesExpected = event.bytesTotal;
			Draw();
		}

		private function CompleteHandler(event:FlexEvent):void {
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}