package book3d
{
import flash.display.*;
import flash.geom.*;
import flash.events.*;
import flash.utils.*;

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

//import book3d.PageFlipEvent;
import book3d.BookPage3D;

public class FlipBook3D extends DisplayObject3D
{
	private var _pages:Array=null;
	private var _pageWidth:Number=0;
	private var _pageHeight:Number=0;
	private var _currentPage:int=0;
	public var flippedleft:int=0;
	public var flippedright:int=0;
	public var viewp:Viewport3D=null;
	public var centerContainerDO3D:DisplayObject3D=null;
	public var duration:Number=1;
	
	public function FlipBook3D()
	{
		super();
		centerContainerDO3D=DisplayObject3D.ZERO;
		addChild(centerContainerDO3D);
		_pages=[];
	}
	
	public function get numPages():int
	{
		return(_pages.length);
	}
	
	public function addPage(pf:DisplayObject,tf:String,pb:DisplayObject,tb:String,hardness:Number=.5,pageColor:int=0xffffff):void
	{
		var i=_pages.length;
		_pages.push(new BookPage3D(this,i,pf,tf,pb,tb,hardness,pageColor));
		//flippedright++;
		centerContainerDO3D.addChild(_pages[_pages.length-1]);
		_pages[_pages.length-1].duration=duration;
	}
	
	public function set pageHeight(h:Number):void
	{
		_pageHeight=h;
	}
	
	public function get pageHeight():Number
	{
		return(_pageHeight);
	}
	
	public function set pageWidth(w:Number):void
	{
		_pageWidth=w;
	}
	
	public function get pageWidth():Number
	{
		return(_pageWidth);
	}
}
}