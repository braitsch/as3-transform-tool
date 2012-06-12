##[AS3 Transform Tool](http://www.quietless.com/kitchen/transform-tool-drag-scale-and-rotate-at-runtime/)

####A simple transform tool similar to what you might find in an application like Photoshop.

Example Usage
***
```
var tool = new TransformTool();
    tool.mode = TransformTool.ROTATE;
    tool.iconScale = new HandleHintScale();
    tool.iconRotate = new HandleHintRotate();
    tool.boundaries = new Rectangle(50, 50, 475, 260);
    stage.addChild(tool);

// register targets so they can be selected //
    tool.targets = [mySprite1, mySprite1];
// set the tool's active target on mouseClick //
    tool.activeTarget = mySprite1;
```
[More information available here.](http://www.quietless.com/kitchen/transform-tool-drag-scale-and-rotate-at-runtime/)