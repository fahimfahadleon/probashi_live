package com.horoftech.probashi_live;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class RtmpCameraPlatformViewFactory extends PlatformViewFactory {
    public RtmpCameraPlatformViewFactory() {
        super(StandardMessageCodec.INSTANCE);
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        return new RtmpCameraPlatformView(context);
    }
}