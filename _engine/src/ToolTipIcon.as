package
{
import flash.display.Sprite;
import flash.filters.DropShadowFilter;
public class ToolTipIcon extends Sprite
{
	public static const WIDTH:Number = 22;
	public static const HEIGHT:Number = BUBBLE_H + TIP_H;
	private static const BUBBLE_H:Number = 15;
	private static const CURVE:Number = 3;
	private static const TIP_X:Number = 0;
	private static const TIP_W:Number = 5;
	private static const TIP_H:Number = 5;
	public function ToolTipIcon():void
	{
		graphics.lineStyle(1, 0, .4, true);
		graphics.beginFill(0xf7eded, .85);
		graphics.moveTo(CURVE, 0);
		graphics.lineTo(WIDTH - CURVE, 0);
		graphics.curveTo(WIDTH, 0, WIDTH, CURVE);
		graphics.lineTo(WIDTH, BUBBLE_H - CURVE);
		graphics.curveTo(WIDTH, BUBBLE_H, WIDTH - CURVE, BUBBLE_H);
		graphics.lineTo(CURVE + TIP_X + TIP_W, BUBBLE_H);
		graphics.lineTo(CURVE + TIP_X, BUBBLE_H + TIP_H);
		graphics.lineTo(CURVE + TIP_X, BUBBLE_H);
		graphics.lineTo(CURVE, BUBBLE_H);
		graphics.curveTo(0, BUBBLE_H, 0, BUBBLE_H - CURVE);
		graphics.lineTo(0, CURVE);
		graphics.curveTo(0, 0, CURVE, 0);
		graphics.endFill();
		this.filters = [new DropShadowFilter(1, 45, 0, .35)];
	}
}
}