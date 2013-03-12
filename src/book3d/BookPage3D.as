package book3d
{
import flash.display.*;
import flash.geom.*;
import flash.events.*;
import flash.utils.*;

import com.as3dmod.ModifierStack;
import com.as3dmod.modifiers.*;
import com.as3dmod.plugins.pv3d.LibraryPv3d;
import com.as3dmod.util.ModConstant;

import org.papervision3d.*;
import org.papervision3d.core.proto.*;
import org.papervision3d.core.math.*;
import org.papervision3d.core.geom.renderables.*;
import org.papervision3d.objects.*;
import org.papervision3d.objects.primitives.*;
import org.papervision3d.view.*;
import org.papervision3d.materials.*;
import org.papervision3d.materials.utils.*;
import org.papervision3d.objects.primitives.*;
import org.papervision3d.events.*;

// TweenMax
import com.greensock.*;
import fl.motion.easing.Exponential;

//import book3d.PageFlipEvent;
import book3d.FlipBook3D;

public class BookPage3D extends Cube
{
	private var _flipBook3D:FlipBook3D=null;
	private var _matFront:MovieMaterial=null;
	private var _matBack:MovieMaterial=null;
	private var _matEdge:ColorMaterial=null;
	private var _frontType:String="bitmap",_backType:String="bitmap";
	private var _frontmc:Sprite=null,_backmc:Sprite=null;
	private var _frontclicksprite:Sprite,_backclicksprite:Sprite;
	private var _index:int=0;
	private var _w:Number=0,_h:Number=0;
	private var _mats:MaterialsList=null;
	private var _pageHardness:Number=.5;
	private var _dur:Number=1;
	private var _angle=45*Math.PI/180;
	private var _force=5;
	private var _frames:Boolean=false;
	private var to:Object=null;
	private var _flipPt:Number=0;
	private var _mod:ModifierStack=null;
	private var _bend:Bend=null,bend2:Bend;
	private var _pivot:Pivot=null;
	private var elevation:Number=0;
	private var isFlippedLeft:Boolean=false,isFlippedRight:Boolean=true,flippingLeft:Boolean=false,flippingRight:Boolean=false;
	private var _mx:Number=0,drag:Boolean=false;
	private var zz:Number=1;
	private var _pageColor=0xffffff;
	
	public function set duration(d:Number)
	{
		if (d>0)
		_dur=d;
	}
	
	public function set frames(f:Boolean)
	{
		_frames=f;
	}
	
	public function BookPage3D(flipBook:FlipBook3D,index:int,frontmc:DisplayObject,fronttype:String,backmc:DisplayObject,backtype:String,hardness:Number=0.5,pagecolor:int=-1)
	{
		_flipBook3D=flipBook;
		_flipBook3D.flippedright++;
		_index=index;
		_frontType=fronttype.toLowerCase();
		_backType=backtype.toLowerCase();
		if (_frontType!="swf" && _frontType!="bitmap")
			_frontType="bitmap";
		if (_backType!="swf" && _backType!="bitmap")
			_backType="bitmap";
		
		// align flipBook
		if (_index==0)
			_flipBook3D.centerContainerDO3D.x=-_flipBook3D.pageWidth*.5;
		
		if (pagecolor>-1)
			_pageColor=pagecolor;
		_pageHardness=hardness;
		_pageHardness=Math.min(1,_pageHardness);
		_pageHardness=Math.max(0,_pageHardness);
		_frontmc=new Sprite();
		_backmc=new Sprite();
		/*_w=Math.min(frontmc.width,backmc.width);
		_h=Math.min(frontmc.height,backmc.height);
		_w=Math.min(_w,_flipBook3D.pageWidth);
		_h=Math.min(_h,_flipBook3D.pageHeight);*/
		
		_w=_flipBook3D.pageWidth;
		_h=_flipBook3D.pageHeight;
		
		_angle=.25*Math.PI*_w/_h;
		
		_frontmc.graphics.beginFill(_pageColor);
		_frontmc.graphics.drawRect(0,0,_w,_h);
		_frontmc.graphics.endFill();
		
		_backmc.graphics.beginFill(_pageColor);
		_backmc.graphics.drawRect(0,0,_w,_h);
		_backmc.graphics.endFill();
		
		if (frontmc!=null)
		{
		_frontmc.addChild(frontmc);
		if (frontmc.width<_w)
			frontmc.x=.5*(_w-frontmc.width);
		if (frontmc.height<_h)
			frontmc.y=.5*(_h-frontmc.height);
		}
		if (backmc!=null)
		{
		_backmc.addChild(backmc);
		// center pages
		if (backmc.width<_w)
			backmc.x=.5*(_w-backmc.width);
		if (backmc.height<_h)
			backmc.y=.5*(_h-backmc.height);
		}
		
		// add page flip interaction
		_frontclicksprite=new Sprite();
		_frontclicksprite.mouseEnabled=true;
		_frontclicksprite.useHandCursor=true;
		_frontclicksprite.buttonMode=true;
		_frontclicksprite.graphics.beginFill(0x444444,0);
		_frontclicksprite.graphics.drawRect(0,0,_w*.1,_h);
		_frontclicksprite.graphics.endFill();
		_frontmc.addChild(_frontclicksprite);
		_frontclicksprite.x=_flipBook3D.pageWidth-_frontclicksprite.width;
		_frontclicksprite.doubleClickEnabled=true;
		_frontclicksprite.addEventListener(MouseEvent.CLICK,flipLeft);
		//_frontclicksprite.addEventListener(MouseEvent.MOUSE_DOWN,startFlipDrag);
		//_frontclicksprite.addEventListener(MouseEvent.MOUSE_UP,endFlipDrag);
		_backclicksprite=new Sprite();
		_backclicksprite.mouseEnabled=true;
		_backclicksprite.useHandCursor=true;
		_backclicksprite.buttonMode=true;
		_backclicksprite.graphics.beginFill(0x777777,0);
		_backclicksprite.graphics.drawRect(0,0,_w*.1,_h);
		_backclicksprite.graphics.endFill();
		_backmc.addChild(_backclicksprite);
		_backclicksprite.doubleClickEnabled=true;
		_backclicksprite.addEventListener(MouseEvent.CLICK,flipRight);
		//_backclicksprite.addEventListener(MouseEvent.MOUSE_DOWN,startFlipDrag);
		//_backclicksprite.addEventListener(MouseEvent.MOUSE_UP,endFlipDrag);
		
		var clipRect=new Rectangle(0,0,_w,_h);
		var ft:Boolean=false;
		var bt:Boolean=false;
		if (_frontType=="swf")
			ft=true;
		if (_backType=="swf")
			bt=true;
		_matFront = new MovieMaterial( _frontmc ,false,ft,true,clipRect);
		_matBack = new MovieMaterial( _backmc ,false,bt,true,clipRect);
		_matEdge = new ColorMaterial( 0x333333 ,1);
		_matFront.fillColor=_pageColor;
		_matBack.fillColor=_pageColor;
		/*_matFront.oneSide=false;
		_matBack.oneSide=false;
		_matFront.doubleSided=true;
		_matBack.doubleSided=true;*/
		//_matFront.tiled=true;
		//_matBack.tiled=true;
		_matFront.smooth=true;
		_matBack.smooth=true;
		//_matFront.allowAutoResize=true;
		//_matBack.allowAutoResize=true;
		// page flip clicks
		_matFront.interactive=true;
		_matBack.interactive=true;
		//_matFront.rect=clipRect;
		//_matBack.rect=clipRect;
		
		// MATERIALS.. materials with loaders on two sides all other materials transparent color material
		_mats = new MaterialsList();
		_mats.addMaterial( _matEdge, "bottom");
		_mats.addMaterial( _matEdge , "top" );
		_mats.addMaterial( _matEdge , "left");
		_mats.addMaterial( _matEdge , "right");
		_mats.addMaterial( _matBack , "front" );
		_mats.addMaterial( _matFront , "back");

		// CUBE.. that appears as a plane with two sides
		super( _mats, _w, .5, _h, 10,10,1);
		this.useOwnContainer=true;
		this.x=_w*.5;
		//this.y=-.5*(_flipBook3D.pageHeight-this._h);
		this.z=zz*_index;
		_mod = new ModifierStack( new LibraryPv3d() , this );
        _pivot = new Pivot(this.x, 0, 0);
		_mod.addModifier(_pivot);
		_mod.collapse();
		_bend = new Bend();
		_bend.constraint = ModConstant.LEFT;
		_bend.angle=0.0;
		_bend.force=0.0;
		_bend.offset=0.0;
		if (_h>_w)
			_bend.switchAxes=true;
		_mod.addModifier( _bend );
		/*bend2=new Bend();
		bend2.constraint=ModConstant.RIGHT;
		bend2.angle=0;
		bend2.offset=0.2;
		bend2.force=0.5;
		//_mod.addModifier( bend2 );
		*/
	}
	/*
	private function startFlipDrag(e:MouseEvent=null):void
	{
		trace("DOWN");
		//return;
		drag=true;
		if (e!=null)
		{
			_flipPt=e.localY/_h;
		}
		_mx=_flipBook3D.viewp.containerSprite.mouseX;
		this.addEventListener(Event.ENTER_FRAME,flipDrag);
	}
	
	private function endFlipDrag(e:MouseEvent=null):void
	{
		trace("UP");
		//return;
		drag=false;
		this.removeEventListener(Event.ENTER_FRAME,flipDrag);
	}
	
	private function flipDrag(e:Event=null):void
	{
		var mm=_flipBook3D.viewp.containerSprite.mouseX;
		if (mm>_mx && this.rotationY>0) // drag right
		{
		 to={angle:this.rotationY+90,t:1-this.rotationY/180}
		 renderFlip();
		}
		else if (mm<=_mx && this.rotationY<180) // drag left
		{
		 to={angle:this.rotationY+5,t:this.rotationY/180}
		 renderFlip();
		}
		_mx=mm;
	}
	*/
	public function flipLeft(e:MouseEvent=null):void
	{
		if (!isFlippedLeft && !flippingLeft && !flippingRight && _index==_flipBook3D.flippedleft)
		{
			if (e!=null)
			{
				_flipPt=e.localY/_flipBook3D.pageHeight;
			}
			flippingLeft=true;
			_bend.angle=(2*_flipPt-1)*_angle;
			to={angle:this.rotationY,t:0, xx:0};
			TweenMax.to(to, _dur, {useFrames:_frames, /*ease:Exponential.easeInOut,*/ angle:180, xx:1, t:0, bezierThrough:[{t:1}], onUpdate:renderFlip, onComplete:flipFinished});
			_flipBook3D.flippedleft++;
			_flipBook3D.flippedright--;
			this.z=-zz*_flipBook3D.flippedleft;
		}
	}
	
	public function flipRight(e:MouseEvent=null):void
	{
		if (!isFlippedRight && !flippingRight && !flippingLeft && _index==_flipBook3D.numPages-_flipBook3D.flippedright-1)
		{
			if (e!=null)
			{
				_flipPt=e.localY/_flipBook3D.pageHeight;
			}
			flippingRight=true;
			_bend.angle=(2*_flipPt-1)*_angle;
			to={angle:this.rotationY,t:0,xx:0};
			TweenMax.to(to, _dur, {useFrames:_frames, /*ease:Exponential.easeInOut,*/ angle:0, xx:1, t:0, bezierThrough:[{t:1}], onUpdate:renderFlip, onComplete:flipFinished});
			_flipBook3D.flippedleft--;
			_flipBook3D.flippedright++;
		}
	}

	private	function renderFlip():void
	{
		// align flipBook to center
		if (flippingLeft && _index==0 && _flipBook3D.numPages>1)
			_flipBook3D.centerContainerDO3D.x=(1-to.xx)*_flipBook3D.centerContainerDO3D.x;
		else if (flippingLeft && _index==_flipBook3D.numPages-1)
			_flipBook3D.centerContainerDO3D.x=(1-to.xx)*_flipBook3D.centerContainerDO3D.x+to.xx*_flipBook3D.pageWidth*.5;
		else if (flippingRight && _index==0)
			_flipBook3D.centerContainerDO3D.x=(1-to.xx)*_flipBook3D.centerContainerDO3D.x-to.xx*_flipBook3D.pageWidth*.5;
		else if (flippingRight && _index==_flipBook3D.numPages-1)
			_flipBook3D.centerContainerDO3D.x=(1-to.xx)*_flipBook3D.centerContainerDO3D.x;
			
		this.rotationY = to.angle;
		_bend.force=  -((to.angle-90)/90)*to.t*_force*(1-_pageHardness);
		_bend.offset = (1-to.t)*0.6+to.t*0.5;
		_mod.apply();
	}
	
	
	private function flipFinished() : void
	{
		if (flippingLeft)
		{
			flippingLeft=false;
			isFlippedLeft=true;
			flippingRight=false;
			isFlippedRight=false;
		}
		else if (flippingRight)
		{
			flippingLeft=false;
			isFlippedRight=true;
			flippingRight=false;
			isFlippedLeft=false;
			this.z=zz*_index;
		}
		_bend.force=0.0;
		_bend.angle=0.0;
		_bend.offset=0.0;
		_mod.apply();
		//dispatchEvent(new PageFlipEvent());
	}
	
}
}