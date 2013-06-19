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
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import gs.easing.Bounce;
import gs.easing.Elastic;
import gs.easing.Expo;
public class RetryPopup extends SequencerPopup
{
	private var _parent:Sprite;
	private var WIDTH:Number = 325;
	private var HEIGHT:Number = 300;
	private static const COLOR_YELLOW:Number = 0xf9bf59;
	private static const COLOR_RED:Number = 0xd76350;
	private static const COLOR_GREEN:Number = 0xa8c387;
	private static const EASE_BOUNCY:Function = Elastic.easeOut;
	private static const DELAY_BOUNCE:Number = .6;
	private static const TEXTFORMAT_FADED:TextFormat = new TextFormat("__Helvetica", 12, 0x828c94, true);
	private var _triesLeftHolder:Sprite;
	private var _text2:TextField;
	private var _text3:TextField;
	private var _whiteEllipse:Sprite;
	private var _button:SequencerButton;
	private var _flipper0:NumberFlipper; // used for the one's place (i.e.: 1[5])
	private var _flipper1:NumberFlipper; // used for the ten's place (i.e.: [1]5)
	private var _victorious:Boolean = false;
	private var _practiceMode:Boolean = false;
	private var tween:GTween;
	public function RetryPopup(baseSprite:Sprite)
	{
		super(WIDTH, HEIGHT);
		//store reference to base
		_parent = baseSprite;
	}
	override protected function draw():void
	{
		super.draw();
		/* draw inner pannel */
		var spaceForText:Number = 30;
		drawInnerPanel(new Rectangle(PADDING_PANEL_H, PADDING_PANEL_V, _width - PADDING_PANEL_H * 2, _height - PADDING_PANEL_V * 2 - spaceForText));
		/* draw button */
		// this button is center oriented... all positioning math is based around that
		_button = new SequencerButton();
		_button.centerOrientation = true;
		updateButtonText("Try again!");
		_popup.addChild(_button);
		_button.addEventListener(MouseEvent.CLICK, onClickButton, false, 0, true);
		/* draw informational text heading ("You have") */
		var text0:TextField = initTextField(TEXTFORMAT_TITLE);
		text0.text = "You have";
		text0.x = _innerPanel.width / 2 - text0.width / 2;
		text0.y = PADDING_TEXT_V;
		_innerPanel.addChild(text0);
		/* create flipper */
		_flipper0 = new NumberFlipper(onFlipperReachedTarget, onFlipper0ReachedTen);
		_flipper1 = new NumberFlipper();
		_flipper0.y = text0.y + text0.height;
		_flipper1.y = text0.y + text0.height;
		arrangeFlippers(0);
		_innerPanel.addChild(_flipper0);
		_innerPanel.addChild(_flipper1);
		/* draw informational text ("items in the right spot") */
		var text1:TextField = initTextField(TEXTFORMAT_TITLE);
		text1.text = "items in the right spot";
		text1.x = _innerPanel.width / 2 - text1.width / 2;
		text1.y = _flipper0.y + _flipper0.dimensions.height;
		_innerPanel.addChild(text1);
		/* draw informational text ("out of X") */
		_text2 = initTextField(TEXTFORMAT_FADED);
		updateTotalItemsText(0);
		_text2.x = _innerPanel.width / 2 - _text2.width / 2;
		_text2.y = text1.y + text1.height - 5;
		_innerPanel.addChild(_text2);
		/* draw informational text ("You have X tries left") */
		// this sprite is center oriented... all positioning math is based around that
		_triesLeftHolder = new Sprite();
		_whiteEllipse = new Sprite(); // create circle for tries left
		_triesLeftHolder.addChildAt(_whiteEllipse, 0);
		_text3 = initTextField(TEXTFORMAT_NORMAL);
		_triesLeftHolder.addChild(_text3);
		_popup.addChild(_triesLeftHolder);
		updateTriesText(0);
	}
	public function show(freeTriesLeft:int, numCorrect:int, totalItems:int, penalty:int, userLost:Boolean = false):void
	{
		// shows and places one or two flippers according to total possible count
		arrangeFlippers(totalItems);
		if(userLost) /* if player loses */
		{
			updateButtonText("Visit Score Screen");
			setFlipperColor(COLOR_YELLOW);
		}
		else if(numCorrect == totalItems) /* if user wins */
		{
			_victorious = true;
			updateButtonText("Visit Score Screen");
			setFlipperColor(COLOR_YELLOW);
		}
		else
		{
			updateButtonText("Try again!");
			setFlipperColor(COLOR_YELLOW);
		}
		/* Hide components to be shown later */
		_button.visible = false;
		_triesLeftHolder.visible = false;
		/* Update component contents */
		_practiceMode = penalty == 0;
		updateTriesText(freeTriesLeft, penalty, numCorrect == totalItems, userLost);
		//		numCorrect == totalItems
		flipToTarget(numCorrect);
		updateTotalItemsText(totalItems);
		if(numCorrect == 0) /* if no answers are right */
		{
			setFlipperColor(COLOR_RED);
		}
		//show the window
		this.visible = true;
	}
	private function flipToTarget(target:int):void
	{
		_flipper0.flipFlipper(target);
	}
	/**
	 * Arrange and include flippers to account for maximum number we will reach.
	 * This class currently only supports numbers up to 99 but can be easily expanded
	 *
	 * @param maxNumber maximum number this flipper will reach
	 */
	private function arrangeFlippers(maxNumber:int):void
	{
		if(maxNumber < 10)
		{ // max number is less than 10
			_flipper1.visible = false;
			_flipper0.x = _innerPanel.width / 2 - _flipper0.dimensions.width / 2;
		}
		else
		{ //  max number is greater than 9
			_flipper1.visible = true;
			var combinedWidth:Number = _flipper0.dimensions.width + _flipper1.dimensions.width + NumberFlipper.FLIPPER_SPACING;
			_flipper1.x = _innerPanel.width / 2 - combinedWidth / 2;
			_flipper0.x = _flipper1.x + _flipper1.width + NumberFlipper.FLIPPER_SPACING;
		}
	}
	private function setFlipperColor(color:Number):void
	{
		_flipper0.textColor = color;
		_flipper1.textColor = color;
	}
	/**
	 * @private
	 * Called when flipper is done flipping towards its target
	 */
	private function onFlipperReachedTarget():void
	{
		trace("flipper reached target");
		if(!_practiceMode || _victorious)
		{
			_triesLeftHolder.visible = true;
			_triesLeftHolder.scaleX = _triesLeftHolder.scaleY = 0.5;
			tween = new GTween(_triesLeftHolder, DELAY_BOUNCE, {scaleX:1, scaleY:1});
			tween.ease = EASE_BOUNCY;
			tween.onComplete = onTriesHolderShown;
		}
		else
		{
			_button.y -= 10;
			onTriesHolderShown(null);
		}
		if(_victorious)
		{
			setFlipperColor(COLOR_GREEN);
			_victorious = false;
		}
	}
	private function onFlipper0ReachedTen():void
	{
		_flipper1.flipFlipper(_flipper0.flipperPosition / 10);
	}
	/**
	 * Called when tries holder ("you have X tries left.") is shown.
	 * Shows Button in same fashion that tries holder was shown
	 */
	private function onTriesHolderShown(tween:GTween):void
	{
		_button.visible = true;
		_button.scaleX = _button.scaleY = .5;
		this.tween = new GTween(_button, DELAY_BOUNCE, {scaleX:1, scaleY:1});
		this.tween.ease = EASE_BOUNCY;
	}
	/**
	 * Sets up the white field that give information about tries left and points deducted
	 */
	private function updateTriesText(freeTriesLeft:int, penalty:int = 0, allCorrect:Boolean = false, userLost:Boolean = false):void
	{
		_whiteEllipse.graphics.clear();
		_whiteEllipse.graphics.beginFill(0xffffff);
		_text3.autoSize = TextFieldAutoSize.LEFT;
		if(allCorrect) // user won
		{
			_text3.htmlText = "<font color='#50791e'>You have the correct sequence!</font>"
			_whiteEllipse.graphics.drawRoundRect(0,0,_text3.width + 20,20, 20);
			_whiteEllipse.y = _text3.y;
			_whiteEllipse.x = -_whiteEllipse.width / 2;
		}
		else if(userLost)       // user lost the game
		{
			_text3.htmlText = "<font color='#ac4d3d'>You've Lost!</font>"
			_whiteEllipse.graphics.drawRoundRect(0,0,_text3.width + 20,20, 20);
			_whiteEllipse.y = _text3.y;
			_whiteEllipse.x = -_whiteEllipse.width / 2;
		}
		else if(freeTriesLeft > 0)   // we still have free tries left
		{
			_text3.htmlText = "<font color='#50791e'>You have " + freeTriesLeft + " free tries left.</font>"
			_whiteEllipse.graphics.drawRoundRect(0,0,_text3.width + 20,20, 20);
			_whiteEllipse.y = _text3.y;
			_whiteEllipse.x = -_whiteEllipse.width / 2;
		}
		else if(freeTriesLeft == 0)  // this was our last free try
		{
			_text3.htmlText = "<font color='#ac4d3d'>Next time, you lose points!</font>"
			_whiteEllipse.graphics.drawRoundRect(0,0,_text3.width + 20,20, 20);
			_whiteEllipse.y = _text3.y;
			_whiteEllipse.x = -_whiteEllipse.width / 2;
		}
		else                         // user lost points
		{
			_text3.htmlText = "You lost  <font color='#ac4d3d'>" + penalty + "</font>  points.";
			_whiteEllipse.graphics.drawCircle(0,0,10);
			_whiteEllipse.y = _text3.y + 11;
			_whiteEllipse.x = 5;//_text3.width / 2 - _whiteEllipse.width / 2 + 10;
		}
		_whiteEllipse.graphics.endFill();
		_text3.x = - _text3.width / 2;
		_triesLeftHolder.x = _triesLeftHolder.parent.width / 2;
		_triesLeftHolder.y = _button.y - _button.height / 2 - _triesLeftHolder.height - 10;
	}
	private function updateTotalItemsText(totalItems:int):void
	{
		_text2.text = "out of " + totalItems + ".";
	}
	private function updateButtonText(text:String):void
	{
		_button.text = text;
		_button.x = _width / 2;
		_button.y = _height - _button.height / 2 - 15;
	}
	private function onClickButton(e:MouseEvent):void
	{
		visible = false;
		_flipper0.updateFlipperText(0);
		dispatchEvent(new Event(Event.CLOSE));
		_flipper0.destroyFlipperParts();
	}
}
}