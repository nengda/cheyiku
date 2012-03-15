package DTS.Net
{
	import DTS.Logger.LogWindow;
	import DTS.UI.MessageBox;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Timer;

	public class HTTPClient
	{
		public static const FLAG_SUPPRESSBOUNCERINSTRUCTIONS:uint = 1;
		public static const FLAG_SUPPRESSIOERRORALERT:uint = 2;
		public static const FLAG_SUPPRESSSECURITYERRORALERT:uint = 4;
		public static const FLAG_SUPPRESSALL:uint = 0x7fffffff;

		public static function Post(invoker:String, url:String, parameters:Object, onComplete:Function, onError:Function=null, flags:uint=0):HTTPClient {
			var urlRequest:URLRequest = new URLRequest(url);
			var urlVariables:URLVariables = new URLVariables();
			for (var k:String in parameters) {
				urlVariables[k] = parameters[k];
			}
			urlVariables.timestamp = (new Date()).getTime().toString(16);
			urlRequest.data = urlVariables;
			urlRequest.method = "POST";
			return new HTTPClient(invoker, urlRequest, onComplete, onError, flags);
		}

		public var Flags:uint;
		private var _invoker:String = "Unknown";
		private var _loader:URLLoader = null;
		private var _request:URLRequest = null;
		private var _onComplete:Function = null;
		private var _onError:Function = null;
		private var _retries:int = 0;
		private var _timer:Timer = null;
		private var _loggerName:String;

		public function HTTPClient(invoker:String, request:URLRequest, onComplete:Function, onError:Function=null, flags:uint=0) {
			_invoker = invoker;
			_request = request;
			_onComplete = onComplete;
			_onError = onError;
			Flags = flags;
			_loggerName = "HTTPClient:" + _invoker + "|" + Flags;

			_loader = new URLLoader();
			_loader.addEventListener(Event.COMPLETE, OnComplete);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnSecurityError);
			_loader.load(_request);
		}

		public function get Loader():URLLoader {
			return _loader;
		}

		private function OnComplete(event:Event):void {
			var response:String = _loader.data;
			if (response.match(/AuthenticationFailed/i) != null) {
				if (!HasFlag(FLAG_SUPPRESSBOUNCERINSTRUCTIONS)) {
					ShowBouncerInstruction();
				}
				LogWindow.Log(_loggerName, "Cookie expired for URL '" + _request.url + "'");
			}
			else {
				try {
					_onComplete(response);
				}
				catch (error:Error) {
					MessageBox.Show(
						"An internal error has occurred. Please contact DTS for assistance.\n\n" + 
						"[" + _invoker + "] " + error.getStackTrace() + "\n" +
						((DTSFlexLib.Debug) ? ("\n\n[Server response]\n" + response) : ""),
						"Error"
					);
					if (_onError != null) {
						_onError();
					}
				}
			}
		}

		private function OnIOError(event:IOErrorEvent):void {
			if ((event.text.match(/^Error \#2032/) != null || event.text.match(/^Error \#2036/) != null) && _retries < 5) {
				LogWindow.Log(_loggerName, "IO error '" + event.text + "' caught. Retrying...");
				_loader.load(_request);
				_retries++;
			}
			else {
				var message:String = "[" + _invoker + "] IO error '" + event.text + "'" + ((DTSFlexLib.Debug) ? (" for URL '" + _request.url + "'") : "");
				LogWindow.Log(_loggerName, message);
				if (!HasFlag(FLAG_SUPPRESSIOERRORALERT)) {
					MessageBox.Show("An internal error has occurred. Please contact DTS for assistance.\n\n" + message, "Error");
				}
				if (_onError != null) {
					_onError();
				}
			}
		}

		private function OnSecurityError(event:SecurityErrorEvent):void {
			if (event.text.match(/^Error \#2048/) != null) {
				if (!HasFlag(FLAG_SUPPRESSBOUNCERINSTRUCTIONS)) {
					ShowBouncerInstruction();
				}
				LogWindow.Log(_loggerName, "Cookie expired for URL '" + _request.url + "'");
			}
			else {
				var message:String = "[" + _invoker + "] Security error '" + event.text + "'" + ((DTSFlexLib.Debug) ? (" for URL '" + _request.url + "'") : "");
				LogWindow.Log(_loggerName, message);
				if (!HasFlag(FLAG_SUPPRESSSECURITYERRORALERT)) {
					MessageBox.Show("An internal error has occurred. Please contact DTS for assistance.\n\n" + message, "Error");
				}
				if (_onError != null) {
					_onError();
				}
			}
		}

		private function OnTimerComplete(event:TimerEvent):void {
			if (BouncerInstructionsDialog.Instance == null) {
				_loader.load(_request);
			}
			else {
				_timer.start();
			}
		}

		private function ShowBouncerInstruction():void {
			BouncerInstructionsDialog.Open();
			if (_timer == null) {
				_timer = new Timer(1000, 1);
				_timer.addEventListener(TimerEvent.TIMER_COMPLETE, OnTimerComplete);
			}
			_timer.start();
		}

		private function HasFlag(flag:uint):Boolean {
			return (Flags & flag) ? true : false;
		}
	}
}
