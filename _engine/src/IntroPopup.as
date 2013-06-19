/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
public class IntroPopup extends SequencerPopup
{
	private static const WIDTH:Number = 680;
	private static const HEIGHT:Number = 410;
	private var _button:SequencerButton;
	private var _numTries:int;
	private var _penalty:int;
	[Embed(source="/assets/swf/HowToPlay.swf", mimeType="application/x-shockwave-flash")]
	private var IntroVideo:Class;
	public function IntroPopup(numTries:int, penaltyPerTry:int)
	{
		super(WIDTH, HEIGHT);
		_numTries = numTries;
		_penalty = penaltyPerTry;
	}
	override protected function draw():void
	{
		super.draw();
		/* draw inner panel */
		drawInnerPanel();
		/* draw start playing button */
		_button = new SequencerButton();
		_button.text = "Start Playing";
		_button.width = 175;
		centerButton();
		_popup.addChild(_button);
		_button.addEventListener(MouseEvent.CLICK, onClickButton, false, 0, true);
		/* draw intro video */
		var screeny:MovieClip = new IntroVideo();
		screeny.x = _width - PADDING_PANEL_H * 2 - screeny.width;
		screeny.y = _popup.height / 2 - screeny.height / 2;//_height - PADDING_PANEL_V * 2 - screeny.height;
//		var stroke:int = 10;
//		var curve:int = 0;
//		screeny.graphics.lineStyle(stroke, 0xbacad5);
//		screeny.graphics.drawRoundRect(0, 0, screeny.width, screeny.height, curve);
//		screeny.graphics.lineStyle(1, 0xbacad5);
//		stroke /= 2;
//		screeny.graphics.drawRoundRect(-stroke, -stroke, screeny.width+stroke*2, screeny.height+stroke*2, curve);
		_popup.addChild(screeny);
		// keep track of workable space (space left over after screeny)
		var widthAvail:Number = _innerPanel.width - screeny.width;
		/* draw "How to play:" title */
		var text0:TextField = initTextField(TEXTFORMAT_TITLE);
		text0.text = "How to play:";
		text0.x = widthAvail / 2 - text0.width / 2;
		text0.y = PADDING_TEXT_V;
		_innerPanel.addChild(text0);
		/* draw instructional text */
		var text1:TextField = initTextField(TEXTFORMAT_NORMAL);
		text1.autoSize = TextFieldAutoSize.NONE;
		text1.wordWrap = true;
		text1.multiline = true;
		var plusSize:Number = int(TEXTFORMAT_NORMAL.size);
		plusSize += 4; // could not do this where initialized for some reason
		var instructionText:String = "";
		if(_numTries == 0) instructionText += "\n";
		instructionText += "Order the tiles correctly in the sequence list.";
		if(_numTries > 0) instructionText += "\n\nYou have <font size='" + plusSize + "'>" + _numTries + "</font> free " + (_numTries > 1 ? "tries":"try") + " to get them in the right order.";
		instructionText +="\n\nYou will be deducted <font size='" + plusSize + "' color='#e99492'>" + _penalty + " points</font> for each incorrect sequence you submit" + (_numTries > 0 ? " after that":"") + ".";
		text1.htmlText = instructionText;
		text1.width = 230;
		text1.height = _innerPanel.height - text1.y;
		text1.x = widthAvail / 2 - text1.width / 2;
		text1.y = text0.y + text0.height + PADDING_TEXT_V;
		_innerPanel.addChild(text1);
	}
	private function centerButton():void
	{
		_button.x = _width / 2 - _button.width / 2;
		_button.y = _height - _button.height - 15;
	}
	private function onClickButton(e:MouseEvent):void
	{
		this.visible = false;
		delete(this);
	}
}
}