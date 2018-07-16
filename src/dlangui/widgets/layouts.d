// Written in the D programming language.

/**
This module contains common layouts implementations.

Layouts are similar to the same in Android.

LinearLayout - either VerticalLayout or HorizontalLayout.
VerticalLayout - just LinearLayout with orientation=Orientation.Vertical
HorizontalLayout - just LinearLayout with orientation=Orientation.Horizontal
FrameLayout - children occupy the same place, usually one one is visible at a time
TableLayout - children aligned into rows and columns
ResizerWidget - widget to resize sibling widgets

Synopsis:

----
import dlangui.widgets.layouts;

----

Copyright: Vadim Lopatin, 2014
License:   Boost License 1.0
Authors:   Vadim Lopatin, coolreader.org@gmail.com
*/
module dlangui.widgets.layouts;

public import dlangui.widgets.widget;
import std.conv;

/// helper for layouts
struct LayoutItem {
    Widget _widget;
    Orientation _orientation;
    int _measuredWidth; 
    int _measuredMinWidth;
    int _measuredHeight; 
    int _measuredMinHeight;
    
    int _layoutWidth;
    int _layoutHeight;

    int _minSize; //  min size for primary dimension
    int _maxSize; //  max size for primary dimension
    int _weight; // weight
    bool _fillParent;
    @property int layoutWidth() { return _layoutWidth; }
    @property int layoutHeight() { return _layoutHeight; }
    @property int weight() { return _weight; }
    @property ubyte alignment() {return _widget.alignment; }
    // just to help GC
    void clear() {
        _widget = null;
    }
    /// sets item for widget
    void set(Widget widget, Orientation orientation) {
        _widget = widget;
        _orientation = orientation;
    }

    void measureWidth(int parentWidth) {
        _widget.measureWidth(parentWidth);
        _measuredWidth = _widget.measuredWidth;
    }

    void measureHeight(int parentHeight) {
        _widget.measureHeight(parentHeight);
        _measuredHeight = _widget.measuredHeight;
    }

    void measureMinWidth() {
        _widget.measureMinWidth();
        _weight = _widget.layoutWeight;
        _measuredMinWidth = _widget.measuredMinWidth;
        _layoutWidth = _widget.layoutWidth;
        _layoutHeight = _widget.layoutHeight;
    }

    void measureMinHeight(int width) {
        _widget.measureMinHeight(width);
        _measuredMinHeight = _widget.measuredMinHeight;
    }
    
    void layout(ref Rect rc) {
        _widget.layout(rc);
    }
}

/// helper class for layouts
class LayoutItems {
    Orientation _orientation;
    ubyte _alignment;
    LayoutItem[] _list;
    int _count;
    int itemsMinWidthSum;
    int itemsMinHeightSum;
    int layoutWeightSum;
    int _layoutWidth;
    int _layoutHeight;
    int _totalWidth;
    int _totalHeight;

    void setLayoutParams(Orientation orientation, int layoutWidth, int layoutHeight, ubyte alignment) {
        _orientation = orientation;
        _layoutWidth = layoutWidth;
        _layoutHeight = layoutHeight;
        _alignment = alignment;
    }

    int measureMinWidth() {
        layoutWeightSum = 0;
        int _totalSize = 0;
        itemsMinWidthSum = 0;

        if (_orientation == Orientation.Horizontal) {
            // measure
            for (int i = 0; i < _count; i++) {
                LayoutItem * item = &_list[i];

                item.measureMinWidth();
                if (item.layoutWidth == FILL_PARENT) {
                    layoutWeightSum += item.weight;
                }

                 _totalSize += item._measuredMinWidth;
            }
        }
        else {
            // vertical
            for (int i = 0; i < _count; i++) {
                LayoutItem * item = &_list[i];

                item.measureMinWidth();
                if (item.layoutHeight == FILL_PARENT) {
                    layoutWeightSum += item.weight;
                }

                if (_totalSize < item._measuredMinWidth)
                    _totalSize = item._measuredMinWidth;
            }
            
        }
        itemsMinWidthSum = _totalSize;
        return _totalSize;
    }

    /// fill widget layout list with Visible or Invisible items, measure them
    int measureMinHeight(int width) {
        int _totalSize = 0;
        itemsMinHeightSum = 0;
        
        if (_orientation == Orientation.Horizontal) {
            // measure
            for (int i = 0; i < _count; i++) {
                LayoutItem * item = &_list[i];

                item.measureMinHeight(item._measuredWidth);
                if (_totalSize < item._measuredMinHeight)
                    _totalSize = item._measuredMinHeight;
            }
        }
        else {

            for (int i = 0; i < _count; i++) {
                LayoutItem * item = &_list[i];

                item.measureMinHeight(item._measuredWidth);
                _totalSize += item._measuredMinHeight;
            }
        }
        itemsMinHeightSum = _totalSize;
        return _totalSize;
    }

    int measureWidth(int parentWidth) {
        _totalWidth = 0;

        if (_orientation == Orientation.Horizontal) {
            int extraSpace = 0;
            extraSpace = parentWidth - itemsMinWidthSum;
            if (extraSpace < 1 || layoutWeightSum == 0) {
                for (int i = 0; i < _count; i++) {
                    LayoutItem * item = &_list[i];

                    item.measureWidth(item._measuredMinWidth);
                    _totalWidth += item._measuredWidth;
                }
            }
            else {
                int extraSpaceRemained = extraSpace;
                int extraSpaceStep = extraSpace / layoutWeightSum;

                // maybe we need add step sum to not exceed extraSpace due to rounds
                for (int i = 0; i < _count; i++) {
                    LayoutItem * item = &_list[i];

                    if (item.layoutWidth == FILL_PARENT)
                        item.measureWidth(item._measuredMinWidth + extraSpaceStep * item.weight);
                    else 
                        item.measureWidth(item._measuredMinWidth);

                    _totalWidth += item._measuredWidth;
                }
            }
            
        }
        else {
            // vertical
            for (int i = 0; i < _count; i++) {
                LayoutItem * item = &_list[i];

                int sizeToMeasure = item._measuredMinWidth;
                
                if (item.layoutWidth == FILL_PARENT)
                    item.measureWidth(parentWidth);
                else
                    item.measureWidth(sizeToMeasure);

                if (_totalWidth < item._measuredWidth)
                _totalWidth = item._measuredWidth;
            }

        }
        return _totalWidth;
    }


    int measureHeight(int parentHeight) {
        _totalHeight = 0;

        if (_orientation == Orientation.Horizontal) {
            for (int i = 0; i < _count; i++) {
                LayoutItem * item = &_list[i];

                if (item.layoutHeight == FILL_PARENT)
                    item.measureHeight(parentHeight);
                else
                    item.measureHeight(item._measuredMinHeight);

                if (_totalHeight < item._measuredHeight)
                _totalHeight = item._measuredHeight;
            }
        }
        else {
            // vertical
            int extraSpace = parentHeight - itemsMinHeightSum;
            if (extraSpace < 1 || layoutWeightSum == 0) {
                for (int i = 0; i < _count; i++) {
                    LayoutItem * item = &_list[i];

                    item.measureHeight(item._measuredMinHeight);
                    _totalHeight += item._measuredHeight;
                }
            }
            else {
                int extraSpaceRemained = extraSpace;
                int extraSpaceStep = extraSpace / layoutWeightSum;
            
                // maybe we need add step sum to not exceed extraSpace due to rounds
                for (int i = 0; i < _count; i++) {
                    LayoutItem * item = &_list[i];

                    if (item.layoutHeight == FILL_PARENT)
                        item.measureHeight(item._measuredMinHeight + extraSpaceStep * item.weight);
                    else
                        item.measureHeight(item._measuredMinHeight);

                    _totalHeight += item._measuredHeight;
                }
            }

        }
        return _totalHeight;

    }

    /// fill widget layout list with Visible or Invisible items, measure them
    void setWidgets(ref WidgetList widgets) {
        // remove old items, if any
        clear();
        // reserve space
        if (_list.length < widgets.count)
            _list.length = widgets.count;
        // copy
        for (int i = 0; i < widgets.count; i++) {
            Widget item = widgets.get(i);
            if (item.visibility == Visibility.Gone)
                continue;
            _list[_count++].set(item, _orientation);
        }
    }

    void layout(Rect rc) {
        int mainSizeDelta = 0; // used in alignment

        // main size alignment
        if (_orientation == Orientation.Vertical) {
            if (_totalHeight < rc.height) {
                if ((_alignment & Align.VCenter) == Align.VCenter) {
                    mainSizeDelta = (rc.height - _totalHeight) / 2;
                }
                else if ((_alignment & Align.Bottom) == Align.Bottom) {
                    mainSizeDelta = rc.height - _totalHeight;
                }
            }
        } else {
            if (_totalWidth < rc.width) {
                
                if ((_alignment & Align.HCenter) == Align.HCenter) {
                    mainSizeDelta = (rc.width - _totalWidth) / 2;
                }
                else if ((_alignment & Align.Right) == Align.Right) {
                    mainSizeDelta = rc.width - _totalWidth;
                }
            }
        }
        
        // final resize and layout of children
        int position = mainSizeDelta;
        for (int i = 0; i < _count; i++) {
            LayoutItem * item = &_list[i];
           
            // apply size
            Rect childRect = rc;
            if (_orientation == Orientation.Vertical) {
                // Vertical
                if (item._measuredWidth < rc.width){
                    if ((_alignment & Align.HCenter) == Align.HCenter) {
                        childRect.left += ((rc.width - item._measuredWidth) / 2);
                    }
                    else if ((_alignment & Align.Right) == Align.Right) {
                        childRect.left += (rc.width - item._measuredWidth);
                    }
                }

                childRect.top += position;
                childRect.bottom = childRect.top + item._measuredHeight;
                childRect.right = childRect.left + item._measuredWidth;
                item.layout(childRect);
                position += item._measuredHeight;
            } else {
                // Horizontal
                if (item._measuredHeight < rc.height){
                    if ((_alignment & Align.VCenter) == Align.VCenter) {
                        childRect.top += ((rc.height - item._measuredHeight) / 2);
                    }
                    else if ((_alignment & Align.Bottom) == Align.Bottom) {
                        childRect.top += (rc.height - item._measuredHeight);
                    }
                }
                childRect.left += position;
                childRect.right = childRect.left + item._measuredWidth;
                childRect.bottom = childRect.top + item._measuredHeight;
                item.layout(childRect);
                position += item._measuredWidth;
            }
        }
    }

    void clear() {
        for (int i = 0; i < _count; i++)
            _list[i].clear();
        _count = 0;
    }
    ~this() {
        clear();
    }
}

enum ResizerEventType : int {
    StartDragging,
    Dragging,
    EndDragging
}

interface ResizeHandler {
    void onResize(ResizerWidget source, ResizerEventType event, int currentPosition);
}

/**
 * Resizer control.
 * Put it between other items in LinearLayout to allow resizing its siblings.
 * While dragging, it will resize previous and next children in layout.
 */
class ResizerWidget : Widget {
    protected Orientation _orientation;
    protected Widget _previousWidget;
    protected Widget _nextWidget;
    protected string _styleVertical;
    protected string _styleHorizontal;
    Signal!ResizeHandler resizeEvent;

    /// Orientation: Vertical to resize vertically, Horizontal - to resize horizontally
    @property Orientation orientation() { return _orientation; }
    /// empty parameter list constructor - for usage by factory
    this() {
        this(null);
    }
    /// create with ID parameter
    this(string ID, Orientation orient = Orientation.Vertical) {
        super(ID);
        _styleVertical = "RESIZER_VERTICAL";
        _styleHorizontal = "RESIZER_HORIZONTAL";
        _orientation = orient;
        trackHover = true;
    }

    @property bool validProps() {
        return _previousWidget && _nextWidget;
    }

    /// returns mouse cursor type for widget
    override uint getCursorType(int x, int y) {
        if (_orientation == Orientation.Vertical) {
            return CursorType.SizeNS;
        } else {
            return CursorType.SizeWE;
        }
    }

    protected void updateProps() {
        _previousWidget = null;
        _nextWidget = null;
        LinearLayout parentLayout = cast(LinearLayout)_parent;
        if (parentLayout) {
            _orientation = parentLayout.orientation;
            int index = parentLayout.childIndex(this);
            _previousWidget = parentLayout.child(index - 1);
            _nextWidget = parentLayout.child(index + 1);
        }
        if (validProps) {
            if (_orientation == Orientation.Vertical) {
                styleId = _styleVertical;
            } else {
                styleId = _styleHorizontal;
            }
        } else {
            _previousWidget = null;
            _nextWidget = null;
        }
    }

    override void measureMinWidth() {
        updateProps();
        adjustMeasuredMinWidth(7);
    }

    override void measureMinHeight(int widgetWidth) {
        adjustMeasuredMinHeight(7);
    }

    /// Set widget rectangle to specified value and layout widget contents. (Step 2 of two phase layout).
    override void layout(Rect rc) {
        updateProps();
        if (visibility == Visibility.Gone) {
            return;
        }
        _pos = rc;
        _needLayout = false;
    }

    protected int _delta;
    protected int _minDragDelta;
    protected int _maxDragDelta;
    protected bool _dragging;
    protected int _dragStartPosition; // drag start delta
    protected Point _dragStart;
    protected Rect _dragStartRect;
    protected Rect _scrollArea;

    @property int delta() { return _delta; }

    /// process mouse event; return true if event is processed by widget.
    override bool onMouseEvent(MouseEvent event) {
        // support onClick
        if (event.action == MouseAction.ButtonDown && event.button == MouseButton.Left) {
            setState(State.Pressed);
            _dragging = true;
            _dragStart.x = event.x;
            _dragStart.y = event.y;
            _dragStartPosition = _delta;
            _dragStartRect = _pos;
            _scrollArea = _pos;
            _minDragDelta = 0;
            _maxDragDelta = 0;
            if (validProps) {
                Rect r1 = _previousWidget.pos;
                Rect r2 = _nextWidget.pos;
                _scrollArea.left = r1.left;
                _scrollArea.right = r2.right;
                _scrollArea.top = r1.top;
                _scrollArea.bottom = r2.bottom;
                if (_orientation == Orientation.Vertical) {
                    _minDragDelta = _scrollArea.top - _dragStartRect.top;
                    _maxDragDelta = _scrollArea.bottom - _dragStartRect.bottom;
                }
                if (_delta < _minDragDelta)
                    _delta = _minDragDelta;
                if (_delta > _maxDragDelta)
                    _delta = _maxDragDelta;
            } else if (resizeEvent.assigned) {
                resizeEvent(this, ResizerEventType.StartDragging, _orientation == Orientation.Vertical ? event.y : event.x);
            }
            return true;
        }
        if (event.action == MouseAction.FocusOut && _dragging) {
            return true;
        }
        if ((event.action == MouseAction.ButtonUp && event.button == MouseButton.Left) || (!event.lbutton.isDown && _dragging)) {
            resetState(State.Pressed);
            if (_dragging) {
                //sendScrollEvent(ScrollAction.SliderReleased, _position);
                _dragging = false;
                if (resizeEvent.assigned) {
                    resizeEvent(this, ResizerEventType.EndDragging, _orientation == Orientation.Vertical ? event.y : event.x);
                }
            }
            return true;
        }
        if (event.action == MouseAction.Move && _dragging) {
            int delta = _orientation == Orientation.Vertical ? event.y - _dragStart.y : event.x - _dragStart.x;
            if (resizeEvent.assigned) {
                resizeEvent(this, ResizerEventType.Dragging, _orientation == Orientation.Vertical ? event.y : event.x);
                return true;
            }
            _delta = _dragStartPosition + delta;
            if (_delta < _minDragDelta)
                _delta = _minDragDelta;
            if (_delta > _maxDragDelta)
                _delta = _maxDragDelta;
            Rect rc = _dragStartRect;
            int offset;
            int space;
            if (_orientation == Orientation.Vertical) {
                rc.top += delta;
                rc.bottom += delta;
                if (rc.top < _scrollArea.top) {
                    rc.top = _scrollArea.top;
                    rc.bottom = _scrollArea.top + _dragStartRect.height;
                } else if (rc.bottom > _scrollArea.bottom) {
                    rc.top = _scrollArea.bottom - _dragStartRect.height;
                    rc.bottom = _scrollArea.bottom;
                }
                offset = rc.top - _scrollArea.top;
                space = _scrollArea.height - rc.height;
            } else {
                rc.left += delta;
                rc.right += delta;
                if (rc.left < _scrollArea.left) {
                    rc.left = _scrollArea.left;
                    rc.right = _scrollArea.left + _dragStartRect.width;
                } else if (rc.right > _scrollArea.right) {
                    rc.left = _scrollArea.right - _dragStartRect.width;
                    rc.right = _scrollArea.right;
                }
                offset = rc.left - _scrollArea.left;
                space = _scrollArea.width - rc.width;
            }
            //_pos = rc;
            //int position = space > 0 ? _minValue + offset * (_maxValue - _minValue - _pageSize) / space : 0;
            requestLayout();
            invalidate();
            //onIndicatorDragging(_dragStartPosition, position);
            return true;
        }
        if (event.action == MouseAction.Move && trackHover) {
            if (!(state & State.Hovered)) {
                //Log.d("Hover ", id);
                setState(State.Hovered);
            }
            return true;
        }
        if ((event.action == MouseAction.Leave || event.action == MouseAction.Cancel) && trackHover) {
            //Log.d("Leave ", id);
            resetState(State.Hovered);
            return true;
        }
        if (event.action == MouseAction.Cancel) {
            //Log.d("SliderButton.onMouseEvent event.action == MouseAction.Cancel");
            if (_dragging) {
                resetState(State.Pressed);
                _dragging = false;
                if (resizeEvent.assigned) {
                    resizeEvent(this, ResizerEventType.EndDragging, _orientation == Orientation.Vertical ? event.y : event.x);
                }
            }
            return true;
        }
        return false;
    }
}


/// Arranges items either vertically or horizontally
class LinearLayout : WidgetGroupDefaultDrawing {
    protected Orientation _orientation = Orientation.Vertical;
    /// returns linear layout orientation (Vertical, Horizontal)
    @property Orientation orientation() const { return _orientation; }
    /// sets linear layout orientation
    @property LinearLayout orientation(Orientation value) { _orientation = value; requestLayout(); return this; }

    /// empty parameter list constructor - for usage by factory
    this() {
        this(null);
    }
    /// create with ID parameter and orientation
    this(string ID, Orientation orientation = Orientation.Vertical) {
        super(ID);
        _layoutItems = new LayoutItems();
        _orientation = orientation;
    }

    LayoutItems _layoutItems;

    override void measureMinWidth() {
        _layoutItems.setLayoutParams(orientation, layoutWidth, layoutHeight, alignment);
        _layoutItems.setWidgets(_children);

        int mw = _layoutItems.measureMinWidth();
        adjustMeasuredMinWidth(mw);
    }

    override void measureWidth(int parentWidth) {
        Rect m = margins;
        Rect p = padding;
        int pwidth = parentWidth;
        pwidth -= m.left + m.right + p.left + p.right;

        int w = _layoutItems.measureWidth(pwidth);
        adjustMeasuredWidth(parentWidth, w + m.left + m.right + p.left + p.right); // adjustMeasuredWidth do not adds padings and margins
    }

    override void measureMinHeight(int width) {
        Rect m = margins;
        Rect p = padding;
        int w = width;
        w -= m.left + m.right + p.left + p.right;

        int mh = _layoutItems.measureMinHeight(w);
        adjustMeasuredMinHeight(mh);
    }

    override void measureHeight(int parentHeight) {
        Rect m = margins;
        Rect p = padding;
        int pheight = parentHeight;
        pheight -= m.top + m.bottom + p.top + p.bottom;

        int h = _layoutItems.measureHeight(pheight);
        adjustMeasuredHeight(parentHeight, h + m.top + m.bottom + p.top + p.bottom); // adjustMeasuredHeight do not adds padings and margins
    }

    /// Set widget rectangle to specified value and layout widget contents. (Step 2 of two phase layout).
    override void layout(Rect rc) {
        _needLayout = false;
        if (visibility == Visibility.Gone) {
            return;
        }
        _pos = rc;
        applyMargins(rc);
        applyPadding(rc);
        //debug Log.d("LinearLayout.layout id=", _id, " rc=", rc, " fillHoriz=", layoutWidth == FILL_PARENT);
        _layoutItems.layout(rc);
    }
}

/// Arranges children vertically
class VerticalLayout : LinearLayout {
    /// empty parameter list constructor - for usage by factory
    this() {
        this(null);
    }
    /// create with ID parameter
    this(string ID) {
        super(ID);
        orientation = Orientation.Vertical;
    }
}

/// Arranges children horizontally
class HorizontalLayout : LinearLayout {
    /// empty parameter list constructor - for usage by factory
    this() {
        this(null);
        orientation = Orientation.Horizontal;
    }
    /// create with ID parameter
    this(string ID) {
        super(ID);
        orientation = Orientation.Horizontal;
    }
}

/// place all children into same place (usually, only one child should be visible at a time)
class FrameLayout : WidgetGroupDefaultDrawing {
    /// empty parameter list constructor - for usage by factory
    this() {
        this(null);
    }
    /// create with ID parameter
    this(string ID) {
        super(ID);
    }

    override void measureMinWidth() {
        int mw = 0;
        for (int i = 0; i < _children.count; i++) {
            Widget item = _children.get(i);
            if (item.visibility != Visibility.Gone) {
                item.measureMinWidth();
                if (mw < item.measuredMinWidth)
                    mw = item.measuredMinWidth;
            }
        }
        adjustMeasuredMinWidth(mw);
    }

    override void measureWidth(int parentWidth) {
        Rect m = margins;
        Rect p = padding;
        int pwidth = parentWidth;
        pwidth -= m.left + m.right + p.left + p.right;
        int w = 0;
        
        for (int i = 0; i < _children.count; i++) {
            Widget item = _children.get(i);
            if (item.visibility != Visibility.Gone) {
                item.measureWidth(pwidth);
                if (w < item.measuredWidth)
                    w = item.measuredWidth;
            }
        }
        adjustMeasuredWidth(parentWidth, w + m.left + m.right + p.left + p.right);
    }


    override void measureMinHeight(int width) {
        Rect m = margins;
        Rect p = padding;
        int w = width;
        w -= m.left + m.right + p.left + p.right;

        int mh = 0;
        for (int i = 0; i < _children.count; i++) {
            Widget item = _children.get(i);
            if (item.visibility != Visibility.Gone) {
                item.measureMinHeight(w);
                if (mh < item.measuredMinHeight)
                    mh = item.measuredMinHeight;
            }
        }

        adjustMeasuredMinHeight(mh);
    }

    override void measureHeight(int parentHeight) {
        Rect m = margins;
        Rect p = padding;
        int pheight = parentHeight;
        pheight -= m.top + m.bottom + p.top + p.bottom;

        int h = 0;
        for (int i = 0; i < _children.count; i++) {
            Widget item = _children.get(i);
            if (item.visibility != Visibility.Gone) {
                item.measureHeight(pheight);
                if (h < item.measuredHeight)
                    h = item.measuredHeight;
            }
        }
        adjustMeasuredHeight(parentHeight, h + m.top + m.bottom + p.top + p.bottom); // adjustMeasuredHeight do not adds padings and margins
    }

    /// Set widget rectangle to specified value and layout widget contents. (Step 2 of two phase layout).
    override void layout(Rect rc) {
        _needLayout = false;
        if (visibility == Visibility.Gone) {
            return;
        }
        _pos = rc;
        applyMargins(rc);
        applyPadding(rc);
        for (int i = 0; i < _children.count; i++) {
            Widget item = _children.get(i);
            if (item.visibility == Visibility.Visible) {
                item.layout(rc);
            }
        }
    }

    /// make one of children (with specified ID) visible, for the rest, set visibility to otherChildrenVisibility
    bool showChild(string ID, Visibility otherChildrenVisibility = Visibility.Invisible, bool updateFocus = false) {
        bool found = false;
        Widget foundWidget = null;
        for (int i = 0; i < _children.count; i++) {
            Widget item = _children.get(i);
            if (item.compareId(ID)) {
                item.visibility = Visibility.Visible;
                item.requestLayout();
                foundWidget = item;
                found = true;
            } else {
                item.visibility = otherChildrenVisibility;
            }
        }
        if (foundWidget !is null && updateFocus)
            foundWidget.setFocus();
        return found;
    }
}

/// layout children as table with rows and columns
class TableLayout : WidgetGroupDefaultDrawing {

    this(string ID = null) {
        super(ID);
    }

    this() {
        this(null);
    }

    protected int _colCount = 1;
    /// number of columns
    @property int colCount() { return _colCount; }
    @property TableLayout colCount(int count) { if (_colCount != count) requestLayout(); _colCount = count; return this; }
    @property int rowCount() {
        return (childCount / _colCount) + ((childCount % _colCount == 0 ) ? 0 : 1);
    }

    /// set int property value, for ML loaders
    mixin(generatePropertySettersMethodOverride("setIntProperty", "int",
          "colCount"));

    Widget getCell(int col, int row) {
        int index = row * colCount + col;
        if (index > childCount - 1)
            return null;
        return child(index);
    }


    protected struct ColumnData {
        int minWidth = 0;
        bool fillParent = false;
        int maxLayoutWeight = 1;

        void clear() {
            minWidth = 0;
            fillParent = false;
            maxLayoutWeight = 1;
        }
    }

    protected struct RowData {
        int minHeight = 0;
        bool fillParent = false;
        int maxLayoutWeight = 1;

        void clear() {
            minHeight = 0;
            fillParent = false;
            maxLayoutWeight = 1;
        }
    }

    protected ColumnData[] _colsData;
    protected int _totalWidthWeight = 0;
    protected int _totalColMinWidth = 0;
    override void measureMinWidth() {
        _colsData.length = _colCount;
        foreach (ref cd ; _colsData) 
            cd.clear();
        _totalColMinWidth = 0;
        _totalWidthWeight = 0;

        Widget w;
        ColumnData * cd;
        for (int c = 0 ; c < _colCount ; c++) {
            cd = &_colsData[c];
            for (int r = 0 ; r < rowCount ; r++) {
                w = getCell(c, r);
                if (!w)
                    break;
                w.measureMinWidth();
                
                if (w.measuredMinWidth > cd.minWidth)
                    cd.minWidth = w.measuredMinWidth;
                if (w.layoutWidth == FILL_PARENT) {
                    cd.fillParent = true;
                    if (w.layoutWeight > cd.maxLayoutWeight)
                        cd.maxLayoutWeight = w.layoutWeight;
                }
            }
            _totalColMinWidth += cd.minWidth;
            if (cd.fillParent)
                _totalWidthWeight += cd.maxLayoutWeight;
        }

        adjustMeasuredMinWidth(_totalColMinWidth);
    }

    override void measureWidth(int parentWidth) {
        Rect m = margins;
        Rect p = padding;
        int pwidth = parentWidth - (m.left + m.right + p.left + p.right);
        int totalWidth = 0;

        int extraSpace = pwidth - _totalColMinWidth;
        int extraSpaceRemained = extraSpace;
        int extraSpaceStep = 0;
        if (_totalWidthWeight != 0)
            extraSpaceStep = extraSpace / _totalWidthWeight;

        Widget w;
        ColumnData *cd;
        for (int c = 0 ; c < _colCount ; c++) {
            cd = &_colsData[c];
            if (cd.fillParent) 
                cd.minWidth = cd.minWidth + extraSpaceStep * cd.maxLayoutWeight;
            
            for (int r = 0 ; r < rowCount ; r++) {
                w = getCell(c, r);
                if (!w)
                    break;
                w.measureWidth(cd.minWidth);
            }
            totalWidth += cd.minWidth;
        }
        
        adjustMeasuredWidth(parentWidth, totalWidth + m.left + m.right + p.left + p.right);
    }

    protected RowData[] _rowsData;
    protected int _totalHeightWeight = 0;
    protected int _totalRowMinHeight = 0;
    override void measureMinHeight(int widgetWidth) {
        _totalRowMinHeight = 0;
        _totalHeightWeight = 0;

        _rowsData.length = rowCount;
        foreach (ref rd ; _rowsData) 
            rd.clear();

        RowData * rd;
        ColumnData * cd;
        Widget w;

        for (int r = 0 ; r < rowCount ; r++) {
            rd = &_rowsData[r];
            
            for (int c = 0 ; c < _colCount ; c++) {
                cd = &_colsData[c];
            
                w = getCell(c, r);
                if (!w)
                    break;
                w.measureMinHeight(cd.minWidth);
                if (w.measuredMinHeight > rd.minHeight)
                    rd.minHeight = w.measuredMinHeight;
                if (w.layoutHeight == FILL_PARENT) {
                    rd.fillParent = true;
                    if (w.layoutWeight > rd.maxLayoutWeight)
                        rd.maxLayoutWeight = w.layoutWeight;
                }
            }
            _totalRowMinHeight += rd.minHeight;
            if (rd.fillParent)
                _totalHeightWeight += rd.maxLayoutWeight;
        }
        adjustMeasuredMinHeight(_totalRowMinHeight);
    }

    override void measureHeight(int parentHeight) {
        Rect m = margins;
        Rect p = padding;
        int pheight = parentHeight - (m.top + m.bottom + p.top + p.bottom);
        int totalHeight = 0;

        int extraSpace = parentHeight - _totalRowMinHeight;
        int extraSpaceRemained = extraSpace;
        int extraSpaceStep = 0;
        if (_totalHeightWeight != 0)
            extraSpaceStep = extraSpace / _totalHeightWeight;

        Widget w;
        RowData *rd;
        for (int r = 0 ; r < rowCount ; r++) {
            rd = &_rowsData[r];
            if (rd.fillParent)
                rd.minHeight = rd.minHeight + extraSpaceStep * rd.maxLayoutWeight;

            for (int c = 0 ; c < _colCount ; c++) {
                w = getCell(c, r);
                if (!w)
                    break;
                w.measureHeight(rd.minHeight);
            }
            totalHeight += rd.minHeight;
        }
        
        adjustMeasuredHeight(parentHeight, totalHeight + m.top + m.bottom + p.top + p.bottom);
    }
    
    /// Set widget rectangle to specified value and layout widget contents. (Step 2 of two phase layout).
    override void layout(Rect rc) {
        _needLayout = false;
        if (visibility == Visibility.Gone) {
            return;
        }
        _pos = rc;
        applyMargins(rc);
        applyPadding(rc);

        int y0 = rc.top;
        ColumnData cd;
        RowData rd;
        Widget w;
        for (int y = 0; y < rowCount; y++) {
            rd = _rowsData[y];
            int x0 = rc.left;
            for (int x = 0; x < _colCount; x++) {
                cd = _colsData[x];
                Rect r;
                w = getCell(x, y);
                if (w) {
                    r.left = x0;
                    if (w.measuredWidth < cd.minWidth){
                        if ((alignment & Align.HCenter) == Align.HCenter) {
                            r.left += ((cd.minWidth - w.measuredWidth) / 2);
                        }
                        else if ((alignment & Align.Right) == Align.Right) {
                            r.left += (cd.minWidth - w.measuredWidth);
                        }
                    }
                    r.right = r.left + w.measuredWidth;

                    r.top = y0;
                    if (w.measuredHeight < rd.minHeight){
                        if ((alignment & Align.VCenter) == Align.VCenter) {
                            r.top += ((rd.minHeight - w.measuredHeight) / 2);
                        }
                        else if ((alignment & Align.Bottom) == Align.Bottom) {
                            r.top += (rd.minHeight - w.measuredHeight);
                        }
                    }
                    r.bottom = r.top + w.measuredHeight;

                    w.layout(r);
                }
                else {
                    r.left = r.left + x0;
                    r.top = r.top + y0;
                }
                x0 += cd.minWidth;
            }
            y0 += rd.minHeight;
        }
    }

}

//import dlangui.widgets.metadata;
//mixin(registerWidgets!(VerticalLayout, HorizontalLayout, TableLayout, FrameLayout)());
