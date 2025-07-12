package com.horoftech.probashi_live;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;

import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.common.StandardMessageCodec;

public class GenericStreamViewFactory extends PlatformViewFactory {

    private final GenericStreamView genericStreamViewInstance;

    public GenericStreamViewFactory(GenericStreamView instance) {
        super(StandardMessageCodec.INSTANCE);
        this.genericStreamViewInstance = instance;
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        // Return a PlatformView wrapping the existing instance
        return new PlatformView() {
            @NonNull
            @Override
            public View getView() {
                return genericStreamViewInstance;
            }

            @Override
            public void dispose() {
                // Optional: you can release resources here if needed
            }
        };
    }
}
