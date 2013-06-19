/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
import flash.display.Sprite;
import flash.events.Event;
import flash.filters.BitmapFilterQuality;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
public class SequencerPopup extends Sprite
{
	protected static const CURVATURE:Number = 10;
	protected static const PADDING_PANEL_H:Number = 15;
	protected static const PADDING_PANEL_V:Number = 60;
	protected static const PADDING_TEXT_V:Number = 10;
	protected static const TEXTFORMAT_TITLE:TextFormat = new TextFormat("__Helvetica", 18, 0xffffff, true);
	protected static const TEXTFORMAT_NORMAL:TextFormat = new TextFormat("__Helvetica", 14, 0xffffff, true);
	protected var _width:Number = 325;
	protected var _height:Number = 300;
	protected var _popup:Sprite;
	protected var _innerPanel:Sprite;
	public function SequencerPopup(width:Number, height:Number)
	{
		/* set dimensions */
		_width = width;
		_height = height;
		//prepare for add to stage
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
	}
	protected function onAddedToStage(e:Event):void
	{
		draw();
	}
	protected function draw():void
	{
		/* draw modal */
		graphics.beginFill(0x0, .6);
		graphics.drawRect(0, 0, parent.width, parent.height);
		/* draw container rect */
		_popup = new Sprite();
		_popup.graphics.beginFill(0x93acbe, 1);
		_popup.graphics.drawRoundRect(0, 0, _width, _height, CURVATURE);
		_popup.x = parent.width / 2 - _width / 2;
		_popup.y = parent.height / 2 - _height / 2;
		_popup.filters = [new DropShadowFilter(8, 90, 0, .3)];
		addChild(_popup);
		/* draw title */
		var title:TextField = new TextField();
		title.defaultTextFormat = new TextFormat("_ChunkFiveFont", 48, 0xffffff);
		title.embedFonts = true;
		title.text = "Sequencer!";
		title.selectable = false;
		title.autoSize = TextFieldAutoSize.LEFT;
		title.filters = [new GlowFilter(0x93acbe, 1, 3, 3, 1000, BitmapFilterQuality.HIGH)];
		/* draw subtitle */
		var subtitle:TextField = new TextField();
		subtitle.defaultTextFormat = new TextFormat("AmericanTypewriterFont", 18, 0x3a5568, true);
		subtitle.embedFonts = true;
		subtitle.text = "Put 'em in order!";
		subtitle.selectable = false;
		subtitle.autoSize = TextFieldAutoSize.LEFT;
		subtitle.x = title.x + title.width - subtitle.width - 15;
		subtitle.y = title.y + title.height - 15;
		/* draw container for title */
		var titleContainer:Sprite = new Sprite();
		titleContainer.rotation = -4.5;
		titleContainer.x = _popup.x - 20;
		titleContainer.y = _popup.y - 8;
		titleContainer.addChild(title);
		titleContainer.addChild(subtitle);
		addChild(titleContainer);
	}
	protected function initTextField(format:TextFormat):TextField
	{
		var tf:TextField = new TextField();
		tf.defaultTextFormat = format;
		tf.embedFonts = true;
		tf.selectable = false;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}
	/**
	 * Draws the bordered inner panel seen inside of popup window
	 *
	 * @param bounds
	 * 			Rectangle determines where inner panel is drawn
	 */
	protected function drawInnerPanel(bounds:Rectangle = null):void
	{
		if(bounds == null)
		{
			bounds = new Rectangle(PADDING_PANEL_H, PADDING_PANEL_V, _width - PADDING_PANEL_H * 2, _height - PADDING_PANEL_V * 2)
		}
		_innerPanel = new Sprite();
		_innerPanel.graphics.beginFill(0x54626d);
		_innerPanel.graphics.lineStyle(1, 0xbacad5);
		_innerPanel.graphics.drawRoundRect(0, 0, bounds.width, bounds.height, 8);
		_innerPanel.graphics.endFill();
		_innerPanel.x = bounds.x;
		_innerPanel.y = bounds.y;
		_popup.addChild(_innerPanel);
	}
}
}