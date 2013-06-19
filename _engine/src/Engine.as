/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
import flash.display.BitmapData;
import flash.display.CapsStyle;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import nm.gameServ.engines.EngineCore;
import nm.geom.Dimension;
/**
 * Main class for Sequencer
 */
public class Engine extends EngineCore
{
	public function print(...args):void { if(Engine.DEBUG_MODE) trace(args); }
	//--------------------------------------------------------------------------
	//
	//  Fonts
	//
	//--------------------------------------------------------------------------
	// for embedded fonts to work in flex 4.1 framework, add: embedAsCFF="false"
	[Embed(source="/assets/fonts/Chunkfive.ttf", fontFamily="_ChunkFiveFont", unicodeRange='U+0041-U+005A, U+0061-U+007A, U+0021-U+0021, U+003A-U+003A, U+0028-U+0039')]
	public static const chunkFont:Class;
	[Embed(source="/assets/fonts/AmericanTypewriter.ttc", fontName="AmericanTypewriterFont", fontWeight='bold')]
	public static const typewriterFont:Class;
	[Embed(source="/assets/fonts/lacurg__.ttf", fontName="___Lacuna", unicodeRange='U+0041-U+005A, U+0021-U+003F, U+0061-U+007E')]
	public static const lacurgFont:Class;
	[Embed(source="/assets/fonts/helr65w.ttf", fontName="__Helvetica", fontWeight='bold')]
	public static const helveticaFont:Class;
	//--------------------------------------------------------------------------
	//
	//  Constants
	//
	//--------------------------------------------------------------------------
	public static const DEBUG_MODE:Boolean = false;
	/**
	 * padding around the edge of the screen
	 */
	public static const PADDING:int = 10;
	/**
	 * spacing between components
	 */
	public static const SPACING:int = 5;
	/**
	 * how curvy the rounded corners are
	 */
	public static const CORNER_RADIUS:int = 15;
	/**
	 * the colors used in the title (chosen from here randomly)
	 */
	private static const TITLE_COLORS:Array = ["#4d7bc7", "#56c74d", "#e58d25"];
	/**
	 * thickness of panel borders
	 */
	public static const STROKE_PANEL:int = 3;
	/**
	 * strength of mouse-over highlight for panels
	 */
	public static const HIGHLIGHT_STRENGTH:Number = 0.06;
	/**
	 * number of times to try placing a sequence tile in the distribution panel
	 * without collision before giving up
	 */
	private static const RANDOM_PLACEMENT_TRIES:int = 15;
	//--------------------------------------------------------------------------
	//
	//  Instance Variables
	//
	//--------------------------------------------------------------------------
	/**
	 * the background for this engine
	 */
	private var _bg:Sprite;
	/**
	 * the base for all components to build from
	 */
	private var _base:Sprite;
	/**
	 * background and graphics for the distribution panel
	 */
	private var _distPanelBG:Sprite;
	/**
	 * panel where sequence objects are distributed
	 */
	private var _distPanel:DistributionPanel;
	/**
	 * the dimensions for the distance panel
	 */
	private var _distPanelDim:Dimension;
	/**
	 * panel where sequence objects are distributed
	 */
	private var _titleBox:Sprite;
	/**
	 * dimensions of the title box panel
	 */
	private var _titleBoxDims:Dimension;
	/**
	 * panel on bottom of screen where on-the-fly score details are presented
	 */
	private var _scoreDetailsBox:Sprite;
	/**
	 * dimensions of the score details panel
	 */
	private var _scoreDetailsDims:Dimension;
	/**
	 * text field in score details box that says "Penalties" or "Free Tries"
	 */
	private var _scoreDetailsMainField:TextField;
	/**
	 * text field in score details box that tells user penalty per incorrect sequence
	 */
	private var _scoreDetailsCaption:TextField;
	/**
	 * panel where sequence items are placed into correct sequence
	 */
	private var _sequencePanel:SequencePanel;
	/**
	 * popup that shows how many questions you got wrong/right
	 */
	private var _retryPopup:RetryPopup;
	/**
	 * popup that give instructions on how to play
	 */
	private var _introPopup:IntroPopup;
	/**
	 * button that brings out the next item from the randomized objects list
	 */
	private var _debugField:TextField;
	/**
	 * array of sequence objects (non-visual) loaded from the qSet
	 */
	private var _randomizedSequenceObjects:Array; //<SequenceObject>
	/**
	 * array of sequence in correct order to be compared to at the end
	 */
	private var _idealOrderedSequenceObjects:Array; //<SequenceObject>
	/**
	 * array of visible sequence objects in the distribution panel
	 */
	private var _unorderedSequenceDisplayObjects:Array; //<SequenceDisplayObject>
	/**
	 * collection of visible sequence objects sequence (ordered) panel
	 * :: objects are moved here from the unordered collection when dragged
	 *    into the ordered panel
	 */
	private var _orderedSequenceDisplayObjects:Array; //<SequenceDisplayObject>
	/**
	 * number of attempts allowed before answers are submitted
	 */
	private var _freeAttempts:int;
	/**
	 * percent lost for each incorrect attempt (ranges from 0-100)
	 */
	private var _attemptPenalty:Number;
	/**
	 * number of attempts used
	 */
	private var _attemptsUsed:int;
	/**
	 * current score for the user (starts at 100, decreases with incorrect attempts)
	 */
	private var _runningScore:int;
	//--------------------------------------------------------------------------
	//
	//  Functions
	//
	//--------------------------------------------------------------------------
	/**
	 * function called when the engine is first started.
	 * initiates and creates everything. serves as a constructor
	 */
	protected override function startEngine():void
	{
		var qq:* = EngineCore.qSetData;
		//initialize arrays
		_randomizedSequenceObjects = new Array();
		_idealOrderedSequenceObjects = new Array();
		_unorderedSequenceDisplayObjects = new Array();
		_orderedSequenceDisplayObjects = new Array();
		// Initialize scoring variables
		_attemptsUsed = 0;
		_runningScore = 100;
		_attemptPenalty = EngineCore.qSetData.items[0].options.penalty;
		_freeAttempts = EngineCore.qSetData.items[0].options.freeTries;
		//load sequence objects from EngineCore.qSetData
		for (var i:int = 0; i < EngineCore.qSetData.items[0].items.length; i++)
		{
			var q:Object = EngineCore.qSetData.items[0].items[i]
			var name:String = q.questions[0].text;
			var order:int = (int)(q.answers[0].text);
			_randomizedSequenceObjects.push(new SequenceObject(name, q.options.description, order, q.id));
			_idealOrderedSequenceObjects.push(new SequenceObject(name, q.options.description, order, q.id));
		}
		//find ideal order for sequence objects
		_idealOrderedSequenceObjects.sortOn('order', Array.NUMERIC);
		//randomize objects in randomized list
		shuffleArray(_randomizedSequenceObjects);
		//draw background
		_bg = new Sprite();
		var bgMatrix:Matrix = new Matrix();
		bgMatrix.createGradientBox(widget.width, widget.height, Math.PI / 2);
		_bg.graphics.beginGradientFill(GradientType.LINEAR, [0x855d48, 0x4c3c35], [1,1], [0,255], bgMatrix);
		_bg.graphics.drawRect(0,0,widget.width, widget.height);
		var bitmapData:BitmapData = new BitmapData(4,4,true);
		bitmapData.setPixel32(0,0,0x1D000000); // Top Left Color
		bitmapData.setPixel32(0,1,0x1D000000);
		bitmapData.setPixel32(1,0,0x1D000000);
		bitmapData.setPixel32(1,1,0x1D000000);
		bitmapData.setPixel32(2,0,0x00000000); // Top Right Color
		bitmapData.setPixel32(2,1,0x00000000);
		bitmapData.setPixel32(3,0,0x00000000);
		bitmapData.setPixel32(3,1,0x00000000);
		bitmapData.setPixel32(0,2,0x00000000); // Bottom Left Color
		bitmapData.setPixel32(0,3,0x00000000);
		bitmapData.setPixel32(1,2,0x00000000);
		bitmapData.setPixel32(1,3,0x00000000);
		bitmapData.setPixel32(2,2,0x06ffffff); // Bottom Right Color
		bitmapData.setPixel32(2,3,0x06ffffff);
		bitmapData.setPixel32(3,2,0x06ffffff);
		bitmapData.setPixel32(3,3,0x06ffffff);
		_bg.graphics.beginBitmapFill(bitmapData);
		_bg.graphics.drawRect(0,0,widget.width, widget.height);
		_bg.graphics.endFill();
		this.addChild(_bg);
		// create base
		_base = new Sprite();
		_base.graphics.drawRect(0, 0, _bg.width - PADDING * 2, _bg.height - PADDING * 2);
		_base.x = PADDING;
		_base.y = PADDING;
		this.addChild(_base);
		_base.name = "_base";
		// create distribution panel (left side)
		_distPanelBG = new Sprite();
		var sequencerBg:FL_bgPanel = new FL_bgPanel();
		_distPanelDim = new Dimension(sequencerBg.width + PADDING * 2, sequencerBg.height + PADDING * 2);
		_distPanelBG.graphics.beginFill(0xb0a9c5, 1);
		_distPanelBG.graphics.lineStyle(STROKE_PANEL, 0x0, .35);
		_distPanelBG.graphics.drawRoundRect(0, 0, _distPanelDim.width, _distPanelDim.height, CORNER_RADIUS);
		bitmapData = new BitmapData(sequencerBg.width, sequencerBg.height);
		bitmapData.draw(sequencerBg);
		_distPanelBG.graphics.lineStyle();
		var m:Matrix = new Matrix();
		m.tx = _distPanelBG.width / 2 - sequencerBg.width / 2;
		m.ty = _distPanelBG.height / 2 - sequencerBg.height / 2;
		_distPanelBG.graphics.beginBitmapFill(bitmapData, m, false);
		_distPanelBG.graphics.drawRoundRect(m.tx, m.ty, sequencerBg.width, sequencerBg.height, CORNER_RADIUS);
		_base.addChild(_distPanelBG);
		// create sequence panel (right side)
		_sequencePanel = new SequencePanel(_orderedSequenceDisplayObjects);
		var sequencePanelWidth:Number = _base.width - _distPanelBG.width - SPACING;
		var colWidth:Number = SequencePanel.WIDTH_NUMBER_COLUMN;
		bgMatrix.createGradientBox(sequencePanelWidth, _distPanelDim.height, 0);
		_sequencePanel.graphics.clear();
		_sequencePanel.graphics.lineStyle(STROKE_PANEL, 0x0, .35); //border
		_sequencePanel.graphics.beginGradientFill(GradientType.LINEAR, [0xaebbd1, 0xdce1e9], [1,1], [colWidth, colWidth+1], bgMatrix);
		_sequencePanel.graphics.drawRoundRect(0, 0, sequencePanelWidth, _distPanelDim.height, CORNER_RADIUS); //right side
		_sequencePanel.addEventListener(SequencePanel.SUBMIT_PRESSED, onSubmitButtonClicked, false, 0, true);
		_sequencePanel.graphics.endFill();
		_sequencePanel.x = _distPanelBG.x + _distPanelBG.width + SPACING;
		_sequencePanel.y = 0;
		_base.addChild(_sequencePanel);
		_sequencePanel.name = "_sequencePanel";
		// create title box (top left)
		_titleBox = new Sprite();
		_titleBoxDims = new Dimension(_distPanelBG.width - PADDING * 4, 100);
		_titleBox.mouseEnabled = false; // ignores mouse events and sends them to underlying object
		_titleBox.graphics.beginFill(0x98e898)
		_titleBox.graphics.drawRect(0, 0, _titleBoxDims.width, _titleBoxDims.height);
		_titleBox.graphics.beginFill(0xe8fae8)
		_titleBox.graphics.drawRoundRectComplex(PADDING, 0, _titleBoxDims.width - PADDING * 2, _titleBoxDims.height - PADDING, 0, 0, 6, 6);
		_titleBox.y = _base.globalToLocal(localToGlobal(new Point(0,0))).y;
		_titleBox.x = _base.globalToLocal(_distPanelBG.localToGlobal(new Point(0,0))).x + PADDING * 2;
		_titleBox.graphics.endFill();
		_titleBox.graphics.lineStyle(2, 0x98979d, 1, true, "normal", CapsStyle.NONE);
		_titleBox.graphics.moveTo(0, 0);
		_titleBox.graphics.lineTo(0, _titleBoxDims.height);
		_titleBox.graphics.lineTo(_titleBoxDims.width, _titleBoxDims.height);
		_titleBox.graphics.lineTo(_titleBoxDims.width, 0);
		_titleBox.filters = [new DropShadowFilter(3, 45, 0x505050, .7)];
		var sequenceText:TextField = new TextField(); // Text for "Sequence" Header
		sequenceText.mouseEnabled = false;
		sequenceText.defaultTextFormat = new TextFormat("AmericanTypewriterFont", 18, 0x7b847b, true);
		sequenceText.embedFonts = true;
		sequenceText.selectable = false;
		sequenceText.text = "Sequence:";
		sequenceText.y = PADDING;
		sequenceText.x = PADDING * 2;
		sequenceText.autoSize = TextFieldAutoSize.LEFT;
		_titleBox.addChild(sequenceText);
		var titleText:TextField = new TextField(); // Holds title of sequence
		titleText.mouseEnabled = false;
		titleText.defaultTextFormat = new TextFormat("_ChunkFiveFont", 36, 0x4d7bc7);
		titleText.embedFonts = true;
		titleText.selectable = false;
		var titleWords:Array = inst.name.split(' '); //set alternating colors
		for(i = 0; i < titleWords.length; i++)
		{
			//set word to given color
			titleText.htmlText += "<font color='" + TITLE_COLORS[i % TITLE_COLORS.length] + "'>" + titleWords[i] + "</font>";
			if(i != titleWords.length)
			{
				titleText.htmlText += " ";
			}
		}
		titleText.x = PADDING * 2;
		titleText.autoSize = TextFieldAutoSize.LEFT;
		var writableWidth:Number = _titleBox.width - PADDING * 4;
		if(titleText.width > writableWidth) //scale according to length of text
		{
			titleText.scaleX = titleText.scaleY = (writableWidth / titleText.width)
		}
		var startY:Number = (sequenceText.y + sequenceText.height);
		var writableHeight:Number = _titleBox.height - startY - PADDING * 2;
		titleText.y = startY + writableHeight / 2 - titleText.height * titleText.scaleY / 2 ;
		_titleBox.addChild(titleText);
		//begin dotted line under title
		var dashLength:Number = 3; //begin drawing dotted line
		var numChanges:int = Math.round((_titleBox.width - titleText.x - PADDING * 2) / dashLength);
		var currX:Number = titleText.x;
		var currY:Number = titleText.y + titleText.height;
		_titleBox.graphics.lineStyle(1, 0x9daa9d);
		_titleBox.graphics.moveTo(currX, currY);
		for(i = 0; i < numChanges; i++)
		{
			if(i % 2 == 0)
			{
				currX += dashLength;
				_titleBox.graphics.lineTo(currX, currY);
			}
			else
			{
				currX += dashLength;
				_titleBox.graphics.moveTo(currX, currY);
			}
		}
		_base.addChild(_titleBox);
		// create score details box
		_scoreDetailsBox = new Sprite();
		_scoreDetailsBox.mouseEnabled = false;
		_scoreDetailsDims = new Dimension(_distPanelBG.width - PADDING * 4, 50);
		_scoreDetailsBox.graphics.beginFill(0x98e898)
		_scoreDetailsBox.graphics.drawRect(0, 0, _scoreDetailsDims.width, _scoreDetailsDims.height);
		_scoreDetailsBox.graphics.beginFill(0xe8fae8);
		_scoreDetailsBox.graphics.drawRoundRectComplex(PADDING, PADDING, _scoreDetailsDims.width - PADDING * 2, _scoreDetailsDims.height - PADDING, 6, 6, 0, 0);
		_scoreDetailsBox.y = _base.globalToLocal(localToGlobal(new Point(0,_bg.height))).y - _scoreDetailsDims.height;
		_scoreDetailsBox.x = _base.globalToLocal(_distPanelBG.localToGlobal(new Point(0,0))).x + PADDING * 2;
		_scoreDetailsBox.graphics.endFill();
		_scoreDetailsBox.graphics.lineStyle(2, 0x98979d, 1, true, "normal", CapsStyle.NONE);
		_scoreDetailsBox.graphics.moveTo(0,_scoreDetailsDims.height);
		_scoreDetailsBox.graphics.lineTo(0,0);
		_scoreDetailsBox.graphics.lineTo(_scoreDetailsDims.width, 0);
		_scoreDetailsBox.graphics.lineTo(_scoreDetailsDims.width, _scoreDetailsDims.height);
		_scoreDetailsMainField = createTextField(new TextFormat("_ChunkFiveFont", 16, 0x469e3f));
		_scoreDetailsMainField.htmlText = "Free tries: <font color='#e58d25'>0</font>";
		_scoreDetailsMainField.x = PADDING * 2;
		_scoreDetailsMainField.y = PADDING + (_scoreDetailsDims.height - PADDING) / 2 - _scoreDetailsMainField.height / 2;
		_scoreDetailsBox.addChild(_scoreDetailsMainField);
		_scoreDetailsCaption = createTextField(new TextFormat("_ChunkFiveFont", 14, "0x4d7bc7", null, null, null, null, null, "right"), "(Invalid data received for this widget)");
		_scoreDetailsCaption.autoSize = TextFieldAutoSize.RIGHT;
		_scoreDetailsCaption.y = PADDING + (_scoreDetailsDims.height - PADDING) / 2 - _scoreDetailsCaption.height / 2;
		_scoreDetailsCaption.x = _scoreDetailsDims.width - PADDING * 2 - _scoreDetailsCaption.width;
		_scoreDetailsBox.addChild(_scoreDetailsCaption);
		updateScoreDetailsPanel();
		_base.addChild(_scoreDetailsBox);
		// create the layer on which tiles will be placed
		_distPanel = new DistributionPanel(_unorderedSequenceDisplayObjects);
		_distPanel.background = _distPanelBG;
		_distPanel.graphics.drawRoundRect(0, 0, _distPanelDim.width, _distPanelDim.height, CORNER_RADIUS);
		_base.addChild(_distPanel);
		_distPanel.visible = true;
		_distPanel.name = "_distPanel";
		/* draw "try again" popup */
		_retryPopup = new RetryPopup(this);
		_retryPopup.visible = false;
		addChild(_retryPopup);
		/* draw "how to play" popup */
		_introPopup = new IntroPopup(_freeAttempts,_attemptPenalty);
		addChild(_introPopup);
		//show all sequence objects
		for(i = 0; i < _randomizedSequenceObjects.length; i)
		{
			showNextSequenceObject();
		}
	}

	private function createTextField(format:TextFormat, text:String = ""):TextField
	{
		var result:TextField = new TextField();
		result.mouseEnabled = false;
		result.embedFonts = true;
		result.selectable = false;
		result.defaultTextFormat = format;
		result.text = text;
		result.autoSize = TextFieldAutoSize.LEFT;
		return result;
	}

	private function updateScoreDetailsPanel():void
	{
		if(_attemptPenalty == 0)
		{
			_scoreDetailsMainField.htmlText = "Free tries: <font color='#e58d25'>" + "Unlimited" + "</font>";
			_scoreDetailsCaption.text = "(Practice Mode)";
		}
		else if(_freeAttempts - _attemptsUsed > 0)
		{
			_scoreDetailsMainField.htmlText = "Free tries: <font color='#e58d25'>" + (_freeAttempts - _attemptsUsed) + "</font>";
			_scoreDetailsCaption.text = "(No penalty for an incorrect sequence)";
		}
		else
		{
			var penalty:Number = (_attemptsUsed - _freeAttempts) * _attemptPenalty;
			var scoreText:String = "<font color='#469e3f'>Score:</font> <font color='#e58d25'>100";
			if(penalty != 0)
			{
				scoreText += " - " + Math.round(penalty) + " = " + Math.round((100 - penalty)); "</font>";
			}
			_scoreDetailsMainField.htmlText = scoreText;
			_scoreDetailsCaption.text = "(" + -Math.round(_attemptPenalty) + " for an incorrect sequence)";
		}
	}

	private function reparentObject(child:DisplayObject, newParent:DisplayObjectContainer):void
	{
		var newPosition:Point = newParent.globalToLocal(child.localToGlobal(new Point(0,0)));
		child.x = newPosition.x;
		child.y = newPosition.y;
		newParent.addChild(child);
		// check if submit button should be enabled or not
		_sequencePanel.submitEnabled = _unorderedSequenceDisplayObjects.length == 0;
	}

	private function shuffleArray(arr:Array):void
	{
		var len:int = arr.length;
		var temp:SequenceObject;
		var i:int = len;
		while(i--)
		{
			var rand:int = Math.floor(Math.random() * len);
			temp = SequenceObject(arr[i]);
			arr[i] = arr[rand];
			arr[rand] = temp;
		}
	}

	private function showNextSequenceObject():SequenceDisplayObject
	{
		if(_randomizedSequenceObjects.length != 0)
		{
			//create visual sequence object
			var nextObject:SequenceDisplayObject =
				new SequenceDisplayObject(_randomizedSequenceObjects.pop(), _base);
			//add drag/drop events to the visual object
			nextObject.addEventListener(SequenceDisplayObject.EVENT_DRAG, onObjectDrag, false, 0, true);
			nextObject.addEventListener(SequenceDisplayObject.EVENT_BEGIN_DRAG, onObjectBeginDrag, false, 0, true);
			nextObject.addEventListener(SequenceDisplayObject.EVENT_DROPPED, onObjectDropped, false, 0, true);
			//find number of items dispensed so far
			var count:int = EngineCore.qSetData.items[0].items.length - _randomizedSequenceObjects.length - 1;
			/* Find x and y position for this tile through multiple random attempts, trying to avoid collisions */
			// establish bounds for random placement
			var maxX:Number = _distPanel.width - SequenceDisplayObject.WIDTH;
			var minY:Number = _titleBox.height;
			var maxY:Number = _distPanel.height - SequenceDisplayObject.HEIGHT;
			// add to the screen and keep reference
			nextObject.visible = false;
			_distPanel.addChild(nextObject); // this adds it to _unorderedSequenceDisplayObjects
			// attempt to set coordinates X times or until a placement without collision is found
			for(var i:int = 0; i < RANDOM_PLACEMENT_TRIES; i++)
			{
				// generate a random position
				nextObject.x = Math.random() * maxX;
				nextObject.y = Math.random() * (maxY - minY) + minY;
				// check collisions with all existing tiles
				var collided:Boolean = false;
				for(var j:int = 0; j < _unorderedSequenceDisplayObjects.length - 1; j++)
				{
					var otherObject:SequenceDisplayObject = _unorderedSequenceDisplayObjects[j];
					if(otherObject.hitTestObject(nextObject) == true)
					{
						collided = true;
						break;
					}
				}
				// if we found no collision, we can keep this position. stop trying others
				if(!collided) { break; }
			}
			nextObject.visible = true;
			nextObject.rotated = true;
			return nextObject;
		}
		return null;
	}

	private function attemptSubmit():void
	{
		var numWrong:int = calculateNumWrong();
		var total:int = EngineCore.qSetData.items[0].items.length;
		if(numWrong == 0)         // user wins (all items are correct)
		{
			_retryPopup.show(0, total - numWrong, total, _attemptPenalty);
			_retryPopup.addEventListener(Event.CLOSE, onPopupCloseFinal, false, 0, true);
		}
		else if(_freeAttempts > _attemptsUsed)
		{
			_attemptsUsed++;
			_retryPopup.show(_freeAttempts - _attemptsUsed, total - numWrong, total, _attemptPenalty);
		}
		else
		{
			_attemptsUsed++;
			_runningScore -= _attemptPenalty;
			// scoring.adjustOverallScore(-_attemptPenalty, "Used %n attempt%s");
			scoring.submitInteractionForScoring("0", "attempt_penalty", "-" + _attemptPenalty);
			if(_runningScore > 0) // user lost points but can keep playing
			{
				_retryPopup.show(_freeAttempts - _attemptsUsed, total - numWrong, total, _attemptPenalty);
			}
			else                  // user used up all points.. go to score screen
			{
				_retryPopup.show(_freeAttempts - _attemptsUsed, total - numWrong, total, _attemptPenalty, true);
				_retryPopup.addEventListener(Event.CLOSE, onPopupCloseFinal, false, 0, true);
			}
		}
		// reflect penalty in score details panel
		updateScoreDetailsPanel();
	}

	private function onPopupCloseFinal(e:Event):void
	{
		_retryPopup.removeEventListener(Event.CLOSE, onPopupCloseFinal);
		submitForScoring();
	}

	private function submitForScoring():void
	{
		var len:int = _orderedSequenceDisplayObjects.length;
		var i:int;
		var object:SequenceObject;
		for(i = 0; i < len; i++)
		{
			object = SequenceDisplayObject(_orderedSequenceDisplayObjects[i]).sequenceObject;
			scoring.submitQuestionForScoring(String(object.id), (i + 1).toString());
		}
		end();
	}
	/**
	 * returns the number of sequencing objects that are in the wrong place.
	 * any object not in the exact position as in the EngineCore.qSetData is counted as incorrect
	 */
	private function calculateNumWrong():int
	{
		var i:int;
		var len:int = _orderedSequenceDisplayObjects.length;
		var numWrong:int = 0;
		var qq:* = EngineCore.qSetData;
		for(i = 0; i < len; i++)
		{
			var order:int = SequenceDisplayObject(_orderedSequenceDisplayObjects[i]).sequenceObject.order - 1;
			var text:String = SequenceDisplayObject(_orderedSequenceDisplayObjects[i]).sequenceObject.name;
			if(i != order)
			{
				numWrong++;
			}
		}
		numWrong += Math.abs(len - EngineCore.qSetData.items[0].items.length);
		return numWrong;
	}

	private function onObjectBeginDrag(e:Event):void
	{
		var obj:SequenceDisplayObject = SequenceDisplayObject(e.target);
		//if dragging an object off the ordered panel, move it to the unordered array
		if(obj.parent.parent.parent.parent == _sequencePanel)
		{
			obj.parentArray = _unorderedSequenceDisplayObjects;
			_sequencePanel.onObjectReparented(obj);
			_unorderedSequenceDisplayObjects.push(obj);
		}
		// let sequnce panel know we're dragging over it
		if(mouseIsOverSeqencePanel())
		{
			if(_sequencePanel.pendingItemOver == false)
			{
				_sequencePanel.onItemOver(e);
			}
			_sequencePanel.onObjectDrag(e);
		}
		// simulate picking up the object
		e.target.expandShadow();
		// set the appropriate parent
		reparentObject(obj, _base);
		// assume we dragged too (to set off highlighting)
		onObjectDrag(e);
	}

	private function onObjectDrag(e:Event):void
	{
		if(mouseIsOverSeqencePanel())
		{
			if(_sequencePanel.pendingItemOver == false) //onItemOver - seqPanel
			{
				_sequencePanel.onItemOver(e);
				e.target.rotated = false;
			}
			if(_distPanel.pendingItemOver == true) //onItemOut - distPanel
			{
				_distPanel.onItemOut(e);
			}
			_sequencePanel.onObjectDrag(e);
		}
		else
		{
			if(_distPanel.pendingItemOver == false) //onItemOver - distPanel
			{
				_distPanel.onItemOver(e);
				e.target.rotated = true;
			}
			if(_sequencePanel.pendingItemOver == true) //onItemOut - seqPanel
			{
				_sequencePanel.onItemOut(e);
			}
		}
	}

	private function onObjectDropped(e:Event):void
	{
		//**** add to appropriate sprite (the one mouse is hovering over) ****\\
		var obj:SequenceDisplayObject = SequenceDisplayObject(e.target);
		if(mouseIsOverSeqencePanel())
		{
			reparentObject(obj, _sequencePanel);
			// notify the distribution panel
			_distPanel.itemDroppedElsewhere();
			// set the item to completed status
			obj.completed = true;
			// in case user dragged too fast to where the onItemOver function isn't called
			obj.rotated = false;
		}
		// DROPPED over distribution panel
		else
		{
			// set the item back to not completed status
			obj.completed = false;
			reparentObject(obj, _distPanel);
		}
		e.target.contractShadow();
	}

	private function onSubmitButtonClicked(e:Event):void
	{
		attemptSubmit();
	}

	private function mouseIsOverSeqencePanel():Boolean
	{
		return _base.mouseX > _sequencePanel.x && _base.mouseX < _sequencePanel.x + _sequencePanel.width;
	}
}
}