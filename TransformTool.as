/**
 *  Version : 1.20
 *  Last Updated : 11/24/2009
 *  ActionScript Version : 3.0
 *  Author : Stephen Braitsch : @braitsch
 *  Documentation : http://quietless.com/code/as3/docs/tools/transform-tool.html
**/

package {
	
	import flash.display.Shape;	
	import flash.display.Stage;		
	import flash.display.Sprite;
	import flash.display.DisplayObject;	
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.geom.Matrix;
	
	import fl.core.*;
	import flash.ui.Mouse;
	import flash.events.Event;
	import flash.events.MouseEvent;

	import flash.display.LineScaleMode;
	import flash.display.JointStyle;
	
	public class TransformTool extends Sprite 
	{
		public static const SCALE			:String = 'scale';
		public static const ROTATE			:String = 'rotate';
		private static var _mode			:String;

		private static var _target			:DisplayObject; 
		private static var _targets			:Array = [];
		
		private static var _p1				:Point;
		private static var _p2				:Point;
		private static var _p3				:Point;
		private static var _p4				:Point;
		private static var _stroke			:Sprite;
		
	// four empty shapes positioned at the corners of the stroke //	
		private static var _stroke_tl		:Shape = new Shape();
		private static var _stroke_tr		:Shape = new Shape();
		private static var _stroke_bl		:Shape = new Shape();
		private static var _stroke_br		:Shape = new Shape();
		
	// target boundaries // 
		private static var _dragbounds		:Rectangle;
		private static var _mouseOffset		:Point = new Point(0,0) // used to get dist from _target center //
		private static var _mouseDownPos	:Point; // mouse pos captured on mouse down //	
		
	// min and max scale amounts //	
		private static var _minScale		:Number = .2;
		private static var _maxScale		:Number = 1;
	
	// target specific values //
		private static var _xOffset			:Number; // half the full width _target //
		private static var _yOffset			:Number; // half the full height _target //
		private static var _targCenter		:Point;  // x and y of _target in global space //
		private static var _radius			:Number; // max dist from center of _target to the handles //
		private static var _targRotation	:Number; // rotation of _target //
		
	// bounding box stroke color //	
		private static var _boundBoxColor	:Number = 0xFFFFFF;
	
	// bounding box hints and handles //
		private static var _hint			:Sprite = new Sprite(); // arrows icons //
		private static var _handlepressed	:Boolean; 
	
		private var tl :TransformHandle = new TransformHandle();   // top left //
		private var tr :TransformHandle = new TransformHandle();   // top right //
		private var bl :TransformHandle = new TransformHandle();   // btm left //
		private var br :TransformHandle = new TransformHandle();   // btm right //
	
//--------------------------------------------------------------//
	
		public function TransformTool ()
		{
			_stroke = new Sprite(); 
			_stroke.addChild(_stroke_tl);
			_stroke.addChild(_stroke_tr);
			_stroke.addChild(_stroke_bl);
			_stroke.addChild(_stroke_br);
			this.mouseEnabled = _stroke.mouseEnabled = false;
			addChild(_stroke);
			addChild(tl);
			addChild(tr);
			addChild(bl);
			addChild(br);
			addChild(_hint); 
			_hint.mouseEnabled = _hint.mouseChildren = false;
			addEventListener('HandleRollOver', onHandleRollOver);
			addEventListener('HandleRollOut', onHandleRollOut);
			addEventListener(Event.ADDED_TO_STAGE, registerMouseDown);
			addEventListener(Event.REMOVED_FROM_STAGE, removeMouseDown);
		}


 //- PUBLIC SETTERS ----------------------------------------------------------------------

		public function set targets($targets:Array):void
		{
			_targets = $targets;
		}	

		public function set activeTarget($targ:DisplayObject):void
		{
			_target = $targ;
			_targCenter = new Point($targ.x, $targ.y);
			_targRotation = _target.rotation;
			resetBoundingBox();
			onMouseRelease();
		}

		public function set mode($mode:String):void
		{
			_mode = $mode;
		}
		
		public function set boundaries($rect:Rectangle):void
		{
			_dragbounds = $rect;
		}
		
		public function set iconScale($icon:DisplayObject):void
		{
			$icon.name = TransformTool.SCALE;
			$icon.alpha = 0;
			_hint.addChild($icon); 
		}
				
		public function set iconRotate($icon:DisplayObject):void
		{
			$icon.name = TransformTool.ROTATE;
			$icon.alpha = 0;
			_hint.addChild($icon);
		}
	
		public function set maxScale($val:Number):void
		{
			_maxScale = $val;
		}

		public function set minScale($val:Number):void
		{
			_minScale = $val;
		}

 //- LISTEN FOR MOUSEDOWN EVENT WHEN ADDED TO STAGE ----------------------------------------------------------------------
	
		private function registerMouseDown(evt:Event):void
		{
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMousePress); 
			if (!_dragbounds) _dragbounds = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
		}
	
		private function removeMouseDown(evt:Event):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMousePress);  
		}	


 //- MOUSE PRESS AND RELEASE ----------------------------------------------------------------------

		private function onMousePress(evt:MouseEvent):void
		{
			if (evt.target is Stage) hideBoundingBox();	
			_mouseDownPos = new Point(mouseX, mouseY);			
			_mouseOffset = _targCenter.subtract(_mouseDownPos);
		// check if a registered target was selected //
			for (var i:int = 0; i < _targets.length; i++)
			{
				if (evt.target==_targets[i]) {
					activeTarget = _targets[i];
					stage.addEventListener(MouseEvent.MOUSE_MOVE, moveTarget);
				}
			}				
			if (evt.target is TransformHandle) {
				_handlepressed = true;
				stage.addEventListener(MouseEvent.MOUSE_MOVE, transformTarget);
			}					
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseRelease);
		}

		private function onMouseRelease(evt:MouseEvent = null):void
		{
			checkItemPosition(); // make sure it's not scaled off the stage //
			_handlepressed = false; 
			_hint.getChildByName(_mode).alpha = 0;			
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveTarget);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, transformTarget);	
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseRelease);
		}


 //- TOOL HANDLE ROLLOVER LISTENERS ----------------------------------------------------------------------
		
		private function onHandleRollOver(evt:Event):void
		{
			positionHandleHint(evt.target.x, evt.target.y);
			_hint.getChildByName(_mode).alpha = 1;
		}
		private function onHandleRollOut(evt:Event):void
		{
			if (!_handlepressed) _hint.getChildByName(_mode).alpha = 0;
		}
		
		private function positionHandleHint(xpos:uint = 0, ypos:uint = 0):void
		{
			var xoffset = (mouseX<_targCenter.x) ? -10 : 10;
			var yoffset = (mouseY<_targCenter.y) ? -10 : 10;
			_hint.x = (xpos || mouseX) + xoffset;
			_hint.y = (ypos || mouseY) + yoffset; 
			if (xoffset>0 && yoffset<0) {
				_hint.rotation = 0;
				}   else if (xoffset>0 && yoffset>0){
				_hint.rotation = 90;
				}   else if (xoffset<0 && yoffset>0){
				_hint.rotation = 180;
				}   else{
				_hint.rotation = -90;
			}
		}

 //- TARGET REPOSITIONING ----------------------------------------------------------------------

		private function moveTarget(evt:MouseEvent):void
		{
			var mouse = new Point(mouseX, mouseY);
			_target.x = mouse.x+_mouseOffset.x; 
			_target.y = mouse.y+_mouseOffset.y;
			checkItemPosition();
			evt.updateAfterEvent();
		}
		
		private function checkItemPosition():void
		{
		// constrain x pos to draggable area //	
			var tl = (_target.x-_target.width/2); // left
			var tr = (_target.x+_target.width/2); // right 
			if (tl < _dragbounds.left){
				_target.x = _dragbounds.left+_target.width/2;
			}
			if (tr > _dragbounds.right){
				_target.x = _dragbounds.right-_target.width/2;
			}
		// constrain y pos to draggable area //		
			var tt = (_target.y-_target.height/2); // top
			var tb = (_target.y+_target.height/2); // btm
			if (tt < _dragbounds.top){
				_target.y = _dragbounds.top+_target.height/2;
			}
			if (tb > _dragbounds.bottom){
				_target.y = _dragbounds.bottom-_target.height/2;
			}
		// update and refresh the screen //		
			_targCenter = new Point(_target.x, _target.y);
			_targRotation = _target.rotation;
			repositionBoundingBox();
		}


 //- TARGET TRANSFORMATION ----------------------------------------------------------------------
		
		private function transformTarget(evt:MouseEvent):void
		{
			if (_mode==TransformTool.SCALE) scaleTarget(evt);
			if (_mode==TransformTool.ROTATE) rotateTarget(evt);	
		}

		private function scaleTarget(evt:MouseEvent):void
		{	
			var dist = (Point.distance(new Point(mouseX, mouseY), _targCenter));
			_target.scaleX = _target.scaleY = dist/_radius; 
		// constain scale to min/max values //
			if (_target.scaleX > _maxScale){
				_target.scaleX  = _target.scaleY = _maxScale;
			}	else if (_target.scaleX < _minScale){
				_target.scaleX  = _target.scaleY = _minScale;
			}
		// refresh the screen //	
			positionHandleHint(); redrawBoundingBox(); 
		}

		private function rotateTarget(evt:MouseEvent):void
		{
		// get angle of handle from center //
			var dx1 = _mouseDownPos.x-_targCenter.x;
			var dy1 = _mouseDownPos.y-_targCenter.y;
			var ang1 = (Math.atan2(dy1, dx1)*180)/Math.PI;
		// get angle of mouse from center //
			var dx2 = mouseX-_targCenter.x;
			var dy2 = mouseY-_targCenter.y;
			var ang2 = (Math.atan2(dy2, dx2)*180)/Math.PI;
		// rotate the _target and stroke the difference of the two angles //
			var angle = ang2-ang1;
			_target.rotation = _stroke.rotation = _targRotation+angle; 
		// refresh the screen //
			positionHandleHint(); repositionBoundingBox(); 
		}


 //- BOUNDING BOX & HANDLE DRAW METHODS ----------------------------------------------------------------------

		private function hideBoundingBox():void
		{
			_stroke.graphics.clear();
			tl.visible = false; tr.visible = false;
			bl.visible = false; br.visible = false;
		}

		private function resetBoundingBox():void
		{
			_stroke.rotation = _target.rotation;
			_xOffset = Sprite(_target).getChildAt(0).width/2;
			_yOffset = Sprite(_target).getChildAt(0).height/2;
				_p1 = new Point(-_xOffset, -_yOffset);
				_p2 = new Point(_xOffset, -_yOffset);
				_p3 = new Point(_xOffset, _yOffset);
				_p4 = new Point(-_xOffset, _yOffset);
		// update the max dist from edge to center //	
			_radius = Point.distance(new Point(_target.x-_xOffset, _target.y-_yOffset), _targCenter);
		// redraw and position the bounding box and handles //
			redrawBoundingBox();
			tl.visible = true; tr.visible = true;
			bl.visible = true; br.visible = true;
		}
		
		private function redrawBoundingBox():void
		{
			_stroke.graphics.clear();
			_stroke.graphics.lineStyle(1, _boundBoxColor);
			_stroke.graphics.moveTo(_p1.x, _p1.y);
			_stroke.graphics.lineTo(_p2.x, _p2.y);
			_stroke.graphics.lineTo(_p3.x, _p3.y);
			_stroke.graphics.lineTo(_p4.x, _p4.y);
			_stroke.graphics.lineTo(_p1.x, _p1.y);
		// reposition the four invisible tracking corners //
			_stroke_tl.x = _p1.x; _stroke_tl.y = _p1.y;
			_stroke_tr.x = _p2.x; _stroke_tr.y = _p2.y;
			_stroke_br.x = _p3.x; _stroke_br.y = _p3.y;
			_stroke_bl.x = _p4.x; _stroke_bl.y = _p4.y;
			_stroke.scaleX = _stroke.scaleY = _target.scaleX; 
			repositionBoundingBox();
		}

		private function repositionBoundingBox():void
		{
			_stroke.x = _target.x;
			_stroke.y = _target.y;
		// reposition handles //
			var p1 = _stroke.localToGlobal(new Point(_stroke_tl.x, _stroke_tl.y));
			var p2 = _stroke.localToGlobal(new Point(_stroke_tr.x, _stroke_tr.y));
			var p3 = _stroke.localToGlobal(new Point(_stroke_bl.x, _stroke_bl.y));
			var p4 = _stroke.localToGlobal(new Point(_stroke_br.x, _stroke_br.y));
				tl.x = p1.x-parent.x; tl.y = p1.y-parent.y;
				tr.x = p2.x-parent.x; tr.y = p2.y-parent.y;
				bl.x = p3.x-parent.x; bl.y = p3.y-parent.y;
				br.x = p4.x-parent.x; br.y = p4.y-parent.y;
		}		

	}

}


//------------------CUSTOM TRANSFORM BOX HANDLE-----------------//
//--------------------------------------------------------------//


import flash.display.Shape;
import flash.display.Sprite;
import flash.display.LineScaleMode;	
import flash.display.JointStyle;
import flash.events.Event;	
import flash.events.MouseEvent;	

class TransformHandle extends Sprite
{

	private var handleSize		:uint = 8;
	private var handleFill		:Number = 0x000000;
	private var handleStroke	:Number = 0xFFFFFF;	
	
	public function TransformHandle(){
		var handle = new Shape();
			handle.graphics.lineStyle(2, handleStroke, 1, true, LineScaleMode.NONE, null, JointStyle.MITER);
			handle.graphics.beginFill(handleFill);
			handle.graphics.lineTo(handleSize, 0);
			handle.graphics.lineTo(handleSize, handleSize);
			handle.graphics.lineTo(0, handleSize);
			handle.graphics.lineTo(0, 0);
			handle.graphics.endFill();
			handle.x = -(handle.width/2)+1;
			handle.y = -(handle.height/2)+1;
		addChild(handle);
		addEventListener(MouseEvent.ROLL_OVER, onRollOver);
		addEventListener(MouseEvent.ROLL_OUT, onRollOut);
		this.buttonMode = true; this.visible = false;
	}
	
	private function onRollOver(evt:MouseEvent):void
	{
	    dispatchEvent(new Event('HandleRollOver', true));
	}
	
	private function onRollOut(evt:MouseEvent):void
	{
	    dispatchEvent(new Event('HandleRollOut', true));
	}
}