
package {

	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.events.MouseEvent;
	import TransformTool;

	public class AppMain extends MovieClip
	{
		
		private var _transformTool;
		
		public function AppMain()
		{
			_transformTool = new TransformTool();
			_transformTool.mode = TransformTool.ROTATE;
			_transformTool.iconScale = new HandleHintScale();
			_transformTool.iconRotate = new HandleHintRotate();
		//	_transformTool.boundaries = new Rectangle(50, 50, 475, 260);
		addChild(_transformTool);

		// register targets //
			_transformTool.targets = [f1, f2, f3, f4];
			_transformTool.activeTarget = f3;
			
		// register radio buttons //	
		radio1.addEventListener(MouseEvent.CLICK, changeToolMode);
		radio2.addEventListener(MouseEvent.CLICK, changeToolMode);
		}
		
		private function changeToolMode(evt:MouseEvent):void
		{
			_transformTool.mode = evt.currentTarget.label.toLowerCase();
		}
	
	}

}