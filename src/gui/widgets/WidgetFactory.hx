package gui.widgets;

import haxe.xml.Access;
import hxd.Res.loader;

import gui.widgets.Frame;
import gui.widgets.Button;
import gui.widgets.Image;
import helper.System;

class WidgetFactory
{
    public static var mDefinitionMap:Map<String, Access> = new Map();
    public static var mTagLoaderMap:Map<String, (Access, UIState)->Frame> = new Map();

    public static function LoadFromData(data:Access, currentState:UIState, ?parentFrame:Frame)
    {
        var newFrame:Frame = new Frame();

        // process widget definition
        if (data.hasNode.definition)
        {
            for (defData in data.nodes.definition)
            {
                var defName = XMLHelper.XMLGetName(defData.x);
                mDefinitionMap.set(defName, defData);

                defData.x.parent.removeChild(defData.x);
            }
        }

        // process widget elements
        if (data.x.firstElement() != null)
        {
            for(node in data.x.elements())
            {
                var obj:Access = new Access(node);
                var type = node.nodeName;

                // 根据type创建widget，如果不是有效的type,则将node信息传到state中处理
                // (在state::initialize()之前)
                var frame = LoadFromTag(type, obj, currentState);
                if (frame == null)
                {
                    if (currentState != null) {
                        frame = currentState.RequestUIValue(type, obj);
                    }
                }

                if (frame != null)
                {
                    LoadPosition(obj, frame, parentFrame);
                    LoadCallbacks(obj, frame);
                    ProcessChildren(obj, frame, currentState);

                    var isVisible:Bool = XMLHelper.XMLGetBool(data.x, "visible", true);
                    frame.visible = isVisible;

                    var frameName = XMLHelper.XMLGetName(node);
                    if (frameName != "") {
                        frame.SetName(frameName);
                    }

                    newFrame.addFrameChild(frame);

                    frame.Initialize();
                }
            }
        }   

        return newFrame;
    }

    // TODO:support anchor
    static public function LoadPosition(data:Access, frame:Frame, parentFrame:Frame)
    {
        var isCenterX:Bool = XMLHelper.XMLGetBool(data.x, "center_x", false);
        var isCenterY:Bool = XMLHelper.XMLGetBool(data.x, "center_y", false);
        CenterFrame(frame, isCenterX, isCenterY, parentFrame);

        var x:Float = XMLHelper.XMLGetX(data);
        var y:Float = XMLHelper.XMLGetY(data);
        frame.x = frame.x + x;
        frame.y = frame.y + y;
    }

    static public function LoadCallbacks(data:Access, frame:Frame)
    {
        if (data.hasNode.callback)
        {
            for (callback in data.nodes.callback)
            {
                if (callback.hasNode.onCreated) {
                    ProcessCallbackData(callback.node.onCreated, UIEventType_OnCreated, frame);
                }

                if (callback.hasNode.onMouseOver) {
                    ProcessCallbackData(callback.node.onMouseOver, UIEventType_MouseOver, frame);
                }

                if (callback.hasNode.onMouseOut) {
                    ProcessCallbackData(callback.node.onMouseOut, UIEventType_MouseOut, frame);
                }

                if (callback.hasNode.onMouseClick) {
                    ProcessCallbackData(callback.node.onMouseClick, UIEventType_MouseClick, frame);
                }

                if (callback.hasNode.onDisposed) {
                    ProcessCallbackData(callback.node.onDisposed, UIEventType_OnDisposed, frame);
                }
            }
        }
    }

    static public function GetParams(data:Access):Array<Dynamic>
    {
        var params:Array<Dynamic> = new Array();
        if (data.hasNode.param) 
        {
            for (param in data.nodes.param) 
            {
                if(param.has.type && param.has.value)
                {
					var type:String = param.att.type.toLowerCase();
					var valueStr:String = param.att.value;
                    var value:Dynamic = valueStr;

                    switch (type)
                    {
                        case "int" : value = Std.parseInt(valueStr);
                        case "float": value = Std.parseFloat(valueStr);
                        case "string": value = new String(valueStr);
                        case "bool" : 
                        {
                            var boolStr = valueStr.toLowerCase();
                            if (boolStr == "true" || boolStr == "1") {
                                value = true;
                            }
                            else {
                                value = false;
                            }
                        }
                    }
                    params.push(value);
                }
            }
        }
         
        return params;
    }

    static public function ProcessCallbackData(callback:Access, eventType:UIEventType, frame:Frame)
    {
        var params:Array<Dynamic> = GetParams(callback);

        var eventParams:UIEventParams = 
        {
            event : eventType,
            name : XMLHelper.XMLGetStr(callback.x, "name"), 
            params: params.copy()
        };
        frame.RegisterEvent(eventType, eventParams);
    }

    static public function ProcessChildren(data:Access, frame:Frame, currentState:UIState)
    {
        if (data.hasNode.children)
        {
            for (child in data.nodes.children)
            {
                var newFrame = LoadFromData(child, currentState, frame);
                frame.addFrameChild(newFrame);
            }
        }
    }

    static public function CenterFrame(frame:Frame, centerX:Bool, centerY:Bool, parentFrame:Frame)
    {
        var frameBounds = frame.getBounds();
        var parent = cast(frame.parent, Frame);
        if (parent == null) {
            parent = parentFrame;
        }

        if (parent != null &&  parent.GetName() != "Root")
        {
            var parentBounds = parent.getBounds();
            if (centerX) {
                frame.x = (parentBounds.width - frameBounds.width) / 2;
            }
            if (centerY) {
                frame.y = (parentBounds.height - frameBounds.height) / 2;
            }
        }
        else 
        {
            var screenSize = System.GetScreenSize();
            if (centerX) {
                frame.x = (screenSize.x - frameBounds.width) / 2;
            }
            if (centerY) {
                frame.y = (screenSize.y - frameBounds.height) / 2;
            }

        }
    }

    public static function LoadFromTag(tag:String, info:Access, currentState:UIState)
    {
        var loader = mTagLoaderMap.get(tag);
        if (loader == null) {
            return null;
        }
        return loader(info, currentState);
    }

    public static function Initialize()
    {
        mTagLoaderMap.set("frame", LoadFrame);
        mTagLoaderMap.set("image", LoadImage);
        mTagLoaderMap.set("button", LoadButton);
    }

    public static function LoadFrame(info:Access, currentState:UIState):Frame
    {
        return LoadFromData(info, currentState);
    }

    public static function LoadImage(info:Access, currentState:UIState):Frame
    {
        var image:Image = new Image();
        var srcImage = LoadScaledImage(info);
        if (srcImage != null)
        {
            var width:Int = Std.int(XMLHelper.XMLGetWidth(info, -1));
            var height:Int = Std.int(XMLHelper.XMLGetHeight(info, -1));
            if (width > 0 && height > 0) 
            {
                var scaleX = (width / srcImage.tile.width);
                var scaleY = (height / srcImage.tile.height);

                srcImage.scaleX = scaleX;
                srcImage.scaleY = scaleY;
            }

            image.addChild(srcImage);
        }

        return image;
    }

    public static function LoadScaledImage(info:Access)
    {
        var src:String = XMLHelper.XMLGetStr(info.x, "src", "");
        if (src != "") 
        {
            var srcPath = src + ".png";
            var src:h2d.Bitmap = new h2d.Bitmap(
                hxd.Res.loader.load(srcPath).toImage().toTile());

            if (info.hasNode.resolve("scale"))
            {
                for(scaleNode in info.nodes.resolve("scale"))   
                {
                    var scaleWidth:Float = XMLHelper.XMLGetWidth(scaleNode, -1);
                    var scaleHeight:Float = XMLHelper.XMLGetHeight(scaleNode, -1);
                    if (scaleWidth > 0 && scaleHeight > 0)
                    {
                        src.scaleX = scaleWidth;
                        src.scaleY = scaleHeight;
                    }
                }
            }

            return src;
        }
        return null;
    }

    public static function LoadButton(info:Access, currentState:UIState):Frame
    {
        var button:Button = new Button();

        var id = XMLHelper.XMLGetName(info.x);
        var label:String = XMLHelper.XMLGetStr(info.x, "label");
        var width:Int = Std.int(XMLHelper.XMLGetWidth(info, -1));
        var height:Int = Std.int(XMLHelper.XMLGetHeight(info, -1));

        if (info.hasNode.graphic)
        {
            // every button contains 3 frames
           var imageArray = new Array<Image>();
           imageArray.resize(3);

            for (graphic in info.nodes.graphic)
            {
                var graphicName = XMLHelper.XMLGetName(graphic.x);
                var imageSrc = XMLHelper.XMLGetStr(graphic.x, "image");
                var sliceIntArray = XMLHelper.XMLGetIntArray(graphic, "slice9");
                var srcWidth:Int = Std.int(XMLHelper.XMLGetNumber(graphic.x, "src_width", 0));
                var srcHeight:Int = Std.int(XMLHelper.XMLGetNumber(graphic.x, "src_height", 0));

                switch (graphicName)
                {
                    case "normal":
                        var newImage = new Image();
                        newImage.LoadSlice9Image(imageSrc, srcWidth, srcHeight, sliceIntArray);
                        newImage.SetName(graphicName);
                        imageArray[0] = newImage;

                    case "over" :
                        var newImage = new Image();
                        newImage.LoadSlice9Image(imageSrc, srcWidth, srcHeight, sliceIntArray);
                        newImage.SetName(graphicName);
                        imageArray[1] = newImage;

                    case "down" :
                        var newImage = new Image();
                        newImage.LoadSlice9Image(imageSrc, srcWidth, srcHeight, sliceIntArray);
                        newImage.SetName(graphicName);
                        imageArray[2] = newImage;
                    case "all" :
                        var newImage = new Image();
                        newImage.LoadSlice9Image(imageSrc, srcWidth, srcHeight, sliceIntArray);
                        newImage.SetName(graphicName);
                        imageArray[0] = imageArray[1] = imageArray[2] = newImage;
                }
            }

            button.SetFrameImage(UIButtonFrameIndex_Normal, imageArray[0]);
            button.SetFrameImage(UIButtonFrameIndex_Over,   imageArray[1]);
            button.SetFrameImage(UIButtonFrameIndex_Down,   imageArray[2]);

            button.SetSize(width, height);
        }

        return button;
    }
}