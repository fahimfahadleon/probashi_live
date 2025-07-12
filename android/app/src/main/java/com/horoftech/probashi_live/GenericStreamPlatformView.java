package com.horoftech.probashi_live;

import android.view.View;
import io.flutter.plugin.platform.PlatformView;

public class GenericStreamPlatformView implements PlatformView {

    private final GenericStreamView view;

    public GenericStreamPlatformView(GenericStreamView view) {
        this.view = view;
    }

    @Override
    public View getView() {
        return view;
    }

    @Override
    public void dispose() {
        view.release();
    }
}
