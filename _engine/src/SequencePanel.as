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
import flash.display.CapsStyle;
import flash.display.DisplayObject;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BevelFilter;
import flash.filters.DropShadowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import nm.ui.ScrollBar;
import nm.ui.ScrollBar_base;
import nm.ui.ScrollClip;
import nm.ui.ToolTip;
public class SequencePanel extends Sprite
{
	public function print(...args):void { if(Engine.DEBUG_MODE) trace(args); }
	public static const SUBMIT_PRESSED:String = "submit-pressed";
	public static const DELAY_MOVE:Number = .25;
	public static const WIDTH_NUMBER_COLUMN:Number = 50;
	public static const HEIGHT_FOOTER:Number = 50;
	public static const RADIUS_PREFIX:Number = 15;
	public static const DISP_PREFIX:Number = 10;
	private static const SCROLL_EDGE:Number = .25;
	private static const MARGIN_SPACE:Number = .25;
	private static const SCROLL_RATE_MAX:Number = 650;
	private static const SCROLL_RATE_MIN:Number = 300;
	private static const SPACING_VERTICAL:int = 10;
	private static const SCROLLBAR_DISPLACEMENT:Number = 8;
	public var endMode:Boolean = false; // if true, all items added are added to the end (for testing purposes)
	public var pendingItemOver:Boolean = false;
	// Embed numbers and period
	[Embed(source="/assets/fonts/plump.ttf", fontName="__PlumpMT", unicodeRange='U+0030-U+0039,U+002E-U+002E')]
	private static var myFont:Class;
	/**
	 * array of sequence display objects belonging to this panel
	 * should always reflect the order shown on the screen
	 */
	private var _orderedSequenceDisplayObjects:Array;
	/**
	 * array of number prefixes to be shown next to sequence display objects
	 */
	private var _numberPrefixes:Array;
	private var _pendingObjectPos:int = -1;
	private var _scrollClip:ScrollClip;
	private var _organizeBubble:Sprite;
	private var _submitButtonHolder:Sprite;
	private var _submitButton:SequencerButton;
	private var _submitButtonText:TextField;
	private var _targetWidth:Number;
	private var _targetHeight:Number;
	private var _highlighted:Boolean;
	private var _scrollThrottle:Number;
	private var _scrollTweener:GTween;
	private var _lastDragY:Number;
	private var _dragDir:int;
	private var _scrollBar:ScrollBar;
	private var _ignoreNextScrollEvent:Boolean;
	/**
	 * constructor
	 */
	public function SequencePanel(displayObjectArray:Array)
	{
		super();
		_orderedSequenceDisplayObjects = displayObjectArray;
		_numberPrefixes = new Array();
		this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
	}
	/**
	 * function called when a child is added to this object.
	 * positions the sequence object and adds it to array of sequence objects
	 */
	public override function addChild(child:DisplayObject):DisplayObject
	{
		//only add the child to the array if it's a sequence object
		if(child is SequenceDisplayObject)
		{
			//find pending object position if it doesn't exist
			if(_pendingObjectPos == -1)
			{
				_pendingObjectPos = findPendingPosition(SequenceDisplayObject(child));
			}
			// make default tooltip direction point left
			var toolTipOptions:Object = ToolTip.getOptionsForTarget(child);
			if(toolTipOptions != null) { toolTipOptions.directionPriority = "left"; }
			//add to array of user ordered items
			var object:SequenceDisplayObject = SequenceDisplayObject(child);
			_orderedSequenceDisplayObjects.splice(_pendingObjectPos, 0, child);
			object.removeFromArray(object.parentArray);
			object.parentArray = _orderedSequenceDisplayObjects;
			//hide "Organize tiles here" bubble if this is the first added
			if(_orderedSequenceDisplayObjects.length == 1)
			{
				fadeTransparency(_organizeBubble, true);
			}
			//listen for when this object is removed
			child.addEventListener(Event.REMOVED, onChildRemoved, false, 0, true);
			//adjust y position to new parent (scroll clip)
			var newPoint:Point = _scrollClip.clip.globalToLocal(this.localToGlobal(new Point(0,0)));
			child.y += newPoint.y;
			//restore opacity for pending object's prefix
			if(_numberPrefixes[_pendingObjectPos] != null)
			{
				_numberPrefixes[_pendingObjectPos].alpha = 1;
			}
			//remove pending item space
			_pendingObjectPos = -1;
			// place the object in an appropriate position
			// [not needed because reAllocateDisplayObjects will do this for us later]
			//allocateDisplayObject(SequenceDisplayObject(child));
			//stop scrolling if scrolling
			setScrolling(0);
			//item is no longer pending
			pendingItemOver = false;
			var returnObject:DisplayObject = _scrollClip.clip.addChild(child);
			//update scrollbar
			updateScrollBar();
			//remove highlight once hovered object is added
			setHighlight(false);
			return returnObject;
		}
		else
		{
			return super.addChild(child);
		}
	}
	/**
	 * visually positions the object in question
	 */
	public function reAllocateDisplayObjects():void
	{
		var i:int
		/* Allocate each display object in a sequential fashion */
		for(i = 0; i < _orderedSequenceDisplayObjects.length; i++)
		{
			var obj:SequenceDisplayObject = SequenceDisplayObject(_orderedSequenceDisplayObjects[i]);
			allocateDisplayObject(obj);
		}
		/* If there is a pending object, reduce opacity; restore opacity to all others */
		if(_pendingObjectPos != -1)
		{
			for(i = 0; i < _numberPrefixes.length; i++)
			{
				if(_pendingObjectPos == i)
				{
					Sprite(_numberPrefixes[i]).alpha = .5;
				}
				else
				{
					Sprite(_numberPrefixes[i]).alpha = 1;
				}
			}
		}
	}
	/**
	 * returns index position of the item user is hovering over list
	 */
	public function findPendingPosition(obj:SequenceDisplayObject):int
	{
		if(endMode) { return _orderedSequenceDisplayObjects.length; }
		var yPos:Number = _scrollClip.clip.globalToLocal(obj.localToGlobal(new Point(0,obj.height / 2))).y;
		var positioned:Boolean = false;
		var pendPos:int = -1;
		obj.customDebugText = '[' + yPos + "]";
		obj.updateDebugInfo();
		//find pending position
		for(var i:int = 0; i < _orderedSequenceDisplayObjects.length; i++)
		{
			var obj2:SequenceDisplayObject =
				SequenceDisplayObject(_orderedSequenceDisplayObjects[i]);
			obj2.customDebugText = (obj2.y + obj2.height / 20) + "x";
			obj2.updateDebugInfo();
			if(yPos < calculateObjectPosition(i) + obj2.height)
			{
				pendPos = i;
				positioned = true;
				break;
			}
		}
		//if position was not found, assume it's at the end/bottom
		if(positioned == false)
		{
			pendPos = i;
		}
		return pendPos;
	}
	/**
	 * Creates a bubble with a number in it to show before sequence
	 * objects.
	 * @param displayNum
	 * 			the number to display
	 * @return a sprite containing a bubble with the given number in it
	 *
	 */
	private function createNumberPrefix(index:int):Sprite
	{
		var prefixX:Number = WIDTH_NUMBER_COLUMN / 2;
		var prefix:Sprite = new Sprite();
		prefix.graphics.beginFill(0x3f5d93);
		prefix.graphics.drawCircle(0, 0, RADIUS_PREFIX);
		prefix.x = prefixX;
		prefix.y = calculateObjectPosition(index) + RADIUS_PREFIX + DISP_PREFIX;
		var label:TextField = new TextField();
		label.defaultTextFormat = new TextFormat("__PlumpMT", 18, 0xffffff, true, null, null, null, null, TextFormatAlign.CENTER);
		label.antiAliasType = AntiAliasType.ADVANCED;
		label.embedFonts = true;
		label.selectable = false;
		label.width = RADIUS_PREFIX * 2;
		label.x = -RADIUS_PREFIX;
		label.text = String(index + 1);
		label.autoSize = TextFieldAutoSize.CENTER;
		label.y = -label.height / 2 + 1;
		prefix.addChild(label);
		return prefix;
	}
	private function calculateObjectPosition(index:int):Number
	{
		return (Engine.PADDING +
			index * (SequenceDisplayObject.HEIGHT + SPACING_VERTICAL));
	}
	/**
	 * positions an object in the panel
	 */
	private function allocateDisplayObject(child:SequenceDisplayObject):void
	{
		//center horizontally
		var newX:Number = (_targetWidth - WIDTH_NUMBER_COLUMN) / 2 - (SequenceDisplayObject.WIDTH) / 2 + WIDTH_NUMBER_COLUMN - (_scrollBar.visible?SCROLLBAR_DISPLACEMENT:0);
		print("x:: " + newX);
		//find position in array
		var pos:int = 0;
		for(var i:int = 0; i < _orderedSequenceDisplayObjects.length; i++)
		{
			if(_orderedSequenceDisplayObjects[i] == child)
			{
				pos = i;
				if(i == _orderedSequenceDisplayObjects.length - 1)
				{
					_organizeBubble
				}
				break;
			}
		}
		//position vertically (add to vertical position if there's a pending object there)
		var newY:Number = calculateObjectPosition(pos);
		// if number prefix doesn't exist here, create it
		if(_numberPrefixes[pos] == null)
		{
			addPrefix(_numberPrefixes.length);
		}
		// allocate this item's number prefix
		Sprite(_numberPrefixes[pos]).y = newY + RADIUS_PREFIX + DISP_PREFIX;
		// account for placeholder space
		if(_pendingObjectPos != -1 && _pendingObjectPos <= i)
		{
			newY += SequenceDisplayObject.HEIGHT + SPACING_VERTICAL;
		}
		// start animation towards target position
		if(Math.round(child.x) != Math.round(newX) || Math.round(child.y) != Math.round(newY))
		{
			child.destroyPositionTween();
			child.positionTween = new GTween(child, DELAY_MOVE, {x:newX, y:newY}, {ease:customTween});
			child.positionTween.onChange = updateScrollBar;
			child.positionTween.onComplete = child.destroyPositionTween;
		}
	}
	private function updateScrollPosition(e:Event):void
	{
		if(_ignoreNextScrollEvent)
		{
			_ignoreNextScrollEvent = false;
			return;
		}
		print("::updateScrollPosition");
		_scrollClip.clip.y = -(_scrollBar.scroll * (_scrollClip.clip.height - _scrollClip.height*.75)) / 100;
	}
	/**
	 * Determine if scrollbar is needed and hide/show it accordingly
	 */
	private function updateScrollBar(tween:GTween = null):void
	{
		//Find distance from top (spacer) to include in size comparison
		var yDisp:Number = 0;
		if(_orderedSequenceDisplayObjects.length)
		{
			yDisp = Math.max(0, _orderedSequenceDisplayObjects[0].y);
		}
		//compare sizes to see if scrollbars are needed
		if(_scrollClip.clip.height + yDisp > _scrollClip.height)
		{
			if(_scrollBar.visible == false) // if needed and currently invisible
			{
				_scrollBar.visible = true;  // show it
				reAllocateDisplayObjects();
			}
		}
		else
		{
			if(_scrollBar.visible == true) // if not needed and is visible
			{
				trace("detected no scroll needed");
				_scrollBar.visible = false;// hide it
				_scrollClip.clip.y = 0;    // scroll to the top
				reAllocateDisplayObjects();
			}
		}
		if(_scrollBar.visible)
		{
			//Update size of scrollbar
			_scrollBar.linesPerPage = _scrollClip.height;
			_scrollBar.totalLines = _scrollClip.clip.height + yDisp;
			_scrollBar.redraw();
			_scrollBar.scroll = (-_scrollClip.clip.y / (_scrollClip.clip.height + yDisp - _scrollClip.height*.75)) * 100;
		}
		_ignoreNextScrollEvent = true;
	}
	public function set submitEnabled(val:Boolean):void {
		_submitButton.enabled = val;
	}
	public function get submitEnabled():Boolean {
		return _submitButton.enabled;
	}
	private static function customTween(t:Number, b:Number, c:Number, d:Number):Number
	{
		var ts:Number=(t/=d)*t;
		var tc:Number=ts*t;
		return b+c*(0*tc*ts + -1*ts*ts + 4*tc + -6*ts + 4*t);
	}
	/**
	 *  Fade the given object to the given alpha
	 *  @param target the DisplayObject to fade in/out
	 *  @param transparent sets to transparent if true, to opaque if false
	 */
	private function fadeTransparency(target:DisplayObject, transparent:Boolean):void
	{
		var newValue:int = transparent? 0:1;
		if(target.alpha != newValue)
		{
			new GTween(target, .5, {alpha:newValue});
		}
	}
	public function onAddedToStage(e:Event):void
	{
		//store reference to original dimensions
		_targetWidth = this.width;
		_targetHeight = this.height;
		//add scroll clip for this to use for sequence objects
		_scrollClip = new ScrollClip(_targetWidth, _targetHeight - HEIGHT_FOOTER, false);
		_scrollClip.hScrollEnabled = false;
		_scrollClip.vScrollEnabled = false;
		_scrollClip.setStyle("bgAlpha", 0);
		super.addChild(_scrollClip);
		//_scrollClip.setStyle('bgFill', 0xff0000);
		//create scrollbar
		_scrollBar = new ScrollBar();
		_scrollBar.addEventListener(ScrollBar_base.SCROLL, updateScrollPosition, false, 0, true);
		_scrollBar.height = _targetHeight - HEIGHT_FOOTER - 5;
		updateScrollBar();
		super.addChild(_scrollBar);
		_scrollBar.x -= 5;
		//create "organize tiles here" graphic
		_organizeBubble = new Sprite();
		_organizeBubble.graphics.beginFill(0xf1f3f6);
		_organizeBubble.graphics.drawRoundRect(0,0,152,19,20);
		_organizeBubble.x = WIDTH_NUMBER_COLUMN + ((_targetWidth - WIDTH_NUMBER_COLUMN) / 2 - _organizeBubble.width / 2);
		_organizeBubble.y = _scrollBar.height / 2 - _organizeBubble.height / 2;
		var organizeBubbleText:TextField = new TextField();
		organizeBubbleText.defaultTextFormat = new TextFormat("AmericanTypewriterFont", 14, 0x93a0b8,null,null,null,null,null,TextFormatAlign.CENTER);
		organizeBubbleText.text = "Organize tiles here";
		organizeBubbleText.embedFonts = true;
		organizeBubbleText.selectable = false;
		organizeBubbleText.width = _organizeBubble.width;
		organizeBubbleText.y = -2;
		_organizeBubble.addChild(organizeBubbleText);
		_scrollClip.clip.addChild(_organizeBubble);
		//create "Submit This Sequence" Button
		_submitButtonHolder = new Sprite();
		_submitButtonHolder.graphics.beginFill(0x6a7890);
		_submitButtonHolder.graphics.lineStyle(Engine.STROKE_PANEL, 0x0, .35);
		_submitButtonHolder.graphics.drawRoundRectComplex(0,0,_targetWidth-Engine.STROKE_PANEL, HEIGHT_FOOTER, 0,0,10,10);
		_submitButtonHolder.graphics.lineStyle(Engine.STROKE_PANEL, 0x6a7890, 1, false, "normal", CapsStyle.NONE);
		_submitButtonHolder.graphics.moveTo(Engine.STROKE_PANEL,0);
		_submitButtonHolder.graphics.lineTo(_submitButtonHolder.width - Engine.STROKE_PANEL * 2, 0);
		_submitButtonHolder.graphics.endFill();
		_submitButtonHolder.y = this.height - _submitButtonHolder.height;
		_submitButtonHolder.filters = [new DropShadowFilter(5, 270, 0, .2, 4, 6)];
		_submitButton = new SequencerButton();
		_submitButton.text = "Submit This Sequence";
		_submitButton.width = 220;
		_submitButton.x = _submitButtonHolder.width / 2 - _submitButton.width / 2;
		_submitButton.y = _submitButtonHolder.height / 2 - _submitButton.height / 2;
		_submitButton.addEventListener(MouseEvent.CLICK, onClickSubmit, false, 0, true);
		_submitButtonHolder.addChild(_submitButton);
		submitEnabled = false; /* disables submit button */
		super.addChild(_submitButtonHolder);
	}
	private function onClickSubmit(event:Event):void
	{
		if(_submitButton.enabled) dispatchEvent(new Event(SUBMIT_PRESSED));
	}
	/**
	 * called when a sequence object child is removed
	 */
	private function onChildRemoved(e:Event):void
	{
		if(DisplayObject(e.target).parent != this)
		{
			//remove listener for this object
			DisplayObject(e.target.parent).removeEventListener(Event.REMOVED, onChildRemoved);
			//re-allocate all sequence objects
			reAllocateDisplayObjects();
			print("Child Removed");
		}
		updateScrollBar();
		//show "Organize tiles here" bubble if this is the first added
		if(_orderedSequenceDisplayObjects.length == 0)
		{
			fadeTransparency(_organizeBubble, false);
		}
	}
	/**
	 * Called when an object is removed from this panel
	 * (this function is not called by a listener but by parent)
	 */
	public function onObjectReparented(obj:SequenceDisplayObject):void
	{
		var index:int = obj.removeFromArray(_orderedSequenceDisplayObjects);
		// Remove prefix from array of prefixes and scrollclip
		_scrollClip.clip.removeChild(_numberPrefixes.pop());
	}
	/**
	 * called when a sequence object is dragged over this panel
	 * (this function is not called by a listener but by parent)
	 */
	public function onObjectDrag(e:Event):void
	{
		var obj1:SequenceDisplayObject = SequenceDisplayObject(e.target);
		var newPos:int = findPendingPosition(obj1);
		var refresh:Boolean = newPos != _pendingObjectPos;
		_pendingObjectPos = newPos;
		//set the positions of all the objects to reflect this pending one
		if(refresh)
		{
			reAllocateDisplayObjects();
		}
		//detect vertical direction of mouse movement
		if(this.mouseY > _lastDragY)
		{
			_dragDir = 1;
		}
		else if(this.mouseY < _lastDragY)
		{
			_dragDir = -1;
		}
		else
		{
			_dragDir = 0;
		}
		_lastDragY = this.mouseY;
		//deal with mouse-position conditional scrolling
		if(_dragDir == 1 && mouseY > height * (1 - SCROLL_EDGE))
		{
			setScrolling(1);
		}
		else if(_dragDir == -1 && mouseY < height * SCROLL_EDGE)
		{
			setScrolling(-1);
		}
		else
		{
			setScrolling(0);
		}
	}
	public function setScrolling(throttle:int):void
	{
		//no scrolling if it isn't necessary
		if(_scrollClip.clip.height <= _scrollClip.height)
		{
//			print('::too short to scroll');
			return;
		}
		//ignore redundant statements
		if(throttle == _scrollThrottle)
		{
//			print('::redundant throttle change (' + throttle + ')');
//			print("::;:" + _scrollClip.vScroll);
			return;
		}
		if(throttle == 0)
		{
			if(_scrollTweener != null)
			{
				_scrollTweener.paused = true;
			}
			_scrollThrottle = 0;
//			print('::throttle = 0');
			return;
		}
		var newY:Number;
		var dY:Number;
		var scrollSpeed:Number = SCROLL_RATE_MAX;
		if(throttle > 0)
		{
			newY = -_scrollClip.clip.height + _scrollClip.height * .75;
			dY = _scrollClip.clip.y - newY;
			if(dY <= 0)
			{
				return;
			}
			_scrollTweener = new GTween(_scrollClip.clip, dY/scrollSpeed, {y:newY});
			_scrollTweener.onChange = updateScrollBar;
			print('::throttle = 1');
		}
		else if(throttle < 0)
		{
			//::todo:: if statement for end of list
			newY = 0;
			dY = newY - _scrollClip.clip.y;
			if(dY <= 0)
			{
				return;
			}
			_scrollTweener = new GTween(_scrollClip.clip, dY/scrollSpeed, {y:newY});
			_scrollTweener.onChange = updateScrollBar;
			print('::throttle = -1');
		}
		_scrollThrottle = throttle;
	}
	/**
	 * Called when an item is moved/dragged over the panel
	 * (this function is not called by a listener but by parent)
	 */
	public function onItemOver(e:Event):void
	{
		pendingItemOver = true;
		// Create a number prefix only if we need one
//		if(_numberPrefixes.length <= _orderedSequenceDisplayObjects.length)
//		{
			addPrefix(_numberPrefixes.length);
//		}
			//highlight when an object is hovering over
			setHighlight(true);
	}
	/**
	 * Called when an item is moved/dragged out of the panel
	 * (this function is not called by a listener but by parent)
	 */
	public function onItemOut(e:Event):void
	{
		// Restore opacity to number prefix at removed location
		if(_numberPrefixes[_pendingObjectPos] != null)
		{
			_numberPrefixes[_pendingObjectPos].alpha = 1;
		}
		// Reset variables relating to a pending object
		pendingItemOver = false;
		_pendingObjectPos = -1;
		reAllocateDisplayObjects();
		setScrolling(0);
		updateScrollBar();
		// Remove prefix from array of prefixes and scrollclip
		_scrollClip.clip.removeChild(_numberPrefixes.pop());
		// remove highlight when item is moved out
		setHighlight(false);
	}
	/**
	 * Adds a number bubble to the list (should appear before tiles)
	 */
	private function addPrefix(val:int):void
	{
		// Draw Number Prefix
		var prefix:Sprite = createNumberPrefix(val);
		// Add prefix to array of prefixes and scrollclip
		_numberPrefixes.push(prefix);
		_scrollClip.clip.addChild(prefix);
	}
	/**
	 * Adds/Removes a highlight for this panel
	 * @param val sets highlight if true, removes if false
	 */
	private function setHighlight(val:Boolean):void
	{
		var multiplier:Number = val? 1 + Engine.HIGHLIGHT_STRENGTH : 1;
		this.transform.colorTransform = new ColorTransform(multiplier, multiplier, multiplier);
	}
}
}