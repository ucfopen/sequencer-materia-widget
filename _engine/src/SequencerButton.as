/* See the file "LICENSE.txt" for the full license governing this code. */
////////////////////////////////////////////////////////////////////////////////
//
//  UCF COURSE DEVELOPMENT AND WEB SERVICES
//  Copyright 2010 UCF Course Development and Web Services
//  All Rights Reserved.
//
//  NOTICE: Course Development and Webservices prohibits the use of the
//  following code without explicit permission.  Permission can be obtained
//  from the New Media team at <newmedia@mail.ucf.edu>.
//
////////////////////////////////////////////////////////////////////////////////
package
{
import flash.display.GradientType;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BevelFilter;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
public class SequencerButton extends Sprite
{
	public static const AUTO_WIDTH:int = -1;
	private static const FILTERS_OUT:Array = [];
	private static const FILTERS_OVER:Array = [new GlowFilter(0xdce1e9)];
	private static const TEXTFORMAT_ENABLED:TextFormat = new TextFormat("AmericanTypewriterFont", 16, 0x3a5568,null,null,null,null,null,TextFormatAlign.CENTER);
	private static const TEXTFORMAT_DISABLED:TextFormat = new TextFormat("AmericanTypewriterFont", 16, 0xacacac,null,null,null,null,null,TextFormatAlign.CENTER)
	private var _enabled:Boolean = true;
	private var _centerOrientation:Boolean = false; // if true, this button is oriented at center rather than 0,0
	private var _submitButtonText:TextField;
	private var _width:Number = AUTO_WIDTH;
	public function SequencerButton():void
	{
		draw();
	}
	public function draw():void
	{
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
		addEventListener(MouseEvent.ROLL_OUT, onMouseOut, false, 0, true);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseOut, false, 0, true);
		addEventListener(MouseEvent.MOUSE_UP, onMouseOver, false, 0, true);
		var bWidth:Number = _width == AUTO_WIDTH? 80: _width;
		var bHeight:Number = 32;
		var buttonMatrix:Matrix = new Matrix();
		buttonMatrix.createGradientBox(bWidth, bHeight, Math.PI / 2);
		graphics.beginGradientFill(GradientType.LINEAR, [0xeeeeee, 0xbbbbbb],[1,1],[1,255],buttonMatrix);
		graphics.lineStyle(2, 0x515c6f);
		graphics.drawRoundRect(0,0,bWidth,bHeight,30);
		filters = FILTERS_OUT;
		buttonMode = true;
		_submitButtonText = new TextField();
		_submitButtonText.defaultTextFormat = TEXTFORMAT_ENABLED;
		_submitButtonText.mouseEnabled = false;
		_submitButtonText.embedFonts = true;
		_submitButtonText.antiAliasType = AntiAliasType.ADVANCED;
		_submitButtonText.selectable = false;
		_submitButtonText.filters = [new DropShadowFilter(.7, 45, 0xffffff, .7)];
		addChild(_submitButtonText);
	}
	public function set text(val:String):void
	{
		_submitButtonText.text = val;
		_submitButtonText.autoSize = TextFieldAutoSize.LEFT;
		redraw();
	}
	public function set centerOrientation(val:Boolean):void
	{
		_centerOrientation = val;
		redraw();
	}
	public function redraw():void
	{
		var hPadding:Number = 8;
		var bWidth:Number = _width == AUTO_WIDTH? _submitButtonText.width + hPadding*2: _width;
		var bHeight:Number = 32;
		var buttonMatrix:Matrix = new Matrix();
		buttonMatrix.createGradientBox(bWidth, bHeight, Math.PI / 2);
		graphics.clear();
		graphics.beginGradientFill(GradientType.LINEAR, [0xeeeeee, 0xbbbbbb],[1,1],[1,255],buttonMatrix);
		graphics.lineStyle(2, 0x515c6f);
		var xPos:Number = _centerOrientation? -bWidth / 2 : 0;
		var yPos:Number = _centerOrientation? -bHeight / 2 : 0;
		graphics.drawRoundRect(xPos,yPos,bWidth,bHeight,30);
		_submitButtonText.x = bWidth / 2 - _submitButtonText.width / 2 + xPos;
		_submitButtonText.y = bHeight / 2 - _submitButtonText.height / 2 - 1 + yPos;
	}
	public override function set width(value:Number):void
	{
//		super.width = value;
		_width = value;
		redraw();
	}
	public function get enabled():Boolean
	{
		return _enabled;
	}
	public function set enabled(val:Boolean):void
	{
		_enabled = val;
		buttonMode = val;
		_submitButtonText.setTextFormat(val? TEXTFORMAT_ENABLED : TEXTFORMAT_DISABLED);
	}
	/* also used for onMouseUp */
	private function onMouseOver(event:Event):void
	{
		if(_enabled) filters = FILTERS_OVER;
	}
	/* also used for onMouseDown */
	private function onMouseOut(event:Event):void
	{
		if(_enabled) filters = FILTERS_OUT;
	}
}
}