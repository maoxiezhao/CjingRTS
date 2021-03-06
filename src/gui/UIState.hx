package gui;

import haxe.macro.Expr.Access;
import gui.widgets.Frame;
import gui.MainStage;

class UIState
{
    private var mMainStage:MainStage = null;
    private var mRoot:Frame = null;
    private var mName:String;

    public function new(mainStage:MainStage)
    {
        mMainStage = mainStage;
    }

    public function Initialize(){}
    public function Dispose()
    {
        mRoot.Dispose();
        mRoot.remove();
    }

    public function Update(dt:Float){}
    public function SetVisible(isVisible:Bool) {}
    public function ProcessCallback(event:UIEventType, sender:Frame, name:String,  params:Array<Dynamic>) {}
    public function RequestUIValue(type:String, data:haxe.xml.Access):Frame {
        return null;
    }

    public function GetName() {return mName; }
    public function GetRoot() {return mRoot;}

    public function SetRoot(frame:Frame)
    {
        mRoot = frame;
        frame.SetCurrentStage(this);
    }
}