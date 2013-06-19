/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
	import com.gskinner.motion.GTween;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import gs.easing.Bounce;
	import gs.easing.Elastic;
	import gs.easing.Expo;
	import gs.easing.Linear;
	import nm.geom.Dimension;
public class NumberFlipper extends Sprite
{
	public static const TARGET_NEXT:int = -1; // used to flip to next number towards target
	public static const FLIPPER_SPACING:int = 5;
	//TODO: eliminate unused vars/constants
	private static const COLOR_YELLOW:Number = 0xf9bf59;
	private static const COLOR_RED:Number = 0xd76350;
	private static const TEXTFORMAT_FLIPPER_NORMAL:TextFormat = new TextFormat("__Helvetica", 72, COLOR_YELLOW, true);
	private static const TEXTFORMAT_FADED:TextFormat = new TextFormat("__Helvetica", 12, 0x828c94, true);
	private static const EASE_BOUNCY:Function = Elastic.easeOut;
	private static const EASE_FLIP:Function = gs.easing.Linear.easeInOut;
	private static const DELAY_FLIP:Number = .20;
	private static const DELAY_FLIP_FINAL:Number = .5;
	private static const DELAY_BOUNCE:Number = .6;
	public var dimensions:Dimension = new Dimension(65, 70);
	public var flipperPosition:int;
	private var _flipper:Sprite;
	private var _flipperText:TextField;
	private var tween:GTween;
	private var _flipDelay:Number;
	private var _flipperTarget:int;
	private var _flipperH:Number = 70;
	private var _flipperW:Number = 65;
	private var _flipperPartTop:DisplayObject;
	private var _flipperPartBottom:DisplayObject;
	private var _flipperPartBottomNew:DisplayObject;
	private var _callbackComplete:Function;
	private var _callbackReachedTen:Function;
	public function NumberFlipper(flipperCompleteCallback:Function = null, flipperReachedTenCallback:Function = null)
	{
		/* store callback references*/
		_callbackComplete = flipperCompleteCallback;
		_callbackReachedTen = flipperReachedTenCallback
		/* draw flipper bg */
		_flipper = new Sprite();
		_flipper.graphics.beginFill(0x292929);
		_flipper.graphics.drawRoundRect(0, 0, _flipperW, _flipperH, 10);
		this.addChild(_flipper);
		/* draw flipper line */
		var flipperLine:Sprite = new Sprite();
		flipperLine.graphics.lineStyle(2, 0x54626d, 1, false, "normal", CapsStyle.NONE);
		flipperLine.graphics.moveTo(0, _flipper.height / 2);
		flipperLine.graphics.lineTo(_flipper.width, _flipper.height / 2);
		_flipper.addChild(flipperLine);
		/* draw flipper NUMBER */
		_flipperText = initTextField(TEXTFORMAT_FLIPPER_NORMAL);
		updateFlipperText(0);
		_flipperText.x = _flipper.width / 2 - _flipperText.width / 2;
		_flipperText.y = _flipper.height / 2 - _flipperText.height / 2;
		_flipper.addChildAt(_flipperText, 0);
		// start flipper at 0
		flipperPosition = 0;
	}
	/**
	 * Pseudo-Recursively flips the flipper one by one using
	 * animations until the given target is reached. Only flips between
	 * 0 and 9. Any number N > 9 will show as N%10 (i.e.: 11 will show 1)
	 *
	 * @param target
	 * 			The number we want to flip to. If -1 (TARGET_NEXT), we just continue
	 * 			flipping to initially set target. (if there is no initial target,
	 * 			calling with -1 will do nothing)
	 */
	public function flipFlipper(target:int = TARGET_NEXT):void
	{
		// under normal circumstances, use regular delay flip
		_flipDelay = DELAY_FLIP;
		// set the target if there is a target to set
		if(target != TARGET_NEXT)
		{
			_flipperTarget = target;
		}
		// special actions for second to last and last flipper position
		var currentPos:int = int(_flipperText.text);
		if(flipperPosition == _flipperTarget - 1)
		{
			// on last flipper, go slow
			_flipDelay = DELAY_FLIP_FINAL;
		}
		else if(flipperPosition == _flipperTarget)
		{
			// flipper is done flipping, call callback function
			if(_callbackComplete != null)
			{
				_callbackComplete.apply();
				flipperPosition = 0;
			}
//			flipperPosition = 0;
			return; // were done here
		}
		/* Get bitmap of top half of old flipper */
		var bd1:BitmapData = new BitmapData(_flipperW, _flipperH / 2, true, 0);
		bd1.draw(_flipper);
		_flipperPartTop = new Bitmap(bd1);
		_flipperPartTop.z = 0;
		/* Get bitmap of bottom half of old flipper */
		var bd2_1:BitmapData = new BitmapData(_flipperW, _flipperH, true, 0);
		bd2_1.draw(_flipper);
		var bd2_2:BitmapData = new BitmapData(_flipperW, _flipperH / 2, true, 0);
		bd2_2.copyPixels(bd2_1, new Rectangle(0, _flipperH / 2, _flipperW, _flipperH / 2),new Point(0,0));
		_flipperPartBottom = new Bitmap(bd2_2);
		/* Place bitmap parts over flipper sprite */
		var flipperOrder:int = this.getChildIndex(_flipper);
		_flipperPartTop.x = _flipper.x;
		_flipperPartTop.y = _flipper.y;
		_flipperPartBottom.x = _flipper.x;
		_flipperPartBottom.y = _flipperPartTop.y + _flipperPartTop.height;
		this.addChildAt(_flipperPartTop, flipperOrder + 1);
		this.addChildAt(_flipperPartBottom, flipperOrder + 2);
		// update flipper number to be shown
		flipperPosition++;
		// if we're at 9 and we're going to 10 (we are), call the "reached ten" callback
		if(_callbackReachedTen != null && flipperPosition % 10 == 0)
		{
			_callbackReachedTen.apply();
		}
		// Change text on flipper sprite to reflect new number
		updateFlipperText(flipperPosition % 10);
		// Change color of flipper to green on last flip if victorious
//		if(_victorious && currentPos == _flipperTarget - 1)
//		{
//			_flipperText.textColor = 0xa8c387;
//		}
		/* Get bitmap of bottom half of new flipper */
		var bd3_1:BitmapData = new BitmapData(_flipperW, _flipperH, true, 0);
		bd3_1.draw(_flipper);
		var bd3_2:BitmapData = new BitmapData(_flipperW, _flipperH / 2, true, 0);
		bd3_2.copyPixels(bd3_1, new Rectangle(0, _flipperH / 2, _flipperW, _flipperH / 2),new Point(0,0));
		_flipperPartBottomNew = new Bitmap(bd3_2);
		/* Now add/position bitmap of bottom half of new flipper */
		_flipperPartBottomNew.x = _flipper.x;
		_flipperPartBottomNew.y = _flipperPartBottom.y;
		_flipperPartBottomNew.rotationX = -100;
		this.addChildAt(_flipperPartBottomNew, flipperOrder + 3);
		// Begin tweening
		// we set x to current x just to give GTween something to do. if we don't, GTween won't work
		// what we really want is for GTween to call rotateFlipperTop every tick; we do our own animation work
		tween = new GTween(_flipperPartTop, _flipDelay / 2, {x:_flipperPartTop.x});
		tween.ease = EASE_FLIP;
		tween.onChange = rotateFlipperTop;
		tween.onComplete = flipPart2;
	}
	/**
	 * @private
	 * Rotates the top part of the flipper according to its GTween.
	 * Needed because a speecial function is required to rotate about a pivot point
	 * and GTween's simple property change doesn't suffice
	 *
	 * (This function is called by GTween's changeListener call)
	 * (This function is derrived from GTween.setProperty)
	 */
	protected function rotateFlipperTop(tween:GTween):void {
		var start:int = 0; // start value for this tween
		var end:int = 80; // end value for this tween
		var ratio:Number = tween.ease(tween.calculatedPosition/tween.duration, 0, 1, 1);
		var value:Number = start+(end-start)*ratio;
		_flipperPartTop.transform.matrix3D.appendRotation(value - _flipperPartTop.rotationX, new Vector3D(1,0,0), new Vector3D(0,_flipperH/2,0));
	}
	/**
	 * @private
	 * Used by tween events.
	 * Starts animation of bottom half of flipper flipping
	 */
	private function flipPart2(tween:GTween):void
	{
		this.removeChild(_flipperPartTop);
		_flipperPartTop = null;
		tween = new GTween(_flipperPartBottomNew, _flipDelay / 2, {rotationX:0});
		tween.onComplete = flipPart3;
	}
	/**
	 * @private
	 * Used by tween events.
	 * Cleans up flipper components after flipping is done
	 */
	private function flipPart3(tween:GTween):void
	{
		this.removeChild(_flipperPartBottom);
		this.removeChild(_flipperPartBottomNew);
		_flipperPartBottom = null;
		_flipperPartBottomNew = null;
		tween = null;
		flipFlipper();
	}
	public function destroyFlipperParts():void
	{
		if(_flipperPartTop != null)
		{
			this.removeChild(_flipperPartTop);
		}
		if(_flipperPartBottom != null)
		{
			this.removeChild(_flipperPartBottom);
		}
		if(_flipperPartBottomNew != null)
		{
			this.removeChild(_flipperPartBottomNew);
		}
		_flipperPartTop = null;
		_flipperPartBottom = null;
		_flipperPartBottomNew = null;
		if(tween != null)
		{
			tween.paused = true;
		}
		tween = null;
	}
	public function updateFlipperText(numCorrect:int):void
	{
		_flipperText.text = numCorrect + "";
	}
	// TODO: find a better way than to repeat this function
	protected function initTextField(format:TextFormat):TextField
	{
		var tf:TextField = new TextField();
		tf.defaultTextFormat = format;
		tf.embedFonts = true;
		tf.selectable = false;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}
	public function set textColor(val:Number):void
	{
		_flipperText.textColor = val;
	}
}
}