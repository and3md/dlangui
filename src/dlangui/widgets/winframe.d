// Written in the D programming language.

/**

This module implements window frame widget.


Synopsis:

----
import dlangui.widgets.docks;
----


Copyright: Vadim Lopatin, 2015
License:   Boost License 1.0
Authors:   Vadim Lopatin, coolreader.org@gmail.com
*/
module dlangui.widgets.winframe;

import dlangui.widgets.layouts;
import dlangui.widgets.controls;

/// window frame with caption widget
class WindowFrame : VerticalLayout {
    private VerticalLayout limitV;
    private HorizontalLayout limitH;
    protected Widget _bodyWidget;
    @property Widget bodyWidget() { return _bodyWidget; }
    @property void bodyWidget(Widget widget) {
        _bodyLayout.replaceChild(widget, _bodyWidget);
        _bodyWidget = widget;
        _bodyWidget.parent = this;
        limitH.layoutWidth = bodyWidget.layoutWidth;
        limitH.layoutHeight = bodyWidget.layoutHeight;
        limitV.layoutWidth = bodyWidget.layoutWidth;
        limitV.layoutHeight = bodyWidget.layoutHeight;
        requestLayout();
    }

    protected HorizontalLayout _captionLayout;
    protected TextWidget _caption;
    protected ImageButton _closeButton;
    protected bool _showCloseButton;
    protected HorizontalLayout _bodyLayout;

    @property TextWidget caption() { return _caption; }

    this(string ID, bool showCloseButton = true) {
        super(ID);
        _showCloseButton = showCloseButton;
        initialize();
    }

    Signal!OnClickHandler closeButtonClick;
    protected bool onCloseButtonClick(Widget source) {
        if (closeButtonClick.assigned)
            closeButtonClick(source);
        return true;
    }

    protected void initialize() {

        styleId = STYLE_DOCK_WINDOW;

        limitH = new HorizontalLayout();
        limitV = new VerticalLayout();
        _captionLayout = new HorizontalLayout("DOCK_WINDOW_CAPTION_PANEL");
        _captionLayout.layoutWidth(FILL_PARENT).layoutHeight(WRAP_CONTENT);
        _captionLayout.styleId = STYLE_DOCK_WINDOW_CAPTION;

        _caption = new TextWidget("DOCK_WINDOW_CAPTION");
        _caption.styleId = STYLE_DOCK_WINDOW_CAPTION_LABEL;

        _closeButton = new ImageButton("DOCK_WINDOW_CAPTION_CLOSE_BUTTON");
        _closeButton.styleId = STYLE_BUTTON_TRANSPARENT;
        _closeButton.drawableId = "close";
        _closeButton.trackHover = true;
        _closeButton.click = &onCloseButtonClick;
        if (!_showCloseButton)
            _closeButton.visibility = Visibility.Gone;

        _captionLayout.addChild(_caption);
        _captionLayout.addChild(_closeButton);

        _bodyLayout = new HorizontalLayout();
        _bodyLayout.styleId = STYLE_DOCK_WINDOW_BODY;

        _bodyWidget = createBodyWidget();
        _bodyLayout.addChild(_bodyWidget);
        limitH.layoutWidth = bodyWidget.layoutWidth;
        limitH.layoutHeight = bodyWidget.layoutHeight;
        limitV.layoutWidth = bodyWidget.layoutWidth;
        limitV.layoutHeight = bodyWidget.layoutHeight;

        limitV.addChild(_captionLayout);
        limitV.addChild(_bodyLayout);
        limitH.addChild(limitV);
        addChild(limitH);
    }

    protected Widget createBodyWidget() {
        return new Widget("DOCK_WINDOW_BODY");
    }

    protected void setCaptionStyle(string captionStyleID) {
        _captionLayout.styleId = captionStyleID;
        _captionLayout.onThemeChanged();
    }

    protected string captionStyle() {
        return _captionLayout.styleId;
    }
}
