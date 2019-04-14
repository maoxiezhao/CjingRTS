package game;

import game.entity.Hero;
import h2d.Layers;
import h2d.Mask;
import hxd.Key;

class Game
{
    public var mCurrentApp:App;
    public var mHero:Hero;
    public var mCurrentMap:GameMap;
    public var mRootLayer:h2d.Layers;

    public function new(currentApp:App)
    {
        mCurrentApp = currentApp;
     
        mRootLayer = new h2d.Layers(mCurrentApp.s2d);   
        mCurrentMap = new GameMap(this);
        mHero = new Hero();

        mCurrentMap.AddEntity(mHero);
    }

    public function Update(dt:Float)
    {
        mCurrentMap.Update(dt);

    #if debug
        if (Key.isReleased(Key.ESCAPE)) {
            mCurrentApp.Close();
        }
    #end
    }

    public function Dispose()
    {
        mCurrentMap.Dispose();
    }
}