package book3d
{
import flash.display.*;
import flash.geom.*;
import flash.events.*;
import flash.filters.*;
import flash.utils.*;
import fl.controls.Slider;
import fl.events.SliderEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.text.TextFieldAutoSize;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.filters.*;
import org.papervision3d.*;
import org.papervision3d.view.*;

// TweenMax
import com.greensock.*;
import fl.motion.easing.Exponential;

import book3d.FlipBook3D;

public class FlipBookMain extends Sprite
{
	
	private var sw:int,sh:int;
	private var bvw:Number,bvh:Number;
	private var ch:Number;
	private var bv:BasicView=null;
	private var backgr:Shape=null;
	private var _book:FlipBook3D=null;
	private var pW:Number=500,pH:Number=500;
	private var showControls:Boolean=true;
	private var hardness:Number=.5;
	private var currentimg=-1;
	private var initlater:Boolean=false;
	private var pages:Array=[];
	private var contr:MovieClip=null;
	private var camrad:Number=0;
	private var hh=137.5,hhh=50,hhhh=36.4;
	private var titletext:TextField=null,txtFormat:TextFormat=null,shadowf:DropShadowFilter=null;
	private var title:String=null;
	private var pcolor:int=0xffffff,dur:Number=1;
	private var showBack:Boolean=false;
	
	// xml and loader vars
	private var xml:XML=null;
	private var list:XMLList=null;
	private var loader:URLLoader;
	private var myloaderf:Loader=null,myloaderb:Loader=null;
	private var xml_len:int=0;
	private var xmlload:Boolean=false;
	private var imgload1:Boolean=false,imgload2:Boolean=false;
	private var targetToObject:Array;
	
	public function FlipBookMain()
	{
		super();
		loading.visible=false;
		if (stage)
			init();
		else
		{
			initlater=true;
			addEventListener(Event.ADDED_TO_STAGE,init);
		}
	}
	
	
	private function init(e:Event=null):void
	{
		if (initlater)
		{
			removeEventListener(Event.ADDED_TO_STAGE,init);
			initlater=false;
		}
		
		// no scale to fit automatically in code
		this.stage.scaleMode = StageScaleMode.NO_SCALE;
		this.stage.align=StageAlign.TOP_LEFT;
		sw=this.stage.stageWidth;
		sh=this.stage.stageHeight;
		
		readXML();		
	}	
	
	private function dobackgr():void
	{
		// add background
		if (backgr==null)
		{
			backgr=new Shape();
			addChild(backgr);
		}
		var mat=new Matrix();
		mat.createGradientBox(sw,sh,Math.PI/2);
		backgr.graphics.clear();
		backgr.graphics.beginGradientFill("linear",[0xa50a0a, 0x070000],[1, 1], [0, 255],mat);
		backgr.graphics.drawRect(0,0,sw,sh);
		backgr.graphics.endFill();
	}
	
	private function readXML():void
	{
		loader = new URLLoader(new URLRequest(loaderInfo.parameters["xmlfile"]));
		loader.addEventListener(Event.COMPLETE, createSlideshow);
		xmlload=true;
	}
	
	private function onProgressHandler(e:ProgressEvent):void
	{
		var percent:Number;
		var f:Number=.5,b:Number=.5;
		if (myloaderf!=null)
		{
			f=.5*myloaderf.contentLoaderInfo.bytesLoaded/myloaderf.contentLoaderInfo.bytesTotal;
		}
		if (myloaderb!=null)
		{
			b=.5*myloaderb.contentLoaderInfo.bytesLoaded/myloaderb.contentLoaderInfo.bytesTotal;
		}
		percent =((f+b)+(currentimg))/xml_len;
		loading.bar.scaleX=percent;
		loading.percent.text=int(percent*100)+"%";
		loading.message.text="page "+int(currentimg+1)+" from "+xml_len;
	} 	
	
	private function createSlideshow(e:Event=null):void
	{
			var spr:Sprite;
			
			if (xmlload)
			{
				xml = new XML(e.target.data);
				if (xml.showBackground!=undefined)
				{
					showBack=String(xml.showBackground).toLowerCase()=="true";
				}
				
				if (showBack)
				{
					dobackgr();
				}
				loading.visible=true;
				loading.x=.5*sw;
				loading.y=.5*sh;
				loading.bar.scaleX=0;
				loading.percent.text="0%";
				loading.message.text="";
				if (showBack)
					swapChildren(loading,backgr);
				
				
				if (xml.pageWidth!=undefined)
				{
					pW=Number(String(xml.pageWidth));
				}
				if (xml.pageHeight!=undefined)
				{
					pH=Number(String(xml.pageHeight));
				}
				if (xml.pageColor!=undefined)
				{
					pcolor=int(String(xml.pageColor));
				}
				if (xml.pageFlipDuration!=undefined)
				{
					dur=Number(String(xml.pageFlipDuration));
				}
				if (xml.title!=undefined)
				{
					title=String(xml.title);
				}
				if (xml.showControls!=undefined)
				{
					showControls=String(xml.showControls).toLowerCase()=="true";
				}
				
				if (xml.page!=undefined)
				{
					list = xml.page;
					xml_len=list.length();
				}
				else list=null;
				
				xmlload=false;
				imgload1=false;
				imgload2=false;
			}
			
			if ((list!=null) && (xml_len>0))
			{	
				if (!imgload1 && !imgload2)
				{
					++currentimg;
					if (list[currentimg].@front!=undefined)
					{
						if (myloaderf!=null)
						{
						myloaderf.contentLoaderInfo.removeEventListener(Event.COMPLETE, createSlideshow);
						myloaderf.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgressHandler); 
						}
						myloaderf = new Loader();
						myloaderf.contentLoaderInfo.addEventListener(Event.COMPLETE, createSlideshow);
						myloaderf.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgressHandler); 
						myloaderf.load(new URLRequest(list[currentimg].@front));
						imgload1=true;
					}
					else
					{
						myloaderf=null;
						imgload1=false;
					}
					//trace(currentimg+" front");
					if (list[currentimg].@back!=undefined)
					{
						if (myloaderb!=null)
						{
						myloaderb.contentLoaderInfo.removeEventListener(Event.COMPLETE, createSlideshow);
						myloaderb.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgressHandler); 
						}
						myloaderb = new Loader();
						myloaderb.contentLoaderInfo.addEventListener(Event.COMPLETE, createSlideshow);
						myloaderb.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgressHandler); 
						myloaderb.load(new URLRequest(list[currentimg].@back));
						imgload2=true;
					}
					else
					{
						myloaderb=null;
						imgload2=false;
					}
					//trace(currentimg+" back");
					pages[currentimg]={front:myloaderf, back:myloaderb, frontType:(list[currentimg].@frontType!=undefined)?list[currentimg].@frontType:"bitmap", backType:(list[currentimg].@backType!=undefined)?list[currentimg].@backType:"bitmap", hardness:(list[currentimg].@pageHardness!=undefined)?Number(list[currentimg].@pageHardness):hardness};
				}
				else if (imgload1)
					imgload1=false;
				else
					imgload2=false;
			}
			else 
			{
				removeChild(loading); 
				return; // nothing to do
			}
			if ((currentimg+1>=xml_len) && (!imgload1 && !imgload2))
			{
				startSlideshow();
			}
			else if (!imgload1 && !imgload2) createSlideshow();
	}
	
	private function startSlideshow():void
	{
		removeChild(loading);
		ch=0;
		if (showControls)
		{
			contr=new controls();
			ch=contr.back.height;
			contr.back.width=sw;
			contr.fsonbut.visible=true;
			contr.fsoffbut.visible=false;
			contr.fsonbut.x=sw-contr.fsonbut.width;
			contr.fsonbut.y=contr.back.y;
			contr.fsoffbut.x=sw-contr.fsoffbut.width;
			contr.fsoffbut.y=contr.back.y;
			contr.fsonbut.addEventListener(MouseEvent.CLICK,toggleFullScreen);
			contr.fsoffbut.addEventListener(MouseEvent.CLICK,toggleFullScreen);
			contr.zoom.minimum=10;
			contr.zoom.maximum=300;
			contr.zoom.value=100;
			contr.zoom.liveDragging=true;
			contr.zoom.addEventListener(SliderEvent.CHANGE, setZoom, false, 0, true);
			contr.zoom.visible=false;
			contr.tilt.minimum=-50;
			contr.tilt.maximum=50;
			contr.tilt.value=0;
			contr.tilt.liveDragging=true;
			contr.tilt.addEventListener(SliderEvent.CHANGE, setTilt, false, 0, true);
			contr.tilt.visible=false;
			contr.pan.minimum=-50;
			contr.pan.maximum=50;
			contr.pan.value=0;
			contr.pan.liveDragging=true;
			contr.pan.addEventListener(SliderEvent.CHANGE, setPan, false, 0, true);
			contr.pan.visible=false;
			contr.move.addEventListener(MouseEvent.MOUSE_DOWN,doDrag);
			contr.move.addEventListener(MouseEvent.MOUSE_UP,endDrag);
			contr.move.buttonMode=true;
			contr.move.visible=false;
			contr.zoombut.addEventListener(MouseEvent.CLICK,toggleDO);
			contr.movebut.addEventListener(MouseEvent.CLICK,toggleDO);
			contr.tiltbut.addEventListener(MouseEvent.CLICK,toggleDO);
			contr.panbut.addEventListener(MouseEvent.CLICK,toggleDO);
			targetToObject=[];
			targetToObject["zoombut"]=contr.zoom;
			targetToObject["movebut"]=contr.move;
			targetToObject["tiltbut"]=contr.tilt;
			targetToObject["panbut"]=contr.pan;
		}
		
		if (title!=null)
		{
			titletext=new TextField();
			titletext.autoSize=TextFieldAutoSize.LEFT;
			titletext.multiline=true;
			txtFormat=new TextFormat();
			txtFormat.color=0xffffff;
			txtFormat.font="Arial";
			titletext.defaultTextFormat=txtFormat;
			titletext.htmlText=title;
			shadowf=new DropShadowFilter();
			titletext.filters=[shadowf];
			addChild(titletext);
		}
		
		bvw=.95*sw;
		bvh=.95*(sh-ch);
		bv = new BasicView(bvw, bvh, false, true);
		bv.viewport.buttonMode=true;
		bv.x=.5*(sw-bvw);
		bv.y=.5*(sh-ch-bvh);
		bv.camera.ortho = false;
		Papervision3D.useDEGREES=true;
		addChild(bv);
		
		_book=new FlipBook3D();
		_book.pageWidth=pW;
		_book.pageHeight=pH;
		_book.duration=dur;
		var mm=Math.max(2*_book.pageWidth/bvw,_book.pageHeight/bvh);
		_book.viewp=bv.viewport;
		bv.camera.focus = 100;
		bv.camera.zoom = 100;
		bv.camera.z = -bv.camera.focus*bv.camera.zoom*mm;
		camrad=bv.camera.z;
		bv.scene.addChild( _book);
		for (var i=0;i<pages.length;i++)
		{
			_book.addPage(pages[i].front,pages[i].frontType,pages[i].back,pages[i].backType,pages[i].hardness,pcolor);
		}
		bv.startRendering();
		bv.alpha=0;
		TweenMax.to(bv,.8,{useFrames:false,alpha:1,ease:Exponential.easeInOut});
		
		if (showControls)
		{
			addChild(contr);
			contr.x=0;
			//contr.y=0;
			contr.y=sh-hhh;
		}
		stage.addEventListener(Event.RESIZE,resizeStage);
		stage.addEventListener(Event.FULLSCREEN, resizeStage);
	}
	
	private function doDrag(e:Event):void
	{
		addEventListener(Event.ENTER_FRAME,moveBook);
	}
	
	private function endDrag(e:Event):void
	{
		removeEventListener(Event.ENTER_FRAME,moveBook);
	}
	
	private function moveBook(e:Event):void
	{
		_book.x=sw*(contr.move.mouseX-.5*contr.move.width)/(.5*contr.move.width);
		_book.y=-sh*(contr.move.mouseY-.5*contr.move.height)/(.5*contr.move.height);
	}
	
	private function tweenComplete(doo:DisplayObject):void
	{
		if (doo.alpha==0)
			doo.visible=false;
	}
	
	private function toggleDO(e:Event):void
	{
		var oo=targetToObject[e.target.name];
		if (oo.visible)
		{
			oo.alpha=1;
			TweenMax.to(oo,.8,{useFrames:false, ease:Exponential.easeInOut, alpha:0, onComplete:tweenComplete, onCompleteParams:[oo]});
		}
		else
		{
			oo.visible=true;
			oo.alpha=0;
			TweenMax.to(oo,.8,{useFrames:false, ease:Exponential.easeInOut, alpha:1, onComplete:tweenComplete, onCompleteParams:[oo]});
		}
	}
		
	private function resizeStage(e:Event=null):void
	{
		sw=this.stage.stageWidth;
		sh=this.stage.stageHeight;
		bvw=.95*sw;
		bvh=.95*(sh-ch);
		bv.viewport.viewportWidth=bvw;
		bv.viewport.viewportHeight=bvh;
		bv.x=.5*(sw-bvw);
		bv.y=.5*(sh-ch-bvh);
		var mm=Math.max(2*_book.pageWidth/bvw,_book.pageHeight/bvh);
		//bv.camera.focus = 100;
		//bv.camera.zoom = 100;
		bv.camera.z = -100*100*mm;
		camrad=bv.camera.z;
		
		if (showBack) dobackgr();
		
		if (showControls)
		{
			contr.x=0;
			contr.back.width=sw;
			contr.y=sh-hhh;
			contr.fsonbut.x=sw-contr.fsonbut.width;
			contr.fsoffbut.x=sw-contr.fsoffbut.width;
		}
	}
	
	private function toggleFullScreen(e:Event=null):void
	{
		if (stage.displayState == StageDisplayState.NORMAL) {
	        stage.displayState=StageDisplayState.FULL_SCREEN;
			contr.fsoffbut.visible=true;
			contr.fsonbut.visible=false;
	    } else {
	        stage.displayState=StageDisplayState.NORMAL;
			contr.fsonbut.visible=true;
			contr.fsoffbut.visible=false;
	    }
		resizeStage();		
	}
	
	private function setZoom(e:SliderEvent=null):void
	{
		bv.camera.zoom=contr.zoom.value;
	}
	
	private function setTilt(e:SliderEvent=null):void
	{
		/*bv.camera.z=camrad*Math.cos(contr.tilt.value*Math.PI/10);
		bv.camera.y=camrad*Math.sin(contr.tilt.value*Math.PI/10);*/
		_book.rotationX=contr.tilt.value;
	}

	private function setPan(e:SliderEvent=null):void
	{
		/*bv.camera.z=camrad*Math.cos(contr.pan.value*Math.PI/10);
		bv.camera.x=camrad*Math.sin(contr.pan.value*Math.PI/10);*/
		_book.rotationY=contr.pan.value;
	}
	
	private function setLR(e:SliderEvent=null):void
	{
		_book.x=contr.lr.value;
	}
}
}