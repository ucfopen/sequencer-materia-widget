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
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.ColorTransform;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFormat;
import nm.ui.ToolTip;
public class DistributionPanel extends Sprite
{
	private const INSTRUCTION_FADE_IN_DELAY:Number = .5;
	private const INSTRUCTION_FADE_OUT_DELAY:Number = .1223;
	public var pendingItemOver:Boolean = false;
	private var _background:Sprite;
	private var _instructionLayer:Sprite;
	//array of sequence display objects belonging to this panel
	private var _unorderedSequenceDisplayObjects:Array;
	/**
	 * Constructor - keeps a reference to unordered sequence display object array
	 */
	public function DistributionPanel(displayObjectArray:Array)
	{
		super();
		_unorderedSequenceDisplayObjects = displayObjectArray;
	}
	/**
	 * Override addChild method to make sure any SequenceDisplayObjects added
	 * are placed within bounds and not hanging off
	 *
	 * @param child The SequenceDisplayObject to be added
	 */
	public override function addChild(child:DisplayObject):DisplayObject
	{
		if(child is SequenceDisplayObject)
		{
			if(this.numChildren == 0)  // hide the instruction when adding first item
			{
				fadeTransparency(_instructionLayer, INSTRUCTION_FADE_OUT_DELAY, true);
			}
			allocateDisplayObject(SequenceDisplayObject(child));
			addToList(_unorderedSequenceDisplayObjects, child);
			SequenceDisplayObject(child).parentArray = _unorderedSequenceDisplayObjects;
			// make default tooltip direction point up
			var toolTipOptions:Object = ToolTip.getOptionsForTarget(child);
			if(toolTipOptions != null) { toolTipOptions.directionPriority = "left"; }
		}
		setHighlight(false);
		return super.addChild(child);
	}
	/**
	 * This function is called by the engine whenever a sequencer object is dropped
	 * over the sequence panel. This is done so that we can check (after an object has
	 * been dropped) if there are no more children left so we can show the "done" instruction
	 */
	public function itemDroppedElsewhere():void
	{
		if(this.numChildren == 0)   // show the instruction when empty
		{
			fadeTransparency(_instructionLayer, INSTRUCTION_FADE_IN_DELAY, false);
		}
	}
	/**
	 * Called by SequencerEngine when an item is dragged onto this panel
	 */
	public function onItemOver(e:Event):void
	{
		setHighlight(true);        // highlight this panel
	}
	/**
	 * Called by SequencerEngine when an item is dragged off of this panel
	 */
	public function onItemOut(e:Event):void
	{
		setHighlight(false);        // remove highlight from this panel
	}
	/**
	 * Creates some graphics to add to the background assigned to it.
	 * In particular, the popup that shows when game is complete.
	 */
	public function set background(val:Sprite):void
	{
		/* set the background given */
		_background = val;
		/* create the instruction box that shows up when done */
		_instructionLayer = new Sprite();           // the modal background to contain it all
		_instructionLayer.graphics.lineStyle(Engine.STROKE_PANEL, 0, 0);
		_instructionLayer.graphics.beginFill(0,.4);
		_instructionLayer.graphics.drawRoundRect(0,0,_background.width - Engine.STROKE_PANEL, _background.height, Engine.CORNER_RADIUS);
		var instructionBox:Sprite = new Sprite();    // the box containing the instructions
		var boxW:Number = 360;
		var boxH:Number = 160;
		var padding:Number = 14;
		instructionBox.graphics.beginFill(0xf7eded, 0.85);
		instructionBox.graphics.lineStyle(3, 0x505050, .55, true);
		instructionBox.graphics.drawRoundRect(0, 0, boxW, boxH, Engine.CORNER_RADIUS);
		instructionBox.x = _background.width / 2 - boxW / 2;
		instructionBox.y = _background.height / 2 - boxH / 2;
		var instruction:TextField = new TextField;   // the instructions to be displayed
		instruction.selectable = false;
		instruction.wordWrap = true;
		instruction.width = instructionBox.width - padding * 2;
		instruction.height = instructionBox.height - padding * 2;
		instruction.x = padding;
		instruction.y = padding;
		instruction.defaultTextFormat = new TextFormat("___Lacuna", 18, 0, false);
		instruction.htmlText = "<font size='21' face='__Helvetica'><b>You're Done!</b></font>\n\nMake sure you have the right sequence and press the \"Submit This Sequence\" button at the bottom.";
		instruction.embedFonts = true;
		instruction.antiAliasType = AntiAliasType.ADVANCED;
		instructionBox.addChild(instruction);
		_instructionLayer.addChild(instructionBox);
		_instructionLayer.alpha = 0;
		_background.addChild(_instructionLayer);
	}
	/**
	 * Adds child to list only if it doesn't exist there already
	 */
	private function addToList(list:Array, child:DisplayObject):void
	{
		for(var i:int = 0; i < list.length; i++)
		{
			if(list[i] == child)
			{
				return;
			}
		}
		_unorderedSequenceDisplayObjects.push(child);
	}
	/**
	 * Finds the right x/y position for the given object and places it there
	 * @param child the DisplayObject to be allocated
	 */
	private function allocateDisplayObject(child:DisplayObject):void
	{
		//restrain x-bounds [right]
		if(child.x + child.width > this.width)
		{
			child.x = this.width - child.width;
		}
		//restrain x-bounds [left]
		if(child.x < 0)
		{
			child.x = 0;
		}
		//restrain y-bounds [bottom]
		if(child.y + child.getBounds(child).height > this.height)
		{
			child.y = this.height - child.getBounds(child).height;
		}
		//restrain y-bounds [top]
		if(child.y < 0)
		{
			child.y = 0;
		}
	}
	/**
	 *  Fade the given object to the given alpha
	 *  @param target the DisplayObject to fade in/out
	 *  @param transparent sets to transparent if true, to opaque if false
	 */
	private function fadeTransparency(target:DisplayObject, delay:Number, transparent:Boolean):void
	{
		var newValue:int = transparent? 0:1;
		if(target.alpha != newValue)
		{
			new GTween(target, delay, {alpha:transparent? 0:1});
		}
	}
	/**
	 * Adds/Removes a highlight for this panel
	 * @param val sets highlight if true, removes if false
	 */
	private function setHighlight(val:Boolean):void
	{
		pendingItemOver = val;
		var multiplier:Number = val? 1 + Engine.HIGHLIGHT_STRENGTH : 1;
		_background.transform.colorTransform = new ColorTransform(multiplier, multiplier, multiplier);
	}
}
}