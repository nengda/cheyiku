package DTS.UI
{
    import mx.containers.Canvas;
    import mx.styles.StyleManager;
    import mx.utils.ColorUtil;

	[Style(name="fillColors",type="Array",format="Color",inherit="no")]
	[Style(name="fillAlphas",type="Array",format="Number",inherit="no")]
    public class GradientCanvas extends Canvas
    {
        override protected function updateDisplayList(w:Number, h:Number):void {
            super.updateDisplayList(w, h);

            var fillColors:Array = getStyle("fillColors");
            var fillAlphas:Array = getStyle("fillAlphas");
            var cornerRadius:Number = getStyle("cornerRadius");
            StyleManager.getColorNames(fillColors);

            graphics.clear();
            drawRoundRect(0, 0, w, h, cornerRadius, fillColors, fillAlphas, verticalGradientMatrix(0, 0, w, h));
        }
    }
}