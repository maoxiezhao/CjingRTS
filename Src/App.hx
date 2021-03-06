package;

import h3d.Engine;
import hxd.Timer;
import hxd.Window;
import h3d.impl.MacroHelper;
import hxd.App;
import game.Game;
import game.Assets;
import hxd.System;
import helper.Log;
import helper.System;
import gui.MainStage;
import logic.LogicScene;
import logic.MainScene;

typedef AppOptions = {
    ?name:String,
    ?width:Int,
    ?height:Int,
    ?frameRate:Int
}

class App extends hxd.App 
{
    public static var mAppOptions(get, null):AppOptions;
    public static var mSceneManager:LogicSceneManager;
    public static var mMainStage:MainStage;
    public var isClosed:Bool = false;

    // TEMP
    private var mFPSText:h2d.Text;

    public function new(?options:AppOptions)
    {
        super();

        if (options != null)
        {
            mAppOptions.name = options.name;
            mAppOptions.width = options.width;
            mAppOptions.height = options.height;
        }
        else 
        {
            options = get_mAppOptions();
        }

        helper.System.mScreenSize = new h2d.col.Point(options.width, options.height);

        hxd.Timer.wantedFPS = mAppOptions.frameRate;
        hxd.Res.initEmbed({compressSounds:true});

        helper.Data.load(hxd.Res.data.entry.getBytes().toString());

        Logger.Info("The App Staring.");
    }

    override function init()
    {
        engine.backgroundColor = 0xCC<<24|0x0;
        #if (hl)
        engine.fullScreen = false;
        #end

        mMainStage = new MainStage(this.s2d);
        mSceneManager = new LogicSceneManager(this);
        mSceneManager.RequsetScene(new MainScene(mSceneManager));

        onResize();

        // DEBUG
        var font : h2d.Font = hxd.res.DefaultFont.get();
        mFPSText = new h2d.Text(font);
        
        s2d.addChildAt(mFPSText, 1);
    }

    override function update(dt:Float)
    {
        if (isClosed == true){
            dispose();
            return;
        }

        super.update(dt);

        mMainStage.Update(dt);
        mSceneManager.Update(dt);

        // DEBUG
        mFPSText.text =  "DRAW_CALLS:" + Std.string(engine.drawCalls) + "   FPS:" + Std.string(Math.ceil(Timer.fps()));
    }

    override function onResize()
    {
        super.onResize();
    }

    override function dispose()
    {
        super.dispose();
    
        mSceneManager.Dispose();
        mMainStage.Dispose();

        #if hl
        hxd.System.exit();
        #end
    }

    static function get_mAppOptions() return 
    {
        name : "Test",
        width : 0,
        height : 0,
        frameRate : 60
    }

    public function Close(){
        isClosed = true;
    }
}