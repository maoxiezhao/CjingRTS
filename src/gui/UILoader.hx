package gui;

import haxe.xml.Access;
import hxd.Res.loader;
import helper.Log;

import gui.widgets.Frame;
import gui.widgets.WidgetFactory;

// TEMP
class UILoader
{
    private var mMainStage:MainStage;

    public function new(mainStage:MainStage){
        mMainStage = mainStage;
    }

    public function ParseUIXML(id:String, currentState:UIState) 
    {
        var data:Access = LoadXML(id);
        if (data != null) {
            return ProcessXMLData(data, currentState);
        }
        return null;
    }

    public function LoadXML(id:String, getAccess:Bool = true):Dynamic
    {
        Logger.Info("Loading UI XML:" + id);

        var isExists:Bool = hxd.Res.loader.exists(id);
        if (isExists == false) {
            Logger.Error("Failed to loading UI XML:" + id);
            return null;
        }

        var data = hxd.Res.loader.load(id);
        var xmlData = Xml.parse(data.toText());

        if (getAccess == true)
        {
            var access:Access = new Access(xmlData.firstElement());
            return access;
        }
        else 
        {
            return xmlData.firstElement();
        }
    }

    public function ProcessXMLData(data:Access, currentState:UIState)
    {
        return WidgetFactory.LoadFromData(data, currentState);
    }
}