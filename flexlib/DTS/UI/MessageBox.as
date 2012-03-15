package DTS.UI
{
	import mx.controls.Alert;
	import mx.events.CloseEvent;

	public class MessageBox
	{
		public static function Show(message:String, title:String="", closeHandler:Function=null):void {
			Alert.show(message, title, 4, null, closeHandler);
		}

		public static function ConfirmYesNo(message:String, title:String, onConfirm:Function):void {
			Alert.show(message, title, Alert.YES | Alert.NO, null, function(event:CloseEvent):void {
				if (event.detail == Alert.YES) {
					onConfirm();
				}
			});
		}

		public static function ConfirmOKCancel(message:String, title:String, onConfirm:Function):void {
			Alert.show(message, title, Alert.OK | Alert.CANCEL, null, function(event:CloseEvent):void {
				if (event.detail == Alert.OK) {
					onConfirm();
				}
			});
		}

		public static function PromptForText(title:String, hint:String, value:String, onValidate:Function, onComplete:Function, onCancel:Function=null):TextInputPrompt {
			return TextInputPrompt.Open(title, hint, value, onValidate, onComplete, onCancel);
		}

		public static function PromptForTextMultiline(title:String, hint:String, value:String, onValidate:Function, onComplete:Function, onCancel:Function=null):TextAreaPrompt {
			return TextAreaPrompt.Open(title, hint, value, onValidate, onComplete, onCancel);
		}
	}
}
