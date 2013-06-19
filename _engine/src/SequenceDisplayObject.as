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
import com.joelconnett.geom.FlexMatrixTransformer;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.Timer;
import mx.core.mx_internal;
import nm.events.StandardEvent;
import nm.ui.ToolTip;
public class SequenceDisplayObject extends Sprite
{
	public function print(...args):void { if(Engine.DEBUG_MODE) trace(args); }
	//--------------------------------------------------------------------------
	//
	//  Constants
	//
	//--------------------------------------------------------------------------
	public static const EVENT_DRAG:String = "object-dragged";
	public static const EVENT_BEGIN_DRAG:String = "object-begin-drag";
	public static const EVENT_DROPPED:String = "object-dropped";
	public static const WIDTH:Number = 164;
	public static const HEIGHT:Number = 61;
	private static const ROTATION_MAX:Number = 16;
	private static const ROTATION_DELAY:Number = .3;
	private static const MIN_TEXT_SIZE:Number = 10;
	private static const SHADOW_DELAY:Number = .5;
	private static const SHADOW_ANGLE:Number = 90;
	private static const SHADOW_ALPHA:Number = 0.5;
	private static const SHADOW_DIST1:Number = 1;
	private static const SHADOW_DIST2:Number = 4;
	private static const TOOLTIP_STYLE:Object =
	{
		textColor: 0x404040,
		textAlign:"left",
		backgroundColor:0xf0e7e7,
		backgroundAlpha:.85,
		borderRadius:2,
		borderThickness:2,
		borderColor:0x000000,
		borderAlpha:.47,
		padding: 10
	}
	private static const TOOLTIP_SHOW_DELAY:Number = 300;
	private static const TOOLTIP_HIDE_DELAY:Number = 200;
	private static const HIGHLIGHT_HIDE_DELAY:Number = 20;
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	public var sequenceObject:SequenceObject;
	public var customDebugText:String = "";
	private var _bg:Sprite;
	private var _bg_highlighted:Sprite;
	private var _bg_completed:Sprite;
	private var _positionTween:GTween;
	private var _dragging:Boolean = false;
	private var _base:Sprite;
	private var _label:TextField;
	private var _debugField:TextField;
	private var _parentArray:Array;
	private var _parentArrayIndex:int;
	private var _rotationTween:GTween;
	private var _rotationValue:Number;
	private var _rotationTweenTarget:Number;
	private var _rotated:Boolean = false;
	private var _shadowTween:GTween;
	private var _shadowDistCurrent:Number = SHADOW_DIST1;
	private var _shadowDistTarget:Number = SHADOW_DIST2;
	private var _tipIcon:ToolTipIcon;
	private var _highlightHideTimer:Timer;
	//--------------------------------------------------------------------------
	//
	//  Functions
	//
	//--------------------------------------------------------------------------
	/**
	 * constructor
	 */
	public function SequenceDisplayObject(sequenceObject:SequenceObject, baseSprite:Sprite)
	{
		//store reference to underlying sequence object
		this.sequenceObject = sequenceObject;
		//store reference to base (root) Sprite
		_base = baseSprite;
		//prepare for flash events
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
		//pick a pseudo-random rotation to use in rotated state
		_rotationValue = -ROTATION_MAX + Math.random() * ROTATION_MAX * 2;
	}
	public function updateDebugInfo():void
	{
		if(_debugField != null)
		{
			_debugField.text = sequenceObject.order + "  " +
				(parent == null? 'null':parent.name) + "  " + customDebugText;
		}
	}
	public function removeFromArray(array:Array):int
	{
		if(array == null)
		{
			return -1;
		}
		var len:int = array.length;
		//remove from given array
		for(var i:int = 0; i < len; i ++)
		{
			if(array[i] == this)
			{
				array.splice(i, 1);
				break;
			}
		}
		//return -1 if not found in given array
		if(i == len)
		{
			return -1;
		}
		return i;
	}
	public function destroyPositionTween(tween:GTween = null):void
	{
		if(_positionTween != null)
		{
			_positionTween.paused = true;
			_positionTween = null;
		}
	}
	public function expandShadow():void
	{
		_shadowDistTarget = SHADOW_DIST2;
		_shadowTween = new GTween(this, SHADOW_DELAY, {alpha:this.alpha});
		_shadowTween.onChange = onShadowTweenChange;
	}
	public function contractShadow():void
	{
		_shadowDistTarget = SHADOW_DIST1;
		_shadowTween = new GTween(this, SHADOW_DELAY, {alpha:this.alpha});
		_shadowTween.onChange = onShadowTweenChange;
	}
	/**
	 * handles the graphics for this object
	 */
	private function draw():void
	{
		//draw background
		_bg = new FL_sequenceObject();
//		var bitmapData:BitmapData = new BitmapData(WIDTH, HEIGHT, false);
//		bitmapData.draw(_bg, null, null, BlendMode.DARKEN, null);
//		graphics.beginBitmapFill(bitmapData, null, false);
//		graphics.drawRect(0, 0, WIDTH, HEIGHT);
		//		filters = [new GlowFilter(0x0, .3, 10, 10)];
		filters = [new DropShadowFilter(1, 90, 0, .5)];
		addChild(_bg);
		_bg_completed = new FL_sequenceObjectCompleted();
		_bg_completed.visible = false;
		addChild(_bg_completed);
		_bg_highlighted = new FL_sequenceObjectSelected();
		_bg_highlighted.visible = false;
		addChild(_bg_highlighted);
		//draw label
		_label = new TextField();
		_label.selectable = false;
		_label.defaultTextFormat = new TextFormat("___Lacuna", 20, 0x240606, null, null, null, null, null, 'center');
		_label.antiAliasType = AntiAliasType.ADVANCED;
		_label.embedFonts = true;
		_label.text = sequenceObject.name;
		_label.autoSize = TextFieldAutoSize.CENTER;
		var h:Number = _label.height;
		_label.autoSize = TextFieldAutoSize.NONE;
		_label.width = WIDTH - Engine.PADDING;
		_label.height = h;
		if(_label.textWidth > _label.width) //determine if multiline is needed
		{
			_label.height = HEIGHT;
			_label.multiline = true;
			_label.wordWrap = true;
		}
		_label.x = this.width / 2 - _label.width / 2;
		_label.y = this.height / 2 - _label.height / 2;
		if(_label.textHeight > _label.height) // determine if smaller text size is needed
		{
			shrinkToFit(_label);
		}
		this.addChild(_label);
		//add description tooltip
		var w:Number = calculateToolTipWidth(sequenceObject.description);
		ToolTip.add(this, sequenceObject.description, {width:w, showCallback:onShowTip, hideCallback:onHideTip, showDelay:TOOLTIP_SHOW_DELAY, hideDelay:TOOLTIP_HIDE_DELAY}, TOOLTIP_STYLE);
		//draw debug field
		_debugField = new TextField();
		_debugField.selectable = false;
		_debugField.defaultTextFormat = new TextFormat(null, 8, 0xffffff, false, null, null, null, null, 'center');
		_debugField.text = "_debugField";
		_debugField.autoSize = TextFieldAutoSize.LEFT;
		_debugField.x = 0;
		_debugField.y = this.height - _debugField.height - 2;
		updateDebugInfo();
		// add tooltip icon (if has tooltip)
		if(sequenceObject.description.length)
		{
			_tipIcon = new ToolTipIcon();
			var thisRef:DisplayObject = this;
			_tipIcon.addEventListener(MouseEvent.CLICK, function(e:Event):void { ToolTip.showNow(thisRef); }, false, 0, true);
			_tipIcon.x = WIDTH - _tipIcon.width * .5;
			_tipIcon.y = -_tipIcon.height * .4;
			addChild(_tipIcon);
		}
	}
	private function onShowTip():void
	{
		if(_tipIcon) { _tipIcon.alpha = 0; }
	}
	private function onHideTip():void
	{
		if(_tipIcon) { _tipIcon.alpha = 1; }
	}
	/**
	 * Determines a width for a tooltip based on the number of characters
	 * to be shown in the tooltip
	 */
	private function calculateToolTipWidth(description:String):Number
	{
		if(description.length < 20)
		{
			return 120;
		}
		else if(description.length < 360)
		{
			return 200;
		}
		else if(description.length < 1000)
		{
			return 350;
		}
		else
		{
			return 500;
		}
	}
	private function shrinkToFit(label:TextField):void
	{
		// shrink text
		var format:TextFormat = label.getTextFormat();
		format.size = Math.max(MIN_TEXT_SIZE, Number(format.size) - 2);
		label.setTextFormat(format);
		// stop when text fits or when we reach min text size
		if(label.textHeight <= label.height || Number(format.size) == MIN_TEXT_SIZE)
		{
			trace("\n");
			return;
		}
		else {
			trace("th:" + label.textHeight + "    lh:" + label.height);
		}
		// continue shrinking text
		shrinkToFit(label);
	}
	private function appendRotationCenter(angleDeg:Number):void
	{
		var m:Matrix = this.transform.matrix;
		FlexMatrixTransformer.rotateAroundInternalPoint(m, WIDTH / 2, HEIGHT / 2, angleDeg);
		this.transform.matrix = m;
	}
	/**
	 * called when this object is added to the stage
	 */
	private function onAddedToStage(e:Event):void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		//draw the object
		draw();
		//prepare for user interaction events
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
		addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver, false, 0, true);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut, false, 0, true);
		updateDebugInfo();
	}
	/**
	 * Shows the highlight sprite that shows this tile as highlighted
	 */
	private function onMouseOver(e:Event):void
	{
		_bg_highlighted.visible = true;
		// if timer is active to hide the highlight, destroy it
		if(_highlightHideTimer != null)
		{
			_highlightHideTimer.stop();
			_highlightHideTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, hideHighlight);
			_highlightHideTimer = null;
		}
	}
	/**
	 * Starts a timer with the intent of hiding the highlight on the tile after a given delay
	 */
	private function onMouseOut(e:Event):void
	{
		_highlightHideTimer = new Timer(HIGHLIGHT_HIDE_DELAY, 1);
		_highlightHideTimer.addEventListener(TimerEvent.TIMER_COMPLETE, hideHighlight, false, 0, true);
		_highlightHideTimer.start();
	}
	/**
	 * Timer-Driven function that will hide the sprite that makes this tile appear highlighted
	 */
	private function hideHighlight(e:TimerEvent):void
	{
		_highlightHideTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, hideHighlight);
		_bg_highlighted.visible = false;
	}
	/**
	 * called when the mouse button is released pressed this object
	 */
	private function onMouseDown(e:Event):void
	{
		//stop any active tweens
		destroyPositionTween();
		//let listeners know we're draggin now
		dispatchEvent(new Event(EVENT_BEGIN_DRAG));
		//calculate bounds and begin dragging
		var parentBounds:Rectangle = Sprite(parent).getBounds(parent);
		parentBounds.y = 0;
		parentBounds.width -= this.width;
		// hack fix
		parentBounds.height -= (this.getBounds(this).height + parent.y*2);
		this.startDrag(false, parentBounds);
		//set flag to show this item is being dragged
		_dragging = true;
		updateDebugInfo();
	}
	/**
	 * called when the mouse button is released over this object
	 */
	private function onMouseUp(e:Event):void
	{
		//Only stop draggin if being dragged
		if(_dragging == true)
		{
			_dragging = false;
			//stop dragging
			this.stopDrag();
			//announce the dropping of this object
			dispatchEvent(new Event(EVENT_DROPPED));
			updateDebugInfo();
		}
	}
	/**
	 * Called repeatedly while the mouse moves (if over this object)
	 */
	private function onMouseMove(e:Event):void
	{
		//Only take action if dragging
		if(_dragging == true)
		{
			dispatchEvent(new Event(EVENT_DRAG));
		}
		updateDebugInfo();
	}
	/**
	 * @private
	 * Rotates the display object about an axis by using SequenceDisplayObject.appendRotationCenter
	 * Needed because a speecial function is required to rotate about a pivot point
	 * and GTween's simple property change doesn't suffice
	 *
	 * (This function is called by GTween's change call)
	 * (This function is derrived from GTween.setProperty)
	 */
	private function onRotateTweenChange(e:Event):void
	{
		var start:int = rotation; // start value for this tween
		var end:int = _rotationTweenTarget; // end value for this tween
		var ratio:Number = e.currentTarget.ease(e.currentTarget.calculatedPosition/e.currentTarget.duration, 0, 1, 1);
		var value:Number = start+(end-start)*ratio;
		appendRotationCenter(value - this.rotation);
	}
	/**
	 * @private
	 * Animates expansion of a drop shadow
	 * Needed because a speecial function is required animate filters
	 * and GTween's simple property change doesn't suffice
	 *
	 * (This function is called by GTween's change call)
	 * (This function is derrived from GTween.setProperty)
	 */
	private function onShadowTweenChange(tween:GTween):void
	{
		var start:int = _shadowDistCurrent; // start value for this tween
		var end:int = _shadowDistTarget; // end value for this tween
		var ratio:Number = tween.ease(tween.calculatedPosition/tween.duration, 0, 1, 1);
		var value:Number = start+(end-start)*ratio;
		_shadowDistCurrent = value;
		filters = [new DropShadowFilter(value, SHADOW_ANGLE, 0, SHADOW_ALPHA)];
	}
	public function set parentArray(newParentArray:Array):void
	{
		//set the new parent array
		_parentArray = newParentArray;
		updateDebugInfo();
	}
	public function get parentArray():Array
	{
		return _parentArray;
	}
	public function get order():int
	{
		return sequenceObject.order;
	}
	public function set rotated(val:Boolean):void
	{
		if(val && !_rotated)
		{
//			if(_rotationTween != null) { _rotationTween.pause(); }
//			_rotationTweenTarget = _rotationValue;
//			_rotationTween = new GTween(this, ROTATION_DELAY, {alpha:this.alpha}, {change:onRotateTweenChange});
			appendRotationCenter(_rotationValue - this.rotation);
			_rotated = true;
		}
		else if(!val && _rotated)
		{
//			_rotationTweenTarget = 0;
//			if(_rotationTween != null) { _rotationTween.pause(); }
//			_rotationTween = new GTween(this, ROTATION_DELAY, {alpha:this.alpha}, {change:onRotateTweenChange});
			appendRotationCenter(0 - this.rotation);
			_rotated = false;
		}
	}
	public function set positionTween(val:GTween):void
	{
		if(_dragging == false)
		{
			_positionTween = val;
		}
	}
	public function get positionTween():GTween
	{
		return _positionTween;
	}
	public function set completed(val:Boolean):void
	{
		_bg_completed.visible = val;
	}
}
}