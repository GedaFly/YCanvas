package sk.yoz.ycanvas.demo.explorer.modes
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.IBitmapDrawable;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.events.Event;
    import flash.events.IEventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.geom.Matrix;
    import flash.net.URLRequest;
    import flash.system.ImageDecodingPolicy;
    import flash.system.LoaderContext;
    
    import sk.yoz.ycanvas.demo.explorer.events.PartitionEvent;
    import sk.yoz.ycanvas.starling.interfaces.IPartitionStarling;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.textures.Texture;
    
    public class Partition implements IPartitionStarling
    {
        private static var cachedTexture:Texture;
        
        protected var bitmapData:BitmapData;
        
        private var dispatcher:IEventDispatcher;
        private var error:Boolean;
        private var loader:Loader;
        
        private var _x:int;
        private var _y:int;
        private var _content:starling.display.DisplayObject;
        private var _layer:Layer;
        private var _requestedWidth:uint;
        private var _requestedHeight:uint;
        
        public function Partition(layer:Layer, x:int, y:int, 
            requestedWidth:uint, requestedHeight:uint, 
            dispatcher:IEventDispatcher)
        {
            _layer = layer;
            _x = x;
            _y = y;
            _requestedWidth = requestedWidth;
            _requestedHeight = requestedHeight;
            this.dispatcher = dispatcher;
            
            _content = new Image(getTexture(requestedWidth, requestedHeight));
            content.x = x;
            content.y = y;
        }
        
        public function get x():int
        {
            return _x;
        }
        
        public function get y():int
        {
            return _y;
        }
        
        public function get expectedWidth():uint
        {
            return _requestedWidth;
        }
        
        public function get expectedHeight():uint
        {
            return _requestedHeight;
        }
        
        public function get content():starling.display.DisplayObject
        {
            return _content;
        }
        
        public function get layer():Layer
        {
            return _layer;
        }
        
        public function get loading():Boolean
        {
            return loader != null;
        }
        
        public function get loaded():Boolean
        {
            return bitmapData || error;
        }
        
        public function get concatenatedMatrix():Matrix
        {
            return content.getTransformationMatrix(content.stage);
        }
        
        protected function getTexture(width:uint, height:uint):Texture
        {
            if(cachedTexture && cachedTexture.width == width
                && cachedTexture.height == height)
                return cachedTexture;
            cachedTexture = Texture.fromBitmapData(
                new BitmapData(width, height, true, 0xffffff));
            return cachedTexture;
        }
        
        protected function get url():String
        {
            return null;
        }
        
        protected function set texture(value:BitmapData):void
        {
            content && disposeTexture();
            Image(content).texture = Texture.fromBitmapData(value);
        }
        
        public function applyIBitmapDrawable(source:IBitmapDrawable, 
            matrix:Matrix):void
        {
        }
        
        public function load():void
        {
            stopLoading();
            error = false;
            
            var context:LoaderContext = new LoaderContext(true);
            context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
            
            loader = new Loader;
            loader.load(new URLRequest(url), context);
            
            var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
            loaderInfo.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
            loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError, false, 0, true);
        }
        
        public function stopLoading(cancelRequest:Boolean = true):void
        {
            if(!loading)
                return;
            
            if(cancelRequest)
            {
                try
                {
                    loader.close();
                }
                catch(error:Error){}
            }
            
            var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
            if(loaderInfo)
            {
                loaderInfo.removeEventListener(Event.COMPLETE, onComplete, false);
                loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError, false);
            }
            loader = null;
        }
        
        public function dispose():void
        {
            stopLoading(true);
            bitmapData && bitmapData.dispose();
            bitmapData = null;
            if(content)
            {
                disposeTexture();
                content.dispose();
            } 
        }
        
        protected function disposeTexture():void
        {
            Image(content).texture.base.dispose();
            Image(content).texture.dispose();
        }
        
        public function toString():String
        {
            return "Partition: [x:" + x + ", y:" + y + ", " +
                "level:" + layer.level + "]";
        }
        
        protected function updateTexture():void
        {
            if(bitmapData)
                texture = bitmapData;
        }
        
        protected function onComplete(event:Event):void
        {
            var loaderInfo:LoaderInfo = LoaderInfo(event.target);
            bitmapData = Bitmap(loaderInfo.content).bitmapData;
            updateTexture();
            stopLoading(false);
            
            var type:String = PartitionEvent.LOADED;
            dispatcher.dispatchEvent(new PartitionEvent(type, this));
        }
        
        private function onError(event:Event):void
        {
            error = true;
            updateTexture();
            stopLoading(false);
        }
    }
}